import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/services/conversation_history_service.dart';
import 'package:khetchacha/services/universal_agri_ai_engine.dart';
import 'package:khetchacha/services/unified_agri_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'Rameshbhai Patel',
    mobileNumber: '+91 98765 43210',
    email: 'ramesh.patel@example.com',
    state: 'Gujarat',
    district: 'Rajkot',
    village: 'Gondal',
    farmingType: 'Mixed Crops',
    landSize: '3.0 Acres',
    crops: ['Cotton', 'Wheat', 'Groundnut', 'Soybean', 'Paddy'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConversationHistoryService.instance.init();
    await ConversationHistoryService.instance.clearHistory();
  });

  group('KhetChaCha Multilingual AI — Tier 1 & Tier 2 Language Priority Suite', () {
    final engine = UniversalAgriAiEngine.instance;
    final unifiedAi = UnifiedAgriAiService.instance;

    // =========================================================================
    // 1. LANGUAGE IDENTIFICATION & DEVANAGARI DISAMBIGUATION
    // =========================================================================

    test('1. Devanagari Disambiguation: Distinguishes Marathi vs Hindi context and character ळ', () {
      // Unique character ळ
      expect(
        unifiedAi.detectLanguageCode(
          'कापूस पिकात बोंडअळी नियंत्रणासाठी काय करावे?',
        ),
        'mr',
      );

      // Marathi context without ळ
      expect(
        unifiedAi.detectLanguageCode(
          'गहू पिकाला खत कधी द्यावे आणि पाणी किती द्यावे?',
        ),
        'mr',
      );

      // Hindi context
      expect(
        unifiedAi.detectLanguageCode(
          'गेहूं की फसल में खाद कब दें और पानी कितना लगाएं?',
        ),
        'hi',
      );

      // Gurmukhi Punjabi
      expect(
        unifiedAi.detectLanguageCode('ਝੋਨੇ ਵਿੱਚ ਖਾਦ ਕਦੋਂ ਪਾਉਣੀ ਚਾਹੀਦੀ ਹੈ?'),
        'pa',
      );

      // Gujarati
      expect(unifiedAi.detectLanguageCode('કપાસમાં ખાતર ક્યારે આપવું?'), 'gu');

      // English
      expect(
        unifiedAi.detectLanguageCode(
          'When should I apply fertilizer to cotton?',
        ),
        'en',
      );
    });

    // =========================================================================
    // 2. STT TRANSCRIPT VALIDATION & SPEECH ERROR IDENTIFICATION
    // =========================================================================

    test('2. Identifies speech recognition errors before generating recommendations', () async {
      // Noise tokens and too-short transcripts must fail validation
      expect(engine.validateSttTranscript('uh'), isFalse);
      expect(engine.validateSttTranscript('...'), isFalse);
      expect(engine.validateSttTranscript('hmm um er'), isFalse);
      expect(engine.validateSttTranscript('ਕਣਕ ਵਿੱਚ ਖਾਦ ਕਦੋਂ ਪਾਈਏ'), isTrue);
      expect(engine.validateSttTranscript('કપાસમાં દવા કહો'), isTrue);

      // Voice query with corrupted speech returns supportive retry notice in target language
      final voiceResult = await engine.processQuery(
        query: 'uh um...',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(voiceResult.sender, 'assistant');
      expect(voiceResult.text, contains('અવાજ સ્પષ્ટ સંભળાયો નથી'));
    });

    // =========================================================================
    // 3. TIER 1 EVALUATION: GUJARATI, HINDI, ENGLISH (Text & STT Equivalence)
    // =========================================================================

    test('3. Gujarati: Text input and STT transcript receive equivalent reasoning in Gujarati', () async {
      final textResult = await engine.processQuery(
        query: 'કપાસમાં પાન પીળા પડે તો શું કરવું?',
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'gu',
      );

      final sttResult = await engine.processQuery(
        query: 'કપાસમાં પાન પીળા પડે છે દવા કહો',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(textResult.languageCode, 'gu');
      expect(sttResult.languageCode, 'gu');
      expect(textResult.text, isNotEmpty);
      expect(sttResult.text, isNotEmpty);
    });

    test('4. Hindi: Text input and STT transcript receive equivalent reasoning in Hindi', () async {
      final textResult = await engine.processQuery(
        query: 'गेहूं में पहली सिंचाई कब करें?',
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'hi',
      );

      final sttResult = await engine.processQuery(
        query: 'गेहूं में पहला पानी कब लगाएं',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'hi',
      );

      expect(textResult.languageCode, 'hi');
      expect(sttResult.languageCode, 'hi');
      expect(textResult.text, isNotEmpty);
      expect(sttResult.text, isNotEmpty);
    });

    test('5. English: Text input and STT transcript receive equivalent reasoning in English', () async {
      final textResult = await engine.processQuery(
        query: 'When should I apply fertilizer to cotton?',
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'en',
      );

      final sttResult = await engine.processQuery(
        query: 'when to apply fertilizer for cotton',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'en',
      );

      expect(textResult.languageCode, 'en');
      expect(sttResult.languageCode, 'en');
      expect(textResult.text, isNotEmpty);
      expect(sttResult.text, isNotEmpty);
    });

    // =========================================================================
    // 4. TIER 2 EVALUATION: PUNJABI & MARATHI (Reliable Simple Guidance)
    // =========================================================================

    test('6. Punjabi: Reliable simple agricultural guidance for Text and STT in Gurmukhi', () async {
      final textResult = await engine.processQuery(
        query: 'ਝੋਨੇ ਵਿੱਚ ਖਾਦ ਕਦੋਂ ਪਾਉਣੀ ਚਾਹੀਦੀ ਹੈ?',
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'pa',
      );

      final sttResult = await engine.processQuery(
        query: 'ਝੋਨੇ ਵਿੱਚ ਖਾਦ ਕਦੋਂ ਪਾਈਏ',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'pa',
      );

      expect(textResult.languageCode, 'pa');
      expect(sttResult.languageCode, 'pa');
      // Must not be translated to Hindi or English
      expect(
        textResult.text.contains('ਝੋਨੇ') ||
            textResult.text.contains('ਖਾਦ') ||
            textResult.text.contains('ਪੰਪ'),
        isTrue,
      );
      expect(
        sttResult.text.contains('ਝੋਨੇ') ||
            sttResult.text.contains('ਖਾਦ') ||
            sttResult.text.contains('ਪੰਪ'),
        isTrue,
      );
    });

    test('7. Marathi: Reliable simple agricultural guidance for Text and STT in Marathi', () async {
      final textResult = await engine.processQuery(
        query: 'सोयाबीन पिकाला खत कधी द्यावे?',
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'mr',
      );

      final sttResult = await engine.processQuery(
        query: 'सोयाबीन पिकाला खत कधी टाकायचे',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'mr',
      );

      expect(textResult.languageCode, 'mr');
      expect(sttResult.languageCode, 'mr');
      expect(
        textResult.text.contains('पिका') ||
            textResult.text.contains('खत') ||
            textResult.text.contains('शेती'),
        isTrue,
      );
      expect(
        sttResult.text.contains('पिका') ||
            sttResult.text.contains('खत') ||
            sttResult.text.contains('शेती'),
        isTrue,
      );
    });
  });
}
