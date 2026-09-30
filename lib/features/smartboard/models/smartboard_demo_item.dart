/// MAATRIBHASHA SMARTBOARD — static prototype demo item.
///
/// Prototype rule (§33), reflected in this model and the rendering logic:
/// TEXT is translated; NUMBERS, MATHEMATICAL OPERATORS, FIGURES and
/// DRAWINGS are always preserved byte-for-byte.
///
/// Data source: `assets/prototype_content/smartboard/smartboard_demo.json`
/// (loaded via SmartBoardDemoRepository). For this prototype there is
/// exactly one demo: `math_5_plus_5`.
/// No AI handwriting recognition, no ASR, no ONNX, no remote APIs.
class SmartBoardDemoItem {
  /// Stable demo id, e.g. `math_5_plus_5`.
  final String id;

  /// Source language label for display, e.g. `English`.
  /// Matching itself accepts the teacher's current source selection.
  final String sourceLanguage;

  /// Original board lines, in visual order. Line 0 is the equation and is
  /// NEVER altered by translation.
  final List<String> sourceLines;

  /// The equation line, rendered IDENTICALLY on the ORIGINAL and SANTALI
  /// sides. Digits and operators (`5 + 5 = 10`) must remain exactly unchanged.
  final String equationLine;

  /// Symbols documented as preserved (never translated): digits + operators.
  final List<String> preservedSymbols;

  // ------------------------------------------------------------------
  // Verified Santali vocabulary slots.
  //
  // These MUST come from the project's verified local data source.
  // The words for "five"/"ten" are NOT present in the project JSON yet,
  // so they are explicit EMPTY placeholders, clearly marked for insertion.
  // DO NOT fill these with guessed/hallucinated language.
  // ------------------------------------------------------------------

  /// INSERT VERIFIED WORD: Santali Ol Chiki for "five".
  final String santaliFiveOlChiki;

  /// INSERT VERIFIED WORD: Roman Santali for "five".
  final String santaliFiveRoman;

  /// INSERT VERIFIED WORD: Santali Ol Chiki for "ten".
  final String santaliTenOlChiki;

  /// INSERT VERIFIED WORD: Roman Santali for "ten".
  final String santaliTenRoman;

  /// Local bundled audio asset for this demo, or EMPTY when not yet
  /// prepared. Never invent a file path here.
  final String audioPath;

  const SmartBoardDemoItem({
    required this.id,
    required this.sourceLanguage,
    required this.sourceLines,
    required this.equationLine,
    required this.preservedSymbols,
    required this.santaliFiveOlChiki,
    required this.santaliFiveRoman,
    required this.santaliTenOlChiki,
    required this.santaliTenRoman,
    required this.audioPath,
  });

  /// Parses one `items[]` entry of `smartboard_demo.json`.
  ///
  /// Preservation rule: the `equation` string is stored verbatim and
  /// rendered IDENTICALLY on both sides — digits/operators are never
  /// altered. Only the number words occupy translatable slots.
  factory SmartBoardDemoItem.fromJson(Map<String, dynamic> json) {
    final santali =
        (json['santali'] as Map<String, dynamic>?) ?? const {};
    final olChiki =
        (santali['olChiki'] as List?)?.map((e) => '$e').toList() ??
            const <String>[];
    final roman =
        (santali['roman'] as List?)?.map((e) => '$e').toList() ??
            const <String>[];
    String slot(List<String> list, int i) =>
        i < list.length ? list[i].trim() : '';
    final words = (json['sourceWords'] as List?)
            ?.map((e) => '$e')
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const ['five', 'five', 'ten'];
    final equation = '${json['equation'] ?? '5 + 5 = 10'}';
    return SmartBoardDemoItem(
      id: '${json['id'] ?? 'math_5_plus_5'}',
      sourceLanguage: '${json['sourceLanguage'] ?? 'English'}',
      sourceLines: [equation, words.join('   ')],
      equationLine: equation,
      preservedSymbols: const ['5', '+', '=', '10'],
      santaliFiveOlChiki: slot(olChiki, 0),
      santaliFiveRoman: slot(roman, 0),
      santaliTenOlChiki: slot(olChiki, 2),
      santaliTenRoman: slot(roman, 2),
      audioPath: '${santali['audio'] ?? ''}',
    );
  }

  /// Number words in visual order (five, five, ten) for display.
  List<String> get numberWords {
    if (sourceLines.length > 1) {
      final parts = sourceLines[1]
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length == 3) return parts;
    }
    return const ['five', 'five', 'ten'];
  }

  /// True only when every vocabulary slot holds verified content.
  bool get hasVerifiedWords =>
      santaliFiveOlChiki.isNotEmpty &&
      santaliFiveRoman.isNotEmpty &&
      santaliTenOlChiki.isNotEmpty &&
      santaliTenRoman.isNotEmpty;

  bool get hasAudio => audioPath.trim().isNotEmpty;
}
