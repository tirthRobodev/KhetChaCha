import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/ai_chat_models.dart';
import 'ai_chat_api_service.dart';

/// Single item in the 32-record temporary Q&A dataset.
class TemporaryQARecord {
  final String id;
  final String language;
  final String languageName;
  final String difficulty;
  final String question;
  final String answer;
  final List<String> sourceReferences;
  final bool verified;
  final String createdFor;

  const TemporaryQARecord({
    required this.id,
    required this.language,
    required this.languageName,
    required this.difficulty,
    required this.question,
    required this.answer,
    this.sourceReferences = const [],
    this.verified = false,
    this.createdFor = 'temporary_demo',
  });

  factory TemporaryQARecord.fromJson(Map<String, dynamic> json) {
    return TemporaryQARecord(
      id: json['id'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      languageName: json['language_name'] as String? ?? 'English',
      difficulty: json['difficulty'] as String? ?? 'medium',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sourceReferences:
          (json['source_references'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      verified: json['verified'] as bool? ?? false,
      createdFor: json['created_for'] as String? ?? 'temporary_demo',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'language': language,
    'language_name': languageName,
    'difficulty': difficulty,
    'question': question,
    'answer': answer,
    'source_references': sourceReferences,
    'verified': verified,
    'created_for': createdFor,
  };
}

/// Unified Result returned by TemporaryAgricultureQAService.
class QAResult {
  final bool matchedTemporary;
  final TemporaryQARecord? record;
  final FarmerChatApiResponse response;
  final double confidence;
  final String source; // 'temporary_qa' or 'live_ai'

  const QAResult({
    required this.matchedTemporary,
    required this.response,
    this.record,
    this.confidence = 1.0,
    required this.source,
  });
}

/// One Shared Lookup Service for both Text queries and real Speech-to-Text (STT) queries.
///
/// Features:
/// - Strictly 32 records loaded once into memory (from assets/temporary_qa/questions_answers.json).
/// - Exact language distribution: Gujarati: 7, Hindi: 7, English: 6, Punjabi: 3, Marathi: 3, Telugu: 3, Bengali: 3.
/// - Text & STT submit to the exact same [answerQuestion] entrypoint.
/// - Normalization: Unicode-safe NFC trim, punctuation removal, case folding.
/// - Constrained matching: language-aware lookup with safety checks against weak/unrelated matches.
/// - When uncertain or when temporary mode is disabled, falls back cleanly to the permanent AI backend.
class TemporaryAgricultureQAService {
  TemporaryAgricultureQAService._internal();
  static final TemporaryAgricultureQAService instance =
      TemporaryAgricultureQAService._internal();

  bool isEnabled = true;
  final String version = 'demo-1';
  bool _isLoaded = false;

  final List<TemporaryQARecord> _records = [];
  final Map<String, TemporaryQARecord> _normalizedIndex = {};

  /// Expose unmodifiable view of loaded records for verification tests.
  List<TemporaryQARecord> get records => List.unmodifiable(_records);

  /// Toggle temporary QA mode at runtime.
  void setEnabled(bool enabled) {
    isEnabled = enabled;
  }

  /// Initialize and load the 32 records into memory once.
  Future<void> initialize({String? customJsonString}) async {
    if (_isLoaded && customJsonString == null) return;

    try {
      String jsonStr;
      if (customJsonString != null) {
        jsonStr = customJsonString;
      } else {
        jsonStr = await rootBundle.loadString(
          'temporary_qa/questions_answers.json',
        );
      }

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final List rawList = decoded['records'] as List? ?? [];

      _records.clear();
      _normalizedIndex.clear();

      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final record = TemporaryQARecord.fromJson(item);
          _records.add(record);
          final normQ = normalizeText(record.question);
          _normalizedIndex['${record.language}:$normQ'] = record;
        }
      }

      _isLoaded = true;
      debugPrint(
        '[TemporaryAgricultureQAService] Initialized with ${_records.length} records.',
      );
    } catch (e) {
      debugPrint('[TemporaryAgricultureQAService] Failed to load JSON: $e');
    }
  }

  /// Manually inject records for testing without Flutter bundle.
  void loadRecordsDirectly(List<TemporaryQARecord> recordsList) {
    _records.clear();
    _normalizedIndex.clear();
    for (final r in recordsList) {
      _records.add(r);
      _normalizedIndex['${r.language}:${normalizeText(r.question)}'] = r;
    }
    _isLoaded = true;
  }

  /// Unicode-safe normalization: strips punctuation, spaces, converts to lowercase.
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '')
        .trim();
  }

