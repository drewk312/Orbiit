/// Health Issue - represents a problem detected in the library
class HealthIssue {
  final int id;
  final int? titleId;
  final IssueType issueType;
  final Severity severity;
  final String description;
  final int estimatedImpactScore;
  final int estimatedSpaceSavings;
  final String? fixAction;
  final DateTime createdTimestamp;
  final DateTime? resolvedTimestamp;

  HealthIssue({
    required this.id,
    this.titleId,
    required this.issueType,
    required this.severity,
    required this.description,
    this.estimatedImpactScore = 0,
    this.estimatedSpaceSavings = 0,
    this.fixAction,
    required this.createdTimestamp,
    this.resolvedTimestamp,
  });

  factory HealthIssue.fromJson(Map<String, dynamic> json) {
    return HealthIssue(
      id: json['id'] as int,
      titleId: json['title_id'] as int?,
      issueType: IssueType.fromString(json['issue_type'] as String),
      severity: Severity.fromString(json['severity'] as String),
      description: json['description'] as String,
      estimatedImpactScore: json['estimated_impact_score'] as int? ?? 0,
      estimatedSpaceSavings: json['estimated_space_savings'] as int? ?? 0,
      fixAction: json['fix_action'] as String?,
      createdTimestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['created_timestamp'] as int) * 1000),
      resolvedTimestamp: json['resolved_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['resolved_timestamp'] as int) * 1000)
          : null,
    );
  }

  bool get isResolved => resolvedTimestamp != null;

  String get formattedSpaceSavings {
    if (estimatedSpaceSavings == 0) return '—';
    if (estimatedSpaceSavings < 1024 * 1024) {
      return '${(estimatedSpaceSavings / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(estimatedSpaceSavings / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum IssueType {
  duplicate,
  corrupted,
  missingCover,
  spaceOptimization,
  truncated,
  invalidFormat;

  static IssueType fromString(String value) {
    switch (value) {
      case 'duplicate':
        return IssueType.duplicate;
      case 'corrupted':
        return IssueType.corrupted;
      case 'missing_cover':
        return IssueType.missingCover;
      case 'space_optimization':
        return IssueType.spaceOptimization;
      case 'truncated':
        return IssueType.truncated;
      case 'invalid_format':
        return IssueType.invalidFormat;
      default:
        return IssueType.corrupted;
    }
  }

  String get displayName {
    switch (this) {
      case IssueType.duplicate:
        return 'Duplicate';
      case IssueType.corrupted:
        return 'Corrupted';
      case IssueType.missingCover:
        return 'Missing Cover';
      case IssueType.spaceOptimization:
        return 'Can Optimize';
      case IssueType.truncated:
        return 'Truncated';
      case IssueType.invalidFormat:
        return 'Invalid Format';
    }
  }
}

enum Severity {
  critical,
  high,
  medium,
  low;

  static Severity fromString(String value) {
    switch (value) {
      case 'critical':
        return Severity.critical;
      case 'high':
        return Severity.high;
      case 'medium':
        return Severity.medium;
      case 'low':
        return Severity.low;
      default:
        return Severity.low;
    }
  }
}
