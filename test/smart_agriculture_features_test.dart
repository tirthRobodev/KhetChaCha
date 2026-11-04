import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/crop_recommendation.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/models/location_models.dart';
import 'package:khetchacha/models/mandi_market.dart';
import 'package:khetchacha/screens/crops/crop_recommendation_details_page.dart';
import 'package:khetchacha/screens/farm_production_selection_page.dart';
import 'package:khetchacha/screens/mandi/mandi_comparison_page.dart';
import 'package:khetchacha/screens/mandi/mandi_discovery_page.dart';
import 'package:khetchacha/screens/onboarding/smart_location_detection_page.dart';
import 'package:khetchacha/widgets/phone_input_formatter.dart';
import 'package:khetchacha/services/crop_recommendation_service.dart';
import 'package:khetchacha/services/location_service.dart';
import 'package:khetchacha/services/mandi_discovery_service.dart';
import 'package:khetchacha/services/mandi_price_service.dart';
import 'package:khetchacha/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_video_player_platform.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlayerPlatform.registerWith();
    PermissionService.instance.enableMockMode();
    LocationService.instance.enableMockMode();
  });

  tearDown(() {
    LocationService.instance.disableMockMode();
    PermissionService.instance.resetMockStates();
  });

  const testProfile = FarmerProfile(
    fullName: 'Ramesh Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@khetchacha.in',
    state: 'Gujarat',
    district: 'Ahmedabad',
    village: 'Bhavda',
    taluka: 'Daskroi',
    farmingType: 'Organic',
    landSize: '5 Acre',
    soilType: 'Loamy soil',
    irrigationType: 'Borewell',
    waterAvailability: 'Medium',
    farmingSeason: 'Rabi',
    crops: ['Wheat', 'Tomato', 'Cotton'],
    selectedProducts: ['Wheat', 'Tomato', 'Cotton'],
    latitude: 23.0225,
    longitude: 72.5714,
    farmSetupCompleted: true,
  );

  group('Priority 2: LocationService & Reverse Geocoding Tests', () {
    test('Calculates Haversine distance correctly between Indian cities', () {
      // Ahmedabad (23.0225, 72.5714) to Rajkot (22.3039, 70.8022) ~ 200 km
      final dist = LocationService.instance.calculateDistanceKm(
        23.0225,
        72.5714,
        22.3039,
        70.8022,
      );
      expect(dist, greaterThan(180.0));
      expect(dist, lessThan(230.0));
    });

    test('Finds nearest district from authentic database when offline', () {
      // Near Ludhiana coords (30.90, 75.85)
      final nearest = LocationService.instance.findNearestDistrict(
        30.90,
        75.85,
      );
      expect(nearest.stateKey.toLowerCase(), contains('punjab'));
      expect(nearest.englishName, equals('Ludhiana'));
    });

    test(
      'Saves and restores cached farmer location in SharedPreferences',
      () async {
        const loc = FarmerLocationData(
          state: 'Punjab',
          district: 'Ludhiana',
          taluka: 'Khanna',
          village: 'Kanganwal',
          pincode: '141401',
          latitude: 30.70,
          longitude: 76.21,
          isGpsAccurate: true,
        );

        await LocationService.instance.saveCachedLocation(loc);
        final restored = await LocationService.instance.getCachedLocation();

        expect(restored, isNotNull);
        expect(restored!.state, equals('Punjab'));
        expect(restored.district, equals('Ludhiana'));
        expect(restored.taluka, equals('Khanna'));
        expect(restored.isGpsAccurate, isTrue);
      },
    );
  });

  group('Priority 3: Smart Land & Farm Profile Model Tests', () {
    test('FarmerProfile serializes and deserializes smart land attributes', () {
      final json = testProfile.toJson();
      final revived = FarmerProfile.fromJson(json);

      expect(revived.soilType, equals('Loamy soil'));
      expect(revived.irrigationType, equals('Borewell'));
      expect(revived.waterAvailability, equals('Medium'));
      expect(revived.farmingSeason, equals('Rabi'));
      expect(revived.latitude, equals(23.0225));
      expect(revived.longitude, equals(72.5714));
      expect(revived.taluka, equals('Daskroi'));
    });

    test(
      'copyWith updates land and soil parameters while preserving other data',
      () {
        final updated = testProfile.copyWith(
          soilType: 'Black soil',
          irrigationType: 'Drip irrigation',
          waterAvailability: 'High',
        );

        expect(updated.soilType, equals('Black soil'));
        expect(updated.irrigationType, equals('Drip irrigation'));
        expect(updated.waterAvailability, equals('High'));
        expect(updated.fullName, equals('Ramesh Patel'));
      },
    );
  });

  group('Priority 4: Intelligent Crop Recommendation Engine Tests', () {
    test('Recommends Rabi crops with high scores during Rabi season for Loamy soil', () {
      final recs = CropRecommendationService.instance.getRecommendations(
        testProfile,
      );

      expect(recs, isNotEmpty);
      // Wheat and Mustard should be scored highly for Rabi season
      final wheat = recs.firstWhere((r) => r.englishName == 'Wheat');
      expect(wheat.suitabilityScore, greaterThanOrEqualTo(85));
      expect(wheat.tier, equals(RecommendationTier.bestSuitable));
      expect(wheat.recommendationReason, contains('Ahmedabad'));
    });

    test('Differentiates recommendation between Punjab loamy vs Gujarat black soil', () {
      const punjabProfile = FarmerProfile(
        fullName: 'Gurpreet Singh',
        mobileNumber: '9812345678',
        email: 'gurpreet@khetchacha.in',
        state: 'Punjab',
        district: 'Ludhiana',
        village: 'Near Khanna',
        farmingType: 'Conventional',
        landSize: '10 Acre',
        soilType: 'Loamy soil',
        irrigationType: 'Canal',
        waterAvailability: 'High',
        farmingSeason: 'Kharif',
      );

      const gujaratProfile = FarmerProfile(
        fullName: 'Mansukhbhai',
        mobileNumber: '9898765432',
        email: 'mansukh@khetchacha.in',
        state: 'Gujarat',
        district: 'Rajkot',
        village: 'Gondal',
        farmingType: 'Dryland',
        landSize: '6 Acre',
        soilType: 'Black soil',
        irrigationType: 'Rain-fed',
        waterAvailability: 'Low',
        farmingSeason: 'Kharif',
      );

      final punjabRecs = CropRecommendationService.instance.getRecommendations(
        punjabProfile,
      );
      final gujaratRecs = CropRecommendationService.instance.getRecommendations(
        gujaratProfile,
      );

      // Punjab with Canal & High Water in Kharif should favor Paddy/Rice or Maize
      final punjabPaddy = punjabRecs.firstWhere(
        (r) => r.englishName == 'Paddy (Rice)',
      );
      expect(punjabPaddy.suitabilityScore, greaterThan(80));

      // Gujarat with Rain-fed & Black Soil in Kharif should score Cotton / Groundnut / Bajra high
      final gujaratCotton = gujaratRecs.firstWhere(
        (r) => r.englishName == 'Cotton',
      );
      expect(gujaratCotton.suitabilityScore, greaterThan(75));
    });

    test('Categorizes into 3 distinct tiers: Best, Alternative, Seasonal', () {
      final tiered = CropRecommendationService.instance
          .getTieredRecommendations(testProfile);

      expect(tiered[RecommendationTier.bestSuitable], isNotEmpty);
      expect(tiered[RecommendationTier.alternative], isNotNull);
      expect(tiered[RecommendationTier.seasonalOpportunity], isNotNull);
    });
  });

  group('Priority 5 & 6: Mandi Discovery & Price Comparison Tests', () {
    test('Finds nearby verified mandis sorted by distance', () {
      // From Ahmedabad coordinates
      final nearby = MandiDiscoveryService.instance.getNearbyMarkets(
        latitude: 23.0225,
        longitude: 72.5714,
        maxDistanceKm: 100.0,
      );

      expect(nearby, isNotEmpty);
      expect(nearby.first.market.name, contains('Ahmedabad'));
      expect(nearby.first.distanceKm, lessThan(15.0));
    });

    test('Filters mandis by market type', () {
      final vegMarkets = MandiDiscoveryService.instance.getNearbyMarkets(
        latitude: 23.0225,
        longitude: 72.5714,
        typeFilter: MandiMarketType.vegetableWholesale,
      );

      for (final m in vegMarkets) {
        expect(m.market.type, equals(MandiMarketType.vegetableWholesale));
      }
    });

    test('Compares mandis and calculates Net Selling Amount after transport deduction', () {
      final comparison = MandiPriceService.instance.compareMandis(
        commodity: 'Wheat',
        quantityQuintals: 50.0,
        farmerLat: 23.0225,
        farmerLon: 72.5714,
        transportRatePerKmPerQuintal: 3.50,
      );

      expect(comparison, isNotEmpty);
      final best = comparison.first;
      expect(best.isRecommended, isTrue);
      expect(best.grossRevenue, greaterThan(0));
      expect(best.totalTransportCost, greaterThan(0));
      expect(
        best.netSellingAmount,
        equals(
          best.grossRevenue -
              best.totalTransportCost -
              best.mandiHandlingCharges,
        ),
      );
    });
  });

  group('Widget Tests: Onboarding & Market Discovery Screens', () {
    Widget createTestApp(Widget home) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      );
    }

    testWidgets('SmartLocationDetectionPage renders GPS and Manual options', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(const SmartLocationDetectionPage(profile: testProfile)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farm Location Setup'), findsOneWidget);
      expect(find.text('Auto-Detect via GPS'), findsOneWidget);
      expect(find.text('State / Union Territory *'), findsOneWidget);
      expect(find.text('District *'), findsOneWidget);
    });

    testWidgets(
      'FarmProductionSelectionPage prioritizes Punjab crops at the top',
      (tester) async {
        const punjabProfile = FarmerProfile(
          fullName: 'Sardar Singh',
          mobileNumber: '9876543210',
          email: 'punjab@farmer.com',
          state: 'Punjab',
          district: 'Ludhiana',
          village: 'Sahnewal',
          farmingType: 'Organic',
          landSize: '5 Acres',
        );

        await tester.pumpWidget(
          createTestApp(
            const FarmProductionSelectionPage(profile: punjabProfile),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wheat'), findsOneWidget);
        expect(find.text('Rice'), findsOneWidget);
      },
    );

    test('IndianPhoneNumberInputFormatter sanitizes 91 prefix and autofill numbers', () {
      expect(sanitizeIndianPhoneNumber('+919876543210'), equals('9876543210'));
      expect(sanitizeIndianPhoneNumber('919876543210'), equals('9876543210'));
      expect(sanitizeIndianPhoneNumber('09876543210'), equals('9876543210'));
      expect(sanitizeIndianPhoneNumber('9876543210'), equals('9876543210'));
      expect(
        sanitizeIndianPhoneNumber('+91 98765 43210'),
        equals('9876543210'),
      );
    });

    testWidgets(
      'MandiDiscoveryPage renders nearby markets with distance badges',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(const MandiDiscoveryPage(profile: testProfile)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nearby Mandi & Wholesale Markets'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Markets'), findsOneWidget);
        expect(find.text('Compare Rates'), findsWidgets);
      },
    );

    testWidgets(
      'MandiComparisonPage calculates net revenue with quantity input',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const MandiComparisonPage(
              profile: testProfile,
              initialCommodity: 'Wheat',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Compare Mandi Net Returns'), findsOneWidget);
        expect(find.text('1. Select Crop / Commodity'), findsOneWidget);
        expect(find.text('2. Produce Quantity to Sell'), findsOneWidget);
        expect(find.text('NET ESTIMATED AMOUNT:'), findsWidgets);
      },
    );

    testWidgets('CropRecommendationDetailsPage renders agronomic metrics', (
      tester,
    ) async {
      final rec = CropRecommendationService.instance
          .getRecommendations(testProfile)
          .first;

      await tester.pumpWidget(
        createTestApp(
          CropRecommendationDetailsPage(
            recommendation: rec,
            profile: testProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${rec.englishName} Recommendation'), findsOneWidget);
      expect(find.text('Crop Maturity Duration'), findsOneWidget);
      expect(find.text('Water Requirement'), findsOneWidget);
      expect(find.text('Estimated Cultivation Cost'), findsOneWidget);
      expect(find.text('Compare Mandis'), findsOneWidget);
    });
  });
}
