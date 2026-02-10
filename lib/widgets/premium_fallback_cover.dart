import 'package:flutter/material.dart';
import '../ui/fusion/design_system.dart';

class PremiumFallbackCover extends StatelessWidget {
  final String title;
  final String platform;

  const PremiumFallbackCover({
    super.key,
    required this.title,
    required this.platform,
  });

  Color _getPlatformColor() {
    final p = platform.toLowerCase();
    // Nintendo consoles
    if (p == 'wii u' || p == 'wiiu') return const Color(0xFF009AC7);
    if (p == 'wii') return const Color(0xFF00C2FF);
    if (p == 'gamecube' || p == 'gc') return const Color(0xFF6A0DAD);
    if (p == 'n64' || p.contains('nintendo 64'))
      return const Color(0xFF009B4D); // N64 green
    if (p == 'snes' || p.contains('super nintendo'))
      return const Color(0xFF7B68EE); // SNES purple
    if (p == 'nes') return const Color(0xFFE60012); // NES red
    if (p == 'gba' || p.contains('game boy advance'))
      return const Color(0xFF5B3694); // GBA purple
    if (p == 'gbc' || p.contains('game boy color'))
      return const Color(0xFF8B00FF);
    if (p == 'gb' || p == 'game boy') return const Color(0xFF8BBD39);
    if (p == 'nds' || p == 'ds') return const Color(0xFF5A5A5A);
    if (p == '3ds') return const Color(0xFFD4002A);
    // Sega
    if (p == 'genesis' || p.contains('mega drive'))
      return const Color(0xFF0060A8);
    if (p == 'dreamcast') return const Color(0xFFFF6600);
    if (p == 'saturn') return const Color(0xFF003087);
    if (p == 'game gear' || p == 'gg') return const Color(0xFF0060A8);
    // Sony
    if (p == 'ps1' || p == 'psx' || p == 'playstation')
      return const Color(0xFF003791);
    if (p == 'ps2') return const Color(0xFF003791);
    if (p == 'psp') return const Color(0xFF003791);

    return const Color(0xFF555555);
  }

  /// Get the correct platform badge/icon text
  String _getPlatformBadge() {
    final p = platform.toLowerCase();

    if (p == 'wii u' || p == 'wiiu') return 'Wii U';
    if (p == 'wii') return 'Wii';
    if (p == 'gamecube' || p == 'gc') return 'GC';
    if (p == 'n64' || p.contains('nintendo 64')) return 'N64';
    if (p == 'snes' || p.contains('super nintendo')) return 'SNES';
    if (p == 'nes') return 'NES';
    if (p == 'gba' || p.contains('game boy advance')) return 'GBA';
    if (p == 'gbc' || p.contains('game boy color')) return 'GBC';
    if (p == 'gb' || p == 'game boy') return 'GB';
    if (p == 'nds' || p == 'ds') return 'NDS';
    if (p == '3ds') return '3DS';
    if (p == 'genesis' || p.contains('mega drive')) return 'GEN';
    if (p == 'dreamcast') return 'DC';
    if (p == 'saturn') return 'SAT';
    if (p == 'game gear' || p == 'gg') return 'GG';
    if (p == 'ps1' || p == 'psx' || p == 'playstation') return 'PS1';
    if (p == 'ps2') return 'PS2';
    if (p == 'psp') return 'PSP';

    return platform.length > 4
        ? platform.substring(0, 3).toUpperCase()
        : platform.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getPlatformColor();
    final badge = _getPlatformBadge();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Platform-styled icon/logo area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getPlatformIcon(),
                color: Colors.white.withValues(alpha: 0.7),
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon() {
    final p = platform.toLowerCase();
    // Game controllers/consoles
    if (p == 'wii' || p == 'wii u' || p == 'wiiu')
      return Icons.sports_esports_rounded;
    if (p == 'gamecube' || p == 'gc') return Icons.gamepad_rounded;
    if (p == 'n64') return Icons.gamepad_rounded;
    if (p == 'snes' || p == 'nes') return Icons.videogame_asset_rounded;
    if (p == 'gba' ||
        p == 'gbc' ||
        p == 'gb' ||
        p == 'nds' ||
        p == 'ds' ||
        p == '3ds') {
      return Icons.phone_android_rounded; // Handheld
    }
    if (p == 'psp') return Icons.phone_android_rounded;
    if (p == 'genesis' ||
        p == 'dreamcast' ||
        p == 'saturn' ||
        p == 'game gear' ||
        p == 'gg') {
      return Icons.gamepad_rounded;
    }
    if (p == 'ps1' || p == 'ps2' || p == 'psx') return Icons.gamepad_rounded;

    return Icons.videogame_asset_rounded;
  }
}
