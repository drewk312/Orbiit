import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forge_provider.dart';
import '../ui/fusion/design_system.dart';

/// Compact, non-blocking download notification
/// Can be minimized to just show progress, or dismissed to hide completely
class DownloadStatusOverlay extends StatefulWidget {
  const DownloadStatusOverlay({super.key});

  @override
  State<DownloadStatusOverlay> createState() => _DownloadStatusOverlayState();
}

class _DownloadStatusOverlayState extends State<DownloadStatusOverlay>
    with SingleTickerProviderStateMixin {
  bool _isMinimized = false;
  bool _isDismissed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(builder: (context, forge, child) {
      // Reset dismissed state when a new download starts
      if (forge.isForging && _isDismissed && forge.progress < 0.05) {
        _isDismissed = false;
        _isMinimized = false;
      }

      if (!forge.isForging || forge.currentGame == null || _isDismissed) {
        return const SizedBox.shrink();
      }

      final title = forge.currentGame?.title ?? 'Downloading';
      final progress = forge.progress.clamp(0.0, 1.0);
      final progressPercent = (progress * 100).toStringAsFixed(0);

      // Position at top-right corner
      return Positioned(
        top: 16,
        right: 16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _isMinimized ? 200 : 360,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: OrbColors.bgSecondary.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: OrbColors.orbitCyan.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: OrbColors.orbitCyan.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: _isMinimized
                      ? _buildMinimizedView(
                          title, progress, progressPercent, forge)
                      : _buildExpandedView(
                          title, progress, progressPercent, forge),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMinimizedView(
      String title, double progress, String percent, ForgeProvider forge) {
    return InkWell(
      onTap: () => setState(() => _isMinimized = false),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OrbColors.orbitCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.downloading_rounded,
                    color: OrbColors.orbitCyan,
                    size: 18,
                  ),
                );
              },
            ),
            const SizedBox(width: 10),

            // Progress info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: OrbText.bodySmall.copyWith(
                      color: OrbColors.starWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Mini progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: OrbColors.bgTertiary,
                      valueColor: AlwaysStoppedAnimation(OrbColors.orbitCyan),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Percentage
            Text(
              '$percent%',
              style: OrbText.caption.copyWith(
                color: OrbColors.orbitCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(
      String title, double progress, String percent, ForgeProvider forge) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Download icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OrbColors.orbitCyan, OrbColors.orbitPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: OrbText.titleMedium.copyWith(
                    color: OrbColors.starWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Minimize button
              _buildIconButton(
                icon: Icons.remove_rounded,
                onTap: () => setState(() => _isMinimized = true),
                tooltip: 'Minimize',
              ),
              const SizedBox(width: 4),

              // Close button
              _buildIconButton(
                icon: Icons.close_rounded,
                onTap: () => setState(() => _isDismissed = true),
                tooltip: 'Hide',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: OrbColors.bgTertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 8,
                width: progress * 328, // Approximate width
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OrbColors.orbitCyan, OrbColors.orbitPurple],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: OrbColors.orbitCyan.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status text - simplified, no "pipeline" jargon
              Text(
                progress < 0.01
                    ? 'Starting download...'
                    : progress < 1.0
                        ? 'Downloading...'
                        : 'Complete!',
                style: OrbText.bodySmall.copyWith(
                  color: OrbColors.textSecondary,
                ),
              ),

              // Percentage badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: OrbColors.orbitCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percent%',
                  style: OrbText.caption.copyWith(
                    color: OrbColors.orbitCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              // Pause/Resume Button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (forge.isPaused) {
                      forge.resumeForge();
                    } else {
                      forge.pauseForge();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor:
                        OrbColors.orbitYellow.withValues(alpha: 0.1),
                    foregroundColor: OrbColors.orbitYellow,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: OrbColors.orbitYellow.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        forge.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        forge.isPaused ? 'Resume' : 'Pause',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Cancel Button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    forge.cancelForge();
                    setState(() => _isDismissed = true);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: OrbColors.corrupt.withValues(alpha: 0.1),
                    foregroundColor: OrbColors.corrupt,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: OrbColors.corrupt.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OrbColors.bgTertiary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: OrbColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
