import 'dart:convert';
import 'dart:io';
import '../core/app_logger.dart';

/// Smart Game Metadata Service
/// Fetches rich game information from multiple sources:
/// - Wikipedia (descriptions, release dates, developers)
/// - Libretro Thumbnails (cover art)
/// - GameTDB (Wii/GC specific data)
///
/// "The future of jailbreaking" - intelligent metadata aggregation
class GameMetadataService {
  static final GameMetadataService _instance = GameMetadataService._internal();
  factory GameMetadataService() => _instance;
  GameMetadataService._internal();

  // Cache to avoid repeated API calls
  final Map<String, GameMetadata> _cache = {};

  /// Fetch comprehensive game metadata
  Future<GameMetadata> getGameMetadata(String title, String platform) async {
    final cacheKey = '${title.toLowerCase()}_${platform.toLowerCase()}';

    // Return cached if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    AppLogger.instance
        .debug('[GameMetadata] Fetching metadata for: $title ($platform)');

    // Fetch from multiple sources in parallel
    final results = await Future.wait([
      _fetchWikipediaData(title, platform: platform),
      _fetchCoverArt(title, platform),
    ]);

    final wikiData = results[0] as Map<String, dynamic>?;
    final coverUrl = results[1] as String?;

    final metadata = GameMetadata(
      title: wikiData?['title'] ?? title,
      description:
          wikiData?['description'] ?? _generateDescription(title, platform),
      coverUrl: coverUrl,
      releaseDate: wikiData?['releaseDate'],
      developer: wikiData?['developer'],
      publisher: wikiData?['publisher'],
      genres: wikiData?['genres'] ?? [],
      platform: platform,
      wikiUrl: wikiData?['url'],
    );

    // Cache the result
    _cache[cacheKey] = metadata;

    return metadata;
  }

  /// Fetch data from Wikipedia API
  Future<Map<String, dynamic>?> _fetchWikipediaData(String title,
      {String? platform}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // Clean title for search
      final searchTitle = _cleanTitleForSearch(title);
      final titleLower = title.toLowerCase();
      final platformLower = (platform ?? '').toLowerCase();

      // Build platform-aware search query
      String searchQuery;

      // IMPORTANT: If the title already contains the platform name, use exact title search
      // This handles cases like "New Super Mario Bros. Wii" vs "New Super Mario Bros." (DS)
      if (titleLower.contains('wii u') || titleLower.contains('wiiu')) {
        searchQuery = '"$searchTitle" Wii U video game';
      } else if (titleLower.contains('wii') && !titleLower.contains('wiiu')) {
        // Title already has "Wii" in it - search for exact title
        searchQuery = '"$searchTitle" video game';
      } else if (titleLower.contains('3ds') ||
          titleLower.contains('3d land') ||
          titleLower.contains('3d world')) {
        searchQuery = '"$searchTitle" Nintendo 3DS';
      } else if (titleLower.contains('ds') && !titleLower.contains('3ds')) {
        searchQuery = '"$searchTitle" Nintendo DS';
      } else if (titleLower.contains('64')) {
        searchQuery = '"$searchTitle" Nintendo 64';
      } else if (titleLower.contains('gamecube') || titleLower.contains('gc')) {
        searchQuery = '"$searchTitle" GameCube';
      } else {
        // Title doesn't contain platform - add platform to disambiguate
        if (platformLower.contains('n64') ||
            platformLower.contains('nintendo 64')) {
          searchQuery = '$searchTitle Nintendo 64 video game';
        } else if (platformLower.contains('snes') ||
            platformLower.contains('super nintendo')) {
          searchQuery = '$searchTitle Super Nintendo video game';
        } else if (platformLower.contains('nes') &&
            !platformLower.contains('snes')) {
          searchQuery = '$searchTitle NES video game';
        } else if (platformLower.contains('gba') ||
            platformLower.contains('game boy advance')) {
          searchQuery = '$searchTitle Game Boy Advance';
        } else if (platformLower.contains('gbc') ||
            platformLower.contains('game boy color')) {
          searchQuery = '$searchTitle Game Boy Color';
        } else if (platformLower.contains('wii') &&
            !platformLower.contains('wiiu') &&
            !platformLower.contains('wii u')) {
          // Platform is Wii but title doesn't have "Wii" - add it explicitly
          searchQuery = '$searchTitle Wii video game';
        } else if (platformLower.contains('wiiu') ||
            platformLower.contains('wii u')) {
          searchQuery = '$searchTitle Wii U video game';
        } else if (platformLower.contains('gamecube') ||
            platformLower.contains('gc')) {
          searchQuery = '$searchTitle GameCube video game';
        } else if (platformLower.contains('genesis') ||
            platformLower.contains('mega drive')) {
          searchQuery = '$searchTitle Sega Genesis';
        } else {
          searchQuery = '$searchTitle video game';
        }
      }

      AppLogger.instance.debug('[GameMetadata] Wikipedia search: $searchQuery');

      // Wikipedia API - search for the game
      final searchUrl = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(searchQuery)}&format=json&srlimit=1');

