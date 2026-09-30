import '../../models/teacher_activity.dart';
import '../../repositories/teacher_activity_repository.dart';

class GetTeacherActivitySummaryUseCase {
  final TeacherActivityRepository repository;

  const GetTeacherActivitySummaryUseCase(this.repository);

  Future<TeacherActivitySummary> execute() {
    return repository.getSummary();
  }
}

class GetRecentTeacherActivitiesUseCase {
  final TeacherActivityRepository repository;

  const GetRecentTeacherActivitiesUseCase(this.repository);

  Future<List<TeacherActivity>> execute({int limit = 20}) {
    return repository.getRecentActivities(limit: limit);
  }
}
