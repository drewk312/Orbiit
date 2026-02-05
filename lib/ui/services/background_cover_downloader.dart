import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Background cover downloader - automatically downloads missing covers
/// in parallel using isolates for maximum performance
/// 
/// Based on TinyWii's approach but faster with Flutter isolates
class BackgroundCoverDownloader {
  static const int _maxConcurrentDownloads = 3; // Reduced for stability
  static const Duration _timeout = Duration(milliseconds: 500); // Fast like TinyWii
  
  // Cover URL templates - OPTIMIZED FOR SPEED (smallest files first)
  static const List<String> _coverUrlTemplates = [
    // 2D covers (smallest, fastest)
    'https://art.gametdb.com/wii/cover/{REGION}/{GAMEID}.png',
    'https://art.gametdb.com/gamecube/cover/{REGION}/{GAMEID}.png',
    // Fallback to US region if region-specific fails
    'https://art.gametdb.com/wii/cover/US/{GAMEID}.png',
    'https://art.gametdb.com/gamecube/cover/US/{GAMEID}.png',
  ];

  /// Start background download of missing covers
  /// Returns a stream of progress updates
  static Stream<DownloadProgress> startDownloading(List<CoverDownloadTask> tasks) async* {
    if (tasks.isEmpty) {
      yield DownloadProgress(
        total: 0,
        completed: 0,
        failed: 0,
        currentGameId: null,
        isComplete: true,
      );
      return;
    }

    final receivePort = ReceivePort();
    final rootIsolateToken = RootIsolateToken.instance!;
    final isolate = await Isolate.spawn(
      _downloadIsolate,
      _IsolateParams(
        tasks: tasks,
        sendPort: receivePort.sendPort,
        maxConcurrent: _maxConcurrentDownloads,
        rootIsolateToken: rootIsolateToken,
      ),
    );

    await for (final message in receivePort) {
      if (message is DownloadProgress) {
        yield message;
        if (message.isComplete) {
          receivePort.close();
          isolate.kill();
          break;
        }
      }
    }
  }

  /// Isolate worker function - runs in background thread
  @pragma('vm:entry-point')
  static Future<void> _downloadIsolate(_IsolateParams params) async {
    // Initialize binary messenger for platform channels in isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);
    
    int completed = 0;
    int failed = 0;
    final total = params.tasks.length;

    // Get cache directory
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(path.join(appDir.path, 'wiigc_fusion', 'covers'));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }

    // Process tasks in parallel batches
    final taskQueue = List<CoverDownloadTask>.from(params.tasks);
    final activeTasks = <Future<void>>[];

    while (taskQueue.isNotEmpty || activeTasks.isNotEmpty) {
      // Fill up to maxConcurrent tasks
      while (activeTasks.length < params.maxConcurrent && taskQueue.isNotEmpty) {
        final task = taskQueue.removeAt(0);
        activeTasks.add(_downloadCoverForTask(task, coverDir).then((success) {
          if (success) {
            completed++;
          } else {
            failed++;
          }
          
          // Send progress update
          params.sendPort.send(DownloadProgress(
            total: total,
            completed: completed,
            failed: failed,
            currentGameId: task.gameId,
            isComplete: false,
          ));
        }));
      }

      // Wait for at least one task to complete
      if (activeTasks.isNotEmpty) {
        await activeTasks.first;
        activeTasks.removeAt(0);
      }
    }

    // Send final completion message
    params.sendPort.send(DownloadProgress(
      total: total,
      completed: completed,
      failed: failed,
      currentGameId: null,
      isComplete: true,
    ));
  }

  /// Download cover for a single task
  static Future<bool> _downloadCoverForTask(
    CoverDownloadTask task,
    Directory coverDir,
  ) async {
    final region = task.region ?? 'US';
    
    // Try each URL template until one works
    for (final template in _coverUrlTemplates) {
      final url = template
          .replaceAll('{GAMEID}', task.gameId)
          .replaceAll('{REGION}', region);

      try {
        final response = await http.get(Uri.parse(url)).timeout(_timeout);
        
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          // Success! Save the cover
          final file = File(path.join(coverDir.path, '${task.gameId}.png'));
          await file.writeAsBytes(response.bodyBytes);
          return true;
        }
      } catch (e) {
        // Silent fail, try next URL
        continue;
      }
    }

    return false; // All URLs failed
  }

  /// Check which games are missing covers
  static Future<List<CoverDownloadTask>> findMissingCovers(
    List<GameInfo> games,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(path.join(appDir.path, 'wiigc_fusion', 'covers'));
    
    if (!await coverDir.exists()) {
      // All covers are missing if directory doesn't exist
      return games.map((g) => CoverDownloadTask(
        gameId: g.gameId,
        title: g.title,
        region: g.region,
      )).toList();
    }

    final missingTasks = <CoverDownloadTask>[];
    
    for (final game in games) {
      final coverFile = File(path.join(coverDir.path, '${game.gameId}.png'));
      if (!await coverFile.exists()) {
        missingTasks.add(CoverDownloadTask(
          gameId: game.gameId,
          title: game.title,
          region: game.region,
        ));
      }
    }

    return missingTasks;
  }
}

/// Isolate communication parameters
class _IsolateParams {
  final List<CoverDownloadTask> tasks;
  final SendPort sendPort;
  final int maxConcurrent;
  final RootIsolateToken rootIsolateToken;

  _IsolateParams({
    required this.tasks,
    required this.sendPort,
    required this.maxConcurrent,
    required this.rootIsolateToken,
  });
}

/// A single cover download task
class CoverDownloadTask {
  final String gameId;
  final String title;
  final String? region;

  CoverDownloadTask({
    required this.gameId,
    required this.title,
    this.region,
  });
}

/// Progress update from the background downloader
class DownloadProgress {
  final int total;
  final int completed;
  final int failed;
  final String? currentGameId;
  final bool isComplete;

  DownloadProgress({
    required this.total,
    required this.completed,
    required this.failed,
    required this.currentGameId,
    required this.isComplete,
  });

  int get remaining => total - completed - failed;
  double get percentage => total > 0 ? (completed / total) * 100 : 0;
}

/// Simple game info for cover downloads
class GameInfo {
  final String gameId;
  final String title;
  final String? region;

  GameInfo({
    required this.gameId,
    required this.title,
    this.region,
  });
}
