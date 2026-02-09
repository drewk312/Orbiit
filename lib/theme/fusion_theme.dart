import 'package:flutter/material.dart';

enum FusionThemeMode {
  wiiNostalgia,
  cyberNeon,
  retroWave,
  matrix,
  vaporwave,
  synthwave,
  outrun,
  sunset,
}

class ThemeInfo {
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;
  final bool isDark;

  const ThemeInfo({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
    this.isDark = true,
  });
}

class FusionTheme {
  static ThemeData get wiiNostalgia => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A0E),
        primaryColor: const Color(0xFF00C2FF),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFF00C2FF)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C2FF),
          surface: Color(0xFF0D161E),
        ),
      );

  static ThemeData get cyberNeon => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF00FF88),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFF00FF88)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          surface: Color(0xFF1A1A1A),
        ),
      );

  static ThemeData get retroWave => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E0033),
        primaryColor: const Color(0xFFFF00FF),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFFFF00FF)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF00FF),
          surface: Color(0xFF2D004F),
        ),
      );

  static ThemeData get matrix => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF00FF00),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFF00FF00)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF00),
          surface: Color(0xFF001100),
        ),
      );

  static ThemeData get vaporwave => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E3F),
        primaryColor: const Color(0xFF9D4EDD),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFF9D4EDD)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          surface: Color(0xFF2D2D5F),
        ),
      );

  static ThemeData get synthwave => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        primaryColor: const Color(0xFFFF6B6B),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFFFF6B6B)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B6B),
          surface: Color(0xFF1F1F3F),
        ),
      );

  static ThemeData get outrun => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        primaryColor: const Color(0xFFFF0055),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFFFF0055)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0055),
          surface: Color(0xFF2A2A3E),
        ),
      );

  static ThemeData get sunset => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2D1B69),
        primaryColor: const Color(0xFFFFD700),
        canvasColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          labelMedium: TextStyle(letterSpacing: 2, color: Color(0xFFFFD700)),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          surface: Color(0xFF3D2B79),
        ),
      );

  static ThemeData getTheme(FusionThemeMode mode) {
    switch (mode) {
      case FusionThemeMode.wiiNostalgia:
        return wiiNostalgia;
      case FusionThemeMode.cyberNeon:
        return cyberNeon;
      case FusionThemeMode.retroWave:
        return retroWave;
      case FusionThemeMode.matrix:
        return matrix;
      case FusionThemeMode.vaporwave:
        return vaporwave;
      case FusionThemeMode.synthwave:
        return synthwave;
      case FusionThemeMode.outrun:
        return outrun;
      case FusionThemeMode.sunset:
        return sunset;
    }
  }

  static const Map<FusionThemeMode, ThemeInfo> themeInfo = {
    FusionThemeMode.wiiNostalgia: ThemeInfo(
      name: 'Wii Nostalgia',
      description: 'Classic Wii blue',
      primaryColor: Color(0xFF00C2FF),
      accentColor: Color(0xFF00A0DD),
      icon: Icons.videogame_asset,
    ),
    FusionThemeMode.cyberNeon: ThemeInfo(
      name: 'Cyber Neon',
      description: 'Futuristic green',
      primaryColor: Color(0xFF00FF88),
      accentColor: Color(0xFF00CC66),
      icon: Icons.electric_bolt,
    ),
    FusionThemeMode.retroWave: ThemeInfo(
      name: 'Retro Wave',
      description: '80s synthwave',
      primaryColor: Color(0xFFFF00FF),
      accentColor: Color(0xFFCC00CC),
      icon: Icons.waves,
    ),
    FusionThemeMode.matrix: ThemeInfo(
      name: 'Matrix',
      description: 'Digital green',
      primaryColor: Color(0xFF00FF00),
      accentColor: Color(0xFF00CC00),
      icon: Icons.code,
    ),
    FusionThemeMode.vaporwave: ThemeInfo(
      name: 'Vaporwave',
      description: 'Aesthetic purple',
      primaryColor: Color(0xFF9D4EDD),
      accentColor: Color(0xFF7B3EB8),
      icon: Icons.gradient,
    ),
    FusionThemeMode.synthwave: ThemeInfo(
      name: 'Synthwave',
      description: 'Retro red synth',
      primaryColor: Color(0xFFFF6B6B),
      accentColor: Color(0xFFE55555),
      icon: Icons.music_note,
    ),
    FusionThemeMode.outrun: ThemeInfo(
      name: 'Outrun',
      description: 'Racing red',
      primaryColor: Color(0xFFFF0055),
      accentColor: Color(0xFFCC0044),
      icon: Icons.sports_esports,
    ),
    FusionThemeMode.sunset: ThemeInfo(
      name: 'Sunset',
      description: 'Golden hour',
      primaryColor: Color(0xFFFFD700),
      accentColor: Color(0xFFCCAA00),
      icon: Icons.wb_sunny,
    ),
  };
}
