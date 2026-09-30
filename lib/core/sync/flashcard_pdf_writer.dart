library;

/// Dependency-free Santali flashcard PDF renderer (mirrors backend
/// `app/flashcards/pdf.py`) + offline download helper.
///
/// Renders the ACTUAL generated flashcard payload — visual glyph, Hindi,
/// English (where selected) and Santali text — one card per page. Used as
/// the local fallback when the server PDF artifact cannot be fetched, so
/// Download always produces the real cards. When the server PDF is
/// available it is preferred.
import 'dart:convert';

import '../content/flashcard/flashcard_image_library.dart';
import 'flashcard_image_pdf_writer.dart';
import 'remote_content_data_source.dart';
import 'worksheet_download_store.dart';
import 'worksheet_file.dart';

String _hexUtf16(String text) {
  if (text.isEmpty) return '<FEFF>';
  final buf = StringBuffer('<FEFF');
  for (final rune in text.runes) {
    if (rune <= 0xFFFF) {
      buf.write(rune.toRadixString(16).padLeft(4, '0').toUpperCase());
    } else {
      final v = rune - 0x10000;
      buf.write((0xD800 + (v >> 10)).toRadixString(16).padLeft(4, '0').toUpperCase());
      buf.write((0xDC00 + (v & 0x3FF)).toRadixString(16).padLeft(4, '0').toUpperCase());
    }
  }
  buf.write('>');
  return buf.toString();
}

List<double> _parseHex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length != 6) h = '1B7A4D';
  try {
    return [
      int.parse(h.substring(0, 2), radix: 16) / 255.0,
      int.parse(h.substring(2, 4), radix: 16) / 255.0,
      int.parse(h.substring(4, 6), radix: 16) / 255.0,
    ];
  } catch (_) {
    return [0.11, 0.48, 0.30];
  }
}

String _fc(List<double> c) =>
    '${c[0].toStringAsFixed(3)} ${c[1].toStringAsFixed(3)} ${c[2].toStringAsFixed(3)} rg ';
String _sc(List<double> c) =>
    '${c[0].toStringAsFixed(3)} ${c[1].toStringAsFixed(3)} ${c[2].toStringAsFixed(3)} RG ';

String _pcircle(double cx, double cy, double r,
    {List<double>? fill, List<double>? stroke, double lw = 2.0}) {
  const k = 0.5523;
  final kr = k * r;
  var s = '${(cx + r).toStringAsFixed(1)} ${cy.toStringAsFixed(1)} m '
      '${(cx + r).toStringAsFixed(1)} ${(cy + kr).toStringAsFixed(1)} ${(cx + kr).toStringAsFixed(1)} ${(cy + r).toStringAsFixed(1)} ${cx.toStringAsFixed(1)} ${(cy + r).toStringAsFixed(1)} c '
      '${(cx - kr).toStringAsFixed(1)} ${(cy + r).toStringAsFixed(1)} ${(cx - r).toStringAsFixed(1)} ${(cy + kr).toStringAsFixed(1)} ${(cx - r).toStringAsFixed(1)} ${cy.toStringAsFixed(1)} c '
      '${(cx - r).toStringAsFixed(1)} ${(cy - kr).toStringAsFixed(1)} ${(cx - kr).toStringAsFixed(1)} ${(cy - r).toStringAsFixed(1)} ${cx.toStringAsFixed(1)} ${(cy - r).toStringAsFixed(1)} c '
      '${(cx + kr).toStringAsFixed(1)} ${(cy - r).toStringAsFixed(1)} ${(cx + r).toStringAsFixed(1)} ${(cy - kr).toStringAsFixed(1)} ${(cx + r).toStringAsFixed(1)} ${cy.toStringAsFixed(1)} c h ';
  if (fill != null && stroke != null) {
    return _fc(fill) + _sc(stroke) + '${lw.toStringAsFixed(1)} w B ' + s;
  } else if (fill != null) {
    return _fc(fill) + 'f ' + s;
  }
  return _sc(stroke ?? [0, 0, 0]) + '${lw.toStringAsFixed(1)} w S ' + s;
}

String _pelli(double cx, double cy, double rx, double ry, List<double> fill) =>
    'q ${rx.toStringAsFixed(1)} 0 0 ${ry.toStringAsFixed(1)} ${cx.toStringAsFixed(1)} ${cy.toStringAsFixed(1)} cm ' +
    _pcircle(0, 0, 1.0, fill: fill) +
    'Q ';

