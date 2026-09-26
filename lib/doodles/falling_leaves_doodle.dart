import 'package:flutter/material.dart';
import '../core/theme/palette.dart';
import 'acorn_doodle.dart';
import 'maple_leaf_doodle.dart';
import 'oak_leaf_doodle.dart';

/// A handcrafted drifting autumn leaves cascade with gentle wind swirls.
///
/// Features authentic autumnal botanical details:
/// - Floating miniature maple leaf, oak leaf, and acorn at natural drifting angles
/// - Delicate dotted wind breeze swirls connecting the falling elements
/// - Perfect for library headers, empty states, and reading milestone celebrations
class FallingLeavesDoodle extends StatelessWidget {
  final double width;
  final double height;

  const FallingLeavesDoodle({
    super.key,
    this.width = 320,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dotted Autumn Breeze Line
          Positioned.fill(
            child: CustomPaint(
              painter: _AutumnBreezePainter(),
            ),
          ),

          // 1. Maple Leaf (Drifting Top-Left)
          Positioned(
            left: width * 0.08,
            top: height * 0.08,
            child: const MapleLeafDoodle(
              size: 34,
              color: FloralPalette.rosePetal, // Pumpkin
              angle: -0.35,
            ),
          ),

          // 2. Oak Leaf (Drifting Mid-Center)
          Positioned(
            left: width * 0.42,
            top: height * 0.18,
            child: OakLeafDoodle(
              size: 32,
              color: FloralPalette.buttercupGold, // Golden Amber
              angle: 0.42,
            ),
          ),

          // 3. Little Acorn (Tucked Mid-Right)
          Positioned(
            left: width * 0.68,
            top: height * 0.10,
            child: const AcornDoodle(
              size: 26,
              angle: -0.22,
            ),
          ),

          // 4. Secondary Petite Maple (Floating Far-Right)
          Positioned(
            right: width * 0.06,
            top: height * 0.28,
            child: MapleLeafDoodle(
              size: 26,
              color: FloralPalette.deepRose, // Rust
              angle: 0.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutumnBreezePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final breezePaint = Paint()
      ..color = FloralPalette.latte.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(w * 0.02, h * 0.40);
    path.cubicTo(
      w * 0.25, h * 0.10,
      w * 0.40, h * 0.70,
      w * 0.65, h * 0.35,
    );
    path.cubicTo(
      w * 0.80, h * 0.15,
      w * 0.90, h * 0.50,
      w * 0.98, h * 0.38,
    );

    // Draw dashed path
    final dashArray = [4.0, 5.0];
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final length = dashArray[0];
        final segment = metric.extractPath(distance, distance + length);
        canvas.drawPath(segment, breezePaint);
        distance += length + dashArray[1];
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
