import 'dart:convert';

/// Categories of Agricultural Government News and Farmer Updates
enum AgricultureNewsCategory {
  latestGovtNews,
  newSchemes,
  farmerSubsidies,
  cropInsurance,
  pmKisan,
  fertilizerUpdates,
  seedDistribution,
  mandiPriceNews,
  weatherWarnings,
  pestDiseaseAlerts,
  agriCreditLoans,
  mspAnnouncements,
  stateGovtNews,
  farmerTrainingEvents,
  importantDeadlines,
}

extension AgricultureNewsCategoryExtension on AgricultureNewsCategory {
  String get displayNameEn {
    switch (this) {
      case AgricultureNewsCategory.latestGovtNews:
        return 'Latest Govt News';
      case AgricultureNewsCategory.newSchemes:
        return 'New Govt Schemes';
      case AgricultureNewsCategory.farmerSubsidies:
        return 'Farmer Subsidies';
      case AgricultureNewsCategory.cropInsurance:
        return 'Crop Insurance Updates';
      case AgricultureNewsCategory.pmKisan:
        return 'PM-KISAN Updates';
      case AgricultureNewsCategory.fertilizerUpdates:
        return 'Fertilizer Updates';
      case AgricultureNewsCategory.seedDistribution:
        return 'Seed Distribution';
      case AgricultureNewsCategory.mandiPriceNews:
        return 'Mandi Price News';
      case AgricultureNewsCategory.weatherWarnings:
        return 'Weather Warnings';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'Pest & Disease Alerts';
      case AgricultureNewsCategory.agriCreditLoans:
        return 'Loan & Agri Credit';
      case AgricultureNewsCategory.mspAnnouncements:
        return 'MSP Announcements';
      case AgricultureNewsCategory.stateGovtNews:
        return 'State Agriculture News';
      case AgricultureNewsCategory.farmerTrainingEvents:
        return 'Farmer Training & Events';
      case AgricultureNewsCategory.importantDeadlines:
        return 'Important Deadlines';
    }
  }

  String get displayNameGu {
    switch (this) {
      case AgricultureNewsCategory.latestGovtNews:
        return 'તાજા સરકારી સમાચાર';
      case AgricultureNewsCategory.newSchemes:
        return 'નવી સરકારી યોજનાઓ';
      case AgricultureNewsCategory.farmerSubsidies:
        return 'ખેડૂત સબસિડી';
      case AgricultureNewsCategory.cropInsurance:
        return 'પાક વીમા અપડેટ્સ';
      case AgricultureNewsCategory.pmKisan:
        return 'પીએમ-કિસાન અપડેટ્સ';
      case AgricultureNewsCategory.fertilizerUpdates:
        return 'ખાતર વિતરણ';
      case AgricultureNewsCategory.seedDistribution:
        return 'બિયારણ વિતરણ';
      case AgricultureNewsCategory.mandiPriceNews:
        return 'બજાર ભાવ સમાચાર';
      case AgricultureNewsCategory.weatherWarnings:
        return 'હવામાન ચેતવણી';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'રોગ-જીવાત એલર્ટ';
      case AgricultureNewsCategory.agriCreditLoans:
        return 'કૃષિ લોન અને ધિરાણ';
      case AgricultureNewsCategory.mspAnnouncements:
        return 'ટેકાના ભાવ (MSP)';
      case AgricultureNewsCategory.stateGovtNews:
        return 'રાજ્ય કૃષિ સમાચાર';
      case AgricultureNewsCategory.farmerTrainingEvents:
        return 'ખેડૂત તાલીમ અને શિબિર';
      case AgricultureNewsCategory.importantDeadlines:
        return 'મહત્વપૂર્ણ છેલ્લી તારીખો';
    }
  }