String _prect(double x, double y, double w, double h, List<double> fill) =>
    _fc(fill) +
    '${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} ${w.toStringAsFixed(1)} ${h.toStringAsFixed(1)} re f ';

String _ppoly(List<List<double>> pts, List<double> fill) {
  var s = '';
  for (var i = 0; i < pts.length; i++) {
    s += '${pts[i][0].toStringAsFixed(1)} ${pts[i][1].toStringAsFixed(1)} ${i == 0 ? 'm' : 'l'} ';
  }
  return _fc(fill) + s + 'h f ';
}

String _pline(double x1, double y1, double x2, double y2, List<double> c, double lw) =>
    _sc(c) +
    '${lw.toStringAsFixed(1)} w ${x1.toStringAsFixed(1)} ${y1.toStringAsFixed(1)} m ${x2.toStringAsFixed(1)} ${y2.toStringAsFixed(1)} l S ';

List<double> _namedSwatch(String name) {
  switch (name.trim().toLowerCase()) {
    case 'red':
      return [0.85, 0.12, 0.12];
    case 'blue':
      return [0.15, 0.35, 0.85];
    case 'green':
      return [0.12, 0.55, 0.20];
    case 'yellow':
      return [0.95, 0.78, 0.08];
    case 'black':
      return [0.10, 0.10, 0.10];
    case 'white':
      return [0.96, 0.96, 0.96];
    case 'orange':
      return [1.0, 0.55, 0.05];
    case 'pink':
      return [0.95, 0.45, 0.60];
    case 'purple':
      return [0.50, 0.20, 0.60];
    case 'brown':
      return [0.50, 0.32, 0.18];
    default:
      return [0.20, 0.45, 0.80];
  }
}

