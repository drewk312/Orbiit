import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MYRIENT CACHE - PERSISTENT STORAGE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages persistent caching of Myrient directory listings to disk.
/// Features:
/// - JSON file storage in app documents directory
/// - 24-hour cache expiration
/// - Atomic writes to prevent corruption
/// - Fast cache validation and lookup
///
/// ═══════════════════════════════════════════════════════════════════════════

class MyrientCache {
  static const String _cacheDirectoryName = 'myrient_cache';
  static const String _manifestFileName = 'cache_manifest.json';
  static const int _cacheVersion = 1;
  static const Duration _cacheExpiration = Duration(hours: 24);

  Directory? _cacheDir;
  CacheManifest? _manifest;

  /// Initialize the cache system
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir =
          Directory(path.join(appDir.path, 'Orbiit', _cacheDirectoryName));

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
        debugPrint(
            '[MyrientCache] Created cache directory: ${_cacheDir!.path}');
      }

      await _loadManifest();
      debugPrint('[MyrientCache] Initialized successfully');
    } catch (e) {
      debugPrint('[MyrientCache] Initialization error: $e');
    }
  }

  /// Load the cache manifest
  Future<void> _loadManifest() async {
    try {
      final manifestFile = File(path.join(_cacheDir!.path, _manifestFileName));

      if (await manifestFile.exists()) {
        final contents = await manifestFile.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        _manifest = CacheManifest.fromJson(json);
        debugPrint(
            '[MyrientCache] Loaded manifest with ${_manifest!.sources.length} sources');
      } else {
        _manifest = CacheManifest(version: _cacheVersion, sources: {});
        await _saveManifest();
        debugPrint('[MyrientCache] Created new manifest');
      }
    } catch (e) {
      debugPrint('[MyrientCache] Error loading manifest: $e');
      _manifest = CacheManifest(version: _cacheVersion, sources: {});
    }
  }

  /// Save the cache manifest
  Future<void> _saveManifest() async {
    try {
      final manifestFile = File(path.join(_cacheDir!.path, _manifestFileName));
      final json = _manifest!.toJson();

      // Atomic write: write to temp file, then rename
      final tempFile = File('${manifestFile.path}.tmp');
      await tempFile.writeAsString(jsonEncode(json));
      await tempFile.rename(manifestFile.path);

      debugPrint('[MyrientCache] Saved manifest');
    } catch (e) {
      debugPrint('[MyrientCache] Error saving manifest: $e');
    }
  }

  /// Check if cache exists and is valid for a source
  bool isCacheValid(String sourceKey) {
    if (_manifest == null || !_manifest!.sources.containsKey(sourceKey)) {
      return false;
    }

    final sourceInfo = _manifest!.sources[sourceKey]!;
    final age = DateTime.now().difference(sourceInfo.fetchedAt);

    return age < _cacheExpiration;
  }

  /// Get cache age for a source
  DateTime? getCacheAge(String sourceKey) {
    if (_manifest == null || !_manifest!.sources.containsKey(sourceKey)) {
      return null;
    }
    return _manifest!.sources[sourceKey]!.fetchedAt;
  }

  /// Load cached games for a source
  Future<List<MyrientGameEntry>?> loadCache(String sourceKey) async {
    if (!isCacheValid(sourceKey)) {
      debugPrint('[MyrientCache] Cache invalid or expired for: $sourceKey');
      return null;
    }

    try {
      final cacheFile = File(path.join(_cacheDir!.path, '$sourceKey.json'));

      if (!await cacheFile.exists()) {
        debugPrint('[MyrientCache] Cache file not found: $sourceKey');
        return null;
      }

      final contents = await cacheFile.readAsString();
      final List<dynamic> json = jsonDecode(contents);
      final games = json
          .map((e) => MyrientGameEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
          '[MyrientCache] Loaded ${games.length} games from cache: $sourceKey');
      return games;
    } catch (e) {
      debugPrint('[MyrientCache] Error loading cache for $sourceKey: $e');
      return null;
    }
  }

  /// Save games to cache for a source
  Future<void> saveCache(
      String sourceKey, List<MyrientGameEntry> games, String platform) async {
    try {
      final cacheFile = File(path.join(_cacheDir!.path, '$sourceKey.json'));
      final json = games.map((g) => g.toJson()).toList();

      // Atomic write
      final tempFile = File('${cacheFile.path}.tmp');
      await tempFile.writeAsString(jsonEncode(json));
      await tempFile.rename(cacheFile.path);

      // Update manifest
      _manifest!.sources[sourceKey] = CacheSourceInfo(
        fetchedAt: DateTime.now(),
        gameCount: games.length,
        fileSize: await cacheFile.length(),
        platform: platform,
      );
      await _saveManifest();

      debugPrint(
          '[MyrientCache] Saved ${games.length} games to cache: $sourceKey');
    } catch (e) {
      debugPrint('[MyrientCache] Error saving cache for $sourceKey: $e');
    }
  }

  /// Get all cached source keys
  List<String> getCachedSources() {
    return _manifest?.sources.keys.toList() ?? [];
  }

  /// Get total number of cached games
  int getTotalCachedGames() {
    if (_manifest == null) return 0;
    return _manifest!.sources.values
        .fold(0, (sum, info) => sum + info.gameCount);
  }

  /// Clear cache for a specific source
  Future<void> clearSource(String sourceKey) async {
    try {
      final cacheFile = File(path.join(_cacheDir!.path, '$sourceKey.json'));
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      _manifest!.sources.remove(sourceKey);
      await _saveManifest();
      debugPrint('[MyrientCache] Cleared cache: $sourceKey');
    } catch (e) {
      debugPrint('[MyrientCache] Error clearing cache for $sourceKey: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await for (final entity in _cacheDir!.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            await entity.delete();
          }
        }
      }
      _manifest = CacheManifest(version: _cacheVersion, sources: {});
      await _saveManifest();
      debugPrint('[MyrientCache] Cleared all cache');
    } catch (e) {
      debugPrint('[MyrientCache] Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    if (_manifest == null) {
      return {
        'totalGames': 0,
        'sources': 0,
        'oldestCache': null,
        'newestCache': null,
      };
    }

    DateTime? oldest;
    DateTime? newest;

    for (final info in _manifest!.sources.values) {
      if (oldest == null || info.fetchedAt.isBefore(oldest)) {
        oldest = info.fetchedAt;
      }
      if (newest == null || info.fetchedAt.isAfter(newest)) {
        newest = info.fetchedAt;
      }
    }

    return {
      'totalGames': getTotalCachedGames(),
      'sources': _manifest!.sources.length,
      'oldestCache': oldest,
      'newestCache': newest,
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

/// Represents a single game entry in the cache
class MyrientGameEntry {
  final String title;
  final String url;
  final int size;
  final String platform;
  final String format;

  MyrientGameEntry({
    required this.title,
    required this.url,
    required this.size,
    required this.platform,
    required this.format,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'size': size,
        'platform': platform,
        'format': format,
      };

  factory MyrientGameEntry.fromJson(Map<String, dynamic> json) {
    return MyrientGameEntry(
      title: json['title'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      platform: json['platform'] as String,
      format: json['format'] as String,
    );
  }
}

/// Information about a cached source
class CacheSourceInfo {
  final DateTime fetchedAt;
  final int gameCount;
  final int fileSize;
  final String platform;

  CacheSourceInfo({
    required this.fetchedAt,
    required this.gameCount,
    required this.fileSize,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'fetchedAt': fetchedAt.toIso8601String(),
        'gameCount': gameCount,
        'fileSize': fileSize,
        'platform': platform,
      };

  factory CacheSourceInfo.fromJson(Map<String, dynamic> json) {
    return CacheSourceInfo(
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      gameCount: json['gameCount'] as int,
      fileSize: json['fileSize'] as int,
      platform: json['platform'] as String,
    );
  }
}

/// Cache manifest containing metadata for all cached sources
class CacheManifest {
  final int version;
  final Map<String, CacheSourceInfo> sources;

  CacheManifest({
    required this.version,
    required this.sources,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'sources': sources.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory CacheManifest.fromJson(Map<String, dynamic> json) {
    final sourcesJson = json['sources'] as Map<String, dynamic>;
    final sources = sourcesJson.map(
      (key, value) => MapEntry(
        key,
        CacheSourceInfo.fromJson(value as Map<String, dynamic>),
      ),
    );

    return CacheManifest(
      version: json['version'] as int,
      sources: sources,
    );
  }
}
