import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_result.dart';
import '../../providers/forge_provider.dart';
import '../ui/fusion/design_system.dart';
import '../widgets/xbox_download_card.dart';
import '../widgets/cascading_cover_image.dart';
import '../widgets/immersive_glass_header.dart';
import '../widgets/premium_fallback_cover.dart';

/// Fusion Download Screen
/// Focuses on active download with detailed progress, and clear queue management.
class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(
      builder: (context, forge, child) {
        final active = forge.currentGame;

        return Column(
          children: [
            // Header
            ImmersiveGlassHeader(
              title: 'Downloads',
              subtitle: 'Manage your game installations',
              leading:
                  Icon(Icons.download_rounded, color: FusionColors.textPrimary),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Section: Active Download
                  if (active != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline,
                            color: FusionColors.wiiBlue, size: 20),
                        const SizedBox(width: 8),
                        Text('Downloading Now',
                            style: FusionTypography.headlineMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    XboxStyleDownloadCard(
                      gameTitle: active.title,
                      coverUrl: active.coverUrl,
                      platform: active.platform, // Pass platform for hunting
                      bytesDownloaded: forge.currentDownloadedBytes,
                      totalBytes: forge.currentTotalBytes,
                      speedBytesPerSec: forge.downloadSpeedBps ?? 0.0,
                      isPaused: false, // Future: Implement pause
                      onCancel: forge.cancelForge,
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    // Empty state for active download if queue is also empty?
                    // Or just show nothing here and let Queue handle empty state if both empty.
                    if (forge.downloadQueue.isEmpty) _buildEmptyState(context),
                  ],

                  // Section: Queue
                  if (forge.downloadQueue.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.queue_music,
                            color: FusionColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text('Up Next', style: FusionTypography.headlineMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FusionColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${forge.downloadQueue.length} items',
                            style: const TextStyle(
                                fontSize: 12, color: FusionColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...forge.downloadQueue.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final game = entry.value;
                      return _buildQueueItem(context, game, idx, forge);
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FusionColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: FusionColors.glassBorder),
              ),
              child: const Icon(Icons.cloud_download_outlined,
                  size: 48, color: FusionColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text('No Active Downloads', style: FusionTypography.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Games you download from the Store will appear here.',
              style: FusionTypography.bodyLarge
                  .copyWith(color: FusionColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItem(
      BuildContext context, GameResult game, int index, ForgeProvider forge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FusionColors.surfaceCard,
        borderRadius: BorderRadius.circular(FusionRadius.md),
        border: Border.all(color: FusionColors.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 64,
            child: CascadingCoverImage(
              primaryUrl: game.coverUrl ?? '',
              platform: game.platform, // Correct platform
              title: game.title, // Correct title for hunting
              fit: BoxFit.cover,
              fallbackBuilder: (_) => PremiumFallbackCover(
                title: game.title,
                platform: game.platform,
              ), // Premium fallback
            ),
          ),
        ),
        title: Text(game.title, style: FusionTypography.headlineSmall),
        subtitle: Text('${game.platform} • ${game.size ?? "Unknown Size"}',
            style:
                const TextStyle(color: FusionColors.textMuted, fontSize: 13)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: FusionColors.textSecondary),
          onPressed: () => forge.removeFromQueueAt(index),
          tooltip: 'Remove from Queue',
        ),
      ),
    );
  }
}
