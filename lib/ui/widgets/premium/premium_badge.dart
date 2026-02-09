import 'package:flutter/material.dart';

/// Premium Badge - Status Pills
///
/// Features:
/// - Pill shape (999px radius)
/// - Gradient backgrounds
/// - Pulsing dot for "active" state
/// - Uppercase labels
/// - Optional icons
class PremiumBadge extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool showPulse;
  final PremiumBadgeSize size;
  final List<Color>? gradientColors;

  const PremiumBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.showPulse = false,
    this.size = PremiumBadgeSize.medium,
    this.gradientColors,
  });

  /// Status badges with predefined colors
  factory PremiumBadge.active(String label) => PremiumBadge(
        label: label,
        showPulse: true,
        gradientColors: const [Color(0xFF00D4FF), Color(0xFF0EA5E9)],
      );

  factory PremiumBadge.success(String label) => PremiumBadge(
        label: label,
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
      );

  factory PremiumBadge.warning(String label) => PremiumBadge(
        label: label,
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
      );

  factory PremiumBadge.error(String label) => PremiumBadge(
        label: label,
        gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
      );

  factory PremiumBadge.neutral(String label) => PremiumBadge(
        label: label,
        gradientColors: const [Color(0xFF6B7280), Color(0xFF4B5563)],
      );

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !oldWidget.showPulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && oldWidget.showPulse) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.gradientColors ??
        [
          widget.color ?? const Color(0xFF00D4FF),
          widget.color != null
              ? _darken(widget.color!, 0.1)
              : const Color(0xFF0EA5E9),
        ];

    final sizeValues = _getSizeValues();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeValues.horizontalPadding,
        vertical: sizeValues.verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showPulse) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: sizeValues.dotSize,
                  height: sizeValues.dotSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_pulseAnimation.value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            SizedBox(width: sizeValues.spacing),
          ],
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: sizeValues.iconSize,
              color: Colors.white,
            ),
            SizedBox(width: sizeValues.spacing),
          ],
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: sizeValues.fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: sizeValues.letterSpacing,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  _BadgeSizeValues _getSizeValues() {
    switch (widget.size) {
      case PremiumBadgeSize.small:
        return _BadgeSizeValues(
          horizontalPadding: 8,
          verticalPadding: 4,
          fontSize: 9,
          iconSize: 10,
          dotSize: 6,
          spacing: 4,
          letterSpacing: 0.8,
        );
      case PremiumBadgeSize.medium:
        return _BadgeSizeValues(
          horizontalPadding: 12,
          verticalPadding: 6,
          fontSize: 11,
          iconSize: 12,
          dotSize: 8,
          spacing: 6,
          letterSpacing: 1.0,
        );
      case PremiumBadgeSize.large:
        return _BadgeSizeValues(
          horizontalPadding: 16,
          verticalPadding: 8,
          fontSize: 13,
          iconSize: 14,
          dotSize: 10,
          spacing: 8,
          letterSpacing: 1.2,
        );
    }
  }
}

enum PremiumBadgeSize { small, medium, large }

class _BadgeSizeValues {
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  final double dotSize;
  final double spacing;
  final double letterSpacing;

  _BadgeSizeValues({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
    required this.dotSize,
    required this.spacing,
    required this.letterSpacing,
  });
}
