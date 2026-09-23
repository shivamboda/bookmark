import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/palette.dart';
import 'daisy_doodle.dart';
import 'lavender_doodle.dart';
import 'petal_scatter_doodle.dart';
import 'poppy_doodle.dart';
import 'sketch_underline.dart';
import 'tulip_doodle.dart';
import 'vine_doodle.dart';

/// Interactive Botanical Doodle Showcase Screen.
///
/// Serves as the central approval gallery for all code-drawn botanical elements,
/// including the signature Poppy, floral companions, flourishes, and warm brown accents.
class DoodleGalleryScreen extends StatelessWidget {
  final VoidCallback onBackToJournal;

  const DoodleGalleryScreen({
    super.key,
    required this.onBackToJournal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      appBar: AppBar(
        backgroundColor: FloralPalette.petalWhite,
        elevation: 0,
        title: Text(
          'Botanical Sketchbook',
          style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: FloralPalette.warmCharcoal),
          onPressed: onBackToJournal,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Romantic Header intro
                  Text(
                    'Handcrafted Botanical Elements',
                    style: JournalTypography.headingLarge(color: FloralPalette.warmCharcoal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview the bespoke vector doodles and palette accents crafted for Bookmark.',
                    style: JournalTypography.subheading(color: FloralPalette.mutedCharcoal),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 1. THE SIGNATURE POPPY (HER FAVORITE FLOWER)
                  // ==========================================
                  _buildSectionCard(
                    title: 'The Signature Poppy',
                    subtitle: 'Her favorite flower: opaque crinkled petals, botanical seed pod & stamen ring',
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: FloralPalette.petalWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF2DED9)),
                          ),
                          child: const Center(
                            child: PoppyDoodle(
                              size: 130,
                              showStem: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Bloom Variants',
                          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 20,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildDoodleItem(
                              label: 'Full Bloom',
                              child: const PoppyDoodle(size: 52, showStem: false),
                            ),
                            _buildDoodleItem(
                              label: 'Blush Variant',
                              child: const PoppyDoodle(
                                size: 52,
                                showStem: false,
                                petalColor: FloralPalette.rosePetal,
                              ),
                            ),
                            _buildDoodleItem(
                              label: 'Petite Bloom',
                              child: const PoppyDoodle(size: 38, showStem: false),
                            ),
                            _buildDoodleItem(
                              label: 'With Stem & Leaf',
                              child: const PoppyDoodle(size: 44, showStem: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 2. BOTANICAL COMPANIONS
                  // ==========================================
                  _buildSectionCard(
                    title: 'Floral Companions',
                    subtitle: 'Supporting motifs for genres, tabs & journal status badges',
                    child: Column(
                      children: [
                        // Row 1: Meadow Daisy
                        _buildFlowerRow(
                          flowerName: 'Meadow Daisy',
                          usage: 'Wishlist tab, cheerful marks & chapter dividers (enhanced for white backgrounds)',
                          flower1: const DaisyDoodle(size: 64, showStem: true),
                          flower2: const DaisyDoodle(size: 44, showStem: false),
                        ),

                        const SizedBox(height: 18),
                        const Divider(color: Color(0xFFF4E5E1), height: 1),
                        const SizedBox(height: 18),

                        // Row 2: Spring Tulip
                        _buildFlowerRow(
                          flowerName: 'Spring Tulip',
                          usage: 'Reading-in-progress markers & shelf accents',
                          flower1: const TulipDoodle(size: 64, showStem: true),
                          flower2: const TulipDoodle(size: 44, showStem: false),
                        ),

                        const SizedBox(height: 18),
                        const Divider(color: Color(0xFFF4E5E1), height: 1),
                        const SizedBox(height: 18),

                        // Row 3: Lavender Sprig
                        _buildFlowerRow(
                          flowerName: 'Lavender Sprig',
                          usage: 'Quote attributions, bookmarks & margin notes',
                          flower1: const LavenderDoodle(size: 68),
                          flower2: const LavenderDoodle(size: 46),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. VINES, BORDERS & DRIFTING PETALS
                  // ==========================================
                  _buildSectionCard(
                    title: 'Vines, Borders & Petals',
                    subtitle: 'Flourishes for section divides, empty states & celebrations',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Botanical Leaf Vine (Horizontal Section Divider):',
                          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: VineBorderDoodle(
                            width: 320,
                            height: 26,
                          ),
                        ),

                        const SizedBox(height: 22),
                        const Divider(color: Color(0xFFF4E5E1), height: 1),
                        const SizedBox(height: 18),

                        Text(
                          'Hand-Drawn Fountain Pen Underline:',
                          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const HandDrawnUnderline(
                          width: 220,
                          color: FloralPalette.rosePetal,
                          strokeWidth: 2.4,
                        ),

                        const SizedBox(height: 22),
                        const Divider(color: Color(0xFFF4E5E1), height: 1),
                        const SizedBox(height: 18),

                        Text(
                          'Drifting Petal Scatter (Finished Book Celebration & Ambiance):',
                          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: FloralPalette.petalWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF4E5E1)),
                          ),
                          child: const Center(
                            child: PetalScatterDoodle(
                              width: 280,
                              height: 60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 4. WARM BROWN ACCENTS (PREVIEW ONLY)
                  // ==========================================
                  _buildBrownAccentsCard(),

                  const SizedBox(height: 32),

                  // Bottom Action Button to Return
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onBackToJournal,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                      label: const Text('Looks Good! Return to Journal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FloralPalette.deepRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Card previewing the 5 brown tokens and 6 code-drawn samples
  Widget _buildBrownAccentsCard() {
    return _buildSectionCard(
      title: 'Brown Accents (Preview Only)',
      subtitle: '10-15% supporting warmth: blush pink stays lead, brown adds cozy intimacy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introductory note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FloralPalette.kraftPaper.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6)),
            ),
            child: Text(
              'Supporting accent palette for her favorite cozy brown tones. Warm Charcoal remains default body text.',
              style: JournalTypography.bodySmall(color: FloralPalette.cocoa),
            ),
          ),

          const SizedBox(height: 20),

          // Swatches Header
          Text(
            'The Five Palette Swatches',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 5 Swatches List
          _buildSwatchTile(
            name: 'Espresso',
            hex: '#4A3428',
            color: FloralPalette.espresso,
            role: 'Rare strong text, dark leather spine accents',
          ),
          const SizedBox(height: 10),
          _buildSwatchTile(
            name: 'Cocoa',
            hex: '#7A5240',
            color: FloralPalette.cocoa,
            role: 'Accent text, outlines & notes (6.8:1 on white, WCAG AAA)',
          ),
          const SizedBox(height: 10),
          _buildSwatchTile(
            name: 'Caramel',
            hex: '#B9825A',
            color: FloralPalette.caramel,
            role: 'DECORATIVE ONLY, never text (~3.3:1 on white)',
          ),
          const SizedBox(height: 10),
          _buildSwatchTile(
            name: 'Latte',
            hex: '#D8BBA0',
            color: FloralPalette.latte,
            role: 'Soft fills, spines, dividers & pill backgrounds',
          ),
          const SizedBox(height: 10),
          _buildSwatchTile(
            name: 'Kraft Paper',
            hex: '#F3E7DA',
            color: FloralPalette.kraftPaper,
            role: 'Subtle panel background, quote cards & notes',
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF4E5E1), height: 1),
          const SizedBox(height: 20),

          // Samples Header
          Text(
            'Code-Drawn Botanical Samples',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Handcrafted CustomPainters in the signature watercolor sketchbook style:',
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
          ),
          const SizedBox(height: 16),

          // Sample 1 & 2: Brown Twig with Leaves & Bookmark Ribbon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSampleCard(
                  label: 'Brown Twig with Leaves',
                  child: const SizedBox(
                    height: 70,
                    child: Center(
                      child: CustomPaint(
                        size: Size(110, 56),
                        painter: _BrownTwigPainter(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSampleCard(
                  label: 'Bookmark Ribbon',
                  child: const SizedBox(
                    height: 70,
                    child: Center(
                      child: CustomPaint(
                        size: Size(44, 56),
                        painter: _BookmarkRibbonPainter(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sample 3: Leather-Bound Open Book
          _buildSampleCard(
            label: 'Leather-Bound Open Book',
            child: const SizedBox(
              height: 75,
              child: Center(
                child: CustomPaint(
                  size: Size(160, 65),
                  painter: _LeatherBookPainter(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Sample 4: Kraft-Paper Quote Card with Cocoa Text
          _buildSampleCard(
            label: 'Kraft-Paper Quote Card with Cocoa Text',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: FloralPalette.kraftPaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FloralPalette.latte, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“A book is a quiet garden carried in the pocket.”',
                    style: JournalTypography.subheading(color: FloralPalette.cocoa).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— Arabic Proverb',
                      style: GoogleFonts.caveat(
                        color: FloralPalette.cocoa,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Sample 5 & 6: Latte-and-Cocoa "Paused" Pill & Caveat Line in Cocoa
          _buildSampleCard(
            label: 'Latte & Espresso "Paused" Pill (6.4:1 contrast)',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: FloralPalette.latte.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FloralPalette.cocoa.withValues(alpha: 0.45), width: 1.0),
              ),
              child: Text(
                'Paused',
                style: JournalTypography.bodySmall(color: FloralPalette.espresso).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _buildSampleCard(
            label: 'Caveat Handwritten Line in Cocoa',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'gathered like dried flowers between favorite pages ~',
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  color: FloralPalette.cocoa,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchTile({
    required String name,
    required String hex,
    required Color color,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DCD7)),
      ),
      child: Row(
        children: [
          // Swatch box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Swatch details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: FloralPalette.kraftPaper.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hex,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FloralPalette.warmCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCard({
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DCD7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.2),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildDoodleItem({
    required String label,
    required Widget child,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 70,
          alignment: Alignment.center,
          child: child,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: JournalTypography.marginNote(color: FloralPalette.mutedCharcoal),
        ),
      ],
    );
  }

  Widget _buildFlowerRow({
    required String flowerName,
    required String usage,
    required Widget flower1,
    required Widget flower2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        flower1,
        const SizedBox(width: 14),
        flower2,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flowerName,
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
              ),
              const SizedBox(height: 3),
              Text(
                usage,
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================================
// CODE-DRAWN SAMPLES FOR BROWN ACCENTS PREVIEW
// ========================================================

/// 1. Handcrafted Brown Twig with Leaves
class _BrownTwigPainter extends CustomPainter {
  const _BrownTwigPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final twigPaint = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = FloralPalette.sageGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Arched wood twig
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.75);
    path.cubicTo(
      size.width * 0.35, size.height * 0.45,
      size.width * 0.65, size.height * 0.65,
      size.width * 0.9, size.height * 0.25,
    );
    canvas.drawPath(path, twigPaint);

    // Leaves with petioles
    _drawTwigLeaf(canvas, Offset(size.width * 0.32, size.height * 0.54), -0.6, leafFill, leafStroke, twigPaint);
    _drawTwigLeaf(canvas, Offset(size.width * 0.55, size.height * 0.60), 0.7, leafFill, leafStroke, twigPaint);
    _drawTwigLeaf(canvas, Offset(size.width * 0.78, size.height * 0.40), -0.5, leafFill, leafStroke, twigPaint);
    // Tip leaf
    _drawTwigLeaf(canvas, Offset(size.width * 0.9, size.height * 0.25), 0.4, leafFill, leafStroke, twigPaint);
  }

  void _drawTwigLeaf(Canvas canvas, Offset origin, double angle, Paint fill, Paint stroke, Paint petiole) {
    // Petiole stem
    final petioleEnd = origin.translate(math.cos(angle) * 6, math.sin(angle) * 6);
    canvas.drawLine(origin, petioleEnd, petiole);

    canvas.save();
    canvas.translate(petioleEnd.dx, petioleEnd.dy);
    canvas.rotate(angle);

    final leaf = Path();
    leaf.moveTo(0, 0);
    leaf.cubicTo(-4, -6, -3, -13, 0, -16);
    leaf.cubicTo(3, -13, 4, -6, 0, 0);
    canvas.drawPath(leaf, fill);
    canvas.drawPath(leaf, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Handcrafted Bookmark Ribbon
class _BookmarkRibbonPainter extends CustomPainter {
  const _BookmarkRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ribbonFill = Paint()
      ..shader = const LinearGradient(
        colors: [FloralPalette.caramel, FloralPalette.cocoa],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final ribbonStroke = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final ribbonPath = Path();
    ribbonPath.moveTo(size.width * 0.2, 0);
    ribbonPath.lineTo(size.width * 0.8, 0);
    ribbonPath.lineTo(size.width * 0.8, size.height * 0.85);
    // V-notch cut
    ribbonPath.lineTo(size.width * 0.5, size.height * 0.65);
    ribbonPath.lineTo(size.width * 0.2, size.height * 0.85);
    ribbonPath.close();

    canvas.drawPath(ribbonPath, ribbonFill);
    canvas.drawPath(ribbonPath, ribbonStroke);

    // Subtle satin highlight down the center
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height * 0.68),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Handcrafted Leather-Bound Open Book
class _LeatherBookPainter extends CustomPainter {
  const _LeatherBookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leatherCover = Paint()
      ..color = FloralPalette.cocoa
      ..style = PaintingStyle.fill;

    final leatherStroke = Paint()
      ..color = FloralPalette.cocoa
      ..strokeWidth = 0.95
      ..style = PaintingStyle.stroke;

    final pageFill = Paint()
      ..color = FloralPalette.kraftPaper
      ..style = PaintingStyle.fill;

    final pageStroke = Paint()
      ..color = FloralPalette.latte
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midX = size.width * 0.5;
    final topY = size.height * 0.18;
    final botY = size.height * 0.88;

    // Leather cover underlay
    final coverPath = Path();
    coverPath.moveTo(midX, topY + 4);
    coverPath.cubicTo(midX - 25, topY - 3, midX - 55, topY - 1, 8, topY + 12);
    coverPath.lineTo(6, botY + 5);
    coverPath.cubicTo(midX - 55, botY + 1, midX - 25, botY + 3, midX, botY + 5);
    coverPath.cubicTo(midX + 25, botY + 3, midX + 55, botY + 1, size.width - 6, botY + 5);
    coverPath.lineTo(size.width - 8, topY + 12);
    coverPath.cubicTo(midX + 55, topY - 1, midX + 25, topY - 3, midX, topY + 4);
    canvas.drawPath(coverPath, leatherCover);
    canvas.drawPath(coverPath, leatherStroke);

    // Left Page (Kraft Paper fill)
    final leftPage = Path();
    leftPage.moveTo(midX, topY);
    leftPage.cubicTo(midX - 20, topY - 5, midX - 45, topY - 3, 14, topY + 9);
    leftPage.lineTo(14, botY);
    leftPage.cubicTo(midX - 45, botY - 5, midX - 20, botY - 7, midX, botY);
    leftPage.close();
    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(leftPage, pageStroke);

    // Right Page (Kraft Paper fill)
    final rightPage = Path();
    rightPage.moveTo(midX, topY);
    rightPage.cubicTo(midX + 20, topY - 5, midX + 45, topY - 3, size.width - 14, topY + 9);
    rightPage.lineTo(size.width - 14, botY);
    rightPage.cubicTo(midX + 45, botY - 5, midX + 20, botY - 7, midX, botY);
    rightPage.close();
    canvas.drawPath(rightPage, pageFill);
    canvas.drawPath(rightPage, pageStroke);

    // Spine crease
    canvas.drawLine(
      Offset(midX, topY),
      Offset(midX, botY),
      Paint()..color = FloralPalette.cocoa..strokeWidth = 1.4,
    );

    // Faint simulated ink lines on pages in Latte
    final inkLine = Paint()
      ..color = FloralPalette.latte
      ..strokeWidth = 1.0;
    for (int i = 0; i < 3; i++) {
      final y = topY + 14.0 + (i * 10.0);
      canvas.drawLine(Offset(22, y), Offset(midX - 12, y - 1), inkLine);
      canvas.drawLine(Offset(midX + 12, y - 1), Offset(size.width - 22, y), inkLine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
