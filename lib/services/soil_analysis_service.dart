import 'package:shared_preferences/shared_preferences.dart';

import '../models/soil_profile.dart';

/// Service managing farm soil analysis, chemical nutrient diagnostics,
/// and ICAR-recommended soil management advisories.
class SoilAnalysisService {
  SoilAnalysisService._internal();
  static final SoilAnalysisService instance = SoilAnalysisService._internal();

  static const String _soilProfileKeyPrefix = 'khetchacha_soil_profile_';

  /// Retrieves saved soil profile for a farmer, or generates regional ICAR benchmark.
  Future<SoilProfile> getSoilProfile({
    required String farmerUidOrPhone,
    required String state,
    required String district,
    SoilType? preferredType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_soilProfileKeyPrefix$farmerUidOrPhone';
      final jsonString = prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        return SoilProfile.fromJsonString(jsonString);
      }
    } catch (_) {}

    return SoilProfile.estimatedForRegion(
      state: state,
      district: district,
      preferredType: preferredType,
    );
  }

  /// Saves updated soil profile to persistent storage.
  Future<bool> saveSoilProfile({
    required String farmerUidOrPhone,
    required SoilProfile profile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_soilProfileKeyPrefix$farmerUidOrPhone';
      return await prefs.setString(key, profile.toJsonString());
    } catch (_) {
      return false;
    }
  }

  /// Generates actionable agronomic soil health advice based on NPK and pH levels.
  List<String> getNutrientAdvisory({
    required SoilProfile profile,
    required String langCode,
  }) {
    final advisories = <String>[];
    final lc = langCode.toLowerCase();

    // pH Advisory
    if (profile.pH < 6.5) {
      if (lc == 'gu') {
        advisories.add(
          'જમીન એસિડિક છે (pH < 6.5). જમીનની ફળદ્રુપતા સુધારવા માટે એકરે 200-300 કિગ્રા ચૂનો (લાઈમ) ઉમેરો.',
        );
      } else if (lc == 'hi') {
        advisories.add(
          'मिट्टी अम्लीय है (pH < 6.5)। सुधार हेतु 200-300 किग्रा प्रति एकड़ चूना मिलाएँ।',
        );
      } else if (lc == 'pa') {
        advisories.add(
          'ਮਿੱਟੀ ਤੇਜ਼ਾਬੀ ਹੈ (pH < 6.5)। ਸੁਧਾਰ ਲਈ ਪ੍ਰਤੀ ਏਕੜ 200-300 ਕਿਲੋ ਚੂਨਾ ਪਾਓ।',
        );
      } else {
        advisories.add(
          'Soil is slightly acidic (pH < 6.5). Apply 200-300 kg agricultural lime per acre to buffer pH.',
        );
      }
    } else if (profile.pH > 7.8) {
      if (lc == 'gu') {
        advisories.add(
          'જમીન સહેજ ક્ષારીય છે (pH > 7.8). જીપ્સમ અથવા ખાતરનો ઉપયોગ કરો જેથી પોષક તત્વો સહેલાઈથી મળે.',
        );
      } else if (lc == 'hi') {
        advisories.add(
          'मिट्टी क्षारीय है (pH > 7.8)। जिप्सम और कम्पोस्ट खाद का प्रयोग कर क्षारीयता कम करें।',
        );
      } else if (lc == 'pa') {
        advisories.add(
          'ਮਿੱਟੀ ਖਾਰੀ ਹੈ (pH > 7.8)। ਜਿਪਸਮ ਅਤੇ ਦੇਸੀ ਰੂੜੀ ਦੀ ਵਰਤੋਂ ਕਰੋ।',
        );
      } else {
        advisories.add(
          'Soil is alkaline (pH > 7.8). Apply gypsum (100-150 kg/acre) and organic compost to optimize nutrient availability.',
        );
      }
    } else {
      if (lc == 'gu') {
        advisories.add(
          'જમીનનું pH (6.5 - 7.5) આદર્શ છે, જે મોટાભાગના પાક માટે શ્રેષ્ઠ છે.',
        );
      } else if (lc == 'hi') {
        advisories.add(
          'मिट्टी का pH (6.5 - 7.5) उत्कृष्ट है, अधिकांश फसलों के लिए अनुकूल।',
        );
      } else if (lc == 'pa') {
        advisories.add(
          'ਮਿੱਟੀ ਦਾ pH (6.5 - 7.5) ਆਦਰਸ਼ ਹੈ, ਬਹੁਤੀਆਂ ਫ਼ਸਲਾਂ ਲਈ ਢੁਕਵਾਂ।',
        );
      } else {
        advisories.add(
          'Soil pH is optimal (6.5 - 7.5), suitable for maximum nutrient uptake.',
        );
      }
    }

    // Nitrogen Advisory
    if (profile.nitrogenKgPerHa < 280) {
      if (lc == 'gu') {
        advisories.add(
          'નાઇટ્રોજનની ઉણપ છે. કઠોળ પાક સાથે રોટેશન કરો અથવા લીલો પડવાશ (શણ/ઇકકડ) અપનાવો.',
        );
      } else if (lc == 'hi') {
        advisories.add(
          'नाइट्रोजन की कमी है। दलहनी फसलें उगाएँ या हरी खाद (ढैंचा/सनई) का प्रयोग करें।',
        );
      } else if (lc == 'pa') {
        advisories.add(
          'ਨਾਈਟ੍ਰੋਜਨ ਦੀ ਘਾਟ ਹੈ। ਦਾਲਾਂ ਦੀ ਖੇਤੀ ਕਰੋ ਜਾਂ ਜੰਤਰ/ਸਣ ਦੀ ਹਰੀ ਖਾਦ ਵਰਤੋ।',
        );
      } else {
        advisories.add(
          'Available Nitrogen is low. Practice pulse crop rotation (legumes) or green manuring (Dhaincha/Sunhemp).',
        );
      }
    }

    // Organic Carbon Advisory
    if (profile.organicCarbonPercent < 0.50) {
      if (lc == 'gu') {
        advisories.add(
          'સેન્દ્રીય કાર્બન ઓછો છે (<0.50%). એકરે 4-5 ટન દેશી છાણીયું ખાતર અથવા વર્મીકમ્પોસ્ટ ઉમેરો.',
        );
      } else if (lc == 'hi') {
        advisories.add(
          'जैविक कार्बन कम है। 4-5 टन गोबर की खाद या वर्मीकम्पोस्ट प्रति एकड़ डालें।',
        );
      } else if (lc == 'pa') {
        advisories.add(
          'ਜੈਵਿਕ ਕਾਰਬਨ ਘੱਟ ਹੈ। 4-5 ਟਨ ਦੇਸੀ ਗੋਹੇ ਦੀ ਖਾਦ ਜਾਂ ਵਰਮੀਕੰਪੋਸਟ ਪਾਓ।',
        );
      } else {
        advisories.add(
          'Organic carbon is low (<0.50%). Add 4-5 tons well-decomposed FYM or vermicompost per acre.',
        );
      }
    }

    return advisories;
  }
}
