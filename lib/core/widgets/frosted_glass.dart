import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// Reusable, performance-guarded frosted glass header for modal sheets.
///
/// Strictly adheres to performance guardrails:
/// - Isolated in a [RepaintBoundary] to prevent parent or sibling repainting.
/// - Clipped with [ClipRRect] to constrain the blur raster buffer.
/// - Kept to a low sigma (12.0) to prevent WebKit GPU raster stalls.
class FrostedGlassHeader extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Border? border;

  const FrostedGlassHeader({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blurSigma = 12.0,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (FloralPalette.isDark
                      ? const Color(0xFF2B211A).withValues(alpha: 0.72)
                      : const Color(0xFFFFFBF5).withValues(alpha: 0.75)),
              border: border ??
                  Border(
                    bottom: BorderSide(
                      color: FloralPalette.isDark ? const Color(0x3DF5EBE1) : const Color(0x3DEADBCE),
                      width: 0.8,
                    ),
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button with a soft frosted glass depth halo layer underneath.
///
/// The button itself remains completely solid and crisp for immediate touch response,
/// while an underlying frosted halo layer adds delicate depth without scrolling jank.
class FrostedFloralFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Key? fabKey;
  final String? tooltip;

  const FrostedFloralFab({
    super.key,
    required this.onPressed,
    required this.child,
    this.fabKey,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Frosted glass depth layer underneath (kept cleanly within bounds, no harsh outer border)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                ),
              ),
            ),

            // Clean, solid tappable FAB in signature rust color with soft ivory/dark cocoa icon
            SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                key: fabKey,
                onPressed: onPressed,
                backgroundColor: const Color(0xFFA6482A), // Keep signature rust color
                foregroundColor: FloralPalette.softIvory,
                elevation: 4,
                tooltip: tooltip,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
