// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_dao.dart';

// ignore_for_file: type=lint
mixin _$TeacherDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeachersTable get teachers => attachedDatabase.teachers;
  TeacherDaoManager get managers => TeacherDaoManager(this);
}

class TeacherDaoManager {
  final _$TeacherDaoMixin _db;
  TeacherDaoManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
}
