from typing import Dict, List, Set, Tuple


# Crop keywords mapped to their standard English name
CROP_VOCABULARY: Dict[str, List[str]] = {
    "Cotton": [
        "cotton", "કપાસ", "રૂ", "कपास", "रूई", "ਨਰਮਾ", "ਕਪਾਹ", "कापूस", "பருத்தி", "పత్తి",
        "ಹತ್ತಿ", "പരുത്തി", "তুলা", "କପା", "তুলা", "کپاس"
    ],
    "Wheat": [
        "wheat", "ઘઉં", "गेहूं", "कनक", "ਗੰਦਮ", "गहू", "கோதுமை", "గోధుమలు",
        "ಗೋಧಿ", "ഗോതമ്പ്", "গম", "ଗହମ", "گندم"
    ],
    "Paddy": [
        "paddy", "rice", "ડાંગર", "ચોખા", "ધાન", "चावल", "ਝੋਨਾ", "ਚਾਵਲ", "भात", "तांदूळ",
        "நெல்", "వరి", "ಭತ್ತ", "നെല്ല്", "ধান", "ଧାନ", "چاول", "دھان"
    ],
    "Groundnut": [
        "groundnut", "peanut", "મગફળી", "સીંગ", "मूंगफली", "ਮੂੰਗਫਲੀ", "भुईमूग", "வேர்க்கடலை",
        "వేరుశనగ", "ಕಡಲೆಕಾಯಿ", "നിലക്കടല", "চিনাবাদাম", "ଚିନାବାଦାମ", "مونگ پھلی"
    ],
    "Cumin": [
        "cumin", "જીરું", "જીરૂ", "जीरा", "ਜੀਰਾ", "जिरे", "சீரகம்", "జీలకర్ర",
        "ಜೀರಿಗೆ", "ജീരകം", "জিরে", "ଜିରା", "زیرہ"
    ],
    "Mustard": [
        "mustard", "રાયડો", "રાઈ", "સરસોં", "राई", "ਸਰ੍ਹੋਂ", "मोहरी", "கடுகு", "ఆవాలు",
        "ಸಾಸಿವೆ", "കടുക്", "সরিষা", "ସୋରିଷ", "سرسوں"
    ],
    "Tomato": [
        "tomato", "ટામેટા", "ટામેટી", "टमाटर", "ਟਮਾਟਰ", "टोमॅटो", "தக்காளி", "టమాటా",
        "ಟೊಮೆಟೊ", "തക്കാളി", "টমেটো", "ଟମାଟୋ", "ٹماٹر"
    ],
    "Sugarcane": [
        "sugarcane", "શેરડી", "गन्ना", "ਕਮਾਦ", "ਗੰਨਾ", "ऊस", "கரும்பு", "చెరకు",
        "ಕಬ್ಬು", "കരിമ്പ്", "আখ", "ଆଖୁ", "گنا"
    ],
    "Maize": [
        "maize", "corn", "મકાઈ", "मक्का", "मकई", "ਮੱਕੀ", "मका", "மக்காச்சோளம்", "మొక్కజొన్న",
        "ಮೆಕ್ಕೆಜೋಳ", "ചോളം", "ভুট্টা", "ମକା", "مکئی"
    ],
    "Soybean": [
        "soybean", "સોયાબીન", "सोयाबीन", "ਸੋਇਆਬੀਨ", "சோயாபீன்", "సోయాబీన్",
        "ಸೋಯಾಬೀನ್", "സോയാബീൻ", "সয়াবিন", "ସୋୟାବିନ"
    ],
}

