/// Service providing pure, offline mathematical and agronomic calculation engines
/// for Indian agriculture:
/// - Fertilizer requirements & bag calculations
/// - Land area conversions with regional Bigha & Guntha support
/// - Seed requirements with germination buffer
/// - Crop yield estimations
/// - Farm cost, revenue & profit/loss with break-even analysis
/// - Irrigation water volume (m³ & Litres)
/// - Pesticide dilution & tank mixes
class AgricultureCalculatorService {
  AgricultureCalculatorService._();

  // -------------------------------------------------------------
  // 1. LAND CONVERSIONS
  // -------------------------------------------------------------

  /// Converts any input area into standard Acres
  static double toAcres(double area, String unit, {double bighaPerAcre = 1.6}) {
    if (area <= 0) return 0;
    switch (unit.toLowerCase()) {
      case 'acre':
      case 'એકર':
      case 'एकड़':
        return area;
      case 'hectare':
      case 'હેક્ટર':
      case 'हेक्टेयर':
        return area * 2.47105;
      case 'bigha':
      case 'વીઘા':
      case 'બીઘા':
      case 'बीघा':
        return bighaPerAcre > 0 ? area / bighaPerAcre : area;
      case 'guntha':
      case 'ગૂંઠા':
      case 'गुंठा':
        return area / 40.0;
      case 'sqm':
      case 'ચો.મીટર':
      case 'वर्ग मीटर':
        return area / 4046.86;
      case 'sqft':
      case 'ચો.ફૂટ':
      case 'वर्ग फुट':
        return area / 43560.0;
      default:
        return area;
    }
  }

  /// Converts standard Acres into target unit
  static double fromAcres(
    double acres,
    String targetUnit, {
    double bighaPerAcre = 1.6,
  }) {
    if (acres <= 0) return 0;
    switch (targetUnit.toLowerCase()) {
      case 'acre':
      case 'એકર':
      case 'एकड़':
        return acres;
      case 'hectare':
      case 'હેક્ટર':
      case 'हेक्टेयर':
        return acres / 2.47105;
      case 'bigha':
      case 'વીઘા':
      case 'બીઘા':
      case 'बीघा':
        return acres * bighaPerAcre;
      case 'guntha':
      case 'ગૂંઠા':
      case 'गुંઠા':
      case 'गुंठा':
        return acres * 40.0;
      case 'sqm':
      case 'ચો.મીટર':
      case 'वर्ग मीटर':
        return acres * 4046.86;
      case 'sqft':
      case 'ચો.ફૂટ':
      case 'वर्ग फुट':
        return acres * 43560.0;
      default:
        return acres;
    }
  }

  /// Land Area Conversion result with all units
  static LandAreaResult calculateLandArea({
    required double value,
    required String fromUnit,
    double bighaPerAcre = 1.6,
  }) {
    if (value <= 0) {
      return LandAreaResult.empty();
    }
    final acres = toAcres(value, fromUnit, bighaPerAcre: bighaPerAcre);
    final hectares = acres / 2.47105;
    final sqm = acres * 4046.86;
    final sqft = acres * 43560.0;
    final guntha = acres * 40.0;
    final bigha = acres * bighaPerAcre;

    return LandAreaResult(
      acres: acres,
      hectares: hectares,
      sqm: sqm,
      sqft: sqft,
      guntha: guntha,
      bigha: bigha,
      bighaFactor: bighaPerAcre,
    );
  }

  /// Calculates land area from Length and Width (in feet or meters)
  static LandAreaResult calculateFromDimensions({
    required double length,
    required double width,
    required bool isMeters,
    double bighaPerAcre = 1.6,
  }) {
    if (length <= 0 || width <= 0) {
      return LandAreaResult.empty();
    }
    final double sqm = isMeters
        ? (length * width)
        : (length * width * 0.092903);
    final acres = sqm / 4046.86;
    return calculateLandArea(
      value: acres,
      fromUnit: 'acre',
      bighaPerAcre: bighaPerAcre,
    );
  }

  // -------------------------------------------------------------
  // 2. FERTILIZER CALCULATOR
  // -------------------------------------------------------------

