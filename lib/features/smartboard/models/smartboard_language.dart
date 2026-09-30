/// MAATRIBHASHA SMARTBOARD — language model (future-ready).
///
/// Prototype target: Hindi / English → Santali.
/// Ho and Mundari are declared here so they can be enabled later WITHOUT
/// redesigning the feature — but they are NOT implemented now and must stay
/// disabled in the UI.
enum SmartBoardSourceLanguage {
  hindi,
  english,
}

extension SmartBoardSourceLanguageX on SmartBoardSourceLanguage {
  String get label {
    switch (this) {
      case SmartBoardSourceLanguage.hindi:
        return 'Hindi';
      case SmartBoardSourceLanguage.english:
        return 'English';
    }
  }
}

/// Target languages for the Santali Board selector.
///
/// Only [santali] is implemented. [ho] and [mundari] are intentionally
/// disabled placeholders ("Coming Soon") — no fake translations.
enum SmartBoardTargetLanguage {
  santali,
  ho,
  mundari,
}

extension SmartBoardTargetLanguageX on SmartBoardTargetLanguage {
  String get label {
    switch (this) {
      case SmartBoardTargetLanguage.santali:
        return 'Santali';
      case SmartBoardTargetLanguage.ho:
        return 'Ho';
      case SmartBoardTargetLanguage.mundari:
        return 'Mundari';
    }
  }

  /// Only Santali is active in the prototype.
  bool get isEnabled {
    switch (this) {
      case SmartBoardTargetLanguage.santali:
        return true;
      case SmartBoardTargetLanguage.ho:
      case SmartBoardTargetLanguage.mundari:
        return false;
    }
  }

  String get disabledHint => 'Coming Soon';
}
