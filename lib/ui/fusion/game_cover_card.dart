// ═══════════════════════════════════════════════════════════════════════════
// GAME COVER CARD
// PlayStation-style game card with hover effects and smooth animations
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/discovery_provider.dart';
import '../../core/app_logger.dart';
import '../fusion/design_system.dart';

/// HTTP headers to avoid 403 errors from GameTDB
const Map<String, String> _gametdbHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
  'Accept-Encoding': 'gzip, deflate, br',
  'Connection': 'keep-alive',
  'Sec-Fetch-Dest': 'image',
  'Sec-Fetch-Mode': 'no-cors',
  'Sec-Fetch-Site': 'cross-site',
};

/// Cover image cache with retry and fallback support
class _CoverImageCache {
  static final Map<String, Uint8List?> _cache = {};
  static final Map<String, Future<Uint8List?>> _pending = {};
  static final Set<String> _failed = {}; // Track failed URLs to avoid retries

  static Future<Uint8List?> getImage(String url) async {
    // Skip if we know this URL failed
    if (_failed.contains(url)) {
      return null;
    }

    // Check cache first
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    // Check if already fetching
    if (_pending.containsKey(url)) {
      return _pending[url];
    }

    // Fetch with proper headers and fallback
    _pending[url] = _fetchWithFallback(url);
    final result = await _pending[url];
    _cache[url] = result;
    _pending.remove(url);
    return result;
  }

  static Future<Uint8List?> _fetchWithFallback(String url) async {
    // Try primary URL
    var result = await _fetchImage(url);
    if (result != null) return result;

    // Try alternate cover type (cover instead of cover3D)
    if (url.contains('/cover3D/')) {
      final altUrl = url.replaceFirst('/cover3D/', '/cover/');
      result = await _fetchImage(altUrl);
      if (result != null) return result;
    }

    // Try different regions
    final regions = ['US', 'EN', 'EU', 'JA'];
    for (final region in regions) {
      if (!url.contains('/$region/')) continue;
      for (final altRegion in regions) {
        if (altRegion == region) continue;
        final regionUrl = url.replaceFirst('/$region/', '/$altRegion/');
        result = await _fetchImage(regionUrl);
        if (result != null) return result;
      }
    }

    // Mark as failed
    _failed.add(url);
    return null;
  }

  static Future<Uint8List?> _fetchImage(String url, {int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: _gametdbHeaders,
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          // Verify it's actually an image (PNG starts with 0x89 0x50 0x4E 0x47)
          if (response.bodyBytes.length > 4 &&
              response.bodyBytes[0] == 0x89 &&
              response.bodyBytes[1] == 0x50) {
            return response.bodyBytes;
          }
        }
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        AppLogger.instance
            .warning('Cover fetch failed after ${attempt + 1} attempts: $url');
      } catch (e) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        AppLogger.instance.error(
            'Cover fetch error after ${attempt + 1} attempts: $url',
            error: e);
      }
    }
    return null;
  }

  static void clear() {
    _cache.clear();
    _failed.clear();
  }
}

/// Data model for a game card
class GameCardData {
  final String id;
  final String title;
  final String? coverUrl;
  final String platform; // 'wii', 'gc', 'wiiu'
  final String? size;
  final String? region;
  final bool isFavorite;
  final bool isDownloading;
  final double? downloadProgress;

  const GameCardData({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.platform,
    this.size,
    this.region,
    this.isFavorite = false,
    this.isDownloading = false,
    this.downloadProgress,
  });

  /// Get the cover art URL from GameTDB
  /// Note: GameTDB uses 'wii' path for BOTH Wii and GameCube games
  String get gameTdbCoverUrl {
    final lang = region ?? 'US';
    // GameTDB uses 'wii' for both Wii and GameCube covers
    return 'https://art.gametdb.com/wii/cover3D/$lang/$id.png';
  }

  /// Get full cover URL
  String get fullCoverUrl {
    final lang = region ?? 'US';
    return 'https://art.gametdb.com/wii/coverfull/$lang/$id.png';
  }