  String get displayNameHi {
    switch (this) {
      case AgricultureNewsCategory.latestGovtNews:
        return 'नवीनतम सरकारी समाचार';
      case AgricultureNewsCategory.newSchemes:
        return 'नई सरकारी योजनाएँ';
      case AgricultureNewsCategory.farmerSubsidies:
        return 'किसान सब्सिडी';
      case AgricultureNewsCategory.cropInsurance:
        return 'फसल बीमा अपडेट';
      case AgricultureNewsCategory.pmKisan:
        return 'पीएम-किसान अपडेट';
      case AgricultureNewsCategory.fertilizerUpdates:
        return 'उर्वरक एवं खाद';
      case AgricultureNewsCategory.seedDistribution:
        return 'बीज वितरण';
      case AgricultureNewsCategory.mandiPriceNews:
        return 'मंडी भाव समाचार';
      case AgricultureNewsCategory.weatherWarnings:
        return 'मौसम चेतावनी';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'कीट एवं रोग चेतावनी';
      case AgricultureNewsCategory.agriCreditLoans:
        return 'कृषि ऋण एवं क्रेडिट';
      case AgricultureNewsCategory.mspAnnouncements:
        return 'एमएसपी (MSP) घोषणाएँ';
      case AgricultureNewsCategory.stateGovtNews:
        return 'राज्य कृषि समाचार';
      case AgricultureNewsCategory.farmerTrainingEvents:
        return 'किसान प्रशिक्षण व मेले';
      case AgricultureNewsCategory.importantDeadlines:
        return 'महत्वपूर्ण अंतिम तिथियाँ';
    }
  }

  String get displayNamePa {
    switch (this) {
      case AgricultureNewsCategory.latestGovtNews:
        return 'ਤਾਜ਼ਾ ਸਰਕਾਰੀ ਖ਼ਬਰਾਂ';
      case AgricultureNewsCategory.newSchemes:
        return 'ਨਵੀਆਂ ਸਰਕਾਰੀ ਸਕੀਮਾਂ';
      case AgricultureNewsCategory.farmerSubsidies:
        return 'ਕਿਸਾਨ ਸਬਸਿਡੀਆਂ';
      case AgricultureNewsCategory.cropInsurance:
        return 'ਫ਼ਸਲ ਬੀਮਾ ਅਪਡੇਟਸ';
      case AgricultureNewsCategory.pmKisan:
        return 'ਪੀਐਮ-ਕਿਸਾਨ ਅਪਡੇਟਸ';
      case AgricultureNewsCategory.fertilizerUpdates:
        return 'ਖਾਦ ਵੰਡ';
      case AgricultureNewsCategory.seedDistribution:
        return 'ਬੀਜ ਵੰਡ';
      case AgricultureNewsCategory.mandiPriceNews:
        return 'ਮੰਡੀ ਭਾਅ ਖ਼ਬਰਾਂ';
      case AgricultureNewsCategory.weatherWarnings:
        return 'ਮੌਸਮ ਚੇਤਾਵਨੀ';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'ਕੀੜੇ-ਮਕੌੜੇ ਚੇਤਾਵਨੀ';
      case AgricultureNewsCategory.agriCreditLoans:
        return 'ਖੇਤੀਬਾੜੀ ਕਰਜ਼ਾ';
      case AgricultureNewsCategory.mspAnnouncements:
        return 'ਐਮਐਸਪੀ (MSP) ਐਲਾਨ';
      case AgricultureNewsCategory.stateGovtNews:
        return 'ਸੂਬਾਈ ਖੇਤੀ ਖ਼ਬਰਾਂ';
      case AgricultureNewsCategory.farmerTrainingEvents:
        return 'ਕਿਸਾਨ ਸਿਖਲਾਈ ਤੇ ਮੇਲੇ';
      case AgricultureNewsCategory.importantDeadlines:
        return 'ਜ਼ਰੂਰੀ ਆਖ਼ਰੀ ਮਿਤੀਆਂ';
    }
  }

  String get displayNameMr {
    switch (this) {
      case AgricultureNewsCategory.latestGovtNews:
        return 'ताज्या सरकारी बातम्या';
      case AgricultureNewsCategory.newSchemes:
        return 'नवीन सरकारी योजना';
      case AgricultureNewsCategory.farmerSubsidies:
        return 'शेतकरी सबसिडी';
      case AgricultureNewsCategory.cropInsurance:
        return 'पीक विमा अपडेट्स';
      case AgricultureNewsCategory.pmKisan:
        return 'पीएम-किसान अपडेट्स';
      case AgricultureNewsCategory.fertilizerUpdates:
        return 'खत वितरण';
      case AgricultureNewsCategory.seedDistribution:
        return 'बियाणे वितरण';
      case AgricultureNewsCategory.mandiPriceNews:
        return 'बाजार भाव बातम्या';
      case AgricultureNewsCategory.weatherWarnings:
        return 'हवामान इशारा';
      case AgricultureNewsCategory.pestDiseaseAlerts:
        return 'रोग व कीड इशारा';
      case AgricultureNewsCategory.agriCreditLoans:
        return 'कृषी कर्ज व पतपुरवठा';
      case AgricultureNewsCategory.mspAnnouncements:
        return 'हमीभाव (MSP) घोषणा';
      case AgricultureNewsCategory.stateGovtNews:
        return 'राज्य कृषी बातम्या';
      case AgricultureNewsCategory.farmerTrainingEvents:
        return 'शेतकरी प्रशिक्षण मेळावे';
      case AgricultureNewsCategory.importantDeadlines:
        return 'महत्त्वाच्या अंतिम मुदती';
    }
  }

  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return displayNameGu;
      case 'hi':
        return displayNameHi;
      case 'pa':
        return displayNamePa;
      case 'mr':
        return displayNameMr;
      default:
        return displayNameEn;
    }
  }
}

