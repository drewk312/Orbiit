import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/fusion/design_system.dart';
import '../providers/forge_provider.dart';
import '../providers/discovery_provider.dart';
import '../services/update_service.dart';
import '../main.dart'; // For AppConfig
import 'theme_settings_new.dart'; // Import theme settings

import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Update Logic
  bool _checkingForUpdate = false;
  String _updateStatus = '';
  UpdateRelease? _updateAvailable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GlassCard(
          width: 800,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: OrbColors.border)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      OrbColors.orbitCyan.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OrbColors.orbitCyan.withValues(alpha: 0.15),
                      ),
                      child: Icon(Icons.tune_rounded,
                          size: 24, color: OrbColors.orbitCyan),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Command Center', style: OrbText.headlineMedium),
                          Text('Configure your Orbiit experience',
                              style: OrbText.bodyMedium
                                  .copyWith(color: OrbColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // --- APPEARANCE SECTION ---
                    _buildSectionTitle('Appearance'),
                    const SizedBox(height: 16),
                    _buildSettingTile(
                      title: 'Themes & Visuals',
                      subtitle: 'Customize accent colors and interface style',
                      icon: Icons.palette_rounded,
                      action: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ThemeSettingsScreen()),
                          );
                        },
                        child: const Text('Customize'),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- LIBRARY SECTION ---
                    _buildSectionTitle('Library & Storage'),
                    const SizedBox(height: 16),
                    _buildSettingTile(
                      title: 'Library Paths',
                      subtitle: 'D:\\Games\\Wii',
                      icon: Icons.folder_open_rounded,
                      action: OutlinedButton(
                        onPressed: () {
                          // Stub for path picker
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Manage Paths')));
                        },
                        child: const Text('Manage'),
                      ),
                    ),
                    Consumer<ForgeProvider>(
                      builder: (context, forge, child) {
                        return _buildSettingTile(
                          title: 'Clear Download Queue',
                          subtitle:
                              '${forge.downloadQueue.length} items pending',
                          icon: Icons.cleaning_services_rounded,
                          action: OutlinedButton(
                            onPressed: forge.downloadQueue.isEmpty
                                ? null
                                : () {
                                    forge.clearQueue();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Download queue cleared')),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OrbColors.corrupt,
                              side: const BorderSide(color: OrbColors.corrupt),
                            ),
                            child: const Text('Clear'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- PERSONALIZATION SECTION ---
                    _buildSectionTitle('Personalization'),
                    const SizedBox(height: 16),
                    _buildSettingTile(
                      title: 'Appearance',
                      subtitle: 'Themes, scaling, and motion',
                      icon: Icons.palette_rounded,
                      action: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThemeSettingsScreen(),
                            ),
                          );
                        },
                        child: const Text('Customize'),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- APPLICATION SECTION ---
                    _buildSectionTitle('Application'),
                    const SizedBox(height: 16),
                    _buildUpdateTile(),

                    const SizedBox(height: 32),

                    // --- SYSTEM SECTION ---
                    _buildSectionTitle('System'),
                    const SizedBox(height: 16),
                    _buildSettingTile(
                      title: 'Database & Metadata',
                      subtitle: 'Last updated: Today',
                      icon: Icons.storage_rounded,
                      action: OutlinedButton(
                        onPressed: () {
                          context.read<DiscoveryProvider>().loadStoreSections();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Reloading Store Data...')));
                        },
                        child: const Text('Reload'),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- ABOUT SECTION ---
                    _buildSectionTitle('About'),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.5,
                            colors: [
                              OrbColors.orbitCyan.withValues(alpha: 0.08),
                              OrbColors.orbitPurple.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OrbColors.orbitCyan.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Orbiit Logo representation
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    OrbColors.bgTertiary,
                                    OrbColors.void_,
                                  ],
                                ),
                                border: Border.all(
                                  color: OrbColors.orbitCyan
                                      .withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: OrbColors.orbitCyan
                                        .withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Center O ring
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: OrbColors.starWhite,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  // Cyan dot
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: OrbColors.orbitCyan,
                                        boxShadow: [
                                          BoxShadow(
                                            color: OrbColors.orbitCyan
                                                .withValues(alpha: 0.8),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Purple dot
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: OrbColors.orbitPurple,
                                        boxShadow: [
                                          BoxShadow(
                                            color: OrbColors.orbitPurple
                                                .withValues(alpha: 0.8),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ORBIIT wordmark
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('ORB',
                                    style: OrbText.headlineLarge.copyWith(
                                      color: OrbColors.starWhite,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    )),
                                Text('I',
                                    style: OrbText.headlineLarge.copyWith(
                                      color: OrbColors.orbitCyan,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text('I',
                                    style: OrbText.headlineLarge.copyWith(
                                      color: OrbColors.orbitPurple,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text('T',
                                    style: OrbText.headlineLarge.copyWith(
                                      color: OrbColors.starWhite,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Your games. In orbit.',
                                style: OrbText.caption.copyWith(
                                  color: OrbColors.textMuted,
                                  letterSpacing: 2,
                                  fontSize: 11,
                                )),
                            const SizedBox(height: 8),
                            Text('v1.0.0 "Cosmos"',
                                style: OrbText.bodyMedium.copyWith(
                                  color: OrbColors.textSecondary,
                                )),
                            const SizedBox(height: 20),
                            Text(
                              'A premium, space-themed library manager for your\nWii, GameCube, and retro game collection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: OrbColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('Made by Drewk312 with love',
                                style: OrbText.bodyMedium.copyWith(
                                    color: OrbColors.orbitCyan,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            GlowButton(
                              label: 'Support Development',
                              icon: Icons.rocket_launch_rounded,
                              color: OrbColors.orbitPurple,
                              isCompact: true,
                              onPressed: () async {
                                final Uri url =
                                    Uri.parse('https://ko-fi.com/drewk312');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Could not launch URL')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateTile() {
    return _buildSettingTile(
      title:
          _updateAvailable != null ? 'Update Available!' : 'Check for Updates',
      subtitle: _updateAvailable != null
          ? 'Version ${_updateAvailable!.tagName} is ready.'
          : _updateStatus.isNotEmpty
              ? _updateStatus
              : 'Current Version: ${AppConfig.version}',
      icon: _updateAvailable != null
          ? Icons.system_update
          : Icons.system_update_alt,
      action: OutlinedButton(
        onPressed: _checkingForUpdate ? null : _handleUpdateCheck,
        style: _updateAvailable != null
            ? OutlinedButton.styleFrom(
                foregroundColor: OrbColors.orbitCyan,
                side: BorderSide(color: OrbColors.orbitCyan),
              )
            : null,
        child: _checkingForUpdate
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_updateAvailable != null ? 'Update' : 'Check'),
      ),
    );
  }

  Future<void> _handleUpdateCheck() async {
    if (_updateAvailable != null) {
      // Launch update
      final url = _updateAvailable!.htmlUrl; // Or use assets loop logic
      // Ideally show the dialog from NavigationWrapper, but launching browser is safe for now
      if (await canLaunchUrl(Uri.parse(url))) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      return;
    }

    setState(() {
      _checkingForUpdate = true;
      _updateStatus = 'Checking...';
    });

    try {
      final release = await UpdateService().checkForUpdates();
      if (mounted) {
        if (release != null) {
          setState(() {
            _updateAvailable = release;
            _checkingForUpdate = false;
            _updateStatus = 'New version found!';
          });
        } else {
          setState(() {
            _checkingForUpdate = false;
            _updateStatus = 'You are up to date.';
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _updateAvailable == null)
              setState(() => _updateStatus = '');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdate = false;
          _updateStatus = 'Check failed.';
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: OrbText.caption
                .copyWith(color: OrbColors.orbitCyan, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                OrbColors.orbitCyan.withValues(alpha: 0.5),
                OrbColors.orbitCyan.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FusionTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: FusionTypography.bodyMedium
                        .copyWith(color: FusionColors.textSecondary)),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
