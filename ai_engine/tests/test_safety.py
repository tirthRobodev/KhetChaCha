"""Unit tests for Phase 7 Agricultural Safety & Medicine Validation Engine."""

import pytest
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.safety.medicine_validation import MedicineValidator
from ai_engine.safety.uncertainty_handler import UncertaintyHandler


def test_banned_substances_detection():
    """Confirms prohibited agrochemicals are flagged."""
    text1 = "Farmer wants to spray Endosulfan on his crop."
    banned1 = MedicineValidator.check_banned_substances(text1)
    assert "endosulfan" in banned1

    text2 = "Is monocrotophos safe for tomato leaves?"
    banned2 = MedicineValidator.check_banned_substances(text2)
    assert "monocrotophos" in banned2

    text3 = "Spray neem oil at 50 ml per pump."
    banned3 = MedicineValidator.check_banned_substances(text3)
    assert len(banned3) == 0


def test_hazardous_chemical_mixtures():
    """Detects dangerous or biological-degrading chemical mixtures."""
    text = "Mix Trichoderma and Mancozeb together in the pump."
    incompatibilities = MedicineValidator.check_incompatible_combinations(text)

    assert len(incompatibilities) >= 1
    assert "Hazardous Mixture" in incompatibilities[0]


def test_dosage_validation_limits():
    """Tests detection of dangerous agrochemical overdoses."""
    excessive_text = "Apply Chlorantraniliprole (Coragen) at 50 ml per pump for bollworm."
    res = MedicineValidator.extract_and_validate_dosage(excessive_text)

    assert len(res["excessive_dosage_warnings"]) >= 1
    assert "limit" in res["excessive_dosage_warnings"][0].lower() or "overdosing" in res["excessive_dosage_warnings"][0].lower()


def test_safety_engine_mandatory_ppe_injection():
    """Tests that PPE warnings are automatically attached whenever pesticides are discussed."""
    engine = AgricultureSafetyEngine()
    alerts = engine.evaluate_safety(
        query="કપાસમાં ઈયળ માટે કઈ દવા છાંટવી?",
        response_text="ઈયળ નિયંત્રણ માટે એમામેક્ટીન બેન્ઝોએટ દવાનો છંટકાવ કરવો.",
        language_code="gu",
    )

    alert_titles = [a.title for a in alerts]
    assert "Personal Protective Equipment (PPE)" in alert_titles
    assert any("માસ્ક" in a.message for a in alerts)


def test_uncertainty_handler_for_ambiguous_queries():
    """Tests that vague queries trigger photo upload request and KVK helpline."""
    assert UncertaintyHandler.is_query_highly_ambiguous(
        query="છોડ સુકાઈ રહ્યો છે",
        detected_crops=[],
        detected_symptoms=[],
    ) is True

    clarification = UncertaintyHandler.generate_clarification_response(
        query="છોડ સુકાઈ રહ્યો છે",
        language_code="gu",
    )

    assert clarification["photo_requested"] is True
    assert "1800-180-1551" in clarification["short_answer"]
    assert "ફોટો" in clarification["short_answer"]

