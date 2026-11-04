"""Regression test suite for agricultural recommendation quality and safety consistency.

Verifies:
1. Cotton leaf yellowing differential diagnosis (Magnesium, waterlogging, nutrients, sucking pests).
2. Magnesium Sulphate foliar dosage exactness (10 g/L, 150 g / 15L pump).
3. Waterlogging drainage advisory without premature chemical spraying.
4. Rejection and reconciliation of contradictory dosages across response sections.
5. Strict rejection of unsupported or hazardous chemical recommendations.
6. Insufficient evidence fallback without hallucinated synthetic chemicals.
"""

import pytest
from ai_engine.safety.dosage_validator import DosageConsistencyValidator
from ai_engine.safety.uncertainty_handler import UncertaintyHandler
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.safety.medicine_validation import MedicineValidator
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.gemini.response_generator import ResponseGenerator
from ai_engine.gemini.gemini_client import GeminiClient
from ai_engine.search_engine.search_orchestrator import SearchOrchestrator, SearchOrchestratorResult


def test_cotton_leaf_yellowing_differential_diagnosis_gujarati():
    """Verifies that cotton leaf yellowing in Gujarati generates 4-factor differential diagnosis."""
    query = "કપાસમાં પાંદડા પીળા પડી રહ્યા છે શું કરવું?"
    response = UncertaintyHandler.generate_differential_diagnosis_response(
        query=query,
        language_code="gu",
        detected_crops=["cotton"],
        detected_symptoms=["leaf_yellowing"],
    )

    full_text = f"{response['short_answer']} {response['detailed_explanation']}"

    # 1. Must cover Magnesium deficiency / Lalio
    assert "મેગ્નેશિયમ" in full_text or "લાલિયા" in full_text

    # 2. Must cover Waterlogging / excess water drainage
    assert "પાણી" in full_text or "ભેજ" in full_text or "નિતાર" in full_text

    # 3. Must cover Sucking pests
    assert "ચૂસિયા" in full_text or "જીવાત" in full_text

    # 4. Must specify exact foliar dosage for MgSO4: 150g per 15L pump (10 g/L)
    assert "૧૫૦ ગ્રામ" in full_text or "150 ગ્રામ" in full_text or "150g" in full_text or "1%" in full_text

    # 5. Must include targeted clarifying questions in action steps
    action_text = " ".join(response["action_steps"])
    assert "ફોટો" in action_text or "પાંદડા" in action_text or "પાણી" in action_text


def test_cotton_leaf_yellowing_differential_diagnosis_english():
    """Verifies that cotton leaf yellowing in English generates clear multi-factor differential diagnosis."""
    query = "cotton leaves are turning yellow what should I do?"
    response = UncertaintyHandler.generate_differential_diagnosis_response(
        query=query,
        language_code="en",
        detected_crops=["cotton"],
        detected_symptoms=["leaf_yellowing"],
    )

    full_text = f"{response['short_answer']} {response['detailed_explanation']}"
    assert "magnesium" in full_text.lower()
    assert "waterlog" in full_text.lower() or "drainage" in full_text.lower()
    assert "sucking" in full_text.lower() or "pest" in full_text.lower()
    assert "150 g" in full_text or "10 g/l" in full_text.lower() or "1%" in full_text


def test_magnesium_deficiency_dosage_exactness():
    """Mathematically verifies foliar spray dosage of Magnesium Sulphate: 10 g/L = 150 g/pump."""
    # 150g per 15L pump is valid
    res_valid = DosageConsistencyValidator.validate_dosage_value("magnesium sulphate", 150.0, "g", "pump")
    assert res_valid["status"] == "valid"

    # 10 g/L is valid
    res_valid_l = DosageConsistencyValidator.validate_dosage_value("magnesium sulphate", 10.0, "g", "liter")
    assert res_valid_l["status"] == "valid"

    # 500g per pump is an unsafe overdose
    res_overdose = DosageConsistencyValidator.validate_dosage_value("magnesium sulphate", 500.0, "g", "pump")
    assert res_overdose["status"] == "overdose"
    assert "exceeds" in res_overdose["warning"].lower()


