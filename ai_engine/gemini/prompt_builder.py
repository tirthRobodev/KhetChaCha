"""Prompt construction engine for KhetChacha Farmer AI."""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from ai_engine.language_engine.language_mapper import get_language_by_code
from ai_engine.language_engine.response_language import ResponseLanguageFormatter
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.models.response_models import EvidenceSource
from ai_engine.safety.answer_validator import AnswerValidator


class PromptBuilder:
    """Builds structured system instructions and context-grounded prompts."""

    BASE_SYSTEM_INSTRUCTION = """You are KhetChacha (ખેતચાચા / खेतचाचा), an empathetic, deeply knowledgeable, and trusted Indian agricultural elder, agronomy expert, and Krishi Pandit.

CORE PERSONA & VOICE:
- Speak with warm respect, empathy, and practical wisdom directly to the farmer.
- Use regional agricultural terms naturally (e.g. jivaat, rog, chhadakav, khaatar, bigha, acre).
- Provide immediate, actionable field advice that a farmer standing in a field can execute today.

STRICT ANSWER ARCHITECTURE:
You MUST format your output as a valid JSON object matching this schema:
{
  "short_answer": "40 to 100 words in the requested target language. Direct, comforting, giving numbered priority action steps.",
  "detailed_explanation": "Thorough, structured explanation in the requested target language addressing EVERY requested topic (diagnosis, water, fertilizer, pest control, expenses, timeline). Use clear markdown headings with emojis.",
  "action_steps": ["Step 1...", "Step 2...", "Step 3..."],
  "safety_precautions": ["Precaution 1...", "Precaution 2..."],
  "sources_cited": ["Document or link reference..."]
}

STRICT GROUNDING & SAFETY RULES:
1. Ground your recommendations ONLY in the provided Evidence Knowledge Chunks and verified ICAR/KVK guidance.
2. DO NOT hallucinate pesticide dosages. If an exact dose is not verified in the evidence or CIBRC standards, specify standard organic neem oil (5 ml/liter) or advise consulting the local KVK.
3. NEVER recommend banned substances in India (e.g., Endosulfan, Monocrotophos on vegetables).
4. Always include practical PPE precautions (masks, gloves, wind direction) when spraying any agrochemical.
5. If the evidence does not have enough information to diagnose accurately, advise the farmer to take a clear photo of the leaf or root and contact the Kisan Call Centre (1800-180-1551).
"""

    @classmethod
    def build_system_instruction(cls, language_code: str) -> str:
        """Constructs system instruction with explicit Indic language directive."""
        lang_info = get_language_by_code(language_code)
        lang_directive = ResponseLanguageFormatter.get_language_system_directive(language_code)

        instruction = cls.BASE_SYSTEM_INSTRUCTION + f"\n\nTARGET LANGUAGE DIRECTIVE:\n{lang_directive}"
        return instruction

    @classmethod
    def build_chat_prompt(
        cls,
        request: FarmerChatRequest,
        evidence_sources: List[EvidenceSource],
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """Constructs the full user prompt containing context, query, and evidence."""
        prompt_parts: List[str] = []

        # 1. Farmer & Field Context
        prompt_parts.append("### FARMER & FIELD CONTEXT:")
        prompt_parts.append(f"- Farmer Query: \"{request.query}\"")
        prompt_parts.append(f"- Selected Language: {request.language}")

        decomp = AnswerValidator.decompose_query(request.query)

        crop_val = request.crop
        if not crop_val and "કપાસ" in request.query:
            crop_val = "Cotton (કપાસ)"
        if crop_val:
            prompt_parts.append(f"- Crop: {crop_val}")

        crop_age = request.crop_age_days or decomp.get("extracted_crop_age_days")
        if crop_age:
            prompt_parts.append(f"- Crop Age: {crop_age} days")

        if request.soil_type:
            prompt_parts.append(f"- Soil Type: {request.soil_type}")

        land_area = request.land_area or decomp.get("extracted_land_area")
        land_unit = request.land_unit or decomp.get("extracted_land_unit") or ("Acre" if not land_area else "")
        if land_area:
            prompt_parts.append(f"- Land Size: {land_area} {land_unit}")

        # Location Context
        loc_str = []
        if request.location:
            loc = request.location
            if loc.village: loc_str.append(f"Village: {loc.village}")
            if loc.taluka: loc_str.append(f"Taluka: {loc.taluka}")
            if loc.district: loc_str.append(f"District: {loc.district}")
            if loc.state: loc_str.append(f"State: {loc.state}")
            if loc.latitude and loc.longitude: loc_str.append(f"GPS: ({loc.latitude:.4f}, {loc.longitude:.4f})")

        if request.farmer_district and not any("District:" in s for s in loc_str):
            loc_str.append(f"District: {request.farmer_district}")
        if request.farmer_state and not any("State:" in s for s in loc_str):
            loc_str.append(f"State: {request.farmer_state}")

        if request.grounding:
            g_crop = request.grounding.get("detectedCrop")
            if g_crop and not crop_val:
                prompt_parts.append(f"- Grounding Crop: {g_crop}")
            g_dist = request.grounding.get("district")
            if g_dist and not any("District:" in s for s in loc_str):
                loc_str.append(f"District: {g_dist}")
            g_state = request.grounding.get("state")
            if g_state and not any("State:" in s for s in loc_str):
                loc_str.append(f"State: {g_state}")

        if loc_str:
            prompt_parts.append(f"- Location: {', '.join(loc_str)}")

        # Weather Context
        if request.weather:
            w = request.weather
            w_str = []
            if w.temperature_celsius is not None: w_str.append(f"Temp: {w.temperature_celsius}°C")
            if w.humidity_percent is not None: w_str.append(f"Humidity: {w.humidity_percent}%")
            if w.condition: w_str.append(f"Condition: {w.condition}")
            if w.rain_forecast: w_str.append(f"Rain Forecast: {w.rain_forecast}")
            if w_str:
                prompt_parts.append(f"- Weather: {', '.join(w_str)}")

        # 2. Conversation History (if multi-turn - preserving last 6 turns / 3 complete exchanges)
        if conversation_history:
            prompt_parts.append("\n### RECENT CONVERSATION HISTORY:")
            for turn in conversation_history[-6:]:
                role = turn.get("role", "user")
                content = turn.get("content", "")
                prompt_parts.append(f"- {role.capitalize()}: {content}")

        # 3. Multi-Part Query Decomposition Directives
        if decomp["is_multipart"]:
            prompt_parts.append("\n### MULTI-PART QUESTION REQUIREMENTS:")
            prompt_parts.append(
                "The farmer's question contains multiple distinct agricultural queries. "
                "You MUST comprehensively address EACH of the following requested topics in 'detailed_explanation':"
            )
            if decomp["has_pest_disease"]:
                prompt_parts.append("1. Pest & Disease Diagnosis and Safe Spray Chemical/Organic Control.")
            if decomp["has_water"]:
                prompt_parts.append("2. Irrigation & Water Scheduling for this stage of the crop.")
            if decomp["has_fertilizer"]:
                prompt_parts.append("3. Balanced Fertilizer Schedule and stage-specific dosage.")
            if decomp["has_cost"]:
                prompt_parts.append("4. Estimated Cost & Expenditure Breakdown (₹ for inputs, spray, and labor).")
            if decomp["has_timeline"]:
                prompt_parts.append("5. Structured 30-Day Stage Action Timeline.")

        # 4. Grounding Evidence
        prompt_parts.append("\n### VERIFIED AGRICULTURAL EVIDENCE SOURCES:")
        if evidence_sources:
            for idx, src in enumerate(evidence_sources[:3], 1):
                header = src.title or f"Source {idx}"
                if src.document_name:
                    header += f" (File: {src.document_name}, Page: {src.page_number})"
                elif src.url:
                    header += f" (URL: {src.url})"
                prompt_parts.append(f"\n[EVIDENCE {idx}] {header}")
                clean_snippet = src.snippet.strip()
                if len(clean_snippet) > 250:
                    clean_snippet = clean_snippet[:247] + "..."
                prompt_parts.append(f"Snippet: {clean_snippet}")
        else:
            prompt_parts.append("No specific external documents found. Use standard verified ICAR agronomic principles.")

        prompt_parts.append("\n### TASK:")
        prompt_parts.append(
            f"Generate your advice for the farmer in {get_language_by_code(request.language).name}. "
            f"Remember: Output ONLY valid JSON matching the requested schema. "
            f"Keep 'short_answer' strictly between 40 and 100 words with numbered action steps. "
            f"STRICT CONSISTENCY RULE: Never provide contradictory quantities between 'short_answer', 'action_steps', and 'detailed_explanation'. "
            f"If dosage is given, use the exact same verified concentration (e.g. 10 g/L or 150 g per 15L pump) across all sections."
        )

        return "\n".join(prompt_parts)
