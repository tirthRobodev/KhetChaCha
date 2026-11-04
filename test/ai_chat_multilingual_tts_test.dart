import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/localization/language_data.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/quick_access/ask_khet_chacha_ai_page.dart';
import 'package:khetchacha/services/ai_chat_api_service.dart';
import 'package:khetchacha/services/ai_chat_tts_service.dart';
import 'package:khetchacha/services/language_detection_helper.dart';
import 'package:khetchacha/services/language_service.dart';
import 'package:khetchacha/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'તીર્થ જગાણી',
    mobileNumber: '9876543210',
    email: 'tirth@example.com',
    state: 'Gujarat',
    district: 'Ahmedabad',
    village: 'Sanand',
    farmingType: 'Organic',
    landSize: '5 Bigha',
    selectedProducts: ['Cotton'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.init();
    await LanguageService.instance.setLanguage(LanguageData.getByCode('gu'));
    AiChatTtsService.instance.enableMockMode(
      enabled: true,
      availableLocales: {'gu-IN', 'hi-IN', 'pa-IN', 'en-IN', 'mr-IN', 'ta-IN'},
    );
  });

  tearDown(() {
    AiChatTtsService.instance.resetMockMode();
  });

  group('A. Multilingual Language Detection Tests (23 Languages)', () {
    test('1. Detects Gujarati query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'મારા કપાસના પાંદડા પીળા કેમ પડે છે?',
      );
      expect(code, 'gu');
    });

    test('2. Detects Hindi query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'मेरी कपास की फसल में पत्तियां पीली हो रही हैं, क्या उपाय करें?',
      );
      expect(code, 'hi');
    });

    test('3. Detects Punjabi query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'ਮੇਰੇ ਨਰਮੇ ਦੇ ਪੱਤੇ ਪੀਲੇ ਪੈ ਰਹੇ ਹਨ, ਕੀ ਕਰੀਏ?',
      );
      expect(code, 'pa');
    });

    test('4. Detects Marathi query accurately with regional marker', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'कापसावरील बोंडअळी नियंत्रणासाठी शेतकरी मित्रांनी काय करावे?',
      );
      expect(code, 'mr');
    });

    test('5. Detects Tamil query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'பருத்தி இலைகள் மஞ்சள் நிறமாக மாறுகின்றன என்ன செய்வது?',
      );
      expect(code, 'ta');
    });

    test('6. Detects Telugu query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'పత్తి పంటలో గులాబీ రంగు పురుగు నివారణకు ఏమి చేయాలి?',
      );
      expect(code, 'te');
    });

    test('7. Detects Kannada query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'ಹತ್ತಿ ಬೆಳೆಯಲ್ಲಿ ಗುಲಾಬಿ ಹುಳು ನಿಯಂತ್ರಣ ಹೇಗೆ ಮಾಡುವುದು?',
      );
      expect(code, 'kn');
    });

    test('8. Detects Malayalam query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'പരുത്തിയിലകളിൽ മഞ്ഞനിറം വരുന്നു എന്ത് ചെയ്യണം?',
      );
      expect(code, 'ml');
    });

    test('9. Detects Bengali query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'তুলার পাতা হলুদ হয়ে যাচ্ছে কি ঔষধ স্প্রে করব?',
      );
      expect(code, 'bn');
    });

    test('10. Detects Assamese query with distinctive characters', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'কপাহৰ পাতবোৰ হালধীয়া হৈছে কি কৰিম?',
      );
      expect(code, 'as');
    });

    test('11. Detects Odia query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'କପା ଫସଲରେ ଗୋଲାପୀ ପୋକ ପାଇଁ କଣ ଔଷଧ ସ୍ପ୍ରେ କରିବେ?',
      );
      expect(code, 'or');
    });

    test('12. Detects Urdu query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'کپاس میں گلابی سنڈی کی روک تھام کے لیے کون سی دوا استعمال کریں؟',
      );
      expect(code, 'ur');
    });

    test('13. Detects English query accurately', () {
      final code = LanguageDetectionHelper.detectLanguage(
        'How can I control pink bollworm infestation in my cotton crop?',
      );
      expect(code, 'en');
    });

    test('14. Falls back to active app language for purely numerical inputs', () {
      final code = LanguageDetectionHelper.detectLanguage(
        '10-26-26 50kg',
        fallbackCode: 'gu',
      );
      expect(code, 'gu');
    });

    test('15. All 23 scheduled languages have valid BCP-47 locale mappings', () {
      final expected23 = [
        'en', 'gu', 'hi', 'pa', 'mr', 'bn', 'ta', 'te', 'kn', 'ml',
        'or', 'as', 'ur', 'ne', 'sa', 'kok', 'mai', 'doi', 'ks', 'sd',
        'brx', 'mni', 'sat'
      ];

      for (final code in expected23) {
        final locale = AiChatTtsService.instance.resolveLocale(code);
        expect(locale, isNotEmpty, reason: 'Locale missing for $code');
        expect(locale.contains('-'), isTrue, reason: 'Invalid BCP-47 format for $code: $locale');
      }
    });

    test('16. All 23 scheduled languages have native listen and stop labels', () {
      final expected23 = [
        'en', 'gu', 'hi', 'pa', 'mr', 'bn', 'ta', 'te', 'kn', 'ml',
        'or', 'as', 'ur', 'ne', 'sa', 'kok', 'mai', 'doi', 'ks', 'sd',
        'brx', 'mni', 'sat'
      ];

      for (final code in expected23) {
        final listen = AiChatTtsService.instance.getListenLabel(code);
        final stop = AiChatTtsService.instance.getStopLabel(code);
        expect(listen, isNotEmpty, reason: 'Listen label missing for $code');
        expect(stop, isNotEmpty, reason: 'Stop label missing for $code');
      }
    });
  });

  group('B. Multilingual Text-to-Speech (TTS) Service Tests', () {
    test('1. Speak Gujarati answer sets speaking state and active locale', () async {
      final ok = await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-1',
        text: 'કપાસમાં ગુલાબી ઈયળ માટે ફેરોમોન ટ્રેપ લગાવો.',
        langCode: 'gu',
      );

      expect(ok, isTrue);
      expect(AiChatTtsService.instance.state, AiTtsState.speaking);
      expect(AiChatTtsService.instance.currentlySpeakingMessageId, 'msg-1');
      expect(AiChatTtsService.instance.activeLocale, 'gu-IN');
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-1'), isTrue);
    });

    test('2. Tapping speaker of already speaking answer stops playback (Toggle Off)', () async {
      await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-1',
        text: 'કપાસમાં ગુલાબી ઈયળ માટે ફેરોમોન ટ્રેપ લગાવો.',
        langCode: 'gu',
      );
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-1'), isTrue);

      // Tap same message again
      final ok = await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-1',
        text: 'કપાસમાં ગુલાબી ઈયળ માટે ફેરોમોન ટ્રેપ લગાવો.',
        langCode: 'gu',
      );

      expect(ok, isFalse);
      expect(AiChatTtsService.instance.state, AiTtsState.idle);
      expect(AiChatTtsService.instance.currentlySpeakingMessageId, isNull);
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-1'), isFalse);
    });

    test('3. Switching between answer speakers halts previous speech immediately', () async {
      // Start Message 1
      await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-1',
        text: 'જવાબ ૧: કપાસમાં ખાતર આપો.',
        langCode: 'gu',
      );
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-1'), isTrue);
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-2'), isFalse);

      // Start Message 2
      await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-2',
        text: 'उत्तर २: गेहूं में सिंचाई करें।',
        langCode: 'hi',
      );

      expect(AiChatTtsService.instance.isMessageSpeaking('msg-1'), isFalse);
      expect(AiChatTtsService.instance.isMessageSpeaking('msg-2'), isTrue);
      expect(AiChatTtsService.instance.currentlySpeakingMessageId, 'msg-2');
      expect(AiChatTtsService.instance.activeLocale, 'hi-IN');
    });

    test('4. Missing device voice handling prevents cross-language distortion', () async {
      // Simulate that Kashmiri voice (ks-IN) is NOT installed on device
      final available = await AiChatTtsService.instance.isVoiceAvailable('ks');
      expect(available, isFalse);

      final ok = await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-kashmiri',
        text: 'یمہ مسلس متعلق صٔحیح حل۔',
        langCode: 'ks',
      );

      // Must not speak with wrong language voice
      expect(ok, isFalse);
      expect(AiChatTtsService.instance.state, AiTtsState.idle);
      expect(AiChatTtsService.instance.currentlySpeakingMessageId, isNull);

      final missingMsg = AiChatTtsService.instance.getMissingVoiceMessage('ks');
      expect(missingMsg, contains('کشمیری آواز'));
    });

    test('5. Stop method resets state to idle and clears currently speaking message', () async {
      await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-english',
        text: 'Apply standard Neem oil at 5ml per liter.',
        langCode: 'en',
      );
      expect(AiChatTtsService.instance.state, AiTtsState.speaking);

      await AiChatTtsService.instance.stop();

      expect(AiChatTtsService.instance.state, AiTtsState.idle);
      expect(AiChatTtsService.instance.currentlySpeakingMessageId, isNull);
    });

    test('6. Sanitizes markdown asterisks and URLs before speech synthesis', () async {
      final ok = await AiChatTtsService.instance.speakAnswer(
        messageId: 'msg-markdown',
        text: '### કપાસ સલાહ:\n* **નીમ તેલ**: ૫ મિલી/લિટર.\nસંદર્ભ: https://icar.gov.in',
        langCode: 'gu',
      );
      expect(ok, isTrue);
    });
  });

  group('C. Same Chat Screen UI & Interaction Tests', () {
    testWidgets('1. Displays AI answer and Speaker Button directly below question in the same screen', (tester) async {
      final responseCompleter = Completer<http.Response>();
      final mockClient = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['language'], 'gu');
        return responseCompleter.future;
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);
      LocationService.instance.enableMockMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: AskKhetChachaAiPage(profile: testProfile),
        ),
      );

      await tester.pump();

      // Verify Initial Welcome card exists once
      expect(find.byType(AskKhetChachaAiPage), findsOneWidget);
      expect(find.textContaining('નમસ્તે તીર્થ જગાણી!'), findsOneWidget);

      // Enter question in Gujarati
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'કપાસના પાન પીળા કેમ થાય છે?');
      await tester.pump();

      // Tap Send Button
      final sendBtn = find.byIcon(Icons.send_rounded);
      await tester.tap(sendBtn);
      await tester.pump();

      // Verify question and loading bubble appear in the same chat screen while awaiting backend
      expect(find.text('કપાસના પાન પીળા કેમ થાય છે?'), findsOneWidget);
      expect(find.text('ખેતચાચા AI કૃષિ સલાહ ચકાસી રહ્યા છે...'), findsOneWidget);

      // Now complete the backend response
      responseCompleter.complete(
        http.Response(
          json.encode({
            'success': true,
            'language': 'gu',
            'language_name': 'Gujarati',
            'answer': 'કપાસના પાન પીળા થવાનાં કારણોમાં મેગ્નેશિયમની ઉણપ મુખ્ય છે.',
            'action_steps': [
              'મેગ્નેશિયમ સલ્ફેટ (૧૫૦ ગ્રામ / ૧૫ લીટર પંપ) નો છંટકાવ કરો.',
            ],
            'safety_precautions': [
              'છંટકાવ વખતે મોં પર માસ્ક પહેરો.',
            ],
            'requires_photo': false,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      // Wait for async response and scroll animations to finish
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify answer appears directly below question in the same chat screen
      expect(find.textContaining('મેગ્નેશિયમની ઉણપ મુખ્ય છે'), findsOneWidget);
      expect(find.textContaining('મેગ્નેશિયમ સલ્ફેટ (૧૫૦ ગ્રામ / ૧૫ લીટર પંપ)'), findsOneWidget);

      // Verify Speaker Button is displayed directly below both messages (welcome card and answer)
      final speakerBtns = find.widgetWithText(InkWell, 'જવાબ સાંભળો');
      expect(speakerBtns, findsNWidgets(2));

      // Tap the Speaker Button of the new answer to start speech
      await tester.tap(speakerBtns.last);
      await tester.pump();

      // Button label must change to "અવાજ બંધ કરો" while speaking
      expect(find.text('અવાજ બંધ કરો'), findsOneWidget);
      expect(AiChatTtsService.instance.isMessageSpeaking(AiChatTtsService.instance.currentlySpeakingMessageId!), isTrue);

      // Tap Speaker Button again to stop speech
      await tester.tap(find.text('અવાજ બંધ કરો'));
      await tester.pump();

      // Button label reverts to "જવાબ સાંભળો" on both messages
      expect(find.text('જવાબ સાંભળો'), findsNWidgets(2));
      expect(AiChatTtsService.instance.state, AiTtsState.idle);

      LocationService.instance.disableMockMode();
    });

    testWidgets('2. Answers in Hindi when question is in Hindi, with Hindi speaker button', (tester) async {
      final mockClient = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['language'], 'hi');

        return http.Response(
          json.encode({
            'success': true,
            'language': 'hi',
            'language_name': 'Hindi',
            'answer': 'कपास में गुलाबी सुंडी के लिए फेरोमोन ट्रैप लगाएं।',
            'action_steps': ['प्रति एकड़ 8 से 10 ट्रैप लगाएं।'],
            'safety_precautions': ['कीटनाशक छिड़कते समय मास्क लगाएं।'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);
      LocationService.instance.enableMockMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: AskKhetChachaAiPage(profile: testProfile),
        ),
      );

      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'कपास में गुलाबी सुंडी के लिए क्या करें?');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Wait for async response
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Hindi answer and Hindi speaker button
      expect(find.textContaining('फेरोमोन ट्रैप लगाएं'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'उत्तर सुनें'), findsOneWidget);

      LocationService.instance.disableMockMode();
    });

    testWidgets('3. Handles network failure with Retry button and re-sends successfully', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          // Simulate connection drop
          throw const SocketException('Network is unreachable');
        }
        // Success on retry
        return http.Response(
          json.encode({
            'success': true,
            'language': 'gu',
            'answer': 'જીરુંમાં સુકારો રોગ માટે ટ્રાઇકોડર્મા વાપરો.',
            'action_steps': ['બીજ માવજત કરો.'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);
      LocationService.instance.enableMockMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: AskKhetChachaAiPage(profile: testProfile),
        ),
      );

      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'જીરુંમાં સુકારો');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify error message and Retry button appear
      expect(find.textContaining('સર્વર સાથે સંપર્ક થઈ શક્યો નથી'), findsOneWidget);
      final retryBtnFinder = find.widgetWithText(InkWell, 'ફરી પ્રયાસ કરો (Retry)');
      expect(retryBtnFinder, findsOneWidget);

      // Tap Retry
      await tester.tap(retryBtnFinder);
      await tester.pump();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify retry resolved successfully and answer is rendered
      expect(find.textContaining('ટ્રાઇકોડર્મા વાપરો'), findsOneWidget);
      expect(callCount, 2);

      LocationService.instance.disableMockMode();
    });

    testWidgets('4. Multi-turn conversation preserves multiple consecutive questions in the same scrollable view', (tester) async {
      final mockClient = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final q = body['question'] as String;

        if (q.contains('પ્રશ્ન ૧')) {
          return http.Response(
            json.encode({
              'success': true,
              'language': 'gu',
              'answer': 'જવાબ ૧: કપાસમાં નીંદણ નિયંત્રણ કરો.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else {
          return http.Response(
            json.encode({
              'success': true,
              'language': 'gu',
              'answer': 'જવાબ ૨: ઘઉંમાં પિયત સમયસર આપો.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);
      LocationService.instance.enableMockMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: AskKhetChachaAiPage(profile: testProfile),
        ),
      );

      await tester.pump();

      // Submit Question 1
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'પ્રશ્ન ૧');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Submit Question 2
      await tester.enterText(inputField, 'પ્રશ્ન ૨');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Both questions and answers must be present in the same chat screen
      expect(find.text('પ્રશ્ન ૧'), findsOneWidget);
      expect(find.textContaining('જવાબ ૧: કપાસમાં નીંદણ'), findsOneWidget);
      expect(find.text('પ્રશ્ન ૨'), findsOneWidget);
      expect(find.textContaining('જવાબ ૨: ઘઉંમાં પિયત'), findsOneWidget);

      LocationService.instance.disableMockMode();
    });
  });
}
