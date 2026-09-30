import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/activities.dart';
import '../tables/local_contexts.dart';
import '../tables/nipun_outcomes.dart';

part 'curriculum_dao.g.dart';

@DriftAccessor(tables: [NipunOutcomes, LocalContexts, Activities])
class CurriculumDao extends DatabaseAccessor<AppDatabase> with _$CurriculumDaoMixin {
  CurriculumDao(super.db);

  Future<List<NipunOutcomeData>> getOutcomes({int? grade, String? domain}) {
    final query = select(nipunOutcomes);
    if (grade != null) {
      query.where((tbl) => tbl.grade.equals(grade));
    }
    if (domain != null && domain.isNotEmpty) {
      query.where((tbl) => tbl.domain.equals(domain));
    }
    return query.get();
  }

  Future<NipunOutcomeData?> getOutcomeByCode(String code) {
    return (select(nipunOutcomes)..where((tbl) => tbl.code.equals(code))).getSingleOrNull();
  }

  Future<void> insertOutcomes(List<NipunOutcomesCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(nipunOutcomes, list));
  }

  Future<List<LocalContextData>> getLocalContextItems({String? category}) {
    final query = select(localContexts);
    if (category != null && category.isNotEmpty && category != 'All') {
      query.where((tbl) => tbl.category.equals(category));
    }
    return query.get();
  }

  Future<void> insertLocalContexts(List<LocalContextsCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(localContexts, list));
  }

  Future<List<ActivityData>> getActivities({String? strand, int? grade, String? language}) {
    final query = select(activities);
    if (grade != null) {
      query.where((tbl) => tbl.grade.equals(grade));
    }
    if (strand != null && strand.isNotEmpty) {
      query.where((tbl) => tbl.strandOrStage.equals(strand));
    }
    if (language != null && language.isNotEmpty) {
      query.where((tbl) => tbl.language.equals(language));
    }
    return query.get();
  }

  Future<ActivityData?> getActivityById(String id) {
    return (select(activities)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertActivities(List<ActivitiesCompanion> list) async {
    await batch((b) => b.insertAllOnConflictUpdate(activities, list));
  }
}
