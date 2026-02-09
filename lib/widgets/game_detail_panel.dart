import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_result.dart';
import '../ui/fusion/design_system.dart';
import '../services/game_metadata_service.dart';
import 'cascading_cover_image.dart';
import 'premium_fallback_cover.dart';

/// Smart Game Detail Panel - Fetches rich metadata from Wikipedia & other sources
/// "The future of jailbreaking" - intelligent metadata aggregation
class GameDetailPanel extends StatefulWidget {
  final GameResult game;
  final VoidCallback? onDownload;
  final VoidCallback? onPlay;
  final VoidCallback? onDelete;
  final bool isLibraryMode;

  const GameDetailPanel({
    super.key,
    required this.game,
    this.onDownload,
    this.onPlay,
    this.onDelete,
    this.isLibraryMode = false,
  });

  @override
  State<GameDetailPanel> createState() => _GameDetailPanelState();
}

class _GameDetailPanelState extends State<GameDetailPanel> {
  final GameMetadataService _metadataService = GameMetadataService();
  GameMetadata? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      final metadata = await _metadataService.getGameMetadata(
        widget.game.title,
        widget.game.platform,
      );
      if (mounted) {
        setState(() {
          _metadata = metadata;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 900,
        height: 650,
        decoration: BoxDecoration(
          color: OrbColors.bgPrimary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(OrbRadius.xl),
          border: Border.all(color: OrbColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: OrbColors.orbitCyan.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            Divider(height: 1, color: OrbColors.border),

            // Content
            Expanded(
              child: Row(
                children: [
                  // Left: Cover Art & Actions
                  _buildLeftPanel(),
                  
                  // Vertical Divider
                  Container(width: 1, color: OrbColors.border),
                  
                  // Right: Details & Metadata
                  Expanded(child: _buildRightPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final platformColor = _getPlatformColor(widget.game.platform);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Platform icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(OrbRadius.md),
            ),
            child: Icon(
              _getPlatformIcon(widget.game.platform),
              color: platformColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _metadata?.title ?? widget.game.title,
                  style: OrbText.headlineMedium.copyWith(
                    color: OrbColors.starWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_metadata?.developer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'by ${_metadata!.developer}',
                    style: OrbText.bodySmall.copyWith(
                      color: OrbColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: OrbColors.orbitCyan,
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: OrbColors.textSecondary),
            hoverColor: OrbColors.bgTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final platformColor = _getPlatformColor(widget.game.platform);
    
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Cover Art
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OrbRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: platformColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OrbRadius.lg),
                child: CascadingCoverImage(
                  primaryUrl: _metadata?.coverUrl ?? widget.game.coverUrl ?? 'https://placeholder.invalid/none.png',
                  gameId: widget.game.gameId,
                  platform: widget.game.platform,
                  title: widget.game.title,
                  fallbackBuilder: (_) => PremiumFallbackCover(
                    title: widget.game.title,
                    platform: widget.game.platform,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: widget.isLibraryMode
                ? _buildGlowButton(
                    label: 'Play Now',
                    icon: Icons.play_arrow_rounded,
                    color: OrbColors.ready,
                    onPressed: widget.onPlay,
                  )
                : _buildGlowButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    color: OrbColors.orbitCyan,
                    onPressed: widget.onDownload,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        // === ABOUT SECTION ===
        _buildSectionTitle('About this game', Icons.info_outline),
        const SizedBox(height: 16),
        
        // Smart description
        if (_isLoading)
          _buildLoadingPlaceholder()
        else
          Text(
            _metadata?.description ?? _getDefaultDescription(),
            style: OrbText.bodyLarge.copyWith(
              color: OrbColors.textPrimary,
              height: 1.6,
            ),
          ),
        
        // Wikipedia link if available
        if (_metadata?.wikiUrl != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchUrl(_metadata!.wikiUrl!),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new, size: 14, color: OrbColors.orbitCyan),
                const SizedBox(width: 6),
                Text(
                  'Read more on Wikipedia',
                  style: OrbText.bodySmall.copyWith(
                    color: OrbColors.orbitCyan,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 32),

        // === DETAILS SECTION ===
        _buildSectionTitle('Details', Icons.list_alt),
        const SizedBox(height: 16),
        _buildDetailGrid(),
        
        const SizedBox(height: 32),
        
        // === GENRES (if available) ===
        if (_metadata != null && _metadata!.genres.isNotEmpty) ...[
          _buildSectionTitle('Genres', Icons.category_outlined),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _metadata!.genres.map((genre) => _buildGenreChip(genre)).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // === SOURCE SECTION ===
        if (widget.game.pageUrl.isNotEmpty) ...[
          _buildSectionTitle('Source', Icons.cloud_download_outlined),
          const SizedBox(height: 16),
          _buildSourceCard(),
          const SizedBox(height: 32),
        ],

        // === LIBRARY MANAGEMENT ===
        if (widget.isLibraryMode) ...[
          _buildSectionTitle('Manage', Icons.settings),
          const SizedBox(height: 16),
          _buildDeleteButton(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: OrbColors.orbitCyan),
        const SizedBox(width: 10),
        Text(
          title,
          style: OrbText.titleLarge.copyWith(
            color: OrbColors.starWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid() {
    final details = <_DetailData>[
      _DetailData('Platform', _getPlatformFullName(widget.game.platform)),
      _DetailData('Region', '${widget.game.regionEmoji} ${widget.game.region}'),
      _DetailData('Size', widget.game.formattedSize),
      _DetailData('Game ID', widget.game.gameId ?? 'Unknown'),
      _DetailData('Format', widget.game.format ?? 'ROM'),
    ];
    
    // Add metadata details if available
    if (_metadata?.releaseDate != null) {
      details.add(_DetailData('Released', _metadata!.releaseDate!));
    }
    if (_metadata?.publisher != null) {
      details.add(_DetailData('Publisher', _metadata!.publisher!));
    }

    return Wrap(
      spacing: 32,
      runSpacing: 20,
      children: details.map((d) => _buildDetailItem(d.label, d.value)).toList(),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: OrbText.caption.copyWith(
              color: OrbColors.textMuted,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: OrbText.bodyMedium.copyWith(
              color: OrbColors.starWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OrbColors.bgTertiary,
        borderRadius: BorderRadius.circular(OrbRadius.full),
        border: Border.all(color: OrbColors.border),
      ),
      child: Text(
        genre,
        style: OrbText.bodySmall.copyWith(
          color: OrbColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSourceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrbColors.bgTertiary,
        borderRadius: BorderRadius.circular(OrbRadius.md),
        border: Border.all(color: OrbColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.game.requiresBrowser ? Icons.language : Icons.download,
                color: OrbColors.orbitCyan,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.game.provider,
                  style: OrbText.titleMedium.copyWith(
                    color: OrbColors.starWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.game.requiresBrowser 
                      ? OrbColors.needsFix.withValues(alpha: 0.2)
                      : OrbColors.ready.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(OrbRadius.sm),
                ),
                child: Text(
                  widget.game.requiresBrowser ? 'Browser Required' : 'Direct Download',
                  style: OrbText.caption.copyWith(
                    color: widget.game.requiresBrowser ? OrbColors.needsFix : OrbColors.ready,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.game.pageUrl,
            style: OrbText.caption.copyWith(
              color: OrbColors.textMuted,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton.icon(
      onPressed: widget.onDelete,
      icon: Icon(Icons.delete_outline, size: 18, color: OrbColors.corrupt),
      label: Text(
        'Delete from Library',
        style: TextStyle(color: OrbColors.corrupt),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: OrbColors.corrupt.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildGlowButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OrbRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(OrbRadius.lg),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: OrbText.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: OrbColors.bgTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 300,
          decoration: BoxDecoration(
            color: OrbColors.bgTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 200,
          decoration: BoxDecoration(
            color: OrbColors.bgTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  String _getDefaultDescription() {
    return 'A ${_getPlatformFullName(widget.game.platform)} game from ${widget.game.region}.';
  }

  String _getPlatformFullName(String platform) {
    final p = platform.toLowerCase();
    if (p == 'wii') return 'Nintendo Wii';
    if (p == 'wii u' || p == 'wiiu') return 'Nintendo Wii U';
    if (p == 'gamecube' || p == 'gc') return 'Nintendo GameCube';
    if (p == 'n64') return 'Nintendo 64';
    if (p == 'snes') return 'Super Nintendo';
    if (p == 'nes') return 'Nintendo Entertainment System';
    if (p == 'gba') return 'Game Boy Advance';
    if (p == 'gbc') return 'Game Boy Color';
    if (p == 'gb') return 'Game Boy';
    if (p == 'nds' || p == 'ds') return 'Nintendo DS';
    if (p == '3ds') return 'Nintendo 3DS';
    if (p == 'genesis') return 'Sega Genesis';
    if (p == 'dreamcast') return 'Sega Dreamcast';
    if (p == 'ps1' || p == 'psx') return 'PlayStation';
    if (p == 'ps2') return 'PlayStation 2';
    if (p == 'psp') return 'PlayStation Portable';
    return platform;
  }

  Color _getPlatformColor(String platform) {
    final p = platform.toLowerCase();
    if (p == 'wii') return OrbColors.orbitCyan;
    if (p == 'wii u' || p == 'wiiu') return const Color(0xFF00A8E8);
    if (p == 'gamecube' || p == 'gc') return OrbColors.orbitPurple;
    if (p == 'n64') return const Color(0xFF009B4D);
    if (p == 'snes') return const Color(0xFF7B68EE);
    if (p == 'nes') return const Color(0xFFE60012);
    if (p == 'gba') return const Color(0xFF5B3694);
    if (p == 'gbc') return const Color(0xFF8B00FF);
    if (p == 'gb') return const Color(0xFF8BBD39);
    if (p == 'genesis') return const Color(0xFF0060A8);
    if (p == 'dreamcast') return const Color(0xFFFF6600);
    if (p == 'ps1' || p == 'ps2' || p == 'psp') return const Color(0xFF003791);
    return OrbColors.orbitCyan;
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p == 'gba' || p == 'gbc' || p == 'gb' || p == 'nds' || p == 'ds' || p == '3ds' || p == 'psp') {
      return Icons.phone_android_rounded;
    }
    return Icons.sports_esports_rounded;
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }
}

class _DetailData {
  final String label;
  final String value;
  _DetailData(this.label, this.value);
}
