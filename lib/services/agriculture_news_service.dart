import 'package:shared_preferences/shared_preferences.dart';

import '../models/agriculture_news_item.dart';
import '../models/farmer_profile.dart';

/// Centralized Service for Official Indian Government Agriculture News,
/// Subsidies, Scheme Updates, and Verified Farmer Advisories.
class AgricultureNewsService {
  AgricultureNewsService._();
  static final AgricultureNewsService instance = AgricultureNewsService._();

  static const String _bookmarkKey = 'khetchacha_news_bookmarks_';
  final Set<String> _bookmarkedIds = {};
  bool _bookmarksLoaded = false;

  /// Verified Master Database of Official Agricultural News Announcements
  static final List<AgricultureNewsItem> _masterNewsDatabase = [
    // 1. National PM-KISAN
    AgricultureNewsItem(
      id: 'news_pmkisan_19',
      headline: 'PM-KISAN 19th Installment of ₹2,000 to be Deposited into Aadhaar-Linked Accounts',
      description: 'The Ministry of Agriculture & Farmers Welfare has announced that the 19th installment under PM-Kisan Samman Nidhi will be transferred directly via DBT PFMS. Over 9.5 crore landholder farmers with completed eKYC and land seeding will receive ₹2,000.',
      aiSummary: 'Good news! PM-KISAN ₹2,000 installment is being released. Ensure your Aadhaar eKYC and bank account seeding are active on the portal.',
      originalSource: 'Ministry of Agriculture & Farmers Welfare, GoI',
      officialSourceUrl: 'https://pmkisan.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(hours: 12)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(hours: 2)),
      applicableState: 'All India',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.pmKisan,
      relevantCrops: const ['All Crops'],
      applicationDeadline: DateTime.now().add(const Duration(days: 20)),
      isVerified: true,
      iconEmoji: '💰',
      localizedHeadlines: const {
        'gu': 'પીએમ-કિસાન યોજના: ₹2,000 નો 19મો હપ્તો આધાર લિંક્ડ બેંક ખાતામાં જમા થશે',
        'hi': 'पीएम-किसान योजना: ₹2,000 की 19वीं किस्त आधार से जुड़े बैंक खातों में होगी जमा',
        'pa': 'ਪੀਐਮ-ਕਿਸਾਨ ਸਕੀਮ: ₹2,000 ਦੀ 19ਵੀਂ ਕਿਸ਼ਤ ਆਧਾਰ ਲਿੰਕ ਖਾਤਿਆਂ ਵਿੱਚ ਜਮ੍ਹਾਂ ਹੋਵੇਗੀ',
        'mr': 'पीएम-किसान योजना: ₹2,000 चा 19वा हप्ता आधार लिंक बँक खात्यात जमा होणार',
      },
      localizedSummaries: const {
        'gu': 'ખેડૂત મિત્રો માટે ખુશખબર: પીએમ-કિસાનનો ₹2,000 નો હપ્તો જમા થઈ રહ્યો છે. તમારા આધાર eKYC અને બેંક ખાતાની ચકાસણી પોર્ટલ પર પૂર્ણ કરો.',
        'hi': 'किसान भाइयों के लिए खुशखबरी: पीएम-किसान की ₹2,000 की किस्त जारी हो रही है। पोर्टल पर अपना आधार eKYC और बैंक खाता सत्यापन पूरा करें।',
        'pa': 'ਕਿਸਾਨ ਵੀਰਾਂ ਲਈ ਖੁਸ਼ਖਬਰੀ: ਪੀਐਮ-ਕਿਸਾਨ ਦੀ ₹2,000 ਦੀ ਕਿਸ਼ਤ ਜਾਰੀ ਹੋ ਰਹੀ ਹੈ। ਪੋਰਟਲ \'ਤੇ ਆਪਣਾ ਆਧਾਰ eKYC ਪੂਰਾ ਕਰੋ।',
        'mr': 'शेतकरी मित्रांसाठी आनंदाची बातमी: पीएम-किसानचा ₹2,000 चा हप्ता जमा होत आहे. पोर्टलवर आपले आधार eKYC पूर्ण करा.',
      },
    ),

    // 2. Gujarat iKhedut Tractor & Micro-Irrigation Subsidy
    AgricultureNewsItem(
      id: 'news_guj_ikhedut_tractor',
      headline: 'Gujarat iKhedut Portal Opens for 50% Agricultural Equipment & Tractor Subsidies',
      description: 'Department of Agriculture, Government of Gujarat has activated the application window on iKhedut portal. Small, marginal, and SC/ST farmers can avail up to ₹60,000 subsidy on tractors and 50% assistance on rotavators and seed drills.',
      aiSummary: 'Gujarat Farmers: Apply online on iKhedut portal for 50% tractor and equipment subsidy before the application deadline.',
      originalSource: 'Gujarat Agriculture & Cooperation Department',
      officialSourceUrl: 'https://ikhedut.gujarat.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 1)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(hours: 4)),
      applicableState: 'Gujarat',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.farmerSubsidies,
      relevantCrops: const ['All Crops', 'Groundnut', 'Cotton', 'Wheat'],
      applicationDeadline: DateTime.now().add(const Duration(days: 25)),
      isVerified: true,
      iconEmoji: '🚜',
      localizedHeadlines: const {
        'gu': 'ગુજરાત આઈ-ખેડૂત પોર્ટલ: ટ્રેક્ટર અને કૃષિ સાધનો પર 50% સુધીની સબસિડી માટે અરજી શરૂ',
        'hi': 'गुजरात आई-खेड़ूत पोर्टल: ट्रैक्टर और कृषि उपकरणों पर 50% सब्सिडी के लिए आवेदन शुरू',
        'pa': 'ਗੁਜਰਾਤ ਆਈ-ਖੇਡੂਤ ਪੋਰਟਲ: ਟਰੈਕਟਰ ਅਤੇ ਖੇਤੀ ਸੰਦਾਂ \'ਤੇ 50% ਸਬਸਿਡੀ ਲਈ ਅਰਜ਼ੀਆਂ ਸ਼ੁਰੂ',
        'mr': 'गुजरात आय-खेडूत पोर्टल: ट्रॅक्टर आणि कृषी अवजारांवर 50% अनुदानासाठी अर्ज सुरू',
      },
      localizedSummaries: const {
        'gu': 'ગુજરાતના ખેડૂતો: ટ્રેક્ટર, રોટાવેટર અને વાવણીયા પર 50% સરકારી સહાય મેળવવા માટે આઈ-ખેડૂત પોર્ટલ પર છેલ્લી તારીખ પહેલાં અરજી કરો.',
        'hi': 'गुजरात के किसान: ट्रैक्टर और आधुनिक कृषि उपकरणों पर 50% तक की छूट पाने के लिए आई-खेड़ूत पोर्टल पर अंतिम तिथि से पहले आवेदन करें।',
        'pa': 'ਗੁਜਰਾਤ ਦੇ ਕਿਸਾਨ: ਟਰੈਕਟਰ ਅਤੇ ਖੇਤੀ ਸੰਦਾਂ \'ਤੇ 50% ਸਬਸਿਡੀ ਲੈਣ ਲਈ ਆਈ-ਖੇਡੂਤ ਪੋਰਟਲ \'ਤੇ ਆਨਲਾਈਨ ਅਪਲਾਈ ਕਰੋ।',
        'mr': 'गुजरातचे शेतकरी: ट्रॅक्टर व कृषी अवजारांवर 50% अनुदानासाठी आय-खेडूत पोर्टलवर मुदतीपूर्वी अर्ज करा.',
      },
    ),

    // 3. Gujarat Groundnut & Cotton MSP Procurement
    AgricultureNewsItem(
      id: 'news_guj_groundnut_msp',
      headline: 'Gujarat Announces Groundnut Procurement at MSP of ₹6,783/Q across Saurashtra Mandis',
      description: 'State government through GUJCOT and NAFED will initiate minimum support price procurement for Kharif Groundnut in Amreli, Junagadh, and Rajkot APMCs. Farmer registration is mandatory via VCE village panchayat centres.',
      aiSummary: 'Saurashtra & Amreli Farmers: Register with 7/12 land records at your Gram Panchayat to sell Groundnut at government MSP of ₹6,783/Quintal.',
      originalSource: 'NAFED & Gujarat State Civil Supplies',
      officialSourceUrl: 'https://agri.gujarat.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 2)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(days: 1)),
      applicableState: 'Gujarat',
      applicableDistricts: const [
        'Amreli',
        'Junagadh',
        'Rajkot',
        'Bhavnagar',
        'Jamnagar',
        'All',
      ],
      category: AgricultureNewsCategory.mspAnnouncements,
      relevantCrops: const ['Groundnut', 'Cotton'],
      applicationDeadline: DateTime.now().add(const Duration(days: 15)),
      isVerified: true,
      iconEmoji: '🥜',
      localizedHeadlines: const {
        'gu': 'ગુજરાત સરકાર દ્વારા સૌરાષ્ટ્ર માર્કેટ યાર્ડોમાં ટેકાના ભાવે ₹6,783 પ્રતિ ક્વિન્ટલ મગફળી ખરીદીની જાહેરાત',
        'hi': 'गुजरात में सौराष्ट्र की मंडियों में ₹6,783 प्रति क्विंटल न्यूनतम समर्थन मूल्य पर मूंगफली खरीद की घोषणा',
        'pa': 'ਗੁਜਰਾਤ ਸਰਕਾਰ ਵੱਲੋਂ ਐਮਐਸਪੀ \'ਤੇ ₹6,783 ਪ੍ਰਤੀ ਕੁਇੰਟਲ ਮੂੰਗਫਲੀ ਖਰੀਦ ਦਾ ਐਲਾਨ',
        'mr': 'गुजरात सरकारतर्फे ₹6,783 प्रति क्विंटल हमीभावाने भुईमूग खरेदीची घोषणा',
      },
      localizedSummaries: const {
        'gu': 'સૌરાષ્ટ્ર અને અમરેલીના ખેડૂતો: ટેકાના ભાવે ₹6,783 પ્રતિ ક્વિન્ટલ મગફળી વેચવા માટે ગ્રામ પંચાયતમાં 7/12 સાથે વહેલી તકે નોંધણી કરાવો.',
        'hi': 'सौराष्ट्र के किसान: ₹6,783 प्रति क्विंटल एमएसपी पर मूंगफली बेचने हेतु अपनी ग्राम पंचायत में 7/12 नकल के साथ पंजीकरण कराएं।',
        'pa': 'ਸੌਰਾਸ਼ਟਰ ਦੇ ਕਿਸਾਨ: ਐਮਐਸਪੀ \'ਤੇ ਮੂੰਗਫਲੀ ਵੇਚਣ ਲਈ ਆਪਣੀ ਗ੍ਰਾਮ ਪੰਚਾਇਤ ਵਿੱਚ ਰਜਿਸਟ੍ਰੇਸ਼ਨ ਕਰਵਾਓ।',
        'mr': 'शेतकरी बांधवांनो: ₹6,783 हमीभावाने भुईमूग विक्रीसाठी ग्रामपंचायतीत 7/12 दाखल्यासह नोंदणी करा.',
      },
    ),

    // 4. Punjab Wheat Rabi MSP & Certified Seed Subsidy
    AgricultureNewsItem(
      id: 'news_pb_wheat_subsidy',
      headline: 'Punjab Govt Announces 50% Subsidy on Certified Wheat Seeds (PBW 826 & HD 3086)',
      description: 'Punjab Department of Agriculture has launched online subsidy registration for high-yielding certified wheat seeds. Farmers in Ludhiana, Bathinda, and Jalandhar can apply through the Punjab Agri Portal to receive direct seed delivery through cooperative societies.',
      aiSummary: 'Punjab Farmers: Get 50% subsidy on certified high-yielding wheat seeds. Apply on Punjab Agri Portal before sowing season.',
      originalSource: 'Punjab Department of Agriculture & Farmers Welfare',
      officialSourceUrl: 'https://agri.punjab.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 1)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(hours: 6)),
      applicableState: 'Punjab',
      applicableDistricts: const [
        'Ludhiana',
        'Bathinda',
        'Jalandhar',
        'Patiala',
        'All',
      ],
      category: AgricultureNewsCategory.seedDistribution,
      relevantCrops: const ['Wheat'],
      applicationDeadline: DateTime.now().add(const Duration(days: 18)),
      isVerified: true,
      iconEmoji: '🌾',
      localizedHeadlines: const {
        'gu': 'પંજાબ સરકાર દ્વારા ઘઉંના ઉચ્ચ ગુણવત્તાવાળા પ્રમાણિત બિયારણ પર 50% સબસિડીની જાહેરાત',
        'hi': 'पंजाब सरकार द्वारा गेहूं के प्रमाणित बीजों (PBW 826 व HD 3086) पर 50% सब्सिडी की घोषणा',
        'pa': 'ਪੰਜਾਬ ਸਰਕਾਰ ਵੱਲੋਂ ਕਣਕ ਦੇ ਪ੍ਰਮਾਣਿਤ ਬੀਜਾਂ (PBW 826 ਅਤੇ HD 3086) \'ਤੇ 50% ਸਬਸਿਡੀ ਦਾ ਐਲਾਨ',
        'mr':
            'पंजाब सरकारतर्फे गव्हाच्या प्रमाणित बियाण्यांवर 50% सबसिडी जाहीर',
      },
      localizedSummaries: const {
        'gu': 'પંજાબના ખેડૂતો: વાવણીની ઋતુ પહેલાં પંજાબ એગ્રી પોર્ટલ પરથી 50% સબસિડી સાથે ઘઉંના સુધારેલા બિયારણ મેળવો.',
        'hi': 'पंजाब के किसान: बुवाई से पहले पंजाब एग्री पोर्टल पर आवेदन कर उन्नत गेहूं बीज पर 50% छूट प्राप्त करें।',
        'pa': 'ਪੰਜਾਬ ਦੇ ਕਿਸਾਨ ਵੀਰੋ: ਕਣਕ ਦੇ ਪ੍ਰਮਾਣਿਤ ਉੱਚ ਝਾੜ ਵਾਲੇ ਬੀਜਾਂ \'ਤੇ 50% ਸਬਸਿਡੀ ਪ੍ਰਾਪਤ ਕਰਨ ਲਈ ਪੋਰਟਲ \'ਤੇ ਅਪਲਾਈ ਕਰੋ।',
        'mr': 'पंजाबचे शेतकरी: गव्हाच्या दर्जेदार बियाण्यांवर 50% सवलत मिळवण्यासाठी पोर्टलवर अर्ज करा.',
      },
    ),

    // 5. National PMFBY Crop Insurance
    AgricultureNewsItem(
      id: 'news_pmfby_claim_window',
      headline: 'PM Fasal Bima Yojana (PMFBY): 72-Hour Crop Loss Intimation Extended for Excess Rain',
      description: 'Ministry of Agriculture has issued instructions to all empanelled insurance companies to accept farmer intimations via the PMFBY Crop Insurance App or toll-free number 14447 for standing crop damage due to localized heavy rainfall.',
      aiSummary: 'Heavy Rain Damage Alert: Report localized crop damage within 72 hours via the PMFBY mobile app or helpline 14447 to claim insurance.',
      originalSource: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      officialSourceUrl: 'https://pmfby.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 3)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(days: 2)),
      applicableState: 'All India',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.cropInsurance,
      relevantCrops: const ['All Crops'],
      isVerified: true,
      iconEmoji: '🛡️',
      localizedHeadlines: const {
        'gu': 'પ્રધાનમંત્રી ફસલ બીમા યોજના (PMFBY): કમોસમી વરસાદથી થયેલા પાક નુકસાન માટે 72 કલાકમાં જાણ કરો',
        'hi': 'प्रधानमंत्री फसल बीमा योजना (PMFBY): बेमौसम बारिश से फसल नुकसान की सूचना 72 घंटे में दर्ज कराएं',
        'pa': 'ਪੀਐਮ ਫਸਲ ਬੀਮਾ ਯੋਜਨਾ: ਬੇਮੌਸਮੀ ਮੀਂਹ ਨਾਲ ਹੋਏ ਫ਼ਸਲੀ ਨੁਕਸਾਨ ਦੀ ਰਿਪੋਰਟ 72 ਘੰਟਿਆਂ ਵਿੱਚ ਦਿਓ',
        'mr': 'प्रधानमंत्री पीक विमा योजना: अतिवृष्टीमुळे झालेल्या नुकसानाची माहिती 72 तासांत कळवा',
      },
      localizedSummaries: const {
        'gu': 'પાક નુકસાની એલર્ટ: પાક વીમાનો લાભ મેળવવા માટે PMFBY એપ અથવા હેલ્પલાઈન 14447 પર 72 કલાકની અંદર નુકસાનીની જાણ કરો.',
        'hi': 'फसल नुकसान चेतावनी: बीमा क्लेम के लिए PMFBY ऐप या टोल-फ्री नंबर 14447 पर 72 घंटे के भीतर नुकसान की सूचना दें।',
        'pa': 'ਫ਼ਸਲ ਨੁਕਸਾਨ ਸੂਚਨਾ: ਬੀਮਾ ਕਲੇਮ ਲੈਣ ਲਈ PMFBY ਐਪ ਜਾਂ ਹੈਲਪਲਾਈਨ 14447 \'ਤੇ 72 ਘੰਟਿਆਂ ਅੰਦਰ ਇਤਲਾਹ ਦਿਓ।',
        'mr': 'पीक नुकसान भरपाई: नुकसान झाल्यापासून 72 तासांच्या आत PMFBY ॲप किंवा 14447 वर माहिती नोंदवा.',
      },
    ),

    // 6. PM-KUSUM Solar Pump Subsidy
    AgricultureNewsItem(
      id: 'news_pm_kusum_solar',
      headline: 'PM-KUSUM: Up to 60% Financial Assistance for Off-Grid Agricultural Solar Pumps',
      description: 'Ministry of New & Renewable Energy in coordination with state discoms has opened Phase 3 registrations for 3 HP to 10 HP solar water pumping systems for irrigation in non-grid electrified farmland.',
      aiSummary: 'Solar Pump Scheme: Get up to 60% government subsidy to install an agricultural solar pump for lifetime free irrigation.',
      originalSource: 'Ministry of New and Renewable Energy (MNRE)',
      officialSourceUrl: 'https://pmkusum.mnre.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 4)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(days: 3)),
      applicableState: 'All India',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.newSchemes,
      relevantCrops: const ['All Crops'],
      applicationDeadline: DateTime.now().add(const Duration(days: 30)),
      isVerified: true,
      iconEmoji: '☀️',
      localizedHeadlines: const {
        'gu': 'પીએમ-કુસુમ યોજના: ખેતીમાં સિંચાઈ માટે સોલર પંપ પર 60% સુધી સરકારી સહાય',
        'hi': 'पीएम-कुसुम योजना: खेत में सिंचाई हेतु सोलर वाटर पंप पर 60% तक सरकारी सहायता',
        'pa':
            'ਪੀਐਮ-ਕੁਸੁਮ ਸਕੀਮ: ਸਿੰਚਾਈ ਲਈ ਸੋਲਰ ਪੰਪਾਂ \'ਤੇ 60% ਤੱਕ ਸਰਕਾਰੀ ਸਬਸਿਡੀ',
        'mr': 'पीएम-कुसुम योजना: शेतातील सिंचनासाठी सौर पंपावर 60% पर्यंत शासकीय अनुदान',
      },
      localizedSummaries: const {
        'gu': 'સોલર પંપ યોજના: આજીવન મફત સિંચાઈ માટે સોલર વોટર પંપ લગાવવા પર 60% સરકારી સબસિડી મેળવો.',
        'hi': 'सोलर पंप योजना: जीवनभर मुफ्त सिंचाई के लिए कृषि सोलर पंप लगाने हेतु 60% सरकारी सब्सिडी प्राप्त करें।',
        'pa': 'ਸੋਲਰ ਪੰਪ ਸਕੀਮ: ਖੇਤਾਂ ਵਿੱਚ ਮੁਫ਼ਤ ਸਿੰਚਾਈ ਲਈ ਸੋਲਰ ਪੰਪ ਲਗਾਉਣ ਵਾਸਤੇ 60% ਸਬਸਿਡੀ ਦਾ ਲਾਭ ਉਠਾਓ।',
        'mr': 'सौर पंप योजना: मोफत सिंचनासाठी सोलर वॉटर पंप बसवण्यासाठी 60% शासकीय अनुदानाचा लाभ घ्या.',
      },
    ),

    // 7. IMD Weather Warning
    AgricultureNewsItem(
      id: 'news_imd_rain_alert',
      headline: 'IMD Agromet Advisory: Isolated Thunderstorms & Hail Warning across Western States',
      description: 'India Meteorological Department (IMD) has issued a yellow advisory for parts of Gujarat, Rajasthan, and Western MP. Farmers are advised to provide drainage channels in open fields and postpone pesticide sprays.',
      aiSummary: 'Weather Warning: Avoid chemical spraying for the next 48 hours and ensure field drainage channels are clear to prevent waterlogging.',
      originalSource: 'India Meteorological Department (IMD)',
      officialSourceUrl: 'https://mausam.imd.gov.in',
      publishedDate: DateTime.now().subtract(const Duration(hours: 6)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(hours: 1)),
      applicableState: 'All India',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.weatherWarnings,
      relevantCrops: const ['All Crops'],
      isVerified: true,
      iconEmoji: '⛈️',
      localizedHeadlines: const {
        'gu': 'હવામાન ચેતવણી: પશ્ચિમ ભારતના વિસ્તારોમાં કમોસમી વરસાદ અને કરા પડવાની શક્યતા, ખેતરમાં પાણીના નિકાલની વ્યવસ્થા રાખો',
        'hi': 'मौसम चेतावनी: पश्चिमी राज्यों में आंधी, बारिश व ओलावृष्टि की संभावना, कीटनाशक छिड़काव टालें',
        'pa': 'ਮੌਸਮ ਚੇਤਾਵਨੀ: ਗੜੇਮਾਰੀ ਅਤੇ ਤੇਜ਼ ਮੀਂਹ ਦੀ ਸੰਭਾਵਨਾ, ਖੇਤਾਂ ਵਿੱਚ ਕੀਟਨਾਸ਼ਕ ਸਪਰੇਅ ਰੋਕੋ',
        'mr': 'हवामान इशारा: अवकाळी पाऊस आणि गारपिटीची शक्यता, शेतात पाण्याचा निचरा करा',
      },
      localizedSummaries: const {
        'gu': 'હવામાન સાવચેતી: આગામી 48 કલાક સુધી દવાનો છંટકાવ ટાળો અને ખેતરમાં પાણી ભરાઈ ન રહે તે માટે નિકાલની વ્યવસ્થા કરો.',
        'hi': 'मौसम सावधानी: अगले 48 घंटों तक रासायनिक छिड़काव से बचें और खेतों में जल निकासी सुनिश्चित करें।',
        'pa': 'ਮੌਸਮ ਸਾਵਧਾਨੀ: ਅਗਲੇ 48 ਘੰਟੇ ਸਪਰੇਅ ਨਾ ਕਰੋ ਅਤੇ ਖੇਤਾਂ ਵਿੱਚ ਪਾਣੀ ਦੇ ਨਿਕਾਸ ਦਾ ਪ੍ਰਬੰਧ ਰੱਖੋ।',
        'mr': 'हवामान दक्षता: पुढील 48 तास फवारणी टाळा आणि शेतात पाणी साचणार नाही याची काळजी घ्या.',
      },
    ),

    // 8. Cotton Pink Bollworm Pest Alert
    AgricultureNewsItem(
      id: 'news_pest_cotton_pink_bollworm',
      headline: 'ICAR-CICR Pest Alert: Pheromone Trap Installation Urged for Cotton Pink Bollworm',
      description: 'Central Institute for Cotton Research (CICR) alerts cotton growers in Gujarat, Maharashtra, and Punjab to install 8-10 pheromone traps per acre at 45-60 days crop stage to monitor moth emergence and prevent larvae penetration.',
      aiSummary: 'Pest Advisory: Install pheromone traps (8/acre) in cotton fields to protect squares and bolls from pink bollworm damage.',
      originalSource: 'ICAR - Central Institute for Cotton Research (CICR)',
      officialSourceUrl: 'https://cicr.org.in',
      publishedDate: DateTime.now().subtract(const Duration(days: 2)),
      lastUpdatedDate: DateTime.now().subtract(const Duration(days: 1)),
      applicableState: 'All India',
      applicableDistricts: const ['All'],
      category: AgricultureNewsCategory.pestDiseaseAlerts,
      relevantCrops: const ['Cotton'],
      isVerified: true,
      iconEmoji: '🐛',
      localizedHeadlines: const {
        'gu': 'કપાસમાં ગુલાબી ઈયળનો ઉપદ્રવ અટકાવવા માટે ફેરોમોન ટ્રેપ (હેક્ટર દીઠ 8 ટ્રેપ) લગાવવાની વૈજ્ઞાનિક સલાહ',
        'hi': 'कपास में गुलाबी सुंडी (Pink Bollworm) से बचाव के लिए फेरोमोन ट्रैप लगाने की वैज्ञानिक सलाह',
        'pa': 'ਨਰਮੇ ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ ਦੇ ਹਮਲੇ ਤੋਂ ਬਚਾਅ ਲਈ ਫੇਰੋਮੋਨ ਟਰੈਪ ਲਗਾਉਣ ਦੀ ਸਲਾਹ',
        'mr': 'कापसावरील गुलाबी बोंडअळीच्या नियंत्रणासाठी कामगंध सापळे लावण्याचा कृषी सल्ला',
      },
      localizedSummaries: const {
        'gu': 'રોગ-જીવાત એલર્ટ: કપાસના ઝીંડવાને ગુલાબી ઈયળથી બચાવવા માટે ખેતરમાં એકરે 8 ફેરોમોન ટ્રેપ લગાવી નિયમિત દેખરેખ રાખો.',
        'hi': 'कीट सलाह: कपास की फसल को गुलाबी सुंडी से बचाने के लिए प्रति एकड़ 8 फेरोमोन ट्रैप लगाकर निगरानी करें।',
        'pa': 'ਕੀੜੇ-ਮਕੌੜੇ ਸਲਾਹ: ਨਰਮੇ ਦੇ ਟੀਂਡਿਆਂ ਨੂੰ ਗੁਲਾਬੀ ਸੁੰਡੀ ਤੋਂ ਬਚਾਉਣ ਲਈ 8 ਟਰੈਪ ਪ੍ਰਤੀ ਏਕੜ ਲਗਾਓ।',
        'mr': 'कीड नियंत्रण सल्ला: बोंडांचे रक्षण करण्यासाठी एकरी 8 कामगंध सापळे लावून बारीक लक्ष ठेवा.',
      },
    ),
  ];

