/// Fix Plan - recommended actions to improve library health
class FixPlan {
  final List<FixAction> actions;
  final int projectedScoreImprovement;
  final int projectedSpaceSavings;
  final DateTime generated;

  FixPlan({
    required this.actions,
    required this.projectedScoreImprovement,
    required this.projectedSpaceSavings,
    required this.generated,
  });

  factory FixPlan.fromJson(Map<String, dynamic> json) {
    return FixPlan(
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => FixAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      projectedScoreImprovement:
          json['projected_score_improvement'] as int? ?? 0,
      projectedSpaceSavings: json['projected_space_savings'] as int? ?? 0,
      generated: json['generated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['generated'] as int) * 1000)
          : DateTime.now(),
    );
  }

  int get totalActions => actions.length;

  String get formattedSavings {
    if (projectedSpaceSavings < 1024 * 1024 * 1024) {
      return '${(projectedSpaceSavings / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(projectedSpaceSavings / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class FixAction {
  final String actionType; // quarantine, convert, fetch_metadata, verify
  final String description;
  final int priority;
  final int scoreImpact;
  final int spaceSavings;
  final Map<String, dynamic> parameters;

  FixAction({
    required this.actionType,
    required this.description,
    this.priority = 5,
    this.scoreImpact = 0,
    this.spaceSavings = 0,
    required this.parameters,
  });

  factory FixAction.fromJson(Map<String, dynamic> json) {
    return FixAction(
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      priority: json['priority'] as int? ?? 5,
      scoreImpact: json['score_impact'] as int? ?? 0,
      spaceSavings: json['space_savings'] as int? ?? 0,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
    );
  }

  String get displayName {
    switch (actionType) {
      case 'quarantine':
        return 'Quarantine Duplicates';
      case 'convert':
        return 'Convert to RVZ';
      case 'fetch_metadata':
        return 'Fetch Missing Metadata';
      case 'verify':
        return 'Verify Files';
      default:
        return actionType;
    }
  }
}
