import 'package:flutter/material.dart';
import '../animation/splash_animation_screen.dart';
import 'language_selection_page.dart';

/// [WelcomePage] wraps the animated splash sequence
/// and automatically navigates to [LanguageSelectionPage] using [Navigator.pushReplacement]
/// upon video completion.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashAnimationScreen(
      onAnimationComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LanguageSelectionPage(),
          ),
        );
      },
    );
  }
}
