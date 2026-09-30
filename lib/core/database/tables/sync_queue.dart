import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'teacher_profile', 'lesson', 'assessment_result', etc.
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get payload => text()(); // JSON payload
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // 'PENDING', 'SYNCING', 'SYNCED', 'FAILED'
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
