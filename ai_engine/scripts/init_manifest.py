"""Initializes and updates the research manifest tracking all 300 crop entries."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path


def initialize_research_manifest():
    root = Path(__file__).resolve().parent.parent
    crops_file = root / "data" / "catalogue" / "crops.json"
    manifest_file = root / "data" / "research" / "research_manifest.json"

    if not crops_file.exists():
        raise FileNotFoundError(f"Canonical crops file not found at {crops_file}")

    with open(crops_file, "r", encoding="utf-8") as f:
        crops_data = json.load(f)

    # Existing manifest if present
    existing_manifest = {}
    if manifest_file.exists():
        try:
            with open(manifest_file, "r", encoding="utf-8") as f:
                existing_manifest = json.load(f).get("crops", {})
        except Exception:
            existing_manifest = {}

    manifest_crops = {}
    for crop_id, crop_info in crops_data.items():
        if crop_id in existing_manifest:
            manifest_crops[crop_id] = existing_manifest[crop_id]
        else:
            manifest_crops[crop_id] = {
                "crop_id": crop_id,
                "catalogue_entry_numbers": crop_info.get("catalogue_entries", []),
                "primary_name": crop_info.get("primary_english_name", ""),
                "gujarati_name": crop_info.get("gujarati_name", ""),
                "botanical_name": crop_info.get("botanical_name", ""),
                "categories": crop_info.get("categories", []),
                "status": "not_started",
                "confidence_level": "insufficient",
                "local_pdf_sources_found": 0,
                "online_sources_found": 0,
                "diseases_recorded": 0,
                "pests_recorded": 0,
                "nutrient_disorders_recorded": 0,
                "chemical_options_verified": 0,
                "organic_options_verified": 0,
                "last_researched_at": None,
                "notes": [],
                "error_message": None,
            }

    data = {
        "total_canonical_crops": len(manifest_crops),
        "total_catalogue_entries": sum(len(c["catalogue_entry_numbers"]) for c in manifest_crops.values()),
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "crops": manifest_crops,
    }

    with open(manifest_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Initialized research manifest for {len(manifest_crops)} canonical crops at {manifest_file}")
    return manifest_file


if __name__ == "__main__":
    initialize_research_manifest()

