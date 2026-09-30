import 'package:drift/drift.dart';

@DataClassName('TranslationFeedbackData')
class TranslationFeedback extends Table {
  TextColumn get id => text()();
  TextColumn get original => text()();
  TextColumn get translated => text()();
  TextColumn get issueType => text()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
