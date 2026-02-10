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

  /// Get available categories
  Map<String, String> getCategories() {
    return _categories;
  }

  /// Get homebrew by category
  Future<List<GameResult>> getHomebrewByCategory(String category) async {
    return searchHomebrew('', category: category);
  }

  /// Search homebrew applications
  Future<List<GameResult>> searchHomebrew(String query,
      {String? category}) async {
    try {
      developer.log(
          '[OSC] Searching homebrew: $query${category != null ? " in $category" : ""}');

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

      // Client-side filtering because API v3 might return mixed results or ignore the param
      if (category != null && category.isNotEmpty) {
        results.retainWhere(
            (item) => item.region.toLowerCase() == category.toLowerCase());
      }

      // If filtering left us with nothing, return empty
      if (results.isEmpty && category != null) {
        developer.log('[OSC] No results found for category: $category');
        return [];
      }

      return results;
    } catch (e) {
      developer.log('[OSC] Search failed: $e');
      return [];
    }
  }

  /// Get popular homebrew
  Future<List<GameResult>> getPopularHomebrew() async {
    try {
      developer.log('[OSC] Fetching popular homebrew');

      // Specific list for popular recommendation fallback or prioritization
      const popularSlugs = [
        'usbloader_gx',
        'nintendont',
        'priiloader',
        'wiixplorer',
        'savegame_manager_gx',
        'cleanrip',
        'fceugx', 
        'snes9xgx',
        'vbagx',
        'genplus-gx',
        'not64', 
        'wiimednafen',
        'wiistation',
        'd2x-cios-installer',
        'yawmme',
      ];

      final results = <GameResult>[];
      final client = http.Client();

      final response = await client.get(Uri.parse('$_baseUrl/contents'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        // 1. Find all recommended apps first (to float them to top)
        for (final slug in popularSlugs) {
          try {
            final match = data.firstWhere(
              (item) => item['slug'] == slug || item['name'].toString().toLowerCase().contains(slug.replaceAll('_', ' ')),
              orElse: () => null,
            );
            
            if (match != null) {
              final game = _parseOSCItem(match);
              if (game != null) results.add(game);
            }
          } catch (_) {}
        }
        
        // 2. Add other high-rated items to fill the list
        for (final item in data.take(50)) {
           final game = _parseOSCItem(item);
           if (game != null && !results.any((r) => r.pageUrl == game.pageUrl)) {
             results.add(game);
           }
        }
      }

      client.close();

      if (results.isEmpty) throw Exception('No results from API');
      return results;
    } catch (e) {
      developer.log('[OSC] Popular fetch failed: $e');
      return [];
    }
  }

  /// Get recommended homebrew (Essentials from wii.hacks.guide)
  Future<List<GameResult>> getRecommendedHomebrew() async {
    // List of recommended slugs from wii.hacks.guide
    const recommendedSlugs = [
      'usbloader_gx',
      'nintendont',
      'priiloader',
      'wiixplorer',
      'savegame_manager_gx',
      'cleanrip',
      'fceugx',
      'snes9xgx',
      'vbagx',
      'genplus-gx',
      'not64',
      'wiimednafen',
      'wiistation',
      'd2x-cios-installer',
      'yawmme',
      'syscheck-hde',
      'wiimodlite',
      'hackmii_installer',
      'blue-dump-mod',
      'bbb',
      'ftpii',
      'wii-earth',
      'wiimc-ss',
      'quake-wii',
      'doom-wii',
      'blobby-volley-2',
      'super-mario-war-wii',
      'riivolution',
      'wiiflow',
      'retroarch-wii',
      'newersmbw',
      'scummvm',
      'wii64',
      'helium-boy',
    ];

    final client = http.Client();
    try {
      final results = <GameResult>[];
      final response = await client.get(Uri.parse('$_baseUrl/contents'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
         for (final slug in recommendedSlugs) {
          try {
            final match = data.firstWhere(
              (item) => item['slug'] == slug || item['name'].toString().toLowerCase().contains(slug.replaceAll('_', ' ')),
              orElse: () => null,
            );
            if (match != null) {
              final game = _parseOSCItem(match);
              if (game != null) results.add(game);
            }
          } catch (_) {}
        }
      }
      return results;
    } catch (e) {
      developer.log('[OSC] Recommended fetch failed: $e');
      return [];
    } finally {
      client.close();
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
        slug: slug,
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
      // Add more mocks if needed, kept simple for now
    ];

    var filtered = mockData;

    if (category != null && category.isNotEmpty) {
      filtered = filtered
          .where((game) => game.region.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where(
              (game) => game.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}
