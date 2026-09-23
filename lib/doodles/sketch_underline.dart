import 'package:flutter/material.dart';

/// A handcrafted, organic pen/brush underline drawn via CustomPainter.
///
/// Adds an authentic journal / botanical notebook feel beneath titles
/// with natural variations in stroke width and a gentle curve.
class HandDrawnUnderline extends StatelessWidget {
  final double width;
  final Color? color;
  final double strokeWidth;

  const HandDrawnUnderline({
    super.key,
    required this.width,
    this.color,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 14,
      child: CustomPaint(
        painter: _UnderlinePainter(
          color: color ?? const Color(0xFFE88FA6),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _UnderlinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.cubicTo(
      size.width * 0.28, size.height * 0.1,
      size.width * 0.65, size.height * 0.85,
      size.width, size.height * 0.35,
    );

    canvas.drawPath(path, paint);

    // Subtle second faint stroke for layered ink texture
    final faintPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = strokeWidth * 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final faintPath = Path();
    faintPath.moveTo(size.width * 0.15, size.height * 0.55);
    faintPath.cubicTo(
      size.width * 0.45, size.height * 0.35,
      size.width * 0.75, size.height * 0.75,
      size.width * 0.95, size.height * 0.45,
    );
    canvas.drawPath(faintPath, faintPaint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
