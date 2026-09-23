import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/poppy_doodle.dart';

/// Empty state display when no books match or the shelf is empty.
///
/// Features a handcrafted open leather-bound journal vector illustration
/// with a delicate blush poppy resting beside it, accompanied by warm literary copy.
class LibraryEmptyState extends StatelessWidget {
  final VoidCallback? onAddBook;
  final String? title;
  final String? subtitle;
  final String? buttonLabel;

  const LibraryEmptyState({
    super.key,
    this.onAddBook,
    this.title,
    this.subtitle,
    this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.2),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Open Leather Book & Poppy Illustration
          SizedBox(
            width: 170,
            height: 95,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Open Leather-bound Book Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LeatherOpenBookPainter(),
                  ),
                ),
                // Poppy resting gracefully beside the open pages
                const Positioned(
                  right: -10,
                  top: -24,
                  child: PoppyDoodle(
                    size: 72,
                    showStem: true,
                    petalColor: FloralPalette.rosePetal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Heading
          Text(
            title ?? 'Your shelf is waiting for its first story',
            textAlign: TextAlign.center,
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
          ),

          const SizedBox(height: 8),

          // Handwritten hint in Caveat using Cocoa accent
          Text(
            subtitle ?? 'add a favorite book or one you wish to read ~',
            textAlign: TextAlign.center,
            style: JournalTypography.handwriting(color: FloralPalette.cocoa),
          ),

          if (onAddBook != null) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onAddBook,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text(buttonLabel ?? 'Add a Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeatherOpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Leather cover underlay in rich Cocoa
    final coverUnderlay = Paint()
      ..color = FloralPalette.cocoa
      ..style = PaintingStyle.fill;

    final leatherStroke = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 0.95
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pageFill = Paint()
      ..color = FloralPalette.kraftPaper
      ..style = PaintingStyle.fill;

    final pageStroke = Paint()
      ..color = FloralPalette.latte
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = FloralPalette.latte.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midX = size.width * 0.46;
    final spineY = size.height * 0.25;
    final bottomY = size.height * 0.88;

    // Leather cover underlay (peeking out beneath pages)
    final coverPath = Path();
    coverPath.moveTo(midX, spineY + 4);
    coverPath.cubicTo(midX - 30, spineY - 4, midX - 65, spineY - 2, 8, spineY + 14);
    coverPath.lineTo(6, bottomY + 6);
    coverPath.cubicTo(midX - 65, bottomY + 2, midX - 30, bottomY + 4, midX, bottomY + 6);
    coverPath.cubicTo(midX + 30, bottomY + 4, midX + 65, bottomY + 2, size.width - 6, bottomY + 6);
    coverPath.lineTo(size.width - 8, spineY + 14);
    coverPath.cubicTo(midX + 65, spineY - 2, midX + 30, spineY - 4, midX, spineY + 4);
    canvas.drawPath(coverPath, coverUnderlay);
    canvas.drawPath(coverPath, leatherStroke);

    // Left Page (Kraft Paper fill)
    final leftPage = Path();
    leftPage.moveTo(midX, spineY);
    leftPage.cubicTo(midX - 25, spineY - 6, midX - 55, spineY - 4, 12, spineY + 10);
    leftPage.lineTo(12, bottomY);
    leftPage.cubicTo(midX - 55, bottomY - 6, midX - 25, bottomY - 8, midX, bottomY);
    leftPage.close();
    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(leftPage, pageStroke);

    // Right Page (Kraft Paper fill)
    final rightPage = Path();
    rightPage.moveTo(midX, spineY);
    rightPage.cubicTo(midX + 25, spineY - 6, midX + 55, spineY - 4, size.width - 12, spineY + 10);
    rightPage.lineTo(size.width - 12, bottomY);
    rightPage.cubicTo(midX + 55, bottomY - 6, midX + 25, bottomY - 8, midX, bottomY);
    rightPage.close();
    canvas.drawPath(rightPage, pageFill);
    canvas.drawPath(rightPage, pageStroke);

    // Center Spine shadow in Cocoa
    final spinePaint = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(midX, spineY), Offset(midX, bottomY), spinePaint);

    // Faint simulated text lines on pages in Latte
    for (int i = 0; i < 3; i++) {
      final y = spineY + 18.0 + (i * 12.0);
      // Left lines
      canvas.drawLine(Offset(24, y + 2), Offset(midX - 16, y - 1), linePaint);
      // Right lines
      canvas.drawLine(Offset(midX + 16, y - 1), Offset(size.width - 24, y + 2), linePaint);
    }

    // Small caramel bookmark ribbon resting across the left page
    final ribbonPaint = Paint()
      ..color = FloralPalette.caramel
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final ribbonPath = Path();
    ribbonPath.moveTo(midX, spineY + 2);
    ribbonPath.cubicTo(midX - 15, spineY + 18, midX - 28, spineY + 28, midX - 20, bottomY - 10);
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _LeatherOpenBookPainter oldDelegate) => false;
}
