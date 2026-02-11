import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spinning Disc Widget - Animated loading indicator
class SpinningDisc extends StatefulWidget {
  final double size;
  final Color? color;
  final bool isSpinning;
  final Duration spinDuration;

  const SpinningDisc({
    super.key,
    this.size = 56,
    this.color,
    this.isSpinning = true,
    this.spinDuration = const Duration(seconds: 2),
  });

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.spinDuration,
      vsync: this,
    );
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _controller.repeat();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discColor = widget.color ?? Theme.of(context).primaryColor;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _DiscPainter(
              color: discColor,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _DiscPainter extends CustomPainter {
  final Color color;
  final double progress;

  _DiscPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer disc
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outerPaint);

    // Disc ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.85, ringPaint);
    canvas.drawCircle(center, radius * 0.4, ringPaint);

    // Shine effect (rotating)
    final shinePaint = Paint()
      ..shader = SweepGradient(
        startAngle: progress * 2 * math.pi,
        endAngle: (progress * 2 * math.pi) + math.pi / 2,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.85));
    canvas.drawCircle(center, radius * 0.85, shinePaint);

    // Center hole
    final holePaint = Paint()..color = color.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius * 0.15, holePaint);

    // Center highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius * 0.08, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _DiscPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Game Card Loading State with Spinning Disc
class GameCardLoading extends StatelessWidget {
  final String? title;
  final String platform;
  final double? size;

  const GameCardLoading({
    super.key,
    this.title,
    this.platform = 'Unknown',
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spinning disc
          SpinningDisc(
            size: size ?? 56,
            color: primaryColor,
          ),
          const SizedBox(height: 16),
          // Platform badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              platform.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
