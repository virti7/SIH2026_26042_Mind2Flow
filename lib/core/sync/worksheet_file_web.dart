import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'worksheet_file_stub.dart' show WorksheetFileStore;
export 'worksheet_file_stub.dart' show WorksheetFileStore;

/// Browser-safe file store: worksheet bytes persist as base64 in
/// SharedPreferences (backed by browser local storage) under a versioned
/// key, plus a session memory fallback. The teacher opens the worksheet
/// offline from this local copy; the browser download itself is triggered
/// through the Share action where the platform supports it.
class WebWorksheetFileStore implements WorksheetFileStore {
  static const String _prefix = 'worksheet_file_v1:';

  SharedPreferences? prefs;
  final Map<String, List<int>> _memory = {};
  Future<void>? _prefsInit;

  WebWorksheetFileStore({this.prefs});

  Future<void> _ensurePrefs() {
    _prefsInit ??= (() async {
      if (prefs != null) return;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}
    })();
    return _prefsInit!;
  }

  @override
  Future<String> saveBytes(String fileName, List<int> bytes) async {
    _memory[fileName] = bytes;
    await _ensurePrefs();
    final p = prefs;
    if (p != null) {
      try {
        await p.setString(_prefix + fileName, base64Encode(bytes));
      } catch (_) {}
    }
    return 'web-local:$fileName';
  }

  @override
  Future<List<int>?> readBytes(String storageRef) async {
    final fileName = storageRef.startsWith('web-local:')
        ? storageRef.substring('web-local:'.length)
        : storageRef;
    final mem = _memory[fileName];
    if (mem != null) return mem;
    await _ensurePrefs();
    final p = prefs;
    if (p != null) {
      try {
        final raw = p.getString(_prefix + fileName);
        if (raw != null && raw.isNotEmpty) {
          final bytes = base64Decode(raw);
          _memory[fileName] = bytes;
          return bytes;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> deleteFile(String storageRef) async {
    final fileName = storageRef.startsWith('web-local:')
        ? storageRef.substring('web-local:'.length)
        : storageRef;
    _memory.remove(fileName);
    await _ensurePrefs();
    final p = prefs;
    if (p != null) {
      try {
        await p.remove(_prefix + fileName);
      } catch (_) {}
    }
  }
}

/// Resolved through the conditional export so dart:io never leaks onto web.
WorksheetFileStore createPlatformFileStore() => WebWorksheetFileStore();
