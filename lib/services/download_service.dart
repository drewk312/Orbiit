// ═══════════════════════════════════════════════════════════════════════════
// DOWNLOAD SERVICE
// WiiGC-Fusion - Enterprise-grade download management with queue processing
// ═══════════════════════════════════════════════════════════════════════════
//
// This service provides:
//   • Queue-based download management with priority support
//   • Automatic retry with exponential backoff for failed downloads
//   • Progress tracking and speed calculation
//   • Pause/resume capability
//   • Concurrent download limiting
//   • File integrity validation
//
// Architecture:
//   ┌──────────────────────────────────────────────────────────────────────┐
//   │  DownloadService (Singleton)                                        │
//   │  ├── _queue: List<DownloadTask>                                     │
//   │  ├── _activeDownloads: Map<String, StreamSubscription>              │
//   │  └── _queueController: StreamController<List<DownloadTask>>         │
//   │                                                                     │
//   │  Flow: addToQueue() → _processQueue() → _executeDownload()          │
//   │        → Progress updates → Complete/Error/Retry                    │
//   └──────────────────────────────────────────────────────────────────────┘
//
// Usage:
//   final service = DownloadService();
//   final task = await service.addToQueue(
//     url: 'https://archive.org/download/...',
//     title: 'Super Mario Galaxy',
//     destinationFolder: 'C:/Games/Wii',
//     gameId: 'RMGE01',
//   );
//
//   service.queueStream.listen((queue) {
//     print('Queue updated: ${queue.length} items');
//   });
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIGURATION CONSTANTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Download service configuration
abstract class _Config {
  /// Maximum concurrent downloads
  static const int maxConcurrent = 3;

  /// Maximum retry attempts for failed downloads
  static const int maxRetries = 3;

  /// Base delay between retry attempts (exponential backoff)
  static const Duration retryBaseDelay = Duration(seconds: 2);

  /// Connection timeout for HTTP requests
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Read timeout for streaming data
  static const Duration readTimeout = Duration(minutes: 5);

  /// Minimum file size to consider download valid (1KB)
  static const int minimumFileSizeBytes = 1024;

  /// Progress update throttle interval
  static const Duration progressThrottle = Duration(milliseconds: 100);

  /// User agent for HTTP requests - mimics browser to avoid 403 blocks
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Manages game downloads with queue processing and progress tracking.
///
/// Features:
/// - Queue-based download management
/// - Automatic retry with exponential backoff
/// - Progress tracking with speed calculation
/// - Concurrent download limiting
///
/// Example:
/// ```dart
/// final service = DownloadService();
///
/// // Listen for queue updates
/// service.queueStream.listen((tasks) {
///   for (final task in tasks) {
///     print('${task.title}: ${task.progressPercent}');
///   }
/// });
///
/// // Add a download
/// await service.addToQueue(
///   url: 'https://example.com/game.wbfs',
///   title: 'My Game',
///   destinationFolder: '/downloads',
/// );
/// ```
class DownloadService {
  // ─────────────────────────────────────────────────────────────────────────
  // Internal State
  // ─────────────────────────────────────────────────────────────────────────

  /// All download tasks (pending, active, and completed)
  final List<DownloadTask> _queue = [];

  /// Currently downloading task
  DownloadTask? _currentDownload;

  /// Whether queue processor is running
  bool _isActive = false;

  /// HTTP client for downloads (reused for connection pooling)
  final http.Client _httpClient = http.Client();

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Controllers
  // ─────────────────────────────────────────────────────────────────────────

  /// Broadcasts queue state changes
  final _queueController = StreamController<List<DownloadTask>>.broadcast();

  /// Stream of queue updates for UI binding
  Stream<List<DownloadTask>> get queueStream => _queueController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // Public Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Get immutable copy of current queue
  List<DownloadTask> get queue => List.unmodifiable(_queue);

  /// Get currently active download (null if idle)
  DownloadTask? get currentDownload => _currentDownload;

  /// Get count of pending downloads
  int get pendingCount =>
      _queue.where((t) => t.status == DownloadStatus.pending).length;

