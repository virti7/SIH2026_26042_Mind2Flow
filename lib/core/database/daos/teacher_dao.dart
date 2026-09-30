import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/teachers.dart';

part 'teacher_dao.g.dart';

@DriftAccessor(tables: [Teachers])
class TeacherDao extends DatabaseAccessor<AppDatabase> with _$TeacherDaoMixin {
  TeacherDao(super.db);

  Future<TeacherData?> getProfile() => select(teachers).getSingleOrNull();

  /// Account-scoped lookup. The teacher row PK is the Supabase user UUID,
  /// so one device holds one row per teacher account.
  Future<TeacherData?> getProfileById(String userId) {
    return (select(teachers)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateProfile(TeachersCompanion profile) =>
      into(teachers).insertOnConflictUpdate(profile);
}
