import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/fusion_theme.dart';
import '../providers/forge_provider.dart';
import '../services/update_service.dart';
import '../main.dart'; // For AppConfig

/// Settings Screen - Theme selection with animated toggle
class SettingsScreen extends StatefulWidget {
  final FusionThemeMode currentTheme;
  final bool isDarkMode;
  final Function(FusionThemeMode) onThemeChanged;
  final Function(bool) onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleController;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;

  // Update Logic
  bool _checkingForUpdate = false;
  String _updateStatus = '';
  UpdateRelease? _updateAvailable;
  double? _updateProgress;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeOutBack),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
    );

    if (widget.isDarkMode) {
      _toggleController.value = 1;
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDarkMode != oldWidget.isDarkMode) {
      if (widget.isDarkMode) {
        _toggleController.forward();
      } else {
        _toggleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    super.dispose();
  }

  void _toggleDarkMode() {
    widget.onDarkModeChanged(!widget.isDarkMode);
  }

  Widget _buildDownloadSettingsCard() {
    return Consumer<ForgeProvider>(builder: (context, forge, child) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Downloads',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Auto-start persisted queue'),
                subtitle: const Text(
                    'Automatically start queued downloads from previous sessions'),
                value: forge.autoStartPersistedQueue,
                onChanged: (v) => forge.autoStartPersistedQueue = v,
              ),
              SwitchListTile(
                title: const Text('Allow resume at offset'),
                subtitle: const Text(
                    'Attempt to resume interrupted downloads when supported by source/native'),
                value: forge.allowResumeAtOffset,
                onChanged: (v) => forge.allowResumeAtOffset = v,
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.3),
                      primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.settings_suggest_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Customize your experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Kinetic Dark Mode Toggle
          _buildKineticDarkModeCard(primaryColor, isDark),

          const SizedBox(height: 32),

          // Updates
          _buildUpdateCard(context, primaryColor, isDark),

          const SizedBox(height: 32),

          // Download settings (auto-start persisted queue, resume toggle)
          _buildDownloadSettingsCard(),

          const SizedBox(height: 32),

          // Theme Grid Title
          Text(
            'Theme Personality',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Theme Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: FusionThemeMode.values.length,
              itemBuilder: (context, index) {
                final mode = FusionThemeMode.values[index];
                return _buildThemeCard(context, mode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(
      BuildContext context, Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _updateAvailable != null
                    ? Colors.green.withValues(alpha: 0.1)
                    : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _updateAvailable != null
                    ? Icons.system_update
                    : Icons.system_update_alt,
                color: _updateAvailable != null ? Colors.green : primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _updateAvailable != null
                        ? 'Update Available!'
                        : 'Application Version',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (_updateAvailable != null)
                    Text('Version ${_updateAvailable!.tagName} is ready.',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey))
                  else
                    Text(
                        'Current: ${AppConfig.version} ${_updateStatus.isNotEmpty ? '• $_updateStatus' : ''}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  if (_updateProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _updateProgress),
                  ]
                ],
              ),
            ),
            if (_updateProgress == null)
              ElevatedButton(
                onPressed: _checkingForUpdate ? null : _handleUpdateCheck,
                child: Text(_updateAvailable != null ? 'UPDATE' : 'CHECK'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdateCheck() async {
    if (_updateAvailable != null) {
      // Perform update
      setState(() {
        _checkingForUpdate = true;
        _updateProgress = 0.0;
      });
      try {
        await UpdateService().downloadAndInstall(_updateAvailable!, (progress) {
          if (mounted) setState(() => _updateProgress = progress);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Update failed: $e')));
          setState(() {
            _checkingForUpdate = false;
            _updateProgress = null;
          });
        }
      }
      return;
    }

    // Check
    setState(() {
      _checkingForUpdate = true;
      _updateStatus = 'Checking...';
    });

    final release = await UpdateService().checkForUpdates();

    if (mounted) {
      if (release != null) {
        setState(() {
          _updateAvailable = release;
          _updateStatus = '';
          _checkingForUpdate = false;
        });
      } else {
        setState(() {
          _updateStatus = 'Up to date';
          _checkingForUpdate = false;
        });

        // Clear status after delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _updateStatus = '');
        });
      }
    }
  }

  Widget _buildKineticDarkModeCard(Color primaryColor, bool isDark) {
    return GestureDetector(
      onTap: _toggleDarkMode,
      child: ListenableBuilder(
        listenable: _toggleController,
        builder: (context, _) {
          final sunColor = const Color(0xFFFFB800);
          final moonColor = const Color(0xFF8B5CF6);
          final bgColor = Color.lerp(
            sunColor.withValues(alpha: 0.15),
            moonColor.withValues(alpha: 0.15),
            _rotationAnim.value,
          )!;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColor, bgColor.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color.lerp(
                  sunColor,
                  moonColor,
                  _rotationAnim.value,
                )!
                    .withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    sunColor,
                    moonColor,
                    _rotationAnim.value,
                  )!
                      .withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Kinetic Icon
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(sunColor, moonColor, _rotationAnim.value)!,
                          Color.lerp(
                            sunColor.withValues(alpha: 0.7),
                            moonColor.withValues(alpha: 0.7),
                            _rotationAnim.value,
                          )!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(
                            sunColor,
                            moonColor,
                            _rotationAnim.value,
                          )!
                              .withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _rotationAnim.value * 3.14159,
                      child: Icon(
                        widget.isDarkMode
                            ? Icons.nightlight_round
                            : Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isDarkMode
                            ? 'Easy on the eyes'
                            : 'Bright and clear',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Track
                Container(
                  width: 64,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: Color.lerp(
                      const Color(0xFFE0E0E0),
                      const Color(0xFF2D2D3A),
                      _rotationAnim.value,
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: widget.isDarkMode ? 32 : 4,
                        top: 4,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isDarkMode
                                ? Icons.nightlight_round
                                : Icons.wb_sunny,
                            size: 16,
                            color: widget.isDarkMode ? moonColor : sunColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, FusionThemeMode mode) {
    final info = FusionTheme.themeInfo[mode]!;
    final isSelected = widget.currentTheme == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onThemeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    info.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    info.primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? info.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: info.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [info.primaryColor, info.accentColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: info.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(info.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              info.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? info.primaryColor
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              info.description,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
