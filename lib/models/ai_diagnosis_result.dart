/// Model representing the outcome of an AI-powered Crop Image Diagnosis.
/// Includes identified plant category, plant part, health assessment, symptoms,
/// prevention, bio/chemical treatments, full narrative, and escalation routes.
class AiDiagnosisResult {
  final String cropName;
  final String diagnosisTitle;
  final double confidencePercentage;
  final String
  severityLevel; // 'None - Healthy', 'Low', 'Moderate', 'Severe', 'Uncertain'
  final bool isHealthy;
  final List<String> symptoms;
  final List<String> preventiveMeasures;
  final List<String> organicRemedies;
  final List<String> chemicalRemedies;
  final String? uncertaintyWarning;
  final String? analyzedImagePath;

  // Enhanced Dynamic Vision Attributes
  final String plantCategory;
  final String plantPart;
  final String healthStatus; // 'healthy', 'possibly_affected', 'clearly_damaged', 'uncertain'
  final List<String> possibleCauses;
  final List<String> additionalInfoNeeded;
  final List<String> immediateActions;
  final String fullAnswer;
  final String languageCode;

  const AiDiagnosisResult({
    required this.cropName,
    required this.diagnosisTitle,
    required this.confidencePercentage,
    required this.severityLevel,
    required this.isHealthy,
    required this.symptoms,
    required this.preventiveMeasures,
    required this.organicRemedies,
    required this.chemicalRemedies,
    this.uncertaintyWarning,
    this.analyzedImagePath,
    this.plantCategory = 'Crop',
    this.plantPart = 'Leaf',
    this.healthStatus = 'uncertain',
    this.possibleCauses = const [],
    this.additionalInfoNeeded = const [],
    this.immediateActions = const [],
    this.fullAnswer = '',
    this.languageCode = 'gu',
  });

  Map<String, dynamic> toJson() => {
    'cropName': cropName,
    'diagnosisTitle': diagnosisTitle,
    'confidencePercentage': confidencePercentage,
    'severityLevel': severityLevel,
    'isHealthy': isHealthy,
    'symptoms': symptoms,
    'preventiveMeasures': preventiveMeasures,
    'organicRemedies': organicRemedies,
    'chemicalRemedies': chemicalRemedies,
    'uncertaintyWarning': uncertaintyWarning,
    'analyzedImagePath': analyzedImagePath,
    'plantCategory': plantCategory,
    'plantPart': plantPart,
    'healthStatus': healthStatus,
    'possibleCauses': possibleCauses,
    'additionalInfoNeeded': additionalInfoNeeded,
    'immediateActions': immediateActions,
    'fullAnswer': fullAnswer,
    'languageCode': languageCode,
  };

  factory AiDiagnosisResult.fromJson(Map<String, dynamic> json) {
    final isH =
        json['isHealthy'] as bool? ??
        (json['is_healthy'] as bool?) ??
        (json['healthStatus'] == 'healthy' ||
            json['health_status'] == 'healthy');

    final healthStat =
        json['healthStatus'] as String? ??
        json['health_status'] as String? ??
        (isH ? 'healthy' : 'clearly_damaged');

    return AiDiagnosisResult(
      cropName:
          json['cropName'] as String? ??
          json['plant_name'] as String? ??
          json['crop_detected'] as String? ??
          'Crop',
      diagnosisTitle:
          json['diagnosisTitle'] as String? ??
          json['diagnosis_title'] as String? ??
          'General Health Check',
      confidencePercentage:
          (json['confidencePercentage'] as num?)?.toDouble() ??
          (json['confidence_percentage'] as num?)?.toDouble() ??
          88.0,
      severityLevel:
          json['severityLevel'] as String? ??
          json['severity_level'] as String? ??
          (isH ? 'None - Healthy' : 'Moderate'),
      isHealthy: isH,
      symptoms: List<String>.from(
        json['symptoms'] as List? ?? json['observed_symptoms'] as List? ?? [],
      ),
      preventiveMeasures: List<String>.from(
        json['preventiveMeasures'] as List? ??
            json['preventive_measures'] as List? ??
            [],
      ),
      organicRemedies: List<String>.from(
        json['organicRemedies'] as List? ??
            json['organic_remedies'] as List? ??
            [],
      ),
      chemicalRemedies: List<String>.from(
        json['chemicalRemedies'] as List? ??
            json['chemical_remedies'] as List? ??
            [],
      ),
      uncertaintyWarning:
          json['uncertaintyWarning'] as String? ??
          json['uncertainty_warning'] as String?,
      analyzedImagePath: json['analyzedImagePath'] as String?,
      plantCategory:
          json['plantCategory'] as String? ??
          json['plant_category'] as String? ??
          'Crop',
      plantPart:
          json['plantPart'] as String? ??
          json['plant_part'] as String? ??
          'Leaf',
      healthStatus: healthStat,
      possibleCauses: List<String>.from(
        json['possibleCauses'] as List? ??
            json['possible_causes'] as List? ??
            [],
      ),
      additionalInfoNeeded: List<String>.from(
        json['additionalInfoNeeded'] as List? ??
            json['additional_info_needed'] as List? ??
            [],
      ),
      immediateActions: List<String>.from(
        json['immediateActions'] as List? ??
            json['immediate_actions'] as List? ??
            json['action_steps'] as List? ??
            [],
      ),
      fullAnswer:
          json['fullAnswer'] as String? ?? json['answer'] as String? ?? '',
      languageCode:
          json['languageCode'] as String? ??
          json['language'] as String? ??
          'gu',
    );
  }
}
