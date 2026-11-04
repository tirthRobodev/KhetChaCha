/// Comprehensive Multilingual Localization for Government Schemes and Subsidies.
/// Supports Gujarati, Hindi, Punjabi, Marathi, Telugu, Tamil, Kannada, Bengali, Malayalam, and English.
class GovtSchemeLocalization {
  GovtSchemeLocalization._();

  static String getTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સરકારી યોજનાઓ અને સબસિડી';
      case 'hi':
        return 'सरकारी योजनाएं एवं सब्सिडी';
      case 'pa':
        return 'ਸਰਕਾਰੀ ਸਕੀਮਾਂ ਅਤੇ ਸਬਸਿਡੀਆਂ';
      case 'mr':
        return 'सरकारी योजना आणि अनुदान';
      case 'te':
        return 'ప్రభుత్వ పథకాలు మరియు రాయితీలు';
      case 'ta':
        return 'அரசு திட்டங்கள் மற்றும் மானியங்கள்';
      case 'kn':
        return 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು ಮತ್ತು ಸಬ್ಸಿಡಿಗಳು';
      case 'bn':
        return 'সরকারি প্রকল্প ও ভর্তুকি';
      case 'ml':
        return 'സർക്കാർ പദ്ധതികളും സബ്‌സിഡിയും';
      case 'or':
        return 'ସରକାରୀ ଯୋଜନା ଓ ସବସିଡି';
      default:
        return 'Government Schemes & Subsidies';
    }
  }

  static String getSearchHint(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'યોજનાઓ, સબસિડી, ટ્રેક્ટર, ટપક સિંચાઈ શોધો...';
      case 'hi':
        return 'योजनाएं, सब्सिडी, ट्रैक्टर, ड्रिप सिंचाई खोजें...';
      case 'pa':
        return 'ਸਕੀਮਾਂ, ਸਬਸਿਡੀਆਂ, ਟਰੈਕਟਰ, ਤੁਪਕਾ ਸਿੰਚਾਈ ਖੋਜੋ...';
      case 'mr':
        return 'योजना, सबसिडी, ट्रॅक्टर, ठिबक सिंचन शोधा...';
      default:
        return 'Search schemes, subsidies, tractors, drip...';
    }
  }

  static String getCategoryLabel(String category, String langCode) {
    final lc = langCode.toLowerCase();
    switch (category) {
      case 'All':
        return lc == 'gu'
            ? 'બધા'
            : (lc == 'hi'
                  ? 'सभी'
                  : (lc == 'pa' ? 'ਸਾਰੇ' : (lc == 'mr' ? 'सर्व' : 'All')));
      case 'Farmer Welfare':
        return lc == 'gu'
            ? 'ખેડૂત કલ્યાણ'
            : (lc == 'hi'
                  ? 'किसान कल्याण'
                  : (lc == 'pa'
                        ? 'ਕਿਸਾਨ ਭਲਾਈ'
                        : (lc == 'mr' ? 'शेतकरी कल्याण' : 'Farmer Welfare')));
      case 'Equipment & Machinery':
        return lc == 'gu'
            ? 'સાધન અને કૃષિ યંત્રો'
            : (lc == 'hi'
                  ? 'कृषि यंत्र व उपकरण'
                  : (lc == 'pa'
                        ? 'ਖੇਤੀ ਮਸ਼ੀਨਰੀ'
                        : (lc == 'mr'
                              ? 'कृषी अवजारे व यंत्रे'
                              : 'Equipment & Machinery')));
      case 'Natural Farming':
        return lc == 'gu'
            ? 'પ્રાકૃતિક ખેતી'
            : (lc == 'hi'
                  ? 'प्राकृतिक खेती'
                  : (lc == 'pa'
                        ? 'ਕੁਦਰਤੀ ਖੇਤੀ'
                        : (lc == 'mr' ? 'नैसर्गिक शेती' : 'Natural Farming')));
      case 'Irrigation & Water':
        return lc == 'gu'
            ? 'સિંચાઈ અને જળ'
            : (lc == 'hi'
                  ? 'सिंचाई एवं जल'
                  : (lc == 'pa'
                        ? 'ਸਿੰਚਾਈ ਅਤੇ ਪਾਣੀ'
                        : (lc == 'mr'
                              ? 'सिंचन व पाणी'
                              : 'Irrigation & Water')));
      case 'Agriculture':
        return lc == 'gu'
            ? 'ખેતીવાડી'
            : (lc == 'hi'
                  ? 'कृषि'
                  : (lc == 'pa'
                        ? 'ਖੇਤੀਬਾੜੀ'
                        : (lc == 'mr' ? 'कृषी' : 'Agriculture')));
      case 'Horticulture':
        return lc == 'gu'
            ? 'બાગાયત'
            : (lc == 'hi'
                  ? 'बागवानी'
                  : (lc == 'pa'
                        ? 'ਬਾਗਬਾਨੀ'
                        : (lc == 'mr' ? 'बागकाम' : 'Horticulture')));
      case 'Irrigation and Solar':
      case 'Irrigation & Solar':
        return lc == 'gu'
            ? 'સોલાર અને સિંચાઈ'
            : (lc == 'hi' ? 'सौर एवं सिंचाई' : 'Irrigation & Solar');
      case 'Animal Husbandry':
        return lc == 'gu'
            ? 'પશુપાલન'
            : (lc == 'hi' ? 'पशुपालन' : 'Animal Husbandry');
      case 'Fisheries':
        return lc == 'gu'
            ? 'મત્સ્યોદ્યોગ'
            : (lc == 'hi' ? 'मत्स्य पालन' : 'Fisheries');
      case 'Crop Insurance':
        return lc == 'gu'
            ? 'પાક વીમો'
            : (lc == 'hi' ? 'फसल बीमा' : 'Crop Insurance');
      case 'Marketing and Infrastructure':
      case 'Marketing & Infrastructure':
        return lc == 'gu'
            ? 'બજાર અને ઈન્ફ્રાસ્ટ્રક્ચર'
            : (lc == 'hi' ? 'विपणन एवं ढांचा' : 'Marketing & Infrastructure');
      default:
        return category;
    }
  }

  static String getViewPdfLabel(String langCode) {
    final lc = langCode.toLowerCase();
    return lc == 'gu'
        ? 'GR / PDF જુઓ'
        : (lc == 'hi' ? 'GR / PDF देखें' : 'View GR / PDF');
  }

  static String getHelplineLabel(String langCode) {
    final lc = langCode.toLowerCase();
    return lc == 'gu'
        ? 'હેલ્પલાઇન'
        : (lc == 'hi' ? 'हेल्पलाइन' : 'Helpline');
  }

  static String getDirectApplyLabel(String langCode) {
    final lc = langCode.toLowerCase();
    return lc == 'gu'
        ? 'ઓનલાઇન અરજી'
        : (lc == 'hi' ? 'ऑनलाइन आवेदन' : 'Apply Online');
  }

  static String getLastVerifiedLabel(String langCode) {
    final lc = langCode.toLowerCase();
    return lc == 'gu'
        ? 'ચકાસણી'
        : (lc == 'hi' ? 'सत्यापित' : 'Verified');
  }

  static String getMainBenefitHeading(String langCode) {
    final lc = langCode.toLowerCase();
    return lc == 'gu'
        ? 'મુખ્ય સહાય / સબસિડી:'
        : (lc == 'hi' ? 'मुख्य लाभ / सब्सिडी:' : 'Main Benefit / Subsidy:');
  }

  static String getStatusLabel(String status, String langCode) {
    final lc = langCode.toLowerCase();
    switch (status) {
      case 'All':
        return lc == 'gu' ? 'બધા સ્ટેટસ' : (lc == 'hi' ? 'सभी स्थिति' : 'All');
      case 'Open':
        return lc == 'gu'
            ? 'ચાલુ (Open)'
            : (lc == 'hi'
                  ? 'सक्रिय (Open)'
                  : (lc == 'pa' ? 'ਚਾਲੂ (Open)' : 'Open'));
      case 'Upcoming':
        return lc == 'gu'
            ? 'આગામી (Upcoming)'
            : (lc == 'hi'
                  ? 'आगामी (Upcoming)'
                  : (lc == 'pa' ? 'ਅਗਲੀ (Upcoming)' : 'Upcoming'));
      default:
        return status;
    }
  }

  static String getStateDropdownLabel(String state, String langCode) {
    final lc = langCode.toLowerCase();
    switch (state) {
      case 'All India':
        return lc == 'gu'
            ? 'સમગ્ર ભારત (All India)'
            : (lc == 'hi'
                  ? 'अखिल भारतीय (All India)'
                  : (lc == 'pa' ? 'ਸਮੁੱਚਾ ਭਾਰਤ (All India)' : 'All India'));
      case 'Gujarat':
        return lc == 'gu'
            ? 'ગુજરાત (Gujarat)'
            : (lc == 'hi' ? 'गुजरात (Gujarat)' : 'Gujarat');
      case 'Punjab':
        return lc == 'gu'
            ? 'પંજાબ (Punjab)'
            : (lc == 'hi'
                  ? 'पंजाब (Punjab)'
                  : (lc == 'pa' ? 'ਪੰਜਾਬ (Punjab)' : 'Punjab'));
      case 'Maharashtra':
        return lc == 'gu'
            ? 'મહારાષ્ટ્ર (Maharashtra)'
            : (lc == 'hi'
                  ? 'महाराष्ट्र (Maharashtra)'
                  : (lc == 'mr' ? 'महाराष्ट्र (Maharashtra)' : 'Maharashtra'));
      case 'Uttar Pradesh':
        return lc == 'gu'
            ? 'ઉત્તર પ્રદેશ (UP)'
            : (lc == 'hi' ? 'उत्तर प्रदेश (UP)' : 'Uttar Pradesh');
      case 'Rajasthan':
        return lc == 'gu'
            ? 'રાજસ્થાન (Rajasthan)'
            : (lc == 'hi' ? 'राजस्थान (Rajasthan)' : 'Rajasthan');
      case 'Madhya Pradesh':
        return lc == 'gu'
            ? 'મધ્ય પ્રદેશ (MP)'
            : (lc == 'hi' ? 'मध्य प्रदेश (MP)' : 'Madhya Pradesh');
      case 'Haryana':
        return lc == 'gu'
            ? 'હરિયાણા (Haryana)'
            : (lc == 'hi' ? 'हरियाणा (Haryana)' : 'Haryana');
      default:
        return state;
    }
  }

  static String getDeadlineLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'અંતિમ તારીખ';
      case 'hi':
        return 'अंतिम तिथि';
      case 'pa':
        return 'ਆਖ਼ਰੀ ਤਾਰੀਖ਼';
      case 'mr':
        return 'शेवटची तारीख';
      default:
        return 'Deadline';
    }
  }

  static String getDetailsApplyLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'વિગત અને અરજી';
      case 'hi':
        return 'विवरण व आवेदन';
      case 'pa':
        return 'ਵੇਰਵੇ ਅਤੇ ਅਰਜ਼ੀ';
      case 'mr':
        return 'तपशील आणि अर्ज';
      default:
        return 'Details & Apply';
    }
  }

  static String getNoSchemesLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'આ માપદંડ માટે કોઈ યોજના મળી નથી';
      case 'hi':
        return 'इस मानदंड के लिए कोई योजना उपलब्ध नहीं है';
      case 'pa':
        return 'ਕੋਈ ਸਕੀਮ ਉਪਲਬਧ ਨਹੀਂ ਹੈ';
      case 'mr':
        return 'कोणतीही योजना उपलब्ध नाही';
      default:
        return 'No schemes matching criteria';
    }
  }

  static String getJurisdictionLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'કાર્યક્ષેત્ર:';
      case 'hi':
        return 'क्षेत्राधिकार:';
      default:
        return 'Jurisdiction:';
    }
  }

  static String getBenefitsHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'મુખ્ય નાણાકીય લાભ અને સબસિડી';
      case 'hi':
        return 'मुख्य वित्तीय लाभ एवं सब्सिडी';
      case 'pa':
        return 'ਮੁੱਖ ਵਿੱਤੀ ਲਾਭ ਅਤੇ ਸਬਸਿਡੀ';
      case 'mr':
        return 'मुख्य आर्थिक फायदे आणि अनुदान';
      default:
        return 'Financial Benefits & Subsidy';
    }
  }

  static String getAboutHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'યોજના વિશે વિગત';
      case 'hi':
        return 'योजना के बारे में';
      default:
        return 'About the Scheme';
    }
  }

  static String getEligibilityHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પાત્રતા માપદંડ (કોણ અરજી કરી શકે)';
      case 'hi':
        return 'पात्रता मानदंड (कौन आवेदन कर सकता है)';
      default:
        return 'Eligibility Criteria';
    }
  }

  static String getDocumentsHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'જરૂરી દસ્તાવેજો';
      case 'hi':
        return 'आवश्यक दस्तावेज़';
      default:
        return 'Required Documents';
    }
  }

  static String getCheckStatusLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સ્થિતિ તપાસો';
      case 'hi':
        return 'स्थिति जांचें';
      case 'pa':
        return 'ਸਥਿਤੀ ਜਾਂਚੋ';
      default:
        return 'Check Status';
    }
  }

  static String getApplyPortalLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પોર્ટલ પર અરજી કરો';
      case 'hi':
        return 'पोर्टल पर आवेदन करें';
      case 'pa':
        return 'ਪੋਰਟਲ ਤੇ ਅਰਜ਼ੀ ਦਿਓ';
      default:
        return 'Apply on Portal';
    }
  }

  static String getOfficialPortalLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સત્તાવાર પોર્ટલ:';
      case 'hi':
        return 'आधिकारिक पोर्टल:';
      default:
        return 'Official Portal:';
    }
  }

  static String getLookupTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'અરજી સ્થિતિ તપાસ (Lookup)';
      case 'hi':
        return 'आवेदन स्थिति जांच (Lookup)';
      default:
        return 'Application Status Lookup';
    }
  }

  static String getLookupHint(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return '12-અંકનો આધાર / ખેડૂત નોંધણી ID દાખલ કરો';
      case 'hi':
        return '12-अंकीय आधार / किसान पंजीकरण आईडी दर्ज करें';
      default:
        return 'Enter 12-digit Aadhaar / Farmer ID';
    }
  }

  static String getCloseLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'બંધ કરો';
      case 'hi':
        return 'बंद करें';
      default:
        return 'Close';
    }
  }

  // --- Scheme-Specific Multilingual Mappings ---

  static final Map<String, Map<String, String>> _schemeNames = {
    'pm-kisan-01': {
      'gu': 'પીએમ-કિસાન સન્માન નિધિ યોજના (PM-KISAN)',
      'hi': 'पीएम-किसान सम्मान निधि योजना',
      'pa': 'ਪੀਐਮ-ਕਿਸਾਨ ਸਨਮਾਨ ਨਿਧੀ ਸਕੀਮ',
      'mr': 'पीएम-किसान सन्मान निधी योजना',
    },
    'pmfby-02': {
      'gu': 'પ્રધાનમંત્રી ફસલ બીમા યોજના (PMFBY પાક વીમો)',
      'hi': 'प्रधानमंत्री फसल बीमा योजना (PMFBY)',
      'pa': 'ਪ੍ਰਧਾਨ ਮੰਤਰੀ ਫਸਲ ਬੀਮਾ ਸਕੀਮ',
      'mr': 'प्रधानमंत्री पीक विमा योजना',
    },
    'kcc-03': {
      'gu': 'કિસાન ક્રેડિટ કાર્ડ (KCC) રાહતદરે લોન',
      'hi': 'किसान क्रेडिट कार्ड (KCC) रियायती ऋण योजना',
      'pa': 'ਕਿਸਾਨ ਕ੍ਰੈਡਿਟ ਕਾਰਡ (KCC) ਰਿਆਇਤੀ ਕਰਜ਼ਾ',
      'mr': 'किसान क्रेडिट कार्ड (KCC) सवलतीचे पीक कर्ज',
    },
    'ikhedut-tractor-04': {
      'gu': 'ગુજરાત આઇ-ખેડૂત કૃષિ ટ્રેક્ટર સહાય યોજના',
      'hi': 'गुजरात आई-खेड़ूत कृषि ट्रैक्टर सहायता योजना',
      'pa': 'ਗੁਜਰਾਤ ਟਰੈਕਟਰ ਸਬਸਿਡੀ ਸਕੀਮ',
      'mr': 'गुजरात ट्रॅक्टर सहाय्य योजना',
    },
    'gujarat-natural-05': {
      'gu': 'ગુજરાત દેશી ગાય આધારિત પ્રાકૃતિક ખેતી સહાય',
      'hi': 'गुजरात देशी गाय आधारित प्राकृतिक खेती मासिक सहायता',
      'pa': 'ਗੁਜਰਾਤ ਦੇਸੀ ਗਾਂ ਕੁਦਰਤੀ ਖੇਤੀ ਸਹਾਇਤਾ',
      'mr': 'गुजरात देशी गाय नैसर्गिक शेती मासिक सहाय्य',
    },
    'ikhedut-fencing-06': {
      'gu': 'ગુજરાત સોલાર ઝટકા અને કાંટાળી તાર ફેન્સિંગ સહાય',
      'hi': 'गुजरात सोलर झटका एवं कांटेदार तारबंदी सहायता',
      'pa': 'ਗੁਜਰਾਤ ਸੋਲਰ ਝਟਕਾ ਅਤੇ ਤਾਰਬੰਦੀ ਸਕੀਮ',
      'mr': 'गुजरात सोलर झटका व काटेरी तार कुंपण योजना',
    },
    'pmksy-drip-07': {
      'gu': 'પીએમ કૃષિ સિંચાઈ યોજના (PMKSY) - ટપક / ફુવારા સિંચાઈ',
      'hi': 'प्रधानमंत्री कृषि सिंचाई योजना (PMKSY) - सूक्ष्म सिंचाई',
      'pa': 'ਪ੍ਰਧਾਨ ਮੰਤਰੀ ਕ੍ਰਿਸ਼ੀ ਸਿੰਚਾਈ ਸਕੀਮ (ਤੁਪਕਾ ਸਿੰਚਾਈ)',
      'mr': 'प्रधानमंत्री कृषी सिंचन योजना (सूक्ष्म सिंचन)',
    },
    'midh-horticulture-08': {
      'gu': 'બાગાયત સંકલિત વિકાસ રાષ્ટ્રીય મિશન (MIDH)',
      'hi': 'बागवानी एकीकृत विकास मिशन (MIDH)',
      'pa': 'ਬਾਗਬਾਨੀ ਵਿਕਾਸ ਮਿਸ਼ਨ (MIDH)',
      'mr': 'एकात्मिक फलोत्पादन विकास अभियान',
    },
    'punjab-crm-09': {
      'gu': 'પંજાબ પાક અવશેષ વ્યવસ્થાપન (CRM) સહાય',
      'hi': 'पंजाब फसल अवशेष प्रबंधन (CRM) सब्सिडी योजना',
      'pa': 'ਪੰਜਾਬ ਫਸਲੀ ਰਹਿੰਦ-ਖੂੰਹਦ ਪ੍ਰਬੰਧਨ (CRM) ਸਬਸਿਡੀ',
      'mr': 'पंजाब पीक अवशेष व्यवस्थापन सबसिडी योजना',
    },
    'maha-loan-10': {
      'gu': 'મહારાષ્ટ્ર ડૉ. પંજાબરાવ દેશમુખ 0% વ્યાજ પાક લોન',
      'hi': 'महाराष्ट्र डॉ. पंजाबराव देशमुख 0% ब्याज फसल ऋण',
      'pa': 'ਮਹਾਰਾਸ਼ਟਰ 0% ਵਿਆਜ ਫਸਲੀ ਕਰਜ਼ਾ ਸਕੀਮ',
      'mr': 'महाराष्ट्र डॉ. पंजाबराव देशमुख 0% पीक कर्ज योजना',
    },
    'up-kusum-11': {
      'gu': 'ઉત્તર પ્રદેશ PM-KUSUM સોલાર ટ્યુબવેલ સબસિડી',
      'hi': 'उत्तर प्रदेश PM-KUSUM सोलर नलकूप सब्सिडी योजना',
      'pa': 'ਉੱਤਰ ਪ੍ਰਦੇਸ਼ PM-KUSUM ਸੋਲਰ ਟਿਊਬਵੈੱਲ ਸਬਸਿਡੀ',
      'mr': 'उत्तर प्रदेश PM-KUSUM सोलर नलकूप अनुदान',
    },
    'raj-tarbandi-12': {
      'gu': 'રાજસ્થાન ખેત તારબંધી સહાય યોજના',
      'hi': 'राजस्थान तारबंदी योजना (खेत सुरक्षा तारबंदी)',
      'pa': 'ਰਾਜਸਥਾਨ ਤਾਰਬੰਦੀ ਸਬਸਿਡੀ ਸਕੀਮ',
      'mr': 'राजस्थान शेत तारबंदी अनुदान योजना',
    },
  };

  static final Map<String, Map<String, String>> _schemeBenefits = {
    'pm-kisan-01': {
      'gu': 'વાર્ષિક ₹6,000 (100% સીધા બેંક ખાતામાં DBT PFMS દ્વારા)',
      'hi': '₹6,000/वर्ष (100% प्रत्यक्ष लाभ अंतरण DBT PFMS द्वारा)',
      'pa': '₹6,000/ਸਾਲ (ਸਿੱਧਾ ਬੈਂਕ ਖਾਤੇ ਵਿੱਚ DBT ਰਾਹੀਂ)',
    },
    'pmfby-02': {
      'gu': 'ખરીફ 2%, રવિ 1.5% પ્રીમિયમ દરે સંપૂર્ણ પાક વીમા સુરક્ષા',
      'hi': 'खरीफ 2%, रबी 1.5% प्रीमियम पर व्यापक फसल सुरक्षा',
      'pa': 'ਖਰੀਫ਼ 2%, ਰਬੀ 1.5% ਪ੍ਰੀਮੀਅਮ ਤੇ ਪੂਰੀ ਫਸਲ ਸੁਰੱਖਿਆ',
    },
    'kcc-03': {
      'gu': '₹3 લાખ સુધીની લોન માત્ર 4% વ્યાજે, ₹1.6 લાખ સુધી ગેરંટી વગર',
      'hi': '₹3 लाख तक ऋण 4% ब्याज पर, ₹1.6 लाख तक बिना बंधक',
      'pa': '₹3 ਲੱਖ ਤੱਕ ਕਰਜ਼ਾ 4% ਵਿਆਜ ਤੇ, ₹1.6 ਲੱਖ ਬਿਨਾਂ ਗਾਰੰਟੀ',
    },
    'ikhedut-tractor-04': {
      'gu':
          'સામાન્ય ખેડૂત: 25% સહાય (₹45,000 સુધી), SC/ST/મહિલા: 35% (₹60,000)',
      'hi': 'सामान्य किसान: 25% सब्सिडी (₹45,000), SC/ST/महिला: 35% (₹60,000)',
      'pa': 'ਆਮ ਕਿਸਾਨ: 25% ਸਬਸਿਡੀ (₹45,000), SC/ST/ਔਰਤ: 35% (₹60,000)',
    },
    'gujarat-natural-05': {
      'gu': 'પ્રતિ માસ ₹900 (વાર્ષિક ₹10,800) સીધા બેંક ખાતામાં',
      'hi': 'प्रति माह ₹900 (वार्षिक ₹10,800) सीधे बैंक खाते में',
      'pa': 'ਹਰ ਮਹੀਨੇ ₹900 (ਸਾਲਾਨਾ ₹10,800) ਸਿੱਧਾ ਬੈਂਕ ਖਾਤੇ ਵਿੱਚ',
    },
    'ikhedut-fencing-06': {
      'gu': 'ખર્ચના 50% અથવા મીટર દીઠ ₹200 (મહત્તમ ₹40,000 સહાય)',
      'hi': 'लागत का 50% या ₹200 प्रति मीटर (अधिकतम ₹40,000)',
      'pa': 'ਲਾਗਤ ਦਾ 50% ਜਾਂ ₹200 ਪ੍ਰਤੀ ਮੀਟਰ (ਵੱਧ ਤੋਂ ਵੱਧ ₹40,000)',
    },
    'pmksy-drip-07': {
      'gu': 'ટપક/ફુવારા પદ્ધતિ માટે 55% થી 70% સુધી સરકારી સબસિડી',
      'hi': 'ड्रिप/स्प्रिंकलर स्थापना हेतु 55% से 70% सरकारी सब्सिडी',
      'pa': 'ਤੁਪਕਾ ਸਿੰਚਾਈ ਲਈ 55% ਤੋਂ 70% ਸਰਕਾਰੀ ਸਬਸਿਡੀ',
    },
    'midh-horticulture-08': {
      'gu': 'બગીચા, ગ્રીનહાઉસ, કોલ્ડ સ્ટોરેજ માટે 40% થી 50% સબસિડી',
      'hi': 'बागवानी, पॉलीहाउस, कोल्ड स्टोरेज हेतु 40% से 50% सब्सिडी',
      'pa': 'ਪੌਲੀਹਾਊਸ, ਕੋਲਡ ਸਟੋਰੇਜ ਲਈ 40% ਤੋਂ 50% ਸਬਸਿਡੀ',
    },
    'punjab-crm-09': {
      'gu': 'સુપર સીડર, હેપી સીડર, બેલર પર 50% થી 80% સબસિડી',
      'hi': 'सुपर सीडर, हैप्पी सीडर, बेलर पर 50% से 80% सब्सिडी',
      'pa': 'ਸੁਪਰ ਸੀਡਰ, ਹੈਪੀ ਸੀਡਰ, ਬੇਲਰ ਤੇ 50% ਤੋਂ 80% ਸਬਸਿਡੀ',
    },
    'maha-loan-10': {
      'gu': 'સમયસર ભરપાઈ પર ₹3 લાખ સુધીના પાક ધિરાણ પર 0% વ્યાજ',
      'hi': 'समय पर भुगतान पर ₹3 लाख तक फसल ऋण पर 0% ब्याज',
      'pa': 'ਸਮੇਂ ਸਿਰ ਅਦਾਇਗੀ ਤੇ ₹3 ਲੱਖ ਤੱਕ ਫਸਲੀ ਕਰਜ਼ੇ ਤੇ 0% ਵਿਆਜ',
    },
    'up-kusum-11': {
      'gu': 'સોલાર પંપ અને ટ્યુબવેલ સ્થાપન માટે 60% સુધી અનુદાન',
      'hi': 'सोलर पंप व नलकूप स्थापना हेतु 60% तक सरकारी अनुदान',
      'pa': 'ਸੋਲਰ ਪੰਪ ਲਗਾਉਣ ਲਈ 60% ਤੱਕ ਸਰਕਾਰੀ ਸਬਸਿਡੀ',
    },
    'raj-tarbandi-12': {
      'gu': 'ખેત તારબંધી માટે ખર્ચના 50% અથવા મહત્તમ ₹40,000 સહાય',
      'hi': '400 मीटर तारबंदी हेतु लागत का 50% या अधिकतम ₹40,000 अनुदान',
      'pa': 'ਤਾਰਬੰਦੀ ਲਈ ਲਾਗਤ ਦਾ 50% ਜਾਂ ਵੱਧ ਤੋਂ ਵੱਧ ₹40,000 ਸਬਸਿਡੀ',
    },
  };

  static String getSchemeName(
    String schemeId,
    String fallback,
    String langCode,
  ) {
    final lc = langCode.toLowerCase();
    if (_schemeNames.containsKey(schemeId) &&
        _schemeNames[schemeId]!.containsKey(lc)) {
      return _schemeNames[schemeId]![lc]!;
    }
    // Hindi fallback
    if (lc != 'en' &&
        _schemeNames.containsKey(schemeId) &&
        _schemeNames[schemeId]!.containsKey('hi')) {
      return _schemeNames[schemeId]!['hi']!;
    }
    return fallback;
  }

  static String getSchemeBenefits(
    String schemeId,
    String fallback,
    String langCode,
  ) {
    final lc = langCode.toLowerCase();
    if (_schemeBenefits.containsKey(schemeId) &&
        _schemeBenefits[schemeId]!.containsKey(lc)) {
      return _schemeBenefits[schemeId]![lc]!;
    }
    if (lc != 'en' &&
        _schemeBenefits.containsKey(schemeId) &&
        _schemeBenefits[schemeId]!.containsKey('hi')) {
      return _schemeBenefits[schemeId]!['hi']!;
    }
    return fallback;
  }
}
