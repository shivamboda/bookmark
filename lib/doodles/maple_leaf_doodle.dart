import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical maple leaf doodle drawn via CustomPainter.
///
/// Features authentic autumnal botanical details:
/// - Distinctive 5-pointed lobed maple silhouette with serrated sub-tips
/// - Warm autumn gradient fill (from pumpkin amber to deep rust)
/// - Organic hand-drawn pen outline
/// - Central rachis (stem) and radiating palm veins
class MapleLeafDoodle extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showStem;
  final double angle;

  const MapleLeafDoodle({
    super.key,
    this.size = 64,
    this.color,
    this.showStem = true,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeSize = size.isFinite && size > 0 ? size : 64.0;
    final leafColor = color ?? FloralPalette.rosePetal;

    Widget leaf = SizedBox(
      width: safeSize,
      height: showStem ? safeSize * 1.15 : safeSize,
      child: CustomPaint(
        painter: _MapleLeafPainter(
          color: leafColor,
          showStem: showStem,
        ),
      ),
    );

    if (angle != 0) {
      leaf = Transform.rotate(
        angle: angle,
        child: leaf,
      );
    }

    return leaf;
  }
}

class _MapleLeafPainter extends CustomPainter {
  final Color color;
  final bool showStem;

  _MapleLeafPainter({
    required this.color,
    required this.showStem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = showStem ? size.height * 0.88 : size.height;
    final cx = w * 0.5;
    final base = Offset(cx, h * 0.85);

    // 1. Draw Stem
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.deepRose
        ..strokeWidth = math.max(1.8, w * 0.032)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      stemPath.moveTo(base.dx, base.dy);
      stemPath.quadraticBezierTo(
        base.dx + w * 0.04,
        size.height * 0.94,
        base.dx + w * 0.02,
        size.height * 0.98,
      );
      canvas.drawPath(stemPath, stemPaint);
    }

    // 2. Leaf Body Contour
    final leafPath = Path();
    leafPath.moveTo(base.dx, base.dy);

    // Left basal lobe
    leafPath.cubicTo(w * 0.38, h * 0.82, w * 0.28, h * 0.82, w * 0.20, h * 0.72);
    leafPath.lineTo(w * 0.24, h * 0.67);
    leafPath.cubicTo(w * 0.16, h * 0.65, w * 0.10, h * 0.58, w * 0.08, h * 0.52);

    // Left lateral lobe
    leafPath.cubicTo(w * 0.16, h * 0.50, w * 0.24, h * 0.52, w * 0.28, h * 0.46);
    leafPath.cubicTo(w * 0.18, h * 0.40, w * 0.12, h * 0.32, w * 0.14, h * 0.26);
    leafPath.lineTo(w * 0.22, h * 0.29);
    leafPath.cubicTo(w * 0.24, h * 0.22, w * 0.30, h * 0.18, w * 0.36, h * 0.18);
    leafPath.lineTo(w * 0.34, h * 0.25);
    leafPath.cubicTo(w * 0.38, h * 0.28, w * 0.42, h * 0.32, w * 0.44, h * 0.36);

    // Central apex lobe (left side)
    leafPath.cubicTo(w * 0.42, h * 0.24, w * 0.40, h * 0.12, cx, h * 0.04);

    // Central apex lobe (right side)
    leafPath.cubicTo(w * 0.60, h * 0.12, w * 0.58, h * 0.24, w * 0.56, h * 0.36);
    leafPath.cubicTo(w * 0.58, h * 0.32, w * 0.62, h * 0.28, w * 0.66, h * 0.25);
    leafPath.lineTo(w * 0.64, h * 0.18);
    leafPath.cubicTo(w * 0.70, h * 0.18, w * 0.76, h * 0.22, w * 0.78, h * 0.29);
    leafPath.lineTo(w * 0.86, h * 0.26);

    // Right lateral lobe
    leafPath.cubicTo(w * 0.88, h * 0.32, w * 0.82, h * 0.40, w * 0.72, h * 0.46);
    leafPath.cubicTo(w * 0.76, h * 0.52, w * 0.84, h * 0.50, w * 0.92, h * 0.52);
    leafPath.cubicTo(w * 0.90, h * 0.58, w * 0.84, h * 0.65, w * 0.76, h * 0.67);
    leafPath.lineTo(w * 0.80, h * 0.72);

    // Right basal lobe
    leafPath.cubicTo(w * 0.72, h * 0.82, w * 0.62, h * 0.82, base.dx, base.dy);
    leafPath.close();

    // 3. Fill with Warm Autumn Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          FloralPalette.deepRose.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, fillPaint);

    // 4. Subtle Pen Outline
    final outlinePaint = Paint()
      ..color = FloralPalette.deepRose
      ..strokeWidth = math.max(1.2, w * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(leafPath, outlinePaint);

    // 5. Radiating Palm Veins
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = math.max(1.0, w * 0.018)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Central main vein
    canvas.drawLine(base, Offset(cx, h * 0.12), veinPaint);

    // Left lateral vein
    canvas.drawLine(
      base,
      Offset(w * 0.22, h * 0.34),
      veinPaint,
    );

    // Right lateral vein
    canvas.drawLine(
      base,
      Offset(w * 0.78, h * 0.34),
      veinPaint,
    );

    // Left basal vein
    canvas.drawLine(
      base,
      Offset(w * 0.18, h * 0.60),
      veinPaint,
    );

    // Right basal vein
    canvas.drawLine(
      base,
      Offset(w * 0.82, h * 0.60),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapleLeafPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showStem != showStem;
}