def test_waterlogging_drainage_advisory_no_chemical_spray():
    """Verifies waterlogging advisory emphasizes immediate field drainage without spraying chemical pesticides."""
    response = UncertaintyHandler.generate_differential_diagnosis_response(
        query="કપાસમાં પાણી ભરાવાથી પાન પીળા પડ્યા",
        language_code="gu",
        detected_crops=["cotton"],
        detected_symptoms=["leaf_yellowing"],
    )

    full_text = f"{response['short_answer']} {response['detailed_explanation']}"
    # Waterlogging requires drainage
    assert "પાણી" in full_text and ("નિતાર" in full_text or "કાલિંગ" in full_text or "કાઢી" in full_text or "ભેજ" in full_text)

    # Precaution cautions against premature spraying on waterlogged soil
    precautions_text = " ".join(response["safety_precautions"])
    assert "છંટકાવ" in precautions_text or "દવા" in precautions_text


def test_contradictory_dosage_rejection_and_reconciliation():
    """Detects and reconciles contradictory quantities across response sections."""
    inconsistent_data = {
        "short_answer": "Spray Magnesium Sulphate at 500 g per pump on cotton leaves.",
        "detailed_explanation": "Dissolve Magnesium Sulphate at 10 g/L in water.",
        "action_steps": [
            "Add 150 g Magnesium Sulphate per 15-liter knapsack spray pump.",
            "Inspect underside of leaves.",
        ],
        "safety_precautions": ["Wear protective gear during application."],
    }

    # Cross section validator must detect contradiction
    inconsistencies = DosageConsistencyValidator.validate_cross_section_consistency(inconsistent_data)
    assert len(inconsistencies) > 0
    assert any("contradictory" in inc.lower() for inc in inconsistencies)

    # Reconciliation must sanitize short_answer to match authoritative 150 g per pump
    sanitized = DosageConsistencyValidator.reconcile_and_sanitize_response(inconsistent_data, crop="cotton")
    assert "500 g" not in sanitized["short_answer"]
    assert "150 g" in sanitized["short_answer"] or "10 g/L" in sanitized["short_answer"]


def test_unsupported_chemical_recommendation_rejection():
    """Ensures unauthorized non-selective weedicides are rejected and trigger critical safety alerts."""
    hazardous_query = "કપાસના પાકમાં નીંદણ માટે ગ્લાયફોસેટ (Glyphosate) છાંટી શકાય?"
    hazardous_resp = "હા, તમે કપાસમાં ગ્લાયફોસેટ 100 મિલી પ્રતિ પંપ છાંટી શકો છો."

    # 1. DosageConsistencyValidator must reject Glyphosate on standing cotton
    is_valid, violations = DosageConsistencyValidator.validate_crop_chemical_authorization(hazardous_resp, crop="cotton")
    assert not is_valid
    assert len(violations) > 0
    assert any("unauthorized" in v.lower() or "glyphosate" in v.lower() for v in violations)

    # 2. AgricultureSafetyEngine must raise critical safety alert
    safety_engine = AgricultureSafetyEngine()
    alerts = safety_engine.evaluate_safety(hazardous_query, hazardous_resp, language_code="gu")
    assert any("Weedicide" in a.title or "Herbicide" in a.title or "Safety Alert" in a.title for a in alerts)


def test_insufficient_evidence_prohibits_exact_dose(monkeypatch):
    """When evidence is insufficient and orchestrator has no hits, response does NOT invent chemical doses."""
    client = GeminiClient(api_key=None)  # unconfigured, offline
    mock_orchestrator = type("MockOrch", (), {
        "retrieve_evidence": lambda self, query, crop: SearchOrchestratorResult(
            sources=[], strategy_used="none", query_analysis={}, local_results_count=0, online_results_count=0, is_evidence_sufficient=False
        )
    })()

    generator = ResponseGenerator(gemini_client=client, search_orchestrator=mock_orchestrator)
    req = FarmerChatRequest(query="અજ્ઞાત રહસ્યમય કીટક માટે કોઈ દવા આપો", language="gu")
    resp = generator.generate_response(req)

    assert resp.requires_photo is True
    assert resp.confidence_score <= 0.40
    # Must advise not spraying unverified chemicals
    assert any("ચોક્કસ નિદાન વગર" in step or "કિસાન" in step for step in resp.action_steps)
