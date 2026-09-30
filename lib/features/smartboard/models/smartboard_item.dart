import 'smartboard_language.dart';

/// One translated classroom board item.
///
/// Data comes from the local prototype phrase data (never hardcoded
/// translation text in widgets). The item keeps the source side plus the
/// resolved Santali side so history + "Add to Lesson" need no re-lookup.
class SmartBoardItem {
  final String id;
  final SmartBoardSourceLanguage sourceLanguage;
  final String sourceText;
  final String phraseId;
  final String santaliOlChiki;
  final String santaliRoman;
  final String santaliAudio;
  final DateTime createdAt;
  final bool addedToLesson;

  const SmartBoardItem({
    required this.id,
    required this.sourceLanguage,
    required this.sourceText,
    required this.phraseId,
    required this.santaliOlChiki,
    required this.santaliRoman,
    required this.santaliAudio,
    required this.createdAt,
    this.addedToLesson = false,
  });

  SmartBoardItem copyWith({bool? addedToLesson}) {
    return SmartBoardItem(
      id: id,
      sourceLanguage: sourceLanguage,
      sourceText: sourceText,
      phraseId: phraseId,
      santaliOlChiki: santaliOlChiki,
      santaliRoman: santaliRoman,
      santaliAudio: santaliAudio,
      createdAt: createdAt,
      addedToLesson: addedToLesson ?? this.addedToLesson,
    );
  }
}
