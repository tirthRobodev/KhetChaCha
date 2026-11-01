import 'package:flutter/material.dart';
import '../../models/farmer_profile.dart';
import '../ai/image_ai_diagnosis_page.dart';
import '../expert/ask_expert_page.dart';
import '../farm_production_selection_page.dart';

/// Full-Screen Crop Management Page (Bottom Navigation Destination 2).
/// Displays farmer's selected crops, growth stages, stage-specific advisories,
/// disease prevention guides, and direct shortcuts to Manage Crops and Ask Expert.
class CropManagementPage extends StatefulWidget {
  final FarmerProfile profile;
  final Function(FarmerProfile updated)? onProfileUpdated;

  const CropManagementPage({
    super.key,
    required this.profile,
    this.onProfileUpdated,
  });

  @override
  State<CropManagementPage> createState() => _CropManagementPageState();
}

class _CropManagementPageState extends State<CropManagementPage> {
  late FarmerProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  void _openManageFarmCrops() async {
    final updated = await Navigator.of(context).push<FarmerProfile>(
      MaterialPageRoute(
        builder: (_) => FarmProductionSelectionPage(
          profile: _profile,
          isEditMode: true,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
      widget.onProfileUpdated?.call(updated);
    }
  }

  Map<String, dynamic> _getCropDetails(String crop) {
    final c = crop.toLowerCase();
    if (c.contains('cotton')) {
      return {
        'season': 'Kharif',
        'duration': '150 - 180 Days',
        'currentStage': 'Flowering & Boll Formation',
        'stageProgress': 0.65,
        'advisory': 'Maintain soil moisture at boll filling. Avoid excess nitrogen which promotes vegetative growth.',
        'commonPest': 'Pink Bollworm & Whitefly',
        'icon': '🧶',
      };
    } else if (c.contains('paddy') || c.contains('rice')) {
      return {
        'season': 'Kharif',
        'duration': '120 - 135 Days',
        'currentStage': 'Active Tillering & Panicle Initiation',
        'stageProgress': 0.50,
        'advisory': 'Apply 2nd split dose of Urea with Zinc. Maintain 2-3 cm standing water in field.',
        'commonPest': 'Stem Borer & Leaf Blast',
        'icon': '🌾',
      };
    } else if (c.contains('tomato')) {
      return {
        'season': 'Rabi / Kharif',
        'duration': '90 - 110 Days',
        'currentStage': 'Fruiting & Ripening',
        'stageProgress': 0.75,
        'advisory': 'Stake heavy vines. Spray calcium chloride or micronutrients to prevent blossom end rot.',
        'commonPest': 'Fruit Borer & Early Blight',
        'icon': '🍅',
      };
    } else if (c.contains('wheat')) {
      return {
        'season': 'Rabi',
        'duration': '110 - 125 Days',
        'currentStage': 'Crown Root Initiation (CRI)',
        'stageProgress': 0.25,
        'advisory': 'Provide 1st critical irrigation at 21 days after sowing. Top-dress with Urea.',
        'commonPest': 'Yellow Rust & Termites',
        'icon': '🌾',
      };
    }

    return {
      'season': 'Kharif / Rabi',
      'duration': '100 - 120 Days',
      'currentStage': 'Vegetative Growth',
      'stageProgress': 0.40,
      'advisory': 'Ensure regular weeding and balanced NPK fertilizer application.',
      'commonPest': 'Aphids & Leaf Spot',
      'icon': '🌱',
    };
  }

  @override
  Widget build(BuildContext context) {
    final crops = _profile.effectiveProducts.isNotEmpty
        ? _profile.effectiveProducts
        : ['Cotton', 'Paddy (Rice)', 'Tomato'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Crops & Growth Stages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            tooltip: 'Add / Edit Crops',
            onPressed: _openManageFarmCrops,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Action Card: Add / Manage Farm Crops
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${crops.length} Active Crops Registered',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Farm: ${_profile.effectiveFarmSize} in ${_profile.effectiveDistrict}',
                          style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _openManageFarmCrops,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Detailed Crop Lifecycle & Advisories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 12),

            ...crops.map((crop) {
              final info = _getCropDetails(crop);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Emoji + Title + Season badge
                      Row(
                        children: [
                          Text(info['icon'] as String, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  crop,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                                ),
                                Text(
                                  'Season: ${info['season']} • Duration: ${info['duration']}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Growth Stage Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Growth Stage:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            info['currentStage'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: info['stageProgress'] as double,
                          backgroundColor: const Color(0xFFE8F5E9),
                          color: const Color(0xFF2E7D32),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stage Advisory
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF2E7D32), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                info['advisory'] as String,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Common Pest & Action row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.bug_report_outlined, size: 16, color: Color(0xFFC62828)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Pest Alert: ${info['commonPest']}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.document_scanner_rounded, size: 20, color: Color(0xFF1B5E20)),
                                tooltip: 'Scan with Image AI',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ImageAiDiagnosisPage(profile: _profile)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.support_agent_rounded, size: 20, color: Color(0xFF0288D1)),
                                tooltip: 'Ask Expert',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => AskExpertPage(profile: _profile, preselectedCrop: crop)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

