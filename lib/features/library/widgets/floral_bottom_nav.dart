import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/leaf_sprig_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/tulip_doodle.dart';

/// Geometric shape options for [FloralBottomNav].
enum FloralNavShape {
  /// Floating pill elevated above the screen bottom with 16px side margins and fully rounded stadium ends (radius = height / 2).
  floatingPill,

  /// Docked flush to the screen bottom with large soft 28px rounded top corners.
  dockedSoftRounded,
}

/// Botanical bottom navigation bar featuring handcrafted botanical icons.
///
/// Designed specifically for iPhone 16 standalone mode with correct SafeArea handling,
/// 48px+ tap targets, and an organic blooming scale animation on the selected tab.
/// Inactive tabs use warm soft brown (#8A6B5A / #C9B8AB) for subtle warmth.
class FloralBottomNav extends StatelessWidget {
  /// When true, renders the rich AI-generated watercolor illustration icons.
  /// Set to false to instantly revert back to the vector CustomPainter doodle icons.
  static const bool useWatercolorIcons = true;

  /// Active geometric shape for the bottom navigation bar.
  /// Defaults to [FloralNavShape.floatingPill].
  static FloralNavShape shape = FloralNavShape.floatingPill;

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloralBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return shape == FloralNavShape.floatingPill
        ? _buildFloatingPill(context)
        : _buildDockedSoftRounded(context);
  }

  /// Floating pill elevated above the screen bottom with 16px side margins and fully rounded stadium ends.
  Widget _buildFloatingPill(BuildContext context) {
    const double navHeight = 66.0;
    const double pillRadius = navHeight / 2; // 33.0px = true half-height pill / stadium
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(10.0, bottomInset + 4.0)),
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(pillRadius),
            boxShadow: [
              BoxShadow(
                color: FloralPalette.softShadowTint.withValues(
                  alpha: FloralPalette.isDark ? 0.70 : 0.40,
                ),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(pillRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                height: navHeight,
                decoration: BoxDecoration(
                  color: FloralPalette.isDark
                      ? const Color(0xFF1E1611).withValues(alpha: 0.75)
                      : const Color(0xFFFFFBF5).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(pillRadius),
                  border: Border.all(
                    color: FloralPalette.isDark ? const Color(0x3DF5EBE1) : const Color(0x3D4A3428),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildNavItems(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Docked bar flush to screen edges with large soft 28px rounded top corners.
  Widget _buildDockedSoftRounded(BuildContext context) {
    const double topCornerRadius = 28.0;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(topCornerRadius)),
          boxShadow: [
            BoxShadow(
              color: FloralPalette.softShadowTint.withValues(
                alpha: FloralPalette.isDark ? 0.70 : 0.45,
              ),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(topCornerRadius)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: FloralPalette.isDark
                    ? const Color(0xFF1E1611).withValues(alpha: 0.75)
                    : const Color(0xFFFFFBF5).withValues(alpha: 0.78),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(topCornerRadius)),
                border: Border(
                  top: BorderSide(
                    color: FloralPalette.isDark ? const Color(0x3DF5EBE1) : const Color(0x3D4A3428),
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 66,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildNavItems(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    return [
      _buildNavItem(
        index: 0,
        label: 'Library',
        icon: useWatercolorIcons
            ? _buildWatercolorIcon('assets/icons/nav_poppy.png', isSelected: currentIndex == 0)
            : const PoppyDoodle(
                size: 26,
                showStem: false,
                petalColor: FloralPalette.rosePetal,
              ),
      ),
      _buildNavItem(
        index: 1,
        label: 'Wishlist',
        icon: useWatercolorIcons
            ? _buildWatercolorIcon('assets/icons/nav_tulip.png', isSelected: currentIndex == 1)
            : const TulipDoodle(
                size: 26,
                showStem: false,
                petalColor: FloralPalette.rosePetal,
              ),
      ),
      _buildNavItem(
        index: 2,
        label: 'Stats',
        icon: useWatercolorIcons
            ? _buildWatercolorIcon('assets/icons/nav_daisy.png', isSelected: currentIndex == 2)
            : const DaisyDoodle(
                size: 26,
                showStem: false,
              ),
      ),
      _buildNavItem(
        index: 3,
        label: 'Settings',
        icon: useWatercolorIcons
            ? _buildWatercolorIcon('assets/icons/nav_sprig.png', isSelected: currentIndex == 3)
            : const LeafSprigDoodle(
                size: 26,
              ),
      ),
    ];
  }

  static Widget _buildWatercolorIcon(String assetPath, {required bool isSelected}) {
    return Opacity(
      opacity: isSelected ? 1.0 : 0.88,
      child: Image.asset(
        assetPath,
        width: 26,
        height: 26,
        cacheWidth: 104,
        cacheHeight: 104,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required Widget icon,
  }) {
    final isSelected = currentIndex == index;
    final inactiveColor = FloralPalette.unratedText;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blooming scale animation & subtle rounded background highlight pill
              AnimatedScale(
                scale: isSelected ? 1.14 : 0.95,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FloralPalette.blushPink.withValues(alpha: FloralPalette.isDark ? 0.24 : 0.40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? FloralPalette.deepRose.withValues(alpha: FloralPalette.isDark ? 0.35 : 0.20)
                          : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(child: icon),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: JournalTypography.bodySmall().copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? FloralPalette.deepRose : inactiveColor,
                ),
                child: Text(label),
              ),
              // Non-color active indicator: small botanical dot beneath active label
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4.0 : 0.0,
                height: 4.0,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isSelected ? FloralPalette.deepRose : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
