import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/screens/farmer_details_page.dart';
import 'package:khetchacha/screens/language_selection_page.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('LanguageData contains all 22 scheduled Indian languages plus English', () {
    expect(LanguageData.allLanguages.length, 23);

    final gu = LanguageData.getByCode('gu');
    expect(gu.englishName, 'Gujarati');
    expect(gu.nativeName, 'ગુજરાતી');

    final hi = LanguageData.getByCode('hi');
    expect(hi.englishName, 'Hindi');
    expect(hi.nativeName, 'हिन्दी');

    final en = LanguageData.getByCode('en');
    expect(en.englishName, 'English');

    final searchGuj = LanguageData.search('guj');
    expect(searchGuj.any((l) => l.code == 'gu'), isTrue);

    final searchNative = LanguageData.search('ગુજરાતી');
    expect(searchNative.any((l) => l.code == 'gu'), isTrue);
  });

  test('AppLocalizations provides correct Gujarati, Hindi, and English translations', () {
    final guLoc = AppLocalizations(const Locale('gu'));
    expect(guLoc.farmerDetailsTitle, 'ખેડૂતની મૂળભૂત માહિતી');
    expect(guLoc.fullNameLabel, 'તમારું પૂરું નામ');
    expect(guLoc.mobileNumberLabel, 'તમારો મોબાઇલ નંબર');
    expect(guLoc.emailLabel, 'તમારું ઇમેઇલ આઈડી');
    expect(guLoc.districtLabel, 'તમારો જિલ્લો');
    expect(guLoc.villageLabel, 'તમારું ગામ');
    expect(guLoc.farmingTypeLabel, 'તમારી ખેતીનો પ્રકાર');
    expect(guLoc.landSizeLabel, 'તમારી પાસે કેટલી જમીન છે?');
    expect(guLoc.cropsLabel, 'તમે કયા પાક ઉગાડો છો?');
    expect(guLoc.submitButton, 'આગળ વધો →');
    expect(guLoc.valNameRequired, 'કૃપા કરીને તમારું નામ દાખલ કરો.');

    final hiLoc = AppLocalizations(const Locale('hi'));
    expect(hiLoc.farmerDetailsTitle, 'किसान की बुनियादी जानकारी');
    expect(hiLoc.fullNameLabel, 'आपका पूरा नाम');
    expect(hiLoc.emailLabel, 'आपकी ईमेल आईडी');
    expect(hiLoc.submitButton, 'आगे बढ़ें →');

    final enLoc = AppLocalizations(const Locale('en'));
    expect(enLoc.farmerDetailsTitle, 'Basic Farmer Information');
    expect(enLoc.fullNameLabel, 'Your Full Name');
    expect(enLoc.emailLabel, 'Your Email ID');
  });

  testWidgets('LanguageSelectionPage displays dual columns and enforces compulsory selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LanguageSelectionPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially shows compulsory instruction and disabled button
    expect(find.textContaining('Choose Your Language'), findsOneWidget);
    expect(find.text('Gujarati'), findsOneWidget);
    expect(find.text('ગુજરાતી'), findsOneWidget);
    expect(find.text('Select Language to Continue →'), findsOneWidget);

    // Tap Gujarati
    await tester.tap(find.text('Gujarati'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Dynamic title updates to Gujarati and Continue button is enabled
    expect(find.text('તમારી ભાષા પસંદ કરો'), findsOneWidget);
    expect(find.text('આગળ વધો →'), findsOneWidget);
  });

  testWidgets('FarmerDetailsPage renders localized form and contains all Indian states',
      (WidgetTester tester) async {
    await LanguageService.instance.setLanguage(LanguageData.getByCode('gu'));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('gu'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FarmerDetailsPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify all 36 Indian States and UTs list exists
    expect(FarmerDetailsPage.allIndianStatesAndUTs.length, 36);
    expect(FarmerDetailsPage.allIndianStatesAndUTs.contains('Gujarat'), isTrue);
    expect(FarmerDetailsPage.allIndianStatesAndUTs.contains('Maharashtra'), isTrue);
    expect(FarmerDetailsPage.allIndianStatesAndUTs.contains('Punjab'), isTrue);
    expect(FarmerDetailsPage.allIndianStatesAndUTs.contains('Uttar Pradesh'), isTrue);

    // Verify Gujarati labels exist
    expect(find.text('ખેડૂતની મૂળભૂત માહિતી'), findsWidgets);
    expect(find.text('તમારું પૂરું નામ'), findsOneWidget);
    expect(find.text('તમારો મોબાઇલ નંબર'), findsOneWidget);
    expect(find.text('તમારું ઇમેઇલ આઈડી'), findsOneWidget);
    expect(find.text('તમારું રાજ્ય'), findsOneWidget);
    expect(find.text('તમારો જિલ્લો'), findsOneWidget);
    expect(find.text('આગળ વધો →'), findsOneWidget);

    // Verify crops question feature is removed
    expect(find.text('તમે કયા પાક ઉગાડો છો?'), findsNothing);
  });
}
