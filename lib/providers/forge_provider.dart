// ═══════════════════════════════════════════════════════════════════════════
// FORGE PROVIDER
// WiiGC-Fusion - Download & Game Processing State Management
// ═══════════════════════════════════════════════════════════════════════════
//
// This is the CORE STATE MANAGEMENT provider for download operations.
// It orchestrates the entire download pipeline:
//
//   User Request → Queue Management → URL Resolution → Native Download → UI Updates
//
// Key Features:
//   • Download Queue: Batch downloads with automatic progression
//   • Queue Persistence: Survives app restarts, auto-resumes on launch
//   • Speed Tracking: Real-time bytes/sec and ETA calculations
//   • Archive.org Integration: Resolves metadata URLs to direct downloads
//   • Native FFI: Uses forge_core.dll for high-speed WinHTTP downloads
//   • Production Mode: Requires native library for all operations
//
// Architecture:
//   ┌──────────────────────────────────────────────────────────────────────┐
//   │  SearchScreen / ResultsView / QueueView                             │
//   │      ↓ startForge(game)                                             │
//   │  ForgeProvider (this file)                                          │
//   │      ├── Queue Management (_downloadQueue)                          │
//   │      ├── URL Resolution (ArchiveOrgService)                         │
//   │      ├── Native Bridge (ForgeBridge → forge_core.dll)               │
//   │      └── Progress Polling (_startProgressPolling)                   │
//   │                                                                     │
//   │  Persistence Layer:                                                 │
//   │      ├── wiigc_fusion_queue.json (download queue)                   │
//   │      └── wiigc_fusion_settings.json (provider settings)             │
//   └──────────────────────────────────────────────────────────────────────┘
//
// Usage:
//   final provider = context.read<ForgeProvider>();
//
//   // Start or queue a download
//   await provider.startForge(gameResult);
//
//   // Monitor progress
//   print('${provider.progress * 100}% - ${provider.statusMessage}');
//   print('Speed: ${provider.formattedDownloadSpeed}, ETA: ${provider.formattedEta}');
//
//   // Cancel current download
//   await provider.cancelForge();
//
// Settings:
//   • autoStartPersistedQueue: Auto-start queued downloads on app launch
//   • allowResumeAtOffset: Attempt to resume partial downloads
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../ffi/forge_bridge.dart';
import '../models/game_result.dart';
import '../services/archive_org_service.dart';
import '../services/myrient_scraper.dart';
import '../services/homebrew_automation_service.dart';
import 'package:url_launcher/url_launcher.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Internal configuration constants
abstract final class _Config {
  /// How often to poll native library for progress (ms)
  /// 2000ms (2 seconds) to prevent Windows message queue flooding at high download speeds
  static const pollIntervalMs = 2000;

  /// Default output directory for downloads
  static const defaultOutputDir = 'C:/Orbiit/wbfs';

  /// Queue persistence filename
  static const queueFileName = 'wiigc_fusion_queue.json';

  /// Settings persistence filename
  static const settingsFileName = 'wiigc_fusion_settings.json';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FORGE PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Forge Provider - Manages C++ backend integration for game processing.
///
/// Handles WBFS splitting, partition stripping, and FAT32 formatting.
/// Uses a queue-based download system with persistence and auto-resume.
///
/// Example:
/// ```dart
/// // In a widget
/// final provider = context.watch<ForgeProvider>();
///
/// // Start a download
/// await provider.startForge(gameResult);
///
/// // Display progress
/// LinearProgressIndicator(value: provider.progress);
/// Text(provider.statusMessage);
/// Text('Speed: ${provider.formattedDownloadSpeed}');
/// Text('ETA: ${provider.formattedEta}');
/// ```
class ForgeProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────────────────

  final ForgeBridge _forgeBridge = ForgeBridge();
  final String? _persistenceDir;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a ForgeProvider.
  ///
  /// Parameters:
  /// - [persistenceDir]: Optional directory for queue/settings persistence.
  ///   If null, uses the system's application support directory.
  ForgeProvider({String? persistenceDir}) : _persistenceDir = persistenceDir {
    // Initialize with app's data directory
    _initializeNativeLibrary();
  }

