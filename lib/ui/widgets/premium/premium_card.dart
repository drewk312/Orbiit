import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium Card - Apple Store Quality Container
///
/// Features:
/// - 3-level shadow system (ambient, glow, highlight)
/// - Glass morphism with 20px blur
/// - Hover elevation changes
/// - Configurable glow colors
/// - 28px border radius standard
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? glowColor;
  final bool enableHover;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final List<Color>? gradientColors;
  final double borderRadius;
  final double blurSigma;
  final Border? border;

  const PremiumCard({
    required this.child,
    super.key,
    this.padding,
    this.glowColor,
    this.enableHover = true,
    this.onTap,
    this.width,
    this.height,
    this.gradientColors,
    this.borderRadius = 28,
    this.blurSigma = 20,
    this.border,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultGlowColor = widget.glowColor ?? const Color(0xFF00D4FF);
    final gradientColors = widget.gradientColors ??
        [
          const Color(0xFF1A1A1A).withOpacity(0.9),
          const Color(0xFF0A0A0A).withOpacity(0.95),
        ];

    return MouseRegion(
      onEnter:
          widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown:
            widget.onTap != null ? (_) => _pressController.forward() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _pressController.reverse();
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.onTap != null ? () => _pressController.reverse() : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    // Ambient shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: _isHovered ? 70 : 60,
                      offset: const Offset(0, 20),
                      spreadRadius: -10,
                    ),
                    // Glow shadow
                    BoxShadow(
                      color:
                          defaultGlowColor.withOpacity(_isHovered ? 0.2 : 0.1),
                      blurRadius: _isHovered ? 50 : 40,
                      offset: const Offset(0, 10),
                    ),
                    // Highlight shadow
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        border: widget.border ??
                            Border.all(
                              color: Colors.white
                                  .withOpacity(_isHovered ? 0.15 : 0.08),
                              width: 1.5,
                            ),
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                      ),
                      padding: widget.padding ?? const EdgeInsets.all(32),
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

/// Luxury Color Palette
class LuxuryColors {
  // Primary gradients
  static const cyanGlow = [Color(0xFF00D4FF), Color(0xFF0EA5E9)];
  static const purpleGlow = [Color(0xFF9333EA), Color(0xFF7C3AED)];
  static const amberGlow = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const redGlow = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const greenGlow = [Color(0xFF10B981), Color(0xFF059669)];

  // Surface gradients
  static const darkSurface = [Color(0xFF1A1A1A), Color(0xFF0A0A0A)];
  static const darkestSurface = [Color(0xFF0A0A0A), Color(0xFF000000)];
  static const glassSurface = Color(0xFF000000);

  // Accent colors
  static const cyan = Color(0xFF00D4FF);
  static const purple = Color(0xFF9333EA);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);

  /// Ambient shadow - outermost layer
  static BoxShadow ambient({double blur = 60, bool hovered = false}) =>
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: hovered ? blur + 10 : blur,
        offset: const Offset(0, 20),
        spreadRadius: -10,
      );

  /// Glow shadow - middle layer with color
  static BoxShadow glow(Color color, {bool hovered = false}) => BoxShadow(
        color: color.withOpacity(hovered ? 0.2 : 0.1),
        blurRadius: hovered ? 50 : 40,
        offset: const Offset(0, 10),
      );

  /// Highlight shadow - inner layer
  static BoxShadow highlight({bool hovered = false}) => BoxShadow(
        color: Colors.white.withOpacity(hovered ? 0.08 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, -5),
      );

  /// Get all 3 shadow layers at once
  static List<BoxShadow> layered(Color glowColor, {bool hovered = false}) => [
        ambient(hovered: hovered),
        glow(glowColor, hovered: hovered),
        highlight(hovered: hovered),
      ];
}

/// Premium Typography System
class LuxuryText {
  // Display styles - Hero text
  static const displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -1.5,
    color: Colors.white,
  );

  static const displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -1,
    color: Colors.white,
  );

  static const displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    color: Colors.white,
  );

  // Heading styles - Section titles
  static const headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: Colors.white,
  );

  static const headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: Colors.white,
  );

  // Body styles - Content
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.3,
    color: Colors.white,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
    color: Colors.white,
  );

  // Label styles - UI elements
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
    color: Colors.white,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.8,
    color: Colors.white,
  );

  // Caption styles - Metadata
  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
    color: Colors.white.withOpacity(0.6),
  );

  static TextStyle captionBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.2,
    color: Colors.white.withOpacity(0.7),
  );
}
