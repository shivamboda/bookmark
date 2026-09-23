import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'doodles/poppy_doodle.dart';

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
      home: const WelcomeScreen(),
    );
  }
}

/// Phase 1 Welcome & Verification Screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Center in a phone-proportional column on desktop displays
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Signature Poppy Hero Graphic
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: FloralPalette.blushPink.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      boxShadow: const [FloralPalette.cardShadow],
                    ),
                    alignment: Alignment.center,
                    child: const PoppyDoodle(
                      size: 92,
                      showStem: true,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App Title & Tagline
                  Text(
                    'Bookmark',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: FloralPalette.warmCharcoal,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A personal reading journal, pressed with care',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: FloralPalette.mutedCharcoal,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Phase 1 Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: FloralPalette.softIvory,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: FloralPalette.blushPink.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: const [FloralPalette.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const PoppyDoodle(size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Phase 1: Setup Complete',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: FloralPalette.warmCharcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildStatusRow(
                          icon: Icons.check_circle_rounded,
                          color: FloralPalette.deepForestGreen,
                          title: 'Flutter Web Toolchain',
                          detail: 'Compiled & ready for Chrome & iOS Safari',
                        ),
                        const SizedBox(height: 10),
                        _buildStatusRow(
                          icon: Icons.check_circle_rounded,
                          color: FloralPalette.deepForestGreen,
                          title: 'iPhone 16 Viewport & PWA',
                          detail: 'viewport-fit=cover & standalone mode set',
                        ),
                        const SizedBox(height: 10),
                        _buildStatusRow(
                          icon: Icons.check_circle_rounded,
                          color: FloralPalette.deepForestGreen,
                          title: 'Floral Design System',
                          detail: 'Poppy Blush palette & Playfair typography',
                        ),
                        const SizedBox(height: 10),
                        _buildStatusRow(
                          icon: Icons.check_circle_rounded,
                          color: FloralPalette.deepForestGreen,
                          title: 'Storage Decoupled',
                          detail: 'StorageService abstraction layer ready',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next Step Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: FloralPalette.blushPink.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: FloralPalette.poppyRed,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ready for Phase 2: Local Database (Hive) & Data Models.',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FloralPalette.warmCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FloralPalette.warmCharcoal,
                ),
              ),
              Text(
                detail,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: FloralPalette.mutedCharcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
