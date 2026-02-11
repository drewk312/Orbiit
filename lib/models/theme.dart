import 'package:flutter/material.dart';

enum WiiGCThemePreset {
  wiiClassic,
  gameCubeIndigo,
  oledBlack,
  retroCRT,
  minimalPro,
}

class WiiGCTheme {
  final WiiGCThemePreset preset;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final double cornerRadius;
  final double spacing;
  final Duration animationDuration;
  final bool reducedMotion;
  final double fontScale;

  // TextTheme proxy to allow easy access in UI
  TextTheme get textTheme {
    // Use a consistent text theme based on lightness/darkness
    final isDark = backgroundColor.computeLuminance() < 0.5;
    final base = isDark
        ? Typography.material2021().englishLike
        : Typography.material2021().black;

    return base.copyWith(
      displayLarge:
          base.displayLarge?.copyWith(fontFamily: 'Orbitron', color: textColor),
      displayMedium: base.displayMedium
          ?.copyWith(fontFamily: 'Orbitron', color: textColor),
      displaySmall:
          base.displaySmall?.copyWith(fontFamily: 'Orbitron', color: textColor),
      headlineMedium: base.headlineMedium?.copyWith(
          fontFamily: 'Orbitron',
          color: textColor,
          fontWeight: FontWeight.bold),
      titleLarge: base.titleLarge
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      bodyLarge:
          base.bodyLarge?.copyWith(color: textColor.withValues(alpha: 0.9)),
      bodyMedium:
          base.bodyMedium?.copyWith(color: textColor.withValues(alpha: 0.8)),
    );
  }

  const WiiGCTheme({
    required this.preset,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.cornerRadius,
    required this.spacing,
    required this.animationDuration,
    this.reducedMotion = false,
    this.fontScale = 1.0,
  });

  static WiiGCTheme getTheme(WiiGCThemePreset preset) {
    switch (preset) {
      case WiiGCThemePreset.wiiClassic:
        return const WiiGCTheme(
          preset: WiiGCThemePreset.wiiClassic,
          primaryColor: Color(0xFF00C2FF),
          secondaryColor: Color(0xFFB000FF),
          backgroundColor: Color(0xFF1A1A1A),
          surfaceColor: Color(0xFF2A2A2A),
          textColor: Colors.white,
          cornerRadius: 8,
          spacing: 8,
          animationDuration: Duration(milliseconds: 300),
        );
      case WiiGCThemePreset.gameCubeIndigo:
        return const WiiGCTheme(
          preset: WiiGCThemePreset.gameCubeIndigo,
          primaryColor: Color(0xFF6A5ACD),
          secondaryColor: Color(0xFF9370DB),
          backgroundColor: Color(0xFF0F0F23),
          surfaceColor: Color(0xFF1A1A3A),
          textColor: Colors.white,
          cornerRadius: 12,
          spacing: 12,
          animationDuration: Duration(milliseconds: 400),
        );
      case WiiGCThemePreset.oledBlack:
        return const WiiGCTheme(
          preset: WiiGCThemePreset.oledBlack,
          primaryColor: Color(0xFF00FF88),
          secondaryColor: Color(0xFFFF0088),
          backgroundColor: Colors.black,
          surfaceColor: Color(0xFF111111),
          textColor: Colors.white,
          cornerRadius: 4,
          spacing: 4,
          animationDuration: Duration(milliseconds: 200),
        );
      case WiiGCThemePreset.retroCRT:
        return const WiiGCTheme(
          preset: WiiGCThemePreset.retroCRT,
          primaryColor: Color(0xFF00FF00),
          secondaryColor: Color(0xFFFF0000),
          backgroundColor: Color(0xFF000000),
          surfaceColor: Color(0xFF0A0A0A),
          textColor: Color(0xFF00FF00),
          cornerRadius: 0,
          spacing: 8,
          animationDuration: Duration(milliseconds: 500),
        );
      case WiiGCThemePreset.minimalPro:
        return const WiiGCTheme(
          preset: WiiGCThemePreset.minimalPro,
          primaryColor: Color(0xFF007AFF),
          secondaryColor: Color(0xFF5856D6),
          backgroundColor: Color(0xFFF2F2F7),
          surfaceColor: Colors.white,
          textColor: Colors.black,
          cornerRadius: 16,
          spacing: 16,
          animationDuration: Duration(milliseconds: 250),
        );
    }
  }

  WiiGCTheme copyWith({
    WiiGCThemePreset? preset,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    double? cornerRadius,
    double? spacing,
    Duration? animationDuration,
    bool? reducedMotion,
    double? fontScale,
  }) {
    return WiiGCTheme(
      preset: preset ?? this.preset,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      spacing: spacing ?? this.spacing,
      animationDuration: animationDuration ?? this.animationDuration,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}
