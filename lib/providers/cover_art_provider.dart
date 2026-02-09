import 'package:flutter/foundation.dart';
import '../services/cover_art/cover_art_service.dart';
import '../services/cover_art/cover_art_source.dart';

/// Provider for managing cover art downloads with progress tracking
class CoverArtProvider extends ChangeNotifier {
  final CoverArtService _service;
  
  // Progress tracking
  final Map<String, CoverArtDownloadProgress> _downloads = {};
  
  // Cache statistics
  int _cacheSize = 0;
  int _cachedCount = 0;
  
  CoverArtProvider({CoverArtService? service})
      : _service = service ?? CoverArtService();
  
  /// Get download progress for a specific game
  CoverArtDownloadProgress? getProgress(String gameTitle) => _downloads[gameTitle];
  
  /// Get all active downloads
  List<CoverArtDownloadProgress> get activeDownloads =>
      _downloads.values.where((d) => !d.isComplete).toList();
  
  /// Get cache size in bytes
  int get cacheSize => _cacheSize;
  
  /// Get number of cached covers
  int get cachedCount => _cachedCount;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _service.initialize();
    await _updateCacheStats();
  }
  
  /// Download cover art for a single game
  Future<String?> downloadCover({
    required String gameTitle,
    required GamePlatform platform,
    String? gameId,
    bool forceDownload = false,
  }) async {
    // Create progress tracker
    final progress = CoverArtDownloadProgress(
      gameTitle: gameTitle,
      platform: platform,
    );
    _downloads[gameTitle] = progress;
    notifyListeners();
    
    try {
      progress.status = DownloadStatus.downloading;
      notifyListeners();
      
      final coverPath = await _service.getCoverArt(
        gameTitle: gameTitle,
        platform: platform,
        gameId: gameId,
        forceDownload: forceDownload,
      );
      
      if (coverPath != null) {
        progress.status = DownloadStatus.complete;
        progress.localPath = coverPath;
        await _updateCacheStats();
      } else {
        progress.status = DownloadStatus.notFound;
      }
    } catch (e) {
      progress.status = DownloadStatus.error;
      progress.error = e.toString();
    }
    
    notifyListeners();
    return progress.localPath;
  }
  
  /// Batch download covers for multiple games
  Future<void> batchDownload(List<GameInfo> games) async {
    // Create progress trackers for all games
    for (final game in games) {
      _downloads[game.title] = CoverArtDownloadProgress(
        gameTitle: game.title,
        platform: game.platform,
        status: DownloadStatus.queued,
      );
    }
    notifyListeners();
    
    await _service.batchGetCovers(
      games: games,
      onProgress: (completed, total) {
        // Update overall progress
        for (int i = 0; i < completed && i < games.length; i++) {
          final game = games[i];
          final progress = _downloads[game.title];
          if (progress != null && progress.status == DownloadStatus.queued) {
            progress.status = DownloadStatus.complete;
          }
        }
        notifyListeners();
      },
    );
    
    await _updateCacheStats();
    notifyListeners();
  }
  
  /// Clear completed downloads from progress list
  void clearCompleted() {
    _downloads.removeWhere((_, progress) => progress.isComplete);
    notifyListeners();
  }
  
  /// Clear all cached covers
  Future<void> clearCache() async {
    await _service.clearCache();
    _downloads.clear();
    await _updateCacheStats();
    notifyListeners();
  }
  
  /// Update cache statistics
  Future<void> _updateCacheStats() async {
    _cacheSize = await _service.getCacheSize();
    // Count would require reading directory - approximate for now
    _cachedCount = _downloads.values.where((d) => d.isComplete).length;
  }
  
  /// Format cache size for display
  String get formattedCacheSize {
    if (_cacheSize < 1024) return '$_cacheSize B';
    if (_cacheSize < 1024 * 1024) return '${(_cacheSize / 1024).toStringAsFixed(1)} KB';
    return '${(_cacheSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Progress tracking for individual cover art downloads
class CoverArtDownloadProgress {
  final String gameTitle;
  final GamePlatform platform;
  
  DownloadStatus status;
  String? localPath;
  String? error;
  
  CoverArtDownloadProgress({
    required this.gameTitle,
    required this.platform,
    this.status = DownloadStatus.queued,
    this.localPath,
    this.error,
  });
  
  bool get isComplete => status == DownloadStatus.complete || status == DownloadStatus.notFound;
  bool get isError => status == DownloadStatus.error;
  bool get isDownloading => status == DownloadStatus.downloading;
}

enum DownloadStatus {
  queued,
  downloading,
  complete,
  notFound,
  error,
}
