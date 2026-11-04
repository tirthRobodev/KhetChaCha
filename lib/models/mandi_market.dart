/// Classification of agricultural market entities in India.
enum MandiMarketType {
  apmcMandi,
  vegetableWholesale,
  grainMarket,
  fruitMarket,
  subziMandi,
}

extension MandiMarketTypeExtension on MandiMarketType {
  String get displayTitle {
    switch (this) {
      case MandiMarketType.apmcMandi:
        return 'APMC Principal Yard';
      case MandiMarketType.vegetableWholesale:
        return 'Vegetable Wholesale Market';
      case MandiMarketType.grainMarket:
        return 'Grain Market (Anaaj Mandi)';
      case MandiMarketType.fruitMarket:
        return 'Fruit Wholesale Mandi';
      case MandiMarketType.subziMandi:
        return 'Sabzi Mandi Yard';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MandiMarketType.apmcMandi:
        return '🏛️';
      case MandiMarketType.vegetableWholesale:
        return '🥦';
      case MandiMarketType.grainMarket:
        return '🌾';
      case MandiMarketType.fruitMarket:
        return '🍎';
      case MandiMarketType.subziMandi:
        return '🥬';
    }
  }
}

/// Mandi price entry for a verified commodity based on Agmarknet / eNAM standards.
class MandiCommodityPrice {
  final String commodity;
  final String variety;
  final String grade;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String unit;
  final DateTime lastUpdated;
  final DateTime? reportingDate;
  final String officialSource;
  final String verificationStatus;
  final double? previousModalPrice;
  final List<MandiPriceHistoryEntry> history;

  const MandiCommodityPrice({
    required this.commodity,
    this.variety = 'FAQ (Fair Average Quality)',
    this.grade = 'FAQ',
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    this.unit = '₹/Quintal',
    required this.lastUpdated,
    this.reportingDate,
    this.officialSource =
        'AGMARKNET / Gujarat State Agricultural Marketing Board',
    this.verificationStatus = 'Verified',
    this.previousModalPrice,
    this.history = const [],
  });

  Map<String, dynamic> toJson() => {
    'commodity': commodity,
    'variety': variety,
    'grade': grade,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'modalPrice': modalPrice,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
    'reportingDate': (reportingDate ?? lastUpdated).toIso8601String(),
    'officialSource': officialSource,
    'verificationStatus': verificationStatus,
    'previousModalPrice': previousModalPrice,
    'history': history.map((h) => h.toJson()).toList(),
  };

