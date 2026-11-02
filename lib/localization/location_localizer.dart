import 'location_data.dart';

/// Centralized localization engine for Indian States and Districts.
/// Supports all 22 Eighth Schedule Indian Languages + English:
/// Tamil (ta), Telugu (te), Kannada (kn), Malayalam (ml), Marathi (mr),
/// Punjabi (pa), Bengali (bn), Odia (or), Assamese (as), Gujarati (gu),
/// Hindi (hi), Urdu (ur), Sanskrit (sa), Nepali (ne), Konkani (kok),
/// Maithili (mai), Bodo (brx), Dogri (doi), Kashmiri (ks), Sindhi (sd),
/// Santali (sat), Manipuri (mni), and English (en).
class LocationLocalizer {
  LocationLocalizer._();

  // ==========================================
  // STATE TRANSLATIONS DICTIONARY
  // ==========================================
  static const Map<String, Map<String, String>> _stateTranslations = {
    'Tamil Nadu': {
      'ta': 'தமிழ்நாடு',
      'te': 'తమిళనాడు',
      'kn': 'ತಮಿಳುನಾಡು',
      'ml': 'തമിഴ്നാട്',
      'mr': 'तमिळनाडू',
      'pa': 'ਤਾਮਿਲ ਨਾਡੂ',
      'bn': 'তামিলনাড়ু',
      'or': 'ତାମିଲନାଡୁ',
      'as': 'তামিলনাডু',
      'hi': 'तमिलनाडु',
      'gu': 'તમિલનાડુ',
      'ur': 'تمل ناڈو',
    },
    'Gujarat': {
      'gu': 'ગુજરાત',
      'hi': 'गुजरात',
      'ta': 'குஜராத்',
      'te': 'గుజరాత్',
      'kn': 'ಗುಜರಾತ್',
      'ml': 'ഗുജറാത്ത്',
      'mr': 'गुजरात',
      'pa': 'ਗੁਜਰਾਤ',
      'bn': 'গুজরাত',
      'or': 'ଗୁଜରାଟ',
      'as': 'গুজৰাট',
      'ur': 'گجرات',
    },
    'Maharashtra': {
      'mr': 'महाराष्ट्र',
      'gu': 'મહારાષ્ટ્ર',
      'hi': 'महाराष्ट्र',
      'ta': 'மகாராஷ்டிரா',
      'te': 'మహారాష్ట్ర',
      'kn': 'ಮಹಾರಾಷ್ಟ್ರ',
      'ml': 'മഹാരാഷ്ട്ര',
      'pa': 'ਮਹਾਰਾਸ਼ਟਰ',
      'bn': 'মহারাষ্ট্র',
      'or': 'ମହାରାଷ୍ଟ୍ର',
      'as': 'মহাৰাষ্ট্ৰ',
      'ur': 'مہاراشٹرا',
    },
    'Karnataka': {
      'kn': 'ಕರ್ನಾಟಕ',
      'gu': 'કર્ણાટક',
      'hi': 'कर्नाटक',
      'ta': 'கர்நாடகா',
      'te': 'కర్ణాటక',
      'ml': 'കർണാടക',
      'mr': 'कर्नाटक',
      'pa': 'ਕਰਨਾਟਕ',
      'bn': 'কর্ণাটক',
      'or': 'କର୍ଣ୍ଣାଟକ',
      'as': 'কৰ্ণাটক',
      'ur': 'کرناٹک',
    },
    'Andhra Pradesh': {
      'te': 'ఆంధ్ర ప్రదేశ్',
      'gu': 'આંધ્ર પ્રદેશ',
      'hi': 'आंध्र प्रदेश',
      'ta': 'ஆந்திரப் பிரதேசம்',
      'kn': 'ಆಂಧ್ರ ಪ್ರದೇಶ',
      'ml': 'ആന്ധ്രാപ്രദേശ്',
      'mr': 'आंध्र प्रदेश',
      'pa': 'ਆਂਧਰਾ ਪ੍ਰਦੇਸ਼',
      'bn': 'অন্ধ্রপ্রদেশ',
      'or': 'ଆନ୍ଧ୍ର ପ୍ରଦେଶ',
      'as': 'অন্ধ্ৰ প্ৰদেশ',
      'ur': 'آندھرا پردیش',
    },
    'Telangana': {
      'te': 'తెలంగాణ',
      'gu': 'તેલંગાણા',
      'hi': 'तेलंगाना',
      'ta': 'தெலுங்கானா',
      'kn': 'ತೆಲಂಗಾಣ',
      'ml': 'തെലങ്കാന',
      'mr': 'तेलंगणा',
      'pa': 'ਤੇਲੰਗਾਨਾ',
      'bn': 'তেলেঙ্গানা',
      'or': 'ତେଲେଙ୍ଗାନା',
      'as': 'তেলেংগানা',
      'ur': 'تلنگانہ',
    },
    'Kerala': {
      'ml': 'കേരളം',
      'gu': 'કેરળ',
      'hi': 'केरल',
      'ta': 'கேரளா',
      'te': 'కేరళ',
      'kn': 'ಕೇರಳ',
      'mr': 'केरळ',
      'pa': 'ਕੇਰਲ',
      'bn': 'কেরল',
      'or': 'କେରଳ',
      'as': 'কেৰালা',
      'ur': 'کیرالہ',
    },
    'Punjab': {
      'pa': 'ਪੰਜਾਬ',
      'gu': 'પંજાબ',
      'hi': 'पंजाब',
      'ta': 'பஞ்சாப்',
      'te': 'పంజాబ్',
      'kn': 'ಪಂಜಾಬ್',
      'ml': 'പഞ്ചാബ്',
      'mr': 'पंजाब',
      'bn': 'পাঞ্জাব',
      'or': 'ପଞ୍ଜାବ',
      'as': 'পঞ্জাব',
      'ur': 'پنجاب',
    },
    'Haryana': {
      'hi': 'हरियाणा',
      'pa': 'ਹਰਿਆਣਾ',
      'gu': 'હરિયાણા',
      'ta': 'ஹரியானா',
      'te': 'హర్యానా',
      'kn': 'ಹರಿಯಾಣ',
      'ml': 'ഹരിയാന',
      'mr': 'हरियाणा',
      'bn': 'হরিয়ানা',
      'or': 'ହରିୟାଣା',
      'as': 'হাৰিয়ানা',
      'ur': 'ہریانہ',
    },
    'Rajasthan': {
      'hi': 'राजस्थान',
      'gu': 'રાજસ્થાન',
      'ta': 'ராஜஸ்தான்',
      'te': 'రాజస్థాన్',
      'kn': 'ರಾಜಸ್ಥಾನ',
      'ml': 'രാജസ്ഥാൻ',
      'mr': 'राजस्थान',
      'pa': 'ਰਾਜਸਥਾਨ',
      'bn': 'রাজস্থান',
      'or': 'ରାଜସ୍ଥାନ',
      'as': 'ৰাজস্থান',
      'ur': 'راجستھان',
    },
    'Madhya Pradesh': {
      'hi': 'मध्य प्रदेश',
      'gu': 'મધ્ય પ્રદેશ',
      'ta': 'மத்தியப் பிரதேசம்',
      'te': 'మధ్య ప్రదేశ్',
      'kn': 'ಮಧ್ಯ ಪ್ರದೇಶ',
      'ml': 'മധ്യപ്രദേശ്',
      'mr': 'मध्य प्रदेश',
      'pa': 'ਮੱਧ ਪ੍ਰਦੇਸ਼',
      'bn': 'মধ্যপ্রদেশ',
      'or': 'ମଧ୍ୟ ପ୍ରଦେଶ',
      'as': 'মধ্য প্ৰদেশ',
      'ur': 'مدھیہ پردیش',
    },
    'Uttar Pradesh': {
      'hi': 'उत्तर प्रदेश',
      'gu': 'ઉત્તર પ્રદેશ',
      'ta': 'உத்தரப் பிரதேசம்',
      'te': 'ఉత్తర ప్రదేశ్',
      'kn': 'ಉತ್ತರ ಪ್ರದೇಶ',
      'ml': 'ഉത്തർപ്രദേശ്',
      'mr': 'उत्तर प्रदेश',
      'pa': 'ਉੱਤਰ ਪ੍ਰਦੇਸ਼',
      'bn': 'উত্তরপ্রদেশ',
      'or': 'ଉତ୍ତର ପ୍ରଦେଶ',
      'as': 'উত্তৰ প্ৰদেশ',
      'ur': 'اتر پردیش',
    },
    'Bihar': {
      'hi': 'बिहार',
      'gu': 'બિહાર',
      'ta': 'பீகார்',
      'te': 'బీహార్',
      'kn': 'ಬಿಹಾರ',
      'ml': 'ബിഹാർ',
      'mr': 'बिहार',
      'pa': 'ਬਿਹਾਰ',
      'bn': 'বিহার',
      'or': 'ବିହାର',
      'as': 'বিহাৰ',
      'ur': 'بہار',
    },
    'West Bengal': {
      'bn': 'পশ্চিমবঙ্গ',
      'gu': 'પશ્ચિમ બંગાળ',
      'hi': 'पश्चिम बंगाल',
      'ta': 'மேற்கு வங்காளம்',
      'te': 'పశ్చిమ బెంగాల్',
      'kn': 'ಪಶ್ಚಿಮ ಬಂಗಾಳ',
      'ml': 'പശ്ചിമ ബംഗാൾ',
      'mr': 'पश्चिम बंगाल',
      'pa': 'ਪੱਛਮੀ ਬੰਗਾਲ',
      'or': 'ପଶ୍ଚିମ ବଙ୍ଗ',
      'as': 'পশ্চিমবংগ',
      'ur': 'مغربی بنگال',
    },
    'Odisha': {
      'or': 'ଓଡ଼ିଶା',
      'gu': 'ઓડિશા',
      'hi': 'ओडिशा',
      'ta': 'ஒடிசா',
      'te': 'ఒడిశా',
      'kn': 'ಒಡಿಶಾ',
      'ml': 'ഒഡീഷ',
      'mr': 'ओडिशा',
      'pa': 'ਓਡੀਸ਼ਾ',
      'bn': 'ওড়িশা',
      'as': 'ওড়িশা',
      'ur': 'اوڈیشہ',
    },
    'Assam': {
      'as': 'অসম',
      'bn': 'আসাম',
      'gu': 'આસામ',
      'hi': 'असम',
      'ta': 'அசாம்',
      'te': 'అస్సాం',
      'kn': 'ಅಸ್ಸಾಂ',
      'ml': 'അസം',
      'mr': 'आसाम',
      'pa': 'ਅਸਾਮ',
      'or': 'ଆସାମ',
      'ur': 'آسام',
    },
    'Chhattisgarh': {
      'hi': 'छत्तीसगढ़',
      'gu': 'છત્તીસગઢ',
      'ta': 'சத்தீஸ்கர்',
      'te': 'ఛత్తీస్‌గఢ్',
      'kn': 'ಛತ್ತೀಸ್‌ಗಢ',
      'ml': 'ഛത്തീസ്ഗഢ്',
      'mr': 'छत्तीसगड',
      'pa': 'ਛੱਤੀਸਗੜ੍ਹ',
      'bn': 'ছত্তিশগড়',
      'or': 'ଛତିଶଗଡ଼',
      'as': 'ছত্তীশগড়',
      'ur': 'چھتیس گڑھ',
    },
    'Jharkhand': {
      'hi': 'झारखंड',
      'gu': 'ઝારખંડ',
      'ta': 'ஜார்கண்ட்',
      'te': 'జార్ఖండ్',
      'kn': 'ಜಾರ್ಖಂಡ್',
      'ml': 'ഝാർഖണ്ഡ്',
      'mr': 'झारखंड',
      'pa': 'ਝਾਰਖੰਡ',
      'bn': 'ঝাড়খণ্ড',
      'or': 'ଝାଡ଼ଖଣ୍ଡ',
      'as': 'ঝাৰখণ্ড',
      'ur': 'جھارکھنڈ',
    },
    'Uttarakhand': {
      'hi': 'उत्तराखंड',
      'gu': 'ઉત્તરાખંડ',
      'ta': 'உத்தராகண்ட்',
      'te': 'ఉత్తరాఖండ్',
      'kn': 'ಉತ್ತರಾಖಂಡ',
      'ml': 'ഉത്തരാഖണ്ഡ്',
      'mr': 'उत्तराखंड',
      'pa': 'ਉੱਤਰਾਖੰਡ',
      'bn': 'উত্তরাখণ্ড',
      'or': 'ଉତ୍ତରାଖଣ୍ଡ',
      'as': 'উত্তৰাখণ্ড',
      'ur': 'اتراکھنڈ',
    },
    'Himachal Pradesh': {
      'hi': 'हिमाचल प्रदेश',
      'gu': 'હિમાચલ પ્રદેશ',
      'ta': 'இமாச்சலப் பிரதேசம்',
      'te': 'హిమాచల్ ప్రదేశ్',
      'kn': 'ಹಿಮಾಚಲ ಪ್ರದೇಶ',
      'ml': 'ഹിമാചൽ പ്രദേശ്',
      'mr': 'हिमाचल प्रदेश',
      'pa': 'ਹਿਮਾਚਲ ਪ੍ਰਦੇਸ਼',
      'bn': 'হিমাচল প্রদেশ',
      'or': 'ହିମାଚଳ ପ୍ରଦେଶ',
      'as': 'হিমাচল প্ৰদেশ',
      'ur': 'ہماچل پردیش',
    },
    'Goa': {
      'hi': 'गोवा',
      'mr': 'गोवा',
      'kok': 'गोंय',
      'gu': 'ગોવા',
      'ta': 'கோவா',
      'te': 'గోవా',
      'kn': 'ಗೋವಾ',
      'ml': 'ഗോവ',
      'pa': 'ਗੋਆ',
      'bn': 'গোয়া',
      'or': 'ଗୋଆ',
      'as': 'গোৱা',
      'ur': 'گوا',
    },
    'Tripura': {
      'bn': 'ত্রিপুরা',
      'hi': 'त्रिपुरा',
      'gu': 'ત્રિપુરા',
      'ta': 'திரிபுரா',
      'te': 'త్రిపుర',
      'kn': 'ತ್ರಿಪುರ',
      'ml': 'ത്രിപുര',
      'mr': 'त्रिपुरा',
      'pa': 'ਤ੍ਰਿਪੁਰਾ',
      'or': 'ତ୍ରିପୁରା',
      'as': 'ত্ৰিপুৰা',
      'ur': 'تریپورہ',
    },
    'Meghalaya': {
      'hi': 'मेघालय',
      'gu': 'મેઘાલય',
      'ta': 'மேகாலயா',
      'te': 'మేఘాలయ',
      'kn': 'ಮೇಘಾಲಯ',
      'ml': 'മേഘാലയ',
      'mr': 'मेघालय',
      'pa': 'ਮੇਘਾਲਿਆ',
      'bn': 'মেঘালয়',
      'or': 'ମେଘାଳୟ',
      'as': 'মেঘালয়',
      'ur': 'میگھالیہ',
    },
    'Manipur': {
      'mni': 'মণিপুর',
      'hi': 'मणिपुर',
      'gu': 'મણિપુર',
      'ta': 'மணிப்பூர்',
      'te': 'మణిపూర్',
      'kn': 'ಮಣಿಪುರ',
      'ml': 'മണിപ്പൂർ',
      'mr': 'मणिपूर',
      'pa': 'ਮਣੀਪੁਰ',
      'bn': 'মণিপুর',
      'or': 'ମଣିପୁର',
      'as': 'মণিপুৰ',
      'ur': 'منی پور',
    },
    'Nagaland': {
      'hi': 'नागालैंड',
      'gu': 'નાગાલેન્ડ',
      'ta': 'நாகாலாந்து',
      'te': 'నాగాలాండ్',
      'kn': 'ನಾಗಾಲ್ಯಾಂಡ್',
      'ml': 'നാഗാലാൻഡ്',
      'mr': 'नागालँड',
      'pa': 'ਨਾਗਾਲੈਂਡ',
      'bn': 'নাগাল্যান্ড',
      'or': 'ନାଗାଲାଣ୍ଡ',
      'as': 'নাগালেণ্ড',
      'ur': 'ناگالینڈ',
    },
    'Mizoram': {
      'hi': 'मिजोरम',
      'gu': 'મિઝોરમ',
      'ta': 'மிசோரம்',
      'te': 'మిజోరం',
      'kn': 'ಮಿಜೋರಾಂ',
      'ml': 'മിസോറാം',
      'mr': 'मिझोरम',
      'pa': 'ਮਿਜ਼ੋਰਮ',
      'bn': 'মিজোরাম',
      'or': 'ମିଜୋରାମ',
      'as': 'মিজোৰাম',
      'ur': 'میزورم',
    },
    'Arunachal Pradesh': {
      'hi': 'अरुणाचल प्रदेश',
      'gu': 'અરુણાચલ પ્રદેશ',
      'ta': 'அருணாச்சலப் பிரதேசம்',
      'te': 'అరుణాచల్ ప్రదేశ్',
      'kn': 'ಅರುಣಾಚಲ ಪ್ರದೇಶ',
      'ml': 'അരുണാചൽ പ്രദേശ്',
      'mr': 'अरुणाचल प्रदेश',
      'pa': 'ਅਰੁਣਾਚਲ ਪ੍ਰਦੇਸ਼',
      'bn': 'অরুণাচল প্রদেশ',
      'or': 'ଅରୁଣାଚଳ ପ୍ରଦେଶ',
      'as': 'অৰুণাচল প্ৰদেশ',
      'ur': 'اروناچل پردیش',
    },
    'Sikkim': {
      'hi': 'सिक्किम',
      'gu': 'સિક્કિમ',
      'ta': 'சிக்கிம்',
      'te': 'సిక్కిం',
      'kn': 'ಸಿಕ್ಕಿಂ',
      'ml': 'സിക്കിം',
      'mr': 'सिक्कीम',
      'pa': 'ਸਿੱਕਮ',
      'bn': 'সিকিম',
      'or': 'ସିକିମ',
      'as': 'ছিকিম',
      'ur': 'سکم',
    },
    'Delhi (NCT)': {
      'hi': 'दिल्ली',
      'gu': 'દિલ્હી',
      'ta': 'டெல்லி',
      'te': 'ఢిల్లీ',
      'kn': 'ದೆಹಲಿ',
      'ml': 'ഡൽഹി',
      'mr': 'दिल्ली',
      'pa': 'ਦਿੱਲੀ',
      'bn': 'দিল্লি',
      'or': 'ଦିଲ୍ଲୀ',
      'as': 'দিল্লী',
      'ur': 'دہلی',
    },
    'Jammu and Kashmir': {
      'hi': 'जम्मू और कश्मीर',
      'gu': 'જમ્મુ અને કાશ્મીર',
      'ta': 'ஜம்மு காஷ்மீர்',
      'te': 'జమ్మూ కాశ్మీర్',
      'kn': 'ಜಮ್ಮು ಮತ್ತು ಕಾಶ್ಮೀರ',
      'ml': 'ജമ്മു കശ്മീർ',
      'mr': 'जम्मू आणि काश्मीर',
      'pa': 'ਜੰਮੂ ਅਤੇ ਕਸ਼ਮੀਰ',
      'bn': 'জম্মু ও কাশ্মীর',
      'or': 'ଜମ୍ମୁ ଓ କାଶ୍ମୀର',
      'as': 'জম্মু আৰু কাশ্মীৰ',
      'ur': 'جموں و کشمیر',
    },
    'Ladakh': {
      'hi': 'लद्दाख',
      'gu': 'લદ્દાખ',
      'ta': 'லடாக்',
      'te': 'లడఖ్',
      'kn': 'ಲಡಾಖ್',
      'ml': 'ലഡാക്ക്',
      'mr': 'लडाख',
      'pa': 'ਲਦਾਖ',
      'bn': 'লাদাখ',
      'or': 'ଲଦାଖ',
      'as': 'লাডাখ',
      'ur': 'لداخ',
    },
    'Chandigarh': {
      'hi': 'चंडीगढ़',
      'pa': 'ਚੰਡੀਗੜ੍ਹ',
      'gu': 'ચંદીગઢ',
      'ta': 'சண்டிகர்',
      'te': 'చండీగఢ్',
      'kn': 'ಚಂಡೀಗಢ',
      'ml': 'ചണ്ഡീഗഡ്',
      'mr': 'चंदिगढ',
      'bn': 'চণ্ডীগড়',
      'or': 'ଚଣ୍ଡିଗଡ଼',
      'as': 'চণ্ডীগড়',
      'ur': 'چندی گڑھ',
    },
    'Puducherry': {
      'ta': 'புதுச்சேரி',
      'hi': 'पुडुचेरी',
      'gu': 'પુડુચેરી',
      'te': 'పుదుచ్చేరి',
      'kn': 'ಪುದುಚೇರಿ',
      'ml': 'പുതുച്ചേരി',
      'mr': 'पुडुचेरी',
      'pa': 'ਪੁਡੂਚੇਰੀ',
      'bn': 'পুদুচেরি',
      'or': 'ପୁଡୁଚେରୀ',
      'as': 'পুডুচেৰী',
      'ur': 'پڈوچیری',
    },
    'Dadra and Nagar Haveli and Daman and Diu': {
      'gu': 'દાદરા અને નગર હવેલી અને દમણ અને દીવ',
      'hi': 'दादरा और नगर हवेली और दमन और दीव',
      'mr': 'दादरा आणि नगर हवेली आणि दमण आणि दीव',
      'ta': 'தாத்ரா நகர் ஹவேலி மற்றும் தாமன் தியூ',
      'te': 'దాద్రా నగర్ హవేలీ మరియు డామన్ డయ్యూ',
      'kn': 'ದಾದ್ರಾ ಮತ್ತು ನಗರ ಹವೇಲಿ ಮತ್ತು ದಾಮನ್ ಮತ್ತು ದಿಯು',
      'ml': 'ദാദ്ര ആൻഡ് നഗർ ഹവേലി ദാമൻ ആൻഡ് ദിയു',
      'pa': 'ਦਾਦਰਾ ਅਤੇ ਨਗਰ ਹਵੇਲੀ ਅਤੇ ਦਮਨ ਅਤੇ ਦੀਵ',
      'bn': 'দাদরা ও নগর হাভেলি এবং দমন ও দিউ',
      'ur': 'دادرا و نگر حویلی اور دمن و دیو',
    },
    'Andaman and Nicobar Islands': {
      'hi': 'अंडमान और निकोबार द्वीप समूह',
      'gu': 'અંદમાન અને નિકોબાર ટાપુઓ',
      'ta': 'அந்தமான் நிக்கோபார் தீவுகள்',
      'te': 'అండమాన్ మరియు నికోబార్ దీవులు',
      'kn': 'ಅಂಡಮಾನ್ ಮತ್ತು ನಿಕೋಬಾರ್ ದ್ವೀಪಗಳು',
      'ml': 'ആൻഡമാൻ നിക്കോബാർ ദ്വീപുകൾ',
      'mr': 'अंदमान आणि निकोबार बेटे',
      'pa': 'ਅੰਡੇਮਾਨ ਅਤੇ ਨਿਕੋਬਾਰ ਟਾਪੂ',
      'bn': 'আন্দামান ও নিকোবর দ্বীপপুঞ্জ',
      'or': 'ଆଣ୍ଡାମାନ ଓ ନିକୋବର ଦ୍ୱୀପପୁଞ୍ଜ',
      'ur': 'جزائر انڈمان و نکوبار',
    },
    'Lakshadweep': {
      'ml': 'ലക്ഷദ്വീപ്',
      'hi': 'लक्षद्वीप',
      'gu': 'લક્ષદ્વીપ',
      'ta': 'லட்சத்தீவு',
      'te': 'లక్షద్వీప్',
      'kn': 'ಲಕ್ಷದ್ವೀಪ',
      'mr': 'लक्षद्वीप',
      'pa': 'ਲਕਸ਼ਦੀਪ',
      'bn': 'লাক্ষাদ্বীপ',
      'or': 'ଲାକ୍ଷାଦ୍ୱୀପ',
      'ur': 'لکشدیپ',
    },
  };

