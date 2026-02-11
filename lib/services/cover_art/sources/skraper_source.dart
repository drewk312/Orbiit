import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cover_art_source.dart';

/// Skraper - ROM cover art scraper
/// https://www.skraper.net/
/// Note: Skraper primarily works via their desktop application
/// This implementation uses ScreenScraper API (Skraper's backend)
class SkraperSource implements CoverArtSource {
  static const String baseUrl = 'https://www.screenscraper.fr/api2';

  @override
  String get sourceName => 'Skraper/ScreenScraper';

  @override
  int get priority => 4; // Last fallback

  final http.Client _client;
  final String? _devId;
  final String? _devPassword;
  final String? _userLogin;
  final String? _userPassword;

  SkraperSource({
    http.Client? client,
    String? devId,
    String? devPassword,
    String? userLogin,
    String? userPassword,
  })  : _client = client ?? http.Client(),
        _devId = devId,
        _devPassword = devPassword,
        _userLogin = userLogin,
        _userPassword = userPassword;

  @override
  Future<bool> isAvailable() async {
    if (_devId == null || _devPassword == null) return false;

    try {
      final url = Uri.parse('$baseUrl/ssuserInfos.php').replace(
        queryParameters: {
          'devid': _devId,
          'devpassword': _devPassword,
          'softname': 'Orbiit',
          'output': 'json',
        },
      );

      final response = await _client.get(url).timeout(
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
    if (_devId == null || _devPassword == null) return null;

    try {
      final systemId = _getSystemId(platform);
      if (systemId == null) return null;

      final queryParams = {
        'devid': _devId,
        'devpassword': _devPassword,
        'softname': 'Orbiit',
        'output': 'json',
        'systemeid': systemId.toString(),
        'recherche': title,
      };

      if (_userLogin != null && _userPassword != null) {
        queryParams['ssid'] = _userLogin;
        queryParams['sspassword'] = _userPassword;
      }

      final url = Uri.parse('$baseUrl/jeuInfos.php').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(url).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final game = data['response']?['jeu'] as Map<String, dynamic>?;

      if (game == null) return null;

      // ScreenScraper provides many media types
      final medias = game['medias'] as List?;
      if (medias == null || medias.isEmpty) return null;

      // Find box-2D (front cover)
      final boxMedia = medias.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m?['type'] == 'box-2D',
            orElse: () => medias.first as Map<String, dynamic>?,
          );

      if (boxMedia == null || boxMedia['url'] == null) return null;

      final coverUrl = boxMedia['url'] as String;

      // Build alternates from other media types
      final alternates = <String, String>{};
      for (final media in medias.cast<Map<String, dynamic>>()) {
        final type = media['type'] as String?;
        final url = media['url'] as String?;
        if (type != null && url != null && type != 'box-2D') {
          alternates[type] = url;
        }
      }

      final quality = _determineQuality(
        boxMedia['width'] as int? ?? 0,
        boxMedia['height'] as int? ?? 0,
      );

      return CoverArtResult(
        sourceUrl: coverUrl,
        sourceName: sourceName,
        quality: quality,
        gameId: game['id']?.toString(),
        alternateUrls: alternates,
      );
    } catch (e) {
      print('[Skraper] Error searching for "$title": $e');
      return null;
    }
  }

  @override
  Future<CoverArtResult?> getByGameId(
      String gameId, GamePlatform platform) async {
    // ScreenScraper uses numeric IDs, not game codes
    return null;
  }

  int? _getSystemId(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.wii:
        return 82; // Wii
      case GamePlatform.gamecube:
        return 23; // GameCube
      case GamePlatform.wiiu:
        return 118; // Wii U
      default:
        return null;
    }
  }

  CoverArtQuality _determineQuality(int width, int height) {
    final maxDimension = width > height ? width : height;

    if (maxDimension >= 1200) return CoverArtQuality.ultra;
    if (maxDimension >= 600) return CoverArtQuality.high;
    if (maxDimension >= 300) return CoverArtQuality.medium;
    return CoverArtQuality.low;
  }

  void dispose() {
    _client.close();
  }
}
