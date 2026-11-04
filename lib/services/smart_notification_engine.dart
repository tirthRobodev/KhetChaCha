import 'package:flutter/foundation.dart';

import '../models/agriculture_news_item.dart';
import '../models/farmer_notification.dart';
import '../models/farmer_profile.dart';
import '../models/notification_preferences.dart';
import 'notification_preferences_service.dart';
import 'notification_service.dart';
import 'sms_notification_service.dart';

/// Smart Targeted Notification Engine.
/// Intelligently matches government news, subsidy alerts, and weather warnings
/// against the farmer's verified State, District, Crops, and Notification Preferences.
class SmartNotificationEngine {
  SmartNotificationEngine._();
  static final SmartNotificationEngine instance = SmartNotificationEngine._();

  /// Evaluates and dispatches a verified news announcement to an eligible farmer.
  Future<bool> processAndDeliverNewsAlert({
    required AgricultureNewsItem news,
    required FarmerProfile profile,
    NotificationPreferences? customPreferences,
  }) async {
    // 1. Load Farmer Preferences
    final prefs =
        customPreferences ??
        await NotificationPreferencesService.instance.getPreferences(
          profile.mobileNumber,
        );

    // 2. Category Preference Check
    if (!_isCategoryEnabled(news.category, prefs)) {
      debugPrint(
        '[SmartNotificationEngine] Category ${news.category} disabled by farmer.',
      );
      return false;
    }

    // 3. Location Relevance Check
    if (!news.matchesLocation(
      state: profile.effectiveState,
      district: profile.effectiveDistrict,
    )) {
      debugPrint(
        '[SmartNotificationEngine] News does not match farmer location (${profile.effectiveDistrict}, ${profile.effectiveState}).',
      );
      return false;
    }

    // 4. Crop Relevance Check
    if (!news.matchesCrops(profile.effectiveProducts)) {
      debugPrint(
        '[SmartNotificationEngine] News does not match farmer crops (${profile.effectiveProducts}).',
      );
      return false;
    }

    // 5. In-App Notification Center Dispatch (Appears in Bell Icon)
    final notifId =
        'notif_news_${news.id}_${DateTime.now().millisecondsSinceEpoch}';
    final notif = FarmerNotification(
      id: notifId,
      title: news.headline,
      message: news.aiSummary.isNotEmpty ? news.aiSummary : news.description,
      category: _mapToFarmerNotifCategory(news.category),
      timestamp: DateTime.now(),
      isRead: false,
      deepLinkTarget: 'news_${news.id}',
    );
    await NotificationService.instance.addNotification(notif);

    // 6. SMS Dispatch (Strict opt-in consent checked inside SmsNotificationService)
    if (prefs.enableSmsNotifications && profile.mobileNumber.isNotEmpty) {
      await SmsNotificationService.instance.sendGovtNewsSms(
        mobileNumber: profile.mobileNumber,
        state: profile.effectiveState,
        headline: news.headline,
        link: news.officialSourceUrl,
        isOptedIn: prefs.enableSmsNotifications,
      );
    }

    debugPrint(
      '[SmartNotificationEngine] Successfully delivered alert for ${news.id} to farmer ${profile.fullName}',
    );
    return true;
  }

  bool _isCategoryEnabled(
    AgricultureNewsCategory category,
    NotificationPreferences prefs,
  ) {
    switch (category) {
      case AgricultureNewsCategory.pmKisan:
        return prefs.enablePmKisanUpdates;
      case AgricultureNewsCategory.farmerSubsidies:
      case AgricultureNewsCategory.newSchemes:
        return prefs.enableSubsidyAlerts;
      case AgricultureNewsCategory.weatherWarnings:
        return prefs.enableWeatherAlerts;
      case AgricultureNewsCategory.mandiPriceNews:
      case AgricultureNewsCategory.mspAnnouncements:
        return prefs.enableMandiPriceUpdates;
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return prefs.enableCropAdvisories;
      default:
        return prefs.enableGovernmentNews;
    }
  }

  String _mapToFarmerNotifCategory(AgricultureNewsCategory cat) {
    switch (cat) {
      case AgricultureNewsCategory.pmKisan:
      case AgricultureNewsCategory.farmerSubsidies:
      case AgricultureNewsCategory.newSchemes:
      case AgricultureNewsCategory.latestGovtNews:
        return 'Government Schemes';
      case AgricultureNewsCategory.weatherWarnings:
        return 'Weather Alerts';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'Crop Advisory';
      default:
        return 'Government Schemes';
    }
  }
}
