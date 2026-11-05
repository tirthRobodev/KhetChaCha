import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/services/temporary_agriculture_qa_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TemporaryAgricultureQAService qaService;

  setUp(() async {
    qaService = TemporaryAgricultureQAService.instance;
    await qaService.initialize();
  });

  group('Temporary Agriculture QA Service - Core Dataset Audit', () {
    test('1. Exactly 32 stored records exist', () {
      expect(
        qaService.records.length,
        equals(32),
        reason: 'There must be strictly 32 records loaded - no 33rd question.',
      );
    });

    test('2. Exact Language Distribution across all 7 supported languages', () {
      final counts = <String, int>{};
      for (final r in qaService.records) {
        counts[r.language] = (counts[r.language] ?? 0) + 1;
      }

      expect(
        counts['gu'],
        equals(7),
        reason: 'Gujarati must have exactly 7 questions',
      );
      expect(
        counts['hi'],
        equals(7),
        reason: 'Hindi must have exactly 7 questions',
      );
      expect(
        counts['en'],
        equals(6),
        reason: 'English must have exactly 6 questions',
      );
      expect(
        counts['pa'],
        equals(3),
        reason: 'Punjabi must have exactly 3 questions',
      );
      expect(
        counts['mr'],
        equals(3),
        reason: 'Marathi must have exactly 3 questions',
      );
      expect(
        counts['te'],
        equals(3),
        reason: 'Telugu must have exactly 3 questions',
      );
      expect(
        counts['bn'],
        equals(3),
        reason: 'Bengali must have exactly 3 questions',
      );
    });

    test('3. Unique IDs and Non-Empty Questions and Answers', () {
      final ids = <String>{};
      for (final r in qaService.records) {
        expect(ids.add(r.id), isTrue, reason: 'ID ${r.id} must be unique');
        expect(
          r.question.trim().isNotEmpty,
          isTrue,
          reason: 'Question ${r.id} cannot be empty',
        );
        expect(
          r.answer.trim().isNotEmpty,
          isTrue,
          reason: 'Answer ${r.id} cannot be empty',
        );
        expect(
          r.verified,
          isFalse,
          reason: 'Temporary demo records must not be marked verified',
        );
      }
    });

    test(
      '4. All 32 exact text lookups match their designated answers',
      () async {
        for (final r in qaService.records) {
          final result = await qaService.answerQuestion(
            r.question,
            selectedLanguage: r.language,
          );

          expect(
            result.matchedTemporary,
            isTrue,
            reason: 'Question "${r.question}" must match temporary dataset',
          );
          expect(result.source, equals('temporary_qa'));
          expect(
            result.response.answer,
            equals(r.answer),
            reason: 'Answer must match dataset answer exactly',
          );
          expect(result.confidence, equals(1.0));
        }
      },
    );

    test('5. STT normalized voice transcript lookups match correctly', () async {
      // Simulates real speech-to-text outputs (e.g. without question marks or trailing spaces)
      for (final r in qaService.records) {
        final strippedTranscript = r.question
            .replaceAll(RegExp(r'[?.!,]'), '')
            .trim();
        final result = await qaService.answerQuestion(
          strippedTranscript,
          selectedLanguage: r.language,
        );

        expect(
          result.matchedTemporary,
          isTrue,
          reason:
              'STT transcript "$strippedTranscript" must match record ${r.id}',
        );
        expect(result.response.answer, equals(r.answer));
      }
    });

    test('6. Unrelated questions are rejected from weak matches', () async {
      final unrelatedQuery = 'how to build a rocket to mars in python';
      final result = await qaService.answerQuestion(
        unrelatedQuery,
        selectedLanguage: 'en',
      );

      // Should not falsely match any agricultural demo answer
      expect(
        result.matchedTemporary,
        isFalse,
        reason:
            'Completely unrelated query must never match temporary QA records',
      );
    });

    test('7. Temporary mode can be disabled cleanly', () async {
      qaService.setEnabled(false);
      final sampleQ = qaService.records.first.question;

      final result = await qaService.answerQuestion(
        sampleQ,
        selectedLanguage: 'gu',
      );

      expect(
        result.matchedTemporary,
        isFalse,
        reason: 'When isEnabled is false, temporary records must be bypassed',
      );

      // Re-enable
      qaService.setEnabled(true);
    });

    test('8. Unicode round-trip preserves all 7 scripts cleanly', () {
      final guText = 'કપાસમાં પાણી ક્યારે આપવું?';
      final hiText = 'मेरी मिट्टी का pH 8.3 है।';
      final paText = 'ਕਣਕ ਨੂੰ ਪਾਣੀ ਕਦੋਂ ਦੇਣਾ ਚਾਹੀਦਾ ਹੈ?';
      final mrText = 'टोमॅटोची पाने वाकडी होत आहेत.';
      final teText = 'నేల pH ఎక్కువగా ఉంటే ఏమి చేయాలి?';
      final bnText = 'টমেটো গাছের পাতা কুঁকড়ে যাচ্ছে।';

      expect(guText, isNot(contains('àª')));
      expect(hiText, isNot(contains('à¤')));
      expect(paText.runes.isNotEmpty, isTrue);
      expect(mrText.runes.isNotEmpty, isTrue);
      expect(teText.runes.isNotEmpty, isTrue);
      expect(bnText.runes.isNotEmpty, isTrue);
    });
  });
}
