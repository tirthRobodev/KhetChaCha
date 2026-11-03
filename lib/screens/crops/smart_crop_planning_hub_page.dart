import 'package:flutter/material.dart';

import '../../models/annual_crop_plan.dart';
import '../../models/crop_recommendation.dart';
import '../../models/farm_plot.dart';
import '../../models/farmer_profile.dart';
import '../../models/soil_profile.dart';
import '../../services/annual_crop_planner_service.dart';
import '../../services/crop_audio_service.dart';
import '../../services/crop_recommendation_service.dart';
import '../../services/farm_profile_service.dart';
import '../../services/language_service.dart';
import '../../services/mandi_discovery_service.dart';
import '../../services/soil_analysis_service.dart';
import '../../services/weather_service.dart';
import '../calculators/smart_crop_profit_calculator_page.dart';
import '../mandi/mandi_comparison_page.dart';
import '../mandi/mandi_discovery_page.dart';
import '../soil/smart_soil_profile_page.dart';
import 'annual_farm_planner_page.dart';
import 'crop_recommendation_details_page.dart';
import 'seasonal_planning_page.dart';

/// Complete Smart AI Crop Planning & Annual Farm Management Hub.
/// Integrates all 10 core agricultural modules:
/// 1. My Farm & Plot Overview
/// 2. Location & Soil Profile
/// 3. Top 5 AI Crop Recommendations
/// 4. Kharif Planning (Monsoon)
/// 5. Rabi Planning (Winter)
/// 6. Zaid Planning (Summer)
/// 7. Nearby Mandi Prices & Net Freight Discovery
/// 8. Location-Aware Weather Forecast & Advisories
/// 9. Crop Profit Calculator (Per Acre & Per Farm)
/// 10. Annual Two-Crop Rotation Planner
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
  AnnualCropPlan? _primaryAnnualPlan;
  List<FarmPlot> _plots = [];
  bool _isLoading = true;
  bool _isSpeaking = false;

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
    _isLoading = false;
    _loadAllHubData();
  }

  Future<void> _loadAllHubData() async {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    // 1. Load Soil Profile
    final soil = await SoilAnalysisService.instance.getSoilProfile(
      farmerUidOrPhone: _profile.mobileNumber,
      state: _profile.effectiveState,
      district: _profile.effectiveDistrict,
      preferredType: SoilTypeExtension.fromString(_profile.soilType),
    );

    // 2. Load Weather
    final weather = await WeatherService.instance.getLiveWeather(
      district: _profile.effectiveDistrict,
      state: _profile.effectiveState,
      latitude: _profile.latitude,
      longitude: _profile.longitude,
      langCode: langCode,
    );

    // 3. Load Farm Plots
    final plots = await FarmProfileService.instance.getFarmPlots(_profile.mobileNumber);

    // 4. Compute Top 5 AI Recommendations
    final top5 = CropRecommendationService.instance.getTop5Recommendations(
      _profile,
      soilProfile: soil,
      weather: weather,
    );

    // 5. Generate Annual Two-Crop Rotation Plan
    final plans = AnnualCropPlannerService.instance.generateAnnualPlans(
      _profile,
      plot: plots.isNotEmpty ? plots.first : null,
      soilProfile: soil,
    );

    if (mounted) {
      setState(() {
        _soilProfile = soil;
        _weatherReport = weather;
        _plots = plots;
        _top5Crops = top5;
        _primaryAnnualPlan = plans.isNotEmpty ? plans.first : null;
        _isLoading = false;
      });
    }
  }

  void _speakAdvisory() {
    if (_top5Crops.isEmpty) return;
    final topCrop = _top5Crops.first;
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    String text;
    if (langCode == 'gu') {
      text = 'નમસ્તે ${_profile.fullName}! તમારા ${_profile.effectiveDistrict} ખેતર માટે સૌથી અનુકૂળ પાક ${topCrop.nativeName ?? topCrop.englishName} છે. અંદાજિત નફો એકરે ${(topCrop.netProfitPerAcre / 1000).toStringAsFixed(0)} હજાર રૂપિયા છે.';
    } else if (langCode == 'hi') {
      text = 'नमस्ते ${_profile.fullName}! आपके ${_profile.effectiveDistrict} खेत के लिए सबसे उपयुक्त फसल ${topCrop.englishName} है। अनुमानित लाभ ${(topCrop.netProfitPerAcre / 1000).toStringAsFixed(0)} हजार रुपये प्रति एकड़ है।';
    } else {
      text = 'Namaste ${_profile.fullName}! For your farm in ${_profile.effectiveDistrict}, the top recommended crop is ${topCrop.englishName} with an estimated net return of ${(topCrop.netProfitPerAcre / 1000).toStringAsFixed(0)} thousand rupees per acre.';
    }

    CropAudioService.instance.speakText(
      text: text,
      langCode: langCode,
      id: topCrop.cropId,
    );

    setState(() => _isSpeaking = true);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'સ્માર્ટ AI પાક અને ફાર્મ પ્લાનિંગ'
              : (langCode == 'hi'
                  ? 'स्मार्ट AI फसल एवं वार्षिक योजना'
                  : 'Smart AI Crop & Farm Planning'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              color: const Color(0xFFFFD54F),
            ),
            tooltip: 'Audio Summary',
            onPressed: _speakAdvisory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllHubData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : RefreshIndicator(
              color: const Color(0xFF1B5E20),
              onRefresh: _loadAllHubData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Hero Namaste Farmer Card
                    _buildHeroFarmerCard(langCode),

                    const SizedBox(height: 16),

                    // 2. Section 1 & 2: My Farm & Soil Profile Summary Card
                    _buildFarmAndSoilCard(langCode),

                    const SizedBox(height: 16),

                    // 3. Section 3: Top 5 AI Crop Recommendations
                    _buildTop5RecommendationsCard(langCode),

                    const SizedBox(height: 16),

                    // 4. Section 4, 5, 6: Three Seasonal Planners (Kharif, Rabi, Zaid)
                    _buildSeasonalPlanningSection(langCode),

                    const SizedBox(height: 16),

                    // 5. Section 7: Nearby Mandi Prices & Best Market
                    _buildNearbyMandiSnapshot(langCode),

                    const SizedBox(height: 16),

                    // 6. Section 8: Live Weather Forecast & Agricultural Advisory
                    _buildWeatherForecastSection(langCode),

                    const SizedBox(height: 16),

                    // 7. Section 9: Smart Crop Profit Calculator Shortcut
                    _buildProfitCalculatorShortcut(langCode),

                    const SizedBox(height: 16),

                    // 8. Section 10: Two-Crop Annual Farm Planner
                    _buildAnnualPlannerSection(langCode),

                    const SizedBox(height: 24),

                    // Agricultural Disclaimer
                    _buildDisclaimerCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroFarmerCard(String langCode) {
    final season = _profile.farmingSeason.isNotEmpty ? _profile.farmingSeason : 'Kharif';
    final district = _profile.effectiveDistrict.isNotEmpty ? _profile.effectiveDistrict : 'Amreli';
    final state = _profile.effectiveState.isNotEmpty ? _profile.effectiveState : 'Gujarat';

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
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langCode == 'gu' ? 'નમસ્તે ખેડૂત મિત્ર!' : (langCode == 'hi' ? 'नमस्ते किसान भाई!' : 'Namaste Farmer!'),
                style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Season: $season',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _profile.fullName.isNotEmpty ? _profile.fullName : 'KhetChacha Farmer',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '📍 $district, $state • Land: ${_profile.effectiveFarmSize} ${_profile.landUnit}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soil: ${_soilProfile?.soilType.getLocalizedName(langCode) ?? "Black Soil"}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Water: ${_profile.waterAvailability} (${_profile.irrigationType})',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmAndSoilCard(String langCode) {
    final soil = _soilProfile ?? const SoilProfile();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  const Icon(Icons.terrain_rounded, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Text(
                    langCode == 'gu' ? 'જમીન વિશ્લેષણ અને પ્લોટ' : 'Farm Soil & Plot Profile',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final updated = await Navigator.of(context).push<SoilProfile>(
                    MaterialPageRoute(
                      builder: (_) => SmartSoilProfilePage(
                        profile: _profile,
                        initialSoilProfile: _soilProfile,
                      ),
                    ),
                  );
                  if (updated != null) {
                    _loadAllHubData();
                  }
                },
                child: const Text('Edit / Soil Test', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSoilBadge('Soil pH', soil.pH.toStringAsFixed(1), soil.pH < 6.5 ? Colors.orange : const Color(0xFF2E7D32)),
              _buildSoilBadge('Nitrogen (N)', '${soil.nitrogenKgPerHa.toStringAsFixed(0)} kg', Colors.blue.shade700),
              _buildSoilBadge('Phosphorus (P)', '${soil.phosphorusKgPerHa.toStringAsFixed(1)} kg', Colors.teal.shade700),
              _buildSoilBadge('Potassium (K)', '${soil.potassiumKgPerHa.toStringAsFixed(0)} kg', Colors.purple.shade700),
              _buildSoilBadge('Health Score', '${soil.soilHealthScore}/100', const Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: soil.isLabVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  soil.isLabVerified ? Icons.verified_rounded : Icons.info_outline,
                  size: 14,
                  color: soil.isLabVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    soil.isLabVerified
                        ? 'Lab Tested • Report #${soil.labReportNumber}'
                        : 'ICAR Regional Estimated Benchmark for ${_profile.effectiveDistrict}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: soil.isLabVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_plots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Registered Farm Plots: ${_plots.length} (${_plots.map((p) => "${p.name} (${p.sizeInAcres.toStringAsFixed(1)} Ac)").join(", ")})',
              style: const TextStyle(fontSize: 11, color: Color(0xFF616161), fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoilBadge(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
      ],
    );
  }

  Widget _buildTop5RecommendationsCard(String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB300)),
                SizedBox(width: 8),
                Text(
                  'TOP 5 AI CROP RECOMMENDATIONS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                ),
              ],
            ),
            Text(
              'Location-Aware',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._top5Crops.map((crop) => _buildTop5CropItem(crop, langCode)),
      ],
    );
  }

  Widget _buildTop5CropItem(CropRecommendation crop, String langCode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CropRecommendationDetailsPage(
                  recommendation: crop,
                  profile: _profile,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(crop.iconEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                crop.englishName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${crop.suitabilityScore}% Match',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sow: ${crop.bestSowingPeriod} • Harvest: ${crop.expectedHarvestPeriod}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricText('Cost/Ac', '₹${(crop.totalCostPerAcre / 1000).toStringAsFixed(0)}k'),
                    _buildMetricText('Mandi Rate', '₹${crop.mandiSellingPricePerQuintal.toStringAsFixed(0)}/Q'),
                    _buildMetricText('Yield', '${crop.expectedYieldQuintalsPerAcre.toStringAsFixed(0)} Q/Ac'),
                    _buildMetricText('Net Profit', '₹${(crop.netProfitPerAcre / 1000).toStringAsFixed(0)}k/Ac', isHighlight: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  crop.recommendationReason,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF616161), height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricText(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF1B5E20) : const Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonalPlanningSection(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Color(0xFFFF9800)),
              SizedBox(width: 8),
              Text(
                'Three Seasonal Crop Planners',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSeasonButton('Kharif', 'Monsoon', '🌧️', const Color(0xFF1B5E20))),
              const SizedBox(width: 8),
              Expanded(child: _buildSeasonButton('Rabi', 'Winter', '❄️', const Color(0xFF0D47A1))),
              const SizedBox(width: 8),
              Expanded(child: _buildSeasonButton('Zaid', 'Summer', '☀️', const Color(0xFFE65100))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonButton(String season, String subtitle, String icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SeasonalPlanningPage(
              profile: _profile,
              initialSeason: season,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(season, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyMandiSnapshot(String langCode) {
    final lat = _profile.latitude ?? 21.6032;
    final lon = _profile.longitude ?? 71.2221;
    final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: lat,
      longitude: lon,
      maxDistanceKm: 80,
    );

    final firstMarket = nearby.isNotEmpty ? nearby.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text(
                    'Nearby Verified Mandis (e-NAM / APMC)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                child: const Text('View All', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (firstMarket != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstMarket.market.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${firstMarket.distanceKm.toStringAsFixed(1)} km away • ${firstMarket.market.state}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MandiComparisonPage(
                            profile: _profile,
                            initialCommodity: 'Groundnut',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Compare', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherForecastSection(String langCode) {
    final w = _weatherReport;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: Color(0xFF0288D1)),
                  SizedBox(width: 8),
                  Text(
                    'Live Agro-Weather Intelligence',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Open-Meteo Live',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (w != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMini('${w.temperature.toStringAsFixed(1)}°C', 'Temp', Icons.thermostat_rounded),
                _buildWeatherMini('${w.humidity}%', 'Humidity', Icons.water_drop_rounded),
                _buildWeatherMini('${w.windSpeed.toStringAsFixed(0)} km/h', 'Wind', Icons.air_rounded),
                _buildWeatherMini(w.conditionName, 'Condition', Icons.wb_sunny_rounded),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFF59D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📢 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      w.advisory,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
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

  Widget _buildWeatherMini(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0288D1)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
      ],
    );
  }

  Widget _buildProfitCalculatorShortcut(String langCode) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SmartCropProfitCalculatorPage(profile: _profile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.calculate_rounded, color: Color(0xFF1B5E20)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Crop Profit & Cost Calculator',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Simulate Seeds, Fertilizer, Labour, & Net Margin',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualPlannerSection(String langCode) {
    final plan = _primaryAnnualPlan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Row(
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFF1B5E20)),
                  SizedBox(width: 8),
                  Text(
                    'Two-Crop Annual Farm Planner',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnnualFarmPlannerPage(profile: _profile),
                    ),
                  );
                },
                child: const Text('Full Plan', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('${plan.firstCrop.iconEmoji} ➝ ${plan.secondCrop.iconEmoji}', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.firstCrop.englishName} (Kharif) + ${plan.secondCrop.englishName} (Rabi)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Rotation Score: ${plan.rotationCompatibilityScore}% • Est. Annual Net: ₹${(plan.totalAnnualNetProfitPerAcre / 1000).toStringAsFixed(0)}k/ac',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ],
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

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF616161)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Agricultural Advisory Notice: Recommendations and financial estimates are decision-support guidelines based on ICAR, KVK, and APMC historical trends. Actual yields and profits depend on local weather, farm management, and live market dynamics.',
              style: TextStyle(fontSize: 10, color: Color(0xFF616161), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
