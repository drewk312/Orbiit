import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// ═══════════════════════════════════════════════════════════════════════════
/// MYRIENT CACHE SERVICE - INSTANT SEARCH
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This service pre-caches all Myrient directory listings on app startup,
/// enabling instant (<50ms) searches instead of waiting 5-10 seconds.
///
/// Usage:
///   // In main.dart or app initialization:
///   await MyrientCacheService.instance.initialize();
///
///   // Search is now instant:
///   final results = MyrientCacheService.instance.search('Super Mario 74');
///
/// ═══════════════════════════════════════════════════════════════════════════

class MyrientCacheService {
  // Singleton
  static final MyrientCacheService instance = MyrientCacheService._();
  MyrientCacheService._();

  // ─────────────────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────────────────

  bool _isInitialized = false;
  bool _isLoading = false;
  double _loadProgress = 0.0;
  String _loadStatus = '';

  // Master game index: all games from all sources
  final List<MyrientGame> _gameIndex = [];

  // Callbacks for UI updates
  void Function(double progress, String status)? onLoadProgress;
  void Function()? onLoadComplete;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  double get loadProgress => _loadProgress;
  String get loadStatus => _loadStatus;
  int get totalGames => _gameIndex.length;

  // ─────────────────────────────────────────────────────────────────────────
  // SOURCES TO CACHE
  // ─────────────────────────────────────────────────────────────────────────

