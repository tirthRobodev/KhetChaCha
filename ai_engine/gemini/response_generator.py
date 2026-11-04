"""Response generator orchestrating language, search, safety, and Gemini inference."""

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
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.safety.dosage_validator import DosageConsistencyValidator
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
    ):
        self.gemini_client = gemini_client
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
            "gemini_usage": self.gemini_client.get_usage_metrics() if hasattr(self.gemini_client, "get_usage_metrics") else {},
        }

    def generate_response(self, request: FarmerChatRequest) -> FarmerChatResponse:
        """Processes farmer request through language detection, retrieval, generation, and safety."""
        # 1. Determine language
        active_lang = request.language
        if not active_lang or active_lang == "auto":
            active_lang = LanguageDetector.detect_language(request.query)

        # Normalize language
        lang_info = get_language_by_code(active_lang)
        active_lang = lang_info.code

        # Check for personalized context (land size, session history, crop age, soil type)
        # Personalized advice must NEVER be cached or cross-served to unrelated farmers.
        is_personalized = bool(
            request.land_size
            or request.land_area
            or request.session_id
            or (request.crop_age_days and request.crop_age_days > 0)
            or request.soil_type
            or request.farmer_district
            or request.farmer_state
        )

        # Check safe in-memory cache for duplicate non-personalized queries (0 Gemini tokens consumed)
        clean_q = re.sub(r'[^a-zA-Z0-9\u0a80-\u0aff\u0900-\u097f]', '', request.query.lower())
        cache_key = f"{active_lang}:{request.crop or ''}:{clean_q}"
        if not is_personalized and cache_key in self._safe_cache:
            cached_resp, timestamp = self._safe_cache[cache_key]
            if time.time() - timestamp < 3600.0:
                self.cache_hits += 1
                logger.info("Safe Cache Hit: Returning verified advisory (0 Gemini tokens consumed)")
                return cached_resp
        self.cache_misses += 1

        # 2. Extract agronomic attributes
        attrs = identify_query_attributes(request.query)
        detected_crops = attrs.get("crops", [])
        detected_symptoms = attrs.get("symptoms", [])

        # 3. Check for severe ambiguity / lack of info
        if UncertaintyHandler.is_query_highly_ambiguous(request.query, detected_crops, detected_symptoms):
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
        orch_res = self.search_orchestrator.retrieve_evidence(
            query=request.query,
            crop=crop_target,
        )
        evidence_sources = orch_res.sources

        # 4b. Check for Cotton Leaf Yellowing or Single Ambiguous Symptom
        is_cotton_yellowing = (
            ("કપાસ" in request.query or "cotton" in request.query.lower())
            and any(term in request.query.lower() or term in request.query for term in ["પીળા", "લાલિયા", "yellow", "lalio", "yellowing"])
        )
        best_score = evidence_sources[0].confidence_score if evidence_sources else 0.0
        if is_cotton_yellowing or (UncertaintyHandler.is_single_ambiguous_symptom(request.query, detected_crops, detected_symptoms) and best_score < 0.60):
            self.deterministic_responses += 1
            diff_diag = UncertaintyHandler.generate_differential_diagnosis_response(
                query=request.query,
                language_code=active_lang,
                detected_crops=detected_crops or (["cotton"] if is_cotton_yellowing else []),
                detected_symptoms=detected_symptoms or (["leaf_yellowing"] if is_cotton_yellowing else []),
            )
            # Reconcile dosages to ensure authoritative consistency
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

        # 4c. Check for completely Insufficient Evidence across all tiers
        if not orch_res.is_evidence_sufficient and not evidence_sources:
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

        # 6. Generate Response (Gemini or Offline Fallback)
        raw_text = None
        if self.gemini_client.is_available:
            try:
                system_instruction = PromptBuilder.build_system_instruction(active_lang)
                prompt = PromptBuilder.build_chat_prompt(request, evidence_sources, conversation_history=history)
                raw_text = self.gemini_client.generate_content(prompt, system_instruction=system_instruction)
            except Exception as e:
                logger.warning(f"Gemini API call failed ({e}). Falling back gracefully to verified local agronomic synthesis.")
                raw_text = None

        # Parse or generate fallback if Gemini was offline or returned empty
        if raw_text:
            parsed_data = self._parse_gemini_output(raw_text, active_lang)
        else:
            parsed_data = self._generate_offline_response(request, evidence_sources, active_lang, detected_crops, detected_symptoms)

        # 7. Dosage Consistency & Safety Validation
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

        # 8. Record in multi-turn context
        if request.session_id:
            self.context_manager.add_user_message(request.session_id, request.query)
            self.context_manager.add_assistant_message(request.session_id, parsed_data["short_answer"])

        # Compute overall confidence
        base_confidence = 0.88 if raw_text else 0.72
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

        # Cache response for duplicate non-personalized query fast-path (0 Gemini tokens consumed)
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

        # Attempt 2: Regex field extraction
        extracted = {}
        short_m = re.search(r'"short_answer"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"', clean_text)
        if short_m:
            _rv = short_m.group(1)
            try:
                # Use json.loads to safely decode JSON string escapes (\n, \t, \uXXXX)
                # WITHOUT re-encoding the already-Unicode Python str as UTF-8 bytes.
                # The old bytes(...).decode("unicode_escape") call corrupted Gujarati text.
                extracted["short_answer"] = json.loads('"' + _rv + '"')
            except Exception:
                extracted["short_answer"] = _rv

        det_m = re.search(r'"detailed_explanation"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"', clean_text)
        if det_m:
            _rv = det_m.group(1)
            try:
                # Use json.loads to safely decode JSON string escapes (\n, \t, \uXXXX)
                # WITHOUT re-encoding the already-Unicode Python str as UTF-8 bytes.
                # The old bytes(...).decode("unicode_escape") call corrupted Gujarati text.
                extracted["detailed_explanation"] = json.loads('"' + _rv + '"')
            except Exception:
                extracted["detailed_explanation"] = _rv

        if extracted.get("short_answer") and len(extracted["short_answer"]) > 10:
            extracted.setdefault("detailed_explanation", extracted["short_answer"])
            extracted.setdefault("action_steps", ["ખેતરનું નિયમિત નિરીક્ષણ કરો." if language_code == "gu" else "Inspect field regularly."])
            extracted.setdefault("safety_precautions", ["દવા છાંટતી વખતે માસ્ક અને મોજા પહેરો." if language_code == "gu" else "Wear protective mask during spray."])
            return extracted

        # Attempt 3: Meaningful line extraction (stripping structural tokens)
        meaningful_lines = [
            line.strip() for line in raw_text.split("\n")
            if line.strip() and line.strip() not in ("{", "}", "```", "```json", "[", "]")
        ]
        
        short_ans = meaningful_lines[0] if meaningful_lines else "તમારા પાકમાં રોગ કે સમસ્યાનું સમયસર નિરીક્ષણ કરો."
        detailed = "\n".join(meaningful_lines[1:]) if len(meaningful_lines) > 1 else short_ans

        # Strip remaining json key syntax if present
        short_ans = re.sub(r'^"[^"]+"\s*:\s*"?', "", short_ans).rstrip('",')
        detailed = re.sub(r'^"[^"]+"\s*:\s*"?', "", detailed).rstrip('",')

        if len(short_ans.strip()) < 15:
            short_ans = "તમારા પાકમાં રોગ કે જીવાતની સમયસર ઓળખ કરી અધિકૃત કૃષિ ભલામણ મુજબ પગલાં લો."

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
        """Deterministic, authoritative offline agronomic synthesizer when Gemini is unconfigured or offline."""
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
                f"નમસ્તે ખેડૂત મિત્ર! તમારા {crop_name} પાકમાં {symptom_name} માટે તાત્કાલિક પગલાં:\n"
                f"1. લીમડાનું તેલ (1500 PPM) 40-50 મિલી પ્રતિ 15 લીટર પંપમાં ભેળવી છંટકાવ કરવો.\n"
                f"2. પાકમાં વધારે ભેજ ન રહે તે માટે પિયત નિયંત્રિત કરો.\n"
                f"3. લક્ષણો વધુ જણાય તો પ્રમાણિત બાયો-ફંગીસાઈડ અથવા KVK ની ભલામણ મુજબ જ દવા વાપરો."
            )
            detailed = (
                f"તમારા {crop_name} પાકની સ્થિતિનું વિશ્લેષણ:\n"
                f"પાકમાં {symptom_name} પોષકતત્વોની ઉણપ અથવા ભેજવાળા વાતાવરણમાં ફંગસના કારણે થાય છે. "
                f"જમીનમાં યોગ્ય વાયુસંચાર જાળવી રાખવો અને વધુ પડતો યુરિયા ખાતર આપવાનું ટાળવું. "
                f"જો ઉપદ્રવ વધુ હોય તો ટ્રાઈકોડર્મા વિરીડી (50 ગ્રામ / પંપ) નો ઉપયોગ જમીન અને મૂળિયાં પાસે કરવો. "
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
                f"नमस्ते किसान भाई! आपकी {crop_name} फसल में {symptom_name} के लिए तुरंत करें:\n"
                f"1. नीम का तेल (1500 PPM) 40-50 मिली प्रति 15 लीटर पंप में मिलाकर छिड़कें।\n"
                f"2. खेत में जलभराव न होने दें और संतुलित सिंचाई करें।\n"
                f"3. आवश्यकता पड़ने पर ही कृषि विशेषज्ञ या KVK की सलाह से दवा दें।"
            )
            detailed = (
                f"{crop_name} फसल का समाधान:\n"
                f"फसल में {symptom_name} पोषण की कमी या फंगल संक्रमण से हो सकता है। "
                f"पौधों को पर्याप्त धूप और वायु मिलना जरूरी है। अधिक यूरिया का प्रयोग न करें। "
                f"जड़ संबंधी रोग होने पर ट्राइकोडर्मा विरिडी (50 ग्राम प्रति पंप) का उपयोग करें।"
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
        else:
            short_answer = (
                f"Greetings! Recommended immediate actions for {symptom_name} in your {crop_name} crop:\n"
                f"1. Spray Neem Oil (1500 PPM) at 40-50 ml per 15-liter spray pump.\n"
                f"2. Regulate field moisture and avoid over-irrigation.\n"
                f"3. Use balanced micronutrients and avoid excess urea application."
            )
            detailed = (
                f"Detailed Agronomic Advisory for {crop_name}:\n"
                f"The symptoms ({symptom_name}) frequently arise from nutrient imbalance or microclimate humidity. "
                f"Ensure proper drainage and inspect the underside of leaves for early pest activity. "
                f"For root issues, consider bio-control agents like Trichoderma viride."
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

