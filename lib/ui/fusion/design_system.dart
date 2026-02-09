import 'package:flutter/material.dart';
export 'fusion_components.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ORBIIT DESIGN SYSTEM —  "Midnight Aurora"
// Xbox Dashboard-level polish with OLED blacks and space glassmorphism
// ═══════════════════════════════════════════════════════════════════════════

/// FusionColors  — Midnight Aurora Color System
/// OLED-optimized blacks with cyan/purple nebula accents
class FusionColors {
  // === OLED BLACKS (Midnight Aurora Core) ===
  static const void_ = Color(0xFF000000); // Pure OLED Black
  static const abyss = Color(0xFF120C1F); // Deep Purple/Black

  // === BACKGROUNDS ===
  static const bgPrimary = void_; // Pure black primary
  static const bgSecondary = Color(0xFF0F1016); // Elevated cards
  static const bgTertiary = Color(0xFF181820); // Hover states
  static const bgSurface = Color(0xFF20202A); // Input fields

  // === TEXT (Starlight) ===
  static const starlight = Color(0xFFE2E8F0); // Primary text (Midnight Aurora)
  static const textPrimary = starlight; // Alias
  static const textSecondary = Color(0xFF94A3B8); // Secondary text
  static const textMuted = Color(0xFF64748B); // Muted text
  static const textDisabled = Color(0xFF475569); // Disabled state

  // === BRAND COLORS (Nebula) ===
  static const nebulaCyan = Color(0xFF00D4FF); // Wii Brand Color
  static const nebulaPurple = Color(0xFF8B5CF6); // GameCube Brand Color
  static const nebulaViolet = Color(0xFF7C3AED); // Deep violet
  static const nebulaPink = Color(0xFFEC4899); // Hot pink nebula

  // === PLATFORM BADGES ===
  static const wii = nebulaCyan; // Wii cyan
  static const gamecube = nebulaPurple; // GameCube purple
  static const wiiu = Color(0xFF0EA5E9); // Wii U sky blue
  static const gba = Color(0xFF6366F1); // GBA indigo
  static const snes = Color(0xFF94A3B8); // SNES slate
  static const n64 = Color(0xFF22C55E); // N64 green
  static const nes = Color(0xFFEF4444); // NES red
  static const genesis = Color(0xFF111827); // Genesis dark

  // === STATUS COLORS ===
  static const success = Color(0xFF10B981); // Success green
  static const warning = Color(0xFFF59E0B); // Warning amber
  static const error = Color(0xFFEF4444); // Error red
  static const ready = success;
  static const needsFix = warning;
  static const corrupt = error;
  static const downloading = nebulaCyan;

  // === GLASS (Midnight Aurora Glassmorphism) ===
  static const glass = Color(0x0DFFFFFF); // 5% white
  static const glassBorder =
      Color(0x1AFFFFFF); // 10% white (Midnight Aurora spec)

