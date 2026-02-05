import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../services/gametdb_service.dart';

/// Tactile Bento Card - Glassmorphic game card with pulsing disc
class TactileBentoCard extends StatefulWidget {
  final String? gameId;
  final String title;
  final String platform;
  final int? health;
  final bool verified;
  final VoidCallback? onTap;

  const TactileBentoCard({
    super.key,
    this.gameId,
    required this.title,
    required this.platform,
    this.health,
    this.verified = false,
    this.onTap,
  });

  @override
  State<TactileBentoCard> createState() => _TactileBentoCardState();
}

class _TactileBentoCardState extends State<TactileBentoCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Use ValueNotifier for hover state to avoid setState during mouse tracking
  final ValueNotifier<bool> _isHoveredNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> _hoverOffsetNotifier =
      ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _coverLoadedNotifier = ValueNotifier<bool>(false);

  // Throttle hover updates to prevent excessive rebuilds
  Timer? _hoverThrottleTimer;
  Offset? _pendingHoverOffset;

  String? _coverUrl;

  @override
  void initState() {
    super.initState();

    // Pulsing disc animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hover scale animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    _loadCover();
  }

  void _loadCover() {
    if (widget.gameId != null && widget.gameId!.length >= 4) {
      _coverUrl =
          GameTDBService.getCoverUrl(widget.gameId!, platform: widget.platform);
    }
  }

  @override
  void dispose() {
    _hoverThrottleTimer?.cancel();
    _pulseController.dispose();
    _hoverController.dispose();
    _isHoveredNotifier.dispose();
    _hoverOffsetNotifier.dispose();
    _coverLoadedNotifier.dispose();
    super.dispose();
  }

  void _handleHoverEnter() {
    _isHoveredNotifier.value = true;
    _hoverController.forward();
  }

  void _handleHoverExit() {
    _hoverThrottleTimer?.cancel();
    _pendingHoverOffset = null;
    _isHoveredNotifier.value = false;
    _hoverOffsetNotifier.value = Offset.zero;
    _hoverController.reverse();
  }

  void _handleHoverMove(Offset localPosition) {
    // Throttle hover updates to max 30fps (every ~33ms) to prevent excessive rebuilds
    _pendingHoverOffset = localPosition;

    if (_hoverThrottleTimer?.isActive ?? false) {
      return; // Already scheduled
    }

    _hoverThrottleTimer = Timer(const Duration(milliseconds: 33), () {
      if (_pendingHoverOffset != null) {
        _hoverOffsetNotifier.value = _pendingHoverOffset!;
        _pendingHoverOffset = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platformColor = widget.platform.toLowerCase() == 'wii'
        ? const Color(0xFF00A8E8)
        : const Color(0xFF5028A0);

    return MouseRegion(
      onEnter: (_) => _handleHoverEnter(),
      onHover: (e) => _handleHoverMove(e.localPosition),
      onExit: (_) => _handleHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;

            return ValueListenableBuilder<bool>(
              valueListenable: _isHoveredNotifier,
              builder: (context, isHovered, _) {
                return ValueListenableBuilder<Offset>(
                  valueListenable: _hoverOffsetNotifier,
                  builder: (context, hoverOffset, _) {
                    // Calculate rotation based on mouse position relative to center
                    final rotationX = isHovered
                        ? -((hoverOffset.dy - cardHeight / 2) /
                                (cardHeight / 2)) *
                            0.15
                        : 0.0;
                    final rotationY = isHovered
                        ? ((hoverOffset.dx - cardWidth / 2) / (cardWidth / 2)) *
                            0.15
                        : 0.0;

                    return ListenableBuilder(
                      listenable:
                          Listenable.merge([_scaleAnimation, _pulseAnimation]),
                      builder: (context, _) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(rotationX)
                            ..rotateY(rotationY)
                            ..scaleByVector3(Vector3(_scaleAnimation.value,
                                _scaleAnimation.value, 1.0)),
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                      ? primaryColor.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: isHovered ? 24 : 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              const Color(0xFF1A1A2E)
                                                  .withValues(alpha: 0.9),
                                              const Color(0xFF16213E)
                                                  .withValues(alpha: 0.9),
                                            ]
                                          : [
                                              Colors.white
                                                  .withValues(alpha: 0.9),
                                              Colors.grey.shade100
                                                  .withValues(alpha: 0.9),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isHovered
                                          ? primaryColor.withValues(alpha: 0.5)
                                          : primaryColor.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Cover Art / Pulsing Disc
                                      Expanded(
                                        flex: 3,
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: _coverLoadedNotifier,
                                          builder: (context, coverLoaded, _) {
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Pulsing Disc Background
                                                if (!coverLoaded)
                                                  _buildPulsingDisc(
                                                      platformColor),

                                                // Cover Art
                                                if (_coverUrl != null)
                                                  Positioned.fill(
                                                    child: Image.network(
                                                      _coverUrl!,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child, progress) {
                                                        if (progress == null) {
                                                          // Use ValueNotifier instead of setState to avoid mouse tracker issues
                                                          _coverLoadedNotifier
                                                              .value = true;
                                                          return child;
                                                        }
                                                        return _buildPulsingDisc(
                                                            platformColor);
                                                      },
                                                      errorBuilder: (_, __,
                                                              ___) =>
                                                          _buildPulsingDisc(
                                                              platformColor),
                                                    ),
                                                  ),

                                                // Platform Badge
                                                Positioned(
                                                  top: 12,
                                                  right: 12,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: platformColor
                                                          .withValues(
                                                        alpha: 0.9,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: platformColor
                                                              .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                          blurRadius: 8,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      widget.platform
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Health Badge
                                                if (widget.health != null)
                                                  Positioned(
                                                    top: 12,
                                                    left: 12,
                                                    child: _buildHealthBadge(
                                                        widget.health!),
                                                  ),

                                                // Verified Checkmark
                                                if (widget.verified)
                                                  Positioned(
                                                    bottom: 12,
                                                    right: 12,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green
                                                                .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),

                                      // Title Section
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              primaryColor.withValues(
                                                  alpha: 0.1),
                                              primaryColor.withValues(
                                                  alpha: 0.05),
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          widget.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPulsingDisc(Color color) {
    return ListenableBuilder(
      listenable: _pulseController,
      builder: (context, _) {
        return Container(
          width: 100 * _pulseAnimation.value,
          height: 100 * _pulseAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Disc rings
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
              // Center hole
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
              ),
              // Shine effect
              Positioned(
                top: 15,
                left: 20,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 30,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthBadge(int health) {
    final color = health >= 80
        ? Colors.green
        : health >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '$health%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
