import 'review_models.dart';

/// Local Translation Memory store (§12) — prototype-only, in-memory.
///
/// Holds expert corrections keyed by phrase. Future translations check
/// here FIRST (§14): a stored correction always wins over the original
/// phrase-bank translation. No backend, no database — session memory.
class TranslationMemoryStore {
  final List<TranslationMemoryEntry> _entries = [];

  /// Newest correction first.
  List<TranslationMemoryEntry> get all =>
      List<TranslationMemoryEntry>.unmodifiable(_entries.reversed);

  /// §14 lookup: the correction for [phraseId], if the reviewer has sent
  /// one back. Null → use the original translation.
  TranslationMemoryEntry? correctionFor(String phraseId) {
    for (final e in _entries) {
      if (e.phraseId == phraseId) return e;
    }
    return null;
  }

  bool hasCorrection(String phraseId) => correctionFor(phraseId) != null;

  void add(TranslationMemoryEntry entry) {
    // One correction per phrase: a newer expert correction replaces the
    // previous one (last expert wins).
    _entries.removeWhere((e) => e.phraseId == entry.phraseId);
    _entries.add(entry);
  }

  void clear() => _entries.clear();
}

/// Local Reviewer Queue store (§7–§8) — prototype-only, in-memory.
///
/// Queue order is ALWAYS confidence ascending (lowest confidence first =
/// highest review priority first). No separate ranking exists.
class ReviewQueueStore {
  final List<ReviewItem> _items = [];
  int _seq = 0;

  /// §8: sort by confidence ascending. Ties: older item first.
  static int _byQueueOrder(ReviewItem a, ReviewItem b) {
    final c = a.confidenceScore.compareTo(b.confidenceScore);
    if (c != 0) return c;
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Pending items only, sorted lowest confidence first.
  List<ReviewItem> pending() {
    final pending =
        _items.where((i) => i.status == ReviewItemStatus.pending).toList()
          ..sort(_byQueueOrder);
    return List<ReviewItem>.unmodifiable(pending);
  }

  /// Every item (any status), same confidence-ascending order.
  List<ReviewItem> all() {
    final sorted = List<ReviewItem>.from(_items)..sort(_byQueueOrder);
    return List<ReviewItem>.unmodifiable(sorted);
  }

  int get pendingCount =>
      _items.where((i) => i.status == ReviewItemStatus.pending).length;

  ReviewItem? byId(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Adds an item to the queue, assigning the next RV-### id (§7).
  ReviewItem enqueue({
    required String phraseId,
    required ReviewDirection direction,
    required String originalText,
    required String originalRoman,
    required String translatedText,
    required String translatedRoman,
    required int confidenceScore,
    required String reason,
    ReviewContext context = const ReviewContext(),
    String? audioAsset,
    DateTime? createdAt,
  }) {
    _seq++;
    final item = ReviewItem(
      id: 'RV-${_seq.toString().padLeft(3, '0')}',
      phraseId: phraseId,
      direction: direction,
      originalText: originalText,
      originalRoman: originalRoman,
      translatedText: translatedText,
      translatedRoman: translatedRoman,
      confidenceScore: confidenceScore,
      priority: calculatePriority(confidenceScore),
      context: context,
      reason: reason,
      status: ReviewItemStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
      audioAsset: audioAsset,
    );
    _items.add(item);
    return item;
  }

  /// §11: reviewer sent a correction → mark corrected, store the text,
  /// record the reviewer, and (by default) resolve it out of the queue.
  void applyCorrection(
    String reviewId, {
    required String correctedText,
    String reviewer = 'Language Expert',
    ReviewItemStatus status = ReviewItemStatus.corrected,
  }) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == reviewId) {
        _items[i] = _items[i].copyWith(
          correctedText: correctedText,
          status: status,
          reviewer: reviewer,
        );
        return;
      }
    }
  }

  /// Reviewer approved the existing translation without changes.
  void approve(String reviewId, {String reviewer = 'Language Expert'}) =>
      applyCorrection(reviewId,
          correctedText: '', status: ReviewItemStatus.approved, reviewer: reviewer);

  /// Removes every pending queue entry for [phraseId] (used when the
  /// teacher applies the correction — the issue is now resolved).
  void resolvePendingForPhrase(String phraseId) {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.phraseId == phraseId && item.status == ReviewItemStatus.pending) {
        _items[i] = item.copyWith(status: ReviewItemStatus.resolved);
      }
    }
  }

  void clear() {
    _items.clear();
    _seq = 0;
  }
}

/// Local teacher-portal correction notifications (§13) — in-memory.
class CorrectionNoticeStore {
  final List<CorrectionNotice> _notices = [];

  /// Newest first.
  List<CorrectionNotice> get all =>
      List<CorrectionNotice>.unmodifiable(_notices);

  /// Unconsumed notices (teacher has not tapped "Use Corrected Translation").
  List<CorrectionNotice> get unconsumed =>
      List<CorrectionNotice>.unmodifiable(
          _notices.where((n) => !n.consumed));

  int get unconsumedCount => _notices.where((n) => !n.consumed).length;

  void add(CorrectionNotice notice) => _notices.insert(0, notice);

  void markConsumed(String reviewId) {
    for (var i = 0; i < _notices.length; i++) {
      if (_notices[i].reviewId == reviewId) {
        _notices[i] = _notices[i].copyWith(consumed: true);
      }
    }
  }

  void clear() => _notices.clear();
}
