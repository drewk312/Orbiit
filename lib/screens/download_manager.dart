import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'; // Add this dependency if missing
import 'package:provider/provider.dart';

import '../../models/game_result.dart';
import '../../providers/forge_provider.dart';
import '../../services/download_center_service.dart';
import '../ui/fusion/design_system.dart';
import '../widgets/cascading_cover_image.dart';
import '../widgets/immersive_glass_header.dart';
import '../widgets/premium_fallback_cover.dart';
import '../widgets/xbox_download_card.dart';

/// Fusion Download Screen
/// Focuses on active download with detailed progress, clear queue management,
/// and manual archive import (Phase 5).
class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final DownloadCenterService _downloadCenter = DownloadCenterService();
  List<File> _detectedArchives = [];
  bool _scanning = false;

  // Processing State
  bool _isProcessing = false;
  String _processStatus = '';
  double _processProgress = 0;
  File? _processingFile;

  @override
  void initState() {
    super.initState();
    _scanDownloads();
  }

  Future<void> _scanDownloads() async {
    setState(() => _scanning = true);
    try {
      Directory? downloadsDir;
      if (Platform.isWindows) {
        // Windows Downloads usually UserProfile/Downloads
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsDir = Directory(path.join(userProfile, 'Downloads'));
        }
      } else {
        // Fallback for others
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir != null) {
        final archives =
            await _downloadCenter.scanForGameArchives(downloadsDir);
        if (mounted) {
          setState(() {
            _detectedArchives = archives;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _importFile(File file) async {
    // Determine destination (assume last used SD or ask?)
    // For automation, let's pick the first available "Game Library" drive or ask user?
    // Let's ask user for Library Root for now, or use a saved preference.

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Game Library Root (where "wbfs" folder is)',
      lockParentWindow: true,
    );

    if (result == null) return;
    final destRoot = Directory(result);

    setState(() {
      _isProcessing = true;
      _processingFile = file;
      _processStatus = 'Starting import...';
      _processProgress = 0.0;
    });

    try {
      await _downloadCenter.processArchive(
        archiveFile: file,
        destinationRoot: destRoot,
        onStatus: (s) {
          if (mounted) setState(() => _processStatus = s);
        },
        onProgress: (p) {
          if (mounted) setState(() => _processProgress = p);
        },
      );

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Successfully imported ${path.basename(file.path)}')),
        );
        // Refresh list?
        _scanDownloads();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingFile = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(
      builder: (context, forge, child) {
        final active = forge.currentGame;

        return Column(
          children: [
            // Header
            ImmersiveGlassHeader(
              title: 'Downloads',
              subtitle: 'Manage your game installations',
              leading: const Icon(Icons.download_rounded,
                  color: FusionColors.textPrimary),
              actions: [
                IconButton(
                  icon: const Icon(Icons.folder_open,
                      color: FusionColors.nebulaCyan),
                  tooltip: 'Import from File',
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'zip',
                        '7z',
                        'rar',
                        'iso',
                        'wbfs',
                        'rvz'
                      ],
                    );
                    if (result != null && result.files.single.path != null) {
                      _importFile(File(result.files.single.path!));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Scan Downloads Folder',
                  onPressed: _scanDownloads,
                ),
              ],
            ),

            if (_isProcessing)
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FusionColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FusionColors.nebulaCyan),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircularProgressIndicator(strokeWidth: 3),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Importing: ${path.basename(_processingFile?.path ?? "")}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(_processStatus,
                                  style:
                                      const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: _processProgress > 0 ? _processProgress : null),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Section: Detected Archives (Phase 5)
                  if (_detectedArchives.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.save_alt,
                            color: FusionColors.nebulaCyan, size: 20),
                        const SizedBox(width: 8),
                        const Text('Ready to Import',
                            style: FusionTypography.headlineMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FusionColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_detectedArchives.length} files found',
                            style: const TextStyle(
                                fontSize: 12, color: FusionColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._detectedArchives
                        .map((file) => _buildDetectedItem(file)),
                    const SizedBox(height: 32),
                  ],

                  // Section: Active Download
                  if (active != null) ...[
                    const Row(
                      children: [
                        Icon(Icons.play_circle_outline,
                            color: FusionColors.wiiBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Downloading Now',
                            style: FusionTypography.headlineMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    XboxStyleDownloadCard(
                      gameTitle: active.title,
                      coverUrl: active.coverUrl,
                      platform: active.platform, // Pass platform for hunting
                      bytesDownloaded: forge.currentDownloadedBytes,
                      totalBytes: forge.currentTotalBytes,
                      speedBytesPerSec: forge.downloadSpeedBps ?? 0.0,
                      onCancel: forge.cancelForge,
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    if (forge.downloadQueue.isEmpty &&
                        _detectedArchives.isEmpty &&
                        !_isProcessing)
                      _buildEmptyState(context),
                  ],

                  // Section: Queue
                  if (forge.downloadQueue.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.queue_music,
                            color: FusionColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Up Next',
                            style: FusionTypography.headlineMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FusionColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${forge.downloadQueue.length} items',
                            style: const TextStyle(
                                fontSize: 12, color: FusionColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...forge.downloadQueue.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final game = entry.value;
                      return _buildQueueItem(context, game, idx, forge);
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetectedItem(File file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FusionColors.surfaceCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FusionColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.archive, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.basename(file.path),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatSize(file.lengthSync()),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _importFile(file),
            style: ElevatedButton.styleFrom(
              backgroundColor: FusionColors.nebulaCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FusionColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: FusionColors.glassBorder),
              ),
              child: const Icon(Icons.cloud_download_outlined,
                  size: 48, color: FusionColors.textMuted),
            ),
            const SizedBox(height: 24),
            const Text('No Active Downloads',
                style: FusionTypography.displayLarge),
            const SizedBox(height: 8),
            if (_detectedArchives.isNotEmpty)
              Text(
                'But we found files in your Downloads folder!\nClick IMPORT to organize them.',
                style: FusionTypography.bodyLarge
                    .copyWith(color: FusionColors.nebulaCyan),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Games you download from the Store will appear here.\nOr use the folder icon to import external archives.',
                style: FusionTypography.bodyLarge
                    .copyWith(color: FusionColors.textSecondary),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItem(
      BuildContext context, GameResult game, int index, ForgeProvider forge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FusionColors.surfaceCard,
        borderRadius: BorderRadius.circular(FusionRadius.md),
        border: Border.all(color: FusionColors.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 64,
            child: CascadingCoverImage(
              primaryUrl: game.coverUrl ?? '',
              platform: game.platform, // Correct platform
              title: game.title, // Correct title for hunting
              fallbackBuilder: (_) => PremiumFallbackCover(
                title: game.title,
                platform: game.platform,
              ), // Premium fallback
            ),
          ),
        ),
        title: Text(game.title, style: FusionTypography.headlineSmall),
        subtitle: Text('${game.platform} • ${game.size ?? "Unknown Size"}',
            style:
                const TextStyle(color: FusionColors.textMuted, fontSize: 13)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: FusionColors.textSecondary),
          onPressed: () => forge.removeFromQueueAt(index),
          tooltip: 'Remove from Queue',
        ),
      ),
    );
  }
}
