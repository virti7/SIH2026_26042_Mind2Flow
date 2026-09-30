import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/translation/bidirectional_phrase_bank.dart';
import 'package:maatribhasha/features/smartboard/data/smartboard_demo_items.dart';
import 'package:maatribhasha/features/smartboard/data/smartboard_lesson_store.dart';
import 'package:maatribhasha/features/smartboard/data/smartboard_repository.dart';
import 'package:maatribhasha/features/smartboard/models/smartboard_demo_item.dart';
import 'package:maatribhasha/features/smartboard/models/smartboard_item.dart';
import 'package:maatribhasha/features/smartboard/models/smartboard_language.dart';
import 'package:maatribhasha/features/smartboard/presentation/widgets/smartboard_canvas.dart';

/// MAATRIBHASHA SMARTBOARD prototype tests: deterministic offline
/// Hindi/English → Santali resolution over seeded bank JSON (never the real
/// asset bundle), plus the in-memory lesson session store.
///
/// No network, no ASR, no models. Ho/Mundari stay disabled by construction.
List<Map<String, dynamic>> _seedItems() => [
      {
        'id': 'phrase_001',
        'hindi': 'मुझे यह नहीं समझ रहा है',
        'hindiRoman': 'Mujhe yah nahin samajh raha hai',
        'hindiAudio': 'assets/prototype_content/translation/audio/hindi/h.wav',
        'santaliOlChiki': 'ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
        'santaliRoman': 'Iñ nowa bang bujhaṛ edañ.',
        'santaliAudio': 'assets/prototype_content/translation/audio/santali/s.wav',
        'category': 'classroom',
        'tags': [],
      },
      {
        'id': 'phrase_002',
        'hindi': 'मैं तुम्हें समझाती हूँ',
        'hindiRoman': 'Main tumhe samjhati hu',
        'hindiAudio': '',
        'santaliOlChiki': 'ᱤᱧ ᱟᱢ ᱞᱟᱹᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ',
        'santaliRoman': 'Iñ am lāgit paṛhaw edañ.',
        'santaliAudio': 'assets/prototype_content/translation/audio/santali/s2.wav',
        'category': 'classroom',
        'tags': [],
      },
    ];

SmartBoardRepository _repo() => SmartBoardRepository(
      bank: BidirectionalPhraseBank(seedJson: _seedItems()),
    );

