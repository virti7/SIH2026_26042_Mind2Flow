import 'dart:convert';

import 'package:flutter/services.dart';

/// Reusable worksheet layout loaded from JSON
/// (`assets/worksheet_templates/<id>.json`): header lines, student-info and
/// footer labels, block headings, colour themes and the question-type →
/// block-kind map. Nothing about the layout is hardcoded in widgets, so new
/// templates can be added as JSON only.
class WorksheetTemplate {
  static const String defaultId = 'bilingual_worksheet_v1';
  static final Map<String, WorksheetTemplate> _cache = {};

  final Map<String, dynamic> json;
  WorksheetTemplate(this.json);

  static Future<WorksheetTemplate> load({
    String id = defaultId,
    AssetBundle? bundle,
  }) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final raw = await (bundle ?? rootBundle)
        .loadString('assets/worksheet_templates/$id.json');
    return _cache[id] = WorksheetTemplate(
        Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Map<String, dynamic> _map(String key, [Map<String, dynamic>? from]) {
    final v = (from ?? json)[key];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  Map<String, dynamic> get layout => _map('layout');
  Map<String, dynamic> get header => _map('header');
  Map<String, dynamic> get studentInfo => _map('student_info');
  Map<String, dynamic> get footer => _map('footer');
  Map<String, dynamic> get labels => _map('labels');
  Map<String, dynamic> get blockHeadings => _map('block_headings');
  Map<String, dynamic> get questionTypeMap => _map('question_type_map');

  double get twoColumnMinWidth =>
      (layout['two_column_min_width'] as num?)?.toDouble() ?? 600;
  double get printWidth => (layout['print_width'] as num?)?.toDouble() ?? 820;

  int spanOf(String kind) =>
      ((_map('block_span', layout)[kind]) as num?)?.toInt() ?? 1;

  Map<String, dynamic> theme(String name) => _map(name, _map('themes'));

  /// Localised label map (`{lang: text}`) for [key] in `labels`.
  Map<String, String> label(String key) => stringMap(labels[key]);
}

/// A worksheet's content, separate from its layout: `meta` fills the
/// template placeholders, `blocks` are the exercises. Built from a
/// generated payload or loaded directly from a document JSON (see
/// `assets/worksheet_templates/samples/`).
class WorksheetDocument {
  final Map<String, dynamic> meta;
  final List<WorksheetBlock> blocks;

  const WorksheetDocument({required this.meta, required this.blocks});

  String get language1 => (meta['language_1'] ?? 'hi').toString();
  String get language2 => (meta['language_2'] ?? '').toString();

  /// Replaces `{key}` placeholders with meta values.
  String fill(String text) => text.replaceAllMapped(
      RegExp(r'\{(\w+)\}'), (m) => (meta[m.group(1)] ?? '').toString());

  factory WorksheetDocument.fromJson(Map<String, dynamic> json) {
    return WorksheetDocument(
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : <String, dynamic>{},
      blocks: ((json['blocks'] as List?) ?? const [])
          .whereType<Map>()
          .map((b) => WorksheetBlock(Map<String, dynamic>.from(b)))
          .toList(),
    );
  }

  /// Maps a generated worksheet payload onto template blocks. A payload
  /// that already carries `blocks` is used as-is; otherwise each question
  /// becomes a block chosen by the template's `question_type_map`.
  factory WorksheetDocument.fromPayload(
    Map<String, dynamic> payload,
    WorksheetTemplate template,
  ) {
    final lang1 = (payload['language_1'] ?? payload['source_language'] ?? 'hi')
        .toString();
    final lang2 = (payload['language_2'] ?? payload['target_language'] ?? '')
        .toString();
    final subject = (payload['subject'] ?? '').toString();
    final meta = <String, dynamic>{
      'grade': payload['grade'] ?? '',
      'subject': subject,
      'subject_hi': payload['subject_hi'] ?? subject,
      'number': payload['worksheet_number'] ?? 1,
      'topic': payload['topic'] ?? payload['title'] ?? '',
      'title_source': payload['title_source'] ?? payload['title_hi'] ??
          payload['title'] ?? '',
      'title_target': payload['title_target'] ?? '',
      'language_1': lang1,
      'language_2': lang2,
      if (payload['meta'] is Map) ...Map<String, dynamic>.from(payload['meta'] as Map),
    };
    if (meta['title_target'] == meta['title_source']) meta['title_target'] = '';

    final rawBlocks = payload['blocks'];
    if (rawBlocks is List && rawBlocks.isNotEmpty) {
      return WorksheetDocument(
        meta: meta,
        blocks: rawBlocks
            .whereType<Map>()
            .map((b) => WorksheetBlock(Map<String, dynamic>.from(b)))
            .toList(),
      );
    }

    final typeMap = template.questionTypeMap;
    final fallbackType = (payload['worksheet_type'] ?? 'practice').toString();
    final blocks = <WorksheetBlock>[];
    for (final q in ((payload['questions'] as List?) ?? const []).whereType<Map>()) {
      final src = _text(q['prompt_source'] ?? q['promptHindi'] ?? q['prompt']);
      final tgt = _text(q['prompt_target'] ?? q['promptTribal']);
      final prompt = <String, String>{
        lang1: src,
        if (tgt.isNotEmpty && tgt != src) lang2: tgt,
      };
      final options = ((q['options'] as List?) ?? const [])
          .map((o) => o is Map ? _text(o['text'] ?? o['value']) : o.toString())
          .where((o) => o.isNotEmpty)
          .toList();
      final answerRaw = q['answer'];
      final answer =
          answerRaw is Map ? _text(answerRaw['value']) : _text(answerRaw);
      final type = (q['type'] ?? fallbackType).toString();
      var kind = (typeMap[type] ?? (options.length > 1 ? 'mcq' : 'write'))
          .toString();
      final visual = _text(q['visualIllustration'] ?? q['visual']);

      if (kind == 'fill_blank') {
        final seq = _parseSequence(src);
        if (seq != null) {
          blocks.add(WorksheetBlock({
            'kind': 'fill_blank',
            'prompt': prompt,
            'sequence': seq.sequence,
            'answers': seq.answers,
          }));
          continue;
        }
        kind = options.length > 1 ? 'mcq' : 'write';
      }
      if (kind == 'mcq' && options.length < 2) kind = 'write';
      blocks.add(WorksheetBlock({
        'kind': kind,
        'prompt': prompt,
        if (visual.isNotEmpty) 'visual': visual,
        if (kind == 'mcq') 'options': options,
        'answer': answer,
      }));
    }
    return WorksheetDocument(meta: meta, blocks: blocks);
  }
}

/// One exercise block (`kind` + kind-specific fields, see the sample JSON).
class WorksheetBlock {
  final Map<String, dynamic> data;
  const WorksheetBlock(this.data);

  String get kind => (data['kind'] ?? 'write').toString();
  Map<String, String> get prompt => stringMap(data['prompt']);
  String get visual => _text(data['visual']);
  String get answer => _text(data['answer']);
  List<String> get options => _strings(data['options']);
  List<String?> get sequence => ((data['sequence'] as List?) ?? const [])
      .map((e) => e == null ? null : e.toString())
      .toList();
  List<String> get answers => _strings(data['answers']);
  List<Map<String, String>> get slots =>
      ((data['slots'] as List?) ?? const []).map(stringMap).toList();
  List<String> get values => _strings(data['values']);
  List<String> get orderAnswer => _strings(data['answer']);
  List<String> get left => _strings(data['left']);
  List<String> get right => _strings(data['right']);
  Map<String, String> get pairAnswer => stringMap(data['answer']);
  List<String> get items => _strings(data['items']);
}

Map<String, String> stringMap(dynamic v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (_text(e.value).isNotEmpty) e.key.toString(): _text(e.value),
    };
  }
  final s = _text(v);
  return s.isEmpty ? {} : {'en': s};
}

