import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cover_art_source.dart';

/// IGDB (Internet Game Database) - Comprehensive game metadata
/// https://www.igdb.com/
/// Requires API key from https://api-docs.igdb.com/
class IGDBSource implements CoverArtSource {
  static const String baseUrl = 'https://api.igdb.com/v4';

  @override
  String get sourceName => 'IGDB';

  @override
  int get priority => 2; // Fallback after GameTDB

  final http.Client _client;
  final String? _clientId;
  final String? _accessToken;

  IGDBSource({
    http.Client? client,
    String? clientId,
    String? accessToken,
  })  : _client = client ?? http.Client(),
        _clientId = clientId,
        _accessToken = accessToken;

  @override
  Future<bool> isAvailable() async {
    if (_clientId == null || _accessToken == null) {
      return false; // API key not configured
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/games'),
            headers: _buildHeaders(),
            body: 'fields id; limit 1;',
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
    if (_clientId == null || _accessToken == null) {
      return null;
    }

    try {
      final platformId = _getPlatformId(platform);
      if (platformId == null) return null;

      // Search for game by title and platform
      final searchQuery = '''
        search "$title";
        fields name, cover.url, cover.width, cover.height;
        where platforms = ($platformId);
        limit 1;
      ''';

      final response = await _client
          .post(
            Uri.parse('$baseUrl/games'),
            headers: _buildHeaders(),
            body: searchQuery,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final games = jsonDecode(response.body) as List;
      if (games.isEmpty) return null;

      final game = games.first as Map<String, dynamic>;
      final cover = game['cover'] as Map<String, dynamic>?;

      if (cover == null || cover['url'] == null) {
        return null;
      }

      // IGDB URLs start with "//" - convert to https
      String coverUrl = cover['url'] as String;
      if (coverUrl.startsWith('//')) {
        coverUrl = 'https:$coverUrl';
      }

      // Convert to high-resolution image
      coverUrl = coverUrl.replaceAll('/t_thumb/', '/t_cover_big/');

      final quality = _determineQuality(
        cover['width'] as int? ?? 0,
        cover['height'] as int? ?? 0,
      );

      // Build alternate resolutions
      final alternates = <String, String>{
        'thumb': coverUrl.replaceAll('/t_cover_big/', '/t_thumb/'),
        'cover_small': coverUrl.replaceAll('/t_cover_big/', '/t_cover_small/'),
        'screenshot_med':
            coverUrl.replaceAll('/t_cover_big/', '/t_screenshot_med/'),
        'screenshot_big':
            coverUrl.replaceAll('/t_cover_big/', '/t_screenshot_big/'),
        'screenshot_huge':
            coverUrl.replaceAll('/t_cover_big/', '/t_screenshot_huge/'),
        '720p': coverUrl.replaceAll('/t_cover_big/', '/t_720p/'),
        '1080p': coverUrl.replaceAll('/t_cover_big/', '/t_1080p/'),
      };

      return CoverArtResult(
        sourceUrl: coverUrl,
        sourceName: sourceName,
        quality: quality,
        gameId: game['id']?.toString(),
        alternateUrls: alternates,
      );
    } catch (e) {
      print('[IGDB] Error searching for "$title": $e');
      return null;
    }
  }

  @override
  Future<CoverArtResult?> getByGameId(
      String gameId, GamePlatform platform) async {
    // IGDB uses numeric IDs, not game codes
    return null;
  }

  Map<String, String> _buildHeaders() {
    return {
      'Client-ID': _clientId!,
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'text/plain',
    };
  }

  int? _getPlatformId(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.wii:
        return 5; // Wii
      case GamePlatform.gamecube:
        return 21; // GameCube
      case GamePlatform.wiiu:
        return 41; // Wii U
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
