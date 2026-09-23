import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical tulip doodle drawn via CustomPainter.
///
/// Features a cupped, overlapping spring blossom in soft rose/blush tones
/// with graceful arching leaves clasping a slender stem.
class TulipDoodle extends StatelessWidget {
  final double size;
  final bool showStem;
  final Color? petalColor;

  const TulipDoodle({
    super.key,
    this.size = 64,
    this.showStem = true,
    this.petalColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: showStem ? size * 1.35 : size,
      child: CustomPaint(
        painter: _TulipPainter(
          showStem: showStem,
          petalColor: petalColor ?? FloralPalette.rosePetal,
        ),
      ),
    );
  }
}

class _TulipPainter extends CustomPainter {
  final bool showStem;
  final Color petalColor;

  _TulipPainter({
    required this.showStem,
    required this.petalColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cupCenter = Offset(
      size.width * 0.5,
      showStem ? size.height * 0.34 : size.height * 0.5,
    );
    final width = showStem ? size.width * 0.55 : size.width * 0.75;
    final height = showStem ? size.height * 0.40 : size.height * 0.70;

    // Stem and long blade leaves
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.85)
        ..strokeWidth = math.max(2.0, size.width * 0.032)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      stemPath.moveTo(cupCenter.dx, cupCenter.dy + height * 0.45);
      stemPath.quadraticBezierTo(
        cupCenter.dx - size.width * 0.04, size.height * 0.65,
        cupCenter.dx + size.width * 0.02, size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Long arched blade leaf left
      final leafPaint = Paint()
        ..color = FloralPalette.sageGreen.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      final leafStroke = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.8)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;

      final leftLeaf = Path();
      leftLeaf.moveTo(cupCenter.dx - 2, size.height * 0.85);
      leftLeaf.cubicTo(
        cupCenter.dx - size.width * 0.35, size.height * 0.70,
        cupCenter.dx - size.width * 0.32, size.height * 0.45,
        cupCenter.dx - size.width * 0.18, size.height * 0.38,
      );
      leftLeaf.cubicTo(
        cupCenter.dx - size.width * 0.22, size.height * 0.55,
        cupCenter.dx - size.width * 0.15, size.height * 0.75,
        cupCenter.dx - 2, size.height * 0.85,
      );
      canvas.drawPath(leftLeaf, leafPaint);
      canvas.drawPath(leftLeaf, leafStroke);
    }

    // Outer Back Petal (visible between front petals)
    final backPetalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(cupCenter.dx, cupCenter.dy - height * 0.52);
    backPath.cubicTo(
      cupCenter.dx - width * 0.28, cupCenter.dy - height * 0.35,
      cupCenter.dx - width * 0.18, cupCenter.dy + height * 0.2,
      cupCenter.dx, cupCenter.dy + height * 0.45,
    );
    backPath.cubicTo(
      cupCenter.dx + width * 0.18, cupCenter.dy + height * 0.2,
      cupCenter.dx + width * 0.28, cupCenter.dy - height * 0.35,
      cupCenter.dx, cupCenter.dy - height * 0.52,
    );
    canvas.drawPath(backPath, backPetalFill);

    // Left Front Cup Petal
    final petalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    final petalOutline = Paint()
      ..color = FloralPalette.poppyRedDark.withValues(alpha: 0.65)
      ..strokeWidth = math.max(1.2, size.width * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leftPetal = Path();
    leftPetal.moveTo(cupCenter.dx, cupCenter.dy + height * 0.48);
    leftPetal.cubicTo(
      cupCenter.dx - width * 0.55, cupCenter.dy + height * 0.25,
      cupCenter.dx - width * 0.52, cupCenter.dy - height * 0.35,
      cupCenter.dx - width * 0.24, cupCenter.dy - height * 0.48,
    );
    leftPetal.cubicTo(
      cupCenter.dx - width * 0.08, cupCenter.dy - height * 0.35,
      cupCenter.dx - width * 0.05, cupCenter.dy + height * 0.2,
      cupCenter.dx, cupCenter.dy + height * 0.48,
    );
    canvas.drawPath(leftPetal, petalFill);
    canvas.drawPath(leftPetal, petalOutline);

    // Right Front Cup Petal (overlapping)
    final rightPetal = Path();
    rightPetal.moveTo(cupCenter.dx, cupCenter.dy + height * 0.48);
    rightPetal.cubicTo(
      cupCenter.dx + width * 0.55, cupCenter.dy + height * 0.25,
      cupCenter.dx + width * 0.52, cupCenter.dy - height * 0.35,
      cupCenter.dx + width * 0.24, cupCenter.dy - height * 0.48,
    );
    rightPetal.cubicTo(
      cupCenter.dx + width * 0.08, cupCenter.dy - height * 0.35,
      cupCenter.dx + width * 0.05, cupCenter.dy + height * 0.2,
      cupCenter.dx, cupCenter.dy + height * 0.48,
    );
    canvas.drawPath(rightPetal, petalFill);
    canvas.drawPath(rightPetal, petalOutline);
  }

  @override
  bool shouldRepaint(covariant _TulipPainter oldDelegate) {
    return oldDelegate.showStem != showStem || oldDelegate.petalColor != petalColor;
  }
}
