import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted sweet botanical daisy doodle drawn via CustomPainter.
///
/// Features soft radiating ivory/cream petals with delicate ink contours,
/// a sunny golden-honey stippled center, and an optional curving stem with leaves.
class DaisyDoodle extends StatelessWidget {
  final double size;
  final bool showStem;
  final Color? petalColor;
  final Color? centerColor;

  const DaisyDoodle({
    super.key,
    this.size = 64,
    this.showStem = false,
    this.petalColor,
    this.centerColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: showStem ? size * 1.35 : size,
      child: CustomPaint(
        painter: _DaisyPainter(
          showStem: showStem,
          petalColor: petalColor ?? Colors.white,
          centerColor: centerColor ?? FloralPalette.buttercupYellow,
        ),
      ),
    );
  }
}

class _DaisyPainter extends CustomPainter {
  final bool showStem;
  final Color petalColor;
  final Color centerColor;

  _DaisyPainter({
    required this.showStem,
    required this.petalColor,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * 0.5,
      showStem ? size.height * 0.35 : size.height * 0.5,
    );
    final radius = showStem ? size.width * 0.35 : size.width * 0.44;

    // Stem & Leaf
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.85)
        ..strokeWidth = math.max(1.8, size.width * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      stemPath.moveTo(center.dx, center.dy + radius * 0.5);
      stemPath.quadraticBezierTo(
        center.dx + size.width * 0.06, size.height * 0.65,
        center.dx - size.width * 0.04, size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Cute small daisy leaf
      final leafPaint = Paint()
        ..color = FloralPalette.sageGreen.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      final leafStroke = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.8)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final leafPath = Path();
      leafPath.moveTo(center.dx + size.width * 0.04, size.height * 0.68);
      leafPath.quadraticBezierTo(
        center.dx + size.width * 0.32, size.height * 0.62,
        center.dx + size.width * 0.36, size.height * 0.74,
      );
      leafPath.quadraticBezierTo(
        center.dx + size.width * 0.18, size.height * 0.76,
        center.dx + size.width * 0.02, size.height * 0.72,
      );
      canvas.drawPath(leafPath, leafPaint);
      canvas.drawPath(leafPath, leafStroke);
    }

    // 12 Radiating elongated petals
    final petalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final petalOutline = Paint()
      ..color = const Color(0xFFD8C2C9).withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.1, size.width * 0.018)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const petalCount = 12;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount) + 0.1;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petal = Path();
      petal.moveTo(0, 0);
      petal.cubicTo(
        -radius * 0.16, -radius * 0.45,
        -radius * 0.22, -radius * 0.88,
        0, -radius * 1.02,
      );
      petal.cubicTo(
        radius * 0.22, -radius * 0.88,
        radius * 0.16, -radius * 0.45,
        0, 0,
      );
      petal.close();

      canvas.drawPath(petal, petalFill);
      canvas.drawPath(petal, petalOutline);
      canvas.restore();
    }

    // Sunny Golden Center Pip
    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.32, centerPaint);

    final centerOutline = Paint()
      ..color = const Color(0xFFC49830)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.32, centerOutline);

    // Stipple Texture Dots
    final dotPaint = Paint()
      ..color = const Color(0xFFA57C1E).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (int j = 0; j < 6; j++) {
      final theta = (j * 2 * math.pi) / 6;
      final offset = Offset(
        center.dx + math.cos(theta) * (radius * 0.16),
        center.dy + math.sin(theta) * (radius * 0.16),
      );
      canvas.drawCircle(offset, size.width * 0.016, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DaisyPainter oldDelegate) {
    return oldDelegate.showStem != showStem ||
        oldDelegate.petalColor != petalColor ||
        oldDelegate.centerColor != centerColor;
  }
}
