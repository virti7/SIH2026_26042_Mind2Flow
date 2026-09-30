// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curriculum_dao.dart';

// ignore_for_file: type=lint
mixin _$CurriculumDaoMixin on DatabaseAccessor<AppDatabase> {
  $NipunOutcomesTable get nipunOutcomes => attachedDatabase.nipunOutcomes;
  $LocalContextsTable get localContexts => attachedDatabase.localContexts;
  $ActivitiesTable get activities => attachedDatabase.activities;
  CurriculumDaoManager get managers => CurriculumDaoManager(this);
}

class CurriculumDaoManager {
  final _$CurriculumDaoMixin _db;
  CurriculumDaoManager(this._db);
  $$NipunOutcomesTableTableManager get nipunOutcomes =>
      $$NipunOutcomesTableTableManager(_db.attachedDatabase, _db.nipunOutcomes);
  $$LocalContextsTableTableManager get localContexts =>
      $$LocalContextsTableTableManager(_db.attachedDatabase, _db.localContexts);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db.attachedDatabase, _db.activities);
}
