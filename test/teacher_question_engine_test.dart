import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/teacher_assist/teacher_question_engine.dart';

/// Spec dynamic_keyword_teacher_guidance_copilot §38-41 test matrix.
/// Fully offline: the engine is built from the REAL shipped JSON files
/// (copilot + teacher_guidance), no network, no LLM.
List<Map<String, dynamic>> _shippedRawItems() {
  final copilot = jsonDecode(File(
          'assets/prototype_content/copilot/teacher_copilot_knowledge.json')
      .readAsStringSync()) as Map<String, dynamic>;
  final guidance = jsonDecode(File(
          'assets/prototype_content/teacher_guidance/teacher_guidance.json')
      .readAsStringSync()) as Map<String, dynamic>;
  final out = <Map<String, dynamic>>[];
  for (final e in (copilot['items'] as List)) {
    out.add(Map<String, dynamic>.from(e as Map));
  }
  for (final e in (guidance['items'] as List)) {
    out.add(Map<String, dynamic>.from(e as Map));
  }
  return out;
}

TeacherQuestionEngine _engine() =>
    TeacherQuestionEngine.withItems(_shippedRawItems());

const _ctx = LessonContext(
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared engine loads both knowledge bases', () {
    test('parses copilot + guidance + subject_sequence', () async {
      final engine = _engine();
      final items = await engine.loadItems();
      expect(items.length, greaterThanOrEqualTo(20));
      final ids = items.map((e) => e.id).toSet();
      expect(ids, contains('worksheet_generation'));
      expect(ids, contains('flashcard_generation'));
      expect(ids, contains('subject_sequence'));
      expect(ids, contains('numbers_up_to_100'));
      expect(ids, contains('numbers_simplify'));
      expect(ids, contains('numbers_assessment'));
    });

    test('no network imports in the shared engine', () {
      final src = File(
              'lib/core/teacher_assist/teacher_question_engine.dart')
          .readAsStringSync();
      for (final token in [
        'package:http',
        'supabase',
        'sarvam',
        'HttpClient',
        'dart:io',
      ]) {
        expect(src.contains(token), isFalse,
            reason: 'engine must stay offline (found "$token")');
      }
    });
  });

  group('Spec §38 test matrix (dynamic answers)', () {
    test('1. worksheet generate kidhar -> WORKSHEET_GENERATION', () async {
      final r = await _engine().resolve(
        'mujhe worksheet generate karni hain main kidhar jau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.intent, 'WORKSHEET_GENERATION');
      expect(r.knowledgeItemId, 'worksheet_generation');
      expect(r.answer,
          'आप Bilingual Worksheet Generator में जाकर worksheet बना सकते हैं।');
      expect(r.route, '/resources/worksheet-generator');
    });

    test('2. bilingual worksheet with images -> WORKSHEET_GENERATION',
        () async {
      final r = await _engine().resolve(
        'how can I make bilingual worksheet with images',
        context: _ctx,
        answerLanguage: AnswerLanguage.english,
      );
      expect(r.matched, isTrue);
      expect(r.intent, 'WORKSHEET_GENERATION');
      expect(r.answer,
          'You can create a worksheet from the Bilingual Worksheet Generator.');
    });

    test('3. flashcard banana -> FLASHCARD_GENERATION', () async {
      final r = await _engine().resolve(
        'mujhe flashcard banana hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'FLASHCARD_GENERATION');
      expect(r.route, '/resources/flashcards');
    });

    test('4. assessment kaha hai -> ASSESSMENT', () async {
      final r = await _engine().resolve(
        'assessment kaha hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'ASSESSMENT');
      expect(r.route, '/assessment/builder');
    });

    test('5. translate kaise karna hai -> LIVE_TRANSLATION', () async {
      final r = await _engine().resolve(
        'translate kaise karna hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'LIVE_TRANSLATION');
      expect(r.route, '/translate');
    });

    test('6. mere downloads kaha hain -> DOWNLOADS', () async {
      final r = await _engine().resolve(
        'mere downloads kaha hain',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'DOWNLOADS');
      expect(r.route, '/resources/downloads');
    });

    test('7. numbers kaise padhau -> numbers TEACHING_METHOD', () async {
      final r = await _engine().resolve(
        'numbers kaise padhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.knowledgeItemId, 'numbers_up_to_100');
    });

    test('8. numbers activity -> counting_activity', () async {
      final r = await _engine().resolve(
        'numbers ke liye ek activity batao',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.knowledgeItemId, 'counting_activity');
    });

    test('9. numbers simple samjhau -> numbers_simplify', () async {
      final r = await _engine().resolve(
        'numbers ko simple kaise samjhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.knowledgeItemId, 'numbers_simplify');
    });

    test('10. numbers assessment -> numbers_assessment', () async {
      final r = await _engine().resolve(
        'numbers ka assessment kaise karu',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.knowledgeItemId, 'numbers_assessment');
    });

    test('11. maths ke baad konsa subject -> SUBJECT_PLANNING', () async {
      final r = await _engine().resolve(
        'mujhe maths ke baad konsa subject padhana chahiye',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.intent, 'SUBJECT_PLANNING');
      expect(r.knowledgeItemId, 'subject_sequence');
      // Must NOT leak into worksheet/flashcard/assessment.
      expect(r.intent, isNot('WORKSHEET_GENERATION'));
      expect(r.intent, isNot('FLASHCARD_GENERATION'));
      expect(r.intent, isNot('ASSESSMENT'));
    });

    test('12. unsupported -> UNKNOWN (never invents)', () async {
      final r = await _engine().resolve(
        'what is the capital of france',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.isUnknown, isTrue);
      expect(r.answer, TeacherQuestionEngine.unknownAnswerHindi);
      expect(r.route, isNull);
    });

    test('13. worksheet + flashcard -> CLARIFICATION', () async {
      final r = await _engine().resolve(
        'mujhe worksheet aur flashcard banana hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.answer, 'आप किस resource से शुरू करना चाहते हैं?');
      expect(
        r.clarificationOptions.map((e) => e.intent).toSet(),
        {'WORKSHEET_GENERATION', 'FLASHCARD_GENERATION'},
      );
    });
  });

  group('Quick questions resolve through the same engine', () {
    test('Worksheet कैसे बनाएं? query', () async {
      final r = await _engine().resolve(
        'mujhe worksheet generate karni hai main kidhar jau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'WORKSHEET_GENERATION');
    });

    test('ek activity batao without topic -> TOPIC clarification', () async {
      final r = await _engine().resolve(
        'ek activity batao',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      // No explicit topic and no conversation topic: must ASK, never
      // auto-answer a random topic (e.g. Numbers).
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.clarificationKind, 'topic');
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
      expect(r.pendingIntent, 'ACTIVITY');
      expect(
        r.clarificationOptions.map((e) => e.label),
        contains('Numbers up to 100'),
      );
    });

    test('Flashcard बनाएं query', () async {
      final r = await _engine().resolve(
        'mujhe flashcard banana hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'FLASHCARD_GENERATION');
    });

    test('Assessment करें query', () async {
      final r = await _engine().resolve(
        'assessment kaha hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'ASSESSMENT');
    });
  });

  group('Answer language preference (§40)', () {
    test('Hindi preference -> Hindi answer, same intent', () async {
      final hi = await _engine().resolve(
        'mujhe worksheet generate karni hain',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      final en = await _engine().resolve(
        'mujhe worksheet generate karni hain',
        context: _ctx,
        answerLanguage: AnswerLanguage.english,
      );
      expect(hi.intent, en.intent);
      expect(hi.knowledgeItemId, en.knowledgeItemId);
      expect(hi.answer, contains('जाकर'));
      expect(en.answer,
          'You can create a worksheet from the Bilingual Worksheet Generator.');
    });
  });

  group('Current context (§41, corrected: page context never selects)', () {
    test('ye kaise samjhau -> TOPIC clarification, not numbers', () async {
      final r = await _engine().resolve(
        'ye kaise samjhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.clarificationKind, 'topic');
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
      expect(r.pendingIntent, 'SIMPLIFY');
      expect(
        r.clarificationOptions.map((e) => e.label),
        containsAll(
            ['Numbers up to 100', 'Place Value', 'Addition', 'Shapes']),
      );
    });

    test('explicit worksheet beats lesson context', () async {
      final r = await _engine().resolve(
        'worksheet kaha hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.intent, 'WORKSHEET_GENERATION');
    });
  });

  group('Follow-up + threshold', () {
    test('haan kholo reopens last route', () async {
      final engine = _engine();
      final first = await engine.resolve(
        'mujhe worksheet generate karni hain main kidhar jau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      final second = await engine.resolve(
        'haan kholo',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
        conversationContext: first.nextContext,
      );
      expect(second.isFollowUpOpen, isTrue);
      expect(second.route, '/resources/worksheet-generator');
    });

    test('strict threshold returns unknown', () async {
      final r = await _engine().resolve(
        'worksheet kaha hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
        threshold: 999,
      );
      expect(r.isUnknown, isTrue);
    });

    test('unknown never reuses previous answer', () async {
      final engine = _engine();
      final first = await engine.resolve(
        'mujhe worksheet generate karni hain main kidhar jau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(first.matched, isTrue);
      final second = await engine.resolve(
        'blarg wugga zug',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
        conversationContext: first.nextContext,
      );
      expect(second.isUnknown, isTrue);
      expect(second.answer, isNot(first.answer));
    });
  });

  group('CRITICAL: vague questions never auto-select a topic (§20)', () {
    const vague = 'mujhe ye kaise padhana hai';

    test('Class 2 Math Numbers page -> CLARIFICATION, not Numbers',
        () async {
      final r = await _engine().resolve(
        vague,
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.isUnknown, isFalse);
      expect(r.clarificationKind, 'topic');
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
      expect(r.pendingIntent, 'TEACHING_METHOD');
      expect(r.knowledgeItemId, isNull);
      expect(
        r.clarificationOptions.map((e) => e.label),
        containsAll(
            ['Numbers up to 100', 'Place Value', 'Addition', 'Shapes']),
      );
    });

    test('English answer language -> English clarification', () async {
      final r = await _engine().resolve(
        vague,
        context: _ctx,
        answerLanguage: AnswerLanguage.english,
      );
      expect(r.needsClarification, isTrue);
      expect(r.answer, TeacherQuestionEngine.topicClarifyEnglish);
    });

    test('Class 1 Language Reading page -> CLARIFICATION, not Reading',
        () async {
      final r = await _engine().resolve(
        vague,
        context: const LessonContext(
          className: 'Class 1',
          subject: 'Language',
          topic: 'Reading',
        ),
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.knowledgeItemId, isNull);
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
    });

    test('Class 3 Math Addition page -> CLARIFICATION, not Addition',
        () async {
      final r = await _engine().resolve(
        vague,
        context: const LessonContext(
          className: 'Class 3',
          subject: 'Mathematics',
          topic: 'Addition',
        ),
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.knowledgeItemId, isNull);
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
    });

    test('vague variants (§8) all clarify without context', () async {
      for (final q in [
        'mujhe ye kaise padhana hai',
        'isko kaise samjhau',
        'ye kaise sikhau',
        'how should I teach this',
        'how can I explain this',
        'iske liye activity batao',
        'iske liye example do',
      ]) {
        final r = await _engine().resolve(
          q,
          context: _ctx,
          answerLanguage: AnswerLanguage.hindi,
        );
        expect(r.needsClarification, isTrue, reason: 'query: $q');
        expect(r.matched, isFalse, reason: 'query: $q');
        expect(r.clarificationKind, 'topic', reason: 'query: $q');
      }
    });
  });

  group('Topic picker data source (§11, §21)', () {
    test('getAvailableTopics reads Class 2 Mathematics from the KB',
        () async {
      final topics = await _engine().getAvailableTopics(
        className: 'Class 2',
        subject: 'Mathematics',
      );
      expect(topics,
          ['Numbers up to 100', 'Place Value', 'Addition', 'Shapes']);
    });

    test('full picker flow: clarify -> Addition -> teaching answer',
        () async {
      final engine = _engine();
      final first = await engine.resolve(
        'mujhe ye kaise padhana hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(first.needsClarification, isTrue);
      expect(first.pendingIntent, 'TEACHING_METHOD');

      // Teacher taps [ Addition ], original intent answers directly.
      final second = await engine.answerForTopicIntent(
        topic: 'Addition',
        intent: first.pendingIntent!,
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(second.matched, isTrue);
      expect(second.knowledgeItemId, 'addition_concrete');
      expect(second.nextContext.lastTopic, 'Addition');
    });

    test('topic without pending intent -> 5 predefined help options',
        () async {
      final engine = _engine();
      final first = await engine.resolve(
        'numbers',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(first.needsClarification, isTrue);
      expect(first.pendingIntent, isNull);

      final options = TeacherQuestionEngine.helpIntentOptions();
      expect(options.map((e) => e.label), [
        'How should I teach it?',
        'Give me an activity',
        'Give me an example',
        'How can I simplify it?',
        'How should I assess it?',
      ]);

      final second = await engine.answerForTopicIntent(
        topic: 'Numbers up to 100',
        intent: 'ACTIVITY',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(second.matched, isTrue);
      expect(second.knowledgeItemId, 'counting_activity');
    });
  });

  group('Explicit topic answers directly (§22, §17)', () {
    test('numbers kaise padhau -> Numbers answer, no clarification',
        () async {
      final r = await _engine().resolve(
        'numbers kaise padhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.needsClarification, isFalse);
      expect(r.knowledgeItemId, 'numbers_up_to_100');
      expect(r.nextContext.lastTopic, 'Numbers up to 100');
    });

    test('addition kaise samjhau on Numbers page -> Addition answer',
        () async {
      final r = await _engine().resolve(
        'addition kaise samjhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.matched, isTrue);
      expect(r.knowledgeItemId, 'addition_concrete');
    });
  });

  group('Follow-up context (§23, §24)', () {
    test('activity follow-up resolves to the established topic', () async {
      final engine = _engine();
      final first = await engine.resolve(
        'numbers kaise padhau',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(first.matched, isTrue);

      final second = await engine.resolve(
        'iske liye ek activity batao',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
        conversationContext: first.nextContext,
      );
      expect(second.matched, isTrue);
      expect(second.knowledgeItemId, 'counting_activity');
    });

    test('anaphoric follow-up without context -> clarification', () async {
      final r = await _engine().resolve(
        'iske liye ek activity batao',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.answer, TeacherQuestionEngine.topicClarifyHindi);
      expect(r.pendingIntent, 'ACTIVITY');
    });
  });

  group('Unknown + planning (§25, §26, §7)', () {
    test('train ticket -> unavailable, no topic picker', () async {
      final r = await _engine().resolve(
        'train ticket kaise book karu',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.isUnknown, isTrue);
      expect(r.needsClarification, isFalse);
      expect(r.answer, TeacherQuestionEngine.unknownAnswerHindi);
      expect(r.clarificationOptions, isEmpty);
    });

    test('mujhe konsa topic padhana hai -> topic list, no auto-pick',
        () async {
      final r = await _engine().resolve(
        'mujhe konsa topic padhana hai',
        context: _ctx,
        answerLanguage: AnswerLanguage.hindi,
      );
      expect(r.needsClarification, isTrue);
      expect(r.matched, isFalse);
      expect(r.answer, TeacherQuestionEngine.topicListHindi);
      expect(
        r.clarificationOptions.map((e) => e.label),
        contains('Addition'),
      );
    });
  });
}
