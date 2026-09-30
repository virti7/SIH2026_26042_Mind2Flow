// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_dao.dart';

// ignore_for_file: type=lint
mixin _$ResourceDaoMixin on DatabaseAccessor<AppDatabase> {
  $SavedMaterialsTable get savedMaterials => attachedDatabase.savedMaterials;
  ResourceDaoManager get managers => ResourceDaoManager(this);
}

class ResourceDaoManager {
  final _$ResourceDaoMixin _db;
  ResourceDaoManager(this._db);
  $$SavedMaterialsTableTableManager get savedMaterials =>
      $$SavedMaterialsTableTableManager(
        _db.attachedDatabase,
        _db.savedMaterials,
      );
}
