import 'package:flutter/material.dart';
import '../services/gametdb_service.dart';
import 'spinning_disc.dart';

/// Game Card - Clean design with cover art and intelligent fallback
class GameCover extends StatefulWidget {
  final String? gameId;
  final String title;
  final String platform;
  final double width;
  final double height;

  const GameCover({
    required this.title,
    super.key,
    this.gameId,
    this.platform = 'wii',
    this.width = 160,
    this.height = 224,
  });

  @override
  State<GameCover> createState() => _GameCoverState();
}

class _GameCoverState extends State<GameCover> {
  Future<String?>? _coverFuture;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(GameCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _loadCover();
    }
  }

  void _loadCover() {
    if (widget.gameId != null && widget.gameId!.length >= 4) {
      _coverFuture = GameTDBService.getBestCover(
        widget.gameId!,
        platform: widget.platform.toLowerCase(),
      );
    } else {
      _coverFuture = Future.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _coverFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildCoverImage(context, snapshot.data!);
        }

        return _buildFallbackCover(context);
      },
    );
  }

  Widget _buildCoverImage(BuildContext context, String coverUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        coverUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackCover(context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingState(context);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SpinningDisc(size: 40, color: primaryColor),
      ),
    );
  }

  Widget _buildFallbackCover(BuildContext context) {
    final isWii = widget.platform.toLowerCase() == 'wii';

    // Use different gradient colors for Wii vs GameCube
    final gradColors = isWii
        ? [const Color(0xFF0088CC), const Color(0xFF00AAFF)]
        : [const Color(0xFF5028A0), const Color(0xFF7B4FD0)];

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradColors[0].withValues(alpha: 0.3),
            gradColors[1].withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradColors[0].withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Disc visual
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradColors[0].withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Disc rings
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Center hole
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Game Card - Enhanced version with hover effects
class AnimatedGameCard extends StatefulWidget {
  final String? gameId;
  final String title;
  final String platform;
  final VoidCallback? onTap;
  final double? healthPercent;
  final bool isVerified;

  const AnimatedGameCard({
    required this.title,
    super.key,
    this.gameId,
    this.platform = 'wii',
    this.onTap,
    this.healthPercent,
    this.isVerified = false,
  });

  @override
  State<AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<AnimatedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  // Use ValueNotifier instead of setState for hover state
  final ValueNotifier<bool> _isHoveredNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWii = widget.platform.toLowerCase() == 'wii';

    final accentColor =
        isWii ? const Color(0xFF00AAFF) : const Color(0xFF9B7ED9);

    return MouseRegion(
      onEnter: (_) {
        _isHoveredNotifier.value = true;
        _controller.forward();
      },
      onExit: (_) {
        _isHoveredNotifier.value = false;
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHoveredNotifier,
          builder: (context, isHovered, _) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: isHovered ? 20 : 8,
                          offset: Offset(0, isHovered ? 8 : 4),
                        ),
                        if (isHovered)
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E1E2E),
                                    const Color(0xFF16161F)
                                  ]
                                : [Colors.white, Colors.grey.shade50],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cover art section
                            Expanded(
                              flex: 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GameCover(
                                    gameId: widget.gameId,
                                    title: widget.title,
                                    platform: widget.platform,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),

                                  // Platform badge
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4)
                                        ],
                                      ),
                                      child: Text(
                                        widget.platform
                                                .toLowerCase()
                                                .contains('game')
                                            ? 'GC'
                                            : 'WII',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Title section
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
