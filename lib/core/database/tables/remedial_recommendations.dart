import 'package:drift/drift.dart';

@DataClassName('RemedialRecommendationData')
class RemedialRecommendations extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().nullable()();
  TextColumn get outcomeCode => text()();
  TextColumn get title => text()();
  TextColumn get subject => text()();
  TextColumn get culturalHook => text()();
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {id};
}
