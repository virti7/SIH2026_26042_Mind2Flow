import 'package:drift/drift.dart';

@DataClassName('SavedMaterialData')
class SavedMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'worksheet', 'flashcard', 'activity', 'lesson'
  TextColumn get title => text()();
  TextColumn get titleHi => text()();
  IntColumn get grade => integer()();
  TextColumn get subject => text()();
  TextColumn get outcomeCode => text()();
  TextColumn get language => text()();
  TextColumn get difficulty => text()();
  TextColumn get contentJson => text()(); // Serialized representation of worksheet, flashcard, or activity
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