  factory MandiCommodityPrice.fromJson(Map<String, dynamic> json) =>
      MandiCommodityPrice(
        commodity: json['commodity'] as String? ?? '',
        variety: json['variety'] as String? ?? 'FAQ',
        grade: json['grade'] as String? ?? 'FAQ',
        minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
        modalPrice: (json['modalPrice'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '₹/Quintal',
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
            : DateTime.now(),
        reportingDate: json['reportingDate'] != null
            ? DateTime.tryParse(json['reportingDate'] as String)
            : null,
        officialSource:
            json['officialSource'] as String? ??
            'AGMARKNET / State Marketing Board',
        verificationStatus: json['verificationStatus'] as String? ?? 'Verified',
        previousModalPrice: (json['previousModalPrice'] as num?)?.toDouble(),
        history:
            (json['history'] as List<dynamic>?)
                ?.map(
                  (e) => MandiPriceHistoryEntry.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
      );
}

/// Historical price observation for trend analysis.
class MandiPriceHistoryEntry {
  final DateTime date;
  final double minPrice;
  final double modalPrice;
  final double maxPrice;
  final String source;
  final String verificationStatus;

  const MandiPriceHistoryEntry({
    required this.date,
    required this.minPrice,
    required this.modalPrice,
    required this.maxPrice,
    this.source = 'AGMARKNET',
    this.verificationStatus = 'Verified',
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'minPrice': minPrice,
    'modalPrice': modalPrice,
    'maxPrice': maxPrice,
    'source': source,
    'verificationStatus': verificationStatus,
  };

  factory MandiPriceHistoryEntry.fromJson(Map<String, dynamic> j) =>
      MandiPriceHistoryEntry(
        date: j['date'] != null
            ? DateTime.tryParse(j['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        minPrice: (j['minPrice'] as num?)?.toDouble() ?? 0.0,
        modalPrice: (j['modalPrice'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (j['maxPrice'] as num?)?.toDouble() ?? 0.0,
        source: j['source'] as String? ?? 'AGMARKNET',
        verificationStatus: j['verificationStatus'] as String? ?? 'Verified',
      );
}

/// Official Government of India Minimum Support Price (MSP) record.
class GovernmentMspRecord {
  final String commodity;
  final String cropSeason; // Kharif / Rabi
  final String marketingYear; // 2024-25 / 2025-26
  final double officialMsp; // ₹ / quintal
  final String unit; // ₹/Quintal
  final String notificationSource; // CCEA / Ministry of Agriculture
  final String effectivePeriod; // 2024-2025
  final bool isVerified;
  final bool isApplicable; // false for spices/vegetables with no statutory MSP
  final String varietySpecification;

  const GovernmentMspRecord({
    required this.commodity,
    required this.cropSeason,
    required this.marketingYear,
    required this.officialMsp,
    this.unit = '₹/Quintal',
    this.notificationSource =
        'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
    this.effectivePeriod = '2024-2025',
    this.isVerified = true,
    this.isApplicable = true,
    this.varietySpecification = 'FAQ Standard',
  });

  /// Official Government of India statutory MSP records (CCEA notifications)
  static final List<GovernmentMspRecord> officialMspRegistry = [
    const GovernmentMspRecord(
      commodity: 'Cotton',
      varietySpecification: 'Medium Staple',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 7121.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Cotton (Long Staple)',
      varietySpecification: 'Long Staple (H-4 / Shankar-6)',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 7521.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Wheat',
      varietySpecification: 'FAQ / Lokwan / Sharbati',
      cropSeason: 'Rabi',
      marketingYear: '2024-25',
      officialMsp: 2275.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'RMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Groundnut',
      varietySpecification: 'Groundnut in Shell (FAQ)',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 6783.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Paddy',
      varietySpecification: 'Common Grade',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 2300.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Mustard',
      varietySpecification: 'Rapeseed & Mustard (FAQ)',
      cropSeason: 'Rabi',
      marketingYear: '2024-25',
      officialMsp: 5650.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'RMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Gram',
      varietySpecification: 'Gram / Desi Chickpea',
      cropSeason: 'Rabi',
      marketingYear: '2024-25',
      officialMsp: 5440.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'RMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Soybean',
      varietySpecification: 'Yellow Soybean',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 4892.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Bajra',
      varietySpecification: 'Pearl Millet (Hybrid / Desi)',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 2625.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Maize',
      varietySpecification: 'Yellow Maize',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 2225.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
    const GovernmentMspRecord(
      commodity: 'Sesame',
      varietySpecification: 'White / Black Sesamum (Til)',
      cropSeason: 'Kharif',
      marketingYear: '2024-25',
      officialMsp: 9267.0,
      notificationSource:
          'Cabinet Committee on Economic Affairs (CCEA), Govt. of India',
      effectivePeriod: 'KMS 2024-25',
      isVerified: true,
      isApplicable: true,
    ),
  ];

  /// Look up the authentic official MSP record for a commodity.
  /// Returns a record with [isApplicable] = false if the commodity is a spice or horticultural
  /// produce that does not receive statutory CCEA MSP.
  static GovernmentMspRecord? getMspForCommodity(String cropName) {
    final lower = cropName.toLowerCase().trim();
    if (lower.isEmpty || lower.contains('all')) return null;

    // Check official list
    for (final m in officialMspRegistry) {
      final cLower = m.commodity.toLowerCase();
      if (cLower == lower || lower.contains(cLower) || cLower.contains(lower)) {
        return m;
      }
    }

    // Known crops where statutory MSP is explicitly not applicable
    const nonMspCrops = [
      'cumin',
      'jeera',
      'jiru',
      'castor',
      'eranda',
      'divela',
      'onion',
      'potato',
      'tomato',
      'fruits',
      'vegetables',
      'banana',
      'mango',
      'chilli',
      'garlic',
      'isabgol',
      'fennel',
      'saunf',
    ];

    if (nonMspCrops.any((k) => lower.contains(k))) {
      return GovernmentMspRecord(
        commodity: cropName,
        cropSeason: 'Open Auction',
        marketingYear: '2024-25',
        officialMsp: 0.0,
        notificationSource: 'Not Covered under CCEA Statutory MSP',
        effectivePeriod: 'Current Trading Year',
        isVerified: false,
        isApplicable: false,
        varietySpecification: 'Commercial / Horticultural Produce',
      );
    }

    return null;
  }
}

/// Official Indian Mandi / APMC model with verified coordinates and commodity prices.
class MandiMarket {
  final String id;
  final String name;
  final MandiMarketType type;
  final String state;
  final String district;
  final String taluka;
  final String address;
  final String pincode;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String contactPhone;
  final bool isVerified;
  final List<String> majorCommodities;
  final List<MandiCommodityPrice> commodityPrices;

  const MandiMarket({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
    required this.district,
    this.taluka = '',
    required this.address,
    this.pincode = '',
    required this.latitude,
    required this.longitude,
    this.openingHours = '06:00 AM - 05:00 PM',
    this.contactPhone = '',
    this.isVerified = true,
    this.majorCommodities = const [],
    this.commodityPrices = const [],
  });

  MandiCommodityPrice? getPriceForCommodity(String cropName) {
    final lower = cropName.toLowerCase();
    for (final p in commodityPrices) {
      if (p.commodity.toLowerCase() == lower ||
          p.commodity.toLowerCase().contains(lower) ||
          lower.contains(p.commodity.toLowerCase())) {
        return p;
      }
    }
    return null;
  }
}
