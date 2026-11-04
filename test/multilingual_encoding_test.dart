// Regression tests for multilingual UTF-8 encoding in KhetChacha Flutter client.
//
// Verifies:
// 1. AI chat API service decodes UTF-8 response bytes correctly.
// 2. Gujarati, Hindi, Punjabi and Tamil text survives JSON decode -> model -> UI.
// 3. TTS text field (derived from answer) is clean Unicode.
// 4. Latin-1 corruption pattern 'àª' never appears in decoded responses.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khetchacha/models/ai_chat_models.dart';
import 'package:khetchacha/services/ai_chat_api_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns raw UTF-8 bytes for the given [data] encoded as a JSON response body.
List<int> _jsonUtf8Bytes(Map<String, dynamic> data) {
  final jsonStr = jsonEncode(data);
  return utf8.encode(jsonStr);
}

/// Creates a mock HTTP client that returns the given [bodyBytes] with the
/// provided [contentType] header.
http.Client _mockClient(
  List<int> bodyBytes, {
  String contentType = 'application/json; charset=utf-8',
  int statusCode = 200,
}) {
  return MockClient((request) async {
    return http.Response.bytes(
      bodyBytes,
      statusCode,
      headers: {'content-type': contentType},
    );
  });
}

/// Gujarati text as it appears in the Gemini API response (clean Unicode).
const _gujaratiAnswer =
    'કૃષિ AI સલાહ: કપાસમાં ગુલાબી ઈયળ (Pink Bollworm) ના ઉપદ્રવ માટે ક્લોરાન્ટ્રાનિલિપ્રોલ 18.5% SC વાપરો.';
const _gujaratiActionStep = 'ખેતરનું નિયમિત નિરીક્ષણ કરો.';
const _gujaratiPrecaution = 'દવા છાંટતી વખતે માસ્ક અને મોજા પહેરો.';

const _hindiAnswer =
    'कृषि AI सलाह: कपास में गुलाबी बोलवर्म के लिए क्लोरेंट्रानिलिप्रोल का प्रयोग करें।';
const _punjabiAnswer =
    'ਕ੍ਰਿਸ਼ੀ AI ਸਲਾਹ: ਕਪਾਹ ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ ਲਈ ਕਲੋਰਾਂਟ੍ਰਾਨਿਲਿਪ੍ਰੋਲ ਦੀ ਵਰਤੋਂ ਕਰੋ।';
const _tamilAnswer =
    'விவசாய AI ஆலோசனை: பருத்தியில் இளஞ்சிவப்பு புழு தாக்குதலுக்கு குளோரான்ட்ரானிலிப்ரோல் பயன்படுத்தவும்.';

