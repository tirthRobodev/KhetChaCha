import 'package:flutter/material.dart';
import '../animation/splash_animation_screen.dart';
import 'language_selection_page.dart';

/// [WelcomePage] wraps the existing first screen animated splash sequence
/// and wires the "Ready for Next Step →" navigation action to the Language Selection Page.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashAnimationScreen(
      showTopBrandHeader: false,
      showTaglines: true,
      onAnimationComplete: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LanguageSelectionPage(),
          ),
        );
      },
    );
  }
}
