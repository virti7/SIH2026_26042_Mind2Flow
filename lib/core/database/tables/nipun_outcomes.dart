import 'package:drift/drift.dart';

@DataClassName('NipunOutcomeData')
class NipunOutcomes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()(); // e.g. M2.1.4
  IntColumn get grade => integer()();
  TextColumn get domain => text()();
  TextColumn get competency => text()();
  TextColumn get titleEn => text()();
  TextColumn get titleHi => text()();
  TextColumn get targetDescription => text()();
  TextColumn get defaultStatus => text()();
  TextColumn get unfinishedSkill => text()();

  @override
  Set<Column> get primaryKey => {id};
}
