import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/smartboard_demo_item.dart';

/// MAATRIBHASHA SMARTBOARD — data-driven static demo repository.
///
/// Single reader for `assets/prototype_content/smartboard/smartboard_demo.json`.
/// Widgets must use this repository — never `rootBundle` / JSON parsing
/// directly in multiple widgets.
///
/// Offline only: bundled asset, no network. Falls back to the compiled-in
/// `math_5_plus_5` demo when the asset is unavailable (e.g. unit tests
/// without a bundle), so the board always opens populated.
class SmartBoardDemoRepository {
  static const String demoAssetPath =
      'assets/prototype_content/smartboard/smartboard_demo.json';

  SmartBoardDemoItem? _current;

  /// Loads the static demo (first `items[]` entry) and caches it.
  Future<SmartBoardDemoItem> loadDemoItem({String? jsonOverride}) async {
    if (_current != null) return _current!;
    final raw = jsonOverride ?? await rootBundle.loadString(demoAssetPath);
    _current = parseDemoJson(raw);
    return _current!;
  }

  /// Cached demo after [loadDemoItem], else null.
  SmartBoardDemoItem? getCurrentDemoItem() => _current;

  /// Parses the `{"items": [...]}` file; first entry wins.
  /// Throws [FormatException] when no items are present.
  static SmartBoardDemoItem parseDemoJson(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List?) ?? const [];
    if (items.isEmpty) {
      throw const FormatException('smartboard_demo.json has no items');
    }
    return SmartBoardDemoItem.fromJson(
      Map<String, dynamic>.from(items.first as Map),
    );
  }
}
