import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/localization/app_localizations.dart';
import 'package:khetchacha/models/crop_recommendation.dart';
import 'package:khetchacha/models/farm_plot.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/models/soil_profile.dart';
import 'package:khetchacha/screens/calculators/smart_crop_profit_calculator_page.dart';
import 'package:khetchacha/screens/crops/annual_farm_planner_page.dart';
import 'package:khetchacha/screens/crops/seasonal_planning_page.dart';
import 'package:khetchacha/screens/crops/smart_crop_planning_hub_page.dart';
import 'package:khetchacha/screens/soil/smart_soil_profile_page.dart';
import 'package:khetchacha/services/annual_crop_planner_service.dart';
import 'package:khetchacha/services/crop_recommendation_service.dart';
import 'package:khetchacha/services/soil_analysis_service.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test farmer profile matching the Amreli, Gujarat scenario from Section 5
  final amreliProfile = FarmerProfile(
    fullName: 'Rameshbhai Patel',
    mobileNumber: '9876543210',
    email: 'ramesh@khetchacha.in',
    state: 'Gujarat',
    district: 'Amreli',
    taluka: 'Amreli',
    village: 'Vankia',
    farmingType: 'Organic / Conventional',
    landSize: '2.0',
    farmSize: '2.0',
    selectedState: 'Gujarat',
    selectedDistrict: 'Amreli',
    soilType: 'Black soil (Regur)',
    irrigationType: 'Borewell',
    waterAvailability: 'Medium',
    farmingSeason: 'Kharif',
    crops: ['Groundnut', 'Cotton'],
  );

  group('Section 1 & 3: Smart Soil Analysis & Profile Tests', () {
    test('Supports all 9 major Indian soil types with multilingual names', () {
      expect(SoilType.values.length, equals(9));
      for (final type in SoilType.values) {
        expect(type.displayNameEn, isNotEmpty);
        expect(type.displayNameGu, isNotEmpty);
        expect(type.displayNameHi, isNotEmpty);
        expect(type.displayNamePa, isNotEmpty);
      }
    });

    test('Infers Black soil and optimal fertility for Amreli, Gujarat benchmark', () {
      final soil = SoilProfile.estimatedForRegion(
        state: 'Gujarat',
        district: 'Amreli',
      );

      expect(soil.soilType, equals(SoilType.blackRegur));
      expect(soil.pH, inInclusiveRange(7.5, 8.2));
      expect(soil.potassiumKgPerHa, greaterThan(250.0));
      expect(soil.isLabVerified, isFalse);
      expect(soil.soilHealthScore, inInclusiveRange(60, 95));
      expect(soil.dataSource, contains('Amreli'));
    });

    test('ICAR Soil Nutrient Advisory provides tailored amendments for pH and OC', () {
      const acidicSoil = SoilProfile(
        pH: 5.8,
        nitrogenKgPerHa: 210.0,
        organicCarbonPercent: 0.35,
      );

      final advisoriesGu = SoilAnalysisService.instance.getNutrientAdvisory(
        profile: acidicSoil,
        langCode: 'gu',
      );
      final advisoriesEn = SoilAnalysisService.instance.getNutrientAdvisory(
        profile: acidicSoil,
        langCode: 'en',
      );

      expect(advisoriesEn.any((a) => a.contains('lime')), isTrue);
      expect(advisoriesEn.any((a) => a.contains('Nitrogen is low')), isTrue);
      expect(advisoriesGu.any((a) => a.contains('ચૂનો')), isTrue);
    });

    test('Farm plot models support multiple parcels and standardized Acre conversion', () {
      const p1 = FarmPlot(
        id: 'plot_1',
        name: 'North Canal Field',
        size: 2.0,
        unit: 'Acre',
      );
      const p2 = FarmPlot(
        id: 'plot_2',
        name: 'South Well Field',
        size: 5.0,
        unit: 'Bigha', // 5 * 0.4 = 2.0 Acres
      );

      expect(p1.sizeInAcres, equals(2.0));
      expect(p2.sizeInAcres, closeTo(2.0, 0.01));
    });
  });

  group('Section 4 & 5: AI Crop Recommendation Engine (Amreli, Gujarat Scenario)', () {
    test('Recommends Top 5 crops for Amreli Kharif season with Groundnut & Cotton high', () {
      final top5 = CropRecommendationService.instance.getTop5Recommendations(
        amreliProfile,
        targetSeason: 'Kharif',
      );

      expect(top5.length, equals(5));
      final names = top5.map((c) => c.englishName).toList();

      // In Amreli Kharif, Groundnut or Cotton or Soybean must be among Top 5
      expect(names.contains('Groundnut') || names.contains('Cotton'), isTrue);

      final groundnut = top5.firstWhere((c) => c.englishName == 'Groundnut');
      expect(groundnut.suitabilityScore, greaterThanOrEqualTo(85));
      expect(groundnut.isLegume, isTrue);
      expect(groundnut.tier, equals(RecommendationTier.bestSuitable));
      expect(groundnut.recommendationReason, contains('Amreli'));
    });

    test('Accurately computes itemized costs, yield, gross revenue, and net profit per acre', () {
      final top5 = CropRecommendationService.instance.getTop5Recommendations(
        amreliProfile,
        targetSeason: 'Kharif',
      );
      final groundnut = top5.firstWhere((c) => c.englishName == 'Groundnut');

      // Formula: Total Cost = Seeds + Fert + Pest + Labour + Irrig + Mach + Other
      final manualCost = groundnut.seedCostPerAcre +
          groundnut.fertilizerCostPerAcre +
          groundnut.pesticideCostPerAcre +
          groundnut.labourCostPerAcre +
          groundnut.irrigationCostPerAcre +
          groundnut.machineryCostPerAcre +
          groundnut.otherCostPerAcre;

      expect(groundnut.totalCostPerAcre, equals(manualCost));

      // Gross Revenue = Expected Yield * Mandi Price
      final manualRevenue = groundnut.expectedYieldQuintalsPerAcre *
          groundnut.mandiSellingPricePerQuintal;
      expect(groundnut.grossRevenuePerAcre, equals(manualRevenue));

      // Net Profit = Gross Revenue - Total Cost
      expect(
        groundnut.netProfitPerAcre,
        equals(manualRevenue - manualCost),
      );

      // Farm-wide calculations (2 Acres)
      expect(groundnut.totalCostForFarm(2.0), equals(manualCost * 2.0));
      expect(groundnut.grossRevenueForFarm(2.0), equals(manualRevenue * 2.0));
      expect(
        groundnut.netProfitForFarm(2.0),
        equals((manualRevenue - manualCost) * 2.0),
      );

      // Break-even price
      expect(
        groundnut.breakEvenPricePerQuintal,
        closeTo(manualCost / groundnut.expectedYieldQuintalsPerAcre, 0.1),
      );
    });

    test('Rabi season in Amreli recommends Wheat, Chickpea, and Cumin', () {
      final rabiRecs = CropRecommendationService.instance.getRecommendations(
        amreliProfile,
        targetSeason: 'Rabi',
      );

      final rabiNames = rabiRecs.map((c) => c.englishName).toList();
      expect(rabiNames.contains('Wheat'), isTrue);
      expect(rabiNames.contains('Gram (Chickpea)'), isTrue);
      expect(rabiNames.contains('Cumin (Jeera)'), isTrue);

      final chickpea = rabiRecs.firstWhere((c) => c.englishName == 'Gram (Chickpea)');
      expect(chickpea.isLegume, isTrue);
      expect(chickpea.suitabilityScore, greaterThanOrEqualTo(80));
    });
  });

  group('Section 7: Two-Crop Annual Farm Planner & Rotation Validation', () {
    test('Generates annual rotation pairing Kharif Groundnut with Rabi Wheat/Gram', () {
      final plans = AnnualCropPlannerService.instance.generateAnnualPlans(amreliProfile);

      expect(plans, isNotEmpty);
      final bestPlan = plans.first;

      // Top plan must be turnaround feasible
      expect(bestPlan.isTurnaroundFeasible, isTrue);
      expect(bestPlan.turnaroundDays, greaterThanOrEqualTo(15));
      expect(bestPlan.rotationCompatibilityScore, greaterThanOrEqualTo(80));

      // Annual financials
      expect(
        bestPlan.totalAnnualCostPerAcre,
        equals(bestPlan.firstCrop.totalCostPerAcre + bestPlan.secondCrop.totalCostPerAcre),
      );
      expect(
        bestPlan.totalAnnualGrossRevenuePerAcre,
        equals(bestPlan.firstCrop.grossRevenuePerAcre + bestPlan.secondCrop.grossRevenuePerAcre),
      );
      expect(
        bestPlan.totalAnnualNetProfitPerAcre,
        equals(bestPlan.firstCrop.netProfitPerAcre + bestPlan.secondCrop.netProfitPerAcre),
      );

      // Management schedules populated
      expect(bestPlan.fertilizerSchedule, isNotEmpty);
      expect(bestPlan.irrigationSchedule, isNotEmpty);
      expect(bestPlan.pestMonitoringAdvice, isNotEmpty);
    });

    test('Detects rotation incompatibility when long-duration Kharif clashes with Rabi', () {
      final plans = AnnualCropPlannerService.instance.generateAnnualPlans(amreliProfile);

      // Cotton + Wheat should be flagged as turnaround clash (cotton harvested in Jan)
      final cottonWheat = plans.firstWhere(
        (p) => p.firstCrop.englishName == 'Cotton' && p.secondCrop.englishName == 'Wheat',
      );

      expect(cottonWheat.isTurnaroundFeasible, isFalse);
      expect(cottonWheat.turnaroundDays, lessThan(0));
      expect(cottonWheat.compatibilityReason, contains('Time clash'));
    });
  });

  group('Section 10 & 11: Widget UI Tests for Planning Screens', () {
    testWidgets('SmartSoilProfilePage renders soil types, sliders, and ICAR advisory', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          SmartSoilProfilePage(profile: amreliProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farm Soil Profile & Health'), findsOneWidget);
      expect(find.text('Farm Soil Classification'), findsOneWidget);
      expect(find.text('Chemical Nutrient Profile'), findsOneWidget);
      expect(find.text('Soil pH (Reaction)'), findsOneWidget);
      expect(find.text('Available Nitrogen (N)'), findsOneWidget);
      expect(find.text('Save Farm Soil Profile'), findsOneWidget);
    });

    testWidgets('SmartCropProfitCalculatorPage calculates gross revenue and net profit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          SmartCropProfitCalculatorPage(profile: amreliProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Smart Crop Profit Calculator'), findsOneWidget);
      expect(find.text('Select Target Crop'), findsOneWidget);
      expect(find.text('Itemized Cultivation Costs (₹ / Acre)'), findsOneWidget);
      expect(find.text('Production & Mandi Selling Price'), findsOneWidget);
      expect(find.text('Sensitivity Scenarios (Risk Tolerance)'), findsOneWidget);
    });

    testWidgets('AnnualFarmPlannerPage renders two-crop cycle and timeline', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          AnnualFarmPlannerPage(profile: amreliProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Annual Two-Crop Farm Planner'), findsOneWidget);
      expect(find.text('RECOMMENDED TWO-CROP ANNUAL CYCLE'), findsOneWidget);
      expect(find.text('ANNUAL FARM FINANCIAL PROJECTION'), findsOneWidget);
      expect(find.text('Yearly Agronomic Management Calendar'), findsOneWidget);
    });

    testWidgets('SeasonalPlanningPage renders Kharif, Rabi, and Zaid tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          SeasonalPlanningPage(profile: amreliProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Three Seasonal Crop Planning'), findsOneWidget);
      expect(find.text('Kharif (Monsoon)'), findsOneWidget);
      expect(find.text('Rabi (Winter)'), findsOneWidget);
      expect(find.text('Zaid (Summer)'), findsOneWidget);
    });

    testWidgets('SmartCropPlanningHubPage integrates all 10 agricultural sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          SmartCropPlanningHubPage(profile: amreliProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Smart AI Crop & Farm Planning'), findsOneWidget);
      expect(find.text('Namaste Farmer!'), findsOneWidget);
      expect(find.text('TOP 5 AI CROP RECOMMENDATIONS'), findsOneWidget);
      expect(find.text('Three Seasonal Crop Planners'), findsOneWidget);
      expect(find.text('Smart Crop Profit & Cost Calculator'), findsOneWidget);
      expect(find.text('Two-Crop Annual Farm Planner'), findsOneWidget);
    });
  });
}
