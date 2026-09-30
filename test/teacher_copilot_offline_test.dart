import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/copilot/copilot_engine.dart';
import 'package:maatribhasha/core/copilot/copilot_models.dart';
import 'package:maatribhasha/core/copilot/copilot_normalizer.dart';
import 'package:maatribhasha/core/copilot/copilot_store.dart';
import 'package:maatribhasha/core/copilot/widgets/copilot_button.dart';
import 'package:maatribhasha/core/copilot/widgets/copilot_chat_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Teacher Co-Pilot tests. No network, no backend, no LLM.
/// The engine is exercised against the REAL shipped JSON knowledge base
/// (parsed from assets/), with a stubbed guidance lookup standing in for
/// the existing PrototypeTeacherGuidanceRepository.
List<CopilotKnowledgeItem> _shippedItems() {
  final file = File(
      'assets/prototype_content/copilot/teacher_copilot_knowledge.json');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (decoded['items'] as List)
      .map((e) => CopilotKnowledgeItem.fromJson(
          Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Mimics the real PrototypeTeacherGuidanceRepository: returns a
/// pre-authored answer only when the expanded query carries a teaching
/// signal, else null (which the engine turns into the fixed unknown).
Future<CopilotGuidanceAnswer?> _stubGuidance(
    String query, CopilotLessonContext lesson) async {
  const signals = [
    'numbers',
    'addition',
    'activity',
    'teach',
    'how to',
    'explain',
    'game',
    'counting',
    '100',
  ];
  if (!signals.any(query.contains)) return null;
  if (query.contains('addition')) {
    return const CopilotGuidanceAnswer(
      answerHindi: 'जोड़ मूर्त वस्तुओं से शुरू करें।',
      answerEnglish: 'Start addition with concrete objects.',
      topic: 'Addition',
    );
  }
  return CopilotGuidanceAnswer(
    answerHindi: 'परीक्षण हिंदी मार्गदर्शन।',
    answerEnglish: 'Test English guidance.',
    topic: (lesson.topic ?? '').isNotEmpty
        ? lesson.topic!
        : 'Numbers up to 100',
  );
}

CopilotEngine _engine() =>
    CopilotEngine.withItems(_shippedItems(), guidanceLookup: _stubGuidance);

const _ctx = CopilotLessonContext(
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
);

void main() {
  // Plain `test` cases below use SharedPreferences (method channels), so
  // the binding must exist before any of them run.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shipped knowledge base files', () {
    test('knowledge JSON parses with 12 valid navigation items', () {
      final items = _shippedItems();
      expect(items.length, greaterThanOrEqualTo(12));
      for (final item in items) {
        expect(item.isValid, isTrue, reason: 'item ${item.id} invalid');
      }
      final intents = items.map((e) => e.intent).toSet();
      for (final required in [
        'WORKSHEET_GENERATION',
        'FLASHCARD_GENERATION',
        'ASSESSMENT',
        'TEACHER_GUIDANCE',
        'LIVE_TRANSLATION',
        'DOWNLOADS',
        'PROGRESS',
        'TEACH',
        'SETTINGS',
        'OFFLINE_CONTENT',
        'ACTIVITY_LIBRARY',
        'RESOURCE_DETAIL',
      ]) {
        expect(intents, contains(required));
      }
    });

    test('every route points at a real AppRoutes path (no dead buttons)',
        () {
      const validRoutes = {
        '/resources/worksheet-generator',
        '/resources/flashcards',
        '/assessment/builder',
        '/teach/guidance',
        '/translate',
        '/resources/downloads',
        '/progress',
        '/teach',
        '/settings',
        '/offline/content',
        '/resources/activities',
        '/resources/topic',
      };
      for (final item in _shippedItems()) {
        expect(validRoutes, contains(item.route),
            reason: 'item ${item.id} has unknown route ${item.route}');
      }
      final navFile = File(
          'assets/prototype_content/copilot/navigation_intents.json');
      expect(navFile.existsSync(), isTrue);
      final nav = jsonDecode(navFile.readAsStringSync())
          as Map<String, dynamic>;
      for (final e in (nav['intents'] as List)) {
        expect(validRoutes, contains((e as Map)['route']));
      }
      final quickFile =
          File('assets/prototype_content/copilot/quick_questions.json');
      expect(quickFile.existsSync(), isTrue);
      final quick =
          jsonDecode(quickFile.readAsStringSync()) as Map<String, dynamic>;
      expect((quick['defaultQuestions'] as List).length,
          greaterThanOrEqualTo(6));
    });
  });

  group('Normalization (Roman Hindi)', () {
    test('trims, lowercases, collapses spaces, strips punctuation', () {
      expect(CopilotNormalizer.normalize('  Mujhe   Worksheet?! '),
          'mujhe worksheet');
    });

    test('worksheet spelling variants unify', () {
      expect(CopilotNormalizer.normalize('Worksheets'), 'worksheet');
      expect(CopilotNormalizer.normalize('WORK SHEET'), 'worksheet');
      expect(CopilotNormalizer.normalize('practice sheet'), 'worksheet');
    });

    test('flashcard spelling variants unify', () {
      expect(CopilotNormalizer.normalize('Flash Cards'), 'flashcard');
      expect(CopilotNormalizer.normalize('flashcards'), 'flashcard');
    });

    test('Roman Hindi variants map to canonical tokens', () {
      expect(CopilotNormalizer.normalize('kahan'), 'kaha');
      expect(CopilotNormalizer.normalize('kidhar'), 'kidhar');
      expect(CopilotNormalizer.normalize('banani'), 'banana');
      expect(CopilotNormalizer.normalize('padhau'), 'padhau');
    });

    test('empty input normalizes to empty', () {
      expect(CopilotNormalizer.normalize(''), '');
      expect(CopilotNormalizer.normalize('  ...?! '), '');
    });
  });

  group('Navigation intents (offline, deterministic)', () {
    test('1. worksheet question -> WORKSHEET_GENERATION', () async {
      final r = await _engine().answer(
        'mujhe worksheet generate karni hain main kidhar jau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.intent, 'WORKSHEET_GENERATION');
      expect(r.route, '/resources/worksheet-generator');
      expect(r.answer, 'आप Bilingual Worksheet Generator में जाकर worksheet बना सकते हैं।');
    });

    test('2. explicit open -> WORKSHEET_GENERATION + autoNavigate', () async {
      final r = await _engine().answer(
        'worksheet generator kholo',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'WORKSHEET_GENERATION');
      expect(r.autoNavigate, isTrue);
    });

    test('3. flashcard banana -> FLASHCARD_GENERATION', () async {
      final r = await _engine().answer(
        'mujhe flashcard banana hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'FLASHCARD_GENERATION');
      expect(r.route, '/resources/flashcards');
      expect(r.answer, 'आप Flashcard Generator से visual flashcards बना सकते हैं।');
    });

    test('4. flashcard kaha milega -> FLASHCARD_GENERATION', () async {
      final r = await _engine().answer(
        'flashcard kaha milega',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'FLASHCARD_GENERATION');
    });

    test('5. assessment kaha hai -> ASSESSMENT', () async {
      final r = await _engine().answer(
        'assessment kaha hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'ASSESSMENT');
      expect(r.route, '/assessment/builder');
    });

    test('6. quiz banana hai -> ASSESSMENT', () async {
      final r = await _engine().answer(
        'quiz banana hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'ASSESSMENT');
    });

    test('7. translation kaha hai -> LIVE_TRANSLATION', () async {
      final r = await _engine().answer(
        'translation kaha hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'LIVE_TRANSLATION');
      expect(r.route, '/translate');
    });

    test('8. mere downloads kaha hain -> DOWNLOADS', () async {
      final r = await _engine().answer(
        'mere downloads kaha hain',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'DOWNLOADS');
      expect(r.route, '/resources/downloads');
    });
  });

  group('Teaching guidance (reuses offline guidance answers)', () {
    test('9. numbers kaise padhau -> current-topic guidance', () async {
      final r = await _engine().answer(
        'numbers kaise padhau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.intent, 'TEACHER_GUIDANCE');
      expect(r.answer, 'परीक्षण हिंदी मार्गदर्शन।');
      expect(r.nextContext.lastTopic, 'Numbers up to 100');
    });

    test('10. ek activity batao -> activity guidance for topic', () async {
      final r = await _engine().answer(
        'ek activity batao',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.intent, 'TEACHER_GUIDANCE');
    });

    test('11. addition kaise samjhau -> addition guidance', () async {
      final r = await _engine().answer(
        'addition kaise samjhau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.answer, 'जोड़ मूर्त वस्तुओं से शुरू करें।');
    });

    test('"ye" resolves to the current lesson topic', () async {
      final r = await _engine().answer(
        'mujhe ye kaise padhana hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.item!.intent, 'TEACHER_GUIDANCE');
      expect(r.nextContext.lastTopic, 'Numbers up to 100');
    });
  });

  group('Answer language preference', () {
    test('12. Hindi preference -> Hindi answer', () async {
      final r = await _engine().answer(
        'mujhe worksheet generate karni hain main kidhar jau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.answer, contains('Bilingual Worksheet Generator'));
      expect(r.answer, contains('जाकर'));
    });

    test('13. English preference -> English answer', () async {
      final r = await _engine().answer(
        'mujhe worksheet generate karni hain main kidhar jau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.english,
      );
      expect(r.answer,
          'You can create a worksheet from the Bilingual Worksheet Generator.');
    });
  });

  group('Offline behavior (no network surface)', () {
    test('14-17. copilot lib files import no network packages', () {
      const forbidden = [
        'package:http',
        'supabase',
        'sarvam',
        'HttpClient',
        'Socket',
        'dart:io',
      ];
      final dir = Directory('lib/core/copilot');
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty);
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final token in forbidden) {
          expect(src.contains(token), isFalse,
              reason: '${f.path} must stay offline (found "$token")');
        }
      }
    });

    test('engine answers with bundled items only (no asset/network)',
        () async {
      final engine = _engine();
      final r = await engine.answer(
        'assessment kaha hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.item!.intent, 'ASSESSMENT');
    });
  });

  group('Conversation context', () {
    test('18. "haan kholo" reopens the last suggested route', () async {
      final engine = _engine();
      final first = await engine.answer(
        'mujhe worksheet generate karni hain main kidhar jau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(first.route, '/resources/worksheet-generator');
      final followUp = await engine.answer(
        'haan kholo',
        lesson: _ctx,
        conversation: first.nextContext,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(followUp.isFollowUpOpen, isTrue);
      expect(followUp.route, '/resources/worksheet-generator');
      expect(followUp.autoNavigate, isTrue);
    });

    test('19. activity follow-up keeps the current topic', () async {
      final engine = _engine();
      final first = await engine.answer(
        'numbers kaise padhau',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      final second = await engine.answer(
        'ek activity batao',
        lesson: _ctx,
        conversation: first.nextContext,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(second.isUnknown, isFalse);
      expect(second.nextContext.lastTopic, 'Numbers up to 100');
    });

    test('20. unknown query shows the fixed fallback (never invents)',
        () async {
      final engine = _engine();
      final hi = await engine.answer(
        'what is the capital of france',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(hi.isUnknown, isTrue);
      expect(hi.answer, CopilotEngine.unknownAnswerHindi);
      expect(hi.route, isNull);
      final en = await engine.answer(
        'what is the capital of france',
        lesson: _ctx,
        language: CopilotAnswerLanguage.english,
      );
      expect(en.answer, CopilotEngine.unknownAnswerEnglish);
    });

    test('21. ambiguous query asks for clarification', () async {
      final r = await _engine().answer(
        'worksheet banana flashcard banana',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
      );
      expect(r.isUnknown, isFalse);
      expect(r.needsClarification, isTrue);
      expect(r.clarificationOptions.length, 2);
      expect(
        r.clarificationOptions.map((e) => e.intent).toSet(),
        {'WORKSHEET_GENERATION', 'FLASHCARD_GENERATION'},
      );
    });

    test('strict threshold returns unknown', () async {
      final r = await _engine().answer(
        'worksheet kaha hai',
        lesson: _ctx,
        language: CopilotAnswerLanguage.hindi,
        threshold: 999,
      );
      expect(r.isUnknown, isTrue);
    });
  });

  group('Account isolation (CopilotStore)', () {
    test('language preference is scoped per teacher account', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storeA =
          CopilotStore(ownerIdProvider: () => 'teacherA', prefsOverride: prefs);
      final storeB =
          CopilotStore(ownerIdProvider: () => 'teacherB', prefsOverride: prefs);
      expect(await storeA.getLanguage(), isNull);
      await storeA.setLanguage(CopilotAnswerLanguage.hindi);
      await storeB.setLanguage(CopilotAnswerLanguage.english);
      expect(await storeA.getLanguage(), CopilotAnswerLanguage.hindi);
      expect(await storeB.getLanguage(), CopilotAnswerLanguage.english);
    });

    test('conversation context never leaks across accounts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storeA =
          CopilotStore(ownerIdProvider: () => 'teacherA', prefsOverride: prefs);
      final storeB =
          CopilotStore(ownerIdProvider: () => 'teacherB', prefsOverride: prefs);
      storeA.saveConversation(const CopilotConversationContext(
        lastIntent: 'WORKSHEET_GENERATION',
        lastRoute: '/resources/worksheet-generator',
      ));
      expect(storeA.conversation().lastRoute,
          '/resources/worksheet-generator');
      expect(storeB.conversation().isEmpty, isTrue);
      storeA.clearConversation();
      expect(storeA.conversation().isEmpty, isTrue);
    });
  });

  group('Co-Pilot widgets (offline)', () {
    testWidgets('button renders with Co-Pilot label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopilotButton(onTap: () {}),
          ),
        ),
      );
      expect(find.byKey(const Key('copilotFab')), findsOneWidget);
      expect(find.text('Co-Pilot'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chat sheet asks language first, then answers offline',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopilotChatSheet(
              engine: _engine(),
              store: CopilotStore(
                  ownerIdProvider: () => 'widgetTeacher',
                  prefsOverride: prefs),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Teacher Co-Pilot'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copilotInput')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('copilotInput')),
          'mujhe worksheet generate karni hain main kidhar jau');
      await tester.tap(find.byKey(const Key('copilotSend')));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'आप Bilingual Worksheet Generator में जाकर worksheet बना सकते हैं।'),
          findsOneWidget);
      expect(
          find.byKey(
              const Key('copilotOpen:/resources/worksheet-generator')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
