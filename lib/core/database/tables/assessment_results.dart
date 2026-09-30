import 'package:drift/drift.dart';

@DataClassName('AssessmentResultRecord')
class AssessmentResults extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get studentName => text()();
  TextColumn get outcomeCode => text()();
  TextColumn get outcomeTitle => text()();
  IntColumn get totalQuestions => integer()();
  IntColumn get correctCount => integer()();
  TextColumn get status => text()();
  TextColumn get unfinishedSkill => text()();
  TextColumn get recommendedRemediation => text()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
