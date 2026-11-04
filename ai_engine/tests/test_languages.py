"""Unit tests for Phase 4 Multilingual Engine (22 Scheduled Indian Languages + English)."""

import pytest
from ai_engine.language_engine.language_mapper import (
    SCHEDULED_INDIAN_LANGUAGES,
    get_language_by_code,
    get_language_info,
    get_supported_language_codes,
)
from ai_engine.language_engine.language_detector import LanguageDetector
from ai_engine.language_engine.regional_vocabulary import (
    CROP_VOCABULARY,
    SYMPTOM_VOCABULARY,
    expand_query_terms,
    identify_query_attributes,
)
from ai_engine.language_engine.response_language import (
    ResponseLanguageFormatter,
    get_response_instruction,
)


def test_all_22_scheduled_languages_plus_english_present():
    """Confirms all 22 8th Schedule Indian languages and English are cataloged."""
    expected_codes = {
        "as", "bn", "brx", "doi", "gu", "hi", "kn", "ks", "kok", "mai",
        "ml", "mni", "mr", "ne", "or", "pa", "sa", "sat", "sd", "ta", "te", "ur", "en"
    }
    actual_codes = set(get_supported_language_codes())
    assert expected_codes.issubset(actual_codes), f"Missing language codes: {expected_codes - actual_codes}"
    assert len(actual_codes) >= 23


def test_language_lookups():
    """Tests case-insensitive code and name lookups."""
    guj_info = get_language_info("gu")
    assert guj_info is not None
    assert guj_info.name == "Gujarati"
    assert guj_info.native_name == "ગુજરાતી"
    assert guj_info.script == "Gujarati"

    hindi_info = get_language_info("Hindi")
    assert hindi_info is not None
    assert hindi_info.code == "hi"

    punjabi_info = get_language_by_code("pa")
    assert punjabi_info.name == "Punjabi"
    assert punjabi_info.script == "Gurmukhi"


def test_language_detector_indic_scripts():
    """Tests language detection across multiple Indian scripts."""
    # Gujarati
    assert LanguageDetector.detect_language("મારા કપાસના પાંદડા પીળા કેમ પડે છે?") == "gu"

    # Hindi
    assert LanguageDetector.detect_language("मेरी कपास की फसल में पत्तियां पीली हो रही हैं") == "hi"

    # Punjabi (Gurmukhi)
    assert LanguageDetector.detect_language("ਮੇਰੇ ਨਰਮੇ ਦੇ ਪੱਤੇ ਪੀਲੇ ਪੈ ਰਹੇ ਹਨ") == "pa"

    # Tamil
    assert LanguageDetector.detect_language("பருத்தி இலைகள் மஞ்சள் நிறமாக மாறுகின்றன") == "ta"

    # Bengali
    assert LanguageDetector.detect_language("তুলার পাতা হলুদ হয়ে যাচ্ছে") == "bn"

    # English
    assert LanguageDetector.detect_language("Why are my cotton leaves turning yellow?") == "en"


def test_regional_vocabulary_attribute_identification():
    """Tests taxonomy extraction for crops, symptoms, and actions."""
    gu_text = "કપાસમાં ગુલાબી ઈયળ આવી ગઈ છે અને પાન પીળા પડે છે"
    attrs = identify_query_attributes(gu_text)

    assert "Cotton" in attrs["crops"]
    assert "pink_bollworm" in attrs["symptoms"]
    assert "leaf_yellowing" in attrs["symptoms"]


def test_regional_query_expansion():
    """Tests that regional terms expand to canonical English keywords."""
    expanded = expand_query_terms("કપાસ પાન પીળા")
    assert "cotton" in expanded.lower()
    assert "yellow" in expanded.lower() or "chlorosis" in expanded.lower()


def test_response_language_formatting_directives():
    """Tests system prompt directives for languages."""
    gu_dir = ResponseLanguageFormatter.get_language_system_directive("gu")
    assert "Gujarati" in gu_dir
    assert "ગુજરાતી" in gu_dir

    en_dir = ResponseLanguageFormatter.get_language_system_directive("en")
    assert "English" in en_dir

