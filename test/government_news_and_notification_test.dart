import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/agriculture_news_item.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/models/notification_preferences.dart';
import 'package:khetchacha/models/sms_delivery_log.dart';
import 'package:khetchacha/services/agriculture_news_service.dart';
import 'package:khetchacha/services/ai_news_intelligence_service.dart';
import 'package:khetchacha/services/notification_preferences_service.dart';
import 'package:khetchacha/services/notification_service.dart';
import 'package:khetchacha/services/smart_notification_engine.dart';
import 'package:khetchacha/services/sms_notification_service.dart';
import 'package:khetchacha/screens/news/government_news_directory_page.dart';
import 'package:khetchacha/screens/notifications/notification_settings_page.dart';
import 'package:khetchacha/screens/farmer_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Location-Aware Government Agriculture News & Schemes', () {
    final gujaratFarmer = FarmerProfile(
      mobileNumber: '+919876543210',
      fullName: 'Rameshbhai Patel',
      email: 'ramesh@khetchacha.in',
      state: 'Gujarat',
      district: 'Amreli',
      taluka: 'Dhari',
      village: 'Chalala',
      farmingType: 'Organic / Conventional',
      landSize: '2.5',
      farmSize: '2.5',
      landUnit: 'Acre',
      selectedProducts: ['Groundnut', 'Cotton'],
    );

    final punjabFarmer = FarmerProfile(
      mobileNumber: '+919876543211',
      fullName: 'Gurpreet Singh',
      email: 'gurpreet@khetchacha.in',
      state: 'Punjab',
      district: 'Ludhiana',
      taluka: 'Khanna',
      village: 'Samrala',
      farmingType: 'Conventional',
      landSize: '5.0',
      farmSize: '5.0',
      landUnit: 'Acre',
      selectedProducts: ['Wheat', 'Paddy'],
    );

    test('Gujarat farmer receives Gujarat schemes and All India news, but NOT Punjab news', () async {
      final news = await AgricultureNewsService.instance.getNewsForFarmer(gujaratFarmer);

      expect(news, isNotEmpty);

      // Must have Gujarat news (iKhedut subsidy or Groundnut MSP)
      final hasGujaratNews = news.any((n) => n.applicableState.toLowerCase() == 'gujarat');
      expect(hasGujaratNews, isTrue, reason: 'Gujarat farmer must see Gujarat agriculture news');

      // Must have National news (PM-KISAN or PM-KUSUM)
      final hasNationalNews = news.any((n) => n.applicableState.toLowerCase() == 'all india');
      expect(hasNationalNews, isTrue, reason: 'All India news must be available to Gujarat farmer');

      // Must NOT contain Punjab specific news
      final hasPunjabNews = news.any((n) => n.applicableState.toLowerCase() == 'punjab');
      expect(hasPunjabNews, isFalse, reason: 'Gujarat farmer must not receive Punjab specific announcements');
    });

    test('Punjab farmer receives Punjab schemes and All India news, but NOT Gujarat news', () async {
      final news = await AgricultureNewsService.instance.getNewsForFarmer(punjabFarmer);

      expect(news, isNotEmpty);

      // Must have Punjab news (Certified wheat seed subsidy)
      final hasPunjabNews = news.any((n) => n.applicableState.toLowerCase() == 'punjab');
      expect(hasPunjabNews, isTrue, reason: 'Punjab farmer must see Punjab certified seed news');

      // Must have National news
      final hasNationalNews = news.any((n) => n.applicableState.toLowerCase() == 'all india');
      expect(hasNationalNews, isTrue, reason: 'Punjab farmer must see National schemes');

      // Must NOT contain Gujarat specific news
      final hasGujaratNews = news.any((n) => n.applicableState.toLowerCase() == 'gujarat');
      expect(hasGujaratNews, isFalse, reason: 'Punjab farmer must not receive Gujarat iKhedut announcements');
    });

    test('Crop matching boosts relevant crop advisories to top', () async {
      final news = await AgricultureNewsService.instance.getNewsForFarmer(gujaratFarmer);
      expect(news.first.matchesCrops(gujaratFarmer.effectiveProducts) || news.first.applicableState == 'Gujarat', isTrue);
    });

    test('Category filtering and search filtering work correctly', () async {
      final subsidies = await AgricultureNewsService.instance.getNewsForFarmer(
        gujaratFarmer,
        categoryFilter: AgricultureNewsCategory.farmerSubsidies,
      );
      expect(subsidies.every((n) => n.category == AgricultureNewsCategory.farmerSubsidies), isTrue);

      final searchResults = await AgricultureNewsService.instance.getNewsForFarmer(
        gujaratFarmer,
        searchQuery: 'Tractor',
      );
      expect(searchResults.any((n) => n.headline.contains('Tractor') || n.description.contains('Tractor')), isTrue);
    });

    test('Bookmarking toggle persists across calls', () async {
      final news = await AgricultureNewsService.instance.getNewsForFarmer(gujaratFarmer);
      final testItem = news.first;

      final bookmarked = await AgricultureNewsService.instance.toggleBookmark(
        gujaratFarmer.mobileNumber,
        testItem.id,
      );
      expect(bookmarked, isTrue);

      final onlyBookmarked = await AgricultureNewsService.instance.getNewsForFarmer(
        gujaratFarmer,
        onlyBookmarked: true,
      );
      expect(onlyBookmarked.any((n) => n.id == testItem.id), isTrue);

      // Toggle off
      final unbookmarked = await AgricultureNewsService.instance.toggleBookmark(
        gujaratFarmer.mobileNumber,
        testItem.id,
      );
      expect(unbookmarked, isFalse);
    });
  });

  group('2. AI News Intelligence & Multilingual Summarization', () {
    final testNews = AgricultureNewsItem(
      id: 'test_pm_kisan',
      headline: 'PM-KISAN 19th Installment Released: ₹2,000 Credited to Eligible Farmers',
      description: 'The Ministry of Agriculture has disbursed ₹2,000 under PM-KISAN. Complete Aadhaar eKYC to receive benefit.',
      aiSummary: '',
      originalSource: 'PM-KISAN Portal',
      officialSourceUrl: 'https://pmkisan.gov.in',
      publishedDate: DateTime.now(),
      lastUpdatedDate: DateTime.now(),
      category: AgricultureNewsCategory.pmKisan,
    );

    test('Generates farmer-friendly summary in Gujarati', () {
      final summaryGu = AiNewsIntelligenceService.instance.generateFarmerFriendlySummary(
        news: testNews,
        langCode: 'gu',
      );
      expect(summaryGu, contains('પીએમ-કિસાન'));
      expect(summaryGu, contains('₹2,000'));
      expect(summaryGu, contains('eKYC'));
    });

    test('Generates farmer-friendly summary in Hindi', () {
      final summaryHi = AiNewsIntelligenceService.instance.generateFarmerFriendlySummary(
        news: testNews,
        langCode: 'hi',
      );
      expect(summaryHi, contains('पीएम-किसान'));
      expect(summaryHi, contains('₹2,000'));
    });

    test('Generates farmer-friendly summary in Punjabi', () {
      final mspNews = testNews.copyWith(
        category: AgricultureNewsCategory.mspAnnouncements,
        applicableState: 'Punjab',
      );
      final summaryPa = AiNewsIntelligenceService.instance.generateFarmerFriendlySummary(
        news: mspNews,
        langCode: 'pa',
      );
      expect(summaryPa, contains('ਕਿਸਾਨ'));
      expect(summaryPa, contains('MSP'));
    });

    test('Summarizes free-form announcement text', () async {
      final textSummary = await AiNewsIntelligenceService.instance.summarizeAnnouncementText(
        headline: 'Heavy Rainfall Alert in Saurashtra',
        text: 'IMD warns of heavy rain up to 100mm in Saurashtra and South Gujarat in the next 48 hours.',
        category: AgricultureNewsCategory.weatherWarnings,
        state: 'Gujarat',
        langCode: 'gu',
      );
      expect(textSummary, contains('હવામાન'));
      expect(textSummary, contains('પાણી'));
    });
  });

  group('3. DLT-Compliant SMS Architecture (TRAI Approved)', () {
    test('SMS dispatch is blocked when farmer has not opted in', () async {
      final log = await SmsNotificationService.instance.sendGovtNewsSms(
        mobileNumber: '9876543210',
        state: 'Gujarat',
        headline: '50% Subsidy on Micro-Irrigation',
        link: 'ikhedut.gujarat.gov.in',
        isOptedIn: false, // Opt-out
      );

      expect(log.status, SmsDeliveryStatus.optedOutBlocked);
      expect(log.isTraiCompliant, isTrue);
      expect(log.senderId, 'KHTCHA');
    });

    test('SMS dispatch succeeds with DLT Header and approved Template ID when opted in', () async {
      final log = await SmsNotificationService.instance.sendGovtNewsSms(
        mobileNumber: '9876543212',
        state: 'Gujarat',
        headline: '50% Subsidy on Micro-Irrigation',
        link: 'ikhedut.gujarat.gov.in',
        isOptedIn: true,
      );

      expect(log.status, SmsDeliveryStatus.delivered);
      expect(log.senderId, 'KHTCHA');
      expect(log.dltTemplateId, isNotEmpty);
      expect(log.recipientMobile, '9876543212');
    });

    test('Duplicate SMS to the same phone within 60 minutes is suppressed', () async {
      final firstLog = await SmsNotificationService.instance.sendGovtNewsSms(
        mobileNumber: '9876543213',
        state: 'Punjab',
        headline: 'Wheat Seed Subsidy Portal Open',
        link: 'agri.punjab.gov.in',
        isOptedIn: true,
      );
      expect(firstLog.status, SmsDeliveryStatus.delivered);

      final secondLog = await SmsNotificationService.instance.sendGovtNewsSms(
        mobileNumber: '9876543213',
        state: 'Punjab',
        headline: 'Wheat Seed Subsidy Portal Open',
        link: 'agri.punjab.gov.in',
        isOptedIn: true,
      );
      expect(secondLog.status, SmsDeliveryStatus.rateLimitExceeded);
      expect(secondLog.failureReason, contains('Duplicate alert suppressed'));
    });

    test('Rate-limits to maximum 5 SMS per phone per day', () async {
      const mobile = '9876543299';
      for (int i = 0; i < 5; i++) {
        final log = await SmsNotificationService.instance.sendPmKisanAlertSms(
          mobileNumber: mobile,
          installmentNo: '${i + 1}th',
          amount: '2000',
          isOptedIn: true,
        );
        expect(log.status, SmsDeliveryStatus.delivered);
      }

      // 6th attempt with a different message
      final sixthLog = await SmsNotificationService.instance.sendWeatherWarningSms(
        mobileNumber: mobile,
        district: 'Amreli',
        weatherType: 'Heavy Rain',
        advisory: 'Clear drainage channels',
        isOptedIn: true,
      );
      expect(sixthLog.status, SmsDeliveryStatus.rateLimitExceeded);
      expect(sixthLog.failureReason, contains('Daily quota of 5 SMS exceeded'));
    });
  });

  group('4. Farmer Notification Preferences Persistence & Quiet Hours', () {
    test('Default preferences have Push enabled and respectful quiet hours (21:00 - 06:00)', () {
      const prefs = NotificationPreferences();
      expect(prefs.enablePushNotifications, isTrue);
      expect(prefs.enableGovernmentNews, isTrue);
      expect(prefs.quietHoursEnabled, isTrue);
      expect(prefs.quietHoursStartHour, 21);
      expect(prefs.quietHoursEndHour, 6);

      // Check quiet hours evaluation
      expect(prefs.isInsideQuietHours(DateTime(2026, 11, 3, 22, 30)), isTrue);
      expect(prefs.isInsideQuietHours(DateTime(2026, 11, 3, 3, 15)), isTrue);
      expect(prefs.isInsideQuietHours(DateTime(2026, 11, 3, 14, 0)), isFalse);
    });

    test('Preferences save and reload accurately from SharedPreferences', () async {
      const mobile = '9876543210';
      final initialPrefs = await NotificationPreferencesService.instance.getPreferences(mobile);
      expect(initialPrefs.enableSmsNotifications, isTrue);

      // Change preferences and save
      final updatedPrefs = initialPrefs.copyWith(
        enableSmsNotifications: false,
        enableWeatherAlerts: false,
      );
      await NotificationPreferencesService.instance.savePreferences(mobile, updatedPrefs);

      final reloadedPrefs = await NotificationPreferencesService.instance.getPreferences(mobile);
      expect(reloadedPrefs.enableSmsNotifications, isFalse);
      expect(reloadedPrefs.enableWeatherAlerts, isFalse);
    });
  });

  group('5. Smart Targeted Notification Engine', () {
    final gujaratProfile = FarmerProfile(
      mobileNumber: '9876543210',
      fullName: 'Ramesh Patel',
      email: 'ramesh@khetchacha.in',
      state: 'Gujarat',
      district: 'Amreli',
      taluka: 'Dhari',
      village: 'Chalala',
      farmingType: 'Conventional',
      landSize: '3.0',
      farmSize: '3.0',
      landUnit: 'Acre',
      selectedProducts: ['Groundnut'],
    );

    test('Dispatches in-app notification when criteria match', () async {
      final news = AgricultureNewsItem(
        id: 'news_smart_test_1',
        headline: 'Groundnut MSP Procurement Center Opened in Amreli',
        description: 'APMC Amreli has commenced procurement at ₹6,783/Q.',
        aiSummary: 'Sell groundnut at MSP in Amreli APMC.',
        originalSource: 'Gujarat Agriculture Dept',
        officialSourceUrl: 'https://agri.gujarat.gov.in',
        publishedDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        applicableState: 'Gujarat',
        applicableDistricts: ['Amreli'],
        relevantCrops: ['Groundnut'],
        category: AgricultureNewsCategory.mspAnnouncements,
      );

      final delivered = await SmartNotificationEngine.instance.processAndDeliverNewsAlert(
        news: news,
        profile: gujaratProfile,
        customPreferences: const NotificationPreferences(),
      );

      expect(delivered, isTrue);

      final inAppNotifs = await NotificationService.instance.getNotifications();
      expect(inAppNotifs.any((n) => n.title.contains('Groundnut MSP Procurement')), isTrue);
    });

    test('Blocks delivery when farmer location does not match', () async {
      final punjabNews = AgricultureNewsItem(
        id: 'news_smart_test_punjab',
        headline: 'Punjab Certified Wheat Seed Subsidy',
        description: 'Punjab government announces certified wheat seed subsidy.',
        aiSummary: 'Avail seed subsidy in Punjab.',
        originalSource: 'Punjab Agriculture Dept',
        officialSourceUrl: 'https://agri.punjab.gov.in',
        publishedDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        applicableState: 'Punjab',
        category: AgricultureNewsCategory.seedDistribution,
      );

      final delivered = await SmartNotificationEngine.instance.processAndDeliverNewsAlert(
        news: punjabNews,
        profile: gujaratProfile,
      );

      expect(delivered, isFalse, reason: 'Punjab news must not be delivered to Gujarat farmer');
    });
  });

  group('6. Widget Tests: Government News Directory & Notification Settings', () {
    final testProfile = FarmerProfile(
      mobileNumber: '9876543210',
      fullName: 'Rameshbhai Patel',
      email: 'ramesh@khetchacha.in',
      state: 'Gujarat',
      district: 'Amreli',
      taluka: 'Dhari',
      village: 'Chalala',
      farmingType: 'Conventional',
      landSize: '3.0',
      farmSize: '3.0',
      landUnit: 'Acre',
      selectedProducts: ['Groundnut'],
    );

    testWidgets('GovernmentNewsDirectoryPage renders category chips and verified cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GovernmentNewsDirectoryPage(profile: testProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Govt Agriculture News & Alerts'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(find.text('All News'), findsOneWidget); // Category chip
      expect(find.text('Subsidies'), findsOneWidget);
      expect(find.text('PM-KISAN'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('NotificationSettingsPage allows toggling SMS alerts and quiet hours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationSettingsPage(profile: testProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('DLT-Compliant SMS Alerts'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('PM-KISAN Installment Updates'), findsOneWidget);
      expect(find.text('Farmer Subsidies & Schemes'), findsOneWidget);
      expect(find.text('Enable Night Quiet Hours'), findsOneWidget);

      // Verify switches exist
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('FarmerDashboardPage displays clean layout without cluttering news section, with Govt News in Quick Access', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FarmerDashboardPage(profile: testProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard is clean (news circulars not cluttering main feed)
      expect(find.text('SMS & Alert Settings'), findsNothing);
      expect(find.text('Admin Broadcast'), findsNothing);

      // Verify Quick Access grid has AI Crop & Farm Plan and Govt News & SMS
      expect(find.text('AI Crop & Farm Plan'), findsOneWidget);
      expect(find.text('Govt News & SMS'), findsOneWidget);
    });
  });
}
