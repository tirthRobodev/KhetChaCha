/// Model representing a crop, vegetable, fruit, or flower in KhetChacha.
class FarmProduct {
  final String id;
  final String englishName;
  final String category; // 'crops', 'vegetables', 'fruits', 'flowers'
  final bool isPopular;
  final String iconEmoji;
  final String? assetImage;
  final List<String> recommendedStates;
  final Map<String, String> translations;

  const FarmProduct({
    required this.id,
    required this.englishName,
    required this.category,
    this.isPopular = false,
    required this.iconEmoji,
    this.assetImage,
    this.recommendedStates = const [],
    this.translations = const {},
  });

  /// Retrieves the localized product name according to the active language code.
  String getLocalizedName(String langCode) {
    final lower = langCode.toLowerCase();
    if (translations.containsKey(lower)) {
      return translations[lower]!;
    }
    // Fallback to English
    return englishName;
  }
}

