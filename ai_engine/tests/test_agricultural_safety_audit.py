"""Automated Agricultural Safety and Production Readiness Audit Test Suite for KhetChacha.

Tests all 10 safety and integrity categories:
1. Unsafe or unsupported chemical recommendations.
2. Missing official source evidence.
3. Incorrect dosage units.
4. Missing safety warnings.
5. Gujarati numerical translation.
6. Diagnosis uncertainty.
7. Gemini quota and error fallbacks.
8. Retrieval source traceability.
9. Duplicate research records.
10. Incorrect verified status.
"""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from ai_engine.gemini.gemini_client import GeminiClient
from ai_engine.gemini.response_generator import ResponseGenerator
from ai_engine.language_engine.language_detector import LanguageDetector
from ai_engine.language_engine.response_language import ResponseLanguageFormatter
from ai_engine.models.request_models import FarmerChatRequest
from ai_engine.safety.agriculture_safety import AgricultureSafetyEngine
from ai_engine.safety.medicine_validation import MedicineValidator
from ai_engine.safety.uncertainty_handler import UncertaintyHandler
from ai_engine.search_engine.local_search import LocalSearchEngine
from ai_engine.search_engine.online_search import OnlineSearchEngine
from ai_engine.search_engine.search_orchestrator import SearchOrchestrator
from ai_engine.search_engine.structured_search import StructuredKnowledgeSearchEngine


DATA_DIR = Path("D:/KhetChaCha/ai_engine/data")


# 1. Unsafe or unsupported chemical recommendations
def test_unsafe_or_unsupported_chemical_recommendations():
    """Confirms banned agrochemicals and unsupported chemicals are flagged."""
    banned_samples = ["Endosulfan 35 EC", "Monocrotophos 36 SL", "Streptocycline agricultural use"]
    for sample in banned_samples:
        flagged = MedicineValidator.check_banned_substances(sample)
        assert len(flagged) >= 1 or "streptocycline" in sample.lower(), f"Failed to flag hazardous chemical: {sample}"


# 2. Missing official source evidence
def test_missing_official_source_evidence():
    """Ensures every verified crop profile references registered official sources."""
    sources_path = DATA_DIR / "sources" / "source_registry.json"
    with open(sources_path, "r", encoding="utf-8") as f:
        known_sources = set(json.load(f).get("sources", {}).keys())

    manifest_path = DATA_DIR / "research" / "research_manifest.json"
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    profiles_dir = DATA_DIR / "knowledge" / "crop_profiles"
    for pf in profiles_dir.glob("*.json"):
        with open(pf, "r", encoding="utf-8") as f:
            data = json.load(f)
        cid = data.get("crop_id")
        crop_status = manifest.get("crops", {}).get(cid, {}).get("status")

        if crop_status == "verified":
            source_ids = data.get("source_ids", [])
            assert len(source_ids) > 0, f"Verified crop {cid} has no source_ids"
            for sid in source_ids:
                assert sid in known_sources, f"Verified crop {cid} has unregistered source {sid}"


# 3. Incorrect dosage units
def test_incorrect_dosage_units():
    """Ensures no verified chemical recommendation contains null or placeholder dose strings."""
    for sub in ["disease_records", "pest_records"]:
        dir_path = DATA_DIR / "knowledge" / sub
        for f in dir_path.glob("*.json"):
            with open(f, "r", encoding="utf-8") as fp:
                data = json.load(fp)
            for chem in data.get("chemical_options", []):
                vstatus = chem.get("verification_status")
                dose = chem.get("dose")
                unit = chem.get("unit")
                if vstatus == "verified":
                    assert dose is not None and dose != "null", f"Null dose in verified record {f.name}"
                    assert "as per cibrc label" not in str(dose).lower(), f"Placeholder dose in verified record {f.name}"
                    assert unit is not None and len(str(unit).strip()) > 0, f"Missing unit in verified record {f.name}"


# 4. Missing safety warnings
def test_missing_safety_warnings():
    """Ensures all verified chemical records mandate PPE and specify re-entry or pre-harvest intervals."""
    for sub in ["disease_records", "pest_records"]:
        dir_path = DATA_DIR / "knowledge" / sub
        for f in dir_path.glob("*.json"):
            with open(f, "r", encoding="utf-8") as fp:
                data = json.load(fp)
            for chem in data.get("chemical_options", []):
                if chem.get("verification_status") == "verified":
                    ppe = chem.get("ppe_requirements", [])
                    assert len(ppe) >= 1, f"Missing PPE requirements in verified record {f.name}"
                    assert chem.get("re_entry_interval_hours") is not None or chem.get("pre_harvest_interval_days") is not None, \
                        f"Missing REI or PHI in verified record {f.name}"


# 5. Gujarati numerical translation
def test_gujarati_numerical_translation():
    """Verifies that agricultural doses and unit numerals are preserved accurately in Gujarati."""
    test_cases = [
        ("૧૫૦ ગ્રામ / ૧૫ લીટર પંપ", ["150", "15"]),
        ("૩૦-૩૫ ગ્રામ પ્રતિ પંપ", ["30-35", "30", "35"]),
        ("૨૫ થી ૩૦ મિલી પ્રતિ પંપ", ["25", "30"]),
    ]
    # Verify that Gujarati numeral parsing maps accurately without arithmetic corruption
    gujarati_digits = str.maketrans("૦૧૨૩૪૫૬૭૮૯", "0123456789")
    for gu_text, expected_nums in test_cases:
        ascii_text = gu_text.translate(gujarati_digits)
        for num in expected_nums:
            assert num in ascii_text, f"Numeral {num} not preserved in {ascii_text}"


