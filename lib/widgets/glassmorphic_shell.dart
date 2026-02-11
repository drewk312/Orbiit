import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class GlassmorphicShell extends StatelessWidget {
  final Widget child;

  const GlassmorphicShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // THE RADIANT BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    Color(0xFF0D161E),
                    Color(0xFF050A0E),
                  ],
                ),
              ),
            ),
          ),

          // AMBIENT GLOW SQUARES
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C2FF).withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              // 📂 CUSTOM GLASS HEADER
              const _GlassHeader(),

              // MAIN CONTENT AREA
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onPanStart: (_) => windowManager.startDragging(),
        child: Row(
          children: [
            // BRAND IDENTITY
            const Icon(Icons.blur_on, color: Color(0xFF00C2FF), size: 28),
            const SizedBox(width: 12),
            Text(
              'ORBIIT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: primaryColor.withValues(alpha: 0.8),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // 3D SQUISHY BUTTONS
            _SquishyButton(
              color: Colors.white.withValues(alpha: 0.1),
              icon: Icons.minimize,
              onTap: () => windowManager.minimize(),
            ),
            const SizedBox(width: 12),
            _SquishyButton(
              color: Colors.white.withValues(alpha: 0.1),
              icon: Icons.crop_square,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            const SizedBox(width: 12),
            _SquishyButton(
              color: Colors.redAccent.withValues(alpha: 0.2),
              icon: Icons.close,
              isClose: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquishyButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _SquishyButton({
    required this.color,
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_SquishyButton> createState() => _SquishyButtonState();
}

class _SquishyButtonState extends State<_SquishyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isPressed ? 0.3 : 0.1),
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: 14,
          color: widget.isClose ? Colors.redAccent : Colors.white70,
        ),
      ),
    );
  }
}
