import 'dart:convert';
import 'dart:io';

import '../models/game_result.dart';
import '../core/app_logger.dart';

/// Represents a single file entry from Archive.org metadata
class ArchiveFile {
  final String name;
  final int size;
  final String? sha1;
  final String downloadUrl;

  ArchiveFile({
    required this.name,
    required this.size,
    this.sha1,
    required this.downloadUrl,
  });
}

/// Service for interacting with Archive.org API
class ArchiveOrgService {
  static final ArchiveOrgService _instance = ArchiveOrgService._internal();
  factory ArchiveOrgService() => _instance;
  ArchiveOrgService._internal();

  static const String _apiBase = 'https://archive.org/advancedsearch.php';
  static const String _metaBase = 'https://archive.org/metadata';

  final _logger = AppLogger.instance;

  /// Fetch files for a given archive identifier using /metadata/{id}
  Future<List<ArchiveFile>> getFilesForIdentifier(String id) async {
    final List<ArchiveFile> files = [];
    if (id.isEmpty) return files;

    try {
      final uri = Uri.parse('$_metaBase/$id');
      _logger.info('Fetching archive metadata: $uri');

      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        _logger
            .error('Archive metadata request failed: ${response.statusCode}');
        return files;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body);

      final fileList = data['files'] as List?;
      if (fileList == null) return files;

      for (final f in fileList) {
        final name = f['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final size = int.tryParse((f['size'] ?? '0').toString()) ?? 0;
        final sha1 = f['sha1']?.toString();
        final encoded = Uri.encodeComponent(name);
        final downloadUrl = 'https://archive.org/download/$id/$encoded';

        files.add(ArchiveFile(
            name: name, size: size, sha1: sha1, downloadUrl: downloadUrl));
      }

      _logger.info('Found ${files.length} files for $id');
      return files;
    } catch (e) {
      _logger.error('getFilesForIdentifier error', error: e);
      return files;
    }
  }

  /// Search archive.org for a query and return GameResult entries (limited fields)
  Future<List<GameResult>> search(String query) async {
    if (query.isEmpty) return [];

    final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    _logger.info('[ArchiveOrg] Searching for: $cleanQuery');

    final List<GameResult> allResults = [];

    try {
      final client = HttpClient();
      final searchParams = {
        'q':
            '($cleanQuery) AND mediatype:(software)', // Removed rigid (wii OR gamecube) to allow Wii U/Retro
        'fl[]': [
          'identifier',
          'title',
          'mediatype',
          'collection',
          'format',
          'item_size'
        ],
        'sort[]': ['downloads desc'],
        'rows': '50',
        'output': 'json',
      };

      final uri = Uri.parse(_apiBase).replace(queryParameters: searchParams);
      _logger.info('[ArchiveOrg] API URI: $uri');

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        _logger.error('[ArchiveOrg] API Error: ${response.statusCode}');
        return allResults;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body);

      if (data['response'] != null && data['response']['docs'] != null) {
        final docs = data['response']['docs'] as List;
        for (var doc in docs) {
          final identifier = doc['identifier']?.toString() ?? '';
          final title = doc['title']?.toString() ?? 'Unknown Title';
          final collection = (doc['collection'] is List)
              ? doc['collection'][0]
              : doc['collection'].toString();

          final lowerColl = collection.toLowerCase();
          final lowerTitle = title.toLowerCase();

          String platform = 'Wii'; // Default

          // Enhanced Platform Detection
          if (lowerColl.contains('wii u') ||
              lowerColl.contains('wiiu') ||
              lowerTitle.contains('wii u')) {
            platform = 'Wii U';
          } else if (lowerColl.contains('gamecube') ||
              lowerColl.contains('ngc') ||
              lowerTitle.contains('gamecube')) {
            platform = 'GameCube';
          } else if (lowerColl.contains('nintedo 64') ||
              lowerColl.contains('n64') ||
              lowerTitle.contains('n64')) {
            platform = 'N64';
          } else if (lowerColl.contains('snes') ||
              lowerColl.contains('super nintendo')) {
            platform = 'SNES';
          } else if (lowerTitle.contains('nes') || lowerColl.contains('nes')) {
            platform = 'NES';
          } else if (lowerColl.contains('wii') || lowerTitle.contains('wii')) {
            platform = 'Wii';
          } else {
            platform = 'Retro';
          }

          allResults.add(GameResult(
            title: title,
            platform: platform,
            region: _detectRegion(title),
            provider: 'Archive.org',
            pageUrl: 'https://archive.org/details/$identifier',
            downloadUrl: 'https://archive.org/download/$identifier',
            sourceIdentifier: identifier,
            isDirectDownload: false,
            requiresBrowser: false,
            size: _formatSize(doc['item_size']),
          ));
        }
      }

      _logger.info('[ArchiveOrg] Found ${allResults.length} results');
      return allResults;
    } catch (e) {
      _logger.error('[ArchiveOrg] Search error: $e');
      return [];
    }
  }

  /// Pick the best file: prefer .wbfs, then .iso, then .rvz
  ArchiveFile? pickBestFile(List<ArchiveFile> files) {
    if (files.isEmpty) return null;

    // Prefer .wbfs
    final wbfs =
        files.where((f) => f.name.toLowerCase().endsWith('.wbfs')).toList();
    if (wbfs.isNotEmpty) return wbfs.first;

    // Then .iso (prefer largest iso)
    final isos =
        files.where((f) => f.name.toLowerCase().endsWith('.iso')).toList();
    if (isos.isNotEmpty) {
      isos.sort((a, b) => b.size.compareTo(a.size));
      return isos.first;
    }

    // Then .rvz
    final rvz =
        files.where((f) => f.name.toLowerCase().endsWith('.rvz')).toList();
    if (rvz.isNotEmpty) return rvz.first;

    // Otherwise return first large file
    files.sort((a, b) => b.size.compareTo(a.size));
    return files.first;
  }

  String _detectRegion(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('(usa)') || lowerTitle.contains('[usa]')) {
      return 'USA';
    }
    if (lowerTitle.contains('(europe)') || lowerTitle.contains('[pal]')) {
      return 'Europe';
    }
    if (lowerTitle.contains('(japan)') || lowerTitle.contains('[jpn]')) {
      return 'Japan';
    }
    return 'USA'; // Default to USA
  }

  String _formatSize(dynamic size) {
    if (size == null) return 'Unknown';
    try {
      final bytes = int.parse(size.toString());
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Unknown';
    }
  }
}
