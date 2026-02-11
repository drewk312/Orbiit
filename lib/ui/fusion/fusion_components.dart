import 'package:flutter/material.dart';
import 'design_system.dart';

class GlowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed; // Changed to nullable
  final Color? color;
  final Color? glowColor; // Added
  final bool isCompact; // Added

  const GlowButton({
    required this.label,
    required this.icon,
    super.key,
    this.onPressed, // Optional now
    this.color,
    this.glowColor,
    this.isCompact = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier to avoid setState in MouseRegion callbacks
  final ValueNotifier<bool> _hovered = ValueNotifier(false);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hovered.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final baseColor = isDisabled
        ? FusionColors.textMuted
        : (widget.color ?? FusionColors.nintendoRed);
    final effectColor = widget.glowColor ?? baseColor;
    final padding = widget.isCompact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return MouseRegion(
      onEnter: (_) => _hovered.value = !isDisabled,
      onExit: (_) => _hovered.value = false,
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, isHovered, child) {
            return AnimatedContainer(
              duration: FusionAnimations.fast,
              padding: padding,
              decoration: BoxDecoration(
                color: baseColor.withValues(
                    alpha: isDisabled ? 0.5 : (isHovered ? 1.0 : 0.8)),
                borderRadius: BorderRadius.circular(FusionRadius.full),
                boxShadow: [
                  if (isHovered && !isDisabled)
                    BoxShadow(
                      color: effectColor.withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      color: Colors.white
                          .withValues(alpha: isDisabled ? 0.7 : 1.0),
                      size: widget.isCompact ? 16 : 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: widget.isCompact
                        ? FusionText.labelLarge.copyWith(
                            color: Colors.white
                                .withValues(alpha: isDisabled ? 0.7 : 1.0))
                        : FusionText.bodyMedium.copyWith(
                            color: Colors.white
                                .withValues(alpha: isDisabled ? 0.7 : 1.0),
                            fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width; // Added
  final double? height; // Added
  final Color? color; // Added (maps to backgroundColor)
  final Color? glowColor; // Added
  final BorderRadius? borderRadius; // Added

  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.width,
    this.height,
    this.color,
    this.glowColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? FusionColors.glass,
          borderRadius: borderRadius ?? BorderRadius.circular(FusionRadius.lg),
          border: Border.all(color: FusionColors.glassBorder),
          boxShadow: [
            if (glowColor != null)
              BoxShadow(
                color: glowColor!.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}
