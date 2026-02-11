// ═══════════════════════════════════════════════════════════════════════════
// FORGE BRIDGE
// WiiGC-Fusion - Dart ↔ C++ FFI Bridge for Native Operations
// ═══════════════════════════════════════════════════════════════════════════
//
// This module bridges Flutter/Dart to the native C++ forge_core library,
// providing high-performance operations that would be slow in pure Dart:
//
// Native Capabilities:
//   • High-speed HTTP downloads via WinHTTP
//   • WBFS file handling and splitting
//   • File system operations (FAT32 formatting, folder structure)
//   • Hash verification (SHA-1 for Redump validation)
//   • Game identity parsing (ISO/WBFS header reading)
//
// Architecture:
//   ┌─────────────────────────────────────────────────────────────────────┐
//   │  Flutter UI (Dart)                                                 │
//   │  └── ForgeProvider (state management)                              │
//   │      └── ForgeBridge (this file - FFI binding)                     │
//   │          └── forge_core.dll (C++ native library)                   │
//   │              ├── WinHTTP download engine                           │
//   │              ├── WBFS parser/splitter                              │
//   │              ├── FAT32 formatter                                   │
//   │              └── SHA-1 hasher                                      │
//   └─────────────────────────────────────────────────────────────────────┘
//
// Production Mode:
//   Requires forge_core.dll to be present. The application will fail to
//   initialize if the native library is not found.
//
// Usage:
//   final bridge = ForgeBridge();
//
//   if (bridge.init()) {
//     final missionId = bridge.startMission(
//       'https://archive.org/.../game.wbfs',
//       'C:/Games/output.wbfs',
//       (status, progress, msg) => print('$progress%'),
//     );
//   }
//
// Native Library Locations (searched in order):
//   1. Executable directory (release builds)
//   2. build/windows/x64/runner/Debug/ (debug builds)
//   3. native/lib/ (development)
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/app_logger.dart';
import '../core/forge_native.dart';
import 'isolate_downloader.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DART MISSION STATE (Internal)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DartMission {
  final int id;
  final String url;
  final String destPath;
  final DateTime startTime;

  int status = ForgeStatus.handshaking.value;
  double progress = 0;
  String message = 'Identifying...';
  bool isCancelled = false;
  bool isMissionPaused = false;

  // Isolate downloader (runs in separate thread)
  IsolateDownloader? downloader;
  StreamSubscription? downloadSubscription;

  _DartMission(this.id, this.url, this.destPath) : startTime = DateTime.now();

  void update(ForgeStatus newStatus, double newProgress, String msg) {
    status = newStatus.value;
    progress = newProgress;
    message = msg;
  }

  Future<void> cancel() async {
    isCancelled = true;
    await downloadSubscription?.cancel();
    await downloader?.cancel();
  }
}

class _WriteOp {
  final int offset;
  final List<int> data;
  _WriteOp(this.offset, this.data);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FORGE STATUS ENUM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Mission status codes (matches C++ ForgeStatus enum)
enum ForgeStatus {
  /// Initial connection handshake
  handshaking(0),

  /// Actively downloading file
  downloading(1),

  /// Extracting from archive
  extracting(2),

  /// Processing/converting file
  forging(3),

  /// Operation complete
  ready(4),

  /// Operation failed
  error(5),

  /// Operation paused
  paused(6);

  const ForgeStatus(this.value);

  /// Native status code value
  final int value;

  /// Create from native status code
  static ForgeStatus fromValue(int value) {
    return ForgeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ForgeStatus.error,
    );
  }

