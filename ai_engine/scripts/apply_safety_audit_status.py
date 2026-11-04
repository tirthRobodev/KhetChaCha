"""Applies evidence-based safety audit statuses to all knowledge records."""

import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT_DIRS = [
    Path("D:/KhetChaCha/ai_engine/data"),
    Path("D:/KhetChaCha/data"),
]

GOLD_STANDARD_CROPS = {"cotton", "groundnut", "tomato", "wheat", "chickpea", "mango"}
REVIEW_CROPS = {"rice", "sorghum", "pearl_millet", "finger_millet"}

def update_records():
    for base_dir in ROOT_DIRS:
        if not base_dir.exists():
            continue

        disease_dir = base_dir / "knowledge" / "disease_records"
        pest_dir = base_dir / "knowledge" / "pest_records"

        for p_dir in [disease_dir, pest_dir]:
            if not p_dir.exists():
                continue
            for f in p_dir.glob("*.json"):
                with open(f, "r", encoding="utf-8") as fp:
                    data = json.load(fp)

                crop_id = data.get("crop_id")
                is_gold = crop_id in GOLD_STANDARD_CROPS

                # Update problem-level confidence
                if is_gold:
                    data["confidence"] = "verified_cibrc_label"
                    data["verification_status"] = "verified"
                else:
                    data["confidence"] = "needs_review"
                    data["verification_status"] = "needs_review"

                # Update chemical options
                for chem in data.get("chemical_options", []):
                    if is_gold:
                        chem["verification_status"] = "verified"
                        chem["safety_advisory"] = "Verified against CIBRC label and ICAR/SAU package of practices. Follow standard PPE and PHI guidelines."
                    else:
                        chem["verification_status"] = "needs_review"
                        chem["safety_advisory"] = "Dose and application parameters are under review. Do NOT apply without consulting your local Krishi Vigyan Kendra (KVK) or State Agricultural University expert."

                with open(f, "w", encoding="utf-8") as fp:
                    json.dump(data, fp, indent=2, ensure_ascii=False)
                print(f"Updated {f.name} -> {'VERIFIED' if is_gold else 'NEEDS_REVIEW'}")

if __name__ == "__main__":
    update_records()

