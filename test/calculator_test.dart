import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/services/agriculture_calculator_service.dart';
import 'package:khetchacha/localization/calculator_localization.dart';

void main() {
  group('AgricultureCalculatorService - Land Area Conversions', () {
    test('Converts Acre to other units accurately', () {
      final res = AgricultureCalculatorService.calculateLandArea(
        value: 1.0,
        fromUnit: 'Acre',
        bighaPerAcre: 1.6,
      );

      expect(res.acres, closeTo(1.0, 0.001));
      expect(res.hectares, closeTo(0.404686, 0.01));
      expect(res.guntha, closeTo(40.0, 0.001));
      expect(res.sqft, closeTo(43560.0, 1.0));
      expect(res.sqm, closeTo(4046.86, 1.0));
      expect(res.bigha, closeTo(1.6, 0.001));
    });

    test('Converts Hectare and regional Bigha factors correctly', () {
      // 1 Hectare = 2.47105 Acres
      final resHa = AgricultureCalculatorService.calculateLandArea(
        value: 1.0,
        fromUnit: 'Hectare',
        bighaPerAcre: 2.5, // Rajasthan/Gujarat Kaccha bigha
      );

      expect(resHa.acres, closeTo(2.471, 0.01));
      expect(resHa.bigha, closeTo(2.471 * 2.5, 0.05));
    });

    test('Computes area from Length x Width dimensions correctly', () {
      // 200 ft x 217.8 ft = 43,560 sq ft = exactly 1.0 Acre
      final resDim = AgricultureCalculatorService.calculateFromDimensions(
        length: 200,
        width: 217.8,
        isMeters: false,
        bighaPerAcre: 1.6,
      );

      expect(resDim.acres, closeTo(1.0, 0.01));
      expect(resDim.guntha, closeTo(40.0, 0.5));
    });

    test('Handles zero and negative area inputs safely without errors', () {
      final resZero = AgricultureCalculatorService.calculateLandArea(
        value: 0,
        fromUnit: 'Acre',
      );
      expect(resZero.acres, equals(0));

      final resNegative = AgricultureCalculatorService.calculateLandArea(
        value: -5.0,
        fromUnit: 'Acre',
      );
      expect(resNegative.acres, equals(0));
    });
  });

  group('AgricultureCalculatorService - Fertilizer Calculator', () {
    test('Calculates Urea bags and loose remainder correctly', () {
      // 2.5 Acres, 45 kg/Acre = 112.5 kg Urea total
      // Standard 50 kg bag: 2 full bags (100 kg) + 12.5 kg remainder
      final res = AgricultureCalculatorService.calculateFertilizer(
        area: 2.5,
        areaUnit: 'Acre',
        crop: 'Wheat',
        fertilizerType: 'Urea (46% N)',
        doseKgPerAcre: 45.0,
        bagWeightKg: 50.0,
      );

      expect(res.totalKgRequired, closeTo(112.5, 0.01));
      expect(res.fullBags, equals(2));
      expect(res.remainingKgInFinalBag, closeTo(12.5, 0.01));
      expect(res.totalBagsDecimal, closeTo(2.25, 0.01));
      expect(res.suppliedN, closeTo(112.5 * 0.46, 0.1)); // 46% N
    });

    test('Calculates DAP with both Nitrogen and Phosphorus fractions', () {
      final res = AgricultureCalculatorService.calculateFertilizer(
        area: 1.0,
        areaUnit: 'Acre',
        crop: 'Gram',
        fertilizerType: 'DAP (18% N, 46% P₂O₅)',
        doseKgPerAcre: 50.0,
        bagWeightKg: 50.0,
      );

      expect(res.totalKgRequired, equals(50.0));
      expect(res.fullBags, equals(1));
      expect(res.remainingKgInFinalBag, equals(0.0));
      expect(res.suppliedN, closeTo(9.0, 0.01)); // 18% of 50 = 9 kg N
      expect(res.suppliedP, closeTo(23.0, 0.01)); // 46% of 50 = 23 kg P₂O₅
    });

    test('Prevents division by zero when bag weight is zero or negative', () {
      final res = AgricultureCalculatorService.calculateFertilizer(
        area: 1.0,
        areaUnit: 'Acre',
        crop: 'Wheat',
        fertilizerType: 'Urea',
        doseKgPerAcre: 50.0,
        bagWeightKg: 0,
      );
      expect(res.totalKgRequired, equals(0));
    });
  });

  group('AgricultureCalculatorService - Seed Calculator', () {
    test('Calculates seed requirement with extra buffer percentage', () {
      // 3 Acres, 20 kg/Acre = 60 kg base. With 10% buffer = 66 kg
      final res = AgricultureCalculatorService.calculateSeed(
        area: 3.0,
        areaUnit: 'Acre',
        seedRatePerAcre: 20.0,
        extraBufferPercent: 10.0,
      );

      expect(res.baseKg, equals(60.0));
      expect(res.bufferKg, equals(6.0));
      expect(res.totalKg, equals(66.0));
      expect(res.kgPerAcre, closeTo(22.0, 0.01));
    });
  });

  group('AgricultureCalculatorService - Crop Yield Calculator', () {
    test('Calculates Quintals, Tons, and Maund (Mon) accurately', () {
      // 2 Acres @ 20 Quintals/Acre = 40 Quintals = 4.0 Metric Tons = 200 Mon
      final res = AgricultureCalculatorService.calculateCropYield(
        area: 2.0,
        areaUnit: 'Acre',
        yieldRate: 20.0,
        yieldUnit: 'Quintal',
      );

      expect(res.totalQuintals, equals(40.0));
      expect(res.totalTons, equals(4.0));
      expect(res.totalMon, equals(200.0));
    });
  });

  group('AgricultureCalculatorService - Farm Cost & Profit Calculator', () {
    test('Computes Net Profit, Revenue, and Break-Even Selling Price', () {
      // Expenses: 4000+8000+3000+10000+3000+5000+2000 = ₹35,000
      // Harvest: 25 Quintals @ ₹2,000/Qtl = ₹50,000 Revenue
      // Net Profit = ₹15,000. Break-even = ₹35,000 / 25 = ₹1,400/Qtl
      final res = AgricultureCalculatorService.calculateCostProfit(
        area: 2.0,
        areaUnit: 'Acre',
        seedCost: 4000,
        fertilizerCost: 8000,
        pesticideCost: 3000,
        labourCost: 10000,
        irrigationCost: 3000,
        machineryCost: 5000,
        otherExpenses: 2000,
        harvestQuantity: 25.0,
        sellingPricePerUnit: 2000.0,
      );

      expect(res.totalExpenses, equals(35000.0));
      expect(res.grossRevenue, equals(50000.0));
      expect(res.netProfit, equals(15000.0));
      expect(res.isProfit, isTrue);
      expect(res.breakEvenPrice, equals(1400.0));
      expect(res.costPerAcre, equals(17500.0));
      expect(res.profitPerAcre, equals(7500.0));
    });

    test('Detects net loss accurately when expenses exceed revenue', () {
      final res = AgricultureCalculatorService.calculateCostProfit(
        area: 1.0,
        areaUnit: 'Acre',
        seedCost: 10000,
        fertilizerCost: 10000,
        pesticideCost: 0,
        labourCost: 0,
        irrigationCost: 0,
        machineryCost: 0,
        otherExpenses: 0,
        harvestQuantity: 5.0,
        sellingPricePerUnit: 2000.0, // Revenue = 10,000, Expense = 20,000
      );

      expect(res.netProfit, equals(-10000.0));
      expect(res.isProfit, isFalse);
    });
  });

  group('AgricultureCalculatorService - Pesticide Dilution Calculator', () {
    test('Calculates chemical and spray solution for knapsack sprayers', () {
      // 16 L knapsack, 2.5 ml/L, 5 tanks
      // Per tank = 16 * 2.5 = 40 ml
      // Total product = 40 * 5 = 200 ml
      // Total solution = 16 * 5 = 80 Litres
      final res = AgricultureCalculatorService.calculatePesticide(
        tankCapacityLitres: 16.0,
        dosePerLitre: 2.5,
        doseUnit: 'ml',
        numberOfTanks: 5,
      );

      expect(res.productPerTank, equals(40.0));
      expect(res.totalProduct, equals(200.0));
      expect(res.totalSpraySolutionLitres, equals(80.0));
    });
  });

  group('CalculatorLocalization - Currency and Number Formatting', () {
    test('Formats Indian Rupee (₹) with Indian comma grouping', () {
      expect(CalculatorLocalization.formatINR(1500), equals('₹1,500'));
      expect(CalculatorLocalization.formatINR(150000), equals('₹1,50,000'));
      expect(CalculatorLocalization.formatINR(2500000), equals('₹25,00,000'));
      expect(CalculatorLocalization.formatINR(-4500), equals('-₹4,500'));
    });

    test('Provides Gujarati, Hindi and English translations', () {
      expect(
        CalculatorLocalization.t('fertilizer_calc_name', 'gu'),
        equals('ખાતર કેલ્ક્યુલેટર'),
      );
      expect(
        CalculatorLocalization.t('fertilizer_calc_name', 'hi'),
        equals('उर्वरक कैलकुलेटर'),
      );
      expect(
        CalculatorLocalization.t('fertilizer_calc_name', 'en'),
        equals('Fertilizer Calculator'),
      );
    });
  });
}
