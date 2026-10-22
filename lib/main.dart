import 'package:flutter/material.dart';
import 'package:khetchacha/animation/splash_animation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhetChachaApp());
}

/// The root application widget for KhetChacha.
class KhetChachaApp extends StatelessWidget {
  const KhetChachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhetChacha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Agriculture Forest Green
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFF9933), // Warm Indian Saffron / Amber
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
      ),
      home: SplashAnimationScreen(
        onAnimationComplete: () {
          // Navigation hook for the future Language Selection screen.
          // For now, the animation finishes and gracefully keeps the final branded splash
          // screen visible as per requirements.
          debugPrint('KhetChacha: Splash animation completed.');
        },
      ),
    );
  }
}

/// Backward compatibility alias for tests and default templates.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const KhetChachaApp();
  }
}

