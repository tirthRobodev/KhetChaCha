import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/marketplace/natural_farming_marketplace_page.dart';
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

  group('NaturalFarmingMarketplacePage UI & Overflow Tests', () {
    testWidgets(
      'Renders marketplace product cards without layout overflow on 360px mobile screens',
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

        // Allow async loading to finish
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify page title and tabs
        expect(find.text('Natural Farming Marketplace'), findsOneWidget);
        expect(find.text('Browse & Buy'), findsOneWidget);
        expect(find.textContaining('Seller Hub'), findsOneWidget);

        // Verify first product exists and renders
        expect(
          find.text('Desi Gir Cow Liquid Jeevamrut (Fermented)'),
          findsOneWidget,
        );
        expect(
          find.text('Organic Bhalia Desi Wheat (Gluten Rich)'),
          findsOneWidget,
        );

        // Verify Order Now buttons exist and are visible
        expect(find.text('Order Now'), findsAtLeastNWidgets(1));

        // Tap on first Order Now button to test modal opening
        final orderButtons = find.widgetWithText(ElevatedButton, 'Order Now');
        await tester.tap(orderButtons.first);
        await tester.pumpAndSettle();

        // Check order sheet content
        expect(find.text('Order Summary & Direct Checkout'), findsOneWidget);
        expect(find.text('UPI QR Code'), findsOneWidget);
        expect(find.text('Cash on Delivery'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders properly even on extremely compact 320px screen width with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
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

        // Verify products are rendered without throw
        expect(find.text('Natural Farming Marketplace'), findsOneWidget);
        expect(
          find.text('Desi Gir Cow Liquid Jeevamrut (Fermented)'),
          findsOneWidget,
        );
      },
    );
  });
}
