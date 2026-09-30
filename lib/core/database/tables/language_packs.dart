import 'package:drift/drift.dart';

@DataClassName('LanguagePackRecord')
class LanguagePacks extends Table {
  TextColumn get id => text()();
  TextColumn get language => text()();
  IntColumn get sizeMb => integer()();
  TextColumn get version => text()();
  TextColumn get status => text()(); // 'installed', 'available', 'downloading', 'updateAvailable'
  RealColumn get progress => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
