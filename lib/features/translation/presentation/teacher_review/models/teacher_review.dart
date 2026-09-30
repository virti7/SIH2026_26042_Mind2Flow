import 'package:equatable/equatable.dart';
import '../../../../../core/review/review_models.dart';

/// Teacher Review model extending ReviewItem with teacher/classroom context
class TeacherReview extends Equatable {
  final String id;
  final String phraseId;
  final ReviewDirection direction;
  final String originalText;
  final String originalRoman;
  final String translatedText;
  final String translatedRoman;
  final int confidenceScore;
  final ReviewPriority priority;
  final ReviewContext context;
  final String reason;
  final ReviewItemStatus status;
  final DateTime createdAt;
  final String? audioAsset;
  final String? correctedText;
  final String? correctedRoman;
  final String? reviewer;
  final String teacherId;
  final String classroomId;
  final String teacherName;
  final String classroomName;

  const TeacherReview({
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
    this.correctedRoman,
    this.reviewer,
    required this.teacherId,
    required this.classroomId,
    required this.teacherName,
    required this.classroomName,
  });

  /// Direction label for cards: "Hindi → Santali" or "Santali → Hindi"
  String get directionLabel => direction == ReviewDirection.hindiToSantali
      ? 'Hindi → Santali'
      : 'Santali → Hindi';

  /// Effective translation after correction
  String get effectiveTranslation =>
      (correctedText != null && correctedText!.trim().isNotEmpty)
          ? correctedText!
          : translatedText;

  /// Effective Roman after correction
  String get effectiveRoman =>
      (correctedRoman != null && correctedRoman!.trim().isNotEmpty)
          ? correctedRoman!
          : translatedRoman;

  bool get isResolved =>
      status == ReviewItemStatus.resolved ||
      status == ReviewItemStatus.corrected ||
      status == ReviewItemStatus.approved;

  bool get isPending => status == ReviewItemStatus.pending;

  /// Create a copy with updated fields for correction
  TeacherReview copyWith({
    String? correctedText,
    String? correctedRoman,
    ReviewItemStatus? status,
    String? reviewer,
  }) =>
      TeacherReview(
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
        correctedRoman: correctedRoman ?? this.correctedRoman,
        reviewer: reviewer ?? this.reviewer,
        teacherId: teacherId,
        classroomId: classroomId,
        teacherName: teacherName,
        classroomName: classroomName,
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
        correctedRoman,
        reviewer,
        teacherId,
        classroomId,
        teacherName,
        classroomName,
      ];
}