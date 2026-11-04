/// Comprehensive Multilingual Localization for Government Schemes and Subsidies.
/// Supports Gujarati, Hindi, Punjabi, and English.
class GovtSchemeLocalization {
  GovtSchemeLocalization._();

  static String getTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'અખિલ ભારતીય યોજનાઓ';
      case 'hi':
        return 'अखिल भारतीय योजनाएं';
      case 'pa':
        return 'ਸਮੁੱਚੀਆਂ ਭਾਰਤੀ ਸਕੀਮਾਂ';
      default:
        return 'All India Schemes';
    }
  }

  static String getSearchHint(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'યોજના શોધો (દા.ત. સિંચાઈ, સબસિડી...)';
      case 'hi':
        return 'योजना खोजें (उदा. सिंचाई, सब्सिडी...)';
      case 'pa':
        return 'ਸਕੀਮ ਖੋਜੋ (ਜਿਵੇਂ ਕਿ ਸਿੰਚਾਈ, ਸਬਸਿਡੀ...)';
      default:
        return 'Search schemes (e.g. irrigation, subsidy...)';
    }
  }

  static String getCategoryLabel(String category, String langCode) {
    final lc = langCode.toLowerCase();
    switch (category) {
      case 'All Categories':
      case 'All':
        return lc == 'gu'
            ? 'બધી કેટેગરી'
            : (lc == 'hi' ? 'सभी श्रेणियां' : 'All Categories');
      case 'Agriculture':
        return lc == 'gu' ? 'ખેતીવાડી' : (lc == 'hi' ? 'कृषि' : 'Agriculture');
      case 'Irrigation':
      case 'Irrigation & Water':
        return lc == 'gu' ? 'સિંચાઈ' : (lc == 'hi' ? 'सिंचाई' : 'Irrigation');
      case 'Horticulture':
        return lc == 'gu'
            ? 'બાગાયત'
            : (lc == 'hi' ? 'बागवानी' : 'Horticulture');
      case 'Animal Husbandry':
        return lc == 'gu'
            ? 'પશુપાલન'
            : (lc == 'hi' ? 'पशुपालन' : 'Animal Husbandry');
      case 'Dairy':
        return lc == 'gu' ? 'ડેરી વિકાસ' : (lc == 'hi' ? 'डेयरी' : 'Dairy');
      case 'Fisheries':
        return lc == 'gu'
            ? 'મત્સ્યપાલન'
            : (lc == 'hi' ? 'मत्स्य पालन' : 'Fisheries');
      case 'Farm Machinery':
      case 'Equipment & Machinery':
        return lc == 'gu'
            ? 'કૃષિ યંત્રો'
            : (lc == 'hi' ? 'कृषि मशीनरी' : 'Farm Machinery');
      case 'Crop Insurance':
        return lc == 'gu'
            ? 'પાક વીમો'
            : (lc == 'hi' ? 'फसल बीमा' : 'Crop Insurance');
      case 'Solar Energy':
        return lc == 'gu'
            ? 'સૌર ઊર્જા'
            : (lc == 'hi' ? 'सौर ऊर्जा' : 'Solar Energy');
      case 'Seeds and Fertilizers':
        return lc == 'gu'
            ? 'બિયારણ અને ખાતર'
            : (lc == 'hi' ? 'बीज व उर्वरक' : 'Seeds and Fertilizers');
      case 'Farmer Welfare':
        return lc == 'gu'
            ? 'ખેડૂત કલ્યાણ'
            : (lc == 'hi' ? 'किसान कल्याण' : 'Farmer Welfare');
      case 'Natural Farming':
        return lc == 'gu'
            ? 'પ્રાકૃતિક ખેતી'
            : (lc == 'hi' ? 'प्राकृतिक खेती' : 'Natural Farming');
      default:
        return category;
    }
  }

  static String getBenefitTypeLabel(String benefit, String langCode) {
    final lc = langCode.toLowerCase();
    switch (benefit) {
      case 'All Benefits':
      case 'All':
        return lc == 'gu'
            ? 'બધા લાભ'
            : (lc == 'hi' ? 'सभी लाभ' : 'All Benefits');
      case 'Subsidy':
        return lc == 'gu'
            ? 'સબસિડી / સહાય'
            : (lc == 'hi' ? 'सब्सिडी' : 'Subsidy');
      case 'Loan':
        return lc == 'gu' ? 'ધિરાણ / લોન' : (lc == 'hi' ? 'ऋण / लोन' : 'Loan');
      case 'Insurance':
        return lc == 'gu' ? 'વીમો' : (lc == 'hi' ? 'बीमा' : 'Insurance');
      case 'Direct Benefit Transfer':
        return lc == 'gu'
            ? 'સીધો ખાતામાં લાભ (DBT)'
            : (lc == 'hi' ? 'डीबीटी (DBT)' : 'Direct Benefit Transfer');
      case 'Equipment Assistance':
        return lc == 'gu'
            ? 'સાધન સહાય'
            : (lc == 'hi' ? 'उपकरण सहायता' : 'Equipment Assistance');
      case 'Training':
        return lc == 'gu' ? 'તાલીમ' : (lc == 'hi' ? 'प्रशिक्षण' : 'Training');
      case 'Financial Assistance':
        return lc == 'gu'
            ? 'નાણાકીય સહાય'
            : (lc == 'hi' ? 'वित्तीय सहायता' : 'Financial Assistance');
      default:
        return benefit;
    }
  }

  static String getCropFilterLabel(String crop, String langCode) {
    final lc = langCode.toLowerCase();
    switch (crop) {
      case 'All Crops':
      case 'All':
        return lc == 'gu'
            ? 'બધા પાક'
            : (lc == 'hi' ? 'सभी फसलें' : 'All Crops');
      case 'Wheat':
        return lc == 'gu' ? 'ઘઉં (Wheat)' : (lc == 'hi' ? 'गेहूं' : 'Wheat');
      case 'Rice':
      case 'Paddy':
        return lc == 'gu'
            ? 'ડાંગર / ચોખા'
            : (lc == 'hi' ? 'धान / चावल' : 'Rice');
      case 'Cotton':
        return lc == 'gu' ? 'કપાસ (Cotton)' : (lc == 'hi' ? 'कपास' : 'Cotton');
      case 'Groundnut':
        return lc == 'gu'
            ? 'મગફળી (Groundnut)'
            : (lc == 'hi' ? 'मूंगफली' : 'Groundnut');
      case 'Maize':
        return lc == 'gu' ? 'મકાઈ (Maize)' : (lc == 'hi' ? 'मक्का' : 'Maize');
      case 'Pulses':
      case 'Gram':
        return lc == 'gu'
            ? 'કઠોળ (Pulses)'
            : (lc == 'hi' ? 'दलहन / चना' : 'Pulses');
      case 'Vegetables':
        return lc == 'gu'
            ? 'શાકભાજી (Vegetables)'
            : (lc == 'hi' ? 'सब्जियां' : 'Vegetables');
      case 'Fruits':
        return lc == 'gu' ? 'ફળો (Fruits)' : (lc == 'hi' ? 'फल' : 'Fruits');
      case 'Other Crops':
        return lc == 'gu'
            ? 'અન્ય પાક'
            : (lc == 'hi' ? 'अन्य फसलें' : 'Other Crops');
      default:
        return crop;
    }
  }

  static String getStatusLabel(String status, String langCode) {
    final lc = langCode.toLowerCase();
    switch (status.toLowerCase()) {
      case 'all':
      case 'all status':
        return lc == 'gu'
            ? 'બધી સ્થિતિ'
            : (lc == 'hi' ? 'सभी स्थिति' : 'All Status');
      case 'open':
        return lc == 'gu'
            ? 'ચાલુ (Open)'
            : (lc == 'hi' ? 'सक्रिय (Open)' : 'Open');
      case 'upcoming':
        return lc == 'gu'
            ? 'આગામી (Upcoming)'
            : (lc == 'hi' ? 'आगामी (Upcoming)' : 'Upcoming');
      case 'ongoing':
        return lc == 'gu'
            ? 'નિરંતર (Ongoing)'
            : (lc == 'hi' ? 'निरंतर (Ongoing)' : 'Ongoing');
      case 'closed':
        return lc == 'gu'
            ? 'બંધ થયેલ (Closed)'
            : (lc == 'hi' ? 'समाप्त (Closed)' : 'Closed');
      case 'status unknown':
      case 'unknown':
        return lc == 'gu'
            ? 'અચોક્કસ'
            : (lc == 'hi' ? 'अज्ञात स्थिति' : 'Status Unknown');
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
            : (lc == 'hi' ? 'अखिल भारतीय (All India)' : 'All India');
      case 'Gujarat':
        return lc == 'gu'
            ? 'ગુજરાત (Gujarat)'
            : (lc == 'hi' ? 'गुजरात' : 'Gujarat');
      case 'Punjab':
        return lc == 'gu'
            ? 'પંજાબ (Punjab)'
            : (lc == 'hi' ? 'पंजाब' : 'Punjab');
      case 'Maharashtra':
        return lc == 'gu'
            ? 'મહારાષ્ટ્ર (Maharashtra)'
            : (lc == 'hi' ? 'महाराष्ट्र' : 'Maharashtra');
      case 'Uttar Pradesh':
        return lc == 'gu'
            ? 'ઉત્તર પ્રદેશ (UP)'
            : (lc == 'hi' ? 'उत्तर प्रदेश' : 'Uttar Pradesh');
      case 'Rajasthan':
        return lc == 'gu'
            ? 'રાજસ્થાન (Rajasthan)'
            : (lc == 'hi' ? 'राजस्थान' : 'Rajasthan');
      case 'Madhya Pradesh':
        return lc == 'gu'
            ? 'મધ્ય પ્રદેશ (MP)'
            : (lc == 'hi' ? 'मध्य प्रदेश' : 'Madhya Pradesh');
      case 'Haryana':
        return lc == 'gu'
            ? 'હરિયાણા (Haryana)'
            : (lc == 'hi' ? 'हरियाणा' : 'Haryana');
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
      default:
        return 'Deadline';
    }
  }

  static String getDetailsApplyLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'વિગત જુઓ';
      case 'hi':
        return 'विवरण देखें';
      default:
        return 'Scheme Details';
    }
  }

  static String getApplyOnlineLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સત્તાવાર પોર્ટલ પર ઓનલાઇન અરજી કરો';
      case 'hi':
        return 'आधिकारिक पोर्टल पर ऑनलाइन आवेदन करें';
      default:
        return 'Apply Online on Official Portal';
    }
  }

  static String getCheckEligibilityLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'મારી પાત્રતા તપાસો';
      case 'hi':
        return 'मेरी पात्रता जांचें';
      default:
        return 'Check My Eligibility';
    }
  }

  static String getNoSchemesLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પસંદ કરેલા ફિલ્ટર સાથે કોઈ યોજના મળી નથી.';
      case 'hi':
        return 'चयनित फिल्टर के अनुसार कोई योजना नहीं मिली।';
      default:
        return 'No schemes found matching your search/filters.';
    }
  }

  static String getResetFiltersLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'ફિલ્ટર્સ રીસેટ કરો';
      case 'hi':
        return 'फिल्टर रीसेट करें';
      default:
        return 'Reset Filters';
    }
  }

  static String getBenefitsHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સહાય / સબસિડી વિગત';
      case 'hi':
        return 'सब्सिडी एवं वित्तीय लाभ';
      default:
        return 'Benefits & Financial Assistance';
    }
  }

  static String getAboutHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'યોજના વિશે માહિતી';
      case 'hi':
        return 'योजना का विवरण';
      default:
        return 'Scheme Overview';
    }
  }

  static String getEligibilityHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'લાભ મેળવવા માટેની પાત્રતા';
      case 'hi':
        return 'पात्रता मानदंड';
      default:
        return 'Eligibility Criteria';
    }
  }

  static String getDocumentsHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'જરૂરી આધાર-પુરાવા (દસ્તાવેજો)';
      case 'hi':
        return 'आवश्यक दस्तावेज';
      default:
        return 'Required Documents';
    }
  }

  static String getHowToApplyHeading(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'અરજી કરવાની પદ્ધતિ';
      case 'hi':
        return 'आवेदन कैसे करें';
      default:
        return 'How to Apply';
    }
  }

  static String getLookupTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'અરજીનું સ્ટેટસ તપાસો';
      case 'hi':
        return 'आवेदन स्थिति जांचें';
      default:
        return 'Check Application Status';
    }
  }

  static String getLookupHint(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'આધાર નંબર અથવા ખેડૂત નોંધણી નંબર દાખલ કરો';
      case 'hi':
        return 'आधार या किसान पंजीकरण संख्या दर्ज करें';
      default:
        return 'Enter 12-digit Aadhaar or Farmer ID';
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

  static String getJurisdictionLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'ક્ષેત્ર:';
      case 'hi':
        return 'क्षेत्र:';
      default:
        return 'State:';
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

  static String getCheckStatusLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'સ્ટેટસ તપાસો';
      case 'hi':
        return 'स्थिति जांचें';
      default:
        return 'Check Status';
    }
  }

  static String getApplyPortalLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પોર્ટલ ખોલો';
      case 'hi':
        return 'पोर्टल खोलें';
      default:
        return 'Open Portal';
    }
  }

  static String getSchemesCountLabel(int count, String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return '$count યોજનાઓ ઉપલબ્ધ';
      case 'hi':
        return '$count योजनाएं उपलब्ध';
      case 'pa':
        return '$count ਸਕੀਮਾਂ ਉਪਲਬਧ';
      default:
        return '$count Schemes Available';
    }
  }

  static String getFilterCategoryTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'કેટેગરી પસંદ કરો';
      case 'hi':
        return 'श्रेणी चुनें';
      default:
        return 'Select Category';
    }
  }

  static String getFilterBenefitTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'લાભ પ્રકાર પસંદ કરો';
      case 'hi':
        return 'लाभ का प्रकार चुनें';
      default:
        return 'Select Benefit Type';
    }
  }

  static String getFilterCropTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પાક પસંદ કરો';
      case 'hi':
        return 'फसल चुनें';
      default:
        return 'Select Crop';
    }
  }

  static String getFilterCategoryLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'કેટેગરી';
      case 'hi':
        return 'श्रेणी';
      default:
        return 'Category';
    }
  }

  static String getFilterBenefitLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'લાભ';
      case 'hi':
        return 'लाभ';
      default:
        return 'Benefit';
    }
  }

  static String getFilterCropLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'પાક';
      case 'hi':
        return 'फसल';
      default:
        return 'Crop';
    }
  }

  static String getSortByLabel(String sortBy, String langCode) {
    final lc = langCode.toLowerCase();
    switch (sortBy) {
      case 'Application Deadline':
        return lc == 'gu'
            ? 'અંતિમ તારીખ'
            : (lc == 'hi' ? 'आवेदन अंतिम तिथि' : 'Application Deadline');
      case 'Alphabetical':
        return lc == 'gu'
            ? 'નામ પ્રમાણે (A-Z)'
            : (lc == 'hi' ? 'नाम अनुसार (A-Z)' : 'Alphabetical (A to Z)');
      case 'Latest Verified':
      default:
        return lc == 'gu'
            ? 'નવીનતમ ચકાસાયેલ'
            : (lc == 'hi' ? 'नवीनतम सत्यापित' : 'Latest Verified');
    }
  }

  static String getSchemeName(String id, String defaultName, String langCode) {
    final lc = langCode.toLowerCase();
    if (lc == 'gu') {
      switch (id) {
        case 'pm-kisan-01':
          return 'પીએમ-કિસાન સન્માન નિધિ (PM-KISAN)';
        case 'pmfby-02':
        case 'pmfby-crop-insurance-02':
          return 'પ્રધાનમંત્રી ફસલ બીમા યોજના (PMFBY)';
        case 'pmksy-drip-03':
          return 'પ્રધાનમંત્રી કૃષિ સિંચાઈ યોજના - ટપક સિંચાઈ (PMKSY)';
        case 'ikhedut-tractor-04':
        case 'ikhedut-tractor-14':
          return 'ગુજરાત આઈ-ખેડૂત કૃષિ ટ્રેક્ટર સહાય યોજના';
        case 'pm-kusum-04':
        case 'pm-kusum-solar-04':
          return 'પીએમ-કુસુમ સોલાર પંપ સબસિડી યોજના (PM-KUSUM)';
        case 'kcc-loan-05':
        case 'kcc-crop-loan-05':
          return 'કિસાન ક્રેડિટ કાર્ડ ૪% વ્યાજ સબસિડી (KCC)';
        case 'gujarat-cow-15':
        case 'guj-cow-02':
        case 'ikhedut-cow-15':
          return 'ગુજરાત દેશી ગાય નિભાવ ખર્ચ સહાય યોજના';
        case 'gujarat-fencing-16':
        case 'guj-solar-fence-16':
          return 'ગુજરાત આઈ-ખેડૂત સોલાર ઝાટકા વાડ સહાય યોજના';
        case 'gujarat-polyhouse-17':
        case 'guj-greenhouse-17':
          return 'ગુજરાત હાઇ-ટેક ગ્રીનહાઉસ અને પોલીહાઉસ સબસિડી';
        case 'soil-health-09':
        case 'soil-health-card-09':
          return 'સોઇલ હેલ્થ કાર્ડ - જમીન આરોગ્ય યોજના';
        default:
          return defaultName;
      }
    }
    if (lc == 'hi') {
      switch (id) {
        case 'pm-kisan-01':
          return 'प्रधानमंत्री किसान सम्मान निधि (PM-KISAN)';
        case 'pmfby-02':
        case 'pmfby-crop-insurance-02':
          return 'प्रधानमंत्री फसल बीमा योजना (PMFBY)';
        case 'pmksy-drip-03':
          return 'प्रधानमंत्री कृषि सिंचाई योजना - ड्रिप व स्प्रिंकलर (PMKSY)';
        case 'ikhedut-tractor-04':
        case 'ikhedut-tractor-14':
          return 'गुजरात आई-खेड़ूत कृषि ट्रैक्टर सहायता योजना';
        case 'pm-kusum-04':
        case 'pm-kusum-solar-04':
          return 'पीएम-कुसुम सौर ऊर्जा पंप योजना (PM-KUSUM)';
        case 'kcc-loan-05':
        case 'kcc-crop-loan-05':
          return 'किसान क्रेडिट कार्ड ऋण योजना (KCC)';
        default:
          return defaultName;
      }
    }
    return defaultName;
  }

  static String getSchemeBenefits(
    String id,
    String defaultBenefits,
    String langCode,
  ) {
    final lc = langCode.toLowerCase();
    if (lc == 'gu') {
      switch (id) {
        case 'pm-kisan-01':
          return 'વાર્ષિક ₹૬,૦૦૦ (૩ સરખા હપ્તામાં ₹૨,૦૦૦ ડીબીટી)';
        case 'gujarat-cow-15':
        case 'guj-cow-02':
        case 'ikhedut-cow-15':
          return 'પ્રતિ માસ ₹૯૦૦ (વાર્ષિક ₹૧૦,૮૦૦) દેશી ગાયના નિભાવ માટે';
        default:
          return defaultBenefits;
      }
    }
    if (lc == 'hi') {
      switch (id) {
        case 'pm-kisan-01':
          return 'वार्षिक ₹6,000 (तीन समान किस्तों में ₹2,000)';
        default:
          return defaultBenefits;
      }
    }
    return defaultBenefits;
  }
}
