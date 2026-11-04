import 'package:flutter/material.dart';

import '../../localization/crop_master_database.dart';
import '../../models/annual_crop_plan.dart';
import '../../models/crop_recommendation.dart';
import '../../models/farmer_profile.dart';
import '../../models/farming_action_task.dart';
import '../../models/soil_profile.dart';
import '../../services/annual_crop_planner_service.dart';
import '../../services/crop_audio_service.dart';
import '../../services/crop_recommendation_service.dart';
import '../../services/farm_profile_service.dart';
import '../../services/language_service.dart';
import '../../services/mandi_discovery_service.dart';
import '../../services/personal_farming_chacha_service.dart';
import '../../services/soil_analysis_service.dart';
import '../../services/weather_service.dart';
import '../calculators/smart_crop_profit_calculator_page.dart';
import '../mandi/mandi_comparison_page.dart';
import '../mandi/mandi_discovery_page.dart';
import '../soil/smart_soil_profile_page.dart';
import 'annual_farm_planner_page.dart';
import 'crop_recommendation_details_page.dart';
import 'seasonal_planning_page.dart';

/// Master Personal AI Farming Assistant ("KhetChacha AI").
/// Transforms the complex farm planning dashboard into a friendly, knowledgeable
/// farming companion that understands the farmer's land, weather, and mandi prices.
class SmartCropPlanningHubPage extends StatefulWidget {
  final FarmerProfile profile;

  const SmartCropPlanningHubPage({super.key, required this.profile});

  @override
  State<SmartCropPlanningHubPage> createState() =>
      _SmartCropPlanningHubPageState();
}

class _SmartCropPlanningHubPageState extends State<SmartCropPlanningHubPage> {
  late FarmerProfile _profile;
  SoilProfile? _soilProfile;
  FarmWeatherReport? _weatherReport;
  List<CropRecommendation> _top5Crops = [];
  int _selectedCropIndex = 0;
  bool _showAlternativeCrops = false;
  AnnualCropPlan? _primaryAnnualPlan;
  // List<FarmPlot> _plots = [];
  List<MandiMarketWithDistance> _nearbyMarkets = [];
  List<FarmingActionTask> _actionTasks = [];
  Set<String> _completedTaskIds = {};
  bool _isLoading = true;
  bool _isSpeaking = false;
  bool _showTechnicalDetails = true;

  // Ask KhetChacha State
  final TextEditingController _questionController = TextEditingController();
  String? _askedQuestion;
  String? _aiAnswer;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _soilProfile = SoilProfile.estimatedForRegion(
      state: _profile.effectiveState,
      district: _profile.effectiveDistrict,
      preferredType: SoilTypeExtension.fromString(_profile.soilType),
    );
    _top5Crops = CropRecommendationService.instance.getTop5Recommendations(
      _profile,
      soilProfile: _soilProfile,
    );
    final plans = AnnualCropPlannerService.instance.generateAnnualPlans(
      _profile,
      soilProfile: _soilProfile,
    );
    _primaryAnnualPlan = plans.isNotEmpty ? plans.first : null;
    _actionTasks = PersonalFarmingChachaService.instance
        .generateWeeklyActionPlan(
          crop: _top5Crops.isNotEmpty ? _top5Crops.first : null,
          profile: _profile,
          weather: null,
          langCode: 'en',
        );
    _isLoading = false;
    _loadAllHubData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHubData() async {
    final langCode = _profile.selectedLanguage.isNotEmpty
        ? _profile.selectedLanguage
        : LanguageService.instance.currentLanguage.locale.languageCode;

    // 1. Load Soil Profile
    final soil = await SoilAnalysisService.instance.getSoilProfile(
      farmerUidOrPhone: _profile.mobileNumber,
      state: _profile.effectiveState,
      district: _profile.effectiveDistrict,
      preferredType: SoilTypeExtension.fromString(_profile.soilType),
    );

    // 2. Load Live Weather
    final weather = await WeatherService.instance.getLiveWeather(
      district: _profile.effectiveDistrict,
      state: _profile.effectiveState,
      latitude: _profile.latitude,
      longitude: _profile.longitude,
      langCode: langCode,
    );

    // 3. Load Farm Plots
    final plots = await FarmProfileService.instance.getFarmPlots(
      _profile.mobileNumber,
    );

    // 4. Compute Top 5 AI Recommendations
    final top5 = CropRecommendationService.instance.getTop5Recommendations(
      _profile,
      soilProfile: soil,
      weather: weather,
    );

    // 5. Load Nearby Mandis
    final lat = _profile.latitude ?? 21.6032;
    final lon = _profile.longitude ?? 71.2221;
    final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: lat,
      longitude: lon,
      maxDistanceKm: 120,
    );

