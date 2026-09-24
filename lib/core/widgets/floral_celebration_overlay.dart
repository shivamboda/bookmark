import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../doodles/poppy_doodle.dart';
import '../../doodles/acorn_doodle.dart';
import '../../doodles/maple_leaf_doodle.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

/// Triggers the full-screen botanical petal celebration overlay.
void showFloralCelebration(
  BuildContext context, {
  required String bookTitle,
  bool isGoalAchieved = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => FloralCelebrationDialog(
      bookTitle: bookTitle,
      isGoalAchieved: isGoalAchieved,
    ),
  );
}

/// Dialog containing floating petals particle animation and romantic congratulations card.
class FloralCelebrationDialog extends StatefulWidget {
  final String bookTitle;
  final bool isGoalAchieved;

  const FloralCelebrationDialog({
    super.key,
    required this.bookTitle,
    this.isGoalAchieved = false,
  });

  @override
  State<FloralCelebrationDialog> createState() => _FloralCelebrationDialogState();
}

class _FloralCelebrationDialogState extends State<FloralCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_PetalParticle> _particles = [];
  final Random _rng = Random();
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addListener(() {
        _updateParticles();
        setState(() {});
      });

    // Generate 42 romantic botanical particles
    for (int i = 0; i < 42; i++) {
      _particles.add(_PetalParticle.random(_rng));
    }

    _controller.forward();

    // Auto-dismiss after completion
    _autoDismissTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    final progress = _controller.value;
    for (final p in _particles) {
      p.update(progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Particle Canvas spanning the full screen
            Positioned.fill(
              child: CustomPaint(
                painter: _PetalParticlesPainter(particles: _particles),
              ),
            ),

            // Centered Romantic Celebration Card
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent taps on card from closing prematurely
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFF2DED9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: FloralPalette.deepRose.withValues(alpha: 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Signature botanical blooming poppy motif with autumn leaf & acorn accents
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: -28,
                              bottom: -2,
                              child: MapleLeafDoodle(
                                size: 34,
                                color: FloralPalette.rosePetal,
                                angle: -0.32,
                              ),
                            ),
                            const Positioned(
                              right: -24,
                              bottom: 0,
                              child: AcornDoodle(
                                size: 28,
                                angle: 0.22,
                              ),
                            ),
                            PoppyDoodle(
                              size: 74,
                              showStem: false,
                              petalColor: widget.isGoalAchieved
                                  ? FloralPalette.buttercupGold
                                  : FloralPalette.poppyRed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Romantic Caveat handwriting heading
                        Text(
                          widget.isGoalAchieved ? '🌸 Reading Goal Achieved!' : 'Story Completed ~',
                          textAlign: TextAlign.center,
                          style: JournalTypography.handwriting(
                            color: widget.isGoalAchieved ? const Color(0xFFD48B28) : FloralPalette.deepRose,
                          ).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Book Title in Fraunces serif
                        Text(
                          widget.bookTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Romantic closing journal note
                        Text(
                          'Another world explored, another chapter etched into memory.',
                          textAlign: TextAlign.center,
                          style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dismiss button
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.favorite_rounded, size: 16),
                          label: const Text('Cherish & Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FloralPalette.deepRose,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ParticleType { rosePetal, leaf, sparkle }

class _PetalParticle {
  double x; // 0.0 to 1.0 (normalized screen width)
  double y; // 0.0 to 1.0 (normalized screen height)
  final double size;
  final double speedY;
  final double swayFreq;
  final double swayAmp;
  double rotation;
  final double rotationSpeed;
  final Color color;
  final _ParticleType type;

  _PetalParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.swayFreq,
    required this.swayAmp,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.type,
  });

  factory _PetalParticle.random(Random rng) {
    final types = [_ParticleType.rosePetal, _ParticleType.rosePetal, _ParticleType.leaf, _ParticleType.sparkle];
    final type = types[rng.nextInt(types.length)];

    Color color;
    switch (type) {
      case _ParticleType.rosePetal:
        color = [
          FloralPalette.rosePetal,
          FloralPalette.deepRose.withValues(alpha: 0.8),
          FloralPalette.blushPink,
          const Color(0xFFFAD2E1),
        ][rng.nextInt(4)];
        break;
      case _ParticleType.leaf:
        color = FloralPalette.sageGreen.withValues(alpha: 0.85);
        break;
      case _ParticleType.sparkle:
        color = const Color(0xFFE89A2E);
        break;
    }

    return _PetalParticle(
      x: rng.nextDouble(),
      y: -0.15 - (rng.nextDouble() * 0.3), // Staggered start above the screen
      size: 10 + rng.nextDouble() * 14,
      speedY: 0.28 + rng.nextDouble() * 0.35,
      swayFreq: 2.0 + rng.nextDouble() * 4.0,
      swayAmp: 0.04 + rng.nextDouble() * 0.08,
      rotation: rng.nextDouble() * 2 * pi,
      rotationSpeed: (rng.nextDouble() - 0.5) * 4.0,
      color: color,
      type: type,
    );
  }

  void update(double progress) {
    y += speedY * 0.016;
    x += sin(progress * 2 * pi * swayFreq) * (swayAmp * 0.02);
    rotation += rotationSpeed * 0.02;
  }
}

class _PetalParticlesPainter extends CustomPainter {
  final List<_PetalParticle> particles;

  const _PetalParticlesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      if (py < -20 || py > size.height + 20) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      if (p.type == _ParticleType.sparkle) {
        // Star sparkle
        final path = Path()
          ..moveTo(0, -p.size * 0.45)
          ..quadraticBezierTo(0, 0, p.size * 0.45, 0)
          ..quadraticBezierTo(0, 0, 0, p.size * 0.45)
          ..quadraticBezierTo(0, 0, -p.size * 0.45, 0)
          ..quadraticBezierTo(0, 0, 0, -p.size * 0.45);
        canvas.drawPath(path, paint);
      } else {
        // Romantic curved petal / leaf
        final path = Path()
          ..moveTo(0, -p.size / 2)
          ..quadraticBezierTo(p.size * 0.4, 0, 0, p.size / 2)
          ..quadraticBezierTo(-p.size * 0.4, 0, 0, -p.size / 2);
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalParticlesPainter oldDelegate) => true;
}
