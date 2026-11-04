import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Interactive Sowing & Harvesting Crop Calendar.
class CropCalendarPage extends StatelessWidget {
  final FarmerProfile profile;

  const CropCalendarPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final stages = [
      {
        'stage': 'Land Preparation',
        'timeline': 'May - June',
        'status': 'Completed',
        'icon': Icons.landscape_rounded,
      },
      {
        'stage': 'Sowing / Transplanting',
        'timeline': 'June - July',
        'status': 'Completed',
        'icon': Icons.grass_rounded,
      },
      {
        'stage': 'First Top Dressing & Weeding',
        'timeline': 'August',
        'status': 'Completed',
        'icon': Icons.water_drop_rounded,
      },
      {
        'stage': 'Flowering & Pest Vigilance',
        'timeline': 'September',
        'status': 'Active Stage',
        'icon': Icons.nature_rounded,
      },
      {
        'stage': 'Grain Filling / Fruit Maturity',
        'timeline': 'October',
        'status': 'Upcoming',
        'icon': Icons.grain_rounded,
      },
      {
        'stage': 'Harvesting & Threshing',
        'timeline': 'November - December',
        'status': 'Upcoming',
        'icon': Icons.agriculture_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.cropCalendarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farming Timeline & Stages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crops: ${profile.effectiveProducts.join(', ')} • ${profile.effectiveState}',
                  style: const TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...stages.map((st) {
            final isActive = st['status'] == 'Active Stage';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                  width: isActive ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      st['icon'] as IconData,
                      color: isActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF757575),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st['stage'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          st['timeline'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      st['status'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
