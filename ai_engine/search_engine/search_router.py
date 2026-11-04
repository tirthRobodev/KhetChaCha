"""Query analysis, category classification, and search routing."""

from __future__ import annotations

import re
from typing import Any, Dict
from ai_engine.language_engine.regional_vocabulary import identify_query_attributes

PEST_DISEASE_KEYWORDS = {
    "pest", "disease", "insect", "worm", "aphid", "fungus", "wilt", "blight",
    "rot", "bollworm", "caterpillar", "whitefly", "curl", "yellowing",
    "ઇયળ", "જીવાત", "રોગ", "કાળિયો", "સુકારો", "મુંડા", "મોલો", "ઈયળ",
    "कीट", "रोग", "इल्ली", "झुलसा", "उकठा", "सुंडी", "माहू",
}

FERTILIZER_KEYWORDS = {
    "fertilizer", "urea", "dap", "npk", "potash", "zinc", "nutrient", "manure",
    "compost", "ખાતર", "યૂરિયા", "ડીએપી", "પોટાશ", "છાણિયું",
    "खाद", "उर्वरक", "यूरिया", "डीएपी", "पोटाश", "गोबर",
}

MARKET_KEYWORDS = {
    "mandi", "apmc", "price", "rate", "bhav", "msp", "market",
    "ભાવ", "મંડી", "બજાર", "ભાવો",
    "भाव", "मंडी", "बाजार", "दाम",
}

WEATHER_KEYWORDS = {
    "rain", "weather", "temperature", "forecast", "monsoon", "drought",
    "વરસાદ", "હવામાન", "તાપમાન",
    "बारिश", "मौसम", "तापमान", "मानसून",
}


class SearchRouter:
    """Categorizes agricultural queries and determines retrieval strategy."""

    @classmethod
    def classify_query(cls, query: str) -> Dict[str, Any]:
        """Analyzes query text to detect intent category, crop entities, and symptoms."""
        q_lower = query.lower()

        # Identify crop, symptom, and action entities from multilingual vocabulary
        attrs = identify_query_attributes(query)

        # Categorization logic using robust substring matching for Indic scripts
        category = "general_agriculture"
        confidence = 0.5

        if any(k in q_lower for k in PEST_DISEASE_KEYWORDS) or attrs.get("symptoms"):
            category = "pest_and_disease"
            confidence = 0.9
        elif any(k in q_lower for k in FERTILIZER_KEYWORDS) or "fertilizer" in attrs.get("actions", []):
            category = "soil_and_fertilizer"
            confidence = 0.85
        elif any(k in q_lower for k in MARKET_KEYWORDS):
            category = "market_and_pricing"
            confidence = 0.95
        elif any(k in q_lower for k in WEATHER_KEYWORDS) or "irrigation" in attrs.get("actions", []):
            category = "weather_and_irrigation"
            confidence = 0.85
            category = "weather_and_irrigation"
            confidence = 0.85

        # Decision on local search priority:
        # Pests, diseases, and fertilizers have deep coverage in ICAR/University PDF manuals
        prioritize_local = category in {"pest_and_disease", "soil_and_fertilizer", "general_agriculture"}

        return {
            "category": category,
            "confidence": confidence,
            "crops_detected": attrs.get("crops", []),
            "symptoms_detected": attrs.get("symptoms", []),
            "actions_detected": attrs.get("actions", []),
            "prioritize_local": prioritize_local,
        }
