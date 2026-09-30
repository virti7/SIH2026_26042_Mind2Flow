import '../../enums/app_enums.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GetStudentsUseCase {
  final StudentRepository repository;

  const GetStudentsUseCase(this.repository);

  Future<List<StudentRecord>> execute({int? grade}) async {
    return repository.getStudents(grade: grade);
  }
}

class GetStudentProfileUseCase {
  final StudentRepository repository;

  const GetStudentProfileUseCase(this.repository);

  Future<StudentRecord?> execute(String studentId) async {
    return repository.getStudentById(studentId);
  }
}

class UpdateStudentOutcomeStatusUseCase {
  final StudentRepository repository;

  const UpdateStudentOutcomeStatusUseCase(this.repository);

  Future<void> execute(String studentId, String outcomeCode, OutcomeStatus newStatus) async {
    return repository.updateOutcomeStatus(studentId, outcomeCode, newStatus);
  }
}
