import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Polished hero illustration for the Home screen card.
///
/// Flat vector style matching the MaatriBhasha identity: Indian
/// primary-school teacher holding a tablet, two young learners, a small
/// stack of books and multilingual "language dots".
///
/// - Fully offline (pure CustomPaint, no network image, no raster asset).
/// - Solid flat fills only — no gradients, no AI-looking effects.
/// - Contains NO text, letters, speech bubbles or wordmarks; every caption
///   stays in Flutter widgets.
/// - Scales to its box, so the hero card stays overflow-free on small
///   phones, normal phones and tablets.
class HomeTeacherHeroIllustration extends StatelessWidget {
  final double height;
  final double width;
  final AlignmentGeometry alignment;

  const HomeTeacherHeroIllustration({
    super.key,
    this.height = 104,
    this.width = 148,
    this.alignment = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Teacher at chalkboard teaching students in classroom',
      child: SizedBox(
        height: height,
        width: width,
        child: Image.asset(
          'assets/illustrations/classroom_teaching_hero.png',
          alignment: alignment,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            painter: _HomeTeacherHeroPainter(),
          ),
        ),
      ),
    );
  }
}

class _HomeTeacherHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // ---------- Backdrop: soft flat spotlight (solid fills only) ----------
    final backdrop = Paint()
      ..color = AppColors.pastelGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.58, h * 0.5),
      _min(w, h) * 0.62,
      backdrop,
    );
    final ring = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(w * 0.58, h * 0.5),
      _min(w, h) * 0.62,
      ring,
    );

    // ---------- Distant foliage dots (flat, subtle) ----------
    final leaf = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.88, h * 0.12), 13, leaf);
    canvas.drawCircle(Offset(w * 0.97, h * 0.24), 9, leaf);

    // ---------- Book stack (learning materials, top-left) ----------
    final stackY = h * 0.16;
    _rrect(canvas, Rect.fromLTWH(w * 0.04, stackY + 10, 30, 9),
        AppColors.accentBlue, 2.5);
    _rrect(canvas, Rect.fromLTWH(w * 0.04, stackY, 26, 9),
        AppColors.accentOrange, 2.5);
    // Pencil resting on the stack.
    canvas.save();
    canvas.translate(w * 0.04 + 34, stackY + 4);
    canvas.rotate(-0.5);
    _rrect(canvas, const Rect.fromLTWH(0, 0, 18, 5),
        AppColors.accentAmber, 2.5);
    final tip = Path()
      ..moveTo(18, 0)
      ..lineTo(24, 2.5)
      ..lineTo(18, 5)
      ..close();
    canvas.drawPath(tip, Paint()..color = const Color(0xFF334155));
    canvas.restore();

    // ---------- Ground ----------
    final ground = Paint()
      ..color = AppColors.greenBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(6, h - 8),
      Offset(w - 6, h - 8),
      ground,
    );

    // ---------- Teacher (Indian primary-school teacher with tablet) ----------
    final tx = w * 0.36;
    final ty = h - 10; // feet baseline
    const skin = Color(0xFF9C6642);
    const hair = Color(0xFF2B2320);

    // Bun + head + hair cap (compact verticals fit h >= 76).
    canvas.drawCircle(Offset(tx + 8, ty - 56), 4.5, Paint()..color = hair);
    canvas.drawCircle(Offset(tx, ty - 46), 10, Paint()..color = hair);
    canvas.drawCircle(Offset(tx, ty - 44.5), 8.5, Paint()..color = skin);

    // Kurta (green) with dupatta stripe.
    final kurta = Path()
      ..moveTo(tx - 10, ty - 36)
      ..lineTo(tx + 10, ty - 36)
      ..lineTo(tx + 15, ty - 1)
      ..lineTo(tx - 15, ty - 1)
      ..close();
    canvas.drawPath(kurta, Paint()..color = AppColors.primary);
    final dupatta = Path()
      ..moveTo(tx - 4, ty - 36)
      ..lineTo(tx + 2, ty - 36)
      ..lineTo(tx + 7, ty - 1)
      ..lineTo(tx + 1, ty - 1)
      ..close();
    canvas.drawPath(dupatta, Paint()..color = AppColors.primaryDark);

    // Arm reaching to the tablet.
    final arm = Paint()
      ..color = skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tx + 8, ty - 30),
      Offset(tx + 26, ty - 26),
      arm,
    );

    // Tablet: slate body + light screen with flat book glyph (no text).
    final tabletRect = Rect.fromLTWH(tx + 23, ty - 44, 26, 32);
    _rrect(canvas, tabletRect, const Color(0xFF334155), 4);
    _rrect(
      canvas,
      Rect.fromLTWH(tx + 26, ty - 41, 20, 26),
      AppColors.accentBlueLight,
      2.5,
    );
    _rrect(
      canvas,
      Rect.fromLTWH(tx + 29, ty - 36, 14, 8),
      AppColors.primary,
      1.5,
    );
    canvas.drawCircle(
      Offset(tx + 32, ty - 22),
      2.2,
      Paint()..color = AppColors.accentOrange,
    );
    canvas.drawCircle(
      Offset(tx + 38, ty - 22),
      2.2,
      Paint()..color = AppColors.accentBlue,
    );

    // ---------- Child 1 (front, orange) holding a small book ----------
    final c1x = w * 0.66;
    final c1y = h - 8;
    canvas.drawCircle(Offset(c1x, c1y - 22), 8, Paint()..color = const Color(0xFFB07A4B));
    final c1body = Path()
      ..moveTo(c1x - 8, c1y - 14)
      ..lineTo(c1x + 8, c1y - 14)
      ..lineTo(c1x + 11, c1y)
      ..lineTo(c1x - 11, c1y)
      ..close();
    canvas.drawPath(c1body, Paint()..color = AppColors.accentOrange);
    final bookRect = Rect.fromLTWH(c1x - 16, c1y - 14, 10, 12);
    _rrect(canvas, bookRect, Colors.white, 1.5);
    canvas.drawRect(
      bookRect,
      Paint()
        ..color = AppColors.accentOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ---------- Child 2 (right, blue, raised hand) — room permitting ----------
    if (w >= 128) {
      final c2x = w * 0.88;
      final c2y = h - 8;
      canvas.drawCircle(
          Offset(c2x, c2y - 24), 8, Paint()..color = const Color(0xFF8A5A33));
      final c2body = Path()
        ..moveTo(c2x - 8, c2y - 16)
        ..lineTo(c2x + 8, c2y - 16)
        ..lineTo(c2x + 11, c2y)
        ..lineTo(c2x - 11, c2y)
        ..close();
      canvas.drawPath(c2body, Paint()..color = AppColors.accentBlue);
      final raisedArm = Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(c2x + 6, c2y - 14),
        Offset(c2x + 12, c2y - 25),
        raisedArm,
      );
    }

    // ---------- Open book + multilingual dots (top-right, no letters) ----------
    final bookCx = w * 0.66;
    final bookCy = h * 0.14;
    final pageFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pageEdge = Paint()
      ..color = AppColors.greenBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final leftPage = Path()
      ..moveTo(bookCx - 16, bookCy)
      ..quadraticBezierTo(bookCx - 8, bookCy - 4, bookCx, bookCy)
      ..lineTo(bookCx, bookCy + 9)
      ..quadraticBezierTo(bookCx - 8, bookCy + 5, bookCx - 16, bookCy + 9)
      ..close();
    final rightPage = Path()
      ..moveTo(bookCx + 16, bookCy)
      ..quadraticBezierTo(bookCx + 8, bookCy - 4, bookCx, bookCy)
      ..lineTo(bookCx, bookCy + 9)
      ..quadraticBezierTo(bookCx + 8, bookCy + 5, bookCx + 16, bookCy + 9)
      ..close();
    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(rightPage, pageFill);
    canvas.drawPath(leftPage, pageEdge);
    canvas.drawPath(rightPage, pageEdge);

    // Three language dots beneath the book: mother-tongue multilingualism.
    const dotY = 0.30;
    canvas.drawCircle(Offset(bookCx - 12, h * dotY),
        4.5, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(bookCx, h * dotY),
        4.5, Paint()..color = AppColors.accentBlue);
    canvas.drawCircle(Offset(bookCx + 12, h * dotY),
        4.5, Paint()..color = AppColors.accentOrange);
  }

  void _rrect(Canvas canvas, Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  double _min(double a, double b) => a < b ? a : b;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
