/// Health Score - overall library health assessment
class HealthScore {
  final int score; // 0-100
  final int totalTitles;
  final int healthyCount;
  final int duplicateCount;
  final int corruptedCount;
  final int missingMetadataCount;
  final int totalSizeBytes;
  final int potentialSavingsBytes;
  final DateTime timestamp;

  HealthScore({
    required this.score,
    required this.totalTitles,
    required this.healthyCount,
    required this.duplicateCount,
    required this.corruptedCount,
    required this.missingMetadataCount,
    required this.totalSizeBytes,
    required this.potentialSavingsBytes,
    required this.timestamp,
  });

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    return HealthScore(
      score: json['score'] as int,
      totalTitles: json['total_titles'] as int? ?? 0,
      healthyCount: json['healthy_count'] as int? ?? 0,
      duplicateCount: json['duplicate_count'] as int? ?? 0,
      corruptedCount: json['corrupted_count'] as int? ?? 0,
      missingMetadataCount: json['missing_metadata_count'] as int? ?? 0,
      totalSizeBytes: json['total_size_bytes'] as int? ?? 0,
      potentialSavingsBytes: json['potential_savings_bytes'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as int) * 1000)
          : DateTime.now(),
    );
  }

  String get grade {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 65) return 'D+';
    if (score >= 60) return 'D';
    return 'F';
  }

  String get formattedTotalSize {
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedPotentialSavings {
    if (potentialSavingsBytes < 1024 * 1024 * 1024) {
      return '${(potentialSavingsBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(potentialSavingsBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int get totalIssues => duplicateCount + corruptedCount + missingMetadataCount;

  double get healthPercentage => totalTitles > 0 ? (healthyCount / totalTitles) * 100 : 0;
}