/// Official Government Agriculture News & Farmer Alert item
class AgricultureNewsItem {
  final String id;
  final String headline;
  final String description;
  final String aiSummary; // Simplified farmer-friendly action advice
  final String originalSource; // e.g. Ministry of Agriculture, PM-KISAN, IMD, iKhedut
  final String officialSourceUrl;
  final DateTime publishedDate;
  final DateTime lastUpdatedDate;
  final String applicableState; // 'All India', 'Gujarat', 'Punjab', 'Maharashtra', etc.
  final List<String> applicableDistricts; // ['All'] or specific districts
  final AgricultureNewsCategory category;
  final List<String> relevantCrops; // ['All'] or ['Groundnut', 'Cotton', 'Wheat']
  final DateTime? applicationDeadline;
  final bool isVerified;
  final String iconEmoji;
  final bool isBookmarked;
  final Map<String, String>? localizedHeadlines;
  final Map<String, String>? localizedDescriptions;
  final Map<String, String>? localizedSummaries;

  const AgricultureNewsItem({
    required this.id,
    required this.headline,
    required this.description,
    required this.aiSummary,
    required this.originalSource,
    required this.officialSourceUrl,
    required this.publishedDate,
    required this.lastUpdatedDate,
    this.applicableState = 'All India',
    this.applicableDistricts = const ['All'],
    required this.category,
    this.relevantCrops = const ['All Crops'],
    this.applicationDeadline,
    this.isVerified = true,
    this.iconEmoji = '📰',
    this.isBookmarked = false,
    this.localizedHeadlines,
    this.localizedDescriptions,
    this.localizedSummaries,
  });

  /// Retrieve localized headline with intelligent language fallback
  String getLocalizedHeadline(String langCode) {
    final lc = langCode.toLowerCase();
    if (localizedHeadlines != null && localizedHeadlines!.containsKey(lc) && localizedHeadlines![lc]!.isNotEmpty) {
      return localizedHeadlines![lc]!;
    }
    // Fallback: If Hindi is present and requested is non-English, try Hindi first
    if (lc != 'en' && localizedHeadlines != null && localizedHeadlines!.containsKey('hi') && localizedHeadlines!['hi']!.isNotEmpty) {
      return localizedHeadlines!['hi']!;
    }
    return headline;
  }

  /// Retrieve localized description with intelligent language fallback
  String getLocalizedDescription(String langCode) {
    final lc = langCode.toLowerCase();
    if (localizedDescriptions != null && localizedDescriptions!.containsKey(lc) && localizedDescriptions![lc]!.isNotEmpty) {
      return localizedDescriptions![lc]!;
    }
    if (lc != 'en' && localizedDescriptions != null && localizedDescriptions!.containsKey('hi') && localizedDescriptions!['hi']!.isNotEmpty) {
      return localizedDescriptions!['hi']!;
    }
    return description;
  }

  /// Retrieve localized farmer-friendly summary
  String getLocalizedSummary(String langCode) {
    final lc = langCode.toLowerCase();
    if (localizedSummaries != null && localizedSummaries!.containsKey(lc) && localizedSummaries![lc]!.isNotEmpty) {
      return localizedSummaries![lc]!;
    }
    if (lc != 'en' && localizedSummaries != null && localizedSummaries!.containsKey('hi') && localizedSummaries!['hi']!.isNotEmpty) {
      return localizedSummaries!['hi']!;
    }
    if (aiSummary.isNotEmpty && lc == 'en') {
      return aiSummary;
    }
    return aiSummary;
  }

