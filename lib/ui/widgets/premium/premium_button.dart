import 'package:flutter/material.dart';

/// Premium Button - Apple-Style CTA
///
/// Variants:
/// - Primary: Gradient fill, white text
/// - Secondary: Border only, colored text
/// - Destructive: Red gradient
///
/// Features:
/// - Press/hover states with haptic feedback
/// - Icon + label support
/// - Gradient backgrounds
/// - Smooth animations
class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PremiumButtonStyle style;
  final Color? customColor;
  final bool isLoading;
  final double? width;
  final double height;
  final double fontSize;

  const PremiumButton({
    required this.label,
    super.key,
    this.icon,
    this.onPressed,
    this.style = PremiumButtonStyle.primary,
    this.customColor,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.fontSize = 16,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    final color = widget.customColor;

    switch (widget.style) {
      case PremiumButtonStyle.primary:
        if (color != null) {
          return [color, _darken(color, 0.1)];
        }
        return const [Color(0xFF00D4FF), Color(0xFF0EA5E9)];

      case PremiumButtonStyle.destructive:
        return const [Color(0xFFEF4444), Color(0xFFDC2626)];

      case PremiumButtonStyle.secondary:
      case PremiumButtonStyle.ghost:
        return [Colors.transparent, Colors.transparent];
    }
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _getTextColor() {
    switch (widget.style) {
      case PremiumButtonStyle.primary:
      case PremiumButtonStyle.destructive:
        return Colors.white;

      case PremiumButtonStyle.secondary:
      case PremiumButtonStyle.ghost:
        return widget.customColor ?? const Color(0xFF00D4FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final gradientColors = _getGradientColors();
    final textColor = _getTextColor();
    final borderColor = widget.customColor ?? const Color(0xFF00D4FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.style == PremiumButtonStyle.primary ||
                    widget.style == PremiumButtonStyle.destructive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDisabled
                        ? [Colors.grey.shade800, Colors.grey.shade900]
                        : gradientColors,
                  )
                : null,
            color: widget.style == PremiumButtonStyle.ghost
                ? (widget.customColor ?? const Color(0xFF00D4FF))
                    .withOpacity(_isPressed ? 0.15 : (_isHovered ? 0.1 : 0))
                : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.style == PremiumButtonStyle.secondary
                ? Border.all(
                    color: isDisabled
                        ? Colors.grey.shade700
                        : borderColor.withOpacity(
                            _isPressed ? 0.5 : (_isHovered ? 0.4 : 0.3)),
                    width: 1.5,
                  )
                : null,
            boxShadow: widget.style == PremiumButtonStyle.primary && !isDisabled
                ? [
                    BoxShadow(
                      color: (widget.customColor ?? const Color(0xFF00D4FF))
                          .withOpacity(_isHovered ? 0.4 : 0.2),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer effect for primary buttons
                if (widget.style == PremiumButtonStyle.primary && !isDisabled)
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: CustomPaint(
                          painter: _ShimmerPainter(
                            progress: _shimmerAnimation.value,
                            baseColor: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(textColor),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 18,
                                color: isDisabled
                                    ? Colors.grey.shade600
                                    : textColor,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: isDisabled
                                    ? Colors.grey.shade600
                                    : textColor,
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PremiumButtonStyle {
  primary, // Gradient fill
  secondary, // Border only
  destructive, // Red gradient
  ghost, // Transparent, hover background
}

/// Shimmer effect painter
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  _ShimmerPainter({
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withOpacity(0),
          baseColor.withOpacity(0.1),
          baseColor.withOpacity(0),
        ],
        stops: const [0.3, 0.5, 0.7],
        transform: GradientRotation(progress * 3.14159),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