  /// Create glass color with custom opacity
  static Color glassOpacity(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  /// Create glass black with custom opacity
  static Color glassBlack(double opacity) =>
      Colors.black.withValues(alpha: opacity);

  static Color glassWhite(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  // === BORDERS ===
  static const border = Color(0xFF1E293B); // Subtle border
  static const borderHover = Color(0xFF334155); // Hover highlight
  static const borderFocus = nebulaCyan; // Active focus
  static const borderGlow = nebulaPurple; // Glow effect

  // === GRADIENTS ===
  static const auroraGradient = LinearGradient(
    colors: [nebulaCyan, nebulaPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const deepSpaceGradient = LinearGradient(
    colors: [void_, abyss],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // === BACKWARD COMPATIBILITY ALIASES ===
  static const orbitCyan = nebulaCyan;
  static const orbitPurple = nebulaPurple;
  static const orbitYellow = warning; // Yellow alias
  static const starWhite = starlight;
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = success;
  static const accentAmber = warning;
  static const accentRed = error;
  static const amber = warning;
  static const surfaceCard = bgSecondary;
  static const backgroundDark = bgPrimary;
  static const wiiBlue = nebulaCyan;
  static const cosmicPurple = nebulaPurple;
  static const borderSubtle = border;
  static const electricCyan = nebulaCyan;
  static const nintendoRed = error;
  static const nintendoTeal = wiiu;
  static const wiiU = wiiu;
  static const orbitGradient = auroraGradient;
}

/// Backward compatibility typedef
/// @deprecated Use FusionColors instead
typedef OrbColors = FusionColors;

// ═══════════════════════════════════════════════════════════════════════════
// FUSION SHADOWS — Cosmic glow effects
// ═══════════════════════════════════════════════════════════════════════════

class FusionShadows {
  static const small = [
    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
  ];
  static const medium = [
    BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))
  ];
  static const large = [
    BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 8))
  ];
  static const lg = large;

  // Neon Glows
  static List<BoxShadow> cyanGlow(double intensity) => [
        BoxShadow(
          color: FusionColors.nebulaCyan.withValues(alpha: 0.25 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: FusionColors.nebulaCyan.withValues(alpha: 0.1 * intensity),
          blurRadius: 32 * intensity,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> purpleGlow(double intensity) => [
        BoxShadow(
          color: FusionColors.nebulaPurple.withValues(alpha: 0.25 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: FusionColors.nebulaPurple.withValues(alpha: 0.1 * intensity),
          blurRadius: 32 * intensity,
          spreadRadius: 4,
        ),
      ];

  // Generic Glow
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.1 * intensity),
          blurRadius: 32 * intensity,
          spreadRadius: 4,
        ),
      ];
}

/// @deprecated Use FusionShadows instead
typedef OrbShadows = FusionShadows;

// ═══════════════════════════════════════════════════════════════════════════
// FUSION TYPOGRAPHY — Tech-focused, Clean, Modern
// ═══════════════════════════════════════════════════════════════════════════

class FusionText {
  static const _fontFamily = 'Segoe UI';

  // Display — For Hero sections
  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: FusionColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: FusionColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Headlines — For Section titles
  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: FusionColors.textPrimary,
    letterSpacing: -0.25,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: FusionColors.textPrimary,
  );

  // Titles — For Cards
  static const titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FusionColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: FusionColors.textPrimary,
    letterSpacing: 0.1,
  );

  // Body — For Content
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FusionColors.textSecondary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: FusionColors.textSecondary,
    height: 1.4,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FusionColors.textMuted,
  );

  // Labels — For Buttons and Badges
  static const labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Aliases
  static const caption = bodySmall;
  static const textDesc = bodySmall;
  static const headlineSmall = headlineMedium;
}

// Backwards compatibility
/// @deprecated Use FusionText instead
typedef OrbText = FusionText;
typedef FusionTypography = FusionText;

// ═══════════════════════════════════════════════════════════════════════════
// FUSION SPACING & RADIUS
// ═══════════════════════════════════════════════════════════════════════════

class FusionSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0; // Increased base spacing for clearer layout
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

class FusionRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const full = 9999.0;
}

/// @deprecated Use FusionSpacing instead
typedef OrbSpacing = FusionSpacing;

/// @deprecated Use FusionRadius instead
typedef OrbRadius = FusionRadius;

// ═══════════════════════════════════════════════════════════════════════════
// FUSION ANIMATIONS
// ═══════════════════════════════════════════════════════════════════════════

class FusionAnimations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 600);
  static const cosmic = Duration(milliseconds: 1200); // For backgrounds

  static const curve = Curves.easeOutCubic;
  static const bounce = Curves.elasticOut;

  // Aliases
  static const smooth = medium;
  static const normal = medium;
  static const snappy = fast;
}

/// @deprecated Use FusionAnimations instead
typedef OrbAnimations = FusionAnimations;

// ═══════════════════════════════════════════════════════════════════════════
// METADATA
// ═══════════════════════════════════════════════════════════════════════════

class OrbiitApp {
  static const String name = 'Orbiit';
  static const String tagline = 'Your games. In orbit.';
  static const String version = '1.0.0';
  static const String codename = 'Midnight Aurora';
}
