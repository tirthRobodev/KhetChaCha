import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/calculators/crop_yield_calculator_page.dart';
import 'package:khetchacha/screens/calculators/farm_cost_profit_calculator_page.dart';
import 'package:khetchacha/screens/calculators/farmer_calculator_page.dart';
import 'package:khetchacha/screens/calculators/fertilizer_calculator_page.dart';
import 'package:khetchacha/screens/calculators/land_area_calculator_page.dart';
import 'package:khetchacha/screens/calculators/pesticide_dilution_calculator_page.dart';
import 'package:khetchacha/screens/calculators/seed_calculator_page.dart';
import 'package:khetchacha/screens/calculators/smart_crop_profit_calculator_page.dart';
import 'package:khetchacha/screens/farmer_dashboard_page.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:khetchacha/services/marketplace_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'Rameshbhai Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@patel.com',
    state: 'Gujarat',
    district: 'Ahmedabad',
    village: 'Bhavda, Daskroi',
    farmingType: 'Natural',
    landSize: '3.0 Acres',
    latitude: 23.0225,
    longitude: 72.5714,
    crops: ['Paddy (Rice)', 'Groundnut (Peanut)', 'Cotton'],
    selectedProducts: ['Paddy (Rice)', 'Groundnut (Peanut)', 'Cotton'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage(LanguageData.getByCode('gu'));
    await MarketplaceService.instance.init();
  });

  Widget wrapWithMaterial(
    Widget child, {
    double textScale = 1.0,
    Locale locale = const Locale('gu'),
  }) {
    return MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: child,
      ),
    );
  }

  group('RESPONSIVE OVERFLOW TESTS — ZERO RENDERFLEX OVERFLOW ON 9 TARGET SCREENS', () {
    const testSizes = [
      Size(320, 640), // Narrow budget Android
      Size(360, 780), // Standard Android
      Size(393, 852), // iPhone / Pixel 7
      Size(412, 915), // Large flagship Android
    ];

    for (final size in testSizes) {
      testWidgets(
        'Screen 1 & 2: FarmerDashboardPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const FarmerDashboardPage(profile: testProfile),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 3 & 4: FertilizerCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const FertilizerCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 5: LandAreaCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const LandAreaCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 6 & 7: CropYieldCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const CropYieldCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 8: PesticideDilutionCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const PesticideDilutionCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 9: FarmerCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const FarmerCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 9: FarmCostProfitCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const FarmCostProfitCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 9: SeedCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const SeedCalculatorPage(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Screen 9: SmartCropProfitCalculatorPage renders with zero overflow on ${size.width}x${size.height} in Gujarati',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const SmartCropProfitCalculatorPage(profile: testProfile),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'High font scaling (1.25x) renders with zero overflow on narrow screen 360dp in Gujarati',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2, 780 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrapWithMaterial(
            const FertilizerCalculatorPage(),
            textScale: 1.25,
            locale: const Locale('gu'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          wrapWithMaterial(
            const CropYieldCalculatorPage(),
            textScale: 1.25,
            locale: const Locale('gu'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          wrapWithMaterial(
            const LandAreaCalculatorPage(),
            textScale: 1.25,
            locale: const Locale('gu'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          wrapWithMaterial(
            const PesticideDilutionCalculatorPage(),
            textScale: 1.25,
            locale: const Locale('gu'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
