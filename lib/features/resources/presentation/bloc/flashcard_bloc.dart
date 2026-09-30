import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

abstract class FlashcardEvent extends Equatable {
  const FlashcardEvent();
  @override
  List<Object?> get props => [];
}

class LoadFlashcardsEvent extends FlashcardEvent {
  final String topic;
  final TribalLanguage language;
  const LoadFlashcardsEvent({this.topic = 'Numbers', this.language = TribalLanguage.mundari});
  @override
  List<Object?> get props => [topic, language];
}

class NextFlashcardEvent extends FlashcardEvent {}
class PrevFlashcardEvent extends FlashcardEvent {}

class SwitchFlashcardLanguage extends FlashcardEvent {
  final TribalLanguage language;
  const SwitchFlashcardLanguage(this.language);
  @override
  List<Object?> get props => [language];
}

abstract class FlashcardState extends Equatable {
  const FlashcardState();
  @override
  List<Object?> get props => [];
}

class FlashcardLoading extends FlashcardState {}

class FlashcardLoaded extends FlashcardState {
  final List<FlashcardItem> cards;
  final int currentIndex;
  final TribalLanguage language;
  final bool isAudioPlaying;

  const FlashcardLoaded({
    required this.cards,
    required this.currentIndex,
    required this.language,
    this.isAudioPlaying = false,
  });

  FlashcardItem get currentCard => cards[currentIndex];

  @override
  List<Object?> get props => [cards, currentIndex, language, isAudioPlaying];
}

class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  final ResourceRepository resourceRepository;

  FlashcardBloc({required this.resourceRepository}) : super(FlashcardLoading()) {
    on<LoadFlashcardsEvent>((event, emit) async {
      emit(FlashcardLoading());
      final cards = await resourceRepository.getFlashcards(
        topic: event.topic,
        language: event.language,
      );
      // Record real classroom use so teacher Progress reflects it.
      // Stored per topic+language (upsert), so repeated use never duplicates.
      try {
        await resourceRepository.saveFlashcardSet(
          topic: event.topic,
          language: event.language,
          cards: cards,
        );
      } catch (_) {
        // Usage recording is best-effort; cards still display offline.
      }
      emit(FlashcardLoaded(
        cards: cards,
        currentIndex: 0,
        language: event.language,
      ));
    });

    on<NextFlashcardEvent>((event, emit) {
      if (state is FlashcardLoaded) {
        final current = state as FlashcardLoaded;
        if (current.currentIndex < current.cards.length - 1) {
          emit(FlashcardLoaded(
            cards: current.cards,
            currentIndex: current.currentIndex + 1,
            language: current.language,
          ));
        }
      }
    });

    on<PrevFlashcardEvent>((event, emit) {
      if (state is FlashcardLoaded) {
        final current = state as FlashcardLoaded;
        if (current.currentIndex > 0) {
          emit(FlashcardLoaded(
            cards: current.cards,
            currentIndex: current.currentIndex - 1,
            language: current.language,
          ));
        }
      }
    });

    on<SwitchFlashcardLanguage>((event, emit) async {
      add(LoadFlashcardsEvent(topic: 'Numbers', language: event.language));
    });
  }
}
