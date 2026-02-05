import 'package:flutter/material.dart';
import '../ui/fusion/design_system.dart';
import '../services/navigation_service.dart';

class FusionSidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const FusionSidebar(
      {super.key, required this.currentIndex, required this.onSelected});

  @override
  State<FusionSidebar> createState() => _FusionSidebarState();
}

class _FusionSidebarState extends State<FusionSidebar> {
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  static const double _collapsedWidth = 64.0;
  static const double _expandedWidth = 200.0;

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
            duration: const Duration(milliseconds: 200),
            width: width,
            decoration: BoxDecoration(
              color: FusionColors.bgSecondary,
              border: Border(
                  right: BorderSide(color: FusionColors.border, width: 1)),
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
                        fit: FlexFit.loose,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
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
                _sidebarItem(NavigationService.home, Icons.home_outlined,
                    'Home', isHovered),
                _sidebarItem(NavigationService.discovery,
                    Icons.explore_outlined, 'Deep Space', isHovered),
                _sidebarItem(NavigationService.games, Icons.map_outlined,
                    'Star Map', isHovered),
                _sidebarItem(NavigationService.downloads,
                    Icons.downloading_outlined, 'Warp', isHovered),
                _sidebarItem(NavigationService.homebrew,
                    Icons.developer_mode_outlined, 'Homebrew', isHovered),
                _sidebarItem(NavigationService.tools,
                    Icons.construction_outlined, 'Engineering', isHovered),
                const Spacer(),
                _sidebarItem(NavigationService.settings,
                    Icons.settings_outlined, 'Command', isHovered),
                const SizedBox(height: 12),
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
              ? Border(
                  left: BorderSide(color: FusionColors.nintendoRed, width: 4))
              : null,
          color: selected ? FusionColors.bgTertiary : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                child: Icon(icon,
                    color: selected
                        ? FusionColors.nintendoRed
                        : FusionColors.textSecondary,
                    size: 22),
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      color: selected
                          ? FusionColors.textPrimary
                          : FusionColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
