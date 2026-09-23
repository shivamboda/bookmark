import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'doodles/poppy_doodle.dart';
import 'doodles/sketch_underline.dart';
import 'models/book.dart';
import 'services/hive_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize decoupled Hive CE storage
  final storageService = HiveStorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const BookmarkApp(),
    ),
  );
}

/// Root Application Widget with dynamic floral theme switching
class BookmarkApp extends ConsumerWidget {
  const BookmarkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Bookmark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(mode: themeMode),
      home: const JournalCoverScreen(),
    );
  }
}

/// Phase 2 Interactive Journal Screen: Theme System & Hive Database Preview
class JournalCoverScreen extends ConsumerWidget {
  const JournalCoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final booksAsync = ref.watch(booksProvider);
    final isDark = currentTheme == FloralThemeMode.midnightGarden;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // Top Header: Side-by-side Row to guarantee ZERO collision across all phone widths
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Handwritten Tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOL. I • READING JOURNAL',
                              style: JournalTypography.bodySmall(
                                color: isDark
                                    ? const Color(0xFFC7B5E8)
                                    : FloralPalette.deepForestGreen.withValues(alpha: 0.85),
                              ).copyWith(
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Main App Title in Fraunces
                            Text(
                              'Bookmark',
                              style: JournalTypography.headingHero(
                                color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Hand-drawn wavy ink underline
                            HandDrawnUnderline(
                              width: 155,
                              color: isDark ? const Color(0xFFE88FA6) : FloralPalette.rosePetal,
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

                  const SizedBox(height: 24),

                  // Botanical Palette Selector Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2531) : FloralPalette.softIvory,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFF2DED9),
                        width: 1.0,
                      ),
                      boxShadow: const [FloralPalette.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Botanical Themes',
                                style: JournalTypography.headingSmall(
                                  color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                                ),
                              ),
                            ),
                            Text(
                              'tap to switch',
                              style: JournalTypography.marginNote(
                                color: isDark ? const Color(0xFFC7B5E8) : FloralPalette.mutedCharcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildThemePill(
                              ref: ref,
                              mode: FloralThemeMode.poppyBlush,
                              label: 'Poppy Blush',
                              swatchColor: FloralPalette.rosePetal,
                              isSelected: currentTheme == FloralThemeMode.poppyBlush,
                            ),
                            _buildThemePill(
                              ref: ref,
                              mode: FloralThemeMode.lavenderMeadow,
                              label: 'Lavender Meadow',
                              swatchColor: const Color(0xFFC7B5E8),
                              isSelected: currentTheme == FloralThemeMode.lavenderMeadow,
                            ),
                            _buildThemePill(
                              ref: ref,
                              mode: FloralThemeMode.sageGarden,
                              label: 'Sage Garden',
                              swatchColor: FloralPalette.sageGreen,
                              isSelected: currentTheme == FloralThemeMode.sageGarden,
                            ),
                            _buildThemePill(
                              ref: ref,
                              mode: FloralThemeMode.midnightGarden,
                              label: 'Midnight Garden',
                              swatchColor: const Color(0xFF1E1A22),
                              isSelected: currentTheme == FloralThemeMode.midnightGarden,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section Header: Seeded Library from Hive CE
                  Row(
                    children: [
                      Text(
                        'On the Shelf',
                        style: JournalTypography.headingMedium(
                          color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '• local database',
                          style: JournalTypography.marginNote(
                            color: isDark ? const Color(0xFFC7B5E8) : FloralPalette.deepForestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Error loading books: $err'),
                    ),
                    data: (books) {
                      if (books.isEmpty) {
                        return const Center(
                          child: Text('Your shelf is waiting for its first story...'),
                        );
                      }

                      return Column(
                        children: books.map((book) => _buildBookCard(context, ref, book, isDark)).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemePill({
    required WidgetRef ref,
    required FloralThemeMode mode,
    required String label,
    required Color swatchColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setTheme(mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? swatchColor.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? swatchColor : const Color(0x33A0A0A0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: JournalTypography.bodySmall().copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, WidgetRef ref, Book book, bool isDark) {
    Color statusColor;
    switch (book.status) {
      case ReadingStatus.reading:
        statusColor = const Color(0xFFD97724);
      case ReadingStatus.finished:
        statusColor = FloralPalette.deepForestGreen;
      case ReadingStatus.wantToRead:
        statusColor = const Color(0xFF7C5E9B);
      case ReadingStatus.paused:
        statusColor = FloralPalette.mutedCharcoal;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2531) : FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFF2DED9),
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
                        color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.authorDisplay,
                      style: JournalTypography.subheading(
                        color: isDark ? const Color(0xFFD6CAD0) : FloralPalette.mutedCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  book.status.label,
                  style: JournalTypography.bodySmall(color: statusColor).copyWith(
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
                const Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: Color(0xFFF4B23E),
                ),
                const SizedBox(width: 4),
                Text(
                  book.rating.toStringAsFixed(1),
                  style: JournalTypography.bodyMedium(
                    color: isDark ? Colors.white : FloralPalette.warmCharcoal,
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
                          color: (isDark ? Colors.white : FloralPalette.blushPink).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g,
                          style: JournalTypography.bodySmall(
                            color: isDark ? const Color(0xFFE88FA6) : FloralPalette.warmCharcoal,
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
                color: (isDark ? Colors.black : FloralPalette.petalWhite).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('“', style: TextStyle(fontSize: 18, color: FloralPalette.rosePetal)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      book.quotes.first.quote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: JournalTypography.bodySmall(
                        color: isDark ? const Color(0xFFE0D4DA) : FloralPalette.warmCharcoal,
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
