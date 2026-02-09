// ═══════════════════════════════════════════════════════════════════════════
// ORBIIT CONSTANTS - Midnight Aurora Edition
// ═══════════════════════════════════════════════════════════════════════════
// Central configuration for app-wide constants, magic numbers, and settings.
// Modify these values to customize behavior without hunting through code.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Application metadata and branding
abstract final class AppMeta {
  static const String name = 'Orbiit';
  static const String version = '1.0.0';
  static const String codename = 'Midnight Aurora';
  static const String author = 'Orbiit Team';
  static const String copyright = '© 2026 $author';

  /// Semantic version components for programmatic comparison
  static const int versionMajor = 1;
  static const int versionMinor = 0;
  static const int versionPatch = 0;
}

/// Window configuration
abstract final class WindowConfig {
  static const Size defaultSize = Size(1100, 700);
  static const Size minimumSize = Size(900, 650);
  static const String title = AppMeta.name;
}

/// Platform detection and magic bytes
abstract final class PlatformMagic {
  /// Wii magic bytes at offset 0x18
  static const int wiiMagic = 0x5D1C9EA3;

  /// GameCube magic bytes at offset 0x1C
  static const int gameCubeMagic = 0xC2339F3D;

  /// WBFS magic header
  static const String wbfsMagic = 'WBFS';

  /// File header offset for platform detection
  static const int headerOffset = 0x1C;
}

/// File formats supported by Orbiit
abstract final class FileFormats {
  /// Supported game file extensions
  static const List<String> gameExtensions = [
    '.iso',
    '.wbfs',
    '.rvz',
    '.gcz',
    '.wia',
    '.ciso',
  ];

  /// Archive extensions that may contain games
  static const List<String> archiveExtensions = ['.zip', '.7z', '.rar'];

  /// Cover art extensions
  static const List<String> imageExtensions = [
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  ];

  /// Check if a file is a supported game format
  static bool isGameFile(String path) {
    final lower = path.toLowerCase();
    return gameExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Check if a file is an archive
  static bool isArchive(String path) {
    final lower = path.toLowerCase();
    return archiveExtensions.any((ext) => lower.endsWith(ext));
  }
}

/// Network configuration
abstract final class NetworkConfig {
  /// Default timeout for HTTP requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Extended timeout for large downloads
  static const Duration downloadTimeout = Duration(minutes: 30);

  /// Timeout for API calls
  static const Duration apiTimeout = Duration(seconds: 15);

  /// Maximum retry attempts for failed requests
  static const int maxRetries = 3;

  /// Delay between retries (exponential backoff base)
  static const Duration retryDelay = Duration(seconds: 2);

  /// User agent string for HTTP requests
  static const String userAgent = '${AppMeta.name}/${AppMeta.version}';

  /// Chunk size for streaming downloads (1MB)
  static const int downloadChunkSize = 1024 * 1024;
}

/// Cache configuration
abstract final class CacheConfig {
  /// Maximum cache size before cleanup (500 MB)
  static const int maxCacheSizeBytes = 500 * 1024 * 1024;

  /// Cover art cache folder name
  static const String coverCacheFolder = 'cover_cache';

  /// Database filename
  static const String databaseFile = 'library.db';

  /// Settings filename
  static const String settingsFile = 'settings.json';

  /// Queue persistence filename
  static const String queueFile = 'queue.json';
}

/// Download queue configuration
abstract final class QueueConfig {
  /// Maximum concurrent downloads
  static const int maxConcurrentDownloads = 3;

  /// Progress polling interval (250ms for 60fps feel)
  static const Duration pollingInterval = Duration(milliseconds: 250);

  /// Minimum file size to be considered valid (1 MB)
  static const int minimumFileSize = 1024 * 1024;
}

/// UI Configuration - Midnight Aurora Standards
abstract final class UIConfig {
  /// Animation durations for 60fps smoothness
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// Animation curves - Midnight Aurora standard
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;

  /// Card dimensions
  static const double cardWidth = 240.0;
  static const double cardAspectRatio = 0.68;

  /// Border radius values - Midnight Aurora luxury standard
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;

  /// Spacing values
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  /// Shadow blur values for layered depth
  static const double shadowAmbient = 60.0;
  static const double shadowGlow = 40.0;
  static const double shadowHighlight = 20.0;

