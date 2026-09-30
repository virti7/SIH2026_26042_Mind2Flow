import '../../enums/app_enums.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class GenerateWorksheetUseCase {
  final ResourceRepository repository;

  const GenerateWorksheetUseCase(this.repository);

  Future<QueuedWorksheetGeneration> execute({
    required int grade,
    required String subject,
    required String outcomeCode,
    required TribalLanguage targetLanguage,
    required DifficultyLevel difficulty,
    required WorksheetType type,
    required int questionCount,
  }) async {
    return repository.generateWorksheet(
      grade: grade,
      subject: subject,
      outcomeCode: outcomeCode,
      targetLanguage: targetLanguage,
      difficulty: difficulty,
      type: type,
      questionCount: questionCount,
    );
  }
}

class SaveWorksheetUseCase {
  final ResourceRepository repository;

  const SaveWorksheetUseCase(this.repository);

  Future<void> execute(WorksheetItem item) async {
    return repository.saveWorksheet(item);
  }
}

class GetSavedWorksheetsUseCase {
  final ResourceRepository repository;

  const GetSavedWorksheetsUseCase(this.repository);

  Future<List<WorksheetItem>> execute() async {
    return repository.getSavedWorksheets();
  }
}

class GetFlashcardsUseCase {
  final ResourceRepository repository;

  const GetFlashcardsUseCase(this.repository);

  Future<List<FlashcardItem>> execute({
    required String topic,
    required TribalLanguage language,
  }) async {
    return repository.getFlashcards(topic: topic, language: language);
  }
}

class GetSavedFlashcardsUseCase {
  final ResourceRepository repository;

  const GetSavedFlashcardsUseCase(this.repository);

  Future<List<FlashcardItem>> execute() async {
    return repository.getSavedFlashcards();
  }
}
