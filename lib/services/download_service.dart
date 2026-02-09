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
  // Singleton instance
  static final DownloadService _instance = DownloadService._internal();

  /// Factory constructor returns the singleton instance
  factory DownloadService() {
    return _instance;
  }

  /// Internal private constructor
  DownloadService._internal();

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

  /// Process downloads in queue concurrently.
  ///
  /// Automatically handles:
  /// - Finding pending tasks
  /// - Starting downloads up to maxConcurrent limit
  /// - Restarting loop when a slot frees up
  Future<void> _processQueue() async {
    // Prevent re-entry if already fully saturated
    if (_isActive) {
      final activeCount = _queue.where((t) => t.status == DownloadStatus.downloading).length;
      if (activeCount >= _Config.maxConcurrent) return;
    }
    
    _isActive = true;

    while (true) {
      final activeCount = _queue.where((t) => t.status == DownloadStatus.downloading).length;
      final pendingTaskIndex = _queue.indexWhere((t) => t.status == DownloadStatus.pending);

      if (pendingTaskIndex == -1) {
        // No more pending tasks
        if (activeCount == 0) _isActive = false;
        break; 
      }

      if (activeCount < _Config.maxConcurrent) {
        final task = _queue[pendingTaskIndex];
        // Start download WITHOUT awaiting so the loop continues to start others 
        // if slots are available
        _executeDownload(task).then((_) {
            // Recursively trigger queue check when a download finishes to fill the slot
            _processQueue(); 
        });
      } else {
        // Wait for a slot to free up (handled by the .then callback above)
        break; 
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download Execution
  // ─────────────────────────────────────────────────────────────────────────

  /// Execute a single download with retry & resume support.
  Future<void> _executeDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task._startTime ??= DateTime.now();
    _notifyQueueUpdate();

    debugPrint('[DownloadService] Starting download: ${task.title}');

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

      // ── Check for existing file (Resume Logic) ──
      file = File(filePath);
      int existingBytes = 0;
      if (await file.exists()) {
        existingBytes = await file.length();
      }

      // ── Start Request ──
      final request = http.Request('GET', Uri.parse(task.url))
        ..headers['User-Agent'] = _Config.userAgent
        ..headers['Accept'] = '*/*'
        ..headers['Accept-Encoding'] = 'identity'
        ..headers['Cache-Control'] = 'no-cache';
      
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
        debugPrint('[DownloadService] Resuming from byte $existingBytes');
      }

      // Only timeout the initial connection
      response = await _httpClient.send(request).timeout(_Config.connectionTimeout);

      debugPrint('[DownloadService] HTTP ${response.statusCode}');

      // Handle server not supporting ranges (returns 200 instead of 206)
      if (existingBytes > 0 && response.statusCode == 200) {
         debugPrint('[DownloadService] Server ignored Range header. Restarting download.');
         existingBytes = 0;
         await file.delete();
         await file.create();
      } else if (response.statusCode == 416) {
         // Range not satisfiable - assume complete
         debugPrint('[DownloadService] Range not satisfiable. Assuming file complete.');
         task.status = DownloadStatus.completed;
         task.progress = 1.0;
         _notifyQueueUpdate();
         return;
      } else if (response.statusCode >= 400) {
        throw DownloadException('HTTP ${response.statusCode}');
      }

      // Get content length
      int contentLength = response.contentLength ?? 0;
      if (contentLength == 0) {
        contentLength = int.tryParse(response.headers['content-length'] ?? '0') ?? 0;
      }
      // If 206, content-length is usually just the chunk, so look at content-range if needed
      // But usually simply adding existingBytes works purely for progress calc
      if (response.statusCode == 206) {
         // Headers usually show full size in Content-Range: bytes START-END/TOTAL
         final rangeHeader = response.headers['content-range'];
         if (rangeHeader != null) {
            final parts = rangeHeader.split('/');
            if (parts.length > 1) {
              final total = int.tryParse(parts[1]);
              if (total != null) task.totalBytes = total;
            }
         }
      } 
      
      // Fallback if totalBytes not set from range
      if (task.totalBytes == 0 && contentLength > 0) {
        task.totalBytes = contentLength + existingBytes;
      }

      // ── Stream download ──
      sink = file.openWrite(mode: FileMode.append);

      task.downloadedBytes = existingBytes;
      var lastProgressUpdate = DateTime.now();
      
      // Speed calculation vars
      int bytesAtLastInterval = existingBytes;

      await for (final chunk in response.stream) {
        if (task._isCancelled) {
          await sink.flush();
          await sink.close();
          // Keep partial file for potential resume if user actively paused
          // But if "cancelled" usually means delete.
          // Let's assume cancel = delete for now unless we add specific "Pause" state handling
          if (task.status == DownloadStatus.cancelled) {
             try { await file.delete(); } catch (_) {}
          }
          return;
        }
        
        // Handle Pause during stream
        if (task.status == DownloadStatus.paused) {
           await sink.flush();
           await sink.close();
           return; 
        }

        sink.add(chunk);
        task.downloadedBytes += chunk.length;

        // Throttle updates
        final now = DateTime.now();
        if (now.difference(lastProgressUpdate) >= _Config.progressThrottle) {
          // Progress
          if (task.totalBytes > 0) {
            task.progress = task.downloadedBytes / task.totalBytes;
          }
          
          // Speed
          final durationSeconds = now.difference(lastProgressUpdate).inMilliseconds / 1000.0;
          if (durationSeconds > 0) {
             final bytesDiff = task.downloadedBytes - bytesAtLastInterval;
             task.currentSpeed = (bytesDiff / durationSeconds).round();
          }
          
          bytesAtLastInterval = task.downloadedBytes;
          lastProgressUpdate = now;
          _notifyQueueUpdate();
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      // ── Validate ──
      final actualSize = await file.length();
      if (actualSize < _Config.minimumFileSizeBytes) {
        throw DownloadException('File too small (${actualSize}B)');
      }

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task._endTime = DateTime.now();
      _notifyQueueUpdate();
      
      // Attempt to clean up next item immediately
      _isActive = false; // Flag this slot as free logic wise
      // But _processQueue recursion handles finding next task
      
    } catch (e) {
      if (sink != null) await sink.close();
      debugPrint('[DownloadService] Error: $e');
      await _handleDownloadError(task, e.toString());
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

  /// Current download speed in bytes per second
  int currentSpeed;

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
    this.currentSpeed = 0,
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
