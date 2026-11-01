import 'package:flutter/material.dart';

import '../animation/splash_animation_screen.dart';
import '../localization/language_data.dart';
import '../services/farm_profile_service.dart';
import '../services/language_service.dart';
import 'farmer_dashboard_page.dart';
import 'language_selection_page.dart';

/// [WelcomePage] wraps the animated splash sequence.
/// On playback completion:
/// - If returning farmer with setup completed: routes directly to [FarmerDashboardPage].
/// - If new user or onboarding: routes to [LanguageSelectionPage] (Select Language first).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _handleNavigation(BuildContext context) async {
    final profile = await FarmProfileService.instance.loadFarmProfile();

    if (!context.mounted) return;

    if (profile != null && profile.farmSetupCompleted) {
      // Restore selected language
      if (profile.selectedLanguage.isNotEmpty) {
        final lang = LanguageData.allLanguages.firstWhere(
          (l) => l.code == profile.selectedLanguage,
          orElse: () => LanguageData.defaultLanguage,
        );
        await LanguageService.instance.setLanguage(lang);
      }

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FarmerDashboardPage(profile: profile),
        ),
      );
    } else {
      // New user flow: Animation complete -> Select Language first -> Phone Login -> Details
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashAnimationScreen(
      onAnimationComplete: () => _handleNavigation(context),
    );
  }
}
