import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/quick_phrases.dart';
import '../tables/translation_feedback.dart';
import '../tables/translation_history.dart';

part 'translation_dao.g.dart';

@DriftAccessor(tables: [TranslationHistory, TranslationFeedback, QuickPhrases])
class TranslationDao extends DatabaseAccessor<AppDatabase> with _$TranslationDaoMixin {
  TranslationDao(super.db);

  Future<void> insertMessage(TranslationHistoryCompanion msg) {
    return into(translationHistory).insertOnConflictUpdate(msg);
  }

  Future<List<TranslationHistoryData>> getRecentHistory({int limit = 50}) {
    return (select(translationHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<void> insertFeedback(TranslationFeedbackCompanion fb) {
    return into(translationFeedback).insertOnConflictUpdate(fb);
  }

  Future<List<TranslationFeedbackData>> getPendingFeedback() {
    return (select(translationFeedback)..where((tbl) => tbl.syncStatus.equals('pending'))).get();
  }

  Future<List<QuickPhraseData>> getQuickPhrases({String? category}) {
    final query = select(quickPhrases);
    if (category != null && category.isNotEmpty && category != 'All') {
      query.where((tbl) => tbl.category.equals(category));
    }
    return query.get();
  }

  Future<void> insertQuickPhrases(List<QuickPhrasesCompanion> phrases) async {
    await batch((b) => b.insertAllOnConflictUpdate(quickPhrases, phrases));
  }
}
