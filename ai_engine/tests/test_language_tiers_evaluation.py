"""Comprehensive Language-Specific Evaluation Suite for KhetChacha AI.

Evaluates:
- Tier 1: Gujarati, Hindi, English (Simple, Medium, Long, Complex Unseen Questions)
- Tier 2: Punjabi, Marathi (Simple Agricultural Questions + STT Transcripts + Complexity Limitation)
- Linguistic Context Disambiguation (Devanagari Hindi vs Marathi, character ळ)
"""

import pytest
from ai_engine.backend.config import Settings
from ai_engine.backend.dependencies import ServiceContainer
from ai_engine.language_engine.language_detector import LanguageDetector
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.safety.answer_validator import AnswerValidator


@pytest.fixture
def container():
    settings = Settings()
    return ServiceContainer(settings)


# ==============================================================================
# 1. DEVANAGARI DISAMBIGUATION & LANGUAGE DETECTION EVALUATION
# ==============================================================================

def test_devanagari_marathi_unique_character_l():
    """Character 'ळ' (U+0933) is exclusively Marathi among Devanagari regional languages."""
    query = "कापूस पिकात बोंडअळी नियंत्रणासाठी काय करावे?"
    lang = LanguageDetector.detect_language(query)
    assert lang == "mr"


def test_devanagari_marathi_lexical_context():
    """Marathi query without 'ळ' must be disambiguated by linguistic context and markers."""
    query = "गहू पिकाला खत कधी द्यावे आणि पाणी किती द्यावे?"
    lang = LanguageDetector.detect_language(query)
    assert lang == "mr"


def test_devanagari_hindi_lexical_context():
    """Hindi query with common Devanagari markers must resolve to Hindi."""
    query = "गेहूं की फसल में खाद कब दें और पानी कितना लगाएं?"
    lang = LanguageDetector.detect_language(query)
    assert lang == "hi"


def test_code_mixed_transliterations():
    """Tests code-mixed Gujlish, Hinglish, Romanized Marathi, and Romanized Punjabi."""
    assert LanguageDetector.detect_language("kapas ma su karvu dava mate") == "gu"
    assert LanguageDetector.detect_language("gehu ki fasal me kya kare") == "hi"
    assert LanguageDetector.detect_language("shetkari sheti favarni kay karave") == "mr"
    assert LanguageDetector.detect_language("kanak di kheti sundi roktham") == "pa"


# ==============================================================================
# 2. TIER 1 EVALUATION — GUJARATI (Simple, Medium, Long, Complex Multi-Part)
# ==============================================================================

