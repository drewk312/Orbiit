import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../app_logger.dart';

/// Cover Art Service - Download and cache game covers
class CoverArtService {
  static const String _gameTDBBaseUrl = 'https://art.gametdb.com';

  /// Headers to avoid 403 errors from GameTDB
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Orbiit/1.0',
    'Accept': 'image/png, image/webp, image/*, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://www.gametdb.com/',
  };

  // GameTDB regions mapping
  static String _mapRegionToCode(String region) {
    switch (region.toLowerCase()) {
      case 'usa':
        return 'US';
      case 'europe':
        return 'EN';
      case 'japan':
        return 'JA';
      case 'korea':
        return 'KO';
      default:
        return 'US'; // Default to US
    }
  }

  /// Get local cache directory for covers
  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'covers'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Get cover file path for a game ID
  static Future<File> getCoverFile(String gameId, String platform) async {
    final cacheDir = await _getCacheDir();
    final filename = '${platform}_$gameId.png';
    return File(path.join(cacheDir.path, filename));
  }

  /// Check if cover exists in cache
  static Future<bool> hasCover(String gameId, String platform) async {
    final file = await getCoverFile(gameId, platform);
    return file.exists();
  }

  /// Download cover art for a game
  /// Returns true if successful, false if not found
  static Future<bool> downloadCover(
      String gameId, String platform, String region,
      {String? customUrl}) async {
    try {
      final file = await getCoverFile(gameId, platform);

      // If already cached, skip
      if (await file.exists()) {
        return true;
      }

      String url;
      if (customUrl != null && customUrl.isNotEmpty) {
        url = customUrl;
      } else {
        // Build URL based on platform
        final regionCode = _mapRegionToCode(region);

        if (platform == 'wii') {
          // Wii covers: https://art.gametdb.com/wii/cover/US/RSBE01.png
          url = '$_gameTDBBaseUrl/wii/cover/$regionCode/$gameId.png';
        } else if (platform == 'wiiu' || platform == 'wii u') {
          url = '$_gameTDBBaseUrl/wiiu/cover/$regionCode/$gameId.png';
        } else if (platform == 'ds' || platform == 'nds') {
          url = '$_gameTDBBaseUrl/ds/cover/$regionCode/$gameId.png';
        } else if (platform == 'switch' || platform == 'nsw') {
          url = '$_gameTDBBaseUrl/switch/cover/$regionCode/$gameId.png';
        } else if (platform == 'gamecube' || platform == 'gc') {
          // GameCube covers: https://art.gametdb.com/gamecube/cover/US/GALE01.png
          url = '$_gameTDBBaseUrl/gamecube/cover/$regionCode/$gameId.png';
        } else {
          // For unknown platforms or homebrew, we shouldn't guess GameCube.
          // But if the ID format looks like a Nintendo ID (4 or 6 chars), it might be valid.
          // For now, only default if it looks like a standard ID, otherwise skip to avoid "wrong" covers.
          if (gameId.length == 4 || gameId.length == 6) {
            url = '$_gameTDBBaseUrl/gamecube/cover/$regionCode/$gameId.png';
          } else {
            AppLogger.instance.info(
                'Skipping cover download for platform: $platform',
                component: 'CoverArt');
            return false;
          }
        }
      }

      AppLogger.instance.info('Downloading cover: $url', component: 'CoverArt');

      // Use headers to avoid 403 errors - extended timeout for slow connections
      final response =
          await http.get(Uri.parse(url), headers: _headers).timeout(
                const Duration(seconds: 45),
              );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        AppLogger.instance
            .info('Cover downloaded: $gameId', component: 'CoverArt');
        return true;
      } else {
        AppLogger.instance.info(
            'Cover not found: $gameId (HTTP ${response.statusCode})',
            component: 'CoverArt');
        return false;
      }
    } catch (e) {
      AppLogger.instance.error('Error downloading cover for $gameId: $e',
          component: 'CoverArt', error: e);
      return false;
    }
  }

  /// Batch download covers for multiple games
  static Future<void> downloadCoversForGames(
      List<Map<String, String>> games) async {
    for (final game in games) {
      final gameId = game['gameId']!;
      final platform = game['platform']!;
      final region = game['region'] ?? 'USA';
      final coverUrl = game['coverUrl'];

      await downloadCover(gameId, platform, region, customUrl: coverUrl);

      // Small delay to avoid hammering the server
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Get region code from game ID (last character indicates region)
  static String getRegionFromGameId(String gameId) {
    if (gameId.length < 4) return 'US';

    // Region code is typically the 4th character (or last for 4-char IDs)
    final regionChar =
        gameId.length >= 6 ? gameId[3] : gameId[gameId.length - 1];

    switch (regionChar.toUpperCase()) {
      case 'E':
        return 'US'; // USA
      case 'P':
        return 'EN'; // Europe (PAL)
      case 'J':
        return 'JA'; // Japan
      case 'K':
        return 'KO'; // Korea
      case 'W':
        return 'TW'; // Taiwan
      case 'X':
        return 'EN'; // Europe (X variant)
      case 'Y':
        return 'EN'; // Europe (Y variant)
      case 'D':
        return 'DE'; // Germany
      case 'F':
        return 'FR'; // France
      case 'I':
        return 'IT'; // Italy
      case 'S':
        return 'ES'; // Spain
      case 'H':
        return 'NL'; // Netherlands
      case 'U':
        return 'AU'; // Australia
      default:
        return 'US';
    }
  }

  /// Clear all cached covers
  static Future<void> clearCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
