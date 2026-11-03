import 'package:flutter/material.dart';

import '../animation/splash_animation_screen.dart';
import '../localization/language_data.dart';
import '../services/farm_profile_service.dart';
import '../services/language_service.dart';
import '../services/permission_service.dart';
import 'farmer_dashboard_page.dart';
import 'language_selection_page.dart';

/// [WelcomePage] wraps the animated splash sequence.
/// On playback completion:
/// - If first launch: sequentially prompts all native Android system permissions
///   directly, then navigates to [LanguageSelectionPage].
/// - If returning farmer with setup completed: routes directly to [FarmerDashboardPage].
/// - If new user / setup pending: routes to [LanguageSelectionPage].
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _handleNavigation(BuildContext context) async {
    final isOnboardingDone = await PermissionService.instance
        .isOnboardingCompleted();
    final profile = await FarmProfileService.instance.loadFarmProfile();

    if (!context.mounted) return;

    // First App Launch Experience:
    // Right after splash animation completes, ask all permissions sequentially via native Android system dialogs
    if (!isOnboardingDone) {
      await PermissionService.instance.requestAll();
      await PermissionService.instance.setOnboardingCompleted(true);
    }

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
      // New user flow: Animation complete -> System permissions asked -> Language Selection -> Phone Login -> Details -> Crop Selection -> Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(initialProfile: profile),
        ),
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
