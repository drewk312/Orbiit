import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpaceRocketLoader extends StatelessWidget {
  final double progress;
  final double height;
  final double width;

  const SpaceRocketLoader({
    required this.progress,
    super.key,
    this.height = 60,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    // Smoothly interpolate the progress value for the rocket movement
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 500),
      curve: Curves
          .easeOutBack, // Slight overshoot makes the rocket feel heavy/real
      builder: (context, animatedProgress, child) {
        return SizedBox(
          height: height,
          width: width,
          child: _ParticleEngine(progress: animatedProgress),
        );
      },
    );
  }
}

class _ParticleEngine extends StatefulWidget {
  final double progress;

  const _ParticleEngine({required this.progress});

  @override
  State<_ParticleEngine> createState() => _ParticleEngineState();
}

class _ParticleEngineState extends State<_ParticleEngine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // We use a list of random values to make the smoke look chaotic but consistent
  final List<double> _randomSeeds =
      List.generate(20, (index) => math.Random().nextDouble());

  @override
  void initState() {
    super.initState();
    // High speed loop for the jittery engine fire
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpaceRocketPainter(
        progress: widget.progress,
        animationValue: _controller,
        randomSeeds: _randomSeeds,
      ),
    );
  }
}

class SpaceRocketPainter extends CustomPainter {
  final double progress;
  final Animation<double> animationValue;
  final List<double> randomSeeds;

  SpaceRocketPainter({
    required this.progress,
    required this.animationValue,
    required this.randomSeeds,
  }) : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    // Calculate rocket nose position
    final rocketTipX = size.width * progress;
    // How long the rocket is (visual scale)
    const rocketLength = 40.0;

    // 1. Draw The "Space Track" (Background)
    // Instead of a solid line, let's draw a series of faint dots (stars)
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // Draw 10 "stars" along the path
    for (int i = 0; i < 10; i++) {
      final double starX = (size.width / 10) * i + (size.width / 20);
      if (starX > rocketTipX) {
        // Only draw stars ahead of the rocket
        canvas.drawCircle(Offset(starX, centerY), 1.5, trackPaint);
      }
    }

    // 2. Draw The Exhaust (Fire & Smoke)
    if (progress > 0.01) {
      _drawExhaust(canvas, rocketTipX - rocketLength + 5, centerY, size.height);
    }

    // 3. Draw The Retro Rocket
    canvas.save();
    canvas.translate(rocketTipX, centerY);
    _drawCoolRocket(canvas, rocketLength);
    canvas.restore();
  }

  void _drawExhaust(
      Canvas canvas, double tailX, double centerY, double maxHeight) {
    final loop = animationValue.value;

    // A. The Core Flame (High energy, close to tail)
    // We draw a jittery triangle
    final flamePath = Path();
    flamePath.moveTo(0, 0); // At rocket tail

    // Fluctuate flame length
    final double flameLen = -15.0 - (math.sin(loop * math.pi * 4) * 4);

    flamePath.lineTo(flameLen, -3);
    flamePath.lineTo(flameLen - 2, 0); // Tip of flame
    flamePath.lineTo(flameLen, 3);
    flamePath.close();

    // Shift flame to world coordinates
    final flameMatrix = Matrix4.identity()..translate(tailX, centerY);

    canvas.drawPath(
        flamePath.transform(flameMatrix.storage),
        Paint()
          ..color = const Color(0xFFFF5722) // Deep Orange
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    canvas.drawPath(
        flamePath.transform(flameMatrix.storage),
        Paint()
          ..color = const Color(0xFFFFC107) // Yellow Core
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // B. The Smoke Plume (Expanding clouds)
    // We use the seeds to draw expanding circles trailing behind
    for (int i = 0; i < randomSeeds.length; i++) {
      // Create a "time" value for this particle based on loop + index
      // This creates the "conveyor belt" effect of smoke moving backwards
      final double t = (loop + (i / randomSeeds.length)) % 1.0;

      // Position: Moves from tail (0) backwards
      // We limit the trail length based on progress so smoke doesn't appear at x=0 instantly
      final double maxTrail = math.min(100, tailX);
      final double dx = t * maxTrail;

      final double currentX = tailX - dx;
      if (currentX < 0) continue; // Don't draw off screen

      // Turbulence: Random Y offset that grows as it gets further away
      // randomSeeds[i] gives us a consistent "lane" for this particle
      final double turbulence = (randomSeeds[i] - 0.5) * 20 * t;
      final double currentY = centerY + turbulence;

      // Size: Grows as it moves away
      final double radius = 3.0 + (t * 12.0);

      // Color: Transition from Orange -> Grey -> Transparent
      Color smokeColor;
      if (t < 0.2) {
        smokeColor = Color.lerp(Colors.orange, Colors.grey, t * 5)!;
      } else {
        smokeColor = Colors.grey.shade400;
      }

      // Opacity: Fades out at the end
      final double opacity = (1.0 - t).clamp(0.0, 1.0);

      canvas.drawCircle(Offset(currentX, currentY), radius,
          Paint()..color = smokeColor.withOpacity(opacity * 0.5));
    }
  }

  void _drawCoolRocket(Canvas canvas, double length) {
    // Scale everything relative to length (approx 40px)
    // Drawing a classic Sci-Fi "Tintin" style rocket

    // We are at (0,0) which is the NOSE of the rocket.
    // So we draw backwards (negative X).

    final paintBody = Paint()..color = const Color(0xFFEEEEEE); // Silver/White
    final paintRed = Paint()..color = const Color(0xFFD32F2F); // Red Fins
    final paintWindow = Paint()..color = const Color(0xFF29B6F6); // Cyan Window

    // 1. Fins (Draw first so they are behind body)
    final pathFins = Path();
    // Top Fin
    pathFins.moveTo(-25, -6);
    pathFins.lineTo(-35, -12);
    pathFins.lineTo(-30, -4);
    // Bottom Fin
    pathFins.moveTo(-25, 6);
    pathFins.lineTo(-35, 12);
    pathFins.lineTo(-30, 4);

    canvas.drawPath(pathFins, paintRed);

    // 2. Main Body (Teardrop shape)
    final pathBody = Path();
    pathBody.moveTo(0, 0); // Nose
    pathBody.quadraticBezierTo(-10, -8, -30, -8); // Top curve
    pathBody.lineTo(-32, -8);
    pathBody.lineTo(-32, 8); // Back engine block
    pathBody.lineTo(-30, 8);
    pathBody.quadraticBezierTo(-10, 8, 0, 0); // Bottom curve
    pathBody.close();

    // Add shadow/gradient to body for 3D look
    paintBody.shader = const LinearGradient(
      colors: [Colors.white, Color(0xFFBDBDBD)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(const Rect.fromLTWH(-40, -10, 40, 20));

    canvas.drawPath(pathBody, paintBody);

    // 3. Porthole Window
    canvas.drawCircle(
        const Offset(-15, 0), 4, Paint()..color = Colors.grey.shade300); // Rim
    canvas.drawCircle(const Offset(-15, 0), 3, paintWindow); // Glass
    // Glint on window
    canvas.drawCircle(const Offset(-16, -1), 1, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant SpaceRocketPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue;
  }
}
