import 'package:flutter/material.dart';
import '../services/download_service.dart';

/// Download Queue Widget - Shows active and queued downloads
class DownloadQueueWidget extends StatelessWidget {
  final DownloadService downloadService;

  const DownloadQueueWidget({
    required this.downloadService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      stream: downloadService.queueStream,
      initialData: downloadService.queue,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Downloads',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Task list
              ...tasks.take(5).map((task) => _buildTaskItem(context, task)),

              if (tasks.length > 5)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      '+${tasks.length - 5} more in queue',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, DownloadTask task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and status
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(task),
              if (task.status == DownloadStatus.downloading ||
                  task.status == DownloadStatus.pending)
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                  onPressed: () => downloadService.cancelDownload(task.id),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),

          // Progress bar (for downloading)
          if (task.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.formattedSize,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                Text(
                  task.progressPercent,
                  style: TextStyle(color: Colors.blue[400], fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DownloadTask task) {
    Color color;
    IconData icon;

    switch (task.status) {
      case DownloadStatus.pending:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
      case DownloadStatus.downloading:
        color = Colors.blue;
        icon = Icons.download;
      case DownloadStatus.extracting:
        color = Colors.orange;
        icon = Icons.unarchive;
      case DownloadStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
      case DownloadStatus.error:
        color = Colors.red;
        icon = Icons.error;
      case DownloadStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
      case DownloadStatus.retrying:
        color = Colors.purple;
        icon = Icons.refresh;
      case DownloadStatus.paused:
        color = Colors.orange;
        icon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            task.statusText,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Compact download indicator for the sidebar/header
class DownloadIndicator extends StatelessWidget {
  final DownloadService downloadService;
  final VoidCallback? onTap;

  const DownloadIndicator({
    required this.downloadService,
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      stream: downloadService.queueStream,
      initialData: downloadService.queue,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final activeCount = tasks
            .where((t) =>
                t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.pending)
            .length;

        if (activeCount == 0) {
          return const SizedBox.shrink();
        }

        final currentTask = downloadService.currentDownload;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: currentTask?.progress,
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$activeCount downloading',
                  style: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
