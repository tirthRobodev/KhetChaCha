import 'india_districts_data.dart';
import 'location_localizer.dart';

export 'location_localizer.dart';

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
    return LocationLocalizer.getStateName(this, langCode);
  }

  String getPureNativeName(String langCode) {
    return LocationLocalizer.getStatePureNative(this, langCode);
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
    return LocationLocalizer.getDistrictName(this, langCode);
  }

  String getPureNativeName(String langCode) {
    return LocationLocalizer.getDistrictPureNative(this, langCode);
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
      hindiName: 'આંધ્ર પ્રદેશ',
      latitude: 15.9129,
      longitude: 79.7400,
    ),
    IndianState(
      key: 'Telangana',
      englishName: 'Telangana',
      gujaratiName: 'તેલંગાણા',
      hindiName: 'તેલંગાણા',
      latitude: 17.3850,
      longitude: 78.4867,
    ),
    IndianState(
      key: 'West Bengal',
      englishName: 'West Bengal',
      gujaratiName: 'પશ્ચિમ બંગાળ',
      hindiName: 'પશ્ચિમ બંગાળ',
      latitude: 22.5726,
      longitude: 88.3639,
    ),
    IndianState(
      key: 'Odisha',
      englishName: 'Odisha',
      gujaratiName: 'ઓડિશા',
      hindiName: 'ઓડિશા',
      latitude: 20.9517,
      longitude: 85.0985,
    ),
    IndianState(
      key: 'Kerala',
      englishName: 'Kerala',
      gujaratiName: 'કેરળ',
      hindiName: 'કેરળ',
      latitude: 10.8505,
      longitude: 76.2711,
    ),
    IndianState(
      key: 'Assam',
      englishName: 'Assam',
      gujaratiName: 'આસામ',
      hindiName: 'આસામ',
      latitude: 26.2006,
      longitude: 92.9376,
    ),
    IndianState(
      key: 'Chhattisgarh',
      englishName: 'Chhattisgarh',
      gujaratiName: 'છત્તીસગઢ',
      hindiName: 'છત્તીસગઢ',
      latitude: 21.2787,
      longitude: 81.8661,
    ),
    IndianState(
      key: 'Jharkhand',
      englishName: 'Jharkhand',
      gujaratiName: 'ઝારખંડ',
      hindiName: 'ઝારખંડ',
      latitude: 23.6102,
      longitude: 85.2799,
    ),
    IndianState(
      key: 'Uttarakhand',
      englishName: 'Uttarakhand',
      gujaratiName: 'ઉત્તરાખંડ',
      hindiName: 'ઉત્તરાખંડ',
      latitude: 30.0668,
      longitude: 79.0193,
    ),
    IndianState(
      key: 'Himachal Pradesh',
      englishName: 'Himachal Pradesh',
      gujaratiName: 'હિમાચલ પ્રદેશ',
      hindiName: 'હિમાચલ પ્રદેશ',
      latitude: 31.1048,
      longitude: 77.1734,
    ),
    IndianState(
      key: 'Goa',
      englishName: 'Goa',
      gujaratiName: 'ગોવા',
      hindiName: 'ગોવા',
      latitude: 15.2993,
      longitude: 74.1240,
    ),
    IndianState(
      key: 'Tripura',
      englishName: 'Tripura',
      gujaratiName: 'ત્રિપુરા',
      hindiName: 'ત્રિપુરા',
      latitude: 23.9408,
      longitude: 91.9882,
    ),
    IndianState(
      key: 'Meghalaya',
      englishName: 'Meghalaya',
      gujaratiName: 'મેઘાલય',
      hindiName: 'મેઘાલય',
      latitude: 25.4670,
      longitude: 91.3662,
    ),
    IndianState(
      key: 'Manipur',
      englishName: 'Manipur',
      gujaratiName: 'મણિપુર',
      hindiName: 'મણિપુર',
      latitude: 24.6637,
      longitude: 93.9063,
    ),
    IndianState(
      key: 'Nagaland',
      englishName: 'Nagaland',
      gujaratiName: 'નાગાલેન્ડ',
      hindiName: 'નાગાલેન્ડ',
      latitude: 26.1584,
      longitude: 94.5624,
    ),
    IndianState(
      key: 'Mizoram',
      englishName: 'Mizoram',
      gujaratiName: 'મિઝોરમ',
      hindiName: 'મિઝોરમ',
      latitude: 23.1645,
      longitude: 92.9376,
    ),
    IndianState(
      key: 'Arunachal Pradesh',
      englishName: 'Arunachal Pradesh',
      gujaratiName: 'અરુણાચલ પ્રદેશ',
      hindiName: 'અરુણાચલ પ્રદેશ',
      latitude: 28.2180,
      longitude: 94.7278,
    ),
    IndianState(
      key: 'Sikkim',
      englishName: 'Sikkim',
      gujaratiName: 'સિક્કિમ',
      hindiName: 'સિક્કિમ',
      latitude: 27.5330,
      longitude: 88.5122,
    ),
    IndianState(
      key: 'Delhi (NCT)',
      englishName: 'Delhi (NCT)',
      gujaratiName: 'દિલ્હી',
      hindiName: 'દિલ્હી',
      latitude: 28.7041,
      longitude: 77.1025,
    ),
    IndianState(
      key: 'Jammu and Kashmir',
      englishName: 'Jammu and Kashmir',
      gujaratiName: 'જમ્મુ અને કાશ્મીર',
      hindiName: 'જમ્મુ અને કાશ્મીર',
      latitude: 33.7782,
      longitude: 76.5762,
    ),
    IndianState(
      key: 'Ladakh',
      englishName: 'Ladakh',
      gujaratiName: 'લદ્દાખ',
      hindiName: 'લદ્દાખ',
      latitude: 34.1526,
      longitude: 77.5771,
    ),
    IndianState(
      key: 'Chandigarh',
      englishName: 'Chandigarh',
      gujaratiName: 'ચંદીગઢ',
      hindiName: 'ચંદીગઢ',
      latitude: 30.7333,
      longitude: 76.7794,
    ),
    IndianState(
      key: 'Puducherry',
      englishName: 'Puducherry',
      gujaratiName: 'પુડુચેરી',
      hindiName: 'પુડુચેરી',
      latitude: 11.9416,
      longitude: 79.8083,
    ),
    IndianState(
      key: 'Dadra and Nagar Haveli and Daman and Diu',
      englishName: 'Dadra and Nagar Haveli and Daman and Diu',
      gujaratiName: 'દાદરા અને નગર હવેલી અને દમણ અને દીવ',
      hindiName: 'દાદરા અને નગર હવેલી અને દમણ અને દીવ',
      latitude: 20.3974,
      longitude: 72.8328,
    ),
    IndianState(
      key: 'Andaman and Nicobar Islands',
      englishName: 'Andaman and Nicobar Islands',
      gujaratiName: 'અંદમાન અને નિકોબાર ટાપુઓ',
      hindiName: 'અંદમાન અને નિકોબાર ટાપુઓ',
      latitude: 11.7401,
      longitude: 92.6586,
    ),
    IndianState(
      key: 'Lakshadweep',
      englishName: 'Lakshadweep',
      gujaratiName: 'લક્ષદ્વીપ',
      hindiName: 'લક્ષદ્વીપ',
      latitude: 10.5667,
      longitude: 72.6417,
    ),
  ];

  /// Complete comprehensive list of all districts across all 28 States & 8 Union Territories
  static const List<IndianDistrict> allDistricts =
      IndiaDistrictsData.allDistricts;

  /// Returns districts for a given state key, dynamically matching all Indian districts
  static List<IndianDistrict> getDistrictsForState(String? stateKey) {
    if (stateKey == null || stateKey.isEmpty) return [];
    final cleanState = stateKey.trim().toLowerCase();
    final matches = allDistricts
        .where((d) => d.stateKey.toLowerCase() == cleanState)
        .toList();
    if (matches.isNotEmpty) return matches;

    // Fallback: create default district representing state center if state not found
    final state = allStates.firstWhere(
      (s) => s.key.toLowerCase() == cleanState,
      orElse: () => allStates.first,
    );
    return [
      IndianDistrict(
        key: '${state.englishName} Central',
        stateKey: state.key,
        englishName: '${state.englishName} Central',
        gujaratiName: '${state.gujaratiName} મુખ્ય જિલ્લો',
        hindiName: '${state.hindiName} મુખ્ય જિલ્લો',
        latitude: state.latitude,
        longitude: state.longitude,
      ),
    ];
  }

  /// Finds accurate coordinates for a given district & state across all of India
  static ({double lat, double lon}) getCoordinates({
    String? district,
    String? state,
  }) {
    if (district != null && district.trim().isNotEmpty) {
      final raw = district.trim().toLowerCase();
      // Remove parentheses and contents, e.g. "Ahmedabad (અમદાવાદ)" -> "Ahmedabad"
      final cleanDistrict = raw.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

      for (final d in allDistricts) {
        final keyLower = d.key.toLowerCase();
        final engLower = d.englishName.toLowerCase();

        if (keyLower == cleanDistrict ||
            engLower == cleanDistrict ||
            raw.contains(keyLower) ||
            raw.contains(engLower) ||
            (d.gujaratiName.isNotEmpty &&
                raw.contains(d.gujaratiName.toLowerCase())) ||
            (d.hindiName.isNotEmpty &&
                raw.contains(d.hindiName.toLowerCase()))) {
          return (lat: matchLat(d.latitude), lon: matchLon(d.longitude));
        }
      }
    }

    if (state != null && state.trim().isNotEmpty) {
      final rawState = state.trim().toLowerCase();
      final cleanState = rawState.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

      for (final s in allStates) {
        final keyLower = s.key.toLowerCase();
        final engLower = s.englishName.toLowerCase();
        if (keyLower == cleanState ||
            engLower == cleanState ||
            rawState.contains(keyLower) ||
            rawState.contains(engLower) ||
            (s.gujaratiName.isNotEmpty &&
                rawState.contains(s.gujaratiName.toLowerCase())) ||
            (s.hindiName.isNotEmpty &&
                rawState.contains(s.hindiName.toLowerCase()))) {
          return (lat: matchLat(s.latitude), lon: matchLon(s.longitude));
        }
      }
    }

    // Default: Central India / Gujarat coordinates
    return (lat: 23.0225, lon: 72.5714);
  }

  static double matchLat(double lat) => lat != 0.0 ? lat : 23.0225;
  static double matchLon(double lon) => lon != 0.0 ? lon : 72.5714;
}
