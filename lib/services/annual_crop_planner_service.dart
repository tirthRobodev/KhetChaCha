import '../models/annual_crop_plan.dart';
import '../models/farm_plot.dart';
import '../models/farmer_profile.dart';
import '../models/soil_profile.dart';
import 'crop_recommendation_service.dart';

/// Service generating and validating Two-Crop Annual Farm Rotation Plans
/// according to ICAR crop rotation and agronomic compatibility principles.
class AnnualCropPlannerService {
  AnnualCropPlannerService._internal();
  static final AnnualCropPlannerService instance =
      AnnualCropPlannerService._internal();

  /// Generates recommended annual rotation plans tailored to the farmer's plot and soil
  List<AnnualCropPlan> generateAnnualPlans(
    FarmerProfile profile, {
    FarmPlot? plot,
    SoilProfile? soilProfile,
  }) {
    final kharifCrops = CropRecommendationService.instance.getRecommendations(
      profile,
      soilProfile: soilProfile ?? plot?.soilProfile,
      targetSeason: 'Kharif',
    );

    final rabiCrops = CropRecommendationService.instance.getRecommendations(
      profile,
      soilProfile: soilProfile ?? plot?.soilProfile,
      targetSeason: 'Rabi',
    );

    final plans = <AnnualCropPlan>[];
    int planCounter = 1;

    // Evaluate combinations of top Kharif and Rabi crops
    for (final kharif in kharifCrops.take(4)) {
      for (final rabi in rabiCrops.take(4)) {
        // Skip obvious incompatible combinations
        // e.g. Long duration cotton (harvested in Jan) cannot follow standard early Nov wheat
        final isCotton = kharif.englishName.toLowerCase().contains('cotton');
        final isWheat = rabi.englishName.toLowerCase().contains('wheat');

        int turnaroundDays = 20; // Default safe buffer
        bool turnaroundFeasible = true;

        if (isCotton && isWheat) {
          turnaroundDays =
              -30; // Cotton still standing in fields during wheat sowing window
          turnaroundFeasible = false;
        } else if (kharif.englishName.toLowerCase().contains('soybean') ||
            kharif.englishName.toLowerCase().contains('groundnut') ||
            kharif.englishName.toLowerCase().contains('pearl millet')) {
          turnaroundDays = 25; // Safe October harvest, November Rabi sowing
          turnaroundFeasible = true;
        }

        final isLegumeCereal =
            (kharif.isLegume && !rabi.isLegume) ||
            (!kharif.isLegume && rabi.isLegume);

        // Compute compatibility score
        int score = ((kharif.suitabilityScore + rabi.suitabilityScore) / 2)
            .round();

        String reason;
        if (!turnaroundFeasible) {
          score -= 30;
          reason =
              'Time clash: Long-duration ${kharif.englishName} delays field clearing past the optimal ${rabi.englishName} sowing date.';
        } else if (isLegumeCereal) {
          score += 10; // Excellent nitrogen restoration
          reason =
              'Optimal Rotation: ${kharif.isLegume ? kharif.englishName : rabi.englishName} fixes atmospheric nitrogen in the soil, boosting root growth and yield for subsequent ${kharif.isLegume ? rabi.englishName : kharif.englishName}.';
        } else if (kharif.isLegume && rabi.isLegume) {
          score += 4;
          reason = 'Double Pulse Cycle: High soil health and nitrogen accumulation with minimal chemical fertilizer requirement.';
        } else {
          score -= 5;
          reason = 'Standard Cereal/Cash Rotation: Requires supplementary organic compost or green manuring to prevent soil nutrient depletion.';
        }

        final finalScore = score.clamp(30, 96);

        plans.add(
          AnnualCropPlan(
            id: 'plan_$planCounter',
            plotId: plot?.id ?? 'plot_1',
            plotName: plot?.name ?? 'Main Farm Plot',
            agriculturalYear:
                '${DateTime.now().year} - ${DateTime.now().year + 1}',
            firstCrop: kharif,
            secondCrop: rabi,
            thirdCrop: null,
            rotationCompatibilityScore: finalScore,
            isCompatible: turnaroundFeasible && finalScore >= 70,
            isLegumeCerealRotation: isLegumeCereal,
            compatibilityReason: reason,
            turnaroundDays: turnaroundDays,
            isTurnaroundFeasible: turnaroundFeasible,
            kharifLandPrepPeriod:
                'May 20 - June 10 (Deep summer ploughing, 4 tons FYM)',
            kharifSowingDate: kharif.bestSowingPeriod,
            kharifHarvestDate: kharif.expectedHarvestPeriod,
            rabiLandPrepPeriod: turnaroundFeasible
                ? 'October 25 - November 05 (Rotavator seedbed preparation)'
                : 'Field occupied by standing crop',
            rabiSowingDate: rabi.bestSowingPeriod,
            rabiHarvestDate: rabi.expectedHarvestPeriod,
            fertilizerSchedule: [
              'Kharif Basal: 50 kg DAP + 25 kg MOP + 10 kg Zinc Sulphate per acre',
              'Kharif Top-dress: Split Urea application at 30 and 45 days after sowing',
              'Rabi Basal: Apply reduced Nitrogen due to previous crop residue credit',
              'Rabi Critical Stages: Secondary spray of 19:19:19 or NPK micronutrients',
            ],
            irrigationSchedule: [
              'Kharif: Rainfed supported by 2 supplementary life-saving irrigations during dry spells',
              'Rabi: 4-5 timed irrigations (CRI stage, tillering, flowering, and grain filling)',
            ],
            pestMonitoringAdvice: [
              'Install yellow sticky traps (10/acre) and pheromone traps at 25 DAS',
              'Scout weekly for sucking pests, leaf spot, and pod borers',
              'Spray neem oil (10,000 ppm @ 3 ml/L) as preventive eco-friendly measure',
            ],
          ),
        );
        planCounter++;
      }
    }

    // Sort descending by rotation compatibility score and annual net profit
    plans.sort((a, b) {
      if (a.isTurnaroundFeasible != b.isTurnaroundFeasible) {
        return a.isTurnaroundFeasible ? -1 : 1;
      }
      final comp = b.rotationCompatibilityScore.compareTo(
        a.rotationCompatibilityScore,
      );
      if (comp != 0) return comp;
      return b.totalAnnualNetProfitPerAcre.compareTo(
        a.totalAnnualNetProfitPerAcre,
      );
    });

    return plans;
  }
}
