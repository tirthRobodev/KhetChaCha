import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/models/ai_conversation_message.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/services/conversation_history_service.dart';
import 'package:khetchacha/services/unified_agri_ai_service.dart';
import 'package:khetchacha/services/voice_assistant_service.dart';
import 'package:khetchacha/screens/ai/voice_assistant_page.dart';
import 'package:khetchacha/screens/quick_access/ask_khet_chacha_ai_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyProfile = FarmerProfile(
    fullName: 'Rameshbhai Patel',
    mobileNumber: '+91 98765 43210',
    email: 'ramesh.patel@example.com',
    state: 'Gujarat',
    district: 'Rajkot',
    village: 'Gondal',
    farmingType: 'Organic & Traditional',
    landSize: '8.5 Acres',
    crops: ['Cotton', 'Groundnut', 'Wheat'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConversationHistoryService.instance.init();
    await ConversationHistoryService.instance.clearHistory();
  });

  group(
    'Phase 3 — 22 Indian Scheduled Languages & Code-Mixed Detection Tests',
    () {
      final aiService = UnifiedAgriAiService.instance;

      test('Detects Gujarati Script accurately', () {
        final code = aiService.detectLanguageCode(
          'કપાસમાં ગુલાબી ઈયળ માટે શું કરવું?',
        );
        expect(code, 'gu');
      });

      test('Detects Hindi Script accurately', () {
        final code = aiService.detectLanguageCode(
          'गेहूं में पीली कुंगी के लिए कौन सी दवा डालें?',
        );
        expect(code, 'hi');
      });

      test('Detects Gurmukhi (Punjabi) Script accurately', () {
        final code = aiService.detectLanguageCode(
          'ਝੋਨੇ ਵਿੱਚ ਪੱਤਾ ਲਪੇਟ ਸੁੰਡੀ ਦਾ ਇਲਾਜ ਦੱਸੋ',
        );
        expect(code, 'pa');
      });

      test('Detects Marathi Devanagari with regional markers', () {
        final code = aiService.detectLanguageCode(
          'कापूस पिकांवर पांढरी माशी चा प्रादुर्भाव आहे, काय करावे?',
        );
        expect(code, 'mr');
      });

      test('Detects Tamil Script accurately', () {
        final code = aiService.detectLanguageCode(
          'பருத்தி பயிரில் புழு தாக்குதல் உள்ளது என்ன செய்வது',
        );
        expect(code, 'ta');
      });

      test('Detects Telugu Script accurately', () {
        final code = aiService.detectLanguageCode(
          'వరి పంటలో అగ్గి తెగులు నివారణ ఎలా',
        );
        expect(code, 'te');
      });

      test('Detects Bengali Script accurately', () {
        final code = aiService.detectLanguageCode(
          'ধানের পাতা হলুদ হয়ে যাচ্ছে কি করব',
        );
        expect(code, 'bn');
      });

      test('Detects Odia Script accurately', () {
        final code = aiService.detectLanguageCode(
          'ଧାନ ଫସଲରେ ରୋଗ ଲାଗିଛି କଣ କରିବି',
        );
        expect(code, 'or');
      });

      test('Detects English Script accurately', () {
        final code = aiService.detectLanguageCode(
          'What is the best fertilizer dose for Cotton?',
        );
        expect(code, 'en');
      });

      test('Detects Code-Mixed Gujlish accurately', () {
        final code = aiService.detectLanguageCode(
          'kapas ma gulabi eeyad mate dava kaho',
        );
        expect(code, 'gu');
      });

      test('Detects Code-Mixed Hinglish accurately', () {
        final code = aiService.detectLanguageCode(
          'gehu ki fasal me keeda lag gaya hai dawae batao',
        );
        expect(code, 'hi');
      });

      test('Resolves proper BCP-47 speech recognition locales', () {
        expect(aiService.resolveSpeechLocale('gu'), 'gu-IN');
        expect(aiService.resolveSpeechLocale('hi'), 'hi-IN');
        expect(aiService.resolveSpeechLocale('pa'), 'pa-IN');
        expect(aiService.resolveSpeechLocale('mr'), 'mr-IN');
        expect(aiService.resolveSpeechLocale('ta'), 'ta-IN');
        expect(aiService.resolveSpeechLocale('te'), 'te-IN');
        expect(aiService.resolveSpeechLocale('en'), 'en-IN');
      });
    },
  );

  group('Phase 4 & 5 — Multi-Part Question Handling & 6-Part Response Standard', () {
    final aiService = UnifiedAgriAiService.instance;

    test('Processes complex multi-part Gujarati query without truncation', () async {
      const complexQuery =
          'મારા કપાસમાં પાન પીળા પડે છે અને નીચે સફેદ જીવાત દેખાય છે, સાથે ફૂલ ખરી પડે છે. આ કયો રોગ છે? કઈ દવા છાંટવી? કેટલું પ્રમાણ રાખવું? અને હાલમાં ખાતર કયું આપવું?';

      final response = await aiService.processQuery(
        query: complexQuery,
        profile: dummyProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(response.sender, 'assistant');
      expect(response.languageCode, 'gu');
      expect(response.text.length, greaterThan(250)); // Non-truncated

      // Verify all 6 structured agricultural sections
      final sections = response.structuredSections;
      expect(sections, isNotNull);
      expect(sections!['problemUnderstanding'], isNotEmpty);
      expect(sections['likelyCauses'], isNotEmpty);
      expect(sections['recommendedActions'], isNotEmpty);
      expect(sections['timingAndSteps'], isNotEmpty);
      expect(sections['precautionsAndDosages'], isNotEmpty);
      expect(sections['additionalInfoNeeded'], isNotEmpty);

      // Verify authentic dosages and measures
      expect(
        response.text.contains('૧૫ લિટર') || response.text.contains('પંપ'),
        isTrue,
      );
      expect(
        response.text.contains('ઇમામેક્ટીન') ||
            response.text.contains('ફેરોમોન'),
        isTrue,
      );
    });

    test(
      'Processes fertilizer query with balanced nutrient dosage guidance',
      () async {
        const query = 'કપાસમાં ખાતરનો કેટલો હપ્તો અને ક્યારે આપવો?';

        final response = await aiService.processQuery(
          query: query,
          profile: dummyProfile,
          inputMode: 'text',
          preferredLanguageCode: 'gu',
        );

        expect(response.structuredSections, isNotNull);
        expect(
          response.text.contains('૧૯:૧૯:૧૯') ||
              response.text.contains('યુરિયા'),
          isTrue,
        );
      },
    );

    test('Processes mandi price inquiry with market rates', () async {
      const query = 'કપાસનો આજનો બજાર ભાવ અને શ્રેષ્ઠ મંડી કઈ છે?';

      final response = await aiService.processQuery(
        query: query,
        profile: dummyProfile,
        inputMode: 'text',
        preferredLanguageCode: 'gu',
      );

      expect(response.structuredSections, isNotNull);
      expect(
        response.text.contains('APMC') || response.text.contains('ભાવ'),
        isTrue,
      );
    });
  });

  group('Phase 6 — Voice Assistant Markdown Sanitization & Audio Chunking', () {
    test(
      'Sanitizes Markdown headers, bolding, bullets and links for natural TTS',
      () {
        const rawMarkdown = '''
### ૧. તમારી સમસ્યાની સમજ
**કપાસમાં** સફેદ માખી માટે:
• [લિન્ક](http://example.com) દવા: `ઇમામેક્ટીન`
> સાવચેતી: પંપ દીઠ ૫ ગ્રામ.
''';

        final clean = VoiceAssistantService.sanitizeMarkdownForSpeech(
          rawMarkdown,
        );

        expect(clean.contains('###'), isFalse);
        expect(clean.contains('**'), isFalse);
        expect(clean.contains('['), isFalse);
        expect(clean.contains(']'), isFalse);
        expect(clean.contains('`'), isFalse);
        expect(clean.contains('>'), isFalse);
        expect(clean.contains('•'), isFalse);
        expect(clean.contains('લિન્ક દવા: ઇમામેક્ટીન'), isTrue);
      },
    );

    test('Splits long text into sentence chunks under 220 characters without cutting words', () {
      const longText =
          'કપાસમાં ગુલાબી ઈયળ માટે એકરે ૮-૧૦ ફેરોમોન ટ્રેપ લગાવો. પ્રથમ સ્પ્રે સાંજના સમયે પવન શાંત હોય ત્યારે કરો. ઉપદ્રવ વધુ હોય તો ૧૦-૧૨ દિવસ પછી બીજી દવાનો સ્પ્રે કરો. ૧૫ લિટર પાણીના પંપમાં ઇમામેક્ટીન બેન્ઝોએટ ૫ ગ્રામ નાખવું. સ્પ્રે કરતી વખતે મોં પર માસ્ક અને હાથમોજાં પહેરો.';

      final chunks = VoiceAssistantService.chunkTextForTts(
        longText,
        maxChunkLength: 120,
      );

      expect(chunks.length, greaterThanOrEqualTo(2));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(125));
        expect(chunk.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 8 — Shared Persistent Conversation History', () {
    test('Shares conversation messages across Voice and Text modes', () async {
      final history = ConversationHistoryService.instance;

      // 1. Add voice message
      final voiceMsg = AiConversationMessage(
        id: 'voice_1',
        sender: 'user',
        text: 'કપાસમાં કઈ દવા વાપરવી?',
        inputMode: 'voice',
        languageCode: 'gu',
        timestamp: DateTime.now(),
      );
      await history.addMessage(voiceMsg);

      // 2. Add text message
      final textMsg = AiConversationMessage(
        id: 'text_1',
        sender: 'user',
        text: 'ઘઉંમાં પહેલું પિયત ક્યારે આપવું?',
        inputMode: 'text',
        languageCode: 'gu',
        timestamp: DateTime.now(),
      );
      await history.addMessage(textMsg);

      expect(history.messages.length, 2);
      expect(history.messages.first.isVoice, isTrue);
      expect(history.messages.last.isVoice, isFalse);

      final voiceQueries = history.getRecentVoiceQueries();
      expect(voiceQueries.length, 1);
      expect(voiceQueries.first.text, 'કપાસમાં કઈ દવા વાપરવી?');

      // 3. Clear history
      await history.clearHistory();
      expect(history.messages.isEmpty, isTrue);
    });
  });

  group('Phase 7 — UI Widget Rendering Smoke Tests', () {
    testWidgets('Renders VoiceAssistantPage with pulsing mic centerpiece', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VoiceAssistantPage(profile: dummyProfile)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VoiceAssistantPage), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.textContaining('Voice Assistant'), findsWidgets);
    });

    testWidgets('Renders AskKhetChachaAiPage with input bar and logo', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AskKhetChachaAiPage(profile: dummyProfile)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AskKhetChachaAiPage), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });
  });
}
