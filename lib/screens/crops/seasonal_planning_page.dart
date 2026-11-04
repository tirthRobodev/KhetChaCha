import 'package:flutter/material.dart';

import '../../models/crop_recommendation.dart';
import '../../models/farmer_profile.dart';
import '../../services/crop_recommendation_service.dart';
import '../../services/language_service.dart';
import 'crop_recommendation_details_page.dart';

/// Three Seasonal Crop Planning Screen for Kharif (Monsoon), Rabi (Winter), and Zaid (Summer).
class SeasonalPlanningPage extends StatefulWidget {
  final FarmerProfile profile;
  final String initialSeason;

  const SeasonalPlanningPage({
    super.key,
    required this.profile,
    this.initialSeason = 'Kharif',
  });

  @override
  State<SeasonalPlanningPage> createState() => _SeasonalPlanningPageState();
}

class _SeasonalPlanningPageState extends State<SeasonalPlanningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

  @override
  void initState() {
    super.initState();
    int initialIdx = _seasons.indexOf(widget.initialSeason);
    if (initialIdx < 0) initialIdx = 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIdx,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'મોસમી પાક આયોજન'
              : (langCode == 'hi'
                    ? 'मौसमी फसल योजना'
                    : 'Three Seasonal Crop Planning'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD54F),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              text: langCode == 'gu'
                  ? 'ચોમાસુ (ખરીફ)'
                  : (langCode == 'hi' ? 'खरीफ (मानसून)' : 'Kharif (Monsoon)'),
              icon: const Text('🌧️', style: TextStyle(fontSize: 16)),
            ),
            Tab(
              text: langCode == 'gu'
                  ? 'શિયાળુ (રવિ)'
                  : (langCode == 'hi' ? 'रबी (शीतकालीन)' : 'Rabi (Winter)'),
              icon: const Text('❄️', style: TextStyle(fontSize: 16)),
            ),
            Tab(
              text: langCode == 'gu'
                  ? 'ઉનાળુ (જાયદ)'
                  : (langCode == 'hi' ? 'जायद (ग्रीष्म)' : 'Zaid (Summer)'),
              icon: const Text('☀️', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeasonView('Kharif', langCode),
          _buildSeasonView('Rabi', langCode),
          _buildSeasonView('Zaid', langCode),
        ],
      ),
    );
  }

  Widget _buildSeasonView(String season, String langCode) {
    final crops = CropRecommendationService.instance.getRecommendations(
      widget.profile,
      targetSeason: season,
    );

    String calendarWindow;
    String climateAdvisory;
    Color themeColor;

    if (season == 'Kharif') {
      calendarWindow = 'June to October (Monsoon onset)';
      climateAdvisory = 'Monsoon rainfall patterns, waterlogging drainage, and soil moisture retention are evaluated for optimal seedling emergence.';
      themeColor = const Color(0xFF1B5E20);
    } else if (season == 'Rabi') {
      calendarWindow = 'October to March (Winter)';
      climateAdvisory = 'Cool nighttime temperatures, dew availability, and supplementary irrigation scheduling ensure maximum grain filling and tillering.';
      themeColor = const Color(0xFF0D47A1);
    } else {
      calendarWindow = 'March to June (Summer)';
      climateAdvisory = 'Short-duration (60-80 day) crops resilient against extreme midday heat and moisture stress with assured irrigation.';
      themeColor = const Color(0xFFE65100);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Season Header Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$season Cropping Window',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: themeColor,
                    ),
                  ),
                  Text(
                    calendarWindow,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                climateAdvisory,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'TOP RECOMMENDED CROPS FOR $season.toUpperCase()',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF757575),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 10),

        if (crops.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text('No specific crops recorded for this season.'),
            ),
          )
        else
          ...crops.map((crop) => _buildCropCard(crop, langCode, themeColor)),
      ],
    );
  }

  Widget _buildCropCard(
    CropRecommendation crop,
    String langCode,
    Color themeColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  profile: widget.profile,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        crop.iconEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${crop.suitabilityScore}% Match',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${crop.expectedDuration} • ${crop.waterRequirement}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                            ),
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
                    _buildMetricCol(
                      'Est. Cost',
                      '₹${(crop.totalCostPerAcre / 1000).toStringAsFixed(0)}k/ac',
                    ),
                    _buildMetricCol(
                      'Expected Yield',
                      '${crop.expectedYieldQuintalsPerAcre.toStringAsFixed(0)} Q/ac',
                    ),
                    _buildMetricCol(
                      'Selling Price',
                      '₹${crop.mandiSellingPricePerQuintal.toStringAsFixed(0)}/Q',
                    ),
                    _buildMetricCol(
                      'Est. Net Profit',
                      '₹${(crop.netProfitPerAcre / 1000).toStringAsFixed(0)}k/ac',
                      isHighlight: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? const Color(0xFF1B5E20)
                : const Color(0xFF212121),
          ),
        ),
      ],
    );
  }
}
