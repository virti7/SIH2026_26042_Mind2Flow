import 'dart:async';
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import 'santali_flashcard_model.dart';

abstract class FlashcardProgressStore {
  Future<FlashcardLearningProgress?> getProgress(String cardId);
  Future<Map<String, FlashcardLearningProgress>> getAllProgress();
  Future<void> saveProgress(FlashcardLearningProgress progress);
  Future<FlashcardLearningProgress> recordSeen(String cardId);
  Future<FlashcardLearningProgress> recordAttempt({
    required String cardId,
    required bool isCorrect,
  });
  Future<void> resetDeckProgress(List<String> cardIds);
}

/// Drift / SQLite implementation of [FlashcardProgressStore].
/// Uses raw SQL custom statements so no build_runner codegen step is required.
class SqliteFlashcardProgressStore implements FlashcardProgressStore {
  final AppDatabase db;
  bool _initialized = false;

  SqliteFlashcardProgressStore({required this.db});

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS flashcard_learning_progress (
      card_id TEXT NOT NULL PRIMARY KEY,
      seen_count INTEGER NOT NULL DEFAULT 0,
      correct_count INTEGER NOT NULL DEFAULT 0,
      incorrect_count INTEGER NOT NULL DEFAULT 0,
      last_reviewed_at TEXT NOT NULL,
      is_mastered INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String createIndexSql = '''
    CREATE INDEX IF NOT EXISTS idx_fc_progress_mastered 
    ON flashcard_learning_progress (is_mastered);
  ''';

  Future<void> _ensureReady() async {
    if (_initialized) return;
    try {
      await db.customStatement(createTableSql);
      await db.customStatement(createIndexSql);
      _initialized = true;
    } catch (_) {
      // In-flight or already exists
    }
  }

  @override
  Future<FlashcardLearningProgress?> getProgress(String cardId) async {
    await _ensureReady();
    try {
      final rows = await db.customSelect(
        'SELECT card_id, seen_count, correct_count, incorrect_count, last_reviewed_at, is_mastered '
        'FROM flashcard_learning_progress WHERE card_id = ?',
        variables: [Variable.withString(cardId)],
      ).get();

      if (rows.isEmpty) return null;
      final row = rows.first;
      return FlashcardLearningProgress(
        cardId: row.read<String>('card_id'),
        seenCount: row.read<int>('seen_count'),
        correctCount: row.read<int>('correct_count'),
        incorrectCount: row.read<int>('incorrect_count'),
        lastReviewedAt: DateTime.tryParse(row.read<String>('last_reviewed_at')) ?? DateTime.now(),
        isMastered: row.read<int>('is_mastered') == 1,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, FlashcardLearningProgress>> getAllProgress() async {
    await _ensureReady();
    final map = <String, FlashcardLearningProgress>{};
    try {
      final rows = await db.customSelect(
        'SELECT card_id, seen_count, correct_count, incorrect_count, last_reviewed_at, is_mastered '
        'FROM flashcard_learning_progress',
      ).get();

      for (final row in rows) {
        final cardId = row.read<String>('card_id');
        map[cardId] = FlashcardLearningProgress(
          cardId: cardId,
          seenCount: row.read<int>('seen_count'),
          correctCount: row.read<int>('correct_count'),
          incorrectCount: row.read<int>('incorrect_count'),
          lastReviewedAt: DateTime.tryParse(row.read<String>('last_reviewed_at')) ?? DateTime.now(),
          isMastered: row.read<int>('is_mastered') == 1,
        );
      }
    } catch (_) {}
    return map;
  }

  @override
  Future<void> saveProgress(FlashcardLearningProgress progress) async {
    await _ensureReady();
    await db.customStatement(
      '''
      INSERT INTO flashcard_learning_progress (
        card_id, seen_count, correct_count, incorrect_count, last_reviewed_at, is_mastered
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(card_id) DO UPDATE SET
        seen_count = excluded.seen_count,
        correct_count = excluded.correct_count,
        incorrect_count = excluded.incorrect_count,
        last_reviewed_at = excluded.last_reviewed_at,
        is_mastered = excluded.is_mastered
      ''',
      [
        progress.cardId,
        progress.seenCount,
        progress.correctCount,
        progress.incorrectCount,
        progress.lastReviewedAt.toIso8601String(),
        progress.isMastered ? 1 : 0,
      ],
    );
  }

  @override
  Future<FlashcardLearningProgress> recordSeen(String cardId) async {
    final existing = await getProgress(cardId) ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );

    final updated = existing.markSeen();
    await saveProgress(updated);
    return updated;
  }

  @override
  Future<FlashcardLearningProgress> recordAttempt({
    required String cardId,
    required bool isCorrect,
  }) async {
    final existing = await getProgress(cardId) ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );

    final updated = existing.recordAttempt(isCorrect: isCorrect);
    await saveProgress(updated);
    return updated;
  }

  @override
  Future<void> resetDeckProgress(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    await _ensureReady();
    final placeholders = List.filled(cardIds.length, '?').join(',');
    await db.customStatement(
      'DELETE FROM flashcard_learning_progress WHERE card_id IN ($placeholders)',
      cardIds,
    );
  }
}

/// In-memory fallback for test environments or offline initializations without SQLite.
class InMemoryFlashcardProgressStore implements FlashcardProgressStore {
  final Map<String, FlashcardLearningProgress> _store = {};

  @override
  Future<FlashcardLearningProgress?> getProgress(String cardId) async {
    return _store[cardId];
  }

  @override
  Future<Map<String, FlashcardLearningProgress>> getAllProgress() async {
    return Map.unmodifiable(_store);
  }

  @override
  Future<void> saveProgress(FlashcardLearningProgress progress) async {
    _store[progress.cardId] = progress;
  }

  @override
  Future<FlashcardLearningProgress> recordSeen(String cardId) async {
    final existing = _store[cardId] ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );
    final updated = existing.markSeen();
    _store[cardId] = updated;
    return updated;
  }

  @override
  Future<FlashcardLearningProgress> recordAttempt({
    required String cardId,
    required bool isCorrect,
  }) async {
    final existing = _store[cardId] ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );
    final updated = existing.recordAttempt(isCorrect: isCorrect);
    _store[cardId] = updated;
    return updated;
  }

  @override
  Future<void> resetDeckProgress(List<String> cardIds) async {
    for (final id in cardIds) {
      _store.remove(id);
    }
  }
}
