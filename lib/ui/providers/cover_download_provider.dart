import 'package:flutter/foundation.dart';
import '../services/background_cover_downloader.dart';

/// Provider for managing automatic background cover downloads
/// Automatically starts downloading missing covers when library loads
class CoverDownloadProvider extends ChangeNotifier {
  DownloadProgress? _currentProgress;
  bool _isDownloading = false;
  DateTime? _lastDownloadTime;

  DownloadProgress? get currentProgress => _currentProgress;
  bool get isDownloading => _isDownloading;
  bool get hasDownloadedRecently {
    if (_lastDownloadTime == null) return false;
    return DateTime.now().difference(_lastDownloadTime!) <
        const Duration(hours: 1);
  }

  /// Start automatic background download for missing covers
  Future<void> startAutomaticDownload(List<GameInfo> games) async {
    if (_isDownloading) return; // Already downloading
    if (games.isEmpty) return;

    _isDownloading = true;
    notifyListeners();

    try {
      // Find which covers are missing
      final missingCovers =
          await BackgroundCoverDownloader.findMissingCovers(games);

      if (missingCovers.isEmpty) {
        debugPrint('All covers already downloaded!');
        _isDownloading = false;
        _lastDownloadTime = DateTime.now();
        notifyListeners();
        return;
      }

      debugPrint(
          'Starting background download of ${missingCovers.length} missing covers...');

      // Start parallel downloads in background
      await for (final progress
          in BackgroundCoverDownloader.startDownloading(missingCovers)) {
        _currentProgress = progress;
        notifyListeners();

        if (progress.isComplete) {
          debugPrint(
              'Cover download complete! ${progress.completed}/${progress.total} succeeded, ${progress.failed} failed');
          _lastDownloadTime = DateTime.now();
          break;
        }
      }
    } catch (e) {
      debugPrint('Error during background cover download: $e');
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Reset download state (for manual retry)
  void reset() {
    _currentProgress = null;
    _isDownloading = false;
    _lastDownloadTime = null;
    notifyListeners();
  }
}
