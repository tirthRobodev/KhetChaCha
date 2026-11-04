import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../localization/crop_master_database.dart';
import '../localization/language_data.dart';
import '../models/farmer_profile.dart';
import '../services/auth_service.dart';
import '../services/farm_profile_service.dart';
import '../services/farming_recommendation_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/weather_service.dart';
import '../widgets/farmer_avatar.dart';
import '../widgets/khetchacha_logo.dart';
import 'ai/image_ai_diagnosis_page.dart';
import 'ai/voice_assistant_page.dart';
import 'calculators/calculator_dashboard_page.dart';
import 'calculators/fertilizer_calculator_page.dart';
import 'crops/crop_management_page.dart';
import 'expert/ask_expert_page.dart';
import 'farm_production_selection_page.dart';
import 'marketplace/natural_farming_marketplace_page.dart';
import 'notifications_page.dart';
import 'phone_login_page.dart';
import 'quick_access/ask_khet_chacha_ai_page.dart';
import 'quick_access/crop_advisory_page.dart';
import 'quick_access/crop_calendar_page.dart';
import 'quick_access/detailed_weather_page.dart';
import 'quick_access/mandi_rates_page.dart';
import 'quick_access/pest_disease_page.dart';
import 'quick_access/seed_variety_page.dart';
import 'quick_access/sell_products_page.dart';
import 'quick_access/soil_health_page.dart';
import 'schemes/govt_schemes_directory_page.dart';
import '../models/crop_recommendation.dart';
import '../models/mandi_market.dart';
import '../services/crop_recommendation_service.dart';
import '../services/location_service.dart';
import '../services/mandi_discovery_service.dart';
import 'crops/crop_recommendation_details_page.dart';
import 'crops/annual_farm_planner_page.dart';
import 'crops/seasonal_planning_page.dart';
import 'crops/smart_crop_planning_hub_page.dart';
import 'calculators/smart_crop_profit_calculator_page.dart';
import 'soil/smart_soil_profile_page.dart';
import 'mandi/mandi_comparison_page.dart';
import 'mandi/mandi_discovery_page.dart';
import 'onboarding/smart_location_detection_page.dart';
import 'news/government_news_directory_page.dart';

/// Advanced Personalized Farmer Dashboard Screen for KhetChaCha.
/// Matches the reference design with state-specific farmer avatar,
/// live weather card & rain advisory, 12 quick access cards,
/// My Farm Overview, and bottom navigation bar.
class FarmerDashboardPage extends StatefulWidget {
  final FarmerProfile profile;

  const FarmerDashboardPage({super.key, required this.profile});

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> {
  late FarmerProfile _profile;
  FarmWeatherReport? _weatherReport;
  bool _isLoadingWeather = true;
  int _currentNavIndex = 0;
  RecommendationTier _selectedRecTier = RecommendationTier.bestSuitable;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    NotificationService.instance.init();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;
    final report = await WeatherService.instance.getLiveWeather(
      district: _profile.effectiveDistrict,
      state: _profile.effectiveState,
      latitude: _profile.latitude,
      longitude: _profile.longitude,
      langCode: langCode,
    );

    if (!mounted) return;
    setState(() {
      _weatherReport = report;
      _isLoadingWeather = false;
    });
  }

