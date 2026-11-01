/// Represents localized name and regional aliases for a specific language.
class LocalizedCropName {
  final String name;
  final List<String> aliases;
  final List<String> transliterations;

  const LocalizedCropName({
    required this.name,
    this.aliases = const [],
    this.transliterations = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'aliases': aliases,
        'transliterations': transliterations,
      };

  factory LocalizedCropName.fromJson(Map<String, dynamic> json) => LocalizedCropName(
        name: json['name'] as String? ?? '',
        aliases: List<String>.from(json['aliases'] as List? ?? []),
        transliterations: List<String>.from(json['transliterations'] as List? ?? []),
      );
}

/// Official 11 Crop Categories defined for KhetChacha
enum CropCategoryType {
  cerealsMillets, // 1–20
  pulsesLegumes, // 21–45
  oilseeds, // 46–60
  commercialFibre, // 61–75
  vegetables, // 76–130
  fruits, // 131–180
  spicesHerbs, // 181–210
  medicinalPlants, // 211–235
  flowersOrnamental, // 236–260
  fodderForage, // 261–275
  plantationAgroforestry, // 276–300
}

/// Category metadata with icons, labels, and localized titles
class CropCategoryMeta {
  final String id;
  final String titleEn;
  final String titleGu;
  final String titleHi;
  final String iconEmoji;
  final int startNumber;
  final int endNumber;

  const CropCategoryMeta({
    required this.id,
    required this.titleEn,
    required this.titleGu,
    required this.titleHi,
    required this.iconEmoji,
    required this.startNumber,
    required this.endNumber,
  });

  String getTitle(String langCode) {
    if (langCode == 'gu') return titleGu;
    if (langCode == 'hi') return titleHi;
    return titleEn;
  }
}

/// Complete Master Record for a single Indian Cultivated Crop (1 of 300)
class CropMasterEntry {
  final String cropId; // CROP_001 to CROP_300
  final int itemNumber; // 1 to 300
  final String canonicalNameEn;
  final String categoryId;
  final String? scientificName;
  final bool isPopular;
  final String iconEmoji;
  final String? assetImage;
  final Map<String, LocalizedCropName> names;
  final List<String> searchKeywords;
  final List<String> linkedCropIds; // Cross-referenced synonyms (e.g. Amla <-> Indian gooseberry)
  final String? synonymOf;
  final bool isActive;

  const CropMasterEntry({
    required this.cropId,
    required this.itemNumber,
    required this.canonicalNameEn,
    required this.categoryId,
    this.scientificName,
    this.isPopular = false,
    required this.iconEmoji,
    this.assetImage,
    required this.names,
    this.searchKeywords = const [],
    this.linkedCropIds = const [],
    this.synonymOf,
    this.isActive = true,
  });

  /// Get localized display name for a given language code (fallback to English)
  String getLocalizedName(String langCode) {
    final lower = langCode.toLowerCase();
    if (names.containsKey(lower)) {
      return names[lower]!.name;
    }
    return canonicalNameEn;
  }

  /// Get secondary display label (shows English or transliteration for clarity)
  String getSecondaryLabel(String activeLangCode) {
    if (activeLangCode.toLowerCase() == 'en') {
      final gu = names['gu']?.name;
      final hi = names['hi']?.name;
      if (gu != null && gu.isNotEmpty) return gu;
      if (hi != null && hi.isNotEmpty) return hi;
      return '';
    }
    return canonicalNameEn;
  }

  /// Matches a search query across English, Gujarati, Hindi, regional aliases, and Roman transliterations
  bool matchesQuery(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    // 1. Match Canonical English Name
    if (canonicalNameEn.toLowerCase().contains(clean)) return true;

    // 2. Match Search Keywords
    for (final kw in searchKeywords) {
      if (kw.toLowerCase().contains(clean)) return true;
    }

    // 3. Match all populated localized names and aliases
    for (final localized in names.values) {
      if (localized.name.toLowerCase().contains(clean)) return true;
      for (final alias in localized.aliases) {
        if (alias.toLowerCase().contains(clean)) return true;
      }
      for (final translit in localized.transliterations) {
        if (translit.toLowerCase().contains(clean)) return true;
      }
    }

    return false;
  }

  Map<String, dynamic> toJson() => {
        'crop_id': cropId,
        'item_number': itemNumber,
        'canonical_name_en': canonicalNameEn,
        'category_id': categoryId,
        'scientific_name': scientificName,
        'is_popular': isPopular,
        'icon_emoji': iconEmoji,
        'asset_image': assetImage,
        'names': names.map((k, v) => MapEntry(k, v.toJson())),
        'search_keywords': searchKeywords,
        'linked_crop_ids': linkedCropIds,
        'synonym_of': synonymOf,
        'is_active': isActive,
      };

  factory CropMasterEntry.fromJson(Map<String, dynamic> json) => CropMasterEntry(
        cropId: json['crop_id'] as String? ?? '',
        itemNumber: json['item_number'] as int? ?? 0,
        canonicalNameEn: json['canonical_name_en'] as String? ?? '',
        categoryId: json['category_id'] as String? ?? '',
        scientificName: json['scientific_name'] as String?,
        isPopular: json['is_popular'] as bool? ?? false,
        iconEmoji: json['icon_emoji'] as String? ?? '🌱',
        assetImage: json['asset_image'] as String?,
        names: (json['names'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, LocalizedCropName.fromJson(Map<String, dynamic>.from(v as Map))),
        ),
        searchKeywords: List<String>.from(json['search_keywords'] as List? ?? []),
        linkedCropIds: List<String>.from(json['linked_crop_ids'] as List? ?? []),
        synonymOf: json['synonym_of'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}
