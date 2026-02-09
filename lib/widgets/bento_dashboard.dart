import 'package:flutter/material.dart';
import '../theme/fusion_theme.dart';

/// Bento Dashboard Layout - Main shell of the application
class BentoDashboard extends StatelessWidget {
  final FusionThemeMode themeMode;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget child;

  const BentoDashboard({
    super.key,
    required this.themeMode,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (responsive labels)
          LayoutBuilder(
            builder: (context, constraints) {
              final labelType = constraints.maxWidth > 1000
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected;
              return NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: labelType,
                backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
                indicatorColor: primaryColor.withValues(alpha: 0.15),
                destinations: [
                  const NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: Text('Discovery'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.grid_view),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: Text('Library'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.usb_outlined),
                    selectedIcon: Icon(Icons.usb),
                    label: Text('Hardware'),
                  ),
                ],
            leading: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gamepad, color: primaryColor, size: 24),
                ),
                const SizedBox(height: 32),
              ],
            ),
                );
            },
          ),

          // Vertical Divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: isDark ? Colors.white10 : Colors.grey[200],
          ),

          // Main Content Area
          Expanded(child: child),
        ],
      ),
    );
  }
}
