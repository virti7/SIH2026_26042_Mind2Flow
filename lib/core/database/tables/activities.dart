import 'package:drift/drift.dart';

@DataClassName('ActivityData')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get titleHi => text()();
  IntColumn get grade => integer()();
  TextColumn get subject => text()();
  TextColumn get strandOrStage => text()();
  TextColumn get language => text()();
  IntColumn get durationMinutes => integer()();
  TextColumn get difficulty => text()();
  TextColumn get materials => text()();
  TextColumn get teacherStepsJson => text()(); // JSON List
  TextColumn get studentStepsJson => text()(); // JSON List
  TextColumn get questionsJson => text()(); // JSON List
  TextColumn get expectedResponse => text()();
  TextColumn get audioPromptHindi => text()();
  TextColumn get audioPromptTribal => text()();
  BoolColumn get isSaved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
