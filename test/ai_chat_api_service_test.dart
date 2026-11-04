import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/models/ai_chat_models.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/quick_access/ask_khet_chacha_ai_page.dart';
import 'package:khetchacha/services/ai_chat_api_service.dart';
import 'package:khetchacha/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = FarmerProfile(
    fullName: 'રમેશભાઈ પટેલ',
    mobileNumber: '9876543210',
    email: 'ramesh@example.com',
    state: 'Gujarat',
    district: 'Ahmedabad',
    village: 'Sanand',
    farmingType: 'Organic',
    landSize: '5 Bigha',
    selectedProducts: ['Cotton'],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiChatApiService Unit Tests', () {
    test('1. Successful Gujarati chat response parsing', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/chat');
        final responseData = {
          'success': true,
          'language': 'gu',
          'language_name': 'Gujarati',
          'answer': 'કપાસમાં લાલિયા રોગ માટે મેગ્નેશિયમ સલ્ફેટ (૧૫૦ ગ્રામ / ૧૫ લીટર પંપ) નો છંટકાવ કરો.',
          'detailed_explanation': 'કપાસમાં પાન લાલ કે પીળા પડવાનું કારણ મેગ્નેશિયમ તત્વની ઉણપ અને ભેજ છે.',
          'action_steps': [
            'ખેતરમાં ભરાયેલું પાણી તાત્કાલિક નિકાલ કરો.',
            'મેગ્નેશિયમ સલ્ફેટનો સવારે છંટકાવ કરો.',
          ],
          'safety_precautions': [
            'દવાનો છંટકાવ કરતી વખતે માસ્ક અને મોજા પહેરો.',
          ],
          'crop_detected': 'Cotton',
          'symptoms_identified': ['leaf yellowing', 'lalio'],
          'confidence_score': 0.95,
          'sources': [
            {
              'title': 'ICAR-CICR Cotton Advisory',
              'document_name': 'ICAR_CICR_Cotton_Crop_Advisory.pdf',
              'page_number': 1,
              'page_or_section': 'Lalio Management',
              'source_type': 'local_pdf',
              'snippet': 'Magnesium deficiency causes reddening...',
              'confidence_score': 0.98,
            }
          ],
          'search_strategy_used': 'local_only',
          'requires_photo': false,
        };
        return http.Response(json.encode(responseData), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'કપાસમાં પાન પીળાં કેમ થાય છે?',
        language: 'gu',
        currentCrop: 'Cotton',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.success, isTrue);
      expect(res.isError, isFalse);
      expect(res.language, 'gu');
      expect(res.answer, contains('મેગ્નેશિયમ સલ્ફેટ'));
      expect(res.actionSteps.length, 2);
      expect(res.safetyPrecautions.length, 1);
      expect(res.sources.length, 1);
      expect(res.sources.first.documentName, 'ICAR_CICR_Cotton_Crop_Advisory.pdf');
      expect(res.requiresPhoto, isFalse);
    });

    test('2. Successful English chat response parsing', () async {
      final mockClient = MockClient((request) async {
        final responseData = {
          'success': true,
          'language': 'en',
          'language_name': 'English',
          'answer': 'For wheat rust, apply Propiconazole 25% EC at 15-20 ml per 15L spray pump.',
          'detailed_explanation': 'Wheat rust is caused by Puccinia species under high humidity.',
          'action_steps': [
            'Spray Propiconazole early morning.',
            'Avoid excess nitrogen fertilizer.',
          ],
          'safety_precautions': [
            'Wear protective mask and gloves.',
            'Follow 30 days pre-harvest interval.',
          ],
          'crop_detected': 'Wheat',
          'sources': [],
          'requires_photo': false,
        };
        return http.Response(json.encode(responseData), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'Wheat rust treatment?',
        language: 'en',
        currentCrop: 'Wheat',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.success, isTrue);
      expect(res.language, 'en');
      expect(res.answer, contains('Propiconazole'));
      expect(res.actionSteps.length, 2);
    });

    test('3. Network unavailable (SocketException)', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'કપાસમાં રોગ',
        language: 'gu',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.success, isFalse);
      expect(res.answer, contains('સર્વર સાથે સંપર્ક થઈ શક્યો નથી'));
      expect(res.actionSteps, anyElement(contains('1800-180-1551')));
    });

    test('4. Server timeout (TimeoutException)', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Request timed out');
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'Wheat disease',
        language: 'en',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.answer, contains('took too long to respond'));
    });

    test('5. HTTP 429 Quota Exceeded handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Rate limit exceeded"}', 429);
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'મગફળીમાં રોગ',
        language: 'gu',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.answer, contains('ઘણો ટ્રાફિક છે'));
    });

    test('6. HTTP 422 Validation Error handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Field required"}', 422);
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: '',
        language: 'gu',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.answer, contains('વિગતો ખૂટે છે'));
    });

    test('7. HTTP 500 Server Error handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Internal server error"}', 500);
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(
        question: 'કપાસમાં રોગ',
        language: 'gu',
      );

      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.answer, contains('ક્ષતિ સર્જાઈ છે'));
    });

    test('8. Empty response body handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(question: 'Test', language: 'en');
      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.answer, isEmpty);
      expect(res.actionSteps, isEmpty);
    });

    test('9. Invalid JSON format handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{invalid_json_payload', 200, headers: {'content-type': 'application/json'});
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(question: 'Test', language: 'gu');
      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.isError, isTrue);
      expect(res.answer, contains('ક્ષતિ સર્જાઈ છે'));
    });

    test('10. Missing sources fallback handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'success': true,
            'answer': 'Advisory without explicit sources cited.',
            'sources': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(question: 'Test', language: 'en');
      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.sources, isEmpty);
      expect(res.answer, 'Advisory without explicit sources cited.');
    });

    test('11. requires_photo flag parsing', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'success': true,
            'answer': 'લક્ષણો અસ્પષ્ટ છે, પાકનો ફોટો મોકલો.',
            'requires_photo': true,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      const req = FarmerChatApiRequest(question: 'છોડ સુકાઈ રહ્યો છે', language: 'gu');
      final res = await AiChatApiService.instance.sendFarmerQuery(req);

      expect(res.requiresPhoto, isTrue);
    });

    test('12. Location coordinates omitted when permission not granted', () {
      // Create request payload with null coordinates
      const locPayload = FarmerLocationPayload(
        district: 'Ahmedabad',
        state: 'Gujarat',
        latitude: null,
        longitude: null,
      );

      const req = FarmerChatApiRequest(
        question: 'કપાસમાં ખાતર',
        language: 'gu',
        location: locPayload,
      );

      final jsonMap = req.toJson();
      expect(jsonMap['location'], isNotNull);
      expect(jsonMap['location']['latitude'], isNull);
      expect(jsonMap['location']['longitude'], isNull);
      expect(jsonMap['location']['district'], 'Ahmedabad');
      expect(jsonMap['location']['state'], 'Gujarat');
    });

    test('13. Physical Android device base URL configuration', () async {
      final service = AiChatApiService.instance;
      service.setPhysicalAndroidDevice(true);
      expect(AiChatApiService.defaultPhysicalDevBaseUrl, 'http://10.180.217.194:8000');

      service.setPhysicalAndroidDevice(false);
      expect(AiChatApiService.defaultEmulatorBaseUrl, 'http://10.0.2.2:8000');

      // Reset to physical device default
      service.setPhysicalAndroidDevice(true);
    });
  });

  group('AskKhetChachaAiPage Widget Tests', () {
    testWidgets('Renders chatbot UI, sends message and renders response bubble', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'success': true,
            'language': 'gu',
            'answer': 'કપાસમાં ગુલાબી ઈયળ માટે ફેરોમોન ટ્રેપ લગાવો.',
            'action_steps': ['૮-૧૦ ફેરોમોન ટ્રેપ લગાવો.'],
            'safety_precautions': ['માસ્ક પહેરો.'],
            'requires_photo': false,
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

      // Verify title and welcome message
      expect(find.byType(AskKhetChachaAiPage), findsOneWidget);
      expect(find.textContaining('AI'), findsWidgets);

      // Enter question
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, 'કપાસમાં ગુલાબી ઈયળ માટે શું કરવું?');
      await tester.pump();

      // Tap Send
      final sendBtn = find.byIcon(Icons.send_rounded);
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pump();

      // Expect loading text or user message
      expect(find.text('કપાસમાં ગુલાબી ઈયળ માટે શું કરવું?'), findsOneWidget);

      // Wait for mock API response and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify bot answer and action steps rendered
      expect(find.textContaining('ફેરોમોન ટ્રેપ લગાવો'), findsWidgets);

      LocationService.instance.disableMockMode();
    });

    testWidgets('Retry on failure preserves original question without creating duplicate question bubbles', (tester) async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // First attempt times out or fails
          throw TimeoutException('Simulated server timeout');
        } else {
          // Second attempt succeeds
          return http.Response(
            json.encode({
              'success': true,
              'language': 'gu',
              'answer': 'સફળતાપૂર્વક જવાબ મળ્યો.',
              'action_steps': [],
              'safety_precautions': [],
              'requires_photo': false,
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

      // Enter question
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'ઘઉંમાં ખાતર ક્યારે નાખવું?');
      await tester.pump();

      // Tap Send
      final sendBtn = find.byIcon(Icons.send_rounded);
      await tester.tap(sendBtn);
      await tester.pump();

      // Exactly 1 user question exists
      expect(find.text('ઘઉંમાં ખાતર ક્યારે નાખવું?'), findsOneWidget);

      // Settle the timeout error
      await tester.pump(const Duration(milliseconds: 500));

      // Error message should be rendered with Retry button
      final retryBtn = find.text('ફરી પ્રયાસ કરો (Retry)');
      expect(retryBtn, findsOneWidget);

      // Verify still exactly 1 user question before retry
      expect(find.text('ઘઉંમાં ખાતર ક્યારે નાખવું?'), findsOneWidget);

      // Scroll to make retry button visible and tap it
      await tester.ensureVisible(retryBtn);
      await tester.pumpAndSettle();
      await tester.tap(retryBtn, warnIfMissed: false);
      await tester.pump();

      // Crucial assertion: User question MUST NOT be duplicated!
      expect(find.text('ઘઉંમાં ખાતર ક્યારે નાખવું?'), findsOneWidget);

      // Settle the successful response
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Bot answer rendered
      expect(find.text('સફળતાપૂર્વક જવાબ મળ્યો.'), findsOneWidget);

      // Ensure user question STILL appears exactly once
      expect(find.text('ઘઉંમાં ખાતર ક્યારે નાખવું?'), findsOneWidget);

      LocationService.instance.disableMockMode();
    });
  });
}