  static FertilizerResult calculateFertilizer({
    required double area,
    required String areaUnit,
    required String crop,
    required String fertilizerType,
    required double doseKgPerAcre,
    double? dosePerSelectedUnit,
    String? doseUnit, // 'per_acre', 'per_selected_unit', 'per_bigha'
    double bagWeightKg = 50.0,
    double bighaPerAcre = 1.6,
  }) {
    if (area <= 0 ||
        (doseKgPerAcre <= 0 &&
            (dosePerSelectedUnit == null || dosePerSelectedUnit <= 0)) ||
        bagWeightKg <= 0) {
      return FertilizerResult.empty();
    }

    final acres = toAcres(area, areaUnit, bighaPerAcre: bighaPerAcre);

    final double effectiveKgPerAcre;
    final double effectiveKgPerSelectedUnit;
    final double totalKg;

    final unitLower = areaUnit.toLowerCase();
    final isBigha =
        unitLower.contains('bigha') ||
        unitLower.contains('વીઘા') ||
        unitLower.contains('બીઘા') ||
        unitLower.contains('बीघा');

    if (dosePerSelectedUnit != null && dosePerSelectedUnit > 0) {
      effectiveKgPerSelectedUnit = dosePerSelectedUnit;
      totalKg = area * effectiveKgPerSelectedUnit;
      effectiveKgPerAcre = acres > 0
          ? totalKg / acres
          : effectiveKgPerSelectedUnit * bighaPerAcre;
    } else {
      effectiveKgPerAcre = doseKgPerAcre;
      totalKg = acres * effectiveKgPerAcre;
      if (isBigha) {
        effectiveKgPerSelectedUnit = bighaPerAcre > 0
            ? effectiveKgPerAcre / bighaPerAcre
            : effectiveKgPerAcre;
      } else if (acres > 0 && area > 0) {
        effectiveKgPerSelectedUnit = totalKg / area;
      } else {
        effectiveKgPerSelectedUnit = effectiveKgPerAcre;
      }
    }

    final double kgPerBigha = bighaPerAcre > 0
        ? effectiveKgPerAcre / bighaPerAcre
        : effectiveKgPerAcre;

    final fullBags = (totalKg ~/ bagWeightKg);
    final remainderKg = totalKg - (fullBags * bagWeightKg);
    final totalBagsDecimal = totalKg / bagWeightKg;

    // Nutrient estimation based on standard Indian commercial grades
    double nPercent = 0.0;
    double pPercent = 0.0;
    double kPercent = 0.0;

    final typeLower = fertilizerType.toLowerCase();
    if (typeLower.contains('urea') ||
        typeLower.contains('યુરિયા') ||
        typeLower.contains('यूरिया')) {
      nPercent = 46.0;
    } else if (typeLower.contains('dap') ||
        typeLower.contains('ડીએપી') ||
        typeLower.contains('डीएपी')) {
      nPercent = 18.0;
      pPercent = 46.0;
    } else if (typeLower.contains('mop') ||
        typeLower.contains('પોટાશ') ||
        typeLower.contains('पोटाश')) {
      kPercent = 60.0;
    } else if (typeLower.contains('10:26:26') ||
        typeLower.contains('10-26-26')) {
      nPercent = 10.0;
      pPercent = 26.0;
      kPercent = 26.0;
    } else if (typeLower.contains('12:32:16') ||
        typeLower.contains('12-32-16')) {
      nPercent = 12.0;
      pPercent = 32.0;
      kPercent = 16.0;
    } else if (typeLower.contains('ssp') || typeLower.contains('એસએસપી')) {
      pPercent = 16.0;
    }

    final suppliedN = (totalKg * nPercent) / 100.0;
    final suppliedP = (totalKg * pPercent) / 100.0;
    final suppliedK = (totalKg * kPercent) / 100.0;

    return FertilizerResult(
      acres: acres,
      inputArea: area,
      inputAreaUnit: areaUnit,
      totalKgRequired: totalKg,
      kgPerAcre: effectiveKgPerAcre,
      kgPerBigha: kgPerBigha,
      kgPerSelectedUnit: effectiveKgPerSelectedUnit,
      bagWeightKg: bagWeightKg,
      fullBags: fullBags,
      remainingKgInFinalBag: remainderKg > 0.001 ? remainderKg : 0.0,
      totalBagsDecimal: totalBagsDecimal,
      suppliedN: suppliedN,
      suppliedP: suppliedP,
      suppliedK: suppliedK,
    );
  }

