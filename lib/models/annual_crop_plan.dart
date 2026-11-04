import 'crop_recommendation.dart';

/// Comprehensive Two-Crop Annual Farm Rotation Plan for an agricultural year.
/// Models the standard Indian farming cycle: Kharif (Monsoon) followed by Rabi (Winter),
/// with optional Zaid (Summer), evaluating rotational compatibility, nutrient replenishment,
/// turnaround feasibility, and annual net farm income.
class AnnualCropPlan {
  final String id;
  final String plotId;
  final String plotName;
  final String agriculturalYear;
  final CropRecommendation firstCrop; // Kharif crop
  final CropRecommendation secondCrop; // Rabi crop
  final CropRecommendation? thirdCrop; // Optional Zaid crop

  // Rotational Agronomy Evaluation
  final int rotationCompatibilityScore; // 0 - 100
  final bool isCompatible;
  final bool isLegumeCerealRotation;
  final String compatibilityReason;
  final int turnaroundDays; // Days between Kharif harvest and Rabi sowing
  final bool isTurnaroundFeasible;

  // Yearly Agronomic Management Schedule
  final String kharifLandPrepPeriod;
  final String kharifSowingDate;
  final String kharifHarvestDate;
  final String rabiLandPrepPeriod;
  final String rabiSowingDate;
  final String rabiHarvestDate;

  final List<String> fertilizerSchedule;
  final List<String> irrigationSchedule;
  final List<String> pestMonitoringAdvice;

  const AnnualCropPlan({
    required this.id,
    required this.plotId,
    required this.plotName,
    required this.agriculturalYear,
    required this.firstCrop,
    required this.secondCrop,
    this.thirdCrop,
    required this.rotationCompatibilityScore,
    required this.isCompatible,
    required this.isLegumeCerealRotation,
    required this.compatibilityReason,
    required this.turnaroundDays,
    required this.isTurnaroundFeasible,
    required this.kharifLandPrepPeriod,
    required this.kharifSowingDate,
    required this.kharifHarvestDate,
    required this.rabiLandPrepPeriod,
    required this.rabiSowingDate,
    required this.rabiHarvestDate,
    required this.fertilizerSchedule,
    required this.irrigationSchedule,
    required this.pestMonitoringAdvice,
  });

  /// Total Annual Cultivation Investment per Acre
  double get totalAnnualCostPerAcre {
    double total = firstCrop.totalCostPerAcre + secondCrop.totalCostPerAcre;
    if (thirdCrop != null) {
      total += thirdCrop!.totalCostPerAcre;
    }
    return total;
  }

  /// Total Annual Gross Produce Value per Acre
  double get totalAnnualGrossRevenuePerAcre {
    double total =
        firstCrop.grossRevenuePerAcre + secondCrop.grossRevenuePerAcre;
    if (thirdCrop != null) {
      total += thirdCrop!.grossRevenuePerAcre;
    }
    return total;
  }

  /// Total Annual Net Farm Profit per Acre
  double get totalAnnualNetProfitPerAcre =>
      totalAnnualGrossRevenuePerAcre - totalAnnualCostPerAcre;

  /// Annual financial projections for the entire farm/plot
  double totalAnnualCostForFarm(double acres) =>
      totalAnnualCostPerAcre * (acres > 0 ? acres : 1.0);
  double totalAnnualGrossRevenueForFarm(double acres) =>
      totalAnnualGrossRevenuePerAcre * (acres > 0 ? acres : 1.0);
  double totalAnnualNetProfitForFarm(double acres) =>
      totalAnnualNetProfitPerAcre * (acres > 0 ? acres : 1.0);
}