      final searchReq = await client.getUrl(searchUrl);
      searchReq.headers.set('User-Agent', 'Orbiit/1.0 (Game Manager App)');
      final searchRes = await searchReq.close();

      if (searchRes.statusCode != 200) return null;

      final searchBody = await searchRes.transform(utf8.decoder).join();
      final searchJson = json.decode(searchBody);

      final searchResults = searchJson['query']?['search'] as List?;
      if (searchResults == null || searchResults.isEmpty) return null;

      final pageTitle = searchResults[0]['title'] as String;
      final pageId = searchResults[0]['pageid'];

      // Get page extract (summary)
      final extractUrl = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&pageids=$pageId&prop=extracts|info&exintro=true&explaintext=true&inprop=url&format=json');

      final extractReq = await client.getUrl(extractUrl);
      extractReq.headers.set('User-Agent', 'Orbiit/1.0 (Game Manager App)');
      final extractRes = await extractReq.close();

      if (extractRes.statusCode != 200) return null;

      final extractBody = await extractRes.transform(utf8.decoder).join();
      final extractJson = json.decode(extractBody);

      final pages = extractJson['query']?['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.values.first;
      final extract = page['extract'] as String? ?? '';
      final fullUrl = page['fullurl'] as String?;

      // Parse info from extract
      final parsed = _parseWikipediaExtract(extract, pageTitle);
      parsed['url'] = fullUrl;

      AppLogger.instance
          .debug('[GameMetadata] Wikipedia data found for: $title');
      return parsed;
    } catch (e) {
      AppLogger.instance.warning('[GameMetadata] Wikipedia fetch error: $e');
      return null;
    }
  }

  /// Parse useful info from Wikipedia extract
  Map<String, dynamic> _parseWikipediaExtract(String extract, String title) {
    final result = <String, dynamic>{
      'title': title,
      'description': '',
      'developer': null,
      'publisher': null,
      'releaseDate': null,
      'genres': <String>[],
    };

    if (extract.isEmpty) return result;

    // Get first 2-3 sentences as description
    final sentences = extract.split(RegExp(r'(?<=[.!?])\s+'));
    final descSentences = sentences.take(3).join(' ');
    result['description'] = descSentences.length > 500
        ? '${descSentences.substring(0, 497)}...'
        : descSentences;

    // Try to extract developer
    final devMatch = RegExp(r'developed by ([^.]+)', caseSensitive: false)
        .firstMatch(extract);
    if (devMatch != null) {
      result['developer'] = devMatch.group(1)?.trim();
    }

    // Try to extract publisher
    final pubMatch = RegExp(r'published by ([^.]+)', caseSensitive: false)
        .firstMatch(extract);
    if (pubMatch != null) {
      result['publisher'] = pubMatch.group(1)?.trim();
    }

    // Try to extract release year
    final yearMatch =
        RegExp(r'released.*?(\d{4})|(\d{4}).*?release', caseSensitive: false)
            .firstMatch(extract);
    if (yearMatch != null) {
      result['releaseDate'] = yearMatch.group(1) ?? yearMatch.group(2);
    }

    // Try to extract genres
    final genrePatterns = [
      'role-playing',
      'RPG',
      'action',
      'adventure',
      'platformer',
      'puzzle',
      'racing',
      'sports',
      'fighting',
      'shooter',
      'simulation',
      'strategy',
      'horror',
      'survival',
      'stealth',
      'rhythm',
      'party',
      'educational'
    ];

    for (final genre in genrePatterns) {
      if (extract.toLowerCase().contains(genre.toLowerCase())) {
        result['genres'].add(genre);
      }
    }

    return result;
  }

  /// Fetch cover art from Libretro thumbnails
  Future<String?> _fetchCoverArt(String title, String platform) async {
    try {
      final system = _getLibretroSystem(platform);
      final cleanTitle = _cleanTitleForSearch(title);

      // Try various name formats
      final candidates = <String>[
        cleanTitle,
        '$cleanTitle (USA)',
        '$cleanTitle (USA, Europe)',
        '$cleanTitle (Europe)',
        '$cleanTitle (World)',
        '$cleanTitle (U)',
        '$cleanTitle (J)',
      ];

      // Also try "The" swap (Libretro often uses "Title, The" format)
      if (cleanTitle.startsWith('The ')) {
        final swapped = '${cleanTitle.substring(4)}, The';
        candidates.add(swapped);
        candidates.add('$swapped (USA)');
        candidates.add('$swapped (U)');
      }

      // Special handling for Zelda games (Libretro uses "Legend of Zelda, The" format)
      if (cleanTitle.toLowerCase().contains('zelda')) {
        // e.g., "The Legend of Zelda: Ocarina of Time" -> "Legend of Zelda, The - Ocarina of Time"
        final zeldaMatch =
            RegExp(r'The Legend of Zelda[:\s]*(.*)').firstMatch(cleanTitle);
        if (zeldaMatch != null) {
          final subtitle = zeldaMatch.group(1)?.trim() ?? '';
          if (subtitle.isNotEmpty) {
            candidates.add('Legend of Zelda, The - $subtitle (USA)');
            candidates.add('Legend of Zelda, The - $subtitle (U)');
            candidates.add('Legend of Zelda, The - $subtitle (USA) (Rev 1)');
            candidates.add('Legend of Zelda, The - $subtitle (USA) (Rev 2)');
          } else {
            candidates.add('Legend of Zelda, The (USA)');
            candidates.add('Legend of Zelda, The (U)');
          }
        }
      }

      // Special handling for Super Mario games
      if (cleanTitle.toLowerCase().contains('mario')) {
        candidates.add('$cleanTitle (USA) (Rev 1)');
        candidates.add('$cleanTitle (USA) (Rev 2)');
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      for (final name in candidates) {
        final encoded = Uri.encodeComponent(name);
        final url =
            'https://raw.githubusercontent.com/libretro-thumbnails/$system/master/Named_Boxarts/$encoded.png';

        try {
          final req = await client.headUrl(Uri.parse(url));
          final res = await req.close();

          if (res.statusCode == 200) {
            AppLogger.instance.debug('[GameMetadata] Found cover art: $url');
            return url;
          }
        } catch (_) {
          continue;
        }
      }

      return null;
    } catch (e) {
      AppLogger.instance.warning('[GameMetadata] Cover art fetch error: $e');
      return null;
    }
  }

  /// Clean title for searching
  String _cleanTitleForSearch(String title) {
    String clean = title;

    // Remove region tags
    clean = clean.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ');
    // Remove disc info
    clean = clean.replaceAll(RegExp(r'\s*\[[^\]]*\]\s*'), ' ');
    // Remove version info
    clean = clean.replaceAll(RegExp(r'\s*v\d+.*', caseSensitive: false), '');
    // Remove Rev info
    clean =
        clean.replaceAll(RegExp(r'\s*Rev\s*\d+.*', caseSensitive: false), '');
    // Normalize spaces
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    return clean;
  }

  /// Generate a basic description if Wikipedia fails
  String _generateDescription(String title, String platform) {
    final platformName = _getPlatformFullName(platform);
    return 'A $platformName game.';
  }

  /// Get full platform name
  String _getPlatformFullName(String platform) {
    final p = platform.toLowerCase();

    if (p == 'wii') return 'Nintendo Wii';
    if (p == 'wii u' || p == 'wiiu') return 'Nintendo Wii U';
    if (p == 'gamecube' || p == 'gc') return 'Nintendo GameCube';
    if (p == 'n64') return 'Nintendo 64';
    if (p == 'snes') return 'Super Nintendo';
    if (p == 'nes') return 'Nintendo Entertainment System';
    if (p == 'gba') return 'Game Boy Advance';
    if (p == 'gbc') return 'Game Boy Color';
    if (p == 'gb') return 'Game Boy';
    if (p == 'nds' || p == 'ds') return 'Nintendo DS';
    if (p == '3ds') return 'Nintendo 3DS';
    if (p == 'genesis') return 'Sega Genesis';
    if (p == 'dreamcast') return 'Sega Dreamcast';
    if (p == 'saturn') return 'Sega Saturn';
    if (p == 'ps1' || p == 'psx') return 'PlayStation';
    if (p == 'ps2') return 'PlayStation 2';
    if (p == 'psp') return 'PlayStation Portable';

    return platform;
  }

  /// Get Libretro system name for thumbnails
  String _getLibretroSystem(String platform) {
    final p = platform.toLowerCase();

    if (p == 'wii') return 'Nintendo_-_Wii';
    if (p == 'wii u' || p == 'wiiu') return 'Nintendo_-_Wii_U';
    if (p == 'gamecube' || p == 'gc') return 'Nintendo_-_GameCube';
    if (p == 'n64' || p == 'nintendo 64') return 'Nintendo_-_Nintendo_64';
    if (p == 'snes' || p == 'super nintendo') {
      return 'Nintendo_-_Super_Nintendo_Entertainment_System';
    }
    if ((p == 'nes' || p == 'nintendo') && !p.contains('super')) {
      return 'Nintendo_-_Nintendo_Entertainment_System';
    }
    if (p == 'gba' || p == 'game boy advance') {
      return 'Nintendo_-_Game_Boy_Advance';
    }
    if (p == 'gbc' || p == 'game boy color') return 'Nintendo_-_Game_Boy_Color';
    if (p == 'gb' || p == 'game boy') return 'Nintendo_-_Game_Boy';
    if (p == 'nds' || p == 'ds' || p == 'nintendo ds') {
      return 'Nintendo_-_Nintendo_DS';
    }
    if (p == '3ds' || p == 'nintendo 3ds') return 'Nintendo_-_Nintendo_3DS';
    if (p == 'genesis' || p == 'mega drive' || p == 'sega genesis') {
      return 'Sega_-_Mega_Drive_-_Genesis';
    }
    if (p == 'dreamcast' || p == 'sega dreamcast') return 'Sega_-_Dreamcast';
    if (p == 'saturn' || p == 'sega saturn') return 'Sega_-_Saturn';
    if (p == 'ps1' || p == 'psx' || p == 'playstation') {
      return 'Sony_-_PlayStation';
    }
    if (p == 'ps2' || p == 'playstation 2') return 'Sony_-_PlayStation_2';
    if (p == 'psp' || p == 'playstation portable') {
      return 'Sony_-_PlayStation_Portable';
    }

    return 'Nintendo_-_Wii';
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}

/// Rich game metadata model
class GameMetadata {
  final String title;
  final String description;
  final String? coverUrl;
  final String? releaseDate;
  final String? developer;
  final String? publisher;
  final List<String> genres;
  final String platform;
  final String? wikiUrl;

  const GameMetadata({
    required this.title,
    required this.description,
    required this.platform,
    this.coverUrl,
    this.releaseDate,
    this.developer,
    this.publisher,
    this.genres = const [],
    this.wikiUrl,
  });

  bool get hasRichData =>
      description.isNotEmpty &&
      description != 'A $platform game.' &&
      (developer != null || publisher != null || releaseDate != null);
}
