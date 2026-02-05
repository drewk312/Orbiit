import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:window_manager/window_manager.dart';
import 'discovery.dart';
import 'homebrew.dart';
import 'home_screen.dart';
// import '../widgets/download_status_overlay.dart';
import '../ui/screens/tools_screen.dart';
import '../ui/screens/game_library_screen.dart' show GameLibraryScreen;
import '../ui/screens/download_center.dart' show DownloadCenterScreen;
import '../screens/settings_screen.dart' show SettingsScreen;
import '../widgets/fusion_sidebar.dart';
import '../services/navigation_service.dart';
import '../services/legal_notice_service.dart';
import '../services/update_service.dart';
import '../ui/fusion/design_system.dart';
import '../ui/widgets/space_background.dart';

/// NavigationWrapper - Orbiit's premium space-themed navigation
/// "Your games. In orbit." — cosmic, premium, immersive
class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper>
    with TickerProviderStateMixin {
  final NavigationService _navService = NavigationService();
  late AnimationController _bgAnimController;
  late AnimationController _particleController;

  // ORBIIT SPACE THEME - Unified cosmic aesthetic
  // Deep space with cyan (Wii) and purple (GameCube) accents
  static const _orbiitTheme = _TabTheme(
    primary: Color(0xFF00D4FF), // Orbit Cyan (Wii)
    secondary: Color(0xFF8B5CF6), // Orbit Purple (GameCube)
    accent: Color(0xFF00D4FF), // Orbit Cyan
    bgGradient: [
      Color(0xFF0D0D12), // OrbColors.bgPrimary
      Color(0xFF141419), // OrbColors.bgSecondary
      Color(0xFF08080C), // OrbColors.void_
    ],
  );

  // Keep as list for compatibility - all using unified Orbiit theme
  static const _tabThemes = <_TabTheme>[
    _orbiitTheme, // 0: Launch (Home)
    _orbiitTheme, // 1: Deep Space (Store)
    _orbiitTheme, // 2: Star Map (Library)
    _orbiitTheme, // 3: Warp (Downloads)
    _orbiitTheme, // 4: Homebrew
    _orbiitTheme, // 5: Engineering (Tools)
    _orbiitTheme, // 6: Command (Settings)
  ];

  // Enable space animations for the cosmic aesthetic
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _navService.addListener(_onNavChanged);

    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Check for updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      final release = await updateService.checkForUpdates();
      
      if (release != null && mounted) {
        _showUpdateDialog(release);
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  void _showUpdateDialog(UpdateRelease release) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF00D4FF)),
            const SizedBox(width: 12),
            const Text('New Update Available', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${release.tagName} is now available.',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  release.body,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download & Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _performUpdate(release);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performUpdate(UpdateRelease release) async {
    // Show progress dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return const AlertDialog(
            backgroundColor: Color(0xFF1A1A22),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00D4FF)),
                SizedBox(height: 16),
                Text('Downloading update...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        },
      ),
    );

    try {
      final updateService = UpdateService();
      // On success, the installer will run and we can exit, or just let it close us
      await updateService.downloadAndInstall(release, (progress) {
        // We could update the dialog here if we passed the setState down
      });
      // Close the app or similar?
    } catch (e) {
       if (mounted) {
         Navigator.of(context).pop(); // Close progress dialog
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Update failed: $e')),
         );
       }
    }
  }

  @override
  void dispose() {
    _navService.removeListener(_onNavChanged);
    _bgAnimController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onNavChanged() {
    setState(() {});
  }

  Future<void> _navigateToDiscover() async {
    final accepted = await LegalNoticeService.showLegalNotice(context);
    if (accepted) {
      _navService.navigateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tabs (mapped to NavigationService indices)
    // NavigationService: 0=Home, 1=Store, 2=Library, 3=Downloads, 4=Homebrew, 5=Tools, 6=Settings
    final List<Widget> screens = [
      const HomeScreen(), // 0: Home
      const DiscoveryScreen(), // 1: Store (Discovery)
      GameLibraryScreen(), // 2: Library
      const DownloadCenterScreen(), // 3: Downloads
      HomebrewScreen(embedInWrapper: true), // 4: Homebrew
      const ToolsScreen(embedInWrapper: true), // 5: Tools
      SettingsScreen(), // 6: Settings
    ];

    int currentIndex = _navService.currentIndex;
    // Clamp to valid screen index
    if (currentIndex >= screens.length) currentIndex = 0;

    final theme = _tabThemes[currentIndex];

    return Scaffold(
      backgroundColor: OrbColors.void_,
      body: SpaceBackground(
        enableAnimation: !_reduceMotion,
        child: Column(
          children: [
            // === CUSTOM TITLE BAR ===
            _OrbiitTitleBar(),

            // === MAIN CONTENT ===
            Expanded(
              child: Stack(
                children: [
                  // AMBIENT NEBULA GLOWS (cyan and purple)
                  if (!_reduceMotion) ...[
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      top: -40 + (currentIndex * 10.0),
                      right: -60 - (currentIndex * 8.0),
                      child: _PremiumGlow(
                        color: OrbColors.orbitCyan,
                        size: 300,
                        opacity: 0.08,
                        controller: _bgAnimController,
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      bottom: -60 - (currentIndex * 6.0),
                      left: -40 + (currentIndex * 8.0),
                      child: _PremiumGlow(
                        color: OrbColors.orbitPurple,
                        size: 250,
                        opacity: 0.06,
                        controller: _bgAnimController,
                        reverse: true,
                      ),
                    ),
                  ],

                  // SUBTLE SCANLINES for retro CRT feel
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ScanlinesPainter(
                            color: OrbColors.orbitCyan.withValues(alpha: 0.01)),
                      ),
                    ),
                  ),

                  // MAIN LAYOUT: Sidebar + Main Content
                  Row(
                    children: [
                      // Orbiit Sidebar (collapsible on hover)
                      FusionSidebar(
                        currentIndex: _navService.currentIndex,
                        onSelected: (idx) {
                          // If user taps Store, show legal notice first
                          if (idx == NavigationService.discovery) {
                            _navigateToDiscover();
                          } else {
                            _navService.navigateTo(idx);
                          }
                        },
                      ),

                      // Main content area
                      Expanded(
                        child: Stack(
                          children: [
                            AnimatedSwitcher(
                              duration: OrbAnimations.smooth,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeIn,
                              child: KeyedSubtree(
                                key: ValueKey(currentIndex),
                                child: screens[currentIndex],
                              ),
                            ),
                            // const DownloadStatusOverlay(), // Disabled by user request
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ORBIIT TITLE BAR =================
/// Custom title bar with Orbiit branding and window controls
class _OrbiitTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: OrbColors.bgSecondary.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(
              color: OrbColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // ORBIIT BRAND
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OrbColors.bgTertiary,
                    OrbColors.void_,
                  ],
                ),
                border: Border.all(
                  color: OrbColors.orbitCyan.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center O
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OrbColors.starWhite,
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Cyan dot
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OrbColors.orbitCyan,
                      ),
                    ),
                  ),
                  // Purple dot
                  Positioned(
                    bottom: 3,
                    left: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OrbColors.orbitPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Title text
            Row(
              children: [
                Text(
                  'ORB',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OrbColors.starWhite,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'I',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OrbColors.orbitCyan,
                  ),
                ),
                Text(
                  'I',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OrbColors.orbitPurple,
                  ),
                ),
                Text(
                  'T',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OrbColors.starWhite,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // WINDOW CONTROLS
            _WindowButton(
              icon: Icons.remove_rounded,
              onTap: () => windowManager.minimize(),
            ),
            const SizedBox(width: 8),
            _WindowButton(
              icon: Icons.crop_square_rounded,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            const SizedBox(width: 8),
            _WindowButton(
              icon: Icons.close_rounded,
              isClose: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Window control button with hover effect
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, isHovered, _) {
            return AnimatedContainer(
              duration: OrbAnimations.fast,
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: isHovered
                    ? (widget.isClose
                        ? OrbColors.corrupt.withValues(alpha: 0.8)
                        : OrbColors.bgTertiary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: isHovered
                    ? (widget.isClose ? Colors.white : OrbColors.starWhite)
                    : OrbColors.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tab theme definition for unique aesthetics
class _TabTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> bgGradient;

  const _TabTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bgGradient,
  });
}

/// ================= PARTICLE FIELD =================
/// Floating particles with parallax effect
class _ParticleField extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _ParticleField({
    required this.color,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            color: color,
            progress: controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  final double progress;
  final math.Random _random =
      math.Random(42); // Fixed seed for consistent particles

  _ParticlePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final particleSize = _random.nextDouble() * 1.4 + 0.6;
      final speed = _random.nextDouble() * 0.4 + 0.4;
      final opacity = _random.nextDouble() * 0.12 + 0.03;

      // Gentle, smaller floating motion
      final offsetY = math.sin((progress * 2 * math.pi * speed) + i) * 12;
      final offsetX = math.cos((progress * 2 * math.pi * speed * 0.5) + i) * 6;

      paint.color = color.withValues(
          alpha: opacity * (0.6 + 0.4 * math.sin(progress * 2 * math.pi + i)));

      canvas.drawCircle(
        Offset(baseX + offsetX, baseY + offsetY),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// ================= SCANLINES PAINTER =================
/// CRT-style scanline effect overlay
class _ScanlinesPainter extends CustomPainter {
  final Color color;

  _ScanlinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// ================= PREMIUM GLOW =================
/// Animated ambient glow with pulsing effect
class _PremiumGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final AnimationController controller;
  final bool reverse;

  const _PremiumGlow({
    required this.color,
    required this.size,
    required this.opacity,
    required this.controller,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = reverse ? 1.0 - controller.value : controller.value;
        final pulseOpacity =
            opacity * (0.6 + 0.4 * math.sin(progress * 2 * math.pi));
        final pulseSize =
            size * (0.95 + 0.05 * math.sin(progress * 2 * math.pi));

        return Container(
          width: pulseSize,
          height: pulseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: pulseOpacity),
                color.withValues(alpha: pulseOpacity * 0.5),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        );
      },
    );
  }
}
