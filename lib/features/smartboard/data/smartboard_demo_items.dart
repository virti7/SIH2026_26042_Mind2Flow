import '../models/smartboard_demo_item.dart';

/// MAATRIBHASHA SMARTBOARD — static prototype demo data.
///
/// Stored SEPARATELY from the drawing implementation. Exactly one demo:
/// `math_5_plus_5` — the fixed mathematics example
///   `5 + 5 = 10` / `five five ten`.
///
/// Santali vocabulary rule: words MUST come from the project's verified
/// local data source. "five"/"ten" are not present there yet, so the slots
/// below stay EMPTY and clearly marked. Nothing here is hallucinated.
const SmartBoardDemoItem math5Plus5Demo = SmartBoardDemoItem(
  id: 'math_5_plus_5',
  sourceLanguage: 'English',
  sourceLines: [
    '5 + 5 = 10',
    'five   five   ten',
  ],
  equationLine: '5 + 5 = 10',
  preservedSymbols: ['5', '+', '=', '10'],
  // INSERT VERIFIED WORD: Santali Ol Chiki for "five".
  santaliFiveOlChiki: '',
  // INSERT VERIFIED WORD: Roman Santali for "five".
  santaliFiveRoman: '',
  // INSERT VERIFIED WORD: Santali Ol Chiki for "ten".
  santaliTenOlChiki: '',
  // INSERT VERIFIED WORD: Roman Santali for "ten".
  santaliTenRoman: '',
  // No local Santali audio prepared for this demo yet — do NOT invent one.
  audioPath: '',
);

/// All static prototype demos (currently exactly one).
const List<SmartBoardDemoItem> smartBoardStaticDemos = [
  math5Plus5Demo,
];

/// Normalises board text for static-demo matching: lowercase, collapse ALL
/// whitespace runs (spaces, newlines, tabs) to single spaces.
String normalizeDemoInput(String input) =>
    input.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Matches board text against the static `math_5_plus_5` demo.
///
/// Accepts the equation plus the three number words in any whitespace
/// layout (`five   five   ten`, newlines, etc.). Deterministic local match
/// only — never guesses, returns null otherwise.
SmartBoardDemoItem? matchStaticDemo(String boardText) {
  final norm = normalizeDemoInput(boardText);
  if (norm.isEmpty) return null;
  // Spacing-tolerant: "5+5=10" and "5 + 5 = 10" both match.
  final compact = norm.replaceAll(' ', '');
  if (compact.contains('5+5=10') &&
      norm.contains('five') &&
      norm.contains('ten')) {
    return math5Plus5Demo;
  }
  return null;
}
