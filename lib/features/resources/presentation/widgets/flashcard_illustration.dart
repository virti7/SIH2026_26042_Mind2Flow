import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Real vector illustrations for flashcards (mirrors backend
/// `app/flashcards/vector_art.py`).
///
/// Paints actual educational visuals with [Canvas] operators — never emoji,
/// never stock images, never words inside the image. Used by the preview
/// cards (and full-set grid) so teachers see the same art that the PDF
/// composer prints.
class FlashcardIllustration extends StatelessWidget {
  final String art;
  final Color palette;
  final int? count;
  final String? swatch;
  final double height;

  const FlashcardIllustration({
    super.key,
    required this.art,
    this.palette = const Color(0xFF1B7A4D),
    this.count,
    this.swatch,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FlashcardArtPainter(
          art: art,
          palette: palette,
          count: count ?? 1,
          swatch: swatch ?? '',
        ),
      ),
    );
  }
}

Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
Paint _stroke(Color c, double w) =>
    Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round;

Color _namedSwatch(String name) {
  switch (name.trim().toLowerCase()) {
    case 'red':
      return const Color(0xFFD91F1F);
    case 'blue':
      return const Color(0xFF2659D9);
    case 'green':
      return const Color(0xFF1F8C33);
    case 'yellow':
      return const Color(0xFFF2C714);
    case 'black':
      return const Color(0xFF1A1A1A);
    case 'white':
      return const Color(0xFFF4F4F4);
    case 'orange':
      return const Color(0xFFFF8C0D);
    case 'pink':
      return const Color(0xFFF27399);
    case 'purple':
      return const Color(0xFF803399);
    case 'brown':
      return const Color(0xFF80512E);
    default:
      return const Color(0xFF337ACC);
  }
}

class _FlashcardArtPainter extends CustomPainter {
  final String art;
  final Color palette;
  final int count;
  final String swatch;

  _FlashcardArtPainter({
    required this.art,
    required this.palette,
    required this.count,
    required this.swatch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = math.min(size.width, size.height);
    final a = _Art(canvas, cx, cy, s, palette);
    switch (art) {
      case 'mango':
        a.mango();
      case 'banana':
        a.banana();
      case 'apple':
        a.appleAt(cx, cy, s);
      case 'apples':
        a.apples(count.clamp(1, 10));
      case 'orange':
        a.orange();
      case 'guava':
      case 'papaya':
        a.guava();
      case 'grapes':
        a.grapes();
      case 'cow':
      case 'goat':
      case 'dog':
      case 'buffalo':
        a.quadruped(art);
      case 'hen':
      case 'bird':
      case 'parrot':
      case 'crow':
      case 'sparrow':
      case 'pigeon':
      case 'owl':
      case 'peacock':
        a.bird();
      case 'fish':
        a.fish();
      case 'book':
        a.book();
      case 'ball':
        a.ball();
      case 'sun':
        a.sun();
      case 'moon':
        a.moon();
      case 'tree':
        a.tree();
      case 'flower':
        a.flower();
      case 'eye':
        a.eye();
      case 'hand':
        a.hand();
      case 'running':
        a.running();
      case 'reading':
        a.reading();
      case 'circle':
      case 'triangle':
      case 'square':
      case 'rectangle':
      case 'oval':
      case 'star':
        a.shapeOutline(art);
      case 'swatch':
        a.swatch(_namedSwatch(swatch));
      default:
        a.emblem();
    }
  }

  @override
  bool shouldRepaint(covariant _FlashcardArtPainter old) =>
      old.art != art ||
      old.palette != palette ||
      old.count != count ||
      old.swatch != swatch;
}

class _Art {
  final Canvas c;
  final double cx, cy, s;
  final Color pal;
  _Art(this.c, this.cx, this.cy, this.s, this.pal);