/// The Latin-1 misread of Gujarati bytes — must NEVER appear in decoded output.
const _gujaratiCorruption = 'àª';

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  late AiChatApiService svc;

  setUp(() {
    svc = AiChatApiService.instance;
    svc.setPhysicalAndroidDevice(false); // Use emulator URL in tests
  });

  // -------------------------------------------------------------------------
  // 1. Gujarati UTF-8 round-trip
  // -------------------------------------------------------------------------
  group('Gujarati UTF-8 encoding', () {
    test('Gujarati answer survives HTTP bodyBytes -> utf8.decode -> jsonDecode -> model', () async {
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'gu',
        'language_name': 'Gujarati',
        'answer': _gujaratiAnswer,
        'short_answer': _gujaratiAnswer,
        'detailed_explanation': _gujaratiAnswer,
        'action_steps': [_gujaratiActionStep],
        'safety_precautions': [_gujaratiPrecaution],
        'sources': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(
        question: 'કપાસમાં ગુલાબી ઈયળ',
        language: 'gu',
      );
      final res = await svc.sendFarmerQuery(req);

      expect(res.success, isTrue, reason: 'Response should succeed');
      expect(
        res.answer,
        equals(_gujaratiAnswer),
        reason: 'Gujarati answer must not be corrupted',
      );
      expect(
        res.answer,
        isNot(contains(_gujaratiCorruption)),
        reason: 'Latin-1 corruption pattern must not appear',
      );
      expect(
        res.actionSteps,
        contains(_gujaratiActionStep),
        reason: 'Gujarati action step must be intact',
      );
    });

    test('Gujarati answer (used for TTS) has no Latin-1 corruption', () async {
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'gu',
        'language_name': 'Gujarati',
        'answer': _gujaratiAnswer,
        'short_answer': _gujaratiAnswer,
        'sources': [],
        'action_steps': [],
        'safety_precautions': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(question: 'ખેડૂત', language: 'gu');
      final res = await svc.sendFarmerQuery(req);

      // TTS is derived from answer
      expect(
        res.answer,
        isNot(contains(_gujaratiCorruption)),
        reason: 'TTS source (answer) must have clean Gujarati Unicode',
      );
    });

    test(
      'Gujarati decoding works even without charset in Content-Type header',
      () async {
        final bodyBytes = _jsonUtf8Bytes({
          'success': true,
          'language': 'gu',
          'language_name': 'Gujarati',
          'answer': _gujaratiAnswer,
          'short_answer': _gujaratiAnswer,
          'sources': [],
          'action_steps': [],
          'safety_precautions': [],
          'confidence_score': 0.9,
          'source_type': 'local_pdf',
          'search_strategy_used': 'local_only',
          'requires_photo': false,
          'needs_more_information': false,
        });

        // No charset in header — service must still decode correctly via utf8.decode(bodyBytes)
        svc.setHttpClientForTesting(
          _mockClient(bodyBytes, contentType: 'application/json'),
        );

        final req = FarmerChatApiRequest(question: 'ટેસ્ટ', language: 'gu');
        final res = await svc.sendFarmerQuery(req);

        expect(
          res.answer,
          equals(_gujaratiAnswer),
          reason: 'Must decode UTF-8 correctly even without charset header',
        );
        expect(res.answer, isNot(contains(_gujaratiCorruption)));
      },
    );
  });

  // -------------------------------------------------------------------------
  // 2. Hindi UTF-8 round-trip
  // -------------------------------------------------------------------------
  group('Hindi UTF-8 encoding', () {
    test('Hindi Devanagari answer is decoded without corruption', () async {
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'hi',
        'language_name': 'Hindi',
        'answer': _hindiAnswer,
        'short_answer': _hindiAnswer,
        'sources': [],
        'action_steps': ['खेत में जलभराव न होने दें।'],
        'safety_precautions': ['दस्ताने और मास्क का प्रयोग करें।'],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(question: 'कपास रोग', language: 'hi');
      final res = await svc.sendFarmerQuery(req);

      expect(
        res.answer,
        equals(_hindiAnswer),
        reason: 'Hindi Devanagari must not be corrupted',
      );
      expect(
        res.answer,
        isNot(contains('à¤')),
        reason: 'Hindi Latin-1 corruption must not appear',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 3. Punjabi UTF-8 round-trip
  // -------------------------------------------------------------------------
  group('Punjabi UTF-8 encoding', () {
    test('Punjabi Gurmukhi answer is decoded without corruption', () async {
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'pa',
        'language_name': 'Punjabi',
        'answer': _punjabiAnswer,
        'short_answer': _punjabiAnswer,
        'sources': [],
        'action_steps': [],
        'safety_precautions': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(question: 'ਕਪਾਹ ਰੋਗ', language: 'pa');
      final res = await svc.sendFarmerQuery(req);

      expect(
        res.answer,
        equals(_punjabiAnswer),
        reason: 'Punjabi Gurmukhi must not be corrupted',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 4. Tamil UTF-8 round-trip
  // -------------------------------------------------------------------------
  group('Tamil UTF-8 encoding', () {
    test('Tamil script answer is decoded without corruption', () async {
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'ta',
        'language_name': 'Tamil',
        'answer': _tamilAnswer,
        'short_answer': _tamilAnswer,
        'sources': [],
        'action_steps': [],
        'safety_precautions': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(
        question: 'பருத்தி நோய்',
        language: 'ta',
      );
      final res = await svc.sendFarmerQuery(req);

      expect(
        res.answer,
        equals(_tamilAnswer),
        reason: 'Tamil script must not be corrupted',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 5. utf8.decode(bodyBytes) is used
  // -------------------------------------------------------------------------
  group('HTTP body decoding method', () {
    test('Service uses utf8.decode(bodyBytes) for JSON parsing', () async {
      const gujaratiChar = 'ક'; // U+0A95
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'gu',
        'language_name': 'Gujarati',
        'answer': gujaratiChar,
        'short_answer': gujaratiChar,
        'sources': [],
        'action_steps': [],
        'safety_precautions': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(question: 'ક', language: 'gu');
      final res = await svc.sendFarmerQuery(req);

      expect(
        res.answer,
        equals(gujaratiChar),
        reason: 'Single Gujarati char U+0A95 must decode to ક, not àª...',
      );
      expect(
        res.answer,
        isNot(equals('àª\u0095')),
        reason: 'Latin-1 misread of Gujarati UTF-8 bytes must not appear',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 6. Detailed explanation encoding
  // -------------------------------------------------------------------------
  group('Detailed explanation encoding', () {
    test('Gujarati detailed_explanation is clean Unicode', () async {
      const detail =
          'કપાસમાં ગુલાબી ઈયળ (Pectinophora gossypiella) : ૧. ફૂલ ખરી પડે. ૨. ૧ ટ્રૅપ / હેક્ટર.';
      final bodyBytes = _jsonUtf8Bytes({
        'success': true,
        'language': 'gu',
        'language_name': 'Gujarati',
        'answer': _gujaratiAnswer,
        'short_answer': _gujaratiAnswer,
        'detailed_explanation': detail,
        'sources': [],
        'action_steps': [],
        'safety_precautions': [],
        'confidence_score': 0.9,
        'source_type': 'local_pdf',
        'search_strategy_used': 'local_only',
        'requires_photo': false,
        'needs_more_information': false,
      });

      svc.setHttpClientForTesting(_mockClient(bodyBytes));

      final req = FarmerChatApiRequest(question: 'ટેસ્ટ', language: 'gu');
      final res = await svc.sendFarmerQuery(req);

      expect(
        res.detailedExplanation,
        equals(detail),
        reason: 'Gujarati detailed_explanation must not be corrupted',
      );
      expect(res.detailedExplanation, isNot(contains(_gujaratiCorruption)));
    });
  });
}
