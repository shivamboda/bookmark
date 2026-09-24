import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

/// Handcrafted Botanical Blossom Rating Bar.
///
/// Replaces generic Material star icons with handcrafted 5-petal botanical blossoms.
/// Supports:
/// - 0.5 half-step precision (empty, half-filled, full-filled).
/// - Tactile tap toggling (tap once -> full, tap again -> half, tap once more -> clear/drop).
/// - Horizontal drag to scrub rating effortlessly.
/// - Delightful spring bounce micro-animation on interaction.
/// - Read-only mode for compact card and detail displays.
class FloralRatingBar extends StatefulWidget {
  final double? rating; // 0.0 to 5.0, nullable for unrated
  final ValueChanged<double?>? onRatingChanged;
  final bool readOnly;
  final double blossomSize;
  final double spacing;
  final bool showLabel;
  final bool showClearButton;

  const FloralRatingBar({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.readOnly = false,
    this.blossomSize = 34,
    this.spacing = 8,
    this.showLabel = false,
    this.showClearButton = false,
  });

  @override
  State<FloralRatingBar> createState() => _FloralRatingBarState();
}

class _FloralRatingBarState extends State<FloralRatingBar> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  int _lastInteractedIndex = -1;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0.9,
      upperBound: 1.25,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _triggerBounce(int index) {
    setState(() => _lastInteractedIndex = index);
    _bounceController.forward().then((_) {
      if (mounted) _bounceController.reverse();
    });
  }

  void _handleTap(int index) {
    if (widget.readOnly || widget.onRatingChanged == null) return;

    final targetScore = index + 1.0;
    final currentScore = widget.rating ?? 0.0;
    double? newRating;

    if (currentScore == targetScore) {
      // Drop to half
      newRating = targetScore - 0.5;
    } else if (currentScore == targetScore - 0.5) {
      // If dropping from 0.5, clear to null; else set previous full
      newRating = targetScore > 1.0 ? targetScore - 1.0 : null;
    } else {
      // Set to full
      newRating = targetScore;
    }

    _triggerBounce(index);
    widget.onRatingChanged!(newRating);
  }

  void _handleHorizontalDrag(DragUpdateDetails details, double totalWidth) {
    if (widget.readOnly || widget.onRatingChanged == null) return;

    final dx = details.localPosition.dx.clamp(0.0, totalWidth);
    final rawRatio = dx / totalWidth;
    final rawScore = rawRatio * 5.0;

    // Round to nearest 0.5 increment
    final stepped = (rawScore * 2).round() / 2;
    final clamped = stepped.clamp(0.5, 5.0);

    final itemIndex = (clamped.ceil() - 1).clamp(0, 4);
    if (itemIndex != _lastInteractedIndex) {
      _triggerBounce(itemIndex);
    }

    widget.onRatingChanged!(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = widget.rating ?? 0.0;
    final isRated = widget.rating != null && widget.rating! > 0;

    final totalBlossomsWidth = (widget.blossomSize * 5) + (widget.spacing * 4);

    final blossomsRow = GestureDetector(
      onHorizontalDragUpdate: widget.readOnly
          ? null
          : (details) => _handleHorizontalDrag(details, totalBlossomsWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final blossomTarget = index + 1.0;
          double fillFraction = 0.0;

          if (currentScore >= blossomTarget) {
            fillFraction = 1.0;
          } else if (currentScore >= blossomTarget - 0.5) {
            fillFraction = 0.5;
          } else {
            fillFraction = 0.0;
          }

          final isInteracted = index == _lastInteractedIndex;

          final blossomWidget = CustomPaint(
            size: Size(widget.blossomSize, widget.blossomSize),
            painter: BotanicalBlossomPainter(fillFraction: fillFraction),
          );

          if (widget.readOnly) {
            return Padding(
              padding: EdgeInsets.only(right: index < 4 ? widget.spacing : 0),
              child: blossomWidget,
            );
          }

          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? widget.spacing : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('rating_star_${index + 1}'),
                borderRadius: BorderRadius.circular(widget.blossomSize / 2),
                onTap: () => _handleTap(index),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  child: Center(
                    child: isInteracted
                        ? AnimatedBuilder(
                            animation: _bounceController,
                            builder: (context, child) => Transform.scale(
                              scale: _bounceController.value,
                              child: child,
                            ),
                            child: blossomWidget,
                          )
                        : blossomWidget,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );

    if (!widget.showLabel && !widget.showClearButton) {
      return blossomsRow;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel || widget.showClearButton) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showLabel)
                Text(
                  'Rating',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  Text(
                    isRated ? '${widget.rating!.toStringAsFixed(1)} / 5.0' : 'Unrated',
                    style: JournalTypography.bodySmall(
                      color: isRated ? const Color(0xFFD48B28) : FloralPalette.unratedText,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (widget.showClearButton && isRated && !widget.readOnly) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      key: const ValueKey('clear_rating_btn'),
                      onTap: () => widget.onRatingChanged?.call(null),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Clear',
                          style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        blossomsRow,
      ],
    );
  }
}

/// Custom painter for a 5-petal botanical blossom with 0.0, 0.5, and 1.0 fill stages.
class BotanicalBlossomPainter extends CustomPainter {
  final double fillFraction; // 0.0 (empty), 0.5 (half), 1.0 (full)

  const BotanicalBlossomPainter({required this.fillFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final petalRadius = radius * 0.44;
    final petalDist = radius * 0.54;

    final outlinePaint = Paint()
      ..color = fillFraction > 0 ? const Color(0xFFC77826) : const Color(0xFFD9C6B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;

    final unfilledFillPaint = Paint()
      ..color = const Color(0xFFF7F2EE)
      ..style = PaintingStyle.fill;

    final filledPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFDF7A), // Luminous buttercup gold
          Color(0xFFE89A2E), // Rich warm amber gold
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Draw the 5 petals in a circular flower arrangement
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - (pi / 2);
      final px = center.dx + petalDist * cos(angle);
      final py = center.dy + petalDist * sin(angle);
      path.addOval(Rect.fromCircle(center: Offset(px, py), radius: petalRadius));
    }

    if (fillFraction <= 0.0) {
      // Unfilled flower: subtle parchment fill + soft latte outline
      canvas.drawPath(path, unfilledFillPaint);
      canvas.drawPath(path, outlinePaint);
      // Center seed
      canvas.drawCircle(center, radius * 0.22, Paint()..color = const Color(0xFFE5D5C8));
    } else if (fillFraction >= 1.0) {
      // Fully filled flower: vibrant buttercup gold + amber core
      canvas.drawPath(path, filledPaint);
      canvas.drawPath(path, outlinePaint);
      // Center flower pistil / stamen
      canvas.drawCircle(
        center,
        radius * 0.24,
        Paint()..color = const Color(0xFFB5651D),
      );
      canvas.drawCircle(
        center,
        radius * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    } else {
      // Half filled flower: clip left half with filledPaint, right half with unfilled
      // 1. Draw base unfilled
      canvas.drawPath(path, unfilledFillPaint);

      // 2. Clip left half and draw filled
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, center.dx, size.height));
      canvas.drawPath(path, filledPaint);
      canvas.restore();

      // 3. Draw entire outline
      canvas.drawPath(path, outlinePaint);

      // Center pistil (half colored)
      canvas.drawCircle(center, radius * 0.22, Paint()..color = const Color(0xFFE5D5C8));
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, center.dx, size.height));
      canvas.drawCircle(center, radius * 0.22, Paint()..color = const Color(0xFFB5651D));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BotanicalBlossomPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction;
  }
}


/// A compact botanical blossom icon used for ratings on cards, badges, and lists.
class BotanicalBlossomIcon extends StatelessWidget {
  final double size;
  final double fillFraction;

  const BotanicalBlossomIcon({
    super.key,
    this.size = 17,
    this.fillFraction = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: BotanicalBlossomPainter(fillFraction: fillFraction),
      ),
    );
  }
}
