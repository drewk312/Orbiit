import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cover_art_source.dart';

/// MobyGames - Historical game database with cover art
/// https://www.mobygames.com/
/// Requires API key from https://www.mobygames.com/info/api/
class MobyGamesSource implements CoverArtSource {
  static const String baseUrl = 'https://api.mobygames.com/v1';

  @override
  String get sourceName => 'MobyGames';

  @override
  int get priority => 3; // Third fallback

  final http.Client _client;
  final String? _apiKey;

  MobyGamesSource({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey;

  @override
  Future<bool> isAvailable() async {
    if (_apiKey == null) return false;

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/platforms?api_key=$_apiKey'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<CoverArtResult?> searchByTitle(
      String title, GamePlatform platform) async {
    if (_apiKey == null) return null;

    try {
      final platformId = _getPlatformId(platform);
      if (platformId == null) return null;

      // Search for game
      final searchUrl = Uri.parse('$baseUrl/games').replace(queryParameters: {
        'api_key': _apiKey,
        'title': title,
        'platform': platformId.toString(),
      });

      final searchResponse = await _client.get(searchUrl).timeout(
            const Duration(seconds: 15),
          );

      if (searchResponse.statusCode != 200) return null;

      final searchData =
          jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final games = searchData['games'] as List?;

      if (games == null || games.isEmpty) return null;

      final gameId = games.first['game_id'] as int;

      // Get cover art for the game
      final coverUrl =
          Uri.parse('$baseUrl/games/$gameId/platforms/$platformId').replace(
        queryParameters: {'api_key': _apiKey},
      );

      final coverResponse = await _client.get(coverUrl).timeout(
            const Duration(seconds: 45),
          );

      if (coverResponse.statusCode != 200) return null;

      final coverData = jsonDecode(coverResponse.body) as Map<String, dynamic>;
      final sampleCovers = coverData['sample_cover'] as Map<String, dynamic>?;

      if (sampleCovers == null || sampleCovers['image'] == null) {
        return null;
      }

      final imageUrl = sampleCovers['image'] as String;

      // MobyGames provides different sizes
      final alternates = <String, String>{
        'thumbnail': sampleCovers['thumbnail_image'] as String? ?? imageUrl,
      };

      return CoverArtResult(
        sourceUrl: imageUrl,
        sourceName: sourceName,
        quality:
            CoverArtQuality.medium, // MobyGames typically has medium quality
        gameId: gameId.toString(),
        alternateUrls: alternates,
      );
    } catch (e) {
      print('[MobyGames] Error searching for "$title": $e');
      return null;
    }
  }

  @override
  Future<CoverArtResult?> getByGameId(
      String gameId, GamePlatform platform) async {
    // MobyGames uses numeric IDs, not game codes
    return null;
  }

  int? _getPlatformId(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.wii:
        return 82; // Wii
      case GamePlatform.gamecube:
        return 14; // GameCube
      case GamePlatform.wiiu:
        return 132; // Wii U
      default:
        return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
