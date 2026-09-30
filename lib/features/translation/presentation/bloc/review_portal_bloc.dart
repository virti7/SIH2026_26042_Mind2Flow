import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/review/review_models.dart';
import '../../../../core/review/review_stores.dart';

// EVENTS
abstract class ReviewPortalEvent extends Equatable {
  const ReviewPortalEvent();
  @override
  List<Object?> get props => [];
}

class LoadReviewQueue extends ReviewPortalEvent {
  const LoadReviewQueue();
}

/// Reviewer opened a queue item's detail screen.
class OpenReviewItem extends ReviewPortalEvent {
  final String reviewId;
  const OpenReviewItem(this.reviewId);
  @override
  List<Object?> get props => [reviewId];
}

/// §11: reviewer pressed "Send Correction" (corrected text may be identical
/// to approve without changes — both resolve the item).
class SubmitReviewerCorrection extends ReviewPortalEvent {
  final String reviewId;
  final String correctedText;
  final String reviewer;
  const SubmitReviewerCorrection({
    required this.reviewId,
    required this.correctedText,
    this.reviewer = 'Language Expert',
  });
  @override
  List<Object?> get props => [reviewId, correctedText, reviewer];
}

/// Reviewer approved the existing translation (no changes).
class ApproveReviewItem extends ReviewPortalEvent {
  final String reviewId;
  final String reviewer;
  const ApproveReviewItem({
    required this.reviewId,
    this.reviewer = 'Language Expert',
  });
  @override
  List<Object?> get props => [reviewId, reviewer];
}

/// Show/hide resolved items in the portal list.
class ToggleShowResolved extends ReviewPortalEvent {
  const ToggleShowResolved();
}

// STATES
abstract class ReviewPortalState extends Equatable {
  const ReviewPortalState();
  @override
  List<Object?> get props => [];
}

class ReviewPortalInitial extends ReviewPortalState {}

class ReviewPortalLoaded extends ReviewPortalState {
  /// §8: queue order is ALWAYS confidence ascending — lowest confidence
  /// (= highest review priority) first. The store guarantees the order;
  /// this state just carries it.
  final List<ReviewItem> queue;
  final List<ReviewItem> resolved;
  final ReviewItem? selected;
  final bool showResolved;
  final bool correctionSaved;

  const ReviewPortalLoaded({
    required this.queue,
    required this.resolved,
    this.selected,
    this.showResolved = false,
    this.correctionSaved = false,
  });

  int get pendingCount => queue.length;

  @override
  List<Object?> get props =>
      [queue, resolved, selected, showResolved, correctionSaved];
}

/// BLoC for the offline Reviewer Portal (§7–§11). Reads/writes the shared
/// in-memory [ReviewQueueStore], [TranslationMemoryStore] and
/// [CorrectionNoticeStore] — the exact same instances the Translator bloc
/// uses, so the loop closes locally with no backend.
class ReviewPortalBloc extends Bloc<ReviewPortalEvent, ReviewPortalState> {
  final ReviewQueueStore queueStore;
  final TranslationMemoryStore memoryStore;
  final CorrectionNoticeStore noticeStore;

  ReviewPortalBloc({
    required this.queueStore,
    required this.memoryStore,
    required this.noticeStore,
  }) : super(ReviewPortalInitial()) {
    on<LoadReviewQueue>((event, emit) {
      _emitLoaded(emit);
    });

    on<OpenReviewItem>((event, emit) {
      final item = queueStore.byId(event.reviewId);
      _emitLoaded(emit, selected: item);
    });

    on<SubmitReviewerCorrection>((event, emit) {
      final item = queueStore.byId(event.reviewId);
      if (item == null) return;
      final text = event.correctedText.trim();
      if (text.isEmpty) return;
      // 1) mark review item corrected + store the text (§11)
      queueStore.applyCorrection(event.reviewId,
          correctedText: text, reviewer: event.reviewer);
      // 2) add the correction to Translation Memory (§12)
      memoryStore.add(TranslationMemoryEntry(
        phraseId: item.phraseId,
        direction: item.direction,
        sourceLanguage:
            item.direction == ReviewDirection.santaliToHindi ? 'Santali' : 'Hindi',
        targetLanguage:
            item.direction == ReviewDirection.santaliToHindi ? 'Hindi' : 'Santali',
        originalTranslation: item.translatedText,
        correctedTranslation: text,
        reviewStatus: 'approved',
        reviewer: event.reviewer,
        context: item.context,
        createdAt: DateTime.now(),
      ));
      // 3) notify the Teacher Portal (§13)
      noticeStore.add(CorrectionNotice(
        reviewId: item.id,
        phraseId: item.phraseId,
        originalTranslation: item.translatedText,
        correctedTranslation: text,
        context: item.context,
        createdAt: DateTime.now(),
      ));
      debugReviewLog('correctionSent reviewId=${item.id} phraseId=${item.phraseId}');
      _emitLoaded(emit, correctionSaved: true);
    });

    on<ApproveReviewItem>((event, emit) {
      queueStore.approve(event.reviewId, reviewer: event.reviewer);
      debugReviewLog('approved reviewId=${event.reviewId}');
      _emitLoaded(emit, correctionSaved: true);
    });

    on<ToggleShowResolved>((event, emit) {
      final s = state;
      _emitLoaded(emit,
          showResolved: s is ReviewPortalLoaded ? !s.showResolved : false);
    });
  }

  void _emitLoaded(
    Emitter<ReviewPortalState> emit, {
    ReviewItem? selected,
    bool? showResolved,
    bool correctionSaved = false,
  }) {
    final currentShowResolved = showResolved ??
        (state is ReviewPortalLoaded
            ? (state as ReviewPortalLoaded).showResolved
            : false);
    final sel = selected ??
        (state is ReviewPortalLoaded
            ? (state as ReviewPortalLoaded).selected
            : null);
    final pendingItems = queueStore.pending();
    final resolvedItems = queueStore
        .all()
        .where((i) => i.isResolved)
        .toList();
    emit(ReviewPortalLoaded(
      queue: pendingItems,
      resolved: resolvedItems,
      selected: sel != null && queueStore.byId(sel.id) != null ? sel : null,
      showResolved: currentShowResolved,
      correctionSaved: correctionSaved,
    ));
  }

  void debugReviewLog(String message) {
    assert(() {
      // ignore: avoid_print
      print('[ReviewPortal] $message');
      return true;
    }());
  }
}
