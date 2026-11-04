import 'package:flutter/material.dart';

import '../../localization/language_data.dart';
import '../../models/farmer_profile.dart';
import '../../services/farm_profile_service.dart';
import '../../services/language_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/farmer_welcome_hero_display.dart';
import '../farmer_dashboard_page.dart';
import '../language_selection_page.dart';

/// Full-Screen Responsive Farmer Welcome Screen.
///
/// Implements all requirements from Section 5:
/// 1. Centers the complete Indian farmer character using [FarmerWelcomeHeroDisplay].
/// 2. Shows the complete Indian flag, saffron turban, hands, body, and feet.
/// 3. Never crops or truncates any part of the farmer illustration.
/// 4. Responsive across every mobile screen size (small 320px, standard, large/tall 20:9, tablets).
/// 5. Uses [BoxFit.contain] for the foreground character illustration.
/// 6. Uses a softly blurred [BoxFit.cover] background of the same image to eliminate letterboxing.
/// 7. Maintains original image aspect ratio without stretching or distortion.
/// 8. Respects [SafeArea] and mobile system bars.
class FarmerWelcomeScreen extends StatelessWidget {
  final FarmerProfile? initialProfile;

  const FarmerWelcomeScreen({super.key, this.initialProfile});

  Future<void> _handleGetStarted(BuildContext context) async {
    final isOnboardingDone = await PermissionService.instance
        .isOnboardingCompleted();
    final profile =
        initialProfile ?? await FarmProfileService.instance.loadFarmProfile();

    if (!context.mounted) return;

    if (!isOnboardingDone) {
      await PermissionService.instance.requestAll();
      await PermissionService.instance.setOnboardingCompleted(true);
    }

    if (!context.mounted) return;

    final hasSetup =
        (profile != null && profile.farmSetupCompleted) ||
        await FarmProfileService.instance.hasCompletedFarmSetup();

    if (hasSetup) {
      final activeProfile =
          profile ??
          FarmerProfile(
            fullName: 'Kisan Mitra',
            mobileNumber: '',
            email: '',
            state: 'Gujarat',
            district: 'Amreli',
            village: 'Chalala',
            farmingType: 'Conventional',
            landSize: '2.0',
            farmSetupCompleted: true,
          );

      if (activeProfile.selectedLanguage.isNotEmpty) {
        final lang = LanguageData.allLanguages.firstWhere(
          (l) => l.code == activeProfile.selectedLanguage,
          orElse: () => LanguageData.defaultLanguage,
        );
        await LanguageService.instance.setLanguage(lang);
      }

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FarmerDashboardPage(profile: activeProfile),
        ),
      );
    } else {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(initialProfile: profile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    final title = langCode == 'gu'
        ? 'ખેતચાચા (KhetChacha)'
        : (langCode == 'hi'
              ? 'खेतचाचा (KhetChacha)'
              : (langCode == 'pa' ? 'ਖੇਤਚਾਚਾ (KhetChacha)' : 'KhetChacha'));

    final tagline = langCode == 'gu'
        ? 'તમારો અંગત AI ખેતી મિત્ર'
        : (langCode == 'hi'
              ? 'आपका व्यक्तिगत AI कृषि मित्र'
              : (langCode == 'pa'
                    ? 'ਤੁਹਾਡਾ ਨਿੱਜੀ AI ਖੇਤੀ ਮਿੱਤਰ'
                    : 'Your Personal AI Farming Assistant'));

    final getStartedLabel = langCode == 'gu'
        ? 'શરૂ કરો • આગળ વધો'
        : (langCode == 'hi'
              ? 'शुरू करें • आगे बढ़ें'
              : (langCode == 'pa'
                    ? 'ਸ਼ੁਰੂ ਕਰੋ • ਅੱਗੇ ਵਧੋ'
                    : 'Get Started • Continue'));

    return Scaffold(
      backgroundColor: const Color(0xFF0B3720),
      body: FarmerWelcomeHeroDisplay(
        // The Indian farmer illustration asset showing full turban, Indian flag, hands & feet
        imagePath: 'assets/images/farmers/gujarat.png',
        overlay: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Subtle top branding badge
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.agriculture_rounded,
                          color: Color(0xFFFF9933), // Indian Saffron
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Bottom Welcoming Card with action button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => _handleGetStarted(context),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  getStartedLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
