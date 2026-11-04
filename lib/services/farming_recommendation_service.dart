import '../localization/farm_products_data.dart';
import '../models/farm_product.dart';

/// Service delivering localized agricultural advice, state-specific crop rotations,
/// local Mandi hubs, and weather-aware farming recommendations.
class FarmingRecommendationService {
  FarmingRecommendationService._internal();
  static final FarmingRecommendationService instance =
      FarmingRecommendationService._internal();

  /// Returns recommended crops tailored specifically to the farmer's state.
  List<FarmProduct> getRecommendedCropsForState(String stateName) {
    final stateKey = _normalizeState(stateName);
    switch (stateKey) {
      case 'gujarat':
        return [
          FarmProductsData.findById('cotton')!,
          FarmProductsData.findById('groundnut')!,
          FarmProductsData.findById('wheat')!,
          FarmProductsData.findById('cumin')!,
          FarmProductsData.findById('onion')!,
          FarmProductsData.findById('castor')!,
        ];
      case 'punjab':
        return [
          FarmProductsData.findById('wheat')!,
          FarmProductsData.findById('paddy')!,
          FarmProductsData.findById('mustard')!,
          FarmProductsData.findById('maize')!,
          FarmProductsData.findById('cotton')!,
          FarmProductsData.findById('sugarcane')!,
        ];
      case 'kerala':
        return [
          FarmProductsData.findById('paddy')!,
          FarmProductsData.findById('coconut')!,
          FarmProductsData.findById('banana')!,
          FarmProductsData.findById('ginger')!,
          FarmProductsData.findById('tomato')!,
        ];
      case 'rajasthan':
        return [
          FarmProductsData.findById('mustard')!,
          FarmProductsData.findById('bajra')!,
          FarmProductsData.findById('gram')!,
          FarmProductsData.findById('wheat')!,
          FarmProductsData.findById('cumin')!,
          FarmProductsData.findById('groundnut')!,
        ];
      case 'maharashtra':
        return [
          FarmProductsData.findById('soybean')!,
          FarmProductsData.findById('cotton')!,
          FarmProductsData.findById('onion')!,
          FarmProductsData.findById('sugarcane')!,
          FarmProductsData.findById('pomegranate')!,
          FarmProductsData.findById('banana')!,
        ];
      case 'uttar_pradesh':
        return [
          FarmProductsData.findById('wheat')!,
          FarmProductsData.findById('sugarcane')!,
          FarmProductsData.findById('potato')!,
          FarmProductsData.findById('paddy')!,
          FarmProductsData.findById('mustard')!,
          FarmProductsData.findById('mango')!,
        ];
      default:
        return FarmProductsData.popularProducts;
    }
  }

  /// Returns 3-4 tailored farming advisories based on selected state, district, and chosen crops.
  List<String> getPersonalizedAdvisories({
    required String stateName,
    required String districtName,
    required List<String> selectedProducts,
    required String langCode,
  }) {
    final stateKey = _normalizeState(stateName);

    switch (stateKey) {
      case 'gujarat':
        return _getGujaratAdvisories(langCode, selectedProducts, districtName);
      case 'punjab':
        return _getPunjabAdvisories(langCode, selectedProducts, districtName);
      case 'kerala':
        return _getKeralaAdvisories(langCode, selectedProducts, districtName);
      case 'rajasthan':
        return _getRajasthanAdvisories(
          langCode,
          selectedProducts,
          districtName,
        );
      case 'maharashtra':
        return _getMaharashtraAdvisories(
          langCode,
          selectedProducts,
          districtName,
        );
      case 'uttar_pradesh':
        return _getUPAdvisories(langCode, selectedProducts, districtName);
      default:
        return _getDefaultAdvisories(langCode, selectedProducts, stateName);
    }
  }

  /// Current agricultural season in India (Kharif, Rabi, Zaid)
  String getCurrentSeason(String langCode) {
    final now = DateTime.now();
    final month = now.month;

    // Kharif: June - October (Monsoon)
    // Rabi: November - March (Winter)
    // Zaid: April - May (Summer)
    String seasonKey;
    if (month >= 6 && month <= 10) {
      seasonKey = 'Kharif';
    } else if (month >= 11 || month <= 3) {
      seasonKey = 'Rabi';
    } else {
      seasonKey = 'Zaid';
    }

    switch (langCode.toLowerCase()) {
      case 'gu':
        return seasonKey == 'Kharif'
            ? 'ચોમાસુ (ખરીફ)'
            : (seasonKey == 'Rabi' ? 'શિયાળુ (રવિ)' : 'ઉનાળુ (જાયદ)');
      case 'hi':
        return seasonKey == 'Kharif'
            ? 'खरीफ (Kharif)'
            : (seasonKey == 'Rabi' ? 'रबी (Rabi)' : 'जायद (Zaid)');
      case 'pa':
        return seasonKey == 'Kharif'
            ? 'ਸਾਉਣੀ / ਖ਼ਰੀਫ਼'
            : (seasonKey == 'Rabi' ? 'ਹਾੜ੍ਹੀ / ਰਬੀ' : 'ਜ਼ਾਇਦ');
      default:
        return '$seasonKey Season';
    }
  }

