import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical lavender sprig doodle drawn via CustomPainter.
///
/// Features a slender tapering stem adorned with soft, layered lavender florets
/// in delicate watercolor washes and fine ink accents.
class LavenderDoodle extends StatelessWidget {
  final double size;
  final Color? floretColor;

  const LavenderDoodle({
    super.key,
    this.size = 64,
    this.floretColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.6,
      height: size,
      child: CustomPaint(
        painter: _LavenderPainter(
          floretColor: floretColor ?? FloralPalette.lavenderMist,
        ),
      ),
    );
  }
}

class _LavenderPainter extends CustomPainter {
  final Color floretColor;

  _LavenderPainter({required this.floretColor});

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = FloralPalette.deepForestGreen.withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.6, size.height * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gently curving slender stem
    final stemPath = Path();
    stemPath.moveTo(size.width * 0.5, size.height * 0.12);
    stemPath.quadraticBezierTo(
      size.width * 0.45, size.height * 0.55,
      size.width * 0.52, size.height * 0.98,
    );
    canvas.drawPath(stemPath, stemPaint);

    final floretFill = Paint()
      ..color = floretColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final floretAccent = Paint()
      ..color = const Color(0xFF9B82C4).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final floretStroke = Paint()
      ..color = const Color(0xFF7A62A0).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 7 tiers of paired florets tapering toward the tip
    const tiers = 7;
    for (int t = 0; t < tiers; t++) {
      final progress = t / tiers;
      final y = size.height * 0.15 + (progress * size.height * 0.52);
      final floretWidth = size.width * (0.18 + (1.0 - progress) * 0.08);
      final floretHeight = size.height * (0.05 - progress * 0.015);
      final stemX = size.width * 0.5 - (math.sin(progress * math.pi) * 3);

      // Left floret
      canvas.save();
      canvas.translate(stemX - 2, y);
      canvas.rotate(-0.35 + (t % 2 == 0 ? 0.05 : -0.05));
      final leftRect = Rect.fromCenter(
        center: Offset(-floretWidth * 0.8, 0),
        width: floretWidth * 1.6,
        height: floretHeight * 1.5,
      );
      canvas.drawOval(leftRect, t % 2 == 0 ? floretFill : floretAccent);
      canvas.drawOval(leftRect, floretStroke);
      canvas.restore();

      // Right floret
      canvas.save();
      canvas.translate(stemX + 2, y - 2);
      canvas.rotate(0.35 + (t % 2 == 0 ? -0.05 : 0.05));
      final rightRect = Rect.fromCenter(
        center: Offset(floretWidth * 0.8, 0),
        width: floretWidth * 1.6,
        height: floretHeight * 1.5,
      );
      canvas.drawOval(rightRect, t % 2 == 0 ? floretAccent : floretFill);
      canvas.drawOval(rightRect, floretStroke);
      canvas.restore();
    }

    // Top terminal bud
    final tipRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.12),
      width: size.width * 0.18,
      height: size.height * 0.06,
    );
    canvas.drawOval(tipRect, floretFill);
    canvas.drawOval(tipRect, floretStroke);
  }

  @override
  bool shouldRepaint(covariant _LavenderPainter oldDelegate) {
    return oldDelegate.floretColor != floretColor;
  }
}
