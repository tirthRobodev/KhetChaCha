/// Tier of recommendation based on farmer's soil, irrigation, and season.
enum RecommendationTier { bestSuitable, alternative, seasonalOpportunity }

/// Risk classification based on climate vulnerability, pest susceptibility, and market price volatility.
enum CropRiskLevel { low, medium, high }

extension CropRiskLevelExtension on CropRiskLevel {
  String get displayNameEn {
    switch (this) {
      case CropRiskLevel.low:
        return 'Low Risk';
      case CropRiskLevel.medium:
        return 'Moderate Risk';
      case CropRiskLevel.high:
        return 'High Risk / High Return';
    }
  }

  String get displayNameGu {
    switch (this) {
      case CropRiskLevel.low:
        return 'ઓછું જોખમ';
      case CropRiskLevel.medium:
        return 'મધ્યમ જોખમ';
      case CropRiskLevel.high:
        return 'વધુ જોખમ / વધુ નફો';
    }
  }

  String get displayNameHi {
    switch (this) {
      case CropRiskLevel.low:
        return 'कम जोखिम';
      case CropRiskLevel.medium:
        return 'मध्यम जोखिम';
      case CropRiskLevel.high:
        return 'उच्च जोखिम / अधिक लाभ';
    }
  }

  String get displayNamePa {
    switch (this) {
      case CropRiskLevel.low:
        return 'ਘੱਟ ਜੋਖਮ';
      case CropRiskLevel.medium:
        return 'ਦਰਮਿਆਨਾ ਜੋਖਮ';
      case CropRiskLevel.high:
        return 'ਉੱਚ ਜੋਖਮ / ਵੱਧ ਮੁਨਾਫਾ';
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
      default:
        return displayNameEn;
    }
  }
}

/// Rich agricultural recommendation model based on ICAR, KVK, and State Agri University guidelines.
class CropRecommendation {
  final String cropId;
  final String englishName;
  final String? nativeName;
  final int suitabilityScore; // 0 - 100%
  final String bestSowingPeriod;
  final String expectedHarvestPeriod;
  final String expectedDuration;
  final String waterRequirement;
  final String soilSuitability;
  final String estimatedCost;
  final String potentialSellingPrice;
  final String expectedYieldRange;
  final String yieldSource;
  final String recommendationReason;
  final RecommendationTier tier;
  final String season;
  final String iconEmoji;

  // Itemized Cultivation Economics per Acre (Section 4 & 10)
  final double seedCostPerAcre;
  final double fertilizerCostPerAcre;
  final double pesticideCostPerAcre;
  final double labourCostPerAcre;
  final double irrigationCostPerAcre;
  final double machineryCostPerAcre;
  final double otherCostPerAcre;

  // Revenue & Production per Acre
  final double expectedYieldQuintalsPerAcre;
  final double mandiSellingPricePerQuintal;

  // Risk & Agronomic Evaluation
  final CropRiskLevel riskLevel;
  final String riskExplanation;
  final bool isLegume; // Important for crop rotation nitrogen-fixation
  final DateTime lastUpdated;
  final bool isVerifiedData;

  const CropRecommendation({
    required this.cropId,
    required this.englishName,
    this.nativeName,
    required this.suitabilityScore,
    required this.bestSowingPeriod,
    this.expectedHarvestPeriod = 'Seasonal maturity',
    required this.expectedDuration,
    required this.waterRequirement,
    required this.soilSuitability,
    required this.estimatedCost,
    required this.potentialSellingPrice,
    required this.expectedYieldRange,
    required this.yieldSource,
    required this.recommendationReason,
    required this.tier,
    required this.season,
    this.iconEmoji = '🌾',
    this.seedCostPerAcre = 3500.0,
    this.fertilizerCostPerAcre = 4200.0,
    this.pesticideCostPerAcre = 2200.0,
    this.labourCostPerAcre = 5000.0,
    this.irrigationCostPerAcre = 2000.0,
    this.machineryCostPerAcre = 2500.0,
    this.otherCostPerAcre = 1000.0,
    this.expectedYieldQuintalsPerAcre = 16.0,
    this.mandiSellingPricePerQuintal = 2400.0,
    this.riskLevel = CropRiskLevel.low,
    this.riskExplanation = 'Stable regional crop with steady mandi demand.',
    this.isLegume = false,
    DateTime? lastUpdated,
    this.isVerifiedData = true,
  }) : lastUpdated = lastUpdated ?? const _DefaultDateTime();

  /// Total Cultivation Cost per Acre:
  /// Seeds + Fertilizer + Pesticides + Labour + Irrigation + Machinery + Other
  double get totalCostPerAcre =>
      seedCostPerAcre +
      fertilizerCostPerAcre +
      pesticideCostPerAcre +
      labourCostPerAcre +
      irrigationCostPerAcre +
      machineryCostPerAcre +
      otherCostPerAcre;

