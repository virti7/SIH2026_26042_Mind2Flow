library;

/// Dependency-free worksheet PDF renderer (mirrors backend
/// `app/worksheets/pdf.py`).
///
/// Renders the ACTUAL generated worksheet payload into a valid PDF file —
/// never mock/placeholder content. Used as the local fallback when the
/// server PDF artifact cannot be fetched, so Download always produces the
/// real worksheet. When the server PDF is available it is preferred.
import 'dart:convert';

String _hexUtf16(String text) {
  if (text.isEmpty) return '<FEFF>';
  final units = text.codeUnits;
  final buf = StringBuffer('<FEFF');
  // Encode convenient BMP chars directly; surrogate pairs for astral planes.
  for (final rune in text.runes) {
    if (rune <= 0xFFFF) {
      buf.write(rune.toRadixString(16).padLeft(4, '0').toUpperCase());
    } else {
      final v = rune - 0x10000;
      final hi = 0xD800 + (v >> 10);
      final lo = 0xDC00 + (v & 0x3FF);
      buf.write(hi.toRadixString(16).padLeft(4, '0').toUpperCase());
      buf.write(lo.toRadixString(16).padLeft(4, '0').toUpperCase());
    }
  }
  buf.write('>');
  units.toString(); // keep analyzer calm about unused local in some SDKs
  return buf.toString();
}

List<String> _wrap(String text, int maxChars) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final lines = <String>[];
  var cur = '';
  for (var w in words) {
    final probe = cur.isEmpty ? w : '$cur $w';
    if (probe.length <= maxChars) {
      cur = probe;
    } else {
      if (cur.isNotEmpty) lines.add(cur);
      while (w.length > maxChars) {
        lines.add(w.substring(0, maxChars));
        w = w.substring(maxChars);
      }
      cur = w;
    }
  }
  if (cur.isNotEmpty) lines.add(cur);
  if (lines.isEmpty) lines.add('');
  return lines;
}

