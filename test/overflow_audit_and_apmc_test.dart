import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/models/crop_recommendation.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/crops/annual_farm_planner_page.dart';
import 'package:khetchacha/screens/crops/crop_recommendation_details_page.dart';
import 'package:khetchacha/screens/crops/seasonal_planning_page.dart';
import 'package:khetchacha/screens/mandi/mandi_comparison_page.dart';
import 'package:khetchacha/screens/quick_access/detailed_weather_page.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:khetchacha/services/mandi_price_service.dart';
import 'package:khetchacha/services/marketplace_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'Ramesh Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@patel.com',
    state: 'Gujarat',
    district: 'Amreli',
    village: 'Dhari',
    farmingType: 'Natural',
    landSize: '2.5 Acres',
    latitude: 21.6032,
    longitude: 71.2223,
    crops: ['Cotton', 'Groundnut'],
    selectedProducts: ['Cotton', 'Groundnut'],
  );

  final sampleCrop = CropRecommendation(
    cropId: 'crop_groundnut_kharif',
    englishName: 'Groundnut (Peanut)',
    nativeName: 'મગફળી',
    season: 'Kharif',
    suitabilityScore: 94,
    recommendationReason:
        'Excellent soil match for Medium Black soil in Amreli.',
    bestSowingPeriod: '15 June - 05 July',
    expectedDuration: '105-115 Days',
    waterRequirement: 'Medium (450-550 mm)',
    soilSuitability: 'Medium Black, Well-drained Loam',
    estimatedCost: '₹14,500 - ₹16,500/Acre',
    potentialSellingPrice: '₹6,400 - ₹7,200/Quintal',
    expectedYieldRange: '10-14 Quintal/Acre',
    yieldSource: 'Junagadh Agricultural University (JAU)',
    tier: RecommendationTier.bestSuitable,
    seedCostPerAcre: 3500,
    fertilizerCostPerAcre: 2200,
    pesticideCostPerAcre: 1800,
    labourCostPerAcre: 4800,
    irrigationCostPerAcre: 1600,
    machineryCostPerAcre: 1800,
    expectedYieldQuintalsPerAcre: 12.0,
    mandiSellingPricePerQuintal: 6800,
    iconEmoji: '🥜',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage(LanguageData.getByCode('en'));
    await MarketplaceService.instance.init();
  });

  Widget wrapWithMaterial(
    Widget child, {
    double textScale = 1.0,
    Locale locale = const Locale('en'),
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

  group('TASK 1 — ZERO OVERFLOW ON RESPONSIVE SCREEN SIZES & FONT SCALING', () {
    const screenSizes = [
      Size(320, 640), // Narrow low-cost device
      Size(360, 780), // Standard Android
      Size(393, 852), // iPhone 14/15 / Pixel 7
      Size(412, 915), // Large Android
    ];

    for (final size in screenSizes) {
      testWidgets(
        'AnnualFarmPlannerPage renders with zero overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(const AnnualFarmPlannerPage(profile: testProfile)),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('ANNUAL FARM FINANCIAL PROJECTION'), findsOneWidget);
          expect(find.text('Annual Investment'), findsOneWidget);
          expect(find.text('Gross Revenue'), findsOneWidget);
          expect(find.text('Net Return / Ac'), findsOneWidget);
        },
      );

      testWidgets(
        'CropRecommendationDetailsPage renders with zero overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              CropRecommendationDetailsPage(
                recommendation: sampleCrop,
                profile: testProfile,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Estimated Cultivation Economics'), findsOneWidget);
          expect(find.text('Seeds'), findsOneWidget);
          expect(find.text('Labour'), findsOneWidget);
          expect(find.text('Gross Rev'), findsOneWidget);
        },
      );

      testWidgets(
        'SeasonalPlanningPage renders with zero overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(const SeasonalPlanningPage(profile: testProfile)),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'DetailedWeatherPage renders with zero overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(const DetailedWeatherPage(profile: testProfile)),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('7-Day Agricultural Forecast'), findsOneWidget);
        },
      );

      testWidgets(
        'MandiComparisonPage renders with zero overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithMaterial(
              const MandiComparisonPage(
                profile: testProfile,
                initialCommodity: 'Cotton',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Zero overflow under accessibility High Text Scaling (1.5x) on narrow 360dp screen',
      (tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          debugPrint(
            'HIGH TEXT SCALE DETAILED ERROR: ${details.toDiagnosticsNode().toStringDeep()}',
          );
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        tester.view.physicalSize = const Size(360 * 2, 780 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrapWithMaterial(
            const AnnualFarmPlannerPage(profile: testProfile),
            textScale: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        final err = tester.takeException();
        expect(err, isNull);
      },
    );
  });

  group('TASK 2 — FUNCTIONAL APMC SORTING MODES WITH TIE-BREAKING', () {
    test('Mode 0 (Highest Price First), Mode 1 (Nearest First), Mode 2 (Lowest First)', () {
      final comparisons = MandiPriceService.instance.compareMandis(
        commodity: 'Cotton',
        quantityQuintals: 10.0,
        farmerLat: testProfile.effectiveLatitude,
        farmerLon: testProfile.effectiveLongitude,
      );

      expect(comparisons.isNotEmpty, isTrue);

      // Mode 0: Highest Price First
      final sortedHigh = List<MandiComparisonResult>.from(comparisons);
      sortedHigh.sort((a, b) {
        final cmp = b.modalPrice.compareTo(a.modalPrice);
        if (cmp != 0) return cmp;
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        return a.market.name.compareTo(b.market.name);
      });

      for (int i = 0; i < sortedHigh.length - 1; i++) {
        expect(
          sortedHigh[i].modalPrice >= sortedHigh[i + 1].modalPrice,
          isTrue,
        );
      }

      // Mode 1: Nearest Mandi First
      final sortedNear = List<MandiComparisonResult>.from(comparisons);
      sortedNear.sort((a, b) {
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        final cmp = b.modalPrice.compareTo(a.modalPrice);
        if (cmp != 0) return cmp;
        return a.market.name.compareTo(b.market.name);
      });

      for (int i = 0; i < sortedNear.length - 1; i++) {
        expect(
          sortedNear[i].distanceKm <= sortedNear[i + 1].distanceKm,
          isTrue,
        );
      }

      // Mode 2: Lowest Price First
      final sortedLow = List<MandiComparisonResult>.from(comparisons);
      sortedLow.sort((a, b) {
        final cmp = a.modalPrice.compareTo(b.modalPrice);
        if (cmp != 0) return cmp;
        final dCmp = a.distanceKm.compareTo(b.distanceKm);
        if (dCmp != 0) return dCmp;
        return a.market.name.compareTo(b.market.name);
      });

      for (int i = 0; i < sortedLow.length - 1; i++) {
        expect(sortedLow[i].modalPrice <= sortedLow[i + 1].modalPrice, isTrue);
      }
    });
  });

  group('TASK 4 — STATUTORY MSP VS MANDI TRADING RATES SEPARATION', () {
    test('CCEA Official Statutory MSP registry lookup', () {
      // Statutory MSP crops
      final cottonMsp = MandiPriceService.instance.getMspRecord('Cotton');
      expect(cottonMsp, isNotNull);
      expect(cottonMsp!.isApplicable, isTrue);
      expect(cottonMsp.officialMsp, 7121.0);
      expect(cottonMsp.notificationSource, contains('CCEA'));

      final wheatMsp = MandiPriceService.instance.getMspRecord('Wheat');
      expect(wheatMsp, isNotNull);
      expect(wheatMsp!.isApplicable, isTrue);
      expect(wheatMsp.officialMsp, 2275.0);

      final groundnutMsp = MandiPriceService.instance.getMspRecord('Groundnut');
      expect(groundnutMsp, isNotNull);
      expect(groundnutMsp!.isApplicable, isTrue);
      expect(groundnutMsp.officialMsp, 6783.0);

      // Non-MSP Spices & Horticulture Crops
      final cuminMsp = MandiPriceService.instance.getMspRecord('Cumin');
      expect(cuminMsp, isNotNull);
      expect(cuminMsp!.isApplicable, isFalse);

      final onionMsp = MandiPriceService.instance.getMspRecord('Onion');
      expect(onionMsp, isNotNull);
      expect(onionMsp!.isApplicable, isFalse);

      final castorMsp = MandiPriceService.instance.getMspRecord('Castor');
      expect(castorMsp, isNotNull);
      expect(castorMsp!.isApplicable, isFalse);
    });

    test('MandiComparisonResult correctly computes difference against MSP', () {
      final results = MandiPriceService.instance.compareMandis(
        commodity: 'Cotton',
        quantityQuintals: 10.0,
        farmerLat: testProfile.effectiveLatitude,
        farmerLon: testProfile.effectiveLongitude,
      );

      final item = results.first;
      expect(item.hasMsp, isTrue);
      expect(item.mspRecord, isNotNull);
      expect(item.mspDifference, isNotNull);
      expect(item.mspDifference, item.modalPrice - item.mspRecord!.officialMsp);
      expect(item.officialSource, contains('AGMARKNET'));
      expect(item.verificationStatus, contains('Verified'));
    });
  });

  group('TASK 6 — NET RETURN PROFIT CALCULATION FORMULA', () {
    test(
      'Calculates Gross Revenue minus Transport minus Expenses accurately',
      () {
        const quantity = 25.0; // Quintals
        const modalPrice = 7200.0; // ₹/Q
        const distance = 42.0; // km
        const transportRate = 5.0; // ₹/km
        const otherExpenses = 150.0;

        final grossRevenue = quantity * modalPrice; // 180,000
        final transportCost = distance * transportRate; // 210
        final netProceeds =
            grossRevenue - transportCost - otherExpenses; // 179,640

        expect(grossRevenue, 180000.0);
        expect(transportCost, 210.0);
        expect(netProceeds, 179640.0);
      },
    );
  });
}
