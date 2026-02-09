import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/game_result.dart';

/// Vimm's Lair Service for Wii and GameCube scraping
class VimmService {
  static const String _baseUrl = 'https://vimm.net';

  Future<List<GameResult>> search(String query, {String? platform}) async {
    debugPrint('[VimmService] Searching for: $query (Platform: $platform)');

    if (query.isEmpty) return [];

    final results = <GameResult>[];
    final systemsToSearch = <String>[];

    if (platform == null || platform == 'All') {
      systemsToSearch.addAll(['Wii', 'GameCube']);
    } else if (platform == 'Wii') {
      systemsToSearch.add('Wii');
    } else if (platform == 'GameCube') {
      systemsToSearch.add('GameCube');
    } else if (platform == 'Retro') {
      systemsToSearch.addAll(['N64', 'SNES', 'Genesis', 'NES']);
    } else if (platform == 'N64') {
      systemsToSearch.add('N64');
    } else if (platform == 'SNES') {
      systemsToSearch.add('SNES');
    }

    try {
      for (final system in systemsToSearch) {
        results.addAll(await _searchSystem(query, system));
      }
    } catch (e) {
      debugPrint('[VimmService] Search error: $e');
    }

    return results;
  }

  Future<List<GameResult>> _searchSystem(String query, String system) async {
    final searchUrl = Uri.parse(
        '$_baseUrl/vault/?p=list&system=$system&q=${Uri.encodeComponent(query)}');

    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final request = await client.getUrl(searchUrl);
      final response = await request.close();

      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      return _parseHtml(body, system);
    } catch (e) {
      debugPrint('[VimmService] Error searching $system: $e');
      return [];
    }
  }

  List<GameResult> _parseHtml(String html, String system) {
    final results = <GameResult>[];

    // Pattern for game links: <a href="/vault/17747">Mario Party 8</a>
    final gamePattern = RegExp(
      r"<a href='/vault/(\d+)'>([^<]+)</a>",
      caseSensitive: false,
    );

    final matches = gamePattern.allMatches(html);

    for (final match in matches) {
      final id = match.group(1);
      final title = match.group(2)?.trim() ?? '';

      if (id == null || title.isEmpty) continue;

      results.add(GameResult(
        title: title,
        platform: system,
        region: _detectRegion(title),
        provider: "Vimm's Lair",
        pageUrl: '$_baseUrl/vault/$id',
        coverUrl: '$_baseUrl/image.php?type=box&id=$id', // Direct cover access
        downloadUrl: null, // Mediated via downloadGame
        requiresBrowser: false, // Handled by in-app downloader
        isDirectDownload: false,
      ));
    }

    return results;
  }

  // ... (previous code)

  /// Fetches the hidden form values required for downloading
  /// Returns a map with 'mediaId' and 'alt'
  Future<Map<String, String>?> getDownloadDetails(String gameUrl) async {
    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final request = await client.getUrl(Uri.parse(gameUrl));
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();

      // Extract mediaId
      final mediaIdMatch =
          RegExp(r'name="mediaId" value="(\d+)"').firstMatch(body);
      final mediaId = mediaIdMatch?.group(1);

      // Extract alt
      final altMatch = RegExp(r'name="alt" value="(\d+)"').firstMatch(body);
      final alt = altMatch?.group(1) ?? '0'; // Default to 0

      if (mediaId != null) {
        return {'mediaId': mediaId, 'alt': alt};
      }
      return null;
    } catch (e) {
      debugPrint('[VimmService] Failed to get download details: $e');
      return null;
    }
  }

  /// Downloads the game using the details from [startDownload]
  /// [onProgress] callback with 0.0 to 1.0
  Future<File?> downloadGame(String gameUrl, Directory destination,
      {Function(double)? onProgress}) async {
    final details = await getDownloadDetails(gameUrl);
    if (details == null) {
      debugPrint('[VimmService] Could not resolve download details');
      return null;
    }

    final mediaId = details['mediaId'];
    final alt = details['alt'];
    const downloadActionUrl =
        'https://dl3.vimm.net/'; // Verified from browser logic

    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      // Important: Vimm's often checks Referer

      final request = await client.postUrl(Uri.parse(downloadActionUrl));
      request.headers.set('Referer', gameUrl);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('Origin', 'https://vimm.net');

      // Construct body: mediaId=XXXX&alt=0&format=0 (0 for wbfs/7z typically)
      // Format 0 = .7z/.wbfs, Format 1 = .rvz (sometimes)
      // We will request format=0 as default
      final bodyData = 'mediaId=$mediaId&alt=$alt&format=0';
      request.write(bodyData);

      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint(
            '[VimmService] Download request failed: ${response.statusCode}');
        return null;
      }

      // Determine filename from header or fallback
      String filename = 'game_download.7z';
      final contentDisposition = response.headers.value('content-disposition');
      if (contentDisposition != null) {
        final nameMatch =
            RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (nameMatch != null) {
          filename = nameMatch.group(1)!;
        }
      }

      final saveFile = File(path.join(destination.path, filename));
      final sink = saveFile.openWrite();

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      await response.listen(
        (data) {
          sink.add(data);
          receivedBytes += data.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        },
        onDone: () async {
          await sink.close();
        },
        onError: (e) {
          debugPrint('[VimmService] Download stream error: $e');
          sink.close();
        },
        cancelOnError: true,
      ).asFuture();

      return saveFile;
    } catch (e) {
      debugPrint('[VimmService] Download failed: $e');
      return null;
    }
  }

  String _detectRegion(String title) {
    if (title.contains('(USA)')) return 'USA';
    if (title.contains('(Europe)')) return 'Europe';
    if (title.contains('(Japan)')) return 'Japan';
    return 'USA'; // Default
  }
}
