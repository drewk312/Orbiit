import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:xml/xml.dart';

/// Service for managing WiiTDB database - rich game metadata
/// Based on TinyWii's approach but with better caching and parsing
class WiiTDBService {
  // Use official GameTDB.com source (was GitHub mirror which now returns 404)
  static const String _downloadUrl =
      'https://www.gametdb.com/wiitdb.zip?LANG=EN';
  static const String _cacheFileName = 'wiitdb_en.xml';
  static const String _zipFileName = 'wiitdb.zip';

  static Map<String, GameMetadata>? _cachedDatabase;
  static DateTime? _lastUpdate;

  /// Get the WiiTDB cache directory
  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory(path.join(appDir.path, 'wiigc_fusion', 'wiitdb'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Check if database is cached and up-to-date (refresh every 30 days)
  static Future<bool> isDatabaseCached() async {
    final cacheDir = await _getCacheDir();
    final file = File(path.join(cacheDir.path, _cacheFileName));

    if (!await file.exists()) return false;

    final lastModified = await file.lastModified();
    final daysSinceUpdate = DateTime.now().difference(lastModified).inDays;

    return daysSinceUpdate < 30; // Refresh monthly
  }

  /// Download and extract WiiTDB database
  static Future<void> downloadDatabase({
    Function(int current, int total)? onProgress,
  }) async {
    final cacheDir = await _getCacheDir();
    final zipFile = File(path.join(cacheDir.path, _zipFileName));
    final xmlFile = File(path.join(cacheDir.path, _cacheFileName));

    // Download ZIP with headers to avoid 403/404
    final response = await http.get(
      Uri.parse(_downloadUrl),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode == 200) {
      // Save ZIP file
      await zipFile.writeAsBytes(response.bodyBytes);

      // Extract XML from ZIP using archive package
      try {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        // Find the wiitdb.xml file in the archive
        for (final file in archive) {
          if (file.name.toLowerCase().contains('wiitdb') &&
              file.name.endsWith('.xml')) {
            await xmlFile.writeAsBytes(file.content as List<int>);
            break;
          }
        }

        // Clean up ZIP file
        if (await zipFile.exists()) {
          await zipFile.delete();
        }

        _cachedDatabase = null; // Clear cache to force reload
        _lastUpdate = DateTime.now();
      } catch (e) {
        throw Exception('Failed to extract WiiTDB ZIP: $e');
      }
    } else {
      throw Exception('Failed to download WiiTDB: ${response.statusCode}');
    }
  }

  /// Load and parse the WiiTDB database
  static Future<Map<String, GameMetadata>> loadDatabase() async {
    // Return cached if available
    if (_cachedDatabase != null) {
      return _cachedDatabase!;
    }

    final cacheDir = await _getCacheDir();
    final xmlFile = File(path.join(cacheDir.path, _cacheFileName));

    if (!await xmlFile.exists()) {
      throw Exception('WiiTDB database not found. Please download it first.');
    }

    final xmlContent = await xmlFile.readAsString();
    final document = XmlDocument.parse(xmlContent);

    final database = <String, GameMetadata>{};

    // Parse all game entries
    for (final gameNode in document.findAllElements('game')) {
      try {
        final metadata = _parseGameNode(gameNode);
        if (metadata != null) {
          database[metadata.id] = metadata;
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    _cachedDatabase = database;
    return database;
  }

  /// Parse individual game XML node
  static GameMetadata? _parseGameNode(XmlElement gameNode) {
    final id = gameNode.getAttribute('name');
    if (id == null) return null;

    final type = gameNode.findElements('type').firstOrNull?.innerText;

    // Locale nodes (titles in different languages)
    final locales = <String, LocaleData>{};
    for (final locale in gameNode.findElements('locale')) {
      final lang = locale.getAttribute('lang') ?? 'EN';
      final title = locale.findElements('title').firstOrNull?.innerText;
      final synopsis = locale.findElements('synopsis').firstOrNull?.innerText;

      if (title != null) {
        locales[lang] = LocaleData(
          title: title,
          synopsis: synopsis,
        );
      }
    }

    // Get primary title (English fallback)
    final title =
        locales['EN']?.title ?? locales.values.firstOrNull?.title ?? 'Unknown';

    // Developer/Publisher
    final developer = gameNode.findElements('developer').firstOrNull?.innerText;
    final publisher = gameNode.findElements('publisher').firstOrNull?.innerText;

    // Dates
    final date = gameNode.findElements('date').firstOrNull;
    final year = date?.getAttribute('year');
    final month = date?.getAttribute('month');
    final day = date?.getAttribute('day');

    // Genre
    final genre = gameNode.findElements('genre').firstOrNull?.innerText;

    // Rating
    final rating = gameNode.findElements('rating').firstOrNull;
    final ratingType = rating?.getAttribute('type');
    final ratingValue = rating?.getAttribute('value');

    // Players
    final input = gameNode.findElements('input').firstOrNull;
    final players = input?.getAttribute('players');

    // Wi-Fi features
    final wifi = gameNode.findElements('wi-fi').firstOrNull;
    final wifiPlayers = wifi?.getAttribute('players');
    final wifiFeatures = <String>[];
    for (final feature in wifi?.findElements('feature') ?? <XmlElement>[]) {
      final featureName = feature.innerText;
      if (featureName.isNotEmpty) {
        wifiFeatures.add(featureName);
      }
    }

    // ROM info (for checksums)
    final roms = <RomInfo>[];
    for (final rom in gameNode.findElements('rom')) {
      final name = rom.getAttribute('name');
      final size = rom.getAttribute('size');
      final crc = rom.getAttribute('crc');
      final md5 = rom.getAttribute('md5');
      final sha1 = rom.getAttribute('sha1');

      if (name != null) {
        roms.add(RomInfo(
          name: name,
          size: size != null ? int.tryParse(size) : null,
          crc32: crc,
          md5: md5,
          sha1: sha1,
        ));
      }
    }

    return GameMetadata(
      id: id,
      type: type,
      locales: locales,
      developer: developer,
      publisher: publisher,
      releaseYear: year,
      releaseMonth: month,
      releaseDay: day,
      genre: genre,
      ratingType: ratingType,
      ratingValue: ratingValue,
      players: players,
      wifiPlayers: wifiPlayers,
      wifiFeatures: wifiFeatures,
      roms: roms,
    );
  }

  /// Get metadata for a specific game ID
  static Future<GameMetadata?> getGameMetadata(String gameId) async {
    final database = await loadDatabase();
    return database[gameId];
  }

  /// Search games by title
  static Future<List<GameMetadata>> searchByTitle(String query) async {
    final database = await loadDatabase();
    final lowerQuery = query.toLowerCase();

    return database.values
        .where((game) => game.title.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get all games of a specific genre
  static Future<List<GameMetadata>> getGamesByGenre(String genre) async {
    final database = await loadDatabase();

    return database.values
        .where((game) => game.genre?.toLowerCase() == genre.toLowerCase())
        .toList();
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final database = await loadDatabase();

    final wiiGames = database.values.where((g) => g.type == 'Wii').length;
    final gcGames = database.values.where((g) => g.type == 'GameCube').length;
    final genres = database.values
        .where((g) => g.genre != null)
        .map((g) => g.genre!)
        .toSet()
        .length;

    return {
      'total': database.length,
      'wii': wiiGames,
      'gamecube': gcGames,
      'genres': genres,
      'lastUpdate': _lastUpdate,
    };
  }
}

/// Game metadata from WiiTDB
class GameMetadata {
  final String id;
  final String? type; // 'Wii' or 'GameCube'
  final Map<String, LocaleData> locales;
  final String? developer;
  final String? publisher;
  final String? releaseYear;
  final String? releaseMonth;
  final String? releaseDay;
  final String? genre;
  final String? ratingType; // ESRB, PEGI, etc.
  final String? ratingValue; // E, T, M, etc.
  final String? players; // "1-4"
  final String? wifiPlayers;
  final List<String> wifiFeatures;
  final List<RomInfo> roms;

  GameMetadata({
    required this.id,
    required this.locales,
    this.type,
    this.developer,
    this.publisher,
    this.releaseYear,
    this.releaseMonth,
    this.releaseDay,
    this.genre,
    this.ratingType,
    this.ratingValue,
    this.players,
    this.wifiPlayers,
    this.wifiFeatures = const [],
    this.roms = const [],
  });

  String get title =>
      locales['EN']?.title ?? locales.values.firstOrNull?.title ?? 'Unknown';
  String? get synopsis =>
      locales['EN']?.synopsis ?? locales.values.firstOrNull?.synopsis;

  String get releaseDate {
    if (releaseYear == null) return 'Unknown';
    if (releaseMonth == null) return releaseYear!;
    if (releaseDay == null) return '$releaseMonth/$releaseYear';
    return '$releaseMonth/$releaseDay/$releaseYear';
  }

  String get displayGenre => genre ?? 'Unknown';
  String get displayDeveloper => developer ?? 'Unknown';
  String get displayPublisher => publisher ?? developer ?? 'Unknown';
  String get displayPlayers => players ?? '1';

  bool get hasMultiplayer => players != null && !players!.startsWith('1');
  bool get hasOnline => wifiPlayers != null && wifiPlayers != '0';
}

/// Locale-specific game data
class LocaleData {
  final String title;
  final String? synopsis;

  LocaleData({
    required this.title,
    this.synopsis,
  });
}

/// ROM checksum information
class RomInfo {
  final String name;
  final int? size;
  final String? crc32;
  final String? md5;
  final String? sha1;

  RomInfo({
    required this.name,
    this.size,
    this.crc32,
    this.md5,
    this.sha1,
  });
}
