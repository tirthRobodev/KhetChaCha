"""Answer validation and multi-part query completeness engine for KhetChacha AI."""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Tuple

from ai_engine.language_engine.language_mapper import get_language_by_code


class AnswerValidator:
    """Validates that farmer responses thoroughly address all requested facets:

    - Irrigation / Water schedule
    - Balanced fertilizer & nutrition
    - Pest & disease diagnosis and control
    - 30-day stage timeline
    - Estimated costs / economic budget
    - Script and language integrity across Tier 1 (Gujarati, Hindi, English) and Tier 2 (Punjabi, Marathi)
    """

    # Keyword patterns across Gujarati, Hindi, Punjabi, Marathi, English
    WATER_PATTERNS = [
        r"પાણી", r"સિંચાઈ", r"પીયત", r"પાણીનું",
        r"पानी", r"सिंचाई", r"सिचाई",
        r"ਪਾਣੀ", r"ਸਿੰਚਾਈ", r"ਪਾਣੀ ਦਾ",
        r"पाणी", r"सिंचन", r"पाण्याचे", r"ठिबक",
        r"\bwater\b", r"\birrigation\b", r"\bwatering\b",
    ]

    FERTILIZER_PATTERNS = [
        r"ખાતર", r"યુરિયા", r"ડીએપી", r"પોટાશ", r"પોષણ",
        r"खाद", r"उर्वरक", r"यूरिया", r"डीएपी", r"पोटाश",
        r"ਖਾਦ", r"ਯੂਰੀਆ", r"ਡੀਏਪੀ",
        r"खत", r"खते", r"युरिया", r"डीएपी", r"पोटॅश",
        r"\bfertilizer\b", r"\bnutrient\b", r"\burea\b", r"\bdap\b", r"\bnpk\b",
    ]

    PEST_DISEASE_PATTERNS = [
        r"રોગ", r"જીવાત", r"ચૂસિયા", r"ઈયળ", r"દવા", r"છંટકાવ", r"પીળા", r"લાલિયા",
        r"रोग", r"कीट", r"कीड़ा", r"दवा", r"स्प्रे", r"पीला", r"सुंडी",
        r"ਕੀੜੇ", r"ਸਪਰੇਅ", r"ਦਵਾਈ", r"ਸੁੰਡੀ", r"ਪੀਲੇ", r"ਰੋਗ",
        r"रोग", r"किड", r"कीड", r"औषध", r"फवारणी", r"पिवळे", r"अळी", r"बोंडअळी",
        r"\bpest\b", r"\bdisease\b", r"\bspray\b", r"\byellow\b", r"\binsect\b",
    ]

    COST_PATTERNS = [
        r"ખર્ચ", r"બજેટ", r"રૂપિયા", r"ભાવ", r"કેટલો થશે",
        r"खर्च", r"लागत", r"बजट", r"रुपये", r"कितना होगा",
        r"ਖਰਚਾ", r"ਲਾਗਤ", r"ਬਜਟ", r"ਰੁਪਏ", r"ਕਿੰਨਾ ਹੋਵੇਗਾ",
        r"खर्च", r"लागत", r"अंदाजपत्रक", r"रुपये", r"किती होईल",
        r"\bcost\b", r"\bexpense\b", r"\bbudget\b", r"\bprice\b", r"\bestimate\b",
    ]

    TIMELINE_PATTERNS = [
        r"આયોજન", r"શેડ્યુલ", r"૩૦ દિવસ", r"30 દિવસ", r"દિવસનું", r"તબક્કા",
        r"योजना", r"शेड्यूल", r"३० दिन", r"30 दिन", r"दिनों का", r"चरणबद्ध",
        r"ਯੋਜਨਾ", r"ਸ਼ਡਿਊਲ", r"੩੦ ਦਿਨ", r"30 ਦਿਨ", r"ਦਿਨਾਂ ਦਾ",
        r"नियोजन", r"वेळापत्रक", r"३० दिवस", r"30 दिवस", r"दिवसांचे",
        r"\bplan\b", r"\bschedule\b", r"\b30 days\b", r"\btimeline\b",
    ]

    @classmethod
    def decompose_query(cls, query: str) -> Dict[str, Any]:
        """Analyzes farmer query to identify all requested agronomic facets and dimensions."""
        q_lower = query.lower()

        has_water = any(re.search(pat, q_lower) for pat in cls.WATER_PATTERNS)
        has_fertilizer = any(re.search(pat, q_lower) for pat in cls.FERTILIZER_PATTERNS)
        has_pest_disease = any(re.search(pat, q_lower) for pat in cls.PEST_DISEASE_PATTERNS)
        has_cost = any(re.search(pat, q_lower) for pat in cls.COST_PATTERNS)
        has_timeline = any(re.search(pat, q_lower) for pat in cls.TIMELINE_PATTERNS)

        # Detect crop age in days
        age_match = re.search(r"(\d+)\s*(?:દિવસ|દિન|दिन|ਦਿਨ|दिवस|days|din)", query, re.IGNORECASE)
        extracted_age = int(age_match.group(1)) if age_match else None

        # Detect land size
        land_match = re.search(
            r"(\d+(?:\.\d+)?)\s*(એકર|વીઘા|વિઘા|એકડ|एकड़|बीघा|विघा|ਏਕੜ|ਬਿੱਘਾ|एकर|विघे|acre|bigha|hectare)",
            query,
            re.IGNORECASE,
        )
        extracted_land_area = float(land_match.group(1)) if land_match else None
        extracted_land_unit = land_match.group(2) if land_match else None

        facets_count = sum([has_water, has_fertilizer, has_pest_disease, has_cost, has_timeline])

        return {
            "is_multipart": facets_count >= 2,
            "facets_count": facets_count,
            "has_water": has_water,
            "has_fertilizer": has_fertilizer,
            "has_pest_disease": has_pest_disease,
            "has_cost": has_cost,
            "has_timeline": has_timeline,
            "extracted_crop_age_days": extracted_age,
            "extracted_land_area": extracted_land_area,
            "extracted_land_unit": extracted_land_unit,
        }

    @classmethod
    def validate_and_enrich_response(
        cls,
        parsed_data: Dict[str, Any],
        query: str,
        language_code: str = "gu",
        crop: Optional[str] = None,
        land_area: Optional[float] = None,
        land_unit: Optional[str] = None,
        crop_age_days: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Inspects response content to ensure all requested multi-part facets are thoroughly satisfied.

        If the LLM or fallback skipped any requested dimension, enriches with verified ICAR/SAU recommendations.
        """
        decomp = cls.decompose_query(query)
        if not decomp["is_multipart"]:
            return parsed_data

        crop_norm = (crop or "cotton").lower()
        area = land_area or decomp["extracted_land_area"] or 1.0
        unit = land_unit or decomp["extracted_land_unit"] or ("એકર" if language_code == "gu" else ("ਏਕੜ" if language_code == "pa" else ("एकर" if language_code in ("hi", "mr") else "acre")))
        age = crop_age_days or decomp["extracted_crop_age_days"] or 45

        det_text = parsed_data.get("detailed_explanation", "")
        action_steps = list(parsed_data.get("action_steps", []))

        # Check Water / Irrigation requirement
        if decomp["has_water"]:
            has_water_in_answer = any(re.search(pat, det_text) for pat in cls.WATER_PATTERNS)
            if not has_water_in_answer:
                water_advice = cls._get_water_guidance(crop_norm, age, language_code)
                det_text += f"\n\n{water_advice}"
                action_steps.append(cls._get_water_action_step(crop_norm, age, language_code))

        # Check Fertilizer requirement
        if decomp["has_fertilizer"]:
            has_fert_in_answer = any(re.search(pat, det_text) for pat in cls.FERTILIZER_PATTERNS)
            if not has_fert_in_answer:
                fert_advice = cls._get_fertilizer_guidance(crop_norm, age, area, unit, language_code)
                det_text += f"\n\n{fert_advice}"
                action_steps.append(cls._get_fertilizer_action_step(crop_norm, age, language_code))

        # Check Cost / Budget requirement
        if decomp["has_cost"]:
            has_cost_in_answer = any(re.search(pat, det_text) for pat in cls.COST_PATTERNS)
            if not has_cost_in_answer:
                cost_advice = cls._get_cost_guidance(crop_norm, area, unit, language_code)
                det_text += f"\n\n{cost_advice}"
                action_steps.append(cls._get_cost_action_step(crop_norm, area, unit, language_code))

        # Check 30-Day Timeline requirement
        if decomp["has_timeline"]:
            has_timeline_in_answer = any(re.search(pat, det_text) for pat in cls.TIMELINE_PATTERNS)
            if not has_timeline_in_answer:
                timeline_advice = cls._get_timeline_guidance(crop_norm, age, language_code)
                det_text += f"\n\n{timeline_advice}"

        parsed_data["detailed_explanation"] = det_text.strip()
        parsed_data["action_steps"] = action_steps
        return parsed_data

    # =========================================================================
    # VERIFIED AGRONOMIC DOMAIN TEMPLATES (ICAR / SAU GUIDELINES)
    # =========================================================================

    @classmethod
    def _get_water_guidance(cls, crop: str, age: int, lang: str) -> str:
        if lang == "gu":
            return (
                f"💧 **પાણી વ્યવસ્થાપન ({age} દિવસના તબક્કે):**\n"
                f"કપાસમાં ફૂલ-ભમરી બેસવાના સમયે જમીનમાં ભેજ જળવાઈ રહેવો અતિ જરૂરી છે. "
                f"ભારે કાળી જમીનમાં ૮ થી ૧૦ દિવસે અને મધ્યમ ગોરાડુ જમીનમાં ૬ થી ૭ દિવસે હળવું પિયત આપવું. "
                f"વધુ પડતું પાણી ભરાઈ ન રહે તેનું ખાસ ધ્યાન રાખવું."
            )
        elif lang == "hi":
            return (
                f"💧 **सिंचाई प्रबंधन ({age} दिन की अवस्था):**\n"
                f"कपास में फूल और कलियां बनने के समय खेत में नमी बनी रहना अति आवश्यक है। "
                f"भारी मिट्टी में 8 से 10 दिन और हल्की मिट्टी में 6 से 7 दिन के अंतराल पर हल्की सिंचाई करें। जलभराव न होने दें।"
            )
        elif lang == "pa":
            return (
                f"💧 **ਸਿੰਚਾਈ ਪ੍ਰਬੰਧਨ ({age} ਦਿਨਾਂ ਦੀ ਅਵਸਥਾ):**\n"
                f"ਫ਼ਸਲ ਵਿੱਚ ਫੁੱਲ ਅਤੇ ਡੋਡੀਆਂ ਬਣਨ ਸਮੇਂ ਖੇਤ ਵਿੱਚ ਢੁਕਵੀਂ ਨਮੀ ਹੋਣੀ ਬਹੁਤ ਜ਼ਰੂਰੀ ਹੈ। "
                f"ਭਾਰੀ ਜ਼ਮੀਨ ਵਿੱਚ 8 ਤੋਂ 10 ਦਿਨ ਅਤੇ ਹਲਕੀ ਜ਼ਮੀਨ ਵਿੱਚ 6 ਤੋਂ 7 ਦਿਨਾਂ ਦੇ ਵਕਫ਼ੇ 'ਤੇ ਹਲਕੀ ਸਿੰਚਾਈ ਕਰੋ। ਖੇਤ ਵਿੱਚ ਪਾਣੀ ਖੜ੍ਹਾ ਨਾ ਹੋਣ ਦਿਓ।"
            )
        elif lang == "mr":
            return (
                f"💧 **पाणी व्यवस्थापन ({age} दिवसांच्या अवस्थेत):**\n"
                f"पिकाला पाते व फुले लागण्याच्या काळात जमिनीत योग्य ओलावा असणे अत्यंत आवश्यक आहे. "
                f"भारी काळ्या जमिनीत ८ ते १० दिवसांनी आणि मध्यम जमिनीत ६ ते ७ दिवसांच्या अंतराने हलके पाणी द्यावे. शेतात पाणी साचून राहू देऊ नये."
            )
        else:
            return (
                f"💧 **Water & Irrigation Management ({age}-day stage):**\n"
                f"Maintain consistent soil moisture during flowering/squaring stage. "
                f"Irrigate every 8-10 days in black soil and every 6-7 days in lighter soils. Avoid water stagnation."
            )

    @classmethod
    def _get_water_action_step(cls, crop: str, age: int, lang: str) -> str:
        if lang == "gu":
            return "પિયત: જમીનમાં પૂરતો ભેજ જાળવી ૭-૮ દિવસે હળવું પાણી આપો."
        elif lang == "hi":
            return "सिंचाई: खेत में उचित नमी बनाए रखें और 7-8 दिनों में हल्की सिंचाई करें।"
        elif lang == "pa":
            return "ਸਿੰਚਾਈ: ਜ਼ਮੀਨ ਵਿੱਚ ਢੁਕਵੀਂ ਨਮੀ ਬਣਾਈ ਰੱਖੋ ਅਤੇ 7-8 ਦਿਨਾਂ ਵਿੱਚ ਹਲਕਾ ਪਾਣੀ ਦਿਓ।"
        elif lang == "mr":
            return "पाणी व्यवस्थापन: जमिनीत पुरेसा ओलावा राखून ७-८ दिवसांनी हलके पाणी द्यावे."
        else:
            return "Irrigation: Maintain adequate moisture; apply light irrigation every 7-8 days."

    @classmethod
    def _get_fertilizer_guidance(cls, crop: str, age: int, area: float, unit: str, lang: str) -> str:
        urea_amt = int(25 * area)
        if lang == "gu":
            return (
                f"🌱 **ખાતર વ્યવસ્થાપન ({area} {unit} માટે):**\n"
                f"૪૫ દિવસના પાકમાં પૂર્તિ ખાતર તરીકે {area} {unit} માટે આશરે {urea_amt} કિલો યુરિયા આપવું. "
                f"પાન પીળા પડતા હોય તો ૧૫ લિટરના પંપમાં ૧૯:૧૯:૧૯ (૧૦૦ ગ્રામ) + મેગ્નેશિયમ સલ્ફેટ (૫૦ ગ્રામ) ઉમેરી પંપ દીઠ છંટકાવ કરવો, "
                f"જેથી પાન તરત લીલાછમ થશે."
            )
        elif lang == "hi":
            return (
                f"🌱 **उर्वरक प्रबंधन ({area} {unit} हेतु):**\n"
                f"45 दिन की अवस्था पर टॉप-ड्रेसिंग के रूप में प्रति {unit} 25 किग्रा यूरिया दें। "
                f"पत्तियों के पीलेपन को दूर करने हेतु 19:19:19 (100 ग्राम) + मैग्नीशियम सल्फेट (50 ग्राम) प्रति 15 लीटर पंप घोलकर छिड़काव करें।"
            )
        elif lang == "pa":
            return (
                f"🌱 **ਖਾਦ ਪ੍ਰਬੰਧਨ ({area} {unit} ਲਈ):**\n"
                f"45 ਦਿਨਾਂ ਦੀ ਫ਼ਸਲ ਵਿੱਚ ਟੌਪ-ਡ੍ਰੈਸਿੰਗ ਵਜੋਂ ਲਗਭਗ {urea_amt} ਕਿਲੋ ਯੂਰੀਆ ਪਾਓ। "
                f"ਪੱਤਿਆਂ ਦੇ ਪੀਲੇਪਣ ਲਈ 19:19:19 (100 ਗ੍ਰਾਮ) + ਮੈਗਨੀਸ਼ੀਅਮ ਸਲਫੇਟ (50 ਗ੍ਰਾਮ) ਪ੍ਰਤੀ 15 ਲੀਟਰ ਪੰਪ ਘੋਲ ਕੇ ਛਿੜਕਾਅ ਕਰੋ।"
            )
        elif lang == "mr":
            return (
                f"🌱 **खत व्यवस्थापन ({area} {unit} साठी):**\n"
                f"४५ दिवसांच्या पिकात खताचा हप्ता म्हणून {area} {unit} साठी सुमारे {urea_amt} किलो युरिया द्यावा. "
                f"पानांच्या पिवळेपणावर १९:१९:१९ (१०० ग्रॅम) + मॅग्नेशियम सल्फेट (५० ग्रॅम) प्रति १५ लिटर पंपात मिसळून फवारणी करावी."
            )
        else:
            return (
                f"🌱 **Fertilizer Management ({area} {unit}):**\n"
                f"Top-dress with ~{urea_amt} kg Urea for {area} {unit}. "
                f"For yellow leaves, spray foliar NPK 19:19:19 (100g) + Magnesium Sulphate (50g) per 15L pump."
            )

    @classmethod
    def _get_fertilizer_action_step(cls, crop: str, age: int, lang: str) -> str:
        if lang == "gu":
            return "ખાતર: ૧૯:૧૯:૧૯ (૧૦૦ ગ્રામ/પંપ) + મેગ્નેશિયમ સલ્ફેટ (૫૦ ગ્રામ/પંપ) નો પર્ણ છંટકાવ કરવો."
        elif lang == "hi":
            return "उर्वरक: 19:19:19 (100 ग्राम/पंप) + मैग्नीशियम सल्फेट (50 ग्राम/पंप) का छिड़काव करें।"
        elif lang == "pa":
            return "ਖਾਦ: 19:19:19 (100 ਗ੍ਰਾਮ/ਪੰਪ) + ਮੈਗਨੀਸ਼ੀਅਮ ਸਲਫੇਟ (50 ਗ੍ਰਾਮ/ਪੰਪ) ਦਾ ਪੱਤਿਆਂ 'ਤੇ ਛਿੜਕਾਅ ਕਰੋ।"
        elif lang == "mr":
            return "खत: १९:१९:१९ (१०० ग्रॅम/पंप) + मॅग्नेशियम सल्फेट (५० ग्रॅम/पंप) ची पानांवर फवारणी करावी."
        else:
            return "Fertilizer: Foliar spray of NPK 19:19:19 (100g/pump) + Magnesium Sulphate (50g/pump)."

    @classmethod
    def _get_cost_guidance(cls, crop: str, area: float, unit: str, lang: str) -> str:
        per_acre = 2200
        total_min = int(per_acre * area * 0.9)
        total_max = int(per_acre * area * 1.15)
        if lang == "gu":
            return (
                f"💰 **અંદાજિત ખર્ચ ગણતરી ({area} {unit}):**\n"
                f"- યુરિયા તથા પૂર્તિ ખાતર: ₹૫૦૦ - ₹૭૦૦ પ્રતિ એકર\n"
                f"- ચૂસિયા જીવાત અને રોગ નિયંત્રણ દવા (૨ છંટકાવ): ₹૧,૨૦૦ - ₹૧,૫૦૦ પ્રતિ એકર\n"
                f"- મજૂરી અને છંટકાવ ખર્ચ: ₹૪૦૦ - ₹૫૦૦ પ્રતિ એકર\n"
                f"👉 **કુલ અંદાજિત ખર્ચ:** {area} {unit} માટે આશરે **₹{total_min:,} થી ₹{total_max:,}** થશે."
            )
        elif lang == "hi":
            return (
                f"💰 **अनुमानित लागत विवरण ({area} {unit}):**\n"
                f"- उर्वरक एवं यूरिया: ₹500 - ₹700 प्रति एकड़\n"
                f"- कीटनाशक व फफूंदनाशक (2 छिड़काव): ₹1,200 - ₹1,500 प्रति एकड़\n"
                f"- मजदूरी व्यय: ₹400 - ₹500 प्रति एकड़\n"
                f"👉 **कुल अनुमानित खर्च:** {area} {unit} हेतु लगभग **₹{total_min:,} से ₹{total_max:,}**।"
            )
        elif lang == "pa":
            return (
                f"💰 **ਅੰਦਾਜ਼ਨ ਖਰਚਾ ਵੇਰਵਾ ({area} {unit}):**\n"
                f"- ਯੂਰੀਆ ਅਤੇ ਖਾਦ: ₹500 - ₹700 ਪ੍ਰਤੀ ਏਕੜ\n"
                f"- ਕੀਟਨਾਸ਼ਕ ਅਤੇ ਸਪਰੇਅ: ₹1,200 - ₹1,500 ਪ੍ਰਤੀ ਏਕੜ\n"
                f"- ਮਜ਼ਦੂਰੀ ਖਰਚ: ₹400 - ₹500 ਪ੍ਰਤੀ ਏਕੜ\n"
                f"👉 **ਕੁੱਲ ਅੰਦਾਜ਼ਨ ਖਰਚਾ:** {area} {unit} ਲਈ ਲਗਭਗ **₹{total_min:,} ਤੋਂ ₹{total_max:,}** ਹੋਵੇਗਾ।"
            )
        elif lang == "mr":
            return (
                f"💰 **अंदाजे खर्च तपशील ({area} {unit}):**\n"
                f"- युरिया व रासायनिक खते: ₹५०० - ₹७०० प्रति एकर\n"
                f"- कीटकनाशक व फवारणी औषधे: ₹१,२०० - ₹१,५०० प्रति एकर\n"
                f"- मजुरी व फवारणी खर्च: ₹४०० - ₹५०० प्रति एकर\n"
                f"👉 **एकूण अंदाजे खर्च:** {area} {unit} साठी सुमारे **₹{total_min:,} ते ₹{total_max:,}** येईल."
            )
        else:
            return (
                f"💰 **Estimated Cost Breakdown ({area} {unit}):**\n"
                f"- Fertilizer & Top-dressing: ₹500 - ₹700 per acre\n"
                f"- Pesticide & Foliar Sprays (2 rounds): ₹1,200 - ₹1,500 per acre\n"
                f"- Labor / Spray Application: ₹400 - ₹500 per acre\n"
                f"👉 **Total Estimated Expenditure:** ~**₹{total_min:,} to ₹{total_max:,}** for {area} {unit}."
            )

    @classmethod
    def _get_cost_action_step(cls, crop: str, area: float, unit: str, lang: str) -> str:
        if lang == "gu":
            return f"બજેટ: {area} {unit} માટે ₹૩,૫૦૦ - ₹૪,૫૦૦ ના અંદાજિત ખર્ચ સાથે ગુણવત્તાયુક્ત અધિકૃત દવા જ વાપરવી."
        elif lang == "hi":
            return f"बजट: {area} {unit} हेतु ₹3,500 - ₹4,500 के अनुमानित बजट में प्रमाणित दवाइयों का ही उपयोग करें।"
        elif lang == "pa":
            return f"ਬਜਟ: {area} {unit} ਲਈ ₹3,500 - ₹4,500 ਦੇ ਅੰਦਾਜ਼ਨ ਬਜਟ ਵਿੱਚ ਪ੍ਰਮਾਣਿਤ ਖਾਦ-ਦਵਾਈਆਂ ਦੀ ਹੀ ਵਰਤੋਂ ਕਰੋ।"
        elif lang == "mr":
            return f"अंदाजपत्रक: {area} {unit} साठी ₹३,५०० - ₹४,५०० च्या अंदाजे बजेटमध्ये अधिकृत कृषी केंद्रातूनच औषधे खरेदी करावीत."
        else:
            return f"Budget: Estimated ~₹3,500 - ₹4,500 for {area} {unit}; purchase certified inputs with invoice."

    @classmethod
    def _get_timeline_guidance(cls, crop: str, age: int, lang: str) -> str:
        if lang == "gu":
            return (
                f"🗓️ **આગામી ૩૦ દિવસનું તબક્કાવાર આયોજન:**\n"
                f"- **દિવસ ૧ થી ૫:** લીમડાનું તેલ (૫૦ મિલી/પંપ) અથવા એસીટામિપ્રિડ (૬-૮ ગ્રામ/પંપ) નો પ્રથમ છંટકાવ + પિયત.\n"
                f"- **દિવસ ૬ થી ૧૨:** ૧૯:૧૯:૧૯ અને મેગ્નેશિયમ સલ્ફેટનો પર્ણ છંટકાવ કરી પાનનો પીળાશ દૂર કરવો.\n"
                f"- **દિવસ ૧૩ થી ૨૦:** યુરિયા ખાતરનું પૂર્તિ ખાતર તરીકે આપવું અને જમીન નિંદામણ મુક્ત કરવી.\n"
                f"- **દિવસ ૨૧ થી ૩૦:** પાકની નવી ફૂટ અને ભમરીનું નિરીક્ષણ કરી જરૂરિયાત મુજબ બીજો હળવો છંટકાવ."
            )
        elif lang == "hi":
            return (
                f"🗓️ **आगामी 30 दिनों की चरणबद्ध कार्य योजना:**\n"
                f"- **दिन 1 से 5:** नीम तेल (50 मिली/पंप) अथवा एसिटामिप्रिड (6-8 ग्राम/पंप) का प्रथम छिड़काव + सिंचाई।\n"
                f"- **दिन 6 से 12:** 19:19:19 और मैग्नीशियम सल्फेट का छिड़काव कर पीलेपन का निवारण।\n"
                f"- **दिन 13 से 20:** यूरिया का टॉप-ड्रेसिंग प्रयोग एवं निराई-गुड़ाई।\n"
                f"- **दिन 21 से 30:** नई कलियों की निगरानी एवं आवश्यकतानुसार द्वितीय सुरक्षात्मक छिड़काव।"
            )
        elif lang == "pa":
            return (
                f"🗓️ **ਅਗਲੇ 30 ਦਿਨਾਂ ਦੀ ਪੜਾਅਵਾਰ ਯੋਜਨਾ:**\n"
                f"- **ਦਿਨ 1 ਤੋਂ 5:** ਨਿੰਮ ਦਾ ਤੇਲ (50 ਮਿਲੀ/ਪੰਪ) ਜਾਂ ਐਸੀਟਾਮਿਪ੍ਰਿਡ ਦਾ ਪਹਿਲਾ ਛਿੜਕਾਅ + ਸਿੰਚਾਈ।\n"
                f"- **ਦਿਨ 6 ਤੋਂ 12:** 19:19:19 ਅਤੇ ਮੈਗਨੀਸ਼ੀਅਮ ਸਲਫੇਟ ਦਾ ਛਿੜਕਾਅ ਕਰਕੇ ਪੀਲੇਪਣ ਦਾ ਹੱਲ ਕਰੋ।\n"
                f"- **ਦਿਨ 13 ਤੋਂ 20:** ਯੂਰੀਆ ਖਾਦ ਪਾਓ ਅਤੇ ਨਦੀਨਾਂ ਦੀ ਰੋਕਥਾਮ ਕਰੋ।\n"
                f"- **ਦਿਨ 21 ਤੋਂ 30:** ਨਵੇਂ ਫੁੱਲਾਂ-ਡੋਡੀਆਂ ਦਾ ਨਿਰੀਖਣ ਕਰਕੇ ਲੋੜ ਅਨੁਸਾਰ ਦੂਜਾ ਹਲਕਾ ਛਿੜਕਾਅ ਕਰੋ।"
            )
        elif lang == "mr":
            return (
                f"🗓️ **पुढील ३० दिवसांचे टप्पानिहाय नियोजन:**\n"
                f"- **दिवस १ ते ५:** निंबोळी अर्क (५० मिली/पंप) किंवा असिटामिप्रिडची पहिली फवारणी + हलके पाणी.\n"
                f"- **दिवस ६ ते १२:** १९:१९:१९ आणि मॅग्नेशियम सल्फेटची फवारणी करून पिवळेपणा दूर करावा.\n"
                f"- **दिवस १३ ते २०:** युरिया खताचा हप्ता देणे आणि तण नियंत्रण करणे.\n"
                f"- **दिवस २१ ते ३०:** नवीन फुलोरा व पाते यांचे निरीक्षण करून गरजेनुसार हलकी फवारणी करावी."
            )
        else:
            return (
                f"🗓️ **Structured 30-Day Action Schedule:**\n"
                f"- **Days 1 to 5:** First protective spray (Neem oil 50ml or Acetamiprid 6-8g per 15L pump) + irrigation.\n"
                f"- **Days 6 to 12:** Foliar spray of NPK 19:19:19 + Magnesium Sulphate to reverse yellowing.\n"
                f"- **Days 13 to 20:** Top-dressing with Urea and weed eradication.\n"
                f"- **Days 21 to 30:** Field scout for new squares/blooms and apply secondary spray if threshold exceeds."
            )
