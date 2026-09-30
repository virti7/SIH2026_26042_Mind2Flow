import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GetAssessmentQuestionsUseCase {
  final AssessmentRepository repository;

  const GetAssessmentQuestionsUseCase(this.repository);

  Future<List<AssessmentQuestionItem>> execute(String outcomeCode) async {
    return repository.getQuestionsForOutcome(outcomeCode);
  }
}

class SubmitAssessmentUseCase {
  final AssessmentRepository repository;

  const SubmitAssessmentUseCase(this.repository);

  Future<AssessmentResultData> execute({
    required String studentId,
    required String studentName,
    required String outcomeCode,
    required List<int> selectedAnswers,
  }) async {
    return repository.submitAssessment(
      studentId: studentId,
      studentName: studentName,
      outcomeCode: outcomeCode,
      selectedAnswers: selectedAnswers,
    );
  }
}

class GetRemedialActivityUseCase {
  final AssessmentRepository repository;

  const GetRemedialActivityUseCase(this.repository);

  Future<ActivityItem> execute(String outcomeCode) async {
    return repository.getRemedialActivityForOutcome(outcomeCode);
  }
}

class SubmitReassessmentUseCase {
  final AssessmentRepository repository;

  const SubmitReassessmentUseCase(this.repository);

  Future<AssessmentResultData> execute({
    required String studentId,
    required String outcomeCode,
    required bool passed,
  }) async {
    return repository.submitReassessment(
      studentId: studentId,
      outcomeCode: outcomeCode,
      passed: passed,
    );
  }
}