# Symptom keywords mapped to standard agronomic issues
SYMPTOM_VOCABULARY: Dict[str, List[str]] = {
    "leaf_yellowing": [
        "yellow", "chlorosis", "પીળા", "પીળું", "પીળાશ", "પીળા પાન", "पीले", "पीला", "पीलापन",
        "ਪੀਲੇ", "ਪੀਲਾਪਨ", "पिवळे", "पिवळसर", "மஞ்சள்", "పసుపు", "ಹಳದಿ", "മഞ്ഞ", "হলুদ", "ହଳଦିଆ", "پیلا"
    ],
    "pest_infestation": [
        "pest", "insect", "bug", "worm", "જીવાત", "ઈયળ", "કીટક", "ચૂસિયા", "કીડા",
        "कीट", "इल्ली", "कीड़ा", "सूंड़ी", "ਮੱਖੀ", "ਸੁੰਡੀ", "ਕੀੜਾ", "आळी", "किडे", "பூச்சி", "పురుగు",
        "ಕೀಟ", "കീടങ്ങൾ", "পোকা", "ପୋକ", "کیڑے"
    ],
    "pink_bollworm": [
        "pink bollworm", "ગુલાબી ઈયળ", "गुलाबी सुंडी", "गुलाबी इल्ली", "ਗੁਲਾਬੀ ਸੁੰਡੀ",
        "बोंडअळी", "ரோஜா நிற காய்ப்புழு", "గులాబీ రంగు పురుగు", "ಗುಲಾಬಿ ಕಾಯಿ ಕೊರಕ"
    ],
    "leaf_curl": [
        "leaf curl", "curl", "પાન વળવા", "કોકડવા", "पत्ता मरोड़", "ਕੋਕੜੂੰ", "चुरडा मुरडा",
        "இலை சுருட்டை", "ఆకు ముడుత", "ಎಲೆ ಮುದುರುವಿಕೆ", "പച്ചതുള്ളൻ"
    ],
    "wilt_fungus": [
        "wilt", "fungus", "sukara", "સુકારો", "ફૂગ", "ઉધઈ", "उकठा", "झुलसा", "फफूंद",
        "ਉਖੜਾ", "ਉੱਲੀ", "मर", "बुरशी", "வாடல்", "ఎండు తెగులు", "ಸೊರಗು ರೋಗ", "വാട്ടം", "ঢলে পড়া"
    ],
    "blight": [
        "blight", "કરમોડી", "કાળતરો", "झुलसा", "ब्लाइट", "ਝੁਲਸਾ", "करपा", "கருகல்", "మాడు తెగులు", "ಕಮಟು ರೋಗ"
    ],
    "aphids_whitefly": [
        "aphid", "whitefly", "jassid", "મોલો", "મશી", "સફેદ માખી", "માહો", "माहू", "सफेद मक्खी",
        "ਚਿੱਟੀ ਮੱਖੀ", "मावा", "துளிர்ப்பூச்சி", "తెల్ల దోమ", "ಬಿಳಿ ನೊಣ"
    ]
}

# Farming action keywords
ACTION_VOCABULARY: Dict[str, List[str]] = {
    "fertilizer": [
        "fertilizer", "manure", "urea", "dap", "ખાતર", "યુરિયા", "છાણીયું", "દેશી ખાતર", "જીવામૃત",
        "खाद", "उर्वरक", "यूरिया", "जीवामृत", "ਖਾਦ", "ਯੂਰੀਆ", "खत", "उरवरक", "உரம்", "ఎరువు",
        "ಗೊಬ್ಬರ", "വളം", "সার", "ସାର", "کھاد"
    ],
    "pesticide": [
        "pesticide", "insecticide", "spray", "medicine", "દવા", "જંતુનાશક", "છંટકાવ",
        "दवा", "कीटनाशक", "छिड़काव", "ਦਵਾਈ", "ਕੀਟਨਾਸ਼ਕ", "औषध", "कीटकनाशक", "பூச்சிக்கொல்லி",
        "పురుగుమందు", "ಔಷಧ", "കീടനാശിനി", "কীটনাশক", "କୀଟନାଶକ", "دوائی"
    ],
    "irrigation": [
        "irrigation", "water", "પાણી", "પિયત", "ટપક", "સિંચાઈ", "पानी", "सिंचाई", "ड्रिप",
        "ਪਾਣੀ", "ਸਿੰਚਾਈ", "पाणी", "ठिबक", "நீர்", "பாசனம்", "నీరు", "సాగునీరు", "ನೀರು", "വെള്ളം", "জল", "ଜଳସେଚନ", "پانی"
    ]
}


def identify_query_attributes(text: str) -> Dict[str, List[str]]:
    """Identifies crop, symptom, and action taxonomy attributes from natural language query text."""
    t_lower = text.lower()

    detected_crops = []
    for crop_name, variants in CROP_VOCABULARY.items():
        if any(v.lower() in t_lower for v in variants):
            detected_crops.append(crop_name)

    detected_symptoms = []
    for symptom_name, variants in SYMPTOM_VOCABULARY.items():
        if any(v.lower() in t_lower for v in variants):
            detected_symptoms.append(symptom_name)

    detected_actions = []
    for action_name, variants in ACTION_VOCABULARY.items():
        if any(v.lower() in t_lower for v in variants):
            detected_actions.append(action_name)

    return {
        "crops": detected_crops,
        "symptoms": detected_symptoms,
        "actions": detected_actions,
    }


def expand_query_terms(query: str) -> str:
    """
    Expands an Indian regional agricultural query with canonical English keywords
    and disease terms to empower local PDF semantic search and online search.
    Returns expanded space-separated query string.
    """
    q_lower = query.lower()
    expanded_set: Set[str] = set(query.strip().split())

    # 1. Match Crops
    for english_crop, variants in CROP_VOCABULARY.items():
        if any(v.lower() in q_lower for v in variants):
            expanded_set.add(english_crop)
            expanded_set.add(english_crop.lower())

    # 2. Match Symptoms
    for concept, variants in SYMPTOM_VOCABULARY.items():
        if any(v.lower() in q_lower for v in variants):
            expanded_set.add(concept.replace("_", " "))
            expanded_set.update(concept.split("_"))

    # 3. Match Actions
    for action, variants in ACTION_VOCABULARY.items():
        if any(v.lower() in q_lower for v in variants):
            expanded_set.add(action)

    return " ".join(sorted(list(expanded_set)))
