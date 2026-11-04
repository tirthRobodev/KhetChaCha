from typing import Dict
from .language_mapper import SCHEDULED_INDIAN_LANGUAGES, get_language_info


from typing import Dict
from .language_mapper import SCHEDULED_INDIAN_LANGUAGES, get_language_info


# Standardized short agricultural disclaimers in all 22 scheduled Indian languages + English
FALLBACK_INSUFFICIENT_EVIDENCE: Dict[str, str] = {
    "gu": "આ રોગ કે સમસ્યા વિશે સ્થાનિક પુસ્તિકા કે અધિકૃત સ્ત્રોતમાં પૂરતી વિગત મળેલ નથી. ચોક્કસ સલાહ માટે તમારા પાકના પાનનો ફોટો મોકલો અથવા નજીકના કેવીકે (KVK) કે કૃષિ યુનિવર્સિટીનો સંપર્ક કરો.",
    "hi": "इस समस्या के बारे में स्थानीय दस्तावेजों या आधिकारिक स्रोतों में पर्याप्त जानकारी नहीं मिली है। सही समाधान के लिए फसल का स्पष्ट फोटो भेजें या नजदीकी कृषि विज्ञान केंद्र (KVK) से संपर्क करें।",
    "pa": "ਇਸ ਸਮੱਸਿਆ ਬਾਰੇ ਸਾਡੇ ਦਸਤਾਵੇਜ਼ਾਂ ਵਿੱਚ ਪੂਰੀ ਜਾਣਕਾਰੀ ਨਹੀਂ ਮਿਲੀ। ਸਹੀ ਹੱਲ ਲਈ ਫ਼ਸਲ ਦੀ ਫੋਟੋ ਭੇਜੋ ਜਾਂ ਨੇੜਲੇ ਕੇਵੀਕੇ (KVK) ਨਾਲ ਸੰਪਰਕ ਕਰੋ।",
    "mr": "या समस्येबाबत अधिकृत माहिती पुस्तिकेत उपलब्ध नाही. अचूक निदानासाठी पिकाचा फोटो पाठवा किंवा जवळच्या कृषी विज्ञान केंद्राशी (KVK) संपर्क साधा.",
    "bn": "এই সমস্যা সম্পর্কে প্রাতিষ্ঠানিক নথিতে পর্যাপ্ত তথ্য মেলেনি। সঠিক সমাধানের জন্য ফসলের পরিষ্কার ছবি পাঠান বা নিকটস্থ কৃষি বিজ্ঞান কেন্দ্র (KVK)-এর সাথে যোগাযোগ করুন।",
    "te": "ఈ సమస్యకు సంబంధించి అధికారిక రికార్డులలో తగిన సమాచారం లభించలేదు. సరైన పరిష్కారం కొరకు పంట ఫోటో పంపండి లేదా సమీపంలోని కృషి విజ్ఞాన కేంద్రం (KVK) ను సంప్రదించండి.",
    "ta": "இந்த பிரச்சினை குறித்து அதிகாரப்பூர்வ ஆவணங்களில் போதுமான தகவல் கிடைக்கவில்லை. சரியான தீர்வுக்கு பயிரின் புகைப்படத்தை அனுப்பவும் அல்லது அருகிலுள்ள வேளாண் அறிவியல் மையத்தை (KVK) தொடர்பு கொள்ளவும்.",
    "kn": "ಈ ಸಮಸ್ಯೆಯ ಬಗ್ಗೆ ಅಧಿಕೃತ ದಾಖಲೆಗಳಲ್ಲಿ ಸಾಕಷ್ಟು ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ. ನಿಖರ ಪರಿಹಾರಕ್ಕಾಗಿ ಬೆಳೆಯ ಸ್ಪಷ್ಟ ಫೋಟೋ ಕಳುಹಿಸಿ ಅಥವಾ ಹತ್ತಿರದ ಕೃಷಿ ವಿಜ್ಞಾನ ಕೇಂದ್ರವನ್ನು (KVK) ಸಂಪರ್ಕಿಸಿ.",
    "ml": "ഈ പ്രശ്നത്തെക്കുറിച്ച് ഔദ്യോഗിക രേഖകളിൽ മതിയായ വിവരങ്ങൾ ലഭ്യമല്ല. ശരിയായ പരിഹാരത്തിനായി വിളയുടെ വ്യക്തമായ ഫോട്ടോ അയക്കുകയോ അടുത്തുള്ള കൃഷി വിജ്ഞാൻ കേന്ദ്രവുമായി (KVK) ബന്ധപ്പെടുകയോ ചെയ്യുക.",
    "or": "ଏହି ସମସ୍ୟା ବିଷୟରେ ସରକାରୀ ତଥ୍ୟରେ ପର୍ଯ୍ୟାପ୍ତ ସୂଚନା ମିଳିନାହିଁ। ସଠିକ୍ ସମାଧାନ ପାଇଁ ଫସଲର ସ୍ପଷ୍ଟ ଫଟୋ ପଠାନ୍ତୁ କିମ୍ବା ନିକଟସ୍ଥ କୃଷି ବିଜ୍ଞାନ କେନ୍ଦ୍ର (KVK) ସହିତ ଯୋଗାଯୋଗ କରନ୍ତୁ।",
    "as": "এই সমস্যাটোৰ বিষয়ে আধিকাৰিক নথি-পত্ৰত পৰ্যাপ্ত তথ্য পোৱা হোৱা নাই। সঠিক সমাধানৰ বাবে শস্যৰ স্পষ্ট ফটো পঠিয়াওক বা ওচৰৰ কৃষি বিজ্ঞান কেন্দ্ৰ (KVK)ৰ সৈতে যোগাযোগ কৰক।",
    "ur": "اس مسئلے کے بارے میں سرکاری ریکارڈ میں کافی معلومات دستیاب نہیں ہیں۔ درست حل کے لیے فصل کی واضح تصویر بھیجیں یا قریبی کرشی وگیان کیندر (KVK) سے رابطہ کریں۔",
    "sa": "अस्याः समस्यायाः विषये आधिकारिकग्रन्थेषु पर्याप्तविवरणं न लब्धम्। सम्यक् समाधानाय सस्यस्य छायाचित्रं प्रेषयन्तु अथवा निकटे विद्यमानं कृषिविज्ञानकेन्द्रं (KVK) सम्पर्कयन्तु।",
    "kok": "ह्या प्रस्ना खातीर अधिकृत कागदपत्रांनी पुरो तितली म्हायती मेळूंक ना. योग्य समाधाना खातीर पिकाचो फोटो धाडात वा लागींच्या कृषी विज्ञान केंद्रा कडेन (KVK) संपर्क करात.",
    "mai": "ई समस्याक बारे मे आधिकारिक दस्तावेज मे पर्याप्त जानकारी नहि भेटल। सही समाधान लेल फसलक स्पष्ट फोटो पठाउ वा नजदीकी कृषि विज्ञान केंद्र (KVK) सँ संपर्क करू।",
    "ne": "यो समस्याको बारेमा आधिकारिक कागजातहरूमा पर्याप्त जानकारी भेटिएन। सही समाधानको लागि बालीको स्पष्ट तस्बिर पठाउनुहोस् वा नजिकको कृषि विज्ञान केन्द्र (KVK) मा सम्पर्क गर्नुहोस्।",
    "sd": "هن مسئلي بابت سرڪاري دستاويزن ۾ پوري ڄاڻ ناهي ملي. صحيح حل لاءِ فصل جو صاف فوٽو موڪليو يا ويجهي زرعي سائنس مرڪز (KVK) سان رابطو ڪريو.",
    "ks": "یمہ مسلس متعلق چھنہ سرکٲری دستاویزن منٛز پورٕ جانکٲری لبنہ آمژ۔ صٔحیح حل خٲطرٕ سوزیو فصصلک واضح فوٹو یا قریبی کے وی کے (KVK) یس سیت رابطہ کٔریو۔",
    "brx": "बे जेंनानि सोमोन्दै आबुं खारि गैया। मोजां राहा मोननो थाखाय फसलनि गोगो फोटो हर नङाब्ला खाथिनि कृषि विज्ञान केन्द्र (KVK) जों रायज्लाय।",
    "doi": "इस समस्या दे बारे च सरकारी रिकार्ड च पूरी जानकारी नेईं मिली। सही समाधान आस्तै फसल दी साफ़ फोटो भेजो या नेड़े दे कृषि विज्ञान केंद्र (KVK) कन्नै संपर्क करो।",
    "mni": "মসিগী ৱাফম অসিগী মতাংদা অফবা ৱারোল ফংদ্রি। অচুম্বা পাম্বৈগীদমক পাম্বীগী ফোতো থারকউ নত্রগা নকপদা লৈবা ক্রিশি বিজ্ঞান কেন্দ্র (KVK) দা ৱা তনবিউ।",
    "sat": "ᱱᱚᱣᱟ ᱮᱴᱠᱮᱴᱚᱬᱮ ᱵᱟᱵᱚᱛ ᱥᱚᱨᱠᱟᱨᱤ ᱚᱞ ᱨᱮ ᱡᱚᱛᱷᱟᱛ ᱵᱟᱰᱟᱭ ᱵᱟᱹᱱᱩᱜ-ᱟ᱾ ᱥᱟᱹᱨᱤ ᱩᱯᱟᱹᱭ ᱞᱟᱹᱜᱤᱫ ᱯᱷᱚᱥᱚᱞ ᱨᱮᱱᱟᱜ ᱯᱷᱚᱴᱚ ᱵᱷᱮᱡᱟᱭ ᱯᱮ ᱟᱨᱵᱟᱝ ᱥᱩᱨ ᱨᱮᱱᱟᱜ ᱠᱨᱤᱥᱤ ᱵᱤᱜᱽᱭᱟᱱ ᱠᱮᱱᱫᱽᱨᱚ (KVK) ᱥᱟᱞᱟᱜ ᱥᱟᱹᱜᱟᱹᱭ ᱡᱚᱲᱟᱣ ᱯᱮ᱾",
    "en": "Sufficient verified advisory is not found in our records for this query. For an accurate diagnosis, please share a photo of the affected plant or consult your nearest Krishi Vigyan Kendra (KVK).",
}

