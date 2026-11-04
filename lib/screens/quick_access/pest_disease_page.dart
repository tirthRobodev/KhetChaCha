import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';

/// Pest & Disease Diagnostic Guide.
class PestDiseasePage extends StatelessWidget {
  final FarmerProfile profile;

  const PestDiseasePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final crops = profile.effectiveProducts.isNotEmpty
        ? profile.effectiveProducts
        : ['Cotton', 'Paddy'];

    final pestItems = [
      {
        'crop': 'Cotton',
        'pest': 'Pink Bollworm & Whitefly',
        'symptoms': 'Rosetted flowers, damaged bolls with small holes, and yellowing leaves.',
        'remedy': 'Install 8-10 pheromone traps per acre. Spray Neem Seed Kernel Extract (NSKE 5%) or Profenofos 50 EC.',
      },
      {
        'crop': 'Paddy (Rice)',
        'pest': 'Brown Plant Hopper (BPH) & Stem Borer',
        'symptoms': 'Hopper burn patches in fields, dead hearts during vegetative stage, white ears at heading.',
        'remedy': 'Maintain alternate wetting and drying (AWD). Apply Cartap Hydrochloride 4G or Chlorantraniliprole 0.4G.',
      },
      {
        'crop': 'Tomato',
        'pest': 'Fruit Borer (Helicoverpa) & Early Blight',
        'symptoms': 'Circular brown spots on lower leaves and bored holes in green and red fruits.',
        'remedy': 'Plant African Marigold as a trap crop. Spray Mancozeb 75 WP (2g/L) for early blight control.',
      },
      {
        'crop': 'Wheat',
        'pest': 'Yellow Rust (Puccinia striiformis)',
        'symptoms':
            'Yellow stripe-like pustules running parallel to leaf veins.',
        'remedy': 'Spray Propiconazole 25 EC (Tilt) @ 200 ml in 200 liters of water per acre immediately upon first spot.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.pestAndDiseaseTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bug_report_rounded,
                  color: Color(0xFFC62828),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active Pest Alerts for ${profile.effectiveState} (${crops.join(', ')})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...pestItems.map(
            (item) => Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['crop']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'High Vigilance',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['pest']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Symptoms: ${item['symptoms']!}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF616161),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💊 Remedy: ${item['remedy']!}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
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
