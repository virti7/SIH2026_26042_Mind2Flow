import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/santali_audio_player.dart';
import 'package:maatribhasha/core/content/santali_phrase_bank.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/features/translation/presentation/bloc/translation_bloc.dart';

/// MASTER OFFLINE SANTALI PHRASE BANK tests.
///
/// ONE central JSON file + ONE local audio folder -> repository -> UI.
/// No network, no Sarvam, no FastAPI anywhere on this path.

const _bankPath =
    'assets/prototype_content/translation/phrase_bank/santali_phrase_bank.json';
const _sunAudio =
    'assets/prototype_content/translation/audio/santali/santali_sun_rises_east.wav';
const _sunOlChiki = 'ᱪᱟᱱᱫᱚ ᱫᱚ ᱯᱩᱨᱩᱵᱽ ᱠᱷᱚᱱ ᱨᱟᱠᱟᱵᱽ ᱮᱫᱟᱭ';

Map<String, dynamic> _readBankJson() {
  final file = File(_bankPath);
  expect(file.existsSync(), isTrue, reason: 'master JSON must exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<SantaliPhrase> _seedFromRealFile() {
  final decoded = _readBankJson();
  final phrases = (decoded['phrases'] as List).cast<Map>();
  return phrases
      .map((e) => SantaliPhrase.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

SantaliPhraseBankRepository _repo() => SantaliPhraseBankRepository(
      seedPhrases: _seedFromRealFile(),
      availableAssetsOverride: {_sunAudio},
    );

/// Remote pipeline stand-in. Throws on ANY call: the phrase-bank path must
/// never reach it (no network, no Sarvam, no FastAPI).
class _ThrowingTranslationRepository implements TranslationRepository {
  int translateCalls = 0;

  @override
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async {
    translateCalls++;
    throw StateError('remote pipeline must not be called by the phrase bank');
  }

  @override
  Future<List<QuickPhrase>> getQuickPhrases({String? category}) async => [];

  @override
  Future<void> submitFeedback({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  }) async {}
}

/// Player that always fails playback (simulates a missing/unplayable asset
/// at play time).
class _FailingAudioPlayer implements SantaliAudioPlayer {
  @override
  String? get lastAssetPath => null;

  @override
  Future<void> playAsset(String assetPath) async {
    throw const SantaliAudioPlaybackFailure(
        'Audio unavailable for this phrase.');
  }

  @override
  Future<void> replay() async {
    throw const SantaliAudioPlaybackFailure(
        'Audio unavailable for this phrase.');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> preload(List<String> assetPaths) async {}
}

Future<TranslationSessionActive> _activeSession(TranslationBloc bloc) async {
  bloc.add(InitTranslationSession());
  final state =
      await bloc.stream.firstWhere((s) => s is TranslationSessionActive);
  return state as TranslationSessionActive;
}

void main() {
  group('Master JSON file', () {
    test('1. JSON loads successfully with version + language header', () {
      final decoded = _readBankJson();
      expect(decoded['version'], 1);
      final lang = decoded['language'] as Map;
      expect(lang['source'], 'Hindi');
      expect(lang['target'], 'Santali');
      expect((decoded['phrases'] as List), isNotEmpty);
    });

    test('2. all valid phrase records parse, none invalid', () async {
      final repo = _repo();
      final phrases = await repo.load();
      expect(phrases.length, _seedFromRealFile().length);
      expect(await repo.invalidIds(), isEmpty);
      // Load-once cache: second load returns the same content.
      final again = await repo.load();
      expect(again.map((p) => p.id), phrases.map((p) => p.id));
    });

    test('3-6. Hindi, Ol Chiki, Roman, audio fields load', () async {
      final repo = _repo();
      final sun = await repo.getById('sun_rises_east');
      expect(sun, isNotNull);
      expect(sun!.hindi, 'सूरज पूरब से निकलता है।');
      expect(sun.santaliOlChiki, _sunOlChiki);
      expect(sun.audio, _sunAudio);

      final book = await repo.getById('open_book_page_5');
      expect(book, isNotNull);
      expect(book!.hindi, 'अपनी पुस्तक पृष्ठ संख्या 5 पर खोलें।');
      expect(book.category, 'Instructions');
      // Roman field exists in the JSON even when not yet verified.
      final decoded = _readBankJson();
      final rawBook = (decoded['phrases'] as List)
          .cast<Map>()
          .firstWhere((e) => e['id'] == 'open_book_page_5');
      expect(rawBook.containsKey('santaliRoman'), isTrue);
      expect(rawBook.containsKey('audio'), isTrue);
    });

    test('7. category filtering works, categories come from JSON', () async {
      final repo = _repo();
      final cats = await repo.categories();
      for (final expected in [
        'Classroom management',
        'Greeting',
        'Instructions',
        'Encouragement',
        'Questions',
        'Mathematics',
        'Literacy',
        'Activity phrases',
        'Emergency',
      ]) {
        expect(cats, contains(expected));
      }
      final instructions =
          await repo.search(category: 'Instructions');
      expect(instructions, isNotEmpty);
      expect(instructions.every((p) => p.category == 'Instructions'), isTrue);
      final all = await repo.search();
      expect(all.length, greaterThan(instructions.length));
    });

    test('8. search works across Hindi', () async {
      final repo = _repo();
      final byHindi = await repo.search(query: 'गिनो');
      expect(byHindi.map((p) => p.id),
          containsAll(['count_to_five', 'count_these']));
      final byDevanagari = await repo.search(query: 'किताब');
      expect(byDevanagari, isNotEmpty);
    });

    test('9. search works across Roman Santali', () {
      const p = SantaliPhrase(
        id: 'x',
        category: 'Greeting',
        hindi: 'नमस्ते',
        santaliOlChiki: '',
        santaliRoman: 'Johar gidrako',
        audio: 'assets/prototype_content/translation/audio/santali/x.wav',
      );
      expect(p.matchesQuery('johar'), isTrue);
      expect(p.matchesQuery('GIDRako'), isTrue);
    });

    test('10. search works across Ol Chiki', () async {
      final repo = _repo();
      final results = await repo.search(query: 'ᱪᱟᱱᱫᱚ');
      expect(results.map((p) => p.id), contains('sun_rises_east'));
    });

    test('11. tags work', () async {
      final repo = _repo();
      final byTag = await repo.search(query: 'book');
      expect(byTag.map((p) => p.id), contains('open_book_page_5'));
      final attention = await repo.search(query: 'attention');
      expect(attention, isNotEmpty);
    });
  });

  group('Local audio playback', () {
    test('12. speaker plays the correct local audio per phrase', () async {
      final player = NoopSantaliAudioPlayer();
      final repo = _repo();
      final book = (await repo.getById('open_book_page_5'))!;
      final greeting = (await repo.getById('greeting_namaste'))!;
      await player.playAsset(book.audio);
      await player.playAsset(greeting.audio);
      expect(player.playLog, [book.audio, greeting.audio]);
      expect(book.audio, isNot(equals(greeting.audio)));
    });

    test('13. repeat plays the same local audio again', () async {
      final player = NoopSantaliAudioPlayer();
      await player.playAsset(_sunAudio);
      await player.replay();
      expect(player.playLog, [_sunAudio, _sunAudio]);
    });

    test('14. missing audio handled safely (no crash, reported)', () async {
      final repo = _repo();
      final book = (await repo.getById('open_book_page_5'))!;
      // Only the sun wav is bundled in the test override.
      expect(await repo.audioExists(book), isFalse);
      expect(await repo.audioExists(
          (await repo.getById('sun_rises_east'))!), isTrue);

      // Bloc path with an unplayable asset: texts stay, honest error shown.
      final remote = _ThrowingTranslationRepository();
      final bloc = TranslationBloc(
        translationRepository: remote,
        santaliAudioPlayer: _FailingAudioPlayer(),
      );
      await _activeSession(bloc);
      bloc.add(UsePhraseBankPhraseInLiveLesson(
        phraseId: book.id,
        hindi: book.hindi,
        santaliOlChiki: book.santaliOlChiki,
        santaliRoman: book.santaliRoman,
        audioAsset: book.audio,
      ));
      final failed = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).translationError != null);
      final active = failed as TranslationSessionActive;
      expect(active.currentInputHindi, book.hindi);
      expect(active.translationError, 'Audio unavailable for this phrase.');
      expect(remote.translateCalls, 0);
      await bloc.close();
    });

    test('15. missing Santali text handled safely (never fabricated)',
        () async {
      final repo = _repo();
      final book = (await repo.getById('open_book_page_5'))!;
      expect(book.hasOlChiki, isFalse);
      expect(book.hasRoman, isFalse);

      final remote = _ThrowingTranslationRepository();
      final player = NoopSantaliAudioPlayer();
      final bloc = TranslationBloc(
        translationRepository: remote,
        santaliAudioPlayer: player,
      );
      await _activeSession(bloc);
      bloc.add(UsePhraseBankPhraseInLiveLesson(
        phraseId: book.id,
        hindi: book.hindi,
        santaliOlChiki: book.santaliOlChiki,
        santaliRoman: book.santaliRoman,
        audioAsset: book.audio,
      ));
      final ready = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).currentInputHindi == book.hindi);
      expect((ready as TranslationSessionActive).currentTranslationResult,
          'Not provided');
      expect(remote.translateCalls, 0);
      await bloc.close();
    });
  });

  group('Live Lesson integration', () {
    test('16. Use in Live Lesson passes the correct data', () async {
      final remote = _ThrowingTranslationRepository();
      final player = NoopSantaliAudioPlayer();
      final bloc = TranslationBloc(
        translationRepository: remote,
        santaliAudioPlayer: player,
      );
      await _activeSession(bloc);
      const hindi = 'सूरज पूरब से निकलता है।';
      bloc.add(const UsePhraseBankPhraseInLiveLesson(
        phraseId: 'sun_rises_east',
        hindi: hindi,
        santaliOlChiki: _sunOlChiki,
        santaliRoman: '',
        audioAsset: _sunAudio,
      ));
      final ready = await bloc.stream.firstWhere((s) =>
          s is TranslationSessionActive &&
          (s as TranslationSessionActive).currentInputHindi == hindi);
      final active = ready as TranslationSessionActive;
      expect(active.currentTranslationResult, _sunOlChiki);
      expect(active.localAudioAsset, _sunAudio);
      expect(active.localPhraseId, 'sun_rises_east');
      expect(active.isLocalPrototype, isTrue);
      expect(active.targetLanguage, TribalLanguage.santali);
      // The phrase's own local clip played — nothing else.
      expect(player.playLog, [_sunAudio]);
      expect(remote.translateCalls, 0);
      await bloc.close();
    });
  });

  group('Offline + integrity guarantees', () {
    test('17. no network dependency: all audio paths are local', () {
      final decoded = _readBankJson();
      final raw = jsonEncode(decoded);
      expect(raw.contains('http'), isFalse);
      expect(raw.contains('firebase'), isFalse);
      expect(raw.contains('supabase'), isFalse);
      for (final e in (decoded['phrases'] as List).cast<Map>()) {
        final audio = e['audio'].toString();
        expect(audio.startsWith('assets/'), isTrue);
        expect(audio.contains('://'), isFalse);
      }
    });

    test('18. existing phrase data not duplicated: unique ids, no Dart lists',
        () {
      final decoded = _readBankJson();
      final ids = (decoded['phrases'] as List)
          .cast<Map>()
          .map((e) => e['id'].toString())
          .toList();
      expect(ids.toSet().length, ids.length,
          reason: 'phrase ids must be unique');

      // The Quick Phrase Bank UI must not carry its own hardcoded dataset.
      final screen = File(
          'lib/features/translation/presentation/pages/translation_screens.dart');
      final source = screen.readAsStringSync();
      expect(source.contains('_extras'), isFalse);
      expect(source.contains('qp_local_'), isFalse);
      expect(source.contains('SantaliPhraseBankRepository'), isTrue);
      expect(source.contains('.json'), isFalse,
          reason: 'UI loads via the repository, never a JSON path literal');
    });
  });
}
