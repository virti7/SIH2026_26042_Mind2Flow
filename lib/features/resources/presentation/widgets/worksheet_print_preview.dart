import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/worksheet_template/worksheet_template.dart';
import 'worksheet_template_view.dart';

/// Shows the black & white print version of a worksheet and prints it.
///
/// The page is rendered with the same template in `print` mode, captured
/// as an image (so Hindi / Ol Chiki shape exactly as on screen) and split
/// across A4 pages.
Future<void> showWorksheetPrintPreview(
  BuildContext context, {
  required WorksheetTemplate template,
  required WorksheetDocument document,
  String fileName = 'worksheet',
}) {
  return showDialog(
    context: context,
    builder: (_) => _PrintPreviewDialog(
        template: template, document: document, fileName: fileName),
  );
}

class _PrintPreviewDialog extends StatefulWidget {
  final WorksheetTemplate template;
  final WorksheetDocument document;
  final String fileName;
  const _PrintPreviewDialog(
      {required this.template, required this.document, required this.fileName});

  @override
  State<_PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<_PrintPreviewDialog> {
  final GlobalKey _boundary = GlobalKey();
  bool _printing = false;

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final bytes = await _capturePdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.fileName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Printing failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<Uint8List> _capturePdf() async {
    final boundary =
        _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    const pixelRatio = 2.5;
    final full = await boundary.toImage(pixelRatio: pixelRatio);
    // Slice the tall page image into A4-proportioned pages.
    final pageHeightPx =
        (full.width * PdfPageFormat.a4.height / PdfPageFormat.a4.width).floor();
    final doc = pw.Document(title: widget.fileName);
    for (var top = 0; top < full.height; top += pageHeightPx) {
      final h = (full.height - top) < pageHeightPx ? full.height - top : pageHeightPx;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, full.width.toDouble(), pageHeightPx.toDouble()),
          Paint()..color = Colors.white);
      canvas.drawImageRect(
        full,
        Rect.fromLTWH(0, top.toDouble(), full.width.toDouble(), h.toDouble()),
        Rect.fromLTWH(0, 0, full.width.toDouble(), h.toDouble()),
        Paint(),
      );
      final slice = await recorder
          .endRecording()
          .toImage(full.width, pageHeightPx);
      final png = await slice.toByteData(format: ui.ImageByteFormat.png);
      final image = pw.MemoryImage(png!.buffer.asUint8List());
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
    }
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.print_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Print preview (black & white)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                color: const Color(0xFFE5E7EB),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _boundary,
                      child: SizedBox(
                        width: widget.template.printWidth,
                        child: WorksheetTemplateView(
                          template: widget.template,
                          document: widget.document,
                          printMode: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded),
                label: Text(_printing ? 'Preparing...' : 'Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
