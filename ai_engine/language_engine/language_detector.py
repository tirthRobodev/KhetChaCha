from typing import Tuple, Dict, Optional
from .language_mapper import SCHEDULED_INDIAN_LANGUAGES, LanguageInfo, get_language_info


# Marker words for Devanagari regional language disambiguation
DEVANAGARI_MARKERS: Dict[str, Tuple[str, ...]] = {
    "mr": ("आहे", "नाही", "पिकात", "पिक", "शेतकरी", "कशी", "करावे", "झाले", "औषध", "फवारणी", "बोंडअळी"),
    "ne": ("छ", "छैन", "गर्ने", "हुन्छ", "भने", "गर्नुहोस्"),
    "mai": ("अछि", "होइछ", "करब", "हमरा", "तोहर", "गेल", "छै"),
    "sa": ("अस्ति", "भवति", "कृषि", "पादपस्य", "रोगः", "करोतु"),
    "kok": ("आसा", "ना", "करचें", "शेतकार", "झाડ"),
    "doi": ("ऐ", "नेईं", "कन्ने", "कीता"),
    "brx": ("दं", "गैया", "हाबनाय", "आबाद"),
    "hi": ("है", "हैं", "क्या", "करें", "इस्तेमाल", "कीटनाशक", "फसल", "पत्ते", "उपाय", "पानी", "खाद", "की", "का", "के", "में", "हो", "रही", "रहा")
}

# Assamese distinct characters in Eastern Nagari script
ASSAMESE_CHARS = {"ৰ", "ৱ"}

# Kashmiri distinct characters in Perso-Arabic script
KASHMIRI_CHARS = {"ؠ", "ۄ", "ؽ"}

# Sindhi distinct characters in Perso-Arabic script
SINDHI_CHARS = {"ڄ", "ڃ", "ڳ", "ڱ", "ڏ", "ڦ", "ٻ", "ٽ", "ٺ", "ٿ", "ڀ"}


class LanguageDetector:
    """
    High-accuracy, zero-external-dependency language detector
    engineered specifically for all 22 Indian scheduled languages + English.
    """

    @classmethod
    def detect_language(cls, text: str) -> str:
        """Convenience classmethod returning ISO language code."""
        code, _, _ = cls().detect(text)
        return code

    def detect(self, text: str) -> Tuple[str, str, float]:
        """
        Detects language from input text.
        Returns: (language_code, language_name, confidence_score)
        """
        if not text or not text.strip():
            return "en", "English", 1.0

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
            return "en", "English", 1.0

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
            # Check for Assamese unique letters 'ৰ' (U+09F0) or 'ৱ' (U+09F1)
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
            words = clean_text.split()
            word_set = set(words)

            scores: Dict[str, int] = {}
            for lang, markers in DEVANAGARI_MARKERS.items():
                match_count = sum(1 for m in markers if m in word_set or (len(m) >= 4 and m in clean_text))
                scores[lang] = match_count

            # If a distinct non-Hindi regional language has more matches than Hindi, use it
            best_lang = max(scores, key=scores.get)
            if scores[best_lang] > 0 and best_lang != "hi" and scores[best_lang] > scores.get("hi", 0):
                info = get_language_info(best_lang)
                name = info.name if info else best_lang
                return best_lang, name, max(0.85, confidence)

            return "hi", "Hindi", max(0.85, confidence)

        # Latin fallback -> English
        return "en", "English", confidence


# Global Singleton
detector = LanguageDetector()
language_detector = detector