  // ==========================================
  // TAMIL NADU DISTRICTS (All 38)
  // ==========================================
  static const Map<String, String> _tamilDistrictNames = {
    'Ariyalur': 'அரியலூர்',
    'Chengalpattu': 'செங்கல்பட்டு',
    'Chennai': 'சென்னை',
    'Coimbatore': 'கோயம்புத்தூர்',
    'Cuddalore': 'கடலூர்',
    'Dharmapuri': 'தர்மபுரி',
    'Dindigul': 'திண்டுக்கல்',
    'Erode': 'ஈரோடு',
    'Kallakurichi': 'கள்ளக்குறிச்சி',
    'Kanchipuram': 'காஞ்சிபுரம்',
    'Kanyakumari': 'கன்னியாகுமரி',
    'Karur': 'கரூர்',
    'Krishnagiri': 'கிருஷ்ணகிரி',
    'Madurai': 'மதுரை',
    'Mayiladuthurai': 'மயிலாடுதுறை',
    'Nagapattinam': 'நாகப்பட்டினம்',
    'Namakkal': 'நாமக்கல்',
    'Nilgiris': 'நீலகிரி (ஊட்டி)',
    'Perambalur': 'பெரம்பலூர்',
    'Pudukkottai': 'புதுக்கோட்டை',
    'Ramanathapuram': 'ராமநாதபுரம்',
    'Ranipet': 'ராணிப்பேட்டை',
    'Salem': 'சேலம்',
    'Sivaganga': 'சிவகங்கை',
    'Tenkasi': 'தென்காசி',
    'Thanjavur': 'தஞ்சாவூர்',
    'Theni': 'தேனி',
    'Thoothukudi': 'தூத்துக்குடி',
    'Tiruchirappalli': 'திருச்சிராப்பள்ளி (திருச்சி)',
    'Tirunelveli': 'திருநெல்வேலி',
    'Tirupathur': 'திருப்பத்தூர்',
    'Tiruppur': 'திருப்பூர்',
    'Tiruvallur': 'திருவள்ளூர்',
    'Tiruvannamalai': 'திருவண்ணாமலை',
    'Tiruvarur': 'திருவாரூர்',
    'Vellore': 'வேலூர்',
    'Viluppuram': 'விழுப்புரம்',
    'Virudhunagar': 'விருதுநகர்',
  };

