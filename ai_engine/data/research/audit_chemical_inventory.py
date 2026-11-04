import json
from pathlib import Path

knowledge_dir = Path("ai_engine/data/knowledge")
total_chems = 0
verified_count = 0
quarantine_count = 0

print("================================================================================")
print("             KHETCHACHA AGROCHEMICAL INVENTORY & SAFETY AUDIT                  ")
print("================================================================================")

for p in sorted(knowledge_dir.rglob("*.json")):
    try:
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        chems = data.get("chemical_options", [])
        if chems:
            print(f"\nFILE: {p.relative_to(knowledge_dir)} ({len(chems)} chemicals)")
            for idx, c in enumerate(chems, 1):
                total_chems += 1
                ai = c.get("active_ingredient", "N/A")
                form = c.get("formulation", "N/A")
                crop = c.get("exact_crop", "N/A")
                target = c.get("target_problem", "N/A")
                dose = c.get("dose", "N/A")
                unit = c.get("unit", "N/A")
                method = c.get("application_method", "N/A")
                phi = c.get("pre_harvest_interval_days", "N/A")
                status = c.get("verification_status", "N/A")
                ppes = c.get("ppe_requirements", [])
                
                if status == "verified":
                    verified_count += 1
                else:
                    quarantine_count += 1

                print(f"  [{idx}] {ai} ({form})")
                print(f"      Crop: {crop} | Target: {target}")
                print(f"      Dose: {dose} {unit} | Method: {method} | PHI: {phi} days")
                print(f"      PPE: {', '.join(ppes) if ppes else 'None specified'}")
                print(f"      Status: {status.upper()}")
    except Exception as e:
        print(f"Error reading {p}: {e}")

print("\n================================================================================")
print(f"TOTAL CHEMICAL OPTIONS AUDITED: {total_chems}")
print(f"VERIFIED AUTHORITATIVE OPTIONS: {verified_count}")
print(f"QUARANTINED / UNVERIFIED OPTIONS: {quarantine_count}")
print("================================================================================")