  static final List<_CacheSource> _sources = [
    // High priority - cache first
    _CacheSource(
        'wii_rvz',
        'Wii',
        'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
        'RVZ'),
    _CacheSource(
        'gamecube_rvz',
        'GameCube',
        'https://myrient.erista.me/files/Redump/Nintendo%20-%20GameCube%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
        'RVZ'),
    _CacheSource(
        'n64_big',
        'N64',
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29/',
        'Z64'),
    _CacheSource(
        'n64_ra',
        'N64',
        'https://myrient.erista.me/files/RetroAchievements/RA%20-%20Nintendo%2064/',
        'Z64',
        isHack: true),
    _CacheSource(
        'gba',
        'GBA',
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/',
        'GBA'),
    _CacheSource(
        'snes',
        'SNES',
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/',
        'SFC'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize the cache service.
  /// Call this on app startup. It will:
  /// 1. Load existing cache from disk (instant)
  /// 2. Start background refresh if cache is stale
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    _loadStatus = 'Loading catalog...';
    _notifyProgress();

    try {
      // Try to load from disk first (instant)
      final loaded = await _loadFromDisk();

      if (loaded && _gameIndex.isNotEmpty) {
        debugPrint(
            '[MyrientCache] Loaded ${_gameIndex.length} games from disk cache');
        _isInitialized = true;
        _isLoading = false;
        _loadProgress = 1.0;
        _loadStatus = 'Ready';
        _notifyProgress();
        onLoadComplete?.call();

        // Check if cache is stale and refresh in background
        if (await _isCacheStale()) {
          debugPrint(
              '[MyrientCache] Cache is stale, refreshing in background...');
          _refreshInBackground();
        }
        return;
      }

      // No cache - fetch fresh
      debugPrint('[MyrientCache] No disk cache, fetching fresh...');
      await _fetchAllSources();
      await _saveToDisk();

      _isInitialized = true;
      _isLoading = false;
      _loadProgress = 1.0;
      _loadStatus = 'Ready';
      _notifyProgress();
      onLoadComplete?.call();
    } catch (e) {
      debugPrint('[MyrientCache] Init error: $e');
      _isLoading = false;
      _loadStatus = 'Error loading catalog';
      _notifyProgress();
    }
  }

  /// Force refresh the cache
  Future<void> refresh() async {
    _gameIndex.clear();
    _isInitialized = false;
    await initialize();
  }

  void _notifyProgress() {
    onLoadProgress?.call(_loadProgress, _loadStatus);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH - INSTANT!
  // ─────────────────────────────────────────────────────────────────────────

  /// Search the cached game index. Returns instantly (<50ms).
  List<MyrientGame> search(String query, {String? platform, int limit = 50}) {
    if (query.isEmpty || _gameIndex.isEmpty) return [];

    final terms = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    if (terms.isEmpty) return [];

    final results = <MyrientGame>[];

    for (final game in _gameIndex) {
      // Platform filter
      if (platform != null && platform.toLowerCase() != 'all') {
        if (!game.platform.toLowerCase().contains(platform.toLowerCase())) {
          continue;
        }
      }

      // Match all search terms
      final normalizedTitle = game.searchableTitle;
      if (terms.every((term) => normalizedTitle.contains(term))) {
        results.add(game);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Get all games for a platform
  List<MyrientGame> getByPlatform(String platform, {int limit = 100}) {
    return _gameIndex
        .where((g) => g.platform.toLowerCase() == platform.toLowerCase())
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH FROM MYRIENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchAllSources() async {
    final total = _sources.length;

    for (int i = 0; i < total; i++) {
      final source = _sources[i];
      _loadStatus = 'Loading ${source.platform}...';
      _loadProgress = i / total;
      _notifyProgress();

      try {
        final games = await _fetchSource(source);
        _gameIndex.addAll(games);
        debugPrint('[MyrientCache] Fetched ${games.length} from ${source.id}');
      } catch (e) {
        debugPrint('[MyrientCache] Error fetching ${source.id}: $e');
      }
    }

    debugPrint('[MyrientCache] Total: ${_gameIndex.length} games indexed');
  }

  Future<List<MyrientGame>> _fetchSource(_CacheSource source) async {
    final games = <MyrientGame>[];

    final client = HttpClient();
    client.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final request = await client.getUrl(Uri.parse(source.url));
      final response =
          await request.close().timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return games;

      final body = await response.transform(utf8.decoder).join();
      final lines = body.split('\n');

      for (final line in lines) {
        if (!line.startsWith('|') || !line.contains('](')) continue;
        if (line.contains('File Name') || line.contains('Parent directory'))
          continue;

        final linkMatch = RegExp(r'\[([^\]]+)\]\(([^\s\)"]+)').firstMatch(line);
        if (linkMatch == null) continue;

        final displayName = linkMatch.group(1)!;
        final href = linkMatch.group(2)!;

        if (href == '../' || href == './' || href.startsWith('?')) continue;

        String decodedName;
        try {
          decodedName = Uri.decodeComponent(displayName);
        } catch (_) {
          decodedName = displayName;
        }

        final lowerName = decodedName.toLowerCase();
        if (!lowerName.endsWith('.zip') &&
            !lowerName.endsWith('.7z') &&
            !lowerName.endsWith('.rvz') &&
            !lowerName.endsWith('.wux') &&
            !lowerName.endsWith('.chd') &&
            !lowerName.endsWith('.iso')) {
          continue;
        }

        // Extract size
        String size = '';
        final sizeMatch = RegExp(r'\|\s*([0-9.]+\s*[KMGT]iB)').firstMatch(line);
        if (sizeMatch != null) size = sizeMatch.group(1)!;

        // Clean title
        final title = decodedName
            .replaceAll(
                RegExp(r'\.(zip|7z|rar|chd|iso|wux|rvz)$',
                    caseSensitive: false),
                '')
            .trim();

        games.add(MyrientGame(
          title: title,
          platform: source.platform,
          format: source.format,
          downloadUrl: source.url + href,
          size: size,
          isHack: source.isHack,
          region: _detectRegion(decodedName),
        ));
      }
    } catch (e) {
      debugPrint('[MyrientCache] Fetch error: $e');
    } finally {
      client.close();
    }

    return games;
  }

  String _detectRegion(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('(usa)') || lower.contains('(us)')) return 'USA';
    if (lower.contains('(europe)') || lower.contains('(eu)')) return 'Europe';
    if (lower.contains('(japan)') || lower.contains('(jp)')) return 'Japan';
    if (lower.contains('(world)')) return 'World';
    return 'USA';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISK CACHE
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> get _cacheFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return path.join(dir.path, 'WiiGCFusion', 'myrient_cache.json');
  }

  Future<bool> _loadFromDisk() async {
    try {
      final file = File(await _cacheFilePath);
      if (!await file.exists()) return false;

      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;

      final games =
          (data['games'] as List).map((g) => MyrientGame.fromJson(g)).toList();

      _gameIndex.clear();
      _gameIndex.addAll(games);

      return true;
    } catch (e) {
      debugPrint('[MyrientCache] Load error: $e');
      return false;
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = File(await _cacheFilePath);
      await file.parent.create(recursive: true);

      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'count': _gameIndex.length,
        'games': _gameIndex.map((g) => g.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(data));
      debugPrint('[MyrientCache] Saved ${_gameIndex.length} games to disk');
    } catch (e) {
      debugPrint('[MyrientCache] Save error: $e');
    }
  }

  Future<bool> _isCacheStale() async {
    try {
      final file = File(await _cacheFilePath);
      if (!await file.exists()) return true;

      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      return age.inHours > 24; // Refresh if older than 24 hours
    } catch (e) {
      return true;
    }
  }

  void _refreshInBackground() {
    // Don't await - let it run in background
    Future(() async {
      try {
        final freshIndex = <MyrientGame>[];

        for (final source in _sources) {
          try {
            final games = await _fetchSource(source);
            freshIndex.addAll(games);
          } catch (e) {
            // Continue with other sources
          }
        }

        if (freshIndex.isNotEmpty) {
          _gameIndex.clear();
          _gameIndex.addAll(freshIndex);
          await _saveToDisk();
          debugPrint(
              '[MyrientCache] Background refresh complete: ${freshIndex.length} games');
        }
      } catch (e) {
        debugPrint('[MyrientCache] Background refresh error: $e');
      }
    });
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    _gameIndex.clear();
    _isInitialized = false;

    try {
      final file = File(await _cacheFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[MyrientCache] Clear error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class MyrientGame {
  final String title;
  final String platform;
  final String format;
  final String downloadUrl;
  final String size;
  final String region;
  final bool isHack;

  // Pre-computed for fast search
  late final String searchableTitle;

  MyrientGame({
    required this.title,
    required this.platform,
    required this.format,
    required this.downloadUrl,
    required this.size,
    required this.region,
    this.isHack = false,
  }) {
    searchableTitle = title.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'platform': platform,
        'format': format,
        'downloadUrl': downloadUrl,
        'size': size,
        'region': region,
        'isHack': isHack,
      };

  factory MyrientGame.fromJson(Map<String, dynamic> json) => MyrientGame(
        title: json['title'] ?? '',
        platform: json['platform'] ?? '',
        format: json['format'] ?? '',
        downloadUrl: json['downloadUrl'] ?? '',
        size: json['size'] ?? '',
        region: json['region'] ?? 'USA',
        isHack: json['isHack'] ?? false,
      );
}

class _CacheSource {
  final String id;
  final String platform;
  final String url;
  final String format;
  final bool isHack;

  const _CacheSource(this.id, this.platform, this.url, this.format,
      {this.isHack = false});
}
