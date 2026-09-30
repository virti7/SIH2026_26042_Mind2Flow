import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/saved_materials.dart';

part 'resource_dao.g.dart';

@DriftAccessor(tables: [SavedMaterials])
class ResourceDao extends DatabaseAccessor<AppDatabase> with _$ResourceDaoMixin {
  ResourceDao(super.db);

  Future<void> insertSavedMaterial(SavedMaterialsCompanion material) {
    return into(savedMaterials).insertOnConflictUpdate(material);
  }

  Future<void> insertSavedMaterials(List<SavedMaterialsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(savedMaterials, list));
  }

  Future<List<SavedMaterialData>> getSavedMaterials({String? type}) {
    final query = select(savedMaterials);
    if (type != null && type.isNotEmpty && type != 'All') {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<SavedMaterialData?> getSavedMaterialById(String id) {
    return (select(savedMaterials)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Account-scoped read: only rows claimed by the current teacher (via the
  /// `account_owned_records` mapping, entity_type `saved_material`) are
  /// returned. Pass the id set from `ownedEntityIds(...)`; rows without a
  /// claim (legacy) stay hidden from every account. Never load all rows and
  /// filter in the UI — filter here, at the data layer.
  Future<List<SavedMaterialData>> getOwnedSavedMaterials({
    String? type,
    required Set<String> ownedIds,
  }) async {
    if (ownedIds.isEmpty) return const [];
    final query = select(savedMaterials)
      ..where((tbl) => tbl.id.isIn(ownedIds));
    if (type != null && type.isNotEmpty && type != 'All') {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Account-scoped single-row read. Returns null unless [id] is claimed by
  /// the current teacher, so one account can never open another's material
  /// by id (preview fallback, sync completion checks).
  Future<SavedMaterialData?> getOwnedSavedMaterialById(
    String id,
    Set<String> ownedIds,
  ) {
    if (!ownedIds.contains(id)) return Future.value(null);
    return getSavedMaterialById(id);
  }

  Future<int> getSavedMaterialsCount() async {
    final countExp = savedMaterials.id.count();
    final query = selectOnly(savedMaterials)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
