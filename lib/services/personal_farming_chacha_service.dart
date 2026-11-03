import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop_recommendation.dart';
import '../models/farmer_profile.dart';
import '../models/farming_action_task.dart';
import '../services/mandi_discovery_service.dart';
import '../services/weather_service.dart';

/// Intelligent Agricultural Assistant Service ("Personal Farming Chacha").
/// Translates complex agronomic data, weather forecasts, and mandi trends
/// into simple, friendly, actionable conversation for Indian farmers.
class PersonalFarmingChachaService {
  PersonalFarmingChachaService._();
  static final PersonalFarmingChachaService instance =
      PersonalFarmingChachaService._();

  static const String _completedTasksPrefPrefix = 'khetchacha_action_tasks_';

  // =========================================================================
  // 1. PERSONAL GREETING GENERATION
  // =========================================================================
  String generateFarmerGreeting(
    FarmerProfile profile,
    String langCode,
    String season,
  ) {
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : (langCode == 'gu'
            ? 'ખેડૂત મિત્ર'
            : (langCode == 'hi'
                ? 'किसान भाई'
                : (langCode == 'pa' ? 'ਕਿਸਾਨ ਵੀਰ' : 'Farmer Friend')));

    final district = profile.effectiveDistrict.isNotEmpty
        ? profile.effectiveDistrict
        : 'Amreli';

    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'નમસ્તે $name! 👋\nતમારા $district ખેતરની જમીન, હવામાન અને આજના બજારના ભાવ પ્રમાણે અમે તમારા માટે ખેતીની ઉત્તમ સલાહ તૈયાર કરી છે.';
      case 'hi':
        return 'नमस्ते $name! 👋\nआपके $district खेत की मिट्टी, मौसम और आज के मंडी भाव के अनुसार हमने आपके लिए उत्तम कृषि सलाह तैयार की है।';
      case 'pa':
        return 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ $name! 👋\nਤੁਹਾਡੇ $district ਖੇਤ ਦੀ ਮਿੱਟੀ, ਮੌਸਮ ਅਤੇ ਅੱਜ ਦੇ ਮੰਡੀ ਭਾਅ ਅਨੁਸਾਰ ਅਸੀਂ ਵਧੀਆ ਖੇਤੀ ਸਲਾਹ ਤਿਆਰ ਕੀਤੀ ਹੈ।';
      case 'mr':
        return 'नमस्कार $name! 👋\nतुमच्या $district शेताची जमीन, हवामान आणि आजचे बाजारभाव यानुसार आम्ही तुमच्यासाठी शेतीचा सल्ला तयार केला आहे.';
      default:
        return 'Namaste $name! 👋\nBased on your $district farm\'s soil, local weather, and today\'s mandi prices, we have prepared personal farming guidance for you.';
    }
  }

  // =========================================================================
  // 2. PRIMARY CROP HEADLINE & FRIENDLY "WHY" REASONS
  // =========================================================================
  String generateBestCropHeadline(
    CropRecommendation crop,
    FarmerProfile profile,
    String langCode,
  ) {
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : (langCode == 'gu'
            ? 'ખેડૂત મિત્ર'
            : (langCode == 'hi'
                ? 'किसान भाई'
                : (langCode == 'pa' ? 'ਕਿਸਾਨ ਵੀਰ' : 'Farmer Friend')));

    final cropName = crop.nativeName ?? crop.englishName;

    switch (langCode.toLowerCase()) {
      case 'gu':
        return '🌱 $name, અત્યારે તમારા ખેતર માટે $cropName ની ખેતી એક સારો વિકલ્પ હોઈ શકે છે.';
      case 'hi':
        return '🌱 $name, इस समय आपके खेत के लिए $cropName की खेती एक बहुत अच्छा विकल्प हो सकती है।';
      case 'pa':
        return '🌱 $name, ਇਸ ਸਮੇਂ ਤੁਹਾਡੇ ਖੇਤ ਲਈ $cropName ਦੀ ਖੇਤੀ ਬਹੁਤ ਵਧੀਆ ਵਿਕਲਪ ਹੋ ਸਕਦੀ ਹੈ।';
      case 'mr':
        return '🌱 $name, सध्या तुमच्या शेतासाठी $cropName ची लागवड एक उत्तम पर्याय ठरू शकते.';
      default:
        return '🌱 $name, right now cultivating $cropName is the most profitable choice for your farm.';
    }
  }

  List<String> generateBestCropWhyReasons(
    CropRecommendation crop,
    FarmerProfile profile,
    String langCode,
  ) {
    final soil = profile.soilType.isNotEmpty ? profile.soilType : 'કાળી જમીન';

    switch (langCode.toLowerCase()) {
      case 'gu':
        return [
          'તમારી $soil માટે સૌથી વધુ અનુકૂળ.',
          'હાલની ઋતુમાં વાવણી યોગ્ય સમય (${crop.bestSowingPeriod}).',
          'પાણીની જરૂરિયાત તમારા ઉપલબ્ધ પાણી પ્રમાણે વ્યવસ્થિત થઈ શકે.',
          'નજીકની મંડીમાં બજારની સારી સંભાવના અને ઊંચી માગ.',
        ];
      case 'hi':
        return [
          'आपकी $soil के लिए अत्यधिक उपयुक्त।',
          'वर्तमान मौसम में बुवाई का सही समय (${crop.bestSowingPeriod})।',
          'पानी की आवश्यकता आपकी उपलब्ध सिंचाई के अनुसार उपयुक्त।',
          'निकटतम मंडी में अच्छी मांग और लाभकारी मूल्य।',
        ];
      case 'pa':
        return [
          'ਤੁਹਾਡੀ $soil ਲਈ ਬਿਲਕੁਲ ਢੁਕਵੀਂ ਫਸਲ।',
          'ਮੌਜੂਦਾ ਮੌਸਮ ਵਿੱਚ ਬਿਜਾਈ ਦਾ ਸਹੀ ਸਮਾਂ (${crop.bestSowingPeriod})।',
          'ਪਾਣੀ ਦੀ ਲੋੜ ਤੁਹਾਡੀ ਉਪਲਬਧ ਸਿੰਚਾਈ ਅਨੁਸਾਰ ਢੁਕਵੀਂ।',
          'ਨੇੜਲੀ ਮੰਡੀ ਵਿੱਚ ਚੰਗੀ ਮੰਗ ਅਤੇ ਵਧੀਆ ਭਾਅ।',
        ];
      case 'mr':
        return [
          'तुमच्या $soil साठी अत्यंत अनुकूल.',
          'सध्याच्या हंगामात पेरणीसाठी योग्य वेळ (${crop.bestSowingPeriod}).',
          'पाण्याची गरज तुमच्या उपलब्ध सिंचनानुसार योग्य.',
          'जवळच्या बाजारपेठेत उत्तम मागणी व चांगला दर.',
        ];
      default:
        return [
          'Highly suited for your $soil type.',
          'Optimal sowing window right now (${crop.bestSowingPeriod}).',
          'Water needs match your farm irrigation facility.',
          'Strong demand and stable prices in nearby mandis.',
        ];
    }
  }

  // =========================================================================
  // 3. UNDERSTANDABLE LOCAL WEATHER ADVICE
  // =========================================================================
  String generateFriendlyWeatherAdvice(
    FarmWeatherReport? weather,
    FarmerProfile profile,
    String langCode,
  ) {
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : 'ખેડૂત મિત્ર';

    if (weather == null) {
      return langCode == 'gu'
          ? 'હાલ હવામાન સામાન્ય છે. વાવણી પહેલાં જમીનમાં પૂરતો ભેજ ચકાસી લો.'
          : 'Weather is favorable. Ensure adequate soil moisture before sowing.';
    }

    final isRainy = weather.conditionName.toLowerCase().contains('rain') ||
        weather.weatherCode >= 51;
    final isHot = weather.temperature >= 35.0;

    switch (langCode.toLowerCase()) {
      case 'gu':
        if (isRainy) {
          return '$name, આવતા દિવસોમાં વરસાદની શક્યતા છે. અત્યારે સિંચાઈ ટાળો અને ખેતરમાં વધારાના પાણીના નિકાલની યોગ્ય વ્યવસ્થા કરો.';
        } else if (isHot) {
          return '$name, તાપમાન ઊંચું (${weather.temperature.toStringAsFixed(0)}°C) રહેવાની ધારણા છે. પાકને તાપથી બચાવવા વહેલી સવારે અથવા સાંજે જ હળવી સિંચાઈ કરો.';
        } else {
          return '$name, આવતા અઠવાડિયે વરસાદની શક્યતા ઓછી છે. જો ખેતરમાં પૂરતું પાણી ઉપલબ્ધ હોય તો વાવણી પહેલાં જમીનમાં જરૂરી ભેજ જાળવો.';
        }
      case 'hi':
        if (isRainy) {
          return '$name, आगामी दिनों में बारिश की संभावना है। अभी सिंचाई न करें और खेत में जल निकासी की व्यवस्था दुरुस्त रखें।';
        } else if (isHot) {
          return '$name, तापमान अधिक (${weather.temperature.toStringAsFixed(0)}°C) रहने का अनुमान है। फसल में नमी बनाए रखने हेतु सुबह या शाम के समय हल्की सिंचाई करें।';
        } else {
          return '$name, अगले हफ्ते बारिश की संभावना कम है। खेत में पर्याप्त नमी बनाए रखकर बुवाई की तैयारी शुरू करें।';
        }
      case 'pa':
        if (isRainy) {
          return '$name, ਅਗਲੇ ਦਿਨਾਂ ਵਿੱਚ ਮੀਂਹ ਪੈਣ ਦੀ ਸੰਭਾਵਨਾ ਹੈ। ਹੁਣੇ ਸਿੰਚਾਈ ਰੋਕੋ ਅਤੇ ਪਾਣੀ ਦੇ ਨਿਕਾਸ ਦਾ ਪ੍ਰਬੰਧ ਕਰੋ।';
        } else {
          return '$name, ਅਗਲੇ ਹਫ਼ਤੇ ਮੌਸਮ ਸਾਫ਼ ਰਹੇਗਾ। ਬਿਜਾਈ ਤੋਂ ਪਹਿਲਾਂ ਜ਼ਮੀਨ ਵਿੱਚ ਲੋੜੀਂਦੀ ਨਮੀ ਦੀ ਜਾਂਚ ਕਰੋ।';
        }
      default:
        if (isRainy) {
          return 'Rain is expected in upcoming days. Avoid chemical spray and ensure clear field drainage.';
        } else if (isHot) {
          return 'High temperatures ahead (${weather.temperature.toStringAsFixed(0)}°C). Irrigate during early morning or late evening to conserve moisture.';
        } else {
          return 'Weather is stable with low rain chance. Maintain adequate soil moisture for prompt seed germination.';
        }
    }
  }

  // =========================================================================
  // 4. NEXT 7 DAYS FARMING ACTION PLAN
  // =========================================================================
  List<FarmingActionTask> generateWeeklyActionPlan({
    required CropRecommendation? crop,
    required FarmerProfile profile,
    required FarmWeatherReport? weather,
    required String langCode,
    Set<String> completedTaskIds = const {},
  }) {
    final cropName = crop?.nativeName ?? crop?.englishName ?? 'પાક';
    final isRainy = weather != null &&
        (weather.conditionName.toLowerCase().contains('rain') ||
            weather.weatherCode >= 51);

    if (langCode == 'gu') {
      return [
        FarmingActionTask(
          id: 'task_soil_prep_1',
          dayName: 'સોમવાર (Monday)',
          dayIndex: 1,
          title: 'ખેતરની જમીન તૈયાર કરો',
          description: 'જમીનને ઊંડી ખેડ કરી ઢેફા ભાંગી જમીન સમતલ બનાવો.',
          whyReason: 'બીજનો સારો ઉગાવો થાય અને મૂળ જમીનમાં ઊંડે ઉતરી શકે.',
          timing: 'સવારે 7:00 થી 11:00',
          estimatedCost: '₹1,200',
          isCompleted: completedTaskIds.contains('task_soil_prep_1'),
        ),
        FarmingActionTask(
          id: 'task_moisture_check_2',
          dayName: 'મંગળવાર (Tuesday)',
          dayIndex: 2,
          title: 'જમીનમાં ભેજ અને તાપમાન તપાસો',
          description: 'જમીનમાં 4-5 ઇંચ ઊંડાઈએ પૂરતો ભેજ છે કે નહીં તે ચકાસો.',
          whyReason: isRainy
              ? 'વરસાદની આગાહી હોવાથી વધારાનું પાણી ન ભરાય તે જોવું જરૂરી છે.'
              : 'યોગ્ય ભેજ વગર વાવેલું બિયારણ સુકાઈ જવાનું જોખમ રહે છે.',
          timing: 'સવારે અથવા સાંજે',
          estimatedCost: 'મફત',
          isCompleted: completedTaskIds.contains('task_moisture_check_2'),
        ),
        FarmingActionTask(
          id: 'task_seed_treatment_3',
          dayName: 'બુધવાર (Wednesday)',
          dayIndex: 3,
          title: '$cropName ના પ્રમાણિત બિયારણ અને માવજત',
          description: 'ટ્રાઇકોડર્મા અથવા કાર્બેન્ડાઝીમ વડે બીજ માવજત (સીડ ટ્રીટમેન્ટ) કરો.',
          whyReason: 'ઉગતા છોડને ફૂગ અને ઉધઈ જેવા રોગો સામે 90% રક્ષણ મળે છે.',
          timing: 'વાવણીના 6 કલાક પહેલાં',
          estimatedCost: '₹350',
          isCompleted: completedTaskIds.contains('task_seed_treatment_3'),
        ),
        FarmingActionTask(
          id: 'task_basal_fertilizer_4',
          dayName: 'ગુરુવાર (Thursday)',
          dayIndex: 4,
          title: 'પાયાનું ખાતર (DAP / જીવામૃત) આપો',
          description: 'જમીનમાં ભલામણ મુજબ દેશી ખાતર અથવા પાયાનું ખાતર મિક્સ કરો.',
          whyReason: 'શરૂઆતના 20 દિવસ સુધી પાકને મૂળના ઝડપી વિકાસ માટે ફોસ્ફરસ જરૂરી છે.',
          timing: 'વાવણી સાથે',
          estimatedCost: '₹1,400',
          isCompleted: completedTaskIds.contains('task_basal_fertilizer_4'),
        ),
        FarmingActionTask(
          id: 'task_sowing_day_5',
          dayName: 'શુક્રવાર (Friday)',
          dayIndex: 5,
          title: 'હવામાન તપાસી વાવણી શરૂ કરો',
          description: 'યોગ્ય અંતરે (બે હાર વચ્ચે 30-45 સેમી) બિયારણ વાવો.',
          whyReason: 'યોગ્ય અંતર રાખવાથી છોડને પૂરતો સૂર્યપ્રકાશ અને હવા મળે છે.',
          timing: 'સવારે 6:30 થી 10:30',
          estimatedCost: '₹800 (વાવણી મજૂરી)',
          isCompleted: completedTaskIds.contains('task_sowing_day_5'),
        ),
        FarmingActionTask(
          id: 'task_irrigation_inspection_6',
          dayName: 'શનિવાર (Saturday)',
          dayIndex: 6,
          title: 'હળવું ઓપણી / પિયત અને નિરીક્ષણ',
          description: 'જરૂર જણાય તો હળવું પિયત આપો જેથી જમીન પોચી રહે.',
          whyReason: 'બીજનું અંકુરણ જમીન કઠણ ન થાય ત્યારે જ સરળતાથી બહાર નીકળી શકે.',
          timing: 'સાંજે 4:00 પછી',
          estimatedCost: '₹300',
          isCompleted: completedTaskIds.contains('task_irrigation_inspection_6'),
        ),
        FarmingActionTask(
          id: 'task_next_week_plan_7',
          dayName: 'રવિવાર (Sunday)',
          dayIndex: 7,
          title: 'આગામી અઠવાડિયાનું આયોજન અને નીંદણ નિયંત્રણ',
          description: 'અંકુરણની ટકાવારી તપાસો અને જરૂરી નીંદણનાશકનું આયોજન કરો.',
          whyReason: 'શરૂઆતથી નીંદણ મુક્ત ખેતર 25% વધુ ઉત્પાદન આપે છે.',
          timing: 'સમીક્ષા સમય',
          estimatedCost: 'મફત',
          isCompleted: completedTaskIds.contains('task_next_week_plan_7'),
        ),
      ];
    } else if (langCode == 'hi') {
      return [
        FarmingActionTask(
          id: 'task_soil_prep_1',
          dayName: 'सोमवार (Monday)',
          dayIndex: 1,
          title: 'खेत की जुताई एवं तैयारी',
          description: 'खेत में गहरी जुताई कर पाटा लगाएं और मिट्टी भुरभुरी बनाएं।',
          whyReason: 'बीज का अंकुरण बेहतर होता है और जड़ें गहराई तक जाती हैं।',
          timing: 'सुबह 7:00 से 11:00',
          estimatedCost: '₹1,200',
          isCompleted: completedTaskIds.contains('task_soil_prep_1'),
        ),
        FarmingActionTask(
          id: 'task_moisture_check_2',
          dayName: 'मंगलवार (Tuesday)',
          dayIndex: 2,
          title: 'मृदा में नमी की जांच',
          description: 'खेत में 4 इंच गहराई तक पर्याप्त नमी सुनिश्चित करें।',
          whyReason: 'पर्याप्त नमी के बिना बुवाई करने पर बीज सूखने का खतरा रहता है।',
          timing: 'सुबह या शाम',
          estimatedCost: 'निःशुल्क',
          isCompleted: completedTaskIds.contains('task_moisture_check_2'),
        ),
        FarmingActionTask(
          id: 'task_seed_treatment_3',
          dayName: 'बुधवार (Wednesday)',
          dayIndex: 3,
          title: '$cropName का बीजोपचार (Seed Treatment)',
          description: 'ट्राइकोडर्मा अथवा कार्बेन्डाजिम से बीज शोधन करें।',
          whyReason: 'पौधों को फफूंद एवं कीटों से 90% तक सुरक्षा मिलती है।',
          timing: 'बुवाई से 4 घंटे पूर्व',
          estimatedCost: '₹350',
          isCompleted: completedTaskIds.contains('task_seed_treatment_3'),
        ),
        FarmingActionTask(
          id: 'task_basal_fertilizer_4',
          dayName: 'गुरुवार (Thursday)',
          dayIndex: 4,
          title: 'आधारभूत खाद (DAP / कम्पोस्ट) का प्रयोग',
          description: 'सिफारिश के अनुसार खेत में संतुलित उर्वरक मिलाएं।',
          whyReason: 'प्रारंभिक अवस्था में जड़ों के तीव्र विकास के लिए आवश्यक है।',
          timing: 'बुवाई के साथ',
          estimatedCost: '₹1,400',
          isCompleted: completedTaskIds.contains('task_basal_fertilizer_4'),
        ),
        FarmingActionTask(
          id: 'task_sowing_day_5',
          dayName: 'शुक्रवार (Friday)',
          dayIndex: 5,
          title: 'मौसम देखकर बुवाई का कार्य',
          description: 'उचित कतार दूरी (30-45 सेमी) पर बुवाई करें।',
          whyReason: 'सही दूरी रखने से पौधों को पर्याप्त धूप और पोषण मिलता है।',
          timing: 'सुबह 6:30 से 10:30',
          estimatedCost: '₹800',
          isCompleted: completedTaskIds.contains('task_sowing_day_5'),
        ),
        FarmingActionTask(
          id: 'task_irrigation_inspection_6',
          dayName: 'शनिवार (Saturday)',
          dayIndex: 6,
          title: 'हल्की सिंचाई एवं निरीक्षण',
          description: 'यदि आवश्यक हो तो हल्की सिंचाई करें जिससे पपड़ी न जमे।',
          whyReason: 'कोमल अंकुर आसानी से जमीन से बाहर आ सकें।',
          timing: 'शाम 4:00 के बाद',
          estimatedCost: '₹300',
          isCompleted: completedTaskIds.contains('task_irrigation_inspection_6'),
        ),
        FarmingActionTask(
          id: 'task_next_week_plan_7',
          dayName: 'रविवार (Sunday)',
          dayIndex: 7,
          title: 'अंकुरण समीक्षा एवं खरपतवार प्रबंधन',
          description: 'खेत का फेरा लगाकर अंकुरण प्रतिशत का अवलोकन करें।',
          whyReason: 'शुरुआत में नियंत्रित खरपतवार 25% अधिक उपज सुनिश्चित करता है।',
          timing: 'समीक्षा',
          estimatedCost: 'निःशुल्क',
          isCompleted: completedTaskIds.contains('task_next_week_plan_7'),
        ),
      ];
    } else {
      // English fallback
      return [
        FarmingActionTask(
          id: 'task_soil_prep_1',
          dayName: 'Monday',
          dayIndex: 1,
          title: 'Land Preparation & Levelling',
          description: 'Plough field to fine tilth and break hard soil clods.',
          whyReason: 'Allows root penetration and uniform seed germination.',
          timing: '7:00 AM - 11:00 AM',
          estimatedCost: '₹1,200',
          isCompleted: completedTaskIds.contains('task_soil_prep_1'),
        ),
        FarmingActionTask(
          id: 'task_moisture_check_2',
          dayName: 'Tuesday',
          dayIndex: 2,
          title: 'Soil Moisture & Temperature Check',
          description: 'Verify 4-5 inches moisture depth across the field.',
          whyReason: 'Dry seedbeds cause poor seedling emergence.',
          timing: 'Morning or Evening',
          estimatedCost: 'Free',
          isCompleted: completedTaskIds.contains('task_moisture_check_2'),
        ),
        FarmingActionTask(
          id: 'task_seed_treatment_3',
          dayName: 'Wednesday',
          dayIndex: 3,
          title: 'Certified Seed Inoculation & Treatment',
          description: 'Treat seed with Trichoderma / Carbendazim.',
          whyReason: 'Prevents seedling wilt and root rot diseases.',
          timing: '4 hours before sowing',
          estimatedCost: '₹350',
          isCompleted: completedTaskIds.contains('task_seed_treatment_3'),
        ),
        FarmingActionTask(
          id: 'task_basal_fertilizer_4',
          dayName: 'Thursday',
          dayIndex: 4,
          title: 'Basal Fertilizer Application',
          description: 'Apply recommended DAP / Compost to seed furrow.',
          whyReason: 'Promotes rapid early root establishment.',
          timing: 'During sowing',
          estimatedCost: '₹1,400',
          isCompleted: completedTaskIds.contains('task_basal_fertilizer_4'),
        ),
        FarmingActionTask(
          id: 'task_sowing_day_5',
          dayName: 'Friday',
          dayIndex: 5,
          title: 'Weather-Informed Precision Sowing',
          description: 'Sow at recommended row spacing (30-45 cm).',
          whyReason: 'Ensures ample sunlight and canopy aeration.',
          timing: '6:30 AM - 10:30 AM',
          estimatedCost: '₹800',
          isCompleted: completedTaskIds.contains('task_sowing_day_5'),
        ),
        FarmingActionTask(
          id: 'task_irrigation_inspection_6',
          dayName: 'Saturday',
          dayIndex: 6,
          title: 'Light Irrigation & Crust Prevention',
          description: 'Provide light irrigation if crust forms.',
          whyReason: 'Prevents seedling entrapment in hard soil.',
          timing: 'After 4:00 PM',
          estimatedCost: '₹300',
          isCompleted: completedTaskIds.contains('task_irrigation_inspection_6'),
        ),
        FarmingActionTask(
          id: 'task_next_week_plan_7',
          dayName: 'Sunday',
          dayIndex: 7,
          title: 'Emergence Audit & Weed Plan',
          description: 'Inspect germination percentage and plan weed removal.',
          whyReason: 'Weed-free early stage increases final yield by 25%.',
          timing: 'Evening audit',
          estimatedCost: 'Free',
          isCompleted: completedTaskIds.contains('task_next_week_plan_7'),
        ),
      ];
    }
  }

  // =========================================================================
  // 5. TASK COMPLETION PERSISTENCE
  // =========================================================================
  Future<Set<String>> loadCompletedTaskIds(String farmerPhone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_completedTasksPrefPrefix$farmerPhone';
      final list = prefs.getStringList(key) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleTaskCompleted(
    String farmerPhone,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_completedTasksPrefPrefix$farmerPhone';
      final current = (prefs.getStringList(key) ?? []).toSet();
      if (isCompleted) {
        current.add(taskId);
      } else {
        current.remove(taskId);
      }
      await prefs.setStringList(key, current.toList());
    } catch (e) {
      debugPrint('[PersonalFarmingChachaService] Error saving task: $e');
    }
  }

  // =========================================================================
  // 6. QUESTION & ANSWER INTELLIGENCE (SECTION 10: ASK KHETCHACHA)
  // =========================================================================
  String answerFarmerQuestion(
    String question, {
    required FarmerProfile profile,
    required CropRecommendation? crop,
    required FarmWeatherReport? weather,
    required MandiMarketWithDistance? market,
    required String langCode,
  }) {
    final q = question.toLowerCase().trim();
    final cropName = crop?.nativeName ?? crop?.englishName ?? 'ચણા';
    final district = profile.effectiveDistrict.isNotEmpty
        ? profile.effectiveDistrict
        : 'અમરેલી';

    // 1. Crop recommendation question: "મારે અત્યારે કયો પાક વાવવો જોઈએ?"
    if (q.contains('કયો પાક') ||
        q.contains('कौन सी फसल') ||
        q.contains('ਕਿਹੜੀ ਫਸਲ') ||
        q.contains('which crop')) {
      if (langCode == 'gu') {
        return 'તમારા $district ખેતર અને ${profile.soilType} જમીન પ્રમાણે અત્યારે $cropName ની ખેતી સૌથી ઉત્તમ રહેશે. અંદાજિત નફો એકરે ₹${((crop?.netProfitPerAcre ?? 35000) / 1000).toStringAsFixed(0)} હજાર મળી શકે છે.';
      } else if (langCode == 'hi') {
        return 'आपके $district क्षेत्र और ${profile.soilType} मिट्टी के लिए इस समय $cropName की बुवाई सर्वोत्तम रहेगी। अनुमानित लाभ लगभग ₹${((crop?.netProfitPerAcre ?? 35000) / 1000).toStringAsFixed(0)} हजार प्रति एकड़ है।';
      } else {
        return 'For your $district farm with ${profile.soilType}, $cropName is the top recommended crop right now with expected profit around ₹${((crop?.netProfitPerAcre ?? 35000) / 1000).toStringAsFixed(0)}k per acre.';
      }
    }

    // 2. Weather question: "આવતા અઠવાડિયે વરસાદ આવશે?"
    if (q.contains('વરસાદ') ||
        q.contains('बारिश') ||
        q.contains('ਮੀਂਹ') ||
        q.contains('rain')) {
      if (weather != null &&
          (weather.conditionName.toLowerCase().contains('rain') ||
              weather.weatherCode >= 51)) {
        if (langCode == 'gu') {
          return 'હા, આવતા 2-3 દિવસમાં $district માં હળવોથી મધ્યમ વરસાદ આવવાની શક્યતા છે. અત્યારે રાસાયણિક છંટકાવ અને સિંચાઈ ટાળો.';
        } else {
          return 'Yes, light to moderate rainfall is expected in $district in the next 2-3 days. Avoid spraying and ensure field drainage.';
        }
      } else {
        if (langCode == 'gu') {
          return 'ના, આવતા અઠવાડિયે વરસાદની શક્યતા ઘણી ઓછી છે. હવામાન સ્વચ્છ રહેશે અને તાપમાન ${weather?.temperature.toStringAsFixed(1) ?? '28'}°C આસપાસ રહેશે.';
        } else {
          return 'No, rain probability is low for the upcoming week. Conditions will remain clear around ${weather?.temperature.toStringAsFixed(1) ?? '28'}°C.';
        }
      }
    }

    // 3. Fertilizer question: "ચણામાં કેટલું ખાતર નાખવું?"
    if (q.contains('ખાતર') ||
        q.contains('खाद') ||
        q.contains('ਖਾਦ') ||
        q.contains('fertilizer')) {
      if (langCode == 'gu') {
        return '$cropName માં વાવણી સમયે એકરે 20 કિલો DAP અને 10 કિલો પોટાશ પાયામાં આપો. સાથે જીવામૃત અથવા દેશી ખાતર આપવાથી જમીનમાં પોષક તત્વો વધશે.';
      } else if (langCode == 'hi') {
        return '$cropName में बुवाई के समय प्रति एकड़ 20 किग्रा DAP और 10 किग्रा पोटाश आधारभूत खाद के रूप में दें। जैविक जीवामृत का प्रयोग सर्वोत्तम रहता है।';
      } else {
        return 'For $cropName, apply 20 kg DAP and 10 kg Potash per acre as basal dose at sowing. Combine with organic compost for best yield.';
      }
    }

    // 4. Mandi rate question: "મારી નજીકની મંડીમાં શું ભાવ છે?"
    if (q.contains('ભાવ') ||
        q.contains('भाव') ||
        q.contains('ਭਾਅ') ||
        q.contains('price') ||
        q.contains('mandi')) {
      if (market != null) {
        final commodity = market.market.getPriceForCommodity(cropName) ??
            (market.market.commodityPrices.isNotEmpty
                ? market.market.commodityPrices.first
                : null);
        final rate = commodity != null
            ? commodity.modalPrice.toStringAsFixed(0)
            : '5,700';
        final comName = commodity?.commodity ?? cropName;

        if (langCode == 'gu') {
          return 'તમારી નજીકની ${market.market.name} (${market.distanceKm.toStringAsFixed(0)} કિમી) માં $comName નો છેલ્લો મોડલ ભાવ ₹$rate પ્રતિ ક્વિન્ટલ છે.';
        } else {
          return 'In your nearest ${market.market.name} (${market.distanceKm.toStringAsFixed(0)} km), latest price for $comName is ₹$rate / Quintal.';
        }
      } else {
        return langCode == 'gu'
            ? 'નજીકની મંડીમાં ચણાનો અંદાજિત સરેરાશ ભાવ ₹5,400 થી ₹5,800 પ્રતિ ક્વિન્ટલ ચાલે છે.'
            : 'Average nearby mandi rate ranges between ₹5,400 and ₹5,800 per Quintal.';
      }
    }

    // Generic agricultural AI response
    if (langCode == 'gu') {
      return 'ખેતચાચા તમારા પ્રશ્નનો અભ્યાસ કરી રહ્યા છે: $district વિસ્તાર માટે $cropName ની ખેતી અને હવામાન સલાહનું પાલન કરવાથી ઉત્તમ પરિણામ મળશે.';
    } else {
      return 'KhetChacha AI advisory: For $district conditions, timely sowing of $cropName and following weather alerts will maximize yield.';
    }
  }
}
