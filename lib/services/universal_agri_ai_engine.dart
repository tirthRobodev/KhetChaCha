import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/ai_chat_models.dart';
import '../models/ai_conversation_message.dart';
import '../models/farmer_profile.dart';
import 'ai_chat_api_service.dart';
import 'conversation_history_service.dart';
import 'location_service.dart';
import 'permission_service.dart';
import 'unified_agri_ai_service.dart';
import 'universal_agri_vision_service.dart';

/// The Universal Agricultural AI Engine for KhetChaCha.
///
/// Serves as the single unified question processing engine shared by BOTH
/// Text Chat (AskKhetChachaAiPage) and Voice Assistant (VoiceAssistantPage / STT).
///
/// Features:
/// - Universal question normalization & transcript sanitization.
/// - Support for all 22 scheduled Indian languages + English with Indic script detection.
/// - 3-Tier Fault-Tolerant Execution:
///     Tier 1: FastAPI AI Engine Backend (/api/v1/chat) with full farmer & agronomic context.
///     Tier 2: Direct Gemini fallback when backend is unreachable and API key is present.
///     Tier 3: Authoritative grounded offline agricultural synthesis (0 network dependency).
/// - Comprehensive multi-part scenario handling (e.g. 2-acre cotton 45-day yellowing + pests
///   requiring water, fertilizer, diagnosis, pest control, expenses, and a 30-day plan).
/// - Automatic synchronization with shared persistent `ConversationHistoryService`.
class UniversalAgriAiEngine {
  UniversalAgriAiEngine._internal();
  static final UniversalAgriAiEngine instance = UniversalAgriAiEngine._internal();

