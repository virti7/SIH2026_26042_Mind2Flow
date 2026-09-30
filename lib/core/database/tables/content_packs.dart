import 'package:drift/drift.dart';

@DataClassName('ContentPackRecord')
class ContentPacks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get sizeMb => integer()();
  BoolColumn get isInstalled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
