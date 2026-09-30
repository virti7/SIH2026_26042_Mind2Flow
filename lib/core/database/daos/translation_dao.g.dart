// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_dao.dart';

// ignore_for_file: type=lint
mixin _$TranslationDaoMixin on DatabaseAccessor<AppDatabase> {
  $TranslationHistoryTable get translationHistory =>
      attachedDatabase.translationHistory;
  $TranslationFeedbackTable get translationFeedback =>
      attachedDatabase.translationFeedback;
  $QuickPhrasesTable get quickPhrases => attachedDatabase.quickPhrases;
  TranslationDaoManager get managers => TranslationDaoManager(this);
}

class TranslationDaoManager {
  final _$TranslationDaoMixin _db;
  TranslationDaoManager(this._db);
  $$TranslationHistoryTableTableManager get translationHistory =>
      $$TranslationHistoryTableTableManager(
        _db.attachedDatabase,
        _db.translationHistory,
      );
  $$TranslationFeedbackTableTableManager get translationFeedback =>
      $$TranslationFeedbackTableTableManager(
        _db.attachedDatabase,
        _db.translationFeedback,
      );
  $$QuickPhrasesTableTableManager get quickPhrases =>
      $$QuickPhrasesTableTableManager(_db.attachedDatabase, _db.quickPhrases);
}
