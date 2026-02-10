import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cover_art_source.dart';

/// GameTDB - Primary source for Wii/GameCube cover art
/// https://www.gametdb.com/
class GameTDBSource implements CoverArtSource {
  static const String baseUrl = 'https://art.gametdb.com';
  static const String apiUrl = 'https://www.gametdb.com/wiitdb.txt';

  @override
  String get sourceName => 'GameTDB';

  @override
  int get priority => 1; // Highest priority for Wii/GC

  final http.Client _client;

  GameTDBSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _client.head(Uri.parse(baseUrl)).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<CoverArtResult?> searchByTitle(
      String title, GamePlatform platform) async {
    // GameTDB requires game ID, so we can't search by title directly
    // This would require parsing the wiitdb.txt database
    // For now, return null and rely on getByGameId
    return null;
  }

  @override
  Future<CoverArtResult?> getByGameId(
      String gameId, GamePlatform platform) async {
    if (platform != GamePlatform.wii && platform != GamePlatform.gamecube) {
      return null; // GameTDB only supports Wii and GameCube
    }

    try {
      // GameTDB cover art URLs:
      // Wii: https://art.gametdb.com/wii/cover/US/{GAMEID}.png
      // GameCube: https://art.gametdb.com/gc/cover/US/{GAMEID}.png

      final regions = ['US', 'EN', 'EU', 'JA', 'KO', 'FR', 'DE', 'ES', 'IT'];
      final platformCode = platform == GamePlatform.wii ? 'wii' : 'gc';

      // Try each region until we find a valid cover
      for (final region in regions) {
        final coverUrl = '$baseUrl/$platformCode/cover/$region/$gameId.png';
        final response = await _client.head(Uri.parse(coverUrl)).timeout(
              const Duration(seconds: 45),
            );

        if (response.statusCode == 200) {
          // Build alternate URLs for different regions
          final alternates = <String, String>{};
          for (final r in regions) {
            if (r != region) {
              alternates[r] = '$baseUrl/$platformCode/cover/$r/$gameId.png';
            }
          }

          // Also add 3D covers, discs, and full covers
          alternates['cover3D'] =
              '$baseUrl/$platformCode/cover3D/$region/$gameId.png';
          alternates['disc'] =
              '$baseUrl/$platformCode/disc/$region/$gameId.png';
          alternates['coverfull'] =
              '$baseUrl/$platformCode/coverfull/$region/$gameId.png';

          return CoverArtResult(
            sourceUrl: coverUrl,
            sourceName: sourceName,
            quality: CoverArtQuality
                .high, // GameTDB typically has high-quality covers
            gameId: gameId,
            alternateUrls: alternates,
          );
        }
      }

      return null; // No cover found for any region
    } catch (e) {
      print('[GameTDB] Error fetching cover for $gameId: $e');
      return null;
    }
  }

  /// Extract game ID from ISO filename
  /// Example: "RMGE01.wbfs" -> "RMGE01"
  static String? extractGameIdFromFilename(String filename) {
    final match = RegExp(r'([A-Z0-9]{6})').firstMatch(filename);
    return match?.group(1);
  }

  void dispose() {
    _client.close();
  }
}
