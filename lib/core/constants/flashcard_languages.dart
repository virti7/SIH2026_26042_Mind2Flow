/// Santali multilingual flashcard language registry.
///
/// ONLY three languages exist in this generator: Hindi, English, Santali.
/// No Ho. No Mundari. No other language. Provider routing always happens
/// SERVER-SIDE (FastAPI + Sarvam); this registry only carries display info
/// and the teacher-facing language-mode options.
library;

/// Internal code sent to the backend (hi, en, sat).
class FlashcardLanguage {
  final String code;
  final String displayName;
  final String nativeName;
  final String script;

  const FlashcardLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.script,
  });
}

class FlashcardLanguages {
  FlashcardLanguages._();

  static const hindi = FlashcardLanguage(
    code: 'hi',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
    script: 'Devanagari',
  );

  static const english = FlashcardLanguage(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    script: 'Latin',
  );

  static const santali = FlashcardLanguage(
    code: 'sat',
    displayName: 'Santali',
    nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
    script: 'Ol Chiki',
  );

  /// The only languages this generator supports, in stable UI order.
  static const List<FlashcardLanguage> all = [hindi, english, santali];

  static bool isSupported(String code) {
    final key = code.trim().toLowerCase();
    return key == 'hi' ||
        key == 'hi-in' ||
        key == 'en' ||
        key == 'en-in' ||
        key == 'sat' ||
        key == 'sat-in';
  }
}

/// Teacher-facing language modes. The third option keeps Hindi, English
/// and Santali together for multilingual classroom support.
class FlashcardLanguageMode {
  final String code;
  final String label;
  final String description;

  const FlashcardLanguageMode({
    required this.code,
    required this.label,
    required this.description,
  });

  /// BCP-47 source codes sent to Sarvam per mode (server resolves these too).
  List<String> get sourceApiCodes {
    switch (code) {
      case 'en_sat':
        return ['en-IN'];
      case 'hi_en_sat':
        return ['hi-IN', 'en-IN'];
      default:
        return ['hi-IN'];
    }
  }

  String get targetApiCode => 'sat-IN';
}

class FlashcardLanguageModes {
  FlashcardLanguageModes._();

  static const hindiSantali = FlashcardLanguageMode(
    code: 'hi_sat',
    label: 'Hindi + Santali',
    description: 'Hindi word with Santali equivalent',
  );

  static const englishSantali = FlashcardLanguageMode(
    code: 'en_sat',
    label: 'English + Santali',
    description: 'English word with Santali equivalent',
  );

  static const hindiEnglishSantali = FlashcardLanguageMode(
    code: 'hi_en_sat',
    label: 'Hindi + English + Santali',
    description: 'Multilingual classroom support',
  );

  static const List<FlashcardLanguageMode> all = [
    hindiSantali,
    englishSantali,
    hindiEnglishSantali,
  ];

  static FlashcardLanguageMode byCode(String code) {
    for (final m in all) {
      if (m.code == code) return m;
    }
    return hindiSantali;
  }
}

/// Flashcard types served by the single underlying generator.
class FlashcardTypes {
  FlashcardTypes._();

  static const List<String> all = [
    'vocabulary',
    'object_identification',
    'action',
    'number',
    'shape',
    'color',
    'concept',
  ];

  static String label(String code) {
    switch (code) {
      case 'object_identification':
        return 'Object Identification';
      case 'action':
        return 'Action';
      case 'number':
        return 'Number / Counting';
      case 'shape':
        return 'Shape';
      case 'color':
        return 'Color';
      case 'concept':
        return 'Concept';
      default:
        return 'Vocabulary';
    }
  }
}
