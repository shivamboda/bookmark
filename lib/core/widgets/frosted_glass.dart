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
              color: backgroundColor ?? FloralPalette.softIvory.withValues(alpha: 0.85),
              border: border ??
                  const Border(
                    bottom: BorderSide(
                      color: Color(0xFFE8D7C8),
                      width: 1.0,
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
        width: 66,
        height: 66,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft frosted halo layer beneath
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: FloralPalette.deepRose.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE8D7C8).withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Solid tappable FAB
            FloatingActionButton(
              key: fabKey,
              onPressed: onPressed,
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              elevation: 3,
              tooltip: tooltip,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