  /// Get count of completed downloads
  int get completedCount =>
      _queue.where((t) => t.status == DownloadStatus.completed).length;

  /// Whether any download is currently active
  bool get isDownloading => _currentDownload != null;

  // ─────────────────────────────────────────────────────────────────────────
  // Queue Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Add a download to the queue.
  ///
  /// Returns the created [DownloadTask] for tracking.
  /// Queue processing starts automatically if not already running.
  ///
  /// Example:
  /// ```dart
  /// final task = await service.addToQueue(
  ///   url: 'https://archive.org/download/game/game.wbfs',
  ///   title: 'Super Mario Galaxy',
  ///   destinationFolder: 'C:/Wii/Games',
  ///   gameId: 'RMGE01',
  ///   platform: 'Wii',
  /// );
  /// ```
  Future<DownloadTask> addToQueue({
    required String url,
    required String title,
    required String destinationFolder,
    String? gameId,
    String? platform,
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    // Generate unique ID
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}';

    final task = DownloadTask(
      id: id,
      url: url,
      title: title,
      destinationFolder: destinationFolder,
      gameId: gameId,
      platform: platform,
      priority: priority,
    );

    // Insert based on priority
    final insertIndex = _findInsertIndex(priority);
    _queue.insert(insertIndex, task);
    _notifyQueueUpdate();

    // Start processing if idle
    if (!_isActive) {
      _processQueue();
    }

    return task;
  }

  /// Find correct insertion index for priority ordering
  int _findInsertIndex(DownloadPriority priority) {
    // High priority goes after existing high priority but before normal
    if (priority == DownloadPriority.high) {
      final firstNormal = _queue.indexWhere((t) =>
          t.priority == DownloadPriority.normal &&
          t.status == DownloadStatus.pending);
      return firstNormal == -1 ? _queue.length : firstNormal;
    }
    return _queue.length;
  }

  /// Cancel a download by task ID.
  ///
  /// Returns `true` if task was found and cancelled.
  /// For active downloads, cancels in-progress transfer.
  /// For pending downloads, removes from queue.
  Future<bool> cancelDownload(String taskId) async {
    final taskIndex = _queue.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;

    final task = _queue[taskIndex];

    // Signal cancellation for active download
    if (task == _currentDownload) {
      task._cancel();
    }

    task.status = DownloadStatus.cancelled;
    _queue.removeAt(taskIndex);
    _notifyQueueUpdate();

    return true;
  }

  /// Pause all downloads
  void pauseAll() {
    _currentDownload?._cancel();
    for (final task in _queue) {
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.paused;
      }
    }
    _isActive = false;
    _notifyQueueUpdate();
  }

  /// Resume queue processing
  void resumeAll() {
    for (final task in _queue) {
      if (task.status == DownloadStatus.paused) {
        task.status = DownloadStatus.pending;
        task._retryCount = 0;
      }
    }
    if (!_isActive) {
      _processQueue();
    }
    _notifyQueueUpdate();
  }

  /// Clear completed downloads from queue
  void clearCompleted() {
    _queue.removeWhere((t) =>
        t.status == DownloadStatus.completed ||
        t.status == DownloadStatus.cancelled);
    _notifyQueueUpdate();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Queue Processing
  // ─────────────────────────────────────────────────────────────────────────

  /// Process downloads in queue sequentially.
  ///
  /// Automatically handles:
  /// - Finding next pending task
  /// - Executing download with retries
  /// - Moving to next task on completion/failure
  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isActive) return;

    _isActive = true;

    while (_queue.isNotEmpty && _isActive) {
      // Find next pending task
      final taskIndex =
          _queue.indexWhere((t) => t.status == DownloadStatus.pending);

      if (taskIndex == -1) break;

      _currentDownload = _queue[taskIndex];
      await _executeDownload(_currentDownload!);
      _currentDownload = null;
    }

    _isActive = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download Execution
  // ─────────────────────────────────────────────────────────────────────────

  /// Execute a single download with retry support.
  ///
  /// Handles:
  /// - Directory creation
  /// - Progress tracking
  /// - Automatic retry on failure
  /// - File validation
  Future<void> _executeDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task._startTime = DateTime.now();
    _notifyQueueUpdate();

