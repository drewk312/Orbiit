import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../services/cover_art/cover_art_service.dart';

/// Service for preparing covers for jailbroken Wii USB loaders
class USBLoaderService {
  static const String _gameTDBBaseUrl = 'https://art.gametdb.com';

  /// Prepare covers for USB Loader GX on an SD card
  ///
  /// Downloads 4 cover types to: SD:/apps/usbloader_gx/images/
  /// - 3D covers (default)
  /// - 2D flat covers
  /// - Full quality covers
  /// - Disc art
  static Future<void> prepareForUSBLoaderGX(
    String sdCardPath,
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    final baseDir =
        Directory(path.join(sdCardPath, 'apps', 'usbloader_gx', 'images'));
    await baseDir.create(recursive: true);

    // Create subdirectories
    final dirs = {
      '3D': baseDir.path,
      '2D': path.join(baseDir.path, '2D'),
      'full': path.join(baseDir.path, 'full'),
      'disc': path.join(baseDir.path, 'disc'),
    };

    for (final dir in dirs.values) {
      await Directory(dir).create(recursive: true);
    }

    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final gameId = game['gameId']!;
      final platform = game['platform']!;

      onProgress?.call(i + 1, games.length, gameId);

      if (platform.toLowerCase() != 'wii')
        continue; // USB Loader GX is Wii only

      final regionCode = CoverArtService.getRegionFromGameId(gameId);

      // Download all 4 cover types
      await _downloadCover(
        '$_gameTDBBaseUrl/wii/cover3D/$regionCode/$gameId.png',
        path.join(dirs['3D']!, '$gameId.png'),
      );

      await _downloadCover(
        '$_gameTDBBaseUrl/wii/cover/$regionCode/$gameId.png',
        path.join(dirs['2D']!, '$gameId.png'),
      );

      await _downloadCover(
        '$_gameTDBBaseUrl/wii/coverfull/$regionCode/$gameId.png',
        path.join(dirs['full']!, '$gameId.png'),
      );

      await _downloadCover(
        '$_gameTDBBaseUrl/wii/disc/$regionCode/$gameId.png',
        path.join(dirs['disc']!, '$gameId.png'),
      );

      // Small delay to avoid hammering server
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Prepare covers for WiiFlow Lite on an SD card
  ///
  /// Downloads 2 cover types to: SD:/wiiflow/
  /// - boxcovers (full quality)
  /// - covers (2D flat)
  static Future<void> prepareForWiiFlow(
    String sdCardPath,
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    final boxcoverDir =
        Directory(path.join(sdCardPath, 'wiiflow', 'boxcovers'));
    final coverDir = Directory(path.join(sdCardPath, 'wiiflow', 'covers'));

    await boxcoverDir.create(recursive: true);
    await coverDir.create(recursive: true);

    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final gameId = game['gameId']!;
      final platform = game['platform']!;

      onProgress?.call(i + 1, games.length, gameId);

      if (platform.toLowerCase() != 'wii') continue; // WiiFlow is Wii only

      final regionCode = CoverArtService.getRegionFromGameId(gameId);

      // Boxcover (full quality)
      await _downloadCover(
        '$_gameTDBBaseUrl/wii/coverfull/$regionCode/$gameId.png',
        path.join(boxcoverDir.path, '$gameId.png'),
      );

      // 2D cover
      await _downloadCover(
        '$_gameTDBBaseUrl/wii/cover/$regionCode/$gameId.png',
        path.join(coverDir.path, '$gameId.png'),
      );

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Prepare covers for both USB Loader GX and WiiFlow
  static Future<void> prepareForBothLoaders(
    String sdCardPath,
    List<Map<String, String>> games, {
    Function(int current, int total, String gameId)? onProgress,
  }) async {
    // First prepare USB Loader GX (4 types per game)
    await prepareForUSBLoaderGX(
      sdCardPath,
      games,
      onProgress: (curr, total, gameId) {
        onProgress?.call(curr, total * 2, 'USB Loader GX: $gameId');
      },
    );

    // Then prepare WiiFlow (2 types per game)
    await prepareForWiiFlow(
      sdCardPath,
      games,
      onProgress: (curr, total, gameId) {
        onProgress?.call(total + curr, total * 2, 'WiiFlow: $gameId');
      },
    );
  }

  /// Helper to download a single cover file
  static Future<bool> _downloadCover(String url, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return true; // Already downloaded
      }

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 2),
          );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }

      return false;
    } catch (e) {
      return false; // Silent fail
    }
  }

  /// List available SD card drives (Windows)
  static Future<List<String>> detectSDCards() async {
    final drives = <String>[];

    // Check common drive letters (D: through Z:)
    for (int i = 'D'.codeUnitAt(0); i <= 'Z'.codeUnitAt(0); i++) {
      final drive = '${String.fromCharCode(i)}:';
      final dir = Directory(drive);

      if (await dir.exists()) {
        // Check if it looks like a Wii SD card
        final wbfsDir = Directory(path.join(drive, 'wbfs'));
        final appsDir = Directory(path.join(drive, 'apps'));

        if (await wbfsDir.exists() || await appsDir.exists()) {
          drives.add(drive);
        }
      }
    }

    return drives;
  }

  /// Get total cover count that will be downloaded
  static int getUSBLoaderGXCoverCount(int gameCount) => gameCount * 4;
  static int getWiiFlowCoverCount(int gameCount) => gameCount * 2;
  static int getBothLoadersCoverCount(int gameCount) => gameCount * 6;
}
