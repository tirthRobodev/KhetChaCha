/// Comprehensive localized location data for Indian States and Districts.
/// Supports Gujarati, Hindi, Marathi, and English with latitude/longitude coordinates
/// for live agricultural weather forecasting.
class IndianState {
  final String key;
  final String englishName;
  final String gujaratiName;
  final String hindiName;
  final double latitude;
  final double longitude;

  const IndianState({
    required this.key,
    required this.englishName,
    required this.gujaratiName,
    required this.hindiName,
    required this.latitude,
    required this.longitude,
  });

  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return '$gujaratiName ($englishName)';
      case 'hi':
        return '$hindiName ($englishName)';
      default:
        return englishName;
    }
  }

  String getPureNativeName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return gujaratiName;
      case 'hi':
        return hindiName;
      default:
        return englishName;
    }
  }
}

class IndianDistrict {
  final String key;
  final String stateKey;
  final String englishName;
  final String gujaratiName;
  final String hindiName;
  final double latitude;
  final double longitude;

  const IndianDistrict({
    required this.key,
    required this.stateKey,
    required this.englishName,
    required this.gujaratiName,
    required this.hindiName,
    required this.latitude,
    required this.longitude,
  });

  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return '$gujaratiName ($englishName)';
      case 'hi':
        return '$hindiName ($englishName)';
      default:
        return englishName;
    }
  }

  String getPureNativeName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return gujaratiName;
      case 'hi':
        return hindiName;
      default:
        return englishName;
    }
  }
}

