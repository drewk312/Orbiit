import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_result.dart';
import '../providers/forge_provider.dart';

class SmartDownloadButton extends StatelessWidget {
  final GameResult game;
  final VoidCallback? onPressed;
  const SmartDownloadButton({required this.game, super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(builder: (context, forge, child) {
      final isMe = forge.currentGame?.title == game.title && forge.isForging;
      final queued = forge.isQueued(game);

      // Currently downloading
      if (isMe) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: forge.progress,
                    strokeWidth: 3,
                    color: const Color(0xFF00C2FF),
                  ),
                  Text('${(forge.progress * 100).toInt()}%',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(forge.statusMessage,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        );
      }

      // Already queued
      if (queued) {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Queued'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white70,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      // Idle state
      return ElevatedButton.icon(
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Download'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C2FF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed ??
            () {
              Provider.of<ForgeProvider>(context, listen: false)
                  .startForge(game);
            },
      );
    });
  }
}
