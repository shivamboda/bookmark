import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted woodland acorn doodle drawn via CustomPainter.
///
/// Features authentic autumnal botanical details:
/// - Textured cross-hatched cupule (cap) with gentle stem
/// - Smooth rounded nut body with tapered bottom tip
/// - Warm caramel fill with subtle gloss highlight arc
/// - Organic hand-drawn pen outlines
class AcornDoodle extends StatelessWidget {
  final double size;
  final Color? capColor;
  final Color? nutColor;
  final double angle;

  const AcornDoodle({
    super.key,
    this.size = 54,
    this.capColor,
    this.nutColor,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeSize = size.isFinite && size > 0 ? size : 54.0;
    final cap = capColor ?? FloralPalette.espresso;
    final nut = nutColor ?? FloralPalette.caramel;

    Widget acorn = SizedBox(
      width: safeSize * 0.85,
      height: safeSize,
      child: CustomPaint(
        painter: _AcornPainter(
          capColor: cap,
          nutColor: nut,
        ),
      ),
    );

    if (angle != 0) {
      acorn = Transform.rotate(
        angle: angle,
        child: acorn,
      );
    }

    return acorn;
  }
}

class _AcornPainter extends CustomPainter {
  final Color capColor;
  final Color nutColor;

  _AcornPainter({
    required this.capColor,
    required this.nutColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // 1. Stem on Cap
    final stemPaint = Paint()
      ..color = capColor
      ..strokeWidth = math.max(2.0, w * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(cx, h * 0.18);
    stemPath.cubicTo(
      cx - w * 0.06, h * 0.10,
      cx - w * 0.02, h * 0.04,
      cx + w * 0.08, h * 0.02,
    );
    canvas.drawPath(stemPath, stemPaint);

    // 2. Nut Body (Drawn first so cap sits cleanly over it)
    final nutPath = Path();
    final nutTopY = h * 0.36;
    nutPath.moveTo(w * 0.18, nutTopY);
    nutPath.cubicTo(
      w * 0.12, h * 0.60,
      w * 0.28, h * 0.88,
      cx, h * 0.96, // Bottom tip
    );
    nutPath.cubicTo(
      w * 0.72, h * 0.88,
      w * 0.88, h * 0.60,
      w * 0.82, nutTopY,
    );
    nutPath.close();

    // Nut Fill with Warm Caramel Gradient
    final nutFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          nutColor,
          FloralPalette.cocoa,
        ],
      ).createShader(Rect.fromLTWH(0, nutTopY, w, h - nutTopY))
      ..style = PaintingStyle.fill;
    canvas.drawPath(nutPath, nutFill);

    // Nut Outline
    final nutOutline = Paint()
      ..color = FloralPalette.espresso
      ..strokeWidth = math.max(1.4, w * 0.028)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(nutPath, nutOutline);

    // Nut Gloss Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = math.max(1.4, w * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.26, h * 0.44);
    highlightPath.quadraticBezierTo(w * 0.22, h * 0.62, w * 0.34, h * 0.76);
    canvas.drawPath(highlightPath, highlightPaint);

    // 3. Cap (Cupule)
    final capPath = Path();
    capPath.moveTo(w * 0.10, h * 0.38);
    // Rounded top dome
    capPath.cubicTo(
      w * 0.10, h * 0.18,
      w * 0.90, h * 0.18,
      w * 0.90, h * 0.38,
    );
    // Gentle curved rim overlapping nut
    capPath.cubicTo(
      w * 0.70, h * 0.43,
      w * 0.30, h * 0.43,
      w * 0.10, h * 0.38,
    );
    capPath.close();

    // Cap Fill
    final capFill = Paint()
      ..color = capColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(capPath, capFill);

    // Cap Cross-Hatch Texture
    final hatchPaint = Paint()
      ..color = FloralPalette.latte.withValues(alpha: 0.65)
      ..strokeWidth = math.max(0.8, w * 0.016)
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipPath(capPath);
    // Diagonal hatching 1
    for (double i = -w * 0.5; i < w * 1.5; i += w * 0.14) {
      canvas.drawLine(Offset(i, h * 0.10), Offset(i + w * 0.4, h * 0.45), hatchPaint);
    }
    // Diagonal hatching 2
    for (double i = -w * 0.5; i < w * 1.5; i += w * 0.14) {
      canvas.drawLine(Offset(i + w * 0.4, h * 0.10), Offset(i, h * 0.45), hatchPaint);
    }
    canvas.restore();

    // Cap Outline
    final capOutline = Paint()
      ..color = FloralPalette.espresso
      ..strokeWidth = math.max(1.5, w * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(capPath, capOutline);
  }

  @override
  bool shouldRepaint(covariant _AcornPainter oldDelegate) =>
      oldDelegate.capColor != capColor || oldDelegate.nutColor != nutColor;
}