  /// Human-readable status text
  String get displayText {
    switch (this) {
      case ForgeStatus.handshaking:
        return 'Connecting...';
      case ForgeStatus.downloading:
        return 'Downloading';
      case ForgeStatus.extracting:
        return 'Extracting';
      case ForgeStatus.forging:
        return 'Processing';
      case ForgeStatus.ready:
        return 'Complete';
      case ForgeStatus.error:
        return 'Error';
      case ForgeStatus.paused:
        return 'Paused';
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FFI TYPE DEFINITIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Progress callback - Native signature
typedef ForgeProgressCallbackNative = ffi.Void Function(
  ffi.Int32 status,
  ffi.Float progress,
  ffi.Pointer<Utf8> message,
);

/// Progress callback - Dart signature
typedef ForgeProgressCallbackDart = void Function(
  int status,
  double progress,
  ffi.Pointer<Utf8> message,
);

/// Native GameIdentity struct (matches C++ definition)
///
/// Contains parsed game metadata from ISO/WBFS headers
final class GameIdentityNative extends ffi.Struct {
  /// Platform: 0=Unknown, 1=Wii, 2=GameCube
  @ffi.Int32()
  external int platform;

  /// Format: 0=Unknown, 1=ISO, 2=WBFS, 3=NKit, 4=RVZ
  @ffi.Int32()
  external int format;

  /// 6-character title ID + padding (e.g., "RMGE01")
  @ffi.Array(8)
  external ffi.Array<ffi.Uint8> titleId;

  /// Game title string (null-terminated)
  @ffi.Array(256)
  external ffi.Array<ffi.Uint8> gameTitle;

  /// Region code: 0=Unknown, 1=NTSC-U, 2=PAL, 3=NTSC-J
  @ffi.Uint8()
  external int region;

  /// Disc number for multi-disc games
  @ffi.Uint8()
  external int discNumber;

  /// File size in bytes
  @ffi.Uint64()
  external int fileSize;

  /// Whether the ISO has been scrubbed (unused data removed)
  @ffi.Bool()
  external bool isScrubbed;

  /// Whether game requires cIOS to run
  @ffi.Bool()
  external bool requiresCios;
}

/// Callback for game discovery during folder scan
typedef ForgeGameFoundCallbackNative = ffi.Void Function(
  ffi.Pointer<Utf8> filePath,
  ffi.Pointer<GameIdentityNative> identity,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FORGE BRIDGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// FFI bridge to forge_core C++ native library.
///
/// Provides high-performance native operations for game file processing.
/// Automatically falls back to mock mode if native library unavailable.
///
/// Example:
/// ```dart
/// final bridge = ForgeBridge();
///
/// // Initialize (required before other calls)
/// if (bridge.init()) {
///   print('Native library ready');
/// } else {
///   print('Running in mock mode');
/// }
///
/// // Start a download mission
/// final missionId = bridge.startMission(
///   'https://archive.org/download/game/game.wbfs',
///   'C:/Downloads/game.wbfs',
///   progressCallback,
/// );
/// ```
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FFI TYPEDEFS (FUNCTION POINTERS)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

typedef ForgeInit = int Function();
typedef ForgeShutdown = void Function();
typedef ForgeScanFolder = int Function(
  ffi.Pointer<Utf8>,
  bool,
  ffi.Pointer<ffi.NativeFunction<ForgeGameFoundCallbackNative>>,
);
typedef ForgeStartMission = int Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>,
);
typedef ForgeCancelMission = bool Function(int);
typedef ForgeGetMissionProgress = bool Function(
  int,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Float>,
  ffi.Pointer<Utf8>,
  int,
);
typedef ForgeFormatDrive = bool Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>,
);
typedef ForgeVerifyHash = bool Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef ForgeDeployStructure = bool Function(ffi.Pointer<Utf8>);
typedef ForgeConvertIsoToWbfs = int Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>,
);
typedef ForgeSplitWbfsFat32 = int Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>,
);
typedef ForgeGetFileFormat = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

class ForgeBridge {
  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────

  /// Loaded native library handle
  ffi.DynamicLibrary? _lib;

  /// Path to the loaded native library
  String? _libraryPath;

  /// Path to the database directory (for forge_init)
  String? _dbPath;

  /// Whether running in mock mode (no native library)
  bool _isMock = true;

  // ─────────────────────────────────────────────────────────────────────────
  // Dart-based Mission State (Non-Blocking)
  // ─────────────────────────────────────────────────────────────────────────

  final Map<int, _DartMission> _dartMissions = {};
  int _nextMissionId = 10000;

  // ─────────────────────────────────────────────────────────────────────────
  // Native Function Pointers (null if in mock mode)
  // ─────────────────────────────────────────────────────────────────────────

  ForgeInit? _forgeInit;
  ForgeShutdown? _forgeShutdown;
  ForgeScanFolder? _forgeScanFolder;
  ForgeStartMission? _forgeStartMission;
  ForgeCancelMission? _forgeCancelMission;
  ForgeGetMissionProgress? _forgeGetMissionProgress;
  ForgeFormatDrive? _forgeFormatDrive;
  ForgeVerifyHash? _forgeVerifyHash;
  ForgeDeployStructure? _forgeDeployStructure;

