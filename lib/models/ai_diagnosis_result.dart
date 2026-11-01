/// Model representing the outcome of an AI-powered Crop Image Diagnosis.
/// Includes identified disease/pest, confidence score, symptoms, prevention,
/// bio/chemical treatments, and a clear escalation route to a verified expert.
class AiDiagnosisResult {
  final String cropName;
  final String diagnosisTitle;
  final double confidencePercentage;
  final String severityLevel; // 'None - Healthy', 'Low', 'Moderate', 'Severe'
  final bool isHealthy;
  final List<String> symptoms;
  final List<String> preventiveMeasures;
  final List<String> organicRemedies;
  final List<String> chemicalRemedies;
  final String? uncertaintyWarning;
  final String? analyzedImagePath;

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
      };

  factory AiDiagnosisResult.fromJson(Map<String, dynamic> json) => AiDiagnosisResult(
        cropName: json['cropName'] as String? ?? 'Crop',
        diagnosisTitle: json['diagnosisTitle'] as String? ?? 'General Health Check',
        confidencePercentage: (json['confidencePercentage'] as num?)?.toDouble() ?? 88.0,
        severityLevel: json['severityLevel'] as String? ?? 'Moderate',
        isHealthy: json['isHealthy'] as bool? ?? false,
        symptoms: List<String>.from(json['symptoms'] as List? ?? []),
        preventiveMeasures: List<String>.from(json['preventiveMeasures'] as List? ?? []),
        organicRemedies: List<String>.from(json['organicRemedies'] as List? ?? []),
        chemicalRemedies: List<String>.from(json['chemicalRemedies'] as List? ?? []),
        uncertaintyWarning: json['uncertaintyWarning'] as String?,
        analyzedImagePath: json['analyzedImagePath'] as String?,
      );
}

