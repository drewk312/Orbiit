import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_logger.dart';

/// Global error handler for the app
class ErrorHandler {
  static final AppLogger _logger = AppLogger.instance;

  /// Show error dialog to user
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? details,
    VoidCallback? onRetry,
  }) async {
    _logger.error('Showing error dialog: $title - $message');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (details != null)
            TextButton(
              onPressed: () async {
                // Save diagnostics to app documents directory
                try {
                  final dir = await getApplicationDocumentsDirectory();
                  final fname =
                      'wiigc_scan_diag_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';
                  final file = File('${dir.path}/$fname');
                  await file.writeAsString(details);

                  // Inform user
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Diagnostic Saved'),
                        content: Text('Saved diagnostic to:\n${file.path}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  // Silently log; show a simple error dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Save Failed'),
                        content: Text('Failed to save diagnostic: $e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccessDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    _logger.info('Showing success dialog: $title - $message');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show warning dialog
  static Future<void> showWarningDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onContinue,
  }) async {
    _logger.warning('Showing warning dialog: $title - $message');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onContinue != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              child: const Text('Continue'),
            ),
        ],
      ),
    );
  }

  /// Handle async operation with error handling
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingText,
    String? errorTitle,
    String Function(Object)? errorMessage,
    VoidCallback? onRetry,
  }) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(loadingText ?? 'Loading...'),
              ],
            ),
          ),
        );
      }

      // Perform operation
      final result = await operation();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      _logger.error('Async operation failed', error: e);

      // Show error dialog
      if (context.mounted) {
        await showErrorDialog(
          context,
          errorTitle ?? 'Operation Failed',
          errorMessage?.call(e) ?? 'An unexpected error occurred: $e',
          details: e.toString(),
          onRetry: onRetry,
        );
      }

      return null;
    }
  }
}
