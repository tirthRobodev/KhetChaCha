import 'dart:typed_data';

import '../models/ai_diagnosis_result.dart';
import '../models/farmer_profile.dart';
import 'universal_agri_vision_service.dart';

/// Service powering AI Crop Disease and Pest Diagnosis.
/// Integrates with UniversalAgriVisionService for genuine dynamic visual reasoning
/// across any crop, fruit, vegetable, tree, flower, leaf, stem, root, or seed.
class AiCropDiagnosisService {
  AiCropDiagnosisService._();
  static final AiCropDiagnosisService instance = AiCropDiagnosisService._();

  /// Perform AI Diagnosis on uploaded or camera captured crop/plant image.
  /// Calls UniversalAgriVisionService for genuine multimodal inspection without hardcoding.
  Future<AiDiagnosisResult> analyzeCropImage({
    required String cropName,
    required String imagePath,
    Uint8List? imageBytes,
    String? userQuestion,
    String? languageCode,
    FarmerProfile? profile,
  }) async {
    return UniversalAgriVisionService.instance.diagnoseImage(
      imagePath: imagePath,
      imageBytes: imageBytes,
      cropHint: cropName,
      userQuestion: userQuestion,
      targetLanguageCode: languageCode,
      profile: profile,
    );
  }

  /// Returns known agricultural diagnoses references for a given crop (used as reference).
  List<AiDiagnosisResult> getPossibleDiagnoses(String cropName) {
    final normalized = _referenceKnowledgeBase.keys.firstWhere(
      (k) =>
          cropName.toLowerCase().contains(k.toLowerCase()) ||
          k.toLowerCase().contains(cropName.toLowerCase()),
      orElse: () => 'Cotton',
    );
    return _referenceKnowledgeBase[normalized] ?? [];
  }

  static const Map<String, List<AiDiagnosisResult>> _referenceKnowledgeBase = {
    'Cotton': [
      AiDiagnosisResult(
        cropName: 'Cotton',
        diagnosisTitle: 'Pink Bollworm (Pectinophora gossypiella)',
        confidencePercentage: 94.6,
        severityLevel: 'Moderate to High',
        isHealthy: false,
        symptoms: [
          'Rosetted flower appearance (petals tied together)',
          'Small entry pin-holes on developing bolls',
          'Premature boll dropping and stained lint fiber inside bolls',
        ],
        preventiveMeasures: [
          'Install 8-10 Pheromone traps per acre at 45 days after sowing',
          'Destroy crop residues after harvest to break the pupal diapause',
          'Avoid extended ratoon cotton cultivation',
        ],
        organicRemedies: [
          'Spray 5% Neem Seed Kernel Extract (NSKE) at squaring stage',
          'Release Trichogramma bactrae egg parasitoid @ 60,000/acre at weekly intervals',
          'Spray Beauveria bassiana bio-insecticide @ 5g/liter',
        ],
        chemicalRemedies: [
          'Emamectin Benzoate 5% SG @ 5g / 15L water',
          'Chlorantraniliprole 18.5% SC @ 6ml / 15L water',
          'Profenofos 50% EC @ 30ml / 15L water (only if economic threshold crossed)',
        ],
        uncertaintyWarning:
            'AI diagnosis indicates early-to-mid stage infestation. For confirmed ETL counting and pesticide prescription, forward this image to a verified Agronomist.',
      ),
      AiDiagnosisResult(
        cropName: 'Cotton',
        diagnosisTitle: 'Whitefly Infestation (Bemisia tabaci)',
        confidencePercentage: 91.2,
        severityLevel: 'Moderate',
        isHealthy: false,
        symptoms: [
          'Chlorotic spots on leaves resulting in yellowing and curling',
          'Black sooty mold fungus developing on honeydew excretion',
          'Stunted plant vigor and leaf shedding',
        ],
        preventiveMeasures: [
          'Erect yellow sticky traps @ 10-15 per acre',
          'Avoid excessive synthetic pyrethroid sprays which trigger whitefly resurgence',
        ],
        organicRemedies: [
          'Neem Oil (1500 ppm) @ 50ml / 15L water',
          'Verticillium lecanii @ 5g/L water in evening hours',
        ],
        chemicalRemedies: [
          'Diafenthiuron 50% WP @ 20g / 15L water',
          'Pyriproxyfen 10% EC @ 25ml / 15L water',
        ],
        uncertaintyWarning:
            'Whitefly counts vary rapidly across field microclimates. Verify nymph counts per leaf before spraying.',
      ),
    ],
    'Paddy (Rice)': [
      AiDiagnosisResult(
        cropName: 'Paddy (Rice)',
        diagnosisTitle: 'Rice Blast Disease (Magnaporthe oryzae)',
        confidencePercentage: 93.8,
        severityLevel: 'High',
        isHealthy: false,
        symptoms: [
          'Spindle-shaped or eye-shaped lesions with brown or grey centers',
          'Rotting of nodal rings (node blast)',
          'Blackening at the base of panicles leading to empty grains (neck blast)',
        ],
        preventiveMeasures: [
          'Avoid heavy single-dose urea application; use split nitrogen doses',
          'Treat seeds with Tricyclazole 75 WP @ 2g/kg seed before nursery sowing',
        ],
        organicRemedies: [
          'Spray Pseudomonas fluorescens @ 10g/L water at early tillering',
          'Apply fermented cow dung & neem leaf extract slurry (Dashparni ark)',
        ],
        chemicalRemedies: [
          'Tricyclazole 75% WP @ 12g / 15L water',
          'Kasugamycin 3% SL @ 30ml / 15L water',
          'Azoxystrobin 18.2% + Difenoconazole 11.4% SC @ 15ml / 15L water',
        ],
        uncertaintyWarning:
            'Neck blast can spread rapidly under high humidity. Consult local KVK agronomist immediately if spots are visible on more than 5% of tillers.',
      ),
    ],
  };
}
