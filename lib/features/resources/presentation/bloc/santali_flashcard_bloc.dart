import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/content/flashcard/santali_flashcard_model.dart';
import '../../../../core/content/flashcard/santali_flashcard_repository.dart';

// ---- Events ----

abstract class SantaliFlashcardEvent extends Equatable {
  const SantaliFlashcardEvent();
  @override
  List<Object?> get props => [];
}

class LoadSantaliDecksEvent extends SantaliFlashcardEvent {
  final String? initialDeckId;
  const LoadSantaliDecksEvent({this.initialDeckId});
  @override
  List<Object?> get props => [initialDeckId];
}

class SelectSantaliDeckEvent extends SantaliFlashcardEvent {
  final String deckId;
  const SelectSantaliDeckEvent(this.deckId);
  @override
  List<Object?> get props => [deckId];
}

class FlipCardEvent extends SantaliFlashcardEvent {}

class NextCardEvent extends SantaliFlashcardEvent {}

class PreviousCardEvent extends SantaliFlashcardEvent {}

class AnswerCardEvent extends SantaliFlashcardEvent {
  final bool isCorrect;
  const AnswerCardEvent({required this.isCorrect});
  @override
  List<Object?> get props => [isCorrect];
}

class ResetDeckProgressEvent extends SantaliFlashcardEvent {
  final String deckId;
  const ResetDeckProgressEvent(this.deckId);
  @override
  List<Object?> get props => [deckId];
}

class RestartDeckEvent extends SantaliFlashcardEvent {
  const RestartDeckEvent();
}

// ---- States ----

abstract class SantaliFlashcardState extends Equatable {
  const SantaliFlashcardState();
  @override
  List<Object?> get props => [];
}

class SantaliFlashcardInitial extends SantaliFlashcardState {}

class SantaliFlashcardLoading extends SantaliFlashcardState {}

class SantaliFlashcardLoaded extends SantaliFlashcardState {
  final List<FlashcardCategoryMetadata> categories;
  final List<FlashcardDeck> decks;
  final FlashcardDeck? activeDeck;
  final int currentIndex;
  final bool isRevealed;
  final Map<String, FlashcardLearningProgress> progressMap;
  final String assetRoot;

  const SantaliFlashcardLoaded({
    required this.categories,
    required this.decks,
    this.activeDeck,
    this.currentIndex = 0,
    this.isRevealed = false,
    required this.progressMap,
    required this.assetRoot,
  });

  CurriculumFlashcard? get currentCard {
    if (activeDeck == null || activeDeck!.cards.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= activeDeck!.cards.length) return null;
    return activeDeck!.cards[currentIndex];
  }

  int get totalCardsInDeck => activeDeck?.cardCount ?? 0;

  FlashcardLearningProgress? get currentCardProgress {
    final c = currentCard;
    if (c == null) return null;
    return progressMap[c.id];
  }

  int masteredCountForDeck(String deckId) {
    final deck = decks.firstWhere((d) => d.id == deckId, orElse: () => FlashcardDeck(id: '', title: '', categoryKey: '', folder: ''));
    int count = 0;
    for (final card in deck.cards) {
      if (progressMap[card.id]?.isMastered == true) count++;
    }
    return count;
  }

  int seenCountForDeck(String deckId) {
    final deck = decks.firstWhere((d) => d.id == deckId, orElse: () => FlashcardDeck(id: '', title: '', categoryKey: '', folder: ''));
    int count = 0;
    for (final card in deck.cards) {
      if ((progressMap[card.id]?.seenCount ?? 0) > 0) count++;
    }
    return count;
  }

