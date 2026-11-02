import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/crop_master_database.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farm_production_selection_page.dart';
import 'package:khetchacha/services/crop_audio_service.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:khetchacha/models/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('KhetChacha 300-Crop Multilingual Localization Tests', () {
    test('Punjabi (pa) crop nameplates and secondary labels', () {
      final wheat = CropMasterDatabase.getCropById('CROP_001')!;
      final rice = CropMasterDatabase.getCropById('CROP_002')!;
      final maize = CropMasterDatabase.getCropById('CROP_003')!;
      final sorghum = CropMasterDatabase.getCropById('CROP_005')!;
      final pearlMillet = CropMasterDatabase.getCropById('CROP_006')!;
      final fingerMillet = CropMasterDatabase.getCropById('CROP_007')!;
      final barnyardMillet = CropMasterDatabase.getCropById('CROP_011')!;

      // Nameplates must be in authentic Punjabi
      expect(wheat.getLocalizedName('pa'), 'ਕਣਕ');
      expect(rice.getLocalizedName('pa'), 'ਝੋਨਾ / ਚੌਲ');
      expect(maize.getLocalizedName('pa'), 'ਮੱਕੀ');
      expect(sorghum.getLocalizedName('pa'), 'ਜਵਾਰ');
      expect(pearlMillet.getLocalizedName('pa'), 'ਬਾਜਰਾ');
      expect(fingerMillet.getLocalizedName('pa'), 'ਕੋਦਰਾ (ਰਾਗੀ)');
      expect(barnyardMillet.getLocalizedName('pa'), contains('ਸਵਾਂਕ'));

      // Secondary labels in Punjabi mode must show English canonical name
      expect(wheat.getSecondaryLabel('pa'), 'Wheat');
      expect(rice.getSecondaryLabel('pa'), 'Rice');
      expect(maize.getSecondaryLabel('pa'), 'Maize');
      expect(pearlMillet.getSecondaryLabel('pa'), 'Pearl millet (Bajra)');
    });

    test('Gujarati (gu) crop nameplates and secondary labels', () {
      final wheat = CropMasterDatabase.getCropById('CROP_001')!;
      final rice = CropMasterDatabase.getCropById('CROP_002')!;
      final pearlMillet = CropMasterDatabase.getCropById('CROP_006')!;
      final barnyardMillet = CropMasterDatabase.getCropById('CROP_011')!;

      // Nameplates must be in Gujarati
      expect(wheat.getLocalizedName('gu'), 'ઘઉં');
      expect(rice.getLocalizedName('gu'), 'ડાંગર');
      expect(pearlMillet.getLocalizedName('gu'), 'બાજરી');
      expect(barnyardMillet.getLocalizedName('gu'), contains('સામો'));

      // Secondary labels in Gujarati mode must show English canonical name
      expect(wheat.getSecondaryLabel('gu'), 'Wheat');
      expect(rice.getSecondaryLabel('gu'), 'Rice');
      expect(pearlMillet.getSecondaryLabel('gu'), 'Pearl millet (Bajra)');
    });

    test('Marathi (mr) crop nameplates and secondary labels', () {
      final wheat = CropMasterDatabase.getCropById('CROP_001')!;
      final rice = CropMasterDatabase.getCropById('CROP_002')!;
      final maize = CropMasterDatabase.getCropById('CROP_003')!;
      final pearlMillet = CropMasterDatabase.getCropById('CROP_006')!;

      expect(wheat.getLocalizedName('mr'), 'गहू');
      expect(rice.getLocalizedName('mr'), 'भात / तांदूळ');
      expect(maize.getLocalizedName('mr'), 'मका');
      expect(pearlMillet.getLocalizedName('mr'), 'बाजरी');

      expect(wheat.getSecondaryLabel('mr'), 'Wheat');
    });

    test('English (en) crop nameplates and secondary labels', () {
      final wheat = CropMasterDatabase.getCropById('CROP_001')!;
      final pearlMillet = CropMasterDatabase.getCropById('CROP_006')!;

      expect(wheat.getLocalizedName('en'), 'Wheat');
      expect(wheat.getSecondaryLabel('en'), isEmpty);
      expect(pearlMillet.getLocalizedName('en'), 'Pearl millet (Bajra)');
      expect(pearlMillet.getSecondaryLabel('en'), isEmpty);
    });

    test(
      'All 300 crops have non-empty localized names in Punjabi and Marathi',
      () {
        for (final crop in CropMasterDatabase.masterCrops) {
          final pa = crop.getLocalizedName('pa');
          final mr = crop.getLocalizedName('mr');
          expect(
            pa.isNotEmpty,
            isTrue,
            reason: '${crop.cropId} missing Punjabi name',
          );
          expect(
            mr.isNotEmpty,
            isTrue,
            reason: '${crop.cropId} missing Marathi name',
          );
        }
      },
    );

    test('Category tabs localize in Punjabi, Gujarati, Hindi, and Marathi', () {
      final allCat = CropMasterDatabase.categories.firstWhere(
        (c) => c.id == 'all',
      );
      final cereals = CropMasterDatabase.categories.firstWhere(
        (c) => c.id == 'cereals_millets',
      );
      final pulses = CropMasterDatabase.categories.firstWhere(
        (c) => c.id == 'pulses_legumes',
      );

      // Punjabi
      expect(allCat.getTitle('pa'), contains('ਸਾਰੇ'));
      expect(cereals.getTitle('pa'), contains('ਫ਼ਸਲਾਂ'));
      expect(pulses.getTitle('pa'), contains('ਦਾਲਾਂ'));

      // Gujarati
      expect(allCat.getTitle('gu'), 'બધા (લોકપ્રિય)');
      expect(cereals.getTitle('gu'), 'ધાન્ય પાક');
      expect(pulses.getTitle('gu'), 'કઠોળ પાક');

      // Marathi
      expect(allCat.getTitle('mr'), contains('सर्व'));
      expect(cereals.getTitle('mr'), contains('धान्य'));
      expect(pulses.getTitle('mr'), contains('डाळी'));
    });

    test(
      'TTS Locale Resolution supports all Indian agricultural languages',
      () {
        final tts = CropAudioService.instance;
        expect(tts.resolveLocale('pa'), 'pa-IN');
        expect(tts.resolveLocale('gu'), 'gu-IN');
        expect(tts.resolveLocale('hi'), 'hi-IN');
        expect(tts.resolveLocale('mr'), 'mr-IN');
        expect(tts.resolveLocale('bn'), 'bn-IN');
        expect(tts.resolveLocale('ta'), 'ta-IN');
        expect(tts.resolveLocale('te'), 'te-IN');
        expect(tts.resolveLocale('kn'), 'kn-IN');
        expect(tts.resolveLocale('ml'), 'ml-IN');
        expect(tts.resolveLocale('or'), 'or-IN');
        expect(tts.resolveLocale('as'), 'as-IN');
        expect(tts.resolveLocale('ur'), 'ur-IN');
        expect(tts.resolveLocale('en'), 'en-IN');
      },
    );
  });

  group('FarmProductionSelectionPage Punjabi Widget Localization', () {
    testWidgets('Renders Punjabi nameplates and localized selected chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await LanguageService.instance.setLanguage(
        const AppLanguage(
          code: 'pa',
          englishName: 'Punjabi',
          nativeName: 'ਪੰਜਾਬੀ',
        ),
      );

      const profile = FarmerProfile(
        fullName: 'ਗੁਰਪ੍ਰੀਤ ਸਿੰਘ',
        mobileNumber: '9876543210',
        email: 'gurpreet@khet.com',
        state: 'Punjab',
        district: 'Ludhiana',
        village: 'Khanna',
        farmingType: 'Commercial',
        landSize: '5 Acres',
        selectedLanguage: 'pa',
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
          locale: const Locale('pa'),
          home: const FarmProductionSelectionPage(profile: profile),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Subtitle in Punjabi
      expect(find.text('ਆਪਣੇ ਖੇਤ ਦੀਆਂ ਫ਼ਸਲਾਂ ਚੁਣੋ'), findsOneWidget);

      // Category tab in Punjabi
      expect(find.text('ਫ਼ਸਲਾਂ (ਅਨਾਜ)'), findsOneWidget);

      // Nameplates on cards must be Punjabi!
      expect(find.text('ਕਣਕ'), findsOneWidget);
      expect(find.text('ਝੋਨਾ / ਚੌਲ'), findsOneWidget);
      expect(find.text('ਮੱਕੀ'), findsOneWidget);

      // Secondary label is English underneath
      expect(find.text('Wheat'), findsOneWidget);

      // Tap on Wheat card (ਕਣਕ)
      final wheatCard = find.text('ਕਣਕ');
      await tester.tap(wheatCard);
      await tester.pumpAndSettle();

      // Selected chip at bottom MUST show Punjabi name "ਕਣਕ", not English "Wheat"!
      expect(
        find.text('ਕਣਕ'),
        findsNWidgets(2),
      ); // Card nameplate + Bottom chip
      expect(find.text('ਚੁਣੇ ਗਏ (1)'), findsOneWidget);

      // Bottom button in Punjabi
      expect(find.text('ਡੈਸ਼ਬੋਰਡ \'ਤੇ ਅੱਗੇ ਵਧੋ →'), findsOneWidget);
    });
  });

  group('Feature: farm-production-selection-localization Property Tests', () {
    const supportedCodes = [
      'en',
      'hi',
      'pa',
      'gu',
      'mr',
      'ta',
      'te',
      'kn',
      'ml',
      'bn',
      'or',
      'as',
      'ur',
    ];

    test('Property 1: Crop name data completeness', () {
      for (final crop in CropMasterDatabase.masterCrops) {
        for (final code in ['pa', 'gu', 'mr', 'hi', 'en']) {
          final name = crop.getLocalizedName(code);
          expect(
            name.isNotEmpty,
            isTrue,
            reason: 'Crop ${crop.cropId} missing name for $code',
          );
        }
      }
    });

    test('Property 2: Crop name fallback to English', () {
      const unsupportedCodes = ['xx', 'zz', 'unsupported', 'klingon'];
      for (final crop in CropMasterDatabase.masterCrops.take(50)) {
        for (final code in unsupportedCodes) {
          expect(
            crop.getLocalizedName(code),
            equals(crop.canonicalNameEn),
            reason:
                'Expected crop ${crop.cropId} to fall back to English canonical name',
          );
        }
      }
    });

    test('Property 3: Search matches all localized forms', () {
      for (final crop in CropMasterDatabase.masterCrops.take(50)) {
        // English canonical name match
        expect(crop.matchesQuery(crop.canonicalNameEn), isTrue);

        // Punjabi match
        final paName = crop.getLocalizedName('pa');
        if (paName.isNotEmpty) {
          expect(crop.matchesQuery(paName), isTrue);
        }

        // Gujarati match
        final guName = crop.getLocalizedName('gu');
        if (guName.isNotEmpty) {
          expect(crop.matchesQuery(guName), isTrue);
        }

        // Marathi match
        final mrName = crop.getLocalizedName('mr');
        if (mrName.isNotEmpty) {
          expect(crop.matchesQuery(mrName), isTrue);
        }
      }
    });

    test('Property 4: Category title completeness and resolution', () {
      for (final category in CropMasterDatabase.categories) {
        for (final code in supportedCodes) {
          final title = category.getTitle(code);
          expect(
            title.isNotEmpty,
            isTrue,
            reason: 'Category ${category.id} returned empty title for $code',
          );
        }
        // Unsupported code fallback
        expect(category.getTitle('xx_unsupported'), equals(category.titleEn));
      }
    });

    test('Property 5: UI string localization completeness and fallback', () {
      for (final code in supportedCodes) {
        final loc = AppLocalizations(Locale(code));
        expect(loc.selectFarmProductionTitle.isNotEmpty, isTrue);
        expect(loc.selectFarmProductionSubtitle.isNotEmpty, isTrue);
        expect(loc.searchCropsHint.isNotEmpty, isTrue);
        expect(loc.clearAll.isNotEmpty, isTrue);
        expect(loc.selectAtLeastOneHint.isNotEmpty, isTrue);
        expect(loc.continueToDashboard.isNotEmpty, isTrue);
      }
    });

    test('Property 6: Primary and secondary name resolution', () {
      for (final crop in CropMasterDatabase.masterCrops) {
        // English: primary = canonicalNameEn, secondary = ''
        expect(crop.getLocalizedName('en'), equals(crop.canonicalNameEn));
        expect(crop.getSecondaryLabel('en'), isEmpty);

        // Non-English: primary = localized, secondary = canonicalNameEn
        for (final code in ['pa', 'gu', 'mr']) {
          final primary = crop.getLocalizedName(code);
          expect(primary.isNotEmpty, isTrue);
          expect(crop.getSecondaryLabel(code), equals(crop.canonicalNameEn));
        }
      }
    });

    test('Property 7: TTS locale resolution', () {
      final tts = CropAudioService.instance;
      for (final code in supportedCodes) {
        final locale = tts.resolveLocale(code);
        expect(locale.isNotEmpty, isTrue);
        expect(locale.contains('-'), isTrue);
      }
      expect(tts.resolveLocale('en'), equals('en-IN'));
    });
  });
}
