import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_result.dart';

/// Myrient service - Live HTTP directory search
class MyrientService {
  // Cache for directory listings
  static final Map<String, List<_MyrientFile>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(hours: 1);

  // Core sources
  static const _sources = {
    'Wii': 'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
    'GameCube': 'https://myrient.erista.me/files/Redump/Nintendo%20-%20GameCube%20-%20NKit%20RVZ%20%5Bzstd-19-128k%5D/',
    'N64': 'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29/',
    'SNES': 'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/',
    'GBA': 'https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/',
  };

  /// Initialize cache (compatibility)
  Future<void> initializeCache() async {
    debugPrint('[Myrient] Initialize called');
  }

  /// Refresh cache (compatibility)
  Future<void> refreshCache() async {
    _cache.clear();
    _cacheTime.clear();
    debugPrint('[Myrient] Cache cleared');
  }

  /// Search for games
  Future<List<GameResult>> search(String query, {String? platform}) async {
    if (query.isEmpty) return [];

    debugPrint('[Myrient] Searching: $query (platform: $platform)');
    final results = <GameResult>[];
    final terms = _normalize(query);

    // Determine which sources to search
    final sourcesToSearch = <MapEntry<String, String>>[];
    if (platform == null || platform.toLowerCase() == 'all') {
      sourcesToSearch.addAll(_sources.entries.take(3)); // Search top 3
    } else {
      final match = _sources.entries.where((e) => 
        e.key.toLowerCase() == platform.toLowerCase() ||
        platform.toLowerCase().contains(e.key.toLowerCase())
      );
      sourcesToSearch.addAll(match);
    }

    if (sourcesToSearch.isEmpty) {
      sourcesToSearch.addAll(_sources.entries.take(2));
    }

    // Search each source
    for (final source in sourcesToSearch) {
      try {
        final files = await _getFiles(source.value);
        for (final file in files) {
          if (_matches(file.name, terms)) {
            results.add(GameResult(
              title: _cleanTitle(file.name),
              platform: source.key,
              region: _detectRegion(file.name),
              provider: 'Myrient',
              pageUrl: source.value,
              downloadUrl: source.value + file.href,
              isDirectDownload: true,
              requiresBrowser: false,
              format: file.name.endsWith('.rvz') ? 'RVZ' : 
                      file.name.endsWith('.rvz') ? 'ROM' : 'ISO',
              size: file.size,
            ));
            if (results.length >= 15) break;
          }
        }
        if (results.length >= 15) break;
      } catch (e) {
        debugPrint('[Myrient] Error searching ${source.key}: $e');
      }
    }

    debugPrint('[Myrient] Found ${results.length} results');
    return results;
  }

  /// Search cached (compatibility)
  Future<List<GameResult>> searchCached(String query, {String? platform}) async {
    return search(query, platform: platform);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<_MyrientFile>> _getFiles(String url) async {
    // Check cache
    final cached = _cacheTime[url];
    if (cached != null && DateTime.now().difference(cached) < _cacheDuration) {
      return _cache[url] ?? [];
    }

    // Fetch directory
    final client = HttpClient();
    client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      final files = _parseDirectory(body);

      _cache[url] = files;
      _cacheTime[url] = DateTime.now();

      return files;
    } catch (e) {
      debugPrint('[Myrient] Fetch error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  List<_MyrientFile> _parseDirectory(String html) {
    final files = <_MyrientFile>[];
    
    // Myrient uses markdown table format:
    // | [Name](url) | size | date |
    final pattern = RegExp(r'\|\s*\[([^\]]+)\]\(([^"\s\)]+)[^|]*\|\s*([^|]+)\|');

    for (final match in pattern.allMatches(html)) {
      final name = match.group(1)!;
      final href = match.group(2)!;
      final size = match.group(3)?.trim() ?? '';

      if (href == '../' || href == './' || name.contains('Parent')) continue;

      String decoded;
      try {
        decoded = Uri.decodeComponent(name);
      } catch (_) {
        decoded = name;
      }

      final lower = decoded.toLowerCase();
      if (lower.endsWith('.rvz') || lower.endsWith('.zip') || 
          lower.endsWith('.7z') || lower.endsWith('.iso')) {
        files.add(_MyrientFile(href: href, name: decoded, size: size));
      }
    }

    return files;
  }

  List<String> _normalize(String query) {
    return query.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1)
      .toList();
  }

  bool _matches(String fileName, List<String> terms) {
    final normalized = fileName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
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
}

class _MyrientFile {
  final String href;
  final String name;
  final String size;
  _MyrientFile({required this.href, required this.name, required this.size});
}