    // 6. Generate Annual Two-Crop Rotation Plan
    final plans = AnnualCropPlannerService.instance.generateAnnualPlans(
      _profile,
      plot: plots.isNotEmpty ? plots.first : null,
      soilProfile: soil,
    );

    // 7. Load Completed Tasks & Generate Weekly Schedule
    final completed = await PersonalFarmingChachaService.instance
        .loadCompletedTaskIds(_profile.mobileNumber);
    final activeCrop = top5.isNotEmpty ? top5.first : null;
    final tasks = PersonalFarmingChachaService.instance
        .generateWeeklyActionPlan(
          crop: activeCrop,
          profile: _profile,
          weather: weather,
          langCode: langCode,
          completedTaskIds: completed,
        );

    if (mounted) {
      setState(() {
        _soilProfile = soil;
        _weatherReport = weather;
        _top5Crops = top5;
        _nearbyMarkets = nearby;
        _primaryAnnualPlan = plans.isNotEmpty ? plans.first : null;
        _completedTaskIds = completed;
        _actionTasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _speakAdvisory() {
    if (_top5Crops.isEmpty) return;
    final activeCrop = _top5Crops[_selectedCropIndex];
    final langCode = _profile.selectedLanguage.isNotEmpty
        ? _profile.selectedLanguage
        : LanguageService.instance.currentLanguage.locale.languageCode;

    final greeting = PersonalFarmingChachaService.instance
        .generateFarmerGreeting(_profile, langCode, _profile.farmingSeason)
        .replaceAll('\n', ' ');

    final cropHeadline = PersonalFarmingChachaService.instance
        .generateBestCropHeadline(activeCrop, _profile, langCode);

    final weatherAdvice = PersonalFarmingChachaService.instance
        .generateFriendlyWeatherAdvice(_weatherReport, _profile, langCode);

    final fullSpeech = '$greeting $cropHeadline $weatherAdvice';

    CropAudioService.instance.speakText(
      text: fullSpeech,
      langCode: langCode,
      id: activeCrop.cropId,
    );

    setState(() => _isSpeaking = true);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _handleAskQuestion(String question) {
    if (question.trim().isEmpty) return;
    final langCode = _profile.selectedLanguage.isNotEmpty
        ? _profile.selectedLanguage
        : LanguageService.instance.currentLanguage.locale.languageCode;
    final activeCrop = _top5Crops.isNotEmpty
        ? _top5Crops[_selectedCropIndex]
        : null;
    final market = _nearbyMarkets.isNotEmpty ? _nearbyMarkets.first : null;

    final answer = PersonalFarmingChachaService.instance.answerFarmerQuestion(
      question,
      profile: _profile,
      crop: activeCrop,
      weather: _weatherReport,
      market: market,
      langCode: langCode,
    );

    setState(() {
      _askedQuestion = question;
      _aiAnswer = answer;
    });

    _questionController.clear();

    // Speak AI answer
    CropAudioService.instance.speakText(
      text: answer,
      langCode: langCode,
      id: 'ai_qa_response',
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = _profile.selectedLanguage.isNotEmpty
        ? _profile.selectedLanguage
        : LanguageService.instance.currentLanguage.locale.languageCode;
    final activeCrop = _top5Crops.isNotEmpty
        ? _top5Crops[_selectedCropIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'ખેતચાચા AI ખેતી સલાહકાર'
              : (langCode == 'hi'
                    ? 'खेतचाचा AI कृषि सलाहकार'
                    : (langCode == 'pa'
                          ? 'ਖੇਤਚਾਚਾ AI ਖੇਤੀ ਸਲਾਹਕਾਰ'
                          : 'Smart AI Crop & Farm Planning')),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              color: const Color(0xFFFFD54F),
            ),
            tooltip: langCode == 'gu' ? 'સલાહ સાંભળો' : 'Listen to Advice',
            onPressed: _speakAdvisory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAllHubData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : RefreshIndicator(
              color: const Color(0xFF1B5E20),
              onRefresh: _loadAllHubData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION 1: PERSONAL GREETING CARD
                    _buildSection1PersonalGreeting(langCode),

                    const SizedBox(height: 16),

                    // SECTION 2: YOUR BEST CROP (ONE PRIMARY RECOMMENDATION)
                    if (activeCrop != null)
                      _buildSection2BestCrop(activeCrop, langCode),

                    const SizedBox(height: 16),

                    // SECTION 3: THIS WEEK'S WEATHER ADVICE
                    _buildSection3WeatherAdvice(langCode),

                    const SizedBox(height: 16),

                    // SECTION 4: WHAT TO DO THIS WEEK (7 DAYS ACTION PLAN)
                    _buildSection4WeeklyActionPlan(langCode),

                    const SizedBox(height: 16),

                    // SECTION 5: NEARBY MANDI PRICE INTELLIGENCE
                    _buildSection5NearbyMandi(activeCrop, langCode),

                    const SizedBox(height: 16),

                    // SECTION 6: YOUR ANNUAL FARM PLAN (TWO-CROP ROTATION)
                    _buildSection6AnnualFarmPlan(langCode),

                    const SizedBox(height: 16),

                    // SECTION 7: ASK KHETCHACHA AI (CONVERSATIONAL QA & VOICE)
                    _buildSection7AskKhetChacha(langCode),

                    const SizedBox(height: 20),

                    // COLLAPSIBLE ADVANCED AGRICULTURAL TOOLS & DETAILS
                    _buildAdvancedToolsSection(langCode),

                    const SizedBox(height: 20),

                    // AGRICULTURAL DISCLAIMER
                    _buildDisclaimerCard(langCode),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================================
  // SECTION 1: PERSONAL GREETING CARD (My Personal Farming Chacha)
  // =========================================================================
  Widget _buildSection1PersonalGreeting(String langCode) {
    final season = _profile.farmingSeason.isNotEmpty
        ? _profile.farmingSeason
        : 'Rabi';

    final greetingText = PersonalFarmingChachaService.instance
        .generateFarmerGreeting(_profile, langCode, season);

    final district = _profile.effectiveDistrict.isNotEmpty
        ? _profile.effectiveDistrict
        : 'Amreli';
    final state = _profile.effectiveState.isNotEmpty
        ? _profile.effectiveState
        : 'Gujarat';
    final village = _profile.village.isNotEmpty
        ? _profile.village
        : (langCode == 'gu' ? 'તમારું ગામ' : 'Your Village');

    final soilLabel = _profile.soilType.isNotEmpty
        ? _profile.soilType
        : (langCode == 'gu' ? 'કાળી જમીન' : 'Black Soil');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Season Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langCode == 'gu'
                    ? 'નમસ્તે ખેડૂત મિત્ર!'
                    : (langCode == 'hi'
                          ? 'नमस्ते किसान भाई!'
                          : (langCode == 'pa'
                                ? 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਿਸਾਨ ਵੀਰ!'
                                : 'Namaste Farmer!')),
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Season: $season',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Greeting & Speaker Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('👨‍🌾', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Automatic Location & Farm Understanding Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGreetingChip(
                icon: Icons.location_on_rounded,
                label: '$village, $district, $state',
                color: const Color(0xFFFFD54F),
              ),
              _buildGreetingChip(
                icon: Icons.landscape_rounded,
                label: '${_profile.effectiveFarmSize} ${_profile.landUnit}',
                color: Colors.white,
              ),
              _buildGreetingChip(
                icon: Icons.grass_rounded,
                label: soilLabel,
                color: Colors.white,
              ),
              _buildGreetingChip(
                icon: Icons.wb_sunny_rounded,
                label: '$season ઋતુ',
                color: const Color(0xFFFFD54F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 2: YOUR BEST CROP (One Primary Recommendation)
  // =========================================================================
  Widget _buildSection2BestCrop(CropRecommendation crop, String langCode) {
    final master = CropMasterDatabase.findCropByName(crop.englishName);
    final cropDisplayName = (master != null && langCode != 'en')
        ? master.getLocalizedName(langCode)
        : (crop.nativeName ?? crop.englishName);

    final whyReasons = PersonalFarmingChachaService.instance
        .generateBestCropWhyReasons(crop, _profile, langCode);

    final farmAcres = double.tryParse(_profile.effectiveFarmSize) ?? 2.0;
    final totalCost = crop.totalCostForFarm(farmAcres);
    final netProfit = crop.netProfitForFarm(farmAcres);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best Match Badge & Crop Header
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  crop.iconEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        langCode == 'gu'
                            ? '★ સર્વશ્રેષ્ઠ અનુકૂળ પાક (${crop.suitabilityScore}% મેચ)'
                            : (langCode == 'hi'
                                  ? '★ सर्वश्रेष्ठ उपयुक्त फसल (${crop.suitabilityScore}% मैच)'
                                  : '★ Best Suitable Crop (${crop.suitabilityScore}% Match)'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cropDisplayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      '(${crop.englishName})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Friendly conversational statement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              PersonalFarmingChachaService.instance.generateBestCropHeadline(
                crop,
                _profile,
                langCode,
              ),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Why Suitable Reasons (Section 3)
          Text(
            langCode == 'gu'
                ? 'શા માટે આ પાક અનુકૂળ છે?'
                : (langCode == 'hi'
                      ? 'यह फसल क्यों उपयुक्त है?'
                      : 'Why is this crop suitable?'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          ...whyReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF424242),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sowing time highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFFE65100),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    langCode == 'gu'
                        ? 'વાવણીનો યોગ્ય સમય: ${crop.bestSowingPeriod}'
                        : (langCode == 'hi'
                              ? 'बुवाई का सही समय: ${crop.bestSowingPeriod}'
                              : 'Optimal Sowing Window: ${crop.bestSowingPeriod}'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Farm Economics Snapshot (Per Actual Farm Size)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langCode == 'gu'
                      ? 'તમારા $farmAcres એકર ખેતરમાં અંદાજિત હિસાબ:'
                      : 'Estimated Economics for your $farmAcres Acres:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleEconBox(
                        label: langCode == 'gu' ? 'અંદાજિત ખર્ચ' : 'Est. Cost',
                        amount: '₹${(totalCost / 1000).toStringAsFixed(0)}k',
                        color: const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSimpleEconBox(
                        label: langCode == 'gu' ? 'અંદાજિત નફો' : 'Est. Profit',
                        amount: '₹${(netProfit / 1000).toStringAsFixed(0)}k',
                        color: const Color(0xFF1B5E20),
                        isHighlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Buttons: View Alternatives & Details
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAlternativeCrops = !_showAlternativeCrops;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _showAlternativeCrops
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  label: Text(
                    _showAlternativeCrops
                        ? (langCode == 'gu' ? 'પાક છુપાવો' : 'Hide Others')
                        : (langCode == 'gu'
                              ? 'બીજા પાક જુઓ'
                              : 'View Alternatives'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CropRecommendationDetailsPage(
                          recommendation: crop,
                          profile: _profile,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    langCode == 'gu' ? 'સંપૂર્ણ વિગત' : 'Full Details',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optional 2-3 Alternative Crops (Shown ONLY when farmer taps "બીજા પાક જુઓ")
          if (_showAlternativeCrops && _top5Crops.length > 1) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              langCode == 'gu'
                  ? 'અન્ય વૈકલ્પિક પાક (વધુ 2-3 વિકલ્પો):'
                  : 'Alternative Options for your Farm:',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF616161),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_top5Crops.length - 1, (idx) {
              final realIndex = idx + 1;
              final altCrop = _top5Crops[realIndex];
              final altMaster = CropMasterDatabase.findCropByName(
                altCrop.englishName,
              );
              final altName = (altMaster != null && langCode != 'en')
                  ? altMaster.getLocalizedName(langCode)
                  : (altCrop.nativeName ?? altCrop.englishName);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Row(
                  children: [
                    Text(
                      altCrop.iconEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            altName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${altCrop.suitabilityScore}% Match • નફો: ₹${(altCrop.netProfitPerAcre / 1000).toStringAsFixed(0)}k/Ac',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCropIndex = realIndex;
                          _showAlternativeCrops = false;
                        });
                      },
                      child: Text(
                        langCode == 'gu' ? 'પસંદ કરો' : 'Select',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleEconBox({
    required String label,
    required String amount,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 3: THIS WEEK'S WEATHER (Local Weather-Based Advice)
  // =========================================================================
  Widget _buildSection3WeatherAdvice(String langCode) {
    final w = _weatherReport;
    final advice = PersonalFarmingChachaService.instance
        .generateFriendlyWeatherAdvice(w, _profile, langCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weather Header & Temp Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_outlined,
                      color: Color(0xFF0288D1),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        langCode == 'gu'
                            ? 'આ અઠવાડિયાનું હવામાન'
                            : (langCode == 'hi'
                                  ? 'इस सप्ताह का मौसम'
                                  : 'This Week\'s Weather'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (w != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thermostat_rounded,
                          size: 14,
                          color: Color(0xFF0288D1),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${w.temperature.toStringAsFixed(1)}°C • ${w.conditionName}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0288D1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Plain-Language Understandable Weather Advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFF59D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5D4037),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 4: WHAT TO DO THIS WEEK (Personalized 7 Days Action Plan)
  // =========================================================================
  Widget _buildSection4WeeklyActionPlan(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  langCode == 'gu'
                      ? 'આ અઠવાડિયે તમારા ખેતરમાં શું કરવું?'
                      : (langCode == 'hi'
                            ? 'इस सप्ताह खेत में क्या करें?'
                            : 'What to do on your farm this week?'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tasks List (Monday - Sunday or 5-7 tasks)
          ..._actionTasks.map((task) => _buildTaskItem(task, langCode)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(FarmingActionTask task, String langCode) {
    final isDone = _completedTaskIds.contains(task.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F8E9) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day & Cost Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.dayName,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (task.estimatedCost.isNotEmpty)
                Text(
                  '${langCode == 'gu' ? 'ખર્ચ' : 'Cost'}: ${task.estimatedCost}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF757575),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Task Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDone ? const Color(0xFF2E7D32) : const Color(0xFF212121),
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),

          const SizedBox(height: 4),

          // Why & How
          Text(
            task.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '💡 ${task.whyReason}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF616161),
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 8),

          // Complete Button ("કામ પૂર્ણ થયું ✓")
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () async {
                final newState = !isDone;
                await PersonalFarmingChachaService.instance.toggleTaskCompleted(
                  _profile.mobileNumber,
                  task.id,
                  newState,
                );
                setState(() {
                  if (newState) {
                    _completedTaskIds.add(task.id);
                  } else {
                    _completedTaskIds.remove(task.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBDBDBD),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: isDone ? Colors.white : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone
                          ? (langCode == 'gu'
                                ? 'કામ પૂર્ણ થયું ✓'
                                : 'Completed ✓')
                          : (langCode == 'gu' ? 'પૂર્ણ કરો' : 'Mark Done'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.white : const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 5: NEARBY MANDI PRICE INTELLIGENCE
  // =========================================================================
  Widget _buildSection5NearbyMandi(CropRecommendation? crop, String langCode) {
    final firstMarket = _nearbyMarkets.isNotEmpty ? _nearbyMarkets.first : null;
    final cropName = crop?.nativeName ?? crop?.englishName ?? 'ચણા';

    // Find commodity price matching current crop or first commodity
    final commodity =
        firstMarket?.market.getPriceForCommodity(cropName) ??
        (firstMarket?.market.commodityPrices.isNotEmpty == true
            ? firstMarket!.market.commodityPrices.first
            : null);

    final modalPrice = commodity != null
        ? commodity.modalPrice.toStringAsFixed(0)
        : (crop?.mandiSellingPricePerQuintal.toStringAsFixed(0) ?? '5,400');

    final minPrice = commodity != null
        ? commodity.minPrice.toStringAsFixed(0)
        : '5,100';

    final maxPrice = commodity != null
        ? commodity.maxPrice.toStringAsFixed(0)
        : '5,800';

    final marketName = firstMarket?.market.name ?? 'અમરેલી APMC';
    final distance = firstMarket != null
        ? '${firstMarket.distanceKm.toStringAsFixed(0)} કિમી'
        : '15 કિમી';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    langCode == 'gu'
                        ? 'નજીકની મંડીના ભાવ'
                        : (langCode == 'hi'
                              ? 'निकटतम मंडी भाव'
                              : 'Nearby Mandi Prices'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MandiDiscoveryPage(profile: _profile),
                    ),
                  );
                },
                child: Text(
                  langCode == 'gu' ? 'બધી મંડીઓ' : 'All Mandis',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Simple Conversational Message (Section 6)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              langCode == 'gu'
                  ? 'તમારા નજીકની $marketName ($distance) માં $cropName નો છેલ્લો ઉપલબ્ધ ભાવ ₹$modalPrice પ્રતિ ક્વિન્ટલ છે.'
                  : 'In your nearest $marketName ($distance), latest price for $cropName is ₹$modalPrice per Quintal.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Clean Price Range Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimplePriceText(
                  langCode == 'gu' ? 'લઘુત્તમ' : 'Min',
                  '₹$minPrice',
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                _buildSimplePriceText(
                  langCode == 'gu' ? 'મોડલ ભાવ' : 'Modal',
                  '₹$modalPrice',
                  isBold: true,
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                _buildSimplePriceText(
                  langCode == 'gu' ? 'મહત્તમ' : 'Max',
                  '₹$maxPrice',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Selling recommendation
          Text(
            langCode == 'gu'
                ? '💡 સલાહ: નજીકની આ મંડીમાં વેચવાથી પરિવહન ખર્ચ ઓછો થશે અને સારો નફો મળશે.'
                : '💡 Advice: Selling at this market minimizes freight cost and maximizes net profit.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF616161),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MandiComparisonPage(
                      profile: _profile,
                      initialCommodity: crop?.englishName ?? 'Wheat',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.compare_arrows_rounded, size: 16),
              label: Text(
                langCode == 'gu'
                    ? 'બધા બજારો અને પરિવહન ખર્ચ સરખાવો'
                    : 'Compare Rates & Freight Cost',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(color: Color(0xFF1B5E20)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePriceText(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF1B5E20) : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SECTION 6: YOUR ANNUAL FARM PLAN (Two-Crop Annual Rotation)
  // =========================================================================
  Widget _buildSection6AnnualFarmPlan(String langCode) {
    final plan = _primaryAnnualPlan;
    final farmAcres = double.tryParse(_profile.effectiveFarmSize) ?? 2.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.autorenew_rounded,
                      color: Color(0xFF1B5E20),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        langCode == 'gu'
                            ? 'તમારા ખેતરની વાર્ષિક ખેતી'
                            : (langCode == 'hi'
                                  ? 'वार्षिक दो-फसल योजना'
                                  : 'Two-Crop Annual Farm Planner'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnnualFarmPlannerPage(profile: _profile),
                    ),
                  );
                },
                child: Text(
                  langCode == 'gu' ? 'સંપૂર્ણ આયોજન' : 'Full Plan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (plan != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1st Crop (Kharif)
                      Expanded(
                        child: _buildCropCycleStep(
                          stepNumber: '1',
                          season: langCode == 'gu'
                              ? 'પ્રથમ પાક (ચોમાસુ)'
                              : '1st: Monsoon',
                          cropName: plan.firstCrop.englishName,
                          emoji: plan.firstCrop.iconEmoji,
                          timing: 'જુલાઈ - ઓક્ટોબર',
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      ),
                      // 2nd Crop (Rabi)
                      Expanded(
                        child: _buildCropCycleStep(
                          stepNumber: '2',
                          season: langCode == 'gu'
                              ? 'બીજો પાક (શિયાળુ)'
                              : '2nd: Winter',
                          cropName: plan.secondCrop.englishName,
                          emoji: plan.secondCrop.iconEmoji,
                          timing: 'નવેમ્બર - માર્ચ',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          langCode == 'gu'
                              ? 'વાર્ષિક અંદાજિત ચોખ્ખી આવક:'
                              : 'Est. Annual Net Profit:',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF616161),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${((plan.totalAnnualNetProfitPerAcre * farmAcres) / 1000).toStringAsFixed(0)}k ($farmAcres એકર)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCropCycleStep({
    required String stepNumber,
    required String season,
    required String cropName,
    required String emoji,
    required String timing,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cropName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            season,
            style: const TextStyle(fontSize: 10, color: Color(0xFF757575)),
          ),
          Text(
            timing,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 7: ASK KHETCHACHA AI (Interactive Voice & Text Q&A)
  // =========================================================================
  Widget _buildSection7AskKhetChacha(String langCode) {
    final quickQuestions = langCode == 'gu'
        ? [
            'મારે અત્યારે કયો પાક વાવવો જોઈએ?',
            'આવતા અઠવાડિયે વરસાદ આવશે?',
            'ચણામાં કેટલું ખાતર નાખવું?',
            'મારી નજીકની મંડીમાં શું ભાવ છે?',
          ]
        : (langCode == 'hi'
              ? [
                  'मुझे अभी कौन सी फसल बोनी चाहिए?',
                  'अगले हफ्ते बारिश होगी क्या?',
                  'चने में कितना खाद डालें?',
                  'निकटतम मंडी में क्या भाव है?',
                ]
              : [
                  'Which crop should I sow right now?',
                  'Will it rain next week?',
                  'How much fertilizer for gram?',
                  'What is the price in nearby mandi?',
                ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF1B5E20),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  langCode == 'gu'
                      ? 'ખેતચાચા ને પૂછો (Ask KhetChacha AI)'
                      : (langCode == 'hi'
                            ? 'खेतचाचा से पूछें (Ask KhetChacha AI)'
                            : 'Ask KhetChacha AI'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            langCode == 'gu'
                ? 'કોઈપણ પ્રશ્ન પસંદ કરો અથવા લખીને પૂછો:'
                : 'Tap any question below or type your question:',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
          ),

          const SizedBox(height: 10),

          // 4 Quick Question Chips (Section 10)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickQuestions.map((q) {
              return InkWell(
                onTap: () => _handleAskQuestion(q),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 13,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        q,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Question Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: langCode == 'gu'
                        ? 'ખેતીનો કોઈપણ પ્રશ્ન પૂછો...'
                        : 'Ask any farming question...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: _handleAskQuestion,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _handleAskQuestion(_questionController.text),
              ),
            ],
          ),

          // Live AI Response Card
          if (_aiAnswer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_askedQuestion != null) ...[
                    Text(
                      '${langCode == 'gu' ? 'પ્રશ્ન' : 'Question'}: "$_askedQuestion"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('👨‍🌾', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            langCode == 'gu'
                                ? 'ખેતચાચા નો ઉત્તર:'
                                : 'KhetChacha AI Answer:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: Color(0xFF1B5E20),
                        ),
                        onPressed: () {
                          CropAudioService.instance.speakText(
                            text: _aiAnswer!,
                            langCode: langCode,
                            id: 'qa_repeat',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _aiAnswer!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // COLLAPSIBLE ADVANCED AGRICULTURAL TOOLS & DETAILS
  // =========================================================================
  Widget _buildAdvancedToolsSection(String langCode) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showTechnicalDetails,
          onExpansionChanged: (val) =>
              setState(() => _showTechnicalDetails = val),
          title: Text(
            langCode == 'gu'
                ? 'વધુ કૃષિ સાધનો અને વિગતો'
                : (langCode == 'hi'
                      ? 'उन्नत कृषि उपकरण एवं विवरण'
                      : 'Advanced Tools & Soil Profile'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: Color(0xFF616161),
            ),
          ),
          leading: const Icon(
            Icons.build_circle_outlined,
            color: Color(0xFF1B5E20),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildToolTile(
                    icon: Icons.science_outlined,
                    title: langCode == 'gu'
                        ? 'જમીન વિશ્લેષણ અને સોઇલ હેલ્થ કાર્ડ'
                        : 'Soil Health Card & N-P-K Report',
                    subtitle: langCode == 'gu'
                        ? 'જમીન પ્રકાર, pH, નાઇટ્રોજન, ફોસ્ફરસ, પોટાશ'
                        : 'Lab test pH, Nitrogen, Phosphorus & Micronutrients',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SmartSoilProfilePage(profile: _profile),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 12),
                  _buildToolTile(
                    icon: Icons.calculate_outlined,
                    title: 'Smart Crop Profit & Cost Calculator',
                    subtitle: langCode == 'gu'
                        ? 'બિયારણ, ખાતર, મજૂરી અને નફાનું વિગતવાર ગણતરી'
                        : 'Detailed seed, fertilizer, and net profit simulator',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SmartCropProfitCalculatorPage(profile: _profile),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 12),
                  _buildToolTile(
                    icon: Icons.calendar_view_month_outlined,
                    title: 'Three Seasonal Crop Planners',
                    subtitle: langCode == 'gu'
                        ? 'ચોમાસુ (Kharif), શિયાળુ (Rabi), ઉનાળુ (Zaid) આયોજન'
                        : 'Kharif, Rabi, and Zaid seasonal planners',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SeasonalPlanningPage(profile: _profile),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 12),
                  _buildToolTile(
                    icon: Icons.view_list_rounded,
                    title: 'TOP 5 AI CROP RECOMMENDATIONS',
                    subtitle: langCode == 'gu'
                        ? 'તમારા વિસ્તારના ટોચના 5 પાકોની યાદી'
                        : 'Full regional ranking of all top 5 crops',
                    onTap: () {
                      setState(() {
                        _showAlternativeCrops = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // AGRICULTURAL DISCLAIMER
  // =========================================================================
  Widget _buildDisclaimerCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF616161)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              langCode == 'gu'
                  ? 'કૃષિ સલાહ સૂચના: ભલામણો અને નાણાકીય અંદાજો ICAR, KVK અને સરકારી કૃષિ યુનિવર્સિટીના માર્ગદર્શન મુજબ નિર્ણય લેવામાં મદદ કરવા માટે છે. વાસ્તવિક ઉત્પાદન અને બજાર ભાવ હવામાન અને ખેતી વ્યવસ્થાપન પર આધારિત છે.'
                  : 'Agricultural Advisory Notice: Recommendations and financial estimates are decision-support guidelines based on ICAR, KVK, and APMC historical trends. Actual yields and profits depend on local weather, farm management, and live market dynamics.',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF616161),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
