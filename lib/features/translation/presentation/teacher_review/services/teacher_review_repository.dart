import '../models/teacher_review.dart';
import '../data/teacher_review_demo_data.dart';

/// Repository for the teacher-facing Review list (READ-ONLY).
/// Provides view/inspect/filter/sort over static local demo data.
/// Write workflows live in the separate expert app, never here.
class TeacherReviewRepository {
  TeacherReviewRepository._();
  static final TeacherReviewRepository _instance = TeacherReviewRepository._();
  factory TeacherReviewRepository() => _instance;

  final List<TeacherReview> _reviews = List.from(TeacherReviewDemoData.allReviews);

  /// Get all reviews for the current teacher/classroom
  List<TeacherReview> getReviewsForTeacher({
    String teacherId = TeacherReviewDemoData.currentTeacherId,
    String classroomId = TeacherReviewDemoData.currentClassroomId,
  }) {
    return _reviews
        .where((review) =>
            review.teacherId == teacherId && review.classroomId == classroomId)
        .toList();
  }

  /// Get pending reviews for current teacher/classroom
  List<TeacherReview> getPendingReviews({
    String teacherId = TeacherReviewDemoData.currentTeacherId,
    String classroomId = TeacherReviewDemoData.currentClassroomId,
  }) {
    return getReviewsForTeacher(teacherId: teacherId, classroomId: classroomId)
        .where((review) => review.isPending)
        .toList();
  }

  /// Get resolved reviews for current teacher/classroom
  List<TeacherReview> getResolvedReviews({
    String teacherId = TeacherReviewDemoData.currentTeacherId,
    String classroomId = TeacherReviewDemoData.currentClassroomId,
  }) {
    return getReviewsForTeacher(teacherId: teacherId, classroomId: classroomId)
        .where((review) => review.isResolved)
        .toList();
  }

  /// Get review by ID (only if belongs to current teacher/classroom)
  TeacherReview? getReviewById(String reviewId,
      {String teacherId = TeacherReviewDemoData.currentTeacherId,
      String classroomId = TeacherReviewDemoData.currentClassroomId}) {
    try {
      return getReviewsForTeacher(teacherId: teacherId, classroomId: classroomId)
          .firstWhere((review) => review.id == reviewId);
    } catch (_) {
      return null;
    }
  }

  /// Get dashboard counts for current teacher/classroom
  Map<String, int> getCounts({
    String teacherId = TeacherReviewDemoData.currentTeacherId,
    String classroomId = TeacherReviewDemoData.currentClassroomId,
  }) {
    final reviews = getReviewsForTeacher(
        teacherId: teacherId, classroomId: classroomId);
    final pending = reviews.where((r) => r.isPending).length;
    final resolved = reviews.where((r) => r.isResolved).length;
    return {
      'total': reviews.length,
      'pending': pending,
      'resolved': resolved,
    };
  }

  /// Reset demo data (for testing)
  void resetDemoData() {
    _reviews.clear();
    _reviews.addAll(TeacherReviewDemoData.allReviews);
  }
}