  // ==========================================
  // TELUGU DISTRICTS (Major AP & Telangana)
  // ==========================================
  static const Map<String, String> _teluguDistrictNames = {
    'Visakhapatnam': 'విశాఖపట్నం',
    'Vijayawada': 'విజయవాడ',
    'NTR': 'ఎన్టీఆర్ (విజయవాడ)',
    'Guntur': 'గుంటూరు',
    'Tirupati': 'తిరుపతి',
    'Kurnool': 'కర్నూలు',
    'Nellore': 'నెల్లూరు',
    'Sri Potti Sriramulu Nellore': 'నెల్లూరు',
    'East Godavari': 'తూర్పు గోదావరి (రాజమండ్రి)',
    'West Godavari': 'పశ్చిమ గోదావరి (భీమవరం)',
    'Krishna': 'కృష్ణా (మచిలీపట్నం)',
    'Kadapa': 'వైఎస్ఆర్ కడప',
    'YSR Kadapa': 'వైఎస్ఆర్ కడప',
    'Ananthapuramu': 'అనంతపురం',
    'Chittoor': 'చిత్తూరు',
    'Kakinada': 'కాకినాడ',
    'Eluru': 'ఏలూరు',
    'Srikakulam': 'శ్రీకాకుళం',
    'Vizianagaram': 'విజయనగరం',
    'Prakasam': 'ప్రకాశం (ఒంగోలు)',
    'Nandyal': 'నంద్యాల',
    'Bapatla': 'బాపట్ల',
    'Palnadu': 'పల్నాడు',
    'Annamayya': 'అన్నమయ్య',
    'Sri Sathya Sai': 'శ్రీ సత్యసాయి (పుట్టపర్తి)',
    'Alluri Sitharama Raju': 'అల్లూరి సీతారామరాజు',
    'Anakapalli': 'అనకాపల్లి',
    'Parvathipuram Manyam': 'పార్వతీపురం మన్యం',
    'Hyderabad': 'హైదరాబాద్',
    'Warangal': 'వరంగల్',
    'Hanamkonda': 'హనుమకొండ',
    'Karimnagar': 'కరీంనగర్',
    'Khammam': 'ఖమ్మం',
    'Nizamabad': 'నిజామాబాద్',
    'Mahabubnagar': 'మహబూబ్‌నగర్',
    'Nalgonda': 'నల్గొండ',
    'Ranga Reddy': 'రంగారెడ్డి',
    'Sangareddy': 'సంగారెడ్డి',
    'Siddipet': 'సిద్దిపేట',
    'Medak': 'మెదక్',
    'Adilabad': 'ఆదిలాబాద్',
    'Bhadradri Kothagudem': 'భద్రాద్రి కొత్తగూడెం',
    'Jagtial': 'జగిత్యాల',
    'Jangaon': 'జనగామ',
    'Kamareddy': 'కామారెడ్డి',
    'Mancherial': 'మంచిర్యాల',
    'Medchal-Malkajgiri': 'మేడ్చల్ మల్కాజ్‌గిరి',
    'Nagarkurnool': 'నాగర్‌కర్నూల్',
    'Peddapalli': 'పెద్దపల్లి',
    'Rajanna Sircilla': 'రాజన్న సిరిసిల్ల',
    'Suryapet': 'సూర్యాపేట',
    'Vikarabad': 'వికారాబాద్',
    'Wanaparthy': 'వనపర్తి',
    'Yadadri Bhuvanagiri': 'యాదాద్రి భువనగిరి',
  };

