import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Government Schemes Directory for Farmers.
class GovtSchemesPage extends StatelessWidget {
  final FarmerProfile profile;

  const GovtSchemesPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final schemes = [
      {
        'title': 'PM-Kisan Samman Nidhi',
        'subtitle': '₹6,000 per year in 3 direct bank installments to landholding farmers.',
        'tag': 'Central Scheme',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF1B5E20),
      },
      {
        'title': 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        'subtitle': 'Comprehensive crop insurance against drought, floods, and unseasonal rainfall.',
        'tag': 'Crop Insurance',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF0277BD),
      },
      {
        'title': 'Kisan Credit Card (KCC)',
        'subtitle': 'Low interest short-term credit at 4% effective interest rate for agricultural inputs.',
        'tag': 'Credit & Loan',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFFE65100),
      },
      {
        'title': '${profile.effectiveState} Micro-Irrigation Subsidy',
        'subtitle': 'Up to 70% subsidy on installation of Drip & Sprinkler irrigation equipment.',
        'tag': 'State Subsidy',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF2E7D32),
      },
      {
        'title': 'Soil Health Card Scheme',
        'subtitle': 'Free soil testing every 2 years with customized fertilizer recommendations.',
        'tag': 'Soil Nutrition',
        'icon': Icons.grass_rounded,
        'color': const Color(0xFF6A1B9A),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.governmentSchemesTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: schemes.length,
        itemBuilder: (context, i) {
          final s = schemes[i];
          final color = s['color'] as Color;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s['icon'] as IconData, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['tag'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['subtitle'] as String,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF616161), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