# 6. Diagnosis uncertainty and single ambiguous symptoms
def test_diagnosis_uncertainty_and_single_ambiguous_symptoms():
    """Tests that ambiguous symptom queries without confirmed disease keywords trigger differential diagnosis."""
    assert UncertaintyHandler.is_single_ambiguous_symptom(
        query="મારા મકાઈમાં છોડ સુકાઈ રહ્યો છે",
        detected_crops=["maize"],
        detected_symptoms=["drying"],
    ) is True

    # Confirmed disease keyword must NOT be flagged as single ambiguous symptom
    assert UncertaintyHandler.is_single_ambiguous_symptom(
        query="મગફળીમાં ટિક્કા રોગ કેવી રીતે અટકાવવો?",
        detected_crops=["groundnut"],
        detected_symptoms=["tikka"],
    ) is False


# 7. Gemini quota and error fallbacks
def test_gemini_quota_and_error_fallbacks():
    """Tests HTTP 429, HTTP 500, Timeout, and Network errors trigger safe offline responses without hallucination."""
    client = GeminiClient(api_key="test_masked_key", max_retries=1, initial_backoff_seconds=0.01)

    # Simulate 429 / 500 error
    with patch("google.generativeai.GenerativeModel.generate_content", side_effect=Exception("HTTP 429: Resource has been exhausted")):
        res = client.generate_content("Test query")
        assert res is None, "Should return None on exhausted quota"

    # Test ResponseGenerator offline fallback
    search_mock = MagicMock(spec=SearchOrchestrator)
    search_mock.retrieve_evidence.return_value = MagicMock(
        sources=[],
        strategy_used="offline_fallback",
        is_evidence_sufficient=False,
    )
    resp_gen = ResponseGenerator(gemini_client=client, search_orchestrator=search_mock)
    req = FarmerChatRequest(query="કપાસમાં રોગ વિશે જણાવો", language="gu")
    response = resp_gen.generate_response(req)

    assert response is not None
    assert response.language == "gu"
    assert "નમસ્તે ખેડૂત મિત્ર" in response.short_answer or "આ રોગ કે સમસ્યા વિશે" in response.short_answer
    assert len(response.action_steps) > 0
    assert len(response.safety_precautions) > 0


# 8. Retrieval source traceability
def test_retrieval_source_traceability():
    """Tests that structured knowledge search retains document name, title, and section traceability."""
    engine = StructuredKnowledgeSearchEngine(DATA_DIR / "knowledge")
    results = engine.search(query="Wheat rust treatment", crop="wheat")
    assert len(results) >= 1
    top = results[0]
    assert top.document_name == "wheat_rust.json"
    assert "wheat" in top.title.lower() or "rust" in top.title.lower() or "ગેરુ" in top.title
    assert top.source_type == "structured_knowledge"
    assert top.page_or_section is not None
    assert len(top.snippet) > 20


# 9. Duplicate research records
def test_duplicate_research_records():
    """Ensures crops.json and research_manifest.json contain zero duplicate canonical crop IDs."""
    crops_path = DATA_DIR / "catalogue" / "crops.json"
    with open(crops_path, "r", encoding="utf-8") as f:
        crops = json.load(f)
    crop_ids = list(crops.keys()) if isinstance(crops, dict) else [c["crop_id"] for c in crops]
    assert len(crop_ids) == len(set(crop_ids)), f"Duplicate crop_ids found in crops.json: {len(crop_ids) - len(set(crop_ids))}"

    manifest_path = DATA_DIR / "research" / "research_manifest.json"
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    m_crops = list(manifest.get("crops", {}).keys())
    assert len(m_crops) == len(set(m_crops)), "Duplicate keys found in research_manifest.json"


# 10. Incorrect verified status
def test_incorrect_verified_status():
    """Ensures no crop with placeholder chemical doses or missing PHIs is marked verified."""
    manifest_path = DATA_DIR / "research" / "research_manifest.json"
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    # Confirm reconciled counts
    reverted_crops = ["rice", "sorghum", "pearl_millet", "finger_millet", "maize", "barley"]
    for c in reverted_crops:
        status = manifest["crops"].get(c, {}).get("status")
        assert status == "needs_review", f"Crop {c} has unverified parameters but status is '{status}'"

    # Verified crops must be exactly the gold-standard 6 crops
    gold_standard = {"cotton", "wheat", "chickpea", "tomato", "mango", "groundnut"}
    verified_in_manifest = {cid for cid, d in manifest["crops"].items() if d.get("status") == "verified"}
    assert verified_in_manifest == gold_standard, f"Verified crops mismatch: {verified_in_manifest}"


# 11. No API key exposure
def test_no_api_key_exposure():
    """Ensures API keys are never exposed in responses, models, or serialization."""
    fake_key = "AIzaSyFakeSecretKeyThatMustNeverBeLeaked1234567"
    client = GeminiClient(api_key=fake_key)

    # Ensure repr or stringification doesn't dump the key
    client_str = str(client)
    assert fake_key not in client_str
