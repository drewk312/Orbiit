import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Engine',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WiiGCThemePreset.values.map((preset) {
                final theme = WiiGCTheme.getTheme(preset);
                return _ThemeOption(
                  theme: theme,
                  isSelected: themeProvider.currentTheme.preset == preset,
                  onTap: () => themeProvider.setTheme(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Reduced Motion'),
                const Spacer(),
                Switch(
                  value: themeProvider.currentTheme.reducedMotion,
                  onChanged: (value) {
                    themeProvider.updateTheme(
                      themeProvider.currentTheme.copyWith(reducedMotion: value),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('Font Scale'),
                const Spacer(),
                Slider(
                  value: themeProvider.currentTheme.fontScale,
                  min: 0.8,
                  max: 1.4,
                  onChanged: (value) {
                    themeProvider.updateTheme(
                      themeProvider.currentTheme.copyWith(fontScale: value),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final WiiGCTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: theme.animationDuration,
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(theme.cornerRadius),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              theme.preset.name.replaceAll('WiiGCThemePreset.', ''),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}