import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/farm_products_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farm_production_selection_page.dart';
import 'package:khetchacha/screens/farmer_dashboard_page.dart';
import 'package:khetchacha/services/farming_recommendation_service.dart';
import 'package:khetchacha/widgets/farmer_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FarmerProfile & Firebase Schema (Section 9)', () {
    test(
      'Serializes and deserializes all required Firebase fields correctly',
      () {
        final profile = FarmerProfile(
          fullName: 'Tirth Patel',
          mobileNumber: '9876543210',
          email: 'tirth@khetchacha.com',
          state: 'Gujarat',
          district: 'Rajkot',
          village: 'Gondal',
          farmingType: 'Organic',
          landSize: '2 - 5 Acres',
          crops: ['Paddy (Rice)', 'Tomato'],
          firebaseUid: 'firebase_user_abc123',
          isPhoneVerified: true,
          selectedLanguage: 'gu',
          selectedState: 'Gujarat',
          selectedDistrict: 'Rajkot',
          selectedCategories: ['crops', 'vegetables'],
          selectedProducts: ['Paddy (Rice)', 'Tomato'],
          farmSize: '2 - 5 Acres',
          farmSetupCompleted: true,
          updatedAt: '2026-11-01T10:00:00Z',
        );

        final json = profile.toJson();

        expect(json['fullName'], 'Tirth Patel');
        expect(json['mobileNumber'], '9876543210');
        expect(json['email'], 'tirth@khetchacha.com');
        expect(json['firebaseUid'], 'firebase_user_abc123');
        expect(json['isPhoneVerified'], true);
        expect(json['selectedLanguage'], 'gu');
        expect(json['selectedState'], 'Gujarat');
        expect(json['selectedDistrict'], 'Rajkot');
        expect(json['selectedCategories'], ['crops', 'vegetables']);
        expect(json['selectedProducts'], ['Paddy (Rice)', 'Tomato']);
        expect(json['farmSize'], '2 - 5 Acres');
        expect(json['farmSetupCompleted'], true);
        expect(json['updatedAt'], isNotEmpty);

        // Verify deserialization
        final restored = FarmerProfile.fromJson(json);
        expect(restored.fullName, 'Tirth Patel');
        expect(restored.effectiveState, 'Gujarat');
        expect(restored.effectiveDistrict, 'Rajkot');
        expect(restored.effectiveProducts, ['Paddy (Rice)', 'Tomato']);
        expect(restored.effectiveFarmSize, '2 - 5 Acres');
        expect(restored.farmSetupCompleted, true);
      },
    );
  });

  group('State-Wise Farmer Avatar System (Section 3)', () {
    test('Resolves state key accurately for English state names', () {
      expect(FarmerAvatar.resolveStateKey('Gujarat'), 'gujarat');
      expect(FarmerAvatar.resolveStateKey('Punjab'), 'punjab');
      expect(FarmerAvatar.resolveStateKey('Kerala'), 'kerala');
      expect(FarmerAvatar.resolveStateKey('Rajasthan'), 'rajasthan');
      expect(FarmerAvatar.resolveStateKey('Maharashtra'), 'maharashtra');
      expect(FarmerAvatar.resolveStateKey('Uttar Pradesh'), 'uttar_pradesh');
      expect(FarmerAvatar.resolveStateKey('Tamil Nadu'), 'default');
    });

    test(
      'Resolves state key accurately for regional localized state names',
      () {
        expect(FarmerAvatar.resolveStateKey('ગુજરાત'), 'gujarat');
        expect(FarmerAvatar.resolveStateKey('ਪੰਜਾਬ'), 'punjab');
        expect(FarmerAvatar.resolveStateKey('കേരളം'), 'kerala');
        expect(FarmerAvatar.resolveStateKey('राजस्थान'), 'rajasthan');
        expect(FarmerAvatar.resolveStateKey('महाराष्ट्र'), 'maharashtra');
        expect(FarmerAvatar.resolveStateKey('उत्तर प्रदेश'), 'uttar_pradesh');
      },
    );

    test(
      'Maps to designated asset illustrations in assets/images/farmers/',
      () {
        expect(
          FarmerAvatar.getAssetPathForState('Gujarat'),
          'assets/images/farmers/gujarat.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Punjab'),
          'assets/images/farmers/punjab.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Kerala'),
          'assets/images/farmers/kerala.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Rajasthan'),
          'assets/images/farmers/rajasthan.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Maharashtra'),
          'assets/images/farmers/maharashtra.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Uttar Pradesh'),
          'assets/images/farmers/uttar_pradesh.png',
        );
        expect(
          FarmerAvatar.getAssetPathForState('Goa'),
          'assets/images/farmers/default_farmer.png',
        );
      },
    );
  });

  group('Farm Products Data & Filtering (Section 2 & 5)', () {
    test('Contains popular crops matching design screenshot', () {
      final popular = FarmProductsData.popularProducts;
      expect(popular.length, greaterThanOrEqualTo(10));

      final popularIds = popular.map((p) => p.id).toSet();
      expect(popularIds.contains('wheat'), isTrue);
      expect(popularIds.contains('paddy'), isTrue);
      expect(popularIds.contains('cotton'), isTrue);
      expect(popularIds.contains('maize'), isTrue);
      expect(popularIds.contains('groundnut'), isTrue);
      expect(popularIds.contains('soybean'), isTrue);
      expect(popularIds.contains('sugarcane'), isTrue);
      expect(popularIds.contains('mustard'), isTrue);
      expect(popularIds.contains('potato'), isTrue);
      expect(popularIds.contains('onion'), isTrue);
      expect(popularIds.contains('tomato'), isTrue);
    });

    test('Filters correctly across all 4 categories', () {
      final crops = FarmProductsData.getProductsByCategory('crops');
      final vegetables = FarmProductsData.getProductsByCategory('vegetables');
      final fruits = FarmProductsData.getProductsByCategory('fruits');
      final flowers = FarmProductsData.getProductsByCategory('flowers');

      expect(crops.isNotEmpty, isTrue);
      expect(vegetables.isNotEmpty, isTrue);
      expect(fruits.isNotEmpty, isTrue);
      expect(flowers.isNotEmpty, isTrue);
    });

    test('Live search handles English and Gujarati crop names', () {
      final wheatEn = FarmProductsData.search('Wheat');
      expect(wheatEn.any((p) => p.id == 'wheat'), isTrue);

      final cottonGu = FarmProductsData.search('કપાસ');
      expect(cottonGu.any((p) => p.id == 'cotton'), isTrue);

      final tomatoHi = FarmProductsData.search('टमाटर');
      expect(tomatoHi.any((p) => p.id == 'tomato'), isTrue);
    });
  });

  group('State-Wise Farming Personalization (Section 5)', () {
    test('Provides distinct, specialized advisories for Gujarat, Punjab, and Kerala', () {
      final recService = FarmingRecommendationService.instance;

      final gujAdv = recService.getPersonalizedAdvisories(
        stateName: 'Gujarat',
        districtName: 'Rajkot',
        selectedProducts: ['Cotton', 'Groundnut'],
        langCode: 'en',
      );
      expect(
        gujAdv.any((a) => a.contains('GGRC') || a.contains('cotton')),
        isTrue,
      );

      final punjabAdv = recService.getPersonalizedAdvisories(
        stateName: 'Punjab',
        districtName: 'Ludhiana',
        selectedProducts: ['Wheat', 'Paddy'],
        langCode: 'en',
      );
      expect(
        punjabAdv.any((a) => a.contains('PAU') || a.contains('Happy Seeder')),
        isTrue,
      );

      final keralaAdv = recService.getPersonalizedAdvisories(
        stateName: 'Kerala',
        districtName: 'Kottayam',
        selectedProducts: ['Paddy', 'Banana'],
        langCode: 'en',
      );
      expect(
        keralaAdv.any(
          (a) =>
              a.contains('lime') ||
              a.contains('acidity') ||
              a.contains('Krishi Bhavan'),
        ),
        isTrue,
      );
    });
  });

  group('Multilingual UI Translation (Section 4)', () {
    test('AppLocalizations provides complete Gujarati translations for Dashboard & Crops', () {
      final loc = AppLocalizations(const Locale('gu'));

      expect(loc.selectFarmProductionTitle, 'તમારા ખેતરના પાક પસંદ કરો');
      expect(loc.continueToDashboard, 'ડેશબોર્ડ પર આગળ વધો →');
      expect(loc.welcomeGreeting('તીર્થ'), 'સ્વાગત છે, તીર્થ 👋');
      expect(loc.myFarmButton, 'મારું ખેતર');
      expect(loc.cropAdvisoryTitle, 'પાક સલાહ');
      expect(loc.mandiRatesTitle, 'બજાર ભાવ (મંડી)');
      expect(loc.farmCalculatorTitle, 'કૃષિ કેલ્ક્યુલેટર');
      expect(loc.navHome, 'હોમ');
      expect(loc.navCrops, 'પાક');
    });

    test('AppLocalizations provides complete Punjabi translations for Dashboard & Crops', () {
      final loc = AppLocalizations(const Locale('pa'));

      expect(loc.selectFarmProductionTitle, 'ਆਪਣੇ ਖੇਤ ਦੀਆਂ ਫ਼ਸਲਾਂ ਚੁਣੋ');
      expect(loc.continueToDashboard, 'ਡੈਸ਼ਬੋਰਡ \'ਤੇ ਅੱਗੇ ਵਧੋ →');
      expect(loc.welcomeGreeting('ਗੁਰਪ੍ਰੀਤ'), 'ਜੀ ਆਇਆਂ ਨੂੰ, ਗੁਰਪ੍ਰੀਤ 👋');
      expect(loc.myFarmButton, 'ਮੇਰਾ ਖੇਤ');
      expect(loc.cropAdvisoryTitle, 'ਫ਼ਸਲ ਸਲਾਹ');
      expect(loc.mandiRatesTitle, 'ਮੰਡੀ ਭਾਅ');
      expect(loc.navHome, 'ਮੁੱਖ');
      expect(loc.navCrops, 'ਫ਼ਸਲਾਂ');
    });
  });

  group('Widget Tests: Farm Production Selection & Dashboard (Section 2 & 6)', () {
    testWidgets(
      'FarmProductionSelectionPage renders progress, categories, and toggles selection',
      (tester) async {
        const profile = FarmerProfile(
          fullName: 'Tirth',
          mobileNumber: '9876543210',
          email: 'tirth@gmail.com',
          state: 'Gujarat',
          district: 'Rajkot',
          village: 'Gondal',
          farmingType: 'Organic',
          landSize: '2 - 5 Acres',
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
            home: const FarmProductionSelectionPage(profile: profile),
          ),
        );

        await tester.pumpAndSettle();

        // Check header and titles
        expect(find.text('Select Your Farm Production'), findsOneWidget);
        expect(find.text('All (Popular)'), findsOneWidget);
        expect(find.text('Crops'), findsOneWidget);
        expect(find.text('Vegetables'), findsOneWidget);
        expect(find.text('Continue to Dashboard →'), findsOneWidget);

        // Verify Wheat and Cotton appear
        expect(find.text('Wheat'), findsOneWidget);
        expect(find.text('Cotton'), findsAtLeastNWidgets(1));
        expect(find.text('More Products'), findsOneWidget);
      },
    );

    testWidgets(
      'FarmerDashboardPage renders welcome card, farmer avatar, and 12 quick access cards',
      (tester) async {
        const profile = FarmerProfile(
          fullName: 'Tirth',
          mobileNumber: '9876543210',
          email: 'tirth@gmail.com',
          state: 'Kerala',
          district: 'Kottayam',
          village: 'Kumarakom',
          farmingType: 'Commercial',
          landSize: '2 - 5 Acres',
          crops: ['Paddy', 'Tomato'],
          selectedState: 'Kerala',
          selectedDistrict: 'Kottayam',
          selectedProducts: ['Paddy', 'Tomato'],
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
            home: const FarmerDashboardPage(profile: profile),
          ),
        );

        await tester.pump();

        // Verify Welcome card elements
        expect(find.text('Welcome, Tirth 👋'), findsOneWidget);
        expect(find.text('Kottayam, Kerala'), findsOneWidget);
        expect(find.text('My Farm'), findsOneWidget);

        // Verify FarmerAvatar is present
        expect(find.byType(FarmerAvatar), findsOneWidget);

        // Verify Quick Access section (9 Prioritized Services as per PS000046)
        expect(find.text('Quick Access'), findsOneWidget);
        expect(find.text('AI Crop & Farm Plan'), findsOneWidget);
        expect(find.text('Government Schemes'), findsOneWidget);
        expect(find.text('Govt News & SMS'), findsOneWidget);
        expect(find.text('Ask Agri Expert'), findsOneWidget);
        expect(find.text('AI Crop Diagnosis'), findsOneWidget);
        expect(find.text('Crop Advisory'), findsOneWidget);
        expect(find.text('Weather Forecast'), findsOneWidget);
        expect(find.text('Mandi Rates'), findsOneWidget);
        expect(find.text('Fertilizer Guide'), findsOneWidget);

        // Verify Dashboard 2.0 Bottom Navigation
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Crops'), findsOneWidget);
        expect(find.text('AI Assistant'), findsOneWidget);
        expect(find.text('Image AI'), findsOneWidget);
        expect(find.text('Voice AI'), findsOneWidget);

        // Verify My Farm Overview
        expect(find.text('My Farm Overview'), findsOneWidget);
      },
    );
  });
}
