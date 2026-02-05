import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ui/fusion/design_system.dart';

class RocketProgressPainter extends CustomPainter {
  final double progress;
  final Animation<double> particleAnimation;
  final Color trackColor;
  final Color barColor;

  RocketProgressPainter({
    required this.progress,
    required this.particleAnimation,
    required this.trackColor,
    required this.barColor,
  }) : super(repaint: particleAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    canvas.drawPath(path, trackPaint);

    // 2. Draw Progress Line
    final progressWidth = size.width * progress;
    final progressPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
      
    // Gradient for the trail
    progressPaint.shader = LinearGradient(
      colors: [barColor.withOpacity(0.0), barColor],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, progressWidth, size.height));

    if (progress > 0.01) {
      canvas.drawLine(
        Offset(0, size.height / 2), 
        Offset(progressWidth, size.height / 2), 
        progressPaint
      );
    }

    // 3. Draw Particles (Smoke)
    final random = math.Random(42); // Seed for consistency per frame if needed, but we want animation
    // Actually we want random positions relative to the rocket

    if (progress > 0) {
      final particleCount = 10;
      for (int i = 0; i < particleCount; i++) {
        final t = (particleAnimation.value + i / particleCount) % 1.0;
        // Particles originate from rocket tail and fade out backwards
        final particleX = progressWidth - (t * 40); // Trail length 40
        if (particleX < 0) continue;
        
        final particleY = size.height / 2 + (math.sin(t * 10 + i) * 5); // Wiggle
        final particleSize = 2.0 + (t * 3); // Grow
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        
        canvas.drawCircle(
          Offset(particleX, particleY),
          particleSize,
          Paint()..color = Colors.white.withOpacity(opacity * 0.5),
        );
      }
    }

    // 4. Draw Rocket
    final rocketX = progressWidth;
    final rocketY = size.height / 2;
    
    canvas.save();
    canvas.translate(rocketX, rocketY);
    // Rotate 45 degrees if using an icon, or draw custom shape
    canvas.rotate(math.pi / 4); 
    
    // Draw simple rocket shape or use icon
    // Using a simple shape for 'pure code' approach
    final rocketPaint = Paint()..color = Colors.white;
    final rPath = Path();
    // Nose
    rPath.moveTo(10, 0); 
    // Body
    rPath.quadraticBezierTo(0, -5, -10, -5);
    rPath.lineTo(-10, 5);
    rPath.quadraticBezierTo(0, 5, 10, 0);
    // Fins
    rPath.moveTo(-8, -5);
    rPath.lineTo(-15, -10);
    rPath.lineTo(-10, -3);
    
    rPath.moveTo(-8, 5);
    rPath.lineTo(-15, 10);
    rPath.lineTo(-10, 3);
    
    canvas.drawPath(rPath, rocketPaint);
    
    // Engine Glow
    canvas.drawCircle(Offset(-10, 0), 3, Paint()..color = Colors.orange..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RocketProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.particleAnimation != particleAnimation;
  }
}

class RocketProgressBar extends StatefulWidget {
  final double progress;
  final Color color;

  const RocketProgressBar({
    super.key,
    required this.progress,
    this.color = const Color(0xFF00D4FF),
  });

  @override
  State<RocketProgressBar> createState() => _RocketProgressBarState();
}

class _RocketProgressBarState extends State<RocketProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: CustomPaint(
        painter: RocketProgressPainter(
          progress: widget.progress.clamp(0.0, 1.0),
          particleAnimation: _controller,
          trackColor: Colors.white.withOpacity(0.1),
          barColor: widget.color,
        ),
      ),
    );
  }
}
