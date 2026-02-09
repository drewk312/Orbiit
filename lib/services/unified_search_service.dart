// ═══════════════════════════════════════════════════════════════════════════
// UNIFIED SEARCH SERVICE
// WiiGC-Fusion - Federated ROM search across multiple sources
// ═══════════════════════════════════════════════════════════════════════════
//
// This service provides a "Google for ROMs" experience by:
//   • Searching multiple sources simultaneously (parallel execution)
//   • Intelligently prioritizing results by format quality
//   • De-duplicating results across sources
//   • Providing fallback when sources are unavailable
//
// Search Priority (Best to Acceptable):
//   1. Myrient RVZ     - Best quality, smallest size, Dolphin-native
//   2. Myrient Other   - Good quality, various formats
//   3. Vimm's Lair     - Reliable, verified hashes
//   4. Archive.org     - Large collection, variable quality
//
// Architecture:
//   ┌────────────────────────────────────────────────────────────────────┐
//   │  UnifiedSearchService (Singleton)                                 │
//   │  ├── searchAll() → Parallel search across all providers           │
//   │  ├── _searchMyrient() → With error isolation                      │
//   │  ├── _searchVimm() → With error isolation                         │
//   │  └── _searchArchiveOrg() → With error isolation                   │
//   │                                                                   │
//   │  Results: Prioritized → Deduplicated → Returned                   │
//   └────────────────────────────────────────────────────────────────────┘
//
// Usage:
//   final service = UnifiedSearchService();
//   final results = await service.searchAll('Mario Galaxy', platform: 'Wii');
//
//   for (final game in results) {
//     print('${game.title} from ${game.provider}');
//   }
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import '../models/game_result.dart';
import 'myrient_service.dart';
import 'vimm_service.dart';
import '../core/app_logger.dart';
import 'archive_org_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Search service configuration
abstract class _Config {
  /// Timeout for individual provider searches
  static const Duration searchTimeout = Duration(seconds: 15);

  /// Minimum query length to perform search
  static const int minQueryLength = 2;

  /// Maximum results to return per provider
  static const int maxResultsPerProvider = 50;

  /// Enable debug logging
  static const bool debugLogging = true;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UNIFIED SEARCH SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Federated ROM search service that queries multiple providers simultaneously.
///
/// This singleton service provides unified search across:
/// - **Myrient**: High-quality RVZ/NKit formats
/// - **Vimm's Lair**: Verified ROMs with hash validation
/// - **Archive.org**: Large collection of preserved games
///
/// Results are automatically prioritized by format quality and deduplicated.
///
/// Example:
/// ```dart
/// final service = UnifiedSearchService();
///
/// // Search all sources
/// final results = await service.searchAll('zelda');
///
/// // Get best source for a specific game
/// final sources = await service.getSourcesForGame('Zelda Twilight Princess', 'Wii');
/// ```
class UnifiedSearchService {
  // ─────────────────────────────────────────────────────────────────────────
  // Singleton Pattern
  // ─────────────────────────────────────────────────────────────────────────

  static final UnifiedSearchService _instance =
      UnifiedSearchService._internal();

  /// Get the singleton instance
  factory UnifiedSearchService() => _instance;

  UnifiedSearchService._internal();

  // ─────────────────────────────────────────────────────────────────────────
  // Service Instances
  // ─────────────────────────────────────────────────────────────────────────

  final MyrientService _myrient = MyrientService();
  final VimmService _vimm = VimmService();
  final ArchiveOrgService _archive = ArchiveOrgService();

  // ─────────────────────────────────────────────────────────────────────────
  // Search Statistics
  // ─────────────────────────────────────────────────────────────────────────

  /// Last search timing by provider
  final Map<String, Duration> _lastSearchTiming = {};

  /// Get search timing for analysis
  Map<String, Duration> get searchTiming => Map.unmodifiable(_lastSearchTiming);

  // ─────────────────────────────────────────────────────────────────────────
  // Main Search API
  // ─────────────────────────────────────────────────────────────────────────

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialize search services (pre-cache Myrient)
  Future<void> initialize({Function(String, double)? onProgress}) async {
    _log('[Unified] Initializing search services...');
    try {
      await _myrient.initializeCache();
      _log('[Unified] Initialization complete');
    } catch (e) {
      _log('[Unified] Initialization error: $e');
    }
  }

