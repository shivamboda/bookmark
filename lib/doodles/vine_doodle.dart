import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical vine border or horizontal flourish drawn via CustomPainter.
///
/// Features a gentle organic curving stem, alternating sage green leaves connected
/// with delicate tiny stems (petioles), and winding tendrils for dividing sections or framing cards.
class VineBorderDoodle extends StatelessWidget {
  final double? width;
  final double height;
  final Color? stemColor;
  final Color? leafColor;

  const VineBorderDoodle({
    super.key,
    this.width,
    this.height = 24,
    this.stemColor,
    this.leafColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0);
        return SizedBox(
          width: w,
          height: height,
          child: CustomPaint(
            painter: _VineBorderPainter(
              stemColor: stemColor ?? FloralPalette.cocoa,
              leafColor: leafColor ?? FloralPalette.sageGreen,
            ),
          ),
        );
      },
    );
  }
}

class _VineBorderPainter extends CustomPainter {
  final Color stemColor;
  final Color leafColor;

  _VineBorderPainter({
    required this.stemColor,
    required this.leafColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = stemColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = leafColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = stemColor.withValues(alpha: 0.75)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Organic wavy vine stem across the width
    final vinePath = Path();
    vinePath.moveTo(0, size.height * 0.5);

    const waves = 4;
    final waveWidth = size.width / waves;

    for (int i = 0; i < waves; i++) {
      final startX = i * waveWidth;
      final midX = startX + waveWidth * 0.5;
      final endX = startX + waveWidth;
      final yOffset = (i % 2 == 0 ? -1 : 1) * (size.height * 0.26);

      vinePath.quadraticBezierTo(
        midX, size.height * 0.5 + yOffset,
        endX, size.height * 0.5,
      );
    }
    canvas.drawPath(vinePath, stemPaint);

    // Leaves attached with tiny stems (petioles) to the vine
    for (int i = 0; i < waves; i++) {
      final midX = i * waveWidth + waveWidth * 0.5;
      final isUp = i % 2 == 0;
      final vineY = size.height * 0.5 + (isUp ? -size.height * 0.26 : size.height * 0.26);
      final petioleEndY = vineY + (isUp ? -5.0 : 5.0);

      // Draw tiny petiole connecting vine to leaf
      canvas.drawLine(
        Offset(midX, vineY),
        Offset(midX + 2, petioleEndY),
        stemPaint..strokeWidth = 1.1,
      );

      canvas.save();
      canvas.translate(midX + 2, petioleEndY);
      canvas.rotate(isUp ? -0.42 : 0.42);

      final leaf = Path();
      leaf.moveTo(0, 0);
      leaf.cubicTo(
        -4, isUp ? -8 : 8,
        13, isUp ? -13 : 13,
        17, 0,
      );
      leaf.cubicTo(
        13, isUp ? 7 : -7,
        4, isUp ? 3 : -3,
        0, 0,
      );
      leaf.close();

      canvas.drawPath(leaf, leafFill);
      canvas.drawPath(leaf, leafStroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _VineBorderPainter oldDelegate) {
    return oldDelegate.stemColor != stemColor || oldDelegate.leafColor != leafColor;
  }
}
