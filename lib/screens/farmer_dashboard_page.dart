import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
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

                const SizedBox(height: 16),

                // 2. Weather Card
                _buildLiveWeatherCard(loc, langCode),

                const SizedBox(height: 12),

                // 3. Rain Advisory Banner
                _buildRainAdvisoryStrip(loc),

                const SizedBox(height: 20),

                // 4. Quick Access (12 Cards)
                _buildQuickAccessSection(loc),

                const SizedBox(height: 20),

                // 5. My Farm Overview
                _buildMyFarmOverviewSection(loc, seasonText),

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
                              '${_profile.effectiveDistrict}, ${_profile.effectiveState}',
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
                                  crop,
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
  /// 1. Government Schemes
  /// 2. Ask Agriculture Expert
  /// 3. AI Crop Diagnosis
  /// 4. Natural Farming Marketplace
  /// 5. Crop Advisory
  /// 6. Weather Forecast
  /// 7. Mandi Rates
  /// 8. Fertilizer Guide
  /// 9. Farm Calculator
  Widget _buildQuickAccessSection(AppLocalizations loc) {
    final items = [
      // 1. Government Schemes & Subsidies
      {
        'title': loc.governmentSchemesTitle,
        'subtitle': 'Subsidies & Portals',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF00897B),
        'bg': const Color(0xFFE0F2F1),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GovtSchemesDirectoryPage(profile: _profile),
          ),
        ),
      },
      // 2. Ask Agriculture Expert
      {
        'title': 'Ask Agri Expert',
        'subtitle': 'AAU & KVK Help',
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFF1B5E20),
        'bg': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AskExpertPage(profile: _profile)),
        ),
      },
      // 3. AI Crop Diagnosis
      {
        'title': 'AI Crop Diagnosis',
        'subtitle': 'Pest & Leaf Scan',
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
        'title': 'Natural Market',
        'subtitle': 'Certified Organic',
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
        'subtitle': 'Sowing to Harvest',
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
        'subtitle': '7-Day Rain Alert',
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
        'subtitle': 'Live APMC Yard',
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
        'subtitle': 'Urea & DAP Dosing',
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
        'subtitle': 'Area & Yield Tools',
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 14,
                        color: Color(0xFF1B5E20),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'See All',
                        style: TextStyle(
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
            final onTap = item['onTap'] as VoidCallback;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 8.0,
                  ),
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
  Widget _buildMyFarmOverviewSection(AppLocalizations loc, String seasonText) {
    final crops = _profile.effectiveProducts.isNotEmpty
        ? _profile.effectiveProducts
        : ['Paddy', 'Tomato'];
    final landSize = _profile.effectiveFarmSize.isNotEmpty
        ? _profile.effectiveFarmSize
        : '2 - 5 Acres';

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
                  title: landSize,
                  subtitle: loc.farmSizeLabel,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFarmInfoBox(
                  icon: Icons.eco_rounded,
                  title: loc.cropsCountLabel(crops.length),
                  subtitle: crops.take(2).join(', '),
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
