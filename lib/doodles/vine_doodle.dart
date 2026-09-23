import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical vine border or horizontal flourish drawn via CustomPainter.
///
/// Features a gentle organic curving stem, alternating sage green leaves,
/// and delicate curlicue tendrils for dividing sections or framing cards.
class VineBorderDoodle extends StatelessWidget {
  final double width;
  final double height;
  final Color? stemColor;
  final Color? leafColor;

  const VineBorderDoodle({
    super.key,
    required this.width,
    this.height = 24,
    this.stemColor,
    this.leafColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _VineBorderPainter(
          stemColor: stemColor ?? FloralPalette.deepForestGreen,
          leafColor: leafColor ?? FloralPalette.sageGreen,
        ),
      ),
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
      ..color = stemColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = leafColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = stemColor.withValues(alpha: 0.7)
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
      final yOffset = (i % 2 == 0 ? -1 : 1) * (size.height * 0.28);

      vinePath.quadraticBezierTo(
        midX, size.height * 0.5 + yOffset,
        endX, size.height * 0.5,
      );
    }
    canvas.drawPath(vinePath, stemPaint);

    // Leaves placed along the crests and valleys
    for (int i = 0; i < waves; i++) {
      final midX = i * waveWidth + waveWidth * 0.5;
      final isUp = i % 2 == 0;
      final leafY = size.height * 0.5 + (isUp ? -size.height * 0.24 : size.height * 0.24);

      canvas.save();
      canvas.translate(midX, leafY);
      canvas.rotate(isUp ? -0.4 : 0.4);

      final leaf = Path();
      leaf.moveTo(0, 0);
      leaf.cubicTo(
        -5, isUp ? -10 : 10,
        14, isUp ? -14 : 14,
        18, 0,
      );
      leaf.cubicTo(
        14, isUp ? 8 : -8,
        5, isUp ? 4 : -4,
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
