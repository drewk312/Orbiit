import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'scanner_service.dart';
import '../core/app_logger.dart';

/// Library State Service - Persists library data across screen switches
class LibraryStateService {
  static final LibraryStateService _instance = LibraryStateService._internal();
  factory LibraryStateService() => _instance;
  LibraryStateService._internal();

  // In-memory cache
  List<ScannedGame> _games = [];
  String? _lastScannedPath;
  bool _hasLoaded = false;

  // Getters
  List<ScannedGame> get games => _games;
  String? get lastScannedPath => _lastScannedPath;
  bool get hasGames => _games.isNotEmpty;
  int get gameCount => _games.length;
  int get verifiedCount => _games.where((g) => g.verified).length;

  /// Update library with scanned games
  void updateLibrary(List<ScannedGame> games, String path) {
    // Deduplicate games by gameId - keep first occurrence
    final seen = <String>{};
    final uniqueGames = <ScannedGame>[];

    for (final game in games) {
      final id = game.gameId;
      if (id != null && id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        uniqueGames.add(game);
      } else if (id == null || id.isEmpty) {
        // Keep games without IDs (edge case)
        uniqueGames.add(game);
      }
    }

    _games = uniqueGames;
    _lastScannedPath = path;
    _saveToCache();
  }

  /// Clear library
  void clearLibrary() {
    _games = [];
    _lastScannedPath = null;
    _saveToCache();
  }

  /// Get average health
  double get averageHealth {
    if (_games.isEmpty) return 0;
    return _games.map((g) => g.health).reduce((a, b) => a + b) / _games.length;
  }

  /// Load from local cache file
  Future<void> loadFromCache() async {
    if (_hasLoaded) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/wiigc_fusion_library.json');

      if (await cacheFile.exists()) {
        final jsonStr = await cacheFile.readAsString();
        
        // Use isolate for JSON parsing
        final data = await compute(_parseLibraryData, jsonStr);

        _lastScannedPath = data['lastPath'] as String?;
        final gamesList = data['games'] as List;

        _games = gamesList.map((g) => ScannedGame.fromMap(g)).toList();
      }
    } catch (e) {
      AppLogger.instance.error('[LibraryState] Error loading cache: $e');
    }

    _hasLoaded = true;
  }

  /// Save to local cache file
  Future<void> _saveToCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/wiigc_fusion_library.json');

      // Prepare data map
      final data = {
        'lastPath': _lastScannedPath,
        'games': _games.map((g) => g.toMap()).toList(),
      };

      // Use isolate for JSON encoding
      final jsonStr = await compute(_encodeLibraryData, data);
      await cacheFile.writeAsString(jsonStr);
    } catch (e) {
      AppLogger.instance.error('[LibraryState] Error saving cache: $e');
    }
  }
}

// ── Isolate Functions ──

/// Parse JSON in background isolate
Map<String, dynamic> _parseLibraryData(String jsonStr) {
  return json.decode(jsonStr) as Map<String, dynamic>;
}

/// Encode JSON in background isolate
String _encodeLibraryData(Map<String, dynamic> data) {
  return json.encode(data);
}
