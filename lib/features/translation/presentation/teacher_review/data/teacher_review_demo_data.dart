import 'package:equatable/equatable.dart';
import '../models/teacher_review.dart';
import '../../../../../core/review/review_models.dart';

/// Static local demo data for the TEACHER-FACING Review list.
///
/// READ-ONLY: the teacher can view status/history only. Write workflows
/// live in the separate expert app and must never appear here.
///
/// Visible to the current teacher/classroom:
///   teacherId = teacher_001, classroomId = classroom_002
///   Total = 6, Pending = 3, Resolved = 3
/// One extra internal record (teacher_002 / classroom_003) exists only to
/// verify filtering and must never appear in the Teacher Review page.
class TeacherReviewDemoData extends Equatable {
  static const String currentTeacherId = 'teacher_001';
  static const String currentClassroomId = 'classroom_002';
  static const String currentTeacherName = 'Sunita Kumari';
  static const String currentClassroomName = 'Class 2';

  static List<TeacherReview> get allReviews => _allReviews;

  static final List<TeacherReview> _allReviews = [
    // RV-001: Hindi → Santali, pending, confidence 78.
    TeacherReview(
      id: 'RV-001',
      phraseId: 'phrase_001',
      direction: ReviewDirection.hindiToSantali,
      originalText: 'मैं तुम्हें समझाती हूँ',
      originalRoman: 'Main tumhe samjhati hu',
      translatedText: 'ᱤᱧ ᱟᱢ ᱞᱟᱜᱤᱛ ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱸ',
      translatedRoman: 'Iñ am lāgit paṛhaw edañ.',
      confidenceScore: 78,
      priority: ReviewPriority.medium,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Communication',
        sessionLabel: 'Morning Session',
      ),
      reason: 'Low confidence — sent for expert review',
      status: ReviewItemStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_explain_to_you.wav',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // RV-002: Santali → Hindi, pending, confidence 62.
    TeacherReview(
      id: 'RV-002',
      phraseId: 'phrase_002',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱤᱧ ᱱᱚᱣᱟ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
      originalRoman: 'Iñ nowa bang bujhaṛ edañ.',
      translatedText: 'मुझे यह नहीं समझ रहा है',
      translatedRoman: 'Mujhe yah nahin samajh raha hai',
      confidenceScore: 62,
      priority: ReviewPriority.medium,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Communication',
        sessionLabel: 'Morning Session',
      ),
      reason: 'Student response — sent for expert review',
      status: ReviewItemStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_dont_understand_this.wav',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // RV-003: Hindi → Santali, pending, confidence 54.
    TeacherReview(
      id: 'RV-003',
      phraseId: 'phrase_003',
      direction: ReviewDirection.hindiToSantali,
      originalText: 'कृपया अपनी किताब खोलें',
      originalRoman: 'Kripya apni kitab kholen',
      translatedText: 'ᱠᱤᱯᱤᱫ ᱟᱨᱤ ᱠᱤᱴᱟᱠ ᱠᱳᱤᱞᱮᱭ',
      translatedRoman: 'Kipri api kitaab khulen',
      confidenceScore: 54,
      priority: ReviewPriority.medium,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Instructions',
        sessionLabel: 'Afternoon Session',
      ),
      reason: 'Low confidence — sent for expert review',
      status: ReviewItemStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_open_book.wav',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // RV-004: Santali → Hindi, resolved, confidence 91.
    TeacherReview(
      id: 'RV-004',
      phraseId: 'phrase_004',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱟᱨᱤ ᱠᱤᱱᱟᱨ ᱮᱫᱟᱸ',
      originalRoman: 'Api kiwār edañ.',
      translatedText: 'दरवाजा खोलो',
      translatedRoman: 'Darwaza kholo',
      confidenceScore: 91,
      priority: ReviewPriority.low,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Instructions',
        sessionLabel: 'Afternoon Session',
      ),
      reason: 'Teacher requested verification',
      status: ReviewItemStatus.resolved,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_open_door.wav',
      correctedText: 'दरवाजा खोलें',
      correctedRoman: 'Darwaza kholen',
      reviewer: 'Language Expert',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // RV-005: Hindi → Santali, resolved, confidence 84.
    TeacherReview(
      id: 'RV-005',
      phraseId: 'phrase_005',
      direction: ReviewDirection.hindiToSantali,
      originalText: 'बैठ जाओ',
      originalRoman: 'Baith jao',
      translatedText: 'ᱵᱟᱭᱤᱫ ᱡᱟᱦ',
      translatedRoman: 'Bāṭiẏā jāo',
      confidenceScore: 84,
      priority: ReviewPriority.low,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Instructions',
        sessionLabel: 'Morning Session',
      ),
      reason: 'Routine verification by expert',
      status: ReviewItemStatus.resolved,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_sit_down.wav',
      correctedText: 'ᱵᱟᱭᱤᱫ ᱡᱟᱦ',
      correctedRoman: 'Bāṭiẏā jāo',
      reviewer: 'Language Expert',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // RV-006: Santali → Hindi, resolved, confidence 67.
    TeacherReview(
      id: 'RV-006',
      phraseId: 'phrase_006',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱤᱧ ᱟᱢ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
      originalRoman: 'Iñ am bujhaṛ edañ.',
      translatedText: 'मैं समझ रहा हूँ',
      translatedRoman: 'Main samajh raha hoon',
      confidenceScore: 67,
      priority: ReviewPriority.medium,
      context: const ReviewContext(
        className: 'Class 2',
        subject: 'Language',
        topic: 'Classroom Communication',
        sessionLabel: 'Morning Session',
      ),
      reason: 'Student response — verified by expert',
      status: ReviewItemStatus.resolved,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_dont_understand_this.wav',
      correctedText: 'मैं समझ रहा हूँ',
      correctedRoman: 'Main samajh raha hoon',
      reviewer: 'Language Expert',
      teacherId: 'teacher_001',
      classroomId: 'classroom_002',
      teacherName: 'Sunita Kumari',
      classroomName: 'Class 2',
    ),

    // Internal record for another teacher/classroom — used only to verify
    // filtering. Must NEVER appear in the Teacher Review page.
    TeacherReview(
      id: 'RV-007',
      phraseId: 'phrase_007',
      direction: ReviewDirection.santaliToHindi,
      originalText: 'ᱤᱧ ᱟᱢ ᱵᱟᱝ ᱵᱩᱡᱷᱟᱹᱣ ᱮᱫᱟᱸ',
      originalRoman: 'Iñ am bang bujhaṛ edañ.',
      translatedText: 'मैं नहीं समझ रहा',
      translatedRoman: 'Main nahin samajh raha',
      confidenceScore: 45,
      priority: ReviewPriority.high,
      context: const ReviewContext(
        className: 'Class 3',
        subject: 'Language',
        topic: 'Classroom Communication',
        sessionLabel: 'Morning Session',
      ),
      reason: 'Internal record — other classroom',
      status: ReviewItemStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      audioAsset:
          'assets/prototype_content/translation/audio/santali/santali_i_dont_understand_this.wav',
      teacherId: 'teacher_002',
      classroomId: 'classroom_003',
      teacherName: 'Another Teacher',
      classroomName: 'Class 3',
    ),
  ];