  // ==========================================
  // KANNADA DISTRICTS (Major Karnataka)
  // ==========================================
  static const Map<String, String> _kannadaDistrictNames = {
    'Bengaluru Urban': 'ಬೆಂಗಳೂರು ನಗರ',
    'Bengaluru Rural': 'ಬೆಂಗಳೂರು ಗ್ರಾಮಾಂತರ',
    'Mysuru': 'ಮೈಸೂರು',
    'Belagavi': 'ಬೆಳಗಾವಿ',
    'Dakshina Kannada': 'ದಕ್ಷಿಣ ಕನ್ನಡ (ಮಂಗಳೂರು)',
    'Dharwad': 'ಧಾರವಾಡ (ಹುಬ್ಬಳ್ಳಿ)',
    'Kalaburagi': 'ಕಲಬುರಗಿ (ಗುಲ್ಬರ್ಗ)',
    'Ballari': 'ಬಳ್ಳಾರಿ',
    'Shivamogga': 'ಶಿವಮೊಗ್ಗ',
    'Udupi': 'ಉಡುಪಿ',
    'Hassan': 'ಹಾಸನ',
    'Mandya': 'ಮಂಡ್ಯ',
    'Davanagere': 'ದಾವಣಗೆರೆ',
    'Tumakuru': 'ತುಮಕೂರು',
    'Vijayapura': 'ವಿಜಯಪುರ (ಬಿಜಾಪುರ)',
    'Bagalkote': 'ಬಾಗಲಕೋಟೆ',
    'Bidar': 'ಬೀದರ್',
    'Chamarajanagara': 'ಚಾಮರಾಜನಗರ',
    'Chikkaballapura': 'ಚಿಕ್ಕಬಳ್ಳಾಪುರ',
    'Chikkamagaluru': 'ಚಿಕ್ಕಮಗಳೂರು',
    'Chitradurga': 'ಚಿತ್ರದುರ್ಗ',
    'Gadag': 'ಗದಗ',
    'Haveri': 'ಹಾವೇರಿ',
    'Kodagu': 'ಕೊಡಗು (ಮಡಿಕೇರಿ)',
    'Kolar': 'ಕೋಲಾರ',
    'Koppal': 'ಕೊಪ್ಪಳ',
    'Raichur': 'ರಾಯಚೂರು',
    'Ramanagara': 'ರಾಮನಗರ',
    'Uttara Kannada': 'ಉತ್ತರ ಕನ್ನಡ (ಕಾರವಾರ)',
    'Vijayanagara': 'ವಿಜಯನಗರ (ಹೊಸಪೇಟೆ)',
    'Yadgir': 'ಯಾದಗಿರಿ',
  };