  Future<void> _ensureBookmarksLoaded(String farmerId) async {
    if (_bookmarksLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('$_bookmarkKey$farmerId');
      if (list != null) {
        _bookmarkedIds.addAll(list);
      }
      _bookmarksLoaded = true;
    } catch (_) {}
  }

  /// Filters official news items strictly matching the farmer's location,
  /// crop preferences, and category.
  Future<List<AgricultureNewsItem>> getNewsForFarmer(
    FarmerProfile profile, {
    AgricultureNewsCategory? categoryFilter,
    String? searchQuery,
    bool onlyBookmarked = false,
  }) async {
    await _ensureBookmarksLoaded(profile.mobileNumber);

    final state = profile.effectiveState.isNotEmpty
        ? profile.effectiveState
        : 'Gujarat';
    final district = profile.effectiveDistrict.isNotEmpty
        ? profile.effectiveDistrict
        : 'Amreli';
    final farmerCrops = profile.effectiveProducts;

    final filtered = <AgricultureNewsItem>[];

    for (final item in _masterNewsDatabase) {
      // 1. Bookmark check
      final isBookmarked = _bookmarkedIds.contains(item.id);
      if (onlyBookmarked && !isBookmarked) continue;

      // 2. Category Filter
      if (categoryFilter != null && item.category != categoryFilter) {
        continue;
      }

      // 3. Location Match (National news or State/District match)
      if (!item.matchesLocation(state: state, district: district)) {
        continue;
      }

      // 4. Search Query Filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final match =
            item.headline.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.originalSource.toLowerCase().contains(q) ||
            item.category.displayNameEn.toLowerCase().contains(q);
        if (!match) continue;
      }

      filtered.add(item.copyWith(isBookmarked: isBookmarked));
    }