  Future<void> _initializeNativeLibrary() async {
    try {
      // Use app directory for database (writable location)
      final appDir = Directory.current.path;
      final success = _forgeBridge.init(appDir);

      if (!success) {
        debugPrint(
            '[ForgeProvider] WARNING: Native init failed - retrying with temp dir');
        final tempDir = Directory.systemTemp.path;
        _forgeBridge.init(tempDir);
      }
    } catch (e) {
      debugPrint('[ForgeProvider] Init error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core State
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a forge operation is currently active
  bool _isForging = false;

  /// Current progress (0.0 to 1.0)
  double _progress = 0.0;

  /// Human-readable status message
  String _statusMessage = '';

  /// Current operation status
  ForgeStatus _currentStatus = ForgeStatus.ready;

  /// Native mission ID for the current operation
  int? _currentMissionId;

  /// The game currently being downloaded
  GameResult? _currentGame;

  /// Path to the file being downloaded
  String? _currentDownloadPath;

  // ─────────────────────────────────────────────────────────────────────────
  // Download Queue
  // ─────────────────────────────────────────────────────────────────────────

  /// Queued games waiting for download
  final List<GameResult> _downloadQueue = [];

  // ─────────────────────────────────────────────────────────────────────────
  // Error State
  // ─────────────────────────────────────────────────────────────────────────

  /// Last error message, or null if no error
  String? _error;

  // ─────────────────────────────────────────────────────────────────────────
  // Progress Polling
  // ─────────────────────────────────────────────────────────────────────────

  /// Timer for polling native progress
  Timer? _pollingTimer;

  // ─────────────────────────────────────────────────────────────────────────
  // Basic Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a download is currently in progress
  bool get isForging => _isForging;

  /// Current progress (0.0 = not started, 1.0 = complete)
  double get progress => _progress;

  /// Human-readable status message
  String get statusMessage => _statusMessage;

  /// Current operation status enum
  ForgeStatus get currentStatus => _currentStatus;

  /// Whether active download is currently paused
  bool get isPaused => _currentStatus == ForgeStatus.paused;

  /// The game currently being downloaded (null if idle)
  GameResult? get currentGame => _currentGame;

  /// Last error message (null if no error)
  String? get error => _error;

  /// Whether running without native library
  bool get isMockMode => _forgeBridge.isMockMode;

  /// Read-only copy of the download queue for UI
  List<GameResult> get downloadQueue => List.unmodifiable(_downloadQueue);

  /// Check if a specific game is already queued or downloading
  bool isQueued(GameResult game) {
    // Try matching by gameId first (most reliable)
    if (game.gameId != null && game.gameId!.isNotEmpty) {
      return _downloadQueue.any((g) => g.gameId == game.gameId) ||
          (_currentGame?.gameId == game.gameId && _isForging);
    }
    // Fallback to pageUrl/title match
    return _downloadQueue.any((g) => g.pageUrl == game.pageUrl) ||
        (_currentGame?.pageUrl == game.pageUrl && _isForging);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Speed & ETA Tracking
  // ─────────────────────────────────────────────────────────────────────────

  DateTime? _lastProgressTimestamp;
  double _lastProgressValue = 0.0;
  int? _lastDownloadedBytes;
  int? _lastTotalBytes;

  /// Progress speed in percent-per-second (0.01 = 1%/s)
  double _progressSpeed = 0.0;

  /// Download speed in bytes per second
  double? _downloadSpeedBps;

  /// Estimated time remaining
  Duration? _estimatedRemaining;

  /// Progress speed in percent-per-second
  double get progressSpeed => _progressSpeed;

  /// Download speed in bytes per second
  double? get downloadSpeedBps => _downloadSpeedBps;

  /// Estimated time remaining
  Duration? get eta => _estimatedRemaining;

  /// Last-seen raw bytes downloaded (0 if unknown)
  int get currentDownloadedBytes => _lastDownloadedBytes ?? 0;

  /// Last-seen total bytes for current mission (1 if unknown to avoid divide by zero)
  int get currentTotalBytes => _lastTotalBytes ?? 1;

  /// Human-readable download speed
  String get formattedDownloadSpeed {
    if (_downloadSpeedBps != null && _downloadSpeedBps! > 0) {
      return _formatBytesPerSecond(_downloadSpeedBps!);
    }
    // As a last resort show percent-per-second if it is meaningfully non-zero
    if (_progressSpeed > 1e-4) {
      return '${(_progressSpeed * 100).toStringAsFixed(2)}%/s';
    }
    return '';
  }

  /// Human-readable ETA
  String get formattedEta {
    if (_estimatedRemaining == null) return '';
    final d = _estimatedRemaining!;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Settings
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether to auto-start queued downloads on app launch
  bool _autoStartPersistedQueue = true;

  /// Whether to attempt resuming partial downloads
  bool _allowResumeAtOffset = false;

  /// Timestamp of last queue save
  /// Timestamp of last queue save
  DateTime? _lastQueueSavedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // Settings Getters/Setters
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether to auto-start queued downloads on app launch
  bool get autoStartPersistedQueue => _autoStartPersistedQueue;

  /// Whether to attempt resuming partial downloads
  bool get allowResumeAtOffset => _allowResumeAtOffset;

  /// Timestamp of last queue save
  DateTime? get lastQueueSavedAt => _lastQueueSavedAt;

  set autoStartPersistedQueue(bool v) {
    _autoStartPersistedQueue = v;
    unawaited(_saveSettingsToDisk());
    notifyListeners();
  }

  set allowResumeAtOffset(bool v) {
    _allowResumeAtOffset = v;
    unawaited(_saveSettingsToDisk());
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize the forge backend and load persisted state.
  ///
  /// Must be called before any other operations.
  /// Loads settings and download queue from disk.
  ///
  /// Returns true if initialization succeeded.
  Future<bool> initialize() async {
    try {
      debugPrint('[ForgeProvider] Initializing forge backend...');
      final success = _forgeBridge.init();

      if (success) {
        debugPrint('[ForgeProvider] Forge backend initialized successfully');
      } else {
        // Warning only - Core download features work via Dart
        debugPrint(
            '[ForgeProvider] WARNING: Native backend init failed. Extended features unavailable.');
        // Do NOT set _error here, allowing the app to functional normally for basic downloads.
      }

      // Load persisted settings & queue after initializing backend
      await _loadSettingsFromDisk();
      await _loadQueueFromDisk();

      notifyListeners();
      return true; // Always return true to allow app startup
    } catch (e) {
      _error = 'Initialization error: $e';
      debugPrint('[ForgeProvider] Initialization error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start downloading a game.
  ///
  Future<void> startHomebrewInstall(GameResult game) async {
    if (_isForging) {
      if (!isQueued(game)) {
        _downloadQueue.add(game);
        unawaited(_saveQueueToDisk());
      }
      notifyListeners();
      return;
    }

    try {
      _currentGame = game;
      _isForging = true;
      _progress = 0.0;
      _statusMessage = 'Initializing Homebrew installation...';
      _currentStatus = ForgeStatus.handshaking;
      _error = null;
      notifyListeners();

      // Determine SD Card Root
      final appDocDir = await getApplicationDocumentsDirectory();
      // Use 'Orbiit/sd_card' in Documents for safety, or C:/Orbiit/sd_card if preferred.
      // Using global config default for now.
      final sdCardRoot = Directory(p.join(_Config.defaultOutputDir, 'sd_card'));
      if (!sdCardRoot.existsSync()) sdCardRoot.createSync(recursive: true);

      await HomebrewAutomationService().installToSD(
        game: game,
        sdCardRoot: sdCardRoot,
        onProgress: (val) {
          _progress = val;
          notifyListeners();
        },
        onStatus: (msg) {
          _statusMessage = msg;
          notifyListeners();
        },
      );

      _statusMessage = 'Install Complete!';
      _currentStatus = ForgeStatus.ready;
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _error = e.toString();
      _currentStatus = ForgeStatus.error;
      debugPrint('[ForgeProvider] Homebrew Install Failed: $e');
    } finally {
      // Clean up state
      _isForging = false;
      _currentGame = null;
      _progress = 0.0;
      notifyListeners();

      // Check queue logic here mirroring startForge...
      if (_downloadQueue.isNotEmpty) {
        final next = _downloadQueue.removeAt(0);
        unawaited(_saveQueueToDisk());
        // Simple heuristic: If platform is Wii Homebrew, recurse homebrew install
        if (next.platform == 'Wii Homebrew') {
          unawaited(startHomebrewInstall(next));
        } else {
          unawaited(startForge(next));
        }
      }
    }
  }

  /// If a download is already in progress, adds the game to the queue.
  /// Otherwise starts the download immediately.
  ///
  /// Parameters:
  /// - [game]: The game to download
  /// - [destinationPath]: Optional custom destination path
  ///
  /// Example:
  /// ```dart
  /// // Add to queue (or start immediately if idle)
  /// await provider.startForge(searchResult);
  ///
  /// // Start with custom destination
  /// await provider.startForge(game, destinationPath: 'D:/Games/output.wbfs');
  /// ```
  Future<void> startForge(GameResult game, {String? destinationPath}) async {
    // If a mission is already active, enqueue and return
    if (_isForging) {
      // Avoid duplicate queue entries
      if (!isQueued(game)) {
        _downloadQueue.add(game);
        debugPrint('[ForgeProvider] Forge busy - queued: ${game.title}');
        // Persist queue to disk
        unawaited(_saveQueueToDisk());
      } else {
        debugPrint('[ForgeProvider] Game already queued: ${game.title}');
      }
      notifyListeners();
      return;
    }

    // Otherwise start immediately
    await _startForgeInternal(game, destinationPath: destinationPath);
  }

  /// Internal implementation for starting a download.
  ///
  /// Handles URL resolution, native bridge calls, and progress polling.
  Future<void> _startForgeInternal(GameResult game,
      {String? destinationPath}) async {
    try {
      // Initialize state
      _currentGame = game;
      _isForging = true;
      _progress = 0.0;
      _statusMessage = 'Resolving game files...';
      _currentStatus = ForgeStatus.handshaking;
      _error = null;

      debugPrint('[ForgeProvider] Starting forge for: ${game.title}');
      notifyListeners();

      // ⚡ Handle External Browser Requirements (Rom Hacks / Manual Downloads)
      if (game.requiresBrowser ||
          (game.description?.contains('requires browser') ?? false)) {
        _statusMessage = 'Opening external download page...';
        notifyListeners();

        final url = game.pageUrl ?? game.downloadUrl;
        if (url != null && url.isNotEmpty) {
          try {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            _statusMessage = 'Opened in browser';
            _currentStatus = ForgeStatus.ready;
          } catch (e) {
            _error = 'Could not open browser: $e';
            _currentStatus = ForgeStatus.error;
          }
        } else {
          _error = 'No URL available to open';
          _currentStatus = ForgeStatus.error;
        }

        // Complete the "forge" immediately
        _isForging = false;
        _progress = 1.0;
        notifyListeners();

        // Process next item in queue after delay
        await Future.delayed(const Duration(seconds: 1));
        if (_downloadQueue.isNotEmpty) {
          final next = _downloadQueue.removeAt(0);
          unawaited(_saveQueueToDisk());
          unawaited(startForge(next));
        }
        return;
      }

      // ─────────────────────────────────────────────────────────────────────
      // URL Resolution
      // ─────────────────────────────────────────────────────────────────────

      String targetUrl = game.downloadUrl ?? '';

      // Handle Myrient URLs - use Scraper to ensure freshness and correctness (Fix for 404s)
      if (targetUrl.isNotEmpty && targetUrl.contains('myrient.erista.me')) {
        try {
          _statusMessage = 'Refining Myrient link...';
          notifyListeners();

          // Extract base directory
          // e.g. https://myrient.erista.me/files/.../Game.zip -> https://myrient.erista.me/files/.../
          final uri = Uri.parse(targetUrl);
          final pathSegments = List<String>.from(uri.pathSegments);

          if (pathSegments.isNotEmpty) {
            // Remove the file part to get the directory
            pathSegments.removeLast();
            final baseUrl = uri
                    .replace(
                        pathSegments: pathSegments, query: null, fragment: null)
                    .toString() +
                '/';

            final scraper = MyrientScraper();
            // Use the Game Title for searching, as the filename in targetUrl might be guessed/wrong
            final refinedUrl = await scraper.findGameUrl(baseUrl, game.title);

            if (refinedUrl != null) {
              debugPrint(
                  '[ForgeProvider] Myrient Scraper refined URL: $targetUrl -> $refinedUrl');
              targetUrl = refinedUrl;
            }
          }
        } catch (e) {
          debugPrint(
              '[ForgeProvider] Scraper refinement failed (using original): $e');
        }
      }

      // Handle Archive.org URLs that need metadata resolution
      if (targetUrl.isEmpty || targetUrl.startsWith('archive://')) {
        if (game.sourceIdentifier != null &&
            game.sourceIdentifier!.isNotEmpty) {
          _statusMessage = 'Resolving Archive.org metadata...';
          notifyListeners();

          final files = await ArchiveOrgService().getFilesForIdentifier(
            game.sourceIdentifier!,
          );
          final best = ArchiveOrgService().pickBestFile(files);

          if (best != null) {
            targetUrl = best.downloadUrl;
            debugPrint('[ForgeProvider] Resolved to: $targetUrl');
          } else {
            throw Exception('No valid Wii ISO/WBFS found for ${game.title}');
          }
        } else {
          throw Exception(
            'Cannot forge: No URL and no Archive Identifier provided.',
          );
        }
      }

      _statusMessage = 'Initializing native pipeline...';
      notifyListeners();

      // ─────────────────────────────────────────────────────────────────────
      // Destination Path
      // ─────────────────────────────────────────────────────────────────────

      // ─────────────────────────────────────────────────────────────────────
      // Smart Path Resolution
      // ─────────────────────────────────────────────────────────────────────

      // Determine extension from URL or Platform
      String ext = '.iso'; // Default
      if (targetUrl.isNotEmpty) {
        final uri = Uri.parse(targetUrl);
        final path = uri.path;
        if (path.contains('.')) {
          ext = p.extension(path);
        }
      }

      // If extension is generic .zip/.7z, we trust it.
      // If it's missing, we guess based on platform.
      if (ext.isEmpty || ext == '.') {
        switch (game.platform.toLowerCase()) {
          // Nintendo
          case 'wii':
            ext = '.wbfs';
            break;
          case 'gamecube':
          case 'gc':
            ext = '.iso';
            break;
          case 'wii u':
          case 'wiiu':
            ext = '.wux';
            break;
          case 'switch':
          case 'nx':
            ext = '.nsp';
            break;
          case 'n64':
          case 'nintendo 64':
            ext = '.z64';
            break;
          case 'snes':
          case 'super nintendo':
            ext = '.sfc';
            break;
          case 'nes':
          case 'nintendo':
            ext = '.nes';
            break;
          case 'gba':
          case 'gameboy advance':
            ext = '.gba';
            break;
          case 'gbc':
          case 'gameboy color':
            ext = '.gbc';
            break;
          case 'gb':
          case 'gameboy':
            ext = '.gb';
            break;
          case 'nds':
          case 'ds':
          case 'nintendo ds':
            ext = '.nds';
            break;
          case '3ds':
          case 'nintendo 3ds':
            ext = '.3ds';
            break;

          // Sony
          case 'ps1':
          case 'psx':
          case 'playstation':
            ext = '.chd';
            break;
          case 'ps2':
          case 'playstation 2':
            ext = '.iso';
            break;
          case 'ps3':
          case 'playstation 3':
            ext = '.iso';
            break;
          case 'psp':
          case 'playstation portable':
            ext = '.iso';
            break;
          case 'psvita':
          case 'vita':
            ext = '.vpk';
            break;

          // Sega
          case 'genesis':
          case 'megadrive':
            ext = '.md';
            break;
          case 'dreamcast':
            ext = '.gdi';
            break;
          case 'saturn':
            ext = '.chd';
            break;
          case 'gamegear':
            ext = '.gg';
            break;

          // Microsoft
          case 'xbox':
            ext = '.iso';
            break;
          case 'xbox 360':
            ext = '.iso';
            break;

          default:
            ext = '.iso';
        }
      }

      // Determine Subfolder
      // Determine Subfolder
      String subfolder = 'downloads';
      final pLower = game.platform.toLowerCase();

      if (pLower.contains('wii u') || pLower == 'wiiu')
        subfolder = 'wiiu';
      else if (pLower == 'wii')
        subfolder = 'wbfs';
      else if (pLower == 'gamecube' || pLower == 'gc')
        subfolder = 'games'; // Nintendont style
      else if (pLower.contains('switch'))
        subfolder = 'switch';
      else if (pLower.contains('ps1') ||
          pLower == 'psx' ||
          pLower == 'playstation')
        subfolder = 'psx';
      else if (pLower.contains('ps2'))
        subfolder = 'ps2';
      else if (pLower.contains('ps3'))
        subfolder = 'ps3';
      else if (pLower.contains('psp'))
        subfolder = 'psp';
      else if (pLower.contains('vita'))
        subfolder = 'psvita';
      else if (pLower.contains('n64'))
        subfolder = 'n64';
      else if (pLower.contains('snes'))
        subfolder = 'snes';
      else if (pLower.contains('nes'))
        subfolder = 'nes';
      else if (pLower.contains('gba'))
        subfolder = 'gba';
      else if (pLower.contains('gbc'))
        subfolder = 'gbc';
      else if (pLower == 'gb' || pLower == 'gameboy')
        subfolder = 'gb';
      else if (pLower.contains('nds') || pLower.contains('ds'))
        subfolder = 'nds';
      else if (pLower.contains('3ds'))
        subfolder = '3ds';
      else if (pLower.contains('genesis') || pLower.contains('megadrive'))
        subfolder = 'genesis';
      else if (pLower.contains('dreamcast'))
        subfolder = 'dreamcast';
      else if (pLower.contains('saturn'))
        subfolder = 'saturn';
      else if (pLower.contains('xbox')) subfolder = 'xbox';

      final String safeTitle = game.title.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '',
      );

      // Construct filename: Title [ID].ext
      final String fileName = '$safeTitle [${game.gameId ?? 'UNKNOWN'}]$ext';

      String destPath;
      if (destinationPath != null) {
        // User provided a custom path (likely from directory picker)
        // We assume it's a directory and append the filename
        destPath = p.join(destinationPath, fileName);
      } else {
        // User requested to use the project root directory instead of Directory.current or Documents
        // This avoids OneDrive path issues.
        final baseDir =
            r'C:\Users\kidke\OneDrive\Desktop\Best Wii\wiigc_fusion';
        destPath = p.join(baseDir, subfolder, fileName);
      }

      // ─────────────────────────────────────────────────────────────────────
      // Ensure destination directory exists FIRST
      // ─────────────────────────────────────────────────────────────────────
      // ─────────────────────────────────────────────────────────────────────
      // CRITICAL: Create directory BEFORE native call
      // ─────────────────────────────────────────────────────────────────────
      final destDir = Directory(p.dirname(destPath));
      debugPrint('[ForgeProvider] Destination directory: ${destDir.path}');

      if (!await destDir.exists()) {
        debugPrint('[ForgeProvider] Creating directory: ${destDir.path}');
        try {
          await destDir.create(recursive: true);
          debugPrint('[ForgeProvider] ✓ Directory created successfully');
        } catch (e) {
          debugPrint('[ForgeProvider] ✗ Failed to create directory: $e');
          throw Exception(
              'Cannot create output directory: ${destDir.path} - $e');
        }
      }

      // Verify the directory actually exists now
      if (!await destDir.exists()) {
        throw Exception('Directory creation failed silently: ${destDir.path}');
      }

      debugPrint('[ForgeProvider] ✓ Directory verified: ${destDir.path}');

      // Store the download path for later use (e.g., deletion on cancel)
      _currentDownloadPath = destPath;

      // ─────────────────────────────────────────────────────────────────────
      // Resume Support (experimental)
      // ─────────────────────────────────────────────────────────────────────

      if (_allowResumeAtOffset) {
        try {
          final f = File(destPath);
          if (await f.exists()) {
            final len = await f.length();
            if (len > 0) {
              _statusMessage =
                  'Resuming from ${_formatBytesPerSecond(len.toDouble())}';
              debugPrint(
                '[ForgeProvider] Resume requested for $destPath at $len bytes '
                '(native support required)',
              );
              notifyListeners();
              // TODO: Pass `len` as offset to native if supported
            }
          }
        } catch (e) {
          debugPrint('[ForgeProvider] Resume check failed: $e');
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // Ensure Native Library is Ready
      // ─────────────────────────────────────────────────────────────────────

      // We only strictly require native library if specific native features are needed.
      // For general downloading, Dart Isolates are sufficient.
      // So we log a warning instead of throwing exception.

      if (!_forgeBridge.isNativeReady && !_forgeBridge.isMockMode) {
        _statusMessage = 'Waiting for native library...';
        notifyListeners();

        // Wait for native library to initialize (max 2 seconds)
        int waitMs = 0;
        while (!_forgeBridge.isNativeReady && waitMs < 2000) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitMs += 100;
        }

        if (!_forgeBridge.isNativeReady) {
          debugPrint(
              '[ForgeProvider] WARNING: Native library not ready. Proceeding with Dart fallback.');
          // Do not throw.
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // Start Native Mission
      // ─────────────────────────────────────────────────────────────────────

      void progressCallback(
        int status,
        double progress,
        ffi.Pointer<Utf8> message,
      ) {
        handleProgressUpdate(status, progress, message.toDartString());
      }

      debugPrint('[ForgeProvider] Native Mission Details:');
      debugPrint('  URL: $targetUrl');
      debugPrint('  Dest: $destPath');
      debugPrint(
          '  Lib: ${_forgeBridge.isNativeReady ? "Native Ready" : "ERROR - Library Not Loaded"}');

      _currentMissionId = await _forgeBridge.startMission(
        targetUrl,
        destPath,
        progressCallback,
      );

      if (_currentMissionId == 0) {
        throw Exception(
            'Native mission failed to start (ID 0). Check file permissions or disk space.');
      }

      debugPrint(
        '[ForgeProvider] Forge mission started with ID: $_currentMissionId',
      );

      // Start polling for progress (callbacks don't work from C++ threads)
      _startProgressPolling();
    } catch (e) {
      _error = 'Download error: $e';
      _isForging = false;
      _currentStatus = ForgeStatus.error;
      _statusMessage = 'Failed to start download';

      debugPrint('[ForgeProvider] Download start error: $e');
      notifyListeners();

      // Try starting next queued mission if present
      if (_downloadQueue.isNotEmpty) {
        final next = _downloadQueue.removeAt(0);
        debugPrint(
            '[ForgeProvider] Starting next queued after error: ${next.title}');
        await _startForgeInternal(next);
      }
    }
  }

  /// Cancel current forge operation
  Future<void> cancelForge() async {
    // Guard: Check if there's anything to cancel
    if (!_isForging || _currentMissionId == null) {
      debugPrint('[ForgeProvider] No forge operation to cancel');
      return;
    }

    // Store current mission ID and download path before any state changes
    final missionIdToCancel = _currentMissionId;
    final gameBeingCancelled = _currentGame;
    final downloadPathToDelete = _currentDownloadPath;

    debugPrint('[ForgeProvider] Cancelling forge mission: $missionIdToCancel');

    try {
      // CRITICAL FIX: Stop polling BEFORE cancelling native mission
      // This prevents the polling loop from trying to access a destroyed mission object
      _stopProgressPolling();

      // Call native cancel FIRST, before changing any state
      final success = _forgeBridge.cancelMission(missionIdToCancel!);

      if (!success) {
        // Cancel failed - log but don't change state
        debugPrint('[ForgeProvider] Failed to cancel forge operation');
        _error = 'Failed to cancel forge operation';
        notifyListeners();
        return;
      }

      // Cancel succeeded - now update ALL state atomically
      _isForging = false;
      _currentStatus = ForgeStatus.ready;
      _statusMessage = 'Download cancelled';
      _currentMissionId = null;
      _currentGame = null;
      _currentDownloadPath = null;
      _error = null;

      // Reset speed/eta trackers
      _lastProgressTimestamp = null;
      _lastProgressValue = 0.0;
      _lastDownloadedBytes = null;
      _lastTotalBytes = null;
      _progressSpeed = 0.0;
      _downloadSpeedBps = null;
      _estimatedRemaining = null;

      debugPrint(
          '[ForgeProvider] Forge cancelled successfully: ${gameBeingCancelled?.title ?? 'UNKNOWN'}');

      // Delete the partially downloaded file
      if (downloadPathToDelete != null) {
        try {
          final file = File(downloadPathToDelete);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
                '[ForgeProvider] ✓ Deleted partial download: $downloadPathToDelete');
          }
        } catch (e) {
          debugPrint('[ForgeProvider] ✗ Failed to delete partial download: $e');
        }
      }

      // Single notifyListeners after all state changes
      notifyListeners();

      // Start next queued mission if present (after notifyListeners)
      if (_downloadQueue.isNotEmpty) {
        final next = _downloadQueue.removeAt(0);
        debugPrint(
            '[ForgeProvider] Starting next queued after cancel: ${next.title}');
        // Small delay to ensure UI has time to update
        await Future.delayed(const Duration(milliseconds: 100));
        await _startForgeInternal(next);
      }
    } catch (e) {
      // Crash protection: Log error and reset to safe state
      debugPrint('[ForgeProvider] Cancel error: $e');
      _error = 'Cancel error: $e';
      _isForging = false;
      _currentStatus = ForgeStatus.ready;
      _currentMissionId = null;
      _currentGame = null;
      notifyListeners();
    }
  }

  /// Pause the current forge operation
  Future<void> pauseForge() async {
    if (!_isForging || _currentMissionId == null || isPaused) {
      debugPrint('[ForgeProvider] Nothing to pause or already paused');
      return;
    }

    debugPrint('[ForgeProvider] Pausing forge mission: $_currentMissionId');

    // Stop polling while paused
    _pollingTimer?.cancel();
    _pollingTimer = null;

    _currentStatus = ForgeStatus.paused;
    _statusMessage = 'Download paused';
    notifyListeners();
  }

  /// Resume a paused forge operation
  Future<void> resumeForge() async {
    if (!_isForging || _currentMissionId == null || !isPaused) {
      debugPrint('[ForgeProvider] Nothing to resume or not paused');
      return;
    }

    debugPrint('[ForgeProvider] Resuming forge mission: $_currentMissionId');

    _currentStatus = ForgeStatus.downloading;
    _statusMessage = 'Resuming download...';

    // Restart polling
    _startProgressPolling();

    notifyListeners();
  }

  /// Format a drive with 32KB allocation (FAT32 /A:32K)
  Future<bool> formatDrive(String drivePath, {String? label}) async {
    try {
      debugPrint('[ForgeProvider] Formatting drive: $drivePath');

      void progressCallback(
          int status, double progress, ffi.Pointer<Utf8> message) {
        _currentStatus =
            ForgeStatus.values[status.clamp(0, ForgeStatus.values.length - 1)];
        _progress = progress.clamp(0.0, 1.0);
        _statusMessage = message.toDartString();

        debugPrint(
            '[ForgeProvider] Format progress: ${(progress * 100).toInt()}% - $_statusMessage');
        notifyListeners();
      }

      final success = await _forgeBridge.formatDrive(
          drivePath, label ?? 'Orbiit_Drive', progressCallback);

      if (success) {
        debugPrint('[ForgeProvider] Drive formatted successfully');
      } else {
        _error = 'Failed to format drive';
        debugPrint('[ForgeProvider] Failed to format drive');
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Format error: $e';
      debugPrint('[ForgeProvider] Format error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Deploy USB structure to drive
  Future<bool> deployUsbStructure(String drivePath) async {
    try {
      debugPrint('[ForgeProvider] Deploying USB structure to: $drivePath');

      final success = _forgeBridge.deployStructure(drivePath);

      if (success) {
        debugPrint('[ForgeProvider] USB structure deployed successfully');
      } else {
        _error = 'Failed to deploy USB structure';
        debugPrint('[ForgeProvider] Failed to deploy USB structure');
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Deploy error: $e';
      debugPrint('[ForgeProvider] Deploy error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Verify game hash against redump database
  Future<bool> verifyGameHash(String filePath, {String? expectedHash}) async {
    try {
      debugPrint('[ForgeProvider] Verifying game hash: $filePath');

      final success = _forgeBridge.verifyHash(filePath, expectedHash);

      if (success) {
        debugPrint('[ForgeProvider] Game hash verified successfully');
      } else {
        _error = 'Game hash verification failed';
        debugPrint('[ForgeProvider] Game hash verification failed');
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Hash verification error: $e';
      debugPrint('[ForgeProvider] Hash verification error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Handle a progress update (exposed for testability)
  @visibleForTesting
  void handleProgressUpdate(int status, double progress, String message) {
    _currentStatus =
        ForgeStatus.values[status.clamp(0, ForgeStatus.values.length - 1)];

    // update basic values
    final now = DateTime.now();

    // Try to extract byte counters from message if present
    final parsed = _parseBytesFromMessage(message);
    int? downloadedBytes = parsed?.downloaded;
    int? totalBytes = parsed?.total;

    // If we have bytes, compute bytes/sec using deltas and smoothing
    // BUFFER JITTER PROTECTION: Detect redundant updates from polling
    if (_lastProgressTimestamp != null) {
      final dt =
          now.difference(_lastProgressTimestamp!).inMilliseconds / 1000.0;

      // Check if this update has actual progress
      bool hasProgress = false;
      if (downloadedBytes != null && _lastDownloadedBytes != null) {
        if (downloadedBytes > _lastDownloadedBytes!) hasProgress = true;
      } else {
        if ((progress - _lastProgressValue).abs() > 0.000001)
          hasProgress = true;
      }

      // If no progress (redundant) and short duration (interleaved), SKIP speed calc
      // This prevents "zero speed" glitches when polling runs between isolate updates
      if (!hasProgress && dt < 2.0) {
        // Skip timestamp update to maintain correct dt for next real update
      } else {
        // Valid update (either progress made, or stall > 2s)

        // Calculate Percent Speed
        final clampedProgress = progress.clamp(0.0, 1.0);
        var dp = clampedProgress - _lastProgressValue;
        if (dp < 0) dp = 0;
        if (dt > 0) {
          _progressSpeed = dp / dt;
        }

        // Calculate Byte Speed
        if (downloadedBytes != null && _lastDownloadedBytes != null) {
          final deltaBytes = downloadedBytes - _lastDownloadedBytes!;
          // If delta is huge (restart) or negative, reset
          if (deltaBytes >= 0) {
            final newBps = dt > 0 ? deltaBytes / dt : 0.0;
            const alpha = 0.35;
            if (_downloadSpeedBps == null || _downloadSpeedBps == 0) {
              _downloadSpeedBps = newBps;
            } else {
              _downloadSpeedBps =
                  (_downloadSpeedBps! * (1 - alpha)) + (newBps * alpha);
            }
          }
        }

        // Only update timestamp for valid updates
        _lastProgressTimestamp = now;
      }
    } else {
      _lastProgressTimestamp = now;
    }

    // update last-knowns (use clamped progress)
    // _lastProgressTimestamp already updated above conditionally
    _lastProgressValue = progress.clamp(0.0, 1.0);
    if (downloadedBytes != null) _lastDownloadedBytes = downloadedBytes;
    if (totalBytes != null)
      _lastTotalBytes =
          totalBytes; // retain total for UI and ETA when available

    // compute ETA: prefer bytes/sec when available, otherwise use percent/sec
    _estimatedRemaining = null;
    if (_downloadSpeedBps != null &&
        downloadedBytes != null &&
        totalBytes != null &&
        _downloadSpeedBps! > 0) {
      final remaining = totalBytes - downloadedBytes;
      final secs = remaining / _downloadSpeedBps!;
      if (secs.isFinite && secs >= 0) {
        _estimatedRemaining = Duration(seconds: secs.round());
      }
    } else if (_progressSpeed > 1e-6) {
      final secs = (1.0 - _lastProgressValue) / _progressSpeed;
      if (secs.isFinite && secs >= 0)
        _estimatedRemaining = Duration(seconds: secs.round());
    }

    // set progress and status
    final oldProgress = _progress;
    final oldMessage = _statusMessage; // Capture old message for comparison
    _progress = progress.clamp(0.0, 1.0);
    _statusMessage = message;

    // ANTI-FLOODING: Only notify listeners if relevant state changed
    // We check progress, status, AND message to ensure UI updates for all events
    final progressDelta = (_progress - oldProgress).abs();
    final shouldNotify = progressDelta > 0.0 ||
        _statusMessage != oldMessage ||
        _currentStatus == ForgeStatus.ready ||
        _currentStatus == ForgeStatus.error;

    if (shouldNotify) {
      // Ensure formatted speed shows bytes/sec when known, otherwise show dash
      debugPrint(
          '[ForgeProvider] Progress: ${(_progress * 100).toInt()}% - $_statusMessage • speed=${formattedDownloadSpeed} • eta=${formattedEta}');

      notifyListeners();
    }

    // When mission completes or errors out, start next queued mission if present
    if (_currentStatus == ForgeStatus.ready ||
        _currentStatus == ForgeStatus.error) {
      // Delay to allow UI to update final state
      Future.microtask(() async {
        _isForging = false;
        final finishedGame = _currentGame;
        _currentMissionId = null;
        _currentGame = null;

        // reset speed/eta trackers for next mission
        _lastProgressTimestamp = null;
        _lastProgressValue = 0.0;
        _lastDownloadedBytes = null;
        _lastTotalBytes = null;
        _progressSpeed = 0.0;
        _downloadSpeedBps = null;
        _estimatedRemaining = null;

        debugPrint(
            '[ForgeProvider] Mission finished for: ${finishedGame?.title ?? 'UNKNOWN'}');
        notifyListeners();

        // Start next queued mission if any
        if (_downloadQueue.isNotEmpty) {
          final next = _downloadQueue.removeAt(0);
          debugPrint('[ForgeProvider] Dequeued next mission: ${next.title}');
          await _startForgeInternal(next);
        }
      });
    }
  }

  // Try to parse messages like '12.3 MB / 700 MB' or 'Downloaded 12.3 MB of 700 MB' or '123456789 / 987654321 bytes'
  _ParsedBytes? _parseBytesFromMessage(String msg) {
    // Quick key/value format parser: "downloaded=123 total=456"
    final kvRegex = RegExp(
        r'downloaded\s*[:=]\s*(\d+)\s*(?:[,;\s]+)?\s*total\s*[:=]\s*(\d+)',
        caseSensitive: false);
    final kvMatch = kvRegex.firstMatch(msg);
    if (kvMatch != null) {
      try {
        final downloaded = int.parse(kvMatch.group(1)!);
        final total = int.parse(kvMatch.group(2)!);
        return _ParsedBytes(downloaded: downloaded, total: total);
      } catch (_) {}
    }

    // First try: "X.XX MB / Y.YY GB" format
    final regex = RegExp(
        r'([0-9.,]+)\s*(B|KB|MB|GB)\s*(?:[\/\\]|of)\s*([0-9.,]+)\s*(B|KB|MB|GB)',
        caseSensitive: false);
    final m = regex.firstMatch(msg);
    if (m != null) {
      try {
        final a = double.parse(m.group(1)!.replaceAll(',', ''));
        final au = m.group(2)!.toUpperCase();
        final b = double.parse(m.group(3)!.replaceAll(',', ''));
        final bu = m.group(4)!.toUpperCase();

        final downloaded = (a * _unitMultiplier(au)).round();
        final total = (b * _unitMultiplier(bu)).round();
        return _ParsedBytes(downloaded: downloaded, total: total);
      } catch (_) {}
    }

    // Second try: "123456789 / 987654321 bytes" raw format
    final rawRegex =
        RegExp(r'(\d+)\s*[\/\\]\s*(\d+)\s*bytes?', caseSensitive: false);
    final rawMatch = rawRegex.firstMatch(msg);
    if (rawMatch != null) {
      try {
        final downloaded = int.parse(rawMatch.group(1)!);
        final total = int.parse(rawMatch.group(2)!);
        return _ParsedBytes(downloaded: downloaded, total: total);
      } catch (_) {}
    }

    // Third try: "Downloading... 123456789 bytes" (unknown total)
    final singleRegex = RegExp(r'(\d+)\s*bytes?', caseSensitive: false);
    final singleMatch = singleRegex.firstMatch(msg);
    if (singleMatch != null) {
      try {
        final downloaded = int.parse(singleMatch.group(1)!);
        return _ParsedBytes(downloaded: downloaded, total: null);
      } catch (_) {}
    }

    return null;
  }

  int _unitMultiplier(String u) {
    switch (u) {
      case 'B':
        return 1;
      case 'KB':
        return 1024;
      case 'MB':
        return 1024 * 1024;
      case 'GB':
        return 1024 * 1024 * 1024;
      default:
        return 1;
    }
  }

  String _formatBytesPerSecond(double bps) {
    if (bps >= 1024 * 1024)
      return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    if (bps >= 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${bps.toStringAsFixed(0)} B/s';
  }

  /// Remove a specific game from the queue
  bool removeFromQueue(GameResult game) {
    final before = _downloadQueue.length;
    _downloadQueue.removeWhere((g) =>
        (g.gameId != null && g.gameId == game.gameId) ||
        g.pageUrl == game.pageUrl);
    final removedAny = _downloadQueue.length != before;
    // Persist queue to disk
    unawaited(_saveQueueToDisk());
    notifyListeners();
    return removedAny;
  }

  /// Remove by index (used by UI Dismissible)
  void removeFromQueueAt(int index) {
    if (index < 0 || index >= _downloadQueue.length) return;
    final removed = _downloadQueue.removeAt(index);
    debugPrint('[ForgeProvider] Removed from queue: ${removed.title}');
    // Persist queue update
    unawaited(_saveQueueToDisk());
    notifyListeners();
  }

  /// Clear entire queue
  void clearQueue() {
    _downloadQueue.clear();
    unawaited(_saveQueueToDisk());
    notifyListeners();
  }

  /// Persist and load helpers
  Future<void> persistQueueNow() async => await _saveQueueToDisk();
  Future<void> loadQueueNow() async => await _loadQueueFromDisk();

  Future<String> _queueFilePath() async {
    if (_persistenceDir != null && _persistenceDir.isNotEmpty) {
      return p.join(_persistenceDir, 'wiigc_fusion_queue.json');
    }
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'wiigc_fusion_queue.json');
  }

  Future<void> _saveQueueToDisk() async {
    try {
      final path = await _queueFilePath();
      final file = File(path);
      await file.create(recursive: true);
      final json = jsonEncode(_downloadQueue.map((g) => g.toJson()).toList());
      await file.writeAsString(json);
      _lastQueueSavedAt = DateTime.now();
      // Also update settings file with lastSaved timestamp
      unawaited(_saveSettingsToDisk());
      debugPrint('[ForgeProvider] Queue persisted to disk: $path');
    } catch (e) {
      debugPrint('[ForgeProvider] Failed to persist queue: $e');
    }
  }

  Future<String> _settingsFilePath() async {
    if (_persistenceDir != null && _persistenceDir.isNotEmpty) {
      return p.join(_persistenceDir, 'wiigc_fusion_settings.json');
    }
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'wiigc_fusion_settings.json');
  }

  Future<void> _saveSettingsToDisk() async {
    try {
      final path = await _settingsFilePath();
      final file = File(path);
      await file.create(recursive: true);
      final map = {
        'autoStartPersistedQueue': _autoStartPersistedQueue,
        'allowResumeAtOffset': _allowResumeAtOffset,
        'lastQueueSavedAt': _lastQueueSavedAt?.toIso8601String(),
      };
      await file.writeAsString(jsonEncode(map));
      debugPrint('[ForgeProvider] Settings persisted to disk: $path');
    } catch (e) {
      debugPrint('[ForgeProvider] Failed to persist settings: $e');
    }
  }

  /// Public helper for tests
  Future<void> persistSettingsNow() async => await _saveSettingsToDisk();

  Future<void> _loadSettingsFromDisk() async {
    try {
      final path = await _settingsFilePath();
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      _autoStartPersistedQueue =
          map['autoStartPersistedQueue'] ?? _autoStartPersistedQueue;
      _allowResumeAtOffset = map['allowResumeAtOffset'] ?? _allowResumeAtOffset;
      if (map['lastQueueSavedAt'] != null) {
        _lastQueueSavedAt = DateTime.tryParse(map['lastQueueSavedAt']);
      }
      debugPrint('[ForgeProvider] Settings loaded from disk: $path');
    } catch (e) {
      debugPrint('[ForgeProvider] Failed to load settings: $e');
    }
  }

  Future<void> _loadQueueFromDisk() async {
    try {
      final path = await _queueFilePath();
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _downloadQueue.clear();
      for (final item in list) {
        _downloadQueue
            .add(GameResult.fromJson(Map<String, dynamic>.from(item)));
      }
      debugPrint(
          '[ForgeProvider] Loaded ${_downloadQueue.length} queued items from disk');
      notifyListeners();

      // If not currently forging, start next mission automatically (only if setting allows it)
      if (_autoStartPersistedQueue &&
          !_isForging &&
          _downloadQueue.isNotEmpty) {
        final next = _downloadQueue.removeAt(0);
        debugPrint(
            '[ForgeProvider] Auto-starting persisted mission: ${next.title}');
        unawaited(_startForgeInternal(next));
        // Persist changed queue
        unawaited(_saveQueueToDisk());
      }
    } catch (e) {
      debugPrint('[ForgeProvider] Failed to load queue from disk: $e');
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    debugPrint('[ForgeProvider] Disposing forge provider');
    _pollingTimer?.cancel();
    _forgeBridge.shutdown();
    super.dispose();
  }

  // --- POLLING FOR NATIVE DOWNLOAD PROGRESS ---

  /// Start polling the native library for download progress
  void _startProgressPolling() {
    // If the mission is running via pure Dart Isolate (which it now is),
    // we do NOT want to poll the native library as that would just waste CPU.
    // The Dart mission pushes updates via the callback mechanism automatically.

    // We only poll if using legacy native missions (ID < 10000)
    if (_currentMissionId != null && _currentMissionId! >= 10000) {
      debugPrint(
          '[ForgeProvider] Skipping native polling for Dart mission #$_currentMissionId');
      return;
    }

    _pollingTimer?.cancel();

    _pollingTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (_currentMissionId == null) {
        timer.cancel();
        return;
      }

      try {
        // Poll native library for progress
        final statusPtr = calloc<ffi.Int32>();
        final progressPtr = calloc<ffi.Float>();
        final messagePtr = calloc<ffi.Uint8>(256).cast<Utf8>();

        final success = _forgeBridge.getMissionProgress(
            _currentMissionId!, statusPtr, progressPtr, messagePtr, 256);

        if (!success) {
          debugPrint(
              '[ForgeProvider] Mission $_currentMissionId not found, stopping poll');
          _stopProgressPolling();
          calloc.free(statusPtr);
          calloc.free(progressPtr);
          calloc.free(messagePtr);
          return;
        }

        final status = statusPtr.value;
        final progress = progressPtr.value;
        final message = messagePtr.toDartString();

        calloc.free(statusPtr);
        calloc.free(progressPtr);
        calloc.free(messagePtr);

        // Update UI
        handleProgressUpdate(status, progress.toDouble(), message);

        // Stop polling if complete or error
        if (status >= 4) {
          // 4 = complete/ready
          timer.cancel();
          _pollingTimer = null;
        }
      } catch (e) {
        debugPrint('[ForgeProvider] Polling error: $e');
        timer.cancel();
        _pollingTimer = null;
      }
    });
  }

  /// Clean up resources
  void _stopProgressPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // --- XBOX-STYLE DOWNLOAD MANAGER SUPPORT ---

  /// Get active downloads for UI display
  List<ActiveDownload> getActiveDownloads() {
    final downloads = <ActiveDownload>[];

    // Add current download with full progress info
    if (_currentGame != null && _isForging) {
      downloads.add(ActiveDownload(
        gameId: _currentGame!.gameId ?? '',
        title: _currentGame!.title,
        platform: _currentGame!.platform,
        region: _currentGame!.region,
        downloadUrl: _currentGame!.downloadUrl ?? _currentGame!.pageUrl,
        coverUrl: _currentGame!.coverUrl,
        progress: _progress,
        speed: _formatSpeed(),
        size: _formatSize(),
        timeRemaining: _formatTimeRemaining(),
        status: status,
      ));
    }

    // Add queued downloads (no progress yet)
    for (final game in _downloadQueue) {
      downloads.add(ActiveDownload(
        gameId: game.gameId ?? '',
        title: game.title,
        platform: game.platform,
        region: game.region,
        downloadUrl: game.downloadUrl ?? game.pageUrl,
        coverUrl: game.coverUrl,
        status: 'queued',
      ));
    }

    return downloads;
  }

  /// Helper to format download speed for UI
  String _formatSpeed() {
    if (_downloadSpeedBps == null || _downloadSpeedBps! <= 0) {
      return '0 B/s';
    }
    return '${_formatBytesPerSecond(_downloadSpeedBps!.toDouble())}/s';
  }

  /// Helper to format total size for UI
  String _formatSize() {
    if (_lastTotalBytes == null || _lastTotalBytes! <= 0) {
      return '${_formatBytesPerSecond(_lastDownloadedBytes?.toDouble() ?? 0)} / Unknown';
    }
    return '${_formatBytesPerSecond(_lastDownloadedBytes?.toDouble() ?? 0)} / ${_formatBytesPerSecond(_lastTotalBytes!.toDouble())}';
  }

  /// Helper to format time remaining for UI
  String _formatTimeRemaining() {
    if (_estimatedRemaining == null) {
      return '--:--';
    }
    final totalSeconds = _estimatedRemaining!.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Clear completed downloads
  void clearCompletedDownloads() {
    // Remove completed items from queue (when status is ready, download is done)
    _downloadQueue.removeWhere((game) => _currentStatus == ForgeStatus.ready);
    notifyListeners();
  }

  /// Get status string for UI
  String get status {
    switch (_currentStatus) {
      case ForgeStatus.ready:
        return 'idle';
      case ForgeStatus.downloading:
        return 'downloading';
      case ForgeStatus.extracting:
        return 'extracting';
      case ForgeStatus.forging:
        return 'processing';
      case ForgeStatus.error:
        return 'error';
      case ForgeStatus.handshaking:
        return 'connecting';
      case ForgeStatus.paused:
        return 'paused';
    }
  }
}

// Small helper for parsed bytes
class _ParsedBytes {
  final int downloaded;
  final int? total;
  _ParsedBytes({required this.downloaded, this.total});
}

/// Model for active download (for UI)
class ActiveDownload {
  final String gameId;
  final String title;
  final String platform;
  final String region;
  final String downloadUrl;
  final String? coverUrl;
  final double progress;
  final String speed;
  final String size;
  final String timeRemaining;
  final String status;

  ActiveDownload({
    required this.gameId,
    required this.title,
    required this.platform,
    required this.region,
    required this.downloadUrl,
    this.coverUrl,
    this.progress = 0.0,
    this.speed = '0 B/s',
    this.size = 'Unknown',
    this.timeRemaining = '--:--',
    this.status = 'queued',
  });
}
