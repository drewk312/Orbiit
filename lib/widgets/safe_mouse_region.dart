// ═══════════════════════════════════════════════════════════════════════════
// SAFE MOUSE REGION
// WiiGC-Fusion - Error-safe MouseRegion wrapper for debugging
// ═══════════════════════════════════════════════════════════════════════════
//
// This widget wraps MouseRegion to catch and log errors with widget
// identification, making it easier to debug mouse tracker assertion errors.
//
// Usage:
//   SafeMouseRegion(
//     widgetName: 'TactileBentoCard',
//     onEnter: (event) { ... },
//     onHover: (event) { ... },
//     onExit: (event) { ... },
//     child: ...,
//   )
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A MouseRegion wrapper that catches errors and logs widget identification
class SafeMouseRegion extends StatelessWidget {
  /// The name/identifier of the widget using this MouseRegion (for debugging)
  final String widgetName;

  /// Optional callback for when the mouse enters the region
  final void Function(PointerEnterEvent)? onEnter;

  /// Optional callback for when the mouse moves within the region
  final void Function(PointerHoverEvent)? onHover;

  /// Optional callback for when the mouse exits the region
  final void Function(PointerExitEvent)? onExit;

  /// The child widget
  final Widget child;

  /// Whether to enable mouse tracking
  final bool cursor;

  /// Whether to enable hover effects
  final bool opaque;

  const SafeMouseRegion({
    super.key,
    required this.widgetName,
    required this.child,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.cursor = true,
    this.opaque = true,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor ? SystemMouseCursors.click : MouseCursor.defer,
      opaque: opaque,
      onEnter: onEnter != null
          ? (event) {
              try {
                onEnter!(event);
              } catch (e, stack) {
                _logError('onEnter', e, stack);
              }
            }
          : null,
      onHover: onHover != null
          ? (event) {
              try {
                onHover!(event);
              } catch (e, stack) {
                _logError('onHover', e, stack);
              }
            }
          : null,
      onExit: onExit != null
          ? (event) {
              try {
                onExit!(event);
              } catch (e, stack) {
                _logError('onExit', e, stack);
              }
            }
          : null,
      child: child,
    );
  }

  void _logError(String callbackName, Object error, StackTrace stack) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('MOUSE REGION ERROR DETECTED');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('Widget: $widgetName');
    debugPrint('Callback: $callbackName');
    debugPrint('Error: $error');
    debugPrint('Stack Trace:');
    debugPrint(stack.toString());
    debugPrint('═══════════════════════════════════════════════════════════');

    // Extract file path and line number
    final stackStr = stack.toString();
    final stackLines = stackStr.split('\n');
    final List<String> relevantFiles = [];

    for (final line in stackLines) {
      if (line.contains('.dart:')) {
        // Try package: URL format first
        var match =
            RegExp(r'package:([a-zA-Z0-9_]+)/([a-zA-Z0-9_/\\]+\.dart):(\d+)')
                .firstMatch(line);
        if (match != null) {
          final relativePath = match.group(2);
          final lineNum = match.group(3);
          final fullPath = 'lib/$relativePath';
          relevantFiles.add('$fullPath:$lineNum');
        } else {
          // Try direct file path format
          match = RegExp(r'([a-zA-Z0-9_/\\:\.]+\.dart):(\d+)').firstMatch(line);
          if (match != null) {
            final path = match.group(1);
            final lineNum = match.group(2);
            if (path != null &&
                path.contains('wiigc_fusion') &&
                !path.contains('flutter')) {
              relevantFiles.add('$path:$lineNum');
            }
          }
        }
      }
    }

    if (relevantFiles.isNotEmpty) {
      debugPrint('Relevant Files:');
      for (final file in relevantFiles.take(5)) {
        debugPrint('  • $file');
      }
    }
  }
}
