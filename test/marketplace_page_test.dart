import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/marketplace/natural_farming_marketplace_page.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:khetchacha/services/marketplace_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'Ramesh Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@patel.com',
    state: 'Gujarat',
    district: 'Anand',
    village: 'Mogri',
    farmingType: 'Natural',
    landSize: '5 Acres',
    latitude: 22.5645,
    longitude: 72.9289,
    crops: ['Wheat', 'Cotton'],
    selectedProducts: ['Wheat', 'Cotton'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage(LanguageData.getByCode('en'));
    await MarketplaceService.instance.init();
  });

  Widget buildTestPage({
    FarmerProfile profile = testProfile,
    Locale locale = const Locale('en'),
    int initialTabIndex = 0,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: NaturalFarmingMarketplacePage(
        profile: profile,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  group('NaturalFarmingMarketplacePage 3-Feature Tab & UI Tests', () {
    testWidgets(
      'Preserves all 3 feature options on Page 1: Nearby Mandi, Highest Price, Best Estimated Net Return',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestPage());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify page title
        expect(find.text('Natural Market & APMC Mandis'), findsOneWidget);

        // Verify all THREE tabs exist
        expect(find.text('Nearby Mandi'), findsOneWidget);
        expect(find.text('Highest Price'), findsOneWidget);
        expect(find.text('Best Estimated Net Return'), findsOneWidget);

        // Verify Relocated Complete APMC section in Tab 0
        expect(find.text('Nearby Mandis & Wholesale Rates'), findsOneWidget);
        expect(find.text('Find Mandis'), findsOneWidget);
        expect(find.text('Compare Rates'), findsOneWidget);

        // Verify Mandi search bar exists
        expect(find.byType(TextField), findsOneWidget);

        // Verify Natural Farming Linkage Card from Remote is rendered
        expect(
          find.text('Natural Farming Certification & Direct Marketing'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tab 1: Highest Price First rate comparison renders top rate banner and sorted APMCs',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestPage(initialTabIndex: 1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify Tab 1 is active
        expect(find.widgetWithText(Tab, 'Highest Price'), findsOneWidget);
        expect(find.text('Sort By: Highest Price First'), findsOneWidget);
        expect(find.text('🏆 Highest Verified Rate Today'), findsOneWidget);

        // Verify crop selector exists
        expect(find.text('Wheat'), findsWidgets);
        expect(find.text('Cotton'), findsWidgets);
      },
    );

    testWidgets(
      'Tab 2: Profit Calculator renders interactive inputs and calculates net return',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestPage(initialTabIndex: 2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify calculator controls
        expect(find.text('Farmer Net Proceeds Calculator'), findsOneWidget);
        expect(find.text('Calculate Best Net Return'), findsOneWidget);

        // Tap calculate button
        await tester.tap(find.text('Calculate Best Net Return'));
        await tester.pumpAndSettle();

        // Verify ranked result and best recommendation badge
        expect(find.text('🏆 Best Estimated Net Return'), findsOneWidget);
        expect(find.text('Net Proceeds'), findsWidgets);
      },
    );

    testWidgets('Renders in Gujarati language with authentic terminology', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await LanguageService.instance.setLanguage(LanguageData.getByCode('gu'));

      await tester.pumpWidget(buildTestPage(locale: const Locale('gu')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify Gujarati tab labels
      expect(find.text('નજીકની મંડી'), findsOneWidget);
      expect(find.text('સૌથી વધુ ભાવ'), findsOneWidget);
      expect(find.text('વધુ ચોખ્ખી આવક'), findsOneWidget);

      // Verify Gujarati APMC header
      expect(find.text('નજીકની મંડીઓ અને બજાર ભાવો'), findsOneWidget);
      expect(find.text('મંડીઓ શોધો'), findsOneWidget);
      expect(find.text('ભાવો સરખાવો'), findsOneWidget);
    });

    testWidgets('Zero layout overflow on small 320px screen width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestPage());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Zero layout overflow on standard 360px screen width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestPage());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
