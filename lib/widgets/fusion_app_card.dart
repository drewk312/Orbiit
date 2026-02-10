import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../ui/fusion/design_system.dart';
import 'cascading_cover_image.dart';
import 'premium_fallback_cover.dart';

/// FusionAppCard - Professional-grade game card matching TinyWii structure
/// Version/Size at top corners, Image in center, [INFO][ARCHIVE][GET] buttons at bottom
class FusionAppCard extends StatefulWidget {
  final GameResult game;
  final VoidCallback? onInfo;
  final VoidCallback? onArchive;
  final VoidCallback? onForge;
  final VoidCallback? onDownload;
  final bool isLoading;
  final String
      downloadStatus; // 'idle', 'downloading', 'unzipping', 'ready', 'error'
  final double downloadProgress;
  final String? localCover; // ⚡ Added for instant local display

  const FusionAppCard({
    super.key,
    required this.game,
    this.onInfo,
    this.onArchive,
    this.onForge,
    this.onDownload,
    this.isLoading = false,
    this.downloadStatus = 'idle',
    this.downloadProgress = 0.0,
    this.localCover,
  });

  @override
  State<FusionAppCard> createState() => _FusionAppCardState();
}

class _FusionAppCardState extends State<FusionAppCard> {
  // Track hover state - use simple bool with setState wrapped in WidgetsBinding
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setHovered(bool value) {
    // Schedule setState to avoid build-phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isHovering != value) {
        setState(() => _isHovering = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platformLower = widget.game.platform.toLowerCase();
    final isWii = platformLower == 'wii';
    final isHomebrew = platformLower.contains('homebrew');
    // Use platform-specific colors
    final accentColor = isHomebrew
        ? const Color(0xFFB000FF) // Purple for homebrew
        : _getPlatformColor(widget.game.platform);
    final isHovering = _isHovering;

    // ⚡ Prefer local cover if available
    final displayUrl = widget.localCover ?? widget.game.coverUrl ?? '';
    final hasDisplayImage = displayUrl.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(isHovering ? 1.02 : 1.0, isHovering ? 1.02 : 1.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.4 : 0.2),
                blurRadius: isHovering ? 32 : 16,
                spreadRadius: isHovering ? 4 : 0,
                offset: Offset(0, isHovering ? 12 : 6),
              ),
              if (isHovering)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16162A)]
                      : [Colors.white, const Color(0xFFF8F9FA)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Intelligent Cover Art Rendering with cascading fallback
                  // Always use CascadingCoverImage - it handles null URLs with Libretro fallback
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1A. Background Layer with Cascading Fallback
                      CascadingCoverImage(
                        // CascadingCoverImage uses Libretro thumbnails as fallback
                        primaryUrl: displayUrl,
                        gameId: widget.game.gameId,
                        platform: widget.game.platform,
                        title: widget.game.title,
                        fit: BoxFit.cover,
                        fallbackBuilder: (context) => PremiumFallbackCover(
                          title: widget.game.title,
                          platform: widget.game.platform,
                        ),
                      ),

                      // 1B. Blur Layer (only for Homebrew to hide pixelation)
                      if (isHomebrew && hasDisplayImage) ...[
                        BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                        // 1C. Sharp Icon Layer
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.6,
                            child: !displayUrl.startsWith('http')
                                ? Image.file(
                                    File(displayUrl),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  )
                                : Image.network(
                                    displayUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                          ),
                        ),
                      ]
                    ],
                  ),

                  // 2. Glass Gradient Overlay (Essential for text readability)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.7),
                          Colors
                              .black, // Fully black at bottom for max contrast
                        ],
                        stops: const [0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),

                  // 3. Top Badges (floating)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _buildTopSection(accentColor, isWii, isHomebrew),
                  ),

                  // 4. Title & Actions (Bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title with strong shadow
                          Text(
                            widget.game.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.2,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Action Buttons
                          _buildBottomSection(accentColor, true,
                              isHovering), // Force dark mode for actions
                        ],
                      ),
                    ),
                  ),

                  // 5. Loading Overlay
                  if (widget.isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(Color accentColor, bool isWii, bool isHomebrew) {
    // User requested "logo on the other side" - so we restore visibility and swap positions.
    // Platform Badge: Right
    // Size Badge: Left

    String badgeText;
    if (isHomebrew) {
      badgeText = widget.game.region ?? 'APP';
    } else {
      // Properly detect platform from game data
      badgeText = _getPlatformBadge(widget.game.platform);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          8, 8, 8, 0), // Reduced padding to prevent overflow
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Size badge (Glassmorphic, Smaller) - NOW ON LEFT
          if (widget.game.size != null)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(FusionRadius.sm),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.game.size!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Changed to ellipsis
                ),
              ),
            )
          else
            const SizedBox(), // Spacer

          const SizedBox(width: 4),

          // Platform/Category badge - NOW ON RIGHT
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.9),
                borderRadius:
                    BorderRadius.circular(FusionRadius.md), // More rounded
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11, // Slightly larger for "Logo" feel
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter', // Ensure brand font
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Changed to ellipsis
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(Color accentColor, bool isDark, bool isHovering) {
    // Logic: If we have detailed actions (Info/Archive), show the multi-button row.
    // Otherwise, if we only have a download action, show the big button.
    final bool showBigButton = widget.onInfo == null &&
        widget.onArchive == null &&
        widget.onDownload != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // Option A: Single Big Download Button
          if (showBigButton)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onDownload,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(
                              alpha: isHovering ? 0.5 : 0.3),
                          blurRadius: isHovering ? 20 : 12,
                          spreadRadius: isHovering ? 2 : 0,
                          offset: Offset(0, isHovering ? 6 : 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 22,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'DOWNLOAD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // Option B: Multi-Action Row (Info, Archive, Download)

            // [INFO] Button
            Expanded(
              child: _buildActionButton(
                'INFO',
                Icons.info_outline,
                accentColor.withValues(alpha: 0.6),
                widget.onInfo,
              ),
            ),
            const SizedBox(width: 8),

            // [ARCHIVE] Button
            Expanded(
              child: _buildActionButton(
                'ARCHIVE',
                Icons.archive_outlined,
                accentColor.withValues(alpha: 0.6),
                widget.onArchive,
              ),
            ),
            const SizedBox(width: 8),

            // [DOWNLOAD] Button (Uses onForge OR onDownload)
            Expanded(
              child: _buildActionButton(
                'DOWNLOAD',
                Icons.download,
                accentColor,
                widget.onForge ?? widget.onDownload,
                isPrimary: true,
              ),
            ),
          ]
        ],
      ),
    );
  }

  /// Get the correct platform badge text based on game platform
  String _getPlatformBadge(String platform) {
    final lower = platform.toLowerCase();

    // Nintendo consoles
    if (lower == 'wii' ||
        lower.contains('wii') &&
            !lower.contains('wii u') &&
            !lower.contains('wiiu')) return 'Wii';
    if (lower == 'wii u' || lower == 'wiiu') return 'Wii U';
    if (lower == 'gamecube' || lower == 'gc') return 'GC';
    if (lower == 'n64' || lower.contains('nintendo 64')) return 'N64';
    if (lower == 'snes' || lower.contains('super nintendo') || lower == 'sfc')
      return 'SNES';
    if (lower == 'nes' || lower == 'famicom') return 'NES';
    if (lower == 'gba' || lower.contains('game boy advance')) return 'GBA';
    if (lower == 'gbc' || lower.contains('game boy color')) return 'GBC';
    if (lower == 'gb' || lower == 'game boy') return 'GB';
    if (lower == 'nds' || lower == 'ds' || lower.contains('nintendo ds'))
      return 'NDS';
    if (lower == '3ds' || lower.contains('nintendo 3ds')) return '3DS';

    // Sega consoles
    if (lower == 'genesis' || lower.contains('mega drive')) return 'GEN';
    if (lower == 'master system' || lower == 'sms') return 'SMS';
    if (lower == 'game gear' || lower == 'gg') return 'GG';
    if (lower == 'dreamcast' || lower == 'dc') return 'DC';
    if (lower == 'saturn') return 'SAT';

    // Sony consoles
    if (lower == 'ps1' || lower == 'playstation' || lower == 'psx')
      return 'PS1';
    if (lower == 'ps2' || lower == 'playstation 2') return 'PS2';
    if (lower == 'psp' || lower.contains('playstation portable')) return 'PSP';

    // Fallback: use first 3-4 chars uppercase
    if (platform.length <= 4) return platform.toUpperCase();
    return platform.substring(0, 3).toUpperCase();
  }

  /// Get accent color based on platform
  Color _getPlatformColor(String platform) {
    final lower = platform.toLowerCase();

    // Nintendo - Blue/Cyan family
    if (lower == 'wii' || lower.contains('wii') && !lower.contains('wii u'))
      return OrbColors.orbitCyan;
    if (lower == 'wii u' || lower == 'wiiu') return const Color(0xFF00A8E8);
    if (lower == 'gamecube' || lower == 'gc') return OrbColors.orbitPurple;
    if (lower == 'n64' || lower.contains('nintendo 64'))
      return const Color(0xFF009B4D); // N64 green
    if (lower == 'snes' || lower.contains('super nintendo'))
      return const Color(0xFF7B68EE); // SNES purple
    if (lower == 'nes') return const Color(0xFFE60012); // NES red
    if (lower == 'gba' || lower.contains('game boy advance'))
      return const Color(0xFF5B3694); // GBA purple
    if (lower == 'gbc' || lower.contains('game boy color'))
      return const Color(0xFF8B00FF); // GBC purple
    if (lower == 'gb') return const Color(0xFF8BBD39); // GB green
    if (lower == 'nds' || lower == 'ds')
      return const Color(0xFF5A5A5A); // DS silver
    if (lower == '3ds') return const Color(0xFFD4002A); // 3DS red

    // Sega - Blue family
    if (lower == 'genesis' || lower.contains('mega drive'))
      return const Color(0xFF0060A8); // Sega blue
    if (lower == 'dreamcast') return const Color(0xFFFF6600); // DC orange
    if (lower == 'saturn') return const Color(0xFF003087); // Saturn blue

    // Sony - Blue family
    if (lower == 'ps1' || lower == 'psx' || lower == 'playstation')
      return const Color(0xFF003791);
    if (lower == 'ps2') return const Color(0xFF003791);
    if (lower == 'psp') return const Color(0xFF003791);

    // Default
    return OrbColors.orbitCyan;
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isPrimary = false,
  }) {
    // Priority 2: Use Icon-only buttons with Tooltips to prevent overflow
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: isPrimary ? 38 : 34,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPrimary
                  ? color.withValues(alpha: 0.8)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: isPrimary ? 0.85 : 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
