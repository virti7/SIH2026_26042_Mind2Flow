import '../../enums/app_enums.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GetNipunOutcomesUseCase {
  final LessonRepository repository;

  const GetNipunOutcomesUseCase(this.repository);

  Future<List<NipunOutcome>> execute({int? grade, String? domain}) async {
    return repository.getOutcomes(grade: grade, domain: domain);
  }
}

class GetLessonPlanUseCase {
  final LessonRepository repository;

  const GetLessonPlanUseCase(this.repository);

  Future<LessonPlan> execute(String outcomeCode) async {
    return repository.getLessonPlanForOutcome(outcomeCode);
  }
}

class CreateLessonPlanUseCase {
  final LessonRepository repository;

  const CreateLessonPlanUseCase(this.repository);

  Future<LessonPlan> execute(LessonPlan plan) async {
    return repository.createLesson(plan);
  }
}

class UpdateLessonPlanUseCase {
  final LessonRepository repository;

  const UpdateLessonPlanUseCase(this.repository);

  Future<LessonPlan> execute(LessonPlan plan) async {
    return repository.updateLesson(plan);
  }
}

class UpdateLessonDeliveryProgressUseCase {
  final LessonRepository repository;

  const UpdateLessonDeliveryProgressUseCase(this.repository);

  Future<void> execute({
    required String lessonId,
    required int currentStep,
    bool isCompleted = false,
  }) async {
    return repository.updateLessonDeliveryProgress(lessonId, currentStep, isCompleted);
  }
}

class GetLessonDeliveryProgressUseCase {
  final LessonRepository repository;

  const GetLessonDeliveryProgressUseCase(this.repository);

  Future<Map<String, dynamic>?> execute(String lessonId) async {
    return repository.getLessonDeliveryProgress(lessonId);
  }
}

class GetActivitiesUseCase {
  final LessonRepository repository;

  const GetActivitiesUseCase(this.repository);

  Future<List<ActivityItem>> execute({
    String? strand,
    int? grade,
    TribalLanguage? language,
  }) async {
    return repository.getActivities(strand: strand, grade: grade, language: language);
  }
}
