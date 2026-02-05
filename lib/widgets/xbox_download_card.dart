import 'dart:ui';
import 'package:flutter/material.dart';
import 'cascading_cover_image.dart';

import 'premium_fallback_cover.dart';

/// Premium "Apple-like" Download Card
/// Glassmorphism, subtle gradients, clean typography.
/// Replaces the old Xbox-style card but keeps the name to avoid breaking imports.
class XboxStyleDownloadCard extends StatelessWidget {
  final String gameTitle;
  final String? coverUrl;
  final String platform; // Added for cover art hunting
  final int bytesDownloaded;
  final int totalBytes;
  final double speedBytesPerSec;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final bool isPaused;
  final bool isQueued;

  const XboxStyleDownloadCard({
    super.key,
    required this.gameTitle,
    this.coverUrl,
    this.platform = 'wii', // Default for backward compatibility
    this.bytesDownloaded = 0,
    this.totalBytes = 1, // Avoid div by zero
    this.speedBytesPerSec = 0,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.isPaused = false,
    this.isQueued = false,
  });

  @override
  Widget build(BuildContext context) {
    // Progress calculation
    final progress =
        totalBytes > 0 ? (bytesDownloaded / totalBytes).clamp(0.0, 1.0) : 0.0;

    final percentage = (progress * 100).toStringAsFixed(1);
    final sizeStr = _formatBytes(totalBytes);
    final downloadedStr = _formatBytes(bytesDownloaded);

    // Status Text
    String statusText;
    if (isQueued) {
      statusText = 'Queued';
    } else if (isPaused) {
      statusText = 'Paused';
    } else {
      // Calculate ETA
      if (speedBytesPerSec > 0) {
        final remainingBytes = totalBytes - bytesDownloaded;
        final secondsRemaining = remainingBytes / speedBytesPerSec;
        statusText =
            'Downloading • ${_formatDuration(Duration(seconds: secondsRemaining.round()))} remaining';
      } else {
        statusText = 'Starting...';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16), // Rounded corners (Apple style)
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Heavy glass blur
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08), // Very subtle fill
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Colors.white.withValues(alpha: 0.12), // Subtle glass border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cover Art (with shadow)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 90,
                    child: CascadingCoverImage(
                      primaryUrl: coverUrl ?? '',
                      platform: platform,
                      title: gameTitle, // Activate title-based hunting
                      fit: BoxFit.cover,
                      fallbackBuilder: (context) => PremiumFallbackCover(
                        title: gameTitle,
                        platform: platform,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      gameTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3, // San Francisco style tracking
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Status & Speed row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (!isQueued && !isPaused && speedBytesPerSec > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatSpeed(speedBytesPerSec),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPaused
                              ? Colors.amber
                              : const Color(0xFF0A84FF), // iOS Blue or Amber
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Stats Row (Size)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$downloadedStr / $sizeStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Controls (Apple-style circle buttons)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onPause != null) ...[
                    _CircleButton(
                      icon: isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      onTap: isPaused ? onResume : onPause,
                      tooltip: isPaused ? 'Resume' : 'Pause',
                    ),
                    const SizedBox(width: 12),
                  ],
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: onCancel,
                    tooltip: 'Cancel',
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(double bytesPerSec) {
    // Show MB/s
    final mbps = bytesPerSec / (1024 * 1024);
    return '${mbps.toStringAsFixed(1)} MB/s';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }
}

class _CircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isDestructive;

  const _CircleButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
    this.isDestructive = false,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  // Use ValueNotifier to avoid setState in MouseRegion callbacks
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hovered,
            builder: (context, isHovered, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered
                      ? (widget.isDestructive
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2))
                      : Colors.transparent,
                  border: Border.all(
                    color: isHovered
                        ? (widget.isDestructive
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.5))
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: isHovered
                      ? (widget.isDestructive
                          ? const Color(0xFFFF453A)
                          : Colors.white)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
