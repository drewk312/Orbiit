// ═══════════════════════════════════════════════════════════════════════════
// FUSION UI
// Consistent glass, motion, spacing, typography (no branding words).
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class UiColors {
  static const Color spaceBlack = Color(0xFF050508);
  static const Color spaceDark = Color(0xFF0A0A12);
  static const Color spaceMedium = Color(0xFF12121A);
  static const Color spaceLight = Color(0xFF1A1A24);

  static const Color indigo = Color(0xFF6366F1);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);

  static const Color wiiCyan = Color(0xFF00C2FF);
  static const Color gamecubePurple = Color(0xFFB000FF);
  static const Color nintendoRed = Color(0xFFE3001B);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B4C8);
  static const Color textTertiary = Color(0xFF6B6B80);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static const Color bgSecondary = Color(0xFF12121A); // Alias for spaceMedium
  static const Color orbitCyan = Color(0xFF00C2FF); // Alias for wiiCyan

  static const Color error = Color(0xFFEF4444);

  static const Color borderSubtle = Color(0x1AFFFFFF); // 10% white
  static const Color surface = Color(0xFF12121A);

  static Color glassWhite(double opacity) =>
      Color.fromRGBO(255, 255, 255, opacity);
}

class UiGradients {
  static const LinearGradient space = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050508),
      Color(0xFF0A0A12),
      Color(0xFF12121A),
      Color(0xFF0A0A12),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient indigo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1),
      Color(0xFF4F46E5),
      Color(0xFF4338CA),
    ],
  );

  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4),
      Color(0xFF0891B2),
      Color(0xFF0E7490),
    ],
  );

  static LinearGradient shimmer(double progress) => LinearGradient(
        begin: Alignment(-1.0 + progress * 2, 0),
        end: Alignment(-0.5 + progress * 2, 0),
        colors: [
          UiColors.glassWhite(0),
          UiColors.glassWhite(0.1),
          UiColors.glassWhite(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
}

class UiType {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
    color: UiColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: UiColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: UiColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.2,
    color: UiColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    height: 1.1,
    color: UiColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: UiColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: UiColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: UiColors.textTertiary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: UiColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: UiColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: UiColors.textTertiary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: UiColors.textTertiary,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.4,
    color: UiColors.textSecondary,
  );
}

class UiRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double full = 999;
}

class UiShadows {
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.4 * intensity),
          blurRadius: 20,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2 * intensity),
          blurRadius: 40,
          spreadRadius: -8,
        ),
      ];
}

class SectionHeaderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int? count;
  final Color? accent;

  const SectionHeaderRow({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.count,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? UiColors.cyan;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: a.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: a.withValues(alpha: 0.24)),
          ),
          child: Icon(icon, size: 18, color: a.withValues(alpha: 0.95)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: UiType.labelLarge.copyWith(
                  letterSpacing: 1,
                  color: UiColors.textPrimary.withValues(alpha: 0.92),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: UiType.bodySmall),
              ],
            ],
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: a.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: a.withValues(alpha: 0.22)),
            ),
            child: Text(
              '$count',
              style: UiType.labelMedium.copyWith(color: a),
            ),
          ),
      ],
    );
  }
}

class ChipPill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color accent;

  const ChipPill({
    required this.text,
    super.key,
    this.icon,
    this.accent = UiColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent.withValues(alpha: 0.95)),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: UiType.labelMedium.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blurSigma;
  final Color? glowColor;
  final bool enableHover;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = UiRadius.xl,
    this.blurSigma = 16,
    this.glowColor,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => _c.forward() : null,
      onExit: widget.enableHover ? (_) => _c.reverse() : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            return Transform.scale(
              scale: 1.0 + (0.02 * t),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: UiColors.glassWhite(0.06 + (0.04 * t)),
                  border: Border.all(
                    color: UiColors.glassWhite(0.10 + (0.06 * t)),
                    width: 1.2,
                  ),
                  boxShadow: widget.glowColor != null
                      ? UiShadows.glow(widget.glowColor!, intensity: 0.7 * t)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final Color? outlineColor;
  final bool outlined;

  /// Optional font size for the label (default uses UiType.labelLarge)
  final double? fontSize;

  const ActionButton({
    required this.label,
    required this.icon,
    super.key,
    this.onPressed,
    this.gradient,
    this.outlineColor,
    this.outlined = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final oc = outlineColor ?? UiColors.indigo;
    final textStyle = UiType.labelLarge.copyWith(
      color: outlined ? oc : Colors.white,
      fontSize: fontSize,
    );
    final iconSize = (fontSize ?? 14) + 4;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: outlined ? oc : Colors.white,
        ),
        SizedBox(width: fontSize != null ? 6 : 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: fontSize != null ? 28 : 0),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: textStyle,
            ),
          ),
        ),
      ],
    );
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(UiRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize != null ? 10 : 16,
          vertical: fontSize != null ? 10 : 12,
        ),
        decoration: BoxDecoration(
          gradient: outlined ? null : (gradient ?? UiGradients.indigo),
          color: outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(UiRadius.md),
          border: outlined ? Border.all(color: oc, width: 2) : null,
        ),
        child: fontSize != null
            ? content
            : FittedBox(fit: BoxFit.scaleDown, child: content),
      ),
    );
  }
}

class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBlock(
      {required this.width, required this.height, super.key, this.radius = 12});

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: UiGradients.shimmer(_c.value),
          ),
        );
      },
    );
  }
}

class LoadingOrb extends StatefulWidget {
  final Color color;
  final double size;
  const LoadingOrb({required this.color, super.key, this.size = 56});

  @override
  State<LoadingOrb> createState() => _LoadingOrbState();
}

class _LoadingOrbState extends State<LoadingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              endAngle: math.pi * 2 * math.max(_c.value, 0.01),
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.5),
                widget.color.withValues(alpha: 0),
                widget.color,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: UiShadows.glow(widget.color, intensity: 0.6),
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.7,
              height: widget.size * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: UiColors.spaceDark,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compatibility layer for SpaceColors -> UiColors
class SpaceColors {
  static const Color cyanNeon = UiColors.wiiCyan;
  static const Color textPrimary = UiColors.textPrimary;
  static const Color textSecondary = UiColors.textSecondary;
  static const Color background = UiColors.spaceBlack;
  static const Color cardBg = UiColors.spaceMedium;
  static const Color success = UiColors.success;
  static const Color error = UiColors.error;
  static const Color deepSpace = Color(0xFF0B0D17);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [UiColors.wiiCyan, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Holographic Card Widget (Compact alternative to GlassCard)
class HoloCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const HoloCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: UiColors.glassWhite(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: UiColors.glassWhite(0.1)),
      ),
      child: child,
    );
  }
}
