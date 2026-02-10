import 'package:flutter/material.dart';
import 'dart:ui';
import '../ui/fusion_ui/fusion_ui.dart';

class PremiumDownloadTile extends StatelessWidget {
  final String title;
  final String status;
  final double progress; // 0.0 to 1.0
  final String speed; // e.g. "12.5 MB/s"
  final String eta; // e.g. "45s"
  final String size; // e.g. "1.2 GB"
  final VoidCallback? onCancel;

  const PremiumDownloadTile({
    super.key,
    required this.title,
    required this.status,
    required this.progress,
    required this.speed,
    required this.eta,
    required this.size,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder makes the progress bar glide smoothly
    // even if the download stream sends "jittery" updates.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Title & Status
                    Row(
                      children: [
                        // Icon Box
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SpaceColors.cyanNeon.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.download_rounded,
                              color: SpaceColors.cyanNeon, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Percentage Text (Monospace prevents jittering width)
                        Text(
                          "${(animatedProgress * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cancel Button
                        if (onCancel != null)
                          GestureDetector(
                            onTap: onCancel,
                            child: const Icon(Icons.close,
                                color: Colors.white38, size: 18),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ROW 2: Smooth Progress Bar
                    Stack(
                      children: [
                        // Track
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // Fill
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 6,
                              width: constraints.maxWidth * animatedProgress,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    SpaceColors.cyanNeon,
                                    Color(0xFF3B82F6)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        SpaceColors.cyanNeon.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ROW 3: Stats Grid (Fixed Widths prevent layout shifts)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                            Icons.speed, speed.isEmpty ? "-- MB/s" : speed),
                        _buildStatItem(
                            Icons.timer_outlined, eta.isEmpty ? "--:--" : eta),
                        _buildStatItem(Icons.data_usage, size),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return SizedBox(
      width: 100, // FIXED WIDTH is the key to stopping flicker
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
