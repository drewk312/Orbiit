import 'package:http/http.dart' as http;
import '../cover_art_source.dart';

class LibRetroSource implements CoverArtSource {
  static const String baseUrl = 'https://thumbnails.libretro.com';

  @override
  String get sourceName => 'LibRetro Thumbnails';

  @override
  int get priority => 2;

  final http.Client _client;

  LibRetroSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CoverArtResult?> getByGameId(
      String gameId, GamePlatform platform) async {
    return null; // LibRetro doesn't support IDs
  }

  @override
  Future<CoverArtResult?> searchByTitle(
      String title, GamePlatform platform) async {
    final libRetroPlatform = _getLibRetroPlatform(platform);
    if (libRetroPlatform == null) return null;

    final safeTitle = _sanitize(title);
    final url = '$baseUrl/$libRetroPlatform/Named_Boxarts/$safeTitle.png';

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Orbiit/1.0.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
        return CoverArtResult(
          sourceUrl: url,
          sourceName: sourceName,
          quality: CoverArtQuality.medium,
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  String _sanitize(String title) {
    // LibRetro naming convention:
    // Special chars are replaced with _
    // & is explicitly replaced with _
    return title
        .replaceAll('&', '_')
        .replaceAll(RegExp(r'[:\\/?"*<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _getLibRetroPlatform(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.gba:
        return 'Nintendo - Game Boy Advance';
      case GamePlatform.gbc:
        return 'Nintendo - Game Boy Color';
      case GamePlatform.gameboy:
        return 'Nintendo - Game Boy';
      case GamePlatform.n64:
        return 'Nintendo - Nintendo 64';
      case GamePlatform.snes:
        return 'Nintendo - Super Nintendo Entertainment System';
      case GamePlatform.nes:
        return 'Nintendo - Nintendo Entertainment System';
      case GamePlatform.genesis:
        return 'Sega - Mega Drive - Genesis';

      case GamePlatform.wii:
      case GamePlatform
            .gamecube: // LibRetro might have GC/Wii but usually GameTDB is better
      case GamePlatform.wiiu:
      case GamePlatform.nds:
      case GamePlatform.n3ds:
        return null; // Rely on GameTDB for these
      default:
        return null;
    }
  }
}