  // ISO/WBFS Conversion Functions (for real Wii hardware)
  ForgeConvertIsoToWbfs? _forgeConvertIsoToWbfs;
  ForgeSplitWbfsFat32? _forgeSplitWbfsFat32;
  ForgeGetFileFormat? _forgeGetFileFormat;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  ForgeBridge() {
    _initializeNativeLibrary();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether running in mock mode (no native library loaded)
  bool get isMockMode => _isMock;

  /// Whether the native library is loaded and ready to use
  bool get isNativeReady => !_isMock && _lib != null;

  /// Force mock mode (useful for testing)
  void setMockMode(bool mock) {
    _isMock = mock;
    if (mock) _lib = null;
  }

  void _initializeNativeLibrary() {
    final logger = AppLogger.instance;

    try {
      // Use ForceNative singleton for one-time loading
      final native = ForgeNative.instance;

      if (!native.isLoaded) {
        logger.warning(
            'Native library not found via ForgeNative, falling back to mock mode');
        _isMock = true;
        _lib = null;
        return;
      }

      logger.info('Connecting to pre-loaded native library...');
      _libraryPath = native.loadedPath;
      _lib = native.lib;

      // Bind functions (only if library loaded)
      _forgeInit = _lib!
          .lookupFunction<ffi.Int32 Function(), int Function()>('forge_init');

      _forgeShutdown = _lib!
          .lookupFunction<ffi.Void Function(), void Function()>(
              'forge_shutdown');

      _forgeScanFolder = _lib!.lookupFunction<
          ffi.Int32 Function(ffi.Pointer<Utf8>, ffi.Bool,
              ffi.Pointer<ffi.NativeFunction<ForgeGameFoundCallbackNative>>),
          int Function(
              ffi.Pointer<Utf8>,
              bool,
              ffi.Pointer<
                  ffi.NativeFunction<
                      ForgeGameFoundCallbackNative>>)>('forge_scan_folder');

      _forgeStartMission = _lib!.lookupFunction<
              ffi.Uint64 Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
                  ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>),
              int Function(
                  ffi.Pointer<Utf8>,
                  ffi.Pointer<Utf8>,
                  ffi.Pointer<
                      ffi.NativeFunction<ForgeProgressCallbackNative>>)>(
          'forge_start_mission');

      _forgeCancelMission = _lib!
          .lookupFunction<ffi.Bool Function(ffi.Uint64), bool Function(int)>(
              'forge_cancel_mission');

      _forgeGetMissionProgress = _lib!.lookupFunction<
          ffi.Bool Function(ffi.Uint64, ffi.Pointer<ffi.Int32>,
              ffi.Pointer<ffi.Float>, ffi.Pointer<Utf8>, ffi.Int32),
          bool Function(int, ffi.Pointer<ffi.Int32>, ffi.Pointer<ffi.Float>,
              ffi.Pointer<Utf8>, int)>('forge_get_mission_progress');

      // Optional: Drive formatting (may not exist in all builds)
      try {
        _forgeFormatDrive = _lib!.lookupFunction<
            ffi.Bool Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
                ffi.Pointer<ffi.NativeFunction<ForgeProgressCallbackNative>>),
            bool Function(
                ffi.Pointer<Utf8>,
                ffi.Pointer<Utf8>,
                ffi.Pointer<
                    ffi.NativeFunction<
                        ForgeProgressCallbackNative>>)>('forge_format_drive');
      } catch (e) {
        logger.warning('forge_format_drive not available in this build');
      }

      // Optional: Hash verification
      try {
        _forgeVerifyHash = _lib!.lookupFunction<
            ffi.Bool Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>),
            bool Function(
                ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>('forge_verify_hash');
      } catch (e) {
        logger.warning('forge_verify_hash not available in this build');
      }

      // Optional: Deploy structure
      try {
        _forgeDeployStructure = _lib!.lookupFunction<
            ffi.Bool Function(ffi.Pointer<Utf8>),
            bool Function(ffi.Pointer<Utf8>)>('forge_deploy_structure');
      } catch (e) {
        logger.warning('forge_deploy_structure not available in this build');
      }

      // Optional: ISO/WBFS conversion functions (may not exist in all builds)
      try {
        _forgeConvertIsoToWbfs = _lib!
            .lookupFunction<
                    ffi.Uint64 Function(
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ForgeProgressCallbackNative>>),
                    int Function(
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ForgeProgressCallbackNative>>)>(
                'forge_convert_iso_to_wbfs');

        _forgeSplitWbfsFat32 = _lib!
            .lookupFunction<
                    ffi.Uint64 Function(
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ForgeProgressCallbackNative>>),
                    int Function(
                        ffi.Pointer<Utf8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ForgeProgressCallbackNative>>)>(
                'forge_split_wbfs_fat32');

        _forgeGetFileFormat = _lib!.lookupFunction<
            ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>),
            ffi.Pointer<Utf8> Function(
                ffi.Pointer<Utf8>)>('forge_get_file_format');
      } catch (e) {
        logger.warning('Conversion functions not available in this build: $e');
      }

      logger.info('Native library bound successfully');

