import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ai_conversation_message.dart';
import '../models/farmer_profile.dart';
import 'ai_crop_diagnosis_service.dart';
import 'mandi_discovery_service.dart';

/// The central intelligence brain for KhetChaCha.
/// Coordinates language detection, multi-part intent decomposition, agronomic grounding,
/// and AI response generation (via backend proxy, Gemini, or grounded offline fallback).
class UnifiedAgriAiService {
  UnifiedAgriAiService._internal();
  static final UnifiedAgriAiService instance = UnifiedAgriAiService._internal();

  // Configurable backend URL. On Android emulator 10.0.2.2 maps to host machine.
  static const String defaultBackendUrl = 'http://10.0.2.2:8000';
  String _customBackendUrl = defaultBackendUrl;

  // Optional direct Gemini API Key via dart-define or runtime setting
  String _geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  void setCustomBackendUrl(String url) {
    _customBackendUrl = url;
  }

  void setGeminiApiKey(String apiKey) {
    _geminiApiKey = apiKey;
  }

  String get geminiApiKey => _geminiApiKey;
  String get backendUrl => _customBackendUrl;

  // ===========================================================================
  // 1. LANGUAGE & SCRIPT DETECTION (22 SCHEDULED LANGUAGES + CODE-MIXED)
  // ===========================================================================

  /// Detects language from user text across 22 Indian scheduled languages.
  /// Falls back to provided [currentLanguageCode] or 'en' if ambiguous.
  String detectLanguageCode(String text, {String? currentLanguageCode}) {
    final clean = text.trim();
    if (clean.isEmpty) return currentLanguageCode ?? 'en';

    // Script range checks
    int gujarati = 0;
    int devanagari = 0;
    int gurmukhi = 0;
    int bengali = 0;
    int tamil = 0;
    int telugu = 0;
    int kannada = 0;
    int malayalam = 0;
    int odia = 0;
    int arabic = 0;
    int olChiki = 0;
    int latin = 0;

    for (final rune in clean.runes) {
      if (rune >= 0x0A80 && rune <= 0x0AFF) {
        gujarati++;
      } else if (rune >= 0x0900 && rune <= 0x097F) {
        devanagari++;
      } else if (rune >= 0x0A00 && rune <= 0x0A7F) {
        gurmukhi++;
      } else if (rune >= 0x0980 && rune <= 0x09FF) {
        bengali++;
      } else if (rune >= 0x0B80 && rune <= 0x0BFF) {
        tamil++;
      } else if (rune >= 0x0C00 && rune <= 0x0C7F) {
        telugu++;
      } else if (rune >= 0x0C80 && rune <= 0x0CFF) {
        kannada++;
      } else if (rune >= 0x0D00 && rune <= 0x0D7F) {
        malayalam++;
      } else if (rune >= 0x0B00 && rune <= 0x0B7F) {
        odia++;
      } else if (rune >= 0x0600 && rune <= 0x06FF) {
        arabic++;
      } else if (rune >= 0x1C50 && rune <= 0x1C7F) {
        olChiki++;
      } else if ((rune >= 0x0041 && rune <= 0x005A) ||
          (rune >= 0x0061 && rune <= 0x007A)) {
        latin++;
      }
    }

    if (gujarati > 0 && gujarati >= devanagari) return 'gu';
    if (gurmukhi > 0) return 'pa';
    if (tamil > 0) return 'ta';
    if (telugu > 0) return 'te';
    if (kannada > 0) return 'kn';
    if (malayalam > 0) return 'ml';
    if (odia > 0) return 'or';
    if (olChiki > 0) return 'sat';
    if (arabic > 0) return 'ur'; // Or Kashmiri/Sindhi Arabic

    if (bengali > 0) {
      // Check Assamese characters (ৰ, ৱ)
      if (clean.contains('ৰ') || clean.contains('ৱ')) return 'as';
      return 'bn';
    }

    if (devanagari > 0) {
      // 1. Marathi unique character 'ळ'
      if (clean.contains('ळ')) return 'mr';

      // 2. Linguistic context scoring for Marathi vs Hindi
      final mrMarkers = [
        'आहे', 'आहेत', 'नाही', 'नाहीत', 'काय', 'कसे', 'कशी', 'कसा', 'कधी',
        'करावे', 'करावी', 'करावा', 'करायचे', 'पिकाला', 'पिकावर', 'पिकात', 'पिक',
        'शेतकरी', 'शेती', 'फवारणी', 'औषध', 'औषधे', 'खत', 'खते', 'माती',
        'किड', 'कीड', 'माशी', 'अळी', 'बोंडअळी', 'द्यावे', 'द्यावी', 'लागेल',
        'होईल', 'झाले', 'झाली', 'झाला', 'कापूस', 'गहू', 'भात', 'भुईमूग', 'सोयाबीन'
      ];
      final hiMarkers = [
        'है', 'हैं', 'नहीं', 'क्या', 'कैसे', 'कैसा', 'कैसी', 'कब', 'करें',
        'करना', 'करूं', 'फसल', 'फसलों', 'किसान', 'खेती', 'छिड़काव', 'दवा',
        'दवाई', 'खाद', 'मिट्टी', 'कीट', 'कीड़ा', 'मक्खी', 'सुंडी', 'दें',
        'देना', 'लगेगा', 'होगी', 'होगा', 'कपास', 'गेहूं', 'धान', 'चावल', 'मूंगफली'
      ];

      int mrScore = 0;
      for (final m in mrMarkers) {
        if (clean.contains(m)) mrScore++;
      }

      int hiScore = 0;
      for (final h in hiMarkers) {
        if (clean.contains(h)) hiScore++;
      }

      if (mrScore > hiScore && mrScore > 0) return 'mr';
      if (hiScore > mrScore && hiScore > 0) return 'hi';

      if (clean.contains('छ') || clean.contains('गर्नुपर्छ')) {
        return 'ne';
      }

      if (currentLanguageCode == 'mr' || currentLanguageCode == 'hi') {
        return currentLanguageCode!;
      }
      return 'hi';
    }

    // Latin / Romanized checks: Check if code-mixed Hinglish / Gujlish / Marathi / Punjabi
    final lower = clean.toLowerCase();
    if (latin > 0) {
      if (lower.contains('khedut') ||
          lower.contains('kapas') ||
          lower.contains('dava') ||
          lower.contains('khatar') ||
          lower.contains('eeyad') ||
          lower.contains('mavthu')) {
        return 'gu';
      }
      if (lower.contains('kisan') ||
          lower.contains('fasal') ||
          lower.contains('keeda') ||
          lower.contains('dawae') ||
          lower.contains('paani') ||
          lower.contains('gehu') ||
          lower.contains('dhan')) {
        return 'hi';
      }
      if (lower.contains('shetkari') ||
          lower.contains('sheti') ||
          lower.contains('favarni') ||
          lower.contains('aushadh') ||
          lower.contains('bondaali') ||
          lower.contains('kay karave')) {
        return 'mr';
      }
      if (lower.contains('kheti') ||
          lower.contains('sundi') ||
          lower.contains('chitti makhi') ||
          lower.contains('kanak') ||
          lower.contains('jhona')) {
        return 'pa';
      }
    }

    return currentLanguageCode ?? 'en';
  }