  /// Get reviews filtered for current teacher and classroom
  static List<TeacherReview> getReviewsForCurrentTeacher() {
    return _allReviews
        .where((review) =>
            review.teacherId == currentTeacherId &&
            review.classroomId == currentClassroomId)
        .toList();
  }

  /// Get pending reviews for current teacher/classroom
  static List<TeacherReview> getPendingReviews() {
    return getReviewsForCurrentTeacher()
        .where((review) => review.isPending)
        .toList();
  }

  /// Get resolved reviews for current teacher/classroom
  static List<TeacherReview> getResolvedReviews() {
    return getReviewsForCurrentTeacher()
        .where((review) => review.isResolved)
        .toList();
  }

  /// Get review by ID (only if belongs to current teacher/classroom)
  static TeacherReview? getReviewById(String reviewId) {
    try {
      return getReviewsForCurrentTeacher()
          .firstWhere((review) => review.id == reviewId);
    } catch (_) {
      return null;
    }
  }

  /// Get counts for dashboard (computed from the dataset, never hardcoded).
  static Map<String, int> getCounts() {
    final reviews = getReviewsForCurrentTeacher();
    final pending = reviews.where((r) => r.isPending).length;
    final resolved = reviews.where((r) => r.isResolved).length;
    return {
      'total': reviews.length,
      'pending': pending,
      'resolved': resolved,
    };
  }

  @override
  List<Object?> get props => [_allReviews];
}
