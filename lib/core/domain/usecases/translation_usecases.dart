import '../../enums/app_enums.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class TranslateUtteranceUseCase {
  final TranslationRepository repository;

  const TranslateUtteranceUseCase(this.repository);

  Future<TranslationMessage> execute({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async {
    return repository.translateUtterance(
      text: text,
      targetLanguage: targetLanguage,
      isTeacher: isTeacher,
      contextMeta: contextMeta,
    );
  }
}

class GetQuickPhrasesUseCase {
  final TranslationRepository repository;

  const GetQuickPhrasesUseCase(this.repository);

  Future<List<QuickPhrase>> execute({String? category}) async {
    return repository.getQuickPhrases(category: category);
  }
}

class SubmitTranslationFeedbackUseCase {
  final TranslationRepository repository;

  const SubmitTranslationFeedbackUseCase(this.repository);

  Future<void> execute({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  }) async {
    return repository.submitFeedback(
      original: original,
      translated: translated,
      issueType: issueType,
      comment: comment,
    );
  }
}
