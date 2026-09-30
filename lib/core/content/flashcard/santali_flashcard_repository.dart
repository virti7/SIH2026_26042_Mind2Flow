import 'flashcard_progress_store.dart';
import 'santali_flashcard_local_data_source.dart';
import 'santali_flashcard_model.dart';

abstract class SantaliFlashcardRepository {
  Future<List<FlashcardCategoryMetadata>> getCategories();
  Future<List<FlashcardDeck>> getDecks();
  Future<FlashcardDeck?> getDeckById(String deckId);
  Future<CurriculumFlashcard?> getCardById(String cardId);
  Future<List<CurriculumFlashcard>> getAllCards();
  Future<Map<String, FlashcardLearningProgress>> getAllProgress();
  Future<FlashcardLearningProgress?> getProgress(String cardId);
  Future<FlashcardLearningProgress> recordCardSeen(String cardId);
  Future<FlashcardLearningProgress> recordCardResult({
    required String cardId,
    required bool isCorrect,
  });
  Future<void> resetDeckProgress(String deckId);
  String get assetRoot;
}

class SantaliFlashcardRepositoryImpl implements SantaliFlashcardRepository {
  final SantaliFlashcardLocalDataSource localDataSource;
  final FlashcardProgressStore progressStore;

  SantaliFlashcardRepositoryImpl({
    required this.localDataSource,
    required this.progressStore,
  });

  @override
  String get assetRoot => localDataSource.assetRoot;

  @override
  Future<List<FlashcardCategoryMetadata>> getCategories() =>
      localDataSource.getCategories();

  @override
  Future<List<FlashcardDeck>> getDecks() => localDataSource.getDecks();

  @override
  Future<FlashcardDeck?> getDeckById(String deckId) =>
      localDataSource.getDeckById(deckId);

  @override
  Future<CurriculumFlashcard?> getCardById(String cardId) =>
      localDataSource.getCardById(cardId);

  @override
  Future<List<CurriculumFlashcard>> getAllCards() =>
      localDataSource.getAllCards();

  @override
  Future<Map<String, FlashcardLearningProgress>> getAllProgress() =>
      progressStore.getAllProgress();

  @override
  Future<FlashcardLearningProgress?> getProgress(String cardId) =>
      progressStore.getProgress(cardId);

  @override
  Future<FlashcardLearningProgress> recordCardSeen(String cardId) =>
      progressStore.recordSeen(cardId);

  @override
  Future<FlashcardLearningProgress> recordCardResult({
    required String cardId,
    required bool isCorrect,
  }) =>
      progressStore.recordAttempt(cardId: cardId, isCorrect: isCorrect);

  @override
  Future<void> resetDeckProgress(String deckId) async {
    final deck = await getDeckById(deckId);
    if (deck == null) return;
    final cardIds = deck.cards.map((c) => c.id).toList();
    await progressStore.resetDeckProgress(cardIds);
  }
}