/// Renders [payload] (server worksheet content JSON) to PDF bytes.
List<int> renderWorksheetPdf(Map<String, dynamic> payload) {
  const pageW = 595.0;
  const pageH = 842.0;
  const margin = 48.0;
  const lineH = 14.0;

  final questions = (payload['questions'] as List?) ?? [];
  final types = (payload['worksheet_types'] as List?)?.map((e) => e.toString()).toList() ??
      [(payload['worksheet_type'] ?? 'practice').toString()];
  final lang1 = (payload['language_1'] ?? payload['source_language'] ?? '').toString();
  final lang2 = (payload['target_language'] ?? payload['language_2'] ?? '').toString();

  final pages = <String>[];
  var cur = StringBuffer();
  var y = pageH - margin;

  void push(String line, int size, [double gap = lineH]) {
    if (y < margin + gap) {
      pages.add(cur.toString());
      cur = StringBuffer();
      y = pageH - margin;
    }
    cur.write('BT /F1 $size Tf ${margin.toStringAsFixed(1)} ${y.toStringAsFixed(1)} Td ${_hexUtf16(line)} Tj ET\n');
    y -= gap;
  }

  void pushWrapped(String text, [int size = 10]) {
    for (final ln in _wrap(text, 88)) {
      push(ln, size);
    }
  }

  String str(dynamic v) => (v ?? '').toString();

  push('NIPUN BHARAT BILINGUAL WORKSHEET', 14, 18);
  pushWrapped(str(payload['title_source'].toString().isNotEmpty
      ? payload['title_source']
      : payload['title']));
  final titleTarget = str(payload['title_target']);
  if (titleTarget.isNotEmpty && titleTarget != str(payload['title_source'])) {
    pushWrapped(titleTarget);
  }
  push('Class ${payload['grade'] ?? ''}  Section ${str(payload['section']).isNotEmpty ? payload['section'] : 'General'}  ${str(payload['subject'])}', 10);
  push('Topic: ${str(payload['topic'])}   NIPUN: ${str(payload['curriculum_id'] ?? payload['nipun_outcome'] ?? 'custom topic')}', 10);
  push('Languages: $lang1 + $lang2   Types: ${types.join(', ')}', 10);
  push('Difficulty: ${str(payload['difficulty'])}   Questions: ${questions.length}', 10);
  push('Name: ____________________   Date: ____/____/________', 10);
  push('', 10);
  final instructions = payload['instructions'];
  if (instructions is Map) {
    final src = str(instructions['source']);
    final tgt = str(instructions['target']);
    if (src.isNotEmpty) pushWrapped('Instructions: $src');
    if (tgt.isNotEmpty && tgt != src) pushWrapped(tgt);
  }
  push('', 10);

  for (var i = 0; i < questions.length; i++) {
    final q = (questions[i] as Map).cast<String, dynamic>();
    final qNum = (q['questionNumber'] as num?)?.toInt() ?? (i + 1);
    push('Q$qNum [${str(q['type'])}]', 11);
    final pSrc = str(q['prompt_source'].toString().isNotEmpty ? q['prompt_source'] : q['promptHindi']);
    final pTgt = str(q['prompt_target'].toString().isNotEmpty ? q['prompt_target'] : q['promptTribal']);
    if (pSrc.isNotEmpty) pushWrapped(pSrc);
    if (pTgt.isNotEmpty && pTgt != pSrc) pushWrapped(pTgt);
    final opts = (q['options'] as List?) ?? [];
    for (var j = 0; j < opts.length; j++) {
      final o = opts[j];
      pushWrapped('  (${String.fromCharCode(97 + j)}) ${o.toString()}');
    }
    final visual = str(q['visualIllustration']);
    if (visual.isNotEmpty) pushWrapped('  [visual: $visual]');
    if (payload['bilingual_answers'] == true || payload['bilingual_answer_spaces'] == true) {
      push('  Answer: _______________', 10);
    }
    push('', 6);
  }
  pages.add(cur.toString());

  final objects = <List<int>>[];
  final nPages = pages.length;
  final fontObj = 3 + 2 * nPages;
  final kids = List.generate(nPages, (i) => '${3 + 2 * i} 0 R').join(' ');
  objects.add(latin1.encode('<< /Type /Catalog /Pages 2 0 R >>'));
  objects.add(latin1.encode('<< /Type /Pages /Kids [$kids] /Count $nPages >>'));
  for (var i = 0; i < nPages; i++) {
    final pageObj = 3 + 2 * i;
    final contentObj = 4 + 2 * i;
    objects.add(latin1.encode(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageW.toStringAsFixed(0)} ${pageH.toStringAsFixed(0)}] '
        '/Resources << /Font << /F1 $fontObj 0 R >> >> /Contents $contentObj 0 R >>'));
    final stream = latin1.encode(pages[i]);
    final head = latin1.encode('<< /Length ${stream.length} >>\nstream\n');
    objects.add([...head, ...stream, ...latin1.encode('\nendstream')]);
  }
  objects.add(latin1.encode('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'));

  final out = <int>[...latin1.encode('%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')];
  final offsets = <int>[0];
  for (var idx = 0; idx < objects.length; idx++) {
    offsets.add(out.length);
    out.addAll(latin1.encode('${idx + 1} 0 obj\n'));
    out.addAll(objects[idx]);
    out.addAll(latin1.encode('\nendobj\n'));
  }
  final xrefPos = out.length;
  out.addAll(latin1.encode('xref\n0 ${objects.length + 1}\n'));
  out.addAll(latin1.encode('0000000000 65535 f \n'));
  for (final off in offsets.sublist(1)) {
    out.addAll(latin1.encode('${off.toString().padLeft(10, '0')} 00000 n \n'));
  }
  out.addAll(latin1.encode(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefPos\n%%EOF'));
  return out;
}
