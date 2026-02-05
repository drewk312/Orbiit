import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// RomsFun Provider (Browser Automation Required)
///
/// This provider handles romsfun.com which uses CloudFlare protection.
/// It provides both HTTP-based search (limited) and browser automation hooks.
class RomsFunProvider {
  static const String _baseUrl = 'https://romsfun.com';
  static const String _searchUrl = 'https://romsfun.com/roms';

  /// Search romsfun.com for games via HTTP.
  /// Returns empty list if CloudFlare blocks or parse yields no results.
  Future<List<RomsFunResult>> search(String query) async {
    try {
      final results = await _httpSearch(query);
      return results;
    } catch (e) {
      debugPrint('[RomsFun] HTTP search failed: $e');
      return [];
    }
  }

  /// Attempt HTTP-based search (may fail due to CloudFlare)
  Future<List<RomsFunResult>> _httpSearch(String query) async {
    final url = '$_searchUrl?search=${Uri.encodeComponent(query)}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 403 || response.statusCode == 503) {
      throw Exception('CloudFlare protection active');
    }

    if (response.statusCode == 200) {
      return _parseSearchResults(response.body);
    }

    return [];
  }

  /// Parse search results from HTML response
  List<RomsFunResult> _parseSearchResults(String html) {
    final results = <RomsFunResult>[];

    // Simple regex-based parsing for game cards
    final titleRegex = RegExp(r'class="game-title[^"]*"[^>]*>([^<]+)</');
    final linkRegex = RegExp(r'href="(https://romsfun\.com/roms/[^"]+)"');
    final imgRegex =
        RegExp(r'<img[^>]+src="([^"]+)"[^>]+class="[^"]*game-cover');

    final titles = titleRegex.allMatches(html).map((m) => m.group(1)!).toList();
    final links = linkRegex.allMatches(html).map((m) => m.group(1)!).toList();
    final images = imgRegex.allMatches(html).map((m) => m.group(1)!).toList();

    final count = [titles.length, links.length].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < count; i++) {
      final console = _detectConsole(links[i]);
      results.add(RomsFunResult(
        title: titles[i].trim(),
        console: console,
        pageUrl: links[i],
        thumbnailUrl: i < images.length ? images[i] : null,
      ));
    }

    return results;
  }

  String _detectConsole(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('nintendo-wii-iso')) return 'Wii';
    if (lower.contains('gamecube')) return 'GameCube';
    if (lower.contains('nintendo-ds')) return 'DS';
    if (lower.contains('nintendo-3ds')) return '3DS';
    if (lower.contains('switch')) return 'Switch';
    if (lower.contains('ps2')) return 'PS2';
    if (lower.contains('ps3')) return 'PS3';
    if (lower.contains('psp')) return 'PSP';
    if (lower.contains('xbox')) return 'Xbox';
    return 'Other';
  }

  /// Resolve download link for a game page. Fetches HTML and parses for download links.
  /// Returns null if page is protected (CloudFlare) or no link found.
  Future<String?> resolveDownloadLink(String pageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(pageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      // Look for common download link patterns: .zip, /download/, direct file links
      final body = response.body;
      final zipLink = RegExp(
        r'href="([^"]+\.zip[^"]*)"',
        caseSensitive: false,
      ).firstMatch(body);
      if (zipLink != null) {
        final href = zipLink.group(1)!;
        if (href.startsWith('http')) return href;
        if (href.startsWith('//')) return 'https:$href';
        final base = Uri.parse(pageUrl);
        return base.resolve(href).toString();
      }

      final downloadLink = RegExp(
        r'href="([^"]*download[^"]*)"',
        caseSensitive: false,
      ).firstMatch(body);
      if (downloadLink != null) {
        final href = downloadLink.group(1)!;
        if (href.startsWith('http')) return href;
        if (href.startsWith('//')) return 'https:$href';
        final base = Uri.parse(pageUrl);
        return base.resolve(href).toString();
      }

      return null;
    } catch (e) {
      debugPrint('[RomsFun] resolveDownloadLink failed: $e');
      return null;
    }
  }

}

class RomsFunResult {
  final String title;
  final String console;
  final String pageUrl;
  final String? thumbnailUrl;

  RomsFunResult({
    required this.title,
    required this.console,
    required this.pageUrl,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'console': console,
        'pageUrl': pageUrl,
        'thumbnailUrl': thumbnailUrl,
      };
}
