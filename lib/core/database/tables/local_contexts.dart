import 'package:drift/drift.dart';

@DataClassName('LocalContextData')
class LocalContexts extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get titleHi => text()();
  TextColumn get description => text()();
  TextColumn get culturalRelevance => text()();
  TextColumn get tribalTerm => text()();
  TextColumn get language => text()();

  @override
  Set<Column> get primaryKey => {id};
}