  /// Get 2D cover URL (fallback)
  String get cover2DUrl {
    final lang = region ?? 'US';
    return 'https://art.gametdb.com/wii/cover/$lang/$id.png';
  }

  /// Platform display color
  Color get platformColor {
    switch (platform.toLowerCase()) {
      case 'wii':
        return FusionColors.wiiBlue;
      case 'gc':
      case 'gamecube':
        return const Color(0xFF6441A5);
      case 'wiiu':
        return const Color(0xFF009AC7);
      default:
        return FusionColors.wiiBlue;
    }
  }

  /// Platform icon
  IconData get platformIcon {
    switch (platform.toLowerCase()) {
      case 'wii':
        return Icons.sports_esports;
      case 'gc':
      case 'gamecube':
        return Icons.gamepad;
      case 'wiiu':
        return Icons.tablet;
      default:
        return Icons.videogame_asset;
    }
  }
}

/// Game cover card - PlayStation/Xbox inspired design
class GameCoverCard extends StatefulWidget {
  final GameCardData game;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onInfo;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final double width;
  final double height;

  const GameCoverCard({
    super.key,
    required this.game,
    this.onTap,
    this.onDoubleTap,
    this.onInfo,
    this.onDownload,
    this.onDelete,
    this.onFavorite,
    this.width = 160,
    this.height = 220,
  });

  @override
  State<GameCoverCard> createState() => _GameCoverCardState();
}

