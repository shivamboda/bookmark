import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted drifting petal scatter motif drawn via CustomPainter.
///
/// Features whimsical, floating poppy petals and leaf buds drifting
/// across the canvas with varying rotations, scales, and soft watercolor opacities.
class PetalScatterDoodle extends StatelessWidget {
  final double width;
  final double height;
  final Color? petalColor;

  const PetalScatterDoodle({
    super.key,
    required this.width,
    required this.height,
    this.petalColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PetalScatterPainter(
          petalColor: petalColor ?? FloralPalette.poppyRed,
        ),
      ),
    );
  }
}

class _PetalScatterPainter extends CustomPainter {
  final Color petalColor;

  _PetalScatterPainter({required this.petalColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 5 drifting petals at artistic fixed offsets for repeatable charm
    final petals = [
      _PetalSpec(x: 0.15, y: 0.25, scale: 0.85, angle: 0.4, opacity: 0.75),
      _PetalSpec(x: 0.45, y: 0.15, scale: 0.65, angle: -0.6, opacity: 0.60),
      _PetalSpec(x: 0.82, y: 0.38, scale: 1.05, angle: 0.8, opacity: 0.85),
      _PetalSpec(x: 0.30, y: 0.75, scale: 0.70, angle: -0.2, opacity: 0.65),
      _PetalSpec(x: 0.68, y: 0.82, scale: 0.90, angle: 0.3, opacity: 0.80),
    ];

    for (final p in petals) {
      final center = Offset(size.width * p.x, size.height * p.y);
      final radius = 14.0 * p.scale;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(p.angle);

      final fillPaint = Paint()
        ..color = petalColor.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = FloralPalette.poppyRedDark.withValues(alpha: p.opacity * 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final petal = Path();
      petal.moveTo(0, 0);
      petal.cubicTo(
        -radius * 0.8, -radius * 0.5,
        -radius * 0.9, -radius * 1.2,
        0, -radius * 1.3,
      );
      petal.cubicTo(
        radius * 0.9, -radius * 1.2,
        radius * 0.8, -radius * 0.5,
        0, 0,
      );
      petal.close();

      canvas.drawPath(petal, fillPaint);
      canvas.drawPath(petal, strokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalScatterPainter oldDelegate) {
    return oldDelegate.petalColor != petalColor;
  }
}

class _PetalSpec {
  final double x;
  final double y;
  final double scale;
  final double angle;
  final double opacity;

  const _PetalSpec({
    required this.x,
    required this.y,
    required this.scale,
    required this.angle,
    required this.opacity,
  });
}

