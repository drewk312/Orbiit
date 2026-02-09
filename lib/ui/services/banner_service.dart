import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for downloading GameCube animated banners
/// Based on TinyWii's banners.rs - downloads from banner.rc24.xyz
class BannerService {
  static const String _baseUrl = 'https://banner.rc24.xyz';

  /// Get banner file path for a game
  static Future<File> getBannerFile(String gameId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'banners'));
    await cacheDir.create(recursive: true);

    return File(path.join(cacheDir.path, '$gameId.bnr'));
  }

  /// Check if banner exists in cache
  static Future<bool> hasBanner(String gameId) async {
    final file = await getBannerFile(gameId);
    return file.exists();
  }

  /// Download banner for a GameCube game
  static Future<bool> downloadBanner(String gameId,
      {bool usePartialId = false}) async {
    try {
      final file = await getBannerFile(gameId);

      // If already cached, skip
      if (await file.exists()) {
        return true;
      }

      // Try full ID first
      final url = '$_baseUrl/$gameId.bnr';

      try {
        final response = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 5),
            );

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('✓ Banner downloaded: $gameId');
          return true;
        }
      } catch (e) {
        // Try partial ID (first 3 characters) as fallback
        if (gameId.length >= 3) {
          final partialId = gameId.substring(0, 3);
          final fallbackUrl = '$_baseUrl/$partialId.bnr';

          final response = await http.get(Uri.parse(fallbackUrl)).timeout(
                const Duration(seconds: 5),
              );

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await file.writeAsBytes(response.bodyBytes);
            debugPrint(
                '✓ Banner downloaded (partial ID): $gameId -> $partialId');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false; // Silent fail
    }
  }

  /// Download banners for multiple GameCube games
  static Future<void> downloadBannersForGames(
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final gameId = game['gameId']!;
      final platform = game['platform']!;

      onProgress?.call(i + 1, games.length, gameId);

      // Only download for GameCube games
      if (platform.toLowerCase() != 'gamecube') continue;

      await downloadBanner(gameId);

      // Small delay to avoid hammering server
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Clear all cached banners
  static Future<void> clearCache() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'banners'));

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'banners'));

    if (!await cacheDir.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }
}
