import 'package:drift/drift.dart';

@DataClassName('LearningGapData')
class LearningGaps extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get outcomeCode => text()();
  TextColumn get skill => text()();
  TextColumn get rootCause => text()();
  TextColumn get remediationUsed => text()();
  TextColumn get status => text()(); // 'Ongoing Intervention' or 'Resolved via Remediation'
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
