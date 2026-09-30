import 'package:flutter/foundation.dart';

import '../models/smartboard_item.dart';

/// MAATRIBHASHA SMARTBOARD — in-memory current-lesson session store.
///
/// Holds "Today's Board" (translated items for this lesson session) entirely
/// in memory: fully offline, cleared when the app restarts. "Add to Lesson"
/// only flips [SmartBoardItem.addedToLesson] — history is never cleared by
/// "New Board" / "Clear Board".
class SmartBoardLessonStore extends ChangeNotifier {
  final List<SmartBoardItem> _items = [];

  List<SmartBoardItem> get items => List<SmartBoardItem>.unmodifiable(_items);

  List<SmartBoardItem> get lessonItems =>
      _items.where((e) => e.addedToLesson).toList();

  void add(SmartBoardItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void markAddedToLesson(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(addedToLesson: true);
    notifyListeners();
  }

  bool isAddedToLesson(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    return i != -1 && _items[i].addedToLesson;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
