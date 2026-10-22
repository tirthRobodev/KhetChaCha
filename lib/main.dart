import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'screens/welcome_page.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved language preference (e.g. Gujarati, Hindi, English)
  await LanguageService.instance.init();

  runApp(const KhetChachaApp());
}

/// The root application widget for KhetChacha.
/// Reactively rebuilds when the farmer changes their language selection.
class KhetChachaApp extends StatelessWidget {
  const KhetChachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, _) {
        final currentLanguage = LanguageService.instance.currentLanguage;

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
            scaffoldBackgroundColor: const Color(0xFFF9F7F1),
            fontFamilyFallback: const [
              'Roboto',
              'Noto Sans Gujarati',
              'Noto Sans Devanagari',
              'sans-serif',
            ],
          ),

          // Dynamic Locale Configuration
          locale: currentLanguage.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // First Screen: Welcome / Splash Screen with "Ready for Next Step →"
          home: const WelcomePage(),
        );
      },
    );
  }
}

/// Backward compatibility alias for tests
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const KhetChachaApp();
  }
}
