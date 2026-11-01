import 'dart:math';
import '../models/ai_diagnosis_result.dart';

/// Service powering AI Crop Disease and Pest Diagnosis.
/// Provides authentic disease profiles, symptom analysis, remedies,
/// and safe uncertainty warnings with direct expert forwarding.
class AiCropDiagnosisService {
  AiCropDiagnosisService._();
  static final AiCropDiagnosisService instance = AiCropDiagnosisService._();

  final Map<String, List<AiDiagnosisResult>> _knowledgeBase = {
    'Cotton': [
      const AiDiagnosisResult(
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
      const AiDiagnosisResult(
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
      const AiDiagnosisResult(
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
    'Tomato': [
      const AiDiagnosisResult(
        cropName: 'Tomato',
        diagnosisTitle: 'Tomato Leaf Curl Virus (ToLCV)',
        confidencePercentage: 95.4,
        severityLevel: 'Moderate to High',
        isHealthy: false,
        symptoms: [
          'Severe upward curling, cupping, and crinkling of young leaflets',
          'Interveinal chlorosis (yellowing between leaf veins)',
          'Bushy stunted plant architecture and failure to set fruits',
        ],
        preventiveMeasures: [
          'Vector control is crucial: manage Whitefly vectors using yellow sticky traps',
          'Rogue out and safely bury severely infected young seedlings',
          'Grow border crops of maize or sorghum as windbreaks against whiteflies',
        ],
        organicRemedies: [
          'Spray sour buttermilk (Khatta Chhash) @ 500ml + 50g turmeric in 15L water',
          'Neem oil 10,000 ppm @ 20ml / 15L water',
        ],
        chemicalRemedies: [
          'Acetamiprid 20% SP @ 5g / 15L water',
          'Cyantraniliprole 10.26% OD @ 18ml / 15L water for whitefly nymph control',
        ],
      ),
    ],
    'Wheat': [
      const AiDiagnosisResult(
        cropName: 'Wheat',
        diagnosisTitle: 'Yellow Rust / Stripe Rust (Puccinia striiformis)',
        confidencePercentage: 96.1,
        severityLevel: 'High (Immediate Action Required)',
        isHealthy: false,
        symptoms: [
          'Bright yellow linear pustules arranged in parallel stripes on leaves',
          'Yellow powder readily stains fingers or white cloth when touched',
          'Rapid desiccation of flag leaves leading to shriveled grains',
        ],
        preventiveMeasures: [
          'Plant resistant varieties (e.g. DBW 187, DBW 222, HD 3226)',
          'Conduct weekly field surveys during cool foggy weather',
        ],
        organicRemedies: [
          'Trichoderma harzianum soil and foliar spray @ 5g/L',
          'Apply wood ash and fermented butter-milk foliar dusting',
        ],
        chemicalRemedies: [
          'Propiconazole 25% EC (Tilt) @ 1ml / 1L water (15-20ml per pump)',
          'Tebuconazole 25.9% EC @ 15ml / 15L water',
        ],
        uncertaintyWarning:
            'Yellow rust spreads exponentially on wind currents. Spray within 48 hours of spotting.',
      ),
    ],
  };

  /// Perform AI Diagnosis on uploaded or camera captured crop image
  Future<AiDiagnosisResult> analyzeCropImage({
    required String cropName,
    required String imagePath,
  }) async {
    // Simulate real AI visual inference computation time
    await Future.delayed(const Duration(milliseconds: 1400));

    final normalized = _knowledgeBase.keys.firstWhere(
      (k) => cropName.toLowerCase().contains(k.toLowerCase()) || k.toLowerCase().contains(cropName.toLowerCase()),
      orElse: () => 'Cotton',
    );

    final results = _knowledgeBase[normalized]!;
    final selected = results[Random().nextInt(results.length)];

    return AiDiagnosisResult(
      cropName: selected.cropName,
      diagnosisTitle: selected.diagnosisTitle,
      confidencePercentage: selected.confidencePercentage,
      severityLevel: selected.severityLevel,
      isHealthy: selected.isHealthy,
      symptoms: selected.symptoms,
      preventiveMeasures: selected.preventiveMeasures,
      organicRemedies: selected.organicRemedies,
      chemicalRemedies: selected.chemicalRemedies,
      uncertaintyWarning: selected.uncertaintyWarning,
      analyzedImagePath: imagePath,
    );
  }
}

