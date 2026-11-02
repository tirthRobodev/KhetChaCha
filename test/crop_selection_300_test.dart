import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/crop_master_database.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farm_production_selection_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master 300-Crop Database Completeness & Integrity', () {
    test('Contains exactly 300 crops with sequential CROP_xxx identifiers', () {
      final crops = CropMasterDatabase.getAllCrops();
      expect(crops.length, equals(300));

      for (int i = 0; i < 300; i++) {
        final expectedId = 'CROP_${(i + 1).toString().padLeft(3, '0')}';
        expect(crops[i].cropId, equals(expectedId));
        expect(crops[i].canonicalNameEn, isNotEmpty);
        expect(crops[i].iconEmoji, isNotEmpty);
        expect(crops[i].names['en']?.name, isNotEmpty);
        expect(crops[i].names['gu']?.name, isNotEmpty);
        expect(crops[i].names['hi']?.name, isNotEmpty);
      }
    });

    test(
      'All 11 official agricultural categories are present and populated',
      () {
        final categories = CropMasterDatabase.categories;
        expect(categories.length, equals(12)); // 11 categories + 'all'

        final validCategoryIds = [
          'all',
          'cereals_millets',
          'pulses_legumes',
          'oilseeds',
          'commercial_fibre',
          'vegetables',
          'fruits',
          'spices_herbs',
          'medicinal_plants',
          'flowers_ornamental',
          'fodder_forage',
          'plantation_trees',
        ];

        for (final cat in categories) {
          expect(validCategoryIds.contains(cat.id), isTrue);
        }

        // Check counts per category
        expect(
          CropMasterDatabase.getCropsByCategory('cereals_millets').length,
          equals(20),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('pulses_legumes').length,
          equals(25),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('oilseeds').length,
          equals(15),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('commercial_fibre').length,
          equals(15),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('vegetables').length,
          equals(55),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('fruits').length,
          equals(50),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('spices_herbs').length,
          equals(30),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('medicinal_plants').length,
          equals(25),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('flowers_ornamental').length,
          equals(25),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('fodder_forage').length,
          equals(15),
        );
        expect(
          CropMasterDatabase.getCropsByCategory('plantation_trees').length,
          equals(25),
        );
      },
    );

    test('Synonym cross-referencing resolves correctly', () {
      // Amla (CROP_157) <-> Indian gooseberry (CROP_174)
      final amla = CropMasterDatabase.getCropById('CROP_157');
      final gooseberry = CropMasterDatabase.getCropById('CROP_174');
      expect(amla, isNotNull);
      expect(gooseberry, isNotNull);
      expect(amla!.linkedCropIds.contains('CROP_174'), isTrue);
      expect(gooseberry!.linkedCropIds.contains('CROP_157'), isTrue);

      // Drumstick Moringa (CROP_099) <-> Drumstick pods (CROP_123) <-> Drumstick tree (CROP_300)
      final moringa = CropMasterDatabase.getCropById('CROP_099');
      expect(moringa, isNotNull);
      expect(moringa!.linkedCropIds.contains('CROP_123'), isTrue);
      expect(moringa.linkedCropIds.contains('CROP_300'), isTrue);

      // Cluster bean / Guar (CROP_040) <-> Cluster beans (CROP_118)
      final guar = CropMasterDatabase.getCropById('CROP_040');
      final clusterBeans = CropMasterDatabase.getCropById('CROP_118');
      expect(guar, isNotNull);
      expect(clusterBeans, isNotNull);
      expect(guar!.linkedCropIds.contains('CROP_118'), isTrue);
      expect(clusterBeans!.linkedCropIds.contains('CROP_040'), isTrue);
    });

    test('Multilingual and Roman transliterated search matches accurately', () {
      // English
      final wheatResults = CropMasterDatabase.searchCrops('wheat');
      expect(wheatResults.any((c) => c.cropId == 'CROP_001'), isTrue);

      // Gujarati
      final ghauResults = CropMasterDatabase.searchCrops('ઘઉં');
      expect(ghauResults.any((c) => c.cropId == 'CROP_001'), isTrue);

      // Hindi
      final gehuResults = CropMasterDatabase.searchCrops('गेहूं');
      expect(gehuResults.any((c) => c.cropId == 'CROP_001'), isTrue);

      // Roman transliteration
      final romanResults = CropMasterDatabase.searchCrops('gehu');
      expect(romanResults.any((c) => c.cropId == 'CROP_001'), isTrue);

      final kapasResults = CropMasterDatabase.searchCrops('kapas');
      expect(
        kapasResults.any(
          (c) => c.canonicalNameEn.toLowerCase().contains('cotton'),
        ),
        isTrue,
      );
    });
  });

  group('Critical Farmer Selection Rules & UI Behavior', () {
    testWidgets(
      'Screen starts with ZERO preselected crops and disabled Continue button',
      (tester) async {
        const profile = FarmerProfile(
          fullName: 'Ramesh Patel',
          mobileNumber: '9876543210',
          email: 'ramesh@patel.com',
          state: 'Gujarat',
          district: 'Anand',
          village: 'Mogri',
          farmingType: 'Organic',
          landSize: '5 Acres',
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

        // Rule: Selected count must be 0 initially
        expect(find.text('Selected (0)'), findsOneWidget);

        // Continue button must be DISABLED when 0 crops are selected
        final continueBtnFinder = find.widgetWithText(
          ElevatedButton,
          'Continue to Dashboard →',
        );
        expect(continueBtnFinder, findsOneWidget);

        final ElevatedButton continueBtn = tester.widget(continueBtnFinder);
        expect(continueBtn.onPressed, isNull);

        // Verification hint text must be visible
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping a crop card selects it and enables Continue to Dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const profile = FarmerProfile(
          fullName: 'Kishan Bhai',
          mobileNumber: '9988776655',
          email: 'kishan@patel.com',
          state: 'Gujarat',
          district: 'Rajkot',
          village: 'Gondal',
          farmingType: 'Commercial',
          landSize: '3 Acres',
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

        // Initially 0
        expect(find.text('Selected (0)'), findsOneWidget);

        // Tap on Wheat card
        final wheatCard = find.text('Wheat');
        expect(wheatCard, findsOneWidget);
        await tester.tap(wheatCard);
        await tester.pumpAndSettle();

        // Count is now 1
        expect(find.text('Selected (1)'), findsOneWidget);

        // Continue button must now be ENABLED
        final continueBtnFinder = find.widgetWithText(
          ElevatedButton,
          'Continue to Dashboard →',
        );
        final ElevatedButton continueBtn = tester.widget(continueBtnFinder);
        expect(continueBtn.onPressed, isNotNull);

        // Clear All resets back to 0 and disables button
        final clearAllBtn = find.text('Clear All');
        expect(clearAllBtn, findsOneWidget);
        await tester.tap(clearAllBtn);
        await tester.pumpAndSettle();

        expect(find.text('Selected (0)'), findsOneWidget);
        final ElevatedButton continueBtnReset = tester.widget(
          continueBtnFinder,
        );
        expect(continueBtnReset.onPressed, isNull);
      },
    );
  });
}
