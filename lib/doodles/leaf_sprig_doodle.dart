import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted sweet botanical leaf sprig doodle drawn via CustomPainter.
///
/// Features authentic botanical details matching Poppy, Tulip, and Daisy:
/// - Slender curving stem with natural organic taper
/// - 5 plump, hand-inked sage leaves (2 pairs + terminal crown leaf)
/// - Delicate central leaf veins for rich sketchbook craftsmanship
/// - Warm berry accents at leaf nodes echoing the floral palette
class LeafSprigDoodle extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? leafColor;

  const LeafSprigDoodle({
    super.key,
    this.size = 26,
    this.color,
    this.leafColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeafSprigPainter(
          stemColor: color ?? FloralPalette.deepForestGreen,
          leafFillColor: leafColor ?? FloralPalette.sageGreen,
        ),
      ),
    );
  }
}

class _LeafSprigPainter extends CustomPainter {
  final Color stemColor;
  final Color leafFillColor;

  _LeafSprigPainter({
    required this.stemColor,
    required this.leafFillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Curving Central Stem
    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = math.max(1.3, w * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(w * 0.44, h * 0.92);
    stemPath.quadraticBezierTo(w * 0.46, h * 0.56, w * 0.52, h * 0.22);
    canvas.drawPath(stemPath, stemPaint);

    // 2. Leaf Drawing Helper
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          leafFillColor.withValues(alpha: 0.95),
          const Color(0xFF7A9A72),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = stemColor
      ..strokeWidth = math.max(1.1, w * 0.042)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final veinPaint = Paint()
      ..color = stemColor.withValues(alpha: 0.6)
      ..strokeWidth = math.max(0.8, w * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawLeaf({
      required Offset base,
      required Offset tip,
      required Offset leftControl,
      required Offset rightControl,
    }) {
      final path = Path();
      path.moveTo(base.dx, base.dy);
      path.quadraticBezierTo(leftControl.dx, leftControl.dy, tip.dx, tip.dy);
      path.quadraticBezierTo(rightControl.dx, rightControl.dy, base.dx, base.dy);
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);

      // Central vein
      final veinPath = Path();
      veinPath.moveTo(base.dx, base.dy);
      final midX = (base.dx + tip.dx) * 0.5;
      final midY = (base.dy + tip.dy) * 0.5;
      veinPath.quadraticBezierTo(midX, midY, tip.dx * 0.9 + base.dx * 0.1, tip.dy * 0.9 + base.dy * 0.1);
      canvas.drawPath(veinPath, veinPaint);
    }

    // 3. Five Botanical Leaves
    // Lower Left Leaf
    drawLeaf(
      base: Offset(w * 0.45, h * 0.74),
      tip: Offset(w * 0.14, h * 0.62),
      leftControl: Offset(w * 0.22, h * 0.54),
      rightControl: Offset(w * 0.32, h * 0.78),
    );

    // Lower Right Leaf
    drawLeaf(
      base: Offset(w * 0.47, h * 0.66),
      tip: Offset(w * 0.86, h * 0.54),
      leftControl: Offset(w * 0.72, h * 0.46),
      rightControl: Offset(w * 0.68, h * 0.70),
    );

    // Mid Left Leaf
    drawLeaf(
      base: Offset(w * 0.48, h * 0.48),
      tip: Offset(w * 0.18, h * 0.36),
      leftControl: Offset(w * 0.28, h * 0.28),
      rightControl: Offset(w * 0.36, h * 0.50),
    );

    // Mid Right Leaf
    drawLeaf(
      base: Offset(w * 0.50, h * 0.40),
      tip: Offset(w * 0.82, h * 0.26),
      leftControl: Offset(w * 0.72, h * 0.18),
      rightControl: Offset(w * 0.66, h * 0.42),
    );

    // Terminal Apex Crown Leaf
    drawLeaf(
      base: Offset(w * 0.52, h * 0.22),
      tip: Offset(w * 0.52, h * 0.06),
      leftControl: Offset(w * 0.38, h * 0.13),
      rightControl: Offset(w * 0.66, h * 0.13),
    );

    // 4. Botanical Warm Berry Accents at Node Junctions
    final berryPaint = Paint()
      ..color = FloralPalette.rosePetal
      ..style = PaintingStyle.fill;
    final berryOutline = Paint()
      ..color = const Color(0xFF7A161C).withValues(alpha: 0.8)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final berry1 = Offset(w * 0.42, h * 0.58);
    final berry2 = Offset(w * 0.56, h * 0.45);
    final berryRadius = math.max(1.8, w * 0.065);

    canvas.drawCircle(berry1, berryRadius, berryPaint);
    canvas.drawCircle(berry1, berryRadius, berryOutline);

    canvas.drawCircle(berry2, berryRadius * 0.85, berryPaint);
    canvas.drawCircle(berry2, berryRadius * 0.85, berryOutline);
  }

  @override
  bool shouldRepaint(covariant _LeafSprigPainter oldDelegate) {
    return oldDelegate.stemColor != stemColor ||
        oldDelegate.leafFillColor != leafFillColor;
  }
}
