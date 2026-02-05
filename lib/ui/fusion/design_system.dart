import 'package:flutter/material.dart';
export 'fusion_components.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ORBIIT DESIGN SYSTEM — "Your games. In orbit."
// Space-themed, premium, cosmic aesthetic
// ═══════════════════════════════════════════════════════════════════════════

/// Orbiit Color System — Deep space with cyan/purple accents
class OrbColors {
  // === PRIMARY (Space/Orbit-inspired) ===
  static const orbitCyan =
      Color(0xFF00D4FF); // Primary accent — the "i" dot (Wii)
  static const orbitPurple =
      Color(0xFF8B5CF6); // Secondary — the "i" dot (GameCube)
  static const nebulaViolet = Color(0xFF6B3FA0); // Deep nebula
  static const nebulaPink = Color(0xFFE060FF); // Hot nebula gas
  static const starWhite = Color(0xFFF0F4FF); // Bright star white

  // === BACKGROUNDS (Deep Space) ===
  static const void_ = Color(0xFF08080C); // Deepest space — OLED black
  static const bgPrimary = Color(0xFF0D0D12); // Main background — space
  static const bgSecondary = Color(0xFF141419); // Cards, elevated surfaces
  static const bgTertiary = Color(0xFF1A1A22); // Hover states
  static const bgSurface = Color(0xFF20202A); // Input fields, panels

  // === PLATFORM BADGES ===
  static const wii = Color(0xFF00A8E8); // Wii — blue star
  static const gamecube = Color(0xFF6441A5); // GameCube — purple nebula
  static const wiiu = Color(0xFF009AC7); // Wii U — teal
  static const gba = Color(0xFF4F2982); // GBA — violet
  static const snes = Color(0xFF7B7B7B); // SNES — distant star
  static const n64 = Color(0xFF008000); // N64 — green aurora
  static const nes = Color(0xFFCC0000); // NES — red giant
  static const genesis = Color(0xFF1A1A28); // Genesis — dark matter

  // === STATUS ===
  static const ready = Color(0xFF22C55E); // Game is Wii-ready — green
  static const needsFix = Color(0xFFF59E0B); // Needs conversion — amber warning
  static const corrupt = Color(0xFFEF4444); // File corrupt — red alert
  static const downloading = Color(0xFF00D4FF); // In progress — warp blue

  // === TEXT ===
  static const textPrimary =
      Color(0xFFF0F4FF); // Slightly blue-white (starlight)
  static const textSecondary = Color(0xFF9098A8); // Faded starlight
  static const textMuted = Color(0xFF505868); // Distant star

  // === BORDERS ===
  static const border = Color(0xFF1E2030); // Space panel edge
  static const borderHover = Color(0xFF2A3040); // Hover highlight
  static const borderFocus = Color(0xFF00D4FF); // Focus — cyan star
  static const borderGlow = Color(0xFF8B5CF6); // Glow — purple nebula

  // === GLASS (for glassmorphism panels) ===
  static const glass = Color(0x1AFFFFFF); // Default 10% white glass
  static Color glassOpacity(double opacity) =>
      Color.fromRGBO(140, 160, 255, opacity);
  static Color voidGlass(double opacity) => Color.fromRGBO(0, 0, 0, opacity);
  static const glassBorder = Color(0x33FFFFFF);
  static Color glassWhite(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  // === GRADIENTS ===
  static const orbitGradient = [orbitCyan, orbitPurple];
  static const nebulaGradient = [orbitCyan, nebulaViolet, nebulaPink];
  static const spaceGradient = [void_, bgPrimary, bgSecondary];

  // === ALIASES FOR BACKWARDS COMPATIBILITY ===
  static const success = ready;
  static const error = corrupt;
  static const warning = needsFix;
  static const surfaceCard = bgSecondary;
  static const backgroundDark = bgPrimary;
  static const slate = bgSurface;
  static const borderSubtle = border;
  static const textDesc = textSecondary;
  static const wiiBlue = orbitCyan;
  static const cosmicPurple = orbitPurple;
  static const electricCyan = orbitCyan;
  static const nintendoRed = Color(0xFFE60012); // Keep for specific uses
  static const wiiU = wiiu;
  static const nintendoTeal = wiiu;
  static const auroraGradient = orbitGradient;
}

// Backwards compatibility alias
typedef FusionColors = OrbColors;

// ═══════════════════════════════════════════════════════════════════════════
// ORB SHADOWS — Cosmic glow effects
// ═══════════════════════════════════════════════════════════════════════════

class OrbShadows {
  static const small = [
    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
  ];
  static const medium = [
    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
  ];
  static const lg = [
    BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8))
  ];

  // Glow effects for hover states
  static List<BoxShadow> cyanGlow(double intensity) => [
        BoxShadow(
          color: OrbColors.orbitCyan.withValues(alpha: 0.3 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> purpleGlow(double intensity) => [
        BoxShadow(
          color: OrbColors.orbitPurple.withValues(alpha: 0.3 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}

// Backwards compatibility
typedef FusionShadows = OrbShadows;

// ═══════════════════════════════════════════════════════════════════════════
// ORB TEXT — Space-themed typography
// ═══════════════════════════════════════════════════════════════════════════

class OrbText {
  // Space theme uses clean, geometric sans-serif fonts
  // Ideal: Exo 2, Rajdhani, Orbitron (display), or Outfit
  // Fallback: Segoe UI, SF Pro Display
  static const _fontFamily = 'Segoe UI';

  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: OrbColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: OrbColors.textPrimary,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: OrbColors.textPrimary,
  );

  static const headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: OrbColors.textPrimary,
  );

  static const titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: OrbColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: OrbColors.textSecondary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: OrbColors.textSecondary,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: OrbColors.textSecondary,
  );

  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: OrbColors.textPrimary,
  );

  static const labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: OrbColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: OrbColors.textMuted,
  );

  static const textDesc = OrbColors.textMuted;
}

// Backwards compatibility
typedef FusionText = OrbText;
typedef FusionTypography = OrbText;

// ═══════════════════════════════════════════════════════════════════════════
// ORB SPACING — Consistent spacing throughout the app
// ═══════════════════════════════════════════════════════════════════════════

class OrbSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

typedef FusionSpacing = OrbSpacing;

// ═══════════════════════════════════════════════════════════════════════════
// ORB RADIUS — Border radius values
// ═══════════════════════════════════════════════════════════════════════════

class OrbRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const full = 999.0;
}

typedef FusionRadius = OrbRadius;

// ═══════════════════════════════════════════════════════════════════════════
// ORB ANIMATIONS — Smooth, cosmic transitions
// ═══════════════════════════════════════════════════════════════════════════

class OrbAnimations {
  static const fast = Duration(milliseconds: 100); // Button press
  static const normal = Duration(milliseconds: 200); // Hover states
  static const smooth = Duration(milliseconds: 300); // Page transitions
  static const slow = Duration(milliseconds: 500); // Complex animations
  static const cosmic = Duration(milliseconds: 800); // Background effects

  static const curve = Curves.easeOutCubic;
  static const smoothCurve = curve;
  static const snappy = fast;
}

typedef FusionAnimations = OrbAnimations;

// ═══════════════════════════════════════════════════════════════════════════
// ORBIIT APP METADATA
// ═══════════════════════════════════════════════════════════════════════════

class OrbiitApp {
  static const String name = 'Orbiit';
  static const String tagline = 'Your games. In orbit.';
  static const String version = '1.0.0';
  static const String codename = 'Supernova';

  static const String logoPath = 'assets/images/orbiit_logo.svg';
  static const String wordmarkPath = 'assets/images/orbiit_wordmark.svg';
}