  // --- State-Specific Advisory Generators ---

  List<String> _getGujaratAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'gu') {
      return [
        'ગુજરાત ગ્રીન રિવોલ્યુશન (GGRC) હેઠળ ડ્રિપ ઇરિગેશન સબસિડી માટે e-Dharati પોર્ટલ પર અરજી કરો.',
        'કપાસ અને મગફળીમાં ગુલાબી ઈયળ તથા થ્રીપ્સના નિયંત્રણ માટે ફેરોમોન ટ્રેપ લગાવો.',
        '$district ના ખેડૂતો માટે નર્મદા અને કેનાલ પિયતનું પાણી સમયસર મેળવવા કિસાન હેલ્પલાઇન 1800-180-1551 પર સંપર્ક કરો.',
      ];
    } else if (langCode == 'hi') {
      return [
        'गुजरात जीजीआरसी योजना के तहत सूक्ष्म सिंचाई (ड्रिप) पर 70% तक की सब्सिडी उपलब्ध है।',
        'कपास और मूंगफली में कीट नियंत्रण हेतु जैविक नीम तेल और फेरोमोन ट्रैप का उपयोग करें।',
        '$district के एपीएमसी (APMC) यार्ड में आज के सटीक न्यूनतम समर्थन मूल्य चेक करें।',
      ];
    } else {
      return [
        'Apply for drip & sprinkler irrigation subsidy under GGRC (Gujarat Green Revolution Co.).',
        'Monitor cotton and groundnut crops for pink bollworm and whitefly using sticky traps.',
        'Connect with $district APMC mandi yard for daily live commodity trading rates.',
      ];
    }
  }

  List<String> _getPunjabAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'pa') {
      return [
        'ਪੰਜਾਬ ਐਗਰੀਕਲਚਰਲ ਯੂਨੀਵਰਸਿਟੀ (PAU) ਲੁਧਿਆਣਾ ਵੱਲੋਂ ਕਣਕ ਅਤੇ ਝੋਨੇ ਦੀ ਬਿਜਾਈ ਲਈ ਨਵੀਆਂ ਪ੍ਰਮਾਣਿਤ ਕਿਸਮਾਂ ਅਪਣਾਓ।',
        'ਪਰਾਲੀ ਪ੍ਰਬੰਧਨ (Happy Seeder / Super Seeder) ਲਈ ਖੇਤੀਬਾੜੀ ਵਿਭਾਗ ਪੰਜਾਬ ਵੱਲੋਂ 50% ਸਬਸਿਡੀ ਉਪਲਬਧ ਹੈ।',
        '$district ਜ਼ਿਲ੍ਹੇ ਦੀਆਂ ਨਹਿਰੀ ਪਾਣੀ ਬਾਰੀਆਂ ਅਤੇ ਟਿਊਬਵੈੱਲ ਬਿਜਲੀ ਸਪਲਾਈ ਸ਼ਡਿਊਲ ਦੀ ਜਾਂਚ ਕਰੋ।',
      ];
    } else if (langCode == 'hi') {
      return [
        'पीएयू लुधियाना द्वारा अनुशंसित उन्नत गेहूं और धान की उन्नत किस्मों का ही चयन करें।',
        'पराली प्रबंधन हेतु हैप्पी सीडर और सुपर सीडर पर पंजाब सरकार की सब्सिडी का लाभ उठाएं।',
        '$district जिले की स्थानीय अनाज मंडी में अपनी फसल के ताजा भाव जानें।',
      ];
    } else {
      return [
        'Adopt certified wheat & basmati seeds approved by Punjab Agricultural University (PAU).',
        'Avail 50-80% subsidy on CRM machinery (Happy Seeder, Super SMS) for crop residue management.',
        'Check $district canal water rotation schedules and local grain market auction prices.',
      ];
    }
  }

  List<String> _getKeralaAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'ml') {
      return [
        'കേരളത്തിലെ നെല്ല് പാടങ്ങളിൽ മണ്ണിലെ അമ്ലത്വം കുറയ്ക്കാൻ ഡോളോമൈറ്റ് / കുമ്മായം പ്രയോഗിക്കുക.',
        'കാലവർഷക്കെടുതി തടയാൻ തോടുകളിലും വാഴത്തോട്ടങ്ങളിലും നീർവാർച്ചാ സൗകര്യം ഉറപ്പാക്കുക.',
        '$district കൃഷിഭവനുമായി ബന്ധപ്പെട്ട് പച്ചക്കറി കൃഷി സബ്സിഡികളും വിത്തുകളും കൈപ്പറ്റുക.',
      ];
    } else if (langCode == 'hi') {
      return [
        'केरल के तटीय एवं उच्च भूमि क्षेत्रों में मिट्टी की अम्लता कम करने के लिए चूना/डोलोमाइट डालें।',
        'धान और केले के खेतों में जल निकासी की पुख्ता व्यवस्था रखें ताकि कवक रोग न पनपे।',
        '$district के स्थानीय कृषि भवन से जैविक खाद एवं बीज सब्सिडी की जानकारी लें।',
      ];
    } else {
      return [
        'Apply agricultural lime or dolomite to neutralize high soil acidity in Kerala farmlands.',
        'Ensure proper trench drainage across paddy fields and banana plantations to prevent root rot.',
        'Contact your local $district Krishi Bhavan for state vegetable mission subsidies.',
      ];
    }
  }

  List<String> _getRajasthanAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'hi') {
      return [
        'राजस्थान में शुष्क खेती हेतु कम पानी वाली बाजरा, मूंग एवं जीरा किस्मों की बुवाई करें।',
        'खेत तलाई (फार्म पॉन्ड) एवं सोलर पंप स्थापना पर राजस्थान सरकार द्वारा 70% अनुदान उपलब्ध है।',
        'सर्दियों में पाले से सरसों व चने की फसल को बचाने हेतु शाम के समय हल्की सिंचाई करें।',
      ];
    } else {
      return [
        'Opt for drought-tolerant Pearl Millet (Bajra), Mustard, and Cumin seeds for arid Rajasthan soils.',
        'Apply for solar pump sets and farm pond construction subsidies under RajKisan Sathi.',
        'Protect mustard and gram crops from cold wave and frost damage with light irrigation.',
      ];
    }
  }

  List<String> _getMaharashtraAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'mr') {
      return [
        'कांदा साठवणुकीसाठी चाळ उभारणी योजना आणि ठिबक सिंचनावर महाडीबीटी (MahaDBT) वरून अनुदान मिळवा.',
        'सोयाबीन व कापूस पिकावर रसशोषक किडींच्या नियंत्रणासाठी निंबोळी अर्काची फवारणी करा.',
        '$district जिल्ह्यातील कृषी उत्पन्न बाजार समिती (APMC) चे दैनंदिन आवक आणि भाव तपासा.',
      ];
    } else {
      return [
        'Avail MahaDBT subsidies for drip fertigation in sugarcane, cotton, and onion storage sheds.',
        'Spray neem seed kernel extract (NSKE 5%) for sucking pest control in soybean & cotton.',
        'Check $district APMC wholesale auction rates for onions, cotton, and oilseeds.',
      ];
    }
  }

  List<String> _getUPAdvisories(
    String langCode,
    List<String> products,
    String district,
  ) {
    if (langCode == 'hi') {
      return [
        'गन्ना भुगतान और पर्ची कैलेंडर हेतु यूपी गन्ना किसान ई-गन्ना (e-Ganna) ऐप से जुड़े रहें।',
        'आलू की फसल में झुलसा रोग (Late Blight) की रोकथाम के लिए मैंकोजेब का सुरक्षात्मक छिड़काव करें।',
        '$district में गेहूं की समय पर बुवाई के लिए जीरो टिलेज तकनीक का उपयोग कर लागत घटाएं।',
      ];
    } else {
      return [
        'Track UP sugarcane procurement and slip calendar via the official e-Ganna portal.',
        'Apply prophylactic Mancozeb spray to protect potato crops against late blight in winters.',
        'Adopt zero-tillage sowing for rabi wheat in $district to save fuel and tractor costs.',
      ];
    }
  }

  List<String> _getDefaultAdvisories(
    String langCode,
    List<String> products,
    String state,
  ) {
    return [
      'Get your soil health card tested before the sowing season to optimize fertilizer doses.',
      'Check PM-Kisan Samman Nidhi quarterly installment status and e-KYC compliance.',
      'Monitor daily weather alerts and mandi market prices for maximum harvest yield.',
    ];
  }

  String _normalizeState(String s) {
    final lower = s.trim().toLowerCase();
    if (lower.contains('gujarat') ||
        lower.contains('ગુજરાત') ||
        lower.contains('गुजरात')) {
      return 'gujarat';
    }
    if (lower.contains('punjab') ||
        lower.contains('ਪੰਜਾਬ') ||
        lower.contains('पंजाब')) {
      return 'punjab';
    }
    if (lower.contains('kerala') ||
        lower.contains('കേരളം') ||
        lower.contains('केरल')) {
      return 'kerala';
    }
    if (lower.contains('rajasthan') ||
        lower.contains('રાજસ્થાન') ||
        lower.contains('राजस्थान')) {
      return 'rajasthan';
    }
    if (lower.contains('maharashtra') ||
        lower.contains('મહારાષ્ટ્ર') ||
        lower.contains('महाराष्ट्र')) {
      return 'maharashtra';
    }
    if (lower.contains('uttar pradesh') ||
        lower.contains('ઉત્તર પ્રદેશ') ||
        lower.contains('उत्तर प्रदेश') ||
        lower.contains('up')) {
      return 'uttar_pradesh';
    }
    return 'default';
  }
}
