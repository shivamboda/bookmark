import 'package:flutter/material.dart';
import '../core/theme/palette.dart';

/// A handcrafted botanical bookmark ribbon doodle drawn via CustomPainter.
///
/// Features a satin ribbon in caramel and cocoa with an inverted-V notch
/// and delicate highlight, used for book headers, detail cards, and quote corners.
class BookmarkRibbonDoodle extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;
  final Color? outlineColor;

  const BookmarkRibbonDoodle({
    super.key,
    this.width = 16,
    this.height = 38,
    this.color,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BookmarkRibbonPainter(
          fillColor: color ?? FloralPalette.caramel,
          strokeColor: outlineColor ?? FloralPalette.cocoa,
        ),
      ),
    );
  }
}

class _BookmarkRibbonPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  _BookmarkRibbonPainter({
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ribbonFill = Paint()
      ..shader = LinearGradient(
        colors: [fillColor, FloralPalette.cocoa],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final ribbonStroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final ribbonPath = Path();
    ribbonPath.moveTo(0, 0);
    ribbonPath.lineTo(size.width, 0);
    ribbonPath.lineTo(size.width, size.height * 0.88);
    // Inverted V-cut notch at bottom
    ribbonPath.lineTo(size.width * 0.5, size.height * 0.70);
    ribbonPath.lineTo(0, size.height * 0.88);
    ribbonPath.close();

    canvas.drawPath(ribbonPath, ribbonFill);
    canvas.drawPath(ribbonPath, ribbonStroke);

    // Subtle satin highlight down center
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.42, 0),
      Offset(size.width * 0.42, size.height * 0.72),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BookmarkRibbonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.strokeColor != strokeColor;
  }
}