String _text(dynamic v) => v == null ? '' : v.toString().trim();

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// Parses "Fill in the blank: 3, 4, __, 6, 7" into a sequence with blanks
/// and derives each blank's answer from the (arithmetic) step.
({List<String?> sequence, List<String> answers})? _parseSequence(String prompt) {
  final colon = prompt.lastIndexOf(RegExp(r'[:：]'));
  final body = colon >= 0 ? prompt.substring(colon + 1) : prompt;
  final parts = body.split(',').map((s) => s.trim()).toList();
  if (parts.length < 3) return null;
  final nums = <int?>[];
  for (final p in parts) {
    if (RegExp(r'^_+$').hasMatch(p)) {
      nums.add(null);
    } else {
      final n = int.tryParse(p);
      if (n == null) return null;
      nums.add(n);
    }
  }
  if (!nums.contains(null)) return null;
  // Step from the first two known values.
  int? step;
  for (var i = 0; i < nums.length && step == null; i++) {
    for (var j = i + 1; j < nums.length; j++) {
      if (nums[i] != null && nums[j] != null) {
        final diff = nums[j]! - nums[i]!;
        if (diff % (j - i) == 0) step = diff ~/ (j - i);
        break;
      }
    }
  }
  if (step == null) return null;
  final firstKnown = nums.indexWhere((n) => n != null);
  final answers = <String>[];
  for (var i = 0; i < nums.length; i++) {
    if (nums[i] == null) {
      answers.add('${nums[firstKnown]! + (i - firstKnown) * step}');
    }
  }
  return (
    sequence: nums.map((n) => n?.toString()).toList(),
    answers: answers,
  );
}
