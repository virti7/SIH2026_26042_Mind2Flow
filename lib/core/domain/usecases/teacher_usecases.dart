import '../../enums/app_enums.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GetTeacherProfileUseCase {
  final TeacherRepository repository;

  const GetTeacherProfileUseCase(this.repository);

  Future<TeacherProfile> execute() async {
    return repository.getProfile();
  }
}

class UpdateTeacherProfileUseCase {
  final TeacherRepository repository;

  const UpdateTeacherProfileUseCase(this.repository);

  Future<void> execute(TeacherProfile profile) async {
    return repository.updateProfile(profile);
  }
}

class GetClassroomLanguagesUseCase {
  final TeacherRepository repository;

  const GetClassroomLanguagesUseCase(this.repository);

  Future<List<TribalLanguage>> execute() async {
    return repository.getSelectedLanguages();
  }
}

class UpdateClassroomLanguagesUseCase {
  final TeacherRepository repository;

  const UpdateClassroomLanguagesUseCase(this.repository);

  Future<void> execute(List<TribalLanguage> languages) async {
    return repository.updateLanguages(languages);
  }
}
