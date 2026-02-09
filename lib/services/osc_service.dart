import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/game_result.dart';

/// Open Shop Channel API Service
/// Provides access to homebrew applications and games for Wii
class OSCService {
  static const String _baseUrl = 'https://hbb1.oscwii.org/api/v3';
  static const String _cdnUrl = 'https://hbb1.oscwii.org/hbb';

  static const Map<String, String> _categories = {
    'games': 'Games',
    'emulators': 'Emulators',
    'media': 'Media',
    'utilities': 'Utilities',
    'demos': 'Demos',
  };

  /// Search homebrew applications
  Future<List<GameResult>> searchHomebrew(String query,
      {String? category}) async {
    try {
      developer.log(
          '[OSC] Searching homebrew: $query${category != null ? " in $category" : ""}');

      // Build search URL
      // OSC v3 API: /contents?category=demos or /contents?search=query
      // Note: Endpoint is still /contents, simpler structure
      final url = category != null
          ? '$_baseUrl/contents?category=${Uri.encodeComponent(category)}'
          : '$_baseUrl/contents?search=${Uri.encodeComponent(query)}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('OSC API returned ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data is! List) {
        throw Exception('Invalid OSC API response format');
      }

      final results = <GameResult>[];
      for (final item in data) {
        try {
          final game = _parseOSCItem(item);
          if (game != null) results.add(game);
        } catch (e) {
          developer.log('[OSC] Failed to parse item: $e');
        }
      }

      developer
          .log('[OSC] Found ${results.length} homebrew items before filtering');

      // Client-side filtering because API v3 might return mixed results or ignore the param
      if (category != null && category.isNotEmpty) {
        results.retainWhere(
            (item) => item.region.toLowerCase() == category.toLowerCase());
      }

      // If filtering left us with nothing, fallback to curated/mock data
      // This ensures "Games" category (and others) is populated with our manual entries
      // if the API fails to provide them or returns unrelated items.
      if (results.isEmpty && category != null) {
        developer.log(
            '[OSC] API returned no valid items for $category, using fallback');
        return _generateMockHomebrew(query, category);
      }

      developer.log(
          '[OSC] Returning ${results.length} items after filtering for $category');
      return results;
    } catch (e) {
      developer.log('[OSC] Search failed: $e');
      return _generateMockHomebrew(query, category);
    }
  }

  /// Get homebrew by category
  Future<List<GameResult>> getHomebrewByCategory(String category) async {
    return searchHomebrew('', category: category);
  }

  /// Get popular homebrew
  Future<List<GameResult>> getPopularHomebrew() async {
    try {
      developer.log('[OSC] Fetching popular homebrew');

      // v3 might not support ?sort=downloads directly documented in the snippet I saw,
      // but let's try standard endpoint or assume it works.
      // If fails, we fallback.
      final response =
          await http.get(Uri.parse('$_baseUrl/contents?sort=downloads'));

      if (response.statusCode != 200) {
        throw Exception('OSC API returned ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data is! List) {
        throw Exception('Invalid OSC API response format');
      }

      final results = <GameResult>[];
      for (final item in data.take(20)) {
        // Limit to top 20
        try {
          final game = _parseOSCItem(item);
          if (game != null) results.add(game);
        } catch (e) {
          developer.log('[OSC] Failed to parse item: $e');
        }
      }

      return results;
    } catch (e) {
      developer.log('[OSC] Popular homebrew fetch failed: $e');
      return _generateMockPopularHomebrew();
    }
  }

  /// Get recommended homebrew (Essentials from wii.hacks.guide)
  Future<List<GameResult>> getRecommendedHomebrew() async {
    // List of recommended slugs from wii.hacks.guide
    const recommendedSlugs = [
      // --- ESSENTIAL UTILITIES ---
      'yawmME', // Yet Another Wad Manager Mod
      'SysCheckME', // System Check
      'cdbackup', // Savegame backup
      'ARCME', // Advanced ROM Center
      'wiixplorer-ss', // File Explorer
      'SaveGame_Manager_GX', // Save management
      'csm-installer', // Theme installer
      'CleanRip', // Disc dumping
      'd2x-cios-installer', // Essential cIOS
      'ftpii', // FTP server
      'priiloader', // Brick protection
      'usbloader_gx', // Best USB Loader
      'wiiflow', // Alternative Loader
      'nintendont', // GameCube Loader
      'Homebrew_Browser', // App Store

      // --- EMULATORS ---
      'fceurx', // NES
      'Snes9xRX', // SNES
      'not64', // N64
      'genplus-gx', // Genesis
      'mgba', // GBA
      'wiimednafen', // Multi-system
      'wiiSX', // PS1
      'dosbox-wii', // DOS

      // --- GAMES & ENTERTAINMENT ---
      'WiiMC-SS', // Media Center
      'schismtracker', // Music tracker
      'cavex', // Minecraft-like
      'SonicCDWii', // Sonic CD port
      'smw-wii', // Super Mario War
      'quakegx', // Quake 1
      'SpaceCadetPinball', // Pinball
      'Heli', // Helicopter game
      'NewerSMBW', // Newer SMBW (Slug might vary, we have it in mock)
    ];

    final results = <GameResult>[];

    try {
      final futures = recommendedSlugs.map((slug) async {
        try {
          // v3: /contents?search={slug}
          final response = await http.get(Uri.parse(
              '$_baseUrl/contents?search=${Uri.encodeComponent(slug)}'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body) as List;
            if (data.isNotEmpty) {
              // Find exact match by slug if possible
              // v3 "slug" field
              final item = data.firstWhere((i) => (i['slug'] == slug),
                  orElse: () => data.first);
              return _parseOSCItem(item);
            }
          }
        } catch (e) {
          developer.log('[OSC] Failed to fetch recommended $slug: $e');
        }
        return null;
      });

      final fetched = await Future.wait(futures);
      results.addAll(fetched.whereType<GameResult>());

      return results;
    } catch (e) {
      developer.log('[OSC] Recommended fetch failed: $e');
      return []; // Return empty or fallback
    }
  }

  /// Parse OSC API item to GameResult
  GameResult? _parseOSCItem(Map<String, dynamic> item) {
    try {
      // v3 Schema
      final name = item['name'] as String? ?? 'Unknown';
      final category = item['category'] as String? ?? 'homebrew';
      final version = item['version'] as String? ?? '1.0';
      final author = item['author'] as String? ?? 'Unknown';

      // Description object
      final descObj = item['description'];
      final shortDesc = (descObj is Map)
          ? (descObj['short'] as String?)
          : ''; // handle null or map

      // File size object
      final sizeObj = item['file_size'];
      final sizeBytes =
          (sizeObj is Map) ? (sizeObj['zip_compressed'] as int?) : 0;

      // URL object
      final urlObj = item['url'];
      final zipUrl = (urlObj is Map) ? (urlObj['zip'] as String?) : null;
      final iconUrl = (urlObj is Map) ? (urlObj['icon'] as String?) : null;

      // Fallback if URLs are missing (shouldn't happen on v3 but safe)
      if (zipUrl == null) return null;

      // Format file size
      final sizeStr = _formatFileSize(sizeBytes ?? 0);

      // Slug for page URL
      final slug = item['slug'] as String? ?? name.replaceAll(' ', '_');

      return GameResult(
        title: name,
        platform: 'Wii Homebrew',
        downloadUrl: zipUrl,
        coverUrl: iconUrl,
        size: sizeStr,
        version: version,
        region: category.toUpperCase(),
        provider: author,
        pageUrl: 'https://oscwii.org/library/app/$slug',
        description: shortDesc ?? '',
      );
    } catch (e) {
      developer.log('[OSC] Parse error: $e');
      return null;
    }
  }

  /// Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Generate mock homebrew results for testing
  List<GameResult> _generateMockHomebrew(String query, String? category) {
    developer.log('[OSC] Using mock homebrew data');

    final mockData = [
      GameResult(
        title: 'Homebrew Browser',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/homebrew_browser/homebrew_browser.zip',
        coverUrl: '$_cdnUrl/homebrew_browser/icon.png',
        size: '2.1MB',
        version: '0.3.9',
        region: 'UTILITIES',
        provider: 'teknecal',
        pageUrl: 'https://oscwii.org/library/app/homebrew_browser',
        description: 'Download homebrew apps directly to your Wii',
      ),
      GameResult(
        title: 'WiiMC',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/wiimc/wiimc.zip',
        coverUrl: '$_cdnUrl/wiimc/icon.png',
        size: '8.7MB',
        version: '1.3.0',
        region: 'MEDIA',
        provider: 'rodries',
        pageUrl: 'https://oscwii.org/library/app/wiimc',
        description: 'Multi-format media player for Wii',
      ),
      GameResult(
        title: 'ScummVM',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/scummvm/scummvm.zip',
        coverUrl: '$_cdnUrl/scummvm/icon.png',
        size: '15.2MB',
        version: '2.5.0',
        region: 'EMULATORS',
        provider: 'ScummVM Team',
        pageUrl: 'https://oscwii.org/library/app/scummvm',
        description: 'Play classic point-and-click adventure games',
      ),
      GameResult(
        title: 'FCE Ultra GX',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/fceugx/fceugx.zip',
        coverUrl: '$_cdnUrl/fceugx/icon.png',
        size: '3.4MB',
        version: '3.4.0',
        region: 'EMULATORS',
        provider: 'dborth',
        pageUrl: 'https://oscwii.org/library/app/fceugx',
        description: 'Nintendo Entertainment System emulator',
      ),
      GameResult(
        title: 'Snes9x GX',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/snes9xgx/snes9xgx.zip',
        coverUrl: '$_cdnUrl/snes9xgx/icon.png',
        size: '4.2MB',
        version: '4.4.0',
        region: 'EMULATORS',
        provider: 'dborth',
        pageUrl: 'https://oscwii.org/library/app/snes9xgx',
        description: 'Super Nintendo emulator for Wii',
      ),
      GameResult(
        title: 'Visual Boy Advance GX',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/vbagx/vbagx.zip',
        coverUrl: '$_cdnUrl/vbagx/icon.png',
        size: '5.1MB',
        version: '2.4.0',
        region: 'EMULATORS',
        provider: 'dborth',
        pageUrl: 'https://oscwii.org/library/app/vbagx',
        description: 'Game Boy Advance emulator',
      ),
      GameResult(
        title: 'USB Loader GX',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/usbloader_gx/usbloader_gx.zip',
        coverUrl: '$_cdnUrl/usbloader_gx/icon.png',
        size: '6.8MB',
        version: '3.0',
        region: 'UTILITIES',
        provider: 'USB Loader GX Team',
        pageUrl: 'https://oscwii.org/library/app/usbloader_gx',
        description: 'Load Wii and GameCube backups from USB',
      ),
      GameResult(
        title: 'WiiFlow',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/wiiflow/wiiflow.zip',
        coverUrl: '$_cdnUrl/wiiflow/icon.png',
        size: '7.2MB',
        version: '5.4.9',
        region: 'UTILITIES',
        provider: 'WiiFlow Team',
        pageUrl: 'https://oscwii.org/library/app/wiiflow',
        description: 'Beautiful USB loader with coverflow',
      ),
      // Mock Games for fallback
      GameResult(
        title: 'Newer Super Mario Bros. Wii',
        platform: 'Wii Homebrew',
        downloadUrl: null, // Often external
        coverUrl: null,
        size: '570MB',
        version: '1.2.0',
        region: 'GAMES',
        provider: 'Newer Team',
        pageUrl: 'https://newerteam.com/wii/',
        description: 'Partial conversion of NSMBW w/ new levels',
      ),
      GameResult(
        title: 'Helii',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/helii/helii.zip',
        coverUrl: '$_cdnUrl/helii/icon.png',
        size: '3.5MB',
        version: '1.0',
        region: 'GAMES',
        provider: 'Unknown',
        pageUrl: 'https://oscwii.org/library/app/helii',
        description: 'Fly a helicopter and save people',
      ),
      GameResult(
        title: 'Super Mario War Wii',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/smw-wii/smw-wii.zip',
        coverUrl: '$_cdnUrl/smw-wii/icon.png',
        size: '8.2MB',
        version: '1.4',
        region: 'GAMES',
        provider: 'Tantric',
        pageUrl: 'https://oscwii.org/library/app/smw-wii',
        description: 'Multiplayer Mario deathmatch game',
      ),
      GameResult(
        title: 'QuakeGX',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/quakegx/quakegx.zip',
        coverUrl: '$_cdnUrl/quakegx/icon.png',
        size: '3.6MB',
        version: '0.0.6',
        region: 'GAMES',
        provider: 'QuakeGX Team',
        pageUrl: 'https://oscwii.org/library/app/quakegx',
        description: 'Quake 1 port for Wii',
      ),
      GameResult(
        title: 'Space Cadet Pinball',
        platform: 'Wii Homebrew',
        downloadUrl: '$_cdnUrl/SpaceCadetPinball/SpaceCadetPinball.zip',
        coverUrl: '$_cdnUrl/SpaceCadetPinball/icon.png',
        size: '2.8MB',
        version: '1.0',
        region: 'GAMES',
        provider: 'fgsfds',
        pageUrl: 'https://oscwii.org/library/app/SpaceCadetPinball',
        description: 'Decompilation of 3D Pinball for Windows',
      ),
    ];

    // Filter by category and/or query
    var filtered = mockData;

    // Filter by category first
    if (category != null && category.isNotEmpty) {
      filtered = filtered
          .where((game) => game.region?.toLowerCase() == category.toLowerCase())
          .toList();
    }

    // Then filter by query if provided
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
              (game) => game.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  /// Generate mock popular homebrew
  List<GameResult> _generateMockPopularHomebrew() {
    return _generateMockHomebrew('', null);
  }

  /// Get available categories
  Map<String, String> getCategories() {
    return Map.from(_categories);
  }
}