void main() {
  group('SmartBoard Hindi → Santali', () {
    test('resolves मैं तुम्हें समझाती हूँ to phrase_002', () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.hindi,
        'मैं तुम्हें समझाती हूँ',
      );
      expect(phrase, isNotNull);
      expect(phrase!.id, 'phrase_002');
      expect(phrase.santaliOlChiki, 'ᱤᱧ ᱟᱢ ᱞᱟᱹᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ');
      expect(phrase.santaliRoman, 'Iñ am lāgit paṛhaw edañ.');
      expect(phrase.santaliAudio, isNotEmpty);
      expect(BidirectionalPhrase.isLocalAudio(phrase.santaliAudio), isTrue);
    });

    test('resolves मुझे यह नहीं समझ रहा है to phrase_001', () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.hindi,
        'मुझे यह नहीं समझ रहा है',
      );
      expect(phrase, isNotNull);
      expect(phrase!.id, 'phrase_001');
      expect(phrase.santaliOlChiki, 'ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ');
      expect(phrase.santaliRoman, 'Iñ nowa bang bujhaṛ edañ.');
    });

    test('unknown Hindi returns null (never guesses)', () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.hindi,
        'आज मौसम बहुत अच्छा है',
      );
      expect(phrase, isNull);
    });
  });

  group('SmartBoard English → Santali', () {
    test('resolves I explain to you to phrase_002', () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.english,
        'I explain to you',
      );
      expect(phrase, isNotNull);
      expect(phrase!.id, 'phrase_002');
    });

    test("resolves I don't understand this to phrase_001", () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.english,
        "I don't understand this",
      );
      expect(phrase, isNotNull);
      expect(phrase!.id, 'phrase_001');
    });

    test('unknown English returns null (never guesses)', () async {
      final phrase = await _repo().resolve(
        SmartBoardSourceLanguage.english,
        'Please open your mathematics book',
      );
      expect(phrase, isNull);
    });
  });

  group('SmartBoard language model', () {
    test('source offers only Hindi and English', () {
      expect(SmartBoardSourceLanguage.values,
          [SmartBoardSourceLanguage.hindi, SmartBoardSourceLanguage.english]);
    });

    test('only Santali target is enabled; Ho/Mundari are Coming Soon', () {
      expect(SmartBoardTargetLanguage.santali.isEnabled, isTrue);
      expect(SmartBoardTargetLanguage.ho.isEnabled, isFalse);
      expect(SmartBoardTargetLanguage.mundari.isEnabled, isFalse);
      expect(SmartBoardTargetLanguage.ho.disabledHint, 'Coming Soon');
      expect(SmartBoardTargetLanguage.mundari.disabledHint, 'Coming Soon');
    });

    test('demo inputs exist for both source languages', () {
      final repo = _repo();
      expect(
          repo.demoInputs(SmartBoardSourceLanguage.hindi), isNotEmpty);
      expect(
          repo.demoInputs(SmartBoardSourceLanguage.english), isNotEmpty);
    });
  });

  group('SmartBoardLessonStore session', () {
    SmartBoardItem item(String id) => SmartBoardItem(
          id: id,
          sourceLanguage: SmartBoardSourceLanguage.hindi,
          sourceText: 'मैं तुम्हें समझाती हूँ',
          phraseId: 'phrase_002',
          santaliOlChiki: 'ᱤᱧ ᱟᱢ ᱞᱟᱹᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ',
          santaliRoman: 'Iñ am lāgit paṛhaw edañ.',
          santaliAudio: 'assets/prototype_content/translation/audio/santali/s2.wav',
          createdAt: DateTime(2026, 1, 1),
        );

    test('add + markAddedToLesson keeps history', () {
      final store = SmartBoardLessonStore();
      store.add(item('a'));
      store.add(item('b'));
      expect(store.items.length, 2);
      expect(store.isAddedToLesson('a'), isFalse);
      store.markAddedToLesson('a');
      expect(store.isAddedToLesson('a'), isTrue);
      // History is preserved after marking.
      expect(store.items.length, 2);
      expect(store.lessonItems.length, 1);
    });
  });

  group('Static math demo (math_5_plus_5)', () {
    test('matches the exact two-line board example', () {
      final demo = matchStaticDemo('5 + 5 = 10\nfive   five   ten');
      expect(demo, isNotNull);
      expect(demo!.id, 'math_5_plus_5');
    });

    test('matches spacing variants (no spaces, extra spaces)', () {
      expect(matchStaticDemo('5+5=10 five five ten'), isNotNull);
      expect(matchStaticDemo('  5 + 5 = 10\nfive five ten  '), isNotNull);
    });

    test('does not match unrelated board text', () {
      expect(matchStaticDemo('2 + 3 = 5\ntwo three five'), isNull);
      expect(matchStaticDemo('five little ducks'), isNull);
      expect(matchStaticDemo(''), isNull);
    });

    test('equation line is exactly unchanged', () {
      expect(math5Plus5Demo.equationLine, '5 + 5 = 10');
      expect(math5Plus5Demo.preservedSymbols, ['5', '+', '=', '10']);
    });

    test('Santali word slots are explicit placeholders (never invented)',
        () {
      // No verified five/ten vocabulary in project data yet — the model
      // MUST stay empty and clearly marked rather than hallucinated.
      expect(math5Plus5Demo.santaliFiveOlChiki, isEmpty);
      expect(math5Plus5Demo.santaliFiveRoman, isEmpty);
      expect(math5Plus5Demo.santaliTenOlChiki, isEmpty);
      expect(math5Plus5Demo.santaliTenRoman, isEmpty);
      expect(math5Plus5Demo.hasVerifiedWords, isFalse);
    });

    test('demo audio path is empty (not yet prepared, never invented)',
        () {
      expect(math5Plus5Demo.audioPath, isEmpty);
      expect(math5Plus5Demo.hasAudio, isFalse);
    });

    test('demo model carries the required §19 fields', () {
      final SmartBoardDemoItem demo = math5Plus5Demo;
      expect(demo.sourceLines, ['5 + 5 = 10', 'five   five   ten']);
      expect(demo.sourceLanguage, 'English');
      expect(smartBoardStaticDemos, hasLength(1));
    });
  });

  group('SmartBoardCanvasController tools', () {
    SmartBoardCanvasController controller() =>
        SmartBoardCanvasController();

    test('default tool is pen with classroom ink', () {
      final c = controller();
      expect(c.tool, SmartBoardTool.pen);
      expect(SmartBoardCanvasController.penInk, const Color(0xFF123B68));
    });

    test('pen stroke records points across the board', () {
      final c = controller();
      c.startStroke(const Offset(4, 4));
      c.appendPoint(const Offset(400, 300));
      c.appendPoint(const Offset(796, 596));
      c.endStroke();
      expect(c.strokes, hasLength(1));
      expect(c.strokes.first.points, hasLength(3));
      expect(c.canUndo, isTrue);
    });

    test('highlighter uses wide translucent ink', () {
      final c = controller();
      c.setTool(SmartBoardTool.highlighter);
      c.startStroke(const Offset(10, 10));
      c.endStroke();
      expect(c.strokes.first.width,
          SmartBoardCanvasController.highlighterWidth);
      expect(
          c.strokes.first.color,
          SmartBoardCanvasController.highlighterInk);
    });

    test('undo removes last stroke, redo restores it', () {
      final c = controller();
      c.startStroke(const Offset(0, 0));
      c.endStroke();
      c.startStroke(const Offset(10, 10));
      c.endStroke();
      expect(c.strokes, hasLength(2));
      c.undo();
      expect(c.strokes, hasLength(1));
      expect(c.canRedo, isTrue);
      c.redo();
      expect(c.strokes, hasLength(2));
      expect(c.canRedo, isFalse);
    });

    test('stroke eraser removes touched strokes only', () {
      final c = controller();
      c.startStroke(const Offset(0, 0));
      c.appendPoint(const Offset(0, 100));
      c.endStroke();
      c.startStroke(const Offset(500, 500));
      c.appendPoint(const Offset(600, 600));
      c.endStroke();
      c.setTool(SmartBoardTool.eraser);
      expect(c.eraseAt(const Offset(2, 50)), isTrue);
      expect(c.strokes, hasLength(1));
      expect(c.eraseAt(const Offset(10, 10)), isFalse);
      expect(c.strokes, hasLength(1));
    });

    test('clear empties board and redo history', () {
      final c = controller();
      c.startStroke(const Offset(0, 0));
      c.endStroke();
      c.undo();
      expect(c.canRedo, isTrue);
      c.redo();
      c.clear();
      expect(c.hasContent, isFalse);
      expect(c.canUndo, isFalse);
      expect(c.canRedo, isFalse);
    });
  });
}