  // ==========================================
  // MALAYALAM DISTRICTS (All 14 Kerala)
  // ==========================================
  static const Map<String, String> _malayalamDistrictNames = {
    'Alappuzha': 'ആലപ്പുഴ',
    'Ernakulam': 'എറണാകുളം (കൊച്ചി)',
    'Idukki': 'ഇടുക്കി',
    'Kannur': 'കണ്ണൂർ',
    'Kasaragod': 'കാസർഗോഡ്',
    'Kollam': 'കൊല്ലം',
    'Kottayam': 'കോട്ടയം',
    'Kozhikode': 'കോഴിക്കോട്',
    'Malappuram': 'മലപ്പുറം',
    'Palakkad': 'പാലക്കാട്',
    'Pathanamthitta': 'പത്തനംതിട്ട',
    'Thiruvananthapuram': 'തിരുവനന്തപുരം',
    'Thrissur': 'തൃശ്ശൂർ',
    'Wayanad': 'വയനാട് (കൽപ്പറ്റ)',
  };

  // ==========================================
  // PUNJABI GURMUKHI DISTRICTS
  // ==========================================
  static const Map<String, String> _punjabiDistrictNames = {
    'Amritsar': 'ਅੰਮ੍ਰਿਤਸਰ',
    'Ludhiana': 'ਲੁਧਿਆਣਾ',
    'Jalandhar': 'ਜਲੰਧਰ',
    'Patiala': 'ਪਟਿਆਲਾ',
    'Bathinda': 'ਬਠਿੰਡਾ',
    'Gurdaspur': 'ਗੁਰਦਾਸਪੁਰ',
    'Hoshiarpur': 'ਹੁਸ਼ਿਆਰਪੁਰ',
    'Ferozepur': 'ਫ਼ਿਰੋਜ਼ਪੁਰ',
    'Faridkot': 'ਫ਼ਰੀਦਕੋਟ',
    'Fatehgarh Sahib': 'ਫ਼ਤਹਿਗੜ੍ਹ ਸਾਹਿਬ',
    'Fazilka': 'ਫ਼ਾਜ਼ਿਲਕਾ',
    'Kapurthala': 'ਕਪੂਰਥਲਾ',
    'Mansa': 'ਮਾਨਸਾ',
    'Moga': 'ਮੋਗਾ',
    'Muktsar': 'ਸ੍ਰੀ ਮੁਕਤਸਰ ਸਾਹਿਬ',
    'Pathankot': 'ਪਠਾਨਕੋਟ',
    'Rupnagar': 'ਰੂਪਨਗਰ (ਰੋਪੜ)',
    'Sahibzada Ajit Singh Nagar': 'ਐਸ.ਏ.ਐਸ. ਨਗਰ (ਮੋਹਾਲੀ)',
    'Sangrur': 'ਸੰਗਰੂਰ',
    'Shaheed Bhagat Singh Nagar': 'ਨਵਾਂਸ਼ਹਿਰ',
    'Tarn Taran': 'ਤਰਨ ਤਾਰਨ',
    'Barnala': 'ਬਰਨਾਲਾ',
    'Malerkotla': 'ਮਲੇਰਕੋਟਲਾ',
  };