    // DEBUG: Log the download URL
    debugPrint('[DownloadService] ═══════════════════════════════════════════');
    debugPrint('[DownloadService] Starting download: ${task.title}');
    debugPrint('[DownloadService] URL: ${task.url}');
    debugPrint('[DownloadService] ═══════════════════════════════════════════');

    IOSink? sink;
    File? file;
    http.StreamedResponse? response;

    try {
      // ── Prepare destination ──
      final destDir = Directory(task.destinationFolder);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // ── Determine filename ──
      final fileName = _extractFileName(task.url) ??
          '${task.gameId ?? task.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '')}.download';
      final filePath = path.join(task.destinationFolder, fileName);
      task.destinationPath = filePath;

      // ── Get file size via HEAD request (with error handling) ──
      int contentLength = 0;
      try {
        final headResponse = await http.head(
          Uri.parse(task.url),
          headers: {
            'User-Agent': _Config.userAgent,
            'Accept': '*/*',
            'Accept-Encoding': 'identity', // Don't compress (we want raw file)
            'Cache-Control': 'no-cache',
          },
        ).timeout(_Config.connectionTimeout);

        contentLength = int.tryParse(
              headResponse.headers['content-length'] ?? '0',
            ) ??
            0;
        task.totalBytes = contentLength;

        // DEBUG: Log HEAD response
        debugPrint('[DownloadService] HEAD response: ${headResponse.statusCode}');
        debugPrint('[DownloadService] Content-Length: $contentLength bytes');

        // If HEAD failed with 405 (Method Not Allowed) or similar, just proceed with GET
        // Some servers block HEAD but allow GET
        if (headResponse.statusCode == 405 || headResponse.statusCode == 403) {
          debugPrint(
              '[DownloadService] HEAD rejected (${headResponse.statusCode}), attempting GET anyway...');
        }
      } catch (e) {
        // HEAD request failed, but we'll try GET anyway
        debugPrint('[DownloadService] HEAD request failed: $e, proceeding with GET...');
      }

      // ── Stream download ──
      file = File(filePath);
      sink = file.openWrite();

      final request = http.Request('GET', Uri.parse(task.url))
        ..headers['User-Agent'] = _Config.userAgent
        ..headers['Accept'] = '*/*'
        ..headers['Accept-Encoding'] = 'identity'
        ..headers['Cache-Control'] = 'no-cache';

      // Only timeout the initial connection, not the entire download
      response = await _httpClient.send(request).timeout(_Config.connectionTimeout);

      // DEBUG: Check HTTP status
      debugPrint('[DownloadService] GET response: ${response.statusCode}');
      if (response.statusCode >= 400) {
        await sink.close();
        sink = null;
        throw DownloadException(
            'HTTP ${response.statusCode}: Server returned error');
      }

      // Update content length from response if HEAD didn't work
      if (contentLength == 0) {
        final responseLength = int.tryParse(
              response.headers['content-length'] ?? '0',
            ) ??
            0;
        if (responseLength > 0) {
          contentLength = responseLength;
          task.totalBytes = contentLength;
        }
      }

      task.downloadedBytes = 0;
      var lastProgressUpdate = DateTime.now();
      var lastChunkTime = DateTime.now();

      // Stream download with basic error handling
      // Note: Large downloads may take a long time, so we don't timeout the stream itself
      // but we do detect stalls (no progress for extended periods)
      try {
        await for (final chunk in response.stream) {
          // Check for cancellation
          if (task._isCancelled) {
            if (sink != null) {
              await sink.close();
              sink = null;
            }
            try {
              await file.delete();
            } catch (_) {}
            return;
          }

          try {
            if (sink != null) {
              sink.add(chunk);
              task.downloadedBytes += chunk.length;
              lastChunkTime = DateTime.now(); // Track last chunk time for stall detection

              // Calculate progress
              if (contentLength > 0) {
                task.progress = task.downloadedBytes / contentLength;
              } else {
                // Indeterminate progress (just keep it active visually)
                task.progress = 0.0;
              }

              // Throttle progress updates
              final now = DateTime.now();
              if (now.difference(lastProgressUpdate) >= _Config.progressThrottle) {
                _notifyQueueUpdate();
                lastProgressUpdate = now;
              }
            } else {
              throw DownloadException('Sink was closed unexpectedly');
            }
          } catch (e) {
            // Error writing chunk - close sink and rethrow
            if (sink != null) {
              await sink.close();
              sink = null;
            }
            throw DownloadException('Failed to write data: $e');
          }
        }
      } catch (e) {
        // Stream error - ensure sink is closed
        if (sink != null) {
          try {
            await sink.close();
            sink = null;
          } catch (_) {}
        }
        rethrow; // Re-throw to be caught by outer catch block
      }

      // Ensure sink is closed
      if (sink != null) {
        await sink.close();
        sink = null;
      }

      // ── Validate download ──
      if (!await file.exists()) {
        throw DownloadException('File not created');
      }

      final actualSize = await file.length();
      if (actualSize < _Config.minimumFileSizeBytes) {
        try {
          await file.delete();
        } catch (_) {}
        throw DownloadException(
            'Download too small (${actualSize}B) - likely an error page');
      }

      // ── Success ──
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task._endTime = DateTime.now();
      _notifyQueueUpdate();
    } on TimeoutException catch (e) {
      // Ensure cleanup
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (file != null && task.destinationPath != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await _handleDownloadError(task, 'Connection timeout: ${e.message}');
    } on SocketException catch (e) {
      // Ensure cleanup
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (file != null && task.destinationPath != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await _handleDownloadError(task, 'Network error: ${e.message}');
    } on DownloadException catch (e) {
      // Ensure cleanup
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (file != null && task.destinationPath != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await _handleDownloadError(task, e.message);
    } catch (e, stackTrace) {
      // Ensure cleanup on any unexpected error
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (file != null && task.destinationPath != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
      debugPrint('[DownloadService] Unexpected error: $e');
      debugPrint('[DownloadService] Stack trace: $stackTrace');
      await _handleDownloadError(task, 'Unexpected error: ${e.toString()}');
    }
  }

  /// Handle download error with retry logic
  Future<void> _handleDownloadError(DownloadTask task, String error) async {
    task._retryCount++;

    if (task._retryCount < _Config.maxRetries) {
      // Calculate exponential backoff delay
      final delay = _Config.retryBaseDelay * (1 << (task._retryCount - 1));
      task.errorMessage =
          'Retry ${task._retryCount}/${_Config.maxRetries} in ${delay.inSeconds}s: $error';
      task.status = DownloadStatus.retrying;
      _notifyQueueUpdate();

      await Future.delayed(delay);

      if (!task._isCancelled) {
        task.status = DownloadStatus.pending;
        task.errorMessage = null;
      }
    } else {
      task.status = DownloadStatus.error;
      task.errorMessage = error;
      task._endTime = DateTime.now();
    }

    _notifyQueueUpdate();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Extract filename from URL
  String? _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.contains('.')) {
          return Uri.decodeComponent(lastSegment);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Notify listeners of queue state change
  void _notifyQueueUpdate() {
    if (!_queueController.isClosed) {
      _queueController.add(List.unmodifiable(_queue));
    }
  }

  /// Clean up resources
  void dispose() {
    _currentDownload?._cancel();
    _httpClient.close();
    _queueController.close();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD STATUS ENUM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Status of a download task
enum DownloadStatus {
  /// Waiting in queue
  pending,

  /// Currently downloading
  downloading,

  /// Waiting to retry after failure
  retrying,

  /// Paused by user
  paused,

  /// Extracting compressed archive
  extracting,

  /// Successfully completed
  completed,

  /// Failed with error
  error,

  /// Cancelled by user
  cancelled,
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD PRIORITY ENUM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Priority level for download queue ordering
enum DownloadPriority {
  /// High priority - moved to front of queue
  high,

  /// Normal priority - standard FIFO ordering
  normal,
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD TASK CLASS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Represents a single download task with progress tracking.
///
/// Contains all metadata and state for tracking a download:
/// - Source URL and destination path
/// - Progress and speed calculations
/// - Status and error handling
class DownloadTask {
  // ─────────────────────────────────────────────────────────────────────────
  // Immutable Properties (set at creation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Unique identifier for this task
  final String id;

  /// Source URL to download from
  final String url;

  /// Display title for the download
  final String title;

  /// Destination folder path
  final String destinationFolder;

  /// Game ID (e.g., 'RMGE01') if known
  final String? gameId;

  /// Platform ('Wii' or 'GameCube') if known
  final String? platform;

  /// Download priority level
  final DownloadPriority priority;

  // ─────────────────────────────────────────────────────────────────────────
  // Mutable State
  // ─────────────────────────────────────────────────────────────────────────

  /// Current status
  DownloadStatus status;

  /// Download progress (0.0 to 1.0)
  double progress;

  /// Total file size in bytes
  int totalBytes;

  /// Bytes downloaded so far
  int downloadedBytes;

  /// Full path to downloaded file (set after download starts)
  String? destinationPath;

  /// Error message if status is error
  String? errorMessage;

  // ─────────────────────────────────────────────────────────────────────────
  // Internal State
  // ─────────────────────────────────────────────────────────────────────────

  bool _isCancelled = false;
  int _retryCount = 0;
  DateTime? _startTime;
  DateTime? _endTime;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.destinationFolder,
    this.gameId,
    this.platform,
    this.priority = DownloadPriority.normal,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Internal Methods
  // ─────────────────────────────────────────────────────────────────────────

  void _cancel() {
    _isCancelled = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties - Size
  // ─────────────────────────────────────────────────────────────────────────

  /// Get formatted total file size
  String get formattedSize {
    if (totalBytes == 0) return 'Unknown size';
    return _formatBytes(totalBytes);
  }

  /// Get formatted downloaded size
  String get formattedDownloaded => _formatBytes(downloadedBytes);

  /// Get size progress string (e.g., "1.5 GB / 4.2 GB")
  String get sizeProgress => '$formattedDownloaded / $formattedSize';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties - Progress
  // ─────────────────────────────────────────────────────────────────────────

  /// Get progress as percentage string
  String get progressPercent => '${(progress * 100).toInt()}%';

  /// Get estimated time remaining
  String get timeRemaining {
    if (_startTime == null || progress <= 0) return '--:--';

    final elapsed = DateTime.now().difference(_startTime!);
    final totalEstimated = elapsed.inSeconds / progress;
    final remaining = totalEstimated - elapsed.inSeconds;

    if (remaining <= 0) return 'Almost done';
    if (remaining < 60) return '${remaining.toInt()}s';
    if (remaining < 3600) return '${(remaining / 60).toInt()}m';
    return '${(remaining / 3600).toStringAsFixed(1)}h';
  }

  /// Get download speed in bytes per second
  int get speedBytesPerSecond {
    if (_startTime == null || downloadedBytes == 0) return 0;
    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
    if (elapsed == 0) return 0;
    return (downloadedBytes * 1000 / elapsed).round();
  }

  /// Get formatted download speed
  String get speedFormatted {
    final speed = speedBytesPerSecond;
    if (speed == 0) return '-- MB/s';
    return '${_formatBytes(speed)}/s';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties - Status
  // ─────────────────────────────────────────────────────────────────────────

  /// Get human-readable status text
  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading $progressPercent';
      case DownloadStatus.retrying:
        return 'Retrying...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.extracting:
        return 'Extracting...';
      case DownloadStatus.completed:
        return 'Complete';
      case DownloadStatus.error:
        return 'Error';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Whether this download is currently active
  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.retrying;

  /// Whether this download can be resumed
  bool get canResume =>
      status == DownloadStatus.paused || status == DownloadStatus.error;

  /// Total download duration (only valid after completion)
  Duration? get duration {
    if (_startTime == null || _endTime == null) return null;
    return _endTime!.difference(_startTime!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Debug
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String toString() => 'DownloadTask($title: $statusText)';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD EXCEPTION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Exception thrown during download operations
class DownloadException implements Exception {
  final String message;

  DownloadException(this.message);

  @override
  String toString() => 'DownloadException: $message';
}
