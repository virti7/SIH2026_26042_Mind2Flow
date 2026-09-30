// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_dao.dart';

// ignore_for_file: type=lint
mixin _$OfflineDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagePacksTable get languagePacks => attachedDatabase.languagePacks;
  $ContentPacksTable get contentPacks => attachedDatabase.contentPacks;
  OfflineDaoManager get managers => OfflineDaoManager(this);
}

class OfflineDaoManager {
  final _$OfflineDaoMixin _db;
  OfflineDaoManager(this._db);
  $$LanguagePacksTableTableManager get languagePacks =>
      $$LanguagePacksTableTableManager(_db.attachedDatabase, _db.languagePacks);
  $$ContentPacksTableTableManager get contentPacks =>
      $$ContentPacksTableTableManager(_db.attachedDatabase, _db.contentPacks);
}
