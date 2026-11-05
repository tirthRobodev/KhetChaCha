from dataclasses import dataclass
from typing import Dict, Optional, Tuple, List


@dataclass(frozen=True)
class LanguageInfo:
    code: str                  # ISO 639-1 or 639-2/3
    name: str                  # English name
    native_name: str           # Native script representation
    script: str                # Primary writing script
    unicode_ranges: Tuple[Tuple[int, int], ...]  # Tuple of (start, end) codepoints


# All 22 8th Schedule Indian Languages + English
SCHEDULED_INDIAN_LANGUAGES: Dict[str, LanguageInfo] = {
    "as": LanguageInfo(
        code="as",
        name="Assamese",
        native_name="অসমীয়া",
        script="Bengali-Assamese",
        unicode_ranges=((0x0980, 0x09FF),)
    ),
    "bn": LanguageInfo(
        code="bn",
        name="Bengali",
        native_name="বাংলা",
        script="Bengali",
        unicode_ranges=((0x0980, 0x09FF),)
    ),
    "brx": LanguageInfo(
        code="brx",
        name="Bodo",
        native_name="बड़ो",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "doi": LanguageInfo(
        code="doi",
        name="Dogri",
        native_name="डोगरी",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "gu": LanguageInfo(
        code="gu",
        name="Gujarati",
        native_name="ગુજરાતી",
        script="Gujarati",
        unicode_ranges=((0x0A80, 0x0AFF),)
    ),
    "hi": LanguageInfo(
        code="hi",
        name="Hindi",
        native_name="हिन्दी",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "kn": LanguageInfo(
        code="kn",
        name="Kannada",
        native_name="ಕನ್ನಡ",
        script="Kannada",
        unicode_ranges=((0x0C80, 0x0CFF),)
    ),
    "ks": LanguageInfo(
        code="ks",
        name="Kashmiri",
        native_name="کٲشُر",
        script="Perso-Arabic",
        unicode_ranges=((0x0600, 0x06FF), (0x0750, 0x077F), (0x08A0, 0x08FF))
    ),
    "kok": LanguageInfo(
        code="kok",
        name="Konkani",
        native_name="कोंकणी",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "mai": LanguageInfo(
        code="mai",
        name="Maithili",
        native_name="मैथिली",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "ml": LanguageInfo(
        code="ml",
        name="Malayalam",
        native_name="മലയാളം",
        script="Malayalam",
        unicode_ranges=((0x0D00, 0x0D7F),)
    ),
    "mni": LanguageInfo(
        code="mni",
        name="Manipuri",
        native_name="ꯃꯤꯇꯩꯂꯣꯟ",
        script="Meetei Mayek",
        unicode_ranges=((0xABC0, 0xABFF), (0x0980, 0x09FF))
    ),
    "mr": LanguageInfo(
        code="mr",
        name="Marathi",
        native_name="मराठी",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "ne": LanguageInfo(
        code="ne",
        name="Nepali",
        native_name="नेपाली",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "or": LanguageInfo(
        code="or",
        name="Odia",
        native_name="ଓଡ଼ିଆ",
        script="Odia",
        unicode_ranges=((0x0B00, 0x0B7F),)
    ),
    "pa": LanguageInfo(
        code="pa",
        name="Punjabi",
        native_name="ਪੰਜਾਬੀ",
        script="Gurmukhi",
        unicode_ranges=((0x0A00, 0x0A7F),)
    ),
    "sa": LanguageInfo(
        code="sa",
        name="Sanskrit",
        native_name="संस्कृतम्",
        script="Devanagari",
        unicode_ranges=((0x0900, 0x097F),)
    ),
    "sat": LanguageInfo(
        code="sat",
        name="Santali",
        native_name="ᱥᱟᱱᱛᱟᱲᱤ",
        script="Ol Chiki",
        unicode_ranges=((0x1C50, 0x1C7F),)
    ),
    "sd": LanguageInfo(
        code="sd",
        name="Sindhi",
        native_name="سنڌي",
        script="Perso-Arabic",
        unicode_ranges=((0x0600, 0x06FF), (0x0750, 0x077F), (0x0900, 0x097F))
    ),
    "ta": LanguageInfo(
        code="ta",
        name="Tamil",
        native_name="தமிழ்",
        script="Tamil",
        unicode_ranges=((0x0B80, 0x0BFF),)
    ),
    "te": LanguageInfo(
        code="te",
        name="Telugu",
        native_name="తెలుగు",
        script="Telugu",
        unicode_ranges=((0x0C00, 0x0C7F),)
    ),
    "ur": LanguageInfo(
        code="ur",
        name="Urdu",
        native_name="اردو",
        script="Perso-Arabic",
        unicode_ranges=((0x0600, 0x06FF), (0x0750, 0x077F), (0x08A0, 0x08FF))
    ),
    "en": LanguageInfo(
        code="en",
        name="English",
        native_name="English",
        script="Latin",
        unicode_ranges=((0x0020, 0x007F),)
    ),
}


# Alias for backward and forward compatibility
SUPPORTED_LANGUAGES = SCHEDULED_INDIAN_LANGUAGES


def get_language_by_code(code: str) -> LanguageInfo:
    """Gets LanguageInfo by code or returns Gujarati as sensible default."""
    info = get_language_info(code)
    if info:
        return info
    return SCHEDULED_INDIAN_LANGUAGES.get("gu", SCHEDULED_INDIAN_LANGUAGES["en"])


def get_language_info(code_or_name: str) -> Optional[LanguageInfo]:
    """Look up language info by code or case-insensitive English name."""
    clean = code_or_name.strip().lower()
    if clean in SCHEDULED_INDIAN_LANGUAGES:
        return SCHEDULED_INDIAN_LANGUAGES[clean]
    for info in SCHEDULED_INDIAN_LANGUAGES.values():
        if info.name.lower() == clean or info.native_name == code_or_name.strip():
            return info
    return None


def get_supported_language_codes() -> List[str]:
    """List of all 22 scheduled Indian language codes + 'en'."""
    return list(SCHEDULED_INDIAN_LANGUAGES.keys())


def get_language_display_name(code: str) -> str:
    """Returns English display name for language code."""
    info = get_language_info(code)
    return info.name if info else "Gujarati"


def normalize_language_code(code: str) -> str:
    """Normalizes input code to supported language code, defaulting to 'gu'."""
    if not code or code.strip().lower() in ("auto", ""):
        return "gu"
    info = get_language_info(code)
    return info.code if info else "gu"
