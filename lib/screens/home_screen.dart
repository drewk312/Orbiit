import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/fusion/design_system.dart';
import '../services/navigation_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Orbiit Logo
                  _OrbiitLogoAnimated(),
                  const SizedBox(height: 24),
                  // Greeting
                  Text(
                    '${_getGreeting()}, Commander',
                    style: OrbText.headlineLarge.copyWith(
                      color: OrbColors.starWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your games are in orbit and ready to launch',
                    style: OrbText.bodyLarge.copyWith(
                      color: OrbColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Quick Actions
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _QuickAction(
                        icon: Icons.auto_awesome_outlined,
                        label: 'Star Map',
                        subtitle: 'Your Library',
                        color: OrbColors.orbitCyan,
                        onTap: () {
                          context.read<NavigationService>().navigateTo(2);
                        },
                      ),
                      _QuickAction(
                        icon: Icons.explore_outlined,
                        label: 'Deep Space',
                        subtitle: 'Browse Store',
                        color: OrbColors.orbitPurple,
                        onTap: () {
                          context.read<NavigationService>().navigateTo(1);
                        },
                      ),
                      _QuickAction(
                        icon: Icons.downloading_outlined,
                        label: 'Warp',
                        subtitle: 'Downloads',
                        color: OrbColors.ready,
                        onTap: () {
                          context.read<NavigationService>().navigateTo(3);
                        },
                      ),
                      _QuickAction(
                        icon: Icons.handyman_outlined,
                        label: 'Engineering',
                        subtitle: 'Tools',
                        color: OrbColors.needsFix,
                        onTap: () {
                          context.read<NavigationService>().navigateTo(5);
                        },
                      ),
                    ],
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

/// Animated Orbiit logo with orbiting dots
class _OrbiitLogoAnimated extends StatefulWidget {
  @override
  State<_OrbiitLogoAnimated> createState() => _OrbiitLogoAnimatedState();
}

class _OrbiitLogoAnimatedState extends State<_OrbiitLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                OrbColors.bgTertiary,
                OrbColors.void_,
              ],
            ),
            border: Border.all(
              color: OrbColors.orbitCyan.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: OrbColors.orbitCyan.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: OrbColors.orbitPurple.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center "O" ring
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OrbColors.starWhite.withValues(alpha: 0.9),
                    width: 4,
                  ),
                ),
              ),
              // Center star
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OrbColors.starWhite.withValues(alpha: 0.6),
                  boxShadow: [
                    BoxShadow(
                      color: OrbColors.starWhite.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Orbiting cyan dot (Wii)
              Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: Transform.translate(
                  offset: const Offset(35, 0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OrbColors.orbitCyan,
                      boxShadow: [
                        BoxShadow(
                          color: OrbColors.orbitCyan.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Orbiting purple dot (GameCube)
              Transform.rotate(
                angle: (_controller.value * 2 * 3.14159) + 3.14159,
                child: Transform.translate(
                  offset: const Offset(35, 0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OrbColors.orbitPurple,
                      boxShadow: [
                        BoxShadow(
                          color: OrbColors.orbitPurple.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
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
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
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
              duration: OrbAnimations.normal,
              curve: OrbAnimations.curve,
              width: 160,
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              transform: Matrix4.identity()
                ..scale(isHovered ? 1.05 : 1.0),
              decoration: BoxDecoration(
                color: OrbColors.bgSecondary,
                borderRadius: BorderRadius.circular(OrbRadius.lg),
                border: Border.all(
                  color: isHovered
                      ? widget.color.withValues(alpha: 0.5)
                      : OrbColors.border,
                  width: 1.5,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with glow
                  AnimatedContainer(
                    duration: OrbAnimations.normal,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: isHovered ? 0.25 : 0.15),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(widget.icon, size: 24, color: widget.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    style: OrbText.titleLarge.copyWith(
                      color: isHovered ? OrbColors.starWhite : OrbColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: OrbText.caption.copyWith(
                      color: OrbColors.textMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
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
