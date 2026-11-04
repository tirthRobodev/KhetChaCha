/// Models for KhetChacha Farmer AI Chat API integration with Python FastAPI backend.
library;

class FarmerLocationPayload {
  final String? village;
  final String? taluka;
  final String? district;
  final String? state;
  final double? latitude;
  final double? longitude;

  const FarmerLocationPayload({
    this.village,
    this.taluka,
    this.district,
    this.state,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (village != null && village!.isNotEmpty) data['village'] = village;
    if (taluka != null && taluka!.isNotEmpty) data['taluka'] = taluka;
    if (district != null && district!.isNotEmpty) data['district'] = district;
    if (state != null && state!.isNotEmpty) data['state'] = state;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    return data;
  }
}

class FarmerWeatherPayload {
  final double? temperatureCelsius;
  final double? humidityPercent;
  final String? condition;
  final String? rainForecast;

  const FarmerWeatherPayload({
    this.temperatureCelsius,
    this.humidityPercent,
    this.condition,
    this.rainForecast,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (temperatureCelsius != null) {
      data['temperature_celsius'] = temperatureCelsius;
    }
    if (humidityPercent != null) data['humidity_percent'] = humidityPercent;
    if (condition != null && condition!.isNotEmpty) {
      data['condition'] = condition;
    }
    if (rainForecast != null && rainForecast!.isNotEmpty) {
      data['rain_forecast'] = rainForecast;
    }
    return data;
  }
}

class FarmerChatApiRequest {
  final String question;
  final String language;
  final String? currentCrop;
  final int? cropAgeDays;
  final String? soilType;
  final double? landSize;
  final String? landUnit;
  final FarmerLocationPayload? location;
  final FarmerWeatherPayload? weather;
  final String? conversationId;

  const FarmerChatApiRequest({
    required this.question,
    this.language = 'gu',
    this.currentCrop,
    this.cropAgeDays,
    this.soilType,
    this.landSize,
    this.landUnit,
    this.location,
    this.weather,
    this.conversationId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'question': question,
      'language': language,
    };
    if (currentCrop != null && currentCrop!.isNotEmpty) {
      data['current_crop'] = currentCrop;
    }
    if (cropAgeDays != null) {
      data['crop_age_days'] = cropAgeDays;
    }
    if (soilType != null && soilType!.isNotEmpty) {
      data['soil_type'] = soilType;
    }
    if (landSize != null) {
      data['land_size'] = landSize;
    }
    if (landUnit != null && landUnit!.isNotEmpty) {
      data['land_unit'] = landUnit;
    }
    if (location != null) {
      final locData = location!.toJson();
      if (locData.isNotEmpty) data['location'] = locData;
    }
    if (weather != null) {
      final weatherData = weather!.toJson();
      if (weatherData.isNotEmpty) data['weather'] = weatherData;
    }
    if (conversationId != null && conversationId!.isNotEmpty) {
      data['conversation_id'] = conversationId;
    }
    return data;
  }
}

class AiEvidenceSource {
  final String title;
  final String? documentName;
  final int? pageNumber;
  final String? pageOrSection;
  final String sourceType;
  final String snippet;
  final double confidenceScore;

  const AiEvidenceSource({
    required this.title,
    this.documentName,
    this.pageNumber,
    this.pageOrSection,
    this.sourceType = 'local_pdf',
    this.snippet = '',
    this.confidenceScore = 0.0,
  });

  factory AiEvidenceSource.fromJson(Map<String, dynamic> json) {
    return AiEvidenceSource(
      title: json['title'] as String? ?? 'Agricultural Advisory',
      documentName: json['document_name'] as String?,
      pageNumber: json['page_number'] as int? ?? json['page'] as int?,
      pageOrSection: json['page_or_section'] as String?,
      sourceType: json['source_type'] as String? ?? 'local_pdf',
      snippet: json['snippet'] as String? ?? '',
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble() ??
          (json['relevance_score'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class FarmerChatApiResponse {
  final bool success;
  final String language;
  final String languageName;
  final String answer;
  final String detailedExplanation;
  final List<String> actionSteps;
  final List<String> safetyPrecautions;
  final String? cropDetected;
  final List<String> symptomsIdentified;
  final double confidenceScore;
  final List<AiEvidenceSource> sources;
  final String searchStrategyUsed;
  final bool requiresPhoto;
  final bool isError;
  final String? errorMessage;

  const FarmerChatApiResponse({
    this.success = true,
    this.language = 'gu',
    this.languageName = 'Gujarati',
    required this.answer,
    this.detailedExplanation = '',
    this.actionSteps = const [],
    this.safetyPrecautions = const [],
    this.cropDetected,
    this.symptomsIdentified = const [],
    this.confidenceScore = 0.85,
    this.sources = const [],
    this.searchStrategyUsed = 'local_only',
    this.requiresPhoto = false,
    this.isError = false,
    this.errorMessage,
  });

  factory FarmerChatApiResponse.fromJson(Map<String, dynamic> json) {
    final rawSources =
        json['sources'] as List? ?? json['evidence_sources'] as List? ?? [];
    final sourcesList = rawSources
        .whereType<Map<String, dynamic>>()
        .map((s) => AiEvidenceSource.fromJson(s))
        .toList();

    final rawActions = json['action_steps'] as List? ?? [];
    final actionsList = rawActions.map((e) => e.toString()).toList();

    final rawPrecautions = json['safety_precautions'] as List? ?? [];
    final precautionsList = rawPrecautions.map((e) => e.toString()).toList();

    final rawSymptoms = json['symptoms_identified'] as List? ?? [];
    final symptomsList = rawSymptoms.map((e) => e.toString()).toList();

    return FarmerChatApiResponse(
      success: json['success'] as bool? ?? true,
      language: json['language'] as String? ?? 'gu',
      languageName: json['language_name'] as String? ?? 'Gujarati',
      answer:
          json['answer'] as String? ?? json['short_answer'] as String? ?? '',
      detailedExplanation: json['detailed_explanation'] as String? ?? '',
      actionSteps: actionsList,
      safetyPrecautions: precautionsList,
      cropDetected: json['crop_detected'] as String?,
      symptomsIdentified: symptomsList,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.85,
      sources: sourcesList,
      searchStrategyUsed:
          json['search_strategy_used'] as String? ?? 'local_only',
      requiresPhoto: json['requires_photo'] as bool? ?? false,
      isError: false,
    );
  }

  factory FarmerChatApiResponse.error({
    required String userFriendlyMessage,
    String language = 'gu',
    String? rawError,
  }) {
    return FarmerChatApiResponse(
      success: false,
      isError: true,
      language: language,
      answer: userFriendlyMessage,
      errorMessage: rawError,
      actionSteps: const [
        'ઇન્ટરનેટ કનેક્શન તપાસો અથવા થોડીવાર પછી પ્રયાસ કરો.',
        'ટોલ-ફ્રી કિસાન હેલ્પલાઇન (1800-180-1551) નો સંપર્ક કરો.',
      ],
      safetyPrecautions: const [
        'અધિકૃત ખાતરી વગર કોઈ પણ રાસાયણિક દવાનો અયોગ્ય છંટકાવ કરવો નહીં.',
      ],
    );
  }
}
