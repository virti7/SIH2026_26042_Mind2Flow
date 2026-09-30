import 'package:drift/drift.dart';

@DataClassName('TeacherData')
class Teachers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get school => text()();
  TextColumn get district => text()();
  TextColumn get state => text()();
  TextColumn get classesTaughtJson => text()(); // JSON list of ints e.g. [1, 2, 3]
  TextColumn get teachingLanguage => text()();
  TextColumn get supportedLanguagesJson => text()(); // JSON list of string language names
  TextColumn get activeSessionLanguage => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
