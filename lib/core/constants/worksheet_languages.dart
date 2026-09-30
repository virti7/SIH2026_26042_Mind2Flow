/// Authoritative worksheet language registry (single source of truth on
/// Flutter; mirrors the backend `LanguageCapabilityRegistry` + curriculum
/// language table — never duplicated per-screen).
///
/// Five teacher-selectable languages for bilingual worksheets:
/// Ho, Mundari, Santali, Hindi, English.
///
/// Provider routing always happens SERVER-SIDE (FastAPI). This registry only
/// records which provider *capability* backs each language so the UI can show
/// honest availability copy. No provider names, keys or endpoints appear in
/// teacher-facing UI.
library;

class WorksheetLanguage {
  /// Internal code sent to the backend (hi, en, sat, ho, unr).
  final String code;

  /// Teacher-facing display name.
  final String displayName;

  /// Native/local name shown alongside the display name.
  final String nativeName;

  /// Script information shown to the teacher.
  final String script;

  /// Server-side capability backing this language (never shown to teachers).
  /// 'sarvam' | 'custom-corpus' | 'configured-provider'
  final String providerCapability;

  /// Whether the teacher may select this language right now.
  final bool enabled;

  const WorksheetLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.script,
    required this.providerCapability,
    this.enabled = true,
  });
}

class WorksheetLanguages {
  WorksheetLanguages._();

  static const hindi = WorksheetLanguage(
    code: 'hi',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
    script: 'Devanagari',
    providerCapability: 'configured-provider',
  );

  static const english = WorksheetLanguage(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    script: 'Latin',
    providerCapability: 'configured-provider',
  );

  static const santali = WorksheetLanguage(
    code: 'sat',
    displayName: 'Santali',
    nativeName: 'संथाली',
    script: 'Ol Chiki / Devanagari',
    providerCapability: 'sarvam',
  );

  static const ho = WorksheetLanguage(
    code: 'ho',
    displayName: 'Ho',
    nativeName: 'हो',
    script: 'Warang Chiti / Devanagari',
    providerCapability: 'custom-corpus',
  );

  static const mundari = WorksheetLanguage(
    code: 'unr',
    displayName: 'Mundari',
    nativeName: 'मुण्डारी',
    script: 'Mundari Bani / Devanagari',
    providerCapability: 'custom-corpus',
  );

  /// All five selectable languages, in stable UI order.
  static const List<WorksheetLanguage> all = [
    hindi,
    english,
    santali,
    ho,
    mundari,
  ];

  static WorksheetLanguage byCode(String code) {
    final key = code.trim().toLowerCase();
    for (final lang in all) {
      if (lang.code == key) return lang;
    }
    // Accept common aliases from older payloads.
    switch (key) {
      case 'hi-in':
      case 'hindi':
        return hindi;
      case 'en-in':
      case 'english':
        return english;
      case 'sat-in':
      case 'santali':
      case 'san':
        return santali;
      case 'mundari':
      case 'mun':
        return mundari;
      default:
        return hindi;
    }
  }

  static String displayPair(String code1, String code2) {
    return '${byCode(code1).displayName} + ${byCode(code2).displayName}';
  }

  /// Availability copy for custom-pipeline languages. Shown only when the
  /// server reports the language is not currently configured — never
  /// silently substituted.
  static String? unavailableExplanation(String code) {
    final lang = byCode(code);
    if (lang.providerCapability == 'custom-corpus') {
      return '${lang.displayName} worksheets need the community-verified '
          'language pack on the server. If generation is unavailable, please '
          'choose another language pair or contact support.';
    }
    return null;
  }
}