class _GameCoverCardState extends State<GameCoverCard>
    with SingleTickerProviderStateMixin {
  // Track hover state via animation controller (no setState needed)
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: FusionAnimations.normal,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    // Listen to animation to trigger rebuilds
    _hoverController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    _isHovered = isHovered;
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Transform.scale(
          scale: _isPressed ? 0.97 : _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FusionRadius.lg),
              boxShadow: [
                // Base shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                // Glow shadow on hover
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: widget.game.platformColor
                        .withValues(alpha: 0.4 * _glowAnimation.value),
                    blurRadius: 25 * _glowAnimation.value,
                    spreadRadius: -5,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FusionRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  _buildCoverImage(),

                  // Gradient overlay
                  _buildGradientOverlay(),

                  // Content overlay
                  _buildContentOverlay(),

                  // Hover actions
                  if (_isHovered) _buildHoverActions(),

                  // Download progress
                  if (widget.game.isDownloading) _buildDownloadProgress(),

                  // Favorite badge
                  if (widget.game.isFavorite) _buildFavoriteBadge(),

                  // Platform badge
                  _buildPlatformBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    // Check if we have a locally cached cover from DiscoveryProvider
    final discoveryProvider = context.watch<DiscoveryProvider>();
    final cachedPath = discoveryProvider.getCoverPath(widget.game.id);

    return Container(
      decoration: BoxDecoration(
        color: FusionColors.surfaceCard,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.game.platformColor.withValues(alpha: 0.1),
            FusionColors.surfaceCard,
          ],
        ),
      ),
      child: cachedPath != null
          ? Image.file(
              File(cachedPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          : (widget.game.coverUrl != null
              ? _CachedCoverImage(
                  url: widget.game.coverUrl!,
                  placeholder: _buildPlaceholder(),
                )
              : _buildPlaceholder()),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.game.platformColor.withValues(alpha: 0.2),
            FusionColors.surfaceCard,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.game.platformIcon,
              size: 48,
              color: widget.game.platformColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.game.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: FusionColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ImageChunkEvent progress) {
    final percent = progress.expectedTotalBytes != null
        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
        : null;

    return Container(
      color: FusionColors.surfaceCard,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(widget.game.platformColor),
                backgroundColor: FusionColors.borderSubtle,
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: FusionColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game title
          Text(
            widget.game.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Game ID and Size - Flexible to prevent overflow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: FusionColors.glassWhite(0.15),
                  ),
                  child: Text(
                    widget.game.id,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: FusionColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (widget.game.size != null) ...[
                const SizedBox(width: 6),
                Text(
                  widget.game.size!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: FusionColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoverActions() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FusionRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.onInfo != null)
                    _ActionButton(
                      icon: Icons.info_outline,
                      label: 'Info',
                      onTap: widget.onInfo!,
                    ),
                  if (widget.onDownload != null)
                    _ActionButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: widget.onDownload!,
                      color: FusionColors.success,
                    ),
                  if (widget.onDelete != null)
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: widget.onDelete!,
                      color: FusionColors.error,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.5),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widget.game.downloadProgress ?? 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FusionColors.wiiBlue,
                  Color(0xFF00D4FF),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromRGBO(0, 0, 0, 0.6),
        ),
        child: const Icon(
          Icons.favorite,
          size: 14,
          color: FusionColors.error,
        ),
      ),
    );
  }

  Widget _buildPlatformBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: widget.game.platformColor.withValues(alpha: 0.9),
        ),
        child: Text(
          widget.game.platform.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Action button for hover state
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  // Use ValueNotifier to avoid setState in MouseRegion callbacks
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? FusionColors.wiiBlue;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, isHovered, child) {
            return AnimatedContainer(
              duration: FusionAnimations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FusionRadius.sm),
                color: isHovered
                    ? buttonColor.withValues(alpha: 0.3)
                    : FusionColors.glassWhite(0.1),
                border: Border.all(
                  color: isHovered
                      ? buttonColor.withValues(alpha: 0.5)
                      : FusionColors.glassWhite(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: isHovered ? buttonColor : Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isHovered ? buttonColor : Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Grid of game cover cards (like PS5 library)
class GameCoverGrid extends StatelessWidget {
  final List<GameCardData> games;
  final void Function(GameCardData game)? onGameTap;
  final void Function(GameCardData game)? onGameInfo;
  final void Function(GameCardData game)? onGameDownload;
  final void Function(GameCardData game)? onGameDelete;
  final bool isLoading;
  final ScrollController? scrollController;

  const GameCoverGrid({
    super.key,
    required this.games,
    this.onGameTap,
    this.onGameInfo,
    this.onGameDownload,
    this.onGameDelete,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    }

    if (games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videogame_asset_off, size: 48),
            SizedBox(height: 16),
            Text('No games found'),
            Text('Scan a drive or discover games to get started'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 160.0;
        final spacing = 16.0;
        final cols = ((constraints.maxWidth + spacing) / (cardWidth + spacing))
            .floor()
            .clamp(2, 8);

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(FusionSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: cardWidth / 220,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return GameCoverCard(
              game: game,
              onTap: () => onGameTap?.call(game),
              onInfo: onGameInfo != null ? () => onGameInfo!(game) : null,
              onDownload:
                  onGameDownload != null ? () => onGameDownload!(game) : null,
              onDelete: onGameDelete != null ? () => onGameDelete!(game) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(FusionSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 160 / 220,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

/// Cached cover image that fetches with proper headers
class _CachedCoverImage extends StatefulWidget {
  final String url;
  final Widget placeholder;

  const _CachedCoverImage({
    required this.url,
    required this.placeholder,
  });

  @override
  State<_CachedCoverImage> createState() => _CachedCoverImageState();
}

class _CachedCoverImageState extends State<_CachedCoverImage>
    with SingleTickerProviderStateMixin {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CachedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data = await _CoverImageCache.getImage(widget.url);

    if (mounted) {
      setState(() {
        _imageData = data;
        _isLoading = false;
        _hasError = data == null;
      });

      if (data != null) {
        _fadeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_hasError || _imageData == null) {
      return widget.placeholder;
    }

    return FadeTransition(
      opacity: _fadeController,
      child: Image.memory(
        _imageData!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => widget.placeholder,
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: FusionColors.surfaceCard,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
                FusionColors.wiiBlue.withValues(alpha: 0.7)),
            backgroundColor: FusionColors.borderSubtle,
          ),
        ),
      ),
    );
  }
}
