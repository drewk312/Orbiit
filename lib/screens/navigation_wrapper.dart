import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../screens/settings_screen.dart' show SettingsScreen;
import '../services/legal_notice_service.dart';
import '../services/navigation_service.dart';
import '../services/update_service.dart';
import '../ui/fusion/design_system.dart';
import '../ui/screens/download_center.dart' show DownloadCenterScreen;
import '../ui/screens/game_library_screen.dart' show GameLibraryScreen;
// import '../widgets/download_status_overlay.dart';
import '../ui/screens/tools_hub_screen.dart' show ToolsHubScreen;
import '../ui/widgets/space_background.dart';
import '../widgets/fusion_sidebar.dart';
import 'discovery.dart';
import 'home_screen.dart';
import 'homebrew.dart';

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

  // Enable space animations for the cosmic aesthetic
  final bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _navService.addListener(_onNavChanged);

    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 15),
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
        backgroundColor: FusionColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FusionRadius.lg),
          side:
              BorderSide(color: FusionColors.nebulaCyan.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: FusionColors.nebulaCyan),
            SizedBox(width: 12),
            Text('New Update Available', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${release.tagName} is now available.',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold),
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
            child: const Text('Later',
                style: TextStyle(color: FusionColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download & Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FusionColors.nebulaCyan,
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
            backgroundColor: FusionColors.bgSurface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: FusionColors.nebulaCyan),
                SizedBox(height: 16),
                Text('Downloading update...',
                    style: TextStyle(color: Colors.white)),
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
      const GameLibraryScreen(), // 2: Library
      const DownloadCenterScreen(), // 3: Downloads
      const HomebrewScreen(embedInWrapper: true), // 4: Homebrew
      const ToolsHubScreen(), // 5: Tools
      const SettingsScreen(), // 6: Settings
    ];

    int currentIndex = _navService.currentIndex;
    // Clamp to valid screen index
    if (currentIndex >= screens.length) currentIndex = 0;

    return Scaffold(
      backgroundColor: FusionColors.void_,
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
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeInOutSine,
                      top: -100 +
                          (math.sin(_bgAnimController.value * 2 * math.pi) *
                              20),
                      right: -100 +
                          (math.cos(_bgAnimController.value * 2 * math.pi) *
                              20),
                      child: const _PremiumGlow(
                        color: FusionColors.nebulaCyan,
                        size: 400,
                        opacity: 0.1,
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 3000),
                      curve: Curves.easeInOutSine,
                      bottom: -100 +
                          (math.cos(_bgAnimController.value * 2 * math.pi) *
                              30),
                      left: -100 +
                          (math.sin(_bgAnimController.value * 2 * math.pi) *
                              30),
                      child: const _PremiumGlow(
                        color: FusionColors.nebulaPurple,
                        size: 350,
                        opacity: 0.08,
                      ),
                    ),
                  ],

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
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: FusionAnimations.smooth,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey(currentIndex),
                              child: screens[currentIndex],
                            ),
                          ),
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
/// Custom glassmorphic title bar
class _OrbiitTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: FusionColors.bgSecondary.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: FusionColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                // ORBIIT ICON
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: FusionColors.nebulaCyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: FusionColors.nebulaCyan,
                    size: 16,
                  ),
                ),

                const SizedBox(width: 12),

                // Title / Breadcrumb
                Text(
                  'COSMOS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FusionColors.textPrimary.withValues(alpha: 0.9),
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // WINDOW CONTROLS
                _WindowButton(
                  icon: Icons.remove_rounded,
                  onTap: () => windowManager.minimize(),
                ),
                const SizedBox(width: 4),
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
                const SizedBox(width: 4),
                _WindowButton(
                  icon: Icons.close_rounded,
                  isClose: true,
                  onTap: () => windowManager.close(),
                ),
              ],
            ),
          ),
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
              duration: FusionAnimations.fast,
              width: 42,
              height: 32, // More accessible touch/click target
              decoration: BoxDecoration(
                color: isHovered
                    ? (widget.isClose
                        ? FusionColors.corrupt.withValues(alpha: 0.9)
                        : FusionColors.bgTertiary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(FusionRadius.sm),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: isHovered
                    ? (widget.isClose ? Colors.white : FusionColors.starlight)
                    : FusionColors.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ================= PREMIUM GLOW =================
/// Static-ish glow optimized for composition
class _PremiumGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _PremiumGlow({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.5),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
