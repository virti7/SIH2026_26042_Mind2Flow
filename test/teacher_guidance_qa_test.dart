import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/prototype_teacher_guidance_repository.dart';
import 'package:maatribhasha/core/content/teacher_guidance_models.dart';
import 'package:maatribhasha/features/teach/presentation/pages/teacher_guidance_screen.dart';

/// In-memory AssetBundle serving one JSON string for the guidance asset.
/// Records every requested key so tests can prove no other asset (and no
/// network path) is ever touched. Never hits the network.
class _JsonBundle extends AssetBundle {
  final String json;
  final List<String> requestedKeys = [];

  _JsonBundle(this.json);

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    requestedKeys.add(key);
    if (key == PrototypeTeacherGuidanceRepository.assetPath) {
      return Future.value(json);
    }
    return Future.error(FlutterError('not found: $key'));
  }

  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<T> loadStructuredData<T>(
          String key, Future<T> Function(String value) parser) =>
      Future.error(FlutterError('not found: $key'));

  @override
  void evict(String key) {}
}

/// Small deterministic knowledge base mirroring the shipped file's schema.
const _testKbJson = '''
{
  "version": 1,
  "items": [
    {
      "id": "numbers_up_to_100",
      "className": "Class 2",
      "subject": "Mathematics",
      "topic": "Numbers up to 100",
      "intent": "TEACHING_METHOD",
      "keywords": ["numbers", "number", "counting", "count", "100", "100 तक", "संख्या", "संख्याएँ", "गिनती", "गिनना"],
      "questionPatterns": ["how should I teach numbers up to 100", "how to teach numbers", "100 तक की संख्याएँ कैसे सिखाएँ", "गिनती कैसे सिखाएँ"],
      "answerHindi": "परीक्षण हिंदी उत्तर गिनती।",
      "answerEnglish": "Test English answer counting."
    },
    {
      "id": "counting_activity",
      "className": "Class 2",
      "subject": "Mathematics",
      "topic": "Numbers up to 100",
      "intent": "ACTIVITY",
      "keywords": ["activity", "counting", "count", "game", "play", "गतिविधि", "खेल", "गिनती"],
      "questionPatterns": ["what activity can I use for counting", "give me a counting activity", "गिनती सिखाने के लिए कौन सी गतिविधि करूँ"],
      "answerHindi": "परीक्षण हिंदी उत्तर गतिविधि।",
      "answerEnglish": "Test English answer activity."
    },
    {
      "id": "place_value_tens_ones",
      "className": "Class 2",
      "subject": "Mathematics",
      "topic": "Place Value",
      "intent": "EXPLANATION",
      "keywords": ["place value", "tens", "ones", "ten", "bundle", "दहाई", "इकाई", "दहाई और इकाई", "बंडल"],
      "questionPatterns": ["how can I explain tens and ones", "explain place value", "दहाई और इकाई कैसे समझाएँ"],
      "answerHindi": "परीक्षण हिंदी उत्तर दहाई।",
      "answerEnglish": "Test English answer place value."
    },
    {
      "id": "classroom_activity_generic",
      "className": "Class 2",
      "subject": "Mathematics",
      "topic": "Numbers up to 100",
      "intent": "CLASSROOM_ACTIVITY",
      "keywords": ["activity", "classroom", "game", "fun", "गतिविधि", "कक्षा", "खेल"],
      "questionPatterns": ["give me a classroom activity", "give me an activity", "कोई गतिविधि बताइए"],
      "answerHindi": "परीक्षण हिंदी उत्तर कक्षा।",
      "answerEnglish": "Test English answer classroom."
    }
  ]
}
''';

const _mathNumbersCtx = TeacherGuidanceContext(
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
);

PrototypeTeacherGuidanceRepository _repo(_JsonBundle bundle) =>
    PrototypeTeacherGuidanceRepository(bundle: bundle);

