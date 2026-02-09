import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import '../models/game_result.dart';
import 'myrient_cache.dart';
import 'myrient_index.dart';

/// Myrient service - Live HTTP directory search
class MyrientService {
  // Persistent Cache & Search Index
  final MyrientCache _persistentCache = MyrientCache();
  final MyrientSearchIndex _searchIndex = MyrientSearchIndex();
  bool _isInitialized = false;

  // Core sources
  static const _sources = {
    'Wii':
        'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
    'GameCube':
        'https://myrient.erista.me/files/Redump/Nintendo%20-%20GameCube%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
    'N64':
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29/',
    'SNES':
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/',
    'GBA':
        'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/',
  };

  /// Initialize cache and search index
  Future<void> initializeCache() async {
    if (_isInitialized) return;

    debugPrint('[Myrient] Initializing...');
    await _persistentCache.initialize();

    // Load all cached sources into memory for the index
    final cachedData = <String, List<MyrientGameEntry>>{};
    final sources = _persistentCache.getCachedSources();

    for (final source in sources) {
      final games = await _persistentCache.loadCache(source);
      if (games != null) {
        cachedData[source] = games;
      }
    }

    if (cachedData.isNotEmpty) {
      _searchIndex.buildFromCache(cachedData);
      debugPrint('[Myrient] Index built with ${_searchIndex.totalGames} games');
    }

    _isInitialized = true;
  }

  /// Refresh cache (clear all)
  Future<void> refreshCache() async {
    await _persistentCache.clearAll();
    _searchIndex.clear();
    debugPrint('[Myrient] Cache cleared');
  }

  /// Search for games
  Future<List<GameResult>> search(String query, {String? platform}) async {
    if (query.isEmpty) return [];

    debugPrint('[Myrient] Searching: $query (platform: $platform)');
    final results = <GameResult>[];
    final terms = _normalize(query);

    // 0. Instant Index Search
    if (_searchIndex.totalGames > 0) {
      final cachedResults = _searchIndex.search(query, platform: platform);
      if (cachedResults.isNotEmpty) {
        debugPrint('[Myrient] Found ${cachedResults.length} results in index');
        // The cachedResults from _searchIndex are already MyrientGameEntry
        // We need to map them to GameResult.
        // The MyrientGameEntry from the index should contain the baseUrl.
        return cachedResults.map((e) {
          final baseUrl = _sources[e.platform] ?? e.url;
          return _mapToResult(e, e.platform, baseUrl);
        }).toList();
      }
    }

    // 1. Filter sources based on platform request
    final sourcesToSearch = _sources.entries.where((entry) {
      if (platform == null || platform.toLowerCase() == 'all') return true;
      return entry.key.toLowerCase().contains(platform.toLowerCase());
    }).toList();

    // If no specific match, default to searching everything (or top 3 for speed)
    if (sourcesToSearch.isEmpty) {
      sourcesToSearch.addAll(_sources.entries.take(3));
    }

    // 2. Search sources (and populate cache)
    for (final source in sourcesToSearch) {
      try {
        // This will fetch from network if not in persistent cache,
        // AND populate persistent cache.
        final files = await _getFiles(source.value, source.key);

        // Add specific results to list (fallback linear scan if index wasn't ready)
        // Actually, if we just fetched it, we should add to index?
        // _getFiles saves to cache.
        // For now, simple linear filter on the returned files

        // final terms = _normalize(query); // We need _normalize back or re-implement
        for (final file in files) {
          if (_matches(file.title, terms)) {
            results.add(_mapToResult(file, source.key, source.value));
            if (results.length >= 20) break;
          }
        }
      } catch (e) {
        debugPrint('[Myrient] Error searching ${source.key}: $e');
      }
      if (results.length >= 30) break;
    }

    return results;
  }

  // Helper to safely join base URL and relative href
  String _buildUrl(String base, String href) {
    if (base.endsWith('/')) return base + href;
    return '$base/$href';
  }