  // ==========================================
  // BENGALI DISTRICTS
  // ==========================================
  static const Map<String, String> _bengaliDistrictNames = {
    'Kolkata': 'কলকাতা',
    'Howrah': 'হাওড়া',
    'Darjeeling': 'দার্জিলিং',
    'Hooghly': 'হুগলি',
    'Jalpaiguri': 'জলপাইগুড়ি',
    'Alipurduar': 'আলিপুরদুয়ার',
    'Bankura': 'বাঁকুড়া',
    'Birbhum': 'বীরভূম',
    'Cooch Behar': 'কোচবিহার',
    'Dakshin Dinajpur': 'দক্ষিণ দিনাজপুর',
    'Kalimpong': 'কালিম্পং',
    'Malda': 'মালদা',
    'Murshidabad': 'মুর্শিদাবাদ',
    'Nadia': 'নদিয়া',
    'North 24 Parganas': 'উত্তর ২৪ পরগনা',
    'South 24 Parganas': 'দক্ষিণ ২৪ পরগনা',
    'Paschim Bardhaman': 'পশ্চিম বর্ধমান (আসানসোল)',
    'Purba Bardhaman': 'পূর্ব বর্ধমান',
    'Paschim Medinipur': 'পশ্চিম মেদিনীপুর',
    'Purba Medinipur': 'পূর্ব মেদিনীপুর',
    'Purulia': 'পুরুলিয়া',
    'Uttar Dinajpur': 'উত্তর দিনাজপুর',
    'Jhargram': 'ঝাড়গ্রাম',
  };

