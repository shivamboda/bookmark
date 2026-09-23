import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/palette.dart';
import 'daisy_doodle.dart';
import 'lavender_doodle.dart';
import 'petal_scatter_doodle.dart';
import 'poppy_doodle.dart';
import 'sketch_underline.dart';
import 'tulip_doodle.dart';
import 'vine_doodle.dart';

/// Art showcase screen presenting all handcrafted vector doodles.
///
/// Pure code—zero downloaded images or SVG assets. Scalable, crisp at any DPR,
/// and dynamically tintable with the floral color palette.
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back to Journal bar
                  Row(
                    children: [
                      InkWell(
                        onTap: onBackToJournal,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: FloralPalette.softIvory,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF2DED9)),
                            boxShadow: const [FloralPalette.cardShadow],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 16,
                                color: FloralPalette.rosePetal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Back to Journal',
                                style: JournalTypography.bodySmall(
                                  color: FloralPalette.warmCharcoal,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ART PREVIEW',
                        style: JournalTypography.bodySmall(
                          color: FloralPalette.deepForestGreen,
                        ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sketchbook Title
                  Text(
                    'Botanical Sketchbook',
                    style: JournalTypography.headingHero(color: FloralPalette.warmCharcoal),
                  ),
                  const SizedBox(height: 4),
                  const HandDrawnUnderline(
                    width: 210,
                    color: FloralPalette.rosePetal,
                    strokeWidth: 2.2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'handcrafted vector doodles in pure code ~',
                    style: JournalTypography.handwritingLarge(color: FloralPalette.poppyRed),
                  ),

                  const SizedBox(height: 28),

                  // ==========================================
                  // 1. SIGNATURE POPPY SHOWCASE (The Star)
                  // ==========================================
                  _buildSectionCard(
                    title: 'The Signature Poppy',
                    subtitle: 'Her favorite flower • Star motif throughout Bookmark',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Poppy Botanical Sketch
                        Center(
                          child: Column(
                            children: [
                              const PoppyDoodle(
                                size: 120,
                                showStem: true,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Botanical Field Sketch (curving stem, leaf vein & side bud)',
                                textAlign: TextAlign.center,
                                style: JournalTypography.marginNote(color: FloralPalette.mutedCharcoal),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                        const Divider(color: Color(0xFFF4E5E1), height: 1),
                        const SizedBox(height: 18),

                        // Poppy Bloom Variants (Compact bloom for badges, buttons & stars)
                        Text(
                          'Bloom Variants & Sizes:',
                          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildDoodleItem(
                              label: 'Large Bloom (64px)',
                              child: const PoppyDoodle(size: 64, showStem: false),
                            ),
                            _buildDoodleItem(
                              label: 'Blush Tint (48px)',
                              child: const PoppyDoodle(size: 48, showStem: false, petalColor: FloralPalette.rosePetal),
                            ),
                            _buildDoodleItem(
                              label: 'Icon/Star (32px)',
                              child: const PoppyDoodle(size: 32, showStem: false),
                            ),
                            _buildDoodleItem(
                              label: 'Tiny (22px)',
                              child: const PoppyDoodle(size: 22, showStem: false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 2. COMPANION BOTANICALS
                  // ==========================================
                  _buildSectionCard(
                    title: 'Companion Botanicals',
                    subtitle: 'Supporting flowers for Wishlist, tabs, and chapter markers',
                    child: Column(
                      children: [
                        // Row 1: Sweet Daisy
                        _buildFlowerRow(
                          flowerName: 'Sweet Daisy',
                          usage: 'Wishlist tab, cheerful marks & chapter dividers',
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

                  const SizedBox(height: 32),

                  // Bottom Action Button to Return
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onBackToJournal,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Looks Good! Return to Journal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FloralPalette.rosePetal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      children: [
        child,
        const SizedBox(height: 6),
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
