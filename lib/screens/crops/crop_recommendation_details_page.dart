import 'package:flutter/material.dart';

import '../../models/crop_recommendation.dart';
import '../../models/farmer_profile.dart';
import '../../services/farm_profile_service.dart';
import '../calculators/smart_crop_profit_calculator_page.dart';
import '../mandi/mandi_comparison_page.dart';

/// Detailed view of an ICAR-recommended crop for the farmer's specific land.
class CropRecommendationDetailsPage extends StatelessWidget {
  final CropRecommendation recommendation;
  final FarmerProfile profile;

  const CropRecommendationDetailsPage({
    super.key,
    required this.recommendation,
    required this.profile,
  });

  Future<void> _saveCropToProfile(BuildContext context) async {
    final existingCrops = List<String>.from(profile.effectiveProducts);
    if (!existingCrops.contains(recommendation.englishName)) {
      existingCrops.add(recommendation.englishName);
    }

    final updated = profile.copyWith(
      crops: existingCrops,
      selectedProducts: existingCrops,
    );

    await FarmProfileService.instance.saveFarmProfile(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${recommendation.englishName} added to your active farm crops!',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = recommendation;
    final isSaved = profile.effectiveProducts.contains(rec.englishName);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${rec.englishName} Recommendation',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Crop already saved' : 'Save crop',
            icon: Icon(
              isSaved
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_border_rounded,
              color: const Color(0xFFFFD54F),
            ),
            onPressed: () => _saveCropToProfile(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Crop Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            rec.iconEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rec.englishName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD54F),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${rec.suitabilityScore}% Match',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${rec.season} Season • ${rec.tierTitleEn}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE8F5E9),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Sowing Window: ${rec.bestSowingPeriod}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recommendation Rationale Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why this crop is recommended for your farm:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.recommendationReason,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Key Agronomic Parameters Grid
              const Text(
                'Agronomic & Economic Estimates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),

              _buildDetailTile(
                icon: Icons.access_time_rounded,
                title: 'Crop Maturity Duration',
                value: rec.expectedDuration,
                color: const Color(0xFF0288D1),
              ),
              _buildDetailTile(
                icon: Icons.water_drop_rounded,
                title: 'Water Requirement',
                value: rec.waterRequirement,
                color: const Color(0xFF0097A7),
              ),
              _buildDetailTile(
                icon: Icons.grass_rounded,
                title: 'Soil Suitability',
                value: rec.soilSuitability,
                color: const Color(0xFF689F38),
              ),
              _buildDetailTile(
                icon: Icons.attach_money_rounded,
                title: 'Estimated Cultivation Cost',
                value: rec.estimatedCost,
                color: const Color(0xFFF57C00),
              ),
              _buildDetailTile(
                icon: Icons.sell_rounded,
                title: 'Potential Mandi Selling Price',
                value: rec.potentialSellingPrice,
                color: const Color(0xFF388E3C),
              ),
              _buildDetailTile(
                icon: Icons.inventory_2_rounded,
                title: 'Expected Yield Range',
                value: rec.expectedYieldRange,
                subtitle: 'Source: ${rec.yieldSource}',
                color: const Color(0xFF7B1FA2),
              ),

              const SizedBox(height: 16),

              // Itemized Economics & Estimated Net Profit Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Cultivation Economics',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Net: ₹${(rec.netProfitPerAcre / 1000).toStringAsFixed(1)}k/Ac',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEcoItem(
                          'Seeds',
                          '₹${rec.seedCostPerAcre.toStringAsFixed(0)}',
                        ),
                        _buildEcoItem(
                          'Fertilizer',
                          '₹${rec.fertilizerCostPerAcre.toStringAsFixed(0)}',
                        ),
                        _buildEcoItem(
                          'Pesticides',
                          '₹${rec.pesticideCostPerAcre.toStringAsFixed(0)}',
                        ),
                        _buildEcoItem(
                          'Labour',
                          '₹${rec.labourCostPerAcre.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEcoItem(
                          'Irrigation',
                          '₹${rec.irrigationCostPerAcre.toStringAsFixed(0)}',
                        ),
                        _buildEcoItem(
                          'Machinery',
                          '₹${rec.machineryCostPerAcre.toStringAsFixed(0)}',
                        ),
                        _buildEcoItem(
                          'Total Cost',
                          '₹${rec.totalCostPerAcre.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        _buildEcoItem(
                          'Gross Rev',
                          '₹${rec.grossRevenuePerAcre.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF1B5E20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SmartCropProfitCalculatorPage(
                              profile: profile,
                              initialCrop: rec,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calculate_rounded, size: 18),
                      label: const Text(
                        'Customize Farm Economics in Profit Calculator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MandiComparisonPage(
                              profile: profile,
                              initialCommodity: rec.englishName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.compare_arrows_rounded,
                        color: Color(0xFF1B5E20),
                      ),
                      label: const Text(
                        'Compare Mandis',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _saveCropToProfile(context),
                      icon: Icon(
                        isSaved
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                      ),
                      label: Text(
                        isSaved ? 'Saved in My Crops' : 'Save to My Crops',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF1B5E20) : const Color(0xFF212121),
          ),
        ),
      ],
    );
  }
}