  /// Gross Revenue per Acre: Expected Yield × Mandi Selling Price
  double get grossRevenuePerAcre =>
      expectedYieldQuintalsPerAcre * mandiSellingPricePerQuintal;

  /// Net Profit per Acre: Gross Revenue - Total Cultivation Cost
  double get netProfitPerAcre => grossRevenuePerAcre - totalCostPerAcre;

  /// Break-even selling price per quintal
  double get breakEvenPricePerQuintal =>
      expectedYieldQuintalsPerAcre > 0
          ? totalCostPerAcre / expectedYieldQuintalsPerAcre
          : 0.0;

  // Farm-wide computations
  double totalCostForFarm(double acres) => totalCostPerAcre * (acres > 0 ? acres : 1.0);
  double grossRevenueForFarm(double acres) => grossRevenuePerAcre * (acres > 0 ? acres : 1.0);
  double netProfitForFarm(double acres) => netProfitPerAcre * (acres > 0 ? acres : 1.0);
  double expectedProductionForFarm(double acres) => expectedYieldQuintalsPerAcre * (acres > 0 ? acres : 1.0);

  // Profitability Scenarios
  /// Conservative Scenario: -15% yield, -10% market price
  double get conservativeProfitPerAcre {
    final consYield = expectedYieldQuintalsPerAcre * 0.85;
    final consPrice = mandiSellingPricePerQuintal * 0.90;
    return (consYield * consPrice) - totalCostPerAcre;
  }

  /// Optimistic Scenario: +15% yield, +10% market price
  double get optimisticProfitPerAcre {
    final optYield = expectedYieldQuintalsPerAcre * 1.15;
    final optPrice = mandiSellingPricePerQuintal * 1.10;
    return (optYield * optPrice) - totalCostPerAcre;
  }

  String get tierTitleEn {
    switch (tier) {
      case RecommendationTier.bestSuitable:
        return 'Best Suitable Crops';
      case RecommendationTier.alternative:
        return 'Alternative Crops';
      case RecommendationTier.seasonalOpportunity:
        return 'Seasonal Opportunities';
    }
  }

  String get tierTitleGu {
    switch (tier) {
      case RecommendationTier.bestSuitable:
        return 'સૌથી અનુકૂળ પાક';
      case RecommendationTier.alternative:
        return 'વૈકલ્પિક પાક';
      case RecommendationTier.seasonalOpportunity:
        return 'મોસમી તકો અને રોકડિયા પાક';
    }
  }

  String get tierTitleHi {
    switch (tier) {
      case RecommendationTier.bestSuitable:
        return 'सबसे उपयुक्त फसलें';
      case RecommendationTier.alternative:
        return 'वैकल्पिक फसलें';
      case RecommendationTier.seasonalOpportunity:
        return 'मौसमी अवसर और नकदी फसलें';
    }
  }

  String get tierTitlePa {
    switch (tier) {
      case RecommendationTier.bestSuitable:
        return 'ਸਭ ਤੋਂ ਢੁਕਵੀਆਂ ਫ਼ਸਲਾਂ';
      case RecommendationTier.alternative:
        return 'ਬਦਲਵੀਆਂ ਫ਼ਸਲਾਂ';
      case RecommendationTier.seasonalOpportunity:
        return 'ਮੌਸਮੀ ਮੌਕੇ ਅਤੇ ਨਕਦ ਫ਼ਸਲਾਂ';
    }
  }

  String getLocalizedTierTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return tierTitleGu;
      case 'hi':
        return tierTitleHi;
      case 'pa':
        return tierTitlePa;
      default:
        return tierTitleEn;
    }
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  bool isAfter(DateTime other) => false;
  @override
  bool isBefore(DateTime other) => true;
  @override
  bool isAtSameMomentAs(DateTime other) => false;
  @override
  int compareTo(DateTime other) => 0;
  @override
  DateTime add(Duration duration) => DateTime.now().add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.now().subtract(duration);
  @override
  Duration difference(DateTime other) => const Duration(days: 0);
  @override
  int get millisecondsSinceEpoch => 1730620800000;
  @override
  int get microsecondsSinceEpoch => 1730620800000000;
  @override
  String get timeZoneName => 'IST';
  @override
  Duration get timeZoneOffset => const Duration(hours: 5, minutes: 30);
  @override
  int get year => 2026;
  @override
  int get month => 11;
  @override
  int get day => 3;
  @override
  int get hour => 13;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => DateTime.tuesday;
  @override
  String toIso8601String() => '2026-11-03T13:00:00.000Z';
  @override
  String toString() => '2026-11-03 13:00:00.000';
  @override
  DateTime toLocal() => this;
  @override
  DateTime toUtc() => this;
  @override
  bool get isUtc => false;
}
