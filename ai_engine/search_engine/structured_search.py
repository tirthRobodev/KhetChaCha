"""Structured Crop Knowledge Search Engine for KhetChacha.

Searches gold-standard verified crop profiles, disease records, and pest records
from data/knowledge/ directory.
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from ai_engine.models.response_models import EvidenceSource

logger = logging.getLogger(__name__)


class StructuredKnowledgeSearchEngine:
    """Searches structured JSON crop profiles, disease records, and pest records."""

    def __init__(self, knowledge_dir: Optional[Path] = None):
        if knowledge_dir is None:
            self.knowledge_dir = Path(__file__).resolve().parent.parent / "data" / "knowledge"
        else:
            self.knowledge_dir = Path(knowledge_dir)

        self.profiles_dir = self.knowledge_dir / "crop_profiles"
        self.diseases_dir = self.knowledge_dir / "disease_records"
        self.pests_dir = self.knowledge_dir / "pest_records"

    def search(
        self,
        query: str,
        crop: Optional[str] = None,
        top_k: int = 4,
        min_score: float = 0.25,
    ) -> List[EvidenceSource]:
        """Searches disease records, pest records, and crop profiles matching the query."""
        results: List[EvidenceSource] = []
        q_lower = query.lower()
        crop_lower = crop.lower() if crop else ""

        # Key agricultural synonym terms
        terms = [t for t in q_lower.replace("?", "").replace("!", "").split() if len(t) > 1]

        # 1. Search Disease Records
        if self.diseases_dir.exists():
            for fpath in self.diseases_dir.glob("*.json"):
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    score = self._compute_record_match(data, q_lower, crop_lower, terms)
                    if score >= min_score:
                        snippet = self._format_disease_snippet(data)
                        name_gu = data.get("name", {}).get("gu", "")
                        name_en = data.get("name", {}).get("en", "")
                        title = f"{name_gu} ({name_en})" if name_gu else name_en
                        results.append(
                            EvidenceSource(
                                title=title,
                                document_name=fpath.name,
                                source_type="structured_knowledge",
                                page_or_section="Disease Record & CIBRC Solutions",
                                snippet=snippet,
                                confidence_score=score,
                            )
                        )
                except Exception as e:
                    logger.debug(f"Error reading disease file {fpath}: {e}")

        # 2. Search Pest Records
        if self.pests_dir.exists():
            for fpath in self.pests_dir.glob("*.json"):
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    score = self._compute_record_match(data, q_lower, crop_lower, terms)
                    if score >= min_score:
                        snippet = self._format_pest_snippet(data)
                        name_gu = data.get("name", {}).get("gu", "")
                        name_en = data.get("name", {}).get("en", "")
                        title = f"{name_gu} ({name_en})" if name_gu else name_en
                        results.append(
                            EvidenceSource(
                                title=title,
                                document_name=fpath.name,
                                source_type="structured_knowledge",
                                page_or_section="Pest Record & IPM Solutions",
                                snippet=snippet,
                                confidence_score=score,
                            )
                        )
                except Exception as e:
                    logger.debug(f"Error reading pest file {fpath}: {e}")

        # 3. Search Crop Profiles
        if self.profiles_dir.exists():
            for fpath in self.profiles_dir.glob("*.json"):
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    score = self._compute_profile_match(data, q_lower, crop_lower, terms)
                    if score >= min_score:
                        snippet = self._format_profile_snippet(data)
                        primary_name = data.get("primary_name", fpath.stem)
                        gu_name = data.get("names", {}).get("gu", "")
                        title = f"{gu_name} ({primary_name})" if gu_name else primary_name
                        results.append(
                            EvidenceSource(
                                title=title,
                                document_name=fpath.name,
                                source_type="structured_knowledge",
                                page_or_section="Crop Cultivation Profile",
                                snippet=snippet,
                                confidence_score=score,
                            )
                        )
                except Exception as e:
                    logger.debug(f"Error reading profile file {fpath}: {e}")

        # Sort by confidence score descending
        results.sort(key=lambda s: s.confidence_score, reverse=True)
        return results[:top_k]

    def _compute_record_match(
        self,
        data: Dict[str, Any],
        q_lower: str,
        crop_lower: str,
        terms: List[str],
    ) -> float:
        score = 0.0
        record_crop = str(data.get("crop_id", "")).lower()

        # Crop matching bonus
        if crop_lower and (crop_lower in record_crop or record_crop in crop_lower):
            score += 0.40
        elif record_crop in q_lower:
            score += 0.35

        # Name matching
        names = data.get("name", {})
        for lang_code, name_val in names.items():
            nv_lower = str(name_val).lower()
            if q_lower in nv_lower or any(t in nv_lower for t in terms if len(t) > 2):
                score += 0.45
                break

        # Specific symptom / causal agent matching
        symptoms = " ".join(data.get("symptoms", [])).lower()
        if any(t in symptoms for t in terms if len(t) > 2):
            score += 0.20

        # Special keywords (yellowing, tikka, blight, rust, પીળા, ટિક્કા, સુકારો, ગેરુ)
        special_keywords = {
            "yellow": ["cotton_leaf_yellowing"],
            "yellowing": ["cotton_leaf_yellowing"],
            "પીળા": ["cotton_leaf_yellowing"],
            "લાલિયો": ["cotton_leaf_yellowing"],
            "lalio": ["cotton_leaf_yellowing"],
            "tikka": ["groundnut_tikka_disease"],
            "ટિક્કા": ["groundnut_tikka_disease"],
            "blight": ["tomato_early_blight"],
            "સુકારો": ["tomato_early_blight"],
            "rust": ["wheat_rust"],
            "ગેરુ": ["wheat_rust"],
            "bollworm": ["cotton_pink_bollworm"],
            "ગુલાબી": ["cotton_pink_bollworm"],
            "hopper": ["mango_hopper"],
            "મધિયો": ["mango_hopper"],
            "chana": ["chickpea_pod_borer"],
            "પોપટા": ["chickpea_pod_borer"],
        }
        for kw, prob_ids in special_keywords.items():
            if kw in q_lower and data.get("problem_id") in prob_ids:
                score += 0.40

        return min(0.98, score)

    def _compute_profile_match(
        self,
        data: Dict[str, Any],
        q_lower: str,
        crop_lower: str,
        terms: List[str],
    ) -> float:
        score = 0.0
        crop_id = str(data.get("crop_id", "")).lower()
        primary_name = str(data.get("primary_name", "")).lower()

        if crop_lower and (crop_lower in crop_id or crop_id in crop_lower):
            score += 0.50
        elif crop_id in q_lower or primary_name in q_lower:
            score += 0.45

        gu_name = str(data.get("names", {}).get("gu", "")).lower()
        if gu_name and gu_name in q_lower:
            score += 0.50

        return min(0.95, score)

    def _format_disease_snippet(self, data: Dict[str, Any]) -> str:
        parts = []
        name_gu = data.get("name", {}).get("gu", "")
        name_en = data.get("name", {}).get("en", "")
        parts.append(f"રોગ/સમસ્યા: {name_gu} ({name_en})")
        if data.get("causal_agent"):
            parts.append(f"કારક: {data.get('causal_agent')}")

        symptoms = data.get("symptoms", [])
        if symptoms:
            parts.append(f"લક્ષણો: {'; '.join(symptoms[:2])}")

        prevention = data.get("prevention", [])
        if prevention:
            parts.append(f"અટકાવવાના પગલાં: {'; '.join(prevention[:2])}")

        org_opts = data.get("organic_options", [])
        if org_opts:
            o = org_opts[0]
            dose_str = o.get("dosage") or o.get("dose") or "ભલામણ મુજબ"
            parts.append(f"જૈવિક/ઓર્ગેનિક ઉપાય: {o.get('treatment_name')} - {dose_str} ({o.get('application_method', 'Foliar spray')})")

        chem_opts = data.get("chemical_options", [])
        if chem_opts:
            c = chem_opts[0]
            ai = c.get("active_ingredient") or c.get("chemical_name", "")
            form = c.get("formulation", "")
            dose = c.get("dose") or c.get("dosage", "")
            unit = c.get("unit", "")
            dilution = c.get("dilution", "")
            phi = c.get("pre_harvest_interval_days") or c.get("waiting_period_days")
            vstatus = c.get("verification_status", "unspecified")

            if vstatus == "verified" and dose and dose != "null" and "as per CIBRC label" not in str(dose):
                phi_str = f" પ્રતીક્ષા સમય: {phi} દિવસ." if phi is not None else ""
                parts.append(
                    f"પ્રમાણિત રાસાયણિક ઉપાય: {ai} {form} - પ્રમાણ: {dose} {unit} (પાણી: {dilution}).{phi_str}"
                )
            else:
                parts.append(
                    f"[ચકાસણી હેઠળ રાસાયણિક ઉપાય]: {ai} {form} - નોંધ: ચોક્કસ ડોઝ અને ભલામણ ચકાસણી હેઠળ છે. કૃપા કરીને સ્થાનિક KVK અથવા કૃષિ અધિકારીની સલાહ લીધા બાદ જ ઉપયોગ કરવો."
                )

        return " | ".join(parts)

    def _format_pest_snippet(self, data: Dict[str, Any]) -> str:
        parts = []
        name_gu = data.get("name", {}).get("gu", "")
        name_en = data.get("name", {}).get("en", "")
        parts.append(f"જીવાત: {name_gu} ({name_en})")
        if data.get("scientific_name"):
            parts.append(f"વૈજ્ઞાનિક નામ: {data.get('scientific_name')}")

        etl = data.get("economic_threshold_level", {})
        if etl:
            parts.append(f"આર્થિક ક્ષમ્ય મર્યાદા (ETL): {etl.get('threshold_description', '')}")

        bio = data.get("biological_management", [])
        if bio:
            parts.append(f"જૈવિક નિયંત્રણ: {'; '.join(bio[:2])}")

        chem_opts = data.get("chemical_options", [])
        if chem_opts:
            c = chem_opts[0]
            ai = c.get("active_ingredient") or c.get("chemical_name", "")
            form = c.get("formulation", "")
            dose = c.get("dose") or c.get("dosage", "")
            unit = c.get("unit", "")
            dilution = c.get("dilution", "")
            phi = c.get("pre_harvest_interval_days") or c.get("waiting_period_days")
            vstatus = c.get("verification_status", "unspecified")

            if vstatus == "verified" and dose and dose != "null" and "as per CIBRC label" not in str(dose):
                phi_str = f" પ્રતીક્ષા સમય: {phi} દિવસ." if phi is not None else ""
                parts.append(
                    f"પ્રમાણિત રસાયણ: {ai} {form} - ડોઝ: {dose} {unit} ({dilution}).{phi_str}"
                )
            else:
                parts.append(
                    f"[ચકાસણી હેઠળ રસાયણ]: {ai} {form} - નોંધ: ડોઝ ચકાસણી હેઠળ છે, સ્થાનિક નિષ્ણાતની સલાહ વગર છંટકાવ ન કરવો."
                )

        return " | ".join(parts)

    def _format_profile_snippet(self, data: Dict[str, Any]) -> str:
        primary = data.get("primary_name", "")
        gu_name = data.get("names", {}).get("gu", "")
        botanical = data.get("botanical_name", "")
        season = data.get("season", "")
        soils = ", ".join(data.get("soil_types", []))
        return f"પાક પ્રોફાઇલ: {gu_name} ({primary} - {botanical}) | ઋતુ: {season} | અનુકૂળ જમીન: {soils}"

