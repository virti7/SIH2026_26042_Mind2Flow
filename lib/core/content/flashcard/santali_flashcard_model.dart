import 'package:equatable/equatable.dart';

/// Models for the Santali Visual Vocabulary Flashcard Curriculum.
/// Grounded in the source textbook "Aao Santali Likhna Sikhe.pdf".
/// Preserves full source provenance, printed label image references,
/// and verification status without silent modifications.

class SantaliLabelInfo extends Equatable {
  final String? value;
  final String? rawTextLayer;
  final String? labelImage;
  final String? source;
  final double textLayerCoverage;
  final bool textLayerIncomplete;
  final bool isVerified;

  const SantaliLabelInfo({
    this.value,
    this.rawTextLayer,
    this.labelImage,
    this.source,
    this.textLayerCoverage = 1.0,
    this.textLayerIncomplete = false,
    this.isVerified = false,
  });

  factory SantaliLabelInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SantaliLabelInfo();
    return SantaliLabelInfo(
      value: json['value']?.toString(),
      rawTextLayer: json['raw_text_layer']?.toString(),
      labelImage: json['label_image']?.toString(),
      source: json['source']?.toString(),
      textLayerCoverage: (json['text_layer_coverage'] as num?)?.toDouble() ?? 1.0,
      textLayerIncomplete: json['text_layer_incomplete'] == true,
      isVerified: json['verified'] == true,
    );
  }

  bool get hasText => value != null && value!.trim().isNotEmpty;
  bool get hasLabelImage => labelImage != null && labelImage!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        value,
        rawTextLayer,
        labelImage,
        source,
        textLayerCoverage,
        textLayerIncomplete,
        isVerified,
      ];
}

class SourceLabelInfo extends Equatable {
  final String? english;
  final String? hindi;
  final String? englishOrigin;

  const SourceLabelInfo({
    this.english,
    this.hindi,
    this.englishOrigin,
  });

  factory SourceLabelInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SourceLabelInfo();
    return SourceLabelInfo(
      english: json['english']?.toString(),
      hindi: json['hindi']?.toString(),
      englishOrigin: json['english_origin']?.toString(),
    );
  }

  @override
  List<Object?> get props => [english, hindi, englishOrigin];
}

class SourceProvenance extends Equatable {
  final String document;
  final int page;
  final int? printedPageNumber;
  final String section;
  final List<double> bbox;

  const SourceProvenance({
    required this.document,
    required this.page,
    this.printedPageNumber,
    required this.section,
    this.bbox = const [],
  });

  factory SourceProvenance.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SourceProvenance(
        document: 'Aao Santali Likhna Sikhe.pdf',
        page: 0,
        section: '',
      );
    }
    final rawBbox = json['bbox'] as List<dynamic>? ?? const [];
    return SourceProvenance(
      document: (json['document'] ?? 'Aao Santali Likhna Sikhe.pdf').toString(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      printedPageNumber: (json['printed_page_number'] as num?)?.toInt(),
      section: (json['section'] ?? '').toString(),
      bbox: rawBbox.map((e) => (e as num).toDouble()).toList(),
    );
  }

  @override
  List<Object?> get props => [document, page, printedPageNumber, section, bbox];
}

class CurriculumFlashcard extends Equatable {
  final String id;
  final String category;
  final String? subcategory;
  final String concept;
  final String educationalDomain;
  final String visualType;
  final String englishLabel;
  final SantaliLabelInfo santali;
  final SourceLabelInfo sourceLabel;
  final String caption;
  final List<String> keywords;
  final String relativeImagePath;
  final int imageWidth;
  final int imageHeight;
  final SourceProvenance source;
  final String? aiObject;
  final bool? agreesWithSourceEnglish;
  final String? notes;
  final bool sourceDiscrepancy;
  final bool isVerified;

  const CurriculumFlashcard({
    required this.id,
    required this.category,
    this.subcategory,
    required this.concept,
    required this.educationalDomain,
    required this.visualType,
    required this.englishLabel,
    required this.santali,
    required this.sourceLabel,
    required this.caption,
    required this.keywords,
    required this.relativeImagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.source,
    this.aiObject,
    this.agreesWithSourceEnglish,
    this.notes,
    this.sourceDiscrepancy = false,
    this.isVerified = false,
  });

