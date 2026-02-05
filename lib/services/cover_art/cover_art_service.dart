// ═══════════════════════════════════════════════════════════════════════════
// COVER ART SERVICE
// WiiGC-Fusion - Multi-source cover art discovery and caching
// ═══════════════════════════════════════════════════════════════════════════
//
// This service provides:
//   • Multi-source cover art discovery with intelligent fallback
//   • Local caching for offline access and performance
//   • Batch downloading for library management
//   • Rate limiting to respect API limits
//
// Source Priority (Best to Fallback):
//   1. GameTDB    - Wii/GC specific, high quality, game ID support
//   2. IGDB       - Large database, multiple regions
//   3. MobyGames  - Classic game coverage
//   4. ScreenScraper - Community-curated covers
//
// Cache Architecture:
//   Documents/WiiGC-Fusion/cover_cache/
//   ├── wii_super_mario_galaxy_gametdb.png
//   ├── gc_zelda_wind_waker_igdb.jpg
//   └── ...
//
// Usage:
//   final service = CoverArtService();
//   await service.initialize();
//
//   // Single game lookup
//   final coverPath = await service.getCoverArt(
//     gameTitle: 'Super Mario Galaxy',
//     platform: GamePlatform.wii,
//     gameId: 'RMGE01',
//   );
//
//   // Batch download
//   final results = await service.batchGetCovers(
//     games: libraryGames,
//     onProgress: (done, total) => print('$done/$total'),
//   );
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../globals.dart';
import 'cover_art_source.dart';
import 'sources/gametdb_source.dart';
import 'sources/igdb_source.dart';
import 'sources/mobygames_source.dart';
import 'sources/skraper_source.dart';
import 'sources/libretro_source.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Cover art service configuration
abstract class _Config {
  /// Cache directory name
  static const String cacheDir = 'cover_cache'; // inside 'orbiit' folder

  /// Download timeout duration
  static const Duration downloadTimeout = Duration(seconds: 30);

  /// Minimum valid image size (bytes)
  static const int minImageSize = 1024; // 1KB

  /// Maximum cache age before refresh (days)
  static const int maxCacheAgeDays = 30;

  /// Rate limit delay between requests
  static const Duration rateLimitDelay = Duration(milliseconds: 200);

  /// Enable debug logging
  static const bool debugLogging = true;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COVER ART SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Multi-source cover art download service.
///
/// Searches for game covers across multiple sources in priority order,
/// caching results locally for performance and offline access.
///
/// Source priority: GameTDB → IGDB → MobyGames → ScreenScraper
///
/// Example:
/// ```dart
/// final service = CoverArtService();
/// await service.initialize();
///
/// // Get single cover
/// final path = await service.getCoverArt(
///   gameTitle: 'Mario Kart Wii',
///   platform: GamePlatform.wii,
/// );
///
/// // Check cache stats
/// final size = await service.getCacheSize();
/// print('Cache size: ${size ~/ 1024 ~/ 1024} MB');
/// ```
class CoverArtService {
  // ─────────────────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────────────────

  /// Cover art sources in priority order
  final List<CoverArtSource> _sources;

  /// HTTP client for downloads
  final http.Client _httpClient;

  /// Local cache directory path
  String? _cacheDir;

  /// Whether service has been initialized
  bool _isInitialized = false;