  SantaliFlashcardLoaded copyWith({
    List<FlashcardCategoryMetadata>? categories,
    List<FlashcardDeck>? decks,
    FlashcardDeck? activeDeck,
    int? currentIndex,
    bool? isRevealed,
    Map<String, FlashcardLearningProgress>? progressMap,
    String? assetRoot,
  }) {
    return SantaliFlashcardLoaded(
      categories: categories ?? this.categories,
      decks: decks ?? this.decks,
      activeDeck: activeDeck ?? this.activeDeck,
      currentIndex: currentIndex ?? this.currentIndex,
      isRevealed: isRevealed ?? this.isRevealed,
      progressMap: progressMap ?? this.progressMap,
      assetRoot: assetRoot ?? this.assetRoot,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        decks,
        activeDeck,
        currentIndex,
        isRevealed,
        progressMap,
        assetRoot,
      ];
}

class SantaliFlashcardError extends SantaliFlashcardState {
  final String message;
  const SantaliFlashcardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ---- BLoC ----

class SantaliFlashcardBloc extends Bloc<SantaliFlashcardEvent, SantaliFlashcardState> {
  final SantaliFlashcardRepository repository;
  bool _isAnswering = false;

  SantaliFlashcardBloc({required this.repository}) : super(SantaliFlashcardInitial()) {
    on<LoadSantaliDecksEvent>(_onLoadDecks);
    on<SelectSantaliDeckEvent>(_onSelectDeck);
    on<FlipCardEvent>(_onFlipCard);
    on<NextCardEvent>(_onNextCard);
    on<PreviousCardEvent>(_onPreviousCard);
    on<AnswerCardEvent>(_onAnswerCard);
    on<RestartDeckEvent>(_onRestartDeck);
    on<ResetDeckProgressEvent>(_onResetDeck);
  }

  Future<void> _onLoadDecks(
    LoadSantaliDecksEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    emit(SantaliFlashcardLoading());
    try {
      final categories = await repository.getCategories();
      final decks = await repository.getDecks();
      final progressMap = await repository.getAllProgress();
      final assetRoot = repository.assetRoot;

      FlashcardDeck? activeDeck;
      if (event.initialDeckId != null) {
        activeDeck = decks.firstWhere(
          (d) => d.id == event.initialDeckId,
          orElse: () => decks.isNotEmpty ? decks.first : FlashcardDeck(id: '', title: '', categoryKey: '', folder: ''),
        );
      }

      emit(SantaliFlashcardLoaded(
        categories: categories,
        decks: decks,
        activeDeck: activeDeck,
        currentIndex: 0,
        isRevealed: false,
        progressMap: progressMap,
        assetRoot: assetRoot,
      ));

      // If an active deck is present with cards, record presentation of the first card
      if (activeDeck != null && activeDeck.cards.isNotEmpty) {
        final firstCard = activeDeck.cards.first;
        final seenProg = await repository.recordCardSeen(firstCard.id);
        final updatedMap = Map<String, FlashcardLearningProgress>.from(progressMap);
        updatedMap[firstCard.id] = seenProg;
        if (state is SantaliFlashcardLoaded) {
          emit((state as SantaliFlashcardLoaded).copyWith(progressMap: updatedMap));
        }
      }
    } catch (e) {
      emit(SantaliFlashcardError('Failed to load flashcard curriculum: $e'));
    }
  }

  Future<void> _onSelectDeck(
    SelectSantaliDeckEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      final deck = s.decks.firstWhere(
        (d) => d.id == event.deckId,
        orElse: () => s.decks.first,
      );
      emit(s.copyWith(
        activeDeck: deck,
        currentIndex: 0,
        isRevealed: false,
      ));

      // Record presentation of first card in deck
      if (deck.cards.isNotEmpty) {
        final firstCard = deck.cards.first;
        final seenProg = await repository.recordCardSeen(firstCard.id);
        final updatedMap = Map<String, FlashcardLearningProgress>.from(s.progressMap);
        updatedMap[firstCard.id] = seenProg;
        if (state is SantaliFlashcardLoaded) {
          emit((state as SantaliFlashcardLoaded).copyWith(progressMap: updatedMap));
        }
      }
    }
  }

  void _onFlipCard(
    FlipCardEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      emit(s.copyWith(isRevealed: !s.isRevealed));
    }
  }