  // ==========================================
  // ODIA DISTRICTS
  // ==========================================
  static const Map<String, String> _odiaDistrictNames = {
    'Khordha': 'ଖୋର୍ଦ୍ଧା (ଭୁବନେଶ୍ୱର)',
    'Cuttack': 'କଟକ',
    'Puri': 'ପୁରୀ',
    'Sambalpur': 'ସମ୍ବଲପୁର',
    'Balasore': 'ବାଲେଶ୍ୱର',
    'Sundargarh': 'ସୁନ୍ଦରଗଡ଼ (ରାଉରକେଲା)',
    'Ganjam': 'ଗଞ୍ଜାମ',
    'Angul': 'ଅନୁଗୋଳ',
    'Balangir': 'ବଲାଙ୍ଗୀର',
    'Bargarh': 'ବରଗଡ଼',
    'Bhadrak': 'ଭଦ୍ରକ',
    'Dhenkanal': 'ଢେଙ୍କାନାଳ',
    'Jajpur': 'ଯାଜପୁର',
    'Jharsuguda': 'ଝାରସୁଗୁଡ଼ା',
    'Kalahandi': 'କଳାହାଣ୍ଡି',
    'Kendujhar': 'କେନ୍ଦୁଝର',
    'Koraput': 'କୋରାପୁଟ',
    'Mayurbhanj': 'ମୟୂରଭଞ୍ଜ',
    'Rayagada': 'ରାୟଗଡ଼ା',
  };