  /// Process any farmer query from Voice STT, Text Input, or Multimodal Image Vision.
  Future<AiConversationMessage> processQuery({
    required String query,
    required FarmerProfile profile,
    String inputMode = 'text',
    String? preferredLanguageCode,
    String? conversationId,
    bool saveToHistory = true,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    // 0. Handle Image Payload if present
    Uint8List? resolvedImageBytes = imageBytes;
    String? resolvedImageBase64 = imageBase64;
    String? resolvedImageMimeType = imageMimeType;

    if (resolvedImageBytes == null && imagePath != null && imagePath.isNotEmpty) {
      try {
        if (imagePath.startsWith('assets/')) {
          final byteData = await rootBundle.load(imagePath);
          resolvedImageBytes = byteData.buffer.asUint8List();
        } else {
          final file = File(imagePath);
          if (await file.exists()) {
            resolvedImageBytes = await file.readAsBytes();
          }
        }
      } catch (e) {
        debugPrint('[UniversalAgriAiEngine] Error loading image bytes: $e');
      }
    }

    if (resolvedImageBase64 == null && resolvedImageBytes != null && resolvedImageBytes.isNotEmpty) {
      resolvedImageBase64 = base64Encode(resolvedImageBytes);
      resolvedImageMimeType ??= _detectMimeType(resolvedImageBytes);
    }

    final bool hasImage = resolvedImageBase64 != null && resolvedImageBase64.isNotEmpty;
    var cleanQuery = _normalizeQuery(query);

    if (cleanQuery.isEmpty) {
      if (hasImage) {
        cleanQuery = _getDefaultVisionPrompt(preferredLanguageCode ?? 'gu');
      } else {
        final fallbackLang = preferredLanguageCode ?? 'gu';
        return AiConversationMessage(
          id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'assistant',
          text: _getEmptyQueryMessage(fallbackLang),
          inputMode: inputMode,
          languageCode: fallbackLang,
          timestamp: DateTime.now(),
        );
      }
    }

    // 1. Language Detection & Normalization across 22 Scheduled Indian Languages
    final effectiveLang = UnifiedAgriAiService.instance.detectLanguageCode(
      cleanQuery,
      currentLanguageCode: preferredLanguageCode,
    );

    // 1b. STT Speech Transcript Validation
    // Identify speech recognition errors before generating agricultural recommendations
    if (inputMode == 'voice' && !hasImage && (!validateSttTranscript(query) || !validateSttTranscript(cleanQuery))) {
      final speechErrMsg = getSpeechRecognitionErrorMessage(effectiveLang);
      final errMsg = AiConversationMessage(
        id: 'msg_stt_err_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'assistant',
        text: speechErrMsg,
        inputMode: 'voice',
        languageCode: effectiveLang,
        timestamp: DateTime.now(),
      );
      if (saveToHistory) {
        try {
          await ConversationHistoryService.instance.addMessage(errMsg);
        } catch (_) {}
      }
      return errMsg;
    }

    // 2. Prepare Context Payload
    final profileKey = profile.firebaseUid ?? profile.mobileNumber;
    final effectiveSessionId = conversationId ??
        'session-${profileKey.isNotEmpty ? profileKey : "farmer"}-${DateTime.now().millisecondsSinceEpoch}';

    final effectiveCrop = profile.effectiveProducts.isNotEmpty
        ? profile.effectiveProducts.first
        : (profile.crops.isNotEmpty ? profile.crops.first : null);

    double? landAreaNum;
    final parsedLand = double.tryParse(profile.landSize.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsedLand != null) landAreaNum = parsedLand;

    // Resolve location
    FarmerLocationPayload? locationPayload;
    try {
      final isLocGranted = await PermissionService.instance.checkStatus(KhetPermissionType.location) ==
          KhetPermissionState.granted;
      final cachedLoc = LocationService.instance.lastKnownLocation;
      if (isLocGranted && cachedLoc != null) {
        locationPayload = FarmerLocationPayload(
          village: cachedLoc.village.isNotEmpty ? cachedLoc.village : profile.village,
          taluka: cachedLoc.taluka.isNotEmpty ? cachedLoc.taluka : profile.taluka,
          district: cachedLoc.district.isNotEmpty ? cachedLoc.district : profile.effectiveDistrict,
          state: cachedLoc.state.isNotEmpty ? cachedLoc.state : profile.effectiveState,
          latitude: cachedLoc.latitude,
          longitude: cachedLoc.longitude,
        );
      } else {
        locationPayload = FarmerLocationPayload(
          village: profile.village.isNotEmpty ? profile.village : null,
          taluka: profile.taluka.isNotEmpty ? profile.taluka : null,
          district: profile.effectiveDistrict.isNotEmpty ? profile.effectiveDistrict : null,
          state: profile.effectiveState.isNotEmpty ? profile.effectiveState : null,
        );
      }
    } catch (_) {
      locationPayload = FarmerLocationPayload(
        district: profile.effectiveDistrict.isNotEmpty ? profile.effectiveDistrict : null,
        state: profile.effectiveState.isNotEmpty ? profile.effectiveState : null,
      );
    }

    final apiRequest = FarmerChatApiRequest(
      question: cleanQuery,
      language: effectiveLang,
      currentCrop: effectiveCrop,
      soilType: profile.soilType.isNotEmpty ? profile.soilType : null,
      landSize: landAreaNum,
      landUnit: profile.landUnit.isNotEmpty ? profile.landUnit : 'Acre',
      location: locationPayload,
      conversationId: effectiveSessionId,
      imageBase64: resolvedImageBase64,
      imageMimeType: resolvedImageMimeType,
    );

    // 3. Execution Pipeline (Tier 1 -> Tier 2 -> Tier 3)
    FarmerChatApiResponse? backendResponse;

    try {
      debugPrint('[UniversalAgriAiEngine] Tier 1: Querying Python Backend for "$cleanQuery" (Lang: $effectiveLang, hasImage: $hasImage)');
      final res = await AiChatApiService.instance.sendFarmerQuery(apiRequest);
      if (!res.isError) {
        backendResponse = res;
      } else {
        debugPrint('[UniversalAgriAiEngine] Tier 1 Backend returned error: ${res.errorMessage}');
      }
    } catch (e) {
      debugPrint('[UniversalAgriAiEngine] Tier 1 Backend exception: $e');
    }

    AiConversationMessage finalMessage;

    if (backendResponse != null) {
      // Tier 1 Success: Parse backend structured response
      final structuredMap = <String, String>{
        'problemUnderstanding': backendResponse.answer,
      };

      if (backendResponse.detailedExplanation.isNotEmpty) {
        structuredMap['diagnosis'] = backendResponse.detailedExplanation;
      }
      if (backendResponse.actionSteps.isNotEmpty) {
        structuredMap['recommendedActions'] = backendResponse.actionSteps.join('\n• ');
      }
      if (backendResponse.safetyPrecautions.isNotEmpty) {
        structuredMap['precautionsAndDosages'] = backendResponse.safetyPrecautions.join('\n⚠️ ');
      }
      if (backendResponse.sources.isNotEmpty) {
        structuredMap['sourcesCited'] = backendResponse.sources.map((s) => s.title).join(', ');
      }
      if (backendResponse.plantCategory != null) {
        structuredMap['plantCategory'] = backendResponse.plantCategory!;
      }
      if (backendResponse.plantPart != null) {
        structuredMap['plantPart'] = backendResponse.plantPart!;
      }
      if (backendResponse.healthStatus != null) {
        structuredMap['healthStatus'] = backendResponse.healthStatus!;
      }

      final fullDisplayText = _formatBackendResponseText(backendResponse);

      finalMessage = AiConversationMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'assistant',
        text: fullDisplayText,
        inputMode: inputMode,
        languageCode: backendResponse.language.isNotEmpty ? backendResponse.language : effectiveLang,
        timestamp: DateTime.now(),
        structuredSections: structuredMap,
      );
    } else if (hasImage) {
      // Multimodal Vision Fallback via UniversalAgriVisionService
      debugPrint('[UniversalAgriAiEngine] Tier 2/3: Multimodal Vision Fallback via UniversalAgriVisionService');
      final visionResult = await UniversalAgriVisionService.instance.diagnoseImage(
        imagePath: imagePath ?? '',
        imageBytes: resolvedImageBytes,
        userQuestion: cleanQuery,
        targetLanguageCode: effectiveLang,
        cropHint: effectiveCrop,
        profile: profile,
      );

      final structuredMap = <String, String>{
        'problemUnderstanding': visionResult.diagnosisTitle,
        'diagnosis': visionResult.possibleCauses.isNotEmpty
            ? visionResult.possibleCauses.join(', ')
            : visionResult.diagnosisTitle,
        'recommendedActions': visionResult.organicRemedies.join('\n• '),
        'precautionsAndDosages': visionResult.chemicalRemedies.join('\n⚠️ '),
        'plantCategory': visionResult.plantCategory,
        'plantPart': visionResult.plantPart,
        'healthStatus': visionResult.healthStatus,
      };

      finalMessage = AiConversationMessage(
        id: 'msg_vis_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'assistant',
        text: visionResult.fullAnswer.isNotEmpty
            ? visionResult.fullAnswer
            : visionResult.diagnosisTitle,
        inputMode: inputMode,
        languageCode: effectiveLang,
        timestamp: DateTime.now(),
        structuredSections: structuredMap,
      );
    } else {
      // Tier 2: Check Direct Gemini if key is provided
      String? geminiText;
      final directKey = UnifiedAgriAiService.instance.geminiApiKey;
      if (directKey.isNotEmpty) {
        debugPrint('[UniversalAgriAiEngine] Tier 2: Calling Direct Gemini API');
        try {
          geminiText = await _callGeminiDirect(
            apiKey: directKey,
            query: cleanQuery,
            langCode: effectiveLang,
            crop: effectiveCrop ?? 'Cotton',
            district: profile.effectiveDistrict,
            state: profile.effectiveState,
          );
        } catch (e) {
          debugPrint('[UniversalAgriAiEngine] Tier 2 Direct Gemini error: $e');
        }
      }

      if (geminiText != null && geminiText.trim().isNotEmpty) {
        final parsedSections = UnifiedAgriAiService.instance.parseSixPartResponse(geminiText);
        finalMessage = AiConversationMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'assistant',
          text: geminiText,
          inputMode: inputMode,
          languageCode: effectiveLang,
          timestamp: DateTime.now(),
          structuredSections: parsedSections,
        );
      } else {
        // Tier 3: Grounded Deterministic Agronomic Synthesis (0-network offline fallback)
        debugPrint('[UniversalAgriAiEngine] Tier 3: Generating Grounded Offline Response');
        final offlineGrounding = {
          'detectedCrop': effectiveCrop ?? 'Cotton',
          'district': profile.effectiveDistrict,
          'state': profile.effectiveState,
          'landSize': profile.landSize,
          'soilType': profile.soilType,
        };

        final offlineRes = UnifiedAgriAiService.instance.generateOfflineFallback(
          query: cleanQuery,
          langCode: effectiveLang,
          grounding: offlineGrounding,
        );

        finalMessage = AiConversationMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'assistant',
          text: offlineRes['text'] as String,
          inputMode: inputMode,
          languageCode: effectiveLang,
          timestamp: DateTime.now(),
          structuredSections: offlineRes['sections'] as Map<String, String>?,
        );
      }
    }

    // 4. Shared Persistence Synchronization
    if (saveToHistory) {
      try {
        await ConversationHistoryService.instance.addMessage(finalMessage);
      } catch (e) {
        debugPrint('[UniversalAgriAiEngine] Notice: Could not save message to history: $e');
      }
    }

    return finalMessage;
  }

  /// Helper for AskKhetChachaAiPage to obtain a FarmerChatApiResponse with fallback resilience.
  Future<FarmerChatApiResponse> processChatQuery({
    required FarmerChatApiRequest request,
    required FarmerProfile profile,
    bool enableOfflineFallback = false,
  }) async {
    try {
      final res = await AiChatApiService.instance.sendFarmerQuery(request);
      if (!res.isError || !enableOfflineFallback) {
        return res;
      }
    } catch (e) {
      if (!enableOfflineFallback) {
        return FarmerChatApiResponse(
          answer: 'Unable to connect to AI server. Please retry.',
          isError: true,
          errorMessage: e.toString(),
        );
      }
    }

    // Fallback using Universal Engine
    final msg = await processQuery(
      query: request.question,
      profile: profile,
      inputMode: 'text',
      preferredLanguageCode: request.language,
      conversationId: request.conversationId,
      saveToHistory: false, // Page manages history
      imageBase64: request.imageBase64,
      imageMimeType: request.imageMimeType,
    );

    return FarmerChatApiResponse(
      answer: msg.structuredSections?['problemUnderstanding'] ?? msg.text,
      detailedExplanation: msg.structuredSections?['diagnosis'] ?? msg.text,
      actionSteps: msg.structuredSections?['recommendedActions'] != null
          ? msg.structuredSections!['recommendedActions']!.split('\n• ')
          : const [],
      safetyPrecautions: msg.structuredSections?['precautionsAndDosages'] != null
          ? msg.structuredSections!['precautionsAndDosages']!.split('\n⚠️ ')
          : const [],
      language: msg.languageCode,
      confidenceScore: 0.85,
      plantCategory: msg.structuredSections?['plantCategory'],
      plantPart: msg.structuredSections?['plantPart'],
      healthStatus: msg.structuredSections?['healthStatus'],
    );
  }

  // ===========================================================================
  // STT TRANSCRIPT VALIDATION & NORMALIZATION
  // ===========================================================================

  /// Validates speech recognition transcript before generating agricultural recommendations.
  /// Identifies empty, too short, pure punctuation, or filler-word transcripts.
  bool validateSttTranscript(String transcript) {
    final clean = transcript.trim();
    if (clean.length < 3) return false;
    final withoutPunct = clean.replaceAll(RegExp(r'[\s\.,\?!।\-_\(\)\[\]]'), '');
    if (withoutPunct.length < 3) return false;
    const noiseWords = {'hmm', 'um', 'uh', 'ah', 'er', 'ha', 'oh', 'huh'};
    final tokens = clean
        .toLowerCase()
        .replaceAll(RegExp(r'[\.,\?!।\-_\(\)\[\]]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);
    if (tokens.isEmpty || tokens.every((t) => noiseWords.contains(t))) return false;
    return true;
  }

  /// Returns supportive localized speech error message.
  String getSpeechRecognitionErrorMessage(String lang) {
    switch (lang.toLowerCase()) {
      case 'gu':
        return 'ક્ષમા કરશો, અવાજ સ્પષ્ટ સંભળાયો નથી. કૃપા કરીને માઇક્રોફોન નજીક રાખી ફરીથી તમારો ખેતી પ્રશ્ન બોલો.';
      case 'hi':
        return 'क्षमा करें, आपकी आवाज स्पष्ट रूप से सुनाई नहीं दी। कृपया माइक्रोफोन के पास आकर अपना कृषि प्रश्न पुनः बोलें।';
      case 'pa':
        return 'ਮਾਫ਼ ਕਰਨਾ, ਤੁਹਾਡੀ ਆਵਾਜ਼ ਸਪਸ਼ਟ ਨਹੀਂ ਸੁਣੀ ਗਈ। ਕਿਰਪਾ ਕਰਕੇ ਮਾਈਕ੍ਰੋਫੋਨ ਕੋਲ ਆਪਣਾ ਖੇਤੀ ਸਵਾਲ ਦੁਬਾਰਾ ਬੋਲੋ।';
      case 'mr':
        return 'क्षमस्व, आपला आवाज स्पष्ट ऐकू आला नाही. कृपया मायक्रोफोन जवळ ठेवून आपला शेती प्रश्न पुन्हा विचारा.';
      default:
        return 'Sorry, your speech could not be recognized clearly. Please speak your agricultural question into the microphone again.';
    }
  }

  String _normalizeQuery(String raw) {
    var clean = raw.trim();
    // Remove repeated punctuation and speech artifact tokens
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    clean = clean.replaceAll(RegExp(r'^(uh|um|er|hmm|ah)\s+', caseSensitive: false), '');
    return clean.trim();
  }

  String _getEmptyQueryMessage(String lang) {
    switch (lang) {
      case 'gu':
        return 'કૃપા કરીને તમારો પ્રશ્ન બોલો અથવા લખો. ખેતચાચા તમારી સહાય માટે તૈયાર છે.';
      case 'hi':
        return 'कृपया अपना सवाल बोलें या लिखें। खेतचाचा आपकी सहायता के लिए तैयार हैं।';
      case 'pa':
        return 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਸਵਾਲ ਬੋਲੋ ਜਾਂ ਲਿਖੋ। ਖੇਤਚਾਚਾ ਤੁਹਾਡੀ ਮਦਦ ਲਈ ਤਿਆਰ ਹਨ।';
      case 'mr':
        return 'कृपया आपला प्रश्न बोला किंवा लिहा. खेतचाचा आपल्या मदतीसाठी तयार आहेत.';
      default:
        return 'Please speak or type your agricultural query. KhetChaCha is ready to help.';
    }
  }

  String _formatBackendResponseText(FarmerChatApiResponse res) {
    final buffer = StringBuffer();
    buffer.writeln(res.answer);

    if (res.detailedExplanation.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(res.detailedExplanation);
    }

    if (res.actionSteps.isNotEmpty) {
      buffer.writeln();
      final actionHeading = res.language == 'gu' ? 'મુખ્ય પગલાં:' : (res.language == 'hi' ? 'मुख्य कदम:' : 'Action Steps:');
      buffer.writeln('**$actionHeading**');
      for (final step in res.actionSteps) {
        buffer.writeln('• $step');
      }
    }

    if (res.safetyPrecautions.isNotEmpty) {
      buffer.writeln();
      final safetyHeading = res.language == 'gu' ? 'સાવચેતી અને ડોઝ:' : (res.language == 'hi' ? 'सावधानी एवं मात्रा:' : 'Safety & Dosages:');
      buffer.writeln('**$safetyHeading**');
      for (final p in res.safetyPrecautions) {
        buffer.writeln('⚠️ $p');
      }
    }

    return buffer.toString().trim();
  }

  Future<String?> _callGeminiDirect({
    required String apiKey,
    required String query,
    required String langCode,
    required String crop,
    required String district,
    required String state,
  }) async {
    final systemPrompt = '''
You are KhetChaCha AI, Senior Agricultural Advisor for Indian farmers.
Location: $district, $state. Primary Crop: $crop.
Language requested: $langCode.

CRITICAL INSTRUCTIONS:
Always formulate your response in a structured agricultural format:
PART 1: Understanding problem
PART 2: Likely causes / Diagnosis
PART 3: Recommended actions (Biological / Organic & Chemical)
PART 4: Timing & step-by-step application
PART 5: Precautions & exact dosages (per 15-litre spray pump)
PART 6: Additional information needed from farmer
Respond in native Indic script ($langCode) with accurate, non-hallucinated dosages.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [{'text': systemPrompt}],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': query}],
        },
      ],
      'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 3072},
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] as String?;
      }
    }
    return null;
  }

  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _getDefaultVisionPrompt(String lang) {
    switch (lang) {
      case 'gu':
        return 'આ છોડના ફોટાનું વિશ્લેષણ કરો અને આરોગ્યની સ્થિતિ જણાવો';
      case 'hi':
        return 'कृपया इस पौधे की फोटो देखकर रोग या स्वास्थ्य की स्थिति बताएं';
      case 'pa':
        return 'ਇਸ ਪੌਦੇ ਦੀ ਫੋਟੋ ਦੇਖ ਕੇ ਇਸਦੀ ਸਿਹਤ ਦੀ ਜਾਂਚ ਕਰੋ ਅਤੇ ਸਹੀ ਸਲਾਹ ਦਿਓ';
      case 'mr':
        return 'या रोपाचा फोटो तपासून त्याच्या आरोग्याची स्थिती आणि सल्ला द्या';
      default:
        return 'Diagnose this plant image and provide health assessment';
    }
  }
}