  // -------------------------------------------------------------
  // 3. SEED CALCULATOR
  // -------------------------------------------------------------

  static SeedResult calculateSeed({
    required double area,
    required String areaUnit,
    required double seedRatePerAcre,
    double extraBufferPercent = 0.0,
    double bighaPerAcre = 1.6,
  }) {
    if (area <= 0 || seedRatePerAcre <= 0) {
      return SeedResult.empty();
    }
    final acres = toAcres(area, areaUnit, bighaPerAcre: bighaPerAcre);
    final baseKg = acres * seedRatePerAcre;
    final safeBuffer = extraBufferPercent.clamp(0.0, 50.0);
    final bufferKg = baseKg * (safeBuffer / 100.0);
    final totalKg = baseKg + bufferKg;

    return SeedResult(
      acres: acres,
      baseKg: baseKg,
      bufferPercent: safeBuffer,
      bufferKg: bufferKg,
      totalKg: totalKg,
      kgPerAcre: totalKg / (acres > 0 ? acres : 1.0),
    );
  }

  // -------------------------------------------------------------
  // 4. CROP YIELD CALCULATOR
  // -------------------------------------------------------------

  static CropYieldResult calculateCropYield({
    required double area,
    required String areaUnit,
    required double yieldRate,
    required String yieldUnit, // 'quintal', 'kg', 'ton', 'mon' (20kg)
    double bighaPerAcre = 1.6,
  }) {
    if (area <= 0 || yieldRate <= 0) {
      return CropYieldResult.empty();
    }
    final acres = toAcres(area, areaUnit, bighaPerAcre: bighaPerAcre);

    // Standardize rate to kg per acre
    double rateInKgPerAcre = yieldRate;
    final unitLower = yieldUnit.toLowerCase();
    if (unitLower.contains('quintal') ||
        unitLower.contains('ક્વિન્ટલ') ||
        unitLower.contains('क्विंटल')) {
      rateInKgPerAcre = yieldRate * 100.0;
    } else if (unitLower.contains('ton') ||
        unitLower.contains('ટન') ||
        unitLower.contains('टन')) {
      rateInKgPerAcre = yieldRate * 1000.0;
    } else if (unitLower.contains('mon') ||
        unitLower.contains('મણ') ||
        unitLower.contains('मन')) {
      rateInKgPerAcre = yieldRate * 20.0; // 1 Maund/Mon in Gujarat = 20 kg
    }

    final totalKg = acres * rateInKgPerAcre;
    final totalQuintals = totalKg / 100.0;
    final totalTons = totalKg / 1000.0;
    final totalMon = totalKg / 20.0;

    final yieldPerAcreQuintal = (rateInKgPerAcre / 100.0);
    final yieldPerHectareQuintal = yieldPerAcreQuintal * 2.47105;

    return CropYieldResult(
      acres: acres,
      totalKg: totalKg,
      totalQuintals: totalQuintals,
      totalTons: totalTons,
      totalMon: totalMon,
      yieldPerAcreQuintal: yieldPerAcreQuintal,
      yieldPerHectareQuintal: yieldPerHectareQuintal,
    );
  }

  // -------------------------------------------------------------
  // 5. FARMING COST & PROFIT CALCULATOR
  // -------------------------------------------------------------