  /// Maps language code to standard BCP-47 speech recognition & TTS locale
  String resolveSpeechLocale(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return 'gu-IN';
      case 'hi':
        return 'hi-IN';
      case 'pa':
        return 'pa-IN';
      case 'mr':
        return 'mr-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'bn':
        return 'bn-IN';
      case 'as':
        return 'as-IN';
      case 'or':
        return 'or-IN';
      case 'ur':
        return 'ur-IN';
      case 'ne':
        return 'ne-NP';
      default:
        return 'en-IN';
    }
  }

  // ===========================================================================
  // 2. MULTI-PART QUERY DECOMPOSITION & GROUNDING
  // ===========================================================================

  /// Analyzes query tokens and builds contextual grounding from app services
  Map<String, dynamic> buildGroundingContext({
    required String query,
    required FarmerProfile profile,
    required String languageCode,
  }) {
    final lower = query.toLowerCase();

    // 1. Identify Crop Mentioned
    String detectedCrop = 'Cotton';
    if (lower.contains('rice') ||
        lower.contains('paddy') ||
        lower.contains('ડાંગર') ||
        lower.contains('ચોખા') ||
        lower.contains('धान') ||
        lower.contains('चावल') ||
        lower.contains('ਝੋਨਾ')) {
      detectedCrop = 'Paddy (Rice)';
    } else if (lower.contains('wheat') ||
        lower.contains('ઘઉં') ||
        lower.contains('गेहूं') ||
        lower.contains('ਕਣਕ')) {
      detectedCrop = 'Wheat';
    } else if (lower.contains('groundnut') ||
        lower.contains('peanut') ||
        lower.contains('મગફળી') ||
        lower.contains('मूंगफली') ||
        lower.contains('ਮੂੰਗਫਲੀ')) {
      detectedCrop = 'Groundnut';
    } else if (lower.contains('tomato') ||
        lower.contains('ટામેટા') ||
        lower.contains('टमाटर') ||
        lower.contains('ਟਮਾਟਰ')) {
      detectedCrop = 'Tomato';
    } else if (lower.contains('cumin') ||
        lower.contains('જીરું') ||
        lower.contains('जीरा')) {
      detectedCrop = 'Cumin';
    } else if (lower.contains('mustard') ||
        lower.contains('રાયડો') ||
        lower.contains('सरसों') ||
        lower.contains('ਸਰ੍ਹੋਂ')) {
      detectedCrop = 'Mustard';
    } else if (lower.contains('cotton') ||
        lower.contains('કપાસ') ||
        lower.contains('कपास') ||
        lower.contains('ਕਪਾਹ')) {
      detectedCrop = 'Cotton';
    } else if (profile.crops.isNotEmpty) {
      detectedCrop = profile.crops.first;
    }

    // 2. Pull Domain Diagnosis Data
    final diagnoses = AiCropDiagnosisService.instance.getPossibleDiagnoses(
      detectedCrop,
    );
    final primaryDiag = diagnoses.isNotEmpty ? diagnoses.first : null;

    // 3. Pull Mandi Prices & Comparison
    String mandiSummary = '';
    try {
      final markets = MandiDiscoveryService.instance.getAllMarkets();
      for (final m in markets) {
        final p = m.getPriceForCommodity(detectedCrop);
        if (p != null) {
          mandiSummary = '${m.name}: ₹${p.modalPrice.round()}/Quintal';
          break;
        }
      }
    } catch (_) {}

    return {
      'farmerName': profile.fullName,
      'state': profile.state.isNotEmpty ? profile.state : 'Gujarat',
      'district': profile.district.isNotEmpty ? profile.district : 'Rajkot',
      'landAreaAcres': profile.landSize,
      'detectedCrop': detectedCrop,
      'mandiSummary': mandiSummary,
      'weatherTemp': '28°C',
      'weatherCondition': 'Partly Cloudy',
      'primaryDiagnosis': primaryDiag != null
          ? {
              'title': primaryDiag.diagnosisTitle,
              'symptoms': primaryDiag.symptoms,
              'organic': primaryDiag.organicRemedies,
              'chemical': primaryDiag.chemicalRemedies,
            }
          : null,
    };
  }

  // ===========================================================================
  // 3. MASTER AI QUERY EXECUTION (UNIFIED FOR TEXT & VOICE)
  // ===========================================================================

  /// Executes query reasoning. Employs 3-layer architecture:
  /// Layer 1: Python FastAPI backend (if reachable)
  /// Layer 2: Direct Gemini API (if key present)
  /// Layer 3: Comprehensive grounded deterministic offline agronomic engine
  Future<AiConversationMessage> processQuery({
    required String query,
    required FarmerProfile profile,
    required String inputMode, // 'voice' or 'text'
    String? preferredLanguageCode,
  }) async {
    final langCode = detectLanguageCode(
      query,
      currentLanguageCode: preferredLanguageCode,
    );
    final grounding = buildGroundingContext(
      query: query,
      profile: profile,
      languageCode: langCode,
    );

    String? fullAnswer;
    Map<String, String>? sections;

    // Layer 1: Try Python Backend
    try {
      final backendResponse = await _callPythonBackend(
        query: query,
        langCode: langCode,
        grounding: grounding,
      ).timeout(const Duration(seconds: 4));
      if (backendResponse != null) {
        fullAnswer = backendResponse['text'];
        if (backendResponse['sections'] != null) {
          sections = Map<String, String>.from(
            backendResponse['sections'] as Map,
          );
        }
      }
    } catch (_) {
      // Backend not running or timeout, proceed to next layer
    }

    // Layer 2: Try Direct Gemini API if configured
    if (fullAnswer == null && _geminiApiKey.isNotEmpty) {
      try {
        final geminiResponse = await _callGeminiDirect(
          query: query,
          langCode: langCode,
          grounding: grounding,
        ).timeout(const Duration(seconds: 8));
        if (geminiResponse != null) {
          fullAnswer = geminiResponse;
          sections = parseStructuredSections(fullAnswer, langCode);
        }
      } catch (e) {
        debugPrint(
          '[UnifiedAgriAiService] Gemini API call skipped or error: $e',
        );
      }
    }

    // Layer 3: High-Quality Grounded Offline Agricultural Expert Engine
    if (fullAnswer == null) {
      final offlineResult = _generateGroundedOfflineResponse(
        query: query,
        langCode: langCode,
        grounding: grounding,
      );
      fullAnswer = offlineResult['text']!;
      sections = offlineResult['sections'] as Map<String, String>;
    }

    return AiConversationMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'assistant',
      text: fullAnswer!,
      inputMode: inputMode,
      languageCode: langCode,
      timestamp: DateTime.now(),
      structuredSections: sections,
    );
  }

  // ===========================================================================
  // 4. REMOTE ADAPTERS (PYTHON BACKEND & GEMINI DIRECT)
  // ===========================================================================

  Future<Map<String, dynamic>?> _callPythonBackend({
    required String query,
    required String langCode,
    required Map<String, dynamic> grounding,
  }) async {
    final url = Uri.parse('$_customBackendUrl/api/v1/chat');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: json.encode({
        'question': query,
        'query': query,
        'language': langCode,
        'current_crop': grounding['detectedCrop'],
        'soil_type': grounding['soilType'],
        'land_size': grounding['landAreaAcres'],
        'farmer_district': grounding['district'],
        'farmer_state': grounding['state'],
        'grounding': grounding,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;

      if (data.containsKey('sections') && data.containsKey('text')) {
        return data;
      }

      final shortAnswer = data['short_answer'] as String? ??
          data['answer'] as String? ??
          data['text'] as String? ??
          '';
      final detailed = data['detailed_explanation'] as String? ?? '';
      final actions = (data['action_steps'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final safety = (data['safety_precautions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final fullText = StringBuffer();
      fullText.writeln(shortAnswer);
      if (detailed.isNotEmpty) {
        fullText.writeln();
        fullText.writeln(detailed);
      }
      if (actions.isNotEmpty) {
        fullText.writeln();
        fullText.writeln(langCode == 'gu' ? '**ભલામણ કરેલ પગલાં:**' : (langCode == 'hi' ? '**अनुशंसित कदम:**' : '**Recommended Actions:**'));
        for (final a in actions) {
          fullText.writeln('• $a');
        }
      }
      if (safety.isNotEmpty) {
        fullText.writeln();
        fullText.writeln(langCode == 'gu' ? '**સાવચેતી અને ડોઝ:**' : (langCode == 'hi' ? '**सावधानी एवं मात्रा:**' : '**Safety & Dosages:**'));
        for (final s in safety) {
          fullText.writeln('⚠️ $s');
        }
      }

      return {
        'text': fullText.toString().trim(),
        'sections': {
          'problemUnderstanding': shortAnswer,
          'likelyCauses': detailed.isNotEmpty ? detailed : shortAnswer,
          'recommendedActions': actions.isNotEmpty ? actions.join('\n• ') : 'નિયમિત નિરીક્ષણ કરો.',
          'timingAndSteps': detailed.isNotEmpty ? detailed : 'સમયસર છંટકાવ કરવો.',
          'precautionsAndDosages': safety.isNotEmpty ? safety.join('\n⚠️ ') : '૧૫ લિટર પંપ દીઠ અધિકૃત ડોઝ વાપરો.',
          'additionalInfoNeeded': 'પાંદડાનો ફોટો અપલોડ કરી વધુ વિગત મેળવી શકો છો.',
        },
      };
    }
    return null;
  }

  /// Exposes grounded offline fallback for UniversalAgriAiEngine.
  Map<String, dynamic> generateOfflineFallback({
    required String query,
    required String langCode,
    required Map<String, dynamic> grounding,
  }) {
    return _generateGroundedOfflineResponse(
      query: query,
      langCode: langCode,
      grounding: grounding,
    );
  }

  /// Parses 6-part structured agricultural response into map.
  Map<String, String> parseSixPartResponse(String text) {
    return parseStructuredSections(text, 'gu');
  }

  Future<String?> _callGeminiDirect({
    required String query,
    required String langCode,
    required Map<String, dynamic> grounding,
  }) async {
    final systemInstruction = _buildSystemPrompt(langCode, grounding);
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': query},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 2048},
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
        final text = candidates[0]['content']['parts'][0]['text'] as String?;
        return text;
      }
    }
    return null;
  }

  String _buildSystemPrompt(String langCode, Map<String, dynamic> grounding) {
    final crop = grounding['detectedCrop'] ?? 'Cotton';
    final district = grounding['district'] ?? 'Rajkot';
    final state = grounding['state'] ?? 'Gujarat';

    return '''
You are KhetChaCha AI, the Senior Agricultural Advisor for Indian farmers.
Location: $district, $state. Primary Crop: $crop.
Language requested: $langCode.

CRITICAL INSTRUCTIONS:
1. Always formulate your response in exactly the following 6-part structured agricultural format:
   PART 1: Understanding your problem
   PART 2: Likely causes / Diagnosis
   PART 3: Recommended actions (Biological / Organic & Chemical)
   PART 4: Timing & step-by-step application
   PART 5: Precautions & exact dosages (Always specify dosages per 15-litre knapsack spray pump)
   PART 6: Additional information needed from farmer
2. Do NOT truncate or abbreviate. Be comprehensive, precise, and supportive.
3. Preserve all dosage metrics (e.g. 5g / 15L water pump).
4. Reply in the user's requested language ($langCode) using natural, farmer-friendly vocabulary.
''';
  }

  // ===========================================================================
  // 5. GROUNDED OFFLINE AGRICULTURAL EXPERT ENGINE
  // ===========================================================================

  Map<String, dynamic> _generateGroundedOfflineResponse({
    required String query,
    required String langCode,
    required Map<String, dynamic> grounding,
  }) {
    final crop = grounding['detectedCrop'] as String? ?? 'Cotton';
    final lower = query.toLowerCase();

    // Check query focus: pest/disease, fertilizer/nutrition, mandi price, weather
    final hasPestDisease =
        lower.contains('રોગ') ||
        lower.contains('જીવાત') ||
        lower.contains('ઈયળ') ||
        lower.contains('માખી') ||
        lower.contains('દવા') ||
        lower.contains('પીળા') ||
        lower.contains('ખરી') ||
        lower.contains('pest') ||
        lower.contains('disease') ||
        lower.contains('spray') ||
        lower.contains('curl') ||
        lower.contains('rot') ||
        lower.contains('कीट') ||
        lower.contains('बीमारी') ||
        lower.contains('सुंडी');

    final isPrice =
        lower.contains('ભાવ') ||
        lower.contains('rate') ||
        lower.contains('price') ||
        lower.contains('મંડી') ||
        lower.contains('मंडी');

    final isPureFertilizer =
        !hasPestDisease &&
        (lower.contains('fertilizer') ||
            lower.contains('ખાતર') ||
            lower.contains('खाद') ||
            lower.contains('ਖਾਦ') ||
            lower.contains('खत') ||
            lower.contains('urea') ||
            lower.contains('dap') ||
            lower.contains('npk') ||
            lower.contains('પોટાશ'));

    if (isPrice && !hasPestDisease) {
      return _buildPriceResponse(crop, langCode, grounding);
    } else if (isPureFertilizer) {
      return _buildFertilizerResponse(crop, langCode, grounding);
    } else {
      return _buildPestDiseaseResponse(crop, query, langCode, grounding);
    }
  }

  Map<String, dynamic> _buildPestDiseaseResponse(
    String crop,
    String query,
    String langCode,
    Map<String, dynamic> grounding,
  ) {
    final lower = query.toLowerCase();
    final mentionsFertilizer =
        lower.contains('ખાતર') ||
        lower.contains('fertilizer') ||
        lower.contains('खाद') ||
        lower.contains('ਖਾਦ') ||
        lower.contains('खत') ||
        lower.contains('urea') ||
        lower.contains('npk');

    // Localized 6-part response builder
    if (langCode == 'gu') {
      final p1 =
          'તમારા $crop પાકમાં પાંદડા પીળા પડવા, જીવાતનો ઉપદ્રવ અથવા ફૂલ-ઝીંડવા ખરી પડવાની સમસ્યા ધ્યાને લીધી.';
      final p2 =
          '$crop પાકમાં મુખ્યત્વે ગુલાબી ઈયળ (Pink Bollworm), સફેદ માખી (Whitefly) અથવા થ્રિપ્સ અને સુકારો (Fusarium Wilt) જવાબદાર હોઈ શકે છે.';
      var p3 =
          '• જૈવિક ઉપાય: એકરે ૮-૧૦ ફેરોમોન ટ્રેપ અથવા ૧૫ પીળા/વાદળી ચીકણા કાર્ડ લગાવો. લીંબોળીનું તેલ (૫% અર્ક અથવા ૧૫૦૦ ppm) ૫૦ મિલી સ્પ્રે કરો.\n• રાસાયણિક ઉપાય: ઈયળ માટે ઇમામેક્ટીન બેન્ઝોએટ ૫% એસજી અથવા ક્લોરાન્ટ્રાનિલીપ્રોલ ૧૮.૫% એસસી; સફેદ માખી માટે ડાયફેન્થિયુરોન ૫૦% ડબલ્યુપી વાપરો.';
      if (mentionsFertilizer) {
        p3 += '\n• ખાતર ભલામણ: ૧૯:૧૯:૧૯ વોટર સોલ્યુબલ ખાતર ૭૫ ગ્રામ/પંપ સ્પ્રે કરો. ફૂલ બેસવાની અવસ્થાએ બોરોન ૨૦% (૨૦ ગ્રામ) આપવું. વધુ પડતો યુરિયા ટાળો.';
      }
      final p4 =
          '૧. પ્રથમ સ્પ્રે સાંજના સમયે (પવન શાંત હોય ત્યારે) કરો.\n૨. ઉપદ્રવ વધુ હોય તો ૧૦-૧૨ દિવસ પછી બીજી દવાનો સ્પ્રે કરો.\n૩. સ્પ્રે કરતા પહેલા જમીનમાં પૂરતો ભેજ હોવો જરૂરી છે.';
      final p5 =
          '• પંપ દીઠ પ્રમાણ: ૧૫ લિટર પાણીના પંપમાં ઇમામેક્ટીન બેન્ઝોએટ ૫ ગ્રામ અથવા ક્લોરાન્ટ્રાનિલીપ્રોલ ૬ મિલી નાખવું. વધુ ડોઝ ન નાખવો.\n• નિયમો: સ્પ્રે કરતી વખતે મોં પર માસ્ક અને હાથમોજાં પહેરો. પવનની વિરુદ્ધ દિશામાં સ્પ્રે ન કરવો.';
      final p6 =
          'પાકની ચોક્કસ ઉંમર (વાવણીના દિવસો) કેટલી છે? શું પાંદડા નીચે સફેદ જાળી કે ચીકાશ દેખાય છે? પાંદડાનો ફોટો એપમાં "AI રોગ સ્કેનર" દ્વારા મોકલો.';

      final fullText =
          '''### ૧. તમારી સમસ્યાની સમજ
$p1

### ૨. સંભવિત કારણો અને રોગ નિદાન
$p2

### ૩. ભલામણ કરેલ પગલાં (જૈવિક અને રાસાયણિક)
$p3

### ૪. સમય અને વિગતવાર તબક્કા
$p4

### ૫. સાવચેતી અને ચોક્કસ દવા પ્રમાણ (૧૫ લિટર પંપ)
$p5

### ૬. વધુ જરૂરી માહિતી
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'hi') {
      final p1 =
          'आपके $crop की फसल में पत्तियां पीली होना, कीटों का प्रकोप एवं फूलों का गिरना नोट किया गया है।';
      final p2 =
          '$crop में मुख्य रूप से गुलाबी सुंडी (Pink Bollworm), सफेद मक्खी या थ्रिप्स एवं पोषक तत्वों की कमी इसका प्रमुख कारण हो सकती है।';
      final p3 =
          '• जैविक नियंत्रण: प्रति एकड़ 8-10 फेरोमोन ट्रैप एवं 15 पीले चिपचिपे कार्ड लगाएं। नीम का तेल (1500 ppm) 50 मिली प्रति पंप छिड़कें।\n• रासायनिक नियंत्रण: इमामेक्टिन बेंजोएट 5% एसजी या क्लोरेंट्रानिलिप्रोल 18.5% एससी का छिड़काव करें।';
      final p4 =
          '१. छिड़काव शाम के समय धूप कम होने पर करें।\n२. कीटों का प्रकोप जारी रहने पर 10-12 दिन बाद छिड़काव दोहराएं।\n३. खेत में पर्याप्त नमी होना अनिवार्य है।';
      final p5 =
          '• प्रति पंप मात्रा: 15 लीटर वाले स्प्रे पंप में इमामेक्टिन बेंजोएट 5 ग्राम या क्लोरेंट्रानिलिप्रोल 6 मिली मिलाएं। ओवरडोज न करें।\n• सुरक्षा: छिड़काव के समय दस्ताने और मास्क का प्रयोग करें।';
      final p6 =
          'फसल की बुवाई को कितने दिन हुए हैं? क्या पत्तियों के नीचे सफेद कीड़े दिख रहे हैं? कृपया ऐप के "AI स्कैनर" से फोटो अपलोड करें।';

      final fullText =
          '''### १. आपकी समस्या की समझ
$p1

### २. संभावित कारण एवं रोग पहचान
$p2

### ३. अनुशंसित उपाय (जैविक एवं रासायनिक)
$p3

### ४. समय एवं चरणबद्ध छिड़काव
$p4

### ५. सावधानियां एवं सटीक खुराक (15 लीटर पंप)
$p5

### ६. अतिरिक्त आवश्यक जानकारी
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'pa') {
      final p1 =
          'ਤੁਹਾਡੀ $crop ਦੀ ਫ਼ਸਲ ਵਿੱਚ ਪੱਤੇ ਪੀਲੇ ਪੈਣ, ਕੀੜਿਆਂ ਦਾ ਹਮਲਾ ਜਾਂ ਫੁੱਲ ਝੜਨ ਦੀ ਸਮੱਸਿਆ ਸਮਝੀ ਗਈ ਹੈ।';
      final p2 =
          '$crop ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ (Pink Bollworm), ਚਿੱਟੀ ਮੱਖੀ ਜਾਂ ਤੇਲਾ ਅਤੇ ਉੱਲੀ ਰੋਗ ਇਸ ਦਾ ਮੁੱਖ ਕਾਰਨ ਹੋ ਸਕਦੇ ਹਨ।';
      var p3 =
          '• ਜੈਵਿਕ ਰੋਕਥਾਮ: ਪ੍ਰਤੀ ਏਕੜ 8-10 ਫੇਰੋਮੋਨ ਟਰੈਪ ਲਗਾਓ। ਨਿੰਮ ਦਾ ਤੇਲ (1500 ppm) 50 ਮਿ.ਲੀ. ਪ੍ਰਤੀ 15 ਲੀਟਰ ਪੰਪ ਛਿੜਕੋ।\n• ਰਸਾਇਣਕ ਰੋਕਥਾਮ: ਇਮਾਮੇਕਟਿਨ ਬੈਂਜੋਏਟ 5% ਐਸਜੀ ਜਾਂ ਕੋਰਾਜਨ (ਕਲੋਰੈਂਟਰਾਨਿਲੀਪਰੋਲ 18.5% ਐਸਸੀ) ਦਾ ਛਿੜਕਾਅ ਕਰੋ।';
      if (mentionsFertilizer) {
        p3 += '\n• ਖਾਦ ਦੀ ਸਿਫ਼ਾਰਸ਼: 19:19:19 ਘੁਲਣਸ਼ੀਲ ਖਾਦ 75 ਗ੍ਰਾਮ/ਪੰਪ ਛਿੜਕੋ। ਯੂਰੀਆ ਦੀ ਜ਼ਿਆਦਾ ਵਰਤੋਂ ਤੋਂ ਬਚੋ।';
      }
      final p4 =
          '੧. ਛਿੜਕਾਅ ਸ਼ਾਮ ਦੇ ਸਮੇਂ ਕਰੋ ਜਦੋਂ ਧੁੱਪ ਘੱਟ ਹੋਵੇ।\n੨. ਕੀੜਿਆਂ ਦਾ ਪ੍ਰਕੋਪ ਰਹਿਣ ਤੇ 10-12 ਦਿਨਾਂ ਬਾਅਦ ਛਿੜਕਾਅ ਦੁਹਰਾਓ।\n੩. ਖੇਤ ਵਿੱਚ ਲੋੜੀਂਦੀ ਨਮੀ ਹੋਣੀ ਲਾਜ਼ਮੀ ਹੈ।';
      final p5 =
          '• ਪ੍ਰਤੀ ਪੰਪ ਮਾਤਰਾ: 15 ਲੀਟਰ ਵਾਲੇ ਪੰਪ ਵਿੱਚ ਇਮਾਮੇਕਟਿਨ ਬੈਂਜੋਏਟ 5 ਗ੍ਰਾਮ ਜਾਂ ਕੋਰਾਜਨ 6 ਮਿ.ਲੀ. ਮਿਲਾਓ। ਵੱਧ ਮਾਤਰਾ ਨਾ ਵਰਤੋ।\n• ਸਾਵਧਾਨੀ: ਛਿੜਕਾਅ ਸਮੇਂ ਮਾਸਕ ਅਤੇ ਦਸਤਾਨੇ ਪਾਓ।';
      final p6 =
          'ਫ਼ਸਲ ਦੀ ਬਿਜਾਈ ਨੂੰ ਕਿੰਨੇ ਦਿਨ ਹੋਏ ਹਨ? ਕੀ ਪੱਤਿਆਂ ਹੇਠਾਂ ਚਿੱਟੀ ਮੱਖੀ ਦਿਖ ਰਹੀ ਹੈ? ਕਿਰਪਾ ਕਰਕੇ ਐਪ ਦੇ "AI ਸਕੈਨਰ" ਰਾਹੀਂ ਫੋਟੋ ਭੇਜੋ।';

      final fullText =
          '''### ੧. ਤੁਹਾਡੀ ਸਮੱਸਿਆ ਦੀ ਸਮਝ
$p1

### ੨. ਸੰਭਾਵਿਤ ਕਾਰਨ ਅਤੇ ਰੋਗ ਦੀ ਪਛਾਣ
$p2

### ੩. ਸਿਫਾਰਸ਼ ਕੀਤੇ ਉਪਾਅ (ਜੈਵਿਕ ਅਤੇ ਰਸਾਇਣਕ)
$p3

### ੪. ਸਮਾਂ ਅਤੇ ਕਦਮ-ਦਰ-ਕਦਮ ਛਿੜਕਾਅ
$p4

### ੫. ਸਾਵਧਾਨੀਆਂ ਅਤੇ ਸਹੀ ਖੁਰਾਕ (15 ਲੀਟਰ ਪੰਪ)
$p5

### ੬. ਹੋਰ ਲੋੜੀਂਦੀ ਜਾਣਕਾਰੀ
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'mr') {
      final p1 =
          'आपल्या $crop पिकामध्ये पाने पिवळी पडणे, किडींचा प्रादुर्भाव किंवा फुले गळणे ही समस्या समजून घेतली आहे.';
      final p2 =
          '$crop पिकामध्ये मुख्यत्वे गुलाबी बोंडअळी (Pink Bollworm), पांढरी माशी किंवा तुडतुडे आणि सूक्ष्म अन्नद्रव्यांची कमतरता हे मुख्य कारण असू शकते.';
      var p3 =
          '• जैविक नियंत्रण: एकरी ८-१० कामगंध सापळे लावा. निंबोळी अर्क ५% किंवा निम तेल (1500 ppm) ५० मिली प्रति पंप फवारणी करा.\n• रासायनिक नियंत्रण: इमामेक्टिन बेन्झोएट ५% एसजी किंवा क्लोरँट्रानिलीप्रोल १८.५% एससी ची फवारणी करा.';
      if (mentionsFertilizer) {
        p3 += '\n• खत व्यवस्थापन: १९:१९:१९ विद्राव्य खत ७५ ग्रॅम/पंप फवारा. जास्त युरियाचा वापर टाळा.';
      }
      final p4 =
          '१. फवारणी संध्याकाळच्या वेळी वारा शांत असताना करावी.\n२. किडींचा प्रादुर्भाव जास्त असल्यास १०-१२ दिवसांनी दुसरी फवारणी करा.\n३. जमिनीत पुरेसा ओलावा असणे आवश्यक आहे.';
      final p5 =
          '• प्रति पंप प्रमाण: १५ लिटर पाण्याच्या पंपासाठी इमामेक्टिन बेन्झोएट ५ ग्रॅम किंवा क्लोरँट्रानिलीप्रोल ६ मिली वापरा. जास्त प्रमाण वापरू नका.\n• दक्षता: फवारणी करताना मास्क आणि हातमोजे वापरा.';
      final p6 =
          'पिकाचे वय (पेरणीनंतरचे दिवस) किती आहे? पानांवर पांढरे डाग किंवा किडे दिसतात का? कृपया ॲपमधील "AI रोग स्कॅनर" द्वारे फोटो पाठवा.';

      final fullText =
          '''### १. आपल्या समस्येचे आकलन
$p1

### २. संभाव्य कारणे व रोग निदान
$p2

### ३. शिफारस केलेले उपाय (सेंद्रिय व रासायनिक)
$p3

### ४. वेळ आणि टप्प्याटप्प्याने फवारणी
$p4

### ५. खबरदारी आणि अचूक प्रमाण (१५ लिटर पंप)
$p5

### ६. अतिरिक्त आवश्यक माहिती
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else {
      // English & other scheduled language standard
      final p1 =
          'Understood your concern regarding leaf yellowing, pest attack, and flower dropping in your $crop field.';
      final p2 =
          'Likely causes include Pink Bollworm infestation, Sucking Pests (Whitefly/Thrips), or fungal root rot combined with micronutrient imbalance.';
      final p3 =
          '• Organic Action: Install 8-10 Pheromone Traps/acre. Spray 5% Neem Seed Kernel Extract (NSKE) or Neem Oil 1500ppm @ 50ml/pump.\n• Chemical Action: Spray Emamectin Benzoate 5% SG or Chlorantraniliprole 18.5% SC for caterpillar/bollworm control; Diafenthiuron 50% WP for whitefly.';
      final p4 =
          '1. Spray during evening hours when wind velocity is low.\n2. Repeat after 10-12 days if pest population remains above Economic Threshold Level (ETL).\n3. Ensure adequate soil moisture before spraying.';
      final p5 =
          '• Exact Dosage per 15-Litre Knapsack Pump: Dissolve 5g Emamectin Benzoate 5% SG or 6ml Chlorantraniliprole 18.5% SC. Do not overdose.\n• Safety: Wear gloves and mask. Avoid spraying against wind direction.';
      final p6 =
          'What is the current crop age (days after sowing)? Are leaves curling upwards or downwards? Share a photo via AI Camera Scan.';

      final fullText =
          '''### 1. Understanding Your Problem
$p1

### 2. Likely Causes & Diagnosis
$p2

### 3. Recommended Actions (Organic & Chemical)
$p3

### 4. Timing & Step-by-Step Application
$p4

### 5. Precautions & Exact Dosages (15L Pump)
$p5

### 6. Additional Information Needed
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    }
  }

  Map<String, dynamic> _buildFertilizerResponse(
    String crop,
    String langCode,
    Map<String, dynamic> grounding,
  ) {
    if (langCode == 'gu') {
      final p1 =
          '$crop પાક માટે સંતુલિત ખાતર વ્યવસ્થાપન અને પોષક તત્વોની જરૂરિયાત.';
      final p2 =
          'વધુ પડતો યુરિયા આપવાથી પાક વાનસ્પતિક વૃદ્ધિ કરે છે અને જીવાતોનો ઉપદ્રવ વધે છે; પોટાશ અને ફોસ્ફરસનો અભાવ દાણા/ઝીંડવા નબળા પાડે છે.';
      final p3 =
          '• વાવણી વખતે: ડીએપી (DAP) અથવા એનપીકે (NPK 12:32:16) નો પાયાનો ડોઝ આપો.\n• પૂર્તિ ખાતર: વાવણીના ૩૦ અને ૬૦ દિવસે યુરિયાના નાના હપ્તા સાથે ૧૯:૧૯:૧૯ અથવા ૦૦:૫૨:૩૪ નો સ્પ્રે કરો.';
      final p4 =
          '૧. ફૂલ બેસવાની અવસ્થાએ બોરોન ૨૦% (૨૦ ગ્રામ/૧૫ લિટર) નો સ્પ્રે કરવો.\n૨. દાણા/ઝીંડવા ભરાવાના સમયે ૦૦:૦૦:૫૦ (પોટેશિયમ સલ્ફેટ) ૭૫ ગ્રામ/પંપ આપવું.';
      final p5 =
          '• પંપ દીઠ સ્પ્રે પ્રમાણ: ૧૯:૧૯:૧૯ વોટર સોલ્યુબલ ખાતર ૭૫ ગ્રામ પ્રતિ ૧૫ લિટર પંપ.\n• સાવચેતી: બપોરના તડકામાં રાસાયણિક ખાતરનો સ્પ્રે ન કરવો. જમીનમાં પૂરતો ભેજ હોવો જોઈએ.';
      final p6 =
          'તમારી જમીનનો પ્રકાર કેવો છે (કાળી, ગોરાડુ કે રેતાળ)? છેલ્લે જમીન ચકાસણી (Soil Test) ક્યારે કરાવી હતી?';

      final fullText =
          '''### ૧. તમારી સમસ્યાની સમજ
$p1

### ૨. સંભવિત કારણો અને પોષક તત્વોનું વિશ્લેષણ
$p2

### ૩. ભલામણ કરેલ ખાતર વ્યવસ્થાપન
$p3

### ૪. સમય અને વિગતવાર હપ્તા
$p4

### ૫. સાવચેતી અને પંપ દીઠ ડોઝ (૧૫ લિટર)
$p5

### ૬. વધુ જરૂરી માહિતી
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'hi') {
      final p1 =
          '$crop की फसल के लिए संतुलित उर्वरक और पोषण प्रबंधन योजना।';
      final p2 =
          'अत्यधिक यूरिया के प्रयोग से वानस्पतिक वृद्धि अधिक होती है और रसचूसक कीट बढ़ते हैं; फॉस्फोरस व पोटाश की कमी से दाने/फल कमजोर रह जाते हैं।';
      final p3 =
          '• बुवाई के समय: डीएपी (DAP 50 किग्रा/एकड़) या एनपीके (NPK 12:32:16) का बेसल डोज दें।\n• पर्णीय पोषण: फसल की प्रारंभिक अवस्था में 19:19:19 घुलनशील खाद 75 ग्राम प्रति 15 लीटर पंप का छिड़काव करें।';
      final p4 =
          '१. फूल आने की अवस्था में: बोरॉन 20% (20 ग्राम/15 लीटर पंप) का छिड़काव करें ताकि फूल न झड़ें।\n२. दाना/फल भरते समय: 00:00:50 (पोटेशियम सल्फेट) 75 ग्राम/पंप दें।';
      final p5 =
          '• प्रति पंप मात्रा: 19:19:19 खाद 75 ग्राम प्रति 15 लीटर पंप। कॉपर कवकनाशी के साथ न मिलाएं।\n• सावधानी: दोपहर की तेज धूप में छिड़काव न करें। खेत में पर्याप्त नमी आवश्यक है।';
      final p6 =
          'आपकी मिट्टी का प्रकार कैसा है (काली, दोमट या बलुई)? क्या आपने हाल ही में मृदा परीक्षण (Soil Test) करवाया है?';

      final fullText =
          '''### १. आपकी समस्या की समझ
$p1

### २. पोषक तत्वों का विश्लेषण एवं कमी
$p2

### ३. अनुशंसित उर्वरक प्रबंधन
$p3

### ४. समय एवं चरणबद्ध खुराक
$p4

### ५. सावधानियां एवं सटीक खुराक (15 लीटर पंप)
$p5

### ६. अतिरिक्त आवश्यक जानकारी
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'pa') {
      final p1 =
          '$crop ਫ਼ਸਲ ਲਈ ਸੰਤੁਲਿਤ ਖਾਦ ਪ੍ਰਬੰਧਨ ਅਤੇ ਪੋਸ਼ਕ ਤੱਤਾਂ ਦੀ ਯੋਜਨਾ।';
      final p2 =
          'ਯੂਰੀਆ ਦੀ ਜ਼ਿਆਦਾ ਵਰਤੋਂ ਨਾਲ ਫ਼ਸਲ ਦਾ ਵਾਧਾ ਵੱਧ ਹੁੰਦਾ ਹੈ ਅਤੇ ਕੀੜੇ ਵੱਧਦੇ ਹਨ; ਫਾਸਫੋਰਸ ਅਤੇ ਪੋਟਾਸ਼ ਦੀ ਘਾਟ ਨਾਲ ਦਾਣੇ ਕਮਜ਼ੋਰ ਰਹਿ ਜਾਂਦੇ ਹਨ।';
      final p3 =
          '• ਬਿਜਾਈ ਸਮੇਂ: ਡੀਏਪੀ (DAP 50 ਕਿਲੋ/ਏਕੜ) ਜਾਂ ਐਨਪੀਕੇ (NPK 12:32:16) ਦੀ ਬੁਨਿਆਦੀ ਖੁਰਾਕ ਦਿਓ।\n• ਪੱਤਿਆਂ ਤੇ ਸਪਰੇਅ: ਫ਼ਸਲ ਦੇ ਵਾਧੇ ਸਮੇਂ 19:19:19 ਘੁਲਣਸ਼ੀਲ ਖਾਦ (75 ਗ੍ਰਾਮ/15 ਲੀਟਰ ਪੰਪ) ਦਾ ਛਿੜਕਾਅ ਕਰੋ।';
      final p4 =
          '੧. ਫੁੱਲ ਆਉਣ ਸਮੇਂ: ਬੋਰੋਨ 20% (20 ਗ੍ਰਾਮ/15L ਪੰਪ) ਦਾ ਛਿੜਕਾਅ ਕਰੋ ਤਾਂ ਜੋ ਫੁੱਲ ਨਾ ਝੜਨ।\n੨. ਦਾਣਾ/ਫਲ ਬਣਨ ਸਮੇਂ: 00:00:50 (ਪੋਟਾਸ਼ੀਅਮ ਸਲਫੇਟ) 75 ਗ੍ਰਾਮ/ਪੰਪ ਦਿਓ।';
      final p5 =
          '• ਪ੍ਰਤੀ ਪੰਪ ਖੁਰਾਕ: 19:19:19 ਪਾਣੀ ਵਿੱਚ ਘੁਲਣਸ਼ੀਲ ਖਾਦ 75 ਗ੍ਰਾਮ ਪ੍ਰਤੀ 15 ਲੀਟਰ ਪੰਪ।\n• ਸਾਵਧਾਨੀ: ਧੁੱਪ ਵਿੱਚ ਛਿੜਕਾਅ ਨਾ ਕਰੋ, ਜ਼ਮੀਨ ਵਿੱਚ ਸਹੀ ਨਮੀ ਹੋਣੀ ਚਾਹੀਦੀ ਹੈ।';
      final p6 =
          'ਤੁਹਾਡੀ ਜ਼ਮੀਨ ਕਿਸ ਤਰ੍ਹਾਂ ਦੀ ਹੈ (ਚੀਕਣੀ, ਰੇਤਲੀ ਜਾਂ ਦੋਮਟ)? ਕੀ ਤੁਸੀਂ ਇਸ ਵਾਰ ਦੇਸੀ ਰੂੜੀ ਖਾਦ ਪਾਈ ਸੀ?';

      final fullText =
          '''### ੧. ਤੁਹਾਡੀ ਸਮੱਸਿਆ ਦੀ ਸਮਝ
$p1

### ੨. ਪੋਸ਼ਕ ਤੱਤਾਂ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ
$p2

### ੩. ਸਿਫਾਰਸ਼ ਕੀਤਾ ਖਾਦ ਪ੍ਰਬੰਧਨ
$p3

### ੪. ਸਮਾਂ ਅਤੇ ਖੁਰਾਕ ਦੇ ਪੜਾਅ
$p4

### ੫. ਸਾਵਧਾਨੀਆਂ ਅਤੇ ਪ੍ਰਤੀ ਪੰਪ ਖੁਰਾਕ (15 ਲੀਟਰ)
$p5

### ੬. ਹੋਰ ਲੋੜੀਂਦੀ ਜਾਣਕਾਰੀ
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'mr') {
      final p1 =
          '$crop पिकासाठी संतुलित खत व्यवस्थापन आणि अन्नद्रव्यांची शिफारस.';
      final p2 =
          'युरियाचा अतिरेकी वापर पिकाची अनावश्यक वाढ करतो व रसशोषक किडी वाढतात; स्फुरद व पालाशच्या कमतरतेमुळे फळे व दाणे बारीक राहतात.';
      final p3 =
          '• पेरणीच्या वेळी: डीएपी (DAP ५० किलो/एकर) किंवा एनपीके (NPK 12:32:16) चा बेसल डोस द्या.\n• फवारणी खते: वाढीच्या अवस्थेत १९:१९:१९ विद्राव्य खत (७५ ग्रॅम/१५ लिटर पंप) फवारा.';
      final p4 =
          '१. फुलधारणेच्या अवस्थेत: बोरॉन २०% (२० ग्रॅम/१५ लिटर पंप) ची फवारणी करा.\n२. दाणे/फळे भरण्याच्या वेळी: ००:००:५० (पोटॅशियम सल्फेट) ७५ ग्रॅम/पंप द्या.';
      final p5 =
          '• प्रति पंप डोस: १९:१९:१९ खत ७५ ग्रॅम प्रति १५ लिटर पंप. कॉपर बुरशीनाशकासोबत मिसळू नका.\n• खबरदारी: जमिनीत पुरेशी ओल असतानाच खत व्यवस्थापन करा.';
      final p6 =
          'आपली जमीन कोणत्या प्रकारची आहे (काळी, पोयटा किंवा हलकी)? माती परीक्षण केले आहे का?';

      final fullText =
          '''### १. आपल्या समस्येचे आकलन
$p1

### २. अन्नद्रव्य विश्लेषण व कमतरता
$p2

### ३. शिफारस केलेले खत व्यवस्थापन
$p3

### ४. वेळ आणि टप्प्याटप्प्याने डोस
$p4

### ५. खबरदारी आणि अचूक प्रमाण (१५ लिटर पंप)
$p5

### ६. अतिरिक्त आवश्यक माहिती
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else {
      final p1 =
          'Optimal balanced fertilizer and nutrient schedule for your $crop crop.';
      final p2 =
          'Excess single-dose urea causes vegetative overgrowth and sucking pest surge; phosphorus/potash deficiency limits fruit/boll weight.';
      final p3 =
          '• Basal Dose: Apply DAP (50kg/acre) or NPK 12:32:16 with SSP.\n• Foliar Nutrition: Apply 19:19:19 (Water Soluble) @ 75g/15L pump at vegetative stage.';
      final p4 =
          '1. At flowering stage: Foliar spray of Boron 20% @ 20g/15L pump to prevent flower dropping.\n2. At boll/pod development: Spray 00:00:50 @ 75g/15L pump.';
      final p5 =
          '• Exact Dosage per 15L Pump: 19:19:19 NPK @ 75g/pump. Do not mix with copper fungicides.\n• Soil Precondition: Apply only when soil contains sufficient moisture.';
      final p6 =
          'What is your soil type? Have you applied Farm Yard Manure (FYM) or bio-fertilizers this season?';

      final fullText =
          '''### 1. Understanding Your Problem
$p1

### 2. Likely Causes & Nutrient Deficiencies
$p2

### 3. Recommended Fertilizer Schedule
$p3

### 4. Timing & Stage-Wise Application
$p4

### 5. Precautions & Exact Dosages (15L Pump)
$p5

### 6. Additional Information Needed
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    }
  }

  Map<String, dynamic> _buildPriceResponse(
    String crop,
    String langCode,
    Map<String, dynamic> grounding,
  ) {
    final mandiSummary =
        grounding['mandiSummary'] as String? ?? 'Rajkot APMC: ₹7,100/Quintal';
    if (langCode == 'gu') {
      final p1 = '$crop ના હાલના APMC બજાર ભાવ અને શ્રેષ્ઠ વેચાણ મથકની માહિતી.';
      final p2 =
          'આવક અને ગુણવત્તા (ભેજનું પ્રમાણ, લાલ-પીળો રંગ) ના આધારે વિવિધ મંડીઓમાં ભાવ તફાવત જોવા મળે છે.';
      final p3 =
          '• $mandiSummary\n• વેચાણ સલાહ: સુકવણી અને ગ્રેડિંગ કરીને વેચવાથી ક્વિન્ટલે ₹૨૦૦-૩૦૦ વધુ ભાવ મળી શકે છે.';
      final p4 =
          '૧. સવારે ૯ થી ૧૨ વાગ્યા વચ્ચે મંડીમાં હરાજી માટે પાક પહોંચાડવો.\n૨. ખેતચાચા એપમાં "APMC ભાવ સરખામણી" થી નજીકની ૩ મંડીઓના દૈનિક ભાવ ચકાસો.';
      final p5 =
          '• સાવચેતી: માલ તુલાવ્યા પછી અધિકૃત વજન પાવતી અને વેપારીનું લાયસન્સ અચૂક ચકાસવું.';
      final p6 =
          'તમારી પાસે કેટલો જથ્થો (ક્વિન્ટલ/મણ) તૈયાર છે? તમારો જિલ્લો અને તાલુકો જણાવો.';

      final fullText =
          '''### ૧. તમારી સમસ્યાની સમજ
$p1

### ૨. બજાર પરિસ્થિતિ અને ભાવ તફાવત
$p2

### ૩. ભલામણ કરેલ બજાર ભાવ અને મંડી
$p3

### ૪. સમય અને વેચાણ પગલાં
$p4

### ૫. વેચાણ સાવચેતી અને પાવતી નિયમો
$p5

### ૬. વધુ જરૂરી માહિતી
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'hi') {
      final p1 = '$crop के वर्तमान मंडी भाव और सर्वोत्तम बिक्री केंद्र की जानकारी।';
      final p2 =
          'दैनिक आवक और फसल की गुणवत्ता (नमी, दाने का आकार) के आधार पर विभिन्न मंडियों के भाव में अंतर होता है।';
      final p3 =
          '• $mandiSummary\n• बिक्री सलाह: उपज को सुखाकर और ग्रेडिंग करके बेचने से प्रति क्विंटल ₹200-300 अधिक दाम मिल सकते हैं।';
      final p4 =
          '१. सुबह 9 से 12 बजे के बीच मंडी में नीलामी के लिए माल पहुंचाएं।\n२. खेतचाचा ऐप में निकटतम 3 मंडियों के दैनिक भाव अवश्य जांचें।';
      final p5 =
          '• सावधानी: माल की तौल के बाद आधिकारिक वजन पर्ची और भुगतान रसीद अवश्य लें।';
      final p6 =
          'आपके पास कितना माल (क्विंटल) तैयार है? अपना जिला और तहसील बताएं।';

      final fullText =
          '''### १. आपकी समस्या की समझ
$p1

### २. बाजार की स्थिति एवं भाव अंतर
$p2

### ३. अनुशंसित बाजार भाव एवं मंडी
$p3

### ४. समय एवं बिक्री की रणनीति
$p4

### ५. मंडी में सावधानियां एवं रसीद
$p5

### ६. अतिरिक्त आवश्यक जानकारी
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'pa') {
      final p1 = '$crop ਦੇ ਮੌਜੂਦਾ ਮੰਡੀ ਭਾਅ ਅਤੇ ਵਿਕਰੀ ਕੇਂਦਰਾਂ ਦੀ ਜਾਣਕਾਰੀ।';
      final p2 =
          'ਮੰਡੀਆਂ ਵਿੱਚ ਆਮਦ ਅਤੇ ਨਮੀ ਦੇ ਹਿਸਾਬ ਨਾਲ ਭਾਅ ਵਿੱਚ ਅੰਤਰ ਆਉਂਦਾ ਹੈ।';
      final p3 =
          '• $mandiSummary\n• ਵਿਕਰੀ ਸਲਾਹ: ਫ਼ਸਲ ਨੂੰ ਚੰਗੀ ਤਰ੍ਹਾਂ ਸਾਫ਼ ਅਤੇ ਗਰੇਡ ਕਰਕੇ ਵੇਚਣ ਨਾਲ ਪ੍ਰਤੀ ਕੁਇੰਟਲ ਵੱਧ ਭਾਅ ਮਿਲਦਾ ਹੈ।';
      final p4 =
          '੧. ਸਵੇਰੇ ਸਮੇਂ ਮੰਡੀ ਵਿੱਚ ਬੋਲੀ ਲਈ ਫ਼ਸਲ ਲੈ ਕੇ ਜਾਓ।\n੨. ਖੇਤਚਾਚਾ ਐਪ ਵਿੱਚ ਨੇੜਲੀਆਂ ਮੰਡੀਆਂ ਦੇ ਰੋਜ਼ਾਨਾ ਭਾਅ ਚੈੱਕ ਕਰੋ।';
      final p5 =
          '• ਸਾਵਧਾਨੀ: ਤੁਲਾਈ ਤੋਂ ਬਾਅਦ ਕੰਪਿਊਟਰਾਈਜ਼ਡ ਪਰਚੀ ਅਤੇ ਸਰਕਾਰੀ ਦਸਤਾਵੇਜ਼ ਜ਼ਰੂਰ ਲਵੋ।';
      final p6 =
          'ਤੁਹਾਡੇ ਕੋਲ ਕਿੰਨੀ ਉਪਜ (ਕੁਇੰਟਲ) ਤਿਆਰ ਹੈ? ਤੁਹਾਡਾ ਜ਼ਿਲ੍ਹਾ ਕਿਹੜਾ ਹੈ?';

      final fullText =
          '''### ੧. ਤੁਹਾਡੀ ਸਮੱਸਿਆ ਦੀ ਸਮਝ
$p1

### ੨. ਮੰਡੀ ਹਾਲਾਤ ਅਤੇ ਭਾਅ
$p2

### ੩. ਸਿਫਾਰਸ਼ ਕੀਤੇ ਮੰਡੀ ਭਾਅ
$p3

### ੪. ਸਮਾਂ ਅਤੇ ਵਿਕਰੀ ਦੇ ਕਦਮ
$p4

### ੫. ਮੰਡੀ ਸਾਵਧਾਨੀਆਂ
$p5

### ੬. ਹੋਰ ਲੋੜੀਂਦੀ ਜਾਣਕਾਰੀ
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else if (langCode == 'mr') {
      final p1 = '$crop चे चालू बाजारभाव आणि नजीकच्या कृषी उत्पन्न बाजार समितीची (APMC) माहिती.';
      final p2 =
          'बाजार समितीतील आवक आणि मालाचा दर्जा (ओलावा, प्रतवारी) यानुसार भावात चढ-उतार होतो.';
      final p3 =
          '• $mandiSummary\n• विक्री सल्ला: प्रतवारी व स्वच्छता करून माल विकल्यास प्रतिक्विंटल ₹२००-३०० अधिक दर मिळू शकतो.';
      final p4 =
          '१. सकाळी लिलावाच्या वेळी शेतमाल बाजारात पोहोचवा.\n२. खेतचाचा ॲपमध्ये नजीकच्या ३ बाजार समित्यांचे आजचे दर तपासा.';
      final p5 =
          '• खबरदारी: इलेक्ट्रॉनिक वजन पावती आणि अधिकृत अडत पावती नक्की तपासा.';
      final p6 =
          'आपल्याकडे किती क्विंटल माल तयार आहे? आपला जिल्हा व तालुका कोणता?';

      final fullText =
          '''### १. आपल्या समस्येचे आकलन
$p1

### २. बाजारपेठ स्थिती व भाव फरक
$p2

### ३. शिफारस केलेले बाजारभाव
$p3

### ४. वेळ आणि विक्री धोरण
$p4

### ५. बाजार खबरदारी आणि पावती
$p5

### ६. अतिरिक्त आवश्यक माहिती
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    } else {
      final p1 =
          'Market rate comparison and best selling Mandi hubs for $crop.';
      final p2 =
          'Price variations depend on daily arrivals, moisture percentage, and staple length/grade.';
      final p3 =
          '• $mandiSummary\n• Recommendation: Clean and grade your produce before transport to earn premium modal rates.';
      final p4 =
          '1. Check real-time Mandi directory on KhetChaCha before loading vehicle.\n2. Participate in regulated APMC e-NAM auctions for transparent payment.';
      final p5 =
          '• Precautions: Always obtain computerized weight slip and official APMC settlement voucher.';
      final p6 =
          'What is your harvest volume in Quintals and your nearest transport hub?';

      final fullText =
          '''### 1. Understanding Your Problem
$p1

### 2. Market Dynamics & Price Variance
$p2

### 3. Recommended Mandi Prices & Options
$p3

### 4. Timing & Transport Strategy
$p4

### 5. Precautions & APMC Documentation
$p5

### 6. Additional Information Needed
$p6''';

      return {
        'text': fullText,
        'sections': {
          'problemUnderstanding': p1,
          'likelyCauses': p2,
          'recommendedActions': p3,
          'timingAndSteps': p4,
          'precautionsAndDosages': p5,
          'additionalInfoNeeded': p6,
        },
      };
    }
  }

  /// Parses Markdown output into the 6 structured sections
  Map<String, String> parseStructuredSections(String text, String langCode) {
    final Map<String, String> sections = {};
    final lines = text.split('\n');

    String currentKey = 'problemUnderstanding';
    final StringBuffer currentBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') ||
          trimmed.contains('૧.') ||
          trimmed.contains('1.')) {
        if (trimmed.contains('૧.') ||
            trimmed.contains('1.') ||
            trimmed.toLowerCase().contains('understanding')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'problemUnderstanding';
          currentBuffer.clear();
          continue;
        } else if (trimmed.contains('૨.') ||
            trimmed.contains('2.') ||
            trimmed.toLowerCase().contains('cause') ||
            trimmed.toLowerCase().contains('diagnosis')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'likelyCauses';
          currentBuffer.clear();
          continue;
        } else if (trimmed.contains('૩.') ||
            trimmed.contains('3.') ||
            trimmed.toLowerCase().contains('action') ||
            trimmed.toLowerCase().contains('remed')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'recommendedActions';
          currentBuffer.clear();
          continue;
        } else if (trimmed.contains('૪.') ||
            trimmed.contains('4.') ||
            trimmed.toLowerCase().contains('step') ||
            trimmed.toLowerCase().contains('timing')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'timingAndSteps';
          currentBuffer.clear();
          continue;
        } else if (trimmed.contains('૫.') ||
            trimmed.contains('5.') ||
            trimmed.toLowerCase().contains('precaut') ||
            trimmed.toLowerCase().contains('dosag')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'precautionsAndDosages';
          currentBuffer.clear();
          continue;
        } else if (trimmed.contains('૬.') ||
            trimmed.contains('6.') ||
            trimmed.toLowerCase().contains('additional') ||
            trimmed.toLowerCase().contains('info')) {
          if (currentBuffer.isNotEmpty) {
            sections[currentKey] = currentBuffer.toString().trim();
          }
          currentKey = 'additionalInfoNeeded';
          currentBuffer.clear();
          continue;
        }
      }
      currentBuffer.writeln(line);
    }

    if (currentBuffer.isNotEmpty) {
      sections[currentKey] = currentBuffer.toString().trim();
    }

    return sections;
  }
}
