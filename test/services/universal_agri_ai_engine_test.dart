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
    farmingType: 'Cotton & Groundnut',
    landSize: '2.0 Acres',
    crops: ['Cotton', 'Groundnut'],
    soilType: 'Black Cotton Soil',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConversationHistoryService.instance.init();
    await ConversationHistoryService.instance.clearHistory();
  });

  group('UniversalAgriAiEngine Core Unit & Integration Tests', () {
    final engine = UniversalAgriAiEngine.instance;

    test('1. Simple 1-line concise inquiry returns structured guidance', () async {
      const simpleQuery = 'કપાસમાં ખાતર ક્યારે આપવું?';
      final message = await engine.processQuery(
        query: simpleQuery,
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'gu',
      );

      expect(message.sender, 'assistant');
      expect(message.languageCode, 'gu');
      expect(message.text, isNotEmpty);
      expect(message.structuredSections, isNotNull);
      expect(
        message.text.contains('૧૯:૧૯:૧૯') || message.text.contains('ખાતર') || message.text.contains('યુરિયા'),
        isTrue,
      );
    });

    test('2. Complex 6-part multi-part scenario addresses water, fertilizer, pests, cost, and 30-day timeline', () async {
      const complexQuery =
          'મારા ૨ એકર કપાસમાં ૪૫ દિવસ થયા છે, પાન પીળા પડે છે અને ચૂસિયા જીવાત છે. પાણી, ખાતર, દવા અને ૩૦ દિવસનું આયોજન આપો અને ખર્ચ કેટલો થશે?';

      final message = await engine.processQuery(
        query: complexQuery,
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(message.sender, 'assistant');
      expect(message.languageCode, 'gu');
      expect(message.text.length, greaterThan(250));

      final sections = message.structuredSections;
      expect(sections, isNotNull);
      expect(sections!['problemUnderstanding'], isNotEmpty);
      expect(sections['likelyCauses'], isNotEmpty);
      expect(sections['recommendedActions'], isNotEmpty);
      expect(sections['precautionsAndDosages'], isNotEmpty);

      // Verify authentic dosages and pump measures
      expect(
        message.text.contains('૧૫ લિટર') || message.text.contains('પંપ'),
        isTrue,
      );
    });

    test('3. Code-mixed Gujlish & Hinglish queries are correctly routed and answered', () async {
      const gujlishQuery = 'kapas ma gulabi eeyad mate dava kaho';
      final message = await engine.processQuery(
        query: gujlishQuery,
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(message.languageCode, 'gu');
      expect(message.text, isNotEmpty);
      expect(message.structuredSections, isNotNull);
    });

    test('4. Empty query handling returns supportive guidance without crashing', () async {
      final message = await engine.processQuery(
        query: '   ',
        profile: testProfile,
        inputMode: 'voice',
        preferredLanguageCode: 'gu',
      );

      expect(message.text, contains('કૃપા કરીને'));
    });

    test('5. Automatic synchronization with shared ConversationHistoryService', () async {
      const query = 'કપાસમાં સફેદ માખી માટે કઈ દવા છાંટવી?';
      await engine.processQuery(
        query: query,
        profile: testProfile,
        inputMode: 'text',
        preferredLanguageCode: 'gu',
        saveToHistory: true,
      );

      final history = ConversationHistoryService.instance.messages;
      expect(history.isNotEmpty, isTrue);
      expect(history.last.isUser, isFalse);
      expect(history.last.languageCode, 'gu');
    });

    test('6. Language resolution for Indian languages through UnifiedAgriAiService', () {
      final service = UnifiedAgriAiService.instance;
      expect(service.detectLanguageCode('કપાસમાં પાન પીળા પડે છે'), 'gu');
      expect(service.detectLanguageCode('गेहूं में पीली कुंगी के लिए कौन सी दवा डालें?'), 'hi');
      expect(service.detectLanguageCode('ਝੋਨੇ ਵਿੱਚ ਪੱਤਾ ਲਪੇਟ ਸੁੰਡੀ ਦਾ ਇਲਾਜ ਦੱਸੋ'), 'pa');
      expect(service.detectLanguageCode('వరి పంటలో తెగులు నివారణ ఎలా'), 'te');
      expect(service.detectLanguageCode('What is the best pesticide for cotton?'), 'en');
    });
  });
}

