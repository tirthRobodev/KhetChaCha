"""Agricultural safety engine enforcing PPE, spray precautions, and environmental safeguards."""

from __future__ import annotations

import re
from typing import Dict, List, Optional
from ai_engine.safety.medicine_validation import MedicineValidator


class SafetyAlert:
    """A safety alert with severity, title, and actionable advice."""

    def __init__(self, severity: str, title: str, message: str):
        self.severity = severity  # 'critical', 'warning', 'info'
        self.title = title
        self.message = message

    def to_dict(self) -> Dict[str, str]:
        return {
            "severity": self.severity,
            "title": self.title,
            "message": self.message,
        }


class AgricultureSafetyEngine:
    """Evaluates agricultural advice for safety, toxicity, and environmental impact."""

    PPE_PRECAUTIONS = {
        "gu": "છંટકાવ કરતી વખતે મોઢા પર માસ્ક, આંખે ચશ્મા અને હાથમાં રબરના મોજા અવશ્ય પહેરો. પવનની દિશામાં જ છંટકાવ કરવો. બાળકો અને પશુઓને દૂર રાખવા.",
        "hi": "छिड़काव करते समय मास्क, दस्ताने और चश्मा अवश्य पहनें। हवा की दिशा में ही स्प्रे करें। बच्चों और पशुओं को छिड़काव क्षेत्र से दूर रखें।",
        "en": "Always wear protective mask, gloves, and eye protection while spraying. Spray in the direction of wind. Keep children and livestock away.",
    }

    WEATHER_PRECAUTIONS = {
        "gu": "છંટકાવ સવારે 10 વાગ્યા પહેલા અથવા સાંજે 4 વાગ્યા પછી કરવો. બપોરે તડકામાં કે વરસાદની આગાહી હોય ત્યારે છંટકાવ ન કરવો.",
        "hi": "छिड़काव सुबह 10 बजे से पहले या शाम 4 बजे के बाद करें। तेज धूप या बारिश की संभावना में छिड़काव न करें।",
        "en": "Spray before 10 AM or after 4 PM. Avoid spraying during peak midday heat, strong wind, or if rain is expected within 6 hours.",
    }

    def evaluate_safety(
        self,
        query: str,
        response_text: str,
        language_code: str = "gu",
        crop: Optional[str] = None,
        action_steps: Optional[List[str]] = None,
        detailed_explanation: Optional[str] = None,
    ) -> List[SafetyAlert]:
        """Evaluates query and proposed response text to generate critical safety alerts."""
        from ai_engine.safety.dosage_validator import DosageConsistencyValidator

        alerts: List[SafetyAlert] = []
        combined_text = f"{query} {response_text}".lower()

        # 0. Unsupported / Non-Selective Chemical Rejection (e.g. weedicides for pest management)
        is_auth, auth_errs = DosageConsistencyValidator.validate_crop_chemical_authorization(
            crop=crop, text=f"{response_text} {' '.join(action_steps or [])} {detailed_explanation or ''}"
        )
        for err in auth_errs:
            alerts.append(
                SafetyAlert(
                    severity="critical",
                    title="Unsupported Weedicide/Chemical Recommendation Safety Alert",
                    message=err,
                )
            )

        # 0b. Contradictory Dosage Rejection across sections
        if action_steps or detailed_explanation:
            cons_rep = DosageConsistencyValidator.validate_cross_section_consistency(
                short_answer=response_text,
                action_steps=action_steps or [],
                detailed_explanation=detailed_explanation or "",
            )
            for c_warn in cons_rep["contradictions"]:
                alerts.append(
                    SafetyAlert(
                        severity="critical",
                        title="Contradictory Dosage Rejection",
                        message=c_warn,
                    )
                )

        # 1. Banned chemicals check
        banned = MedicineValidator.check_banned_substances(combined_text)
        if banned:
            for b in banned:
                alerts.append(
                    SafetyAlert(
                        severity="critical",
                        title="Banned Substance Warning",
                        message=f"'{b.title()}' is banned in India under CIBRC regulations. Do not use this substance. Use approved eco-friendly alternatives.",
                    )
                )

        # 2. Chemical incompatibility check
        incompatibilities = MedicineValidator.check_incompatible_combinations(combined_text)
        for inc in incompatibilities:
            alerts.append(
                SafetyAlert(
                    severity="critical",
                    title="Hazardous Mixture Warning",
                    message=inc,
                )
            )

        # 3. Excessive dosage check
        dosage_info = MedicineValidator.extract_and_validate_dosage(response_text)
        for warn in dosage_info.get("excessive_dosage_warnings", []):
            alerts.append(
                SafetyAlert(
                    severity="warning",
                    title="Dosage Precaution",
                    message=warn,
                )
            )

        # 4. Mandatory PPE alert if any pesticide or chemical is mentioned
        chemical_pattern = re.compile(
            r"spray|pesticide|fungicide|insecticide|pump|છંટકાવ|દવા|દવાનો|કીટનાશક|कीटनाशक|छिड़काव|દવાનો છંટકાવ",
            re.IGNORECASE,
        )
        if chemical_pattern.search(combined_text):
            ppe_text = self.PPE_PRECAUTIONS.get(language_code, self.PPE_PRECAUTIONS["en"])
            alerts.append(
                SafetyAlert(
                    severity="info",
                    title="Personal Protective Equipment (PPE)",
                    message=ppe_text,
                )
            )

            # Spray timing & weather
            weather_text = self.WEATHER_PRECAUTIONS.get(language_code, self.WEATHER_PRECAUTIONS["en"])
            alerts.append(
                SafetyAlert(
                    severity="info",
                    title="Spray Timing Precaution",
                    message=weather_text,
                )
            )

        # 5. Honeybee / Pollinator protection during flowering
        flowering_pattern = re.compile(r"flower|flowering|bloom|ફૂલ|બેસવા|ખરણ|फूल|मंजरी", re.IGNORECASE)
        if flowering_pattern.search(combined_text) and chemical_pattern.search(combined_text):
            alerts.append(
                SafetyAlert(
                    severity="warning",
                    title="Pollinator & Honeybee Protection",
                    message="Crop is in flowering stage. Do not spray harsh chemicals in daytime to protect pollinating bees.",
                )
            )

        return alerts

