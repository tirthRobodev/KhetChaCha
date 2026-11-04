import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

BASE_DIR = Path("D:/KhetChaCha/ai_engine/data")

def audit_all_recommendations():
    base = BASE_DIR / "knowledge"
    records = []
    for sub in ["disease_records", "pest_records"]:
        for f in sorted((base / sub).glob("*.json")):
            with open(f, encoding="utf-8") as fp:
                d = json.load(fp)
            prob = d.get("problem_id")
            crop = d.get("crop_id")
            for c in d.get("chemical_options", []):
                records.append({
                    "file": f.name,
                    "crop": crop,
                    "problem": prob,
                    "type": "chemical",
                    "ai": c.get("active_ingredient"),
                    "form": c.get("formulation"),
                    "dose": c.get("dose"),
                    "unit": c.get("unit"),
                    "method": c.get("application_method"),
                    "phi": c.get("pre_harvest_interval_days"),
                    "sources": c.get("source_ids"),
                    "ver_status": c.get("verification_status", "unspecified"),
                })
            for o in d.get("organic_options", []):
                records.append({
                    "file": f.name,
                    "crop": crop,
                    "problem": prob,
                    "type": "organic",
                    "treatment": o.get("treatment_name"),
                    "dose": o.get("dosage"),
                    "evidence": o.get("evidence_level"),
                    "sources": o.get("source_ids"),
                    "ver_status": o.get("verification_status", "unspecified"),
                })

    print(f"Total recommendations audited: {len(records)}")
    chem_count = sum(1 for r in records if r["type"] == "chemical")
    org_count = sum(1 for r in records if r["type"] == "organic")
    print(f"Chemical: {chem_count}, Organic: {org_count}\n")

    print("=== CHEMICAL RECOMMENDATIONS AUDIT ===")
    for idx, r in enumerate([r for r in records if r["type"] == "chemical"], 1):
        print(f"[{idx:02d}] Crop: {r['crop']:<14} | Problem: {r['problem']:<28}")
        print(f"     AI: {r['ai']} ({r['form']})")
        print(f"     Dose: {r['dose']} {r['unit']} | Method: {r['method']} | PHI: {r['phi']} days")
        print(f"     Sources: {r['sources']}")
        print(f"     File: {r['file']}")
        print("-" * 75)

    print("\n=== ORGANIC RECOMMENDATIONS AUDIT ===")
    for idx, r in enumerate([r for r in records if r["type"] == "organic"], 1):
        tname = r['treatment'][:60] if r['treatment'] else "None"
        print(f"[{idx:02d}] Crop: {r['crop']:<14} | Problem: {r['problem']:<28}")
        print(f"     Treatment: {tname}")
        print(f"     Dose: {r['dose']} | Evidence: {r['evidence']}")
        print(f"     Sources: {r['sources']}")
        print(f"     File: {r['file']}")
        print("-" * 75)

if __name__ == "__main__":
    audit_all_recommendations()