  /// Check whether this news applies to a specific state and district
  bool matchesLocation({required String state, required String district}) {
    if (applicableState.toLowerCase() == 'all india' ||
        applicableState.toLowerCase() == 'national' ||
        applicableState.isEmpty) {
      return true;
    }

    if (applicableState.toLowerCase() != state.toLowerCase()) {
      return false;
    }

    if (applicableDistricts.contains('All') ||
        applicableDistricts.isEmpty ||
        applicableDistricts.any((d) => d.toLowerCase() == district.toLowerCase())) {
      return true;
    }

    return false;
  }

  /// Check whether this news applies to any of the farmer's crops
  bool matchesCrops(List<String> farmerCrops) {
    if (relevantCrops.contains('All') ||
        relevantCrops.contains('All Crops') ||
        relevantCrops.isEmpty) {
      return true;
    }

    return relevantCrops.any((c) =>
        farmerCrops.any((fc) => fc.toLowerCase().contains(c.toLowerCase()) ||
            c.toLowerCase().contains(fc.toLowerCase())));
  }

  AgricultureNewsItem copyWith({
    bool? isBookmarked,
    bool? isVerified,
    String? aiSummary,
    AgricultureNewsCategory? category,
    String? applicableState,
    Map<String, String>? localizedHeadlines,
    Map<String, String>? localizedDescriptions,
    Map<String, String>? localizedSummaries,
  }) {
    return AgricultureNewsItem(
      id: id,
      headline: headline,
      description: description,
      aiSummary: aiSummary ?? this.aiSummary,
      originalSource: originalSource,
      officialSourceUrl: officialSourceUrl,
      publishedDate: publishedDate,
      lastUpdatedDate: lastUpdatedDate,
      applicableState: applicableState ?? this.applicableState,
      applicableDistricts: applicableDistricts,
      category: category ?? this.category,
      relevantCrops: relevantCrops,
      applicationDeadline: applicationDeadline,
      isVerified: isVerified ?? this.isVerified,
      iconEmoji: iconEmoji,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      localizedHeadlines: localizedHeadlines ?? this.localizedHeadlines,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
      localizedSummaries: localizedSummaries ?? this.localizedSummaries,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'headline': headline,
    'description': description,
    'aiSummary': aiSummary,
    'originalSource': originalSource,
    'officialSourceUrl': officialSourceUrl,
    'publishedDate': publishedDate.toIso8601String(),
    'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
    'applicableState': applicableState,
    'applicableDistricts': applicableDistricts,
    'category': category.name,
    'relevantCrops': relevantCrops,
    'applicationDeadline': applicationDeadline?.toIso8601String(),
    'isVerified': isVerified,
    'iconEmoji': iconEmoji,
    'isBookmarked': isBookmarked,
    'localizedHeadlines': localizedHeadlines,
    'localizedDescriptions': localizedDescriptions,
    'localizedSummaries': localizedSummaries,
  };

  factory AgricultureNewsItem.fromJson(Map<String, dynamic> json) {
    return AgricultureNewsItem(
      id: json['id'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      aiSummary: json['aiSummary'] as String? ?? '',
      originalSource: json['originalSource'] as String? ?? 'Govt Press Release',
      officialSourceUrl: json['officialSourceUrl'] as String? ?? '',
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'] as String)
          : DateTime.now(),
      lastUpdatedDate: json['lastUpdatedDate'] != null
          ? DateTime.parse(json['lastUpdatedDate'] as String)
          : DateTime.now(),
      applicableState: json['applicableState'] as String? ?? 'All India',
      applicableDistricts: List<String>.from(json['applicableDistricts'] as List? ?? ['All']),
      category: AgricultureNewsCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AgricultureNewsCategory.latestGovtNews,
      ),
      relevantCrops: List<String>.from(json['relevantCrops'] as List? ?? ['All Crops']),
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.tryParse(json['applicationDeadline'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? true,
      iconEmoji: json['iconEmoji'] as String? ?? '📰',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      localizedHeadlines: (json['localizedHeadlines'] as Map?)?.cast<String, String>(),
      localizedDescriptions: (json['localizedDescriptions'] as Map?)?.cast<String, String>(),
      localizedSummaries: (json['localizedSummaries'] as Map?)?.cast<String, String>(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AgricultureNewsItem.fromJsonString(String str) =>
      AgricultureNewsItem.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
