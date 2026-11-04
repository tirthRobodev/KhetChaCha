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
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MarketplaceService.instance.init();
  });

  group('NaturalFarmingMarketplacePage - Relocated APMC Mandi Hub Tests', () {
    testWidgets(
      'Renders Prakruti Bajar APMC Mandi page and wholesale rates cleanly on 360px mobile',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2, 800 * 2);
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
            home: NaturalFarmingMarketplacePage(profile: testProfile),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // 1. Verify page title
        expect(find.text('Prakruti Bajar & APMC Mandi'), findsOneWidget);

        // 2. Verify complete relocated APMC section heading
        expect(
          find.text('Nearby Mandis & Wholesale Rates'),
          findsOneWidget,
        );

        // 3. Verify APMC discovery action buttons
        expect(find.text('Find Mandis'), findsOneWidget);
        expect(find.text('Compare Rates'), findsOneWidget);

        // 4. Verify wholesale commodity rates
        expect(find.text("Today's Wholesale APMC Rates"), findsOneWidget);
        expect(find.text('Wheat'), findsOneWidget);
        expect(find.text('Cotton'), findsOneWidget);
        expect(find.text('View All Live Mandi Rates'), findsOneWidget);

        // 5. Verify zero errors or exceptions
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders Gujarati Prakruti Bajar & APMC section on compact 320px screen without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await LanguageService.instance.setLanguage(
          LanguageData.getByCode('gu'),
        );

        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('gu'),
            home: NaturalFarmingMarketplacePage(profile: testProfile),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Gujarati title
        expect(find.text('પ્રાકૃતિક બજાર અને APMC મંડી'), findsOneWidget);

        // Gujarati APMC buttons
        expect(find.text('મંડીઓ શોધો'), findsOneWidget);
        expect(find.text('ભાવો સરખાવો'), findsOneWidget);

        // Zero exceptions / overflow
        expect(tester.takeException(), isNull);
      },
    );
  });
}
