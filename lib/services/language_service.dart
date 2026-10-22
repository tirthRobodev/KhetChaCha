import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';
import '../localization/language_data.dart';

/// Single source of truth for app language preference.
/// Manages reactive locale updates and persistence using [SharedPreferences].
class LanguageService extends ChangeNotifier {
  static const String _prefKey = 'khetchacha_selected_language_code';

  static final LanguageService instance = LanguageService._internal();

  LanguageService._internal();

  AppLanguage _currentLanguage = LanguageData.defaultLanguage;

  AppLanguage get currentLanguage => _currentLanguage;

  Locale get currentLocale => _currentLanguage.locale;

  bool get isRtl => _currentLanguage.isRtl;

  /// Loads the persisted language selection on app launch
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        _currentLanguage = LanguageData.getByCode(savedCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LanguageService.init() error: $e');
    }
  }

  /// Sets and persists a new language selection, updating the app locale reactively
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (e) {
      debugPrint('LanguageService.setLanguage() error saving preference: $e');
    }
  }
}
