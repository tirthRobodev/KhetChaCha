from typing import Tuple, Dict, Optional
from .language_mapper import SCHEDULED_INDIAN_LANGUAGES, LanguageInfo, get_language_info


# Marker words for Devanagari regional language disambiguation
DEVANAGARI_MARKERS: Dict[str, Tuple[str, ...]] = {
    "mr": (
        "आहे", "आहेत", "नाही", "नाहीत", "काय", "कसे", "कशी", "कसा", "कधी",
        "करावे", "करावी", "करावा", "करायचे", "पिकाला", "पिकावर", "पिकात", "पिकांची", "पिकाचे", "पिक",
        "शेतकरी", "शेती", "फवारणी", "औषध", "औषधे", "खत", "खते", "माती", "किड", "कीड",
        "माशी", "अळी", "बोंडअळी", "द्यावे", "द्यावी", "लागेल", "होईल", "झाले", "झाली", "झाला",
        "त्यासाठी", "यासाठी", "करू", "करा", "कापूस", "गहू", "भात", "भुईमूग", "सोयाबीन", "ऊस", "मका",
        "पाणी", "ठिबक", "सिंचन"
    ),
    "hi": (
        "है", "हैं", "नहीं", "क्या", "कैसे", "कैसा", "कैसी", "कब", "करें", "करे", "करना", "करूं",
        "फसल", "फसलों", "किसान", "खेती", "छिड़काव", "दवा", "दवाई", "खाद", "मिट्टी", "कीट", "कीड़ा",
        "मक्खी", "सुंडी", "दें", "देना", "लगेगा", "होगी", "होगा", "हुए", "हुई", "हुआ",
        "इसके", "उसके", "उपाय", "कपास", "गेहूं", "धान", "चावल", "मूंगफली", "गन्ना", "मक्का",
        "पानी", "सिंचाई"
    ),
    "ne": ("छ", "छैन", "गर्ने", "हुन्छ", "भने", "गर्नुहोस्"),
    "mai": ("अछि", "होइछ", "करब", "हमरा", "तोहर", "गेल", "छै"),
    "sa": ("अस्ति", "भवति", "कृषि", "पादपस्य", "रोगः", "करोतु"),
    "kok": ("आसा", "ना", "करचें", "शेतकार", "झाડ"),
    "doi": ("ऐ", "नेईं", "कन्ने", "कीता"),
    "brx": ("दं", "गैया", "हाबनाय", "आबाद"),
}

# Assamese distinct characters in Eastern Nagari script
ASSAMESE_CHARS = {"ৰ", "ৱ"}

# Kashmiri distinct characters in Perso-Arabic script
KASHMIRI_CHARS = {"ؠ", "ۄ", "ؽ"}

# Sindhi distinct characters in Perso-Arabic script
SINDHI_CHARS = {"ڄ", "ڃ", "ڳ", "ڱ", "ڏ", "ڦ", "ٻ", "ٽ", "ٺ", "ٿ", "ڀ"}


