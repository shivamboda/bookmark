import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'doodles/doodle_gallery_screen.dart';
import 'doodles/poppy_doodle.dart';
import 'doodles/sketch_underline.dart';
import 'models/book.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize decoupled Hive CE storage
  await globalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(globalStorageService),
      ],
      child: const BookmarkApp(),
    ),
  );
}

/// Root Application Widget styled with the signature Poppy Blush theme
class BookmarkApp extends ConsumerWidget {
  const BookmarkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Bookmark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(mode: themeMode),
      home: const MainContainerScreen(),
    );
  }
}

/// Container that seamlessly switches between the Reading Journal and the Doodle Showcase
class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  bool _showDoodleGallery = false;

  @override
  Widget build(BuildContext context) {
    if (_showDoodleGallery) {
      return DoodleGalleryScreen(
        onBackToJournal: () => setState(() => _showDoodleGallery = false),
      );
    }

    return JournalCoverScreen(
      onOpenDoodleGallery: () => setState(() => _showDoodleGallery = true),
    );
  }
}

/// Botanical Reading Journal Screen with Live Library Data & Debug Doodle Preview Link
class JournalCoverScreen extends ConsumerWidget {
  final VoidCallback onOpenDoodleGallery;

  const JournalCoverScreen({
    super.key,
    required this.onOpenDoodleGallery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

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
                  // Top Navigation Bar (Doodle Sketchbook chip is debug-only)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'VOL. I • READING JOURNAL',
                          style: JournalTypography.bodySmall(
                            color: FloralPalette.deepForestGreen.withValues(alpha: 0.85),
                          ).copyWith(
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onOpenDoodleGallery,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: FloralPalette.blushPink.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: FloralPalette.rosePetal.withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PoppyDoodle(size: 16, showStem: false),
                                const SizedBox(width: 5),
                                Text(
                                  'Doodle Art',
                                  style: JournalTypography.bodySmall(
                                    color: FloralPalette.warmCharcoal,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Top Header: Side-by-side Row to guarantee ZERO collision across all phone widths
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Handwritten Tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main App Title in Fraunces
                            Text(
                              'Bookmark',
                              style: JournalTypography.headingHero(
                                color: FloralPalette.warmCharcoal,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Hand-drawn wavy ink underline
                            const HandDrawnUnderline(
                              width: 155,
                              color: FloralPalette.rosePetal,
                              strokeWidth: 2.2,
                            ),

                            const SizedBox(height: 10),

                            // Intimate handwriting note in Caveat
                            Text(
                              'for all the stories we hold close ~',
                              style: JournalTypography.handwritingLarge(
                                color: FloralPalette.poppyRed,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Organic pressed poppy sketch nestled gracefully beside the title
                      const PoppyDoodle(
                        size: 90,
                        showStem: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Journal Entry Note Card (creamy pressed-flower stationery page)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    decoration: BoxDecoration(
                      color: FloralPalette.softIvory,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFF2DED9),
                        width: 1.2,
                      ),
                      boxShadow: const [FloralPalette.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handwritten Chapter Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'chapter one begins here',
                                style: JournalTypography.handwriting(
                                  color: FloralPalette.deepForestGreen,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.auto_stories_outlined,
                              size: 18,
                              color: FloralPalette.deepRose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Warm literary excerpt in Lora
                        Text(
                          '“I have lived a thousand lives and loved a thousand worlds — yet every good book still feels like coming home.”',
                          style: JournalTypography.bodyLarge(
                            color: FloralPalette.warmCharcoal,
                          ).copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Intimate attribution in Caveat
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— for you, with love ♡',
                            style: JournalTypography.handwriting(
                              color: FloralPalette.deepRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Header: Seeded Library from Hive CE (Debug note hidden in release)
                  Row(
                    children: [
                      Text(
                        'On the Shelf',
                        style: JournalTypography.headingMedium(
                          color: FloralPalette.warmCharcoal,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• local database',
                            style: JournalTypography.marginNote(
                              color: FloralPalette.deepForestGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Books List from Hive CE
                  booksAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Error loading shelf: $err',
                        style: JournalTypography.bodySmall(color: Colors.red.shade800),
                      ),
                    ),
                    data: (books) {
                      if (books.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: FloralPalette.softIvory,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF2DED9)),
                          ),
                          child: Column(
                            children: [
                              const PoppyDoodle(size: 48, showStem: false),
                              const SizedBox(height: 12),
                              Text(
                                'Your shelf is waiting for its first story...',
                                style: JournalTypography.subheading(color: FloralPalette.mutedCharcoal),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: books.map((book) => _buildBookCard(context, ref, book)).toList(),
                      );
                    },
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

  Widget _buildBookCard(BuildContext context, WidgetRef ref, Book book) {
    // Recolor status pills strictly into floral palette:
    // Want to Read = Lavender, Reading = Sage, Finished = Blush, Paused = Buttercup
    Color badgeBg;
    Color badgeText;
    Color badgeBorder;

    switch (book.status) {
      case ReadingStatus.wantToRead:
        badgeBg = FloralPalette.lavenderMist.withValues(alpha: 0.35);
        badgeText = FloralPalette.lavenderDark;
        badgeBorder = FloralPalette.lavenderDark.withValues(alpha: 0.35);
      case ReadingStatus.reading:
        badgeBg = FloralPalette.sageGreen.withValues(alpha: 0.35);
        badgeText = FloralPalette.sageGreenDark;
        badgeBorder = FloralPalette.sageGreenDark.withValues(alpha: 0.35);
      case ReadingStatus.finished:
        badgeBg = FloralPalette.blushPink.withValues(alpha: 0.45);
        badgeText = FloralPalette.deepRose;
        badgeBorder = FloralPalette.deepRose.withValues(alpha: 0.35);
      case ReadingStatus.paused:
        badgeBg = FloralPalette.buttercupYellow.withValues(alpha: 0.40);
        badgeText = FloralPalette.buttercupDark;
        badgeBorder = FloralPalette.buttercupDark.withValues(alpha: 0.35);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF2DED9),
          width: 1.0,
        ),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: JournalTypography.headingSmall(
                        color: FloralPalette.warmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.authorDisplay,
                      style: JournalTypography.subheading(
                        color: FloralPalette.mutedCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeBorder,
                    width: 0.9,
                  ),
                ),
                child: Text(
                  book.status.label,
                  style: JournalTypography.bodySmall(color: badgeText).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Rating & Genre Tags
          Row(
            children: [
              if (book.rating > 0) ...[
                // Warm Buttercup Yellow star (strictly within floral palette)
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFE5A922),
                ),
                const SizedBox(width: 4),
                Text(
                  book.rating.toStringAsFixed(1),
                  style: JournalTypography.bodyMedium(
                    color: FloralPalette.warmCharcoal,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: book.genres.map((g) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FloralPalette.blushPink.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g,
                          style: JournalTypography.bodySmall(
                            color: FloralPalette.warmCharcoal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Favorite Quote snippet if present
          if (book.quotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FloralPalette.petalWhite.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('“', style: TextStyle(fontSize: 18, color: FloralPalette.deepRose)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      book.quotes.first.quote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: JournalTypography.bodySmall(
                        color: FloralPalette.warmCharcoal,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
