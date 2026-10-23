import 'package:flutter/material.dart';
import '../models/farmer_profile.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/weather_service.dart';
import 'language_selection_page.dart';
import 'welcome_page.dart';

/// Primary Farmer Dashboard / Home Screen for KhetChacha.
///
/// Features:
/// - Real-time live temperature, humidity, wind, and forecast from Open-Meteo.
/// - Dynamic agricultural advisory tailored to actual district weather.
/// - Multilingual profile header (Name, Village, District, State).
/// - 6 Quick Farmer Services (Crop advisory, Mandi rates, Govt schemes, etc.).
/// - Seamless sign-out and language switcher.
class FarmerDashboardPage extends StatefulWidget {
  final FarmerProfile profile;

  const FarmerDashboardPage({
    super.key,
    required this.profile,
  });

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> {
  FarmWeatherReport? _weatherReport;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final report = await WeatherService.instance.getLiveWeather(
      district: widget.profile.district,
      state: widget.profile.state,
      langCode: langCode,
    );

    if (!mounted) return;
    setState(() {
      _weatherReport = report;
      _isLoadingWeather = false;
    });
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final title = langCode == 'gu'
        ? 'બહાર નીકળો (Sign Out)'
        : (langCode == 'hi' ? 'लॉग आउट (Sign Out)' : 'Sign Out');
    final message = langCode == 'gu'
        ? 'શું તમે ખરેખર ખેતચાચામાંથી બહાર નીકળવા માંગો છો?'
        : (langCode == 'hi'
            ? 'क्या आप वास्तव में खेतचाचा से लॉग आउट करना चाहते हैं?'
            : 'Are you sure you want to sign out from KhetChacha?');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              langCode == 'gu' ? 'રદ કરો' : (langCode == 'hi' ? 'रद्द करें' : 'Cancel'),
              style: const TextStyle(color: Color(0xFF757575)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(langCode == 'gu' ? 'હા, બહાર નીકળો' : (langCode == 'hi' ? 'हाँ, लॉग आउट' : 'Sign Out')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code >= 45 && code <= 48) return Icons.grain_rounded;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 80 && code <= 82) return Icons.shower_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherColor(int code) {
    if (code == 0) return const Color(0xFFFFA000);
    if (code <= 3) return const Color(0xFF0288D1);
    if (code >= 51) return const Color(0xFF1976D2);
    return const Color(0xFFFFA000);
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.instance.currentLanguage;
    final langCode = activeLang.locale.languageCode;
    final profile = widget.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF9933),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'KhetChacha',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Language switcher button
          TextButton.icon(
            icon: const Icon(Icons.translate_rounded, color: Color(0xFFFFD54F), size: 18),
            label: Text(
              activeLang.nativeName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
              );
              // Re-fetch weather in new language if farmer changed language
              _fetchWeather();
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context),
          ),
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
                // 1. Farmer Profile Header Card
                Container(
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFFF9933),
                            child: Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName.trim()[0].toUpperCase()
                                  : 'K',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile.village}, ${profile.district}, ${profile.state}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFE8F5E9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x33FFFFFF)),
                      const SizedBox(height: 8),

                      // Verified Mobile & Email Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x2EFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x55FFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFFFFD54F), size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  profile.mobileNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x2EFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x55FFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined, color: Colors.white, size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  profile.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9933),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${profile.farmingType} • ${profile.landSize}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Real-Time Accurate Weather & Advisory Card
                _buildLiveWeatherCard(langCode),

                const SizedBox(height: 20),

                // 3. Quick Action Grid Title
                Text(
                  langCode == 'gu'
                      ? 'ખેડૂત સેવાઓ (Farmer Services)'
                      : (langCode == 'hi' ? 'किसान सेवाएं (Farmer Services)' : 'Farmer Services'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),

                // Grid of 6 Agricultural Action Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildServiceCard(
                      context,
                      title: 'Crop Advisory',
                      subtitle: 'પાક સલાહ / फसल सलाह',
                      icon: Icons.eco_rounded,
                      color: const Color(0xFF2E7D32),
                    ),
                    _buildServiceCard(
                      context,
                      title: 'Mandi Rates',
                      subtitle: 'બજાર ભાવ / मंडी भाव',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFFE65100),
                    ),
                    _buildServiceCard(
                      context,
                      title: 'Weather Forecast',
                      subtitle: 'હવામાન / मौसम जानकारी',
                      icon: Icons.cloud_outlined,
                      color: const Color(0xFF0277BD),
                    ),
                    _buildServiceCard(
                      context,
                      title: 'Ask KhetChaCha',
                      subtitle: 'AI Krishi Mitra / કૃષિ મિત્ર',
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFF6A1B9A),
                    ),
                    _buildServiceCard(
                      context,
                      title: 'Govt Schemes',
                      subtitle: 'PM-Kisan & Subsidy',
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF4527A0),
                    ),
                    _buildServiceCard(
                      context,
                      title: 'Soil & Fertilizer',
                      subtitle: 'જમીન ચકાસણી / खाद सलाह',
                      icon: Icons.grass_rounded,
                      color: const Color(0xFF558B2F),
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

  /// Builds the real-time weather card fetching from Open-Meteo
  Widget _buildLiveWeatherCard(String langCode) {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Column(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2E7D32)),
              ),
              SizedBox(height: 10),
              Text(
                'Fetching live weather for your district...',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF616161)),
              ),
            ],
          ),
        ),
      );
    }

    final report = _weatherReport!;
    final iconColor = _getWeatherColor(report.weatherCode);
    final iconData = _getWeatherIcon(report.weatherCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar: Location + Live Indicator + Refresh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFDE7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.profile.district}, ${widget.profile.state}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        langCode == 'gu' ? 'લાઈવ હવામાન' : (langCode == 'hi' ? 'लाइव मौसम' : 'LIVE'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2E7D32)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Refresh Weather',
                  onPressed: _fetchWeather,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Temperature + Condition Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.temperature.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              '°C',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.conditionName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Max: ${report.tempMax.toStringAsFixed(0)}°C  •  Min: ${report.tempMin.toStringAsFixed(0)}°C',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 44),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Metrics Chips: Humidity & Wind
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB3E5FC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF0277BD)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${langCode == 'gu' ? 'ભેજ' : (langCode == 'hi' ? 'नमी' : 'Humidity')}: ${report.humidity}%',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF01579B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCEDC8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.air_rounded, size: 16, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${langCode == 'gu' ? 'પવન' : (langCode == 'hi' ? 'हवा' : 'Wind')}: ${report.windSpeed.toStringAsFixed(0)} km/h',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Smart Agricultural Advisory Banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFFF57F17)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.advisory,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF424242),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title service is connected for ${widget.profile.fullName}!'),
              backgroundColor: const Color(0xFF1B5E20),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF757575),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
