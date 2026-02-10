import 'package:flutter/material.dart';
import '../../core/models/task.dart';

/// Queue Screen - View and control background tasks
class QueueScreen extends StatelessWidget {
  final List<BackgroundTask> tasks;
  final Function(int taskId) onPause;
  final Function(int taskId) onResume;
  final Function(int taskId) onCancel;
  final Function(int taskId) onRetry;

  const QueueScreen({
    super.key,
    required this.tasks,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Task Queue'),
        backgroundColor: isDark ? const Color(0xFF12121A) : Colors.white,
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No active tasks',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TaskCard(
                    task: task,
                    onPause: () => onPause(task.id),
                    onResume: () => onResume(task.id),
                    onCancel: () => onCancel(task.id),
                    onRetry: () => onRetry(task.id),
                  ),
                );
              },
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final BackgroundTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _TaskCard({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16162A)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _StateIndicator(state: task.state),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskType.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (task.progressMessage != null)
                      Text(
                        task.progressMessage!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              _buildActions(),
            ],
          ),

          // Progress bar
          if (task.state == TaskState.running) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.progressPercent / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00C2FF)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${task.progressPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (task.estimatedTimeRemaining != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '~${task.estimatedTimeRemaining} remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
          ],

          // Error message
          if (task.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.canPause)
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause, size: 20),
            tooltip: 'Pause',
          ),
        if (task.canResume)
          IconButton(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow, size: 20),
            tooltip: 'Resume',
          ),
        if (task.canRetry)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Retry',
          ),
        if (task.canCancel)
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Cancel',
          ),
      ],
    );
  }
}

class _StateIndicator extends StatelessWidget {
  final TaskState state;

  const _StateIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStateInfo();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  (Color, IconData) _getStateInfo() {
    switch (state) {
      case TaskState.queued:
        return (Colors.grey, Icons.schedule);
      case TaskState.running:
        return (const Color(0xFF00C2FF), Icons.play_circle_filled);
      case TaskState.paused:
        return (Colors.orange, Icons.pause_circle_filled);
      case TaskState.completed:
        return (Colors.green, Icons.check_circle);
      case TaskState.failed:
        return (Colors.red, Icons.error);
    }
  }
}
