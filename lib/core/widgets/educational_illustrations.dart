import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Crisp, resolution-independent educational vector illustrations
/// following the soft educational palette and classroom motifs.
class ClassroomHeroIllustration extends StatelessWidget {
  final double height;
  final double width;

  const ClassroomHeroIllustration({
    super.key,
    this.height = 130,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _ClassroomHeroPainter(),
      ),
    );
  }
}

class _ClassroomHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft background glow / hills
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.greenLight.withValues(alpha: 0.6),
          AppColors.greenSurface.withValues(alpha: 0.2),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(0, h * 0.7)
      ..quadraticBezierTo(w * 0.25, h * 0.5, w * 0.5, h * 0.65)
      ..quadraticBezierTo(w * 0.75, h * 0.8, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, bgPaint);

    // 2. Decorative leaves / tree canopy on right side
    final leafPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w - 20, 25), 45, leafPaint);
    canvas.drawCircle(Offset(w - 55, 35), 32, leafPaint);
    canvas.drawCircle(Offset(w - 35, 60), 28, leafPaint);

    final brightLeafPaint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w - 25, 38), 24, brightLeafPaint);

    // 3. Central Teacher and Children silhouettes / figures
    final primaryPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final warmAccentPaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    final blueAccentPaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.fill;

    final amberPaint = Paint()
      ..color = AppColors.accentAmber
      ..style = PaintingStyle.fill;

    // Base ground line
    final groundPaint = Paint()
      ..color = AppColors.greenBorder
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(10, h - 8), Offset(w - 10, h - 8), groundPaint);

    // Teacher figure (center-left)
    final teacherX = math.max(60.0, w * 0.28);
    final teacherY = h - 22;

    // Head
    canvas.drawCircle(Offset(teacherX, teacherY - 48), 12, primaryPaint);
    // Body / saree drapery
    final teacherBody = Path()
      ..moveTo(teacherX - 10, teacherY - 34)
      ..lineTo(teacherX + 10, teacherY - 34)
      ..lineTo(teacherX + 16, teacherY)
      ..lineTo(teacherX - 16, teacherY)
      ..close();
    canvas.drawPath(teacherBody, primaryPaint);

    // Book in teacher's hand
    final bookPaint = Paint()..color = AppColors.accentOrangeLight;
    final bookCoverPaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bookRect = Rect.fromLTWH(teacherX + 10, teacherY - 36, 16, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(bookRect, const Radius.circular(2)), bookPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bookRect, const Radius.circular(2)), bookCoverPaint);

    // Child 1 (sitting/reading)
    final child1X = teacherX + 45;
    final child1Y = h - 14;
    canvas.drawCircle(Offset(child1X, child1Y - 26), 9, warmAccentPaint);
    final child1Body = Path()
      ..moveTo(child1X - 8, child1Y - 16)
      ..lineTo(child1X + 8, child1Y - 16)
      ..lineTo(child1X + 12, child1Y)
      ..lineTo(child1X - 12, child1Y)
      ..close();
    canvas.drawPath(child1Body, warmAccentPaint);

    // Child 2 (listening with raised hand)
    final child2X = child1X + 38;
    if (child2X < w - 40) {
      final child2Y = h - 14;
      canvas.drawCircle(Offset(child2X, child2Y - 28), 9, blueAccentPaint);
      final child2Body = Path()
        ..moveTo(child2X - 8, child2Y - 18)
        ..lineTo(child2X + 8, child2Y - 18)
        ..lineTo(child2X + 11, child2Y)
        ..lineTo(child2X - 11, child2Y)
        ..close();
      canvas.drawPath(child2Body, blueAccentPaint);

      // Raised hand
      final armPaint = Paint()
        ..color = blueAccentPaint.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(child2X + 6, child2Y - 16), Offset(child2X + 14, child2Y - 28), armPaint);
    }

    // Child 3 (holding slate)
    final child3X = teacherX - 38;
    if (child3X > 30) {
      final child3Y = h - 14;
      canvas.drawCircle(Offset(child3X, child3Y - 26), 9, amberPaint);
      final child3Body = Path()
        ..moveTo(child3X - 8, child3Y - 16)
        ..lineTo(child3X + 8, child3Y - 16)
        ..lineTo(child3X + 11, child3Y)
        ..lineTo(child3X - 11, child3Y)
        ..close();
      canvas.drawPath(child3Body, amberPaint);

      // Slate
      final slatePaint = Paint()..color = const Color(0xFF2C3E50);
      final slateFramePaint = Paint()
        ..color = const Color(0xFFD35400)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final slateRect = Rect.fromLTWH(child3X - 18, child3Y - 16, 12, 14);
      canvas.drawRect(slateRect, slatePaint);
      canvas.drawRect(slateRect, slateFramePaint);
    }

    // 4. Subtle alphabet/number bubbles floating
    _drawFloatingLetter(canvas, 'क', Offset(math.max(25.0, w * 0.12), h * 0.35), AppColors.primary);
    _drawFloatingLetter(canvas, 'A', Offset(teacherX + 22, h * 0.22), AppColors.accentBlue);
    _drawFloatingLetter(canvas, 'अ', Offset(math.min(w - 70, teacherX + 90), h * 0.38), AppColors.accentOrange);
  }

  void _drawFloatingLetter(Canvas canvas, String text, Offset center, Color color) {
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 14, bubblePaint);
    canvas.drawCircle(center, 14, borderPaint);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Motivational strong foundations banner illustration
class StrongFoundationsIllustration extends StatelessWidget {
  const StrongFoundationsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.greenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greenBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.nature_people_rounded, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Strong foundations go further.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Early literacy in the mother tongue empowers lifelong confident learning across subjects.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
