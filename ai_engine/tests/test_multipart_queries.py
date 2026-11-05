"""Tests for multi-part agricultural question decomposition and answer completeness."""

import pytest
from ai_engine.backend.config import Settings
from ai_engine.backend.dependencies import ServiceContainer
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.safety.answer_validator import AnswerValidator


def test_multipart_decomposition_gujarati():
    query = "મારા ૨ એકર કપાસમાં ૪૫ દિવસ થયા છે, પાન પીળા પડે છે અને ચૂસિયા જીવાત છે. પાણી, ખાતર, દવા અને ૩૦ દિવસનું આયોજન આપો અને ખર્ચ કેટલો થશે?"
    decomp = AnswerValidator.decompose_query(query)

    assert decomp["is_multipart"] is True
    assert decomp["facets_count"] == 5
    assert decomp["has_water"] is True
    assert decomp["has_fertilizer"] is True
    assert decomp["has_pest_disease"] is True
    assert decomp["has_cost"] is True
    assert decomp["has_timeline"] is True
    assert decomp["extracted_land_area"] == 2.0
    assert decomp["extracted_crop_age_days"] == 45


def test_multipart_decomposition_hindi():
    query = "मेरी 3 एकड़ कपास 40 दिन की है, पत्तियां पीली हो रही हैं और रसचूसक कीट हैं। पानी, खाद, दवा और खर्च का विवरण दें।"
    decomp = AnswerValidator.decompose_query(query)

    assert decomp["is_multipart"] is True
    assert decomp["has_water"] is True
    assert decomp["has_fertilizer"] is True
    assert decomp["has_pest_disease"] is True
    assert decomp["has_cost"] is True
    assert decomp["extracted_crop_age_days"] == 40


def test_cotton_45day_multipart_advisory_completeness():
    """Validates that the exact multi-part cotton scenario returns all 5 requested facets."""
    settings = Settings()
    container = ServiceContainer(settings)

    request = FarmerChatRequest(
        question="મારા ૨ એકર કપાસમાં ૪૫ દિવસ થયા છે, પાન પીળા પડે છે અને ચૂસિયા જીવાત છે. પાણી, ખાતર, દવા અને ૩૦ દિવસનું આયોજન આપો અને ખર્ચ કેટલો થશે?",
        language="gu",
        crop="Cotton",
        crop_age_days=45,
        land_area=2.0,
        land_unit="એકર",
    )

    response = container.response_generator.generate_response(request)

    assert response.language == "gu"
    assert response.confidence_score >= 0.70
    assert not response.requires_photo  # Multi-part question should not be blocked by photo gate

    full_text = f"{response.short_answer}\n{response.detailed_explanation}\n{' '.join(response.action_steps)}"

    # 1. Irrigation / Water covered
    assert any(w in full_text for w in ["પાણી", "સિંચાઈ", "પિયત"])

    # 2. Fertilizer covered
    assert any(f in full_text for f in ["ખાતર", "૧૯:૧૯:૧૯", "યુરિયા", "મેગ્નેશિયમ"])

    # 3. Pest & Disease covered
    assert any(p in full_text for p in ["જીવાત", "ચૂસિયા", "તેલ", "દવા", "છંટકાવ"])

    # 4. Cost / Expenses breakdown covered
    assert any(c in full_text for c in ["ખર્ચ", "₹", "રૂપિયા", "બજેટ"])

    # 5. Action steps present and non-empty
    assert len(response.action_steps) >= 3
    assert len(response.safety_precautions) >= 1

