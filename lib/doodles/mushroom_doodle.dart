import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted woodland mushroom doodle drawn via CustomPainter.
///
/// Features authentic autumnal botanical details:
/// - Rounded umbrella toadstool cap in rich Poppy Ember or Rust
/// - Soft cream specks and gill rim
/// - Graceful curved stalk in soft cream/latte with ring collar
/// - Little forest moss blades at base
class MushroomDoodle extends StatelessWidget {
  final double size;
  final Color? capColor;
  final Color? stemColor;
  final double angle;

  const MushroomDoodle({
    super.key,
    this.size = 56,
    this.capColor,
    this.stemColor,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeSize = size.isFinite && size > 0 ? size : 56.0;
    final cap = capColor ?? FloralPalette.poppyRed;
    final stem = stemColor ?? FloralPalette.softIvory;

    Widget mushroom = SizedBox(
      width: safeSize * 0.85,
      height: safeSize,
      child: CustomPaint(
        painter: _MushroomPainter(
          capColor: cap,
          stemColor: stem,
        ),
      ),
    );

    if (angle != 0) {
      mushroom = Transform.rotate(
        angle: angle,
        child: mushroom,
      );
    }

    return mushroom;
  }
}

class _MushroomPainter extends CustomPainter {
  final Color capColor;
  final Color stemColor;

  _MushroomPainter({
    required this.capColor,
    required this.stemColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // 1. Moss blades at base
    final mossPaint = Paint()
      ..color = FloralPalette.sageGreenDark
      ..strokeWidth = math.max(1.4, w * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final moss1 = Path();
    moss1.moveTo(cx - w * 0.28, h * 0.98);
    moss1.quadraticBezierTo(cx - w * 0.24, h * 0.86, cx - w * 0.32, h * 0.82);
    canvas.drawPath(moss1, mossPaint);

    final moss2 = Path();
    moss2.moveTo(cx + w * 0.26, h * 0.98);
    moss2.quadraticBezierTo(cx + w * 0.22, h * 0.85, cx + w * 0.30, h * 0.80);
    canvas.drawPath(moss2, mossPaint);

    // 2. Stalk (Stem)
    final stalkPath = Path();
    stalkPath.moveTo(cx - w * 0.14, h * 0.46);
    stalkPath.cubicTo(
      cx - w * 0.16, h * 0.65,
      cx - w * 0.22, h * 0.86,
      cx - w * 0.20, h * 0.98,
    );
    stalkPath.lineTo(cx + w * 0.20, h * 0.98);
    stalkPath.cubicTo(
      cx + w * 0.22, h * 0.86,
      cx + w * 0.16, h * 0.65,
      cx + w * 0.14, h * 0.46,
    );
    stalkPath.close();

    final stalkFill = Paint()
      ..color = stemColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(stalkPath, stalkFill);

    final stalkOutline = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = math.max(1.3, w * 0.026)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(stalkPath, stalkOutline);

    // Subtle Stalk Ring Collar
    final ringPaint = Paint()
      ..color = FloralPalette.caramel
      ..strokeWidth = math.max(1.1, w * 0.02)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - w * 0.14, h * 0.64),
      Offset(cx + w * 0.14, h * 0.64),
      ringPaint,
    );

    // 3. Mushroom Cap
    final capPath = Path();
    capPath.moveTo(w * 0.06, h * 0.48);
    // Umbrella dome
    capPath.cubicTo(
      w * 0.04, h * 0.08,
      w * 0.96, h * 0.08,
      w * 0.94, h * 0.48,
    );
    // Bottom gill rim
    capPath.cubicTo(
      w * 0.70, h * 0.54,
      w * 0.30, h * 0.54,
      w * 0.06, h * 0.48,
    );
    capPath.close();

    final capFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          capColor,
          FloralPalette.deepRose,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.54))
      ..style = PaintingStyle.fill;
    canvas.drawPath(capPath, capFill);

    // Cap Outline
    final capOutline = Paint()
      ..color = FloralPalette.espresso
      ..strokeWidth = math.max(1.5, w * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(capPath, capOutline);

    // 4. Little Cream Dots on Cap
    final dotPaint = Paint()
      ..color = FloralPalette.softIvory.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, h * 0.22), w * 0.048, dotPaint);
    canvas.drawCircle(Offset(cx - w * 0.22, h * 0.32), w * 0.040, dotPaint);
    canvas.drawCircle(Offset(cx + w * 0.24, h * 0.30), w * 0.042, dotPaint);
    canvas.drawCircle(Offset(cx - w * 0.10, h * 0.38), w * 0.032, dotPaint);
    canvas.drawCircle(Offset(cx + w * 0.12, h * 0.39), w * 0.035, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MushroomPainter oldDelegate) =>
      oldDelegate.capColor != capColor || oldDelegate.stemColor != stemColor;
}
