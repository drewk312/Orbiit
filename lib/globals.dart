// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL INSTANCES
// WiiGC-Fusion - Shared singleton services and state
// ═══════════════════════════════════════════════════════════════════════════
//
// This file provides global access to shared service instances.
// Using singletons for services that maintain state across the app.
//
// Note: Consider using Provider/Riverpod for dependency injection in
// production apps. Global instances are used here for simplicity.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'services/download_service.dart';
import 'services/unified_search_service.dart';
import 'services/cover_art/cover_art_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GLOBAL SERVICE INSTANCES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Global download service for managing game downloads
final DownloadService globalDownloadService = DownloadService();

/// Global search service for finding ROMs across sources
final UnifiedSearchService globalSearchService = UnifiedSearchService();

/// Global cover art service for fetching game covers
final CoverArtService globalCoverArtService = CoverArtService();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// APP LOGGER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Simple logging utility with level filtering
class AppLogger {
  /// Current log level
  static LogLevel level = LogLevel.info;

  /// Log file path (set during initialization)
  static String? logFilePath;

  /// Initialize logging with file output
  static Future<void> initialize({String? path}) async {
    logFilePath = path;
    if (path != null) {
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString(
        '=== WiiGC-Fusion Log Started ${DateTime.now()} ===\n',
        mode: FileMode.append,
      );
    }
  }

  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message,
      [String? tag, Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message, tag);
    if (error != null) _log(LogLevel.error, '  Error: $error', tag);
    if (stack != null) _log(LogLevel.error, '  Stack: $stack', tag);
  }

  static void _log(LogLevel logLevel, String message, String? tag) {
    if (logLevel.index < level.index) return;

    final prefix = tag != null ? '[$tag] ' : '';
    final levelStr = logLevel.name.toUpperCase().padRight(7);
    final timestamp = DateTime.now().toString().substring(11, 23);
    final formattedMessage = '$timestamp $levelStr $prefix$message';

    // Console output
    print(formattedMessage);

    // File output (async, fire-and-forget)
    if (logFilePath != null) {
      File(logFilePath!)
          .writeAsString(
            '$formattedMessage\n',
            mode: FileMode.append,
          )
          .then((_) {}, onError: (_) {}); // Fire and forget, ignore errors
    }
  }
}

/// Log level enumeration
enum LogLevel {
  debug,
  info,
  warning,
  error,
  none, // Disable all logging
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INITIALIZATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Initialize all global services
///
/// Call this at app startup before accessing services:
/// ```dart
/// void main() async {
///   await initializeGlobalServices();
///   runApp(MyApp());
/// }
/// ```
Future<void> initializeGlobalServices() async {
  AppLogger.info('Initializing global services...', 'App');

  try {
    await globalCoverArtService.initialize();
    AppLogger.info('Cover art service initialized', 'App');
  } catch (e) {
    AppLogger.error('Failed to initialize cover art service', 'App', e);
  }

  AppLogger.info('Global services ready', 'App');
}

/// Cleanup all global services
///
/// Call this at app shutdown:
/// ```dart
/// // In your main widget
/// @override
/// void dispose() {
///   disposeGlobalServices();
///   super.dispose();
/// }
/// ```
void disposeGlobalServices() {
  AppLogger.info('Disposing global services...', 'App');
  globalDownloadService.dispose();
  globalCoverArtService.dispose();
  AppLogger.info('Global services disposed', 'App');
}
