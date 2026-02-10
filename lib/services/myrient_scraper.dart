import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart';

class MyrientScraper {
  /// Searches a Myrient directory for a file matching the query.
  /// Returns the full download URL if found, or null.
  Future<String?> findGameUrl(String baseUrl, String query) async {
    final client = HttpClient();

    try {
      debugPrint('[MyrientScraper] Fetching listing from: $baseUrl');
      // 1. Fetch the HTML directory listing
      final request = await client.getUrl(Uri.parse(baseUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint(
            "[MyrientScraper] Failed to reach Myrient: ${response.statusCode}");
        return null;
      }

      final htmlBody =
          await response.transform(SystemEncoding().decoder).join();

      // 2. Parse the HTML to find all links (hrefs)
      final document = html_parser.parse(htmlBody);
      final anchors = document.querySelectorAll('a');

      // 3. Filter and match
      String? bestMatchUrl;

      // Simple case-insensitive contains check
      // Normalize query: remove special chars, lowercase
      final normalizedQuery = _normalize(query);
      debugPrint('[MyrientScraper] Looking for: "$normalizedQuery"');

      for (var anchor in anchors) {
        final href = anchor.attributes['href'];
        var text = anchor.text;

        if (href == null || href.isEmpty) continue;
        if (href == '../' || href.contains('Parent Directory')) continue;

        // Clean up filename for comparison
        // Decode URL encoding just in case text is encoded
        try {
          text = Uri.decodeComponent(text);
        } catch (_) {}

        final lower = text.toLowerCase();

        // Check extensions (zip for No-Intro, rvz for Redump, etc)
        if (!lower.endsWith('.zip') &&
            !lower.endsWith('.rvz') &&
            !lower.endsWith('.7z') &&
            !lower.endsWith('.iso')) {
          continue;
        }

        final normalizedFilename = _normalize(text);

        // Check if the filename contains our search query
        // We use a robust "all terms present" check
        if (normalizedFilename.contains(normalizedQuery)) {
          bestMatchUrl = baseUrl + href;
          debugPrint('[MyrientScraper] Found match: $text -> $bestMatchUrl');
          break;
        }
      }

      return bestMatchUrl;
    } catch (e) {
      debugPrint("[MyrientScraper] Error searching Myrient: $e");
      return null;
    } finally {
      client.close();
    }
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
