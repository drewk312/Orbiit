/// Base interface for cover art sources
abstract class CoverArtSource {
  String get sourceName;
  int get priority; // Lower = higher priority

  /// Search for cover art by game title and platform
  Future<CoverArtResult?> searchByTitle(String title, GamePlatform platform);

  /// Get cover art by game ID (if source supports it)
  Future<CoverArtResult?> getByGameId(String gameId, GamePlatform platform);

  /// Check if this source is available/configured
  Future<bool> isAvailable();
}

/// Represents a cover art image from any source
class CoverArtResult {
  final String sourceUrl;
  final String sourceName;
  final CoverArtQuality quality;
  final String? gameId; // Source-specific game ID
  final Map<String, String>? alternateUrls; // Different sizes/regions

  CoverArtResult({
    required this.sourceUrl,
    required this.sourceName,
    required this.quality,
    this.gameId,
    this.alternateUrls,
  });
}

enum CoverArtQuality {
  low, // < 300px
  medium, // 300-600px
  high, // 600-1200px
  ultra, // > 1200px
}

enum GamePlatform {
  wii('wii', 'Nintendo Wii'),
  gamecube('gc', 'Nintendo GameCube'),
  wiiu('wiiu', 'Nintendo Wii U'),
  n64('n64', 'Nintendo 64'),
  snes('snes', 'Super Nintendo'),
  nes('nes', 'Nintendo Entertainment System'),
  gba('gba', 'Game Boy Advance'),
  gbc('gbc', 'Game Boy Color'),
  gameboy('gb', 'Game Boy'),
  genesis('genesis', 'Sega Genesis'),
  n3ds('3ds', 'Nintendo 3DS'),
  nds('ds', 'Nintendo DS');

  final String code;
  final String displayName;

  const GamePlatform(this.code, this.displayName);

  static GamePlatform? fromCode(String code) {
    return GamePlatform.values.cast<GamePlatform?>().firstWhere(
          (p) => p?.code == code.toLowerCase(),
          orElse: () => null,
        );
  }
}
