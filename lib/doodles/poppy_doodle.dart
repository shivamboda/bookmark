import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical poppy sketch drawn via CustomPainter.
///
/// Designed to evoke a delicate watercolor-and-ink field sketch in a botanical journal:
/// soft layered petal washes, loose organic contour lines, a natural curving stem,
/// and an unopened side bud. Pure vector code with zero image assets.
class PoppyDoodle extends StatelessWidget {
  final double size;
  final Color? petalColor;
  final bool showStem;

  const PoppyDoodle({
    super.key,
    this.size = 80,
    this.petalColor,
    this.showStem = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: showStem ? size * 1.35 : size,
      child: CustomPaint(
        painter: _PoppyBotanicalPainter(
          petalColor: petalColor ?? FloralPalette.poppyRed,
          showStem: showStem,
        ),
      ),
    );
  }
}

class _PoppyBotanicalPainter extends CustomPainter {
  final Color petalColor;
  final bool showStem;

  _PoppyBotanicalPainter({
    required this.petalColor,
    required this.showStem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bloomCenter = Offset(
      size.width * 0.54,
      showStem ? size.height * 0.32 : size.height * 0.5,
    );
    final radius = size.width * 0.38;

    // 1. Organic curving stem & leaves if enabled
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.85)
        ..strokeWidth = math.max(2.0, size.width * 0.032)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Main curving stem
      final stemPath = Path();
      stemPath.moveTo(bloomCenter.dx, bloomCenter.dy + radius * 0.45);
      stemPath.cubicTo(
        bloomCenter.dx - size.width * 0.12, size.height * 0.58,
        bloomCenter.dx + size.width * 0.08, size.height * 0.78,
        bloomCenter.dx - size.width * 0.05, size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Primary serrated leaf
      final leafPaint = Paint()
        ..color = FloralPalette.sageGreen.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      final leafStroke = Paint()
        ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final leafPath = Path();
      leafPath.moveTo(bloomCenter.dx - size.width * 0.08, size.height * 0.65);
      leafPath.cubicTo(
        bloomCenter.dx - size.width * 0.45, size.height * 0.58,
        bloomCenter.dx - size.width * 0.40, size.height * 0.75,
        bloomCenter.dx - size.width * 0.05, size.height * 0.72,
      );
      canvas.drawPath(leafPath, leafPaint);
      canvas.drawPath(leafPath, leafStroke);

      // Delicate leaf vein
      final veinPath = Path();
      veinPath.moveTo(bloomCenter.dx - size.width * 0.08, size.height * 0.65);
      veinPath.quadraticBezierTo(
        bloomCenter.dx - size.width * 0.25, size.height * 0.65,
        bloomCenter.dx - size.width * 0.38, size.height * 0.67,
      );
      canvas.drawPath(veinPath, leafStroke);

      // Tiny tender side branch with an unopened poppy bud
      final branchPath = Path();
      branchPath.moveTo(bloomCenter.dx - size.width * 0.02, size.height * 0.52);
      branchPath.quadraticBezierTo(
        bloomCenter.dx + size.width * 0.22, size.height * 0.54,
        bloomCenter.dx + size.width * 0.32, size.height * 0.44,
      );
      canvas.drawPath(branchPath, stemPaint);

      // Unopened bud (drooping teardrop with hairy sepals)
      final budCenter = Offset(bloomCenter.dx + size.width * 0.32, size.height * 0.44);
      final budPaint = Paint()
        ..color = FloralPalette.sageGreen
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: budCenter, width: size.width * 0.12, height: size.width * 0.18),
        budPaint,
      );
      final budPeekingPaint = Paint()
        ..color = petalColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(budCenter.dx + 2, budCenter.dy + size.width * 0.06),
        size.width * 0.04,
        budPeekingPaint,
      );
    }

    // 2. Soft Watercolor Petal Washes (Translucent layers with loose contour strokes)
    final petalFill = Paint()
      ..color = petalColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final petalContour = Paint()
      ..color = FloralPalette.poppyRedDark.withValues(alpha: 0.65)
      ..strokeWidth = math.max(1.3, size.width * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final petalAngles = [0.1, math.pi / 2 - 0.15, math.pi + 0.1, 3 * math.pi / 2 - 0.05];

    // Four flowing, crinkled outer poppy petals
    for (int i = 0; i < petalAngles.length; i++) {
      final angle = petalAngles[i];
      canvas.save();
      canvas.translate(bloomCenter.dx, bloomCenter.dy);
      canvas.rotate(angle);

      final petal = Path();
      petal.moveTo(0, 0);
      petal.cubicTo(
        -radius * 0.75, -radius * 0.45,
        -radius * 0.95, -radius * 1.05,
        -radius * 0.15, -radius * 1.18,
      );
      petal.cubicTo(
        radius * 0.35, -radius * 1.25,
        radius * 0.95, -radius * 0.95,
        radius * 0.65, -radius * 0.4,
      );
      petal.close();

      canvas.drawPath(petal, petalFill);
      canvas.drawPath(petal, petalContour);
      canvas.restore();
    }

    // 3. Inner cupped petals for botanical depth
    final innerFill = Paint()
      ..color = petalColor.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + 0.4;
      canvas.save();
      canvas.translate(bloomCenter.dx, bloomCenter.dy);
      canvas.rotate(angle);

      final innerPetal = Path();
      innerPetal.moveTo(0, 0);
      innerPetal.cubicTo(
        -radius * 0.45, -radius * 0.35,
        -radius * 0.55, -radius * 0.8,
        0, -radius * 0.88,
      );
      innerPetal.cubicTo(
        radius * 0.55, -radius * 0.8,
        radius * 0.45, -radius * 0.35,
        0, 0,
      );
      innerPetal.close();

      canvas.drawPath(innerPetal, innerFill);
      canvas.restore();
    }

    // 4. Botanical Center: Dark charcoal/plum stamen ring + Yellow seed capsule
    final stamenPaint = Paint()
      ..color = FloralPalette.warmCharcoal.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bloomCenter, radius * 0.26, stamenPaint);

    // Radiating stamen pollen dots
    final pollenPaint = Paint()
      ..color = FloralPalette.buttercupYellow.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    for (int j = 0; j < 10; j++) {
      final theta = (j * 2 * math.pi) / 10;
      final offset = Offset(
        bloomCenter.dx + math.cos(theta) * (radius * 0.22),
        bloomCenter.dy + math.sin(theta) * (radius * 0.22),
      );
      canvas.drawCircle(offset, math.max(1.2, size.width * 0.018), pollenPaint);
    }

    // Central star-shaped seed capsule
    final capsulePaint = Paint()
      ..color = const Color(0xFFC8A856)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bloomCenter, radius * 0.12, capsulePaint);
  }

  @override
  bool shouldRepaint(covariant _PoppyBotanicalPainter oldDelegate) {
    return oldDelegate.petalColor != petalColor || oldDelegate.showStem != showStem;
  }
}
