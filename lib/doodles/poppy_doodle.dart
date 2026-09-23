import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical poppy sketch drawn via CustomPainter.
///
/// Features authentic botanical details:
/// - Opaque crinkled petals with radial gradient (deep crimson center to light poppy tips)
/// - Dark plum blotches at petal bases
/// - Small green seed pod with dark stamen filaments and golden pollen anthers
/// - Correct z-order: stem and separate budding stalk drawn behind the bloom
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
    // Coordinate anchor center for main bloom
    final bloomCenterX = size.width * 0.50;
    final bloomCenterY = showStem ? size.height * 0.38 : size.height * 0.50;
    final bloomRadius = size.width * 0.38;

    // Palette Colors
    final deepCrimson = Color.lerp(petalColor, const Color(0xFF8B121A), 0.55)!;
    final coralEdge = Color.lerp(petalColor, const Color(0xFFFFA094), 0.35)!;
    const blotchColor = Color(0xFF260D15); // Dark plum blotch at petal base
    const stemColor = FloralPalette.deepForestGreen;
    const podGreen = Color(0xFF5E8256);
    const podHighlight = Color(0xFF90B584);
    const stamenDark = Color(0xFF1F1216);
    const pollenGold = FloralPalette.buttercupYellow;
    const contourInk = Color(0xFF38151E); // Crisp contour outline

    // ==========================================
    // 1. STEMS & LEAF (DRAWN BEHIND BLOOM)
    // ==========================================
    if (showStem) {
      final stemPaint = Paint()
        ..color = stemColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.038).clamp(2.0, 3.8)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Main Stem
      final stemPath = Path();
      stemPath.moveTo(bloomCenterX, bloomCenterY + 4);
      stemPath.cubicTo(
        bloomCenterX - size.width * 0.06, size.height * 0.55,
        bloomCenterX + size.width * 0.05, size.height * 0.78,
        bloomCenterX - size.width * 0.03, size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);

      // Separate Budding Stalk (distinct from main stem)
      final budStalkPath = Path();
      budStalkPath.moveTo(bloomCenterX + size.width * 0.02, size.height * 0.65);
      budStalkPath.cubicTo(
        bloomCenterX + size.width * 0.22, size.height * 0.58,
        bloomCenterX + size.width * 0.32, size.height * 0.44,
        bloomCenterX + size.width * 0.36, size.height * 0.38,
      );
      final budStalkPaint = Paint()
        ..color = stemColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.025).clamp(1.5, 2.6)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(budStalkPath, budStalkPaint);

      // Drooping Poppy Bud at the end of budding stalk
      final budCenter = Offset(bloomCenterX + size.width * 0.36, size.height * 0.38);
      final budPaint = Paint()
        ..color = podGreen
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: budCenter, width: size.width * 0.11, height: size.width * 0.16),
        budPaint,
      );
      // Faint hint of red petal peeking from bud tip
      final budPetal = Paint()
        ..color = petalColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(budCenter.translate(0, -size.width * 0.06), size.width * 0.03, budPetal);

      // Attached Serrated Leaf on main stem
      final leafStemX = bloomCenterX - size.width * 0.03;
      final leafStemY = size.height * 0.68;
      final leafPath = Path();
      leafPath.moveTo(leafStemX, leafStemY);
      leafPath.cubicTo(
        leafStemX - size.width * 0.18, leafStemY - size.height * 0.05,
        leafStemX - size.width * 0.32, leafStemY + size.height * 0.02,
        leafStemX - size.width * 0.38, leafStemY + size.height * 0.12,
      );
      leafPath.cubicTo(
        leafStemX - size.width * 0.22, leafStemY + size.height * 0.11,
        leafStemX - size.width * 0.12, leafStemY + size.height * 0.08,
        leafStemX, leafStemY + size.height * 0.04,
      );
      leafPath.close();

      final leafPaint = Paint()
        ..color = FloralPalette.sageGreenDark
        ..style = PaintingStyle.fill;
      canvas.drawPath(leafPath, leafPaint);
    }

    // ==========================================
    // 2. OPAQUE PETALS WITH WAVY EDGES & GRADIENT
    // ==========================================
    final petalAngles = [-0.75, 0.75, 2.35, -2.35];

    for (int i = 0; i < petalAngles.length; i++) {
      final angle = petalAngles[i];
      final petalCenter = Offset(
        bloomCenterX + (bloomRadius * 0.42 * math.cos(angle)),
        bloomCenterY + (bloomRadius * 0.42 * math.sin(angle)),
      );

      final petalPath = Path();
      petalPath.moveTo(bloomCenterX, bloomCenterY);

      final tipX = bloomCenterX + (bloomRadius * 1.15 * math.cos(angle));
      final tipY = bloomCenterY + (bloomRadius * 1.15 * math.sin(angle));

      final perpX = -math.sin(angle) * (bloomRadius * 0.75);
      final perpY = math.cos(angle) * (bloomRadius * 0.75);

      petalPath.cubicTo(
        bloomCenterX + perpX * 0.8, bloomCenterY + perpY * 0.8,
        tipX + perpX * 0.6, tipY + perpY * 0.6,
        tipX, tipY,
      );
      petalPath.cubicTo(
        tipX - perpX * 0.6, tipY - perpY * 0.6,
        bloomCenterX - perpX * 0.8, bloomCenterY - perpY * 0.8,
        bloomCenterX, bloomCenterY,
      );
      petalPath.close();

      final gradientPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [deepCrimson, petalColor, coralEdge],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: petalCenter, radius: bloomRadius * 1.1))
        ..style = PaintingStyle.fill;

      canvas.drawPath(petalPath, gradientPaint);

      final outlinePaint = Paint()
        ..color = contourInk.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(petalPath, outlinePaint);
    }

    // ==========================================
    // 3. DARK PLUM BASAL BLOTCHES
    // ==========================================
    final blotchPaint = Paint()
      ..color = blotchColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final bAngle = i * (math.pi / 3.0);
      final blotchOffset = Offset(
        bloomCenterX + (bloomRadius * 0.22 * math.cos(bAngle)),
        bloomCenterY + (bloomRadius * 0.22 * math.sin(bAngle)),
      );
      canvas.drawCircle(blotchOffset, bloomRadius * 0.14, blotchPaint);
    }

    // ==========================================
    // 4. STAMENS & POLLEN ANTHERS (RING)
    // ==========================================
    final stamenFilament = Paint()
      ..color = stamenDark
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final pollenPaint = Paint()
      ..color = pollenGold
      ..style = PaintingStyle.fill;

    const stamenCount = 14;
    for (int i = 0; i < stamenCount; i++) {
      final sAngle = i * (2 * math.pi / stamenCount);
      final start = Offset(
        bloomCenterX + (bloomRadius * 0.18 * math.cos(sAngle)),
        bloomCenterY + (bloomRadius * 0.18 * math.sin(sAngle)),
      );
      final end = Offset(
        bloomCenterX + (bloomRadius * 0.36 * math.cos(sAngle)),
        bloomCenterY + (bloomRadius * 0.36 * math.sin(sAngle)),
      );
      canvas.drawLine(start, end, stamenFilament);
      canvas.drawCircle(end, (size.width * 0.024).clamp(1.4, 2.4), pollenPaint);
    }

    // ==========================================
    // 5. GREEN SEED POD (CAPSULE) WITH STAR CAP
    // ==========================================
    final podCenter = Offset(bloomCenterX, bloomCenterY);
    final podRadius = bloomRadius * 0.24;

    final podPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [podHighlight, podGreen],
      ).createShader(Rect.fromCircle(center: podCenter, radius: podRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(podCenter, podRadius, podPaint);

    final capLinePaint = Paint()
      ..color = const Color(0xFF2C4328)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final cAngle = i * (math.pi / 3.0);
      final ray = Offset(
        podCenter.dx + (podRadius * 0.85 * math.cos(cAngle)),
        podCenter.dy + (podRadius * 0.85 * math.sin(cAngle)),
      );
      canvas.drawLine(podCenter, ray, capLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PoppyBotanicalPainter oldDelegate) {
    return oldDelegate.petalColor != petalColor || oldDelegate.showStem != showStem;
  }
}
