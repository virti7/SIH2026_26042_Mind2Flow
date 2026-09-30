/// Per-teacher Co-Pilot state: answer-language preference (persisted) +
/// lightweight conversation context (in-memory). Fully offline.
///
/// Account isolation: the knowledge base is shared/static; language
/// preference keys are namespaced per owner user id
/// (`<ownerId>:copilot_answer_language`, see `scopedPrefKey`), and
/// conversation contexts live in a per-owner in-memory map. Switching
/// accounts or logging out clears only the previous in-memory context —
/// never unrelated offline data.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../database/account_scope.dart';
import 'copilot_models.dart';

class CopilotStore {
  static const String languageKey = 'copilot_answer_language';

  /// Resolves the authenticated teacher id (Supabase UUID) or null.
  final String? Function()? ownerIdProvider;
  final SharedPreferences? prefsOverride;

  final Map<String, CopilotConversationContext> _contextsByOwner = {};

  CopilotStore({this.ownerIdProvider, this.prefsOverride});

  String _ownerKey() =>
      ((ownerIdProvider?.call() ?? '').trim().isEmpty)
          ? 'unowned'
          : ownerIdProvider!.call()!.trim();

  String get _scopedLanguageKey =>
      scopedPrefKey(
          _ownerKey() == 'unowned' ? null : _ownerKey(), languageKey);

  Future<SharedPreferences?> _prefs() async {
    if (prefsOverride != null) return prefsOverride;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Null = teacher has never chosen (UI must ask Hindi/English first).
  Future<CopilotAnswerLanguage?> getLanguage() async {
    final prefs = await _prefs();
    if (prefs == null) return null;
    final raw = prefs.getString(_scopedLanguageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return copilotLanguageFromString(raw);
  }

  Future<void> setLanguage(CopilotAnswerLanguage language) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    await prefs.setString(
        _scopedLanguageKey, copilotLanguageToString(language));
  }

  CopilotConversationContext conversation() =>
      _contextsByOwner[_ownerKey()] ?? CopilotConversationContext.empty;

  void saveConversation(CopilotConversationContext ctx) {
    _contextsByOwner[_ownerKey()] = ctx;
  }

  /// Call on logout / account switch: clears in-memory follow-up context.
  /// Persisted language preference is kept per account (scoped key).
  void clearConversation([String? ownerId]) {
    if (ownerId != null && ownerId.trim().isNotEmpty) {
      _contextsByOwner.remove(ownerId.trim());
    } else {
      _contextsByOwner.remove(_ownerKey());
    }
  }

  /// Test helper: raw persisted value for the current owner.
  Future<String?> rawPersistedLanguage() async {
    final prefs = await _prefs();
    if (prefs == null) return null;
    return prefs.getString(_scopedLanguageKey);
  }
}