class LocationData {
  /// All 28 States & 8 UTs of India with coordinates & translations
  static const List<IndianState> allStates = [
    IndianState(
      key: 'Gujarat',
      englishName: 'Gujarat',
      gujaratiName: 'ગુજરાત',
      hindiName: 'गुजरात',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    IndianState(
      key: 'Maharashtra',
      englishName: 'Maharashtra',
      gujaratiName: 'મહારાષ્ટ્ર',
      hindiName: 'महाराष्ट्र',
      latitude: 19.0760,
      longitude: 72.8777,
    ),
    IndianState(
      key: 'Rajasthan',
      englishName: 'Rajasthan',
      gujaratiName: 'રાજસ્થાન',
      hindiName: 'राजस्थान',
      latitude: 26.9124,
      longitude: 75.7873,
    ),
    IndianState(
      key: 'Madhya Pradesh',
      englishName: 'Madhya Pradesh',
      gujaratiName: 'મધ્ય પ્રદેશ',
      hindiName: 'मध्य प्रदेश',
      latitude: 23.2599,
      longitude: 77.4126,
    ),
    IndianState(
      key: 'Punjab',
      englishName: 'Punjab',
      gujaratiName: 'પંજાબ',
      hindiName: 'पंजाब',
      latitude: 31.1471,
      longitude: 75.3412,
    ),
    IndianState(
      key: 'Haryana',
      englishName: 'Haryana',
      gujaratiName: 'હરિયાણા',
      hindiName: 'हरियाणा',
      latitude: 29.0588,
      longitude: 76.0856,
    ),
    IndianState(
      key: 'Uttar Pradesh',
      englishName: 'Uttar Pradesh',
      gujaratiName: 'ઉત્તર પ્રદેશ',
      hindiName: 'उत्तर प्रदेश',
      latitude: 26.8467,
      longitude: 80.9462,
    ),
    IndianState(
      key: 'Bihar',
      englishName: 'Bihar',
      gujaratiName: 'બિહાર',
      hindiName: 'बिहार',
      latitude: 25.0961,
      longitude: 85.3131,
    ),
    IndianState(
      key: 'Karnataka',
      englishName: 'Karnataka',
      gujaratiName: 'કર્ણાટક',
      hindiName: 'कर्नाटक',
      latitude: 12.9716,
      longitude: 77.5946,
    ),
    IndianState(
      key: 'Tamil Nadu',
      englishName: 'Tamil Nadu',
      gujaratiName: 'તમિલનાડુ',
      hindiName: 'तमिलनाडु',
      latitude: 13.0827,
      longitude: 80.2707,
    ),
    IndianState(
      key: 'Andhra Pradesh',
      englishName: 'Andhra Pradesh',
      gujaratiName: 'આંધ્ર પ્રદેશ',
      hindiName: 'आंध्र प्रदेश',
      latitude: 15.9129,
      longitude: 79.7400,
    ),
    IndianState(
      key: 'Telangana',
      englishName: 'Telangana',
      gujaratiName: 'તેલંગાણા',
      hindiName: 'तेलंगाना',
      latitude: 17.3850,
      longitude: 78.4867,
    ),
    IndianState(
      key: 'West Bengal',
      englishName: 'West Bengal',
      gujaratiName: 'પશ્ચિમ બંગાળ',
      hindiName: 'पश्चिम बंगाल',
      latitude: 22.5726,
      longitude: 88.3639,
    ),
    IndianState(
      key: 'Odisha',
      englishName: 'Odisha',
      gujaratiName: 'ઓડિશા',
      hindiName: 'ओडिशा',
      latitude: 20.9517,
      longitude: 85.0985,
    ),
    IndianState(
      key: 'Kerala',
      englishName: 'Kerala',
      gujaratiName: 'કેરળ',
      hindiName: 'केरल',
      latitude: 10.8505,
      longitude: 76.2711,
    ),
    IndianState(
      key: 'Assam',
      englishName: 'Assam',
      gujaratiName: 'આસામ',
      hindiName: 'असम',
      latitude: 26.2006,
      longitude: 92.9376,
    ),
    IndianState(
      key: 'Chhattisgarh',
      englishName: 'Chhattisgarh',
      gujaratiName: 'છત્તીસગઢ',
      hindiName: 'छत्तीसगढ़',
      latitude: 21.2787,
      longitude: 81.8661,
    ),
    IndianState(
      key: 'Jharkhand',
      englishName: 'Jharkhand',
      gujaratiName: 'ઝારખંડ',
      hindiName: 'झारखंड',
      latitude: 23.6102,
      longitude: 85.2799,
    ),
    IndianState(
      key: 'Uttarakhand',
      englishName: 'Uttarakhand',
      gujaratiName: 'ઉત્તરાખંડ',
      hindiName: 'उत्तराखंड',
      latitude: 30.0668,
      longitude: 79.0193,
    ),
    IndianState(
      key: 'Himachal Pradesh',
      englishName: 'Himachal Pradesh',
      gujaratiName: 'હિમાચલ પ્રદેશ',
      hindiName: 'हिमाचल प्रदेश',
      latitude: 31.1048,
      longitude: 77.1734,
    ),
    IndianState(
      key: 'Goa',
      englishName: 'Goa',
      gujaratiName: 'ગોવા',
      hindiName: 'गोवा',
      latitude: 15.2993,
      longitude: 74.1240,
    ),
    IndianState(
      key: 'Tripura',
      englishName: 'Tripura',
      gujaratiName: 'ત્રિપુરા',
      hindiName: 'त्रिपुरा',
      latitude: 23.9408,
      longitude: 91.9882,
    ),
    IndianState(
      key: 'Meghalaya',
      englishName: 'Meghalaya',
      gujaratiName: 'મેઘાલય',
      hindiName: 'मेघालय',
      latitude: 25.4670,
      longitude: 91.3662,
    ),
    IndianState(
      key: 'Manipur',
      englishName: 'Manipur',
      gujaratiName: 'મણિપુર',
      hindiName: 'मणिपुर',
      latitude: 24.6637,
      longitude: 93.9063,
    ),
    IndianState(
      key: 'Nagaland',
      englishName: 'Nagaland',
      gujaratiName: 'નાગાલેન્ડ',
      hindiName: 'नागालैंड',
      latitude: 26.1584,
      longitude: 94.5624,
    ),
    IndianState(
      key: 'Mizoram',
      englishName: 'Mizoram',
      gujaratiName: 'મિઝોરમ',
      hindiName: 'मिजोरम',
      latitude: 23.1645,
      longitude: 92.9376,
    ),
    IndianState(
      key: 'Arunachal Pradesh',
      englishName: 'Arunachal Pradesh',
      gujaratiName: 'અરુણાચલ પ્રદેશ',
      hindiName: 'अरुणाचल प्रदेश',
      latitude: 28.2180,
      longitude: 94.7278,
    ),
    IndianState(
      key: 'Sikkim',
      englishName: 'Sikkim',
      gujaratiName: 'સિક્કિમ',
      hindiName: 'सिक्किम',
      latitude: 27.5330,
      longitude: 88.5122,
    ),
    IndianState(
      key: 'Delhi (NCT)',
      englishName: 'Delhi (NCT)',
      gujaratiName: 'દિલ્હી',
      hindiName: 'दिल्ली',
      latitude: 28.7041,
      longitude: 77.1025,
    ),
    IndianState(
      key: 'Jammu and Kashmir',
      englishName: 'Jammu and Kashmir',
      gujaratiName: 'જમ્મુ અને કાશ્મીર',
      hindiName: 'जम्मू और कश्मीर',
      latitude: 33.7782,
      longitude: 76.5762,
    ),
    IndianState(
      key: 'Ladakh',
      englishName: 'Ladakh',
      gujaratiName: 'લદ્દાખ',
      hindiName: 'लद्दाख',
      latitude: 34.1526,
      longitude: 77.5771,
    ),
    IndianState(
      key: 'Chandigarh',
      englishName: 'Chandigarh',
      gujaratiName: 'ચંદીગઢ',
      hindiName: 'चंडीगढ़',
      latitude: 30.7333,
      longitude: 76.7794,
    ),
    IndianState(
      key: 'Puducherry',
      englishName: 'Puducherry',
      gujaratiName: 'પુડુચેરી',
      hindiName: 'पुडुचेरी',
      latitude: 11.9416,
      longitude: 79.8083,
    ),
    IndianState(
      key: 'Dadra and Nagar Haveli and Daman and Diu',
      englishName: 'Dadra and Nagar Haveli and Daman and Diu',
      gujaratiName: 'દાદરા અને નગર હવેલી અને દમણ અને દીવ',
      hindiName: 'दादरा और नगर हवेली और दमन और दीव',
      latitude: 20.3974,
      longitude: 72.8328,
    ),
    IndianState(
      key: 'Andaman and Nicobar Islands',
      englishName: 'Andaman and Nicobar Islands',
      gujaratiName: 'અંદમાન અને નિકોબાર ટાપુઓ',
      hindiName: 'अंडमान और निकोबार द्वीप समूह',
      latitude: 11.7401,
      longitude: 92.6586,
    ),
    IndianState(
      key: 'Lakshadweep',
      englishName: 'Lakshadweep',
      gujaratiName: 'લક્ષદ્વીપ',
      hindiName: 'लक्षद्वीप',
      latitude: 10.5667,
      longitude: 72.6417,
    ),
  ];

  /// Complete list of ALL 33 Districts of Gujarat + major districts of other agricultural states
  static const List<IndianDistrict> allDistricts = [
    // --- GUJARAT (33 Districts) ---
    IndianDistrict(
      key: 'Ahmedabad',
      stateKey: 'Gujarat',
      englishName: 'Ahmedabad',
      gujaratiName: 'અમદાવાદ',
      hindiName: 'अहमदाबाद',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    IndianDistrict(
      key: 'Amreli',
      stateKey: 'Gujarat',
      englishName: 'Amreli',
      gujaratiName: 'અમરેલી',
      hindiName: 'अमरेली',
      latitude: 21.6032,
      longitude: 71.2221,
    ),
    IndianDistrict(
      key: 'Anand',
      stateKey: 'Gujarat',
      englishName: 'Anand',
      gujaratiName: 'આણંદ',
      hindiName: 'आणंद',
      latitude: 22.5645,
      longitude: 72.9289,
    ),
    IndianDistrict(
      key: 'Aravalli',
      stateKey: 'Gujarat',
      englishName: 'Aravalli',
      gujaratiName: 'અરવલ્લી',
      hindiName: 'अरवल्ली',
      latitude: 23.5350,
      longitude: 73.2750,
    ),
    IndianDistrict(
      key: 'Banaskantha',
      stateKey: 'Gujarat',
      englishName: 'Banaskantha (Palanpur)',
      gujaratiName: 'બનાસકાંઠા (પાલનપુર)',
      hindiName: 'बनासकांठा (पालनपुर)',
      latitude: 24.1724,
      longitude: 72.4346,
    ),
    IndianDistrict(
      key: 'Bharuch',
      stateKey: 'Gujarat',
      englishName: 'Bharuch',
      gujaratiName: 'ભરૂચ',
      hindiName: 'भरूच',
      latitude: 21.7051,
      longitude: 72.9959,
    ),
    IndianDistrict(
      key: 'Bhavnagar',
      stateKey: 'Gujarat',
      englishName: 'Bhavnagar',
      gujaratiName: 'ભાવનગર',
      hindiName: 'भावनगर',
      latitude: 21.7645,
      longitude: 72.1519,
    ),
    IndianDistrict(
      key: 'Botad',
      stateKey: 'Gujarat',
      englishName: 'Botad',
      gujaratiName: 'બોટાદ',
      hindiName: 'बोटाद',
      latitude: 22.1704,
      longitude: 71.6669,
    ),
    IndianDistrict(
      key: 'Chhota Udaipur',
      stateKey: 'Gujarat',
      englishName: 'Chhota Udaipur',
      gujaratiName: 'છોટા ઉદેપુર',
      hindiName: 'छोटा उदयपुर',
      latitude: 22.3108,
      longitude: 74.0125,
    ),
    IndianDistrict(
      key: 'Dahod',
      stateKey: 'Gujarat',
      englishName: 'Dahod',
      gujaratiName: 'દાહોદ',
      hindiName: 'दाहोद',
      latitude: 22.8364,
      longitude: 74.2568,
    ),
    IndianDistrict(
      key: 'Dang',
      stateKey: 'Gujarat',
      englishName: 'Dang (Ahwa)',
      gujaratiName: 'ડાંગ (આહવા)',
      hindiName: 'डांग (आहवा)',
      latitude: 20.7565,
      longitude: 73.6872,
    ),
    IndianDistrict(
      key: 'Devbhoomi Dwarka',
      stateKey: 'Gujarat',
      englishName: 'Devbhoomi Dwarka (Khambhalia)',
      gujaratiName: 'દેવભૂમિ દ્વારકા (ખંભાળિયા)',
      hindiName: 'देवभूमि द्वारका (खंभालिया)',
      latitude: 22.2104,
      longitude: 69.6582,
    ),
    IndianDistrict(
      key: 'Gandhinagar',
      stateKey: 'Gujarat',
      englishName: 'Gandhinagar',
      gujaratiName: 'ગાંધીનગર',
      hindiName: 'गांधीनगर',
      latitude: 23.2156,
      longitude: 72.6369,
    ),
    IndianDistrict(
      key: 'Gir Somnath',
      stateKey: 'Gujarat',
      englishName: 'Gir Somnath (Veraval)',
      gujaratiName: 'ગીર સોમનાથ (વેરાવળ)',
      hindiName: 'गीर सोमनाथ (वेरावल)',
      latitude: 20.9000,
      longitude: 70.3667,
    ),
    IndianDistrict(
      key: 'Jamnagar',
      stateKey: 'Gujarat',
      englishName: 'Jamnagar',
      gujaratiName: 'જામનગર',
      hindiName: 'जामनगर',
      latitude: 22.4707,
      longitude: 70.0577,
    ),
    IndianDistrict(
      key: 'Junagadh',
      stateKey: 'Gujarat',
      englishName: 'Junagadh',
      gujaratiName: 'જૂનાગઢ',
      hindiName: 'जूनागढ़',
      latitude: 21.5222,
      longitude: 70.4579,
    ),
    IndianDistrict(
      key: 'Kheda',
      stateKey: 'Gujarat',
      englishName: 'Kheda (Nadiad)',
      gujaratiName: 'ખેડા (નડિયાદ)',
      hindiName: 'खेड़ा (नडियाद)',
      latitude: 22.6916,
      longitude: 72.8634,
    ),
    IndianDistrict(
      key: 'Kutch',
      stateKey: 'Gujarat',
      englishName: 'Kutch (Bhuj)',
      gujaratiName: 'કચ્છ (ભુજ)',
      hindiName: 'कच्छ (भुज)',
      latitude: 23.2420,
      longitude: 69.6669,
    ),
    IndianDistrict(
      key: 'Mahisagar',
      stateKey: 'Gujarat',
      englishName: 'Mahisagar (Lunawada)',
      gujaratiName: 'મહીસાગર (લુણાવાડા)',
      hindiName: 'महीसागर (लुणावाड़ा)',
      latitude: 23.1352,
      longitude: 73.6143,
    ),
    IndianDistrict(
      key: 'Mehsana',
      stateKey: 'Gujarat',
      englishName: 'Mehsana',
      gujaratiName: 'મહેસાણા',
      hindiName: 'मेहसाणा',
      latitude: 23.5880,
      longitude: 72.3693,
    ),
    IndianDistrict(
      key: 'Morbi',
      stateKey: 'Gujarat',
      englishName: 'Morbi',
      gujaratiName: 'મોરબી',
      hindiName: 'मोरबी',
      latitude: 22.8173,
      longitude: 70.8378,
    ),
    IndianDistrict(
      key: 'Narmada',
      stateKey: 'Gujarat',
      englishName: 'Narmada (Rajpipla)',
      gujaratiName: 'નર્મદા (રાજપીપળા)',
      hindiName: 'नर्मदा (राजपीपला)',
      latitude: 21.8700,
      longitude: 73.5000,
    ),
    IndianDistrict(
      key: 'Navsari',
      stateKey: 'Gujarat',
      englishName: 'Navsari',
      gujaratiName: 'નવસારી',
      hindiName: 'नवसारी',
      latitude: 20.9500,
      longitude: 72.9300,
    ),
    IndianDistrict(
      key: 'Panchmahal',
      stateKey: 'Gujarat',
      englishName: 'Panchmahal (Godhra)',
      gujaratiName: 'પંચમહાલ (ગોધરા)',
      hindiName: 'पंचमहाल (गोधरा)',
      latitude: 22.7750,
      longitude: 73.6140,
    ),
    IndianDistrict(
      key: 'Patan',
      stateKey: 'Gujarat',
      englishName: 'Patan',
      gujaratiName: 'પાટણ',
      hindiName: 'पाटण',
      latitude: 23.8500,
      longitude: 72.1300,
    ),
    IndianDistrict(
      key: 'Porbandar',
      stateKey: 'Gujarat',
      englishName: 'Porbandar',
      gujaratiName: 'પોરબંદર',
      hindiName: 'पोरबंदर',
      latitude: 21.6417,
      longitude: 69.6293,
    ),
    IndianDistrict(
      key: 'Rajkot',
      stateKey: 'Gujarat',
      englishName: 'Rajkot',
      gujaratiName: 'રાજકોટ',
      hindiName: 'राजकोट',
      latitude: 22.3039,
      longitude: 70.8022,
    ),
    IndianDistrict(
      key: 'Sabarkantha',
      stateKey: 'Gujarat',
      englishName: 'Sabarkantha (Himatnagar)',
      gujaratiName: 'સાબરકાંઠા (હિંમતનગર)',
      hindiName: 'साबरकांठा (हिम्मतनगर)',
      latitude: 23.5977,
      longitude: 72.9698,
    ),
    IndianDistrict(
      key: 'Surat',
      stateKey: 'Gujarat',
      englishName: 'Surat',
      gujaratiName: 'સુરત',
      hindiName: 'सूरत',
      latitude: 21.1702,
      longitude: 72.8311,
    ),
    IndianDistrict(
      key: 'Surendranagar',
      stateKey: 'Gujarat',
      englishName: 'Surendranagar',
      gujaratiName: 'સુરેન્દ્રનગર',
      hindiName: 'सुरेंद्रनगर',
      latitude: 22.7279,
      longitude: 71.6370,
    ),
    IndianDistrict(
      key: 'Tapi',
      stateKey: 'Gujarat',
      englishName: 'Tapi (Vyara)',
      gujaratiName: 'તાપી (વ્યારા)',
      hindiName: 'तापी (व्यारा)',
      latitude: 21.1118,
      longitude: 73.3934,
    ),
    IndianDistrict(
      key: 'Vadodara',
      stateKey: 'Gujarat',
      englishName: 'Vadodara',
      gujaratiName: 'વડોદરા',
      hindiName: 'वडोदरा',
      latitude: 22.3072,
      longitude: 73.1812,
    ),
    IndianDistrict(
      key: 'Valsad',
      stateKey: 'Gujarat',
      englishName: 'Valsad',
      gujaratiName: 'વલસાડ',
      hindiName: 'वलसाड',
      latitude: 20.6100,
      longitude: 72.9260,
    ),

    // --- MAHARASHTRA ---
    IndianDistrict(
      key: 'Mumbai',
      stateKey: 'Maharashtra',
      englishName: 'Mumbai',
      gujaratiName: 'મુંબઈ',
      hindiName: 'मुंबई',
      latitude: 19.0760,
      longitude: 72.8777,
    ),
    IndianDistrict(
      key: 'Pune',
      stateKey: 'Maharashtra',
      englishName: 'Pune',
      gujaratiName: 'પુણે',
      hindiName: 'पुणे',
      latitude: 18.5204,
      longitude: 73.8567,
    ),
    IndianDistrict(
      key: 'Nagpur',
      stateKey: 'Maharashtra',
      englishName: 'Nagpur',
      gujaratiName: 'નાગપુર',
      hindiName: 'नागपुर',
      latitude: 21.1458,
      longitude: 79.0882,
    ),
    IndianDistrict(
      key: 'Nashik',
      stateKey: 'Maharashtra',
      englishName: 'Nashik',
      gujaratiName: 'નાસિક',
      hindiName: 'नासिक',
      latitude: 19.9975,
      longitude: 73.7898,
    ),
    IndianDistrict(
      key: 'Chhatrapati Sambhaji Nagar',
      stateKey: 'Maharashtra',
      englishName: 'Chhatrapati Sambhaji Nagar (Aurangabad)',
      gujaratiName: 'છત્રપતિ સંભાજી નગર (ઔરંગાબાદ)',
      hindiName: 'छत्रपति संभाजी नगर (औरंगाबाद)',
      latitude: 19.8762,
      longitude: 75.3433,
    ),
    IndianDistrict(
      key: 'Solapur',
      stateKey: 'Maharashtra',
      englishName: 'Solapur',
      gujaratiName: 'સોલાપુર',
      hindiName: 'सोलापुर',
      latitude: 17.6599,
      longitude: 75.9064,
    ),
    IndianDistrict(
      key: 'Kolhapur',
      stateKey: 'Maharashtra',
      englishName: 'Kolhapur',
      gujaratiName: 'કોલ્હાપુર',
      hindiName: 'कोल्हापुर',
      latitude: 16.7050,
      longitude: 74.2433,
    ),

    // --- RAJASTHAN ---
    IndianDistrict(
      key: 'Jaipur',
      stateKey: 'Rajasthan',
      englishName: 'Jaipur',
      gujaratiName: 'જયપુર',
      hindiName: 'जयपुर',
      latitude: 26.9124,
      longitude: 75.7873,
    ),
    IndianDistrict(
      key: 'Jodhpur',
      stateKey: 'Rajasthan',
      englishName: 'Jodhpur',
      gujaratiName: 'જોધપુર',
      hindiName: 'जोधपुर',
      latitude: 26.2389,
      longitude: 73.0243,
    ),
    IndianDistrict(
      key: 'Kota',
      stateKey: 'Rajasthan',
      englishName: 'Kota',
      gujaratiName: 'કોટા',
      hindiName: 'कोटा',
      latitude: 25.2138,
      longitude: 75.8648,
    ),
    IndianDistrict(
      key: 'Udaipur',
      stateKey: 'Rajasthan',
      englishName: 'Udaipur',
      gujaratiName: 'ઉદયપુર',
      hindiName: 'उदयपुर',
      latitude: 24.5854,
      longitude: 73.7125,
    ),

    // --- PUNJAB ---
    IndianDistrict(
      key: 'Ludhiana',
      stateKey: 'Punjab',
      englishName: 'Ludhiana',
      gujaratiName: 'લુધિયાણા',
      hindiName: 'लुधियाना',
      latitude: 30.9010,
      longitude: 75.8573,
    ),
    IndianDistrict(
      key: 'Amritsar',
      stateKey: 'Punjab',
      englishName: 'Amritsar',
      gujaratiName: 'અમૃતસર',
      hindiName: 'अमृतसर',
      latitude: 31.6340,
      longitude: 74.8723,
    ),
    IndianDistrict(
      key: 'Jalandhar',
      stateKey: 'Punjab',
      englishName: 'Jalandhar',
      gujaratiName: 'જલંધર',
      hindiName: 'जालंधर',
      latitude: 31.3260,
      longitude: 75.5762,
    ),
    IndianDistrict(
      key: 'Bathinda',
      stateKey: 'Punjab',
      englishName: 'Bathinda',
      gujaratiName: 'ભટિંડા',
      hindiName: 'बठिंडा',
      latitude: 30.2110,
      longitude: 74.9455,
    ),

    // --- MADHYA PRADESH ---
    IndianDistrict(
      key: 'Indore',
      stateKey: 'Madhya Pradesh',
      englishName: 'Indore',
      gujaratiName: 'ઇન્દોર',
      hindiName: 'इंदौर',
      latitude: 22.7196,
      longitude: 75.8577,
    ),
    IndianDistrict(
      key: 'Bhopal',
      stateKey: 'Madhya Pradesh',
      englishName: 'Bhopal',
      gujaratiName: 'ભોપાલ',
      hindiName: 'भोपाल',
      latitude: 23.2599,
      longitude: 77.4126,
    ),
    IndianDistrict(
      key: 'Ujjain',
      stateKey: 'Madhya Pradesh',
      englishName: 'Ujjain',
      gujaratiName: 'ઉજ્જૈન',
      hindiName: 'उज्जैन',
      latitude: 23.1765,
      longitude: 75.7885,
    ),
    IndianDistrict(
      key: 'Gwalior',
      stateKey: 'Madhya Pradesh',
      englishName: 'Gwalior',
      gujaratiName: 'ગ્વાલિયર',
      hindiName: 'ग्वालियर',
      latitude: 26.2183,
      longitude: 78.1828,
    ),

    // --- UTTAR PRADESH ---
    IndianDistrict(
      key: 'Lucknow',
      stateKey: 'Uttar Pradesh',
      englishName: 'Lucknow',
      gujaratiName: 'લખનૌ',
      hindiName: 'लखनऊ',
      latitude: 26.8467,
      longitude: 80.9462,
    ),
    IndianDistrict(
      key: 'Kanpur',
      stateKey: 'Uttar Pradesh',
      englishName: 'Kanpur',
      gujaratiName: 'કાનપુર',
      hindiName: 'कानपुर',
      latitude: 26.4499,
      longitude: 80.3319,
    ),
    IndianDistrict(
      key: 'Varanasi',
      stateKey: 'Uttar Pradesh',
      englishName: 'Varanasi',
      gujaratiName: 'વારાણસી',
      hindiName: 'वाराणसी',
      latitude: 25.3176,
      longitude: 82.9739,
    ),
    IndianDistrict(
      key: 'Agra',
      stateKey: 'Uttar Pradesh',
      englishName: 'Agra',
      gujaratiName: 'આગ્રા',
      hindiName: 'आगरा',
      latitude: 27.1767,
      longitude: 78.0081,
    ),
  ];

  /// Returns districts for a given state key, falling back to capital if needed
  static List<IndianDistrict> getDistrictsForState(String? stateKey) {
    if (stateKey == null || stateKey.isEmpty) return [];
    final matches = allDistricts.where((d) => d.stateKey.toLowerCase() == stateKey.toLowerCase()).toList();
    if (matches.isNotEmpty) return matches;

    // Fallback: create default district representing state center
    final state = allStates.firstWhere(
      (s) => s.key.toLowerCase() == stateKey.toLowerCase(),
      orElse: () => allStates.first,
    );
    return [
      IndianDistrict(
        key: '${state.englishName} Central',
        stateKey: state.key,
        englishName: '${state.englishName} Central',
        gujaratiName: '${state.gujaratiName} મુખ્ય જિલ્લો',
        hindiName: '${state.hindiName} मुख्य जिला',
        latitude: state.latitude,
        longitude: state.longitude,
      ),
    ];
  }

  /// Finds accurate coordinates for a given district & state
  static ({double lat, double lon}) getCoordinates({String? district, String? state}) {
    if (district != null && district.isNotEmpty) {
      final cleanDistrict = district.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toLowerCase();
      final match = allDistricts.firstWhere(
        (d) =>
            d.key.toLowerCase() == cleanDistrict ||
            d.englishName.toLowerCase().contains(cleanDistrict) ||
            d.gujaratiName.toLowerCase().contains(cleanDistrict) ||
            d.hindiName.toLowerCase().contains(cleanDistrict),
        orElse: () => allDistricts.first,
      );
      if (match.key.toLowerCase() == cleanDistrict ||
          match.englishName.toLowerCase().contains(cleanDistrict)) {
        return (lat: match.latitude, lon: match.longitude);
      }
    }

    if (state != null && state.isNotEmpty) {
      final cleanState = state.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toLowerCase();
      final match = allStates.firstWhere(
        (s) =>
            s.key.toLowerCase() == cleanState ||
            s.englishName.toLowerCase().contains(cleanState) ||
            s.gujaratiName.toLowerCase().contains(cleanState) ||
            s.hindiName.toLowerCase().contains(cleanState),
        orElse: () => allStates.first,
      );
      return (lat: match.latitude, lon: match.longitude);
    }

    // Default: Gujarat coordinates
    return (lat: 23.0225, lon: 72.5714);
  }
}
