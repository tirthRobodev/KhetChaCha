import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';
import '../../services/farming_recommendation_service.dart';
import '../../services/language_service.dart';

/// Interactive Crop Advisory Page tailored to farmer's selected state and crops.
class CropAdvisoryPage extends StatelessWidget {
  final FarmerProfile profile;

  const CropAdvisoryPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final langCode = LanguageService.instance.currentLanguage.locale.languageCode;
    final loc = AppLocalizations.of(context);
    final advisories = FarmingRecommendationService.instance.getPersonalizedAdvisories(
      stateName: profile.effectiveState,
      districtName: profile.effectiveDistrict,
      selectedProducts: profile.effectiveProducts,
      langCode: langCode,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.cropAdvisoryTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card with State Badge
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
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Color(0xFFFF9933), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${profile.effectiveState} • ${profile.effectiveDistrict}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tailored farming recommendations for ${profile.effectiveProducts.join(', ')}',
                  style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Recommended State Practices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 10),

          ...advisories.map((adv) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        adv,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333), height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

