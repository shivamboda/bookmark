import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted vector Poppy flower doodle drawn via CustomPainter.
///
/// Pure code—zero downloaded PNGs/SVGs. Scalable to any dimension,
/// crisp on iPhone 16 Super Retina XDR, and delicately animated or tinted.
class PoppyDoodle extends StatelessWidget {
  final double size;
  final Color? petalColor;
  final bool showStem;

  const PoppyDoodle({
    super.key,
    this.size = 64,
    this.petalColor,
    this.showStem = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PoppyPainter(
          petalColor: petalColor ?? FloralPalette.poppyRed,
          showStem: showStem,
        ),
      ),
    );
  }
}

class _PoppyPainter extends CustomPainter {
  final Color petalColor;
  final bool showStem;

  _PoppyPainter({
    required this.petalColor,
    required this.showStem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, showStem ? size.height * 0.42 : size.height / 2);
    final radius = size.width * 0.36;

    // Optional Stem
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepForestGreen
        ..strokeWidth = math.max(1.8, size.width * 0.035)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      stemPath.moveTo(center.dx, center.dy + radius * 0.6);
      stemPath.quadraticBezierTo(
        center.dx - size.width * 0.08,
        size.height * 0.75,
        center.dx + size.width * 0.04,
        size.height,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Small Leaf
      final leafPaint = Paint()
        ..color = FloralPalette.sageGreen.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      final leafPath = Path();
      leafPath.moveTo(center.dx - size.width * 0.04, size.height * 0.72);
      leafPath.quadraticBezierTo(
        center.dx - size.width * 0.3,
        size.height * 0.68,
        center.dx - size.width * 0.22,
        size.height * 0.8,
      );
      leafPath.close();
      canvas.drawPath(leafPath, leafPaint);
    }

    // Outer Petals (4 overlapping organic heart/scallop shapes)
    final petalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final petalOutline = Paint()
      ..color = FloralPalette.poppyRedDark.withValues(alpha: 0.7)
      ..strokeWidth = math.max(1.2, size.width * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];

    for (int i = 0; i < angles.length; i++) {
      final angle = angles[i] + (i % 2 == 0 ? 0.08 : -0.06);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.cubicTo(
        -radius * 0.7, -radius * 0.5,
        -radius * 0.9, -radius * 1.1,
        0, -radius * 1.15,
      );
      petalPath.cubicTo(
        radius * 0.9, -radius * 1.1,
        radius * 0.7, -radius * 0.5,
        0, 0,
      );

      canvas.drawPath(petalPath, petalFill);
      canvas.drawPath(petalPath, petalOutline);
      canvas.restore();
    }

    // Inner smaller accent petals for rich depth
    final innerPetalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + math.pi / 4;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final innerPath = Path();
      innerPath.moveTo(0, 0);
      innerPath.cubicTo(
        -radius * 0.4, -radius * 0.4,
        -radius * 0.6, -radius * 0.75,
        0, -radius * 0.85,
      );
      innerPath.cubicTo(
        radius * 0.6, -radius * 0.75,
        radius * 0.4, -radius * 0.4,
        0, 0,
      );
      canvas.drawPath(innerPath, innerPetalFill);
      canvas.restore();
    }

    // Dark stamen ring
    final darkCenterPaint = Paint()
      ..color = FloralPalette.warmCharcoal.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, darkCenterPaint);

    // Buttercup Yellow center pip
    final centerPaint = Paint()
      ..color = FloralPalette.buttercupYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.16, centerPaint);

    // Delicate stamen specks
    final speckPaint = Paint()
      ..color = FloralPalette.buttercupYellow.withValues(alpha: 0.9)
      ..strokeWidth = math.max(1.0, size.width * 0.02)
      ..style = PaintingStyle.fill;

    for (int j = 0; j < 8; j++) {
      final theta = (j * 2 * math.pi) / 8;
      final speckOffset = Offset(
        center.dx + math.cos(theta) * (radius * 0.24),
        center.dy + math.sin(theta) * (radius * 0.24),
      );
      canvas.drawCircle(speckOffset, size.width * 0.02, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PoppyPainter oldDelegate) {
    return oldDelegate.petalColor != petalColor || oldDelegate.showStem != showStem;
  }
}
