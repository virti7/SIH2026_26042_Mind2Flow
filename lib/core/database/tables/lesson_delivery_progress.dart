import 'package:drift/drift.dart';

@DataClassName('LessonDeliveryProgressData')
class LessonDeliveryProgress extends Table {
  TextColumn get lessonId => text()();
  IntColumn get currentStep => integer()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {lessonId};
}
