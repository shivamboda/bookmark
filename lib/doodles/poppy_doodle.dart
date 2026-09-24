import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical poppy sketch drawn via CustomPainter.
///
/// Features authentic botanical details:
/// - Opaque crinkled petals with radial gradient (deep crimson center to light poppy tips)
/// - Inner crinkled petals for botanical depth and ruffled richness
/// - Dark plum blotches at petal bases
/// - Small green seed pod with star-spoked cap
/// - Central dark plum stamen ring with radiating filaments and buttercup pollen anther dots
/// - Correct z-order: stem, attached serrated leaf, and separate budding stalk drawn behind the bloom
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
    final safeSize = size.isFinite && size > 0 ? size : 80.0;

    return SizedBox(
      width: safeSize,
      height: showStem ? safeSize * 1.35 : safeSize,
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
      size.width * 0.52,
      showStem ? size.height * 0.38 : size.height * 0.50,
    );
    final radius = size.width * 0.36;

    // ========================================================
    // 1. STEMS, BUD & LEAVES (Z-Order: Drawn behind bloom)
    // ========================================================
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepForestGreen
        ..strokeWidth = math.max(1.8, size.width * 0.034)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Primary gracefully arched stem
      final stemPath = Path();
      stemPath.moveTo(bloomCenter.dx - 1, bloomCenter.dy + radius * 0.4);
      stemPath.cubicTo(
        bloomCenter.dx - size.width * 0.05, size.height * 0.55,
        bloomCenter.dx + size.width * 0.06, size.height * 0.78,
        bloomCenter.dx - size.width * 0.02, size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Separate Budding Stalk (distinct from main stem)
      final branchStalk = Path();
      branchStalk.moveTo(bloomCenter.dx + size.width * 0.02, size.height * 0.62);
      branchStalk.cubicTo(
        bloomCenter.dx + size.width * 0.18, size.height * 0.56,
        bloomCenter.dx + size.width * 0.28, size.height * 0.58,
        bloomCenter.dx + size.width * 0.30, size.height * 0.65,
      );
      canvas.drawPath(branchStalk, stemPaint);

      // Drooping bud at the tip of its own stalk
      final budTip = Offset(bloomCenter.dx + size.width * 0.30, size.height * 0.65);
      final budPaint = Paint()
        ..color = FloralPalette.sageGreen
        ..style = PaintingStyle.fill;
      final budStroke = Paint()
        ..color = FloralPalette.deepForestGreen
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.translate(budTip.dx, budTip.dy);
      canvas.rotate(0.35);

      final budPath = Path();
      budPath.moveTo(0, 0);
      budPath.cubicTo(-size.width * 0.06, size.width * 0.04, -size.width * 0.05, size.width * 0.14, 0, size.width * 0.16);
      budPath.cubicTo(size.width * 0.05, size.width * 0.14, size.width * 0.06, size.width * 0.04, 0, 0);
      canvas.drawPath(budPath, budPaint);
      canvas.drawPath(budPath, budStroke);

      // Tiny peek of red petal from the cracking bud
      final budPetalPaint = Paint()
        ..color = petalColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, size.width * 0.15), size.width * 0.025, budPetalPaint);
      canvas.restore();

      // Botanical Leaf: Originates directly from the stem curve with petiole connection
      final leafStemX = bloomCenter.dx - size.width * 0.02;
      final leafStemY = size.height * 0.72;

      final leafPaint = Paint()
        ..color = FloralPalette.sageGreen.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      final leafStroke = Paint()
        ..color = FloralPalette.deepForestGreen
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;

      final leafPath = Path();
      leafPath.moveTo(leafStemX, leafStemY);
      leafPath.cubicTo(
        leafStemX - size.width * 0.18, leafStemY - size.height * 0.06,
        leafStemX - size.width * 0.42, leafStemY - size.height * 0.04,
        leafStemX - size.width * 0.40, leafStemY + size.height * 0.08,
      );
      leafPath.cubicTo(
        leafStemX - size.width * 0.25, leafStemY + size.height * 0.09,
        leafStemX - size.width * 0.12, leafStemY + size.height * 0.05,
        leafStemX, leafStemY,
      );
      canvas.drawPath(leafPath, leafPaint);
      canvas.drawPath(leafPath, leafStroke);

      // Leaf central vein
      final veinPath = Path();
      veinPath.moveTo(leafStemX, leafStemY);
      veinPath.quadraticBezierTo(
        leafStemX - size.width * 0.20, leafStemY + size.height * 0.01,
        leafStemX - size.width * 0.36, leafStemY + size.height * 0.03,
      );
      canvas.drawPath(veinPath, leafStroke);
    }

    // ========================================================
    // 2. BLOOM (Z-Order: Opaque petals on top of stem)
    // ========================================================
    const petalCount = 4;
    final baseAngles = [0.15, math.pi / 2 + 0.1, math.pi + 0.05, 3 * math.pi / 2 + 0.2];

    for (int i = 0; i < petalCount; i++) {
      final angle = baseAngles[i];
      canvas.save();
      canvas.translate(bloomCenter.dx, bloomCenter.dy);
      canvas.rotate(angle);

      // Wavy, crinkled organic petal contour
      final petal = Path();
      petal.moveTo(0, 0);
      petal.cubicTo(-radius * 0.65, -radius * 0.35, -radius * 0.95, -radius * 0.85, -radius * 0.45, -radius * 1.15);
      petal.cubicTo(-radius * 0.15, -radius * 1.05, 0, -radius * 1.25, radius * 0.25, -radius * 1.10);
      petal.cubicTo(radius * 0.75, -radius * 1.20, radius * 0.95, -radius * 0.75, radius * 0.65, -radius * 0.35);
      petal.close();

      // Solid base underlay to guarantee 100% opacity over any cover tone (no green/brown bleed)
      final baseUnderlayPaint = Paint()
        ..color = const Color(0xFFC7262F)
        ..style = PaintingStyle.fill;
      canvas.drawPath(petal, baseUnderlayPaint);

      // Opaque gradient fill: deeper ruby at center to radiant coral/poppy at wavy tips
      final fillPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.bottomCenter,
          radius: 1.1,
          colors: [
            const Color(0xFF9E1B24), // Deep crimson center
            const Color(0xFFC7262F),
            petalColor.withValues(alpha: 1.0), // 100% solid vibrant red
            const Color(0xFFEA5E55), // Soft luminous tip
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 1.2))
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = const Color(0xFF7A161C).withValues(alpha: 0.75)
        ..strokeWidth = math.max(1.1, size.width * 0.016)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(petal, fillPaint);
      canvas.drawPath(petal, strokePaint);

      // Dark plum blotch at the petal base (signature poppy characteristic)
      final blotchPaint = Paint()
        ..color = const Color(0xFF260D15)
        ..style = PaintingStyle.fill;

      final blotchPath = Path();
      blotchPath.moveTo(0, 0);
      blotchPath.cubicTo(-radius * 0.22, -radius * 0.15, -radius * 0.28, -radius * 0.38, 0, -radius * 0.42);
      blotchPath.cubicTo(radius * 0.28, -radius * 0.38, radius * 0.22, -radius * 0.15, 0, 0);
      canvas.drawPath(blotchPath, blotchPaint);

      canvas.restore();
    }

    // Inner crinkled petals for ruffled richness
    for (int i = 0; i < 2; i++) {
      final angle = (i * math.pi) + 0.75;
      canvas.save();
      canvas.translate(bloomCenter.dx, bloomCenter.dy);
      canvas.rotate(angle);

      final innerPetal = Path();
      innerPetal.moveTo(0, 0);
      innerPetal.cubicTo(-radius * 0.45, -radius * 0.3, -radius * 0.65, -radius * 0.75, 0, -radius * 0.88);
      innerPetal.cubicTo(radius * 0.65, -radius * 0.75, radius * 0.45, -radius * 0.3, 0, 0);

      final innerFill = Paint()
        ..color = petalColor.withValues(alpha: 1.0)
        ..style = PaintingStyle.fill;

      canvas.drawPath(innerPetal, innerFill);
      canvas.restore();
    }

    // ========================================================
    // 3. SEED POD & STAMEN RING
    // ========================================================
    // Dark plum stamen base disk
    final stamenBasePaint = Paint()
      ..color = const Color(0xFF1F0B12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bloomCenter, radius * 0.28, stamenBasePaint);

    // Fine dark stamen filaments radiating outward with golden/buttercup anther dots
    final filamentPaint = Paint()
      ..color = const Color(0xFF1F0B12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final antherPaint = Paint()
      ..color = FloralPalette.buttercupYellow
      ..style = PaintingStyle.fill;

    const antherCount = 14;
    for (int j = 0; j < antherCount; j++) {
      final theta = (j * 2 * math.pi) / antherCount;
      final start = Offset(
        bloomCenter.dx + math.cos(theta) * (radius * 0.18),
        bloomCenter.dy + math.sin(theta) * (radius * 0.18),
      );
      final end = Offset(
        bloomCenter.dx + math.cos(theta) * (radius * 0.28),
        bloomCenter.dy + math.sin(theta) * (radius * 0.28),
      );
      canvas.drawLine(start, end, filamentPaint);
      canvas.drawCircle(end, size.width * 0.018, antherPaint);
    }

    // Central green seed pod (soft muted green with botanical star cap)
    final podPaint = Paint()
      ..color = const Color(0xFF6E8E6A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bloomCenter, radius * 0.16, podPaint);

    // Star-spoked disc atop the poppy pod
    final capPaint = Paint()
      ..color = const Color(0xFF486345)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int k = 0; k < 6; k++) {
      final theta = (k * math.pi) / 6;
      canvas.drawLine(
        Offset(bloomCenter.dx - math.cos(theta) * (radius * 0.14), bloomCenter.dy - math.sin(theta) * (radius * 0.14)),
        Offset(bloomCenter.dx + math.cos(theta) * (radius * 0.14), bloomCenter.dy + math.sin(theta) * (radius * 0.14)),
        capPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PoppyBotanicalPainter oldDelegate) {
    return oldDelegate.petalColor != petalColor || oldDelegate.showStem != showStem;
  }
}
