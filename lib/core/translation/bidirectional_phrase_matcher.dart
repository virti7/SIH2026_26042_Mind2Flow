import '../content/santali_phrase_bank.dart';

/// Bidirectional offline phrase matcher over the master phrase bank.
///
/// Priority (§15): 1. normalized exact match → 2. configured variants →
/// 3. literal keyword matching → 4. no match (never guess, never closest).
/// No embeddings, no LLM, no network. Pure Dart for unit testing.
///
/// Teacher → Student matches the Hindi side; Student → Teacher matches the
/// Santali side (Ol Chiki first, then configured Roman variants).
class BidirectionalMatch {
  final SantaliPhrase phrase;
  final int priority; // 1 exact, 2 variant, 3 keyword

  const BidirectionalMatch(this.phrase, this.priority);
}

class BidirectionalPhraseMatcher {
  /// Hindi normalization: trim, collapse spaces, strip harmless punctuation.
  static String normalizeHindi(String input) {
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Harmless sentence punctuation (Devanagari + ASCII). Keep nukta,
    // anusvara, etc. — only strip boundary punctuation.
    s = s.replaceAll(RegExp(r'[।!?.,;:"]'), '');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Santali normalization: preserve Ol Chiki Unicode exactly (no
  /// transliteration), collapse spaces, strip harmless punctuation.
  static String normalizeSantali(String input) {
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'[᱾!?.,;:"]'), '');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizeRoman(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Teacher → Student: Hindi transcript → phrase.
  BidirectionalMatch? matchHindi(String transcript, List<SantaliPhrase> bank) {
    final norm = normalizeHindi(transcript);
    if (norm.isEmpty) return null;
    // 1. normalized exact match on Hindi.
    for (final p in bank) {
      if (normalizeHindi(p.hindi) == norm) return BidirectionalMatch(p, 1);
    }
    // 2. explicitly configured Hindi variants.
    for (final p in bank) {
      for (final v in p.hindiVariants) {
        if (normalizeHindi(v) == norm) return BidirectionalMatch(p, 2);
      }
    }
    // 3. literal keyword matching: every significant token of the transcript
    // must appear literally in the phrase Hindi (no stemming, no fuzz).
    final tokens = norm.split(' ').where((t) => t.length > 1).toList();
    if (tokens.isEmpty) return null;
    for (final p in bank) {
      final hay = normalizeHindi(p.hindi);
      if (tokens.every(hay.contains)) return BidirectionalMatch(p, 3);
    }
    // 4. no match — caller shows "Translation unavailable…", never guesses.
    return null;
  }

  /// Student → Teacher: Santali transcript → phrase. Ol Chiki first, then
  /// configured Roman variants (case-insensitive).
  BidirectionalMatch? matchSantali(
      String transcript, List<SantaliPhrase> bank) {
    final norm = normalizeSantali(transcript);
    if (norm.isEmpty) return null;
    // 1. normalized exact match on Ol Chiki.
    for (final p in bank) {
      if (p.hasOlChiki && normalizeSantali(p.santaliOlChiki) == norm) {
        return BidirectionalMatch(p, 1);
      }
    }
    // 2a. exact match on the canonical Roman form.
    final roman = normalizeRoman(transcript);
    for (final p in bank) {
      if (p.hasRoman && normalizeRoman(p.santaliRoman) == roman) {
        return BidirectionalMatch(p, 2);
      }
    }
    // 2b. explicitly configured Santali/Roman variants.
    for (final p in bank) {
      for (final v in p.santaliVariants) {
        if (normalizeSantali(v) == norm || normalizeRoman(v) == roman) {
          return BidirectionalMatch(p, 2);
        }
      }
    }
    // 3. literal keyword matching on Ol Chiki tokens.
    final tokens = norm.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return null;
    for (final p in bank) {
      if (!p.hasOlChiki) continue;
      final hay = normalizeSantali(p.santaliOlChiki);
      if (tokens.every(hay.contains)) return BidirectionalMatch(p, 3);
    }
    return null;
  }
}
