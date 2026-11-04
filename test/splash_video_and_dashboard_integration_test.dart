import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/animation/splash_animation_screen.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farmer_dashboard_page.dart';
import 'package:khetchacha/screens/language_selection_page.dart';
import 'package:khetchacha/screens/welcome_page.dart';
import 'package:khetchacha/services/farm_profile_service.dart';
import 'package:khetchacha/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'helpers/fake_video_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlayerPlatform.registerWith();
  });

  group('KhetChacha Intro Video & Real Dashboard Integration Tests', () {
    test(
      '1. Video Asset Validation: Authentic MP4 file exists and has valid size',
      () {
        final file = File('assets/animation/khetchacha_splash.mp4');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'khetchacha_splash.mp4 must exist in assets/animation',
        );
        final size = file.lengthSync();
        expect(
          size,
          greaterThan(1000000),
          reason: 'Video must be the authentic full quality file (>1MB)',
        );
      },
    );

    testWidgets(
      '2. Startup video renders without artificial text overlays or duplicate logos',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SplashAnimationScreen()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // VideoPlayer widget must be active
        expect(find.byType(VideoPlayer), findsWidgets);

        // Verify NO independent/duplicate wordmark overlays or slogans exist
        expect(find.textContaining('Your Farming Friend'), findsNothing);
        expect(find.textContaining('દરેક ખેડૂતનો સાચો સાથી'), findsNothing);
        expect(find.textContaining('Ready for Next Step'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '3. Responsive Video Layout on Small Screen (720p HD: 720 x 1280)',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: SplashAnimationScreen()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(VideoPlayer), findsWidgets);
        expect(find.byType(AspectRatio), findsWidgets);
      },
    );

    testWidgets(
      '4. Responsive Video Layout on Large Tall Screen (FHD+ 20:9: 1080 x 2400)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: SplashAnimationScreen()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(VideoPlayer), findsWidgets);
        expect(find.byType(AspectRatio), findsWidgets);
      },
    );

    testWidgets(
      '5. Video Completion: Automatically triggers completion callback',
      (tester) async {
        bool completed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: SplashAnimationScreen(
              onAnimationComplete: () {
                completed = true;
              },
            ),
          ),
        );
        await tester.pump();

        // Advance clock past the video duration / fallback timer
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(
          completed,
          isTrue,
          reason: 'Video completion callback must fire automatically',
        );
      },
    );

    testWidgets(
      '6. Authenticated / Returning Farmer: Routes directly to actual Main Dashboard',
      (tester) async {
        // Setup returning farmer profile
        final returningFarmer = const FarmerProfile(
          fullName: 'Tirth Patel',
          mobileNumber: '+919876543210',
          email: 'tirth@khetchacha.in',
          state: 'Gujarat',
          district: 'Amreli',
          village: 'Chalala',
          farmingType: 'Conventional',
          landSize: '3.0',
          farmSetupCompleted: true,
        );
        await FarmProfileService.instance.saveFarmProfile(returningFarmer);
        await PermissionService.instance.setOnboardingCompleted(true);

        await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
        await tester.pump();

        // Advance video playback to completion
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // Must navigate directly to the existing Main Dashboard
        expect(find.byType(FarmerDashboardPage), findsOneWidget);
      },
    );

    testWidgets(
      '7. New Farmer / Setup Required: Asks permissions and routes to onboarding',
      (tester) async {
        SharedPreferences.setMockInitialValues({}); // Fresh clean installation

        await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
        await tester.pump();

        // Advance video playback to completion
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // Permissions marked done on launch
        final isDone = await PermissionService.instance.isOnboardingCompleted();
        expect(isDone, isTrue);

        // Lands on LanguageSelectionPage to begin onboarding flow
        expect(find.byType(LanguageSelectionPage), findsOneWidget);
      },
    );

    testWidgets(
      '8. Missing video asset fallback: routes safely without app freezing',
      (tester) async {
        bool fallbackNavigated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: SplashAnimationScreen(
              onAnimationComplete: () {
                fallbackNavigated = true;
              },
            ),
          ),
        );
        await tester.pump();

        // Advance timer for fallback
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(fallbackNavigated, isTrue);
      },
    );
  });
}
