import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farmer_dashboard_page.dart';
import 'package:khetchacha/screens/language_selection_page.dart';
import 'package:khetchacha/screens/splash/khetchacha_logo_splash_screen.dart';
import 'package:khetchacha/screens/welcome/farmer_welcome_screen.dart';
import 'package:khetchacha/services/farm_profile_service.dart';
import 'package:khetchacha/services/permission_service.dart';
import 'package:khetchacha/widgets/farmer_welcome_hero_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KhetChacha Logo Splash Screen - Full-Screen & Responsive Tests', () {
    const screenSizes = [
      Size(320, 640), // Small Android Phone
      Size(360, 800), // Standard Android Phone
      Size(390, 844), // Standard Modern Phone
      Size(412, 915), // Large Android Phone
      Size(600, 1024), // Tablet / Foldable
    ];

    for (final size in screenSizes) {
      testWidgets(
        'Renders full-screen logo without distortion or overflow on ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: KhetChachaLogoSplashScreen(
                displayDuration: Duration(seconds: 2),
              ),
            ),
          );
          await tester.pump();

          // 1. Verify Scaffold with dark agricultural green background (#0B3720)
          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(scaffold.backgroundColor, const Color(0xFF0B3720));

          // 2. Verify AspectRatio preserves 1024/832 artwork ratio
          expect(find.byType(AspectRatio), findsOneWidget);
          final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
          expect(aspect.aspectRatio, closeTo(1024 / 832, 0.01));

          // 3. Verify Image with BoxFit.contain
          final imageFinder = find.byType(Image);
          expect(imageFinder, findsOneWidget);
          final img = tester.widget<Image>(imageFinder);
          expect(img.fit, BoxFit.contain);

          // 4. Verify no RenderFlex overflow
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Tapping anywhere triggers immediate completion', (
      tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: KhetChachaLogoSplashScreen(
            displayDuration: const Duration(seconds: 5),
            onSplashComplete: () => completed = true,
          ),
        ),
      );
      await tester.pump();

      // Tap on screen
      await tester.tap(find.byType(KhetChachaLogoSplashScreen));
      await tester.pump();

      expect(completed, isTrue);
    });
  });

  group('Farmer Welcome Screen - Full-Screen Character & Responsive Tests', () {
    const screenSizes = [
      Size(320, 640), // Small Android Phone
      Size(360, 800), // Standard Android Phone
      Size(390, 844), // Standard Modern Phone
      Size(412, 915), // Large Tall Android Phone (20:9)
      Size(600, 1024), // Large Screen / Tablet
    ];

    for (final size in screenSizes) {
      testWidgets(
        'Renders uncropped farmer character with blurred background on ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('en'),
              home: FarmerWelcomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Verify FarmerWelcomeHeroDisplay is active
          expect(find.byType(FarmerWelcomeHeroDisplay), findsOneWidget);

          // 2. Verify foreground image uses BoxFit.contain and background uses BoxFit.cover
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          expect(images.length, greaterThanOrEqualTo(2));
          expect(images.any((img) => img.fit == BoxFit.contain), isTrue);
          expect(images.any((img) => img.fit == BoxFit.cover), isTrue);

          // 3. Verify get started button exists
          expect(find.byType(ElevatedButton), findsOneWidget);

          // 4. Verify no RenderFlex overflow
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'New user tapping Get Started requests permissions and navigates to LanguageSelectionPage',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: FarmerWelcomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on Get Started button
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify onboarding is marked done and user is on LanguageSelectionPage
        final isDone = await PermissionService.instance.isOnboardingCompleted();
        expect(isDone, isTrue);
        expect(find.byType(LanguageSelectionPage), findsOneWidget);
      },
    );

    testWidgets(
      'Returning farmer with completed setup routes directly to FarmerDashboardPage',
      (tester) async {
        final profile = const FarmerProfile(
          fullName: 'Kisan Ramesh',
          mobileNumber: '+919876543210',
          email: 'ramesh@example.com',
          state: 'Gujarat',
          district: 'Anand',
          village: 'Mogri',
          farmingType: 'Natural',
          landSize: '4.0',
          farmSetupCompleted: true,
        );
        await FarmProfileService.instance.saveFarmProfile(profile);
        await PermissionService.instance.setOnboardingCompleted(true);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: FarmerWelcomeScreen(initialProfile: profile),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Get Started
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.byType(FarmerDashboardPage), findsOneWidget);
      },
    );
  });
}
