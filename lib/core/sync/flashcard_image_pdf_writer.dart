import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable PDF for picture-library flashcards: one card per A4 page with
/// the real picture, the words, and the Santali label crop as printed in
/// the source book. Runs fully offline from bundled assets.
///
/// Words are rasterised with Flutter's own text engine so Devanagari and
/// Ol Chiki shape correctly (the PDF base fonts cover Latin only).
Future<List<int>> renderImageLibraryFlashcardPdf(
  Map<String, dynamic> payload, {
  AssetBundle? bundle,
}) async {
  final assets = bundle ?? rootBundle;
  final cards = (payload['cards'] as List?) ?? const [];
  if (cards.isEmpty) {
    throw StateError('No flashcard content to render.');
  }
  final mode = (payload['language_mode'] ?? 'hi_sat').toString();
  String str(dynamic v) => (v ?? '').toString();

  const green = Color(0xFF1B5E3A);
  const ink = Color(0xFF1F2937);
  const muted = Color(0xFF6B7280);

  final header = await _TextImage.render(
    '${str(payload['topic']).toUpperCase()}  •  Class ${str(payload['grade'])}',
    fontSize: 13,
    color: green,
    weight: FontWeight.w700,
  );

  final doc = pw.Document(
    title: str(payload['title']),
    author: 'Maatribhasha',
  );
  for (var i = 0; i < cards.length; i++) {
    final c = Map<String, dynamic>.from(cards[i] as Map);
    final visual = c['visual'] is Map
        ? Map<String, dynamic>.from(c['visual'] as Map)
        : const <String, dynamic>{};
    final photo = await _loadAsset(assets, str(visual['image']));
    final label = await _loadAsset(assets, str(visual['label_image']));

    final hindi = str(c['hindi']);
    final english = str(c['english']);
    final santali = str(c['santali']);
    final primaryText = mode == 'en_sat' ? english : hindi;
    final secondaryText = mode == 'hi_en_sat' ? english : '';

    final primary = primaryText.isEmpty
        ? null
        : await _TextImage.render(primaryText,
            fontSize: 34, color: const Color(0xFF0F3D26), weight: FontWeight.w700);
    final secondary = secondaryText.isEmpty
        ? null
        : await _TextImage.render(secondaryText, fontSize: 22, color: ink);
    final santaliImg = santali.isEmpty
        ? null
        : await _TextImage.render(santali,
            fontSize: 28, color: green, weight: FontWeight.w600);
    final counter = await _TextImage.render(
      'Listen • Repeat • Learn      '
      '${(i + 1).toString().padLeft(2, '0')} / ${cards.length.toString().padLeft(2, '0')}',
      fontSize: 10,
      color: muted,
    );

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(24),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(green.toARGB32()), width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        ),
        child: pw.Column(
          children: [
            header.widget(),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: photo == null
                  ? pw.SizedBox()
                  : pw.Center(
                      child: pw.Image(pw.MemoryImage(photo),
                          fit: pw.BoxFit.contain)),
            ),
            pw.SizedBox(height: 18),
            if (primary != null) primary.widget(),
            if (secondary != null) ...[
              pw.SizedBox(height: 6),
              secondary.widget(),
            ],
            if (santaliImg != null) ...[
              pw.SizedBox(height: 10),
              santaliImg.widget(),
            ],
            if (label != null) ...[
              pw.SizedBox(height: 8),
              pw.Image(pw.MemoryImage(label), height: 34, fit: pw.BoxFit.contain),
            ],
            pw.SizedBox(height: 16),
            counter.widget(),
          ],
        ),
      ),
    ));
  }
  return doc.save();
}

Future<Uint8List?> _loadAsset(AssetBundle bundle, String path) async {
  if (path.isEmpty) return null;
  try {
    final data = await bundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    return null;
  }
}

/// A line of text rasterised at print resolution.
class _TextImage {
  static const double _scale = 3;

  final Uint8List png;
  final double width;
  final double height;

  const _TextImage(this.png, this.width, this.height);

  pw.Widget widget() => pw.Image(pw.MemoryImage(png), width: width, height: height);

  static Future<_TextImage> render(
    String text, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: fontSize * _scale, color: color, fontWeight: weight),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(maxWidth: 440 * _scale);
    final w = painter.width.ceil().clamp(1, 4000);
    final h = painter.height.ceil().clamp(1, 4000);
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), Offset.zero);
    final image = await recorder.endRecording().toImage(w, h);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return _TextImage(data!.buffer.asUint8List(), w / _scale, h / _scale);
    } finally {
      image.dispose();
      painter.dispose();
    }
  }
}
