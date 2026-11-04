import '../localization/crop_multilingual_translations.dart';

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

  factory LocalizedCropName.fromJson(Map<String, dynamic> json) =>
      LocalizedCropName(
        name: json['name'] as String? ?? '',
        aliases: List<String>.from(json['aliases'] as List? ?? []),
        transliterations: List<String>.from(
          json['transliterations'] as List? ?? [],
        ),
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
  final String? titlePa;
  final String? titleMr;
  final String? titleTa;
  final String? titleTe;
  final String? titleKn;
  final String? titleMl;
  final String? titleBn;
  final String? titleOr;
  final String? titleAs;
  final String? titleUr;
  final String iconEmoji;
  final int startNumber;
  final int endNumber;

  const CropCategoryMeta({
    required this.id,
    required this.titleEn,
    required this.titleGu,
    required this.titleHi,
    this.titlePa,
    this.titleMr,
    this.titleTa,
    this.titleTe,
    this.titleKn,
    this.titleMl,
    this.titleBn,
    this.titleOr,
    this.titleAs,
    this.titleUr,
    required this.iconEmoji,
    required this.startNumber,
    required this.endNumber,
  });

  String getTitle(String langCode) {
    final lower = langCode.toLowerCase();
    switch (lower) {
      case 'gu':
        return titleGu;
      case 'hi':
        return titleHi;
      case 'pa':
        return titlePa ?? _categoryTranslations[id]?['pa'] ?? titleEn;
      case 'mr':
        return titleMr ?? _categoryTranslations[id]?['mr'] ?? titleEn;
      case 'ta':
        return titleTa ?? _categoryTranslations[id]?['ta'] ?? titleEn;
      case 'te':
        return titleTe ?? _categoryTranslations[id]?['te'] ?? titleEn;
      case 'kn':
        return titleKn ?? _categoryTranslations[id]?['kn'] ?? titleEn;
      case 'ml':
        return titleMl ?? _categoryTranslations[id]?['ml'] ?? titleEn;
      case 'bn':
        return titleBn ?? _categoryTranslations[id]?['bn'] ?? titleEn;
      case 'or':
        return titleOr ?? _categoryTranslations[id]?['or'] ?? titleEn;
      case 'as':
        return titleAs ?? _categoryTranslations[id]?['as'] ?? titleEn;
      case 'ur':
        return titleUr ?? _categoryTranslations[id]?['ur'] ?? titleEn;
      default:
        final regional = _categoryTranslations[id]?[lower];
        if (regional != null && regional.isNotEmpty) return regional;
        if (const ['mai', 'kok', 'ne', 'doi', 'sa', 'brx'].contains(lower)) {
          return titleHi;
        }
        return titleEn;
    }
  }

  static const Map<String, Map<String, String>> _categoryTranslations = {
    'all': {
      'pa': 'ਸਾਰੇ (ਪ੍ਰਸਿੱਧ)',
      'mr': 'सर्व (लोकप्रिय)',
      'bn': 'সব (জনপ্রিয়)',
      'ta': 'அனைத்தும் (பிரபலம்)',
      'te': 'అన్నీ (ప్రసిద్ధమైనవి)',
      'kn': 'ಎಲ್ಲವೂ (ಜನಪ್ರಿಯ)',
      'ml': 'എല്ലാം (ജനപ്രിയം)',
      'or': 'ସବୁ (ଲୋକପ୍ରିୟ)',
      'as': 'সকলো (জনপ্ৰিয়)',
      'ur': 'سب (مقبول)',
    },
    'cereals_millets': {
      'pa': 'ਫ਼ਸਲਾਂ (ਅਨਾਜ)',
      'mr': 'धान्य आणि पिके',
      'bn': 'খাদ্যশস্য ও ফসল',
      'ta': 'தானியங்கள்',
      'te': 'ధాన్యాలు',
      'kn': 'ಧಾನ್ಯಗಳು',
      'ml': 'ധാന്യങ്ങൾ',
      'or': 'ଦାନା ଫସଲ',
      'as': 'শস্য আৰু খাদ্যশস্য',
      'ur': 'اناج اور فصلیں',
    },
    'pulses_legumes': {
      'pa': 'ਦਾਲਾਂ ਅਤੇ ਦਲਹਨ',
      'mr': 'डाळी आणि कडधान्ये',
      'bn': 'ডাল ও কলাই',
      'ta': 'பருப்பு வகைகள்',
      'te': 'పప్పుదినుసులు',
      'kn': 'ಕಾಳುಗಳು',
      'ml': 'പയറുവർഗ്ਗങ്ങൾ',
      'or': 'ଡାଲି ଜାତୀୟ',
      'as': 'দাইল আৰু মাহজাতীয়',
      'ur': 'دالیں اور پھلیاں',
    },
    'oilseeds': {
      'pa': 'ਤੇਲ ਬੀਜ',
      'mr': 'तेलबिया पिके',
      'bn': 'তৈলবীজ',
      'ta': 'எண்ணெய் வித்துக்கள்',
      'te': 'నూనెగింజలు',
      'kn': 'ಎಣ್ಣೆಕಾಳುಗಳು',
      'ml': 'എണ്ണക്കുരുക്കൾ',
      'or': 'ତୈଳବୀଜ',
      'as': 'তৈলবীজ',
      'ur': 'تیل دار اجناس',
    },
    'commercial_fibre': {
      'pa': 'ਨਕਦੀ ਅਤੇ ਰੇਸ਼ੇਦਾਰ',
      'mr': 'नगदी व धागा पिके',
      'bn': 'বাণিজ্যিক ও আঁশ',
      'ta': 'பணப்பயிர்கள்',
      'te': 'వాణిజ్య పంటలు',
      'kn': 'ವಾಣಿಜ್ಯ ಬೆಳೆಗಳು',
      'ml': 'ವಾണിಜ್ಯ വിളകൾ',
      'or': 'ଅର୍ଥକାରୀ ଫସଲ',
      'as': 'বাণিজ্যিক শস্য',
      'ur': 'نقد آور فصلیں',
    },
    'vegetables': {
      'pa': 'ਸਬਜ਼ੀਆਂ',
      'mr': 'भाजीपाला',
      'bn': 'শাকসবজি',
      'ta': 'காய்கறிகள்',
      'te': 'కూరగాయలు',
      'kn': 'ತರಕಾರಿಗಳು',
      'ml': 'പച്ചക്കറികൾ',
      'or': 'ପନିପରିବା',
      'as': 'শাক-পাচলি',
      'ur': 'سبزیاں',
    },
    'fruits_nuts': {
      'pa': 'ਫਲ ਅਤੇ ਬਾਗਬਾਨੀ',
      'mr': 'फळे आणि फळबागा',
      'bn': 'ফলমূল ও বাগান',
      'ta': 'பழங்கள்',
      'te': 'పండ్లు',
      'kn': 'ಹಣ್ಣುಗಳು',
      'ml': 'പഴങ്ങൾ',
      'or': 'ଫଳମୂଳ',
      'as': 'ফল-মূল',
      'ur': 'پھل اور باغبانی',
    },
    'spices_condiments': {
      'pa': 'ਮਸਾਲੇ',
      'mr': 'मसाले पिके',
      'bn': 'মসলা',
      'ta': 'மசாலா பொருட்கள்',
      'te': 'సుగంధ ద్రవ్యాలు',
      'kn': 'ಸಾಂಬಾರ ಪದಾರ್ಥಗಳು',
      'ml': 'സുഗന്ധവ്യഞ്ജനങ്ങൾ',
      'or': 'ମସଲା',
      'as': 'মচলা',
      'ur': 'مصالحہ جات',
    },
    'flowers_aromatic': {
      'pa': 'ਫੁੱਲ ਅਤੇ ਖੁਸ਼ਬੂਦਾਰ',
      'mr': 'फुले व सुगंधी वनस्पती',
      'bn': 'ফুল ও সুগন্ধি',
      'ta': 'மலர்கள்',
      'te': 'పూలు',
      'kn': 'ಹೂವುಗಳು',
      'ml': 'പൂക്കൾ',
      'or': 'ଫୁଲ',
      'as': 'ফুল',
      'ur': 'پھول',
    },
    'medicinal': {
      'pa': 'ਔਸ਼ਧੀ ਬੂਟੇ',
      'mr': 'औषधी वनस्पती',
      'bn': 'ভেষজ উদ্ভিদ',
      'ta': 'மூலிகைகள்',
      'te': 'ఔషధ మొక్కలు',
      'kn': 'ಔಷಧೀಯ ಸಸ್ಯಗಳು',
      'ml': 'ഔഷധസസ്യങ്ങൾ',
      'or': 'ଔଷଧୀୟ ବୃକ୍ଷ',
      'as': 'ঔষধি গছ',
      'ur': 'ادویاتی پودے',
    },
    'fodder': {
      'pa': 'ਚਾਰਾ',
      'mr': 'चारा पिके',
      'bn': 'গবাদি খাদ্য',
      'ta': 'தீவனம்',
      'te': 'పశుగ్రాసం',
      'kn': 'ಮೇವು',
      'ml': 'തീറ്റപ്പുല്ല്',
      'or': 'ଘାସଚାରା',
      'as': 'ঘাঁহ-বন',
      'ur': 'چارہ',
    },
    'plantation_trees': {
      'pa': 'ਜੰਗਲਾਤ ਰੁੱਖ',
      'mr': 'वनीकरण व लाकूड',
      'bn': 'বনজ গাছ',
      'ta': 'மரங்கள்',
      'te': 'కలప చెట్లు',
      'kn': 'ಅರಣ್ಯ ಮರಗಳು',
      'ml': 'തടിമരങ്ങൾ',
      'or': 'କାଠ ଗଛ',
      'as': 'কাঠ গছ',
      'ur': 'جنگلاتی درخت',
    },
  };
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
  final String imageAssetId;
  final String? imageUrl;
  final String imageStatus; // 'verified' | 'pending'
  final Map<String, String> imageAltText; // {'en': '...', 'gu': '...'}
  final String visualBadge; // 2-letter distinctive code e.g. 'WH', 'TR', 'MG'
  final int badgeColorValue; // Color int for distinctive appearance
  final Map<String, LocalizedCropName> names;
  final List<String> searchKeywords;
  final List<String>
  linkedCropIds; // Cross-referenced synonyms (e.g. Amla <-> Indian gooseberry)
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
    this.imageAssetId = '',
    this.imageUrl,
    this.imageStatus = 'pending',
    this.imageAltText = const {},
    this.visualBadge = '',
    this.badgeColorValue = 0xFF2E7D32,
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
      final val = names[lower]!.name;
      if (val.isNotEmpty) return val;
    }
    // Check authoritative multilingual translations
    final trans = CropMultilingualTranslations.getLocalizedName(cropId, lower);
    if (trans != null && trans.isNotEmpty) {
      return trans;
    }
    // If not found and language uses Devanagari script, fallback to Hindi if present
    if (const ['mr', 'mai', 'kok', 'ne', 'doi', 'sa', 'brx'].contains(lower)) {
      final hi = names['hi']?.name;
      if (hi != null && hi.isNotEmpty) return hi;
    }
    return canonicalNameEn;
  }

  /// Returns the secondary reference label shown beneath the primary name.
  ///
  /// - English active language: no secondary label is needed, returns ''.
  /// - Non-English active language: returns the English canonical name.
  String getSecondaryLabel(String activeLangCode) {
    if (activeLangCode.toLowerCase() == 'en') {
      return '';
    }
    return canonicalNameEn;
  }

  /// Get localized accessibility / image alt text
  String getAltText(String langCode) {
    final lower = langCode.toLowerCase();
    if (imageAltText.containsKey(lower) && imageAltText[lower]!.isNotEmpty) {
      return imageAltText[lower]!;
    }
    return imageAltText['en'] ?? canonicalNameEn;
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

    // 4. Match multilingual translations
    final multi = CropMultilingualTranslations.getTranslations(cropId);
    if (multi != null) {
      for (final val in multi.values) {
        if (val.toLowerCase().contains(clean)) return true;
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
    'image_asset_id': imageAssetId,
    'image_url': imageUrl,
    'image_status': imageStatus,
    'image_alt_text': imageAltText,
    'visual_badge': visualBadge,
    'badge_color_value': badgeColorValue,
    'names': names.map((k, v) => MapEntry(k, v.toJson())),
    'search_keywords': searchKeywords,
    'linked_crop_ids': linkedCropIds,
    'synonym_of': synonymOf,
    'is_active': isActive,
  };

  factory CropMasterEntry.fromJson(
    Map<String, dynamic> json,
  ) => CropMasterEntry(
    cropId: json['crop_id'] as String? ?? '',
    itemNumber: json['item_number'] as int? ?? 0,
    canonicalNameEn: json['canonical_name_en'] as String? ?? '',
    categoryId: json['category_id'] as String? ?? '',
    scientificName: json['scientific_name'] as String?,
    isPopular: json['is_popular'] as bool? ?? false,
    iconEmoji: json['icon_emoji'] as String? ?? '🌱',
    assetImage: json['asset_image'] as String?,
    imageAssetId:
        json['image_asset_id'] as String? ??
        'crop_${(json['crop_id'] as String? ?? '').toLowerCase()}',
    imageUrl: json['image_url'] as String?,
    imageStatus: json['image_status'] as String? ?? 'pending',
    imageAltText: Map<String, String>.from(
      json['image_alt_text'] as Map? ?? {},
    ),
    visualBadge: json['visual_badge'] as String? ?? '',
    badgeColorValue: json['badge_color_value'] as int? ?? 0xFF2E7D32,
    names: (json['names'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(
        k,
        LocalizedCropName.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    ),
    searchKeywords: List<String>.from(json['search_keywords'] as List? ?? []),
    linkedCropIds: List<String>.from(json['linked_crop_ids'] as List? ?? []),
    synonymOf: json['synonym_of'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );
}