  /// Grid configuration by screen width
  static int gridColumnsForWidth(double width) {
    if (width < 720) return 3;
    if (width < 960) return 4;
    if (width < 1200) return 5;
    return 6;
  }
}

/// Platform-specific colors
abstract final class PlatformColors {
  // Wii Theme (Cyan)
  static const Color wiiPrimary = Color(0xFF00C2FF);
  static const Color wiiGlow = Color(0x4D00C2FF); // 30% opacity
  static const Color wiiAccent = Color(0x8000C2FF); // 50% opacity

  // GameCube Theme (Purple)
  static const Color gameCubePrimary = Color(0xFFB000FF);
  static const Color gameCubeGlow = Color(0x4DB000FF); // 30% opacity
  static const Color gameCubeAccent = Color(0x80B000FF); // 50% opacity

  // Midnight Aurora  - OLED optimized
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF000000); // Pure OLED black
  static const Color lightSurface = Color(0xFFF8F9FA);

  /// Get platform color by name
  static Color forPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'wii':
        return wiiPrimary;
      case 'gamecube':
      case 'gc':
        return gameCubePrimary;
      default:
        return wiiPrimary;
    }
  }
}

/// Cover art source URLs and API endpoints
abstract final class CoverArtEndpoints {
  /// GameTDB cover URL template
  static String gameTDBCover(String gameId, {String region = 'US'}) =>
      'https://art.gametdb.com/wii/cover/$region/$gameId.png';

  /// GameTDB 3D cover URL template
  static String gameTDB3D(String gameId, {String region = 'US'}) =>
      'https://art.gametdb.com/wii/cover3D/$region/$gameId.png';

  /// GameTDB disc URL template
  static String gameTDBDisc(String gameId, {String region = 'US'}) =>
      'https://art.gametdb.com/wii/disc/$region/$gameId.png';

  /// IGDB API base URL
  static const String igdbApi = 'https://api.igdb.com/v4';

  /// MobyGames API base URL
  static const String mobyGamesApi = 'https://api.mobygames.com/v1';

  /// ScreenScraper API base URL
  static const String screenScraperApi = 'https://www.screenscraper.fr/api2';
}

/// Game ID patterns and validation
abstract final class GameIdPatterns {
  /// Wii/GameCube game ID regex (6 characters)
  static final RegExp gameIdRegex = RegExp(r'^[A-Z0-9]{6}$');

  /// Extract game ID from filename pattern: "Game Title [GAMEID].wbfs"
  static final RegExp filenameIdRegex = RegExp(r'\[([A-Z0-9]{6})\]');

  /// Validate a game ID
  static bool isValidGameId(String id) => gameIdRegex.hasMatch(id);

  /// Extract game ID from filename
  static String? extractFromFilename(String filename) {
    final match = filenameIdRegex.firstMatch(filename);
    return match?.group(1);
  }
}

/// Health scoring configuration
abstract final class HealthConfig {
  /// Points deducted per duplicate file
  static const int duplicatePenalty = 5;

  /// Points deducted per critical corruption
  static const int criticalCorruptionPenalty = 20;

  /// Points deducted per high severity issue
  static const int highSeverityPenalty = 10;

  /// Points deducted per missing cover
  static const int missingCoverPenalty = 1;

  /// Points deducted per GB of wasted space (could be RVZ)
  static const double spaceWastePenaltyPerGB = 0.1;

  /// Grade thresholds
  static const int gradeAPlus = 95;
  static const int gradeA = 90;
  static const int gradeBPlus = 85;
  static const int gradeB = 80;
  static const int gradeCPlus = 75;
  static const int gradeC = 70;
  static const int gradeD = 60;
  // Below 60 = F

  /// Get letter grade from score
  static String gradeFromScore(int score) {
    if (score >= gradeAPlus) return 'A+';
    if (score >= gradeA) return 'A';
    if (score >= gradeBPlus) return 'B+';
    if (score >= gradeB) return 'B';
    if (score >= gradeCPlus) return 'C+';
    if (score >= gradeC) return 'C';
    if (score >= gradeD) return 'D';
    return 'F';
  }
}

/// Log levels and debugging
abstract final class LogConfig {
  /// Enable verbose logging in debug builds
  static const bool verboseInDebug = true;

  /// Maximum log file size before rotation (5 MB)
  static const int maxLogFileSize = 5 * 1024 * 1024;

  /// Number of log files to keep
  static const int logFileRetention = 5;
}
