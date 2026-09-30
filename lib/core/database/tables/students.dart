import 'package:drift/drift.dart';

@DataClassName('StudentData')
class Students extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get rollNumber => integer()();
  IntColumn get grade => integer()();
  TextColumn get motherTongue => text()();
  IntColumn get achievedOutcomes => integer().withDefault(const Constant(0))();
  IntColumn get developingOutcomes => integer().withDefault(const Constant(0))();
  IntColumn get needsSupportOutcomes => integer().withDefault(const Constant(0))();
  RealColumn get literacyProgress => real().withDefault(const Constant(0.0))();
  RealColumn get numeracyProgress => real().withDefault(const Constant(0.0))();
  TextColumn get recentEvidence => text()();
  TextColumn get identifiedGapsJson => text().withDefault(const Constant('[]'))(); // JSON list of strings
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
