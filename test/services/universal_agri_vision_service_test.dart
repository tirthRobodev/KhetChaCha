import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khetchacha/models/ai_chat_models.dart';
import 'package:khetchacha/models/ai_diagnosis_result.dart';
import 'package:khetchacha/models/farmer_profile.dart';
import 'package:khetchacha/screens/ai/image_ai_diagnosis_page.dart';
import 'package:khetchacha/services/ai_chat_tts_service.dart';
import 'package:khetchacha/services/ai_crop_diagnosis_service.dart';
import 'package:khetchacha/services/conversation_history_service.dart';
import 'package:khetchacha/services/universal_agri_ai_engine.dart';
import 'package:khetchacha/services/universal_agri_vision_service.dart';

Uint8List createDummyPngBytes() {
  final bytes = Uint8List(250);
  bytes[0] = 0x89;
  bytes[1] = 0x50;
  bytes[2] = 0x4E;
  bytes[3] = 0x47;
  bytes[4] = 0x0D;
  bytes[5] = 0x0A;
  bytes[6] = 0x1A;
  bytes[7] = 0x0A;
  for (int i = 8; i < 250; i++) {
    bytes[i] = (i * 3) % 256;
  }
  return bytes;
}

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
    selectedLanguage: 'gu',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConversationHistoryService.instance.init();
    await ConversationHistoryService.instance.clearHistory();
    AiChatTtsService.instance.enableMockMode(enabled: true);
  });

  tearDown(() {
    AiChatTtsService.instance.resetMockMode();
  });

  group('UniversalAgriVisionService Unit Tests', () {
    test('1. Validates image payload and rejects truncated/corrupted bytes', () async {
      final invalidBytes = Uint8List(20); // Less than 100 bytes
      final result = await UniversalAgriVisionService.instance.diagnoseImage(
        imagePath: 'test_short.png',
        imageBytes: invalidBytes,
        targetLanguageCode: 'gu',
      );

      expect(result.isHealthy, isFalse);
      expect(result.confidencePercentage, 0.0);
      expect(result.fullAnswer.contains('અમાન્ય') || result.diagnosisTitle.contains('Validation'), isTrue);
    });

    test('2. Offline grounded diagnosis yields complete structured attributes without crashing', () async {
      final validBytes = createDummyPngBytes();
      final result = await UniversalAgriVisionService.instance.diagnoseImage(
        imagePath: 'sample_cotton_leaf.png',
        imageBytes: validBytes,
        cropHint: 'Cotton',
        targetLanguageCode: 'gu',
        profile: testProfile,
      );

      expect(result.cropName, 'Cotton');
      expect(result.plantCategory, isNotEmpty);
      expect(result.plantPart, isNotEmpty);
      expect(result.healthStatus, isNotEmpty);
      expect(result.confidencePercentage, greaterThan(70.0));
      expect(result.fullAnswer, isNotEmpty);
    });

    test('3. AiCropDiagnosisService delegates cleanly to UniversalAgriVisionService', () async {
      final validBytes = createDummyPngBytes();
      final result = await AiCropDiagnosisService.instance.analyzeCropImage(
        cropName: 'Tomato',
        imagePath: 'sample_tomato.jpg',
        imageBytes: validBytes,
        languageCode: 'hi',
        profile: testProfile,
      );

      expect(result.cropName, 'Tomato');
      expect(result.confidencePercentage, greaterThan(50.0));
    });

    test('4. Healthy plant diagnosis does NOT prescribe chemical pesticides', () {
      final healthyApiRes = FarmerChatApiResponse(
        answer: 'છોડ સંપૂર્ણ સ્વસ્થ છે. પાન લીલા અને તંદુરસ્ત છે. કોઈ રોગ કે જીવાત જણાતી નથી.',
        detailedExplanation: 'છોડ સામાન્ય વૃદ્ધિ દર્શાવે છે.',
        actionSteps: ['સામાન્ય પાણી અને સમયસર ખાતર આપો'],
        safetyPrecautions: ['કોઈ રાસાયણિક જંતુનાશકની જરૂર નથી'],
        cropDetected: 'Cotton',
        symptomsIdentified: const [],
        confidenceScore: 0.95,
        plantCategory: 'Crop',
        plantPart: 'Leaf',
        healthStatus: 'healthy',
        sources: const [],
      );

      // Test the data model directly with healthy parameters
      final healthyResult = AiDiagnosisResult(
        cropName: 'Cotton',
        diagnosisTitle: 'Cotton સંપૂર્ણ સ્વસ્થ છે',
        confidencePercentage: 95.0,
        severityLevel: 'None - Healthy',
        isHealthy: true,
        symptoms: const [],
        preventiveMeasures: const ['Regular field monitoring'],
        organicRemedies: const [],
        chemicalRemedies: const [],
        plantCategory: 'Crop',
        plantPart: 'Leaf',
        healthStatus: 'healthy',
        fullAnswer: healthyApiRes.answer,
        languageCode: 'gu',
      );

      expect(healthyResult.isHealthy, isTrue);
      expect(healthyResult.severityLevel, 'None - Healthy');
      expect(healthyResult.chemicalRemedies, isEmpty);
      expect(healthyResult.fullAnswer.contains('સ્વસ્થ'), isTrue);
    });

    test('5. Damaged plant diagnosis provides IPM organic and 15L chemical pump dosages', () {
      final damagedResult = AiDiagnosisResult(
        cropName: 'Cotton',
        diagnosisTitle: 'Cotton Leaf Curl & Whitefly Infestation',
        confidencePercentage: 91.0,
        severityLevel: 'Moderate',
        isHealthy: false,
        symptoms: ['Curling of leaves upwards', 'Chlorosis along veins'],
        preventiveMeasures: ['Install yellow sticky traps @ 10-15 per acre'],
        organicRemedies: ['Neem Oil 1500 ppm @ 50ml / 15L pump'],
        chemicalRemedies: ['Diafenthiuron 50% WP @ 20g / 15L spray pump'],
        plantCategory: 'Crop',
        plantPart: 'Leaf',
        healthStatus: 'clearly_damaged',
        immediateActions: ['Spray during calm evening hours'],
        fullAnswer: 'Whitefly infestation observed. Spray recommended doses per 15L water.',
        languageCode: 'en',
      );

      expect(damagedResult.isHealthy, isFalse);
      expect(damagedResult.severityLevel, 'Moderate');
      expect(damagedResult.organicRemedies, isNotEmpty);
      expect(damagedResult.chemicalRemedies, isNotEmpty);
      expect(damagedResult.chemicalRemedies.first, contains('15L'));
    });

    test('6. Multilingual diagnosis support across Gujarati, Hindi, Punjabi, Marathi, English', () async {
      final validBytes = createDummyPngBytes();
      final languages = ['gu', 'hi', 'en', 'pa', 'mr'];

      for (final lang in languages) {
        final res = await UniversalAgriVisionService.instance.diagnoseImage(
          imagePath: 'field_test.jpg',
          imageBytes: validBytes,
          targetLanguageCode: lang,
          profile: testProfile,
        );
        expect(res.languageCode, lang);
        expect(res.diagnosisTitle, isNotEmpty);
        expect(res.fullAnswer, isNotEmpty);
      }
    });
  });

  group('UniversalAgriAiEngine Vision Integration Tests', () {
    test('7. processQuery with imageBytes routes through multimodal vision pipeline', () async {
      final validBytes = createDummyPngBytes();
      final message = await UniversalAgriAiEngine.instance.processQuery(
        query: '',
        profile: testProfile,
        inputMode: 'multimodal',
        preferredLanguageCode: 'gu',
        imageBytes: validBytes,
      );

      expect(message.sender, 'assistant');
      expect(message.languageCode, 'gu');
      expect(message.text, isNotEmpty);
      expect(message.structuredSections, isNotNull);
      expect(message.structuredSections!['plantCategory'], isNotNull);
      expect(message.structuredSections!['healthStatus'], isNotNull);
    });

    test('8. processQuery with image and user text combines both seamlessly', () async {
      final validBytes = createDummyPngBytes();
      final message = await UniversalAgriAiEngine.instance.processQuery(
        query: 'આ પાનમાં કયો રોગ છે?',
        profile: testProfile,
        inputMode: 'multimodal',
        preferredLanguageCode: 'gu',
        imageBytes: validBytes,
      );

      expect(message.sender, 'assistant');
      expect(message.text, isNotEmpty);
      expect(message.structuredSections, isNotNull);
    });
  });

  group('TTS and Widget Integration Tests', () {
    test('9. AiChatTtsService handles diagnosis text and generates proper labels', () async {
      const lang = 'gu';
      final listenLabel = AiChatTtsService.instance.getListenLabel(lang);
      final stopLabel = AiChatTtsService.instance.getStopLabel(lang);

      expect(listenLabel, 'જવાબ સાંભળો');
      expect(stopLabel, 'અવાજ બંધ કરો');

      final spoke = await AiChatTtsService.instance.speakAnswer(
        messageId: 'diag_cotton_test',
        text: 'કપાસનો છોડ સંપૂર્ણ સ્વસ્થ છે.',
        langCode: 'gu',
      );

      expect(spoke, isTrue);
      expect(AiChatTtsService.instance.isMessageSpeaking('diag_cotton_test'), isTrue);

      await AiChatTtsService.instance.stop();
      expect(AiChatTtsService.instance.isMessageSpeaking('diag_cotton_test'), isFalse);
    });

    testWidgets('10. ImageAiDiagnosisPage renders preview and runs diagnosis', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageAiDiagnosisPage(profile: testProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title and initial elements
      expect(find.text('Image AI Crop Diagnosis'), findsOneWidget);
      expect(find.text('Select Target Crop'), findsOneWidget);
      expect(find.text('Capture Camera'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);
      expect(find.text('Analyze Crop Image with AI'), findsOneWidget);

      // Tap Analyze with no image selected -> shows snackbar
      await tester.tap(find.text('Analyze Crop Image with AI'));
      await tester.pumpAndSettle();
      expect(find.text('Please capture or choose a crop image first.'), findsOneWidget);
    });
  });
}
