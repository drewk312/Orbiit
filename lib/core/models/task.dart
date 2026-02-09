/// Background Task - represents an asynchronous operation in the queue
class BackgroundTask {
  final int id;
  final TaskType taskType;
  final TaskState state;
  final int priority;
  final Map<String, dynamic> payload;
  final double progressPercent;
  final String? progressMessage;
  final DateTime? startedTimestamp;
  final DateTime? completedTimestamp;
  final String? errorMessage;
  final int? dependsOn;
  final int retryCount;
  final String? logPath;

  BackgroundTask({
    required this.id,
    required this.taskType,
    required this.state,
    this.priority = 5,
    required this.payload,
    this.progressPercent = 0.0,
    this.progressMessage,
    this.startedTimestamp,
    this.completedTimestamp,
    this.errorMessage,
    this.dependsOn,
    this.retryCount = 0,
    this.logPath,
  });

  factory BackgroundTask.fromJson(Map<String, dynamic> json) {
    return BackgroundTask(
      id: json['id'] as int,
      taskType: TaskType.fromString(json['task_type'] as String),
      state: TaskState.fromString(json['state'] as String),
      priority: json['priority'] as int? ?? 5,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      progressMessage: json['progress_message'] as String?,
      startedTimestamp: json['started_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['started_timestamp'] as int) * 1000)
          : null,
      completedTimestamp: json['completed_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['completed_timestamp'] as int) * 1000)
          : null,
      errorMessage: json['error_message'] as String?,
      dependsOn: json['depends_on'] as int?,
      retryCount: json['retry_count'] as int? ?? 0,
      logPath: json['log_path'] as String?,
    );
  }

  bool get canPause => state == TaskState.running;
  bool get canResume => state == TaskState.paused;
  bool get canCancel => state == TaskState.running || state == TaskState.paused || state == TaskState.queued;
  bool get canRetry => state == TaskState.failed;
  bool get isComplete => state == TaskState.completed;
  bool get isFailed => state == TaskState.failed;

  Duration? get elapsed {
    if (startedTimestamp == null) return null;
    final end = completedTimestamp ?? DateTime.now();
    return end.difference(startedTimestamp!);
  }

  String? get estimatedTimeRemaining {
    if (state != TaskState.running || progressPercent <= 0) return null;
    final elapsed = this.elapsed;
    if (elapsed == null) return null;

    final totalEstimated = elapsed.inSeconds / (progressPercent / 100.0);
    final remaining = totalEstimated - elapsed.inSeconds;

    if (remaining < 60) return '${remaining.toInt()}s';
    if (remaining < 3600) return '${(remaining / 60).toInt()}m';
    return '${(remaining / 3600).toStringAsFixed(1)}h';
  }
}

enum TaskType {
  scan,
  verify,
  convert,
  fetchMetadata,
  quarantine,
  restore;

  static TaskType fromString(String value) {
    switch (value) {
      case 'scan':
        return TaskType.scan;
      case 'verify':
        return TaskType.verify;
      case 'convert':
        return TaskType.convert;
      case 'fetch_metadata':
        return TaskType.fetchMetadata;
      case 'quarantine':
        return TaskType.quarantine;
      case 'restore':
        return TaskType.restore;
      default:
        return TaskType.scan;
    }
  }

  String get displayName {
    switch (this) {
      case TaskType.scan:
        return 'Scan';
      case TaskType.verify:
        return 'Verify';
      case TaskType.convert:
        return 'Convert';
      case TaskType.fetchMetadata:
        return 'Fetch Metadata';
      case TaskType.quarantine:
        return 'Quarantine';
      case TaskType.restore:
        return 'Restore';
    }
  }
}

enum TaskState {
  queued,
  running,
  paused,
  completed,
  failed;

  static TaskState fromString(String value) {
    switch (value) {
      case 'queued':
        return TaskState.queued;
      case 'running':
        return TaskState.running;
      case 'paused':
        return TaskState.paused;
      case 'completed':
        return TaskState.completed;
      case 'failed':
        return TaskState.failed;
      default:
        return TaskState.queued;
    }
  }
}