  void mango() {
    const body = Color(0xFFF28C1A);
    const light = Color(0xFFFFA633);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.60 * s, height: 0.48 * s), _fill(body));
    c.drawOval(Rect.fromCenter(center: Offset(cx - 0.05 * s, cy + 0.03 * s), width: 0.40 * s, height: 0.30 * s), _fill(light));
    c.drawLine(Offset(cx + 0.10 * s, cy + 0.22 * s), Offset(cx + 0.12 * s, cy + 0.36 * s), _stroke(const Color(0xFF59331A), 4));
    c.drawPath(_diamond(cx + 0.24 * s, cy + 0.36 * s, 0.12 * s), _fill(const Color(0xFF218C21)));
  }

  void banana() {
    final p = Path()
      ..moveTo(cx - 0.30 * s, cy + 0.10 * s)
      ..lineTo(cx - 0.10 * s, cy - 0.12 * s)
      ..lineTo(cx + 0.20 * s, cy - 0.10 * s)
      ..lineTo(cx + 0.30 * s, cy + 0.12 * s)
      ..lineTo(cx + 0.05 * s, cy + 0.02 * s)
      ..lineTo(cx - 0.15 * s, cy + 0.16 * s)
      ..close();
    c.drawPath(p, _fill(const Color(0xFFF2CC26)));
    c.drawCircle(Offset(cx - 0.30 * s, cy + 0.10 * s), 0.03 * s, _fill(const Color(0xFF59331A)));
  }

  void appleAt(double x, double y, double sc) {
    const red = Color(0xFFD92626);
    c.drawCircle(Offset(x - 0.09 * sc, y), 0.13 * sc, _fill(red));
    c.drawCircle(Offset(x + 0.09 * sc, y), 0.13 * sc, _fill(red));
    c.drawCircle(Offset(x, y - 0.06 * sc), 0.13 * sc, _fill(red));
    c.drawLine(Offset(x, y + 0.12 * sc), Offset(x + 0.02 * sc, y + 0.26 * sc), _stroke(const Color(0xFF59331A), 4));
    c.drawPath(_diamond(x + 0.10 * sc, y + 0.28 * sc, 0.12 * sc), _fill(const Color(0xFF218C21)));
  }

  void apples(int n) {
    final cols = n > 5 ? 5 : n;
    final gw = 0.34 * s;
    final x0 = cx - (cols - 1) * gw / 2;
    for (var i = 0; i < n; i++) {
      final row = i ~/ (n > 5 ? 5 : n);
      final col = i % (n > 5 ? 5 : n);
      appleAt(x0 + col * gw, cy + (row == 0 ? 0.20 * s : -0.22 * s), s * 0.55);
    }
  }

  void orange() {
    c.drawCircle(Offset(cx, cy), 0.26 * s, _fill(const Color(0xFFFF8C0D)));
    c.drawCircle(Offset(cx - 0.07 * s, cy + 0.07 * s), 0.08 * s, _fill(const Color(0xFFFFAD40)));
    c.drawPath(_diamond(cx + 0.05 * s, cy + 0.34 * s, 0.12 * s), _fill(const Color(0xFF218C21)));
  }

  void guava() {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.48 * s, height: 0.60 * s), _fill(const Color(0xFF73B340)));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.28 * s, height: 0.36 * s), _fill(const Color(0xFF99CC66)));
    c.drawPath(_diamond(cx + 0.08 * s, cy + 0.36 * s, 0.12 * s), _fill(const Color(0xFF218C21)));
  }

  void grapes() {
    const purple = Color(0xFF73338C);
    for (final d in [(-0.12, 0.10), (0.0, 0.12), (0.12, 0.10), (-0.06, -0.04), (0.06, -0.04), (0.0, -0.18)]) {
      c.drawCircle(Offset(cx + d.$1 * s, cy + d.$2 * s), 0.08 * s, _fill(purple));
    }
    c.drawLine(Offset(cx, cy + 0.20 * s), Offset(cx + 0.02 * s, cy + 0.34 * s), _stroke(const Color(0xFF59331A), 4));
  }

  void quadruped(String kind) {
    final body = {'cow': const Color(0xFFF2EDE3), 'goat': const Color(0xFFBFBFC4), 'dog': const Color(0xFFB87A47), 'buffalo': const Color(0xFF404040)}[kind]!;
    const dark = Color(0xFF331F14);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 0.02 * s), width: 0.60 * s, height: 0.36 * s), _fill(body));
    if (kind == 'cow') {
      c.drawCircle(Offset(cx - 0.10 * s, cy + 0.05 * s), 0.06 * s, _fill(dark));
      c.drawCircle(Offset(cx + 0.12 * s, cy - 0.05 * s), 0.05 * s, _fill(dark));
    }
    c.drawCircle(Offset(cx + 0.32 * s, cy + 0.14 * s), 0.11 * s, _fill(body));
    c.drawCircle(Offset(cx + 0.35 * s, cy + 0.15 * s), 0.02 * s, _fill(dark));
    for (final dx in [-0.20, -0.08, 0.08, 0.20]) {
      c.drawRect(Rect.fromLTWH(cx + dx * s - 0.03 * s, cy - 0.34 * s, 0.06 * s, 0.20 * s), _fill(dark));
    }
    c.drawLine(Offset(cx - 0.30 * s, cy + 0.10 * s), Offset(cx - 0.36 * s, cy - 0.12 * s), _stroke(dark, 3));
  }

  void bird() {
    const blue = Color(0xFF337ACC);
    c.drawOval(Rect.fromCenter(center: Offset(cx - 0.02 * s, cy - 0.02 * s), width: 0.48 * s, height: 0.32 * s), _fill(blue));
    c.drawCircle(Offset(cx + 0.20 * s, cy + 0.10 * s), 0.10 * s, _fill(blue));
    final beak = Path()
      ..moveTo(cx + 0.29 * s, cy + 0.10 * s)
      ..lineTo(cx + 0.37 * s, cy + 0.07 * s)
      ..lineTo(cx + 0.29 * s, cy + 0.04 * s)
      ..close();
    c.drawPath(beak, _fill(const Color(0xFFFFA61A)));
    c.drawCircle(Offset(cx + 0.22 * s, cy + 0.13 * s), 0.02 * s, _fill(Colors.black));
    c.drawLine(Offset(cx - 0.05 * s, cy - 0.17 * s), Offset(cx - 0.05 * s, cy - 0.28 * s), _stroke(const Color(0xFFFFA61A), 3));
    c.drawLine(Offset(cx + 0.05 * s, cy - 0.17 * s), Offset(cx + 0.05 * s, cy - 0.28 * s), _stroke(const Color(0xFFFFA61A), 3));
  }

  void fish() {
    const blue = Color(0xFF408CD9);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.52 * s, height: 0.28 * s), _fill(blue));
    final tail = Path()
      ..moveTo(cx - 0.24 * s, cy)
      ..lineTo(cx - 0.38 * s, cy + 0.12 * s)
      ..lineTo(cx - 0.38 * s, cy - 0.12 * s)
      ..close();
    c.drawPath(tail, _fill(const Color(0xFF3373B3)));
    c.drawCircle(Offset(cx + 0.15 * s, cy + 0.03 * s), 0.025 * s, _fill(Colors.black));
  }

  void book() {
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 0.52 * s, height: 0.32 * s), _fill(const Color(0xFF2659B3)));
    c.drawRect(Rect.fromCenter(center: Offset(cx - 0.09 * s, cy), width: 0.22 * s, height: 0.24 * s), _fill(Colors.white));
    c.drawRect(Rect.fromCenter(center: Offset(cx + 0.14 * s, cy), width: 0.16 * s, height: 0.24 * s), _fill(const Color(0xFFF2F2F2)));
  }

  void ball() {
    c.drawCircle(Offset(cx, cy), 0.26 * s, _fill(Colors.white));
    c.drawCircle(Offset(cx, cy), 0.26 * s, _stroke(const Color(0xFF262626), 3));
    c.drawPath(_poly([(0.0, 0.08), (0.07, 0.03), (0.04, -0.06), (-0.04, -0.06), (-0.07, 0.03)]), _fill(const Color(0xFF262626)));
    for (final d in [(-0.14, 0.10), (0.14, 0.10), (0.0, -0.16)]) {
      c.drawCircle(Offset(cx + d.$1 * s, cy + d.$2 * s), 0.045 * s, _fill(const Color(0xFF262626)));
    }
  }

  void sun() {
    c.drawCircle(Offset(cx, cy), 0.18 * s, _fill(const Color(0xFFFFCC1A)));
    for (var i = 0; i < 8; i++) {
      final a = math.pi * i / 4;
      c.drawLine(
        Offset(cx + 0.24 * s * math.cos(a), cy + 0.24 * s * math.sin(a)),
        Offset(cx + 0.34 * s * math.cos(a), cy + 0.34 * s * math.sin(a)),
        _stroke(const Color(0xFFFFA61A), 4),
      );
    }
  }

  void moon() {
    c.drawCircle(Offset(cx, cy), 0.24 * s, _fill(const Color(0xFFFFD94D)));
    c.drawCircle(Offset(cx + 0.12 * s, cy + 0.08 * s), 0.20 * s, _fill(Colors.white));
  }

  void tree() {
    c.drawRect(Rect.fromLTWH(cx - 0.04 * s, cy - 0.10 * s, 0.08 * s, 0.24 * s), _fill(const Color(0xFF73471F)));
    c.drawCircle(Offset(cx, cy + 0.10 * s), 0.20 * s, _fill(const Color(0xFF268033)));
    c.drawCircle(Offset(cx - 0.12 * s, cy + 0.02 * s), 0.13 * s, _fill(const Color(0xFF33943F)));
    c.drawCircle(Offset(cx + 0.12 * s, cy + 0.02 * s), 0.13 * s, _fill(const Color(0xFF33943F)));
  }

  void flower() {
    for (var i = 0; i < 5; i++) {
      final a = 2 * math.pi * i / 5 - math.pi / 2;
      c.drawCircle(Offset(cx + 0.13 * s * math.cos(a), cy + 0.13 * s * math.sin(a)), 0.09 * s, _fill(const Color(0xFFF27399)));
    }
    c.drawCircle(Offset(cx, cy), 0.08 * s, _fill(const Color(0xFFFFCC1A)));
    c.drawRect(Rect.fromLTWH(cx - 0.015 * s, cy + 0.14 * s, 0.03 * s, 0.20 * s), _fill(const Color(0xFF268033)));
  }

  void eye() {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 0.60 * s, height: 0.32 * s), _fill(const Color(0xFFEBEEF2)));
    c.drawCircle(Offset(cx, cy), 0.09 * s, _fill(const Color(0xFF4D73B3)));
    c.drawCircle(Offset(cx, cy), 0.045 * s, _fill(Colors.black));
    c.drawCircle(Offset(cx + 0.03 * s, cy + 0.03 * s), 0.015 * s, _fill(Colors.white));
  }

  void hand() {
    const skin = Color(0xFFF2BF8C);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 0.05 * s), width: 0.28 * s, height: 0.32 * s), _fill(skin));
    for (final dx in [-0.105, -0.035, 0.035, 0.105]) {
      c.drawRect(Rect.fromLTWH(cx + dx * s - 0.03 * s, cy + 0.02 * s, 0.06 * s, 0.16 * s), _fill(skin));
    }
    c.drawOval(Rect.fromCenter(center: Offset(cx - 0.17 * s, cy - 0.02 * s), width: 0.10 * s, height: 0.18 * s), _fill(skin));
  }

  void running() {
    const ink = Color(0xFF1A408C);
    c.drawCircle(Offset(cx + 0.05 * s, cy + 0.28 * s), 0.07 * s, _fill(ink));
    c.drawLine(Offset(cx, cy + 0.18 * s), Offset(cx - 0.05 * s, cy - 0.08 * s), _stroke(ink, 6));
    c.drawLine(Offset(cx - 0.03 * s, cy + 0.10 * s), Offset(cx - 0.25 * s, cy + 0.16 * s), _stroke(ink, 5));
    c.drawLine(Offset(cx - 0.03 * s, cy + 0.10 * s), Offset(cx + 0.16 * s, cy - 0.02 * s), _stroke(ink, 5));
    c.drawLine(Offset(cx - 0.05 * s, cy - 0.08 * s), Offset(cx - 0.22 * s, cy - 0.28 * s), _stroke(ink, 5));
    c.drawLine(Offset(cx - 0.05 * s, cy - 0.08 * s), Offset(cx + 0.14 * s, cy - 0.24 * s), _stroke(ink, 5));
  }

  void reading() {
    c.drawCircle(Offset(cx, cy + 0.22 * s), 0.09 * s, _fill(const Color(0xFFF2BF8C)));
    final left = Path()
      ..moveTo(cx - 0.22 * s, cy - 0.05 * s)
      ..lineTo(cx, cy + 0.02 * s)
      ..lineTo(cx, cy - 0.18 * s)
      ..lineTo(cx - 0.22 * s, cy - 0.25 * s)
      ..close();
    final right = Path()
      ..moveTo(cx + 0.22 * s, cy - 0.05 * s)
      ..lineTo(cx, cy + 0.02 * s)
      ..lineTo(cx, cy - 0.18 * s)
      ..lineTo(cx + 0.22 * s, cy - 0.25 * s)
      ..close();
    const cover = Color(0xFF2659B3);
    c.drawPath(left, _fill(Colors.white));
    c.drawPath(left, _stroke(cover, 2.5));
    c.drawPath(right, _fill(const Color(0xFFF2F2F2)));
    c.drawPath(right, _stroke(cover, 2.5));
  }

  void shapeOutline(String shape) {
    final paint = _stroke(pal, 6);
    final r = 0.30 * s;
    if (shape == 'circle') {
      c.drawCircle(Offset(cx, cy), r, paint);
    } else if (shape == 'triangle') {
      c.drawPath(_poly([(0.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]), paint);
    } else if (shape == 'square') {
      c.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 2 * r, height: 2 * r), paint);
    } else if (shape == 'rectangle') {
      c.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 2 * r, height: 1.3 * r), paint);
    } else if (shape == 'oval') {
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 2 * r, height: 1.24 * r), paint);
    } else if (shape == 'star') {
      final pts = <Offset>[];
      for (var i = 0; i < 10; i++) {
        final rr = i.isEven ? r : 0.45 * r;
        final a = math.pi / 2 + i * math.pi / 5;
        pts.add(Offset(cx + rr * math.cos(a), cy + rr * math.sin(a)));
      }
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      c.drawPath(p, _stroke(pal, 5));
    }
  }

  void swatch(Color color) {
    c.drawCircle(Offset(cx, cy), 0.26 * s, _fill(color));
    c.drawCircle(Offset(cx, cy), 0.26 * s, _stroke(const Color(0xFF333333), 3));
    c.drawCircle(Offset(cx, cy), 0.32 * s, _stroke(pal, 3));
  }

  void emblem() {
    c.drawCircle(Offset(cx, cy), 0.28 * s, _stroke(pal, 4));
    c.drawPath(_diamond(cx, cy, 0.16 * s), _fill(pal));
    c.drawCircle(Offset(cx, cy), 0.05 * s, _fill(Colors.white));
  }

  Path _diamond(double x, double y, double r) {
    return Path()
      ..moveTo(x, y + r)
      ..lineTo(x + r, y)
      ..lineTo(x, y - r)
      ..lineTo(x - r, y)
      ..close();
  }

  Path _poly(List<(double, double)> pts) {
    final p = Path()..moveTo(cx + pts.first.$1 * s, cy + pts.first.$2 * s);
    for (final pt in pts.skip(1)) {
      p.lineTo(cx + pt.$1 * s, cy + pt.$2 * s);
    }
    p.close();
    return p;
  }
}
