"""Agricultural chemical and medicine dosage validation engine conforming to CIBRC & ICAR standards."""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

# Banned or severely restricted agrochemicals under CIBRC / Insecticides Act 1968
BANNED_CHEMICALS_INDIA = {
    "endosulfan",
    "monocrotophos",  # Banned on vegetables and household
    "paraquat",
    "aldicarb",
    "chlordane",
    "ddt",
    "diazinon",
    "dieldrin",
    "methyl parathion",
    "phorate",        # Banned on select crops
    "phosphamidon",
    "sodium cyanide",
    "lindane",
}

# Standard recommended dosage database for common agricultural chemicals (per 15L pump)
# Maps chemical lowercase -> { "max_dose_per_15L": float, "unit": "ml"|"g", "recommended_range": str, "target_pests": List[str] }
APPROVED_DOSAGE_DATABASE: Dict[str, Dict[str, Any]] = {
    "neem oil": {
        "max_dose_per_15L": 75.0,
        "unit": "ml",
        "recommended_range": "40-60 ml per 15 liter pump",
        "description": "Natural bio-pesticide (1500 ppm)",
    },
    "chlorantraniliprole": {  # Coragen
        "max_dose_per_15L": 8.0,
        "unit": "ml",
        "recommended_range": "6-7 ml per 15 liter pump (or 60 ml/acre)",
        "description": "Lepidopteran pest specialist (bollworm, stem borer)",
    },
    "emamectin benzoate": {
        "max_dose_per_15L": 10.0,
        "unit": "g",
        "recommended_range": "7-10 g per 15 liter pump",
        "description": "Effective against caterpillars and bollworms",
    },
    "imidacloprid": {
        "max_dose_per_15L": 7.0,
        "unit": "ml",
        "recommended_range": "3-5 ml per 15 liter pump (17.8% SL)",
        "description": "Systemic insecticide for sucking pests (aphids, jassids)",
    },
    "thiamethoxam": {
        "max_dose_per_15L": 10.0,
        "unit": "g",
        "recommended_range": "5-8 g per 15 liter pump (25% WG)",
        "description": "Sucking pest control",
    },
    "mancozeb": {
        "max_dose_per_15L": 40.0,
        "unit": "g",
        "recommended_range": "30-35 g per 15 liter pump (75% WP)",
        "description": "Broad-spectrum contact fungicide",
    },
    "carbendazim": {
        "max_dose_per_15L": 25.0,
        "unit": "g",
        "recommended_range": "15-20 g per 15 liter pump",
        "description": "Systemic fungicide",
    },
    "copper oxychloride": {
        "max_dose_per_15L": 45.0,
        "unit": "g",
        "recommended_range": "35-40 g per 15 liter pump",
        "description": "Copper fungicide/bactericide (never mix with alkaline pesticides)",
    },
    "hexaconazole": {
        "max_dose_per_15L": 35.0,
        "unit": "ml",
        "recommended_range": "25-30 ml per 15 liter pump",
        "description": "Fungicide for powdery mildew and rust",
    },
    "trichoderma viride": {
        "max_dose_per_15L": 75.0,
        "unit": "g",
        "recommended_range": "50-60 g per 15 liter pump or soil application",
        "description": "Bio-fungicide for root rot and wilt prevention",
    },
    "pseudomonas fluorescens": {
        "max_dose_per_15L": 75.0,
        "unit": "g",
        "recommended_range": "50-60 g per 15 liter pump",
        "description": "Beneficial bio-control agent",
    },
    "magnesium sulphate": {
        "max_dose_per_15L": 200.0,
        "unit": "g",
        "recommended_range": "150 g per 15 liter pump (10 g/L or 1.5 kg/acre in 150-200 L water)",
        "description": "Foliar nutrient for correcting magnesium deficiency and leaf reddening (Lalio) in cotton",
    },
    "urea": {
        "max_dose_per_15L": 150.0,
        "unit": "g",
        "recommended_range": "100-150 g per 15 liter pump (1% spray for synergistic foliar absorption)",
        "description": "Foliar nitrogen supplement",
    },
    "propiconazole": {
        "max_dose_per_15L": 20.0,
        "unit": "ml",
        "recommended_range": "15-20 ml per 15 liter pump (25% EC)",
        "description": "Systemic triazole fungicide for rust and leaf spots",
    },
}

INCOMPATIBLE_COMBINATIONS = [
    ("copper oxychloride", "chlorpyrifos", "Copper reacts with organophosphates causing phytotoxicity."),
    ("trichoderma", "carbendazim", "Chemical fungicides kill beneficial biological agents like Trichoderma."),
    ("trichoderma", "mancozeb", "Chemical fungicides kill beneficial biological agents."),
    ("sulfur", "neem oil", "Applying sulfur within 14 days of oil application burns crop foliage."),
]


class MedicineValidator:
    """Validates agricultural chemical recommendations, dosages, and safety standards."""

    @classmethod
    def check_banned_substances(cls, text: str) -> List[str]:
        """Detects if text references banned agricultural chemicals in India."""
        found_banned = []
        text_lower = text.lower()
        for chemical in BANNED_CHEMICALS_INDIA:
            if re.search(r"\b" + re.escape(chemical) + r"\b", text_lower):
                found_banned.append(chemical)
        return found_banned

    @classmethod
    def check_incompatible_combinations(cls, text: str) -> List[str]:
        """Flags dangerous chemical mixtures mentioned in text."""
        warnings = []
        text_lower = text.lower()
        for chem_a, chem_b, reason in INCOMPATIBLE_COMBINATIONS:
            if chem_a in text_lower and chem_b in text_lower:
                warnings.append(f"Hazardous Mixture Alert: Do NOT mix '{chem_a}' and '{chem_b}'. {reason}")
        return warnings

    @classmethod
    def extract_and_validate_dosage(
        cls,
        text: str,
    ) -> Dict[str, Any]:
        """Extracts dosages mentioned in text and validates against CIBRC/ICAR thresholds."""
        text_lower = text.lower()
        excessive_doses = []
        safe_recommendations = []

        for chemical, info in APPROVED_DOSAGE_DATABASE.items():
            if chemical in text_lower:
                # Look for dosage patterns: e.g. "15 ml", "20g", "30 ml per pump"
                pattern = rf"(\d+(?:\.\d+)?)\s*(?:ml|g|gm|grams|milliliters?)\b"
                matches = re.finditer(pattern, text_lower)
                for m in matches:
                    val = float(m.group(1))
                    # Check if val is in a reasonable single-pump range
                    if val > info["max_dose_per_15L"] * 1.5 and val < 500:
                        excessive_doses.append(
                            f"Warning: Dose of {val} {info['unit']} for '{chemical}' appears higher than ICAR limit ({info['recommended_range']}). Overdosing harms crops and causes soil toxicity."
                        )
                safe_recommendations.append({
                    "chemical": chemical.title(),
                    "recommended_dosage": info["recommended_range"],
                    "description": info["description"],
                })

        return {
            "excessive_dosage_warnings": excessive_doses,
            "approved_reference_doses": safe_recommendations,
        }

