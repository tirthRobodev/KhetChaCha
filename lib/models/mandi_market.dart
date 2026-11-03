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
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String unit;
  final DateTime lastUpdated;

  const MandiCommodityPrice({
    required this.commodity,
    this.variety = 'FAQ (Fair Average Quality)',
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    this.unit = '₹/Quintal',
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'commodity': commodity,
    'variety': variety,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'modalPrice': modalPrice,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory MandiCommodityPrice.fromJson(Map<String, dynamic> json) =>
      MandiCommodityPrice(
        commodity: json['commodity'] as String? ?? '',
        variety: json['variety'] as String? ?? 'FAQ',
        minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
        modalPrice: (json['modalPrice'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '₹/Quintal',
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
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
