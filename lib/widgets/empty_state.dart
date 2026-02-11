import 'package:flutter/material.dart';
import '../ui/fusion/design_system.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.title = 'No items found',
    this.icon,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 64,
                  color: FusionColors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                title,
                style: FusionTypography.headlineMedium.copyWith(
                  color: FusionColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: FusionTypography.bodyLarge.copyWith(
                    color: FusionColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 32),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