# Photo request prompts in all 22 scheduled Indian languages + English
PHOTO_REQUEST_PROMPTS: Dict[str, str] = {
    "gu": "ચોક્કસ નિદાન માટે પાંદડા કે જીવાતનો સ્પષ્ટ ફોટો મોકલો.",
    "hi": "सटीक पहचान के लिए प्रभावित पत्ते या कीट का स्पष्ट फोटो भेजें।",
    "pa": "ਸਹੀ ਪਛਾਣ ਲਈ ਪ੍ਰਭਾਵਿਤ ਪੱਤੇ ਜਾਂ ਕੀੜੇ ਦੀ ਫੋਟੋ ਭੇਜੋ।",
    "mr": "अचूक निदानासाठी बाधित पानाचा किंवा किडीचा स्पष्ट फोटो पाठवा.",
    "bn": "সঠিক সনাক্তকরণের জন্য আক্রান্ত পাতা বা পোকার স্পষ্ট ছবি পাঠান।",
    "te": "ఖచ్చితమైన నిర్ధారణ కొరకు ప్రభావిత ఆకు లేదా పురుగు స్పష్టమైన ఫోటో పంపండి.",
    "ta": "துல்லியமான நோயறிதலுக்கு பாதிக்கப்பட்ட இலை அல்லது பூச்சியின் தெளிவான புகைப்படத்தை அனுப்பவும்.",
    "kn": "ನಿಖರ ರೋಗನಿರ್ಣಯಕ್ಕಾಗಿ ಬಾಧಿತ ಎಲೆ ಅಥವಾ ಕೀಟದ ಸ್ಪಷ್ಟ ಫೋಟೋ ಕಳುಹಿಸಿ.",
    "ml": "കൃത്യമായ രോഗനിർണ്ണയത്തിനായി ബാധിച്ച ഇലയുടെയോ കീടത്തിന്റെയോ വ്യക്തമായ ഫോട്ടോ അയയ്ക്കുക.",
    "or": "ସଠିକ୍ ଚିହ୍ନଟ ପାଇଁ ଆକ୍ରାନ୍ତ ପତ୍ର କିମ୍ବା କୀଟର ସ୍ପଷ୍ଟ ଫଟୋ ପଠାନ୍ତୁ।",
    "as": "সঠিক চিনাক্তকৰণৰ বাবে আক্ৰান্ত পাত বা পোকৰ স্পষ্ট ফটো পঠিয়াওক।",
    "ur": "درست تشخیص کے لیے متاثرہ پتے یا کیڑے کی واضح تصویر بھیجیں۔",
    "sa": "सटीकनिर्णयाय प्रभावितपत्रस्य कीटस्य वा स्पष्टं छायाचित्रं प्रेषयन्तु।",
    "kok": "योग्य वळखणे खातीर दूषित पाल्याचो वा किडीचो नितळ फोटो धाडात.",
    "mai": "सटीक पहचान लेल प्रभावित पात वा कीड़क स्पष्ट फोटो पठाउ।",
    "ne": "सटीक पहिचानको लागि प्रभावित पात वा कीराको स्पष्ट तस्बिर पठाउनुहोस्।",
    "sd": "صحيح سڃاڻپ لاءِ متاثر پنن يا جيت جو صاف فوٽو موڪليو.",
    "ks": "صٔحیح پچھان خٲطرٕ سوزیو پترک یا کیمک واضح فوٹو۔",
    "brx": "थार सिनायथि मोननो थाखाय बिलाइ एबा एनज्लानि गोगो फोटो हर।",
    "doi": "सही पन्छान आस्तै असरदार पत्ते या कीड़े दी साफ़ फोटो भेजो।",
    "mni": "অচুম্বা খঙদোকনবগীদমক অশোকপা মনা নত্রগা তিলগী অফবা ফোতো থারকউ।",
    "sat": "ᱥᱟᱹᱨᱤ ᱪᱤᱱᱦᱟᱹᱣ ᱞᱟᱹᱜᱤᱫ ᱥᱟᱠᱟᱢ ᱟᱨᱵᱟᱝ ᱛᱤᱡᱩ ᱨᱮᱱᱟᱜ ᱥᱟᱯᱷᱟ ᱯᱷᱚᱴᱚ ᱵᱷᱮᱡᱟᱭ ᱯᱮ᱾",
    "en": "For an exact diagnosis, please upload a clear photo of the affected leaf or pest.",
}


