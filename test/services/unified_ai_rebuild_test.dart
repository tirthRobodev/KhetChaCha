import 'dart:convert';

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
import 'package:khetchacha/services/universal_agri_ai_engine.dart';
import 'package:khetchacha/services/voice_assistant_service.dart';

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

  group('Unified AI Rebuild & Multimodal Tests', () {
    test('1. TTS Sanitization articulates currency, pump volume, and percentage in regional languages', () {
      // Gujarati
      final guInput =
          'કપાસમાં ખર્ચ ₹2500 થશે, 15L પંપમાં 50 ml લીમડાનું તેલ નાખો, 20% ઉપદ્રવ ઘટશે.';
      final guSanitized = VoiceAssistantService.sanitizeMarkdownForSpeech(
        guInput,
        languageCode: 'gu',
      );
      expect(guSanitized, contains('2500 રૂપિયા'));
      expect(guSanitized, contains('૧૫ લીટર'));
      expect(guSanitized, contains('50 મિલી'));
      expect(guSanitized, contains('20 ટકા'));

      // Hindi
      final hiInput =
          'धान में लागत ₹1800 आएगी, 15L पंप में 40 ml दवा डालें, 15% पैदावार बढ़ेगी.';
      final hiSanitized = VoiceAssistantService.sanitizeMarkdownForSpeech(
        hiInput,
        languageCode: 'hi',
      );
      expect(hiSanitized, contains('1800 रुपये'));
      expect(hiSanitized, contains('15 लीटर'));
      expect(hiSanitized, contains('40 मिली'));
      expect(hiSanitized, contains('15 प्रतिशत'));
    });

    test('2. UniversalAgriAiEngine.processChatQuery delegates to API Service with multimodal payload', () async {
      String? sentImagePayload;

      final mockClient = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        sentImagePayload = body['image_base64'] as String?;
        return http.Response(
          json.encode({
            'success': true,
            'language': 'gu',
            'answer': 'કપાસમાં લીંબોળીના તેલનો છંટકાવ કરો.',
            'action_steps': ['૧૫ લિટર પંપમાં ૫૦ મિલી દવા છાંટો.'],
            'safety_precautions': ['માસ્ક પહેરો.'],
            'plant_category': 'Crop',
            'plant_part': 'Leaf',
            'health_status': 'affected',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      AiChatApiService.instance.setHttpClientForTesting(mockClient);

      final req = const FarmerChatApiRequest(
        question: 'આ પાનમાં શું રોગ છે?',
        language: 'gu',
        imageBase64: 'data:image/jpeg;base64,sample_bytes',
        imageMimeType: 'image/jpeg',
      );

      final res = await UniversalAgriAiEngine.instance.processChatQuery(
        request: req,
        profile: testProfile,
      );

      expect(res.isError, isFalse);
      expect(res.answer, contains('લીંબોળી'));
      expect(sentImagePayload, 'data:image/jpeg;base64,sample_bytes');
      expect(res.plantCategory, 'Crop');
      expect(res.plantPart, 'Leaf');
    });

    testWidgets(
      '3. AskKhetChachaAiPage specimen picker and image badge chip interaction',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'success': true,
              'language': 'gu',
              'answer': 'ડાંગરમાં પાનનો કરપો / બ્લાસ્ટ જણાય છે.',
              'action_steps': ['૧૫ લિટર પંપ મુજબ છંટકાવ કરો.'],
              'safety_precautions': [],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        AiChatApiService.instance.setHttpClientForTesting(mockClient);
        LocationService.instance.enableMockMode();

        await tester.pumpWidget(
          const MaterialApp(home: AskKhetChachaAiPage(profile: testProfile)),
        );
        await tester.pump();

        // Find Camera/Attachment button
        final attachBtn = find.byTooltip('Attach Crop Photo for Diagnosis');
        expect(attachBtn, findsOneWidget);

        // Tap Attach Button to open sheet
        await tester.tap(attachBtn);
        await tester.pumpAndSettle();

        // Verify bottom sheet appears with crop options
        expect(find.text('Crop Diagnosis Photo'), findsOneWidget);
        expect(find.text('Cotton Pink Bollworm'), findsOneWidget);
        expect(find.text('Paddy Leaf Blast'), findsOneWidget);

        // Select Paddy Leaf Blast specimen
        await tester.tap(find.text('Paddy Leaf Blast'));
        await tester.pumpAndSettle();

        // Verify Photo attached badge chip appears above input bar
        expect(
          find.textContaining('Photo attached: paddy.png'),
          findsOneWidget,
        );

        // Tap dismiss (close icon) on badge chip
        final closeIcon = find.byIcon(Icons.close);
        expect(closeIcon, findsOneWidget);
        await tester.tap(closeIcon);
        await tester.pump();

        // Verify badge chip is dismissed
        expect(find.textContaining('Photo attached: paddy.png'), findsNothing);

        LocationService.instance.disableMockMode();
      },
    );
  });
}