  /// Refresh Myrient cache
  Future<void> refreshCache() async {
    _log('[Unified] Refreshing cache...');
    try {
      await _myrient.refreshCache();
      _log('[Unified] Cache refresh complete');
    } catch (e) {
      _log('[Unified] Cache refresh error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH
  // ──────────────────────────────────────────────────────────────────────────

  /// Search all ROM sources simultaneously.
  ///
  /// Returns results prioritized by format quality:
  /// 1. Myrient RVZ (best compression, Dolphin native)
  /// 2. Myrient other formats
  /// 3. Vimm's Lair
  /// 4. Archive.org
  ///
  /// Parameters:
  /// - [query]: Search query (title, game ID, or keyword)
  /// - [platform]: Optional platform filter ('Wii' or 'GameCube')
  ///
  /// Returns an empty list if query is too short or all providers fail.
  Future<List<GameResult>> searchAll(String query, {String? platform}) async {
    // ── Validate Input ──
    final cleanQuery = query.trim();
    if (cleanQuery.length < _Config.minQueryLength) {
      _log('Query too short: "$cleanQuery"');
      return [];
    }

    _log(
        'Starting unified search for: "$cleanQuery" (platform: ${platform ?? "all"})');

    final stopwatch = Stopwatch()..start();
    final results = <GameResult>[];

    // ── Launch Parallel Searches ──
    final futures = <String, Future<List<GameResult>>>{
      'Myrient': _searchMyrient(cleanQuery, platform),
      'Vimm': _searchVimm(cleanQuery, platform),
      'Archive.org': _searchArchiveOrg(cleanQuery, platform),
    };

    // ── Await All Results ──
    final searchResults = await Future.wait(
      futures.entries.map((entry) async {
        final providerStopwatch = Stopwatch()..start();
        final result = await entry.value;
        providerStopwatch.stop();
        _lastSearchTiming[entry.key] = providerStopwatch.elapsed;
        return MapEntry(entry.key, result);
      }),
    );

    final allResults = Map.fromEntries(searchResults);

    // ── Priority 1: Myrient RVZ (Best Quality) ──
    final myrientResults = allResults['Myrient'] ?? [];
    final rvzResults = myrientResults.where((r) =>
        r.provider.toUpperCase().contains('RVZ') ||
        (r.downloadUrl?.toLowerCase().contains('.rvz') ?? false));
    results.addAll(rvzResults);
    _log('  Myrient RVZ: ${rvzResults.length} results');

    // ── Priority 2: Myrient Other Formats ──
    final otherMyrient = myrientResults.where((r) =>
        !r.provider.toUpperCase().contains('RVZ') &&
        !(r.downloadUrl?.toLowerCase().contains('.rvz') ?? false));
    results.addAll(otherMyrient);
    _log('  Myrient Other: ${otherMyrient.length} results');

    // ── Priority 3: Vimm's Lair (Reliable) ──
    final vimmResults = allResults['Vimm'] ?? [];
    results.addAll(vimmResults);
    _log('  Vimm: ${vimmResults.length} results');

    // ── Priority 4: Archive.org (Large Collection) ──
    final archiveResults = allResults['Archive.org'] ?? [];
    results.addAll(archiveResults);
    _log('  Archive.org: ${archiveResults.length} results');

    // ── Deduplicate Results ──
    final uniqueResults = _deduplicateResults(results);

    stopwatch.stop();
    _log(
        'Search complete: ${uniqueResults.length} unique results in ${stopwatch.elapsedMilliseconds}ms');

    return uniqueResults;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Provider-Specific Search Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Search Myrient with instant cache (< 500ms) or HTTP fallback
  Future<List<GameResult>> _searchMyrient(
      String query, String? platform) async {
    try {
      // Use cached search for instant results
      return await _myrient
          .searchCached(query, platform: platform)
          .timeout(_Config.searchTimeout);
    } on TimeoutException {
      _log('[Myrient] Search timed out');
      return [];
    } catch (e) {
      _log('[Myrient] Search error: $e');
      return [];
    }
  }

  /// Search Vimm's Lair with error isolation
  Future<List<GameResult>> _searchVimm(String query, String? platform) async {
    try {
      return await _vimm
          .search(query, platform: platform)
          .timeout(_Config.searchTimeout);
    } on TimeoutException {
      _log('[Vimm] Search timed out');
      return [];
    } catch (e) {
      _log('[Vimm] Search error: $e');
      return [];
    }
  }

  /// Search Archive.org with error isolation
  Future<List<GameResult>> _searchArchiveOrg(
      String query, String? platform) async {
    try {
      final results = await _archive.search(query);
      if (platform != null) {
        return results
            .where((r) => r.platform.toLowerCase() == platform.toLowerCase())
            .toList();
      }
      return results;
    } on TimeoutException {
      _log('[Archive.org] Search timed out');
      return [];
    } catch (e) {
      _log('[Archive.org] Search error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Result Analysis
  // ─────────────────────────────────────────────────────────────────────────

  /// Get recommended source for a game based on quality/reliability.
  ///
  /// Returns a human-readable recommendation string.
  String getRecommendedSource(List<GameResult> results) {
    if (results.isEmpty) return 'No sources available';

    // Prefer RVZ format (best for Dolphin)
    final hasRvz = results.any((r) =>
        r.provider.toUpperCase().contains('RVZ') ||
        (r.downloadUrl?.toLowerCase().contains('.rvz') ?? false));
    if (hasRvz) return '⭐ Myrient RVZ (Best Quality)';

    // Then Myrient other formats
    final hasMyrient = results.any((r) => r.provider.contains('Myrient'));
    if (hasMyrient) return '✓ Myrient (Good Quality)';

    // Then Vimm (most reliable)
    final hasVimm = results.any((r) => r.provider.contains('Vimm'));
    if (hasVimm) return '✓ Vimm\'s Lair (Verified)';

    // Then Archive.org
    final hasArchive = results.any((r) => r.provider.contains('Archive'));
    if (hasArchive) return 'Archive.org (Large Collection)';

    return results.first.provider;
  }

  /// Get format quality rating (1-5 stars).
  int getFormatRating(GameResult result) {
    final url = result.downloadUrl?.toLowerCase() ?? '';
    final provider = result.provider.toLowerCase();

    if (url.contains('.rvz') || provider.contains('rvz')) return 5;
    if (url.contains('.nkit')) return 4;
    if (url.contains('.wbfs')) return 3;
    if (url.contains('.iso')) return 3;
    if (url.contains('.wad')) return 3;
    if (url.contains('.7z') || url.contains('.zip')) return 2;
    return 1;
  }

  /// Get all available sources for a specific game title.
  ///
  /// Returns a map of provider name to best matching GameResult.
  Future<Map<String, GameResult>> getSourcesForGame(
    String title,
    String platform,
  ) async {
    final results = await searchAll(title, platform: platform);
    final sources = <String, GameResult>{};
    final normalizedTitle = title.toLowerCase();

    for (final result in results) {
      // Match by title similarity
      if (result.title.toLowerCase().contains(normalizedTitle) ||
          normalizedTitle.contains(result.title.toLowerCase())) {
        // Keep best result per provider
        final existingRating = sources[result.provider] != null
            ? getFormatRating(sources[result.provider]!)
            : 0;
        final newRating = getFormatRating(result);

        if (newRating > existingRating) {
          sources[result.provider] = result;
        }
      }
    }

    return sources;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Service Health
  // ─────────────────────────────────────────────────────────────────────────

  /// Check availability of all search services.
  ///
  /// Performs lightweight checks to determine service status.
  Future<Map<String, ServiceStatus>> checkServiceStatus() async {
    final results = <String, ServiceStatus>{};

    // Check each service with timeout
    final checks = await Future.wait([
      _checkService('Myrient', () => _myrient.search('test')),
      _checkService('Vimm', () => _vimm.search('test')),
      _checkService('Archive.org', () => _searchArchiveOrg('test', null)),
    ]);

    for (final check in checks) {
      results[check.name] = check;
    }

    return results;
  }

  Future<ServiceStatus> _checkService(
    String name,
    Future<List<GameResult>> Function() check,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      await check().timeout(const Duration(seconds: 5));
      stopwatch.stop();
      return ServiceStatus(
        name: name,
        isAvailable: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ServiceStatus(
        name: name,
        isAvailable: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Remove duplicate results based on title + platform combination.
  List<GameResult> _deduplicateResults(List<GameResult> results) {
    final seen = <String>{};
    return results.where((game) {
      // Create unique key from normalized title and platform
      final normalizedTitle = game.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final key = '${normalizedTitle}_${game.platform.toLowerCase()}';

      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Log debug messages
  void _log(String message) {
    if (_Config.debugLogging) {
      AppLogger.instance.debug('[UnifiedSearch] $message');
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SERVICE STATUS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Represents the health status of a search provider.
class ServiceStatus {
  /// Provider name
  final String name;

  /// Whether the service is currently available
  final bool isAvailable;

  /// Response latency in milliseconds
  final int latencyMs;

  /// Error message if unavailable
  final String? error;

  const ServiceStatus({
    required this.name,
    required this.isAvailable,
    required this.latencyMs,
    this.error,
  });

  /// Human-readable status
  String get statusText => isAvailable
      ? '✓ Online (${latencyMs}ms)'
      : '✗ Offline${error != null ? ": $error" : ""}';

  @override
  String toString() => 'ServiceStatus($name: $statusText)';
}
