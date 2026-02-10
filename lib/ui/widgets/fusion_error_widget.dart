import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../fusion/design_system.dart';

/// A polished error widget to replace the default "Red Screen of Death".
/// Matches the Orbiit/Fusion design system.
class FusionErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  final VoidCallback? onRestart;

  const FusionErrorWidget({
    super.key,
    required this.details,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 500,
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: FusionColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FusionColors.error.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: FusionColors.void_.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FusionColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: FusionColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: FusionColors.starlight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'An error occurred while rendering this component.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FusionColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FusionColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FusionColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ERROR DETAILS:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: FusionColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      details.exceptionAsString(),
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: FusionColors.textDisabled,
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text:
                            'Orbiit Error:\n${details.exceptionAsString()}\n\nStack Trace:\n${details.stack}',
                      ));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FusionColors.textSecondary,
                      side: const BorderSide(color: FusionColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (onRestart != null) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Restart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FusionColors.nebulaCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
