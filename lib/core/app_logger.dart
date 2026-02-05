// ═══════════════════════════════════════════════════════════════════════════
// APP LOGGER
// WiiGC-Fusion - Structured logging with file persistence
// ═══════════════════════════════════════════════════════════════════════════
//
// This logger provides:
//   • Console output in debug mode
//   • File persistence for troubleshooting
//   • Log level filtering
//   • Component tagging for filtering
//   • Automatic log rotation
//
// Log Levels (ascending severity):
//   DEBUG   - Detailed diagnostic info, only in development
//   INFO    - General operational messages
//   WARNING - Potential issues that don't prevent operation
//   ERROR   - Failures that need attention
//
// Usage:
//   await AppLogger.instance.initialize();
//
//   AppLogger.instance.info('Application started');
//   AppLogger.instance.debug('Parsed 5 games', component: 'Scanner');
//   AppLogger.instance.error('Download failed', error: e, component: 'Forge');
//
// Log Files Location:
//   Documents/WiiGCFusion/logs/app_2024-01-15T10-30-00.log
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LOG LEVEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Log severity levels
enum LogLevel {
  /// Detailed diagnostic information
  debug,

  /// General operational messages
  info,

  /// Potential issues
  warning,

  /// Errors requiring attention
  error,
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Logger configuration
abstract class _Config {
  /// Minimum log level to record (debug in dev, info in release)
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Maximum log file age before rotation (days)
  static const int maxLogAgeDays = 7;

  /// Maximum number of log files to keep
  static const int maxLogFiles = 10;

  /// Log directory name
  static const String logDirName = 'logs';

  /// App name for log directory
  static const String appDirName = 'WiiGCFusion';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// APP LOGGER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Singleton logger with file persistence.
///
/// Initialize at app startup:
/// ```dart
/// void main() async {
///   await AppLogger.instance.initialize();
///   AppLogger.instance.info('App starting...');
///   runApp(MyApp());
/// }
/// ```
class AppLogger {
  // ─────────────────────────────────────────────────────────────────────────
  // Singleton
  // ─────────────────────────────────────────────────────────────────────────

  static AppLogger? _instance;

  /// Get the singleton logger instance
  static AppLogger get instance => _instance ??= AppLogger._();

  AppLogger._();

  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────

  /// Current log file
  File? _logFile;

  /// Whether logger has been initialized
  bool _initialized = false;

  /// Log buffer for batched writes
  final List<String> _buffer = [];

  /// Debounce timer for file writes
  Timer? _writeTimer;

  /// Whether logger is initialized
  bool get isInitialized => _initialized;

  /// Current log file path
  String? get logFilePath => _logFile?.path;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize the logger.
  ///
  /// Creates log directory and file, performs log rotation.
  /// Safe to call multiple times (idempotent).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(
        path.join(docsDir.path, _Config.appDirName, _Config.logDirName),
      );

      // Create log directory
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Rotate old logs
      await _rotateOldLogs(logDir);

      // Create new log file with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      _logFile = File(path.join(logDir.path, 'app_$timestamp.log'));

      // Write header
      await _logFile!.writeAsString(
        '═══════════════════════════════════════════════════════════════\n'
        ' Orbiit Log\n'
        ' Started: ${DateTime.now()}\n'
        ' Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
        '═══════════════════════════════════════════════════════════════\n\n',
      );

      _initialized = true;
      log('Logger initialized at ${_logFile!.path}', level: LogLevel.info);
    } catch (e) {
      debugPrint('[AppLogger] Failed to initialize: $e');
      // Logger can still work without file output
      _initialized = true;
    }
  }

  /// Remove old log files beyond retention policy
  Future<void> _rotateOldLogs(Directory logDir) async {
    try {
      final files = await logDir
          .list()
          .where((e) => e is File && e.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final now = DateTime.now();

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final age = now.difference(file.statSync().modified);

        // Delete if too old or too many files
        if (age.inDays > _Config.maxLogAgeDays || i >= _Config.maxLogFiles) {
          await file.delete();
          debugPrint(
              '[AppLogger] Deleted old log: ${path.basename(file.path)}');
        }
      }
    } catch (e) {
      debugPrint('[AppLogger] Log rotation failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logging Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Core logging method.
  ///
  /// Writes to console and file with timestamp, level, and optional component.
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? component,
  }) {
    // Skip if below minimum level
    if (level.index < _Config.minLevel.index) return;

    // Format message
    final timestamp = _formatTimestamp(DateTime.now());
    final levelStr = level.name.toUpperCase().padRight(7);
    final componentStr = component != null ? '[$component] ' : '';
    final logMessage = '$timestamp $levelStr $componentStr$message';

    // Always print to debug console
    debugPrint(logMessage);

    // Buffer for file write
    if (_logFile != null) {
      _buffer.add('$logMessage\n');
      _scheduleFileWrite();
    }
  }

  /// Schedule debounced file write
  void _scheduleFileWrite() {
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 100), _flushBuffer);
  }

  /// Flush buffer to file
  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty || _logFile == null) return;

    try {
      final content = _buffer.join();
      _buffer.clear();
      await _logFile!.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      debugPrint('[AppLogger] Write failed: $e');
    }
  }

  /// Format timestamp for log output
  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}.'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Log debug message (only in development)
  void debug(String message, {String? component}) =>
      log(message, level: LogLevel.debug, component: component);

  /// Log info message
  void info(String message, {String? component}) =>
      log(message, level: LogLevel.info, component: component);

  /// Log warning message
  void warning(String message, {String? component}) =>
      log(message, level: LogLevel.warning, component: component);

  /// Log error message with optional exception
  void error(String message,
      {String? component, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, component: component);

    if (error != null) {
      log('  └─ Error: $error', level: LogLevel.error, component: component);
    }
    if (stackTrace != null && kDebugMode) {
      log('  └─ Stack: $stackTrace',
          level: LogLevel.error, component: component);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scoped Logging
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a scoped logger for a specific component.
  ///
  /// Example:
  /// ```dart
  /// final log = AppLogger.instance.scoped('DownloadService');
  /// log.info('Starting download...');  // [DownloadService] Starting download...
  /// ```
  ScopedLogger scoped(String component) => ScopedLogger(this, component);

  // ─────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────────────

  /// Flush any pending logs and close
  Future<void> dispose() async {
    _writeTimer?.cancel();
    await _flushBuffer();
    log('Logger shutting down', level: LogLevel.info);
    await _flushBuffer();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SCOPED LOGGER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Logger bound to a specific component.
///
/// Automatically tags all messages with the component name.
class ScopedLogger {
  final AppLogger _logger;
  final String _component;

  const ScopedLogger(this._logger, this._component);

  void debug(String message) => _logger.debug(message, component: _component);
  void info(String message) => _logger.info(message, component: _component);
  void warning(String message) =>
      _logger.warning(message, component: _component);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.error(message,
          component: _component, error: error, stackTrace: stackTrace);
}
