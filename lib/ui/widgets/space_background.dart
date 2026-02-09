import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../fusion/design_system.dart';

/// Animated space background with stars, nebula clouds, and floating particles
///
/// THE signature visual element of Orbiit — creates the feeling of being
/// on a spaceship looking out into deep space.
class SpaceBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;

  const SpaceBackground({
    super.key,
    required this.child,
    this.enableAnimation = true,
  });

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with TickerProviderStateMixin {
  late AnimationController _nebulaController;
  late AnimationController _twinkleController;
  late List<_Star> _stars;
  late List<_NebulaCloud> _nebulaClouds;

  @override
  void initState() {
    super.initState();

    // Generate stars once (increased count for depth)
    _stars = _generateStars(150);
    _nebulaClouds = _generateNebulaClouds(4);

    // Nebula drift animation (very slow)
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    // Star twinkle animation
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.enableAnimation) {
      _nebulaController.repeat();
      _twinkleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  List<_Star> _generateStars(int count) {
    final random = math.Random(42); // Fixed seed for consistency
    return List.generate(count, (i) {
      final type = random.nextDouble();
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: type < 0.6
            ? 0.5 + random.nextDouble() * 0.5 // 60% tiny dust
            : type < 0.9
                ? 1.0 + random.nextDouble() * 0.8 // 30% normal stars
                : 2.0 + random.nextDouble() * 1.5, // 10% bright stars
        opacity: type < 0.6
            ? 0.2 + random.nextDouble() * 0.2 // dim dust
            : type < 0.9
                ? 0.4 + random.nextDouble() * 0.4 // normal
                : 0.7 + random.nextDouble() * 0.3, // bright
        twinkle: type > 0.85, // Only bright stars twinkle
        color: type > 0.90
            ? (random.nextBool() ? OrbColors.orbitCyan : OrbColors.orbitPurple)
            : OrbColors.starWhite,
      );
    });
  }

  List<_NebulaCloud> _generateNebulaClouds(int count) {
    return [
      // Cyan nebula - upper right
      _NebulaCloud(
        centerX: 0.8,
        centerY: 0.2,
        radius: 0.4,
        color: OrbColors.orbitCyan,
        opacity: 0.05,
        driftX: 0.02,
        driftY: 0.015,
        phase: 0,
      ),
      // Purple nebula - lower left
      _NebulaCloud(
        centerX: 0.2,
        centerY: 0.8,
        radius: 0.45,
        color: OrbColors.orbitPurple,
        opacity: 0.04,
        driftX: -0.015,
        driftY: 0.02,
        phase: 0.33,
      ),
      // Pink nebula - center/left
      _NebulaCloud(
        centerX: 0.3,
        centerY: 0.4,
        radius: 0.35,
        color: OrbColors.nebulaPink,
        opacity: 0.03,
        driftX: 0.01,
        driftY: -0.01,
        phase: 0.66,
      ),
      // Deep Violet nebula - bottom right
      _NebulaCloud(
        centerX: 0.7,
        centerY: 0.7,
        radius: 0.3,
        color: OrbColors.nebulaViolet,
        opacity: 0.04,
        driftX: -0.01,
        driftY: -0.015,
        phase: 0.5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Deep space gradient (static basis)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.2), // Slightly off-center
              radius: 1.5,
              colors: [
                const Color(0xFF1A1A24), // Center glow
                OrbColors.bgPrimary,
                OrbColors.void_,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // Layer 2: Nebula clouds (slow animation)
        if (widget.enableAnimation)
          AnimatedBuilder(
            animation: _nebulaController,
            builder: (context, _) {
              return CustomPaint(
                painter: _NebulaPainter(
                  clouds: _nebulaClouds,
                  animationValue: _nebulaController.value,
                ),
                size: Size.infinite,
              );
            },
          )
        else
          CustomPaint(
            painter: _NebulaPainter(
              clouds: _nebulaClouds,
              animationValue: 0,
            ),
            size: Size.infinite,
          ),

        // Layer 3: Star field
        if (widget.enableAnimation)
          AnimatedBuilder(
            animation: _twinkleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarFieldPainter(
                  stars: _stars,
                  twinkleValue: _twinkleController.value,
                ),
                size: Size.infinite,
              );
            },
          )
        else
          CustomPaint(
            painter: _StarFieldPainter(
              stars: _stars,
              twinkleValue: 0.5,
            ),
            size: Size.infinite,
          ),

        // Layer 4: Vignette (darkens corners)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  OrbColors.void_.withValues(alpha: 0.6),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Layer 5: Content
        widget.child,
      ],
    );
  }
}

/// Individual star data
class _Star {
  final double x; // 0-1 position
  final double y; // 0-1 position
  final double size; // radius in pixels
  final double opacity; // base opacity
  final bool twinkle; // whether to animate
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkle,
    required this.color,
  });
}

/// Nebula cloud data
class _NebulaCloud {
  final double centerX;
  final double centerY;
  final double radius;
  final Color color;
  final double opacity;
  final double driftX;
  final double driftY;
  final double phase;

  _NebulaCloud({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.color,
    required this.opacity,
    required this.driftX,
    required this.driftY,
    required this.phase,
  });
}

/// Custom painter for star field
class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkleValue;

  _StarFieldPainter({
    required this.stars,
    required this.twinkleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Calculate opacity with optional twinkle
      double opacity = star.opacity;
      if (star.twinkle) {
        // Smooth twinkle using sine wave
        final twinkleFactor =
            0.5 + 0.5 * math.sin(twinkleValue * 2 * math.pi + star.x * 10);
        opacity = star.opacity * (0.6 + 0.4 * twinkleFactor);
      }

      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw star
      canvas.drawCircle(Offset(x, y), star.size, paint);

      // Add glow for bright stars
      if (star.size > 1.2 && opacity > 0.4) {
        final glowPaint = Paint()
          ..color = star.color.withValues(alpha: opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), star.size * 2.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) {
    return oldDelegate.twinkleValue != twinkleValue;
  }
}

/// Custom painter for nebula clouds
class _NebulaPainter extends CustomPainter {
  final List<_NebulaCloud> clouds;
  final double animationValue;

  _NebulaPainter({
    required this.clouds,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final cloud in clouds) {
      // Calculate animated position
      final phase = (animationValue + cloud.phase) % 1.0;
      final driftX = math.sin(phase * 2 * math.pi) * cloud.driftX;
      final driftY = math.cos(phase * 2 * math.pi) * cloud.driftY;

      final centerX = (cloud.centerX + driftX) * size.width;
      final centerY = (cloud.centerY + driftY) * size.height;
      final radius = cloud.radius * math.min(size.width, size.height);

      // Draw nebula cloud with radial gradient
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            cloud.color.withValues(alpha: cloud.opacity),
            cloud.color.withValues(alpha: cloud.opacity * 0.5),
            cloud.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius,
        ));

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Simplified static space background for performance-sensitive areas
class StaticSpaceBackground extends StatelessWidget {
  final Widget child;

  const StaticSpaceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.2),
          radius: 1.5,
          colors: [
            const Color(0xFF1A1A24),
            OrbColors.bgPrimary,
            OrbColors.void_,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}