class LanguageDetector:
    """
    High-accuracy language detector engineered for KhetChacha's Tier 1 & Tier 2 languages
    (Gujarati, Hindi, English, Punjabi, Marathi) and all 22 Indian scheduled languages.
    """

    @classmethod
    def detect_language(cls, text: str, preferred_language: Optional[str] = None) -> str:
        """Convenience classmethod returning ISO language code."""
        code, _, _ = cls().detect(text, preferred_language=preferred_language)
        return code

    def detect(self, text: str, preferred_language: Optional[str] = None) -> Tuple[str, str, float]:
        """
        Detects language from input text using script analysis and linguistic context.
        Returns: (language_code, language_name, confidence_score)
        """
        if not text or not text.strip():
            fallback = preferred_language or "en"
            info = get_language_info(fallback)
            return fallback, info.name if info else fallback, 1.0

        clean_text = text.strip()

        # 1. Tally script character occurrences
        script_counts: Dict[str, int] = {
            "gujarati": 0,
            "devanagari": 0,
            "gurmukhi": 0,
            "bengali_assamese": 0,
            "tamil": 0,
            "telugu": 0,
            "kannada": 0,
            "malayalam": 0,
            "odia": 0,
            "ol_chiki": 0,
            "meetei_mayek": 0,
            "perso_arabic": 0,
            "latin": 0,
        }

        total_analyzed = 0

        for char in clean_text:
            cp = ord(char)

            if 0x0A80 <= cp <= 0x0AFF:
                script_counts["gujarati"] += 1
            elif 0x0900 <= cp <= 0x097F:
                script_counts["devanagari"] += 1
            elif 0x0A00 <= cp <= 0x0A7F:
                script_counts["gurmukhi"] += 1
            elif 0x0980 <= cp <= 0x09FF:
                script_counts["bengali_assamese"] += 1
            elif 0x0B80 <= cp <= 0x0BFF:
                script_counts["tamil"] += 1
            elif 0x0C00 <= cp <= 0x0C7F:
                script_counts["telugu"] += 1
            elif 0x0C80 <= cp <= 0x0CFF:
                script_counts["kannada"] += 1
            elif 0x0D00 <= cp <= 0x0D7F:
                script_counts["malayalam"] += 1
            elif 0x0B00 <= cp <= 0x0B7F:
                script_counts["odia"] += 1
            elif 0x1C50 <= cp <= 0x1C7F:
                script_counts["ol_chiki"] += 1
            elif (0xABC0 <= cp <= 0xABFF) or (0xAAE0 <= cp <= 0xAAFF):
                script_counts["meetei_mayek"] += 1
            elif (0x0600 <= cp <= 0x06FF) or (0x0750 <= cp <= 0x077F) or (0x08A0 <= cp <= 0x08FF):
                script_counts["perso_arabic"] += 1
            elif (0x0041 <= cp <= 0x005A) or (0x0061 <= cp <= 0x007A):
                script_counts["latin"] += 1
            else:
                continue
            total_analyzed += 1

        if total_analyzed == 0:
            fallback = preferred_language or "en"
            info = get_language_info(fallback)
            return fallback, info.name if info else fallback, 1.0

        dominant_script = max(script_counts, key=script_counts.get)
        count = script_counts[dominant_script]
        confidence = round(count / total_analyzed, 2)

        # 2. Script to Language Resolution
        if dominant_script == "gujarati":
            return "gu", "Gujarati", confidence

        elif dominant_script == "gurmukhi":
            return "pa", "Punjabi", confidence

        elif dominant_script == "tamil":
            return "ta", "Tamil", confidence

        elif dominant_script == "telugu":
            return "te", "Telugu", confidence

        elif dominant_script == "kannada":
            return "kn", "Kannada", confidence

        elif dominant_script == "malayalam":
            return "ml", "Malayalam", confidence

        elif dominant_script == "odia":
            return "or", "Odia", confidence

        elif dominant_script == "ol_chiki":
            return "sat", "Santali", confidence

        elif dominant_script == "meetei_mayek":
            return "mni", "Manipuri", confidence

        elif dominant_script == "bengali_assamese":
            if any(ch in clean_text for ch in ASSAMESE_CHARS):
                return "as", "Assamese", confidence
            return "bn", "Bengali", confidence

        elif dominant_script == "perso_arabic":
            if any(ch in clean_text for ch in KASHMIRI_CHARS):
                return "ks", "Kashmiri", confidence
            if any(ch in clean_text for ch in SINDHI_CHARS):
                return "sd", "Sindhi", confidence
            return "ur", "Urdu", confidence

        elif dominant_script == "devanagari":
            # 1. Unique Marathi letter check: 'ळ' (U+0933) is exclusively Marathi
            if "ळ" in clean_text:
                return "mr", "Marathi", max(0.95, confidence)

            words = clean_text.split()
            word_set = set(words)

            scores: Dict[str, int] = {}
            for lang, markers in DEVANAGARI_MARKERS.items():
                match_count = sum(1 for m in markers if m in word_set or (len(m) >= 4 and m in clean_text))
                scores[lang] = match_count

            mr_score = scores.get("mr", 0)
            hi_score = scores.get("hi", 0)

            # Linguistic context distinction for Marathi vs Hindi
            if mr_score > hi_score and mr_score > 0:
                return "mr", "Marathi", max(0.90, confidence)
            elif hi_score > mr_score and hi_score > 0:
                return "hi", "Hindi", max(0.90, confidence)

            # Check other Devanagari languages
            for lang in ["ne", "mai", "sa", "kok", "doi", "brx"]:
                if scores.get(lang, 0) > max(mr_score, hi_score, 0):
                    info = get_language_info(lang)
                    return lang, info.name if info else lang, max(0.85, confidence)

            # If scores tie or 0 markers found, prefer user's preferred language if it is Devanagari (mr/hi)
            if preferred_language in ("mr", "hi"):
                info = get_language_info(preferred_language)
                return preferred_language, info.name if info else preferred_language, max(0.80, confidence)

            return "hi", "Hindi", max(0.85, confidence)

        # Latin Script: Check for transliterations / code-mixed Gujlish, Hinglish, Marathi
        lower = clean_text.lower()
        if script_counts["latin"] > 0:
            # Gujlish
            if any(term in lower for term in ["khedut", "kapas", "khatar", "eeyad", "mavthu", "su karvu", "dava"]):
                return "gu", "Gujarati", 0.85
            # Hinglish
            if any(term in lower for term in ["kisan", "fasal", "keeda", "dawae", "paani", "gehu", "dhan", "kya kare"]):
                return "hi", "Hindi", 0.85
            # Romanized Marathi
            if any(term in lower for term in ["shetkari", "sheti", "favarni", "aushadh", "bondaali", "kay karave"]):
                return "mr", "Marathi", 0.85
            # Romanized Punjabi
            if any(term in lower for term in ["kheti", "sundi", "chitti makhi", "kanak", "jhona"]):
                return "pa", "Punjabi", 0.85

            if preferred_language and preferred_language != "auto":
                info = get_language_info(preferred_language)
                return preferred_language, info.name if info else preferred_language, confidence

        return "en", "English", confidence


# Global Singleton
detector = LanguageDetector()
language_detector = detector
