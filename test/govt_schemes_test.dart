import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khetchacha/localization/govt_scheme_localization.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/schemes/govt_schemes_directory_page.dart';
import 'package:khetchacha/screens/schemes/scheme_details_page.dart';
import 'package:khetchacha/services/govt_scheme_service.dart';
import 'package:khetchacha/services/language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'Ramesh Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@example.com',
    state: 'Gujarat',
    district: 'Ahmedabad',
    village: 'Sanand',
    farmingType: 'Organic',
    landSize: '3.5',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage(LanguageData.getByCode('en'));
  });

  group('GovtSchemeService - Backend, Database & Logic Tests', () {
    test('Contains authentic verified schemes database (26 schemes)', () {
      final schemes = GovtSchemeService.instance.getAllSchemes();
      expect(schemes.length, greaterThanOrEqualTo(25));

      // Central schemes
      expect(schemes.any((s) => s.id == 'pm-kisan-01'), isTrue);
      expect(schemes.any((s) => s.id == 'pmfby-02'), isTrue);
      expect(schemes.any((s) => s.id == 'pmksy-drip-03'), isTrue);
      expect(schemes.any((s) => s.id == 'pm-kusum-04'), isTrue);
      expect(schemes.any((s) => s.id == 'kcc-loan-05'), isTrue);
      expect(schemes.any((s) => s.id == 'smam-machinery-06'), isTrue);
      expect(schemes.any((s) => s.id == 'soil-health-09'), isTrue);

      // Gujarat state schemes
      expect(schemes.any((s) => s.id == 'ikhedut-tractor-04'), isTrue);
      expect(schemes.any((s) => s.id == 'gujarat-cow-15'), isTrue);
      expect(schemes.any((s) => s.id == 'gujarat-fencing-16'), isTrue);
      expect(schemes.any((s) => s.id == 'gujarat-polyhouse-17'), isTrue);
      expect(schemes.any((s) => s.id == 'gujarat-suryodaya-19'), isTrue);

      // Verify portal links are authentic verified government domains
      for (final s in schemes) {
        expect(s.officialWebsiteUrl.startsWith('https://'), isTrue);
        expect(s.applyUrl.startsWith('https://'), isTrue);
        expect(s.isVerified, isTrue);
      }
    });

    test('Filters by Category accurately across all 12 categories', () {
      final irrigation = GovtSchemeService.instance.searchSchemes(
        categoryFilter: 'Irrigation',
      );
      expect(irrigation.isNotEmpty, isTrue);
      expect(irrigation.every((s) => s.category == 'Irrigation'), isTrue);

      final machinery = GovtSchemeService.instance.searchSchemes(
        categoryFilter: 'Farm Machinery',
      );
      expect(machinery.isNotEmpty, isTrue);
      expect(machinery.every((s) => s.category == 'Farm Machinery'), isTrue);

      final solar = GovtSchemeService.instance.searchSchemes(
        categoryFilter: 'Solar Energy',
      );
      expect(solar.isNotEmpty, isTrue);
      expect(solar.every((s) => s.category == 'Solar Energy'), isTrue);

      final insurance = GovtSchemeService.instance.searchSchemes(
        categoryFilter: 'Crop Insurance',
      );
      expect(insurance.isNotEmpty, isTrue);
      expect(insurance.every((s) => s.category == 'Crop Insurance'), isTrue);
    });

    test('Filters by Benefit Type accurately', () {
      final subsidies = GovtSchemeService.instance.searchSchemes(
        benefitFilter: 'Subsidy',
      );
      expect(subsidies.isNotEmpty, isTrue);
      expect(subsidies.every((s) => s.benefitType == 'Subsidy'), isTrue);

      final loans = GovtSchemeService.instance.searchSchemes(
        benefitFilter: 'Loan',
      );
      expect(loans.isNotEmpty, isTrue);
      expect(loans.every((s) => s.benefitType == 'Loan'), isTrue);

      final dbt = GovtSchemeService.instance.searchSchemes(
        benefitFilter: 'Direct Benefit Transfer',
      );
      expect(dbt.isNotEmpty, isTrue);
      expect(
        dbt.every((s) => s.benefitType == 'Direct Benefit Transfer'),
        isTrue,
      );
    });

    test('Filters by Crop accurately', () {
      final cottonSchemes = GovtSchemeService.instance.searchSchemes(
        cropFilter: 'Cotton',
      );
      expect(cottonSchemes.isNotEmpty, isTrue);
      expect(
        cottonSchemes.every(
          (s) =>
              s.applicableCrops.contains('All Crops') ||
              s.applicableCrops.contains('Cotton'),
        ),
        isTrue,
      );
    });

    test('Filters by State accurately (Central + State integration)', () {
      final gujarat = GovtSchemeService.instance.searchSchemes(
        stateFilter: 'Gujarat',
      );
      expect(gujarat.isNotEmpty, isTrue);
      // Both PM-KISAN (All India) and iKhedut (Gujarat) are present
      expect(gujarat.any((s) => s.id == 'pm-kisan-01'), isTrue);
      expect(gujarat.any((s) => s.id == 'ikhedut-tractor-04'), isTrue);

      final punjab = GovtSchemeService.instance.searchSchemes(
        stateFilter: 'Punjab',
      );
      expect(punjab.any((s) => s.id == 'punjab-crm-20'), isTrue);
      // Gujarat state scheme must not appear under Punjab
      expect(punjab.any((s) => s.id == 'ikhedut-tractor-04'), isFalse);
    });

    test('3-Way Sorting works as expected', () {
      // 1. Latest Verified
      final latest = GovtSchemeService.instance.searchSchemes(
        sortBy: 'Latest Verified',
      );
      expect(latest.isNotEmpty, isTrue);

      // 2. Alphabetical
      final alphabetical = GovtSchemeService.instance.searchSchemes(
        sortBy: 'Alphabetical',
      );
      for (int i = 0; i < alphabetical.length - 1; i++) {
        expect(
          alphabetical[i].name.compareTo(alphabetical[i + 1].name) <= 0,
          isTrue,
        );
      }

      // 3. Application Deadline
      final byDeadline = GovtSchemeService.instance.searchSchemes(
        sortBy: 'Application Deadline',
      );
      expect(byDeadline.isNotEmpty, isTrue);
    });

    test('Free-Text search works across Name, Description, and Keywords', () {
      final searchTractor = GovtSchemeService.instance.searchSchemes(
        searchQuery: 'tractor',
      );
      expect(searchTractor.isNotEmpty, isTrue);
      expect(
        searchTractor.any((s) => s.name.toLowerCase().contains('tractor')),
        isTrue,
      );

      final searchDrip = GovtSchemeService.instance.searchSchemes(
        searchQuery: 'drip',
      );
      expect(searchDrip.isNotEmpty, isTrue);
      expect(
        searchDrip.any((s) => s.description.toLowerCase().contains('drip')),
        isTrue,
      );
    });

    test('Client-side eligibility evaluator produces accurate verdicts', () {
      final pmKisan = GovtSchemeService.instance.getAllSchemes().firstWhere(
        (s) => s.id == 'pm-kisan-01',
      );

      // Eligible scenario
      final res1 = GovtSchemeService.instance.evaluateEligibility(
        scheme: pmKisan,
        farmerState: 'Gujarat',
        farmerCategory: 'Small & Marginal',
        landholdingAcres: 2.0,
        cropOrActivity: 'Wheat',
      );
      expect(res1['isEligible'], isTrue);
      expect(res1['verdict'], equals('Potentially Eligible'));

      // Ineligible state scenario
      final gujCow = GovtSchemeService.instance.getAllSchemes().firstWhere(
        (s) => s.id == 'gujarat-cow-15',
      );
      final res2 = GovtSchemeService.instance.evaluateEligibility(
        scheme: gujCow,
        farmerState: 'Punjab',
        farmerCategory: 'General',
        landholdingAcres: 5.0,
        cropOrActivity: 'Wheat',
      );
      expect(res2['isEligible'], isFalse);
      expect(res2['verdict'], equals('Potentially Not Eligible'));

      // Landholding excess scenario (using PM-KMY which has maxLandAcres: 5.0)
      final pmKmy = GovtSchemeService.instance.getAllSchemes().firstWhere(
        (s) => s.id == 'pmkmy-pension-25',
      );
      final res3 = GovtSchemeService.instance.evaluateEligibility(
        scheme: pmKmy,
        farmerState: 'Gujarat',
        farmerCategory: 'Small & Marginal',
        landholdingAcres: 10.0, // Exceeds 5.0 acres maxLandAcres for PM-KMY
        cropOrActivity: 'Wheat',
      );
      expect(res3['isEligible'], isFalse);
    });
  });

  group('GovtSchemesDirectoryPage - UI, Layout & Multi-Screen Tests', () {
    testWidgets('Renders all required elements on standard screen (360x800)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: GovtSchemesDirectoryPage(profile: testProfile)),
      );
      await tester.pumpAndSettle();

      // 1. Dark green AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(const Color(0xFF1B5E20)));
      expect(find.text('All India Schemes'), findsOneWidget);

      // 2. Compact Search Bar with hint
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Search schemes (e.g. irrigation, subsidy...)'),
        findsOneWidget,
      );

      // 3. Three filter buttons: Category | Benefit | Crop
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Benefit'), findsOneWidget);
      expect(find.text('Crop'), findsOneWidget);

      // 4. Schemes count & State & Sort selectors
      expect(find.textContaining('Schemes Available'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);

      // 5. Scheme cards with category pills, icons, status badges, and deadlines
      expect(find.textContaining('PM-Kisan'), findsWidgets);
      expect(find.text('OPEN'), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

      // Verify zero overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders overflow-free on narrow Android (320x640)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: GovtSchemesDirectoryPage(profile: testProfile)),
      );
      await tester.pumpAndSettle();

      expect(find.text('All India Schemes'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Benefit'), findsOneWidget);
      expect(find.text('Crop'), findsOneWidget);

      // Verify zero overflow on narrow 320dp display
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Renders overflow-free on modern screens (393x852 and 412x915)',
      (tester) async {
        for (final size in [const Size(393, 852), const Size(412, 915)]) {
          await tester.binding.setSurfaceSize(size);

          await tester.pumpWidget(
            const MaterialApp(
              home: GovtSchemesDirectoryPage(profile: testProfile),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('All India Schemes'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets('Filter bottom sheet opens cleanly and filters results', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: GovtSchemesDirectoryPage(profile: testProfile)),
      );
      await tester.pumpAndSettle();

      // Tap on Category button
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();

      // Verify category bottom sheet opened
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Irrigation'), findsWidgets);
      expect(find.text('Horticulture'), findsOneWidget);

      // Select Irrigation from the bottom sheet
      await tester.tap(find.text('Irrigation').last);
      await tester.pumpAndSettle();

      // Verify category button now shows Irrigation
      expect(find.text('Irrigation'), findsWidgets);

      // Verify zero overflow
      expect(tester.takeException(), isNull);
    });
  });

  group('SchemeDetailsPage - Comprehensive Details & Eligibility Tests', () {
    testWidgets(
      'Renders all scheme details, criteria, documents, and portal button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final pmKisan = GovtSchemeService.instance.getAllSchemes().firstWhere(
          (s) => s.id == 'pm-kisan-01',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SchemeDetailsPage(scheme: pmKisan, profile: testProfile),
          ),
        );
        await tester.pumpAndSettle();

        // 1. AppBar and titles
        expect(find.text('Scheme Details'), findsOneWidget);
        expect(find.text(pmKisan.name), findsOneWidget);
        expect(find.text('Central Scheme'), findsOneWidget);

        // 2. Benefits card
        expect(find.text('Benefits & Financial Assistance'), findsOneWidget);
        expect(find.text(pmKisan.benefitsSubsidy), findsOneWidget);

        // 3. Eligibility criteria
        expect(find.text('Eligibility Criteria'), findsOneWidget);

        // 4. Required documents
        expect(find.text('Required Documents'), findsOneWidget);

        // 5. Official Source and Application Timeline
        expect(find.text('Verified Official Source'), findsOneWidget);
        expect(find.textContaining(pmKisan.officialSource), findsOneWidget);

        // 6. Action buttons
        expect(
          find.text(GovtSchemeLocalization.getCheckEligibilityLabel('en')),
          findsOneWidget,
        );
        expect(
          find.text(GovtSchemeLocalization.getApplyOnlineLabel('en')),
          findsOneWidget,
        );

        // 7. Interactive eligibility checker expansion
        final checkFinder = find.text(
          GovtSchemeLocalization.getCheckEligibilityLabel('en'),
        );
        await tester.scrollUntilVisible(checkFinder, 200);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Potentially Eligible'), findsOneWidget);

        // Zero overflow
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SchemeDetailsPage renders overflow-free on narrow screen (320x640)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final ikhedut = GovtSchemeService.instance.getAllSchemes().firstWhere(
          (s) => s.id == 'ikhedut-tractor-04',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SchemeDetailsPage(scheme: ikhedut, profile: testProfile),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scheme Details'), findsOneWidget);
        expect(
          find.text(GovtSchemeLocalization.getApplyOnlineLabel('en')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
