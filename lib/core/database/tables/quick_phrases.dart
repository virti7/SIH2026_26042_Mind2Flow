import 'package:drift/drift.dart';

@DataClassName('QuickPhraseData')
class QuickPhrases extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get hindi => text()();
  TextColumn get ho => text()();
  TextColumn get mundari => text()();
  TextColumn get santali => text()();

  @override
  Set<Column> get primaryKey => {id};
}