  /// Primary shared method called by BOTH Text Controller AND STT microphone.
  Future<QAResult> answerQuestion(
    String originalText, {
    String? selectedLanguage,
    FarmerChatApiRequest? originalRequest,
  }) async {
    final queryText = originalText.trim();
    if (queryText.isEmpty) {
      return QAResult(
        matchedTemporary: false,
        source: 'error',
        response: FarmerChatApiResponse.error(
          userFriendlyMessage: 'Please ask a farming question.',
          language: selectedLanguage ?? 'en',
        ),
      );
    }

    if (!_isLoaded) {
      await initialize();
    }

    // If temporary mode is disabled, immediately forward to live AI backend
    if (!isEnabled) {
      return _fallbackToLiveAi(queryText, selectedLanguage, originalRequest);
    }

    final normQuery = normalizeText(queryText);

    // 1. Exact Normalized Match within selected language (Fast Path)
    if (selectedLanguage != null && selectedLanguage.isNotEmpty) {
      final key = '$selectedLanguage:$normQuery';
      if (_normalizedIndex.containsKey(key)) {
        final rec = _normalizedIndex[key]!;
        return _buildQAResult(rec, 1.0);
      }
    }

    // 2. Exact Normalized Match across all 32 records
    for (final rec in _records) {
      final normRecQ = normalizeText(rec.question);
      if (normRecQ == normQuery) {
        return _buildQAResult(rec, 1.0);
      }
    }

    // 3. Constrained Keyword/Token Similarity within the same language
    TemporaryQARecord? bestMatch;
    double highestScore = 0.0;

    for (final rec in _records) {
      // Disallow cross-language mismatched answers
      if (selectedLanguage != null &&
          selectedLanguage.isNotEmpty &&
          rec.language != selectedLanguage) {
        continue;
      }

      final score = _calculateMatchScore(queryText, rec.question);
      if (score > highestScore) {
        highestScore = score;
        bestMatch = rec;
      }
    }

    // Threshold of 0.70 required to prevent weak/unrelated matches
    if (bestMatch != null && highestScore >= 0.70) {
      return _buildQAResult(bestMatch, highestScore);
    }

    // 4. Fallback to Live Permanent AI Backend
    return _fallbackToLiveAi(queryText, selectedLanguage, originalRequest);
  }

  /// Calculates word/token overlap similarity score (0.0 to 1.0).
  double _calculateMatchScore(String query, String candidate) {
    final qTokens = query
        .toLowerCase()
        .split(RegExp(r'[\s\p{P}]+', unicode: true))
        .where((t) => t.length > 1)
        .toSet();
    final cTokens = candidate
        .toLowerCase()
        .split(RegExp(r'[\s\p{P}]+', unicode: true))
        .where((t) => t.length > 1)
        .toSet();

    if (qTokens.isEmpty || cTokens.isEmpty) return 0.0;

    final intersection = qTokens.intersection(cTokens).length;
    final union = qTokens.union(cTokens).length;
    if (union == 0) return 0.0;

    return intersection / union;
  }

  /// Convert matched TemporaryQARecord into standard FarmerChatApiResponse.
  QAResult _buildQAResult(TemporaryQARecord rec, double confidence) {
    final response = FarmerChatApiResponse(
      success: true,
      language: rec.language,
      languageName: rec.languageName,
      answer: rec.answer,
      detailedExplanation: rec.answer,
      actionSteps: const [],
      safetyPrecautions: const [],
      confidenceScore: confidence,
      searchStrategyUsed: 'temporary_qa_demo',
      requiresPhoto: false,
      isError: false,
    );

    return QAResult(
      matchedTemporary: true,
      record: rec,
      confidence: confidence,
      source: 'temporary_qa',
      response: response,
    );
  }

  /// Forwards query to the live Python AI Engine.
  Future<QAResult> _fallbackToLiveAi(
    String query,
    String? language,
    FarmerChatApiRequest? originalRequest,
  ) async {
    final req =
        originalRequest ??
        FarmerChatApiRequest(question: query, language: language ?? 'gu');

    final apiResponse = await AiChatApiService.instance.sendFarmerQuery(req);
    return QAResult(
      matchedTemporary: false,
      confidence: apiResponse.confidenceScore,
      source: 'live_ai',
      response: apiResponse,
    );
  }
}
