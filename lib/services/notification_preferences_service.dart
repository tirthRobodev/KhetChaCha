import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_preferences.dart';

/// Service managing persistent Farmer Notification Preferences.
class NotificationPreferencesService {
  NotificationPreferencesService._();
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  static const String _prefKeyPrefix = 'khetchacha_notif_prefs_';

  /// Loads notification preferences for a farmer, with safe defaults.
  Future<NotificationPreferences> getPreferences(String farmerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_prefKeyPrefix$farmerId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return NotificationPreferences.fromJsonString(jsonStr);
      }
    } catch (_) {}

    return const NotificationPreferences();
  }

  /// Saves updated notification preferences.
  Future<bool> savePreferences(
    String farmerId,
    NotificationPreferences preferences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        '$_prefKeyPrefix$farmerId',
        preferences.toJsonString(),
      );
    } catch (_) {
      return false;
    }
  }
}
