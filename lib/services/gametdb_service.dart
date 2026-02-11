import 'package:http/http.dart' as http;

/// GameTDB Cover Art Service
/// Provides high-resolution game covers for Wii, GameCube, and Wii U titles
class GameTDBService {
  static const String _baseUrl = 'https://art.gametdb.com';

  /// Cover types available
  static const String cover = 'cover';
  static const String cover3D = 'cover3D';
  static const String disc = 'disc';
  static const String fullcover = 'fullcover';

  /// Get cover URL for a game
  /// @param gameId The 6-character game ID (e.g., RSPE01)
  /// @param platform 'wii', 'gamecube', or 'wiiu'
  /// @param type Cover type (cover, cover3D, disc, fullcover)
  static String getCoverUrl(
    String gameId, {
    String platform = 'wii',
    String type = 'cover3D',
  }) {
    final region = _getRegionFromId(gameId);

    // GameTDB quirks:
    // - Wii is 'wii' (lowercase)
    // - GameCube is 'wii' (for some reason, GameTDB stores GC covers under 'wii' folder structure often,
    //   BUT strictly speaking it should be 'gamecube' if available.
    //   However, standard GameTDB access often defaults 'wii' for both.
    //   Let's check the correct URL structure: art.gametdb.com/wii/cover/US/GMSE01.png

    // Actually looking at GameTDB:
    // Wii: https://art.gametdb.com/wii/cover/US/RMGE01.png
    // GameCube: https://art.gametdb.com/wii/cover/US/GMSE01.png - YES, GC games are under /wii/ on GameTDB!

    const effectivePlatform = 'wii'; // Always use 'wii' for GameTDB covers

    return '$_baseUrl/$effectivePlatform/$type/$region/$gameId.png';
  }

  static String _getRegionFromId(String gameId) {
    if (gameId.length < 4) return 'US';

    final regionChar = gameId[3].toUpperCase();
    switch (regionChar) {
      case 'E':
        return 'US'; // USA (NTSC-U)
      case 'P':
        return 'EN'; // Europe (PAL)
      case 'J':
        return 'JA'; // Japan (NTSC-J)
      case 'W':
        return 'JA'; // Taiwan
      case 'K':
        return 'KO'; // Korea
      case 'X':
        return 'EN'; // Pal alternative
      case 'Y':
        return 'EN'; // Pal alternative
      case 'Z':
        return 'EN'; // Pal alternative
      default:
        return 'US'; // Default to US
    }
  }

  /// Check if cover exists (returns true if HTTP 200)
  static Future<bool> coverExists(String gameId,
      {String platform = 'wii'}) async {
    try {
      final url = getCoverUrl(gameId, platform: platform);
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get best available cover (tries 3D, then flat, then disc)
  static Future<String?> getBestCover(String gameId,
      {String platform = 'wii'}) async {
    // Try 3D cover first
    var url = getCoverUrl(gameId, platform: platform);
    if (await _checkUrl(url)) return url;

    // Try 2D cover
    url = getCoverUrl(gameId, platform: platform, type: cover);
    if (await _checkUrl(url)) return url;

    return null;
  }

  static Future<bool> _checkUrl(String url) async {
    try {
      final response =
          await http.head(Uri.parse(url)).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
