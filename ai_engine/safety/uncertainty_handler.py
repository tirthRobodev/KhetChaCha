"""Uncertainty handler to prevent hallucination when symptoms are ambiguous or information is scarce."""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from ai_engine.language_engine.response_language import ResponseLanguageFormatter


class UncertaintyHandler:
    """Manages low-confidence or ambiguous diagnosis cases."""

    AMBIGUOUS_SYMPTOMS = {
        "leaves drying",
        "plant dying",
        "crop failing",
        "leaves yellowing",
        "yellowing",
        "wilting",
        "dropping flowers",
        "છોડ સુકાઈ રહ્યો છે",
        "પાંદડા સુકાય છે",
        "પાંદડા પીળા થાય છે",
        "પાંદડા પીળા",
        "ફૂલ ખરે છે",
        "છોડ કરમાય છે",
        "पौधा सूख रहा है",
        "पत्तियां पीली पड़ रही हैं",
        "फूल गिर रहे हैं",
    }

    CONFIRMED_DISEASE_KEYWORDS = {
        "tikka", "ટિક્કા", "टिक्का",
        "blight", "સુકારો", "झुलसा",
        "rust", "ગેરુ", "गेरुआ", "रतुआ",
        "blast", "બ્લાસ્ટ",
        "mildew", "છારો", "डाउनी",
        "smut", "કાંગ્યારી",
        "bollworm", "ગુલાબી ઈયળ", "गुलाबी सुंडी",
        "whitefly", "સફેદ માખી", "सफेद मक्खी",
        "hopper", "મધિયો", "હોપર",
        "borer", "ગાભમારો", "તણખલી",
        "magnesium", "મેગ્નેશિયમ",
    }

    KVK_HELPLINE = {
        "gu": "નજીકના કૃષિ વિજ્ઞાન કેન્દ્ર (KVK) અથવા કિસાન કોલ સેન્ટર (ટોલ-ફ્રી નંબર: 1800-180-1551) નો સંપર્ક કરવો.",
        "hi": "नजदीकी कृषि विज्ञान केंद्र (KVK) या किसान कॉल सेंटर (टोल-फ्री नंबर: 1800-180-1551) से संपर्क करें।",
        "en": "Contact your nearest Krishi Vigyan Kendra (KVK) or call the Kisan Call Centre at Toll-Free 1800-180-1551.",
    }

    @classmethod
    def is_query_highly_ambiguous(cls, query: str, detected_crops: List[str], detected_symptoms: List[str]) -> bool:
        """Determines if query has too little specific information to safely recommend strong chemicals."""
        q_clean = query.strip().lower()

        # Very short query without crop
        if len(q_clean.split()) <= 2 and not detected_crops:
            return True

        # Broad ambiguous statement without crop or details
        for amb in cls.AMBIGUOUS_SYMPTOMS:
            if amb in q_clean and not detected_crops:
                return True

        return False

    @classmethod
    def is_single_ambiguous_symptom(cls, query: str, detected_crops: List[str], detected_symptoms: List[str]) -> bool:
        """Determines if query has a known crop but ONLY one ambiguous symptom with no specific disease or pest named."""
        q_clean = query.strip().lower()

        # If a specific confirmed disease/pest keyword is present, it's not ambiguous
        for kw in cls.CONFIRMED_DISEASE_KEYWORDS:
            if kw in q_clean:
                return False

        # If an ambiguous symptom is present and no confirmed keyword
        for amb in cls.AMBIGUOUS_SYMPTOMS:
            if amb in q_clean:
                return True

        return False

    @classmethod
    def generate_differential_diagnosis_response(
        cls,
        query: str,
        language_code: str = "gu",
        detected_crops: Optional[List[str]] = None,
        detected_symptoms: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Builds a structured differential diagnosis distinguishing confirmed from possible diagnosis."""
        crops = detected_crops or []
        crop_name = crops[0] if crops else ("પાક" if language_code == "gu" else "फसल" if language_code == "hi" else "crop")
        symptoms = detected_symptoms or ["લક્ષણો"]
        symptom_str = symptoms[0] if symptoms else "સમસ્યા"
        photo_prompt = ResponseLanguageFormatter.get_photo_request_prompt(language_code)
        kvk_msg = cls.KVK_HELPLINE.get(language_code, cls.KVK_HELPLINE["en"])

        is_cotton = any(c.lower() in ["cotton", "કપાસ", "कपास"] for c in crops) or "cotton" in query.lower() or "કપાસ" in query or "कपास" in query

        if is_cotton:
            if language_code == "gu":
                short_answer = (
                    "ધ્યાન આપો ખેડૂત મિત્ર: તમારા કપાસમાં પાન પીળા પડવા તે એક સંભવિત લક્ષણ (Possible Diagnosis) છે, કોઈ એક પાકો રોગ નથી.\n"
                    "કપાસમાં પાન પીળા થવાના ૪ મુખ્ય કારણો છે:\n"
                    "૧. મેગ્નેશિયમની ઉણપ (લાલિયો): નસો લીલી રહે અને વચ્ચે પીળાશ/લાલાશ થાય. ઉપાય: ૧૫ લીટર પંપમાં ૧૫૦ ગ્રામ મેગ્નેશિયમ સલ્ફેટ (૧૦ ગ્રામ/લીટર) નો છંટકાવ કરવો.\n"
                    "૨. પાણીનો ભરાવો (Waterlogging): મૂળ શ્વાસ ન લઈ શકવાથી પીળાશ આવે. ઉપાય: ખેતરમાંથી તાત્કાલિક પાણીનો નિતાર કરવો (દવા છાંટવી નહીં).\n"
                    "૩. નાઈટ્રોજનની ઉણપ: આખું પાન એકસરખું આછું પીળું પડે.\n"
                    "૪. ચૂસિયા જીવાત (તડતડિયા): પાનની કિનારીઓ પીળી પડી કોકડાઈ જાય. ઉપાય: લીમડાનું તેલ (૫૦ મિલી/પંપ).\n"
                    "ચોક્કસ કારણ જાણ્યા વગર આડેધડ ઝેરી જંતુનાશકો ન છાંટવા."
                )
                detailed = (
                    "કપાસના પાન પીળા થવાનું ઊંડાણપૂર્વક વિશ્લેષણ:\n"
                    "• મેગ્નેશિયમ ઉણપ (લાલિયો): સામાન્ય રીતે ઝીંડવા બેસવાના સમયે (૬૦-૯૦ દિવસે) જૂના પાનમાં નસો લીલી અને વચલો ભાગ પીળો-લાલ થાય છે. "
                    "આ સ્થિતિમાં ૧૫ લીટર પંપમાં ૧૫૦ ગ્રામ મેગ્નેશિયમ સલ્ફેટ (MgSO4) ૧૫ દિવસના અંતરે ૨ વાર છાંટવું.\n"
                    "• પાણીનો ભરાવો: કાળી જમીનમાં ૨૪ કલાકથી વધુ પાણી ભરાયેલું રહે તો મૂળ શ્વાસ લઈ શકતા નથી. પહેલા પાણીનો નિતાર કરવો.\n"
                    f"• જરૂરી પ્રશ્નો: ૧) પીળાશ નસો વચ્ચે છે કે આખા પાનમાં? ૨) જમીનમાં પાણી ભરાયેલું છે? ૩) પાકની ઉંમર કેટલી છે? {photo_prompt} {kvk_msg}"
                )
                action_steps = [
                    "જો પાનની નસો વચ્ચે પીળાશ/લાલાશ હોય તો ૧૫ લીટર પંપમાં ૧૫૦ ગ્રામ મેગ્નેશિયમ સલ્ફેટ (૧૦ ગ્રામ/લીટર) નો છંટકાવ કરવો.",
                    "જો ખેતરમાં પાણી ભરાયેલું હોય તો કોઈ પણ દવા છાંટ્યા વગર ૨૪ કલાકમાં પાણીનો નિતાર કરવો.",
                    "પાનની નીચે તડતડિયા કે થ્રિપ્સ જેવી ચૂસિયા જીવાત તપાસવી.",
                    "પાકની ઉંમર અને પાનનો સ્પષ્ટ ફોટો પાડીને મોકલવો.",
                ]
                precautions = [
                    "પાણી ભરાયેલી સ્થિતિમાં કે પાકા નિદાન વગર રાસાયણિક જંતુનાશક દવા છાંટવી નહીં.",
                    "દવા છાંટતી વખતે માસ્ક અને રબરના મોજા અવશ્ય પહેરવા.",
                    kvk_msg,
                ]
            elif language_code == "hi":
                short_answer = (
                    "ध्यान दें किसान भाई: आपकी कपास की फसल में पत्तियां पीली पड़ना केवल एक संभावित लक्षण (Possible Diagnosis) है, पक्का रोग नहीं।\n"
                    "कपास में पीलापन आने के ४ मुख्य कारण हैं:\n"
                    "१. मैग्नीशियम की कमी (लालिया): नसें हरी रहती हैं और बीच का भाग पीला/लाल होता है। उपाय: १५ लीटर पंप में १५० ग्राम मैग्नीशियम सल्फेट (१० ग्राम/लीटर) का छिड़काव करें।\n"
                    "२. जलभराव (Waterlogging): जड़ों में हवा न मिलने से पीलापन आता है। उपाय: खेत से तुरंत पानी निकालें (दवा का छिड़काव न करें)।\n"
                    "३. नाइट्रोजन की कमी: पूरी पत्ती एकसमान हल्की पीली पड़ जाती है।\n"
                    "४. रसचूसक कीट (हरा तेला/जैसिड): पत्ती के किनारे मुड़ते और पीले होते हैं। उपाय: नीम तेल (५० मिली/पंप)।\n"
                    "सटीक पहचान के बिना जहरीले कीटनाशकों का छिड़काव न करें।"
                )
                detailed = (
                    "कपास में पत्तियों के पीलेपन का वैज्ञानिक विश्लेषण:\n"
                    "• मैग्नीशियम की कमी: बूल/टिंडे बनने की अवस्था में पुरानी पत्तियों की नसें हरी और लैमिना पीली-लाल हो जाती हैं। "
                    "इसके लिए १५ लीटर पंप में १५० ग्राम मैग्नीशियम सल्फेट का घोल बनाकर १५ दिन के अंतराल पर छिड़कें।\n"
                    "• जलभराव: काली मिट्टी में २४ घंटे से अधिक पानी रहने पर जड़ें सांस नहीं ले पातीं। पहले जल निकासी करें।\n"
                    f"• आवश्यक प्रश्न: १) क्या पीलापन नसों के बीच है या पूरी पत्ती पर? २) क्या खेत में पानी जमा है? ३) फसल कितने दिन की है? {photo_prompt} {kvk_msg}"
                )
                action_steps = [
                    "नसों के बीच पीलापन दिखने पर १५ लीटर पंप में १५० ग्राम मैग्नीशियम सल्फेट (१० ग्राम/लीटर) का छिड़काव करें।",
                    "खेत में जलभराव हो तो पहले जलनिकासी करें, रासायनिक दवा न डालें।",
                    "पत्तियों की निचली सतह पर रसचूसक कीटों की जांच करें।",
                    "सटीक निदान के लिए पत्ती की स्पष्ट तस्वीर भेजें।",
                ]
                precautions = [
                    "जलभराव की स्थिति में या बिना पक्के निदान के कीटनाशक का छिड़काव न करें।",
                    "छिड़काव करते समय मास्क और दस्ताने पहनें।",
                    kvk_msg,
                ]
            else:
                short_answer = (
                    "Notice: Cotton leaf yellowing is a non-specific symptom (Possible Diagnosis), not a single confirmed disease.\n"
                    "It commonly stems from 4 distinct agricultural causes:\n"
                    "1. Magnesium Deficiency (Lalio): Veins stay green while interveinal areas turn yellow/red. Remedy: Foliar spray of Magnesium Sulphate @ 10 g/L (150 g per 15L pump).\n"
                    "2. Waterlogging / Poor Aeration: Excess moisture suffocates Vertisol roots. Remedy: Drain standing water within 12-24 hours; do NOT spray chemicals.\n"
                    "3. Nitrogen Deficiency: Uniform pale yellowing of older leaves from bottom up.\n"
                    "4. Sucking Pests (Jassids): Marginal yellowing and downward leaf curling. Remedy: Organic Neem oil (45 ml/pump).\n"
                    "Avoid applying harsh chemical pesticides without confirming the exact cause."
                )
                detailed = (
                    "Agronomic Analysis of Cotton Leaf Yellowing:\n"
                    "• Magnesium Deficiency: Common during peak boll formation (60-90 DAS). Interveinal chlorosis develops into reddish-purple pigmentation under intense sun. Spray 150 g MgSO4 per 15L pump twice at 15-day intervals.\n"
                    "• Waterlogging: Cotton is severely intolerant to >24 hours of standing water. Oxygen starvation causes chlorosis; draining water is the primary corrective action.\n"
                    f"• Diagnostic Questions: 1) Is the yellowing interveinal or whole-leaf? 2) Is there standing water? 3) What is the crop age? {photo_prompt} {kvk_msg}"
                )
                action_steps = [
                    "Spray Magnesium Sulphate @ 10 g/L (150 g per 15-liter pump) if interveinal yellowing is observed.",
                    "Drain excess irrigation or rainwater immediately without applying chemical pesticides.",
                    "Inspect leaf undersides for jassids or thrips.",
                    "Upload a clear close-up photograph of the leaf for confirmed diagnosis.",
                ]
                precautions = [
                    "Do NOT spray pesticides on waterlogged plants with root hypoxia.",
                    "Always wear protective mask and gloves during foliar nutrient application.",
                    kvk_msg,
                ]
            return {
                "short_answer": short_answer,
                "detailed_explanation": detailed,
                "action_steps": action_steps,
                "safety_precautions": precautions,
                "is_differential_diagnosis": True,
                "photo_requested": True,
            }

        if language_code == "gu":
            short_answer = (
                f"ધ્યાન આપો ખેડૂત મિત્ર: તમારા {crop_name}માં '{symptom_str}' એક સંભવિત (Possible) લક્ષણ છે, પાકું નિદાન નથી.\n"
                f"આ લક્ષણ ૩ મુખ્ય કારણોથી હોઈ શકે છે:\n"
                f"૧. પોષકતત્વોની ઉણપ (જેમ કે મેગ્નેશિયમ/નાઈટ્રોજન).\n"
                f"૨. વધુ પડતો ભેજ કે પાણીનો ભરાવો.\n"
                f"૩. પાનની નીચે ચૂસિયા પ્રકારની જીવાતનો ઉપદ્રવ.\n"
                f"ચોક્કસ કારણ જાણ્યા વગર કોઈ પણ જંતુનાશક દવા છાંટવી નહીં."
            )
            detailed = (
                f"વિગતવાર વિશ્લેષણ: માત્ર એક લક્ષણ પરથી કોઈ રોગનું પાકું નિદાન કરવું પાક માટે જોખમી બની શકે છે. "
                f"કૃપા કરીને નીચેની બાબતો તપાસો: ૧) પાનનો ઉપરનો કે નીચેનો ભાગ પીળો/સૂકો છે? ૨) જમીનમાં પાણી ભરાયેલું છે? "
                f"૩) પાનની નીચે ઝીણી જીવાત છે? {photo_prompt} {kvk_msg}"
            )
            action_steps = [
                "પાનની નીચે બારીકાઈથી તપાસો કે લીલા કે સફેદ ચૂસિયા છે કે નહીં.",
                "જો જમીનમાં પાણી ભરાયેલું હોય તો તાત્કાલિક નિતાર કરો.",
                "ચોક્કસ નિદાન માટે પાંદડાનો ફોટો મોકલો અથવા સ્થાનિક KVK સંપર્ક કરો.",
            ]
            precautions = [
                "પાકા નિદાન વગર રાસાયણિક જંતુનાશકોનો આડેધડ છંટકાવ કરવો નહીં.",
                kvk_msg,
            ]
        elif language_code == "hi":
            short_answer = (
                f"ध्यान दें किसान भाई: आपकी {crop_name} फसल में '{symptom_str}' केवल एक संभावित (Possible) लक्षण है, पक्का निदान नहीं।\n"
                f"यह लक्षण ३ कारणों से हो सकता है:\n"
                f"१. पोषक तत्वों (मैग्नीशियम/नाइट्रोजन) की कमी।\n"
                f"२. खेत में जलभराव या अत्यधिक नमी।\n"
                f"३. पत्तियों के नीचे रसचूसक कीटों का प्रकोप।\n"
                f"सटीक पहचान के बिना कोई भी रासायनिक कीटनाशक न छिड़कें।"
            )
            detailed = (
                f"विस्तृत विश्लेषण: सिर्फ एक लक्षण के आधार पर किसी रोग की पुष्टि करना जोखिम भरा हो सकता है। "
                f"कृपया मिट्टी की नमी, फसल की अवस्था और पत्तियों के निचले हिस्से की जांच करें। {photo_prompt} {kvk_msg}"
            )
            action_steps = [
                "पत्तियों के निचली सतह पर रसचूसक कीटों की जांच करें।",
                "खेत में पानी का जमाव हो तो तुरंत जलनिकासी करें।",
                "सटीक समाधान के लिए स्पष्ट तस्वीर भेजें या KVK विशेषज्ञ से मिलें।",
            ]
            precautions = [
                "बिना पुष्टि के रासायनिक दवाओं का अंधाधुंध छिड़काव न करें।",
                kvk_msg,
            ]
        else:
            short_answer = (
                f"Notice: The observed '{symptom_str}' in your {crop_name} is a possible symptom, not a confirmed diagnosis.\n"
                f"It commonly arises from 3 different causes:\n"
                f"1. Nutrient deficiency (such as Magnesium or Nitrogen).\n"
                f"2. Waterlogging or poor root aeration.\n"
                f"3. Sucking pest infestation under leaves.\n"
                f"Do NOT apply synthetic pesticides without confirmed diagnosis."
            )
            detailed = (
                f"Differential Diagnostic Guidance: Diagnosing a specific disease from a single non-specific symptom carries risk of crop damage. "
                f"Please inspect the underside of leaves for pests, verify soil drainage, and observe whether yellowing is interveinal or uniform. {photo_prompt} {kvk_msg}"
            )
            action_steps = [
                "Inspect the underside of lower and middle leaves for sucking pests.",
                "Ensure standing water is drained within 24 hours.",
                "Share a close-up photograph or consult your local KVK agronomist.",
            ]
            precautions = [
                "Avoid indiscriminate chemical pesticide applications without confirmed diagnosis.",
                kvk_msg,
            ]

        return {
            "short_answer": short_answer,
            "detailed_explanation": detailed,
            "action_steps": action_steps,
            "safety_precautions": precautions,
            "is_differential_diagnosis": True,
            "photo_requested": True,
        }

    @classmethod
    def generate_clarification_response(
        cls,
        query: str,
        language_code: str = "gu",
        detected_crops: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Builds a safe, farmer-friendly clarification response requesting a photo or more details."""
        crops = detected_crops or []
        crop_name = crops[0] if crops else ("પાક" if language_code == "gu" else "फसल" if language_code == "hi" else "crop")

        photo_prompt = ResponseLanguageFormatter.get_photo_request_prompt(language_code)
        kvk_msg = cls.KVK_HELPLINE.get(language_code, cls.KVK_HELPLINE["en"])

        if language_code == "gu":
            short_answer = (
                f"નમસ્તે ખેડૂત મિત્ર! તમારા {crop_name}માં લક્ષણો ઘણા સામાન્ય છે, જેથી ચોક્કસ કારણ વગર રાસાયણિક દવાનો છંટકાવ કરવો સલામત નથી.\n\n"
                f"1. કૃપા કરીને પ્રભાવિત પાંદડા અથવા થડનો સ્પષ્ટ ફોટો ખેંચીને મોકલો.\n"
                f"2. પાંદડા નીચે સફેદ કે લીલી જીવાત છે કે થડ કાળું પડ્યું છે તે જણાવો.\n"
                f"3. {kvk_msg}"
            )
            detailed = (
                f"ચોક્કસ નિદાન માટે વધારાની વિગતો જરૂરી છે. વધુ પડતી અથવા ખોટી રાસાયણિક દવાનો ઉપયોગ પાકને નુકસાન પહોંચાડી શકે છે. {photo_prompt}"
            )
        elif language_code == "hi":
            short_answer = (
                f"नमस्ते किसान भाई! आपकी {crop_name} में दिखाई दे रहे लक्षण कई कारणों (पोषण कमी, फंगस या कीट) से हो सकते हैं। बिना सही पहचान के रासायनिक छिड़काव न करें।\n\n"
                f"1. कृपया प्रभावित पत्ते या तने की साफ़ तस्वीर भेजें।\n"
                f"2. क्या पत्तियों के नीचे कोई कीड़ा दिखाई दे रहा है?\n"
                f"3. {kvk_msg}"
            )
            detailed = (
                f"सटीक समाधान हेतु अतिरिक्त जानकारी आवश्यक है। गलत रासायनिक कीटनाशक का उपयोग फसल को नुकसान पहुंचा सकता है। {photo_prompt}"
            )
        else:
            short_answer = (
                f"Greetings! The symptoms on your {crop_name} could be caused by multiple factors (nutrient deficiency, fungal disease, or sucking pests). Applying chemicals without confirmation is not recommended.\n\n"
                f"1. Please share a clear photo of the affected leaves or stem.\n"
                f"2. Check if there are pests on the underside of leaves or wilting at the root.\n"
                f"3. {kvk_msg}"
            )
            detailed = (
                f"Further diagnostic details are needed. Applying unverified chemicals can harm your crop. {photo_prompt}"
            )

        return {
            "short_answer": short_answer,
            "detailed_explanation": detailed,
            "safety_precautions": [kvk_msg],
            "action_steps": [
                "Take a close-up photo of the underside of leaves and root zone.",
                "Check soil moisture levels around the root.",
                "Consult local KVK agronomist before spraying chemicals.",
            ],
            "photo_requested": True,
        }

