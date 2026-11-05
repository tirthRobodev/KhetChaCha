"""Comprehensive End-to-End Verification Test Suite for the KhetChacha Multilingual AI Engine Rebuild.

Covers:
1. Long multi-paragraph agronomic inquiries
2. Multi-part questions across Tier 1 (Gujarati, Hindi, English) and Tier 2 (Punjabi, Marathi)
3. Code-mixed Indic languages (Gujlish, Hinglish, Romanized Marathi, Romanized Punjabi)
4. Resilient JSON repair under model output truncation
5. 6-turn multi-turn conversational memory preservation
6. Banned pesticide detection & 15L knapsack spray pump dosage standardization
7. Multimodal vision metadata grounding
"""

import json
import pytest

from ai_engine.backend.config import Settings
from ai_engine.backend.dependencies import ServiceContainer
from ai_engine.gemini.prompt_builder import PromptBuilder
from ai_engine.language_engine.language_detector import LanguageDetector
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.models.response_models import FarmerChatResponse
from ai_engine.safety.quality_validator import ResponseQualityValidator


@pytest.fixture
def container():
    settings = Settings()
    return ServiceContainer(settings)


# ==============================================================================
# 1. LONG MULTI-PARAGRAPH QUESTIONS
# ==============================================================================

def test_long_multiparagraph_gujarati_question(container):
    """Very long, multi-paragraph inquiry with soil, stage, and complex symptoms in Gujarati."""
    long_query = (
        "નમસ્તે ખેતચાચા. મારા ખેતરમાં ૫ વીઘા કપાસ વાવેલો છે જે લગભગ ૫૫ દિવસનો થયો છે. "
        "જમીન કાળી અને મધ્યમ ગોરાડુ છે. છેલ્લા એક અઠવાડિયાથી વરસાદ બંધ થયા પછી નીચલા પાન "
        "પીળા પડી રહ્યા છે અને કિનારીઓ સુકાઈને વાંકી વળી રહી છે. પાનની નીચે ઝીણા સફેદ રંગના "
        "ચૂસિયા પણ દેખાય છે. સાથે સાથે નવી કળીઓ ખરી રહી છે. "
        "કૃપા કરીને આ રોગનું સચોટ નિદાન કરો, કઈ દવાનો છંટકાવ કરવો, કેટલું પાણી આપવું, "
        "અને કયું ખાતર આપવું જેથી કપાસમાં ફૂલ અને જીંડવા સારા બેસે?"
    )
    request = FarmerChatRequest(
        question=long_query,
        language="gu",
        crop="Cotton",
        crop_age_days=55,
        land_size=5.0,
        land_unit="વીઘા",
        soil_type="Black Clay Loam",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "gu"
    assert len(response.short_answer) > 20
    assert len(response.action_steps) >= 2
    assert len(response.safety_precautions) >= 1
    # Dosages must conform to 15L knapsack pump
    assert any("૧૫" in p or "15" in p or "પંપ" in p for p in response.safety_precautions + response.action_steps)


def test_long_multiparagraph_hindi_question(container):
    """Very long, multi-paragraph inquiry in Hindi covering pest, nutrition, and irrigation."""
    long_query = (
        "नमस्ते खेतचाचा जी। मेरे पास 3 एकड़ में धान की फसल लगी है जो 40 दिन की हो चुकी है। "
        "खेत में पानी की निकासी ठीक नहीं है और पिछले कुछ दिनों से पौधों की पत्तियों पर "
        "तनाव जैसे धब्बे दिखाई दे रहे हैं। कुछ पत्तियां ऊपर से सूख रही हैं। "
        "कृपया बताइए कि क्या यह पत्ता लपेटक कीट है या झुलसा रोग? "
        "इसके रोकथाम के लिए कौन सा सुरक्षित स्प्रे करना चाहिए, कितना पानी खेत में रखना चाहिए, "
        "और यूरिया के साथ क्या मिलाना चाहिए?"
    )
    request = FarmerChatRequest(
        question=long_query,
        language="hi",
        crop="Paddy",
        crop_age_days=40,
        land_size=3.0,
        land_unit="एकड़",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "hi"
    assert len(response.short_answer) > 20
    assert len(response.action_steps) >= 2
    assert any("15" in p or "पंप" in p for p in response.safety_precautions + response.action_steps)


# ==============================================================================
# 2. MULTI-PART QUESTIONS ACROSS TIER 1 & TIER 2 LANGUAGES
# ==============================================================================

def test_multipart_english_pest_irrigation_fertilizer(container):
    """Multi-part inquiry in English covering pest control, irrigation, and fertilizer."""
    request = FarmerChatRequest(
        question="My wheat crop has yellow leaf tips. What fertilizer should I apply and what is the spray schedule?",
        language="en",
        crop="Wheat",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "en"
    assert len(response.action_steps) >= 2
    assert any("15" in p.lower() or "spray" in p.lower() for p in response.safety_precautions + response.action_steps)


def test_punjabi_two_part_agricultural_query(container):
    """Two-part agricultural inquiry in Punjabi (not full 5-part planning) proceeds to full advice."""
    request = FarmerChatRequest(
        question="ਕਪਾਹ ਵਿੱਚ ਪੱਤੇ ਪੀਲੇ ਹੋ ਰਹੇ ਹਨ, ਕਿਹੜੀ ਖਾਦ ਪਾਈਏ ਅਤੇ ਸਪਰੇਅ ਕਿਹੜੀ ਕਰੀਏ?",
        language="pa",
        crop="Cotton",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "pa"
    assert len(response.action_steps) >= 2
    assert any("15" in p or "ਪੰਪ" in p for p in response.safety_precautions + response.action_steps)


def test_marathi_two_part_agricultural_query(container):
    """Two-part agricultural inquiry in Marathi proceeds to full advice."""
    request = FarmerChatRequest(
        question="सोयाबीन पिकावर अळी आली आहे, कोणती फवारणी करावी आणि खत कधी द्यावे?",
        language="mr",
        crop="Soybean",
    )
    response = container.response_generator.generate_response(request)
    assert response.language == "mr"
    assert len(response.action_steps) >= 2
    assert any("15" in p or "पंप" in p or "फवारणी" in p for p in response.safety_precautions + response.action_steps)


# ==============================================================================
# 3. CODE-MIXED INDIC INPUTS (Gujlish, Hinglish, Romanized Marathi, Romanized Punjabi)
# ==============================================================================

def test_code_mixed_detection_and_processing(container):
    """Verifies that code-mixed Romanized Indic queries are correctly identified and answered."""
    # Gujlish
    req_gu = FarmerChatRequest(question="mara khetar ma kapas na pan pila thai gaya che su dava chhatvi")
    resp_gu = container.response_generator.generate_response(req_gu)
    assert resp_gu.language == "gu"

    # Hinglish
    req_hi = FarmerChatRequest(question="gehu ki fasal me kit lag gaye hai konsa spray kare")
    resp_hi = container.response_generator.generate_response(req_hi)
    assert resp_hi.language == "hi"

    # Romanized Marathi
    req_mr = FarmerChatRequest(question="kapus pikavar pandhari mashi aali aahe kay karave")
    resp_mr = container.response_generator.generate_response(req_mr)
    assert resp_mr.language == "mr"

    # Romanized Punjabi
    req_pa = FarmerChatRequest(question="kanak vich gilli jameen te khad kado payie")
    resp_pa = container.response_generator.generate_response(req_pa)
    assert resp_pa.language == "pa"


# ==============================================================================
# 4. RESILIENT JSON REPAIR UNDER TRUNCATION
# ==============================================================================

def test_resilient_json_repair_on_truncated_output(container):
    """Model output truncated before closing quote/braces is repaired and parsed without throwing."""
    truncated_llm_json = (
        '{\n'
        '  "short_answer": "નમસ્તે ખેડૂત મિત્ર! તમારા કપાસ પાકમાં ગુલાબી ઈયળ માટે લીંબોળીનું તેલ ૧૫ લિટર પંપમાં ૫૦ મિલી છાંટો.",\n'
        '  "detailed_explanation": "તમારા કપાસ પાકમાં ઈયળના નિયંત્રણ માટે સવારે છંટકાવ કરવો હિતાવહ છે. પાન નીચે તપાસો'
    )
    parsed = container.response_generator._parse_gemini_output(truncated_llm_json, "gu")
    assert "short_answer" in parsed
    assert "ગુલાબી ઈયળ" in parsed["short_answer"]
    assert "detailed_explanation" in parsed


# ==============================================================================
# 5. 6-TURN CONVERSATION MEMORY CONTINUITY
# ==============================================================================

def test_six_turn_conversation_memory_in_prompt():
    """PromptBuilder injects up to 6 turns (3 exchanges) of recent conversation history."""
    history = [
        {"role": "user", "content": "Query turn 1: Crop is cotton"},
        {"role": "assistant", "content": "Answer 1: Spray neem oil"},
        {"role": "user", "content": "Query turn 2: How much water?"},
        {"role": "assistant", "content": "Answer 2: Give light irrigation"},
        {"role": "user", "content": "Query turn 3: What about urea?"},
        {"role": "assistant", "content": "Answer 3: Apply 25kg urea"},
    ]
    req = FarmerChatRequest(question="Can I mix them together?", language="en")
    prompt = PromptBuilder.build_chat_prompt(req, evidence_sources=[], conversation_history=history)

    assert "Query turn 1" in prompt
    assert "Answer 1" in prompt
    assert "Query turn 2" in prompt
    assert "Query turn 3" in prompt
    assert "Apply 25kg urea" in prompt


# ==============================================================================
# 6. BANNED PESTICIDE DETECTION & SAFETY REDACTION
# ==============================================================================

def test_banned_pesticide_redaction_and_safety_gate():
    """Response mentioning banned pesticides like Endosulfan or Monocrotophos is redacted with warning."""
    raw_response = FarmerChatResponse(
        short_answer="તમે કપાસમાં Endosulfan 35 EC અથવા Monocrotophos નો છંટકાવ કરી શકો છો.",
        detailed_explanation="Endosulfan કપાસના ચૂસિયા માટે વપરાય છે.",
        language="gu",
        confidence_score=0.85,
        action_steps=["Endosulfan 20 ml પ્રતિ પંપ છાંટો."],
        safety_precautions=[],
    )
    req = FarmerChatRequest(question="Endosulfan છંટકાવ કરી શકાય?", language="gu")

    clean_response = ResponseQualityValidator.validate_and_repair(raw_response, req)

    # Must be redacted
    assert "Endosulfan" not in clean_response.short_answer
    assert "Monocrotophos" not in clean_response.short_answer
    assert "Endosulfan" not in clean_response.action_steps[0]

    # Must include critical banned warning
    assert any("પ્રતિબંધિત" in p for p in clean_response.safety_precautions)

    # Must standardize on 15L knapsack pump
    assert any("૧૫ લિટર" in p or "15" in p for p in clean_response.safety_precautions)


# ==============================================================================
# 7. MULTIMODAL VISION METADATA GROUNDING
# ==============================================================================

def test_multimodal_vision_metadata_grounding():
    """When image payload is provided, plant part and category metadata are guaranteed."""
    raw_response = FarmerChatResponse(
        short_answer="Visual plant analysis shows mild leaf yellowing.",
        detailed_explanation="Leaf chlorosis possibly caused by micronutrient deficiency.",
        language="en",
        confidence_score=0.90,
    )
    req = FarmerChatRequest(
        question="What is this symptom?",
        language="en",
        image_base64="data:image/jpeg;base64,/9j/4AAQSkZJRg==",
    )

    grounded_response = ResponseQualityValidator.validate_and_repair(raw_response, req)
    assert grounded_response.plant_category is not None
    assert grounded_response.plant_part is not None
    assert grounded_response.health_status is not None

