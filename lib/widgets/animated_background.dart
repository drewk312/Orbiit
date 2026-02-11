import 'dart:math' as math;

import 'package:flutter/material.dart';

enum BackgroundType { gradient, video, particles, premium, aurora }

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final BackgroundType type;
  final Color? primaryColor;
  final Color? secondaryColor;
  final List<Color>? bgGradient;

  const AnimatedBackground({
    required this.child,
    super.key,
    this.type = BackgroundType.premium,
    this.primaryColor,
    this.secondaryColor,
    this.bgGradient,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradController;
  late AnimationController _particleController;

  // Default themes if none provided
  static const _defaultGradient = [
    Color(0xFF0A0512),
    Color(0xFF150A1F),
    Color(0xFF0D0518)
  ];
  static const _defaultPrimary = Color(0xFFB000FF);
  static const _defaultSecondary = Color(0xFF6B00CC);

  @override
  void initState() {
    super.initState();
    _gradController =
        AnimationController(duration: const Duration(seconds: 8), vsync: this)
          ..repeat();
    _particleController =
        AnimationController(duration: const Duration(seconds: 20), vsync: this)
          ..repeat();
  }

  @override
  void dispose() {
    _gradController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type != BackgroundType.premium &&
        widget.type != BackgroundType.particles &&
        widget.type != BackgroundType.aurora) {
      // Simple gradient for other types or fallback
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.bgGradient ?? _defaultGradient,
          ),
        ),
        child: widget.child,
      );
    }

    final primary = widget.primaryColor ?? _defaultPrimary;
    final secondary = widget.secondaryColor ?? _defaultSecondary;
    final gradient = widget.bgGradient ?? _defaultGradient;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Dynamic Gradient
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // 2. Particles
        _ParticleField(
          color: primary,
          controller: _particleController,
        ),

        // 3. Ambient Glows
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          top: -80, // Simplification: removed index dependency for reuse
          right: -80,
          child: _PremiumGlow(
            color: primary,
            size: 380,
            opacity: 0.12,
            controller: _gradController,
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          bottom: -120,
          left: -100,
          child: _PremiumGlow(
            color: secondary,
            size: 320,
            opacity: 0.08,
            controller: _gradController,
            reverse: true,
          ),
        ),

        // 4. Scanlines
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter:
                  _ScanlinesPainter(color: primary.withValues(alpha: 0.015)),
            ),
          ),
        ),

        // 5. Child
        widget.child,
      ],
    );
  }
}

class _ParticleField extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _ParticleField({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(color: color, progress: controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  final double progress;
  final math.Random _random = math.Random(42);

  _ParticlePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 50; i++) {
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final particleSize = _random.nextDouble() * 2.5 + 0.5;
      final speed = _random.nextDouble() * 0.5 + 0.5;
      final opacity = _random.nextDouble() * 0.3 + 0.1;

      final offsetY = math.sin((progress * 2 * math.pi * speed) + i) * 20;
      final offsetX = math.cos((progress * 2 * math.pi * speed * 0.5) + i) * 10;

      paint.color = color.withValues(
          alpha: opacity * (0.5 + 0.5 * math.sin(progress * 2 * math.pi + i)));

      canvas.drawCircle(
          Offset(baseX + offsetX, baseY + offsetY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ScanlinesPainter extends CustomPainter {
  final Color color;
  _ScanlinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PremiumGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final AnimationController controller;
  final bool reverse;

  const _PremiumGlow({
    required this.color,
    required this.size,
    required this.opacity,
    required this.controller,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = reverse ? 1.0 - controller.value : controller.value;
        final pulseOpacity =
            opacity * (0.6 + 0.4 * math.sin(progress * 2 * math.pi));
        final pulseSize =
            size * (0.95 + 0.05 * math.sin(progress * 2 * math.pi));

        return Container(
          width: pulseSize,
          height: pulseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: pulseOpacity),
                color.withValues(alpha: pulseOpacity * 0.5),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        );
      },
    );
  }
}
