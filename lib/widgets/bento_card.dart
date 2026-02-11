import 'dart:ui';
import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final String title;
  final String platform;
  final Color accentColor;
  final VoidCallback? onTap;

  const BentoCard({
    required this.title,
    required this.platform,
    required this.accentColor,
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // THE PULSING DISC
                  _PulsingDisc(color: accentColor),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    platform.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDisc extends StatefulWidget {
  final Color color;
  const _PulsingDisc({required this.color});

  @override
  State<_PulsingDisc> createState() => _PulsingDiscState();
}

class _PulsingDiscState extends State<_PulsingDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 * _controller.value),
                blurRadius: 20,
                spreadRadius: 5 * _controller.value,
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5 * _controller.value),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.blur_on,
              color: widget.color
                  .withValues(alpha: 0.7 + (0.3 * _controller.value)),
              size: 40,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