  static FarmCostProfitResult calculateCostProfit({
    required double area,
    required String areaUnit,
    required double seedCost,
    required double fertilizerCost,
    required double pesticideCost,
    required double labourCost,
    required double irrigationCost,
    required double machineryCost,
    required double otherExpenses,
    required double harvestQuantity, // in quintals, maunds, etc.
    required double sellingPricePerUnit, // price per quintal or per maund
    String sellingPriceUnit = 'quintal', // 'quintal' or 'maund' (or 'mon')
    String harvestUnit = 'quintal', // 'quintal' or 'maund' (or 'mon')
    double bighaPerAcre = 1.6,
  }) {
    final acres = toAcres(area, areaUnit, bighaPerAcre: bighaPerAcre);
    final totalExpenses =
        seedCost +
        fertilizerCost +
        pesticideCost +
        labourCost +
        irrigationCost +
        machineryCost +
        otherExpenses;

    final unitLower = sellingPriceUnit.toLowerCase();
    final isPriceMaund =
        unitLower.contains('maund') ||
        unitLower.contains('mon') ||
        unitLower.contains('મણ') ||
        unitLower.contains('मन');

    final harvestUnitLower = harvestUnit.toLowerCase();
    final isHarvestMaund =
        harvestUnitLower.contains('maund') ||
        harvestUnitLower.contains('mon') ||
        harvestUnitLower.contains('મણ') ||
        harvestUnitLower.contains('मन');

    final double harvestInQuintals;
    final double harvestInMaunds;

    if (isHarvestMaund) {
      harvestInMaunds = harvestQuantity;
      harvestInQuintals = harvestQuantity / 5.0; // 1 Qtl = 5 Maunds
    } else {
      harvestInQuintals = harvestQuantity;
      harvestInMaunds = harvestQuantity * 5.0;
    }

    final double grossRevenue;
    final double breakEvenPrice;

    if (isPriceMaund) {
      grossRevenue = harvestInMaunds * sellingPricePerUnit;
      breakEvenPrice = harvestInMaunds > 0
          ? totalExpenses / harvestInMaunds
          : 0.0;
    } else {
      grossRevenue = harvestInQuintals * sellingPricePerUnit;
      breakEvenPrice = harvestInQuintals > 0
          ? totalExpenses / harvestInQuintals
          : 0.0;
    }

    final netProfit = grossRevenue - totalExpenses;

    final costPerAcre = acres > 0 ? totalExpenses / acres : 0.0;
    final revenuePerAcre = acres > 0 ? grossRevenue / acres : 0.0;
    final profitPerAcre = acres > 0 ? netProfit / acres : 0.0;

    final roiPercent = totalExpenses > 0
        ? (netProfit / totalExpenses) * 100.0
        : 0.0;

    return FarmCostProfitResult(
      acres: acres,
      totalExpenses: totalExpenses,
      grossRevenue: grossRevenue,
      netProfit: netProfit,
      costPerAcre: costPerAcre,
      revenuePerAcre: revenuePerAcre,
      profitPerAcre: profitPerAcre,
      breakEvenPrice: breakEvenPrice,
      roiPercent: roiPercent,
      isProfit: netProfit >= 0,
      sellingPriceUnit: isPriceMaund ? 'maund' : 'quintal',
      harvestUnit: isHarvestMaund ? 'maund' : 'quintal',
      harvestQuantity: harvestQuantity,
      harvestInQuintals: harvestInQuintals,
      harvestInMaunds: harvestInMaunds,
      sellingPricePerUnit: sellingPricePerUnit,
    );
  }

  // -------------------------------------------------------------
  // 6. IRRIGATION WATER CALCULATOR
  // Formula: Water volume (m³) = Area (m²) × Irrigation depth (mm) ÷ 1000
  // Litres = m³ × 1000 = Area (m²) × Irrigation depth (mm)
  // -------------------------------------------------------------

  static IrrigationResult calculateIrrigation({
    required double area,
    required String areaUnit,
    required double depthMm,
    double efficiencyPercent = 80.0,
    double pumpDischargeLph = 30000.0, // standard 5HP tubewell ~ 30,000 L/hr
    double bighaPerAcre = 1.6,
  }) {
    if (area <= 0 || depthMm <= 0) {
      return IrrigationResult.empty();
    }
    final acres = toAcres(area, areaUnit, bighaPerAcre: bighaPerAcre);
    final areaSqm = acres * 4046.86;

    final theoreticalCubicMeters = (areaSqm * depthMm) / 1000.0;
    final theoreticalLitres = theoreticalCubicMeters * 1000.0;

    final safeEfficiency = efficiencyPercent.clamp(30.0, 100.0);
    final adjustedCubicMeters =
        theoreticalCubicMeters / (safeEfficiency / 100.0);
    final adjustedLitres = theoreticalLitres / (safeEfficiency / 100.0);

    final pumpHours = pumpDischargeLph > 0
        ? adjustedLitres / pumpDischargeLph
        : 0.0;

    return IrrigationResult(
      acres: acres,
      areaSqm: areaSqm,
      depthMm: depthMm,
      efficiencyPercent: safeEfficiency,
      theoreticalCubicMeters: theoreticalCubicMeters,
      theoreticalLitres: theoreticalLitres,
      adjustedCubicMeters: adjustedCubicMeters,
      adjustedLitres: adjustedLitres,
      estimatedPumpHours: pumpHours,
    );
  }

