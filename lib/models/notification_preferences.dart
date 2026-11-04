import 'dart:convert';

/// Granular Notification Preferences for Indian Farmers.
/// Allows farmers to independently toggle specific news, subsidy, weather, and SMS channels.
class NotificationPreferences {
  final bool enableGovernmentNews;
  final bool enableSubsidyAlerts;
  final bool enablePmKisanUpdates;
  final bool enableWeatherAlerts;
  final bool enableMandiPriceUpdates;
  final bool enableCropAdvisories;
  final bool enablePushNotifications;
  final bool enableSmsNotifications;
  final String preferredLanguage; // e.g. 'gu', 'hi', 'pa', 'en'
  final bool quietHoursEnabled;
  final int quietHoursStartHour; // e.g. 21 (9 PM)
  final int quietHoursEndHour; // e.g. 6 (6 AM)
  final String deliveryFrequency; // 'Instant', 'Daily Digest'

  const NotificationPreferences({
    this.enableGovernmentNews = true,
    this.enableSubsidyAlerts = true,
    this.enablePmKisanUpdates = true,
    this.enableWeatherAlerts = true,
    this.enableMandiPriceUpdates = true,
    this.enableCropAdvisories = true,
    this.enablePushNotifications = true,
    this.enableSmsNotifications = true,
    this.preferredLanguage = 'gu',
    this.quietHoursEnabled = true,
    this.quietHoursStartHour = 21,
    this.quietHoursEndHour = 6,
    this.deliveryFrequency = 'Instant',
  });

  /// Check whether current time is inside quiet hours
  bool isInsideQuietHours(DateTime now) {
    if (!quietHoursEnabled) return false;
    final hour = now.hour;
    if (quietHoursStartHour > quietHoursEndHour) {
      // Overnight (e.g. 21:00 to 06:00)
      return hour >= quietHoursStartHour || hour < quietHoursEndHour;
    } else {
      return hour >= quietHoursStartHour && hour < quietHoursEndHour;
    }
  }

  NotificationPreferences copyWith({
    bool? enableGovernmentNews,
    bool? enableSubsidyAlerts,
    bool? enablePmKisanUpdates,
    bool? enableWeatherAlerts,
    bool? enableMandiPriceUpdates,
    bool? enableCropAdvisories,
    bool? enablePushNotifications,
    bool? enableSmsNotifications,
    String? preferredLanguage,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursEndHour,
    String? deliveryFrequency,
  }) {
    return NotificationPreferences(
      enableGovernmentNews: enableGovernmentNews ?? this.enableGovernmentNews,
      enableSubsidyAlerts: enableSubsidyAlerts ?? this.enableSubsidyAlerts,
      enablePmKisanUpdates: enablePmKisanUpdates ?? this.enablePmKisanUpdates,
      enableWeatherAlerts: enableWeatherAlerts ?? this.enableWeatherAlerts,
      enableMandiPriceUpdates:
          enableMandiPriceUpdates ?? this.enableMandiPriceUpdates,
      enableCropAdvisories: enableCropAdvisories ?? this.enableCropAdvisories,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableSmsNotifications:
          enableSmsNotifications ?? this.enableSmsNotifications,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'enableGovernmentNews': enableGovernmentNews,
    'enableSubsidyAlerts': enableSubsidyAlerts,
    'enablePmKisanUpdates': enablePmKisanUpdates,
    'enableWeatherAlerts': enableWeatherAlerts,
    'enableMandiPriceUpdates': enableMandiPriceUpdates,
    'enableCropAdvisories': enableCropAdvisories,
    'enablePushNotifications': enablePushNotifications,
    'enableSmsNotifications': enableSmsNotifications,
    'preferredLanguage': preferredLanguage,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStartHour': quietHoursStartHour,
    'quietHoursEndHour': quietHoursEndHour,
    'deliveryFrequency': deliveryFrequency,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enableGovernmentNews: json['enableGovernmentNews'] as bool? ?? true,
      enableSubsidyAlerts: json['enableSubsidyAlerts'] as bool? ?? true,
      enablePmKisanUpdates: json['enablePmKisanUpdates'] as bool? ?? true,
      enableWeatherAlerts: json['enableWeatherAlerts'] as bool? ?? true,
      enableMandiPriceUpdates: json['enableMandiPriceUpdates'] as bool? ?? true,
      enableCropAdvisories: json['enableCropAdvisories'] as bool? ?? true,
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      enableSmsNotifications: json['enableSmsNotifications'] as bool? ?? true,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'gu',
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
      quietHoursStartHour: json['quietHoursStartHour'] as int? ?? 21,
      quietHoursEndHour: json['quietHoursEndHour'] as int? ?? 6,
      deliveryFrequency: json['deliveryFrequency'] as String? ?? 'Instant',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory NotificationPreferences.fromJsonString(String str) =>
      NotificationPreferences.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
