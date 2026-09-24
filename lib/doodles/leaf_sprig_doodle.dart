import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical leaf sprig doodle drawn via CustomPainter.
///
/// Features a delicate arched stem with alternating sage green leaves,
/// used for the Settings tab icon and delicate botanical flourishes.
class LeafSprigDoodle extends StatelessWidget {
  final double size;
  final Color? color;

  const LeafSprigDoodle({
    super.key,
    this.size = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeafSprigPainter(
          color: color ?? FloralPalette.deepForestGreen,
        ),
      ),
    );
  }
}

class _LeafSprigPainter extends CustomPainter {
  final Color color;

  _LeafSprigPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = math.max(1.4, size.width * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = FloralPalette.sageGreen.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Arched stem from bottom left to top right
    final stemPath = Path();
    stemPath.moveTo(size.width * 0.2, size.height * 0.85);
    stemPath.quadraticBezierTo(
      size.width * 0.45, size.height * 0.55,
      size.width * 0.8, size.height * 0.18,
    );
    canvas.drawPath(stemPath, stemPaint);

    // 4 alternating leaf pairs
    final leafSpecs = [
      _SprigLeaf(t: 0.35, isLeft: true, angle: -0.6, scale: 0.8),
      _SprigLeaf(t: 0.50, isLeft: false, angle: 0.6, scale: 0.85),
      _SprigLeaf(t: 0.68, isLeft: true, angle: -0.5, scale: 0.9),
      _SprigLeaf(t: 0.82, isLeft: false, angle: 0.5, scale: 0.8),
    ];

    for (final spec in leafSpecs) {
      final t = spec.t;
      // Quadratic bezier evaluation
      final p0 = Offset(size.width * 0.2, size.height * 0.85);
      final p1 = Offset(size.width * 0.45, size.height * 0.55);
      final p2 = Offset(size.width * 0.8, size.height * 0.18);

      final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
      final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spec.angle);

      final leaf = Path();
      leaf.moveTo(0, 0);
      leaf.cubicTo(
        -size.width * 0.08 * spec.scale, -size.width * 0.12 * spec.scale,
        -size.width * 0.04 * spec.scale, -size.width * 0.22 * spec.scale,
        0, -size.width * 0.26 * spec.scale,
      );
      leaf.cubicTo(
        size.width * 0.04 * spec.scale, -size.width * 0.22 * spec.scale,
        size.width * 0.08 * spec.scale, -size.width * 0.12 * spec.scale,
        0, 0,
      );
      leaf.close();

      canvas.drawPath(leaf, leafFill);
      canvas.drawPath(leaf, leafStroke);
      canvas.restore();
    }

    // Terminal leaf at the tip
    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.18);
    canvas.rotate(0.7);

    final tipLeaf = Path();
    tipLeaf.moveTo(0, 0);
    tipLeaf.cubicTo(-2, -6, -2, -10, 0, -12);
    tipLeaf.cubicTo(2, -10, 2, -6, 0, 0);
    tipLeaf.close();

    canvas.drawPath(tipLeaf, leafFill);
    canvas.drawPath(tipLeaf, leafStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LeafSprigPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SprigLeaf {
  final double t;
  final bool isLeft;
  final double angle;
  final double scale;

  const _SprigLeaf({
    required this.t,
    required this.isLeft,
    required this.angle,
    required this.scale,
  });
}