def get_response_instruction(lang_code: str) -> str:
    """
    Builds the explicit language directive injected into the LLM system prompt.
    Mandates generating response in the farmer's target language.
    """
    info = get_language_info(lang_code)
    if not info:
        info = SCHEDULED_INDIAN_LANGUAGES["en"]

    if info.code == "en":
        return (
            "LANGUAGE REQUIREMENT: Respond entirely in clear, simple English. "
            "Use terms familiar to Indian farmers."
        )

    return (
        f"CRITICAL LANGUAGE REQUIREMENT: You MUST answer ENTIRELY in {info.name} ({info.native_name}) "
        f"using the official {info.script} script. Do NOT reply in English or Romanized transliteration. "
        f"Write in a warm, respectful tone suitable for a rural Indian farmer."
    )


def get_insufficient_evidence_message(lang_code: str) -> str:
    """Returns safe localized message when both local and online search yield no credible match."""
    return FALLBACK_INSUFFICIENT_EVIDENCE.get(
        lang_code,
        FALLBACK_INSUFFICIENT_EVIDENCE["en"]
    )


def get_photo_request_message(lang_code: str) -> str:
    """Returns localized message asking farmer for leaf/pest photo."""
    return PHOTO_REQUEST_PROMPTS.get(
        lang_code,
        PHOTO_REQUEST_PROMPTS["en"]
    )


class ResponseLanguageFormatter:
    """Formatter facade for localized prompt instructions and agricultural messages."""

    @classmethod
    def get_language_system_directive(cls, lang_code: str) -> str:
        return get_response_instruction(lang_code)

    @classmethod
    def get_insufficient_evidence_fallback(cls, lang_code: str) -> str:
        return get_insufficient_evidence_message(lang_code)

    @classmethod
    def get_photo_request_prompt(cls, lang_code: str) -> str:
        return get_photo_request_message(lang_code)
