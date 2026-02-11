import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';

import '../ffi/forge_bridge.dart';
import '../models/game_result.dart';
import '../services/archive_org_service.dart';
import '../services/archive_service.dart';
import '../services/cover_art/cover_art_service.dart';
import '../services/cover_art/cover_art_source.dart';
import '../services/download_service.dart';
import '../services/gamebrew_service.dart';
import '../services/library_state_service.dart';
import '../services/scanner_service.dart';
import '../services/smart_search_service.dart';
import '../services/unified_search_service.dart';
// import 'package:archive/archive.dart';
import '../services/vimm_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  List<GameResult> _results = [];
  List<GameResult> _popularGames = [];
  List<GameResult> _latestGames = [];
  List<GameResult> _randomGames = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _loadingMessage; // e.g., "Loading sources...", "Fetching covers..."
  String? _error;

  final CoverArtService _coverArtService = CoverArtService();
  final VimmService _vimm = VimmService();
  final SmartSearchService _smartSearch = SmartSearchService();
  final UnifiedSearchService _unifiedSearch = UnifiedSearchService();
  final GameBrewService _gameBrewService = GameBrewService();
  final ArchiveService _archive = ArchiveService();
  final DownloadService _download = DownloadService();
  final LibraryStateService _library = LibraryStateService();
  final ScannerService _scanner = ScannerService();

  // Track cached cover paths by gameId
  final Map<String, String?> _coverPaths = {};

  /// Get cached cover path for a game
  String? getCoverPath(String? gameId) =>
      gameId != null ? _coverPaths[gameId] : null;

  /// Get cached cover path for a game (by title - fallback)
  String? getCoverPathByTitle(String title) {
    for (final game in [..._popularGames, ..._latestGames, ..._randomGames]) {
      if (game.title == title && game.gameId != null) {
        return _coverPaths[game.gameId];
      }
    }
    return null;
  }

  // Track download state per game: 'idle', 'downloading', 'unzipping', 'ready', 'error'
  final Map<String, String> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};

  String getDownloadStatus(String gameTitle) =>
      _downloadStatus[gameTitle] ?? 'idle';
  double getDownloadProgress(String gameTitle) =>
      _downloadProgress[gameTitle] ?? 0.0;

  List<GameResult> get results => _results;
  List<GameResult> get popularGames => _popularGames;
  List<GameResult> get latestGames => _latestGames;
  List<GameResult> get randomGames => _randomGames;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  LibraryStateService get library => _library;

  // Loading state
  final bool _isLoading = false;
  // isLoading should be true if we are explicitly loading OR if we have a loading message active
  bool get isLoading => _isLoading || _loadingMessage != null;
  String? get loadingMessage => _loadingMessage;

  List<String> _lastDiagnostics = [];
  List<String> get lastDiagnostics => _lastDiagnostics;

  void clearSearch() {
    _isSearching = false;
    _searchQuery = '';
    _results = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadStoreSections() async {
    debugPrint('[Discovery] Loading store sections...');

    try {
      final romHacks = await _gameBrewService.fetchHomebrew();

      // Popular titles from all categories
      _popularGames = [
        ..._getPopularTitles(), // Wii
        ..._getPopularGameCubeTitles(),
        ..._getPopularWiiUTitles(), // Wii U
        ..._getPopularRetroTitles(),
        ...romHacks,
      ];

      // Latest releases (simulated for now)
      _latestGames = [
        ..._getLatestTitles(),
        ..._getPopularGameCubeTitles().take(4), // Mix in some GC
        ..._getPopularWiiUTitles().take(4), // Mix in some Wii U
      ];

      // Random picks
      _randomGames = List.from(_popularGames)..shuffle();

      // === WAIT FOR ALL COVERS TO LOAD (NO PLACEHOLDERS!) ===
      debugPrint('[Discovery] Loading covers for store sections...');
      try {
        await _fetchCoversForGames([
          ..._popularGames,
          ..._latestGames,
          ..._randomGames,
        ]);
        debugPrint('[Discovery] All store covers loaded');
      } catch (e) {
        debugPrint('[Discovery] Cover fetch error (continuing): $e');
      }

      notifyListeners();

      // ⚡ Initialize Unified Search Cache (Background)
      _unifiedSearch.initialize(onProgress: (stage, progress) {
        // Optional: Update loading status if we want to show a progress bar
        debugPrint(
            '[Discovery] Cache Init: $stage ${(progress * 100).toInt()}%');
      });
    } catch (e) {
      debugPrint('[Discovery] Error loading store sections: $e');
    }
  }

  /// Manually refresh the catalog cache
  Future<void> refreshCatalog() async {
    _loadingMessage = 'Refreshing catalog...';
    notifyListeners();
    try {
      await _unifiedSearch.refreshCache();
      // Reload store sections to reflect new data
      await loadStoreSections();
    } finally {
      _loadingMessage = null;
      notifyListeners();
    }
  }

  /// Fetch covers for all games in background (non-blocking)
  Future<void> _fetchCoversForGames(List<GameResult> games) async {
    // Deduplicate by gameId (more reliable than title)
    final uniqueGames = <String, GameResult>{};
    for (final game in games) {
      if (game.gameId != null && game.gameId!.isNotEmpty) {
        uniqueGames[game.gameId!] = game;
      }
    }

    debugPrint(
        '[Discovery] Fetching covers for ${uniqueGames.length} games...');

    // Fetch covers in parallel batches of 5 for better reliability
    final gameList = uniqueGames.values.toList();
    const batchSize = 5;

    for (int i = 0; i < gameList.length; i += batchSize) {
      final batch = gameList.skip(i).take(batchSize).toList();

      await Future.wait(
        batch.map((game) => _fetchCoverForGame(game)),
      );

      // Small delay between batches to be nice to servers
      if (i + batchSize < gameList.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    debugPrint('[Discovery] Cover fetching complete');
  }

  /// Fetch cover for a single game
  Future<void> _fetchCoverForGame(GameResult game) async {
    // Skip if no gameId
    if (game.gameId == null || game.gameId!.isEmpty) return;

    // Skip if already cached in memory
    if (_coverPaths.containsKey(game.gameId) &&
        _coverPaths[game.gameId] != null) {
      return;
    }

    try {
      // Normalize platform string
      final GamePlatform platform = _parsePlatform(game.platform);

      // Use the enhanced service to get/download cover
      final coverPath = await _coverArtService.getCoverArt(
        gameTitle: game.title,
        platform: platform,
        gameId: game.gameId,
      );

      if (coverPath != null) {
        _coverPaths[game.gameId!] = coverPath;
        // debugPrint('[Discovery] ✓ Cover cached: ${game.title} (${game.gameId})');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Discovery] Failed to fetch cover for ${game.title}: $e');
    }
  }

  // ... (Existing _getPopularTitles / _getLatestTitles checked below, adding new methods)

  List<GameResult> _getPopularTitles() {
    return [
      // === WII GAMES (Archive.org - Fast & Reliable ISO) ===
      const GameResult(
        title: 'Super Mario Galaxy',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Super%20Mario%20Galaxy%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.4 GB',
        gameId: 'RMGE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RMGE01.png',
      ),
      const GameResult(
        title: 'Super Mario Galaxy 2',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Super%20Mario%20Galaxy%202%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.1 GB',
        gameId: 'SB4E01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SB4E01.png',
      ),
      const GameResult(
        title: 'Super Smash Bros. Brawl',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Super%20Smash%20Bros.%20Brawl%20%28USA%29%20%28En%2CFr%2CEs%29%20%28Rev%202%29.iso',
        size: '7.4 GB',
        gameId: 'RSBE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RSBE01.png',
      ),
      const GameResult(
        title: 'Mario Kart Wii',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Mario%20Kart%20Wii%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.1 GB',
        gameId: 'RMCE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RMCE01.png',
      ),
      const GameResult(
        title: 'New Super Mario Bros. Wii',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/New%20Super%20Mario%20Bros.%20Wii%20%28USA%29%20%28En%2CFr%2CEs%29%20%28Rev%202%29.iso',
        size: '4.4 GB',
        gameId: 'SMNE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SMNE01.png',
      ),
      const GameResult(
        title: 'Animal Crossing: City Folk',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Animal%20Crossing%20-%20City%20Folk%20%28USA%2C%20Asia%29%20%28En%2CFr%2CEs%29%20%28Rev%201%29.iso',
        size: '4.4 GB',
        gameId: 'RUUE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RUUE01.png',
      ),
      const GameResult(
        title: 'Xenoblade Chronicles',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Xenoblade%20Chronicles%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '7.4 GB',
        gameId: 'SX4E01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SX4E01.png',
      ),
      const GameResult(
        title: 'Metroid Prime Trilogy',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Metroid%20Prime%20Trilogy%20%28USA%29.iso',
        size: '7.9 GB',
        gameId: 'R3ME01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/R3ME01.png',
      ),
    ];
  }

  List<GameResult> _getPopularGameCubeTitles() {
    return [
      const GameResult(
        title: 'Super Smash Bros. Melee',
        platform: 'GameCube',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/',
        downloadUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/Super%20Smash%20Bros.%20Melee%20%28USA%29%20%28En%2CJa%29%20%28Rev%202%29.iso',
        size: '1.4 GB',
        gameId: 'GALE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/GALE01.png',
      ),
      const GameResult(
        title: 'Super Mario Sunshine',
        platform: 'GameCube',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/',
        downloadUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/Super%20Mario%20Sunshine%20%28USA%29.iso',
        size: '1.4 GB',
        gameId: 'GMSE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/GMSE01.png',
      ),
      const GameResult(
        title: 'Mario Kart: Double Dash!!',
        platform: 'GameCube',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/',
        downloadUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/Mario%20Kart%20-%20Double%20Dash%21%21%20%28USA%29.iso',
        size: '1.4 GB',
        gameId: 'GM4E01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/GM4E01.png',
      ),
      const GameResult(
        title: 'Luigi\'s Mansion',
        platform: 'GameCube',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/',
        downloadUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/Luigi%27s%20Mansion%20%28USA%29.iso',
        size: '1.1 GB',
        gameId: 'GLME01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/GLME01.png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: The Wind Waker',
        platform: 'GameCube',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/',
        downloadUrl:
            'https://archive.org/download/nIntendo-gamecube-iso-usa-redump.org-2019-10-23/Legend%20of%20Zelda%2C%20The%20-%20The%20Wind%20Waker%20%28USA%29.iso',
        size: '1.4 GB',
        gameId: 'GZLE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/GZLE01.png',
      ),
    ];
  }

  List<GameResult> _getPopularWiiUTitles() {
    return [
      // === WII U GAMES ===
      const GameResult(
        title: 'The Legend of Zelda: Breath of the Wild',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Legend%20of%20Zelda%2C%20The%20-%20Breath%20of%20the%20Wild%20%28USA%29.wux',
        size: '12 GB',
        gameId: 'ALZE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/ALZE01.png',
      ),
      const GameResult(
        title: 'Super Mario 3D World',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Super%20Mario%203D%20World%20%28USA%29.wux',
        size: '5.5 GB',
        gameId: 'ARDE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/ARDE01.png',
      ),
      const GameResult(
        title: 'Mario Kart 8',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Mario%20Kart%208%20%28USA%29.wux',
        size: '7.5 GB',
        gameId: 'AMKE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AMKE01.png',
      ),
      const GameResult(
        title: 'Super Smash Bros. for Wii U',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Super%20Smash%20Bros.%20for%20Wii%20U%20%28USA%29.wux',
        size: '15 GB',
        gameId: 'AXFE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AXFE01.png',
      ),
      const GameResult(
        title: 'Splatoon',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Splatoon%20%28USA%29.wux',
        size: '5 GB',
        gameId: 'AGME01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AGME01.png',
      ),
      const GameResult(
        title: 'Bayonetta 2',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Bayonetta%202%20%28USA%29.wux',
        size: '14 GB',
        gameId: 'AQUE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AQUE01.png',
      ),
      const GameResult(
        title: 'Donkey Kong Country: Tropical Freeze',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Donkey%20Kong%20Country%20-%20Tropical%20Freeze%20%28USA%29.wux',
        size: '11 GB',
        gameId: 'ARKJ01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/ARKJ01.png',
      ),
      const GameResult(
        title: 'Pikmin 3',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Pikmin%203%20%28USA%29.wux',
        size: '7 GB',
        gameId: 'AC3E01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AC3E01.png',
      ),
      const GameResult(
        title: 'New Super Mario Bros. U',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/New%20Super%20Mario%20Bros.%20U%20%28USA%29.wux',
        size: '2 GB',
        gameId: 'ARPE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/ARPE01.png',
      ),
      const GameResult(
        title: 'Xenoblade Chronicles X',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Xenoblade%20Chronicles%20X%20%28USA%29.wux',
        size: '22 GB',
        gameId: 'AX5E01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AX5E01.png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: Twilight Princess HD',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Legend%20of%20Zelda%2C%20The%20-%20Twilight%20Princess%20HD%20%28USA%29.wux',
        size: '8 GB',
        gameId: 'AZAE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/AZAE01.png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: The Wind Waker HD',
        platform: 'Wii U',
        region: 'USA',
        provider: 'Myrient',
        pageUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/',
        downloadUrl:
            'https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20U%20-%20WUX/Legend%20of%20Zelda%2C%20The%20-%20The%20Wind%20Waker%20HD%20%28USA%29.wux',
        size: '6 GB',
        gameId: 'BCZE01',
        coverUrl: 'https://art.gametdb.com/wiiu/cover3D/US/BCZE01.png',
      ),
    ];
  }

  List<GameResult> _getPopularRetroTitles() {
    return [
      // === N64 ===
      const GameResult(
        title: 'Super Mario 64',
        platform: 'N64',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29%20%282016-01-03%29.zip/Super%20Mario%2064%20%28USA%29.z64',
        size: '8 MB',
        gameId: 'NSME',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%2064/Named_Boxarts/Super%20Mario%2064%20(USA).png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: Ocarina of Time',
        platform: 'N64',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29%20%282016-01-03%29.zip/Legend%20of%20Zelda%2C%20The%20-%20Ocarina%20of%20Time%20%28USA%29%20%28Rev%202%29.z64',
        size: '32 MB',
        gameId: 'NZLE',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%2064/Named_Boxarts/Legend%20of%20Zelda,%20The%20-%20Ocarina%20of%20Time%20(USA)%20(Rev%202).png',
      ),
      const GameResult(
        title: 'Mario Kart 64',
        platform: 'N64',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Nintendo%2064%20%28BigEndian%29%20%282016-01-03%29.zip/Mario%20Kart%2064%20%28USA%29.z64',
        size: '12 MB',
        gameId: 'NKTE',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%2064/Named_Boxarts/Mario%20Kart%2064%20(USA).png',
      ),

      // === GBA ===
      const GameResult(
        title: 'Pokemon Emerald',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Pokemon%20-%20Emerald%20Version%20%28USA%2C%20Europe%29.gba',
        size: '16 MB',
        gameId: 'BPEE',
        format: 'GBA',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Game%20Boy%20Advance/Named_Boxarts/Pokemon%20-%20Emerald%20Version%20(USA,%20Europe).png',
      ),
      const GameResult(
        title: 'Pokemon FireRed',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Pokemon%20-%20FireRed%20Version%20%28USA%2C%20Europe%29%20%28Rev%201%29.gba',
        size: '16 MB',
        gameId: 'BPRE',
        format: 'GBA',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Game%20Boy%20Advance/Named_Boxarts/Pokemon%20-%20FireRed%20Version%20(USA,%20Europe)%20(Rev%201).png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: The Minish Cap',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Legend%20of%20Zelda%2C%20The%20-%20The%20Minish%20Cap%20%28USA%2C%20Australia%29.gba',
        size: '8 MB',
        gameId: 'BZME',
        format: 'GBA',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Game%20Boy%20Advance/Named_Boxarts/Legend%20of%20Zelda,%20The%20-%20The%20Minish%20Cap%20(USA).png',
      ),
      const GameResult(
        title: 'Metroid Fusion',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Metroid%20Fusion%20%28USA%2C%20Australia%29.gba',
        size: '8 MB',
        gameId: 'AMTE',
        format: 'GBA',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Game%20Boy%20Advance/Named_Boxarts/Metroid%20Fusion%20(USA).png',
      ),
      const GameResult(
        title: 'Fire Emblem',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Fire%20Emblem%20%28USA%2C%20Australia%29.gba',
        size: '8 MB',
        gameId: 'AFEE',
        format: 'GBA',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Game%20Boy%20Advance/Named_Boxarts/Fire%20Emblem%20(USA,%20Australia).png',
      ),
      const GameResult(
        title: 'Kirby & The Amazing Mirror',
        platform: 'GBA',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Game%20Boy%20Advance%20%282016-02-15%29.zip/Kirby%20%26%20the%20Amazing%20Mirror%20%28USA%29.gba',
        size: '8 MB',
        gameId: 'B8KE',
        format: 'GBA',
      ),

      // === SNES ===
      const GameResult(
        title: 'Super Metroid',
        platform: 'SNES',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System%20%282016-01-03%29.zip/Super%20Metroid%20%28USA%2C%20Europe%29%20%28En%2CJa%29.sfc',
        size: '3 MB',
        gameId: 'SMTD',
        format: 'SFC',
      ),
      const GameResult(
        title: 'The Legend of Zelda: A Link to the Past',
        platform: 'SNES',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System%20%282016-01-03%29.zip/Legend%20of%20Zelda%2C%20The%20-%20A%20Link%20to%20the%20Past%20%28USA%29.sfc',
        size: '1 MB',
        gameId: 'ALTP',
        format: 'SFC',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/Named_Boxarts/Legend%20of%20Zelda,%20The%20-%20A%20Link%20to%20the%20Past%20(USA).png',
      ),
      const GameResult(
        title: 'Chrono Trigger',
        platform: 'SNES',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System%20%282016-01-03%29.zip/Chrono%20Trigger%20%28USA%29.sfc',
        size: '4 MB',
        gameId: 'ACTE',
        format: 'SFC',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/Named_Boxarts/Chrono%20Trigger%20(USA).png',
      ),

      // === NES ===
      const GameResult(
        title: 'Super Mario Bros. 3',
        platform: 'NES',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Nintendo%20Entertainment%20System%20%28Headered%29%20%282016-01-06%29.zip/Super%20Mario%20Bros.%203%20%28USA%29.nes',
        size: '384 KB',
        gameId: 'SMB3',
        format: 'NES',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%20Entertainment%20System/Named_Boxarts/Super%20Mario%20Bros.%203%20(USA).png',
      ),
      const GameResult(
        title: 'The Legend of Zelda',
        platform: 'NES',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Nintendo%20-%20Nintendo%20Entertainment%20System%20%28Headered%29%20%282016-01-06%29.zip/Legend%20of%20Zelda%2C%20The%20%28USA%29.nes',
        size: '128 KB',
        gameId: 'ZLDA',
        format: 'NES',
        coverUrl:
            'https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%20Entertainment%20System/Named_Boxarts/Legend%20of%20Zelda,%20The%20(USA).png',
      ),

      // === Genesis ===
      const GameResult(
        title: 'Sonic the Hedgehog 2',
        platform: 'Genesis',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Sega%20-%20Mega%20Drive%20-%20Genesis%20%282016-03-19%29.zip/Sonic%20the%20Hedgehog%202%20%28World%29.md',
        size: '1 MB',
        gameId: 'MK-1563',
        format: 'MD',
        coverUrl:
            'https://thumbnails.libretro.com/Sega%20-%20Mega%20Drive%20-%20Genesis/Named_Boxarts/Sonic%20the%20Hedgehog%202%20(World).png',
      ),
      const GameResult(
        title: 'Sonic the Hedgehog 3',
        platform: 'Genesis',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/',
        downloadUrl:
            'https://archive.org/download/No-Intro-Collection_2016-01-03_Fixed/Sega%20-%20Mega%20Drive%20-%20Genesis%20%282016-03-19%29.zip/Sonic%20the%20Hedgehog%203%20%28USA%29.md',
        size: '2 MB',
        gameId: 'MK-1079',
        format: 'MD',
        coverUrl:
            'https://thumbnails.libretro.com/Sega%20-%20Mega%20Drive%20-%20Genesis/Named_Boxarts/Sonic%20the%20Hedgehog%203%20(USA).png',
      ),
    ];
  }

  /// Curated list of latest/recent releases - ISO format for REAL Wii hardware
  List<GameResult> _getLatestTitles() {
    return [
      const GameResult(
        title: 'Donkey Kong Country Returns',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Donkey%20Kong%20Country%20Returns%20%28USA%29%20%28En%2CFr%2CEs%29%20%28Rev%201%29.iso',
        size: '4.4 GB',
        gameId: 'SF8E01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SF8E01.png',
      ),
      const GameResult(
        title: 'Kirby\'s Return to Dream Land',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Kirby%27s%20Return%20to%20Dream%20Land%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.4 GB',
        gameId: 'SUKE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SUKE01.png',
      ),
      const GameResult(
        title: 'The Legend of Zelda: Skyward Sword',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Legend%20of%20Zelda%2C%20The%20-%20Skyward%20Sword%20%28USA%29%20%28En%2CFr%2CEs%29%20%28Rev%201%29.iso',
        size: '4.4 GB',
        gameId: 'SOUE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/SOUE01.png',
      ),
      const GameResult(
        title: 'Resident Evil 4: Wii Edition',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Resident%20Evil%204%20-%20Wii%20Edition%20%28USA%29.iso',
        size: '4.4 GB',
        gameId: 'RB4E08',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RB4E08.png',
      ),
      const GameResult(
        title: 'Ookami',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Ookami%20%28USA%29.iso',
        size: '4.4 GB',
        gameId: 'ROWJ08',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/ROWJ08.png',
      ),
      const GameResult(
        title: 'Fire Emblem: Radiant Dawn',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/Fire%20Emblem%20-%20Radiant%20Dawn%20%28USA%29%20%28Rev%201%29.iso',
        size: '4.4 GB',
        gameId: 'RFEE01',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RFEE01.png',
      ),
      const GameResult(
        title: 'MadWorld',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/MadWorld%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.4 GB',
        gameId: 'RZZWE8',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RZZWE8.png',
      ),
      const GameResult(
        title: 'No More Heroes',
        platform: 'Wii',
        region: 'USA',
        provider: 'Archive.org',
        pageUrl: 'https://archive.org/download/Wii_ISO/',
        downloadUrl:
            'https://archive.org/download/Wii_ISO/No%20More%20Heroes%20%28USA%29%20%28En%2CFr%2CEs%29.iso',
        size: '4.4 GB',
        gameId: 'RNHE41',
        coverUrl: 'https://art.gametdb.com/wii/cover3D/US/RNHE41.png',
      ),
    ];
  }

  /// Trigger autonomous search bridge - NOW WITH UNIFIED MULTI-SOURCE SEARCH!
  Future<void> triggerSearch(String query, {String? category}) async {
    if (query.isEmpty) return;

    // Auto-correct query
    final processedQuery = _smartSearch.processQuery(query);
    debugPrint(
        '[Discovery] Original: "$query" -> Processed: "$processedQuery" (Category: $category)');

    _isSearching = true;
    _searchQuery = processedQuery;
    _results = [];
    _error = null;
    _loadingMessage = 'Loading sources...';
    notifyListeners();

    try {
      // 🚀 USE UNIFIED SEARCH - searches ALL sources simultaneously!
      // Priority: Myrient RVZ > Myrient other > Vimm > Archive.org
      _results = await _unifiedSearch.searchAll(processedQuery);

      debugPrint(
          '[Discovery] Found ${_results.length} results from all sources');

      // Group results by source for user transparency
      final sourceCount = <String, int>{};
      for (final result in _results) {
        sourceCount[result.provider] = (sourceCount[result.provider] ?? 0) + 1;
      }

      debugPrint('[Discovery] Source breakdown: $sourceCount');

      // Strict post-filter: keep Wii/GameCube and titles matching tokens
      final tokens = processedQuery
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty && t.length > 2)
          .toList();

      final blacklist = [
        'collection',
        'set',
        'roms',
        'archive',
      ];

      _results = _results.where((r) {
        final title = r.title.toLowerCase();
        final p = r.platform.toLowerCase();

        // Platform check based on Category
        bool platformOk = true;
        if (category != null && category != 'All') {
          if (category == 'Wii') {
            platformOk = p == 'wii' || p == 'wbfs';
          } else if (category == 'GameCube') {
            platformOk = p == 'gamecube' || p == 'gc';
          } else if (category == 'Wii U') {
            platformOk = p == 'wii u' || p == 'wiiu';
          } else if (category == 'Retro') {
            platformOk =
                !['wii', 'gamecube', 'wii u', 'gc', 'wbfs', 'wiiu'].contains(p);
          }
        } else {
          // If 'All', we generally accept everything, but maybe filter out obviously bad stuff if needed
          platformOk = true;
        }

        if (!platformOk) return false;

        // Blacklist check
        final isBlacklisted = blacklist
            .any((b) => title.contains(b) || r.provider.toLowerCase() == b);
        if (isBlacklisted) return false;

        // Scoring check
        if (tokens.isEmpty) return true;

        int matchCount = 0;
        for (final token in tokens) {
          if (title.contains(token)) {
            matchCount++;
          }
        }

        // Allow if >= 50% of tokens match, OR if at least 1 token matches and query is short
        final passes = matchCount > 0 && (matchCount >= tokens.length / 2);

        // Debug: Log why results are filtered
        if (!passes) {
          debugPrint(
              '[Discovery] FILTERED: "${r.title}" (${r.provider}) - matchCount: $matchCount/${tokens.length}');
        }

        return passes;
      }).toList();

      debugPrint('[Discovery] After filtering: ${_results.length} results');

      // Detect platform hints from query
      final platformHints = _smartSearch.detectPlatformHints(processedQuery);
      if (platformHints.isNotEmpty) {
        debugPrint('[Discovery] Platform hints detected: $platformHints');
      }

      // 🎯 SMART SORT: ROM Hacks > Platform Match > Quality > Region
      _results.sort((a, b) {
        // Priority 1: ROM Hacks first
        final aIsHack = a.provider.contains('ROM Hack');
        final bIsHack = b.provider.contains('ROM Hack');
        if (aIsHack != bIsHack) return aIsHack ? -1 : 1;

        // Priority 2: Platform Hint Match
        // Boost results that match inferred platforms (e.g. "mario kart" -> wii)
        bool matchesHint(GameResult r) {
          final p = r.platform.toLowerCase();
          return platformHints.any((h) => p.contains(h) || h.contains(p));
        }

        final aHint = matchesHint(a);
        final bHint = matchesHint(b);
        if (aHint != bHint) return aHint ? -1 : 1;

        // Priority 3: Provider quality (Myrient > Vimm > Archive)
        int providerScore(GameResult r) {
          if (r.provider.contains('Myrient')) return 3;
          if (r.provider == "Vimm's Lair") return 2;
          if (r.provider == 'Archive.org') return 1;
          return 0;
        }

        final providerDiff = providerScore(b).compareTo(providerScore(a));
        if (providerDiff != 0) return providerDiff;

        // Priority 4: Region preference (USA > Europe > World > Japan > Others)
        int regionScore(String region) {
          final r = region.toLowerCase();
          if (r.contains('usa') || r.contains('(us)')) return 5;
          if (r.contains('europe') || r.contains('(eu)')) return 4;
          if (r.contains('world')) return 3;
          if (r.contains('japan') || r.contains('(jp)')) return 2;
          return 1;
        }

        final regionDiff =
            regionScore(b.region).compareTo(regionScore(a.region));
        if (regionDiff != 0) return regionDiff;

        // Priority 5: Token match relevance
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();
        final aMatches = tokens.where((t) => aTitle.contains(t)).length;
        final bMatches = tokens.where((t) => bTitle.contains(t)).length;

        return bMatches.compareTo(aMatches);
      });

      if (_results.isEmpty) {
        _error = "No results found for '$query'";
        _isSearching = false;
        _loadingMessage = null;
      } else {
        // 🎨 WAIT for cover art to load BEFORE showing results (no placeholders!)
        _loadingMessage = 'Fetching covers for ${_results.length} games...';
        notifyListeners();

        debugPrint(
            '[Discovery] Loading covers for ${_results.length} search results...');
        try {
          await _fetchCoversForGames(_results);
          debugPrint('[Discovery] All covers loaded, displaying results');
        } catch (e) {
          debugPrint('[Discovery] Cover fetch error (continuing anyway): $e');
        }

        _loadingMessage = null;
        _isSearching = true; // Keep search mode active to show results
      }
    } catch (e) {
      _error = 'Search Failed: Connection error or scraper blocked.';
      debugPrint('Agent Scrape Error: $e');
      _isSearching = false; // Error, exit search mode
      _loadingMessage = null;
    } finally {
      notifyListeners();
    }
  }

  /// Local filtering for instant results
  void filterLocal(String query) {
    if (query.isEmpty) return;
    // Implementation for instant UI updates
  }

  /// Orchestrate download and unzip
  Future<void> downloadGame(GameResult game) async {
    if (_downloadStatus[game.title] == 'downloading') return;

    _downloadStatus[game.title] = 'downloading';
    _downloadProgress[game.title] = 0.0;
    notifyListeners();

    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) throw Exception('Downloads directory not found');

      File? downloadedFile;

      // Handle Vimm's
      if (game.provider == "Vimm's Lair") {
        downloadedFile = await _vimm.downloadGame(game.pageUrl, downloadDir,
            onProgress: (val) {
          _downloadProgress[game.title] = val;
          notifyListeners();
        });
      }
      // Handle others (simple GET)
      else if (game.downloadUrl != null) {
        final destinationFolder = _library.lastScannedPath ?? downloadDir.path;
        final task = await _download.addToQueue(
          url: game.downloadUrl!,
          title: game.title,
          destinationFolder: destinationFolder,
          gameId: game.gameId,
          platform: game.platform,
        );
        while (task.status == DownloadStatus.pending ||
            task.status == DownloadStatus.downloading) {
          await Future.delayed(const Duration(milliseconds: 300));
          _downloadProgress[game.title] = task.progress;
          notifyListeners();
        }
        if (task.status == DownloadStatus.completed &&
            task.destinationPath != null) {
          downloadedFile = File(task.destinationPath!);
        } else {
          throw Exception(task.errorMessage ?? 'Download failed');
        }
      }

      if (downloadedFile == null) throw Exception('Download failed');

      // Unzipping Phase
      _downloadStatus[game.title] = 'unzipping';
      notifyListeners();

      // Check if it is an archive
      if (downloadedFile.path.endsWith('.7z') ||
          downloadedFile.path.endsWith('.rvz')) {
        final destinationFolder =
            Directory(_library.lastScannedPath ?? downloadDir.path);
        final extractedPath =
            await _archive.extractGame(downloadedFile, destinationFolder);
        if (extractedPath != null) {
          debugPrint('Extracted to: $extractedPath');
          try {
            await downloadedFile.delete();
          } catch (_) {}
        } else {
          throw Exception('Extraction failed');
        }
      }

      _downloadStatus[game.title] = 'ready';
      notifyListeners();

      final targetFolder = _library.lastScannedPath ?? downloadDir.path;
      final games = await _scanner.scanDirectory(targetFolder);
      for (final g in games) {
        g.health = await _scanner.calculateHealth(g);
        g.verified = g.health >= 70;
      }
      _library.updateLibrary(games, targetFolder);
    } catch (e) {
      _downloadStatus[game.title] = 'error';
      _error = e.toString();
      debugPrint('Download Error: $e');
      notifyListeners();
    }
  }

  /// Run a directory diagnostic scan and cache results
  Future<List<String>> runScanDiagnostic(String path) async {
    _lastDiagnostics = [];
    try {
      final results = await _scanner.scanDirectoryDiagnostic(path);
      _lastDiagnostics = results;
      return results;
    } catch (e) {
      _lastDiagnostics = ['Diagnostic failed: $e'];
      return _lastDiagnostics;
    } finally {
      notifyListeners();
    }
  }

  // Forge bridge used for archive acquisitions
  final ForgeBridge _acquireForge = ForgeBridge();

  /// Acquire a game from Archive.org by archive identifier
  Future<void> acquireGame(String archiveId, String gameTitle) async {
    if (archiveId.isEmpty) return;

    // mark starting state
    _downloadStatus[gameTitle] = 'downloading';
    _downloadProgress[gameTitle] = 0.0;
    notifyListeners();

    try {
      final files = await ArchiveOrgService().getFilesForIdentifier(archiveId);
      if (files.isEmpty) {
        _downloadStatus[gameTitle] = 'error';
        _error = 'No files found for $archiveId';
        notifyListeners();
        return;
      }

      final best = ArchiveOrgService().pickBestFile(files);
      if (best == null) {
        _downloadStatus[gameTitle] = 'error';
        _error = 'No suitable file found for $archiveId';
        notifyListeners();
        return;
      }

      // Determine destination
      final downloadDir = await getDownloadsDirectory();
      final destinationBase =
          downloadDir?.path ?? _library.lastScannedPath ?? '.';

      final safeTitle = gameTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final destPath =
          path_lib.join(destinationBase, '$safeTitle [$archiveId].wbfs');

      // Progress callback
      void progressCallback(
          int status, double progress, Pointer<Utf8> messagePtr) {
        final statusStr = _forgeStatusToString(status);

        _downloadStatus[gameTitle] = statusStr;
        _downloadProgress[gameTitle] = progress;
        notifyListeners();
      }

      final missionId = await _acquireForge.startMission(
          best.downloadUrl, destPath, progressCallback);
      debugPrint(
          '[Discovery] Started acquisition mission $missionId for $gameTitle');

      // Keep UI informed
      _downloadStatus[gameTitle] = 'downloading';
      notifyListeners();
    } catch (e) {
      _downloadStatus[gameTitle] = 'error';
      _error = 'Acquisition failed: $e';
      debugPrint('[Discovery] Acquisition failed: $e');
      notifyListeners();
    }
  }

  String _forgeStatusToString(int status) {
    switch (status) {
      case 0:
        return 'handshaking';
      case 1:
        return 'downloading';
      case 2:
        return 'extracting';
      case 3:
        return 'forging';
      case 4:
        return 'ready';
      case 5:
        return 'error';
      default:
        return 'unknown';
    }
  }

  /// Parse platform string to GamePlatform enum
  GamePlatform _parsePlatform(String platform) {
    final lower = platform.toLowerCase();

    // Core platforms
    if (lower == 'wii') return GamePlatform.wii;
    if (lower.contains('wii u') || lower == 'wiiu') return GamePlatform.wiiu;
    if (lower.contains('gamecube') || lower == 'gc') {
      return GamePlatform.gamecube;
    }

    // Retro
    if (lower.contains('n64') || lower.contains('nintendo 64')) {
      return GamePlatform.n64;
    }
    if (lower.contains('snes') || lower.contains('super nintendo')) {
      return GamePlatform.snes;
    }
    if (lower.contains('nes') || lower == 'nintendo') return GamePlatform.nes;

    // Handheld
    if (lower.contains('gba') || lower.contains('game boy advance')) {
      return GamePlatform.gba;
    }
    if (lower.contains('gbc') || lower.contains('color')) {
      return GamePlatform.gbc;
    }
    if (lower.contains('gb') || lower.contains('game boy')) {
      return GamePlatform.gameboy;
    }
    if (lower.contains('3ds')) return GamePlatform.n3ds;
    if (lower.contains('ds')) return GamePlatform.nds;

    // Sega
    if (lower.contains('genesis') || lower.contains('mega drive')) {
      return GamePlatform.genesis;
    }

    // Use generic Wii as fallback if unknown (safest default)
    return GamePlatform.wii;
  }
}
