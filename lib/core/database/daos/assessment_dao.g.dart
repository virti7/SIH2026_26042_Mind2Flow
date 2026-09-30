// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_dao.dart';

// ignore_for_file: type=lint
mixin _$AssessmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssessmentQuestionsTable get assessmentQuestions =>
      attachedDatabase.assessmentQuestions;
  $AssessmentResultsTable get assessmentResults =>
      attachedDatabase.assessmentResults;
  AssessmentDaoManager get managers => AssessmentDaoManager(this);
}

class AssessmentDaoManager {
  final _$AssessmentDaoMixin _db;
  AssessmentDaoManager(this._db);
  $$AssessmentQuestionsTableTableManager get assessmentQuestions =>
      $$AssessmentQuestionsTableTableManager(
        _db.attachedDatabase,
        _db.assessmentQuestions,
      );
  $$AssessmentResultsTableTableManager get assessmentResults =>
      $$AssessmentResultsTableTableManager(
        _db.attachedDatabase,
        _db.assessmentResults,
      );
}
