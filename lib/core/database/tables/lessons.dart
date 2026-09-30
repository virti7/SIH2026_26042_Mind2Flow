import 'package:drift/drift.dart';

@DataClassName('LessonData')
class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get titleHi => text()();
  TextColumn get outcomeCode => text()();
  TextColumn get outcomeTitle => text()();
  IntColumn get grade => integer()();
  TextColumn get subject => text()();
  IntColumn get durationMinutes => integer()();
  TextColumn get learningObjective => text()();
  TextColumn get prerequisiteKnowledge => text()();
  TextColumn get teacherMoves => text()();
  TextColumn get activityOverview => text()();
  TextColumn get assessmentStrategy => text()();
  TextColumn get remediationOption => text()();
  TextColumn get tribalVocabularyJson => text()(); // JSON Map
  TextColumn get requiredMaterialsJson => text()(); // JSON List
  TextColumn get stepsJson => text()(); // JSON List of LessonStep
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
