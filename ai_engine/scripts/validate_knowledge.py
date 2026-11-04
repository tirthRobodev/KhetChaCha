"""Schema, Safety, and Source Traceability Validation Engine for KhetChacha Knowledge Base."""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from ai_engine.models.crop_knowledge_models import (
    CropProfile,
    PlantProblemRecord,
)
from ai_engine.safety.medicine_validation import MedicineValidator

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("knowledge_validator")

ROOT = Path(__file__).resolve().parent.parent
CATALOGUE_FILE = ROOT / "data" / "catalogue" / "crops.json"
MANIFEST_FILE = ROOT / "data" / "research" / "research_manifest.json"
PROFILES_DIR = ROOT / "data" / "knowledge" / "crop_profiles"
DISEASES_DIR = ROOT / "data" / "knowledge" / "disease_records"
PESTS_DIR = ROOT / "data" / "knowledge" / "pest_records"
SOURCE_REGISTRY_FILE = ROOT / "data" / "sources" / "source_registry.json"


def validate_all_knowledge() -> Dict[str, Any]:
    """Runs comprehensive validation across all crop profiles, disease records, pest records, and sources."""
    results = {
        "status": "PASS",
        "profiles_validated": 0,
        "diseases_validated": 0,
        "pests_validated": 0,
        "schema_errors": [],
        "safety_violations": [],
        "source_linkage_warnings": [],
        "missing_dose_warnings": [],
    }

    # Load source registry
    known_sources = set()
    if SOURCE_REGISTRY_FILE.exists():
        with open(SOURCE_REGISTRY_FILE, "r", encoding="utf-8") as f:
            known_sources = set(json.load(f).get("sources", {}).keys())
    known_sources.update(["local_pdf", "icar_official_knowledge", "icar_cicr_cotton_advisory", "aau_groundnut_disease_guide"])

    # 1. Validate Crop Profiles
    profile_files = list(PROFILES_DIR.glob("*.json"))
    for pf in profile_files:
        try:
            with open(pf, "r", encoding="utf-8") as f:
                data = json.load(f)
            CropProfile(**data)
            results["profiles_validated"] += 1
        except Exception as e:
            results["schema_errors"].append(f"CropProfile [{pf.name}]: {str(e)}")

    # 2. Validate Disease Records
    disease_files = list(DISEASES_DIR.glob("*.json"))
    for df in disease_files:
        try:
            with open(df, "r", encoding="utf-8") as f:
                data = json.load(f)
            rec = PlantProblemRecord(**data)
            results["diseases_validated"] += 1

            # Safety validation on chemicals
            for chem in rec.chemical_options:
                banned = MedicineValidator.check_banned_substances(chem.active_ingredient)
                if banned:
                    results["safety_violations"].append(
                        f"BANNED SUBSTANCE: '{banned}' in disease record {df.name}"
                    )
                if not chem.dose or not chem.unit:
                    results["missing_dose_warnings"].append(
                        f"Incomplete dose specification for {chem.active_ingredient} in {df.name}"
                    )

            # Check sources
            for sid in rec.source_ids:
                if sid not in known_sources:
                    results["source_linkage_warnings"].append(
                        f"Unregistered source ID '{sid}' in {df.name}"
                    )

        except Exception as e:
            results["schema_errors"].append(f"DiseaseRecord [{df.name}]: {str(e)}")

    # 3. Validate Pest Records
    pest_files = list(PESTS_DIR.glob("*.json"))
    for pf in pest_files:
        try:
            with open(pf, "r", encoding="utf-8") as f:
                data = json.load(f)
            rec = PlantProblemRecord(**data)
            results["pests_validated"] += 1

            # Safety validation on chemicals
            for chem in rec.chemical_options:
                banned = MedicineValidator.check_banned_substances(chem.active_ingredient)
                if banned:
                    results["safety_violations"].append(
                        f"BANNED SUBSTANCE: '{banned}' in pest record {pf.name}"
                    )
                if not chem.dose or not chem.unit:
                    results["missing_dose_warnings"].append(
                        f"Incomplete dose specification for {chem.active_ingredient} in {pf.name}"
                    )

            # Check sources
            for sid in rec.source_ids:
                if sid not in known_sources:
                    results["source_linkage_warnings"].append(
                        f"Unregistered source ID '{sid}' in {pf.name}"
                    )

        except Exception as e:
            results["schema_errors"].append(f"PestRecord [{pf.name}]: {str(e)}")

    if results["schema_errors"] or results["safety_violations"]:
        results["status"] = "FAIL"

    return results


def main():
    print("=" * 65)
    print("KhetChacha Knowledge Base Validation Engine")
    print("=" * 65)

    res = validate_all_knowledge()

    print(f"\nProfiles Validated:  {res['profiles_validated']}")
    print(f"Diseases Validated:  {res['diseases_validated']}")
    print(f"Pests Validated:     {res['pests_validated']}")
    print(f"Schema Errors:       {len(res['schema_errors'])}")
    print(f"Safety Violations:   {len(res['safety_violations'])}")
    print(f"Missing Doses:       {len(res['missing_dose_warnings'])}")
    print(f"Source Warnings:     {len(res['source_linkage_warnings'])}")

    if res["schema_errors"]:
        print("\n[SCHEMA ERRORS]:")
        for err in res["schema_errors"]:
            print(f"  - {err}")

    if res["safety_violations"]:
        print("\n[SAFETY VIOLATIONS]:")
        for viol in res["safety_violations"]:
            print(f"  - {viol}")

    print("\n" + "=" * 65)
    print(f"OVERALL VALIDATION STATUS: {res['status']}")
    print("=" * 65)

    sys.exit(0 if res["status"] == "PASS" else 1)


if __name__ == "__main__":
    main()

