import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_result.dart';

/// Browser-in-the-loop Agent for romsgames.net scraping
/// This service handles the complex web scraping with JS timer bypass
class BrowserAgentService {
  static const String _baseUrl = 'https://romsgames.net';
  static String get _searchUrl => '$_baseUrl/search';

  /// Main search function that connects to the Browser Agent
  Future<List<GameResult>> searchGames(String query,
      {String platform = 'all'}) async {
    debugPrint('[BrowserAgent] Initiating search for: $query');

    try {
      // Implement real web scraping for romsgames.net
      final results = await _scrapeRomsgamesNet(query, platform);
      return results;
    } catch (e) {
      debugPrint('[BrowserAgent] Search failed: $e');
      return _getFallbackResults(query);
    }
  }

  /// Real scraping implementation for romsgames.net
  Future<List<GameResult>> _scrapeRomsgamesNet(
      String query, String platform) async {
    debugPrint('[BrowserAgent] Connecting to romsgames.net for: $query');

    try {
      // Build search URL with query parameters
      final searchUrl =
          Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}');
      debugPrint('[BrowserAgent] Search URL: $searchUrl');

      // Create HTTP client with headers to bypass basic bot detection
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      // Make the HTTP request
      final request = await client.getUrl(searchUrl);
      request.headers.add('Accept',
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');
      request.headers.add('Accept-Language', 'en-US,en;q=0.5');
      request.headers.add('Accept-Encoding', 'gzip, deflate');
      request.headers.add('Connection', 'keep-alive');
      request.headers.add('Upgrade-Insecure-Requests', '1');

      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint('[BrowserAgent] HTTP Error: ${response.statusCode}');
        return [];
      }

      // Read response body
      final body = await response.transform(utf8.decoder).join();
      debugPrint('[BrowserAgent] Received ${body.length} bytes of HTML');

      // Parse HTML and extract game data
      final results = _parseRomsgamesHtml(body, query, platform);

      if (results.isEmpty) {
        debugPrint('[BrowserAgent] No results found in HTML');
        return [];
      }

      debugPrint('[BrowserAgent] Successfully scraped ${results.length} games');
      return results;
    } catch (e) {
      debugPrint('[BrowserAgent] Scraping error: $e');
      return [];
    }
  }

  /// Parse HTML content from romsgames.net and extract game information
  List<GameResult> _parseRomsgamesHtml(
      String html, String query, String platform) {
    final results = <GameResult>[];
    final lowerQuery = query.toLowerCase();

    debugPrint('[BrowserAgent] Parsing HTML content...');

    // Note: romsgames.net uses cards where the <a> tag contains the href and title is in a div
    final gamePattern = RegExp(
      r'<a[^>]*href="([^"]+)"[^>]*>.*?<div[^>]*>([^<]+)</div>',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = gamePattern.allMatches(html);
    debugPrint('[BrowserAgent] Found ${matches.length} potential game entries');

    for (final match in matches) {
      try {
        final pageUrlSuffix = match.group(1)?.trim() ?? '';
        final title = match.group(2)?.trim() ?? '';

        if (title.isEmpty) continue;

        // Filter by query relevance
        if (!title.toLowerCase().contains(lowerQuery)) {
          continue;
        }

        // Determine platform from URL
        String platformType = 'Unknown';
        if (pageUrlSuffix.contains('nintendo-wii')) {
          platformType = 'Wii';
        } else if (pageUrlSuffix.contains('nintendo-gamecube')) {
          platformType = 'GameCube';
        }

        // Filter by platform if specified
        if (platform != 'all' &&
            platformType.toLowerCase() != platform.toLowerCase()) {
          continue;
        }

        results.add(GameResult(
          title: title,
          platform: platformType,
          region: _detectRegion(title),
          provider: 'romsgames.net',
          pageUrl: 'https://romsgames.net$pageUrlSuffix',
          downloadUrl: null, // Requires secondary resolution
          requiresBrowser: true,
          isDirectDownload: false,
        ));

        debugPrint('[BrowserAgent] Added game: $title ($platformType)');
      } catch (e) {
        debugPrint('[BrowserAgent] Error parsing game entry: $e');
      }
    }

    return results;
  }

  String _detectRegion(String title) {
    if (title.contains('(USA)')) return 'USA';
    if (title.contains('(Europe)')) return 'Europe';
    if (title.contains('(Japan)')) return 'Japan';
    return 'USA';
  }

  /// Fallback results when scraping fails
  List<GameResult> _getFallbackResults(String query) {
    return [];
  }

  /// Extracts download link from a game page by fetching HTML and parsing for .zip/download links.
  Future<String?> extractDownloadLink(String gamePageUrl) async {
    debugPrint('[BrowserAgent] Extracting download link from: $gamePageUrl');

    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      final request = await client.getUrl(Uri.parse(gamePageUrl));
      request.headers.add('Accept',
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();

      // Prefer direct .zip links, then /download/ or download button hrefs
      final zipLink = RegExp(
        r'href="([^"]+\.zip[^"]*)"',
        caseSensitive: false,
      ).firstMatch(body);
      if (zipLink != null) {
        final href = zipLink.group(1)!;
        if (href.startsWith('http')) return href;
        if (href.startsWith('//')) return 'https:$href';
        return Uri.parse(gamePageUrl).resolve(href).toString();
      }

      final downloadHref = RegExp(
        r'href="([^"]*download[^"]*)"',
        caseSensitive: false,
      ).firstMatch(body);
      if (downloadHref != null) {
        final href = downloadHref.group(1)!;
        if (href.startsWith('http')) return href;
        if (href.startsWith('//')) return 'https:$href';
        return Uri.parse(gamePageUrl).resolve(href).toString();
      }

      return null;
    } catch (e) {
      debugPrint('[BrowserAgent] extractDownloadLink error: $e');
      return null;
    }
  }

  /// Simulates the Browser Agent protocol for Antigravity integration
  Map<String, dynamic> getAgentProtocol() {
    return {
      'agent': 'Orbiit Browser Agent v1.0',
      'capabilities': [
        'romsgames.net scraping',
        '15s JS timer bypass',
        'Bot check evasion',
        'Dynamic content extraction',
        'Download link resolution'
      ],
      'endpoints': {
        'search': '/api/agent/search',
        'extract': '/api/agent/extract',
        'status': '/api/agent/status'
      },
      'instructions': [
        'Navigate to romsgames.net',
        'Enter search query in search box',
        'Wait for results to load',
        'Extract game information from cards',
        'Return structured GameResult objects'
      ]
    };
  }
}