  // -------------------------------------------------------------
  // 7. PESTICIDE DILUTION CALCULATOR
  // -------------------------------------------------------------

  static PesticideResult calculatePesticide({
    required double tankCapacityLitres,
    required double dosePerLitre,
    required String doseUnit, // 'ml', 'gram'
    required int numberOfTanks,
  }) {
    if (tankCapacityLitres <= 0 || dosePerLitre <= 0 || numberOfTanks <= 0) {
      return PesticideResult.empty();
    }

    final productPerTank = tankCapacityLitres * dosePerLitre;
    final totalProduct = productPerTank * numberOfTanks;
    final totalSpraySolutionLitres = tankCapacityLitres * numberOfTanks;

    return PesticideResult(
      tankCapacityLitres: tankCapacityLitres,
      dosePerLitre: dosePerLitre,
      doseUnit: doseUnit,
      numberOfTanks: numberOfTanks,
      productPerTank: productPerTank,
      totalProduct: totalProduct,
      totalSpraySolutionLitres: totalSpraySolutionLitres,
    );
  }
}

// -------------------------------------------------------------
// RESULT DATA CLASSES
// -------------------------------------------------------------

class LandAreaResult {
  final double acres;
  final double hectares;
  final double sqm;
  final double sqft;
  final double guntha;
  final double bigha;
  final double bighaFactor;

  const LandAreaResult({
    required this.acres,
    required this.hectares,
    required this.sqm,
    required this.sqft,
    required this.guntha,
    required this.bigha,
    required this.bighaFactor,
  });

  factory LandAreaResult.empty() => const LandAreaResult(
    acres: 0,
    hectares: 0,
    sqm: 0,
    sqft: 0,
    guntha: 0,
    bigha: 0,
    bighaFactor: 1.6,
  );
}

class FertilizerResult {
  final double acres;
  final double totalKgRequired;
  final double kgPerAcre;
  final double bagWeightKg;
  final int fullBags;
  final double remainingKgInFinalBag;
  final double totalBagsDecimal;
  final double suppliedN;
  final double suppliedP;
  final double suppliedK;
  final double inputArea;
  final String inputAreaUnit;
  final double kgPerBigha;
  final double kgPerSelectedUnit;

  const FertilizerResult({
    required this.acres,
    required this.totalKgRequired,
    required this.kgPerAcre,
    required this.bagWeightKg,
    required this.fullBags,
    required this.remainingKgInFinalBag,
    required this.totalBagsDecimal,
    required this.suppliedN,
    required this.suppliedP,
    required this.suppliedK,
    this.inputArea = 0.0,
    this.inputAreaUnit = 'Acre',
    this.kgPerBigha = 0.0,
    this.kgPerSelectedUnit = 0.0,
  });

  factory FertilizerResult.empty() => const FertilizerResult(
    acres: 0,
    totalKgRequired: 0,
    kgPerAcre: 0,
    bagWeightKg: 50,
    fullBags: 0,
    remainingKgInFinalBag: 0,
    totalBagsDecimal: 0,
    suppliedN: 0,
    suppliedP: 0,
    suppliedK: 0,
    inputArea: 0,
    inputAreaUnit: 'Acre',
    kgPerBigha: 0,
    kgPerSelectedUnit: 0,
  );
}

class SeedResult {
  final double acres;
  final double baseKg;
  final double bufferPercent;
  final double bufferKg;
  final double totalKg;
  final double kgPerAcre;

  const SeedResult({
    required this.acres,
    required this.baseKg,
    required this.bufferPercent,
    required this.bufferKg,
    required this.totalKg,
    required this.kgPerAcre,
  });

  factory SeedResult.empty() => const SeedResult(
    acres: 0,
    baseKg: 0,
    bufferPercent: 0,
    bufferKg: 0,
    totalKg: 0,
    kgPerAcre: 0,
  );
}