  factory CurriculumFlashcard.fromJson(Map<String, dynamic> json) {
    final labelMap = json['label'] as Map<String, dynamic>? ?? const {};
    final santaliMap = labelMap['santali'] as Map<String, dynamic>?;
    final sourceLabelMap = json['source_label'] as Map<String, dynamic>?;
    final assetMap = json['asset'] as Map<String, dynamic>? ?? const {};
    final sourceMap = json['source'] as Map<String, dynamic>?;
    final aiMap = json['ai_interpretation'] as Map<String, dynamic>?;
    final reviewMap = json['review'] as Map<String, dynamic>?;

    final kw = (json['keywords'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    return CurriculumFlashcard(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subcategory: json['subcategory']?.toString(),
      concept: (json['concept'] ?? '').toString(),
      educationalDomain: (json['educational_domain'] ?? '').toString(),
      visualType: (json['visual_type'] ?? 'photograph').toString(),
      englishLabel: (labelMap['english'] ?? json['concept'] ?? '').toString(),
      santali: SantaliLabelInfo.fromJson(santaliMap),
      sourceLabel: SourceLabelInfo.fromJson(sourceLabelMap),
      caption: (json['caption'] ?? '').toString(),
      keywords: kw,
      relativeImagePath: (assetMap['path'] ?? '').toString(),
      imageWidth: (assetMap['width'] as num?)?.toInt() ?? 512,
      imageHeight: (assetMap['height'] as num?)?.toInt() ?? 512,
      source: SourceProvenance.fromJson(sourceMap),
      aiObject: aiMap?['object']?.toString(),
      agreesWithSourceEnglish: aiMap?['agrees_with_source_english'] as bool?,
      notes: json['notes']?.toString(),
      sourceDiscrepancy: json['source_discrepancy'] == true,
      isVerified: reviewMap?['verified'] == true || santaliMap?['verified'] == true,
    );
  }

  /// Resolves the image path against the provided asset base directory.
  String resolveImagePath(String assetBase) {
    final cleanBase = assetBase.replaceAll(r'\', '/').endsWith('/')
        ? assetBase.replaceAll(r'\', '/')
        : '${assetBase.replaceAll(r'\', '/')}/';
    final cleanRel = relativeImagePath.replaceAll(r'\', '/').startsWith('/')
        ? relativeImagePath.replaceAll(r'\', '/').substring(1)
        : relativeImagePath.replaceAll(r'\', '/');
    return '$cleanBase$cleanRel';
  }

  /// Resolves the Santali label crop image path.
  String? resolveLabelImagePath(String assetBase) {
    if (!santali.hasLabelImage) return null;
    final cleanBase = assetBase.replaceAll(r'\', '/').endsWith('/')
        ? assetBase.replaceAll(r'\', '/')
        : '${assetBase.replaceAll(r'\', '/')}/';
    final lbl = santali.labelImage!.replaceAll(r'\', '/');
    final cleanLbl = lbl.startsWith('/') ? lbl.substring(1) : lbl;
    return '$cleanBase$cleanLbl';
  }

  bool get isColour => category == 'colours' || visualType == 'colour_swatch';

  String get displayEnglish {
    if (englishLabel.isNotEmpty) return englishLabel;
    return concept;
  }

  String? get hindiMeaning => sourceLabel.hindi;

  @override
  List<Object?> get props => [
        id,
        category,
        subcategory,
        concept,
        englishLabel,
        relativeImagePath,
        sourceDiscrepancy,
      ];
}

/// Deck definition grouping a subset of cards (e.g. "01_colours", "03_domestic_animals")
class FlashcardDeck extends Equatable {
  final String id;
  final String title;
  final String categoryKey;
  final String? subcategoryKey;
  final String folder;
  final List<CurriculumFlashcard> cards;

  const FlashcardDeck({
    required this.id,
    required this.title,
    required this.categoryKey,
    this.subcategoryKey,
    required this.folder,
    this.cards = const [],
  });

  int get cardCount => cards.length;

  FlashcardDeck copyWith({List<CurriculumFlashcard>? cards}) {
    return FlashcardDeck(
      id: id,
      title: title,
      categoryKey: categoryKey,
      subcategoryKey: subcategoryKey,
      folder: folder,
      cards: cards ?? this.cards,
    );
  }

  @override
  List<Object?> get props => [id, title, categoryKey, subcategoryKey, cards.length];
}

/// Category metadata containing one or more decks.
class FlashcardCategoryMetadata extends Equatable {
  final String key;
  final String label;
  final List<FlashcardDeck> decks;

  const FlashcardCategoryMetadata({
    required this.key,
    required this.label,
    required this.decks,
  });

  int get totalCards => decks.fold(0, (sum, d) => sum + d.cardCount);

  @override
  List<Object?> get props => [key, label, decks];
}

/// User's local learning progress for a specific flashcard.
class FlashcardLearningProgress extends Equatable {
  final String cardId;
  final int seenCount;
  final int correctCount;
  final int incorrectCount;
  final DateTime lastReviewedAt;
  final bool isMastered;

  const FlashcardLearningProgress({
    required this.cardId,
    this.seenCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    required this.lastReviewedAt,
    this.isMastered = false,
  });

  /// Records presentation of the card to the learner (seen_count += 1)
  FlashcardLearningProgress markSeen() {
    return FlashcardLearningProgress(
      cardId: cardId,
      seenCount: seenCount + 1,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      lastReviewedAt: lastReviewedAt,
      isMastered: isMastered,
    );
  }

  /// Records an evaluation answer ("I Know" -> isCorrect: true, "Need Practice" -> isCorrect: false)
  /// Deterministic prototype semantics (Section 10 of Brief):
  /// - seenCount guaranteed >= 1
  /// - "I Know" -> correctCount += 1, isMastered = true
  /// - "Need Practice" -> incorrectCount += 1, isMastered = false
  /// - lastReviewedAt updated on every answer
  FlashcardLearningProgress recordAttempt({required bool isCorrect}) {
    return FlashcardLearningProgress(
      cardId: cardId,
      seenCount: seenCount > 0 ? seenCount : 1,
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      incorrectCount: isCorrect ? incorrectCount : incorrectCount + 1,
      lastReviewedAt: DateTime.now(),
      isMastered: isCorrect,
    );
  }

  @override
  List<Object?> get props => [
        cardId,
        seenCount,
        correctCount,
        incorrectCount,
        lastReviewedAt,
        isMastered,
      ];
}
