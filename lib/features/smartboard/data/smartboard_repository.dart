import 'package:flutter/foundation.dart';

import '../../../core/translation/bidirectional_phrase_bank.dart';
import '../models/smartboard_language.dart';

/// MAATRIBHASHA SMARTBOARD — deterministic offline prototype repository.
///
/// All Santali translation content comes from the single source of truth:
/// `assets/prototype_content/translation/bidirectional_phrase_bank.json`
/// via [BidirectionalPhraseBank]. No network, no ASR, no model inference.
///
/// Prototype input model: the teacher's board text is resolved against the
/// local phrase data —
/// * Hindi source → normalized exact match on the bank's Hindi side.
/// * English source → deterministic local demo mapping (prototype stand-in
///   for board-text recognition) onto the same bank records.
///
/// Never guesses: returns null when nothing matches.
class SmartBoardRepository {
  final BidirectionalPhraseBank bank;

  SmartBoardRepository({BidirectionalPhraseBank? bank})
      : bank = bank ?? BidirectionalPhraseBank();

  /// Demo board-text chips per source language (quick classroom entry).
  ///
  /// Hindi strings come from the bank; English strings are the prototype's
  /// deterministic source-side aliases for the same bank records.
  static const Map<String, String> englishDemoMapping = {
    'i explain to you': BidirectionalPhraseBank.hindiToSantaliId,
    "i don't understand this": BidirectionalPhraseBank.santaliToHindiId,
  };

  /// Quick-entry demo texts shown as chips under the board.
  List<String> demoInputs(SmartBoardSourceLanguage source) {
    switch (source) {
      case SmartBoardSourceLanguage.hindi:
        // Canonical prototype phrases (also present in the JSON bank).
        return const [
          'मैं तुम्हें समझाती हूँ',
          'मुझे यह नहीं समझ रहा है',
        ];
      case SmartBoardSourceLanguage.english:
        return const [
          'I explain to you',
          "I don't understand this",
        ];
    }
  }

  /// Resolves board text to a bank phrase. Null = no local match.
  Future<BidirectionalPhrase?> resolve(
    SmartBoardSourceLanguage source,
    String boardText,
  ) async {
    final phrases = await bank.load();
    if (phrases.isEmpty) return null;
    switch (source) {
      case SmartBoardSourceLanguage.hindi:
        return _matchHindi(boardText, phrases);
      case SmartBoardSourceLanguage.english:
        return _matchEnglish(boardText, phrases);
    }
  }

  BidirectionalPhrase? _matchHindi(
    String input,
    List<BidirectionalPhrase> phrases,
  ) {
    final norm = _normalizeHindi(input);
    if (norm.isEmpty) return null;
    for (final p in phrases) {
      if (_normalizeHindi(p.hindi) == norm) return p;
    }
    return null;
  }

  BidirectionalPhrase? _matchEnglish(
    String input,
    List<BidirectionalPhrase> phrases,
  ) {
    final norm = input.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (norm.isEmpty) return null;
    final id = englishDemoMapping[norm];
    if (id == null) {
      debugPrint('[SmartBoard] noEnglishMatch input=$input');
      return null;
    }
    for (final p in phrases) {
      if (p.id == id) return p;
    }
    return null;
  }

  static String _normalizeHindi(String input) {
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'[।!?.,;:"]'), '');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
