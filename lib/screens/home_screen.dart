import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../ui/widgets/premium/premium.dart'; // Deprecated
import '../services/navigation_service.dart';
import '../ui/fusion/design_system.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COMPACT HERO SECTION
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  const _CosmosHeroLogo(),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_getGreeting()}, Commander',
                      style: FusionText.displayMedium.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color:
                                FusionColors.nebulaCyan.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Wii & GameCube backup manager',
                    style: FusionText.bodyLarge.copyWith(
                      color: FusionColors.textSecondary,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SECTION HEADER: QUICK ACTIONS
            Text(
              'QUICK LAUNCH',
              style: FusionText.labelMedium.copyWith(
                color: FusionColors.nebulaCyan,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // COMPACT GRID - 3 columns, 2 rows to fit on screen
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardHeight = constraints.maxHeight * 0.38;

                  return SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _CompactQuickActionCard(
                                height: cardHeight,
                                title: 'Star Map',
                                subtitle: 'Your collection',
                                icon: Icons.map_rounded,
                                gradientColors:
                                    FusionColors.auroraGradient.colors,
                                glowColor: FusionColors.nebulaCyan,
                                onTap: () => context
                                    .read<NavigationService>()
                                    .navigateTo(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CompactQuickActionCard(
                                height: cardHeight,
                                title: 'Deep Space',
                                subtitle: 'Browse games',
                                icon: Icons.explore_rounded,
                                gradientColors: const [
                                  FusionColors.nebulaPurple,
                                  FusionColors.nebulaViolet
                                ],
                                glowColor: FusionColors.nebulaPurple,
                                onTap: () => context
                                    .read<NavigationService>()
                                    .navigateTo(1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CompactQuickActionCard(
                                width: double.infinity,
                                height: cardHeight,
                                title: 'Warp',
                                subtitle: 'Downloads',
                                icon: Icons.rocket_launch_rounded,
                                gradientColors: const [
                                  FusionColors.success,
                                  Color(0xFF059669)
                                ],
                                glowColor: FusionColors.success,
                                onTap: () => context
                                    .read<NavigationService>()
                                    .navigateTo(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactQuickActionCard(
                                width: double.infinity,
                                height: cardHeight,
                                title: 'Tech Lab',
                                subtitle: 'Homebrew',
                                icon: Icons.science_rounded,
                                gradientColors: const [
                                  FusionColors.warning,
                                  Color(0xFFD97706)
                                ],
                                glowColor: FusionColors.warning,
                                onTap: () => context
                                    .read<NavigationService>()
                                    .navigateTo(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CompactQuickActionCard(
                                width: double.infinity,
                                height: cardHeight,
                                title: 'Engineering',
                                subtitle: 'Tools',
                                icon: Icons.build_rounded,
                                gradientColors: const [
                                  Color(0xFF6B7280),
                                  Color(0xFF4B5563)
                                ],
                                glowColor: const Color(0xFF6B7280),
                                onTap: () => context
                                    .read<NavigationService>()
                                    .navigateTo(5),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Empty placeholder to maintain grid
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Logo
class _CosmosHeroLogo extends StatefulWidget {
  const _CosmosHeroLogo();

  @override
  State<_CosmosHeroLogo> createState() => _CosmosHeroLogoState();
}

class _CosmosHeroLogoState extends State<_CosmosHeroLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FusionColors.nebulaCyan
                    .withValues(alpha: 0.3 + (_controller.value * 0.2)),
                FusionColors.nebulaPurple
                    .withValues(alpha: 0.3 + (_controller.value * 0.2)),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: FusionColors.nebulaCyan
                    .withValues(alpha: 0.3 + (_controller.value * 0.2)),
                blurRadius: 40 + (_controller.value * 20),
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.storage_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Compact Quick Action Card - Fits on screen without scrolling
class _CompactQuickActionCard extends StatefulWidget {
  final double? width;
  final double height;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const _CompactQuickActionCard({
    required this.height,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
    this.width,
  });

  @override
  State<_CompactQuickActionCard> createState() =>
      _CompactQuickActionCardState();
}

class _CompactQuickActionCardState extends State<_CompactQuickActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -2.0 : 0.0)
            ..scale(_isPressed ? 0.98 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FusionRadius.xl),
            boxShadow: FusionShadows.glow(
              widget.glowColor,
              intensity: _isHovered ? 1.5 : 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FusionRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FusionColors.bgSecondary.withValues(alpha: 0.85),
                      FusionColors.bgPrimary.withValues(alpha: 0.9),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: _isHovered ? 0.15 : 0.08),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(FusionRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(FusionRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: widget.glowColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    // Text content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style:
                              FusionText.headlineMedium.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: FusionText.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Library Stats Section - Auto-detecting with Premium UI
class _LibraryStatsSection extends StatefulWidget {
  @override
  State<_LibraryStatsSection> createState() => _LibraryStatsSectionState();
}

class _LibraryStatsSectionState extends State<_LibraryStatsSection>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  int _wiiCount = 0;
  int _gcCount = 0;
  double _totalGB = 0;
  List<String> _detectedDrives = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // AUTO-DETECT on mount
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetectDrives());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// AUTO DRIVE DETECTION
  Future<void> _autoDetectDrives() async {
    setState(() => _isScanning = true);

    final drives = <String>[];
    for (final letter in 'DEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final path = '$letter:\\\\';
      if (Directory(path).existsSync()) {
        drives.add(path);
      }
    }

    setState(() {
      _detectedDrives = drives;
      _isScanning = false;
    });

    // Auto-scan first drive if found
    if (drives.isNotEmpty) {
      await _quickScanDrive(drives.first);
    }
  }

  /// Quick scan to count games
  Future<void> _quickScanDrive(String drivePath) async {
    try {
      int wii = 0, gc = 0;
      double totalBytes = 0;

      final dir = Directory(drivePath);
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (ext.endsWith('.wbfs') || ext.endsWith('.iso')) {
            final size = await entity.length();
            totalBytes += size;

            // Simple heuristic: WBFS = Wii, ISO could be either
            if (ext.endsWith('.wbfs') || size > 3.5e9) {
              wii++;
            } else {
              gc++;
            }
          }
        }
      }

      setState(() {
        _wiiCount = wii;
        _gcCount = gc;
        _totalGB = totalBytes / 1e9;
      });
    } catch (e) {
      // Silently fail - drive might be protected
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIBRARY OVERVIEW',
          style: FusionText.labelMedium.copyWith(
            color: FusionColors.nebulaPurple,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),

        // PREMIUM STAT CARDS WITH GLOW
        Row(
          children: [
            Expanded(
              child: _PremiumStatCard(
                label: 'Wii Games',
                value: _wiiCount.toString(),
                icon: Icons.sports_esports,
                color: FusionColors.wii,
                isAnimating: _isScanning,
                pulseAnimation: _pulseController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PremiumStatCard(
                label: 'GameCube',
                value: _gcCount.toString(),
                icon: Icons.gamepad,
                color: FusionColors.gamecube,
                isAnimating: _isScanning,
                pulseAnimation: _pulseController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PremiumStatCard(
                label: 'Total Storage',
                value: '${_totalGB.toStringAsFixed(1)} GB',
                icon: Icons.storage,
                color: FusionColors.nebulaCyan,
                isAnimating: _isScanning,
                pulseAnimation: _pulseController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Drive detection status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FusionColors.bgSecondary.withValues(alpha: 0.5),
                FusionColors.bgSecondary.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(FusionRadius.lg),
            border: Border.all(
              color: _detectedDrives.isEmpty
                  ? FusionColors.glassBorder
                  : FusionColors.nebulaCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: _detectedDrives.isNotEmpty
                ? [
                    BoxShadow(
                      color: FusionColors.nebulaCyan.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _detectedDrives.isEmpty
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    color: _detectedDrives.isEmpty
                        ? FusionColors.nebulaCyan
                        : FusionColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _detectedDrives.isEmpty
                        ? 'No drives detected'
                        : '${_detectedDrives.length} drive(s) detected',
                    style: FusionText.titleMedium.copyWith(
                      color: FusionColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _detectedDrives.isEmpty
                    ? 'Connect a USB drive or SD card to scan for games'
                    : 'Scanned: ${_detectedDrives.join(", ")}',
                style: FusionText.bodySmall.copyWith(
                  color: FusionColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Premium Stat Card with Gradient and Glow
class _PremiumStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAnimating;
  final Animation<double> pulseAnimation;

  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isAnimating,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FusionColors.bgSecondary.withValues(alpha: 0.6),
                FusionColors.bgSecondary.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(FusionRadius.lg),
            border: Border.all(
              color: color.withValues(
                  alpha: 0.2 + (isAnimating ? pulseAnimation.value * 0.2 : 0)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                    alpha: isAnimating ? pulseAnimation.value * 0.15 : 0.05),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: FusionText.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        FusionColors.textPrimary,
                        color.withValues(alpha: 0.8),
                      ],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: FusionText.bodySmall.copyWith(
                  color: FusionColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
