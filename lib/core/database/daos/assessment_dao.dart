import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/assessment_results.dart';
import '../tables/assessments.dart';

part 'assessment_dao.g.dart';

@DriftAccessor(tables: [AssessmentQuestions, AssessmentResults])
class AssessmentDao extends DatabaseAccessor<AppDatabase> with _$AssessmentDaoMixin {
  AssessmentDao(super.db);

  Future<AssessmentQuestionData?> getQuestionsForOutcome(String outcomeCode) {
    return (select(assessmentQuestions)..where((tbl) => tbl.outcomeCode.equals(outcomeCode))).getSingleOrNull();
  }

  Future<void> insertAssessmentQuestions(AssessmentQuestionsCompanion questions) {
    return into(assessmentQuestions).insertOnConflictUpdate(questions);
  }

  Future<void> insertAssessmentResult(AssessmentResultsCompanion result) {
    return into(assessmentResults).insertOnConflictUpdate(result);
  }

  Future<void> insertAssessmentResults(List<AssessmentResultsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(assessmentResults, list));
  }

  Future<List<AssessmentResultRecord>> getAssessmentResultsForStudent(String studentId) {
    return (select(assessmentResults)
          ..where((tbl) => tbl.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<List<AssessmentResultRecord>> getAllAssessmentResults() {
    return (select(assessmentResults)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();
  }

  Future<int> getAssessmentCount() async {
    final countExp = assessmentResults.id.count();
    final query = selectOnly(assessmentResults)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
