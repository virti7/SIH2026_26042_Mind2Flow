import 'package:equatable/equatable.dart';

/// Translation direction of a review item.
enum ReviewDirection { santaliToHindi, hindiToSantali }

/// Human validation signal from the Understanding Check.
enum UnderstandingResponse { understood, notUnderstood }

/// Automatic review priority, derived ONLY from the confidence score
/// (§4): lower confidence => higher review priority. Never assigned
/// manually and never independent from confidence.
enum ReviewPriority { high, medium, low }

/// §4 helper: confidence → review priority.
/// * `>= 80` → [ReviewPriority.low]  (Normal / Low review priority)
/// * `50–79` → [ReviewPriority.medium]
/// * `< 50`  → [ReviewPriority.high]
ReviewPriority calculatePriority(int confidence) {
  if (confidence >= 80) return ReviewPriority.low;
  if (confidence >= 50) return ReviewPriority.medium;
  return ReviewPriority.high;
}

extension ReviewPriorityX on ReviewPriority {
  /// Uppercase label used across the Reviewer Portal UI.
  String get label => switch (this) {
        ReviewPriority.high => 'HIGH PRIORITY',
        ReviewPriority.medium => 'MEDIUM PRIORITY',
        ReviewPriority.low => 'LOW PRIORITY',
      };

  /// Short label for compact badges.
  String get shortLabel => switch (this) {
        ReviewPriority.high => 'HIGH',
        ReviewPriority.medium => 'MEDIUM',
        ReviewPriority.low => 'LOW',
      };
}

/// Hardcoded/preloaded prototype classroom context (§10): the reviewer
/// always sees where the utterance came from — never a bare sentence.
class ReviewContext extends Equatable {
  final String className;
  final String subject;
  final String topic;
  final String sessionLabel;

  const ReviewContext({
    this.className = 'Class 2',
    this.subject = 'Language',
    this.topic = 'Classroom Communication',
    this.sessionLabel = 'Current classroom session',
  });

  /// One-line summary for cards: "Class 2 • Language • Classroom Communication".
  String get summary => '$className • $subject • $topic';

  @override
  List<Object?> get props => [className, subject, topic, sessionLabel];
}

/// Lifecycle of a review item.
enum ReviewItemStatus { pending, corrected, approved, resolved }

extension ReviewItemStatusX on ReviewItemStatus {
  String get label => switch (this) {
        ReviewItemStatus.pending => 'Pending',
        ReviewItemStatus.corrected => 'Corrected',
        ReviewItemStatus.approved => 'Approved',
        ReviewItemStatus.resolved => 'Resolved',
      };
}

/// One entry in the local Reviewer Queue (§7). Built AFTER a real
/// translation result exists — data comes from the phrase record, never
/// hardcoded sentences in Dart.
class ReviewItem extends Equatable {
  final String id; // e.g. RV-001
  final String phraseId; // e.g. phrase_001
  final ReviewDirection direction;
  final String originalText; // input text (source language)
  final String originalRoman;
  final String translatedText; // current prototype translation
  final String translatedRoman;
  final int confidenceScore;
  final ReviewPriority priority; // derived from [confidenceScore] only
  final ReviewContext context;
  final String reason; // why it was sent for review
  final ReviewItemStatus status;
  final DateTime createdAt;
  final String? audioAsset; // original-input local clip
  final String? correctedText; // filled when the reviewer sends a correction
  final String? reviewer; // e.g. "Language Expert"

  const ReviewItem({
    required this.id,
    required this.phraseId,
    required this.direction,
    required this.originalText,
    required this.originalRoman,
    required this.translatedText,
    required this.translatedRoman,
    required this.confidenceScore,
    required this.priority,
    required this.context,
    required this.reason,
    this.status = ReviewItemStatus.pending,
    required this.createdAt,
    this.audioAsset,
    this.correctedText,
    this.reviewer,
  });

  /// Direction label for cards: "Santali → Hindi".
  String get directionLabel => direction == ReviewDirection.santaliToHindi
      ? 'Santali → Hindi'
      : 'Hindi → Santali';

  /// Effective translation after a correction has been applied.
  String get effectiveTranslation =>
      (correctedText != null && correctedText!.trim().isNotEmpty)
          ? correctedText!
          : translatedText;

  bool get isResolved =>
      status == ReviewItemStatus.resolved ||
      status == ReviewItemStatus.corrected ||
      status == ReviewItemStatus.approved;

  ReviewItem copyWith({
    String? correctedText,
    ReviewItemStatus? status,
    String? reviewer,
  }) =>
      ReviewItem(
        id: id,
        phraseId: phraseId,
        direction: direction,
        originalText: originalText,
        originalRoman: originalRoman,
        translatedText: translatedText,
        translatedRoman: translatedRoman,
        confidenceScore: confidenceScore,
        priority: priority,
        context: context,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
        audioAsset: audioAsset,
        correctedText: correctedText ?? this.correctedText,
        reviewer: reviewer ?? this.reviewer,
      );

  @override
  List<Object?> get props => [
        id,
        phraseId,
        direction,
        originalText,
        originalRoman,
        translatedText,
        translatedRoman,
        confidenceScore,
        priority,
        context,
        reason,
        status,
        createdAt,
        audioAsset,
        correctedText,
        reviewer,
      ];
}

/// One Translation Memory record (§12). Prototype-only local data.
class TranslationMemoryEntry extends Equatable {
  final String phraseId;
  final ReviewDirection direction;
  final String sourceLanguage;
  final String targetLanguage;
  final String originalTranslation;
  final String correctedTranslation;
  final String reviewStatus;
  final String reviewer;
  final ReviewContext context;
  final DateTime createdAt;

  const TranslationMemoryEntry({
    required this.phraseId,
    required this.direction,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.originalTranslation,
    required this.correctedTranslation,
    required this.reviewStatus,
    required this.reviewer,
    required this.context,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        phraseId,
        direction,
        sourceLanguage,
        targetLanguage,
        originalTranslation,
        correctedTranslation,
        reviewStatus,
        reviewer,
        context,
        createdAt,
      ];
}

/// Teacher-portal notification card (§13): "Translation corrected by
/// language expert" with a one-tap "Use Corrected Translation" action.
class CorrectionNotice extends Equatable {
  final String reviewId;
  final String phraseId;
  final String originalTranslation;
  final String correctedTranslation;
  final ReviewContext context;
  final DateTime createdAt;
  final bool consumed; // true once "Use Corrected Translation" was applied

  const CorrectionNotice({
    required this.reviewId,
    required this.phraseId,
    required this.originalTranslation,
    required this.correctedTranslation,
    required this.context,
    required this.createdAt,
    this.consumed = false,
  });

  CorrectionNotice copyWith({bool? consumed}) => CorrectionNotice(
        reviewId: reviewId,
        phraseId: phraseId,
        originalTranslation: originalTranslation,
        correctedTranslation: correctedTranslation,
        context: context,
        createdAt: createdAt,
        consumed: consumed ?? this.consumed,
      );

  @override
  List<Object?> get props => [
        reviewId,
        phraseId,
        originalTranslation,
        correctedTranslation,
        context,
        createdAt,
        consumed,
      ];
}