class CropYieldResult {
  final double acres;
  final double totalKg;
  final double totalQuintals;
  final double totalTons;
  final double totalMon;
  final double yieldPerAcreQuintal;
  final double yieldPerHectareQuintal;

  const CropYieldResult({
    required this.acres,
    required this.totalKg,
    required this.totalQuintals,
    required this.totalTons,
    required this.totalMon,
    required this.yieldPerAcreQuintal,
    required this.yieldPerHectareQuintal,
  });

  factory CropYieldResult.empty() => const CropYieldResult(
    acres: 0,
    totalKg: 0,
    totalQuintals: 0,
    totalTons: 0,
    totalMon: 0,
    yieldPerAcreQuintal: 0,
    yieldPerHectareQuintal: 0,
  );
}

class FarmCostProfitResult {
  final double acres;
  final double totalExpenses;
  final double grossRevenue;
  final double netProfit;
  final double costPerAcre;
  final double revenuePerAcre;
  final double profitPerAcre;
  final double breakEvenPrice;
  final double roiPercent;
  final bool isProfit;
  final String sellingPriceUnit;
  final String harvestUnit;
  final double harvestQuantity;
  final double harvestInQuintals;
  final double harvestInMaunds;
  final double sellingPricePerUnit;

  const FarmCostProfitResult({
    required this.acres,
    required this.totalExpenses,
    required this.grossRevenue,
    required this.netProfit,
    required this.costPerAcre,
    required this.revenuePerAcre,
    required this.profitPerAcre,
    required this.breakEvenPrice,
    required this.roiPercent,
    required this.isProfit,
    this.sellingPriceUnit = 'quintal',
    this.harvestUnit = 'quintal',
    this.harvestQuantity = 0.0,
    this.harvestInQuintals = 0.0,
    this.harvestInMaunds = 0.0,
    this.sellingPricePerUnit = 0.0,
  });

  factory FarmCostProfitResult.empty() => const FarmCostProfitResult(
    acres: 0,
    totalExpenses: 0,
    grossRevenue: 0,
    netProfit: 0,
    costPerAcre: 0,
    revenuePerAcre: 0,
    profitPerAcre: 0,
    breakEvenPrice: 0,
    roiPercent: 0,
    isProfit: true,
    sellingPriceUnit: 'quintal',
    harvestUnit: 'quintal',
    harvestQuantity: 0.0,
    harvestInQuintals: 0.0,
    harvestInMaunds: 0.0,
    sellingPricePerUnit: 0.0,
  );
}

class IrrigationResult {
  final double acres;
  final double areaSqm;
  final double depthMm;
  final double efficiencyPercent;
  final double theoreticalCubicMeters;
  final double theoreticalLitres;
  final double adjustedCubicMeters;
  final double adjustedLitres;
  final double estimatedPumpHours;

  const IrrigationResult({
    required this.acres,
    required this.areaSqm,
    required this.depthMm,
    required this.efficiencyPercent,
    required this.theoreticalCubicMeters,
    required this.theoreticalLitres,
    required this.adjustedCubicMeters,
    required this.adjustedLitres,
    required this.estimatedPumpHours,
  });

  factory IrrigationResult.empty() => const IrrigationResult(
    acres: 0,
    areaSqm: 0,
    depthMm: 0,
    efficiencyPercent: 80,
    theoreticalCubicMeters: 0,
    theoreticalLitres: 0,
    adjustedCubicMeters: 0,
    adjustedLitres: 0,
    estimatedPumpHours: 0,
  );
}

class PesticideResult {
  final double tankCapacityLitres;
  final double dosePerLitre;
  final String doseUnit;
  final int numberOfTanks;
  final double productPerTank;
  final double totalProduct;
  final double totalSpraySolutionLitres;

  const PesticideResult({
    required this.tankCapacityLitres,
    required this.dosePerLitre,
    required this.doseUnit,
    required this.numberOfTanks,
    required this.productPerTank,
    required this.totalProduct,
    required this.totalSpraySolutionLitres,
  });

  factory PesticideResult.empty() => const PesticideResult(
    tankCapacityLitres: 0,
    dosePerLitre: 0,
    doseUnit: 'ml',
    numberOfTanks: 0,
    productPerTank: 0,
    totalProduct: 0,
    totalSpraySolutionLitres: 0,
  );
}