  void _openManageFarm() async {
    final updated = await Navigator.of(context).push<FarmerProfile>(
      MaterialPageRoute(
        builder: (_) =>
            FarmProductionSelectionPage(profile: _profile, isEditMode: true),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _profile = updated;
      });
      _fetchWeather();
    }
  }

  void _openLanguagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select App Language / ભાષા પસંદ કરો',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageData.allLanguages.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final lang = LanguageData.allLanguages[i];
                    final isCurrent =
                        LanguageService.instance.currentLanguage.code ==
                        lang.code;

                    return ListTile(
                      title: Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF212121),
                        ),
                      ),
                      subtitle: Text(lang.englishName),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32),
                            )
                          : null,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await LanguageService.instance.setLanguage(lang);
                        final updated = _profile.copyWith(
                          selectedLanguage: lang.code,
                        );
                        await FarmProfileService.instance.saveFarmProfile(
                          updated,
                        );
                        if (!mounted) return;
                        setState(() {
                          _profile = updated;
                        });
                        _fetchWeather();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsPage(profile: _profile)),
    );
  }

  void _openProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            FarmerAvatar(state: _profile.effectiveState, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_profile.effectiveDistrict}, ${_profile.effectiveState}',
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 Mobile: ${_profile.mobileNumber}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (_profile.email.isNotEmpty)
              Text(
                '✉️ Email: ${_profile.email}',
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(height: 6),
            Text(
              '🌾 Selected Crops: ${_profile.effectiveProducts.join(', ')}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '📐 Land Size: ${_profile.effectiveFarmSize}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (_profile.firebaseUid != null) ...[
              const SizedBox(height: 6),
              Text(
                '🔑 UID: ${_profile.firebaseUid}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ],
            const Divider(height: 22),
            Center(child: KhetChachaLogo.full(height: 38)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.signOut();
              await FarmProfileService.instance.clearLocalProfile();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _openCustomizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Customize Dashboard'),
          ],
        ),
        content: const Text(
          'All 12 agricultural tools are currently enabled for quick access. You can prioritize specific tools based on your farming season.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.instance.currentLanguage;
    final langCode = activeLang.locale.languageCode;
    final loc = AppLocalizations.of(context);
    final seasonText = FarmingRecommendationService.instance.getCurrentSeason(
      langCode,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: KhetChachaLogo.appBar(height: 32),
        actions: [
          // Notification Bell with dynamic unread badge
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                ValueListenableBuilder<int>(
                  valueListenable:
                      NotificationService.instance.unreadCountNotifier,
                  builder: (context, count, _) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: _openNotifications,
          ),

          // Language Selector Pill (e.g. 🌐 English ▾)
          InkWell(
            onTap: _openLanguagePicker,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: Color(0xFFFFD54F),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeLang.nativeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Profile Circle Avatar
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _openProfileDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1B5E20),
          onRefresh: _fetchWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Welcome Card with State-Specific Farmer Avatar
                _buildWelcomeCard(loc, langCode),

                const SizedBox(height: 12),

                // 2. Farmer Location Card (Priority 2)
                _buildFarmingLocationCard(loc, langCode),

                const SizedBox(height: 16),

                // Smart AI Crop Planning & Annual Farm Management Hero Banner
                _buildSmartCropPlanningHeroBanner(loc, langCode),

                const SizedBox(height: 16),

                // 3. Personalized Crop Recommendations (Priority 4)
                _buildRecommendedCropsSection(loc, langCode),

                const SizedBox(height: 16),

                // 4. Location-Aware Weather Card (Priority 7)
                _buildLiveWeatherCard(loc, langCode),

                const SizedBox(height: 12),

                // 5. Rain Advisory Banner
                _buildRainAdvisoryStrip(loc),

                const SizedBox(height: 16),

                // 6. Nearby Mandi & Wholesale Markets (Priority 5 & 6)
                _buildNearbyMandiSnapshotCard(loc, langCode),

                const SizedBox(height: 20),

                // 7. Quick Access (Enhanced Shortcuts)
                _buildQuickAccessSection(loc, langCode),

                const SizedBox(height: 20),

                // 8. My Farm Overview
                _buildMyFarmOverviewSection(loc, langCode, seasonText),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // 6. Bottom Navigation Bar matching design reference
      bottomNavigationBar: _buildBottomNavigationBar(loc),
    );
  }

  /// Welcome Card matching the reference mockup
  Future<void> _refreshGpsLocation() async {
    final loc = await LocationService.instance.getCurrentLocation();
    if (loc != null && mounted) {
      final updated = _profile.copyWith(
        state: loc.state,
        district: loc.district,
        selectedState: loc.state,
        selectedDistrict: loc.district,
        village: loc.village.isNotEmpty ? loc.village : _profile.village,
        taluka: loc.taluka.isNotEmpty ? loc.taluka : _profile.taluka,
        pincode: loc.pincode.isNotEmpty ? loc.pincode : _profile.pincode,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      await FarmProfileService.instance.saveFarmProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
      });
      _fetchWeather();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated GPS Location: ${loc.shortSummary}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _openChangeLocation() async {
    final updated = await Navigator.of(context).push<FarmerProfile>(
      MaterialPageRoute(
        builder: (_) =>
            SmartLocationDetectionPage(profile: _profile, isEditMode: true),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _profile = updated;
      });
      _fetchWeather();
    }
  }

  /// 1. Farmer Location Card (Priority 2)
  String _formatCleanLocationComponent(String raw, String langCode) {
    if (raw.isEmpty) return '';
    final trimmed = raw.trim();
    final match = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(trimmed);
    if (match != null) {
      final part1 = match.group(1)!.trim();
      final part2 = match.group(2)!.trim();

      if (langCode == 'gu') {
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(part2)) return part2;
      } else if (langCode == 'hi' ||
          const [
            'mr',
            'mai',
            'kok',
            'ne',
            'doi',
            'sa',
            'brx',
          ].contains(langCode)) {
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0900-\u097F]').hasMatch(part2)) return part2;
      } else if (langCode == 'pa') {
        if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(part1)) return part1;
        if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(part2)) return part2;
      } else if (langCode == 'en') {
        if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(part1)) return part1;
        if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(part2)) return part2;
      }
      return part1.isNotEmpty ? part1 : trimmed;
    }
    return trimmed;
  }

  String _getLocalizedSoil(String soil, String langCode) {
    final clean = soil.toLowerCase();
    if (langCode == 'gu') {
      if (clean.contains('loam')) return 'ગોરાડુ જમીન';
      if (clean.contains('black') || clean.contains('regur')) {
        return 'કાળી જમીન';
      }
      if (clean.contains('alluvial')) return 'કાંપવાળી જમીન';
      if (clean.contains('sandy')) return 'રેતાળ જમીન';
      if (clean.contains('clay')) return 'ચીકણી જમીન';
      if (clean.contains('red')) return 'રાતી જમીન';
    } else if (langCode == 'hi') {
      if (clean.contains('loam')) return 'दोमट मिट्टी';
      if (clean.contains('black') || clean.contains('regur')) {
        return 'काली मिट्टी';
      }
      if (clean.contains('alluvial')) return 'जलोढ़ मिट्टी';
      if (clean.contains('sandy')) return 'बलुई मिट्टी';
      if (clean.contains('clay')) return 'चिकनी मिट्टी';
      if (clean.contains('red')) return 'लाल मिट्टी';
    } else if (langCode == 'pa') {
      if (clean.contains('loam')) return 'ਦੋਮਟ ਮਿੱਟੀ';
      if (clean.contains('black') || clean.contains('regur')) {
        return 'ਕਾਲੀ ਮਿੱਟੀ';
      }
      if (clean.contains('alluvial')) return 'ਜਲੋੜ ਮਿੱਟੀ';
      if (clean.contains('sandy')) return 'ਰੇਤਲੀ ਮਿੱਟੀ';
    }
    return soil;
  }

  String _getLocalizedWater(String water, String langCode) {
    final clean = water.toLowerCase();
    if (langCode == 'gu') {
      if (clean.contains('high') || clean.contains('ample')) {
        return 'વિપુલ પાણી';
      }
      if (clean.contains('medium')) return 'મધ્યમ પાણી';
      if (clean.contains('low') || clean.contains('scarce')) return 'ઓછું પાણી';
    } else if (langCode == 'hi') {
      if (clean.contains('high') || clean.contains('ample')) {
        return 'प्रचुर पानी';
      }
      if (clean.contains('medium')) return 'मध्यम पानी';
      if (clean.contains('low') || clean.contains('scarce')) return 'कम पानी';
    } else if (langCode == 'pa') {
      if (clean.contains('high') || clean.contains('ample')) return 'ਵੱਧ ਪਾਣੀ';
      if (clean.contains('medium')) return 'ਦਰਮਿਆਨਾ ਪਾਣੀ';
      if (clean.contains('low') || clean.contains('scarce')) return 'ਘੱਟ ਪਾਣੀ';
    }
    return '$water water';
  }

  String _getLocalizedRecommendationReason(
    CropRecommendation rec,
    String langCode,
  ) {
    final cleanDist = _formatCleanLocationComponent(
      _profile.effectiveDistrict,
      langCode,
    );
    final profitK = '₹${(rec.netProfitPerAcre / 1000).toStringAsFixed(1)}k';

    if (langCode == 'gu') {
      if (rec.suitabilityScore >= 85) {
        return '$cleanDist માટે શ્રેષ્ઠ પસંદગી (${rec.suitabilityScore}%). અંદાજિત નફો ~$profitK/એકર.${rec.isLegume ? ' જમીનની ફળદ્રુપતા વધારે છે.' : ''}';
      } else if (rec.suitabilityScore >= 70) {
        return '$cleanDist માટે ઉત્તમ વૈકલ્પિક પાક (${rec.suitabilityScore}%). અંદાજિત નફો ~$profitK/એકર.';
      } else {
        return 'મોસમી રોકડિયા પાકની તક (${rec.suitabilityScore}%). નફો ~$profitK/એકર.';
      }
    } else if (langCode == 'hi') {
      if (rec.suitabilityScore >= 85) {
        return '$cleanDist के लिए मुख्य फसल (${rec.suitabilityScore}%)। अनुमानित लाभ ~$profitK/एकड़।${rec.isLegume ? ' मिट्टी की उर्वरता बढ़ाती है।' : ''}';
      } else if (rec.suitabilityScore >= 70) {
        return '$cleanDist के लिए श्रेष्ठ विकल्प (${rec.suitabilityScore}%)। अनुमानित लाभ ~$profitK/एकड़।';
      } else {
        return 'मौसमी नकदी फसल विकल्प (${rec.suitabilityScore}%)। अनुमानित लाभ ~$profitK/एकड़।';
      }
    } else if (langCode == 'pa') {
      if (rec.suitabilityScore >= 85) {
        return '$cleanDist ਲਈ ਮੁੱਖ ਫ਼ਸਲ (${rec.suitabilityScore}%)। ਅੰਦਾਜ਼ਨ ਮੁਨਾਫਾ ~$profitK/ਏਕੜ।';
      } else {
        return '$cleanDist ਲਈ ਚੰਗਾ ਬਦਲ (${rec.suitabilityScore}%)। ਅੰਦਾਜ਼ਨ ਮੁਨਾਫਾ ~$profitK/ਏਕੜ।';
      }
    } else if (langCode == 'mr') {
      if (rec.suitabilityScore >= 85) {
        return '$cleanDist साठी मुख्य पीक (${rec.suitabilityScore}%)। अंदाजे नफा ~$profitK/एकर।';
      } else {
        return '$cleanDist साठी उत्तम पर्याय (${rec.suitabilityScore}%)। अंदाजे नफा ~$profitK/एकर।';
      }
    }

    return 'Prime recommendation (${rec.suitabilityScore}%) for $cleanDist. Est. net return ~$profitK/acre.${rec.isLegume ? ' Natural nitrogen fixer.' : ''}';
  }

  Widget _buildFarmingLocationCard(AppLocalizations loc, String langCode) {
    final state = _formatCleanLocationComponent(
      _profile.effectiveState,
      langCode,
    );
    final district = _formatCleanLocationComponent(
      _profile.effectiveDistrict,
      langCode,
    );
    final taluka = _profile.taluka.isNotEmpty
        ? _formatCleanLocationComponent(_profile.taluka, langCode)
        : (_profile.village.isNotEmpty
              ? _formatCleanLocationComponent(_profile.village, langCode)
              : '');
    final locationText = taluka.isNotEmpty && taluka != district
        ? '$state • $district • $taluka'
        : (state.isNotEmpty && district.isNotEmpty
              ? '$state • $district'
              : (state.isNotEmpty ? state : district));

    final locationTitle = langCode == 'gu'
        ? 'તમારું ખેતીનું સ્થળ'
        : (langCode == 'hi'
              ? 'आपका कृषि स्थान'
              : (langCode == 'pa'
                    ? 'ਤੁਹਾਡਾ ਖੇਤੀ ਸਥਾਨ'
                    : (langCode == 'mr'
                          ? 'तुमचे शेतीचे ठिकाण'
                          : 'Your Farming Location')));

    final changeLabel = langCode == 'gu'
        ? 'બદલો'
        : (langCode == 'hi'
              ? 'बदलें'
              : (langCode == 'pa'
                    ? 'ਬਦਲੋ'
                    : (langCode == 'mr' ? 'बदला' : 'Change')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF757575),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _openChangeLocation,
            child: Text(
              changeLabel,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Refresh GPS',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF2E7D32),
              size: 20,
            ),
            onPressed: _refreshGpsLocation,
          ),
        ],
      ),
    );
  }

  /// Master Smart AI Crop Planning & Annual Farm Management Hero Banner
  Widget _buildSmartCropPlanningHeroBanner(
    AppLocalizations loc,
    String langCode,
  ) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD54F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'gu'
                          ? 'સ્માર્ટ AI પાક અને ફાર્મ પ્લાનિંગ'
                          : (langCode == 'hi'
                                ? 'स्मार्ट AI फसल एवं फार्म प्लानिंग'
                                : 'Smart AI Crop & Farm Planning'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      langCode == 'gu'
                          ? 'દ્વિ-પાક ખરીફ/રવિ ચક્ર • ટોચના 5 પાક • નફા ગણતરી'
                          : (langCode == 'hi'
                                ? 'दो-फसल खरीफ/रबी चक्र • शीर्ष 5 फसलें • लाभ गणना'
                                : 'Two-crop Kharif/Rabi cycle • Top 5 AI crops • Profit simulation'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SmartCropPlanningHubPage(profile: _profile),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: const Color(0xFF1B5E20),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  langCode == 'gu'
                      ? 'હબ ખોલો'
                      : (langCode == 'hi' ? 'हब खोलें' : 'Open Hub'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPlanningQuickChip(
                  icon: Icons.sync_rounded,
                  label: langCode == 'gu'
                      ? 'વાર્ષિક દ્વિ-પાક'
                      : 'Annual 2-Crop Planner',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AnnualFarmPlannerPage(profile: _profile),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildPlanningQuickChip(
                  icon: Icons.terrain_rounded,
                  label: langCode == 'gu'
                      ? 'જમીન વિશ્લેષણ'
                      : 'Soil Profile & NPK',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SmartSoilProfilePage(profile: _profile),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildPlanningQuickChip(
                  icon: Icons.calculate_rounded,
                  label: langCode == 'gu'
                      ? 'નફા કેલ્ક્યુલેટર'
                      : 'Profit Calculator',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SmartCropProfitCalculatorPage(profile: _profile),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildPlanningQuickChip(
                  icon: Icons.calendar_month_rounded,
                  label: langCode == 'gu' ? 'મોસમી આયોજન' : 'Seasonal Planning',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeasonalPlanningPage(profile: _profile),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningQuickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Personalized Crop Recommendations (Priority 4)
  Widget _buildRecommendedCropsSection(AppLocalizations loc, String langCode) {
    final tiered = CropRecommendationService.instance.getTieredRecommendations(
      _profile,
    );
    final currentList = tiered[_selectedRecTier] ?? [];

    final sectionTitle = langCode == 'gu'
        ? 'તમારા ખેતર માટે ભલામણ કરેલ પાક'
        : (langCode == 'hi'
              ? 'आपके खेत के लिए अनुशंसित फसलें'
              : (langCode == 'pa'
                    ? 'ਤੁਹਾਡੇ ਖੇਤ ਲਈ ਸਿਫਾਰਸ਼ ਕੀਤੀਆਂ ਫ਼ਸਲਾਂ'
                    : (langCode == 'mr'
                          ? 'तुमच्या शेतासाठी शिफारस केलेली पिके'
                          : 'Recommended Crops for Your Farm')));

    final cleanDist = _formatCleanLocationComponent(
      _profile.effectiveDistrict,
      langCode,
    );
    final cleanSoil = _getLocalizedSoil(_profile.soilType, langCode);
    final cleanWater = _getLocalizedWater(_profile.waterAvailability, langCode);
    final subtitle = langCode == 'gu'
        ? '$cleanDist • $cleanSoil • $cleanWater અનુસાર'
        : (langCode == 'hi'
              ? '$cleanDist • $cleanSoil • $cleanWater के अनुसार'
              : (langCode == 'pa'
                    ? '$cleanDist • $cleanSoil • $cleanWater ਅਨੁਸਾਰ'
                    : 'Matched to $cleanDist • $cleanSoil • $cleanWater'));

    final aiHubLabel = langCode == 'gu'
        ? 'AI હબ'
        : (langCode == 'hi' ? 'AI हब' : 'AI Hub');
    final changeCropsLabel = langCode == 'gu'
        ? 'પાક બદલો'
        : (langCode == 'hi'
              ? 'फसलें बदलें'
              : (langCode == 'pa'
                    ? 'ਫ਼ਸਲਾਂ ਬਦਲੋ'
                    : (langCode == 'mr' ? 'पिके बदला' : 'Change Crops')));

    final bestSuitableLabel = langCode == 'gu'
        ? '★ શ્રેષ્ઠ અનુકૂળ'
        : (langCode == 'hi'
              ? '★ सर्वश्रेष्ठ उपयुक्त'
              : (langCode == 'pa'
                    ? '★ ਸਭ ਤੋਂ ਢੁਕਵੀਂ'
                    : (langCode == 'mr'
                          ? '★ सर्वोत्तम योग्य'
                          : '★ Best Suitable')));

    final altCropsLabel = langCode == 'gu'
        ? 'વૈકલ્પિક પાક'
        : (langCode == 'hi'
              ? 'वैकल्पिक फसलें'
              : (langCode == 'pa'
                    ? 'ਬਦਲਵੀਆਂ ਫ਼ਸਲਾਂ'
                    : (langCode == 'mr'
                          ? 'पर्यायी पिके'
                          : 'Alternative Crops')));

    final seasonalLabel = langCode == 'gu'
        ? 'મોસમી તકો'
        : (langCode == 'hi'
              ? 'मौसमी अवसर'
              : (langCode == 'pa'
                    ? 'ਮੌਸਮੀ ਮੌਕੇ'
                    : (langCode == 'mr'
                          ? 'हंगामी संधी'
                          : 'Seasonal Opportunities')));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.recommend_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SmartCropPlanningHubPage(profile: _profile),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: Color(0xFF1B5E20),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        aiHubLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _openManageFarm,
                child: Text(
                  changeCropsLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRecTabButton(
                  RecommendationTier.bestSuitable,
                  bestSuitableLabel,
                  langCode,
                ),
                const SizedBox(width: 6),
                _buildRecTabButton(
                  RecommendationTier.alternative,
                  altCropsLabel,
                  langCode,
                ),
                const SizedBox(width: 6),
                _buildRecTabButton(
                  RecommendationTier.seasonalOpportunity,
                  seasonalLabel,
                  langCode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (currentList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  langCode == 'gu'
                      ? 'આ શ્રેણી માટે કોઈ ભલામણ નથી.'
                      : (langCode == 'hi'
                            ? 'इस श्रेणी के लिए कोई अनुशंसा नहीं मिली।'
                            : 'No recommendations found for this tier.'),
                  style: const TextStyle(color: Color(0xFF757575)),
                ),
              ),
            )
          else
            SizedBox(
              height: 248,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentList.length,
                itemBuilder: (ctx, idx) =>
                    _buildCropRecCard(currentList[idx], langCode),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecTabButton(
    RecommendationTier tier,
    String label,
    String langCode,
  ) {
    final isSel = _selectedRecTier == tier;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFFE8F5E9),
      backgroundColor: const Color(0xFFF5F5F5),
      side: BorderSide(
        color: isSel ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
      ),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? const Color(0xFF1B5E20) : const Color(0xFF616161),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedRecTier = tier);
      },
    );
  }

  Widget _buildCropRecCard(CropRecommendation rec, String langCode) {
    final isSaved = _profile.effectiveProducts.contains(rec.englishName);
    final cropMaster = CropMasterDatabase.findCropByName(rec.englishName);
    final cropDisplayName = (cropMaster != null && langCode != 'en')
        ? cropMaster.getLocalizedName(langCode)
        : rec.englishName;

    final yieldLabel = langCode == 'gu'
        ? 'ઉત્પાદન:'
        : (langCode == 'hi'
              ? 'पैदावार:'
              : (langCode == 'pa'
                    ? 'ਝਾੜ:'
                    : (langCode == 'mr' ? 'उत्पादन:' : 'Yield:')));

    final rateLabel = langCode == 'gu'
        ? 'ભાવ:'
        : (langCode == 'hi'
              ? 'भाव:'
              : (langCode == 'pa'
                    ? 'ਭਾਅ:'
                    : (langCode == 'mr' ? 'दर:' : 'Rate:')));

    final detailsLabel = langCode == 'gu'
        ? 'વિગત'
        : (langCode == 'hi'
              ? 'विवरण'
              : (langCode == 'pa'
                    ? 'ਵੇਰਵੇ'
                    : (langCode == 'mr' ? 'तपशील' : 'Details')));

    final saveLabel = isSaved
        ? (langCode == 'gu'
              ? 'સાચવેલ'
              : (langCode == 'hi'
                    ? 'सहेजा गया'
                    : (langCode == 'pa'
                          ? 'ਸੰਭਾਲਿਆ'
                          : (langCode == 'mr' ? 'जतन केले' : 'Saved'))))
        : (langCode == 'gu'
              ? 'સાચવો'
              : (langCode == 'hi'
                    ? 'सहेजें'
                    : (langCode == 'pa'
                          ? 'ਸੰਭਾਲੋ'
                          : (langCode == 'mr' ? 'जतन करा' : 'Save'))));

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rec.iconEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropDisplayName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rec.bestSowingPeriod,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rec.suitabilityScore}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$yieldLabel ${rec.expectedYieldRange}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$rateLabel ${rec.potentialSellingPrice}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              _getLocalizedRecommendationReason(rec, langCode),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF616161),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => CropRecommendationDetailsPage(
                              recommendation: rec,
                              profile: _profile,
                            ),
                          ),
                        )
                        .then((updated) {
                          if (updated != null && mounted) {
                            setState(() => _profile = updated as FarmerProfile);
                          }
                        });
                  },
                  child: Text(
                    detailsLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    backgroundColor: isSaved
                        ? const Color(0xFF757575)
                        : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (!isSaved) {
                      final list = List<String>.from(
                        _profile.effectiveProducts,
                      );
                      list.add(rec.englishName);
                      final updated = _profile.copyWith(
                        crops: list,
                        selectedProducts: list,
                      );
                      await FarmProfileService.instance.saveFarmProfile(
                        updated,
                      );
                      if (mounted) {
                        setState(() => _profile = updated);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$cropDisplayName ${langCode == 'gu' ? 'તમારા ખેતરમાં ઉમેરાયો!' : (langCode == 'hi' ? 'आपकी फसलों में जोड़ी गई!' : 'added to your farm crops!')}',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    saveLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Nearby Mandi Snapshot Card (Priority 5 & 6)
  Widget _buildNearbyMandiSnapshotCard(AppLocalizations loc, String langCode) {
    final lat =
        _profile.latitude ??
        (_profile.effectiveState.toLowerCase().contains('punjab')
            ? 30.9010
            : 23.0225);
    final lon =
        _profile.longitude ??
        (_profile.effectiveState.toLowerCase().contains('punjab')
            ? 75.8573
            : 72.5714);

    final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
      latitude: lat,
      longitude: lon,
      maxDistanceKm: 250.0,
    );

    final nearest = nearby.isNotEmpty ? nearby.first : null;

    final mandiTitle = langCode == 'gu'
        ? 'નજીકની મંડીઓ અને બજાર ભાવો'
        : (langCode == 'hi'
              ? 'नजदीकी मंडियां एवं बाजार भाव'
              : (langCode == 'pa'
                    ? 'ਨੇੜਲੀਆਂ ਮੰਡੀਆਂ ਅਤੇ ਬਾਜ਼ਾਰ ਭਾਅ'
                    : (langCode == 'mr'
                          ? 'जवळच्या बाजारपेठा व दर'
                          : 'Nearby Mandis & Wholesale Rates')));

    final findMandisLabel = langCode == 'gu'
        ? 'મંડીઓ શોધો'
        : (langCode == 'hi'
              ? 'मंडियां खोजें'
              : (langCode == 'pa'
                    ? 'ਮੰਡੀਆਂ ਲੱਭੋ'
                    : (langCode == 'mr' ? 'मंड्या शोधा' : 'Find Mandis')));

    final compareRatesLabel = langCode == 'gu'
        ? 'ભાવો સરખાવો'
        : (langCode == 'hi'
              ? 'भाव तुलना करें'
              : (langCode == 'pa'
                    ? 'ਭਾਅ ਤੁਲਨਾ ਕਰੋ'
                    : (langCode == 'mr' ? 'दर तुलना करा' : 'Compare Rates')));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE65100),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mandiTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
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
                  loc.viewAll,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          if (nearest != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    nearest.market.type.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nearest.market.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${nearest.distanceKm.toStringAsFixed(1)} ${langCode == 'gu' ? 'કિમી દૂર' : (langCode == 'hi' ? 'किमी दूर' : 'km away')} • ${_formatCleanLocationComponent(nearest.market.district, langCode)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandiDiscoveryPage(profile: _profile),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.near_me_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  label: Text(
                    findMandisLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandiComparisonPage(profile: _profile),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: Text(
                    compareRatesLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(AppLocalizations loc, String langCode) {
    final farmerName = _profile.fullName.isNotEmpty
        ? _profile.fullName
        : 'Farmer';
    final crops = _profile.effectiveProducts.isNotEmpty
        ? _profile.effectiveProducts
        : ['Paddy', 'Tomato'];

    return Container(
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
      child: Stack(
        children: [
          // Background subtle agricultural pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.eco_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Greetings, Location, Crops, My Farm Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Name
                      Text(
                        loc.welcomeGreeting(farmerName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Location Pin
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFFF9933),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatCleanLocationComponent(_profile.effectiveDistrict, langCode)}, ${_formatCleanLocationComponent(_profile.effectiveState, langCode)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE8F5E9),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Selected Crop Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: crops.take(3).map((crop) {
                          String emoji = '🌾';
                          if (crop.toLowerCase().contains('tomato')) {
                            emoji = '🍅';
                          }
                          if (crop.toLowerCase().contains('cotton')) {
                            emoji = '🧶';
                          }
                          if (crop.toLowerCase().contains('wheat')) {
                            emoji = '🌾';
                          }
                          if (crop.toLowerCase().contains('onion')) {
                            emoji = '🧅';
                          }
                          if (crop.toLowerCase().contains('potato')) {
                            emoji = '🥔';
                          }

                          final master = CropMasterDatabase.findCropByName(
                            crop,
                          );
                          final cropLabel = (master != null && langCode != 'en')
                              ? master.getLocalizedName(langCode)
                              : crop;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cropLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // "My Farm" Button
                      InkWell(
                        onTap: _openManageFarm,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.home_work_outlined,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                loc.myFarmButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Side: State-Specific Farmer Avatar Illustration!
                Hero(
                  tag: 'farmer_avatar_${_profile.effectiveState}',
                  child: FarmerAvatar(
                    state: _profile.effectiveState,
                    size: 105,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real-Time Live Weather Card (Engineered for zero overflow across all screen sizes)
  Widget _buildLiveWeatherCard(AppLocalizations loc, String langCode) {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Column(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fetching live weather...',
                style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
      );
    }

    final report = _weatherReport!;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DetailedWeatherPage(profile: _profile, report: report),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Icon + Temp (line 1) & Condition (line 2)
            Expanded(
              flex: 7,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFFFA000),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${report.temperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF212121),
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.conditionName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0288D1),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider 1
            Container(
              height: 28,
              width: 1,
              color: const Color(0xFFE0E0E0),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // 2. Max / Min Temperatures
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Max: ${report.tempMax.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Min: ${report.tempMin.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider 2
            Container(
              height: 28,
              width: 1,
              color: const Color(0xFFE0E0E0),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // 3. Humidity
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF0288D1),
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          loc.humidityLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${report.humidity}%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01579B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider 3
            Container(
              height: 28,
              width: 1,
              color: const Color(0xFFE0E0E0),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // 4. Wind Speed
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.air_rounded,
                        color: Color(0xFF2E7D32),
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          loc.windLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${report.windSpeed.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rain Advisory Banner strip
  Widget _buildRainAdvisoryStrip(AppLocalizations loc) {
    final advisoryText =
        _weatherReport?.advisory ??
        'Rain predicted today (92%). Avoid spraying pesticides and fertilizers. Ensure good drainage in fields.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CropAdvisoryPage(profile: _profile),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_sync_rounded,
                color: Color(0xFFF57F17),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  advisoryText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D4037),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFF57F17),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick Access section reorganized in exact priority order (Requirement 7):
  Widget _buildQuickAccessSection(AppLocalizations loc, String langCode) {
    final items = [
      // 0. Smart AI Crop & Farm Planning (New Feature Highlight)
      {
        'title': langCode == 'gu'
            ? 'AI પાક પ્લાન'
            : (langCode == 'hi' ? 'AI फसल प्लान' : 'AI Crop & Farm Plan'),
        'subtitle': langCode == 'gu'
            ? '૨ ઋતુ અને નફો'
            : (langCode == 'hi' ? '2 मौसम एवं लाभ' : '2 Seasons & Profit'),
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF1B5E20),
        'bg': const Color(0xFFE8F5E9),
        'badge': langCode == 'gu'
            ? 'AI પ્લાન'
            : (langCode == 'hi' ? 'AI प्लान' : 'AI PLAN'),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SmartCropPlanningHubPage(profile: _profile),
          ),
        ),
      },
      // 1. Government Schemes & Subsidies
      {
        'title': loc.governmentSchemesTitle,
        'subtitle': langCode == 'gu'
            ? 'સબસિડી અને પોર્ટલ'
            : (langCode == 'hi' ? 'सब्सिडी व पोर्टल' : 'Subsidies & Portals'),
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF00897B),
        'bg': const Color(0xFFE0F2F1),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GovtSchemesDirectoryPage(profile: _profile),
          ),
        ),
      },
      // 1b. Government News & SMS Alerts
      {
        'title': langCode == 'gu'
            ? 'કૃષિ સમાચાર'
            : (langCode == 'hi' ? 'कृषि समाचार' : 'Govt News & SMS'),
        'subtitle': langCode == 'gu'
            ? 'સરકારી અપડેટ્સ'
            : (langCode == 'hi' ? 'सरकारी अपडेट्स' : 'Verified Updates'),
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF00897B),
        'bg': const Color(0xFFE0F2F1),
        'badge': langCode == 'gu'
            ? 'ચકાસાયેલ'
            : (langCode == 'hi' ? 'सत्यापित' : 'VERIFIED'),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GovernmentNewsDirectoryPage(profile: _profile),
          ),
        ),
      },
      // 2. Ask Agriculture Expert
      {
        'title': langCode == 'gu'
            ? 'કૃષિ નિષ્ણાત'
            : (langCode == 'hi' ? 'कृषि विशेषज्ञ' : 'Ask Agri Expert'),
        'subtitle': langCode == 'gu'
            ? 'AAU અને KVK સહાય'
            : (langCode == 'hi' ? 'AAU व KVK मदद' : 'AAU & KVK Help'),
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFF1B5E20),
        'bg': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AskExpertPage(profile: _profile)),
        ),
      },
      // 3. AI Crop Diagnosis
      {
        'title': langCode == 'gu'
            ? 'પાક રોગ નિદાન'
            : (langCode == 'hi' ? 'फसल रोग निदान' : 'AI Crop Diagnosis'),
        'subtitle': langCode == 'gu'
            ? 'કીટક અને પાંદડા સ્કેન'
            : (langCode == 'hi' ? 'कीट व पत्ती स्कैन' : 'Pest & Leaf Scan'),
        'icon': Icons.document_scanner_rounded,
        'color': const Color(0xFF7B1FA2),
        'bg': const Color(0xFFF3E5F5),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImageAiDiagnosisPage(profile: _profile),
          ),
        ),
      },
      // 4. Natural Farming Marketplace
      {
        'title': langCode == 'gu'
            ? 'પ્રાકૃતિક બજાર'
            : (langCode == 'hi' ? 'प्राकृतिक बाजार' : 'Natural Market'),
        'subtitle': langCode == 'gu'
            ? 'પ્રમાણિત ઓર્ગેનિક'
            : (langCode == 'hi' ? 'प्रमाणित जैविक' : 'Certified Organic'),
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFFF57C00),
        'bg': const Color(0xFFFFF3E0),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NaturalFarmingMarketplacePage(profile: _profile),
          ),
        ),
      },
      // 5. Crop Advisory
      {
        'title': loc.cropAdvisoryTitle,
        'subtitle': langCode == 'gu'
            ? 'વાવણીથી લણણી'
            : (langCode == 'hi' ? 'बुवाई से कटाई' : 'Sowing to Harvest'),
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF2E7D32),
        'bg': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CropAdvisoryPage(profile: _profile),
          ),
        ),
      },
      // 6. Weather Forecast
      {
        'title': loc.weatherForecastTitle,
        'subtitle': langCode == 'gu'
            ? '૭-દિવસ વરસાદ ચેતવણી'
            : (langCode == 'hi' ? '7-दिवसीय बारिश अलर्ट' : '7-Day Rain Alert'),
        'icon': Icons.wb_cloudy_rounded,
        'color': const Color(0xFF0288D1),
        'bg': const Color(0xFFE1F5FE),
        'onTap': () async {
          await PermissionService.instance.ensurePermission(
            context,
            type: KhetPermissionType.location,
            featureName: 'Weather Forecast',
            reason: 'Location access allows KhetChacha to detect your local area and provide hyper-local rain forecasts.',
          );
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailedWeatherPage(
                profile: _profile,
                report: _weatherReport,
              ),
            ),
          );
        },
      },
      // 7. Mandi Rates
      {
        'title': loc.mandiRatesTitle,
        'subtitle': langCode == 'gu'
            ? 'લાઈવ APMC બજાર'
            : (langCode == 'hi' ? 'लाइव APMC मंडी' : 'Live APMC Yard'),
        'icon': Icons.currency_rupee_rounded,
        'color': const Color(0xFFD32F2F),
        'bg': const Color(0xFFFFEBEE),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MandiRatesPage(profile: _profile)),
        ),
      },
      // 8. Fertilizer Guide
      {
        'title': loc.fertilizerGuideTitle,
        'subtitle': langCode == 'gu'
            ? 'યુરિયા અને DAP માત્રા'
            : (langCode == 'hi' ? 'यूरिया व DAP खुराक' : 'Urea & DAP Dosing'),
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF512DA8),
        'bg': const Color(0xFFEDE7F6),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FertilizerCalculatorPage()),
        ),
      },
      // 9. Farm Calculator
      {
        'title': loc.farmCalculatorTitle,
        'subtitle': langCode == 'gu'
            ? 'વિસ્તાર અને ઉપજ સાધનો'
            : (langCode == 'hi' ? 'क्षेत्रफल व उपज टूल' : 'Area & Yield Tools'),
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFFE65100),
        'bg': const Color(0xFFFFF3E0),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalculatorDashboardPage()),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: ⚡ Quick Access  ...  ⚙ Customize
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  loc.quickAccessTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                InkWell(
                  onTap: _openSeeAllServicesSheet,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 14,
                        color: Color(0xFF1B5E20),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        loc.viewAll,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openCustomizeDialog,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        loc.customizeButton,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3-Column Responsive Grid of 9 Prioritized Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            final color = item['color'] as Color;
            final bg = item['bg'] as Color;
            final icon = item['icon'] as IconData;
            final title = item['title'] as String;
            final badge = item['badge'] as String?;
            final onTap = item['onTap'] as VoidCallback;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 8.0,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9933),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openSeeAllServicesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final secondaryItems = [
          {
            'title': 'Soil Health & Fertilizer',
            'desc': 'Soil nutrition and NPK card',
            'icon': Icons.grass_rounded,
            'color': const Color(0xFF388E3C),
            'bg': const Color(0xFFE8F5E9),
            'onTap': () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SoilHealthPage(profile: _profile),
                ),
              );
            },
          },
          {
            'title': 'Pest & Disease Encyclopedia',
            'desc': 'Detailed symptoms and chemical doses',
            'icon': Icons.pest_control_rounded,
            'color': const Color(0xFFE91E63),
            'bg': const Color(0xFFFCE4EC),
            'onTap': () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PestDiseasePage(profile: _profile),
                ),
              );
            },
          },
          {
            'title': 'Seed & Variety Directory',
            'desc': 'High-yield certified varieties',
            'icon': Icons.local_florist_rounded,
            'color': const Color(0xFF00796B),
            'bg': const Color(0xFFE0F2F1),
            'onTap': () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeedVarietyPage(profile: _profile),
                ),
              );
            },
          },
          {
            'title': 'Crop Calendar & Schedules',
            'desc': 'Month-by-month agricultural operations',
            'icon': Icons.calendar_month_rounded,
            'color': const Color(0xFF43A047),
            'bg': const Color(0xFFE8F5E9),
            'onTap': () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CropCalendarPage(profile: _profile),
                ),
              );
            },
          },
          {
            'title': 'Sell Produce to Traders',
            'desc': 'APMC mandi broadcast tool',
            'icon': Icons.shopping_bag_rounded,
            'color': const Color(0xFFF57C00),
            'bg': const Color(0xFFFFF3E0),
            'onTap': () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SellProductsPage(profile: _profile),
                ),
              );
            },
          },
        ];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'All Agricultural Services',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              ...secondaryItems.map((item) {
                final color = item['color'] as Color;
                final bg = item['bg'] as Color;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    item['desc'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: item['onTap'] as VoidCallback,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// My Farm Overview Section
  Widget _buildMyFarmOverviewSection(
    AppLocalizations loc,
    String langCode,
    String seasonText,
  ) {
    final crops = _profile.effectiveProducts.isNotEmpty
        ? _profile.effectiveProducts
        : ['Paddy', 'Tomato'];
    final landSize = _profile.effectiveFarmSize.isNotEmpty
        ? _profile.effectiveFarmSize
        : '2 - 5 Acres';

    final localizedLandSize = langCode == 'gu'
        ? landSize.replaceAll('Acres', 'એકર').replaceAll('Acre', 'એકર')
        : (langCode == 'hi'
              ? landSize.replaceAll('Acres', 'एकड़').replaceAll('Acre', 'एकड़')
              : landSize);

    final localizedCropsSubtitle = crops
        .take(2)
        .map((c) {
          final m = CropMasterDatabase.findCropByName(c);
          return (m != null && langCode != 'en')
              ? m.getLocalizedName(langCode)
              : c;
        })
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: 🌱 My Farm Overview  >
          InkWell(
            onTap: _openManageFarm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.park_rounded,
                      color: Color(0xFF1B5E20),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.myFarmOverviewTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF1B5E20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal 3 Information Blocks
          Row(
            children: [
              Expanded(
                child: _buildFarmInfoBox(
                  icon: Icons.map_outlined,
                  title: localizedLandSize,
                  subtitle: loc.farmSizeLabel,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFarmInfoBox(
                  icon: Icons.eco_rounded,
                  title: loc.cropsCountLabel(crops.length),
                  subtitle: localizedCropsSubtitle,
                  color: const Color(0xFF0288D1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFarmInfoBox(
                  icon: Icons.event_available_rounded,
                  title: loc.thisSeasonLabel,
                  subtitle: seasonText,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Custom 5-Item Bottom Navigation Bar (Requirement 8)
  /// Replaces the old (+) Add Farm center button with:
  /// 1. Home
  /// 2. Crops (Dedicated Crop Lifecycle & Disease screen)
  /// 3. AI Assistant (Elevated central button -> Full-screen AI farming chatbot)
  /// 4. Image AI (Dedicated full-screen photo diagnosis)
  /// 5. Voice Assistant (Dedicated full-screen voice assistant)
  Widget _buildBottomNavigationBar(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(
                icon: Icons.home_rounded,
                label: loc.navHome,
                index: 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),

              // 2. Crops
              _buildNavItem(
                icon: Icons.eco_rounded,
                label: loc.navCrops,
                index: 1,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CropManagementPage(
                        profile: _profile,
                        onProfileUpdated: (updated) =>
                            setState(() => _profile = updated),
                      ),
                    ),
                  );
                },
              ),

              // 3. AI Assistant — Central Highlighted Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AskKhetChachaAiPage(profile: _profile),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFF9933),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Image AI
              _buildNavItem(
                icon: Icons.document_scanner_rounded,
                label: 'Image AI',
                index: 3,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ImageAiDiagnosisPage(profile: _profile),
                    ),
                  );
                },
              ),

              // 5. Voice Assistant
              _buildNavItem(
                icon: Icons.mic_rounded,
                label: 'Voice AI',
                index: 4,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VoiceAssistantPage(profile: _profile),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentNavIndex == index;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF9E9E9E),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