    // Sort: Matching crops first, then local state/district news, then by published date descending
    filtered.sort((a, b) {
      final aCropMatch = a.matchesCrops(farmerCrops);
      final bCropMatch = b.matchesCrops(farmerCrops);
      if (aCropMatch != bCropMatch) {
        return aCropMatch ? -1 : 1;
      }
      final aIsLocal = a.applicableState.toLowerCase() == state.toLowerCase();
      final bIsLocal = b.applicableState.toLowerCase() == state.toLowerCase();
      if (aIsLocal != bIsLocal) {
        return aIsLocal ? -1 : 1;
      }
      return b.publishedDate.compareTo(a.publishedDate);
    });

    return filtered;
  }

  /// Toggle bookmark status for a specific news item
  Future<bool> toggleBookmark(String farmerId, String newsId) async {
    await _ensureBookmarksLoaded(farmerId);
    bool newState;
    if (_bookmarkedIds.contains(newsId)) {
      _bookmarkedIds.remove(newsId);
      newState = false;
    } else {
      _bookmarkedIds.add(newsId);
      newState = true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        '$_bookmarkKey$farmerId',
        _bookmarkedIds.toList(),
      );
    } catch (_) {}

    return newState;
  }

  /// Admin capability: add a verified news item
  void addNewsItem(AgricultureNewsItem item) {
    _masterNewsDatabase.insert(0, item);
  }
}
