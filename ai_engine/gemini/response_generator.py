"""Response generator orchestrating language, search, safety, and pluggable LLM inference."""

from __future__ import annotations

import json
import logging
import re
import time
from typing import Any, Dict, List, Optional, Tuple

from ai_engine.gemini.context_manager import ConversationContextManager
from ai_engine.gemini.gemini_client import GeminiClient
from ai_engine.gemini.prompt_builder import PromptBuilder
from ai_engine.language_engine.language_detector import LanguageDetector
from ai_engine.language_engine.language_mapper import get_language_by_code
from ai_engine.language_engine.regional_vocabulary import identify_query_attributes
from ai_engine.language_engine.response_language import ResponseLanguageFormatter
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.models.response_models import EvidenceSource, FarmerChatResponse
from ai_engine.providers.base_provider import BaseLLMProvider
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.safety.answer_validator import AnswerValidator
from ai_engine.safety.dosage_validator import DosageConsistencyValidator
from ai_engine.safety.quality_validator import ResponseQualityValidator
from ai_engine.safety.uncertainty_handler import UncertaintyHandler
from ai_engine.search_engine.search_orchestrator import SearchOrchestrator

logger = logging.getLogger(__name__)


class ResponseGenerator:
    """End-to-end response generation pipeline for KhetChacha Farmer AI."""

    def __init__(
        self,
        gemini_client: GeminiClient,
        search_orchestrator: SearchOrchestrator,
        safety_engine: Optional[AgricultureSafetyEngine] = None,
        context_manager: Optional[ConversationContextManager] = None,
        llm_provider: Optional[BaseLLMProvider] = None,
    ):
        self.gemini_client = gemini_client
        self.llm_provider = llm_provider or gemini_client
        self.search_orchestrator = search_orchestrator
        self.safety_engine = safety_engine or AgricultureSafetyEngine()
        self.context_manager = context_manager or ConversationContextManager()
        self._safe_cache: Dict[str, Tuple[FarmerChatResponse, float]] = {}

        # Cache & Performance Metrics
        self.cache_hits: int = 0
        self.cache_misses: int = 0
        self.deterministic_responses: int = 0

    def clear_cache(self) -> None:
        """Invalidates all cached responses upon knowledge base updates or re-indexing."""
        self._safe_cache.clear()
        logger.info("ResponseGenerator safe cache cleared successfully.")

    def get_metrics(self) -> Dict[str, Any]:
        """Returns cache efficiency and generation metrics."""
        return {
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses,
            "deterministic_responses": self.deterministic_responses,
            "cached_entries_count": len(self._safe_cache),
            "llm_usage": self.llm_provider.get_usage_metrics() if hasattr(self.llm_provider, "get_usage_metrics") else {},
        }

    def generate_response(self, request: FarmerChatRequest) -> FarmerChatResponse:
        """Processes farmer request through language detection, retrieval, generation, and safety."""
        # 1. Determine language
        active_lang = request.language
        preferred_lang = request.language if request.language and request.language != "auto" else None
        if not active_lang or active_lang == "auto":
            active_lang = LanguageDetector.detect_language(request.query, preferred_language=preferred_lang)

        # Normalize language
        lang_info = get_language_by_code(active_lang)
        active_lang = lang_info.code

        # Decompose query to check for multi-part requests
        decomp = AnswerValidator.decompose_query(request.query)
        is_multipart = decomp["is_multipart"]

        # 1b. Check Language Tier Requirements:
        # Tier 1 languages: 'gu', 'hi', 'en' -> Full complex question support
        # Tier 2 languages: 'pa', 'mr' -> Reliable simple agricultural question support
        # Full multi-part complex planning (budget + 30-day schedule, 4+ facets) triggers limitation notice
        is_tier2_full_planning = (
            active_lang in ("pa", "mr")
            and decomp.get("has_cost")
            and decomp.get("has_timeline")
            and decomp.get("facets_count", 0) >= 4
        )
        if is_tier2_full_planning:
            self.deterministic_responses += 1
            if active_lang == "pa":
                limitation_msg = (
                    "ਖੇਤਚਾਚਾ AI ਵਿੱਚ ਪੰਜਾਬੀ ਭਾਸ਼ਾ ਲਈ ਸਰਲ ਖੇਤੀ ਸਵਾਲਾਂ (ਜਿਵੇਂ ਖਾਦ, ਪਾਣੀ, ਕੀੜੇ-ਮਕੌੜੇ ਦੀ ਰੋਕਥਾਮ) ਦੇ ਭਰੋਸੇਯੋਗ ਜਵਾਬ ਉਪਲਬਧ ਹਨ। "
                    "ਪੂਰੇ ਬਹੁ-ਭਾਗੀ ਗੁੰਝਲਦਾਰ ਨਿਯੋਜਨ ਅਤੇ ਵਿੱਤੀ ਬਜਟ ਲਈ ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਸਵਾਲ ਸਰਲ ਭਾਗਾਂ ਵਿੱਚ ਪੁੱਛੋ ਜਾਂ ਹਿੰਦੀ/ਅੰਗਰੇਜ਼ੀ ਦੀ ਚੋਣ ਕਰੋ।"
                )
                action_steps = [
                    "ਆਪਣਾ ਸਵਾਲ ਕਿਸੇ ਇੱਕ ਵਿਸ਼ੇ (ਜਿਵੇਂ ਸਿਰਫ਼ ਖਾਦ ਜਾਂ ਸਿਰਫ਼ ਕੀਟਨਾਸ਼ਕ) ਲਈ ਪੁੱਛੋ।",
                    "ਵਿਸਤ੍ਰਿਤ ਬਹੁ-ਭਾਗੀ ਯੋਜਨਾ ਲਈ ਐਪ ਵਿੱਚ ਹਿੰਦੀ ਜਾਂ ਅੰਗਰੇਜ਼ੀ ਭਾਸ਼ਾ ਚੁਣੋ।",
                    "ਵਧੇਰੇ ਜਾਣਕਾਰੀ ਲਈ ਕਿਸਾਨ ਕਾਲ ਸੈਂਟਰ (1800-180-1551) ਨਾਲ ਸੰਪਰਕ ਕਰੋ।",
                ]
                precautions = [
                    "ਗੁੰਝਲਦਾਰ ਰਸਾਇਣਕ ਮਿਸ਼ਰਣਾਂ ਦੀ ਵਰਤੋਂ ਤੋਂ ਪਹਿਲਾਂ ਸਥਾਨਕ ਕੇਵੀਕੇ ਮਾਹਿਰ ਦੀ ਸਲਾਹ ਲਵੋ।",
                ]
            else:  # Marathi
                limitation_msg = (
                    "खेतचाचा AI मध्ये मराठी भाषेसाठी मूलभूत शेती प्रश्नांची (जसे खत, पाणी, कीड-रोग नियंत्रण) विश्वसनीय उत्तरे उपलब्ध आहेत. "
                    "संपूर्ण बहु-घटक नियोजन आणि अंदाजपत्रकासाठी कृपया आपला प्रश्न सुटसुटीत भागांमध्ये विचारा किंवा हिंदी/इंग्रजी भाषेची निवड करा."
                )
                action_steps = [
                    "आपला प्रश्न एका वेळी एकाच विषयावर (उदा. केवळ खत किंवा केवळ कीटकनाशक) विचारा.",
                    "सविस्तर बहु-घटक नियोजनासाठी अॅपमध्ये हिंदी किंवा इंग्रजी भाषा निवडा.",
                    "अधिक माहितीसाठी किसान कॉल सेंटर (१८००-१८०-१५५१) शी संपर्क साधा.",
                ]
                precautions = [
                    "अचूक माहितीशिवाय रासायनिक खते किंवा औषधांचे अवाजवी मिश्रण करू नका.",
                ]

            return FarmerChatResponse(
                short_answer=limitation_msg,
                detailed_explanation=limitation_msg,
                language=active_lang,
                confidence_score=0.90,
                sources=[],
                action_steps=action_steps,
                safety_precautions=precautions,
                crop_detected=request.crop,
                symptoms_identified=[],
                search_strategy_used="tier2_complexity_limitation",
                requires_photo=False,
            )

        # Check for personalized context (land size, session history, crop age, soil type, or multi-part)
        is_personalized = bool(
            is_multipart
            or request.land_size
            or request.land_area
            or request.session_id
            or (request.crop_age_days and request.crop_age_days > 0)
            or request.soil_type
            or request.farmer_district
            or request.farmer_state
        )

        # Check safe in-memory cache for duplicate non-personalized queries
        clean_q = re.sub(r'[^a-zA-Z0-9\u0a80-\u0aff\u0900-\u097f]', '', request.query.lower())
        cache_key = f"{active_lang}:{request.crop or ''}:{clean_q}"
        if not is_personalized and cache_key in self._safe_cache:
            cached_resp, timestamp = self._safe_cache[cache_key]
            if time.time() - timestamp < 3600.0:
                self.cache_hits += 1
                logger.info("Safe Cache Hit: Returning verified advisory (0 LLM tokens consumed)")
                return cached_resp
        self.cache_misses += 1

        # 2. Extract agronomic attributes
        attrs = identify_query_attributes(request.query)
        detected_crops = attrs.get("crops", [])
        detected_symptoms = attrs.get("symptoms", [])

        # 3. Check for severe ambiguity / lack of info (only if NOT a comprehensive multi-part query)
        if not is_multipart and UncertaintyHandler.is_query_highly_ambiguous(request.query, detected_crops, detected_symptoms):
            self.deterministic_responses += 1
            clarification = UncertaintyHandler.generate_clarification_response(
                query=request.query,
                language_code=active_lang,
                detected_crops=detected_crops,
            )
            return FarmerChatResponse(
                short_answer=clarification["short_answer"],
                detailed_explanation=clarification["detailed_explanation"],
                language=active_lang,
                confidence_score=0.45,
                sources=[],
                action_steps=clarification["action_steps"],
                safety_precautions=clarification["safety_precautions"],
                crop_detected=detected_crops[0] if detected_crops else None,
                symptoms_identified=detected_symptoms,
                search_strategy_used="ambiguity_clarification",
                requires_photo=clarification.get("photo_requested", False),
            )

        # 4. Retrieve Grounding Evidence
        crop_target = request.crop or (detected_crops[0] if detected_crops else None)
        if not crop_target and ("કપાસ" in request.query or "cotton" in request.query.lower()):
            crop_target = "cotton"

        orch_res = self.search_orchestrator.retrieve_evidence(
            query=request.query,
            crop=crop_target,
        )
        evidence_sources = orch_res.sources

        # 4b. Check for Single Ambiguous Symptom (ONLY if NOT multi-part)
        is_cotton_yellowing = (
            ("કપાસ" in request.query or "cotton" in request.query.lower())
            and any(term in request.query.lower() or term in request.query for term in ["પીળા", "લાલિયા", "yellow", "lalio", "yellowing"])
        )
        best_score = evidence_sources[0].confidence_score if evidence_sources else 0.0

        if not is_multipart and (is_cotton_yellowing or (UncertaintyHandler.is_single_ambiguous_symptom(request.query, detected_crops, detected_symptoms) and best_score < 0.60)):
            self.deterministic_responses += 1
            diff_diag = UncertaintyHandler.generate_differential_diagnosis_response(
                query=request.query,
                language_code=active_lang,
                detected_crops=detected_crops or (["cotton"] if is_cotton_yellowing else []),
                detected_symptoms=detected_symptoms or (["leaf_yellowing"] if is_cotton_yellowing else []),
            )
            diff_diag = DosageConsistencyValidator.reconcile_and_sanitize_response(diff_diag, crop=crop_target or "cotton")
            diff_response = FarmerChatResponse(
                short_answer=diff_diag["short_answer"],
                detailed_explanation=diff_diag["detailed_explanation"],
                language=active_lang,
                confidence_score=0.88 if is_cotton_yellowing else 0.55,
                sources=evidence_sources,
                action_steps=diff_diag["action_steps"],
                safety_precautions=diff_diag["safety_precautions"],
                crop_detected=crop_target or ("cotton" if is_cotton_yellowing else None),
                symptoms_identified=detected_symptoms or (["leaf_yellowing"] if is_cotton_yellowing else []),
                search_strategy_used="differential_diagnosis",
                requires_photo=True,
            )
            if not is_personalized:
                self._safe_cache[cache_key] = (diff_response, time.time())
            return diff_response

        # 4c. Check for completely Insufficient Evidence across all tiers (only if not multi-part)
        if not is_multipart and not orch_res.is_evidence_sufficient and not evidence_sources:
            self.deterministic_responses += 1
            insufficient_msg = ResponseLanguageFormatter.get_insufficient_evidence_fallback(active_lang)
            photo_prompt = ResponseLanguageFormatter.get_photo_request_prompt(active_lang)
            insufficient_response = FarmerChatResponse(
                short_answer=insufficient_msg,
                detailed_explanation=(
                    f"{insufficient_msg} {photo_prompt} "
                    f"કૃપા કરીને કિસાન કોલ સેન્ટર (૧૮૦૦-૧૮૦-૧૫૫૧) નો સંપર્ક કરવો."
                    if active_lang == "gu" else
                    f"{insufficient_msg} {photo_prompt} Contact Kisan Call Centre (Toll-Free 1800-180-1551)."
                ),
                language=active_lang,
                confidence_score=0.30,
                sources=[],
                action_steps=[
                    "Do not apply unverified chemical pesticides" if active_lang != "gu" else "ચોક્કસ નિદાન વગર કોઈ પણ રાસાયણિક દવાનો છંટકાવ કરવો નહીં.",
                    photo_prompt,
                    "Contact Kisan Call Centre (1800-180-1551) or local KVK" if active_lang != "gu" else "નજીકના કૃષિ વિજ્ઞાન કેન્દ્ર (KVK) અથવા કિસાન કોલ સેન્ટર (૧૮૦૦-૧૮૦-૧૫૫૧) નો સંપર્ક કરવો.",
                ],
                safety_precautions=[
                    "Avoid applying chemical treatments without verified diagnosis and official recommendation." if active_lang != "gu" else "અધિકૃત ભલામણ અને પાકા નિદાન વગર કોઈ પણ રસાયણ વાપરવું જોખમી છે."
                ],
                crop_detected=crop_target,
                symptoms_identified=detected_symptoms,
                search_strategy_used="insufficient_evidence_fallback",
                requires_photo=True,
            )
            if not is_personalized:
                self._safe_cache[cache_key] = (insufficient_response, time.time())
            return insufficient_response

        # 5. Retrieve Context History
        history = self.context_manager.get_history(request.session_id)

        # 6. Generate Response (LLM or Offline Fallback)
        raw_text = None
        if self.llm_provider.is_available:
            try:
                system_instruction = PromptBuilder.build_system_instruction(active_lang)
                prompt = PromptBuilder.build_chat_prompt(request, evidence_sources, conversation_history=history)
                max_tokens = 4096 if is_multipart else 2048
                raw_text = self.llm_provider.generate_content(
                    prompt,
                    system_instruction=system_instruction,
                    max_output_tokens=max_tokens,
                )
            except Exception as e:
                logger.warning(f"LLM Provider ({self.llm_provider.provider_name}) call failed ({e}). Falling back to verified local agronomic synthesis.")
                raw_text = None

        # Parse or generate fallback if LLM was offline or returned empty
        if raw_text:
            parsed_data = self._parse_gemini_output(raw_text, active_lang)
        else:
            parsed_data = self._generate_offline_response(request, evidence_sources, active_lang, detected_crops, detected_symptoms)

        # 7. Multi-Part Completeness Enrichment & Validation (Tier 1 languages)
        if active_lang in ("gu", "hi", "en"):
            parsed_data = AnswerValidator.validate_and_enrich_response(
                parsed_data=parsed_data,
                query=request.query,
                language_code=active_lang,
                crop=crop_target,
                land_area=request.land_area,
                land_unit=request.land_unit,
                crop_age_days=request.crop_age_days,
            )

        # 8. Dosage Consistency & Safety Validation
        parsed_data = DosageConsistencyValidator.reconcile_and_sanitize_response(parsed_data, crop=crop_target)

        combined_text = f"{parsed_data['short_answer']} {parsed_data['detailed_explanation']}"
        safety_alerts = self.safety_engine.evaluate_safety(
            query=request.query,
            response_text=combined_text,
            language_code=active_lang,
        )

        precautions = list(parsed_data.get("safety_precautions", []))
        for alert in safety_alerts:
            precautions.append(alert.message)

        # Deduplicate precautions
        unique_precautions = list(dict.fromkeys(precautions))

        # 9. Record in multi-turn context (preserving full answer nuances for follow-up questions)
        if request.session_id:
            self.context_manager.add_user_message(request.session_id, request.query)
            short_s = parsed_data["short_answer"]
            det_s = parsed_data.get("detailed_explanation", "")[:350]
            context_entry = f"{short_s} | {det_s}" if det_s and det_s != short_s else short_s
            self.context_manager.add_assistant_message(request.session_id, context_entry)

        # Compute overall confidence
        base_confidence = 0.88 if raw_text else 0.78
        if evidence_sources:
            base_confidence = min(0.96, base_confidence + 0.05)

        final_response = FarmerChatResponse(
            short_answer=parsed_data["short_answer"],
            detailed_explanation=parsed_data["detailed_explanation"],
            language=active_lang,
            confidence_score=base_confidence,
            sources=evidence_sources,
            action_steps=parsed_data.get("action_steps", []),
            safety_precautions=unique_precautions,
            crop_detected=crop_target,
            symptoms_identified=detected_symptoms,
            search_strategy_used=orch_res.strategy_used,
            requires_photo=False,
        )

        # Enforce Production Quality & Safety Gate (Banned substances, 15L spray pump, completeness)
        final_response = ResponseQualityValidator.validate_and_repair(final_response, request)

        # Cache response for duplicate non-personalized query fast-path (0 LLM tokens consumed)
        if not is_personalized:
            self._safe_cache[cache_key] = (final_response, time.time())
        return final_response

    def _parse_gemini_output(self, raw_text: str, language_code: str) -> Dict[str, Any]:
        """Parses model output into structured dictionary with multi-layered extraction resilience."""
        clean_text = raw_text.strip()
        if clean_text.startswith("```json"):
            clean_text = clean_text[7:]
        elif clean_text.startswith("```"):
            clean_text = clean_text[3:]
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3]
        clean_text = clean_text.strip()

        # Attempt 1: Direct JSON parsing
        try:
            data = json.loads(clean_text)
            if isinstance(data, dict) and "short_answer" in data and len(str(data["short_answer"]).strip()) > 10:
                return data
        except Exception:
            pass

        # Attempt 1b: Resilient JSON repair (for outputs truncated at token boundary)
        repaired_text = clean_text
        if not repaired_text.endswith("}"):
            open_quotes = repaired_text.count('"') - repaired_text.count('\\"')
            if open_quotes % 2 != 0:
                repaired_text += '"'
            if repaired_text.count("[") > repaired_text.count("]"):
                repaired_text += "]"
            if repaired_text.count("{") > repaired_text.count("}"):
                repaired_text += "}"
            try:
                data = json.loads(repaired_text)
                if isinstance(data, dict) and "short_answer" in data and len(str(data["short_answer"]).strip()) > 10:
                    return data
            except Exception:
                pass

        # Attempt 2: Flexible Regex field extraction
        extracted = {}
        short_m = re.search(r'"short_answer"\s*:\s*"((?:[^"\\]|\\.)*)"', clean_text, re.DOTALL)
        if not short_m:
            short_m = re.search(r'"short_answer"\s*:\s*"(.*?)(?:"\s*,\s*"|"\s*\})', clean_text, re.DOTALL)
        if short_m:
            _rv = short_m.group(1).replace('\\"', '"').replace('\\n', '\n')
            extracted["short_answer"] = _rv.strip()

        det_m = re.search(r'"detailed_explanation"\s*:\s*"((?:[^"\\]|\\.)*)"', clean_text, re.DOTALL)
        if not det_m:
            det_m = re.search(r'"detailed_explanation"\s*:\s*"(.*?)(?:"\s*,\s*"|"\s*\]|"\s*\})', clean_text, re.DOTALL)
        if det_m:
            _rv = det_m.group(1).replace('\\"', '"').replace('\\n', '\n')
            extracted["detailed_explanation"] = _rv.strip()

        if extracted.get("short_answer") and len(extracted["short_answer"]) > 10:
            extracted.setdefault("detailed_explanation", extracted["short_answer"])
            extracted.setdefault("action_steps", [
                "ખેતરનું નિયમિત નિરીક્ષણ કરો." if language_code == "gu" else
                ("ਖੇਤ ਦਾ ਨਿਰੀਖਣ ਕਰੋ।" if language_code == "pa" else
                ("शेताचे नियमित निरीक्षण करा." if language_code == "mr" else
                ("खेत का नियमित निरीक्षण करें।" if language_code == "hi" else "Inspect field regularly.")))
            ])
            extracted.setdefault("safety_precautions", [
                "દવા છાંટતી વખતે માસ્ક અને મોજા પહેરો." if language_code == "gu" else
                ("ਸਪਰੇਅ ਕਰਦੇ ਸਮੇਂ ਮਾਸਕ ਪਹਿਨੋ।" if language_code == "pa" else
                ("फवारणी करताना मास्क व हातमोजे वापरावेत." if language_code == "mr" else
                ("दवा छिड़कते समय मास्क और दस्ताने पहनें।" if language_code == "hi" else "Wear protective mask during spray.")))
            ])
            return extracted

        # Attempt 3: Meaningful line extraction (stripping structural tokens)
        meaningful_lines = [
            line.strip() for line in raw_text.split("\n")
            if line.strip() and line.strip() not in ("{", "}", "```", "```json", "[", "]")
        ]

        default_short = (
            "તમારા પાકમાં રોગ કે સમસ્યાનું સમયસર નિરીક્ષણ કરો." if language_code == "gu" else
            ("ਤੁਹਾਡੀ ਫ਼ਸਲ ਵਿੱਚ ਕੀੜਿਆਂ ਅਤੇ ਰੋਗਾਂ ਦਾ ਸਮੇਂ ਸਿਰ ਨਿਰੀਖਣ ਕਰੋ।" if language_code == "pa" else
            ("आपल्या पिकातील कीड व रोगांचे वेळेवर निरीक्षण करा." if language_code == "mr" else
            ("अपनी फसल में कीट व रोगों का समय पर निरीक्षण करें।" if language_code == "hi" else "Inspect your crop regularly for symptoms.")))
        )

        short_ans = meaningful_lines[0] if meaningful_lines else default_short
        detailed = "\n".join(meaningful_lines[1:]) if len(meaningful_lines) > 1 else short_ans

        # Strip remaining json key syntax if present
        short_ans = re.sub(r'^"[^"]+"\s*:\s*"?', "", short_ans).rstrip('",')
        detailed = re.sub(r'^"[^"]+"\s*:\s*"?', "", detailed).rstrip('",')

        if len(short_ans.strip()) < 15:
            short_ans = default_short

        return {
            "short_answer": short_ans,
            "detailed_explanation": detailed,
            "action_steps": ["Inspect crop leaves thoroughly", "Follow recommended spray timings"],
            "safety_precautions": ["Wear protective mask during spray"],
        }

    def _generate_offline_response(
        self,
        request: FarmerChatRequest,
        evidence_sources: List[EvidenceSource],
        language_code: str,
        crops: List[str],
        symptoms: List[str],
    ) -> Dict[str, Any]:
        """Deterministic, authoritative offline agronomic synthesizer in the requested native language."""
        crop_name = crops[0].title() if crops else (request.crop or "Crop")
        symptom_name = symptoms[0] if symptoms else "issue"

        # Evidence-grounded synthesis
        evidence_snippet = ""
        source_cite = ""
        if evidence_sources:
            evidence_snippet = evidence_sources[0].snippet
            source_cite = evidence_sources[0].document_name or evidence_sources[0].title

        if language_code == "gu":
            short_answer = (
                f"નમસ્તે ખેડૂત મિત્ર! તમારા {crop_name} પાકમાં તાત્કાલિક પગલાં:\n"
                f"1. ચૂસિયા જીવાત અને પીળાશ માટે લીમડાનું તેલ (1500 PPM) 40-50 મિલી પ્રતિ 15 લીટર પંપમાં ભેળવી છંટકાવ કરવો.\n"
                f"2. પાકમાં વધારે ભેજ ન રહે તે માટે પિયત નિયંત્રિત કરો.\n"
                f"3. ૧૯:૧૯:૧૯ ખાતરનો પર્ણ છંટકાવ કરી પાનનો પીળાશ દૂર કરો."
            )
            detailed = (
                f"તમારા {crop_name} પાકની સ્થિતિનું કૃષિ વિશ્લેષણ:\n"
                f"પાકમાં {symptom_name} પોષકતત્વોની ઉણપ (નાઈટ્રોજન/મેગ્નેશિયમ) અથવા ચૂસિયા જીવાતના ઉપદ્રવથી થાય છે. "
                f"જમીનમાં યોગ્ય વાયુસંચાર જાળવી રાખવો અને વધુ પડતો યુરિયા ખાતર આપવાનું ટાળવું. "
                f"જો ઉપદ્રવ વધુ હોય તો ભલામણ કરેલ કીટનાશકનો યોગ્ય માત્રામાં ઉપયોગ કરવો."
            )
            if evidence_snippet:
                detailed += f"\nસંદર્ભ વિગત ({source_cite}): {evidence_snippet}"
            action_steps = [
                "લીમડાના તેલનો (1500 PPM) સવારે 8 થી 10 વચ્ચે છંટકાવ કરો.",
                "જમીનમાં ભેજનું પ્રમાણ તપાસીને જ પિયત આપો.",
                "રાસાયણિક દવા વાપરતા પહેલા યોગ્ય માત્રા ચકાસો.",
            ]
            precautions = [
                "દવાનો છંટકાવ કરતી વખતે માસ્ક અને મોજા પહેરો.",
                "બપોરે કાળઝાળ ગરમીમાં છંટકાવ ન કરવો.",
            ]
        elif language_code == "hi":
            short_answer = (
                f"नमस्ते किसान भाई! आपकी {crop_name} फसल में तुरंत करें:\n"
                f"1. रसचूसक कीटों व पीलेपन हेतु नीम का तेल (1500 PPM) 40-50 मिली प्रति 15 लीटर पंप में मिलाकर छिड़कें।\n"
                f"2. खेत में जलभराव न होने दें और संतुलित सिंचाई करें।\n"
                f"3. 19:19:19 घुलनशील खाद का पर्ण छिड़काव करें।"
            )
            detailed = (
                f"{crop_name} फसल का समाधान:\n"
                f"फसल में {symptom_name} पोषण की कमी या रसचूसक कीटों के संक्रमण से हो सकता है। "
                f"पौधों को पर्याप्त धूप और वायु मिलना जरूरी है। अधिक यूरिया का प्रयोग न करें। "
                f"आवश्यकतानुसार अनुमोदित कीटनाशक का सही मात्रा में छिड़काव करें।"
            )
            if evidence_snippet:
                detailed += f"\nप्रमाणित संदर्भ ({source_cite}): {evidence_snippet}"
            action_steps = [
                "नीम तेल का छिड़काव सुबह या शाम के समय करें।",
                "खेत में उचित जलनिकासी की व्यवस्था रखें।",
                "संतुलित खाद (NPK) का ही प्रयोग करें।",
            ]
            precautions = [
                "छिड़काव के समय दस्ताने और मास्क का प्रयोग अनिवार्य रूप से करें।",
                "हवा के विपरीत दिशा में छिड़काव कभी न करें।",
            ]
        elif language_code == "pa":
            short_answer = (
                f"ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਿਸਾਨ ਵੀਰ! ਤੁਹਾਡੀ {crop_name} ਦੀ ਫ਼ਸਲ ਲਈ ਤੁਰੰਤ ਸਿਫ਼ਾਰਸ਼ਾਂ:\n"
                f"1. ਕੀੜਿਆਂ ਅਤੇ ਰੋਗਾਂ ਦੀ ਰੋਕਥਾਮ ਲਈ ਨਿੰਮ ਦਾ ਤੇਲ (1500 PPM) 40-50 ਮਿਲੀ ਪ੍ਰਤੀ 15 ਲੀਟਰ ਪੰਪ ਵਿੱਚ ਮਿਲਾ ਕੇ ਛਿੜਕਾਅ ਕਰੋ।\n"
                f"2. ਖੇਤ ਵਿੱਚ ਪਾਣੀ ਖੜ੍ਹਾ ਨਾ ਹੋਣ ਦਿਓ ਅਤੇ ਸੰਤੁਲਿਤ ਸਿੰਚਾਈ ਕਰੋ।\n"
                f"3. ਪੱਤਿਆਂ ਦੇ ਪੀਲੇਪਣ ਲਈ 19:19:19 ਘੁਲਣਸ਼ੀਲ ਖਾਦ ਦਾ ਛਿੜਕਾਅ ਕਰੋ।"
            )
            detailed = (
                f"{crop_name} ਫ਼ਸਲ ਦੀ ਸਥਿਤੀ ਦਾ ਖੇਤੀ ਵਿਸ਼ਲੇਸ਼ਣ:\n"
                f"ਫ਼ਸਲ ਵਿੱਚ {symptom_name} ਪੌਸ਼ਟਿਕ ਤੱਤਾਂ ਦੀ ਘਾਟ ਜਾਂ ਰਸ ਚੂਸਣ ਵਾਲੇ ਕੀੜਿਆਂ ਦੇ ਹਮਲੇ ਕਾਰਨ ਹੋ ਸਕਦਾ ਹੈ। "
                f"ਜ਼ਮੀਨ ਵਿੱਚ ਹਵਾ ਦਾ ਸੰਚਾਰ ਬਣਾਈ ਰੱਖੋ ਅਤੇ ਲੋੜ ਤੋਂ ਵੱਧ ਯੂਰੀਆ ਨਾ ਪਾਓ। "
                f"ਕੀੜਿਆਂ ਦਾ ਜ਼ਿਆਦਾ ਹਮਲਾ ਹੋਣ 'ਤੇ ਯੂਨੀਵਰਸਿਟੀ ਦੁਆਰਾ ਸਿਫ਼ਾਰਸ਼ ਕੀਤੀ ਗਈ ਦਵਾਈ ਦੀ ਹੀ ਵਰਤੋਂ ਕਰੋ।"
            )
            if evidence_snippet:
                detailed += f"\nਪ੍ਰਮਾਣਿਤ ਹਵਾਲਾ ({source_cite}): {evidence_snippet}"
            action_steps = [
                "ਨਿੰਮ ਦੇ ਤੇਲ ਦਾ ਛਿੜਕਾਅ ਸਵੇਰੇ ਜਾਂ ਸ਼ਾਮ ਸਮੇਂ ਕਰੋ।",
                "ਜ਼ਮੀਨ ਵਿੱਚ ਨਮੀ ਦੀ ਪਰਖ ਕਰਕੇ ਹੀ ਸਿੰਚਾਈ ਕਰੋ।",
                "ਰਸਾਇਣਕ ਦਵਾਈ ਦੀ ਵਰਤੋਂ ਤੋਂ ਪਹਿਲਾਂ ਸਹੀ ਮਾਤਰਾ ਯਕੀਨੀ ਬਣਾਓ।",
            ]
            precautions = [
                "ਸਪਰੇਅ ਕਰਦੇ ਸਮੇਂ ਦਸਤਾਨੇ ਅਤੇ ਮਾਸਕ ਜ਼ਰੂਰ ਪਹਿਨੋ।",
                "ਤੇਜ਼ ਹਵਾ ਜਾਂ ਦੁਪਹਿਰ ਦੀ ਗਰਮੀ ਵਿੱਚ ਸਪਰੇਅ ਨਾ ਕਰੋ।",
            ]
        elif language_code == "mr":
            short_answer = (
                f"नमस्कार शेतकरी मित्र! आपल्या {crop_name} पिकासाठी तातडीचे उपाय:\n"
                f"1. रसशोषक कीड व रोगांच्या नियंत्रणासाठी निंबोळी अर्क (1500 PPM) 40-50 मिली प्रति 15 लिटर पंपात मिसळून फवारणी करावी.\n"
                f"2. जमिनीत ओलावा तपासून योग्य प्रमाणात पाणी द्यावे, पाणी साचू देऊ नये.\n"
                f"3. पानांच्या पिवळेपणावर 19:19:19 विद्राव्य खताची फवारणी करावी."
            )
            detailed = (
                f"{crop_name} पिकाचे कृषी सल्लागार विश्लेषण:\n"
                f"पिकात {symptom_name} पोषणद्रव्यांची कमतरता किंवा रसशोषक किडींच्या प्रादुर्भावामुळे असू शकते. "
                f"जमिनीत हवा खेळती राहील याची काळजी घ्या आणि अतिरिक्त युरियाचा वापर टाळा. "
                f"प्रादुर्भाव जास्त असल्यास कृषी विद्यापीठाने शिफारस केलेल्या औषधांचाच योग्य प्रमाणात वापर करावा."
            )
            if evidence_snippet:
                detailed += f"\nप्रमाणित संदर्भ ({source_cite}): {evidence_snippet}"
            action_steps = [
                "निंबोळी अर्काची फवारणी सकाळी किंवा संध्याकाळी करावी.",
                "जमिनीतील ओलावा तपासूनच सिंचन करावे.",
                "रासायनिक औषध वापरताना योग्य प्रमाण तपासावे.",
            ]
            precautions = [
                "फवारणी करताना मास्क आणि हातमोजे वापरावेत.",
                "दुपारी कडक उन्हात फवारणी करू नये.",
            ]
        elif language_code == "bn":
            short_answer = (
                f"নমস্কার কৃষক বন্ধু! আপনার {crop_name} ফসলের জন্য জরুরি পরামর্শ:\n"
                f"১. পোকা ও পাতার হলুদভাব দূর করতে নিম তেল (1500 PPM) প্রতি ১৫ লিটার স্প্রে পাম্পে ৪০-৫০ মিলি মিশিয়ে স্প্রে করুন।\n"
                f"২. জমিতে পরিমিত সেচ দিন এবং অতিরিক্ত ইউরিয়া প্রয়োগ এড়িয়ে চলুন।\n"
                f"৩. প্রয়োজনীয় সুষম পুষ্টির জন্য ১৯:১৯:১৯ সার স্প্রে করুন।"
            )
            detailed = (
                f"{crop_name} ফসলের জন্য বিশদ কৃষি পরামর্শ:\n"
                f"ফসলে {symptom_name} লক্ষণ দেখা দিলে জমিতে সঠিক নিষ্কাশন বজায় রাখুন এবং নিয়মিত পরিদর্শন করুন। "
                f"কীটনাশক ব্যবহারের সময় সর্বদা সঠিক সতর্কতা ও অনুমোদিত মাত্রা বজায় রাখুন।"
            )
            if evidence_snippet:
                detailed += f"\nতথ্যসূত্র ({source_cite}): {evidence_snippet}"
            action_steps = [
                "সকাল বা বিকেলে নিম তেল স্প্রে করুন।",
                "১৫ লিটার স্প্রে পাম্পের নির্ধারিত মাত্রা মেনে চলুন।",
                "অতিরিক্ত জল জমা হতে দেবেন না।",
            ]
            precautions = [
                "কীটনাশক প্রয়োগের সময় মাস্ক ও দস্তানা পরুন।",
                "কড়া রোদে স্প্রে করবেন না।",
            ]
        elif language_code == "te":
            short_answer = (
                f"నమస్కారం రైతు మిత్రమా! మీ {crop_name} పంటకు తక్షణ చర్యలు:\n"
                f"1. రసం పీల్చే పురుగుల నివారణకు వేప నూనె (1500 PPM) 40-50 మి.లీ.ను 15 లీటర్ల స్ప్రే పంపు నీటిలో కలిపి పిచికారీ చేయండి.\n"
                f"2. పొలంలో నీరు నిల్వ ఉండకుండా చూసుకోండి.\n"
                f"3. ఆకుల పసుపు రంగును నివారించడానికి 19:19:19 ఎరువును పిచికారీ చేయండి."
            )
            detailed = (
                f"{crop_name} పంట సమగ్ర యాజమాన్యం:\n"
                f"పంటలో {symptom_name} సంకేతాలు ఉన్నప్పుడు సమతుల్య పోషకాలు అందించడం ముఖ్యం. "
                f"అధిక మోతాదులో యూరియా వాడకండి. సమస్య కొనసాగితే స్థానిక కృషి విజ్ఞాన కేంద్రాన్ని (KVK) సంప్రదించండి."
            )
            if evidence_snippet:
                detailed += f"\nఆధారం ({source_cite}): {evidence_snippet}"
            action_steps = [
                "ఉదయం లేదా సాయంత్రం వేళల్లో వేప నూనె పిచికారీ చేయండి.",
                "15 లీటర్ల స్ప్రే పంపు ప్రామాణిక కొలత పాటించండి.",
                "సమతుల్య ఎరువులను మాత్రమే వాడండి.",
            ]
            precautions = [
                "పిచికారీ చేసేటప్పుడు రక్షణ ముసుగు మరియు చేతి తొడుగులు ధరించండి.",
                "తీవ్రమైన ఎండలో మందులను పిచికారీ చేయవద్దు.",
            ]
        elif language_code == "ta":
            short_answer = (
                f"வணக்கம் விவசாய தோழரே! உங்கள் {crop_name} பயிருக்கான உடனடி பரிந்துரைகள்:\n"
                f"1. சாறு உறிஞ்சும் பூச்சிகள் மற்றும் மஞ்சள் நிறத்திற்கு வேப்பெண்ணெய் (1500 PPM) 40-50 மி.லி.யை 15 லிட்டர் ஸ்ப்ரே பம்பில் கலந்து தெளிக்கவும்.\n"
                f"2. நிலத்தில் நீர் தேங்காமல் சீரான பாசனம் செய்யவும்.\n"
                f"3. 19:19:19 உரத்தை இலைவழியாக தெளிக்கவும்."
            )
            detailed = (
                f"{crop_name} பயிர் பாதுகாப்பு ஆலோசனை:\n"
                f"பயிரில் {symptom_name} ஊட்டச்சத்து பற்றாக்குறை அல்லது பூச்சி தாக்குதலால் ஏற்படலாம். "
                f"முறையான வடிகால் வசதி செய்து, பூச்சி மேலாண்மை நெறிமுறைகளைப் பின்பற்றவும்."
            )
            if evidence_snippet:
                detailed += f"\nசான்று ({source_cite}): {evidence_snippet}"
            action_steps = [
                "வேப்பெண்ணெயை காலை அல்லது மாலை வேளையில் தெளிக்கவும்.",
                "15 லிட்டர் ஸ்ப்ரே பம்ப் அளவினை தவறாமல் பின்பற்றவும்.",
                "சீரான பாசனத்தை உறுதி செய்யவும்.",
            ]
            precautions = [
                "மருந்து தெளிக்கும் போது முகக்கவசம் மற்றும் கையுறைகளை அணியுங்கள்.",
                "காற்றுக்கு எதிர் திசையில் தெளிக்காதீர்கள்.",
            ]
        elif language_code == "kn":
            short_answer = (
                f"ನಮಸ್ಕಾರ ರೈತ ಬಾಂಧವರೇ! ನಿಮ್ಮ {crop_name} ಬೆಳೆಗೆ ತಕ್ಷಣದ ಕ್ರಮಗಳು:\n"
                f"1. ರಸಹೀರುವ ಕೀಟಗಳ ನಿಯಂತ್ರಣಕ್ಕೆ ಬೇವಿನ ಎಣ್ಣೆ (1500 PPM) 40-50 ಮಿ.ಲೀ. ಅನ್ನು 15 ಲೀಟರ್ ಸ್ಪ್ರೇ ಪಂಪ್‌ನಲ್ಲಿ ಬೆರೆಸಿ ಸಿಂಪಡಿಸಿ.\n"
                f"2. ಹೊಲದಲ್ಲಿ ನೀರು ನಿಲ್ಲದಂತೆ ನೋಡಿಕೊಳ್ಳಿ.\n"
                f"3. ಎಲೆಗಳ ಹಳದಿ ಬಣ್ಣ ಹೋಗಲಾಡಿಸಲು 19:19:19 ಗೊಬ್ಬರ ಸಿಂಪಡಿಸಿ."
            )
            detailed = (
                f"{crop_name} ಬೆಳೆ ನಿರ್ವಹಣೆ ಸಲಹೆ:\n"
                f"ಬೆಳೆಯಲ್ಲಿ {symptom_name} ರೋಗಲಕ್ಷಣಗಳು ಪೋಷಕಾಂಶಗಳ ಕೊರತೆ ಅಥವಾ ಕೀಟಗಳಿಂದ ಬರಬಹುದು. "
                f"ಹೆಚ್ಚು ಯೂರಿಯಾ ಬಳಸಬೇಡಿ ಮತ್ತು ಶಿಫಾರಸು ಮಾಡಿದ ಪ್ರಮಾಣದಲ್ಲಿ ಮಾತ್ರ ಸಿಂಪಡಣೆ ಮಾಡಿ."
            )
            if evidence_snippet:
                detailed += f"\nಉಲ್ಲೇಖ ({source_cite}): {evidence_snippet}"
            action_steps = [
                "ಬೇವಿನ ಎಣ್ಣೆಯನ್ನು ಬೆಳಿಗ್ಗೆ ಅಥವಾ ಸಂಜೆ ಸಿಂಪಡಿಸಿ.",
                "15 ಲೀಟರ್ ಸ್ಪ್ರೇ ಪಂಪ್ ಪ್ರಮಾಣವನ್ನು ಕಡ್ಡಾಯವಾಗಿ ಪಾಲಿಸಿ.",
                "ಹೊಲವನ್ನು ನಿಯಮಿತವಾಗಿ ಪರಿಶೀಲಿಸಿ.",
            ]
            precautions = [
                "ಸಿಂಪಡಣೆ ಮಾಡುವಾಗ ಮಾಸ್ಕ್ ಮತ್ತು ಕೈಗವಸುಗಳನ್ನು ಧರಿಸಿ.",
                "ಬಿಸಿಲಿನ ತಾಪ ಹೆಚ್ಚಿರುವಾಗ ಔಷಧ ಸಿಂಪಡಿಸಬೇಡಿ.",
            ]
        else:
            short_answer = (
                f"Greetings! Recommended immediate actions for {crop_name} crop:\n"
                f"1. Spray Neem Oil (1500 PPM) at 40-50 ml per 15-liter spray pump for sucking pests.\n"
                f"2. Regulate field moisture and avoid over-irrigation.\n"
                f"3. Apply foliar NPK 19:19:19 to correct leaf yellowing."
            )
            detailed = (
                f"Detailed Agronomic Advisory for {crop_name}:\n"
                f"The symptoms frequently arise from nutrient imbalance or sucking pest activity. "
                f"Ensure proper drainage and inspect the underside of leaves for early pest activity. "
                f"Follow official University/KVK guidelines for balanced protection."
            )
            if evidence_snippet:
                detailed += f"\nVerified Reference ({source_cite}): {evidence_snippet}"
            action_steps = [
                "Apply organic Neem oil in early morning or late evening.",
                "Ensure balanced soil aeration and drainage.",
                "Consult local KVK agronomist if symptoms persist beyond 4 days.",
            ]
            precautions = [
                "Always wear protective gear and face mask while applying treatments.",
                "Do not spray during windy conditions or strong midday sunlight.",
            ]

        return {
            "short_answer": short_answer,
            "detailed_explanation": detailed,
            "action_steps": action_steps,
            "safety_precautions": precautions,
        }
