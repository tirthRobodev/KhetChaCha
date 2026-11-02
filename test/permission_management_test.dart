import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/onboarding/first_launch_onboarding_page.dart';
import 'package:khetchacha/services/permission_service.dart';
import 'package:khetchacha/widgets/permission_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    PermissionService.instance.enableMockMode(enabled: true);
    PermissionService.instance.resetMockStates();
  });

  group('PermissionService Core Logic Tests', () {
    test('Fresh installation defaults onboarding to not completed', () async {
      final isDone = await PermissionService.instance.isOnboardingCompleted();
      expect(isDone, isFalse);
    });

    test('Onboarding status persists in SharedPreferences', () async {
      await PermissionService.instance.setOnboardingCompleted(true);
      final isDone = await PermissionService.instance.isOnboardingCompleted();
      expect(isDone, isTrue);

      await PermissionService.instance.setOnboardingCompleted(false);
      final isDoneAgain = await PermissionService.instance
          .isOnboardingCompleted();
      expect(isDoneAgain, isFalse);
    });

    test('Checks and requests all 5 permissions', () async {
      final allStates = await PermissionService.instance.checkAll();
      expect(allStates.length, 5);
      expect(allStates.containsKey(KhetPermissionType.location), isTrue);
      expect(allStates.containsKey(KhetPermissionType.camera), isTrue);
      expect(allStates.containsKey(KhetPermissionType.gallery), isTrue);
      expect(allStates.containsKey(KhetPermissionType.microphone), isTrue);
      expect(allStates.containsKey(KhetPermissionType.notification), isTrue);
    });

    test(
      'Mock state transitions work for granted, denied, and permanentlyDenied',
      () async {
        // 1. Initial not requested
        expect(
          await PermissionService.instance.checkStatus(
            KhetPermissionType.camera,
          ),
          KhetPermissionState.notRequested,
        );

        // 2. Request grants
        final granted = await PermissionService.instance.request(
          KhetPermissionType.camera,
        );
        expect(granted, KhetPermissionState.granted);
        expect(
          await PermissionService.instance.checkStatus(
            KhetPermissionType.camera,
          ),
          KhetPermissionState.granted,
        );

        // 3. Denied mock
        PermissionService.instance.setMockState(
          KhetPermissionType.location,
          KhetPermissionState.denied,
        );
        expect(
          await PermissionService.instance.checkStatus(
            KhetPermissionType.location,
          ),
          KhetPermissionState.denied,
        );

        // 4. Permanently denied mock
        PermissionService.instance.setMockState(
          KhetPermissionType.microphone,
          KhetPermissionState.permanentlyDenied,
        );
        expect(
          await PermissionService.instance.checkStatus(
            KhetPermissionType.microphone,
          ),
          KhetPermissionState.permanentlyDenied,
        );
      },
    );

    test('requestAll requests all permissions sequentially', () async {
      final results = await PermissionService.instance.requestAll();
      expect(results.length, 5);
      for (final state in results.values) {
        expect(state, KhetPermissionState.granted);
      }
    });

    test('openSettings completes without crashing', () async {
      final opened = await PermissionService.instance.openSettings();
      expect(opened, isTrue);
    });
  });

  group('PermissionCard Widget Tests', () {
    testWidgets(
      'Renders PermissionCard in not requested state with Enable button',
      (tester) async {
        bool tapped = false;

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
            home: Scaffold(
              body: PermissionCard(
                type: KhetPermissionType.camera,
                state: KhetPermissionState.notRequested,
                onRequest: () => tapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Camera Access'), findsOneWidget);
        expect(find.text('Enable'), findsOneWidget);

        await tester.tap(find.text('Enable'));
        expect(tapped, isTrue);
      },
    );

    testWidgets('Renders PermissionCard in granted state with Enabled badge', (
      tester,
    ) async {
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
          home: const Scaffold(
            body: PermissionCard(
              type: KhetPermissionType.location,
              state: KhetPermissionState.granted,
              onRequest: _noop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      // "Enable" button must not appear when granted
      expect(find.text('Enable'), findsNothing);
    });

    testWidgets(
      'Renders PermissionCard in permanently denied state with Settings button',
      (tester) async {
        bool openedSettings = false;

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
            home: Scaffold(
              body: PermissionCard(
                type: KhetPermissionType.microphone,
                state: KhetPermissionState.permanentlyDenied,
                onRequest: _noop,
                onOpenSettings: () => openedSettings = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Microphone Access'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        await tester.tap(find.text('Settings'));
        expect(openedSettings, isTrue);
      },
    );
  });

  group('FirstLaunchOnboardingPage Widget Tests', () {
    testWidgets('Renders all 5 permission cards and welcome branding', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          home: const FirstLaunchOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Welcome title
      expect(find.text('Welcome to KhetChacha'), findsOneWidget);

      // 5 Permission cards
      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(find.text('Photo & Media Access'), findsOneWidget);
      expect(find.text('Microphone Access'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Buttons
      expect(find.text('Continue to Dashboard →'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
      expect(find.text('Grant All Permissions'), findsOneWidget);
    });

    testWidgets(
      'Tapping Continue to Dashboard sets onboarding completed and navigates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const profile = FarmerProfile(
          fullName: 'Ramesh Patel',
          mobileNumber: '9876543210',
          email: 'ramesh@khet.com',
          state: 'Gujarat',
          district: 'Anand',
          village: 'Tarapur',
          farmingType: 'Organic',
          landSize: '3 Acres',
          selectedLanguage: 'en',
          farmSetupCompleted: true,
        );

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
            home: const FirstLaunchOnboardingPage(profile: profile),
          ),
        );
        await tester.pumpAndSettle();

        final continueButton = find.text('Continue to Dashboard →');
        expect(continueButton, findsOneWidget);

        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        final isDone = await PermissionService.instance.isOnboardingCompleted();
        expect(isDone, isTrue);
      },
    );

    testWidgets(
      'Tapping Skip for now also marks onboarding completed without blocking',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

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
            home: const FirstLaunchOnboardingPage(),
          ),
        );
        await tester.pumpAndSettle();

        final skipButton = find.text('Skip for now');
        expect(skipButton, findsOneWidget);

        await tester.tap(skipButton);
        await tester.pumpAndSettle();

        final isDone = await PermissionService.instance.isOnboardingCompleted();
        expect(isDone, isTrue);
      },
    );

    testWidgets('Tapping Grant All Permissions grants all cards in real-time', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          home: const FirstLaunchOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      final grantAllButton = find.text('Grant All Permissions');
      expect(grantAllButton, findsOneWidget);

      await tester.tap(grantAllButton);
      await tester.pumpAndSettle();

      // All 5 should be granted
      expect(find.text('5 of 5 permissions enabled'), findsOneWidget);
      expect(
        find.text(
          'All permissions enabled! You have full access to all KhetChacha features.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Multilingual rendering in Gujarati', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('gu'),
          home: const FirstLaunchOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ખેતચાચામાં આપનું સ્વાગત છે'), findsOneWidget);
      expect(find.text('પરમિશન સેટઅપ'), findsOneWidget);
      expect(find.text('લોકેશન પરમિશન'), findsOneWidget);
      expect(find.text('કેમેરા પરમિશન'), findsOneWidget);
      expect(find.text('ડેશબોર્ડ પર આગળ વધો →'), findsOneWidget);
      expect(find.text('હમણાં માટે રહેવા દો'), findsOneWidget);
    });
  });

  group('Feature-Level Permission Guard Tests', () {
    testWidgets(
      'ensurePermission returns true immediately when already granted',
      (tester) async {
        PermissionService.instance.setMockState(
          KhetPermissionType.camera,
          KhetPermissionState.granted,
        );

        late BuildContext savedContext;
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
            home: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final result = await PermissionService.instance.ensurePermission(
          savedContext,
          type: KhetPermissionType.camera,
          featureName: 'AI Crop Diagnosis',
          reason: 'Test camera reason',
        );
        expect(result, isTrue);
      },
    );

    testWidgets(
      'ensurePermission displays friendly bottom sheet when not granted',
      (tester) async {
        PermissionService.instance.setMockState(
          KhetPermissionType.camera,
          KhetPermissionState.notRequested,
        );

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
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () {
                      PermissionService.instance.ensurePermission(
                        ctx,
                        type: KhetPermissionType.camera,
                        featureName: 'AI Crop Diagnosis',
                        reason: 'Camera access allows taking photos for AI disease analysis.',
                      );
                    },
                    child: const Text('Check Perm'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Perm'));
        await tester.pumpAndSettle();

        expect(find.text('AI Crop Diagnosis'), findsOneWidget);
        expect(
          find.text(
            'Camera access allows taking photos for AI disease analysis.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Enable'), findsOneWidget);

        // Tap Enable
        await tester.tap(find.text('Enable'));
        await tester.pumpAndSettle();

        // Bottom sheet dismissed
        expect(find.text('AI Crop Diagnosis'), findsNothing);
      },
    );
  });
}

void _noop() {}
