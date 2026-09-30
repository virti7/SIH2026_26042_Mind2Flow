/// Manifest schema for deterministic OFFLINE prototype content.
///
/// Files live under `assets/prototype_content/` and are bundled into the APK
/// (see `pubspec.yaml` + `assets/prototype_content/README.md`).
///
/// This file defines the *format only* — no content is hardcoded here.
/// The teacher adds real PDFs / images / JSON manifests; the loader
/// ([PrototypeLocalContentDataSource]) parses them into these models and
/// converts them into the existing app models (`WorksheetItem`, etc.)
/// so the existing preview / download / SavedMaterials UI is reused.
library;

/// Shared catalog entry: curriculum content is SHARED across teacher
/// accounts. Download records / saved state / progress stay
/// account-scoped in the existing Drift tables.
class PrototypeWorksheetManifest {
  final String id;
  final String title;
  final String className;
  final String subject;
  final String topic;
  final List<String> languages;
  final String type;
  final String asset;

  const PrototypeWorksheetManifest({
    required this.id,
    required this.title,
    required this.className,
    required this.subject,
    required this.topic,
    required this.languages,
    required this.type,
    required this.asset,
  });

  factory PrototypeWorksheetManifest.fromJson(Map<String, dynamic> json) {
    return PrototypeWorksheetManifest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      languages: ((json['languages'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      type: (json['type'] ?? 'bilingual_worksheet').toString(),
      asset: (json['asset'] ?? '').toString(),
    );
  }

  bool get isValid => id.isNotEmpty && asset.isNotEmpty;
}

class PrototypeFlashcardSetManifest {
  final String setId;
  final String title;
  final String className;
  final String subject;
  final String topic;
  final List<String> languagePair;
  final int cardCount;
  final String coverImage;
  final String setFile;

  const PrototypeFlashcardSetManifest({
    required this.setId,
    required this.title,
    required this.className,
    required this.subject,
    required this.topic,
    required this.languagePair,
    required this.cardCount,
    required this.coverImage,
    required this.setFile,
  });

  factory PrototypeFlashcardSetManifest.fromJson(Map<String, dynamic> json) {
    return PrototypeFlashcardSetManifest(
      setId: (json['setId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      languagePair: ((json['languagePair'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
      coverImage: (json['coverImage'] ?? '').toString(),
      setFile: (json['setFile'] ?? '').toString(),
    );
  }

  bool get isValid => setId.isNotEmpty && setFile.isNotEmpty;
}

class PrototypeAssessmentQuestion {
  final int number;
  final String promptHindi;
  final String promptTribal;
  final String type;
  final String? image;
  final List<String> options;
  final int correctIndex;

  const PrototypeAssessmentQuestion({
    required this.number,
    required this.promptHindi,
    required this.promptTribal,
    required this.type,
    this.image,
    required this.options,
    required this.correctIndex,
  });

  factory PrototypeAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return PrototypeAssessmentQuestion(
      number: (json['number'] as num?)?.toInt() ?? 0,
      promptHindi: (json['promptHindi'] ?? '').toString(),
      promptTribal: (json['promptTribal'] ?? '').toString(),
      type: (json['type'] ?? 'mcq').toString(),
      image: json['image']?.toString(),
      options: ((json['options'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class PrototypeAssessmentManifest {
  final String assessmentId;
  final String className;
  final String subject;
  final String topic;
  final String language;
  final List<PrototypeAssessmentQuestion> questions;

  const PrototypeAssessmentManifest({
    required this.assessmentId,
    required this.className,
    required this.subject,
    required this.topic,
    required this.language,
    required this.questions,
  });

  factory PrototypeAssessmentManifest.fromJson(Map<String, dynamic> json) {
    final raw = (json['questions'] as List?) ?? const [];
    return PrototypeAssessmentManifest(
      assessmentId: (json['assessmentId'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      questions: raw
          .whereType<Map>()
          .map((e) => PrototypeAssessmentQuestion.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  bool get isValid => assessmentId.isNotEmpty;
}
