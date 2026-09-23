import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/leaf_sprig_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/tulip_doodle.dart';

/// Botanical bottom navigation bar featuring handcrafted vector flower icons.
///
/// Designed specifically for iPhone 16 standalone mode with correct SafeArea handling,
/// 48px+ tap targets, and an organic blooming scale animation on the selected tab.
class FloralBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloralBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF2DED9),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: FloralPalette.softShadowTint.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Library',
                icon: const PoppyDoodle(
                  size: 26,
                  showStem: false,
                  petalColor: FloralPalette.rosePetal, // Blush poppy variant, not full red
                ),
              ),
              _buildNavItem(
                index: 1,
                label: 'Wishlist',
                icon: const TulipDoodle(
                  size: 26,
                  showStem: false,
                  petalColor: FloralPalette.rosePetal,
                ),
              ),
              _buildNavItem(
                index: 2,
                label: 'Stats',
                icon: const DaisyDoodle(
                  size: 26,
                  showStem: false,
                ),
              ),
              _buildNavItem(
                index: 3,
                label: 'Settings',
                icon: const LeafSprigDoodle(
                  size: 24,
                  color: FloralPalette.deepForestGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required Widget icon,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blooming scale animation on selected floral icon
              AnimatedScale(
                scale: isSelected ? 1.18 : 0.95,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FloralPalette.blushPink.withValues(alpha: 0.35)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: JournalTypography.bodySmall().copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? FloralPalette.deepRose
                      : FloralPalette.mutedCharcoal.withValues(alpha: 0.8),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
