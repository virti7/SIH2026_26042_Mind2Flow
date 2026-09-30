// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_dao.dart';

// ignore_for_file: type=lint
mixin _$StudentDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudentsTable get students => attachedDatabase.students;
  $LearningGapsTable get learningGaps => attachedDatabase.learningGaps;
  $RemedialRecommendationsTable get remedialRecommendations =>
      attachedDatabase.remedialRecommendations;
  StudentDaoManager get managers => StudentDaoManager(this);
}

class StudentDaoManager {
  final _$StudentDaoMixin _db;
  StudentDaoManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$LearningGapsTableTableManager get learningGaps =>
      $$LearningGapsTableTableManager(_db.attachedDatabase, _db.learningGaps);
  $$RemedialRecommendationsTableTableManager get remedialRecommendations =>
      $$RemedialRecommendationsTableTableManager(
        _db.attachedDatabase,
        _db.remedialRecommendations,
      );
}
