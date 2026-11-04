"""Updates research_manifest.json with evidence-based safety audit reconciliation."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT_DIRS = [
    Path("D:/KhetChaCha/ai_engine/data"),
    Path("D:/KhetChaCha/data"),
]

GOLD_CROPS = {"cotton", "groundnut", "tomato", "wheat", "chickpea", "mango"}
REVERT_CROPS = {"rice", "sorghum", "pearl_millet", "finger_millet"}

def update_manifest():
    for base in ROOT_DIRS:
        manifest_path = base / "research" / "research_manifest.json"
        if not manifest_path.exists():
            continue

        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)

        crops = manifest.get("crops", {})

        for cid, entry in crops.items():
            if cid in GOLD_CROPS:
                entry["status"] = "verified"
                entry["confidence_level"] = "high"
                entry["notes"] = ["Gold-standard profile verified against ICAR & CIBRC standards."]
            elif cid in REVERT_CROPS:
                entry["status"] = "needs_review"
                entry["confidence_level"] = "low"
                entry["notes"] = [
                    "Flagged during Agricultural Safety Audit: Chemical recommendations contain placeholder doses ('as per CIBRC label'), missing PHI, or formulation/method discrepancies. Reverted to needs_review pending manual label verification."
                ]

        # Calculate actual counts
        counts = {"verified": 0, "needs_review": 0, "not_started": 0}
        for entry in crops.values():
            st = entry.get("status", "not_started")
            counts[st] = counts.get(st, 0) + 1

        manifest["last_updated"] = datetime.now(timezone.utc).isoformat()
        manifest["summary_counts"] = counts

        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)

        print(f"Manifest at {manifest_path} updated:")
        print(f"  Verified: {counts.get('verified', 0)}")
        print(f"  Needs Review: {counts.get('needs_review', 0)}")
        print(f"  Not Started: {counts.get('not_started', 0)}")
        print(f"  Total: {len(crops)}")

if __name__ == "__main__":
    update_manifest()

