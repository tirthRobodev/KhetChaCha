"""Automated test suite for KhetChacha 300-Crop Knowledge Intelligence System."""

import json
from pathlib import Path
import pytest

from ai_engine.models.crop_knowledge_models import (
    CropProfile,
    PlantProblemRecord,
)
from ai_engine.safety.medicine_validation import MedicineValidator

ROOT = Path(__file__).resolve().parent.parent
CATALOGUE_FILE = ROOT / "data" / "catalogue" / "crops.json"
MANIFEST_FILE = ROOT / "data" / "research" / "research_manifest.json"
PROFILES_DIR = ROOT / "data" / "knowledge" / "crop_profiles"
DISEASES_DIR = ROOT / "data" / "knowledge" / "disease_records"
PESTS_DIR = ROOT / "data" / "knowledge" / "pest_records"
SOURCE_REGISTRY_FILE = ROOT / "data" / "sources" / "source_registry.json"


def test_catalogue_covers_all_300_input_entries():
    """Confirms all 300 user-supplied entries (1-300) are accounted for."""
    assert CATALOGUE_FILE.exists()
    with open(CATALOGUE_FILE, "r", encoding="utf-8") as f:
        catalogue = json.load(f)

    all_entries = set()
    for c in catalogue.values():
        all_entries.update(c.get("catalogue_entries", []))

    expected_entries = set(range(1, 301))
    missing = expected_entries - all_entries
    assert len(missing) == 0, f"Missing catalogue entry numbers: {missing}"
    assert len(all_entries) == 300


def test_catalogue_reconciliation_multi_category_overlaps():
    """Verifies that duplicate multi-category crops are unified with multi-category tags."""
    with open(CATALOGUE_FILE, "r", encoding="utf-8") as f:
        catalogue = json.load(f)

    # Cowpea (#27 pulse, #120 vegetable pods, #273 fodder)
    assert "cowpea" in catalogue
    assert set(catalogue["cowpea"]["catalogue_entries"]) == {27, 120, 273}

    # Cluster Bean (#40 pulse, #118 vegetable)
    assert "cluster_bean" in catalogue
    assert set(catalogue["cluster_bean"]["catalogue_entries"]) == {40, 118}

    # Drumstick / Moringa (#99 vegetable, #123 pods, #300 agroforestry tree)
    assert "moringa" in catalogue
    assert set(catalogue["moringa"]["catalogue_entries"]) == {99, 123, 300}


def test_gold_standard_crop_profiles_schema_valid():
    """Validates that all seeded crop profiles conform to CropProfile schema."""
    profile_files = list(PROFILES_DIR.glob("*.json"))
    assert len(profile_files) >= 5, "At least 5 representative crop profiles must be seeded"

    for pf in profile_files:
        with open(pf, "r", encoding="utf-8") as f:
            data = json.load(f)
        profile = CropProfile(**data)
        assert profile.crop_id == pf.stem
        assert len(profile.names["en"]) > 0
        assert len(profile.names["gu"]) > 0
        assert len(profile.suitable_regions) > 0
        assert len(profile.seasons) > 0
        assert len(profile.source_ids) > 0


def test_disease_and_pest_records_schema_valid():
    """Validates that all disease and pest records conform to PlantProblemRecord schema."""
    disease_files = list(DISEASES_DIR.glob("*.json"))
    pest_files = list(PESTS_DIR.glob("*.json"))

    assert len(disease_files) >= 4
    assert len(pest_files) >= 3

    for file_path in disease_files + pest_files:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        rec = PlantProblemRecord(**data)
        assert rec.problem_id == file_path.stem
        assert len(rec.symptoms) > 0
        assert len(rec.source_ids) > 0


def test_zero_banned_chemicals_in_knowledge_base():
    """Strict safety audit: verifies NO banned substances exist in recommendations."""
    all_record_files = list(DISEASES_DIR.glob("*.json")) + list(PESTS_DIR.glob("*.json"))

    for rf in all_record_files:
        with open(rf, "r", encoding="utf-8") as f:
            data = json.load(f)
        for chem in data.get("chemical_options", []):
            ingredient = chem.get("active_ingredient", "")
            banned = MedicineValidator.check_banned_substances(ingredient)
            assert len(banned) == 0, f"Critical Safety Violation: Banned chemical '{banned}' in {rf.name}"
            # Check dosage is provided
            assert chem.get("dose") is not None, f"Dose missing for {ingredient} in {rf.name}"
            assert chem.get("unit") is not None, f"Unit missing for {ingredient} in {rf.name}"


def test_source_traceability():
    """Confirms all source_ids in verified records are registered in source registry."""
    with open(SOURCE_REGISTRY_FILE, "r", encoding="utf-8") as f:
        registry = json.load(f).get("sources", {})
    known_sources = set(registry.keys())
    known_sources.update(["local_pdf", "icar_official_knowledge"])

    all_record_files = list(PROFILES_DIR.glob("*.json")) + list(DISEASES_DIR.glob("*.json")) + list(PESTS_DIR.glob("*.json"))
    for rf in all_record_files:
        with open(rf, "r", encoding="utf-8") as f:
            data = json.load(f)
        for sid in data.get("source_ids", []):
            assert sid in known_sources, f"Untraced source '{sid}' in {rf.name}"


def test_research_manifest_integrity():
    """Verifies research manifest tracks all 278 canonical crops."""
    with open(MANIFEST_FILE, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    crops = manifest.get("crops", {})
    assert len(crops) == 278
    assert manifest.get("total_catalogue_entries") == 300

    # Check verified crops status
    for cid in ["cotton", "wheat", "chickpea", "tomato", "mango", "groundnut"]:
        assert crops[cid]["status"] == "verified"
        assert crops[cid]["confidence_level"] == "high"

