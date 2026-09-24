import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical oak leaf doodle drawn via CustomPainter.
///
/// Features authentic autumnal botanical details:
/// - Sinuous, rounded undulating lobes characteristic of classic white oak
/// - Warm golden amber to olive sage gradient fill
/// - Central rachis with delicate lateral veins branching into each lobe
/// - Organic hand-drawn pen outline
class OakLeafDoodle extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showStem;
  final double angle;

  const OakLeafDoodle({
    super.key,
    this.size = 64,
    this.color,
    this.showStem = true,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeSize = size.isFinite && size > 0 ? size : 64.0;
    final leafColor = color ?? FloralPalette.buttercupGold;

    Widget leaf = SizedBox(
      width: safeSize * 0.72,
      height: showStem ? safeSize * 1.2 : safeSize,
      child: CustomPaint(
        painter: _OakLeafPainter(
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

class _OakLeafPainter extends CustomPainter {
  final Color color;
  final bool showStem;

  _OakLeafPainter({
    required this.color,
    required this.showStem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = showStem ? size.height * 0.88 : size.height;
    final cx = w * 0.5;
    final base = Offset(cx, h * 0.94);

    // 1. Draw Stem
    if (showStem) {
      final stemPaint = Paint()
        ..color = FloralPalette.cocoa
        ..strokeWidth = math.max(1.8, w * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final stemPath = Path();
      stemPath.moveTo(base.dx, base.dy);
      stemPath.quadraticBezierTo(
        base.dx - w * 0.05,
        size.height * 0.97,
        base.dx - w * 0.03,
        size.height * 1.0,
      );
      canvas.drawPath(stemPath, stemPaint);
    }

    // 2. Sinuous Lobed Leaf Contour
    final leafPath = Path();
    leafPath.moveTo(base.dx, base.dy);

    // Left lobes (from bottom to top)
    // Lobe 1 (basal small)
    leafPath.cubicTo(w * 0.28, h * 0.90, w * 0.12, h * 0.84, w * 0.16, h * 0.77);
    leafPath.cubicTo(w * 0.20, h * 0.73, w * 0.32, h * 0.75, w * 0.34, h * 0.71);

    // Lobe 2 (mid-lower)
    leafPath.cubicTo(w * 0.12, h * 0.67, w * 0.04, h * 0.58, w * 0.10, h * 0.50);
    leafPath.cubicTo(w * 0.16, h * 0.45, w * 0.32, h * 0.50, w * 0.32, h * 0.44);

    // Lobe 3 (upper broad)
    leafPath.cubicTo(w * 0.10, h * 0.38, w * 0.08, h * 0.26, w * 0.18, h * 0.20);
    leafPath.cubicTo(w * 0.26, h * 0.16, w * 0.36, h * 0.22, w * 0.40, h * 0.18);

    // Apex rounded tip
    leafPath.cubicTo(w * 0.42, h * 0.08, w * 0.46, h * 0.02, cx, h * 0.02);
    leafPath.cubicTo(w * 0.54, h * 0.02, w * 0.58, h * 0.08, w * 0.60, h * 0.18);

    // Right lobes (from top to bottom)
    // Lobe 3 (upper broad)
    leafPath.cubicTo(w * 0.64, h * 0.22, w * 0.74, h * 0.16, w * 0.82, h * 0.20);
    leafPath.cubicTo(w * 0.92, h * 0.26, w * 0.90, h * 0.38, w * 0.68, h * 0.44);

    // Lobe 2 (mid-lower)
    leafPath.cubicTo(w * 0.68, h * 0.50, w * 0.84, h * 0.45, w * 0.90, h * 0.50);
    leafPath.cubicTo(w * 0.96, h * 0.58, w * 0.88, h * 0.67, w * 0.66, h * 0.71);

    // Lobe 1 (basal small)
    leafPath.cubicTo(w * 0.68, h * 0.75, w * 0.80, h * 0.73, w * 0.84, h * 0.77);
    leafPath.cubicTo(w * 0.88, h * 0.84, w * 0.72, h * 0.90, base.dx, base.dy);
    leafPath.close();

    // 3. Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          FloralPalette.cocoa.withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, fillPaint);

    // 4. Pen Outline
    final outlinePaint = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = math.max(1.2, w * 0.025)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(leafPath, outlinePaint);

    // 5. Veins
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = math.max(1.0, w * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Central main vein
    canvas.drawLine(base, Offset(cx, h * 0.08), veinPaint);

    // Lateral side veins into lobes
    canvas.drawLine(Offset(cx, h * 0.73), Offset(w * 0.22, h * 0.77), veinPaint);
    canvas.drawLine(Offset(cx, h * 0.73), Offset(w * 0.78, h * 0.77), veinPaint);

    canvas.drawLine(Offset(cx, h * 0.52), Offset(w * 0.16, h * 0.50), veinPaint);
    canvas.drawLine(Offset(cx, h * 0.52), Offset(w * 0.84, h * 0.50), veinPaint);

    canvas.drawLine(Offset(cx, h * 0.30), Offset(w * 0.24, h * 0.20), veinPaint);
    canvas.drawLine(Offset(cx, h * 0.30), Offset(w * 0.76, h * 0.20), veinPaint);
  }

  @override
  bool shouldRepaint(covariant _OakLeafPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showStem != showStem;
}