  /// Get region code from game ID (4th character)
  static String getRegionFromGameId(String gameId) {
    if (gameId.length < 4) return 'EN';

    final regionChar = gameId[3].toUpperCase();
    switch (regionChar) {
      case 'E':
      case 'N':
        return 'US';
      case 'J':
        return 'JA';
      case 'K':
      case 'Q':
      case 'T':
        return 'KO';
      case 'R':
        return 'RU';
      case 'W':
        return 'ZH';
      default:
        return 'EN'; // Europe and others
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────────────────────────────────

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _downloadSuccesses = 0;
  int _downloadFailures = 0;

  /// Cache hit rate (0.0 to 1.0)
  double get cacheHitRate {
    final total = _cacheHits + _cacheMisses;
    return total > 0 ? _cacheHits / total : 0;
  }

  /// Get service statistics
  CoverArtStats get stats => CoverArtStats(
        cacheHits: _cacheHits,
        cacheMisses: _cacheMisses,
        downloadSuccesses: _downloadSuccesses,
        downloadFailures: _downloadFailures,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a cover art service.
  ///
  /// Optionally provide custom sources or HTTP client for testing.
  CoverArtService({
    List<CoverArtSource>? sources,
    http.Client? httpClient,
  })  : _sources = sources ?? [],
        _httpClient = httpClient ?? http.Client() {
    if (_sources.isEmpty) {
      _initializeDefaultSources();
    }
  }

  void _initializeDefaultSources() {
    _sources.addAll([
      GameTDBSource(client: _httpClient),
      IGDBSource(client: _httpClient),
      MobyGamesSource(client: _httpClient),
      SkraperSource(client: _httpClient),
      LibRetroSource(client: _httpClient),
    ]);

    // Sort by priority (lower = higher priority)
    _sources.sort((a, b) => a.priority.compareTo(b.priority));
    _log('Initialized ${_sources.length} cover art sources');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize the cache directory.
  ///
  /// Must be called before using getCoverArt or batchGetCovers.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = path.join(appDir.path, 'orbiit', _Config.cacheDir);
      await Directory(_cacheDir!).create(recursive: true);
      _isInitialized = true;
      _log('Cache initialized at $_cacheDir');
    } catch (e) {
      _log('Failed to initialize cache: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main API
  // ─────────────────────────────────────────────────────────────────────────

  /// Get cover art for a game.
  ///
  /// Checks cache first, then tries each source in priority order.
  /// Returns local file path on success, null if not found.
  ///
  /// Parameters:
  /// - [gameTitle]: Game name to search for
  /// - [platform]: Target platform (Wii or GameCube)
  /// - [gameId]: Optional 6-character game ID (e.g., 'RMGE01')
  /// - [forceDownload]: Skip cache check and download fresh
  ///
  /// Example:
  /// ```dart
  /// final path = await service.getCoverArt(
  ///   gameTitle: 'Super Mario Galaxy',
  ///   platform: GamePlatform.wii,
  ///   gameId: 'RMGE01',
  /// );
  ///
  /// if (path != null) {
  ///   Image.file(File(path));
  /// }
  /// ```
  Future<String?> getCoverArt({
    required String gameTitle,
    required GamePlatform platform,
    String? gameId,
    bool forceDownload = false,
  }) async {
    // Ensure initialized
    if (!_isInitialized) await initialize();

    // ── Check Cache First ──
    if (!forceDownload) {
      final cached = await _getCachedCover(gameTitle, platform);
      if (cached != null) {
        _cacheHits++;
        _log('Cache hit for "$gameTitle"');
        return cached;
      }
      _cacheMisses++;
    }

    _log('Searching for cover: "$gameTitle" (${platform.displayName})');

    // ── Try Each Source ──
    for (final source in _sources) {
      try {
        // Check source availability
        if (!await source.isAvailable()) {
          _log('${source.sourceName} not available, skipping');
          continue;
        }

        _log('Trying ${source.sourceName}...');

        CoverArtResult? result;

        // Try by game ID first (more accurate)
        if (gameId != null && gameId.length == 6) {
          result = await source.getByGameId(gameId, platform);
        }

        // Fallback to title search
        result ??= await source.searchByTitle(gameTitle, platform);

        if (result != null) {
          _log('Found on ${source.sourceName}: ${result.sourceUrl}');

          // Download and cache
          final localPath = await _downloadAndCache(
            result.sourceUrl,
            gameTitle,
            platform,
            source.sourceName,
          );

          if (localPath != null) {
            _downloadSuccesses++;
            return localPath;
          }
        }

        // Rate limit between sources
        await Future.delayed(_Config.rateLimitDelay);
      } catch (e) {
        _log('Error with ${source.sourceName}: $e');
        _downloadFailures++;
        continue; // Try next source
      }
    }

    _log('No cover found for "$gameTitle"');
    return null;
  }

  /// Batch download covers for multiple games.
  ///
  /// Processes games sequentially with progress callbacks.
  /// Returns map of game title to local cover path.
  ///
  /// Example:
  /// ```dart
  /// final results = await service.batchGetCovers(
  ///   games: [
  ///     GameInfo(title: 'Mario Kart', platform: GamePlatform.wii),
  ///     GameInfo(title: 'Zelda', platform: GamePlatform.gc),
  ///   ],
  ///   onProgress: (done, total) {
  ///     print('Progress: $done / $total');
  ///   },
  /// );
  /// ```
  Future<Map<String, String>> batchGetCovers({
    required List<GameInfo> games,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <String, String>{};
    int completed = 0;

    _log('Starting batch download for ${games.length} games');

    for (final game in games) {
      try {
        final coverPath = await getCoverArt(
          gameTitle: game.title,
          platform: game.platform,
          gameId: game.gameId,
        );

        if (coverPath != null) {
          results[game.title] = coverPath;
        }
      } catch (e) {
        _log('Batch error for "${game.title}": $e');
      }

      completed++;
      onProgress?.call(completed, games.length);

      // Rate limit between games
      if (completed < games.length) {
        await Future.delayed(_Config.rateLimitDelay);
      }
    }

    _log('Batch complete: ${results.length}/${games.length} covers found');
    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download & Cache
  // ─────────────────────────────────────────────────────────────────────────

  /// Download cover and save to cache
  Future<String?> _downloadAndCache(
    String url,
    String gameTitle,
    GamePlatform platform,
    String sourceName,
  ) async {
    try {
      _log('Downloading from $url');

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Orbiit/1.0.0',
          'Accept': 'image/*',
        },
      ).timeout(_Config.downloadTimeout);

      // Validate response
      if (response.statusCode != 200) {
        _log('Download failed: HTTP ${response.statusCode}');
        return null;
      }

      if (response.bodyBytes.length < _Config.minImageSize) {
        _log('Image too small (${response.bodyBytes.length}B), likely error');
        return null;
      }

      // Determine extension from content-type or URL
      final ext = _determineExtension(url, response.headers['content-type']);

      // Create safe filename
      final safeTitle = _sanitizeFilename(gameTitle);
      final filename =
          '${platform.code}_${safeTitle}_${sourceName.toLowerCase()}$ext';
      final filePath = path.join(_cacheDir!, filename);

      // Write to disk
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _log('Cached: $filename (${_formatBytes(response.bodyBytes.length)})');
      return filePath;
    } on TimeoutException {
      _log('Download timed out');
      return null;
    } catch (e) {
      _log('Download error: $e');
      return null;
    }
  }

  /// Determine image file extension
  String _determineExtension(String url, String? contentType) {
    final urlLower = url.toLowerCase();

    if (urlLower.contains('.jpg') || urlLower.contains('.jpeg')) return '.jpg';
    if (urlLower.contains('.png')) return '.png';
    if (urlLower.contains('.webp')) return '.webp';

    if (contentType != null) {
      if (contentType.contains('jpeg')) return '.jpg';
      if (contentType.contains('png')) return '.png';
      if (contentType.contains('webp')) return '.webp';
    }

    return '.png'; // Default
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Check cache for existing cover
  Future<String?> _getCachedCover(
      String gameTitle, GamePlatform platform) async {
    if (_cacheDir == null) return null;

    final safeTitle = _sanitizeFilename(gameTitle);
    final cacheDir = Directory(_cacheDir!);

    if (!await cacheDir.exists()) return null;

    final prefix = '${platform.code}_$safeTitle';

    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        final basename = path.basename(entity.path);
        if (basename.startsWith(prefix)) {
          // Optionally check age
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inDays <= _Config.maxCacheAgeDays) {
            return entity.path;
          }
        }
      }
    }

    return null;
  }

  /// Clear all cached covers.
  Future<void> clearCache() async {
    if (_cacheDir == null) return;

    final cacheDir = Directory(_cacheDir!);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
      _cacheHits = 0;
      _cacheMisses = 0;
      _log('Cache cleared');
    }
  }

  /// Get total cache size in bytes.
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final file in cacheDir.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  /// Get formatted cache size string.
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSize();
    return _formatBytes(bytes);
  }

  /// Get number of cached covers.
  Future<int> getCachedCoverCount() async {
    if (_cacheDir == null) return 0;

    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) return 0;

    int count = 0;
    await for (final file in cacheDir.list()) {
      if (file is File) count++;
    }
    return count;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────

  String _sanitizeFilename(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    // Use sanitized length, not original (fixes RangeError)
    final maxLen = sanitized.length.clamp(0, 50);
    return sanitized.substring(0, maxLen);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _log(String message) {
    if (_Config.debugLogging) {
      AppLogger.debug(message, 'CoverArt');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────────────

  /// Release resources.
  void dispose() {
    _httpClient.close();
    for (final source in _sources) {
      if (source is GameTDBSource) source.dispose();
      if (source is IGDBSource) source.dispose();
      if (source is MobyGamesSource) source.dispose();
      if (source is SkraperSource) source.dispose();
    }
    _log('Service disposed');
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GAME INFO
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Game information for batch cover downloads.
class GameInfo {
  /// Game display title
  final String title;

  /// Target platform
  final GamePlatform platform;

  /// Optional 6-character game ID
  final String? gameId;

  const GameInfo({
    required this.title,
    required this.platform,
    this.gameId,
  });

  @override
  String toString() =>
      'GameInfo($title [${gameId ?? "no ID"}] - ${platform.displayName})';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COVER ART STATS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Service statistics for monitoring.
class CoverArtStats {
  final int cacheHits;
  final int cacheMisses;
  final int downloadSuccesses;
  final int downloadFailures;

  const CoverArtStats({
    required this.cacheHits,
    required this.cacheMisses,
    required this.downloadSuccesses,
    required this.downloadFailures,
  });

  /// Total requests processed
  int get totalRequests => cacheHits + cacheMisses;

  /// Cache hit rate (0.0 to 1.0)
  double get hitRate => totalRequests > 0 ? cacheHits / totalRequests : 0;

  /// Download success rate (0.0 to 1.0)
  double get downloadRate {
    final total = downloadSuccesses + downloadFailures;
    return total > 0 ? downloadSuccesses / total : 0;
  }

  @override
  String toString() => '''CoverArtStats(
  cacheHits: $cacheHits,
  cacheMisses: $cacheMisses,
  hitRate: ${(hitRate * 100).toStringAsFixed(1)}%,
  downloadSuccesses: $downloadSuccesses,
  downloadFailures: $downloadFailures,
  downloadRate: ${(downloadRate * 100).toStringAsFixed(1)}%
)''';
}
