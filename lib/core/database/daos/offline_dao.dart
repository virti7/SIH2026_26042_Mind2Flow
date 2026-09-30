import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/content_packs.dart';
import '../tables/language_packs.dart';

part 'offline_dao.g.dart';

@DriftAccessor(tables: [LanguagePacks, ContentPacks])
class OfflineDao extends DatabaseAccessor<AppDatabase> with _$OfflineDaoMixin {
  OfflineDao(super.db);

  Future<List<LanguagePackRecord>> getLanguagePacks() {
    return select(languagePacks).get();
  }

  Stream<List<LanguagePackRecord>> watchLanguagePacks() {
    return select(languagePacks).watch();
  }

  Future<void> insertOrUpdateLanguagePack(LanguagePacksCompanion pack) {
    return into(languagePacks).insertOnConflictUpdate(pack);
  }

  Future<void> insertLanguagePacks(List<LanguagePacksCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(languagePacks, list));
  }

  Future<List<ContentPackRecord>> getContentPacks() {
    return select(contentPacks).get();
  }

  Future<void> insertOrUpdateContentPack(ContentPacksCompanion pack) {
    return into(contentPacks).insertOnConflictUpdate(pack);
  }

  Future<void> insertContentPacks(List<ContentPacksCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(contentPacks, list));
  }
}
