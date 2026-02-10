import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for downloading cheat codes for games
/// Based on TinyWii's txtcodes.rs - downloads Gecko/Ocarina cheat codes
class CheatCodeService {
  // Multiple cheat code sources
  static const List<String> _sources = [
    'https://codes.rc24.xyz', // RC24 cheat codes
    'https://geckocodes.org', // Gecko codes
  ];

  /// Get cheat code file path
  static Future<File> getCheatFile(String gameId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'cheats'));
    await cacheDir.create(recursive: true);

    return File(path.join(cacheDir.path, '$gameId.txt'));
  }

  /// Check if cheats exist for game
  static Future<bool> hasCheats(String gameId) async {
    final file = await getCheatFile(gameId);
    return file.exists();
  }

  /// Download cheat codes for a game
  static Future<bool> downloadCheats(String gameId) async {
    try {
      final file = await getCheatFile(gameId);

      // If already cached, skip
      if (await file.exists()) {
        return true;
      }

      // Try each source
      for (final baseUrl in _sources) {
        final url = '$baseUrl/$gameId.txt';

        try {
          final response = await http.get(Uri.parse(url)).timeout(
                const Duration(seconds: 5),
              );

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            await file.writeAsString(response.body);
            print('✓ Cheats downloaded: $gameId from $baseUrl');
            return true;
          }
        } catch (e) {
          continue; // Try next source
        }
      }

      return false;
    } catch (e) {
      return false; // Silent fail
    }
  }

  /// Export cheats to SD card for USB Loader GX
  static Future<void> exportCheatsToSD(
    String sdCardPath,
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    final codesDir = Directory(path.join(sdCardPath, 'codes'));
    await codesDir.create(recursive: true);

    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final gameId = game['gameId']!;

      onProgress?.call(i + 1, games.length, gameId);

      // Check if we have cheats cached
      final cheatFile = await getCheatFile(gameId);
      if (await cheatFile.exists()) {
        final outputFile = File(path.join(codesDir.path, '$gameId.txt'));
        await cheatFile.copy(outputFile.path);
      } else {
        // Try to download
        if (await downloadCheats(gameId)) {
          final outputFile = File(path.join(codesDir.path, '$gameId.txt'));
          await cheatFile.copy(outputFile.path);
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Download cheats for multiple games
  static Future<void> downloadCheatsForGames(
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final gameId = game['gameId']!;

      onProgress?.call(i + 1, games.length, gameId);

      await downloadCheats(gameId);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Get cheat code content
  static Future<String?> getCheatContent(String gameId) async {
    final file = await getCheatFile(gameId);
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  /// Clear all cached cheats
  static Future<void> clearCache() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'cheats'));

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'cheats'));

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
