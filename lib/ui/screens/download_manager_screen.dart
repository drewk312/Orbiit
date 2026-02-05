import 'package:flutter/material.dart';

import '../widgets/cover_art_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/forge_provider.dart';

/// Xbox-style download manager screen
/// Shows active downloads with cover art, progress bars, and download speeds
class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(
      builder: (context, forge, child) {
        final activeDownloads = forge.getActiveDownloads();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Downloads'),
            actions: [
              // Clear completed button
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  forge.clearCompletedDownloads();
                },
                tooltip: 'Clear Completed',
              ),
            ],
          ),
          body: activeDownloads.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeDownloads.length,
                  itemBuilder: (context, index) {
                    final download = activeDownloads[index];
                    return _buildXboxStyleDownloadCard(download, forge);
                  },
                ),
        );
      },
    );
  }

  /// Empty state when no downloads
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Downloads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Games you download will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Xbox-style download card with cover art
  Widget _buildXboxStyleDownloadCard(
      ActiveDownload download, ForgeProvider forge) {
    final progress = forge.progress;
    final speed = forge.formattedDownloadSpeed;
    final eta = forge.formattedEta;
    final status = forge.status;

    // Determine status color
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'downloading':
        statusColor = Colors.blue;
        statusIcon = Icons.download;
        break;
      case 'complete':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'paused':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art (Xbox-style thumbnail)
            Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CoverArtWidget(
                  gameId: download.gameId,
                  platform: download.platform,
                  region: download.region,
                  title: download.title,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Download info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    download.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Platform + Region
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: download.platform == 'Wii'
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          download.platform,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: download.platform == 'Wii'
                                ? Colors.blue[700]
                                : Colors.purple[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        download.region,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Icon(statusIcon, color: statusColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar (Xbox-style)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Download stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Percentage
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),

                      // Speed
                      if (status == 'downloading')
                        Row(
                          children: [
                            Icon(Icons.speed,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              speed,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                      // ETA
                      if (status == 'downloading' && eta.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              eta,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      if (status == 'downloading')
                        TextButton.icon(
                          onPressed: () {
                            forge.pauseForge();
                          },
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('Pause'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      if (status == 'paused')
                        TextButton.icon(
                          onPressed: () {
                            forge.resumeForge();
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Resume'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          forge.cancelForge();
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
