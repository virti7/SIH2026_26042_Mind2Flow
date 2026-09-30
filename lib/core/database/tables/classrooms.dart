import 'package:drift/drift.dart';

@DataClassName('ClassroomData')
class Classrooms extends Table {
  TextColumn get id => text()();
  IntColumn get grade => integer()();
  TextColumn get name => text()();
  TextColumn get section => text().withDefault(const Constant('A'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
