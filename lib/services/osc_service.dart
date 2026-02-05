import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/game_result.dart';

/// Open Shop Channel API Service
/// Provides access to homebrew applications and games for Wii
class OSCService {
  static const String _baseUrl = 'https://api.oscwii.org/v2';
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

      developer.log('[OSC] Found ${results.length} homebrew items');
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

  /// Parse OSC API item to GameResult
  GameResult? _parseOSCItem(Map<String, dynamic> item) {
    try {
      final name = item['name'] as String? ?? '';
      final displayName = item['display_name'] as String? ?? name;
      final category = item['category'] as String? ?? 'homebrew';
      final version = item['version'] as String? ?? '1.0';
      final size = item['file_size'] as int? ?? 0;
      final coder = item['coder'] as String? ?? 'Unknown';
      final shortDesc = item['short_description'] as String? ?? '';

      // Build download URL
      final downloadUrl = '$_cdnUrl/$name/$name.zip';

      // Build icon URL - OSC serves app icons at predictable paths
      final iconUrl = '$_cdnUrl/$name/icon.png';

      // Format file size
      final sizeStr = _formatFileSize(size);

      return GameResult(
        title: displayName,
        platform: 'Wii Homebrew',
        downloadUrl: downloadUrl,
        coverUrl: iconUrl, // Use OSC app icon as cover
        size: sizeStr,
        version: version,
        region: category.toUpperCase(),
        provider: coder.isNotEmpty ? coder : 'Open Shop Channel',
        pageUrl: 'https://oscwii.org/library/app/$name',
        description: shortDesc,
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
    ];

    // Filter by category and/or query
    var filtered = mockData;
    
    // Filter by category first
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((game) => 
        game.region?.toLowerCase() == category.toLowerCase()
      ).toList();
    }
    
    // Then filter by query if provided
    if (query.isNotEmpty) {
      filtered = filtered.where((game) => 
        game.title.toLowerCase().contains(query.toLowerCase())
      ).toList();
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
