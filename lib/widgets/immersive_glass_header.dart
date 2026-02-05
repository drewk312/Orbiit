import 'dart:ui';
import '../ui/fusion/design_system.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// ImmersiveGlassHeader - Hides native Windows title bar and provides glassmorphic header
/// with window controls and navigation
class ImmersiveGlassHeader extends StatefulWidget {
  final String title;

  /// Optional subtitle / tagline shown under the title
  final String? subtitle;
  final Widget?
      titleWidget; // Custom widget to replace title text (e.g. Search Bar)
  final List<Widget>? actions;
  final Widget? leading;
  final bool showWindowControls;
  final double height;

  const ImmersiveGlassHeader({
    super.key,
    this.title = 'Orbiit',
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showWindowControls = true,
    this.height = 52,
  });

  @override
  State<ImmersiveGlassHeader> createState() => _ImmersiveGlassHeaderState();
}

class _ImmersiveGlassHeaderState extends State<ImmersiveGlassHeader> {
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: widget.subtitle != null ? 60 : widget.height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: FusionColors.glassBorder,
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                // "Midnight Aurora" Glass Header
                color: FusionColors.glass, // 8% white base
              ),
              child: Row(
                children: [
                  // Leading widget (menu/back button)
                  if (widget.leading != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: widget.leading!,
                    )
                  else
                    const SizedBox(width: 12),

                  // App icon (only show if using default title)
                  if (widget.titleWidget == null) ...[
                    _GlowIcon(
                      icon: Icons.gamepad_rounded,
                      color: FusionColors.electricCyan,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Title + optional subtitle or Custom Widget
                  Expanded(
                    child: widget.titleWidget ??
                        _TitleBlock(
                          title: widget.title,
                          subtitle: widget.subtitle,
                        ),
                  ),

                  // Custom actions
                  if (widget.actions != null) ...widget.actions!,

                  const SizedBox(width: 8),

                  // Window controls (top only) – aesthetic pill group
                  if (widget.showWindowControls) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(FusionRadius.lg),
                        border: Border.all(
                          color: FusionColors.glassBorder,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(FusionRadius.lg),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: FusionColors.glassWhite(0.05),
                              borderRadius:
                                  BorderRadius.circular(FusionRadius.lg),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _WindowControlButton(
                                  icon: Icons.remove_rounded,
                                  onPressed: _minimizeWindow,
                                  hoverColor: FusionColors.electricCyan
                                      .withValues(alpha: 0.18),
                                  iconColor: FusionColors.electricCyan,
                                  size: 28,
                                ),
                                const SizedBox(width: 4),
                                _WindowControlButton(
                                  icon: _isMaximized
                                      ? Icons.filter_none_rounded
                                      : Icons.crop_square_rounded,
                                  onPressed: _toggleMaximize,
                                  hoverColor: FusionColors.electricCyan
                                      .withValues(alpha: 0.18),
                                  iconColor: FusionColors.electricCyan,
                                  size: 28,
                                ),
                                const SizedBox(width: 4),
                                _WindowControlButton(
                                  icon: Icons.close_rounded,
                                  onPressed: _closeWindow,
                                  hoverColor: FusionColors.error
                                      .withValues(alpha: 0.25),
                                  iconColor:
                                      FusionColors.error.withValues(alpha: 0.8),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _minimizeWindow() async {
    await windowManager.minimize();
  }

  void _toggleMaximize() async {
    bool isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    setState(() {
      _isMaximized = !isMaximized;
    });
  }

  void _closeWindow() async {
    await windowManager.close();
  }
}

/// Title + optional subtitle block with gradient and subtle glow
class _TitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _TitleBlock({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.92),
              FusionColors.electricCyan.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(bounds),
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 0),
          Text(
            subtitle!,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}

/// Icon with subtle glow for header
class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _GlowIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: size + 8, color: color.withValues(alpha: 0.2)),
        Icon(icon, size: size, color: color),
      ],
    );
  }
}

/// Custom window control button with hover effects
class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color iconColor;
  final double size;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor = const Color(0x4DFFFFFF),
    this.iconColor = const Color(0xB3FFFFFF),
    required this.size,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  final ValueNotifier<bool> _isHoveringNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHoveringNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHoveringNotifier.value = true,
      onExit: (_) => _isHoveringNotifier.value = false,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHoveringNotifier,
          builder: (context, isHovering, _) {
            return AnimatedContainer(
              duration: FusionAnimations.fast,
              curve: FusionAnimations.curve,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: isHovering ? widget.hoverColor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                size: 14,
                color: isHovering
                    ? widget.iconColor
                    : Colors.white.withValues(alpha: 0.5),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Complete app shell with immersive glass header
class ImmersiveAppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool showWindowControls;

  const ImmersiveAppShell({
    super.key,
    required this.child,
    this.title = 'Orbiit',
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.showWindowControls = true,
  });

  double get _headerHeight => subtitle != null ? 72 : 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_headerHeight),
        child: ImmersiveGlassHeader(
          title: title,
          subtitle: subtitle,
          titleWidget: titleWidget,
          actions: actions,
          leading: leading,
          showWindowControls: showWindowControls,
          height: _headerHeight,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: _headerHeight),
        child: child,
      ),
    );
  }
}
