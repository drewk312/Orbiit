import 'package:flutter/material.dart';
import '../../core/models/health_score.dart';
import '../../core/models/health_issue.dart';
import '../../core/models/task.dart';
import '../fusion_ui/fusion_ui.dart';

/// BentoDashboard - Health overview screen with FusionUI
class BentoDashboard extends StatelessWidget {
  final HealthScore? healthScore;
  final List<HealthIssue> topIssues;
  final List<BackgroundTask> activeTasks;
  final VoidCallback onScanPressed;
  final VoidCallback onViewQueuePressed;
  final VoidCallback onFixIssuesPressed;

  const BentoDashboard({
    super.key,
    this.healthScore,
    this.topIssues = const [],
    this.activeTasks = const [],
    required this.onScanPressed,
    required this.onViewQueuePressed,
    required this.onFixIssuesPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: UiColors.wiiCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UiColors.wiiCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: UiColors.wiiCyan),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Library Health',
                  style: UiType.headingLarge,
                ),
              ],
            ),
            actions: [
              ActionButton(
                label: 'SCAN',
                icon: Icons.search_rounded,
                onPressed: onScanPressed,
                outlined: true,
                outlineColor: UiColors.wiiCyan,
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildListDelegate([
                // Health Score Tile
                _HealthScoreTile(score: healthScore, onFixPressed: onFixIssuesPressed),

                // Top Issues Tile
                _TopIssuesTile(issues: topIssues),

                // Space Savings Tile
                _SpaceSavingsTile(healthScore: healthScore),

                // Active Tasks Tile
                _ActiveTasksTile(tasks: activeTasks, onViewQueue: onViewQueuePressed),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreTile extends StatelessWidget {
  final HealthScore? score;
  final VoidCallback onFixPressed;

  const _HealthScoreTile({this.score, required this.onFixPressed});

  @override
  Widget build(BuildContext context) {
    // Determine color based on score
    final displayScore = score?.score ?? 0;
    final grade = score?.grade ?? 'N/A';
    
    Color accent = UiColors.textTertiary;
    if (displayScore >= 90) accent = UiColors.success;
    else if (displayScore >= 70) accent = UiColors.warning;
    else if (displayScore > 0) accent = UiColors.error;

    return GlassCard(
      borderRadius: UiRadius.xxl,
      padding: const EdgeInsets.all(24),
      glowColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'HEALTH SCORE',
                style: UiType.labelMedium.copyWith(color: accent),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayScore',
                    style: UiType.displaySmall.copyWith(fontSize: 56),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'GRADE $grade',
                      style: UiType.labelLarge.copyWith(color: accent),
                    ),
                  ),
                ],
              ),
              if (score != null && displayScore < 100)
                ActionButton(
                  label: 'FIX ISSUES',
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: onFixPressed,
                  gradient: UiGradients.cyan,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopIssuesTile extends StatelessWidget {
  final List<HealthIssue> issues;

  const _TopIssuesTile({required this.issues});

  @override
  Widget build(BuildContext context) {
    final topIssues = issues.take(3).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: UiColors.warning),
              const SizedBox(width: 8),
              Text(
                'TOP ISSUES',
                style: UiType.labelMedium.copyWith(color: UiColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topIssues.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 32, color: UiColors.success),
                    const SizedBox(height: 8),
                    Text(
                      'All Clear!',
                      style: UiType.bodyLarge.copyWith(color: UiColors.success),
                    ),
                  ],
                ),
              ),
            )
          else
            ...topIssues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(issue.severity),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getSeverityColor(issue.severity).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiType.bodyMedium.copyWith(color: UiColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return UiColors.error;
      case Severity.high:
        return UiColors.warning;
      case Severity.medium:
        return UiColors.textSecondary;
      case Severity.low:
        return UiColors.textTertiary;
    }
  }
}

class _SpaceSavingsTile extends StatelessWidget {
  final HealthScore? healthScore;

  const _SpaceSavingsTile({this.healthScore});

  @override
  Widget build(BuildContext context) {
    final savings = healthScore?.formattedPotentialSavings ?? '0 GB';

    return GlassCard(
      glowColor: UiColors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.save_outlined, size: 16, color: UiColors.purple),
              const SizedBox(width: 8),
              Text(
                'POTENTIAL SAVINGS',
                style: UiType.labelMedium.copyWith(color: UiColors.purple),
              ),
            ],
          ),
          const Spacer(),
          Text(
            savings,
            style: UiType.displayMedium.copyWith(color: UiColors.textPrimary, fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            'By converting to RVZ',
            style: UiType.bodyMedium.copyWith(color: UiColors.textSecondary),
          ),
          Text(
            '(Wii games only)',
            style: UiType.labelSmall.copyWith(
              color: UiColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTasksTile extends StatelessWidget {
  final List<BackgroundTask> tasks;
  final VoidCallback onViewQueue;

  const _ActiveTasksTile({required this.tasks, required this.onViewQueue});

  @override
  Widget build(BuildContext context) {
    final runningTasks = tasks.where((t) => t.state == TaskState.running).length;
    final hasRunning = runningTasks > 0;

    return GlassCard(
      glowColor: hasRunning ? UiColors.cyan : UiColors.textTertiary,
      onTap: onViewQueue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: hasRunning ? UiColors.cyan : UiColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                'ACTIVE TASKS',
                style: UiType.labelMedium.copyWith(color: hasRunning ? UiColors.cyan : UiColors.textTertiary),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$runningTasks',
                    style: UiType.displayMedium.copyWith(color: UiColors.textPrimary, fontSize: 40),
                  ),
                  Text(
                    'running now',
                    style: UiType.bodyMedium.copyWith(color: UiColors.textSecondary),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: IconButton(
                  onPressed: onViewQueue,
                  icon: const Icon(Icons.arrow_forward),
                  color: UiColors.textPrimary,
                  iconSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
