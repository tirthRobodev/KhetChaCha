import '../models/app_language.dart';

/// Authoritative single source of truth for all supported Indian languages.
/// Contains the 22 Eighth Schedule Indian Languages + English.
class LanguageData {
  LanguageData._();

  /// Default fallback language
  static const AppLanguage defaultLanguage = AppLanguage(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
  );

  /// 22 Scheduled Indian Languages + English
  static const List<AppLanguage> allLanguages = [
    AppLanguage(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
    ),
    AppLanguage(
      code: 'gu',
      englishName: 'Gujarati',
      nativeName: 'ગુજરાતી',
    ),
    AppLanguage(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
    ),
    AppLanguage(
      code: 'as',
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
    ),
    AppLanguage(
      code: 'bn',
      englishName: 'Bengali',
      nativeName: 'বাংলা',
    ),
    AppLanguage(
      code: 'brx',
      englishName: 'Bodo',
      nativeName: 'बड़ो',
    ),
    AppLanguage(
      code: 'doi',
      englishName: 'Dogri',
      nativeName: 'डोगरी',
    ),
    AppLanguage(
      code: 'kn',
      englishName: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
    ),
    AppLanguage(
      code: 'ks',
      englishName: 'Kashmiri',
      nativeName: 'कॉशुर / كٲشُر',
      isRtl: true,
    ),
    AppLanguage(
      code: 'kok',
      englishName: 'Konkani',
      nativeName: 'कोंकणी',
    ),
    AppLanguage(
      code: 'mai',
      englishName: 'Maithili',
      nativeName: 'मैथिली',
    ),
    AppLanguage(
      code: 'ml',
      englishName: 'Malayalam',
      nativeName: 'മലയാളം',
    ),
    AppLanguage(
      code: 'mni',
      englishName: 'Manipuri (Meitei)',
      nativeName: 'মেইতেই / ꯃꯤꯇꯩꯂꯣꯟ',
    ),
    AppLanguage(
      code: 'mr',
      englishName: 'Marathi',
      nativeName: 'मराठी',
    ),
    AppLanguage(
      code: 'ne',
      englishName: 'Nepali',
      nativeName: 'नेपाली',
    ),
    AppLanguage(
      code: 'or',
      englishName: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
    ),
    AppLanguage(
      code: 'pa',
      englishName: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
    ),
    AppLanguage(
      code: 'sa',
      englishName: 'Sanskrit',
      nativeName: 'संस्कृतम्',
    ),
    AppLanguage(
      code: 'sat',
      englishName: 'Santali',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
    ),
    AppLanguage(
      code: 'sd',
      englishName: 'Sindhi',
      nativeName: 'سنڌي / सिन्धी',
      isRtl: true,
    ),
    AppLanguage(
      code: 'ta',
      englishName: 'Tamil',
      nativeName: 'தமிழ்',
    ),
    AppLanguage(
      code: 'te',
      englishName: 'Telugu',
      nativeName: 'తెలుగు',
    ),
    AppLanguage(
      code: 'ur',
      englishName: 'Urdu',
      nativeName: 'اردو',
      isRtl: true,
    ),
  ];

  /// Find language by code with fallback to English
  static AppLanguage getByCode(String code) {
    return allLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => defaultLanguage,
    );
  }

  /// Search languages by English or Native name
  static List<AppLanguage> search(String query) {
    if (query.trim().isEmpty) {
      return allLanguages;
    }
    final q = query.trim().toLowerCase();
    return allLanguages.where((lang) {
      final matchesEnglish = lang.englishName.toLowerCase().contains(q);
      final matchesNative = lang.nativeName.toLowerCase().contains(q);
      final matchesCode = lang.code.toLowerCase().contains(q);
      return matchesEnglish || matchesNative || matchesCode;
    }).toList();
  }
}
