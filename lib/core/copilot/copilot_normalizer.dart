/// Deterministic Roman-Hindi + English query normalizer for the offline
/// Teacher Co-Pilot. Pure Dart, zero network. No translation engine — the
/// variant dictionary exists only for deterministic intent matching.
library;

/// Roman Hindi spelling variants collapsed to one canonical token.
/// Key = canonical token, values = accepted spellings (all lowercase).
const Map<String, List<String>> copilotVariantDictionary = {
  'kaha': ['kaha', 'kahan', 'kahaan', 'kha'],
  'kaise': ['kaise', 'kaisa', 'kese', 'keshe'],
  'banana': ['banana', 'banani', 'banaye', 'banao', 'bana', 'banau', 'banega', 'banegi', 'banwana'],
  'chahiye': ['chahiye', 'chahiyen', 'chaiye', 'chaahiye'],
  'batao': ['batao', 'bataiye', 'bataye', 'bata', 'batayen'],
  'jana': ['jana', 'jau', 'jaye', 'jाऊं', 'jaun'],
  'kidhar': ['kidhar', 'kidher', 'kidar'],
  'mujhe': ['mujhe', 'muje', 'mujhko'],
  'baccho': ['baccho', 'bachcho', 'bacho', 'bache', 'bachche'],
  'padhau': ['padhau', 'padhao', 'padhaye', 'padhana', 'padhai', 'padho'],
  'sikhau': ['sikhau', 'sikhao', 'sikhaye', 'sikhana', 'sikho'],
  'samjhau': ['samjhau', 'samjhao', 'samjhaye', 'samjhana', 'samjha'],
  'kholo': ['kholo', 'khol', 'khole', 'kholna', 'open'],
  'worksheet': ['worksheet', 'worksheets', 'worksheet', 'worksheet'],
  'flashcard': ['flashcard', 'flashcards', 'flashcard', 'flashcards'],
  'assessment': ['assessment', 'assesment', 'test', 'quiz', 'pariksha'],
  'activity': ['activity', 'activities', 'gatividhi', 'khel'],
  'download': ['download', 'downloads', 'downloaded'],
  'translate': ['translate', 'translation', 'translator', 'anuvad'],
};

/// Reverse lookup: spelling -> canonical token.
final Map<String, String> _variantToCanonical = {
  for (final e in copilotVariantDictionary.entries)
    for (final v in e.value) v: e.key,
};

/// Canonical spelling normalizations applied before variant mapping
/// (multi-word concepts collapsed to a single token).
const Map<String, String> _phraseUnifications = {
  'work sheet': 'worksheet',
  'work sheets': 'worksheet',
  'practice sheet': 'worksheet',
  'flash card': 'flashcard',
  'flash cards': 'flashcard',
  'picture card': 'flashcard',
};

/// Tokens that signal an explicit "open it now" request.
const Set<String> copilotOpenSignals = {
  'kholo',
  'khol',
  'open',
  'kholna',
  'chalao',
  'dikhao',
};

/// Tokens that signal affirmation continuing the previous suggestion.
const Set<String> copilotAffirmSignals = {
  'haan',
  'ha',
  'han',
  'yes',
  'ok',
  'acha',
  'accha',
  'thik',
  'theek',
};

/// Demonstrative / pronoun tokens resolved to the current lesson topic
/// ("ye" -> current topic, e.g. Numbers up to 100).
const Set<String> copilotDemonstratives = {
  'ye',
  'yah',
  'yeh',
  'is',
  'ise',
  'isey',
  'iska',
  'this',
  'that',
  'it',
  'these',
  'इस',
  'यह',
  'ये',
  'उस',
  'वह',
  'इसे',
  'उसे',
};

class CopilotNormalizer {
  /// trim -> lowercase (Latin) -> collapse spaces -> unify phrases ->
  /// strip punctuation (keeps Devanagari + letters + digits + spaces) ->
  /// map spelling variants to canonical tokens.
  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    _phraseUnifications.forEach((phrase, single) {
      s = s.replaceAll(phrase, single);
    });
    s = s.replaceAll(RegExp(r'[^\u0900-\u097Fa-z0-9 ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return s;
    final tokens = s.split(' ').where((t) => t.isNotEmpty).map((t) {
      // Singularize simple English plurals so "worksheets" == "worksheet".
      var token = t;
      final canonical = _variantToCanonical[token];
      if (canonical != null) return canonical;
      if (token.length > 4 && token.endsWith('s') && !token.endsWith('ss')) {
        final singular = token.substring(0, token.length - 1);
        final singularCanonical = _variantToCanonical[singular];
        return singularCanonical ?? singular;
      }
      return token;
    }).toList();
    return tokens.join(' ');
  }

  static List<String> tokenize(String normalized) {
    if (normalized.isEmpty) return const [];
    return normalized
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  /// Extra English/Hindi anchor tokens appended ONLY for the teacher-guidance
  /// repository lookup, so Roman verbs (`padhau`, `sikhau`, `samjhau`)
  /// match its keyword/intent signals. When the query holds a demonstrative
  /// (`ye`, `this`) the current lesson [topic] is appended too, so "ye"
  /// resolves to e.g. "numbers up to 100". The original query is untouched.
  static String expandForGuidance(String normalized, {String? topic}) {
    final tokens = tokenize(normalized).toSet();
    final extra = <String>[];
    if (tokens.contains('padhau') ||
        tokens.contains('sikhau') ||
        tokens.contains('samjhau')) {
      extra.add('teach');
    }
    if (tokens.contains('batao')) extra.add('explain');
    if (tokens.contains('kaise')) extra.add('how to');
    if (tokens.contains('kaha') || tokens.contains('kidhar')) {
      extra.add('where');
    }
    if (tokens.contains('activity')) extra.add('activity game');
    final t = (topic ?? '').trim();
    if (t.isNotEmpty &&
        tokens.intersection(copilotDemonstratives).isNotEmpty) {
      extra.add(normalize(t));
    }
    if (extra.isEmpty) return normalized;
    return '$normalized ${extra.join(' ')}';
  }

  /// True when the query is a follow-up asking to open the last suggestion
  /// ("haan kholo", "kholo", "open karo", "haan open karo").
  static bool isOpenFollowUp(String normalized) {
    final tokens = tokenize(normalized).toSet();
    if (tokens.intersection(copilotOpenSignals).isEmpty) return false;
    // Bare "kholo"/"open" or affirmed ("haan kholo") continues context.
    // Longer queries with fresh keywords are handled as new questions.
    if (tokens.length <= 3) return true;
    return tokens.intersection(copilotAffirmSignals).isNotEmpty;
  }

  static bool hasDemonstrative(String normalized) {
    final tokens = tokenize(normalized).toSet();
    return tokens.intersection(copilotDemonstratives).isNotEmpty;
  }
}
