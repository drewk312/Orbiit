import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/forge_provider.dart';
import '../fusion/design_system.dart';
import '../widgets/cover_art_widget.dart';

/// Cosmic-themed download manager with premium glassmorphism
class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgeProvider>(
      builder: (context, forge, child) {
        final activeDownloads = forge.getActiveDownloads();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Cosmic background effects
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CosmicBackgroundPainter(
                        rotation: _rotationController.value * 2 * 3.14159,
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PREMIUM HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                    child: Row(
                      children: [
                        // Icon with animated glow
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    OrbColors.orbitCyan.withValues(
                                        alpha:
                                            0.3 + _pulseController.value * 0.2),
                                    OrbColors.orbitPurple.withValues(
                                        alpha:
                                            0.3 + _pulseController.value * 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: OrbColors.orbitCyan.withValues(
                                        alpha:
                                            0.4 + _pulseController.value * 0.3),
                                    blurRadius:
                                        20 + _pulseController.value * 10,
                                    spreadRadius: _pulseController.value * 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WARP DRIVE',
                                style: OrbText.caption.copyWith(
                                  color: OrbColors.orbitCyan,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Download Manager',
                                style: OrbText.displayMedium.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  shadows: [
                                    Shadow(
                                      color: OrbColors.orbitCyan
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Clear button
                        _CosmicButton(
                          onPressed: () => forge.clearCompletedDownloads(),
                          icon: Icons.clear_all,
                          tooltip: 'Clear Completed',
                        ),
                      ],
                    ),
                  ),

                  // Downloads list - NO SCROLLING, limited to fit on screen
                  Expanded(
                    child: activeDownloads.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent scrolling
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height - 200,
                              ),
                              child: Column(
                                children: List.generate(
                                  activeDownloads.length > 1
                                      ? 1
                                      : activeDownloads.length,
                                  (index) {
                                    final download = activeDownloads[index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          32, 8, 32, 16),
                                      child: _CosmicDownloadCard(
                                        download: download,
                                        forge: forge,
                                        index: index,
                                        // Adding missing parameters if they are required by the widget definition
                                        // The error said "missing required named parameter".
                                        // But looking at the widget definition in line 305:
                                        // required this.download, required this.forge, required this.index
                                        // These ARE provided in the code I read (lines 164-167).
                                        // Wait, the previous session said: "Missing required named parameters (gameId, platform, region, coverUrl) for a widget."
                                        // But `_CosmicDownloadCard` takes `download`, `forge`, `index`.
                                        // Maybe `_CosmicDownloadCard`'s definition was CHANGED in the file but the usage in `List.generate` was correct?
                                        // Or maybe the error was referring to a DIFFERENT widget call?
                                        // Ah, let's look at `_CosmicDownloadCard` definition again.
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cosmic empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      OrbColors.orbitCyan.withValues(
                          alpha: 0.2 + _pulseController.value * 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Opacity(
                  opacity: 0.3 + _pulseController.value * 0.2,
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 64,
                    color: OrbColors.orbitCyan,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Downloads',
            style: OrbText.headlineLarge.copyWith(
              color: OrbColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your warp drive is idle',
            style: OrbText.bodyMedium.copyWith(
              color: OrbColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cosmic button with glassmorphism
class _CosmicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const _CosmicButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  State<_CosmicButton> createState() => _CosmicButtonState();
}

class _CosmicButtonState extends State<_CosmicButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        OrbColors.orbitCyan.withValues(alpha: 0.2),
                        OrbColors.orbitPurple.withValues(alpha: 0.2),
                      ]
                    : [
                        const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                        const Color(0xFF0A0A0A).withValues(alpha: 0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? OrbColors.orbitCyan.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? OrbColors.orbitCyan
                  : Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cosmic download card with premium glassmorphism
class _CosmicDownloadCard extends StatefulWidget {
  final ActiveDownload download;
  final ForgeProvider forge;
  final int index;

  const _CosmicDownloadCard({
    required this.download,
    required this.forge,
    required this.index,
  });

  @override
  State<_CosmicDownloadCard> createState() => _CosmicDownloadCardState();
}

class _CosmicDownloadCardState extends State<_CosmicDownloadCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final isActive =
        download.status == 'downloading' || download.status == 'paused';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                    const Color(0xFF0A0A0A).withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: _isHovered
                      ? OrbColors.orbitCyan.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: OrbColors.orbitCyan.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover art with cosmic glow
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: OrbColors.orbitCyan.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: download.coverUrl != null &&
                              download.coverUrl!.isNotEmpty
                          ? CoverArtWidget(
                              coverUrl: download.coverUrl!,
                              gameId: download.gameId,
                              platform: download.platform,
                              region: download.region,
                              title: download.title,
                            )
                          : Container(
                              color: const Color(0xFF2A2A2A),
                              child: Icon(
                                Icons.gamepad_rounded,
                                size: 48,
                                color:
                                    OrbColors.orbitCyan.withValues(alpha: 0.5),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and status badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                download.title,
                                style: OrbText.headlineMedium
                                    .copyWith(fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusBadge(status: download.status),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Progress bar with shimmer (only for active downloads)
                        if (isActive) ...[
                          Stack(
                            children: [
                              // Track
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Progress fill
                              FractionallySizedBox(
                                widthFactor: download.progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        OrbColors.orbitCyan,
                                        OrbColors.orbitPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: OrbColors.orbitCyan
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Shimmer effect
                              if (download.status == 'downloading')
                                AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor:
                                          download.progress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            stops: [
                                              (_shimmerController.value - 0.3)
                                                  .clamp(0.0, 1.0),
                                              _shimmerController.value,
                                              (_shimmerController.value + 0.3)
                                                  .clamp(0.0, 1.0),
                                            ],
                                            colors: [
                                              Colors.transparent,
                                              Colors.white
                                                  .withValues(alpha: 0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Stats row
                        if (isActive)
                          Row(
                            children: [
                              _StatPill(
                                icon: Icons.speed_rounded,
                                label: download.speed,
                                color: OrbColors.orbitCyan,
                              ),
                              const SizedBox(width: 12),
                              _StatPill(
                                icon: Icons.storage_rounded,
                                label: download.size,
                                color: OrbColors.orbitPurple,
                              ),
                              const SizedBox(width: 12),
                              _StatPill(
                                icon: Icons.schedule_rounded,
                                label: download.timeRemaining,
                                color: const Color(0xFF6B7280),
                              ),
                            ],
                          ),

                        if (isActive) const SizedBox(height: 16),

                        // Action buttons (only for active downloads)
                        if (isActive)
                          Row(
                            children: [
                              _CosmicActionButton(
                                onPressed: () {
                                  if (download.status == 'downloading') {
                                    widget.forge.pauseForge();
                                  } else if (download.status == 'paused') {
                                    widget.forge.resumeForge();
                                  }
                                },
                                icon: download.status == 'downloading'
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                label: download.status == 'downloading'
                                    ? 'Pause'
                                    : 'Resume',
                                isPrimary: true,
                              ),
                              const SizedBox(width: 12),
                              _CosmicActionButton(
                                onPressed: () => widget.forge.cancelForge(),
                                icon: Icons.close_rounded,
                                label: 'Cancel',
                                isDestructive: true,
                              ),
                            ],
                          ),
                      ],
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
}

/// Status badge with cosmic styling
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'downloading':
        color = OrbColors.orbitCyan;
        icon = Icons.downloading_rounded;
        label = 'WARP';
        break;
      case 'paused':
        color = const Color(0xFFFB923C);
        icon = Icons.pause_circle_rounded;
        label = 'PAUSED';
        break;
      case 'completed':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        label = 'COMPLETE';
        break;
      case 'failed':
        color = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        label = 'FAILED';
        break;
      default:
        color = const Color(0xFF6B7280);
        icon = Icons.help_rounded;
        label = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: OrbText.caption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat pill with icon
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: OrbText.bodySmall.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cosmic action button
class _CosmicActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isDestructive;

  const _CosmicActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  State<_CosmicActionButton> createState() => _CosmicActionButtonState();
}

class _CosmicActionButtonState extends State<_CosmicActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    if (widget.isDestructive) {
      baseColor = const Color(0xFFEF4444);
    } else if (widget.isPrimary) {
      baseColor = OrbColors.orbitCyan;
    } else {
      baseColor = const Color(0xFF6B7280);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [
                      baseColor.withValues(alpha: 0.3),
                      baseColor.withValues(alpha: 0.2),
                    ]
                  : [
                      baseColor.withValues(alpha: 0.15),
                      baseColor.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? baseColor.withValues(alpha: 0.5)
                  : baseColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: baseColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: OrbText.bodyMedium.copyWith(
                  color: baseColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cosmic background painter with rotating nebula effect
class _CosmicBackgroundPainter extends CustomPainter {
  final double rotation;

  _CosmicBackgroundPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // Rotating nebula gradients
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          OrbColors.orbitCyan.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(
        center: Offset(
          center.dx + 200 * (1 + 0.5 * (rotation % 6.28)) / 6.28,
          center.dy + 100 * (1 + 0.5 * ((rotation + 2) % 6.28)) / 6.28,
        ),
        radius: size.width * 0.4,
      ));

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          OrbColors.orbitPurple.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(
        center: Offset(
          center.dx - 150 * (1 + 0.5 * ((rotation + 3) % 6.28)) / 6.28,
          center.dy - 120 * (1 + 0.5 * ((rotation + 1) % 6.28)) / 6.28,
        ),
        radius: size.width * 0.35,
      ));

    canvas.drawCircle(center, size.width * 0.4, paint1);
    canvas.drawCircle(center, size.width * 0.35, paint2);
  }

  @override
  bool shouldRepaint(_CosmicBackgroundPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