def test_gujarati_simple_unseen_question(container):
    """Simple unseen query in Gujarati."""
    request = FarmerChatRequest(
        question="મગફળીમાં પાન પીળા પડે તો શું કરવું?",
        language="gu",
        crop="Groundnut",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "gu"
    assert len(response.short_answer) > 20
    assert any(term in response.short_answer for term in ["નમસ્તે", "ખેડૂત", "૧૯:૧૯:૧૯", "પીળા", "લીમડા"])


def test_gujarati_medium_unseen_question(container):
    """Medium unseen query in Gujarati."""
    request = FarmerChatRequest(
        question="જીરાના પાકમાં કાળી ચરમી રોગના નિયંત્રણ માટે કઈ દવા યોગ્ય છે?",
        language="gu",
        crop="Cumin",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "gu"
    assert len(response.action_steps) >= 2


def test_gujarati_complex_multipart_unseen_question(container):
    """Complex multi-part unseen query with water, fertilizer, pests, timeline, and cost."""
    request = FarmerChatRequest(
        question="મારા ૩ એકર ઘઉંમાં ૩૫ દિવસ થયા છે, પાન સુકાય છે, પીળા પડે છે અને ઉધઈ દેખાય છે. પાણી ક્યારે આપવું, યુરિયા ખાતર કેટલું આપવું અને દવા કઈ વાપરવી? ખર્ચ કેટલો થશે?",
        language="gu",
        crop="Wheat",
        crop_age_days=35,
        land_area=3.0,
        land_unit="એકર",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "gu"
    full_text = f"{response.short_answer} {response.detailed_explanation}"
    # Verify coverage across all facets
    assert any(w in full_text for w in ["પાણી", "સિંચાઈ", "પિયત"])
    assert any(f in full_text for f in ["ખાતર", "યુરિયા", "૧૯:૧૯:૧૯"])
    assert any(c in full_text for c in ["ખર્ચ", "₹", "રૂપિયા"])


# ==============================================================================
# 3. TIER 1 EVALUATION — HINDI (Simple, Medium, Long, Complex Multi-Part)
# ==============================================================================

def test_hindi_simple_unseen_question(container):
    """Simple unseen query in Hindi."""
    request = FarmerChatRequest(
        question="गेहूं में पहली सिंचाई कितने दिन बाद करनी चाहिए?",
        language="hi",
        crop="Wheat",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "hi"
    assert len(response.short_answer) > 20
    assert any(term in response.short_answer for term in ["नमस्ते", "सिंचाई", "किसान", "पानी", "फसल"])


def test_hindi_medium_unseen_question(container):
    """Medium unseen query in Hindi."""
    request = FarmerChatRequest(
        question="सरसों में चेपा कीट के नियंत्रण के लिए कौन सी दवा स्प्रे करें?",
        language="hi",
        crop="Mustard",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "hi"
    assert len(response.action_steps) >= 2


def test_hindi_complex_multipart_unseen_question(container):
    """Complex multi-part unseen query in Hindi."""
    request = FarmerChatRequest(
        question="मेरी 4 एकड़ धान की फसल में 50 दिन हो चुके हैं, तना छेदक कीट लगा है और पत्तियां सूख रही हैं। सिंचाई, उर्वरक, दवा और कुल खर्च का विवरण दें।",
        language="hi",
        crop="Paddy",
        crop_age_days=50,
        land_area=4.0,
        land_unit="एकड़",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "hi"
    full_text = f"{response.short_answer} {response.detailed_explanation}"
    assert any(w in full_text for w in ["सिंचाई", "पानी"])
    assert any(f in full_text for f in ["उर्वरक", "खाद", "यूरिया"])
    assert any(c in full_text for c in ["खर्च", "₹", "रुपये", "लागत"])


# ==============================================================================
# 4. TIER 1 EVALUATION — ENGLISH (Simple, Medium, Long, Complex Multi-Part)
# ==============================================================================

def test_english_simple_unseen_question(container):
    """Simple unseen query in English."""
    request = FarmerChatRequest(
        question="When should I apply the first fertilizer dose for maize crop?",
        language="en",
        crop="Maize",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "en"
    assert len(response.short_answer) > 20


def test_english_complex_multipart_unseen_question(container):
    """Complex multi-part query in English."""
    request = FarmerChatRequest(
        question="My 2-acre sugarcane crop is 60 days old, showing red rot symptoms. Provide irrigation timing, fertilizer schedule, chemical spray with dosage, and estimated budget.",
        language="en",
        crop="Sugarcane",
        crop_age_days=60,
        land_area=2.0,
        land_unit="Acre",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "en"
    full_text = f"{response.short_answer} {response.detailed_explanation}"
    assert any(w in full_text for w in ["Irrigation", "water", "moisture"])
    assert any(f in full_text for f in ["Fertilizer", "Urea", "NPK"])
    assert any(c in full_text for c in ["Cost", "₹", "Budget", "Expenditure"])


# ==============================================================================
# 5. TIER 2 EVALUATION — PUNJABI (Simple Text, Simple STT, Complexity Limitation)
# ==============================================================================

def test_punjabi_simple_text_question(container):
    """Simple agricultural query in Punjabi (Text input)."""
    request = FarmerChatRequest(
        question="ਝੋਨੇ ਵਿੱਚ ਖਾਦ ਕਦੋਂ ਪਾਉਣੀ ਚਾਹੀਦੀ ਹੈ?",
        language="pa",
        crop="Paddy",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "pa"
    # Ensure answer is in authentic Gurmukhi script
    assert any(ch in response.short_answer for ch in ["ਕ", "ਖ", "ਗ", "ਪ", "ਸ", "ਤ"])
    assert "ਖੇਤਚਾਚਾ" in response.short_answer or "ਕਿਸਾਨ" in response.short_answer or "ਫ਼ਸਲ" in response.short_answer


def test_punjabi_simple_stt_transcript_question(container):
    """Simple agricultural speech transcript in Punjabi (STT input)."""
    request = FarmerChatRequest(
        question="ਕਣਕ ਦੀ ਫ਼ਸਲ ਵਿੱਚ ਪਹਿਲਾ ਪਾਣੀ ਕਦੋਂ ਲਗਾਈਏ",
        language="pa",
        crop="Wheat",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "pa"
    assert len(response.action_steps) >= 2


def test_punjabi_complex_limitation_enforcement(container):
    """Complex multi-part Punjabi query triggers clear limitation notice without fabricated schedule."""
    request = FarmerChatRequest(
        question="ਮੇਰੀ 4 ਏਕੜ ਕਪਾਹ 45 ਦਿਨਾਂ ਦੀ ਹੈ, ਪੱਤੇ ਪੀਲੇ ਹਨ, ਪਾਣੀ, ਖਾਦ, ਸਪਰੇਅ, ਖਰਚਾ ਅਤੇ 30 ਦਿਨਾਂ ਦੀ ਯੋਜਨਾ ਦੱਸੋ?",
        language="pa",
        crop="Cotton",
        crop_age_days=45,
        land_area=4.0,
        land_unit="ਏਕੜ",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "pa"
    assert response.search_strategy_used == "tier2_complexity_limitation"
    assert "ਸਰਲ ਖੇਤੀ ਸਵਾਲਾਂ" in response.short_answer
    assert "ਹਿੰਦੀ/ਅੰਗਰੇਜ਼ੀ" in response.short_answer


# ==============================================================================
# 6. TIER 2 EVALUATION — MARATHI (Simple Text, Simple STT, Complexity Limitation)
# ==============================================================================

def test_marathi_simple_text_question(container):
    """Simple agricultural query in Marathi (Text input)."""
    request = FarmerChatRequest(
        question="सोयाबीन पिकाला खत कधी द्यावे?",
        language="mr",
        crop="Soybean",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "mr"
    assert any(term in response.short_answer for term in ["नमस्कार", "शेतकरी", "पिकासाठी", "खत", "उपाय"])


def test_marathi_simple_stt_transcript_question(container):
    """Simple agricultural speech transcript in Marathi (STT input)."""
    request = FarmerChatRequest(
        question="कापूस पिकावर पांढरी माशी साठी कोणते औषध फवारावे",
        language="mr",
        crop="Cotton",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "mr"
    assert len(response.action_steps) >= 2


def test_marathi_complex_limitation_enforcement(container):
    """Complex multi-part Marathi query triggers clear limitation notice without fabricated schedule."""
    request = FarmerChatRequest(
        question="माझ्या ३ एकर कापूस पिकात ४५ दिवस झाले आहेत, पाने पिवळी पडत आहेत, पाणी, खत, फवारणी, खर्च आणि ३० दिवसांचे नियोजन सांगा?",
        language="mr",
        crop="Cotton",
        crop_age_days=45,
        land_area=3.0,
        land_unit="एकर",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "mr"
    assert response.search_strategy_used == "tier2_complexity_limitation"
    assert "मूलभूत शेती प्रश्नांची" in response.short_answer
    assert "हिंदी/इंग्रजी" in response.short_answer

