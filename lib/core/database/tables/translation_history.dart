import 'package:drift/drift.dart';

@DataClassName('TranslationHistoryData')
class TranslationHistory extends Table {
  TextColumn get id => text()();
  BoolColumn get isTeacher => boolean()();
  TextColumn get speakerName => text()();
  TextColumn get originalText => text()();
  TextColumn get translatedText => text()();
  TextColumn get targetLanguage => text()();
  IntColumn get latencyMs => integer()();
  BoolColumn get isOfflineNmt => boolean().withDefault(const Constant(true))();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