  // ==========================================
  // INDIC SCRIPT TRANSLITERATOR
  // Maps Devanagari Unicode characters to target Indic scripts dynamically
  // ==========================================
  static String _transliterateDevanagariToScript(
    String text,
    String targetLang,
  ) {
    int offset = 0;
    switch (targetLang.toLowerCase()) {
      case 'bn':
      case 'as':
        offset = 0x0080; // Bengali & Assamese
        break;
      case 'pa':
        offset = 0x0100; // Gurmukhi (Punjabi)
        break;
      case 'gu':
        offset = 0x0180; // Gujarati
        break;
      case 'or':
        offset = 0x0200; // Odia
        break;
      case 'te':
        offset = 0x0300; // Telugu
        break;
      case 'kn':
        offset = 0x0380; // Kannada
        break;
      case 'ml':
        offset = 0x0400; // Malayalam
        break;
      default:
        return text;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Devanagari range: 0x0901 to 0x0970
      if (code >= 0x0901 && code <= 0x0970) {
        buffer.writeCharCode(code + offset);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Returns localized State name with English subtitle: "தமிழ்நாடு (Tamil Nadu)"
  static String getStateName(IndianState state, String langCode) {
    final code = langCode.toLowerCase();
    if (code == 'en') return state.englishName;

    final nativeName = getStatePureNative(state, code);
    return '$nativeName (${state.englishName})';
  }

  /// Returns pure native State name without English: "தமிழ்நாடு"
  static String getStatePureNative(IndianState state, String langCode) {
    final code = langCode.toLowerCase();
    if (code == 'en') return state.englishName;

    // 1. Direct state translations table
    final stateMap = _stateTranslations[state.key];
    if (stateMap != null && stateMap.containsKey(code)) {
      return stateMap[code]!;
    }

    // 2. Built-in language fields
    if (code == 'gu') return state.gujaratiName;
    if (code == 'hi' ||
        code == 'mr' ||
        code == 'ne' ||
        code == 'kok' ||
        code == 'mai' ||
        code == 'brx' ||
        code == 'doi' ||
        code == 'sa') {
      return state.hindiName;
    }

    // 3. Dynamic Indic phonetic transliteration
    return _transliterateDevanagariToScript(state.hindiName, code);
  }

  /// Returns localized District name with English subtitle: "சென்னை (Chennai)"
  static String getDistrictName(IndianDistrict district, String langCode) {
    final code = langCode.toLowerCase();
    if (code == 'en') return district.englishName;

    final nativeName = getDistrictPureNative(district, code);
    final cleanEnglish = district.englishName
        .replaceAll(RegExp(r'\s*\(.*?\)'), '')
        .trim();
    return '$nativeName ($cleanEnglish)';
  }

  /// Returns pure native District name without English: "சென்னை"
  static String getDistrictPureNative(
    IndianDistrict district,
    String langCode,
  ) {
    final code = langCode.toLowerCase();
    if (code == 'en') return district.englishName;

    final key = district.key;

    // 1. Check specialized regional language dictionaries
    switch (code) {
      case 'ta':
        if (_tamilDistrictNames.containsKey(key)) {
          return _tamilDistrictNames[key]!;
        }
        break;
      case 'te':
        if (_teluguDistrictNames.containsKey(key)) {
          return _teluguDistrictNames[key]!;
        }
        break;
      case 'kn':
        if (_kannadaDistrictNames.containsKey(key)) {
          return _kannadaDistrictNames[key]!;
        }
        break;
      case 'ml':
        if (_malayalamDistrictNames.containsKey(key)) {
          return _malayalamDistrictNames[key]!;
        }
        break;
      case 'pa':
        if (_punjabiDistrictNames.containsKey(key)) {
          return _punjabiDistrictNames[key]!;
        }
        break;
      case 'bn':
        if (_bengaliDistrictNames.containsKey(key)) {
          return _bengaliDistrictNames[key]!;
        }
        break;
      case 'or':
        if (_odiaDistrictNames.containsKey(key)) {
          return _odiaDistrictNames[key]!;
        }
        break;
      case 'gu':
        return district.gujaratiName;
      case 'hi':
      case 'mr':
      case 'ne':
      case 'kok':
      case 'mai':
      case 'brx':
      case 'doi':
      case 'sa':
        return district.hindiName;
    }

    // 2. For scripts without a manual dictionary entry, use phonetic Indic transliteration from Devanagari
    final transliterated = _transliterateDevanagariToScript(
      district.hindiName,
      code,
    );
    if (transliterated.isNotEmpty && transliterated != district.hindiName) {
      return transliterated;
    }

    // Fallback: return Devanagari or English
    return district.hindiName.isNotEmpty
        ? district.hindiName
        : district.englishName;
  }
}
