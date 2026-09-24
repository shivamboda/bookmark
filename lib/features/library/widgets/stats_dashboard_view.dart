import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../models/book.dart';
import 'book_cover_thumbnail.dart';

/// Comprehensive Stats Dashboard for Bookmark.
///
/// Visualizes reading activity for the current calendar year:
/// - Yearly reading goal with blooming poppy doodle
/// - Monthly bar chart of finished books (fl_chart)
/// - Average rating (excluding unrated books)
/// - Genre breakdown (top 3-4 + Other using cleanGenres)
/// - Total pages read (with missing count note)
/// - Highest-rated books showcase (top 3, tie-breaking by finish date)
/// - Graceful empty state when no books have been finished this year.
class StatsDashboardView extends ConsumerWidget {
  final List<Book> books;
  final ValueChanged<int> onNavigateToTab;
  final ValueSetter<Book>? onOpenBook;

  const StatsDashboardView({
    super.key,
    required this.books,
    required this.onNavigateToTab,
    this.onOpenBook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearlyGoal = ref.watch(yearlyGoalProvider);
    final currentYear = DateTime.now().year;

    // Filter books finished in the current calendar year
    final finishedThisYear = books.where((b) {
      return b.status == ReadingStatus.finished &&
          b.finishDate != null &&
          b.finishDate!.year == currentYear;
    }).toList();

    // Books with non-null positive ratings
    final ratedFinished = finishedThisYear.where((b) => b.rating != null && b.rating! > 0).toList();
    final double? avgRating = ratedFinished.isNotEmpty
        ? ratedFinished.map((b) => b.rating!).reduce((a, b) => a + b) / ratedFinished.length
        : null;

    // Page count statistics
    final booksWithPages = finishedThisYear.where((b) => b.pageCount != null && b.pageCount! > 0).toList();
    final int totalPages = booksWithPages.fold<int>(0, (sum, b) => sum + b.pageCount!);
    final int missingPagesCount = finishedThisYear.length - booksWithPages.length;

    // General shelf metrics
    final readingCount = books.where((b) => b.status == ReadingStatus.reading).length;
    final wishlistCount = books.where((b) => b.status == ReadingStatus.wantToRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Reading Goal Card (Always visible at top)
          _buildYearlyGoalCard(context, yearlyGoal, finishedThisYear.length, currentYear),

          const SizedBox(height: 16),

          // 2. Either Empty State OR Full Stats Visualizations
          if (finishedThisYear.isEmpty)
            _buildEmptyState(context, currentYear, readingCount, wishlistCount)
          else ...[
            // Quick 3-Tile Overview Metrics
            _buildMetricsRow(finishedThisYear.length, totalPages, avgRating),

            const SizedBox(height: 20),

            // Monthly Reading Bar Chart (fl_chart)
            _buildMonthlyChartCard(context, finishedThisYear, currentYear),

            const SizedBox(height: 20),

            // Pages Read Card
            _buildPagesCard(totalPages, booksWithPages.length, missingPagesCount),

            const SizedBox(height: 20),

            // Average Rating Card
            _buildRatingCard(avgRating, ratedFinished.length, finishedThisYear.length),

            const SizedBox(height: 20),

            // Genre Breakdown Card
            _buildGenreBreakdownCard(finishedThisYear),

            const SizedBox(height: 20),

            // Highest-Rated Books Showcase
            _buildHighestRatedShowcase(context, ratedFinished),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // YEARLY GOAL CARD WITH BLOOMING POPPY
  // ==========================================
  Widget _buildYearlyGoalCard(
    BuildContext context,
    int? yearlyGoal,
    int finishedCount,
    int currentYear,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$currentYear Reading Goal',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                ),
              ),
              IconButton(
                tooltip: 'Goal Settings',
                icon: Icon(Icons.tune_rounded, size: 20, color: FloralPalette.mutedCharcoal),
                onPressed: () => onNavigateToTab(3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (yearlyGoal == null) ...[
            Text(
              'Set a goal for the year ~',
              style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Track how many books you wish to finish in $currentYear. Head over to Settings to pick a goal whenever you are ready.',
              style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onNavigateToTab(3),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Set Goal in Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FloralPalette.deepRose,
                side: const BorderSide(color: FloralPalette.deepRose),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(44, 44),
              ),
            ),
          ] else ...[
            Builder(builder: (context) {
              final double progress = yearlyGoal > 0 ? (finishedCount / yearlyGoal).clamp(0.0, 1.0) : 0.0;
              final int pct = (progress * 100).round();
              final isReached = finishedCount >= yearlyGoal;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$finishedCount of $yearlyGoal books finished ($pct%)',
                              style: JournalTypography.handwriting(
                                color: isReached ? FloralPalette.sageGreenDark : FloralPalette.deepRose,
                              ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isReached
                                  ? 'Goal achieved! You blossomed right past your target!'
                                  : '${yearlyGoal - finishedCount} more ${yearlyGoal - finishedCount == 1 ? "book" : "books"} to reach your goal',
                              style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Blooming botanical poppy doodle scaling with progress
                      Transform.scale(
                        scale: (0.7 + 0.35 * progress).clamp(0.7, 1.05),
                        child: PoppyDoodle(
                          size: 58,
                          showStem: false,
                          petalColor: isReached ? FloralPalette.buttercupGold : FloralPalette.rosePetal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: FloralPalette.blushPink.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(
                        isReached ? FloralPalette.buttercupGold : FloralPalette.deepRose,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // GRACEFUL EMPTY STATE (0 FINISHED THIS YEAR)
  // ==========================================
  Widget _buildEmptyState(
    BuildContext context,
    int currentYear,
    int readingCount,
    int wishlistCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DaisyDoodle(size: 72, showStem: false),
          const SizedBox(height: 16),
          Text(
            'Your reading journey this year is just beginning ~',
            textAlign: TextAlign.center,
            style: JournalTypography.handwriting(
              color: FloralPalette.warmCharcoal,
            ).copyWith(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Mark books as finished with completion dates in $currentYear to unlock monthly reading pace, genre reflections, and reading memories.',
            textAlign: TextAlign.center,
            style: JournalTypography.bodySmall(
              color: FloralPalette.mutedCharcoal,
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          // Shelf pulse summary
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Chip(
                backgroundColor: FloralPalette.sageGreen.withValues(alpha: 0.2),
                label: Text(
                  '$readingCount currently reading',
                  style: JournalTypography.bodySmall(color: FloralPalette.sageGreenDark),
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              Chip(
                backgroundColor: FloralPalette.lavenderMist.withValues(alpha: 0.3),
                label: Text(
                  '$wishlistCount in wishlist',
                  style: JournalTypography.bodySmall(color: FloralPalette.lavenderDark),
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => onNavigateToTab(0),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('Find Your Next Read'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // METRICS ROW: 3 KEY NUMBERS
  // ==========================================
  Widget _buildMetricsRow(int finishedCount, int totalPages, double? avgRating) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Finished',
            value: '$finishedCount',
            color: FloralPalette.deepRose,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'Pages',
            value: totalPages > 0 ? '$totalPages' : '—',
            color: FloralPalette.sageGreenDark,
            icon: Icons.auto_stories_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'Avg Rating',
            value: avgRating != null ? avgRating.toStringAsFixed(1) : '—',
            color: FloralPalette.buttercupGold,
            icon: Icons.star_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: JournalTypography.headingMedium(color: color).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MONTHLY READING BAR CHART (fl_chart)
  // ==========================================
  Widget _buildMonthlyChartCard(BuildContext context, List<Book> finishedBooks, int currentYear) {
    const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthlyCounts = List<int>.filled(12, 0);

    for (final b in finishedBooks) {
      if (b.finishDate != null) {
        final m = b.finishDate!.month;
        if (m >= 1 && m <= 12) {
          monthlyCounts[m - 1]++;
        }
      }
    }

    final int maxCount = monthlyCounts.reduce(max);
    final double maxY = max(4, maxCount + 1).toDouble();
    final int nowMonth = DateTime.now().month;

    final barGroups = List.generate(12, (index) {
      final count = monthlyCounts[index];
      final isCurrent = (index + 1) == nowMonth;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: isCurrent
                ? FloralPalette.deepRose
                : (count > 0 ? FloralPalette.rosePetal : FloralPalette.blushPink.withValues(alpha: 0.4)),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: FloralPalette.softIvory,
            ),
          ),
        ],
      );
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Books Finished by Month',
                      style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currentYear Reading Pace',
                      style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FloralPalette.blushPink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${finishedBooks.length} total',
                  style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => FloralPalette.warmCharcoal,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = monthLabels[group.x.toInt()];
                      final count = rod.toY.toInt();
                      return BarTooltipItem(
                        '$month: $count ${count == 1 ? "book" : "books"}',
                        TextStyle(
                          color: FloralPalette.softIvory,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: maxY > 6 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value > maxY) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: JournalTypography.bodySmall(
                            color: FloralPalette.mutedCharcoal,
                          ).copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthLabels[idx],
                            style: JournalTypography.bodySmall(
                              color: (idx + 1 == nowMonth)
                                  ? FloralPalette.deepRose
                                  : FloralPalette.mutedCharcoal,
                            ).copyWith(
                              fontSize: 10,
                              fontWeight: (idx + 1 == nowMonth) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 6 ? 2 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: FloralPalette.cardBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGES READ CARD
  // ==========================================
  Widget _buildPagesCard(int totalPages, int booksWithPagesCount, int missingPagesCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FloralPalette.sageGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_stories_rounded, color: FloralPalette.sageGreenDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pages Explored',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat('#,###').format(totalPages),
                  style: JournalTypography.headingLarge(color: FloralPalette.sageGreenDark).copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  missingPagesCount > 0
                      ? 'Across $booksWithPagesCount books ($missingPagesCount ${missingPagesCount == 1 ? "book had" : "books had"} no page count recorded)'
                      : 'Across all $booksWithPagesCount finished books',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // AVERAGE RATING CARD
  // ==========================================
  Widget _buildRatingCard(double? avgRating, int ratedCount, int totalFinished) {
    final unratedCount = totalFinished - ratedCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FloralPalette.kraftPaper,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rounded, color: FloralPalette.buttercupGold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Rating',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                ),
                const SizedBox(height: 4),
                if (avgRating != null) ...[
                  Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: JournalTypography.headingLarge(
                          color: FloralPalette.buttercupGold,
                        ).copyWith(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = (i + 1) <= avgRating.round();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 18,
                            color: FloralPalette.buttercupGold,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unratedCount > 0
                        ? 'Computed across $ratedCount rated ${ratedCount == 1 ? "book" : "books"} ($unratedCount unrated)'
                        : 'Computed across all $ratedCount rated ${ratedCount == 1 ? "book" : "books"}',
                    style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
                  ),
                ] else ...[
                  Text(
                    'No rated books yet',
                    style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rate your finished books to see your average score calculated here ~',
                    style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GENRE BREAKDOWN CARD (Top 3-4 + Other)
  // ==========================================
  Widget _buildGenreBreakdownCard(List<Book> finishedBooks) {
    final Map<String, int> counts = {};
    for (final b in finishedBooks) {
      for (final g in b.cleanGenres) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FloralPalette.softIvory,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FloralPalette.cardBorder),
          boxShadow: [FloralPalette.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favorite Genres', style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal)),
            const SizedBox(height: 8),
            Text(
              'No genres tagged for finished books yet ~',
              style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 15),
            ),
          ],
        ),
      );
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalGenreTags = sorted.fold<int>(0, (sum, e) => sum + e.value);

    // Take top 3 or 4, group rest into 'Other'
    final List<MapEntry<String, int>> displayedGenres = [];
    int otherCount = 0;

    if (sorted.length <= 4) {
      displayedGenres.addAll(sorted);
    } else {
      displayedGenres.addAll(sorted.take(3));
      for (int i = 3; i < sorted.length; i++) {
        otherCount += sorted[i].value;
      }
      if (otherCount > 0) {
        displayedGenres.add(MapEntry('Other', otherCount));
      }
    }

    final genreColors = [
      FloralPalette.deepRose,
      FloralPalette.sageGreenDark,
      FloralPalette.lavenderDark,
      FloralPalette.buttercupGold,
      FloralPalette.mutedCharcoal,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Genre Breakdown',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalGenreTags tags',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Proportional Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: displayedGenres.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final color = genreColors[idx % genreColors.length];
                  final flex = item.value;

                  return Expanded(
                    flex: flex,
                    child: Container(
                      color: color,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend Chips
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: displayedGenres.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = genreColors[idx % genreColors.length];
              final pct = ((item.value / totalGenreTags) * 100).round();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.key} (${item.value})',
                    style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pct%',
                    style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HIGHEST-RATED BOOKS SHOWCASE (Top 3)
  // ==========================================
  Widget _buildHighestRatedShowcase(BuildContext context, List<Book> ratedFinished) {
    if (ratedFinished.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by rating desc, tie-breaking by finishDate desc
    final sorted = List<Book>.from(ratedFinished)..sort((a, b) {
      final rComp = b.rating!.compareTo(a.rating!);
      if (rComp != 0) return rComp;
      final aDate = a.finishDate ?? DateTime(2000);
      final bDate = b.finishDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final top3 = sorted.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: FloralPalette.buttercupGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'Highest-Rated Reads',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your cherished stories of the year ~',
            style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Column(
            children: top3.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final book = entry.value;

              return InkWell(
                onTap: () => onOpenBook != null ? onOpenBook!(book) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Rank indicator
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '#$rank',
                          style: JournalTypography.handwriting(
                            color: rank == 1 ? FloralPalette.buttercupGold : FloralPalette.mutedCharcoal,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini Cover
                      BookCoverThumbnail(
                        book: book,
                        width: 42,
                        height: 60,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 14),
                      // Title, Author, Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.warmCharcoal,
                              ).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              book.authorDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.mutedCharcoal,
                              ).copyWith(fontSize: 11),
                            ),
                            if (book.finishDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Finished ${DateFormat.MMMd().format(book.finishDate!)}',
                                style: JournalTypography.bodySmall(
                                  color: FloralPalette.deepForestGreen,
                                ).copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Star Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FloralPalette.kraftPaper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FloralPalette.blushPink),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: FloralPalette.buttercupGold),
                            const SizedBox(width: 3),
                            Text(
                              book.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: FloralPalette.buttercupGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