  /// Search cached (compatibility)
  Future<List<GameResult>> searchCached(String query,
      {String? platform}) async {
    return search(query, platform: platform);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<MyrientGameEntry>> _getFiles(String url, String platform) async {
    // Check persistent cache first
    if (_persistentCache.isCacheValid(url)) {
      final cached = await _persistentCache.loadCache(url);
      if (cached != null) return cached;
    }

    // Fetch live
    final client = HttpClient();
    client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response =
          await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      final files = _parseDirectory(body, url, platform);

      // Save to cache
      await _persistentCache.saveCache(url, files, platform);

      // We should potentially update the index here, but MyrientSearchIndex
      // currently rebuilds from a map. For now, we accept that the index
      // is built on startup, and new fetches are just cached for next time.
      // If we want immediate index updates, we'd need to extend MyrientSearchIndex.

      return files;
    } catch (e) {
      debugPrint('[Myrient] Fetch error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  List<MyrientGameEntry> _parseDirectory(
      String htmlBody, String baseUrl, String platform) {
    final files = <MyrientGameEntry>[];
    final document = parse(htmlBody);
    final rows = document.querySelectorAll('tr');

    for (final row in rows) {
      final link = row.querySelector('a');
      if (link == null) continue;

      final href = link.attributes['href'];
      final name = link.text.trim();

      if (href == null ||
          href == '../' ||
          href == './' ||
          name == 'Parent Directory') {
        continue;
      }

      String sizeStr = '0';
      final cells = row.querySelectorAll('td');
      for (final cell in cells) {
        final text = cell.text.trim();
        if (RegExp(r'\d+(\.\d+)?\s*[KMGT]i?B').hasMatch(text)) {
          sizeStr = text;
          break;
        }
      }

      final lower = name.toLowerCase();
      String format = 'ISO';
      if (lower.endsWith('.rvz'))
        format = 'RVZ';
      else if (lower.endsWith('.zip'))
        format = 'ZIP';
      else if (lower.endsWith('.7z'))
        format = '7Z';
      else if (lower.endsWith('.wbfs')) format = 'WBFS';

      if (['.rvz', '.zip', '.7z', '.iso', '.wbfs']
          .any((ext) => lower.endsWith(ext))) {
        files.add(MyrientGameEntry(
          title: Uri.decodeComponent(name),
          url: _buildUrl(baseUrl, href),
          size: _parseSize(sizeStr),
          platform: platform,
          format: format,
        ));
      }
    }
    return files;
  }

  int _parseSize(String sizeStr) {
    try {
      final parts = sizeStr.split(' ');
      if (parts.length < 2) return 0;
      double value = double.tryParse(parts[0]) ?? 0;
      String unit = parts[1].toUpperCase();

      int bytes = value.toInt();
      if (unit.contains('GI'))
        bytes = (value * 1024 * 1024 * 1024).toInt();
      else if (unit.contains('MI'))
        bytes = (value * 1024 * 1024).toInt();
      else if (unit.contains('KI'))
        bytes = (value * 1024).toInt();
      else if (unit.contains('G'))
        bytes = (value * 1000 * 1000 * 1000).toInt();
      else if (unit.contains('M'))
        bytes = (value * 1000 * 1000).toInt();
      else if (unit.contains('K')) bytes = (value * 1000).toInt();

      return bytes;
    } catch (e) {
      return 0;
    }
  }

  List<String> _normalize(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
  }

  bool _matches(String fileName, List<String> terms) {
    final normalized =
        fileName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    return terms.every((term) => normalized.contains(term));
  }

  String _cleanTitle(String fileName) {
    return fileName
        .replaceAll(RegExp(r'\.(zip|7z|rvz|iso)$', caseSensitive: false), '')
        .trim();
  }

  String _detectRegion(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('(usa)') || lower.contains('(us)')) return 'USA';
    if (lower.contains('(europe)') || lower.contains('(eu)')) return 'Europe';
    if (lower.contains('(japan)') || lower.contains('(jp)')) return 'Japan';
    if (lower.contains('(world)')) return 'World';
    return 'USA';
  }

  GameResult _mapToResult(
      MyrientGameEntry entry, String platform, String pageUrl) {
    return GameResult(
      title: _cleanTitle(entry.title),
      platform: platform,
      region: _detectRegion(entry.title),
      provider: 'Myrient ${entry.format}',
      pageUrl: pageUrl,
      downloadUrl: entry.url,
      isDirectDownload: true,
      requiresBrowser: false,
      format: entry.format,
      size: _formatBytes(entry.size),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
