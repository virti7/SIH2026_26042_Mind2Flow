import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/learning_gaps.dart';
import '../tables/remedial_recommendations.dart';
import '../tables/students.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students, LearningGaps, RemedialRecommendations])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.db);

  Future<List<StudentData>> getStudents({int? grade}) {
    final query = select(students);
    if (grade != null) {
      query.where((tbl) => tbl.grade.equals(grade));
    }
    return query.get();
  }

  Future<StudentData?> getStudentById(String id) {
    return (select(students)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdateStudent(StudentsCompanion student) {
    return into(students).insertOnConflictUpdate(student);
  }

  Future<void> insertStudents(List<StudentsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(students, list));
  }

  Future<List<LearningGapData>> getLearningGapsByStudent(String studentId) {
    return (select(learningGaps)
          ..where((tbl) => tbl.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> insertOrUpdateLearningGap(LearningGapsCompanion gap) {
    return into(learningGaps).insertOnConflictUpdate(gap);
  }

  Future<void> insertLearningGaps(List<LearningGapsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(learningGaps, list));
  }

  Future<List<RemedialRecommendationData>> getRemedialRecommendations(String outcomeCode, {String? studentId}) {
    final query = select(remedialRecommendations)..where((tbl) => tbl.outcomeCode.equals(outcomeCode));
    if (studentId != null) {
      query.where((tbl) => tbl.studentId.equals(studentId) | tbl.studentId.isNull());
    }
    return query.get();
  }

  Future<void> insertRemedialRecommendations(List<RemedialRecommendationsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(remedialRecommendations, list));
  }
}
