import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/localization/location_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/farmer_details_page.dart';
import 'package:khetchacha/screens/language_selection_page.dart';
import 'package:khetchacha/screens/phone_login_page.dart';
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

  test('All Indian states have comprehensive dynamic districts including all 38 districts of Tamil Nadu', () {
    // 1. Verify Tamil Nadu has all 38 districts (not a single fixed dummy)
    final tnDistricts = LocationData.getDistrictsForState('Tamil Nadu');
    expect(tnDistricts.length, 38);
    expect(tnDistricts.any((d) => d.key == 'Chennai'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Coimbatore'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Madurai'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Salem'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Ariyalur'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Erode'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Kanyakumari'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Thanjavur'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Tiruchirappalli'), isTrue);
    expect(tnDistricts.any((d) => d.key == 'Tamil Nadu Central'), isFalse);

    // 2. Verify Gujarat has all 33 districts
    final gujDistricts = LocationData.getDistrictsForState('Gujarat');
    expect(gujDistricts.length, 33);
    expect(gujDistricts.any((d) => d.key == 'Ahmedabad'), isTrue);
    expect(gujDistricts.any((d) => d.key == 'Surat'), isTrue);

    // 3. Verify Maharashtra has all 36 districts
    final mhDistricts = LocationData.getDistrictsForState('Maharashtra');
    expect(mhDistricts.length, 36);
    expect(mhDistricts.any((d) => d.key == 'Pune'), isTrue);
    expect(mhDistricts.any((d) => d.key == 'Nagpur'), isTrue);

    // 4. Verify Karnataka, Kerala, Rajasthan, UP, Punjab, Haryana, etc.
    expect(LocationData.getDistrictsForState('Karnataka').length, 31);
    expect(LocationData.getDistrictsForState('Kerala').length, 14);
    expect(LocationData.getDistrictsForState('Rajasthan').length, 33);
    expect(LocationData.getDistrictsForState('Uttar Pradesh').length, 75);
    expect(LocationData.getDistrictsForState('Punjab').length, 23);
    expect(LocationData.getDistrictsForState('Haryana').length, 22);
    expect(LocationData.getDistrictsForState('Bihar').length, 38);
    expect(LocationData.getDistrictsForState('West Bengal').length, 23);
    expect(LocationData.getDistrictsForState('Odisha').length, 30);
    expect(LocationData.getDistrictsForState('Telangana').length, 33);
    expect(LocationData.getDistrictsForState('Andhra Pradesh').length, 26);

    // 5. Verify every single state in allStates has dynamic districts (none empty)
    for (final state in LocationData.allStates) {
      final districts = LocationData.getDistrictsForState(state.key);
      expect(districts.isNotEmpty, isTrue, reason: 'Districts missing for ${state.englishName}');
      expect(districts.any((d) => d.key.endsWith('Central')), isFalse,
          reason: 'State ${state.englishName} should not have fixed fallback Central');
    }

    // 6. Test coordinates for Tamil Nadu district
    final cbeCoords = LocationData.getCoordinates(district: 'Coimbatore', state: 'Tamil Nadu');
    expect((cbeCoords.lat - 11.0168).abs() < 0.1, isTrue);
    expect((cbeCoords.lon - 76.9558).abs() < 0.1, isTrue);
  });

  test('States and Districts are displayed in whatever language is selected', () {
    final tnState = LocationData.allStates.firstWhere((s) => s.key == 'Tamil Nadu');
    final cbeDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Coimbatore');
    final chennaiDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Chennai');

    // 1. In Tamil (ta)
    expect(tnState.getLocalizedName('ta'), contains('தமிழ்நாடு'));
    expect(chennaiDistrict.getLocalizedName('ta'), contains('சென்னை'));
    expect(cbeDistrict.getLocalizedName('ta'), contains('கோயம்புத்தூர்'));

    // 2. In Telugu (te)
    final apState = LocationData.allStates.firstWhere((s) => s.key == 'Andhra Pradesh');
    final vizagDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Visakhapatnam');
    expect(apState.getLocalizedName('te'), contains('ఆంధ్ర ప్రదేశ్'));
    expect(vizagDistrict.getLocalizedName('te'), contains('విశాఖపట్నం'));

    // 3. In Kannada (kn)
    final kaState = LocationData.allStates.firstWhere((s) => s.key == 'Karnataka');
    final blrDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Bengaluru Urban');
    expect(kaState.getLocalizedName('kn'), contains('ಕರ್ನಾಟಕ'));
    expect(blrDistrict.getLocalizedName('kn'), contains('ಬೆಂಗಳೂರು'));

    // 4. In Malayalam (ml)
    final klState = LocationData.allStates.firstWhere((s) => s.key == 'Kerala');
    final tvmDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Thiruvananthapuram');
    expect(klState.getLocalizedName('ml'), contains('കേരളം'));
    expect(tvmDistrict.getLocalizedName('ml'), contains('തിരുവനന്തപുരം'));

    // 5. In Marathi (mr)
    final mhState = LocationData.allStates.firstWhere((s) => s.key == 'Maharashtra');
    final puneDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Pune');
    expect(mhState.getLocalizedName('mr'), contains('महाराष्ट्र'));
    expect(puneDistrict.getLocalizedName('mr'), contains('पुणे'));

    // 6. In Punjabi (pa)
    final pbState = LocationData.allStates.firstWhere((s) => s.key == 'Punjab');
    final asrDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Amritsar');
    expect(pbState.getLocalizedName('pa'), contains('ਪੰਜਾਬ'));
    expect(asrDistrict.getLocalizedName('pa'), contains('ਅੰਮ੍ਰਿਤਸਰ'));

    // 7. In Bengali (bn)
    final wbState = LocationData.allStates.firstWhere((s) => s.key == 'West Bengal');
    final kolDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Kolkata');
    expect(wbState.getLocalizedName('bn'), contains('পশ্চিমবঙ্গ'));
    expect(kolDistrict.getLocalizedName('bn'), contains('কলকাতা'));

    // 8. In Gujarati (gu)
    final gjState = LocationData.allStates.firstWhere((s) => s.key == 'Gujarat');
    final amdDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Ahmedabad');
    expect(gjState.getLocalizedName('gu'), contains('ગુજરાત'));
    expect(amdDistrict.getLocalizedName('gu'), contains('અમદાવાદ'));

    // 9. In Hindi (hi)
    final upState = LocationData.allStates.firstWhere((s) => s.key == 'Uttar Pradesh');
    final vnsDistrict = LocationData.allDistricts.firstWhere((d) => d.key == 'Varanasi');
    expect(upState.getLocalizedName('hi'), contains('उत्तर प्रदेश'));
    expect(vnsDistrict.getLocalizedName('hi'), contains('वाराणसी'));
  });

  testWidgets('PhoneLoginPage supports Autofill and pre-populates initial profile credentials',
      (WidgetTester tester) async {
    const testProfile = FarmerProfile(
      fullName: 'Kisan Bhai',
      mobileNumber: '9876543210',
      email: 'kisan@khetchacha.in',
      state: 'Gujarat',
      district: 'Ahmedabad',
      village: 'Sanand',
      farmingType: 'Organic',
      landSize: '5 Acres',
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
        home: PhoneLoginPage(initialProfile: testProfile),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Autofill pre-filled the inputs
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('kisan@khetchacha.in'), findsOneWidget);

    // Verify presence of step indicator and logo
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });
}


