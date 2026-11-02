import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Seed & Certified Variety Guide.
class SeedVarietyPage extends StatelessWidget {
  final FarmerProfile profile;

  const SeedVarietyPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final seedList = [
      {
        'crop': 'Wheat',
        'variety': 'HD-2967 & DBW-187 (Karan Vandana)',
        'yield': '22 - 25 Quintals / Acre',
        'maturity': '140 - 145 Days',
        'traits': 'Resistant to yellow rust and terminal heat stress.',
      },
      {
        'crop': 'Paddy',
        'variety': 'Pusa Basmati 1509 & PR-126',
        'yield': '24 - 28 Quintals / Acre',
        'maturity': '115 - 120 Days',
        'traits':
            'Short duration, saves 25% irrigation water, high market price.',
      },
      {
        'crop': 'Cotton',
        'variety': 'Bt Cotton (Bollgard II hybrids)',
        'yield': '12 - 15 Quintals / Acre',
        'maturity': '160 - 180 Days',
        'traits':
            'High ginning outturn, drought tolerant, bollworm resistance.',
      },
      {
        'crop': 'Groundnut',
        'variety': 'GG-20 & TG-37A',
        'yield': '10 - 14 Quintals / Acre',
        'maturity': '105 - 115 Days',
        'traits': 'High oil content (49%), bold kernels, bunch type.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.seedAndVarietyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ICAR & SAU Certified High-Yield Varieties for ${profile.effectiveState}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...seedList.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['crop']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['variety']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🌾 Yield: ${s['yield']!}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '⏱️ Duration: ${s['maturity']!}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✨ Traits: ${s['traits']!}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
