import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'doodles/poppy_doodle.dart';
import 'doodles/sketch_underline.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BookmarkApp(),
    ),
  );
}

/// Root Application Widget for "Bookmark"
class BookmarkApp extends StatelessWidget {
  const BookmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookmark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(mode: FloralThemeMode.poppyBlush),
      home: const JournalCoverScreen(),
    );
  }
}

/// Intimate Botanical Journal Cover Screen
class JournalCoverScreen extends StatelessWidget {
  const JournalCoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Top Asymmetrical Header: Title + Pressed Botanical Poppy Sketch
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Organic pressed poppy sketch leaning gracefully in from the right
                      Positioned(
                        right: -12,
                        top: -16,
                        child: const Opacity(
                          opacity: 0.95,
                          child: PoppyDoodle(
                            size: 115,
                            showStem: true,
                          ),
                        ),
                      ),

                      // Title & Handwritten Margin Tagline
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date margin stamp
                            Text(
                              'VOL. I • READING JOURNAL',
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.deepForestGreen.withValues(alpha: 0.75),
                              ).copyWith(
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

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
                              width: 175,
                              color: FloralPalette.rosePetal,
                              strokeWidth: 2.2,
                            ),

                            const SizedBox(height: 12),

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
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Journal Entry Note Card (resembling a creamy pressed-flower stationery page)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
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
                              color: FloralPalette.rosePetal,
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
                        const SizedBox(height: 16),

                        // Attribution in Caveat
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— for you, with love ♡',
                            style: JournalTypography.handwriting(
                              color: FloralPalette.rosePetal,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Divider(
                          color: FloralPalette.blushPink.withValues(alpha: 0.45),
                          height: 1,
                        ),
                        const SizedBox(height: 14),

                        // Quiet, elegant journal footnote
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: FloralPalette.poppyRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Poppy Blush palette • Fraunces, Lora & Caveat typography',
                                style: JournalTypography.bodySmall(
                                  color: FloralPalette.mutedCharcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Elegant pill button to open library (Phase 2 preview)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: FloralPalette.rosePetal,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: FloralPalette.rosePetal.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open Library',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
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
}