  Future<void> _onNextCard(
    NextCardEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      if (s.activeDeck != null && s.currentIndex < s.activeDeck!.cards.length - 1) {
        final nextIndex = s.currentIndex + 1;
        emit(s.copyWith(
          currentIndex: nextIndex,
          isRevealed: false,
        ));

        final nextCard = s.activeDeck!.cards[nextIndex];
        final seenProg = await repository.recordCardSeen(nextCard.id);
        final updatedMap = Map<String, FlashcardLearningProgress>.from(s.progressMap);
        updatedMap[nextCard.id] = seenProg;
        if (state is SantaliFlashcardLoaded) {
          emit((state as SantaliFlashcardLoaded).copyWith(progressMap: updatedMap));
        }
      }
    }
  }

  Future<void> _onPreviousCard(
    PreviousCardEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      if (s.currentIndex > 0) {
        final prevIndex = s.currentIndex - 1;
        emit(s.copyWith(
          currentIndex: prevIndex,
          isRevealed: false,
        ));

        if (s.activeDeck != null && prevIndex < s.activeDeck!.cards.length) {
          final prevCard = s.activeDeck!.cards[prevIndex];
          final seenProg = await repository.recordCardSeen(prevCard.id);
          final updatedMap = Map<String, FlashcardLearningProgress>.from(s.progressMap);
          updatedMap[prevCard.id] = seenProg;
          if (state is SantaliFlashcardLoaded) {
            emit((state as SantaliFlashcardLoaded).copyWith(progressMap: updatedMap));
          }
        }
      }
    }
  }

  Future<void> _onAnswerCard(
    AnswerCardEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is! SantaliFlashcardLoaded) return;
    final s = state as SantaliFlashcardLoaded;

    // Guard: Only revealed cards can be answered (prevents blind answering)
    if (!s.isRevealed) return;

    // Guard: Prevent double-tap race conditions while async persistence is in flight
    if (_isAnswering) return;
    _isAnswering = true;

    try {
      final card = s.currentCard;
      if (card == null) return;

      final updatedProgress = await repository.recordCardResult(
        cardId: card.id,
        isCorrect: event.isCorrect,
      );

      final newMap = Map<String, FlashcardLearningProgress>.from(s.progressMap);
      newMap[card.id] = updatedProgress;

      // Auto-advance to next card if not at the end
      final hasNext = s.activeDeck != null && s.currentIndex < s.activeDeck!.cards.length - 1;
      final nextIndex = hasNext ? s.currentIndex + 1 : s.currentIndex;

      emit(s.copyWith(
        progressMap: newMap,
        currentIndex: nextIndex,
        isRevealed: false,
      ));

      // Record presentation of the newly advanced card
      if (hasNext && s.activeDeck != null && nextIndex < s.activeDeck!.cards.length) {
        final nextCard = s.activeDeck!.cards[nextIndex];
        final seenProg = await repository.recordCardSeen(nextCard.id);
        final mapWithSeen = Map<String, FlashcardLearningProgress>.from(
          state is SantaliFlashcardLoaded ? (state as SantaliFlashcardLoaded).progressMap : newMap,
        );
        mapWithSeen[nextCard.id] = seenProg;
        if (state is SantaliFlashcardLoaded) {
          emit((state as SantaliFlashcardLoaded).copyWith(progressMap: mapWithSeen));
        }
      }
    } finally {
      _isAnswering = false;
    }
  }

  Future<void> _onRestartDeck(
    RestartDeckEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      emit(s.copyWith(
        currentIndex: 0,
        isRevealed: false,
      ));

      if (s.activeDeck != null && s.activeDeck!.cards.isNotEmpty) {
        final firstCard = s.activeDeck!.cards.first;
        final seenProg = await repository.recordCardSeen(firstCard.id);
        final updatedMap = Map<String, FlashcardLearningProgress>.from(s.progressMap);
        updatedMap[firstCard.id] = seenProg;
        if (state is SantaliFlashcardLoaded) {
          emit((state as SantaliFlashcardLoaded).copyWith(progressMap: updatedMap));
        }
      }
    }
  }

  Future<void> _onResetDeck(
    ResetDeckProgressEvent event,
    Emitter<SantaliFlashcardState> emit,
  ) async {
    if (state is SantaliFlashcardLoaded) {
      final s = state as SantaliFlashcardLoaded;
      await repository.resetDeckProgress(event.deckId);
      final newMap = await repository.getAllProgress();
      emit(s.copyWith(
        progressMap: newMap,
        currentIndex: 0,
        isRevealed: false,
      ));
    }
  }
}
