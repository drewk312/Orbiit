/// Library Title - represents a game in the user's collection with health data
class LibraryTitle {
  final int id;
  final String gameId;
  final String title;
  final String platform;
  final String? region;
  final String format; // iso, wbfs, rvz
  final String filePath;
  final int fileSizeBytes;
  final String? sha1Partial;
  final String? sha1Full;
  final DateTime addedTimestamp;
  final DateTime modifiedTimestamp;
  final DateTime? lastVerified;
  final HealthStatus healthStatus;
  final bool hasCover;
  final bool hasMetadata;
  final bool isQuarantined;
  final String? quarantineReason;
  final int? variantGroup;

  LibraryTitle({
    required this.id,
    required this.gameId,
    required this.title,
    required this.platform,
    this.region,
    required this.format,
    required this.filePath,
    required this.fileSizeBytes,
    this.sha1Partial,
    this.sha1Full,
    required this.addedTimestamp,
    required this.modifiedTimestamp,
    this.lastVerified,
    this.healthStatus = HealthStatus.unknown,
    this.hasCover = false,
    this.hasMetadata = false,
    this.isQuarantined = false,
    this.quarantineReason,
    this.variantGroup,
  });

  factory LibraryTitle.fromJson(Map<String, dynamic> json) {
    return LibraryTitle(
      id: json['id'] as int,
      gameId: json['game_id'] as String,
      title: json['title'] as String,
      platform: json['platform'] as String,
      region: json['region'] as String?,
      format: json['format'] as String,
      filePath: json['file_path'] as String,
      fileSizeBytes: json['file_size'] as int,
      sha1Partial: json['sha1_partial'] as String?,
      sha1Full: json['sha1_full'] as String?,
      addedTimestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['added_timestamp'] as int) * 1000),
      modifiedTimestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['modified_timestamp'] as int) * 1000),
      lastVerified: json['last_verified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['last_verified'] as int) * 1000)
          : null,
      healthStatus: HealthStatus.fromString(json['health_status'] as String),
      hasCover: (json['has_cover'] as int) == 1,
      hasMetadata: (json['has_metadata'] as int) == 1,
      isQuarantined: (json['is_quarantined'] as int) == 1,
      quarantineReason: json['quarantine_reason'] as String?,
      variantGroup: json['variant_group'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'game_id': gameId,
        'title': title,
        'platform': platform,
        'region': region,
        'format': format,
        'file_path': filePath,
        'file_size': fileSizeBytes,
        'sha1_partial': sha1Partial,
        'sha1_full': sha1Full,
        'added_timestamp': addedTimestamp.millisecondsSinceEpoch ~/ 1000,
        'modified_timestamp': modifiedTimestamp.millisecondsSinceEpoch ~/ 1000,
        'last_verified':
            lastVerified != null ? lastVerified!.millisecondsSinceEpoch ~/ 1000 : null,
        'health_status': healthStatus.toString().split('.').last,
        'has_cover': hasCover ? 1 : 0,
        'has_metadata': hasMetadata ? 1 : 0,
        'is_quarantined': isQuarantined ? 1 : 0,
        'quarantine_reason': quarantineReason,
        'variant_group': variantGroup,
      };

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes} B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum HealthStatus {
  healthy,
  duplicate,
  corrupted,
  missingMetadata,
  unknown;

  static HealthStatus fromString(String value) {
    switch (value) {
      case 'healthy':
        return HealthStatus.healthy;
      case 'duplicate':
        return HealthStatus.duplicate;
      case 'corrupted':
        return HealthStatus.corrupted;
      case 'missing_metadata':
        return HealthStatus.missingMetadata;
      default:
        return HealthStatus.unknown;
    }
  }
}