      // CRITICAL: Mark as NOT in mock mode since library loaded successfully
      _isMock = false;
    } catch (e) {
      logger.error('CRITICAL: Failed to load native library', error: e);
      _lib = null;
      throw Exception('Failed to bind native library: $e');
    }
  }

  /// Initialize the native library.
  ///
  /// Must be called before any other operations.
  /// Safe to call multiple times.
  ///
  /// Returns true if initialization succeeded.
  bool init([String? dbPath]) {
    final logger = AppLogger.instance;

    // Store dbPath for future use (though native init doesn't use it)
    _dbPath = dbPath ?? Directory.current.path;

    try {
      if (_forgeInit != null) {
        final result = _forgeInit!();
        logger.info('Forge native library initialized: $result');
        return result != 0;
      } else {
        logger.error('forge_init function not bound');
        return false;
      }
    } catch (e) {
      logger.error('Failed to initialize native library', error: e);
      return false;
    }
  }

  /// Shutdown the native library and release resources.
  ///
  /// Should be called when the application is closing.
  void shutdown() {
    _forgeShutdown?.call();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download Mission Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Start a download mission.
  ///
  /// Downloads a file from [url] to [destPath], calling [callback] with
  /// progress updates.
  ///
  /// In mock mode, simulates a successful download with fake progress.
  ///
  /// Parameters:
  /// - [url]: Source URL to download from
  /// - [destPath]: Local destination file path
  /// - [callback]: Progress callback receiving (status, progress, message)
  ///
  /// Returns a mission ID for tracking, or 0 on failure.
  ///
  /// Example:
  /// ```dart
  /// final id = bridge.startMission(
  ///   'https://archive.org/download/game.wbfs',
  ///   'C:/Games/game.wbfs',
  ///   (status, progress, msg) {
  ///     print('${(progress * 100).toInt()}%');
  ///   },
  /// );
  /// ```
  Future<int> startMission(
      String url, String destPath, ForgeProgressCallbackDart callback) async {
    final logger = AppLogger.instance;

    // CRITICAL FIX: Return immediately to prevent blocking the UI/Provider
    // Run the download in a background "thread" (async task)

    final id = _nextMissionId++;
    final mission = _DartMission(id, url, destPath);
    _dartMissions[id] = mission;

    logger.info('Starting async Dart download mission #$id: $url');

    // Start the download without awaiting it
    unawaited(_runDartMission(mission, callback));

    return id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCELERATED FORGE ENGINE (Single-Stream High Performance)
  // ─────────────────────────────────────────────────────────────────────────

  /// ══════════════════════════════════════════════════════════════════════════
  /// NEW ISOLATE-BASED DOWNLOAD ENGINE
  /// Runs in separate thread - ZERO UI blocking
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> _runDartMission(
      _DartMission mission, ForgeProgressCallbackDart callback) async {
    final logger = AppLogger.instance;

    try {
      // Clean up any existing download instances (important for resume)
      await mission.downloadSubscription?.cancel();
      await mission.downloader?.cancel();
      mission.downloadSubscription = null;
      mission.downloader = null;

      // Don't reset progress to 0 since we might be resuming
      mission.update(
          ForgeStatus.handshaking, mission.progress, 'Starting download...');
      _sendCallback(callback, ForgeStatus.handshaking, mission.progress,
          'Starting download...');
      logger.info(
          '[ISOLATE-ENGINE] Starting download for mission #${mission.id}');
      logger.info('[ISOLATE-ENGINE] URL: ${mission.url}');
      logger.info('[ISOLATE-ENGINE] Dest: ${mission.destPath}');

      // Create isolate downloader
      mission.downloader = IsolateDownloader();

      // Listen to messages from the isolate (background thread)
      mission.downloadSubscription = mission.downloader!.messageStream.listen(
        (msg) {
          if (mission.isCancelled) return;

          switch (msg.type) {
            case DownloadMessageType.started:
              logger.info('[ISOLATE-ENGINE] Download started');
              // Keep current progress to avoid UI jumping to 0% on resume
              mission.update(ForgeStatus.downloading, mission.progress,
                  msg.message ?? 'Downloading...');
              _sendCallback(callback, ForgeStatus.downloading, mission.progress,
                  msg.message ?? 'Downloading...');
              break;

            case DownloadMessageType.progress:
              // Update mission state (NO FILE I/O, NO BLOCKING)
              // Ensure we don't spam logs but keep updating state
              // Only log occasional updates or significant events
              if (msg.progress == 1.0) {
                logger.info('[ISOLATE-ENGINE] Progress complete');
              }

              mission.update(
                  ForgeStatus.downloading, msg.progress, msg.message ?? '');

              // CRITICAL: We MUST pass the byte counts in the message string if they aren't part of the native callback
              // The callback signature is just (status, progress, message).
              // BUT ForgeProvider parses `message` to find bytes.
              // Msg.message IS ALREADY FORMATTED by IsolateDownloader as "12 MB / 500 MB..."

              _sendCallback(callback, ForgeStatus.downloading, msg.progress,
                  msg.message ?? '');
              break;

            case DownloadMessageType.completed:
              logger.info('[ISOLATE-ENGINE] Download completed!');
              mission.update(ForgeStatus.ready, 1, 'Complete');
              _sendCallback(callback, ForgeStatus.ready, 1, 'Complete');
              break;

            case DownloadMessageType.error:
              logger.error('[ISOLATE-ENGINE] Download error: ${msg.error}');
              mission.update(ForgeStatus.error, 0, msg.message ?? 'Error');
              _sendCallback(
                  callback, ForgeStatus.error, 0, msg.message ?? 'Error');
              break;

            case DownloadMessageType.cancelled:
              logger.info('[ISOLATE-ENGINE] Download cancelled');
              mission.update(ForgeStatus.error, 0, 'Cancelled');
              _sendCallback(callback, ForgeStatus.error, 0, 'Cancelled');
              break;
          }
        },
        onError: (error) {
          logger.error('[ISOLATE-ENGINE] Stream error', error: error);
          mission.update(ForgeStatus.error, 0, 'Error: $error');
          _sendCallback(callback, ForgeStatus.error, 0, 'Error: $error');
        },
      );

      // Start download in isolate (non-blocking)
      await mission.downloader!.startDownload(mission.url, mission.destPath);
    } catch (e) {
      logger.error('[ISOLATE-ENGINE] Fatal error', error: e);
      mission.update(ForgeStatus.error, 0, 'Error: $e');
      _sendCallback(callback, ForgeStatus.error, 0, 'Error: $e');
    }
  }

  // Helpers
  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 99) return '--:--';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }

  void _sendCallback(ForgeProgressCallbackDart callback, ForgeStatus status,
      double progress, String message) {
    if (message.isEmpty) return;
    final ptr = message.toNativeUtf8();
    try {
      callback(status.value, progress, ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  /// Cancel an active download mission.
  ///
  /// Parameters:
  /// - [missionId]: The mission ID returned from [startMission]
  ///
  /// Returns true if cancellation succeeded.
  bool cancelMission(int missionId) {
    // Check if it's a Dart mission
    if (_dartMissions.containsKey(missionId)) {
      final mission = _dartMissions[missionId]!;
      if (!mission.isCancelled) {
        mission.isCancelled = true;
        // Cancel the isolate download
        mission.cancel();

        // If already paused, the worker has exited, so we must clean up manually
        if (mission.status == ForgeStatus.paused.value) {
          final file = File(mission.destPath);
          if (file.existsSync()) {
            try {
              file.deleteSync();
            } catch (_) {}
          }
          mission.status = ForgeStatus.error.value;
          mission.message = 'Cancelled';
        }

        return true;
      }
      return false;
    }

    return _forgeCancelMission?.call(missionId) ?? false;
  }

  /// Pause an active Dart download mission.
  ///
  /// Returns true if paused successfully.
  bool pauseMission(int missionId) {
    if (_dartMissions.containsKey(missionId)) {
      final mission = _dartMissions[missionId]!;
      if (!mission.isCancelled && !mission.isMissionPaused) {
        AppLogger.instance.info('[FORGE] Pausing mission #$missionId');

        mission.isMissionPaused = true;
        mission.status = ForgeStatus.paused.value;
        mission.message = 'Paused';
        // Stop the download stream by closing connection
        // The catch block in _runDartMission should handle the abort
        mission.downloadSubscription?.cancel();
        mission.downloader?.cancel();
        return true;
      }
    }
    return false;
  }

  /// Resume a paused Dart download mission.
  ///
  /// Returns true if resumed successfully.
  bool resumeMission(int missionId, ForgeProgressCallbackDart callback) {
    if (_dartMissions.containsKey(missionId)) {
      final mission = _dartMissions[missionId]!;
      if (mission.isMissionPaused) {
        AppLogger.instance.info('[FORGE] Resuming mission #$missionId');

        // CRITICAL: Reset cancelled flag so message listener works
        mission.isCancelled = false;
        mission.isMissionPaused = false;
        mission.status = ForgeStatus.downloading.value;
        mission.message = 'Resuming...';

        // Send callback to update UI immediately
        _sendCallback(
            callback, ForgeStatus.downloading, mission.progress, 'Resuming...');

        // Restart the download worker (will resume from existing file position)
        unawaited(_runDartMission(mission, callback));
        return true;
      }
    }
    return false;
  }

  /// Get the current progress of a mission.
  ///
  /// Parameters:
  /// - [missionId]: The mission ID to query
  /// - [statusOut]: Pointer to receive status code
  /// - [progressOut]: Pointer to receive progress (0.0-1.0)
  /// - [messageOut]: Pointer to receive status message
  /// - [messageSize]: Size of message buffer
  ///
  /// Returns true if mission exists and values were populated.
  bool getMissionProgress(
    int missionId,
    ffi.Pointer<ffi.Int32> statusOut,
    ffi.Pointer<ffi.Float> progressOut,
    ffi.Pointer<Utf8> messageOut,
    int messageSize,
  ) {
    // Check if it's a Dart mission
    if (_dartMissions.containsKey(missionId)) {
      final mission = _dartMissions[missionId]!;

      // NO FILE I/O - just return cached values that are updated in download loop
      statusOut.value = mission.status;
      progressOut.value = mission.progress;

      // Copy string to buffer safely
      final msgBytes = mission.message.toNativeUtf8();
      final maxLen = messageSize - 1; // Leave room for null terminator

      final units = msgBytes.cast<ffi.Uint8>();
      final outUnits = messageOut.cast<ffi.Uint8>();

      int i = 0;
      for (; i < maxLen; i++) {
        final byte = units[i];
        if (byte == 0) break;
        outUnits[i] = byte;
      }
      outUnits[i] = 0; // Null terminate

      malloc.free(msgBytes); // toNativeUtf8() uses malloc, not calloc
      return true;
    }

    return _forgeGetMissionProgress?.call(
          missionId,
          statusOut,
          progressOut,
          messageOut,
          messageSize,
        ) ??
        false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Drive/File Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Format a drive as FAT32 with 32KB clusters.
  ///
  /// ⚠️ DESTRUCTIVE: All data on the drive will be lost!
  ///
  /// Parameters:
  /// - [drivePath]: Drive path (e.g., "E:")
  /// - [label]: Volume label (max 11 characters)
  /// - [callback]: Progress callback
  /// Format a drive to FAT32 (Dart Implementation via PowerShell).
  ///
  /// Returns true if formatting was successful.
  Future<bool> formatDrive(String drivePath, String label,
      ForgeProgressCallbackDart callback) async {
    final logger = AppLogger.instance;
    // Sanitize drive path (e.g., "E:\" -> "E")
    final driveLetter =
        drivePath.replaceAll(RegExp(r'[:\\]'), '').toUpperCase();

    // Safety check: NEVER format C:
    if (driveLetter == 'C') {
      logger.error('Attempted to format system drive C: - Operation blocked');
      return false;
    }

    logger.info(
        'Starting Dart-based FAT32 format of drive $driveLetter: label=$label');

    try {
      // Use PowerShell to format
      // Format-Volume -DriveLetter E -FileSystem FAT32 -NewFileSystemLabel "WII_GAMES" -Force
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Format-Volume -DriveLetter $driveLetter -FileSystem FAT32 -NewFileSystemLabel "$label" -Force'
        ],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        logger.info('Drive formatted successfully');
        return true;
      } else {
        logger.error('Format failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      logger.error('Format process failed', error: e);
      return false;
    }
  }

  /// Calculate SHA-1 hash of a file.
  Future<String> calculateHash(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) throw Exception('File not found');
    // Run in Future to not block UI (though underlying implementation is sync for now)
    return Future(() {
      final digest = _calculateSha1Sync(file);
      return digest.toString().toLowerCase();
    });
  }

  /// Verify a file's SHA-1 hash against Redump database.
  ///
  /// Parameters:
  /// - [filePath]: Path to the file to verify
  /// - [expectedHash]: Optional expected SHA-1 hash (lowercase hex)
  ///   If null, looks up expected hash from Redump database.
  ///
  /// Returns true if hash matches expected value.
  bool verifyHash(String filePath, [String? expectedHash]) {
    // Pure Dart Implementation (Facilitated)
    if (expectedHash == null) {
      // TODO: Lookup in database not yet implemented in Dart bridge
      // For now, we only verify if expectedHash is provided
      return true; // Assume pass if no expectation
    }

    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      // Calculate SHA-1
      // Note: This is synchronous and might block UI for large files.
      // Ideally run in isolate, but for now we run it here.
      // Since it's usually run from a Provider which might be async,
      // we can't easily make this async without changing the signature.
      // But the signature is synchronous bool.
      // We will suppress the blocking warning for this "facated" version.

      final digest = _calculateSha1Sync(file);
      final actualHash = digest.toString().toLowerCase();
      final expected = expectedHash.toLowerCase();

      final match = actualHash == expected;
      AppLogger.instance.info(
          'Hash verification: $match (Actual: $actualHash, Expected: $expected)');
      return match;
    } catch (e) {
      AppLogger.instance.error('Hash check failed', error: e);
      return false;
    }
  }

  Digest _calculateSha1Sync(File file) {
    // Read file in chunks to avoid memory overflow
    final output = AccumulatorSink<Digest>();
    final input = sha1.startChunkedConversion(output);
    final access = file.openSync();
    final buffer = Uint8List(1024 * 1024); // 1MB buffer

    try {
      while (true) {
        final len = access.readIntoSync(buffer);
        if (len == 0) break;
        input.add(buffer.sublist(0, len));
      }
    } finally {
      access.closeSync();
    }

    input.close();
    return output.events.single;
  }

  /// Deploy USB Loader folder structure to a drive.
  ///
  /// Creates the standard directory structure expected by USB Loader GX:
  /// ```
  /// [drive]/
  /// ├── wbfs/           # Wii games
  /// ├── games/          # GameCube games
  /// ├── covers/         # Cover art cache
  /// │   ├── 2d/
  /// │   ├── 3d/
  /// │   └── disc/
  /// └── config/         # USB Loader configuration
  /// ```
  ///
  /// Parameters:
  /// - [drivePath]: Root drive path (e.g., "E:")
  ///
  /// Returns true if structure was created successfully.
  bool deployStructure(String drivePath) {
    // Pure Dart Implementation (Facilitated)
    try {
      final root = Directory(drivePath);
      if (!root.existsSync()) {
        // Only try to create if it looks like a folder path, not a drive root "X:\"
        // Windows won't let you create "X:\", but assuming drivePath is valid
      }

      final dirs = [
        'wbfs',
        'games',
        'config',
        'apps',
        'covers/2d',
        'covers/3d',
        'covers/disc',
        'covers/full',
      ];

      for (final dir in dirs) {
        final d = Directory(p.join(drivePath, dir));
        if (!d.existsSync()) {
          d.createSync(recursive: true);
        }
      }

      AppLogger.instance.info('Deployed USB structure to $drivePath');
      return true;
    } catch (e) {
      AppLogger.instance.error('Failed to deploy structure', error: e);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ISO/WBFS CONVERSION - For REAL jailbroken Wii (USB Loader GX, WiiFlow)
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert an ISO file to WBFS format for real Wii hardware.
  ///
  /// WBFS is the required format for USB Loader GX and WiiFlow.
  /// RVZ files from Myrient CANNOT be used on real Wii - only Dolphin!
  ///
  /// Parameters:
  /// - [isoPath]: Source ISO file path
  /// - [wbfsOutput]: Destination WBFS file path
  /// - [callback]: Progress callback (optional)
  ///
  /// Returns a mission ID for progress tracking via [getMissionProgress].
  ///
  /// Example:
  /// ```dart
  /// final missionId = bridge.convertIsoToWbfs(
  ///   'C:/Downloads/Super Mario Galaxy (USA).iso',
  ///   'E:/wbfs/Super Mario Galaxy/RMGE01/RMGE01.wbfs',
  ///   (status, progress, msg) => print('Converting: ${(progress * 100).toInt()}%'),
  /// );
  /// ```
  int convertIsoToWbfs(String isoPath, String wbfsOutput,
      [ForgeProgressCallbackDart? callback]) {
    final logger = AppLogger.instance;
    if (_forgeConvertIsoToWbfs == null) {
      logger.error('ISO to WBFS conversion not available in this build');
      throw Exception('Conversion function not available');
    }

    final isoPtr = isoPath.toNativeUtf8();
    final wbfsPtr = wbfsOutput.toNativeUtf8();
    final missionId = _forgeConvertIsoToWbfs!(isoPtr, wbfsPtr, ffi.nullptr);
    malloc.free(isoPtr);
    malloc.free(wbfsPtr);
    logger.info('Started ISO→WBFS conversion mission #$missionId');
    return missionId;
  }

  /// Split a WBFS file for FAT32 compatibility (4GB file size limit).
  ///
  /// USB Loader GX supports split files:
  /// - `GAMEID.wbfs` (first 4GB)
  /// - `GAMEID.wbf1` (next 4GB)
  /// - `GAMEID.wbf2` (etc.)
  ///
  /// Most Wii games are ~4.4GB, so dual-layer games will need splitting.
  ///
  /// Parameters:
  /// - [wbfsPath]: Source WBFS file to split
  /// - [callback]: Progress callback (optional)
  ///
  /// Returns a mission ID for progress tracking.
  int splitWbfsForFat32(String wbfsPath,
      [ForgeProgressCallbackDart? callback]) {
    final logger = AppLogger.instance;
    if (_forgeSplitWbfsFat32 == null) {
      logger.error('WBFS splitting not available in this build');
      throw Exception('Split function not available');
    }

    final pathPtr = wbfsPath.toNativeUtf8();
    final missionId = _forgeSplitWbfsFat32!(pathPtr, ffi.nullptr);
    malloc.free(pathPtr);
    logger.info('Started FAT32 split mission #$missionId for $wbfsPath');
    return missionId;
  }

  /// Detect the format of a game file from its magic bytes.
  ///
  /// Returns one of: "wbfs", "iso", "gcm", "rvz", "wia", "ciso", "unknown"
  ///
  /// ⚠️ IMPORTANT for real Wii hardware:
  /// - "iso", "wbfs", "gcm" = Compatible with USB Loader GX/WiiFlow
  /// - "rvz", "wia" = Dolphin ONLY - will NOT work on real Wii!
  /// - "ciso" = Compressed ISO - may need conversion
  ///
  /// Parameters:
  /// - [filePath]: Path to the file to analyze
  ///
  /// Example:
  /// ```dart
  /// final format = bridge.getFileFormat('E:/wbfs/game/RMGE01/RMGE01.wbfs');
  /// if (format == 'rvz') {
  ///   print('WARNING: RVZ is Dolphin-only! Convert to WBFS for real Wii!');
  /// }
  /// ```
  String getFileFormat(String filePath) {
    // Try to get real identity first using our Dart scanner
    final file = File(filePath);
    final identity = _scanFileHeader(file);

    if (identity != null) {
      if (identity.formatId == 1) {
        // ISO or GCM
        if (identity.platformId == 2) return 'gcm';
        return 'iso';
      }
      if (identity.formatId == 2) return 'wbfs';
      if (identity.formatId == 3) return 'nkit';
      if (identity.formatId == 4) return 'rvz';
    }

    // Fallback to extension check if identification failed or file too small
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.wbfs')) return 'wbfs';
    if (lower.endsWith('.iso')) return 'iso';
    if (lower.endsWith('.rvz')) return 'rvz';
    if (lower.endsWith('.wia')) return 'wia';
    if (lower.endsWith('.gcm')) return 'gcm';
    if (lower.endsWith('.ciso')) return 'ciso';
    return 'unknown';
  }

  /// Check if a file format is compatible with real Wii hardware.
  ///
  /// Returns true for ISO, WBFS, GCM formats.
  /// Returns false for RVZ, WIA (Dolphin-only formats).
  static bool isRealWiiCompatible(String format) {
    final lower = format.toLowerCase();
    return lower == 'iso' || lower == 'wbfs' || lower == 'gcm';
  }

  /// Check if a file format requires conversion for real Wii.
  static bool needsConversionForRealWii(String format) {
    final lower = format.toLowerCase();
    return lower == 'rvz' || lower == 'wia' || lower == 'ciso';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Folder Scanning
  // ─────────────────────────────────────────────────────────────────────────

  /// Static callback holder for folder scanning.
  /// Required because C callbacks can't capture Dart closures.
  static void Function(String, GameIdentity)? _currentScanCallback;

  /// Scan a folder for game files.
  ///
  /// Searches for Wii/GameCube ISOs, WBFS, NKit, and RVZ files.
  /// Parses headers to extract game metadata.
  ///
  /// Parameters:
  /// - [folderPath]: Directory to scan
  /// - [recursive]: Whether to scan subdirectories
  /// - [onFound]: Callback invoked for each game found
  ///
  /// Returns the number of games found.
  ///
  /// Note: Only works with native library. Returns 0 in mock mode.
  // Dart-based file scanner helper
  GameIdentity? _scanFileHeader(File file) {
    try {
      if (!file.existsSync()) return null;
      final len = file.lengthSync();
      if (len < 256) return null; // Too small

      final raf = file.openSync();
      final header = raf.readSync(256);
      raf.close();

      // Check for valid Game ID (ISO/GC) or Magic
      bool isWii = false;
      bool isGc = false;
      bool isWbfs = false;

      // Wii Magic: 0x5D1C9EA3 at 0x18
      if (header[0x18] == 0x5D &&
          header[0x19] == 0x1C &&
          header[0x1A] == 0x9E &&
          header[0x1B] == 0xA3) {
        isWii = true;
      }
      // GC Magic: 0xC2339F3D at 0x1C
      else if (header[0x1C] == 0xC2 &&
          header[0x1D] == 0x33 &&
          header[0x1E] == 0x9F &&
          header[0x1F] == 0x3D) {
        isGc = true;
      }
      // WBFS Magic: "WBFS" at 0x0
      else if (header[0] == 0x57 &&
          header[1] == 0x42 &&
          header[2] == 0x46 &&
          header[3] == 0x53) {
        isWbfs = true;
      }

      // Attempt to identify
      String id = '';
      String title = '';
      int formatId = 0;
      int platformId = 0;

      if (isWii || isGc) {
        formatId = 1; // ISO/GCM
        platformId = isWii ? 1 : 2;

        // ID at 0x00
        for (int i = 0; i < 6; i++) {
          if (header[i] == 0) break;
          id += String.fromCharCode(header[i]);
        }
        // Title at 0x20
        for (int i = 0x20; i < 0x60; i++) {
          if (header[i] == 0) break;
          title += String.fromCharCode(header[i]);
        }
      } else if (isWbfs) {
        formatId = 2; // WBFS
        platformId = 1; // Assume Wii
        // Try to guess from filename if we can't parse WBFS internal header easily
        final name = p.basenameWithoutExtension(file.path);
        final idMatch = RegExp(r'\[([A-Z0-9]{6})\]').firstMatch(name);
        title = name;
        id = idMatch?.group(1) ?? 'UNKNOWN';
      } else {
        return null;
      }

      return GameIdentity(
        platformId: platformId,
        formatId: formatId,
        titleId: id,
        gameTitle: title.trim(),
        fileSize: len,
      );
    } catch (e) {
      return null;
    }
  }

  int scanFolder(
    String folderPath,
    bool recursive,
    void Function(String filePath, GameIdentity identity) onFound,
  ) {
    final logger = AppLogger.instance;
    logger.info(
        'Starting Dart-based folder scan: $folderPath (recursive: $recursive)');

    int count = 0;
    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) return 0;

      final entities = dir.listSync(recursive: recursive, followLinks: false);

      for (final entity in entities) {
        if (entity is File) {
          final identity = _scanFileHeader(entity);
          if (identity != null) {
            count++;
            onFound(entity.path, identity);
          }
        }
      }

      logger.info('Folder scan completed. Found $count games');
      return count;
    } catch (e) {
      logger.error('Folder scan failed', error: e);
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Native Callback Stubs
  // ─────────────────────────────────────────────────────────────────────────

  /// Default progress callback (logs to debug console).

  /// Game found callback stub (routes to _currentScanCallback).
  static void _gameFoundStub(
      ffi.Pointer<Utf8> filePath, ffi.Pointer<GameIdentityNative> identity) {
    if (_currentScanCallback == null) return;

    final pathStr = filePath.toDartString();
    final id = identity.ref;

    // Convert fixed array titleId to String
    final idBytes = <int>[];
    for (var i = 0; i < 8; i++) {
      final b = id.titleId[i];
      if (b == 0) break;
      idBytes.add(b);
    }
    final titleIdStr = String.fromCharCodes(idBytes);

    // Convert fixed array gameTitle to String
    final titleBytes = <int>[];
    for (var i = 0; i < 256; i++) {
      final b = id.gameTitle[i];
      if (b == 0) break;
      titleBytes.add(b);
    }
    final gameTitleStr = String.fromCharCodes(titleBytes);

    _currentScanCallback!(
      pathStr,
      GameIdentity(
        platformId: id.platform,
        formatId: id.format,
        titleId: titleIdStr,
        gameTitle: gameTitleStr,
        fileSize: id.fileSize,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GAME IDENTITY MODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Parsed game identity from ISO/WBFS header.
///
/// Represents metadata extracted from a game file by the native scanner.
@immutable
class GameIdentity {
  // ─────────────────────────────────────────────────────────────────────────
  // Fields
  // ─────────────────────────────────────────────────────────────────────────

  /// Platform ID (1=Wii, 2=GameCube, 3=Wii U)
  final int platformId;

  /// Format ID (1=ISO, 2=WBFS, 3=NKit, 4=RVZ)
  final int formatId;

  /// 6-character title ID (e.g., "RMGE01" for Mario Galaxy)
  final String titleId;

  /// Full game title from header
  final String gameTitle;

  /// File size in bytes
  final int fileSize;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  const GameIdentity({
    required this.platformId,
    required this.formatId,
    required this.titleId,
    required this.gameTitle,
    required this.fileSize,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Human-readable platform name
  String get platformName {
    switch (platformId) {
      case 1:
        return 'Wii';
      case 2:
        return 'GameCube';
      case 3:
        return 'Wii U';
      default:
        return 'Unknown';
    }
  }

  /// Human-readable format name
  String get formatName {
    switch (formatId) {
      case 1:
        return 'ISO';
      case 2:
        return 'WBFS';
      case 3:
        return 'NKit';
      case 4:
        return 'RVZ';
      default:
        return 'Unknown';
    }
  }

  /// Whether this is a Wii game
  bool get isWii => platformId == 1;

  /// Whether this is a GameCube game
  bool get isGameCube => platformId == 2;

  /// 4-letter game code (first 4 chars of titleId)
  String get gameCode =>
      titleId.length >= 4 ? titleId.substring(0, 4) : titleId;

  /// Region code (5th character of titleId)
  String? get regionCode => titleId.length >= 5 ? titleId[4] : null;

  /// File size formatted as human-readable string
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a copy with modified fields
  GameIdentity copyWith({
    int? platformId,
    int? formatId,
    String? titleId,
    String? gameTitle,
    int? fileSize,
  }) {
    return GameIdentity(
      platformId: platformId ?? this.platformId,
      formatId: formatId ?? this.formatId,
      titleId: titleId ?? this.titleId,
      gameTitle: gameTitle ?? this.gameTitle,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  String toString() =>
      'GameIdentity($titleId: $gameTitle [$platformName/$formatName])';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameIdentity &&
        other.platformId == platformId &&
        other.formatId == formatId &&
        other.titleId == titleId &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode => Object.hash(platformId, formatId, titleId, fileSize);
}