void main() {
  group('Normalization', () {
    test('lowercases, trims, collapses spaces, strips punctuation', () {
      expect(
        PrototypeTeacherGuidanceRepository.normalizeQuestion(
            '  How   should I teach numbers?! '),
        'how should i teach numbers',
      );
    });

    test('keeps Hindi words and digits', () {
      expect(
        PrototypeTeacherGuidanceRepository.normalizeQuestion(
            '100 तक की संख्याएँ कैसे सिखाएँ?'),
        '100 तक की संख्याएँ कैसे सिखाएँ',
      );
    });

    test('empty and punctuation-only input normalizes to empty', () {
      expect(PrototypeTeacherGuidanceRepository.normalizeQuestion(''), '');
      expect(
          PrototypeTeacherGuidanceRepository.normalizeQuestion('  ...?! '),
          '');
    });
  });

  group('Shipped knowledge base file', () {
    test('real teacher_guidance.json parses with >=10 valid bilingual items',
        () {
      final file = File(
          'assets/prototype_content/teacher_guidance/teacher_guidance.json');
      expect(file.existsSync(), isTrue,
          reason: 'bundled KB must exist at the documented path');
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      final items = (decoded['items'] as List)
          .map((e) =>
              TeacherGuidanceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      expect(items.length, greaterThanOrEqualTo(10));
      for (final item in items) {
        expect(item.isValid, isTrue, reason: 'item ${item.id} invalid');
        expect(item.answerHindi.trim(), isNotEmpty);
        expect(item.answerEnglish.trim(), isNotEmpty);
      }
      final ids = items.map((e) => e.id).toSet();
      for (final required in [
        'numbers_up_to_100',
        'counting_activity',
        'place_value_tens_ones',
        'addition_concrete',
        'shapes_intro',
        'vocabulary_building',
        'reading_simple_text',
        'writing_sentences',
        'oral_speaking_practice',
        'classroom_activity_generic',
        'numbers_simplify',
        'numbers_assessment',
        'numbers_example',
        'place_value_difficulty',
      ]) {
        expect(ids, contains(required));
      }
    });
  });

  group('Matching (offline, deterministic)', () {
    test('1. exact English question matches numbers item', () async {
      final bundle = _JsonBundle(_testKbJson);
      final r = await _repo(bundle).answerQuestion(
        'How should I teach numbers up to 100?',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.needsClarification, isFalse);
      expect(r.item!.id, 'numbers_up_to_100');
      expect(r.score, greaterThanOrEqualTo(r.threshold));
    });

    test('2. English keyword variation matches counting activity', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'Give me a counting activity.',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'counting_activity');
    });

    test('3. Hindi question matches place value item', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'दहाई और इकाई कैसे समझाएँ?',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'place_value_tens_ones');
    });

    test('4. Hindi keyword variation picks highest-scoring item', () async {
      // "गिनती" hits both numbers + counting, but the TEACHING_METHOD
      // intent ("कैसे") plus topic context ranks numbers first.
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'गिनती कैसे सिखाएँ?',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'numbers_up_to_100');
    });

    test('5. current topic resolves "this"', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How should I teach this?',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'numbers_up_to_100');
    });

    test('6. class context never vetoes a strong keyword match', () async {
      const otherClass = TeacherGuidanceContext(
        className: 'Class 1',
        subject: 'Mathematics',
      );
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How can I explain place value?',
        context: otherClass,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'place_value_tens_ones');
    });

    test('7. subject context never vetoes a strong keyword match', () async {
      const otherSubject = TeacherGuidanceContext(
        className: 'Class 2',
        subject: 'Mathematics',
      );
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How can I explain place value?',
        context: otherSubject,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'place_value_tens_ones');
    });

    test('8. correct highest-scoring match wins outright', () async {
      // Exact pattern (+5) + keywords beats any partial overlap.
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'What activity can I use for counting?',
        context: _mathNumbersCtx,
      );
      expect(r.needsClarification, isFalse);
      expect(r.item!.id, 'counting_activity');
    });

    test('9. near-tie returns clarification instead of guessing', () async {
      // "game activity" hits counting_activity and
      // classroom_activity_generic with identical scores (keyword +
      // intent + context), so the engine must ask, not guess.
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'game activity',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.needsClarification, isTrue);
      expect(r.clarificationOptions.length, 2);
      expect(
        r.clarificationOptions.map((e) => e.id).toSet(),
        {'counting_activity', 'classroom_activity_generic'},
      );
    });

    test('10. unknown question returns fixed unavailable message', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'What is the capital of France?',
        context: _mathNumbersCtx,
      );
      expect(r.isUnknown, isTrue);
      expect(r.item, isNull);
      expect(PrototypeTeacherGuidanceRepository.unknownAnswerHindi,
          'इस प्रश्न के लिए अभी ऑफलाइन मार्गदर्शन उपलब्ध नहीं है।');
      expect(PrototypeTeacherGuidanceRepository.unknownAnswerEnglish,
          'Offline guidance for this question is not available yet.');
    });

    test('11. empty question is unknown (never invents)', () async {
      final repo = _repo(_JsonBundle(_testKbJson));
      for (final q in ['', '   ', '...?!']) {
        final r = await repo.answerQuestion(q, context: _mathNumbersCtx);
        expect(r.isUnknown, isTrue, reason: 'question: "$q"');
      }
    });

    test('12. punctuation normalization still matches', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How should I teach numbers up to 100?!?...',
        context: _mathNumbersCtx,
      );
      expect(r.item!.id, 'numbers_up_to_100');
    });

    test('13. multiple-space normalization still matches', () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How   should  I teach   numbers up to  100',
        context: _mathNumbersCtx,
      );
      expect(r.item!.id, 'numbers_up_to_100');
    });

    test('14/15. fully offline: only the bundled asset is read', () async {
      final bundle = _JsonBundle(_testKbJson);
      final repo = _repo(bundle);
      final r = await repo.answerQuestion(
        'How should I teach numbers up to 100?',
        context: _mathNumbersCtx,
      );
      expect(r.item!.id, 'numbers_up_to_100');
      expect(
        bundle.requestedKeys,
        [PrototypeTeacherGuidanceRepository.assetPath],
        reason: 'no other asset, no network path may be touched',
      );
      expect(repo.isLoaded, isTrue);
      // Second lookup reuses the in-memory cache (no reload).
      bundle.requestedKeys.clear();
      await repo.answerQuestion('गिनती कैसे सिखाएँ?',
          context: _mathNumbersCtx);
      expect(bundle.requestedKeys, isEmpty);
    });

    test('16/17. Hindi AND English answers are returned pre-authored',
        () async {
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How should I teach numbers up to 100?',
        context: _mathNumbersCtx,
      );
      expect(r.item!.answerHindi, 'परीक्षण हिंदी उत्तर गिनती।');
      expect(r.item!.answerEnglish, 'Test English answer counting.');
    });

    test('18. correct item returned for current topic', () async {
      const placeValueCtx = TeacherGuidanceContext(
        className: 'Class 2',
        subject: 'Mathematics',
        topic: 'Place Value',
      );
      final r = await _repo(_JsonBundle(_testKbJson)).answerQuestion(
        'How should I teach this?',
        context: placeValueCtx,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.id, 'place_value_tens_ones');
    });

    test('threshold is configurable', () async {
      final repo = _repo(_JsonBundle(_testKbJson));
      final strict = await repo.answerQuestion(
        'How should I teach this?',
        context: _mathNumbersCtx,
        threshold: 999,
      );
      expect(strict.isUnknown, isTrue);
    });
  });

  group('19. teacher history isolation', () {
    test('owners never see each other\'s questions', () {
      final store = TeacherGuidanceHistoryStore();
      store.record(
          ownerUserId: 'teacherA',
          question: 'q-a',
          matchedItemId: 'numbers_up_to_100');
      store.record(
          ownerUserId: 'teacherB',
          question: 'q-b',
          matchedItemId: 'place_value_tens_ones');

      final a = store.recent('teacherA');
      final b = store.recent('teacherB');
      expect(a.map((e) => e.question), ['q-a']);
      expect(b.map((e) => e.question), ['q-b']);

      store.clear('teacherB');
      expect(store.recent('teacherB'), isEmpty);
      expect(store.recent('teacherA').length, 1);
    });
  });

  group('TeacherGuidanceScreen (offline widget)', () {
    Widget harness() {
      final repo =
          _repo(_JsonBundle(_testKbJson));
      return MaterialApp(
        home: TeacherGuidanceScreen(
          initialContext: _mathNumbersCtx,
          repository: repo,
        ),
      );
    }

    Future<void> ask(WidgetTester tester, String question) async {
      await tester.enterText(
          find.byKey(const Key('guidanceQuestionField')), question);
      await tester.tap(find.byKey(const Key('guidanceAskButton')));
      await tester.pump(); // show Processing...
      expect(find.byKey(const Key('guidanceProcessing')), findsOneWidget);
      await tester.pumpAndSettle();
    }

    testWidgets('asks exact question, shows Hindi + English answers',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.text('Class 2 • Mathematics'), findsOneWidget);
      expect(find.text('Numbers up to 100'), findsOneWidget);
      expect(find.byKey(const Key('guidanceOfflineIndicator')),
          findsOneWidget);

      await ask(tester, 'How should I teach numbers up to 100?');
      expect(find.byKey(const Key('guidanceResultCard')), findsOneWidget);
      expect(find.text('परीक्षण हिंदी उत्तर गिनती।'), findsOneWidget);
      expect(find.text('Test English answer counting.'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown question shows fixed unavailable message',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await ask(tester, 'What is the capital of France?');
      expect(
          find.text(
              'इस प्रश्न के लिए अभी ऑफलाइन मार्गदर्शन उपलब्ध नहीं है।'),
          findsOneWidget);
      expect(
          find.text(
              'Offline guidance for this question is not available yet.'),
          findsOneWidget);
      expect(find.text('Try Another Question'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clarification choice leads to an answer', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await ask(tester, 'game activity');
      expect(find.text('I found guidance for:'), findsOneWidget);
      await tester.tap(
          find.byKey(const Key('clarification_counting_activity')));
      await tester.pumpAndSettle();
      expect(
          find.text('परीक्षण हिंदी उत्तर गतिविधि।'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick chip asks and Try Another resets', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('How should I teach this?'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guidanceResultCard')), findsOneWidget);
      expect(find.text('परीक्षण हिंदी उत्तर गिनती।'), findsOneWidget);

      await tester.tap(
          find.byKey(const Key('guidanceTryAnotherButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guidanceResultCard')), findsNothing);
      expect(find.byKey(const Key('guidanceQuestionField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hindi question answered on narrow phone (360px)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await ask(tester, 'दहाई और इकाई कैसे समझाएँ?');
      expect(find.text('परीक्षण हिंदी उत्तर दहाई।'), findsOneWidget);
      expect(find.text('Test English answer place value.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
