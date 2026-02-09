import '../models/game_result.dart';
import '../core/app_logger.dart';

/// Service to scrape and discover homebrew and rom hacks from GameBrew
class GameBrewService {
  // Cache results in memory
  List<GameResult> _cachedHomebrew = [];

  /// Fetch list of popular Wii Homebrew
  Future<List<GameResult>> fetchHomebrew() async {
    if (_cachedHomebrew.isNotEmpty) return _cachedHomebrew;

    try {
      // For now, we'll return a manually curated list of high-quality homebrew
      // while we perfect the scraping logic for the wiki structure.
      _cachedHomebrew = [
        GameResult(
          title: 'WiiXplorer',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/WiiXplorer',
          description: 'A multi-featured file explorer for the Wii.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        GameResult(
          title: 'USB Loader GX',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/USB_Loader_GX',
          description:
              'The most popular USB Loader for playing games from USB.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        GameResult(
          title: 'Nintendont',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/Nintendont',
          description: 'Runs GameCube games on Wii and Wii U from SD or USB.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        GameResult(
          title: 'Priiloader',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/Priiloader',
          description:
              'A modified version of Preloader that adds brick protection.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        GameResult(
          title: 'SaveGame Manager GX',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/SaveGame_Manager_GX',
          description: 'Manage save files and Miis with a GUI.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        GameResult(
          title: 'CleanRip',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/CleanRip',
          description: 'Create 1:1 ISO dumps of GameCube and Wii discs.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
        // Rom Hacks & Popular Mods
        GameResult(
          title: 'Project+',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'Rom Hacks',
          pageUrl: 'https://projectplusgame.com/download',
          description:
              'The premier competitive modification for Super Smash Bros. Brawl.',
          isDirectDownload: false,
          requiresBrowser: true,
        ),
        GameResult(
          title: 'Newer Super Mario Bros. Wii',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'Rom Hacks',
          pageUrl: 'https://newerteam.com/wii/',
          description:
              'A full unofficial sequel to New Super Mario Bros. Wii with 128 new levels.',
          isDirectDownload: false,
          requiresBrowser: true,
        ),
        GameResult(
          title: 'CTGP Revolution',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'Rom Hacks',
          pageUrl: 'https://www.chadsoft.co.uk/',
          description:
              'The definitive Mario Kart Wii mod with 200+ custom tracks.',
          isDirectDownload: false,
          requiresBrowser: true,
        ),
        GameResult(
          title: 'Riivolution',
          platform: 'Wii',
          region: 'Region Free',
          provider: 'GameBrew',
          pageUrl: 'https://www.gamebrew.org/wiki/Riivolution',
          description: 'On-the-fly patching engine for Wii retail discs.',
          isDirectDownload: false,
          requiresBrowser: false,
        ),
      ];

      return _cachedHomebrew;
    } catch (e) {
      AppLogger.instance.error('Failed to fetch GameBrew content: $e');
      return [];
    }
  }
}
