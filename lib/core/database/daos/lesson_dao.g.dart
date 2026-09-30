// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_dao.dart';

// ignore_for_file: type=lint
mixin _$LessonDaoMixin on DatabaseAccessor<AppDatabase> {
  $LessonsTable get lessons => attachedDatabase.lessons;
  $LessonDeliveryProgressTable get lessonDeliveryProgress =>
      attachedDatabase.lessonDeliveryProgress;
  LessonDaoManager get managers => LessonDaoManager(this);
}

class LessonDaoManager {
  final _$LessonDaoMixin _db;
  LessonDaoManager(this._db);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db.attachedDatabase, _db.lessons);
  $$LessonDeliveryProgressTableTableManager get lessonDeliveryProgress =>
      $$LessonDeliveryProgressTableTableManager(
        _db.attachedDatabase,
        _db.lessonDeliveryProgress,
      );
}
