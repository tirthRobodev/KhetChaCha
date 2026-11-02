import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Soil Health & Organic Fertilizer Guide.
class SoilHealthPage extends StatelessWidget {
  final FarmerProfile profile;

  const SoilHealthPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.soilAndFertilizerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF558B2F), Color(0xFF33691E)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Soil Health Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regional soil guidelines for ${profile.effectiveDistrict}, ${profile.effectiveState}',
                  style: const TextStyle(
                    color: Color(0xFFDCEDC8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildTipCard(
            title: 'Organic Carbon Enhancement',
            description: 'Apply 5-8 tonnes of well-rotted FYM (Farmyard Manure) or Vermicompost per acre before pre-sowing tillage to boost soil microbial activity.',
            icon: Icons.eco_rounded,
          ),
          _buildTipCard(
            title: 'Soil Acidity & Alkalinity (pH Balance)',
            description: 'For acidic soils (common in high-rainfall regions like Kerala), apply 200-250 kg/acre agricultural lime or dolomite. For saline/alkaline soils, add gypsum.',
            icon: Icons.science_rounded,
          ),
          _buildTipCard(
            title: 'Micronutrient Balance (Zinc, Boron & Sulphur)',
            description: 'Zinc deficiency is prevalent across Indian soils causing khaira disease in paddy and white bud in maize. Apply 10 kg Zinc Sulphate (21%) per acre at sowing.',
            icon: Icons.bubble_chart_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF33691E), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF616161),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
