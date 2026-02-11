import 'package:flutter/material.dart';

import '../services/navigation_service.dart';
import '../ui/fusion/design_system.dart';

class FusionSidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const FusionSidebar(
      {required this.currentIndex, required this.onSelected, super.key});

  @override
  State<FusionSidebar> createState() => _FusionSidebarState();
}

class _FusionSidebarState extends State<FusionSidebar> {
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  static const double _collapsedWidth = 72; // Restored
  static const double _expandedWidth =
      220; // Optimized width to fit "Command Center" without extra gap

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  void _onEnter(_) => _hovered.value = true;
  void _onExit(_) => _hovered.value = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: ValueListenableBuilder<bool>(
        valueListenable: _hovered,
        builder: (context, isHovered, child) {
          final width = isHovered ? _expandedWidth : _collapsedWidth;
          return AnimatedContainer(
            duration: FusionAnimations.medium,
            curve: FusionAnimations.curve,
            width: width,
            decoration: const BoxDecoration(
              color: FusionColors.bgSecondary,
              border: Border(right: BorderSide(color: FusionColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: FusionColors.nintendoRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videogame_asset,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      if (isHovered) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                                text: 'ORBIIT',
                                style: FusionText.headlineMedium
                                    .copyWith(color: FusionColors.textPrimary)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Destinations
                _sidebarItem(NavigationService.home, Icons.dashboard_rounded,
                    'Command Center', isHovered),
                _sidebarItem(NavigationService.discovery, Icons.explore_rounded,
                    'Deep Space', isHovered),
                _sidebarItem(NavigationService.downloads,
                    Icons.rocket_launch_rounded, 'Warp', isHovered),
                _sidebarItem(NavigationService.games, Icons.map_rounded,
                    'Star Map', isHovered),
                _sidebarItem(NavigationService.homebrew, Icons.science_rounded,
                    'Tech Lab', isHovered),
                _sidebarItem(NavigationService.tools, Icons.build_rounded,
                    'Engineering', isHovered),
                const Spacer(),
                _sidebarItem(NavigationService.settings, Icons.settings_rounded,
                    'Observatory', isHovered),
                const SizedBox(
                    height: 8), // Reduced from 12 to prevent overflow
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label, bool expanded) {
    final selected = widget.currentIndex == index;
    return InkWell(
      onTap: () => widget.onSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: selected
              ? const Border(
                  left: BorderSide(color: FusionColors.nintendoRed, width: 4))
              : null,
          color: selected ? FusionColors.bgTertiary : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              alignment: Alignment.centerLeft,
              child: Icon(icon,
                  color: selected
                      ? FusionColors.nintendoRed
                      : FusionColors.textSecondary,
                  size: 22),
            ),
            if (expanded) ...[
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: selected
                            ? FusionColors.textPrimary
                            : FusionColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
