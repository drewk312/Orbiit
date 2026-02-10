// ═══════════════════════════════════════════════════════════════════════════
// COVER ART SERVICE
// WiiGC-Fusion - Multi-source cover art discovery and caching
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
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
  static const String cacheDir = 'cover_cache'; // inside 'Orbiit' folder

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
class CoverArtService {
  // ─────────────────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────────────────

  final List<CoverArtSource> _sources;
  final http.Client _httpClient;

  String? _cacheDir;
  bool _isInitialized = false;
  CoverCacheManifest? _manifest;

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

  CoverArtStats get stats => CoverArtStats(
        cacheHits: _cacheHits,
        cacheMisses: _cacheMisses,
        downloadSuccesses: _downloadSuccesses,
        downloadFailures: _downloadFailures,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

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
    _sources.sort((a, b) => a.priority.compareTo(b.priority));
    _log('Initialized ${_sources.length} cover art sources');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      // Unified cache path under 'Orbiit'
      _cacheDir = path.join(appDir.path, 'Orbiit', _Config.cacheDir);
      final dir = Directory(_cacheDir!);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await _loadManifest();

      // Perform migration if manifest is empty but files exist
      if (_manifest!.entries.isEmpty) {
        final fileCount = await dir.list().length;
        if (fileCount > 1) {
          // >1 because manifest.json might be there
          await _migrateExistingCache(dir);
        }
      }

      _isInitialized = true;
      _log(
          'Cache initialized at $_cacheDir with ${_manifest!.entries.length} entries');
    } catch (e) {
      _log('Failed to initialize cache: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Manifest Management
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadManifest() async {
    try {
      final file = File(path.join(_cacheDir!, 'manifest.json'));
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        _manifest = CoverCacheManifest.fromJson(json);
      } else {
        _manifest = CoverCacheManifest(entries: {});
      }
    } catch (e) {
      _log('Error loading manifest, creating new one: $e');
      _manifest = CoverCacheManifest(entries: {});
    }
  }

  Future<void> _saveManifest() async {
    if (_cacheDir == null || _manifest == null) return;
    try {
      final file = File(path.join(_cacheDir!, 'manifest.json'));
      await file.writeAsString(jsonEncode(_manifest!.toJson()));
    } catch (e) {
      _log('Error saving manifest: $e');
    }
  }

  Future<void> _migrateExistingCache(Directory dir) async {
    _log('Migrating existing cache to manifest...');
    await for (final entity in dir.list()) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        if (filename == 'manifest.json') continue;

        // Attempt to parse filename: {platform}_{safeTitle}_{source}.ext
        // This is heuristic and might not be perfect, but standardizes it.
        // If we can't parse perfectly, we just skip or try best effort.
        // Actually, for getCachedCover to work, we need to key it by what we search for.
        // We search by "platform_safeTitle".

        // Let's iterate keys and see if we can reconstruct.
        // Actually, better to just rely on future downloads updating the manifest?
        // No, that loses existing cache.

        // Format: 'wii_mario_kart_wii_gametdb.png'
        // We know structure is: platform_safeTitle_source.ext
        // We can split by '_'. First part is platform.
        // Last part (before ext) is source.
        // Everything in between is safeTitle.

        try {
          final parts = filename.split('_');
          if (parts.length >= 3) {
            final platformCode = parts[0];
            final sourceWithExt = parts.last;
            final source = path.basenameWithoutExtension(sourceWithExt);
            final safeTitle = parts.sublist(1, parts.length - 1).join('_');

            final key = '${platformCode}_$safeTitle';
            _manifest!.entries[key] = CoverCacheEntry(
              filename: filename,
              source: source,
              fetchedAt: (await entity.lastModified()),
            );
          }
        } catch (e) {
          // Ignore files that don't match pattern
        }
      }
    }
    await _saveManifest();
    _log('Migration complete. ${_manifest!.entries.length} entries indexed.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main API
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> getCoverArt({
    required String gameTitle,
    required GamePlatform platform,
    String? gameId,
    bool forceDownload = false,
  }) async {
    if (!_isInitialized) await initialize();

    final key = _getCacheKey(gameTitle, platform);

    // ── Check Cache First ──
    if (!forceDownload) {
      final entry = _manifest!.entries[key];
      if (entry != null) {
        final file = File(path.join(_cacheDir!, entry.filename));
        if (await file.exists()) {
          // Check expiration
          final age = DateTime.now().difference(entry.fetchedAt);
          if (age.inDays <= _Config.maxCacheAgeDays) {
            _cacheHits++;
            return file.path;
          } else {
            _log('Cache expired for "$gameTitle"');
          }
        } else {
          // Entry exists but file missing - clean up
          _manifest!.entries.remove(key);
          await _saveManifest();
        }
      }
      _cacheMisses++;
    }

    _log('Searching for cover: "$gameTitle" (${platform.displayName})');

    // ── Try Each Source ──
    for (final source in _sources) {
      try {
        if (!await source.isAvailable()) continue;

        CoverArtResult? result;
        if (gameId != null && gameId.length == 6) {
          result = await source.getByGameId(gameId, platform);
        }

        // ✨ Fallback: Fuzzy search by title if ID failed or is generic (like Rom Hacks)
        if (result == null &&
            (gameId == null ||
                gameId.length != 6 ||
                platform == GamePlatform.wii)) {
          // For Rom Hacks specifically or just failed lookups
          result = await source.searchByTitle(gameTitle, platform);
        }

        if (result != null) {
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

        await Future.delayed(_Config.rateLimitDelay);
      } catch (e) {
        _log('Error with ${source.sourceName}: $e');
        _downloadFailures++;
        continue;
      }
    }

    return null;
  }

  Future<Map<String, String>> batchGetCovers({
    required List<GameInfo> games,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <String, String>{};
    int completed = 0;

    for (final game in games) {
      final path = await getCoverArt(
        gameTitle: game.title,
        platform: game.platform,
        gameId: game.gameId,
      );
      if (path != null) results[game.title] = path;

      completed++;
      onProgress?.call(completed, games.length);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download & Cache
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> _downloadAndCache(
    String url,
    String gameTitle,
    GamePlatform platform,
    String sourceName,
  ) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Orbiit/1.0.0', 'Accept': 'image/*'},
      ).timeout(_Config.downloadTimeout);

      if (response.statusCode != 200 ||
          response.bodyBytes.length < _Config.minImageSize) {
        return null;
      }

      final ext = _determineExtension(url, response.headers['content-type']);
      final safeTitle = _sanitizeFilename(gameTitle);
      // Clean up source name for filename
      final safeSource = sourceName.replaceAll(RegExp(r'\W'), '').toLowerCase();

      final filename = '${platform.code}_${safeTitle}_$safeSource$ext';
      final filePath = path.join(_cacheDir!, filename);

      await File(filePath).writeAsBytes(response.bodyBytes);

      // Update Manifest
      final key = _getCacheKey(gameTitle, platform);
      _manifest!.entries[key] = CoverCacheEntry(
        filename: filename,
        source: sourceName,
        fetchedAt: DateTime.now(),
      );
      await _saveManifest();

      return filePath;
    } catch (e) {
      _log('Download error: $e');
      return null;
    }
  }

  String _determineExtension(String url, String? contentType) {
    if (contentType != null) {
      if (contentType.contains('jpeg')) return '.jpg';
      if (contentType.contains('png')) return '.png';
    }
    final lower = url.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
    if (lower.endsWith('.png')) return '.png';
    return '.png';
  }

  String _getCacheKey(String title, GamePlatform platform) {
    return '${platform.code}_${_sanitizeFilename(title)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities & Management
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearCache() async {
    if (_cacheDir == null) return;
    final dir = Directory(_cacheDir!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
    _manifest = CoverCacheManifest(entries: {});
    await _saveManifest();
  }

  Future<int> getCacheSize() async {
    if (_manifest == null) return 0;
    // Rough estimate or iterate files
    int size = 0;
    if (_cacheDir != null) {
      final dir = Directory(_cacheDir!);
      if (await dir.exists()) {
        await for (final f in dir.list()) {
          if (f is File) size += await f.length();
        }
      }
    }
    return size;
  }

  String _sanitizeFilename(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final maxLen = sanitized.length.clamp(0, 50);
    return sanitized.substring(0, maxLen);
  }

  void _log(String message) {
    if (_Config.debugLogging) AppLogger.debug(message, 'CoverArt');
  }

  void dispose() {
    _httpClient.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────

class CoverCacheManifest {
  final Map<String, CoverCacheEntry> entries;
  CoverCacheManifest({required this.entries});

  Map<String, dynamic> toJson() => {
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory CoverCacheManifest.fromJson(Map<String, dynamic> json) {
    final e = json['entries'] as Map<String, dynamic>? ?? {};
    return CoverCacheManifest(
      entries: e.map((k, v) => MapEntry(k, CoverCacheEntry.fromJson(v))),
    );
  }
}

class CoverCacheEntry {
  final String filename;
  final String source;
  final DateTime fetchedAt;

  CoverCacheEntry(
      {required this.filename, required this.source, required this.fetchedAt});

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'source': source,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory CoverCacheEntry.fromJson(Map<String, dynamic> json) {
    return CoverCacheEntry(
      filename: json['filename'],
      source: json['source'],
      fetchedAt: DateTime.parse(json['fetchedAt']),
    );
  }
}

class GameInfo {
  final String title;
  final GamePlatform platform;
  final String? gameId;
  const GameInfo({required this.title, required this.platform, this.gameId});
}

class CoverArtStats {
  final int cacheHits;
  final int cacheMisses;
  final int downloadSuccesses;
  final int downloadFailures;
  const CoverArtStats(
      {required this.cacheHits,
      required this.cacheMisses,
      required this.downloadSuccesses,
      required this.downloadFailures});
}
