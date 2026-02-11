import 'package:flutter/foundation.dart';
import 'myrient_cache.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MYRIENT SEARCH INDEX - INSTANT GAME LOOKUPS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// In-memory search index for ultra-fast game discovery without HTML parsing.
/// Features:
/// - Trigram-based fuzzy search for typo tolerance
/// - Normalized title matching
/// - O(1) platform filtering
/// - < 100ms search performance
///
/// ═══════════════════════════════════════════════════════════════════════════

class MyrientSearchIndex {
  // Exact title matching (normalized)
  final Map<String, List<MyrientGameEntry>> _exactIndex = {};

  // Trigram fuzzy matching
  final Map<String, Set<String>> _trigramIndex = {};

  // Platform-specific lookup
  final Map<String, List<MyrientGameEntry>> _platformIndex = {};

  // All games (for fallback)
  final List<MyrientGameEntry> _allGames = [];

  int get totalGames => _allGames.length;
  bool get isEmpty => _allGames.isEmpty;

  /// Build index from cached game entries
  void buildFromCache(Map<String, List<MyrientGameEntry>> cachedSources) {
    final startTime = DateTime.now();

    _exactIndex.clear();
    _trigramIndex.clear();
    _platformIndex.clear();
    _allGames.clear();

    int totalGames = 0;

    for (final entry in cachedSources.entries) {
      final games = entry.value;

      for (final game in games) {
        _allGames.add(game);
        totalGames++;

        // Add to exact index
        final normalizedTitle = _normalizeTitle(game.title);
        _exactIndex.putIfAbsent(normalizedTitle, () => []).add(game);

        // Add to trigram index
        final trigrams = _generateTrigrams(normalizedTitle);
        for (final trigram in trigrams) {
          _trigramIndex.putIfAbsent(trigram, () => {}).add(normalizedTitle);
        }

        // Add to platform index
        final platformKey = game.platform.toLowerCase();
        _platformIndex.putIfAbsent(platformKey, () => []).add(game);
      }
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('[MyrientIndex] Built index: $totalGames games in ${elapsed}ms');
  }

  /// Search for games with instant lookup
  List<MyrientGameEntry> search(String query,
      {String? platform, int maxResults = 100}) {
    if (query.isEmpty) return [];

    final normalizedQuery = _normalizeTitle(query);
    final queryTokens =
        normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();

    if (queryTokens.isEmpty) return [];

    // Step 1: Exact match lookup
    List<MyrientGameEntry> results = [];

    // Check for exact title match
    if (_exactIndex.containsKey(normalizedQuery)) {
      results.addAll(_exactIndex[normalizedQuery]!);
    }

    // Step 2: Token-based matching
    final candidateTitles = <String>{};

    for (final token in queryTokens) {
      // Find titles containing this token
      for (final title in _exactIndex.keys) {
        if (title.contains(token)) {
          candidateTitles.add(title);
        }
      }
    }

    // Add games from candidate titles
    for (final title in candidateTitles) {
      if (_exactIndex.containsKey(title)) {
        results.addAll(_exactIndex[title]!);
      }
    }

    // Step 3: Fuzzy matching with trigrams (if few results)
    if (results.length < 10) {
      final fuzzyMatches = _fuzzySearch(normalizedQuery);
      for (final title in fuzzyMatches) {
        if (_exactIndex.containsKey(title)) {
          results.addAll(_exactIndex[title]!);
        }
      }
    }

    // Step 4: Platform filtering
    if (platform != null && platform.toLowerCase() != 'all') {
      final platformLower = platform.toLowerCase();
      results = results.where((game) {
        final gamePlatform = game.platform.toLowerCase();
        return gamePlatform == platformLower ||
            gamePlatform.contains(platformLower) ||
            platformLower.contains(gamePlatform);
      }).toList();
    }

    // Step 5: Remove duplicates and rank
    final seen = <String>{};
    final uniqueResults = <MyrientGameEntry>[];

    for (final game in results) {
      final key = '${game.title}_${game.platform}_${game.url}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueResults.add(game);
      }
    }

    // Rank by relevance
    uniqueResults.sort((a, b) {
      final aTitle = _normalizeTitle(a.title);
      final bTitle = _normalizeTitle(b.title);

      // Exact match first
      if (aTitle == normalizedQuery && bTitle != normalizedQuery) return -1;
      if (bTitle == normalizedQuery && aTitle != normalizedQuery) return 1;

      // Starts with query
      if (aTitle.startsWith(normalizedQuery) &&
          !bTitle.startsWith(normalizedQuery)) {
        return -1;
      }
      if (bTitle.startsWith(normalizedQuery) &&
          !aTitle.startsWith(normalizedQuery)) {
        return 1;
      }

      // More query tokens matched
      final aMatches = queryTokens.where((t) => aTitle.contains(t)).length;
      final bMatches = queryTokens.where((t) => bTitle.contains(t)).length;
      if (aMatches != bMatches) return bMatches.compareTo(aMatches);

      // Shorter title (more specific)
      return aTitle.length.compareTo(bTitle.length);
    });

    return uniqueResults.take(maxResults).toList();
  }

  /// Fuzzy search using trigram matching
  List<String> _fuzzySearch(String query, {int maxCandidates = 20}) {
    final queryTrigrams = _generateTrigrams(query);
    if (queryTrigrams.isEmpty) return [];

    // Find titles that share trigrams with query
    final titleScores = <String, int>{};

    for (final trigram in queryTrigrams) {
      if (_trigramIndex.containsKey(trigram)) {
        for (final title in _trigramIndex[trigram]!) {
          titleScores[title] = (titleScores[title] ?? 0) + 1;
        }
      }
    }

    // Sort by number of matching trigrams
    final sortedTitles = titleScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTitles.take(maxCandidates).map((e) => e.key).toList();
  }

  /// Get games by platform
  List<MyrientGameEntry> getByPlatform(String platform) {
    final platformKey = platform.toLowerCase();
    return _platformIndex[platformKey] ?? [];
  }

  /// Normalize title for consistent matching
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Generate trigrams for fuzzy matching
  Set<String> _generateTrigrams(String text) {
    if (text.length < 3) return {};

    final trigrams = <String>{};
    for (int i = 0; i <= text.length - 3; i++) {
      trigrams.add(text.substring(i, i + 3));
    }
    return trigrams;
  }

  /// Clear the entire index
  void clear() {
    _exactIndex.clear();
    _trigramIndex.clear();
    _platformIndex.clear();
    _allGames.clear();
    debugPrint('[MyrientIndex] Cleared index');
  }

  /// Get index statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalGames': _allGames.length,
      'uniqueTitles': _exactIndex.length,
      'platforms': _platformIndex.length,
      'trigrams': _trigramIndex.length,
    };
  }

  /// Get popular games (most likely to be searched)
  List<MyrientGameEntry> getPopularGames({int limit = 50}) {
    // Return first N games (could be improved with actual popularity metrics)
    return _allGames.take(limit).toList();
  }
}
