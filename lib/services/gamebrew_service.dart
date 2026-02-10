import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:developer' as developer;
import '../models/game_result.dart';
import '../core/app_logger.dart';

/// Service to scrape and discover homebrew and rom hacks from GameBrew
class GameBrewService {
  // Cache results in memory
  List<GameResult> _cachedHomebrew = [];

  static const String _baseUrl = 'https://www.gamebrew.org';
  static const String _hacksListUrl =
      'https://www.gamebrew.org/wiki/List_of_Wii_rom_hacks';
  static const String _translationsListUrl =
      'https://www.gamebrew.org/wiki/List_of_Wii_translations';

  /// Search games in the homebrew collection
  Future<List<GameResult>> searchGames(String query) async {
    if (_cachedHomebrew.isEmpty) {
      await fetchHomebrew();
    }

    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    return _cachedHomebrew.where((game) {
      return game.title.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  /// Fetch list of popular Wii Homebrew and Rom Hacks
  Future<List<GameResult>> fetchHomebrew() async {
    if (_cachedHomebrew.isNotEmpty) return _cachedHomebrew;

    final hacks = await _scrapeWikiPage(_hacksListUrl, 'ROM Hack');
    final translations =
        await _scrapeWikiPage(_translationsListUrl, 'Translation');

    // Combine unique results
    final allScraped = [...hacks];
    final seenUrls = hacks.map((e) => e.pageUrl).toSet();

    for (final trans in translations) {
      if (!seenUrls.contains(trans.pageUrl)) {
        allScraped.add(trans);
        seenUrls.add(trans.pageUrl);
      }
    }

    // Curated list for fallback and high-quality guaranteed entries
    final curated = [
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
        description: 'The most popular USB Loader for playing games from USB.',
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
      // Notable Rom Hacks that might not be easily scraped or need special URL
      GameResult(
        title: 'Project+',
        platform: 'Wii',
        region: 'ROM Hack',
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
        region: 'ROM Hack',
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
        region: 'ROM Hack',
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

    // Merge scrapes with curated (avoid duplicates by URL/Title)
    final existingUrls = curated.map((e) => e.pageUrl).toSet();
    for (final item in allScraped) {
      if (!existingUrls.contains(item.pageUrl)) {
        curated.add(item);
      }
    }

    _cachedHomebrew = curated;
    return _cachedHomebrew;
  }

  Future<List<GameResult>> _scrapeWikiPage(
      String url, String defaultRegion) async {
    try {
      developer.log('[GameBrew] Scraping $url...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        developer.log('[GameBrew] Failed to load list: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(response.body);
      final results = <GameResult>[];

      // GameBrew 'List of Wii rom hacks' page structure
      final content = document.querySelector('.mw-parser-output');
      if (content == null) return [];

      // 1. Tables (often used for hack lists)
      final tables = content.querySelectorAll('table.wikitable');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          // Need at least name/link and maybe author/desc
          if (cells.isNotEmpty) {
            final link = cells[0].querySelector('a');
            if (link != null) {
              final title = link.text.trim();
              final href = link.attributes['href'];

              String desc = 'Wii $defaultRegion on GameBrew';
              String version = 'Unknown';
              String author = 'Unknown';

              // GameBrew Wiki Table format: Title | Description | Version | Author | Updated
              if (cells.length >= 2) {
                desc = cells[1].text.trim();
                if (desc.isEmpty) desc = 'Wii $defaultRegion on GameBrew';
              }

              if (cells.length >= 3) {
                version = cells[2].text.trim();
              }

              if (cells.length >= 4) {
                author = cells[3].text.trim();
              }

              // Combine extra info into description if needed, or use specific fields if GameResult supports them
              if (author != 'Unknown') {
                desc = '$desc (by $author)';
              }

              // Try to find an image in the row
              String? thumbUrl;
              final img = row.querySelector('img');
              if (img != null) {
                final src = img.attributes['src'];
                if (src != null && src.isNotEmpty) {
                  thumbUrl = src.startsWith('http') ? src : '$_baseUrl$src';
                }
              }

              if (title.isNotEmpty &&
                  href != null &&
                  !href.contains('redlink=1') &&
                  !href.contains('#')) {
                final fullUrl =
                    href.startsWith('http') ? href : '$_baseUrl$href';

                results.add(GameResult(
                  title: title,
                  platform: 'Wii',
                  region: defaultRegion,
                  provider: 'Rom Hacks',
                  pageUrl: fullUrl,
                  downloadUrl: fullUrl,
                  coverUrl: thumbUrl,
                  description: desc,
                  version: version,
                  size: 'Unknown',
                  requiresBrowser: true,
                  isDirectDownload: false,
                ));
              }
            }
          }
        }
      }

      // 2. Unordered lists (ul/li) fallback
      if (results.isEmpty) {
        final items = content.querySelectorAll('li');
        for (final item in items) {
          final link = item.querySelector('a');
          if (link != null) {
            final title = link.text.trim();
            final href = link.attributes['href'];
            if (title.isNotEmpty &&
                href != null &&
                !href.contains('redlink=1') &&
                !href.contains('#')) {
              final fullUrl = href.startsWith('http') ? href : '$_baseUrl$href';
              results.add(GameResult(
                title: title,
                platform: 'Wii',
                region: defaultRegion,
                provider: 'Rom Hacks',
                pageUrl: fullUrl,
                downloadUrl: fullUrl,
                description: '$defaultRegion from GameBrew',
                size: 'Unknown',
                requiresBrowser: true,
                isDirectDownload: false,
              ));
            }
          }
        }
      }

      developer.log('[GameBrew] Scraped ${results.length} items from $url.');
      return results;
    } catch (e) {
      developer.log('[GameBrewService] Error scraping $url: $e');
      return [];
    }
  }
}