/// Paints one vector illustration as PDF operators (mirrors backend
/// `vector_art.draw_art`). No emoji, no words inside the image.
String drawFlashcardArtPdf(String art, double cx, double cy, double size,
    String hexPalette, {int? count, String? swatch}) {
  final s = size;
  final pal = _parseHex(hexPalette);
  var o = 'q ';
  void apple(double x, double y, double sc) {
    const red = [0.85, 0.15, 0.15];
    o += _pcircle(x - 0.09 * sc, y, 0.13 * sc, fill: red);
    o += _pcircle(x + 0.09 * sc, y, 0.13 * sc, fill: red);
    o += _pcircle(x, y - 0.06 * sc, 0.13 * sc, fill: red);
    o += _pline(x, y + 0.12 * sc, x + 0.02 * sc, y + 0.26 * sc, [0.35, 0.2, 0.1], 4.0);
  }

  switch (art) {
    case 'mango':
      o += _pelli(cx, cy, 0.30 * s, 0.24 * s, [0.95, 0.55, 0.10]);
      o += _pelli(cx - 0.05 * s, cy + 0.03 * s, 0.20 * s, 0.15 * s, [1.0, 0.65, 0.20]);
    case 'apple':
      apple(cx, cy, s);
    case 'apples':
      final n = (count ?? 1).clamp(1, 10);
      final cols = n > 5 ? 5 : n;
      final gw = 0.34 * s;
      final x0 = cx - (cols - 1) * gw / 2;
      for (var i = 0; i < n; i++) {
        final row = i ~/ (n > 5 ? 5 : n);
        final col = i % (n > 5 ? 5 : n);
        apple(x0 + col * gw, cy + (row == 0 ? 0.20 * s : -0.22 * s), s * 0.55);
      }
    case 'orange':
      o += _pcircle(cx, cy, 0.26 * s, fill: [1.0, 0.55, 0.05]);
    case 'guava':
    case 'papaya':
      o += _pelli(cx, cy, 0.24 * s, 0.30 * s, [0.45, 0.70, 0.25]);
    case 'grapes':
      for (final d in [
        [-0.12, 0.10],
        [0.0, 0.12],
        [0.12, 0.10],
        [-0.06, -0.04],
        [0.06, -0.04],
        [0.0, -0.18]
      ]) {
        o += _pcircle(cx + d[0] * s, cy + d[1] * s, 0.08 * s, fill: [0.45, 0.20, 0.55]);
      }
    case 'cow':
    case 'goat':
    case 'dog':
    case 'buffalo':
      final body = {'cow': [0.95, 0.93, 0.88], 'goat': [0.75, 0.75, 0.78], 'dog': [0.72, 0.48, 0.28], 'buffalo': [0.25, 0.25, 0.28]}[art]!;
      o += _pelli(cx, cy + 0.02 * s, 0.30 * s, 0.18 * s, body);
      o += _pcircle(cx + 0.32 * s, cy + 0.14 * s, 0.11 * s, fill: body);
      for (final dx in [-0.20, -0.08, 0.08, 0.20]) {
        o += _prect(cx + dx * s - 0.03 * s, cy - 0.34 * s, 0.06 * s, 0.20 * s, [0.20, 0.12, 0.08]);
      }
    case 'hen':
    case 'bird':
    case 'parrot':
    case 'crow':
    case 'sparrow':
    case 'pigeon':
    case 'owl':
    case 'peacock':
      o += _pelli(cx - 0.02 * s, cy - 0.02 * s, 0.24 * s, 0.16 * s, [0.20, 0.45, 0.80]);
      o += _pcircle(cx + 0.20 * s, cy + 0.10 * s, 0.10 * s, fill: [0.20, 0.45, 0.80]);
    case 'fish':
      o += _pelli(cx, cy, 0.26 * s, 0.14 * s, [0.25, 0.55, 0.90]);
    case 'book':
      o += _prect(cx - 0.26 * s, cy - 0.16 * s, 0.52 * s, 0.32 * s, [0.15, 0.35, 0.70]);
      o += _prect(cx - 0.20 * s, cy - 0.12 * s, 0.22 * s, 0.24 * s, [1.0, 1.0, 1.0]);
    case 'ball':
      o += _pcircle(cx, cy, 0.26 * s, fill: [1.0, 1.0, 1.0], stroke: [0.15, 0.15, 0.15], lw: 3.0);
      o += _pcircle(cx, cy, 0.07 * s, fill: [0.15, 0.15, 0.15]);
    case 'sun':
      o += _pcircle(cx, cy, 0.18 * s, fill: [1.0, 0.80, 0.10]);
    case 'moon':
      o += _pcircle(cx, cy, 0.24 * s, fill: [1.0, 0.85, 0.30]);
      o += _pcircle(cx + 0.12 * s, cy + 0.08 * s, 0.20 * s, fill: [1.0, 1.0, 1.0]);
    case 'tree':
      o += _prect(cx - 0.04 * s, cy - 0.34 * s, 0.08 * s, 0.24 * s, [0.45, 0.28, 0.12]);
      o += _pcircle(cx, cy + 0.10 * s, 0.20 * s, fill: [0.15, 0.50, 0.20]);
    case 'flower':
      o += _pcircle(cx, cy, 0.16 * s, fill: [0.95, 0.45, 0.60]);
      o += _pcircle(cx, cy, 0.08 * s, fill: [1.0, 0.80, 0.10]);
    case 'eye':
      o += _pelli(cx, cy, 0.30 * s, 0.16 * s, [0.92, 0.93, 0.95]);
      o += _pcircle(cx, cy, 0.09 * s, fill: [0.30, 0.45, 0.70]);
      o += _pcircle(cx, cy, 0.045 * s, fill: [0.0, 0.0, 0.0]);
    case 'hand':
      o += _pelli(cx, cy - 0.05 * s, 0.14 * s, 0.16 * s, [0.95, 0.75, 0.55]);
      for (final dx in [-0.105, -0.035, 0.035, 0.105]) {
        o += _prect(cx + dx * s - 0.03 * s, cy + 0.02 * s, 0.06 * s, 0.16 * s, [0.95, 0.75, 0.55]);
      }
    case 'running':
      const ink = [0.10, 0.25, 0.55];
      o += _pcircle(cx + 0.05 * s, cy + 0.28 * s, 0.07 * s, fill: ink);
      o += _pline(cx, cy + 0.18 * s, cx - 0.05 * s, cy - 0.08 * s, ink, 6.0);
      o += _pline(cx - 0.05 * s, cy - 0.08 * s, cx - 0.22 * s, cy - 0.28 * s, ink, 5.0);
      o += _pline(cx - 0.05 * s, cy - 0.08 * s, cx + 0.14 * s, cy - 0.24 * s, ink, 5.0);
    case 'reading':
      o += _pcircle(cx, cy + 0.22 * s, 0.09 * s, fill: [0.95, 0.75, 0.55]);
      o += _prect(cx - 0.22 * s, cy - 0.18 * s, 0.44 * s, 0.20 * s, [0.95, 0.95, 0.95]);
    case 'circle':
      o += _pcircle(cx, cy, 0.30 * s, stroke: pal, lw: 6.0);
    case 'triangle':
      o += _ppoly([
        [cx, cy + 0.30 * s],
        [cx + 0.30 * s, cy - 0.30 * s],
        [cx - 0.30 * s, cy - 0.30 * s]
      ], pal);
    case 'square':
      o += _ppoly([
        [cx - 0.30 * s, cy + 0.30 * s],
        [cx + 0.30 * s, cy + 0.30 * s],
        [cx + 0.30 * s, cy - 0.30 * s],
        [cx - 0.30 * s, cy - 0.30 * s]
      ], pal);
    case 'swatch':
      o += _pcircle(cx, cy, 0.26 * s, fill: _namedSwatch(swatch ?? ''));
    default:
      o += _pcircle(cx, cy, 0.28 * s, stroke: pal, lw: 4.0);
      o += _pcircle(cx, cy, 0.10 * s, fill: pal);
  }
  o += 'Q ';
  return o;
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

/// Renders a flashcard [payload] (server content JSON with `cards`) to PDF.
List<int> renderFlashcardPdf(Map<String, dynamic> payload) {
  const pageW = 595.0;
  const pageH = 842.0;
  const margin = 48.0;
  const cx = pageW / 2;

  final cards = (payload['cards'] as List?) ?? [];
  final mode = (payload['language_mode'] ?? 'hi_sat').toString();
  String str(dynamic v) => (v ?? '').toString();

  String line(double x, double y, int size, String text, {bool center = true}) {
    var px = x;
    if (center) {
      px = x > 0 ? x : (cx - text.length * size * 0.30).clamp(margin, pageW - margin);
    }
    return 'BT /F1 $size Tf ${px.toStringAsFixed(1)} ${y.toStringAsFixed(1)} Td ${_hexUtf16(text)} Tj ET\n';
  }

  final pages = <String>[];
  for (var i = 0; i < cards.length; i++) {
    final c = (cards[i] as Map).cast<String, dynamic>();
    final visual = c['visual'];
    final art = visual is Map && str(visual['art']).isNotEmpty
        ? str(visual['art'])
        : 'emblem';
    final artPalette =
        visual is Map ? str(visual['palette']) : '#1B7A4D';
    final artCount =
        visual is Map ? (visual['count'] as num?)?.toInt() : null;
    final artSwatch = visual is Map ? str(visual['swatch']) : '';
    final desc = visual is Map ? str(visual['description_en']) : '';
    final hindi = str(c['hindi']);
    final english = str(c['english']);
    final santali = str(c['santali']);
    final type = str(c['type'].toString().isNotEmpty ? c['type'] : payload['flashcard_type']);

    final sb = StringBuffer();
    var y = pageH - margin;
    sb.write(
        '0.1 0.47 0.3 RG 2 w ${margin.toStringAsFixed(1)} ${margin.toStringAsFixed(1)} ${(pageW - 2 * margin).toStringAsFixed(1)} ${(pageH - 2 * margin).toStringAsFixed(1)} re S\n');
    sb.write(line(margin, y, 13, str(payload['topic']).toUpperCase()));
    y -= 24;
    sb.write(line(margin, y, 10,
        'Class ${str(payload['grade'])}  ${str(payload['subject'])}  $type'));
    y -= 30;
    // Real vector illustration (~55% of card), never emoji/text-in-image.
    sb.write(drawFlashcardArtPdf(art, cx, y - 95, 150.0, artPalette,
        count: artCount, swatch: artSwatch));
    y -= 200;
    if (desc.isNotEmpty) {
      for (final ln in _wrap(desc, 48)) {
        sb.write(line(margin, y, 9, ln));
        y -= 13;
      }
    }
    y -= 14;
    String? primary;
    String? secondary;
    if (mode == 'hi_sat') {
      primary = hindi;
    } else if (mode == 'en_sat') {
      primary = english;
    } else {
      primary = hindi;
      secondary = english.isNotEmpty ? english : null;
    }
    for (final ln in _wrap(primary ?? '', 30)) {
      sb.write(line(margin, y, 26, ln));
      y -= 30;
    }
    if (secondary != null) {
      for (final ln in _wrap(secondary, 36)) {
        sb.write(line(margin, y, 18, ln));
        y -= 22;
      }
    }
    for (final ln in _wrap(santali, 30)) {
      sb.write(line(margin, y, 22, ln));
      y -= 26;
    }
    if (type == 'object_identification') {
      sb.write(line(margin, y, 12, 'What is this?'));
      y -= 18;
    }
    sb.write(line(margin, margin + 26, 10, 'Listen - Repeat - Learn'));
    final counter = '${(i + 1).toString().padLeft(2, '0')} / ${cards.length.toString().padLeft(2, '0')}';
    sb.write(line(margin, margin + 10, 10, counter));
    pages.add(sb.toString());
  }
  if (pages.isEmpty) {
    throw StateError('No flashcard content to render.');
  }

  final objects = <List<int>>[];
  final nPages = pages.length;
  final fontObj = 3 + 2 * nPages;
  final kids = List.generate(nPages, (i) => '${3 + 2 * i} 0 R').join(' ');
  objects.add(latin1.encode('<< /Type /Catalog /Pages 2 0 R >>'));
  objects.add(latin1.encode('<< /Type /Pages /Kids [$kids] /Count $nPages >>'));
  for (var i = 0; i < nPages; i++) {
    objects.add(latin1.encode(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageW.toStringAsFixed(0)} ${pageH.toStringAsFixed(0)}] '
        '/Resources << /Font << /F1 $fontObj 0 R >> >> /Contents ${4 + 2 * i} 0 R >>'));
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

/// Downloads a generated flashcard set: prefers the canonical server PDF
/// artifact, otherwise renders the REAL cards payload locally, then saves
/// bytes + metadata through the shared account-scoped download store
/// (resourceType `flashcard`, so Downloads shows thumbnail/title/topic/
/// class/language mode/card count and opens offline).
Future<WorksheetDownload> downloadFlashcardSet({
  required WorksheetDownloadStore store,
  RemoteContentDataSource? remote,
  required String contentId,
  required Map<String, dynamic> contentPayload,
  Map<String, dynamic>? assets,
  String? teacherId,
}) async {
  final cards = contentPayload['cards'];
  if (cards is! List || cards.isEmpty) {
    throw StateError('No flashcard content to download.');
  }
  List<int>? bytes;
  Future<List<int>?> tryRemote(String asset, String fileName) async {
    if (remote == null || asset.isEmpty) return null;
    try {
      final file = await remote.downloadAsset(asset, fileName);
      final raw = await (file as dynamic).readAsBytes() as List<int>;
      if (raw.length > 5 &&
          raw[0] == 0x25 &&
          raw[1] == 0x50 &&
          raw[2] == 0x44 &&
          raw[3] == 0x46) {
        return raw;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  if (isImageCatalogPayload(contentPayload)) {
    // Catalog decks print the bundled catalog PNGs locally: no network,
    // and Flutter's text engine shapes Hindi / Ol Chiki correctly (the
    // server PDF's base font covers Latin only).
    bytes = await renderImageLibraryFlashcardPdf(contentPayload);
  } else {
    final pdfAsset = assets?['pdf']?.toString() ?? '';
    bytes = await tryRemote(pdfAsset, '$contentId.pdf');
    bytes ??= await tryRemote(
        'content/flashcards/$contentId/download', '$contentId.pdf');
    bytes ??= renderFlashcardPdf(contentPayload);
  }

  await store.saveDownload(
    resourceId: contentId,
    title: (contentPayload['title'] ?? 'Flashcards').toString(),
    contentPayload: {
      ...contentPayload,
      'resource_type': 'flashcard',
      'content_type': 'flashcard',
      'question_count': (contentPayload['cards'] as List).length,
    },
    fileBytes: bytes,
    resourceType: 'flashcard',
    teacherId: teacherId,
    generationRequestId: contentPayload['request_id']?.toString(),
  );
  final saved = await store.getByResourceId(contentId);
  if (saved == null) throw StateError('Download could not be saved.');
  return saved;
}
