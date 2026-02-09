import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// Archive.org Provider for Wii and GameCube collections
class ArchiveOrgProvider {
  static const String wiiCollection = 'ghostware-wii-archive';
  static const String gcCollection = 'GamecubeCollectionByGhostware';

  /// Search for a game in Archive.org collections
  Future<List<ArchiveResult>> search(String query) async {
    final results = <ArchiveResult>[];

    // Search both Wii and GameCube collections
    results.addAll(await _searchCollection(wiiCollection, query, 'Wii'));
    results.addAll(await _searchCollection(gcCollection, query, 'GameCube'));

    return results;
  }

  Future<List<ArchiveResult>> _searchCollection(
    String collection,
    String query,
    String console,
  ) async {
    try {
      // Fetch files.xml to get game list
      final filesUrl =
          'https://archive.org/download/$collection/${collection}_files.xml';
      final response = await http.get(Uri.parse(filesUrl));

      if (response.statusCode != 200) {
        debugPrint('[Archive] Failed to fetch $collection metadata');
        return [];
      }

      // Parse XML
      final document = xml.XmlDocument.parse(response.body);
      final files = document.findAllElements('file');

      final results = <ArchiveResult>[];
      final lowerQuery = query.toLowerCase();

      for (final file in files) {
        final name = file.getAttribute('name') ?? '';
        if (name.endsWith('.iso') && name.toLowerCase().contains(lowerQuery)) {
          // Extract clean title
          final title = name.replaceAll('.iso', '').replaceAll('_', ' ');

          results.add(ArchiveResult(
            title: title,
            console: console,
            fileName: name,
            collection: collection,
            // Files are locked, use torrent magnet link
            downloadStrategy: DownloadStrategy.torrent,
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('[Archive] Error searching $collection: $e');
      return [];
    }
  }

  /// Generate magnet link for Archive.org item
  /// NOTE: Archive.org files are locked, we must use their torrent
  String generateMagnetLink(String collection, String fileName) {
    // Return the collection download page
    return 'https://archive.org/details/$collection';
  }
}

enum DownloadStrategy {
  directHttp,
  torrent,
  browserBypass,
}

class ArchiveResult {
  final String title;
  final String console;
  final String fileName;
  final String collection;
  final DownloadStrategy downloadStrategy;

  ArchiveResult({
    required this.title,
    required this.console,
    required this.fileName,
    required this.collection,
    required this.downloadStrategy,
  });
}
