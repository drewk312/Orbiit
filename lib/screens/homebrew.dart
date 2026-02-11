import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_logger.dart';
import '../models/game_result.dart';
import '../providers/forge_provider.dart';
import '../providers/osc_provider.dart';
import '../providers/wiiload_provider.dart';
import '../services/dlc_manager_service.dart';
import '../services/gamebrew_service.dart';
import '../services/homebrew_automation_service.dart';
import '../services/project_plus_service.dart';
import '../services/riivolution_service.dart';
import '../ui/fusion/design_system.dart';
import '../widgets/fusion_app_card.dart';
import '../widgets/immersive_glass_header.dart';

/// Call from header (e.g. NavigationWrapper) to show Wiiload connection dialog (connect only, no send).
void showWiiloadConnectionDialog(BuildContext context) {
  final initialIp = Provider.of<WiiloadProvider>(context, listen: false).wiiIp;
  showDialog(
    context: context,
    builder: (_) => _WiiloadDialogConnectOnly(initialIp: initialIp),
  );
}

class _WiiloadDialogConnectOnly extends StatefulWidget {
  final String initialIp;

  const _WiiloadDialogConnectOnly({required this.initialIp});

  @override
  State<_WiiloadDialogConnectOnly> createState() =>
      _WiiloadDialogConnectOnlyState();
}

class _WiiloadDialogConnectOnlyState extends State<_WiiloadDialogConnectOnly> {
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderRadius: BorderRadius.circular(FusionRadius.xl),
        padding: const EdgeInsets.all(24),
        glowColor: FusionColors.nebulaCyan,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WIILOAD CONNECTION',
              style: FusionText.labelLarge
                  .copyWith(color: FusionColors.nebulaCyan),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your Wii IP address to enable Wiiload',
              style: FusionText.bodyMedium
                  .copyWith(color: FusionColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              style: FusionText.bodyMedium,
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                hintStyle: FusionText.bodyMedium
                    .copyWith(color: FusionColors.textMuted),
                labelText: 'Wii IP Address',
                labelStyle: FusionText.labelMedium
                    .copyWith(color: FusionColors.nebulaCyan),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                  borderSide: const BorderSide(color: FusionColors.textMuted),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                  borderSide: BorderSide(
                      color: FusionColors.textMuted.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                  borderSide: const BorderSide(
                      color: FusionColors.nebulaCyan, width: 2),
                ),
                filled: true,
                fillColor: FusionColors.bgPrimary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<WiiloadProvider>(
              builder: (context, wiiloadProvider, child) {
                if (wiiloadProvider.isLoading) {
                  return const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(FusionColors.nebulaCyan),
                  );
                }
                if (wiiloadProvider.error.isNotEmpty) {
                  return Text(
                    wiiloadProvider.error,
                    style:
                        FusionText.caption.copyWith(color: FusionColors.error),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'CANCEL',
                        style: FusionText.labelMedium
                            .copyWith(color: FusionColors.textMuted),
                      ),
                    ),
                    GlowButton(
                      label: 'CONNECT',
                      icon: Icons.wifi,
                      color: FusionColors.nebulaCyan,
                      onPressed: () async {
                        wiiloadProvider.setWiiIp(_ipController.text);
                        final connected =
                            await wiiloadProvider.testConnection();
                        if (connected && mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Homebrew Browser Screen - Open Shop Channel integration
/// When [embedInWrapper] is true, returns only content (no app shell) for use in NavigationWrapper.
class HomebrewScreen extends StatefulWidget {
  final bool embedInWrapper;

  const HomebrewScreen({super.key, this.embedInWrapper = false});

  @override
  State<HomebrewScreen> createState() => _HomebrewScreenState();
}

class _HomebrewScreenState extends State<HomebrewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'recommended'; // Default to recommended
  String _selectedConsole = 'wii'; // 'wii' or 'wiiu'

  // Project+ State
  bool _downloadingPPlus = false;
  double _pplusProgress = 0;
  String _pplusStatus = '';
  final ProjectPlusService _projectPlusService = ProjectPlusService();

  // GameBrew (Rom Hacks) State
  final GameBrewService _gameBrewService = GameBrewService();
  List<GameResult> _romHacks = [];
  bool _loadingRomHacks = false;

  @override
  void initState() {
    super.initState();
    // Load popular homebrew on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OSCProvider>(context, listen: false);
      // Load recommended by default now
      provider.loadRecommendedHomebrew();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OSCProvider>(context);
    final categories = provider.categories;

    final content = Padding(
      padding:
          const EdgeInsets.fromLTRB(40, 20, 40, 24), // Reduced bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console selector (Wii vs Wii U) and WiiLoad button
          _buildHeaderRow(),
          const SizedBox(height: 20),
          _buildCategoryTabs(categories, provider),
          const SizedBox(height: 24),
          _buildSearchBar(provider),
          const SizedBox(height: 30),
          Expanded(
            child: _selectedConsole == 'wiiu'
                ? _buildWiiUHomebrewSection()
                : _selectedCategory == 'recommended'
                    ? _buildRecommendedSection(provider)
                    : _selectedCategory == 'rom_hacks'
                        ? _buildRomHacksSection()
                        : provider.isLoading
                            ? _buildLoadingState()
                            : provider.error.isNotEmpty
                                ? _buildErrorState(provider.error, provider)
                                : provider.homebrewResults.isEmpty
                                    ? _buildEmptyState()
                                    : _buildHomebrewGrid(provider),
          ),
        ],
      ),
    );

    if (widget.embedInWrapper) return content;

    return ImmersiveAppShell(
      title: 'HOMEBREW',
      child: content,
    );
  }

  Widget _buildErrorState(String error, OSCProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 80, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'CONNECTION ERROR',
            style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No homebrew apps found',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Center(
      // Center the toggle
      child: GlassCard(
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(FusionRadius.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConsoleTab('Wii', 'wii', FusionColors.nebulaCyan),
            const SizedBox(width: 4),
            _buildConsoleTab('Wii U', 'wiiu', FusionColors.nebulaViolet),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleTab(String label, String console, Color color) {
    final isSelected = _selectedConsole == console;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedConsole = console;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(FusionRadius.lg),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              console == 'wii' ? Icons.gamepad : Icons.tablet_android,
              size: 18,
              color: isSelected
                  ? FusionColors.textPrimary
                  : FusionColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: isSelected
                  ? FusionText.labelMedium
                      .copyWith(color: FusionColors.textPrimary)
                  : FusionText.bodyMedium
                      .copyWith(color: FusionColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// Wii U Homebrew Section with Aroma ecosystem apps
  Widget _buildWiiUHomebrewSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wii U Homebrew (Aroma)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wii U uses the Aroma environment. Apps go in wiiu/environments/aroma/plugins/',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Essential Apps Section
          _buildWiiUSection('Essential Apps', _getEssentialWiiUApps(),
              const Color(0xFF10B981)),
          const SizedBox(height: 32),

          // Plugins Section
          _buildWiiUSection('Recommended Plugins', _getWiiUPlugins(),
              const Color(0xFFF59E0B)),
          const SizedBox(height: 32),

          // Utilities Section
          _buildWiiUSection(
              'Utilities', _getWiiUUtilities(), const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildDLCManagerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.queue_music,
                color: Colors.pinkAccent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legacy DLC Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tools for Rock Band / Just Dance DLC (xyzzy, keys, wad2bin helper).',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GlowButton(
            label: 'MANAGE DLC',
            icon: Icons.library_music,
            color: Colors.pinkAccent,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _DLCManagerDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleBatchUpdate(OSCProvider provider) async {
    final sdCard = await _pickSDCard(context);
    if (sdCard == null) return;

    // Show progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchUpdateProgressDialog(
        games: provider.homebrewResults,
        sdCard: sdCard,
      ),
    );
  }

  Future<Directory?> _pickSDCard(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select your SD Card Root',
      lockParentWindow: true,
    );

    if (result != null) {
      return Directory(result);
    }
    return null;
  }

  Widget _buildEssentialsAutomationCard(OSCProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(FusionRadius.xl),
      // height: 100, // Let it adjust
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.cyanAccent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Essentials Update',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-install or update all recommended homebrew apps to your SD card in one go.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GlowButton(
            label: 'UPDATE ALL',
            icon: Icons.system_update_alt,
            color: Colors.cyanAccent,
            onPressed:
                provider.isLoading ? null : () => _handleBatchUpdate(provider),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRomHacks() async {
    if (_romHacks.isNotEmpty) return;
    if (mounted) setState(() => _loadingRomHacks = true);

    try {
      final hacks = await _gameBrewService.fetchHomebrew();
      if (mounted) {
        setState(() {
          _romHacks = hacks;
          _loadingRomHacks = false;
        });
      }
    } catch (e) {
      AppLogger.instance.error('Error loading rom hacks: $e');
      if (mounted) setState(() => _loadingRomHacks = false);
    }
  }

  Widget _buildRomHacksSection() {
    if (_loadingRomHacks) return _buildLoadingState();
    if (_romHacks.isEmpty) return _buildEmptyState();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _romHacks.length,
          itemBuilder: (context, index) {
            final hack = _romHacks[index];
            return FusionAppCard(
              game: hack,
              onInfo: () => _handleRomHackAction(hack),
              onForge: () => _handleRomHackAction(hack),
            );
          },
        );
      },
    );
  }

  void _handleRomHackAction(GameResult hack) {
    final url = hack.pageUrl;
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Recommended Section with Project+ Banner and curated apps
  Widget _buildRecommendedSection(OSCProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectPlusBanner(),
          const SizedBox(height: 24),
          _buildRiivolutionCard(),
          const SizedBox(height: 24),
          _buildDLCManagerCard(),
          const SizedBox(height: 24),
          // Essentials Automation Card
          _buildEssentialsAutomationCard(provider),
          const SizedBox(height: 32),
          if (provider.isLoading)
            _buildLoadingState()
          else if (provider.error.isNotEmpty)
            _buildErrorState(provider.error, provider)
          else if (provider.homebrewResults.isEmpty)
            _buildEmptyState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: FusionColors.nebulaCyan,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ESSENTIAL HOMEBREW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHomebrewGrid(provider, shrinkWrap: true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProjectPlusBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FusionRadius.xl),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.8), // Deep Blue
            const Color(0xFF3B82F6).withValues(alpha: 0.6), // Light Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Element
          Positioned(
            right: -50,
            top: -50,
            child: Icon(
              Icons.sports_esports,
              size: 200,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(FusionRadius.lg),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Color(0xFF60A5FA),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROJECT PLUS v3.1.5',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The ultimate Super Smash Bros. Brawl mod. Includes balance changes, new characters, and stages.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_downloadingPPlus) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _pplusStatus,
                            style: FusionText.labelMedium
                                .copyWith(color: FusionColors.nebulaCyan),
                          ),
                          Text(
                            '${(_pplusProgress * 100).toInt()}%',
                            style: FusionText.labelMedium
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _pplusProgress,
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              FusionColors.nebulaCyan),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  )
                ] else
                  Row(
                    children: [
                      GlowButton(
                        label: 'INSTALL PROJECT+',
                        icon: Icons.download_rounded,
                        color: const Color(0xFF3B82F6),
                        onPressed: _installProjectPlus,
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => launchUrl(
                            Uri.parse('https://projectplusgame.com/')),
                        icon: const Icon(Icons.open_in_new,
                            size: 16, color: Colors.white70),
                        label: const Text('WEBSITE',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiivolutionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24), // Space below it
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_suggest,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riivolution Mod Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-install mods from .zip files. Handles file placement for you.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GlowButton(
            label: 'MANAGE',
            icon: Icons.build,
            color: FusionColors.nebulaPurple,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _RiivolutionManagerDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _installProjectPlus() async {
    // Basic confirmation dialog could go here
    setState(() {
      _downloadingPPlus = true;
      _pplusProgress = 0.0;
      _pplusStatus = 'Initializing...';
    });

    try {
      // Assuming generic SD root at 'D:\' for dev/test or similar?
      // Or relying on standard paths.
      // In a real scenario, we might ask the user or detect the SD card.
      // For now, let's use a safe location like 'C:\Temp\WiiSD' or ask provider where SD is.
      // Wait, `HardwareWizard` usually detects it.
      // I'll grab the path from `WiiloadProvider` or assume a default for testing, OR ask via a dialog?
      // Or just default to "Downloads/ProjectPlus" if no SD?

      // Better: Check active workspace or something.
      // I'll try to get it from `path_provider` downloads directory for safety if no SD logic is readily available in this scope without pulling in HardwareWizard.
      // Actually, let's just dump it to 'C:\TVG_SD_ROOT' or similar as a placeholder if we can't find real SD, or just downloads.
      // Let's use Downloads directory for now to be safe and not mess with drives blindly.

      final downloadsDir = await getDownloadsDirectory();
      final targetDir =
          Directory(path.join(downloadsDir?.path ?? '', 'Wii_SD_Card_Root'));

      if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

      await _projectPlusService.installProjectPlus(
        sdCardRoot: targetDir,
        onProgress: (p) => setState(() => _pplusProgress = p),
        onStatus: (s) => setState(() => _pplusStatus = s),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project+ Installed to ${targetDir.path}'),
            backgroundColor: FusionColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FusionColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPPlus = false;
        });
      }
    }
  }

  Widget _buildWiiUSection(
      String title, List<Map<String, dynamic>> apps, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: apps.map((app) => _buildWiiUAppCard(app, color)).toList(),
        ),
      ],
    );
  }

  Widget _buildWiiUAppCard(Map<String, dynamic> app, Color color) {
    return GestureDetector(
      onTap: () => _showWiiUAppInfo(app),
      child: SizedBox(
        width: 280,
        child: GlassCard(
          glowColor: color,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                ),
                child: Icon(
                  app['icon'] as IconData? ?? Icons.extension,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['name'] as String,
                      style: FusionText.labelMedium
                          .copyWith(color: FusionColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app['description'] as String,
                      style: FusionText.bodySmall
                          .copyWith(color: FusionColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWiiUAppInfo(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => _WiiUAppInfoDialog(app: app),
    );
  }

  List<Map<String, dynamic>> _getEssentialWiiUApps() {
    return [
      {
        'name': 'Aroma',
        'description': 'Custom firmware environment for Wii U',
        'icon': Icons.memory,
        'downloadUrl': 'https://aroma.foryour.cafe/downloads',
        'installPath': 'wiiu/environments/aroma/',
        'fullDescription':
            'Aroma is the recommended custom firmware environment for Wii U. It provides a modular plugin system, allowing you to customize your console experience.',
      },
      {
        'name': 'Homebrew Appstore',
        'description': 'Browse and download Wii U homebrew',
        'icon': Icons.store,
        'downloadUrl': 'https://github.com/fortheusers/hb-appstore/releases',
        'installPath': 'wiiu/apps/',
        'fullDescription':
            'The Homebrew Appstore lets you browse and download homebrew apps directly from your Wii U. Similar to the Wii\'s Homebrew Browser.',
      },
      {
        'name': 'SaveMii Mod WUT Port',
        'description': 'Manage Wii U and vWii save data',
        'icon': Icons.save,
        'downloadUrl': 'https://github.com/Xpl0itU/savemii/releases',
        'installPath': 'wiiu/apps/',
        'fullDescription':
            'SaveMii Mod WUT Port lets you manage, backup, and restore your Wii U and vWii save data. Essential for protecting your game progress.',
      },
      {
        'name': 'WUP Installer GX2',
        'description': 'Install games and DLC to your Wii U',
        'icon': Icons.install_desktop,
        'downloadUrl': 'https://github.com/Yardape8000/wupinstaller/releases',
        'installPath': 'wiiu/apps/',
        'fullDescription':
            'WUP Installer GX2 allows you to install Wii U titles, DLC, and updates from your SD card or USB storage directly to NAND or USB.',
      },
    ];
  }

  List<Map<String, dynamic>> _getWiiUPlugins() {
    return [
      {
        'name': 'FTPiiU Plugin',
        'description': 'FTP server running in background',
        'icon': Icons.folder_shared,
        'downloadUrl': 'https://github.com/wiiu-env/ftpiiu_plugin/releases',
        'installPath': 'wiiu/environments/aroma/plugins/',
        'fullDescription':
            'Runs an FTP server in the background, allowing you to transfer files to/from your Wii U wirelessly. Access your SD card and USB from any FTP client.',
      },
      {
        'name': 'SDCafiine',
        'description': 'Mod games by redirecting to SD Card',
        'icon': Icons.sd_card,
        'downloadUrl': 'https://github.com/wiiu-env/sdcafiine_plugin/releases',
        'installPath': 'wiiu/environments/aroma/plugins/',
        'fullDescription':
            'SDCafiine allows you to mod games by redirecting file access to the SD Card. Perfect for texture packs, translations, and other game mods.',
      },
      {
        'name': 'Bloopair',
        'description': 'Connect Bluetooth controllers',
        'icon': Icons.bluetooth,
        'downloadUrl':
            'https://github.com/GaryOderNichworworworworworwortwor/Bloopair/releases',
        'installPath': 'wiiu/environments/aroma/modules/setup/',
        'fullDescription':
            'Bloopair allows you to wirelessly connect most popular Bluetooth controllers to your Wii U. Supports PS4, PS5, Xbox, Switch Pro controllers and more.',
      },
      {
        'name': 'Screenshot Plugin',
        'description': 'Take screenshots to SD Card',
        'icon': Icons.camera_alt,
        'downloadUrl': 'https://github.com/wiiu-env/ScreenshotWUPS/releases',
        'installPath': 'wiiu/environments/aroma/plugins/',
        'fullDescription':
            'Capture screenshots directly to your SD Card at any time during gameplay. Press a button combo to save what\'s on screen.',
      },
    ];
  }

  List<Map<String, dynamic>> _getWiiUUtilities() {
    return [
      {
        'name': 'Dumpling',
        'description': 'Dump games, updates, DLC, and saves',
        'icon': Icons.content_copy,
        'downloadUrl': 'https://github.com/emiyl/dumpling/releases',
        'installPath': 'wiiu/apps/',
        'fullDescription':
            'Dumpling allows you to dump your Wii U games, updates, DLC, and saves to your SD card or USB. Perfect for creating backups of your physical games.',
      },
      {
        'name': 'WUDD',
        'description': 'Wii U Disc Dumper',
        'icon': Icons.album,
        'downloadUrl': 'https://github.com/wiiu-env/wudd/releases',
        'installPath': 'wiiu/apps/',
        'fullDescription':
            'WUDD (Wii U Disc Dumper) creates 1:1 backups of your Wii U game discs. Supports dumping to SD card or USB storage.',
      },
      {
        'name': 'Pretendo Network',
        'description': 'Nintendo Network replacement service',
        'icon': Icons.cloud,
        'downloadUrl': 'https://pretendo.network/docs/install/wiiu',
        'installPath': 'Requires Inkay plugin',
        'fullDescription':
            'Pretendo is a free, open-source replacement for Nintendo Network. Brings back online services and Miiverse functionality via Juxtaposition.',
      },
      {
        'name': 'Tiramisu (Legacy)',
        'description': 'Previous CFW environment (archived)',
        'icon': Icons.history,
        'downloadUrl': 'https://tiramisu.foryour.cafe/',
        'installPath': 'wiiu/environments/tiramisu/',
        'fullDescription':
            'Tiramisu is the predecessor to Aroma. It\'s now archived but can still be used for legacy homebrew that hasn\'t been updated for Aroma.',
      },
    ];
  }

  Widget _buildCategoryTabs(
      Map<String, String> categories, OSCProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Recommended tab
          _buildCategoryTab('Recommended', 'recommended', provider),
          const SizedBox(width: 12),

          // "All" tab
          _buildCategoryTab('All', '', provider),
          const SizedBox(width: 12),

          // Rom Hacks tab (Custom via GameBrew)
          _buildCategoryTab('Rom Hacks', 'rom_hacks', provider),
          const SizedBox(width: 12),

          // Category tabs
          ...categories.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildCategoryTab(entry.value, entry.key, provider),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(
      String label, String category, OSCProvider provider) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });

        if (category == 'recommended') {
          provider.loadRecommendedHomebrew();
        } else if (category == 'rom_hacks') {
          _loadRomHacks(); // Load from GameBrew
        } else if (category.isEmpty) {
          provider.loadPopularHomebrew();
        } else {
          provider.loadHomebrewByCategory(category);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FusionColors.nebulaCyan.withValues(alpha: 0.2)
              : FusionColors.glassWhite(0.05),
          borderRadius: BorderRadius.circular(999), // Pill shape
          border: Border.all(
            color: isSelected
                ? FusionColors.nebulaCyan.withValues(alpha: 0.6)
                : FusionColors.glassWhite(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FusionColors.nebulaCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: FusionText.labelMedium.copyWith(
            color: isSelected
                ? FusionColors.textPrimary
                : FusionColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(OSCProvider provider) {
    return GlassCard(
      borderRadius: BorderRadius.circular(FusionRadius.xl),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      glowColor: FusionColors.nebulaPurple,
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            provider.searchHomebrew(val);
          } else {
            provider.loadPopularHomebrew();
          }
        },
        style: FusionText.bodyMedium,
        decoration: InputDecoration(
          hintText: 'SEARCH HOMEBREW...',
          hintStyle:
              FusionText.bodyMedium.copyWith(color: FusionColors.textMuted),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.home_repair_service_rounded,
              color: FusionColors.nebulaPurple,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PulsingHomebrewIcon(),
          const SizedBox(height: 40),
          const Text(
            'LOADING HOMEBREW...',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 4,
              color: Color(0xFFB000FF),
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0xFFB000FF),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CONNECTING TO OPEN SHOP CHANNEL...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomebrewGrid(OSCProvider provider, {bool shrinkWrap = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.symmetric(vertical: 20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.homebrewResults.length,
          itemBuilder: (context, index) {
            final homebrew = provider.homebrewResults[index];
            return FusionAppCard(
              game: homebrew,
              onInfo: () => _showHomebrewInfo(homebrew),
              onArchive: () => _archiveHomebrew(homebrew),
              onForge: () => _downloadHomebrew(homebrew),
            );
          },
        );
      },
    );
  }

  void _showHomebrewInfo(GameResult homebrew) {
    AppLogger.instance.info('[Homebrew] Showing info for: ${homebrew.title}');
    showDialog(
      context: context,
      builder: (ctx) => _HomebrewInfoDialog(
        homebrew: homebrew,
        onInstallToSD: () async {
          Navigator.of(ctx).pop();
          final sdCard = await _pickSDCard(context);
          if (sdCard != null && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  _BatchUpdateProgressDialog(games: [homebrew], sdCard: sdCard),
            );
          }
        },
      ),
    );
  }

  void _archiveHomebrew(GameResult homebrew) {
    AppLogger.instance.info('[Homebrew] Archiving: ${homebrew.title}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archive: ${homebrew.title}'),
        backgroundColor: const Color(0xFFB000FF),
      ),
    );
  }

  Future<void> _downloadHomebrew(GameResult homebrew) async {
    AppLogger.instance
        .info('[Homebrew] Requesting download: ${homebrew.title}');

    if (homebrew.downloadUrl == null) {
      _showSnack('Download URL not available', isError: true);
      return;
    }

    // Check if Wii is connected, if not show connection dialog
    final wiiloadProvider =
        Provider.of<WiiloadProvider>(context, listen: false);
    if (!wiiloadProvider.isConnected) {
      _showWiiloadConnectionDialog(context, homebrew: homebrew);
      return;
    }

    await _downloadAndSendToWii(homebrew);
  }

  Future<void> _downloadAndSendToWii(GameResult homebrew) async {
    final wiiloadProvider =
        Provider.of<WiiloadProvider>(context, listen: false);
    final url = homebrew.downloadUrl!;

    // Show progress
    _showSnack('Downloading ${homebrew.title} component...');
    AppLogger.instance.info('[Homebrew] Downloading from $url');

    File? tempFile;
    try {
      // 1. Download to temp
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${homebrew.title.replaceAll(RegExp(r'[^\w\s]+'), '')}.dol'; // sanitizing
      tempFile = File(path.join(tempDir.path, fileName));

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw HttpException('Failed to download file: ${response.statusCode}');
      }

      await tempFile.writeAsBytes(response.bodyBytes);
      AppLogger.instance.info(
          '[Homebrew] Downloaded to ${tempFile.path} (${response.bodyBytes.length} bytes)');

      // 2. Send to Wii
      if (!mounted) return;
      _showSnack('Sending ${homebrew.title} to Wii...');

      final success = await wiiloadProvider.sendDolFile(tempFile.path);

      if (!mounted) return;
      if (success) {
        _showSnack('${homebrew.title} sent to Wii successfully!',
            color: const Color(0xFF00FF88));
        AppLogger.instance.info('[Homebrew] Successfully sent to Wii');
      } else {
        _showSnack('Failed to send to Wii', isError: true);
        AppLogger.instance.error('[Homebrew] Failed to send via Wiiload');
      }
    } catch (e) {
      AppLogger.instance
          .error('[Homebrew] Error during download/send', error: e);
      if (mounted) {
        _showSnack('Error: ${e.toString()}', isError: true);
      }
    } finally {
      // 3. Cleanup
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  void _showSnack(String message, {bool isError = false, Color? color}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            color ?? (isError ? Colors.red : const Color(0xFFB000FF)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showWiiloadConnectionDialog(BuildContext context,
      {GameResult? homebrew}) {
    final wiiloadProvider =
        Provider.of<WiiloadProvider>(context, listen: false);
    final TextEditingController ipController =
        TextEditingController(text: wiiloadProvider.wiiIp);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB000FF).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB000FF).withValues(alpha: 0.3),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WIILOAD CONNECTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  homebrew != null
                      ? 'Connect to Wii to send ${homebrew.title}'
                      : 'Enter your Wii IP address to enable Wiiload',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '192.168.1.100',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    labelText: 'Wii IP Address',
                    labelStyle: const TextStyle(color: Color(0xFFB000FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFB000FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<WiiloadProvider>(
                  builder: (context, wiiloadProvider, child) {
                    if (wiiloadProvider.isLoading) {
                      return const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFB000FF)),
                      );
                    }

                    if (wiiloadProvider.error.isNotEmpty) {
                      return Text(
                        wiiloadProvider.error,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            wiiloadProvider.setWiiIp(ipController.text);
                            final connected =
                                await wiiloadProvider.testConnection();
                            if (!mounted) return;
                            if (connected && homebrew != null) {
                              navigator.pop();
                              _downloadAndSendToWii(homebrew);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB000FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            homebrew != null ? 'CONNECT & SEND' : 'CONNECT',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _PulsingHomebrewDisc extends StatefulWidget {
  const _PulsingHomebrewDisc();

  @override
  State<_PulsingHomebrewDisc> createState() => _PulsingHomebrewDiscState();
}

class _PulsingHomebrewDiscState extends State<_PulsingHomebrewDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.08, end: 0.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB000FF)
                      .withValues(alpha: _opacityAnimation.value),
                  const Color(0xFF00C2FF)
                      .withValues(alpha: _opacityAnimation.value * 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB000FF)
                      .withValues(alpha: _opacityAnimation.value * 2),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PulsingHomebrewIcon extends StatefulWidget {
  const _PulsingHomebrewIcon();

  @override
  State<_PulsingHomebrewIcon> createState() => _PulsingHomebrewIconState();
}

class _PulsingHomebrewIconState extends State<_PulsingHomebrewIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 1, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFB000FF)
                        .withValues(alpha: 0.25 * _controller.value),
                    const Color(0xFF00C2FF)
                        .withValues(alpha: 0.15 * _controller.value),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB000FF)
                        .withValues(alpha: 0.7 * _controller.value),
                    blurRadius: 80 * _controller.value,
                    spreadRadius: 30 * _controller.value,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00C2FF)
                        .withValues(alpha: 0.4 * _controller.value),
                    blurRadius: 100 * _controller.value,
                    spreadRadius: 40 * _controller.value,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.home_repair_service,
                  color: const Color(0xFFB000FF)
                      .withValues(alpha: 0.8 + (0.2 * _controller.value)),
                  size: 80,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFB000FF)
                          .withValues(alpha: _controller.value),
                      blurRadius: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Premium Homebrew Info Dialog
class _HomebrewInfoDialog extends StatelessWidget {
  final GameResult homebrew;
  final VoidCallback? onInstallToSD;

  const _HomebrewInfoDialog({
    required this.homebrew,
    this.onInstallToSD,
  });

  @override
  Widget build(BuildContext context) {
    // Determine category color
    Color categoryColor = const Color(0xFFB000FF); // Default purple
    IconData categoryIcon = Icons.code;

    final category = homebrew.region.toLowerCase();
    if (category.contains('emulator')) {
      categoryColor = const Color(0xFF10B981); // Green
      categoryIcon = Icons.videogame_asset;
    } else if (category.contains('media')) {
      categoryColor = const Color(0xFFEC4899); // Pink
      categoryIcon = Icons.movie;
    } else if (category.contains('game')) {
      categoryColor = const Color(0xFF3B82F6); // Blue
      categoryIcon = Icons.sports_esports;
    } else if (category.contains('utilit')) {
      categoryColor = const Color(0xFFF59E0B); // Amber
      categoryIcon = Icons.build;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.2),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with cover/icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon/Cover
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withValues(alpha: 0.3),
                          categoryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: homebrew.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              homebrew.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                categoryIcon,
                                size: 36,
                                color: categoryColor,
                              ),
                            ),
                          )
                        : Icon(
                            categoryIcon,
                            size: 36,
                            color: categoryColor,
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Title and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homebrew.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon,
                                  size: 14, color: categoryColor),
                              const SizedBox(width: 6),
                              Text(
                                homebrew.region ?? 'Homebrew',
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Info content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildInfoSection(
                      'Description',
                      homebrew.description ??
                          _getDefaultDescription(
                              homebrew.title, homebrew.region),
                      Icons.info_outline,
                      categoryColor,
                    ),

                    const SizedBox(height: 16),

                    // Details grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              'Platform', homebrew.platform, Icons.devices),
                          if (homebrew.size != null)
                            _buildDetailRow(
                                'Size', homebrew.size!, Icons.storage),
                          if (homebrew.provider.isNotEmpty)
                            _buildDetailRow(
                                'Source', homebrew.provider, Icons.cloud),
                          if (homebrew.downloadUrl != null)
                            _buildDetailRow('Status', 'Available for download',
                                Icons.check_circle,
                                valueColor: const Color(0xFF10B981)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Download',
                            Icons.download_rounded,
                            categoryColor,
                            () {
                              Navigator.pop(context);
                              if (homebrew.downloadUrl != null) {
                                Provider.of<ForgeProvider>(context,
                                        listen: false)
                                    .startHomebrewInstall(homebrew);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Downloading ${homebrew.title}...'),
                                    backgroundColor: FusionColors.nebulaCyan,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No download URL available'),
                                    backgroundColor: FusionColors.error,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            'Wiiload',
                            Icons.send_rounded,
                            const Color(0xFF00D4AA),
                            () {
                              Navigator.pop(context);
                              // TODO: Connect Wiiload action here if feasible
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            'SD Install',
                            Icons.sd_storage,
                            const Color(0xFFF59E0B),
                            onInstallToSD ?? () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getDefaultDescription(String title, String? category) {
    final cat = category?.toLowerCase() ?? '';

    // Known homebrew descriptions
    final Map<String, String> knownApps = {
      'homebrew browser':
          'Browse and download homebrew applications directly from your Wii. The original app store for Wii homebrew.',
      'wiimc':
          'A powerful media player for Wii. Plays videos, music, and streams from network sources. Supports many formats.',
      'scummvm':
          'Run classic point-and-click adventure games like Monkey Island, Day of the Tentacle, and more on your Wii.',
      'fce ultra gx':
          'Nintendo Entertainment System (NES) emulator for Wii. Play classic NES games with save states and customization.',
      'snes9x gx':
          'Super Nintendo emulator for Wii. High compatibility with SNES games, supports save states.',
      'vba gx':
          'Game Boy Advance emulator for Wii. Also plays GB and GBC games. Great compatibility.',
      'genesis plus gx':
          'Sega Genesis/Mega Drive emulator. Also supports Master System, Game Gear, and Sega CD.',
      'usb loader gx':
          'Load Wii and GameCube games from USB storage. Feature-rich with cover art support.',
      'wiiflow':
          'Elegant USB loader with a unique coverflow interface. Supports Wii, GameCube, and emulators.',
      'cleanrip':
          'Create perfect 1:1 backups of your Wii and GameCube game discs to SD or USB.',
      'priiloader':
          'System menu hacks and brick protection. Essential for any modded Wii.',
      'bootmii':
          'Low-level backup and recovery tool. Create and restore NAND backups.',
    };

    final titleLower = title.toLowerCase();
    for (final entry in knownApps.entries) {
      if (titleLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Generate based on category
    if (cat.contains('emulator')) {
      return 'Emulator application for Wii. Run games from other platforms on your Wii console.';
    } else if (cat.contains('media')) {
      return 'Media application for Wii. Play videos, music, or view images on your console.';
    } else if (cat.contains('game')) {
      return 'Homebrew game for Wii. An original game created by the homebrew community.';
    } else if (cat.contains('utilit')) {
      return 'Utility application for Wii. Helps manage, backup, or enhance your Wii system.';
    }

    return 'Homebrew application for Nintendo Wii. Part of the vibrant Wii homebrew community.';
  }
}

/// Wii U App Info Dialog
class _WiiUAppInfoDialog extends StatelessWidget {
  final Map<String, dynamic> app;

  const _WiiUAppInfoDialog({required this.app});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF3B82F6);
    final icon = app['icon'] as IconData? ?? Icons.extension;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Wii U / Aroma',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app['fullDescription'] as String? ??
                          app['description'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Install path
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.folder, size: 16, color: color),
                              SizedBox(width: 8),
                              Text(
                                'Install Location',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              app['installPath'] as String? ?? 'wiiu/apps/',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Download button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = app['downloadUrl'] as String?;
                          if (url != null) {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                              if (context.mounted) Navigator.pop(context);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not launch $url')),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text('Download from GitHub'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiivolutionManagerDialog extends StatefulWidget {
  const _RiivolutionManagerDialog();

  @override
  State<_RiivolutionManagerDialog> createState() =>
      _RiivolutionManagerDialogState();
}

class _RiivolutionManagerDialogState extends State<_RiivolutionManagerDialog> {
  final RiivolutionService _service = RiivolutionService();
  bool _isBusy = false;
  double _progress = 0;
  String _status = '';

  Future<void> _installApp() async {
    setState(() {
      _isBusy = true;
      _progress = 0.0;
      _status = 'Initializing...';
    });

    try {
      // Use Downloads/Wii_SD_Card_Root for logic consistency with P+ installer for now
      // ideally verify with provider or setting
      final downloadsDir = await getDownloadsDirectory();
      final sdRoot =
          Directory(path.join(downloadsDir?.path ?? '', 'Wii_SD_Card_Root'));

      await _service.installRiivolutionApp(
        sdCardRoot: sdRoot,
        onProgress: (p) => setState(() => _progress = p),
        onStatus: (s) => setState(() => _status = s),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Riivolution Installed!'),
              backgroundColor: FusionColors.success),
        );
        Navigator.pop(context); // Close on success? Or stay open.
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _installMod() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Riivolution Mod Zip',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isBusy = true;
          _progress = 0.0;
          _status = 'Preparing mod...';
        });

        final zipFile = File(result.files.single.path!);

        // Same root logic
        final downloadsDir = await getDownloadsDirectory();
        final sdRoot =
            Directory(path.join(downloadsDir?.path ?? '', 'Wii_SD_Card_Root'));

        await _service.installMod(
          modZip: zipFile,
          sdCardRoot: sdRoot,
          onProgress: (p) => setState(() => _progress = p),
          onStatus: (s) => setState(() => _status = s),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Mod "${result.files.single.name}" Installed!'),
                backgroundColor: FusionColors.success),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        color: FusionColors.bgSurface, // Opaque for readability
        width: 500,
        height: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riivolution Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Install the Riivolution app or add custom mods.',
              style: TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            if (_isBusy) ...[
              Text(
                _status,
                style: const TextStyle(
                    color: FusionColors.nebulaCyan,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      FusionColors.nebulaCyan),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text('${(_progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white54))),
            ] else ...[
              // Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.system_update_alt,
                      label: 'Install Riivolution App',
                      color: FusionColors.nebulaCyan,
                      onTap: _installApp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.folder_zip,
                      label: 'Install Mod (.zip)',
                      color: FusionColors.nebulaPurple,
                      onTap: _installMod,
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DLCManagerDialog extends StatefulWidget {
  const _DLCManagerDialog();

  @override
  State<_DLCManagerDialog> createState() => _DLCManagerDialogState();
}

class _DLCManagerDialogState extends State<_DLCManagerDialog> {
  final DLCManagerService _service = DLCManagerService();
  bool _isBusy = false;
  bool _hasKeys = false;
  String _status = '';
  double _progress = 0;

  // Game Selection
  String _selectedGame = 'Rock Band 3';
  String _selectedRegion = 'US';

  String get _calculatedId =>
      _service.calculateTitleId(_selectedGame, _selectedRegion);

  @override
  void initState() {
    super.initState();
    _checkKeys();
  }

  Future<void> _checkKeys() async {
    final downloadsDir = await getDownloadsDirectory();
    final sdRoot =
        Directory(path.join(downloadsDir?.path ?? '', 'Wii_SD_Card_Root'));
    final has = await _service.hasKeys(sdRoot);
    if (mounted) setState(() => _hasKeys = has);
  }

  Future<void> _installXyzzy() async {
    setState(() {
      _isBusy = true;
      _status = 'Installing xyzzy-mod...';
      _progress = 0.0;
    });

    try {
      final downloadsDir = await getDownloadsDirectory();
      final sdRoot =
          Directory(path.join(downloadsDir?.path ?? '', 'Wii_SD_Card_Root'));

      await _service.installXyzzyMod(
        sdCardRoot: sdRoot,
        onProgress: (p) => setState(() => _progress = p),
        onStatus: (s) => setState(() => _status = s),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('xyzzy-mod Installed!'),
              backgroundColor: FusionColors.success),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        color: FusionColors.bgSurface, // Opaque background for readability
        width: 600,
        height: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Legacy DLC Assistant',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasKeys
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _hasKeys
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(_hasKeys ? Icons.key : Icons.key_off,
                      color: _hasKeys ? Colors.green : Colors.orange),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasKeys
                            ? 'Keys Found (Ready for wad2bin)'
                            : 'Keys Missing (Required)',
                        style: TextStyle(
                            color: _hasKeys ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _hasKeys
                            ? 'keys.txt & device.cert present in root.'
                            : 'Install xyzzy, run on Wii to dump keys.',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_isBusy) ...[
              Text(_status,
                  style: const TextStyle(color: FusionColors.nebulaCyan)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepRow(
                          '1. Install Key Dumper',
                          'Installs xyzzy-mod to apps/. Run on Wii first.',
                          _hasKeys ? Icons.check_circle : Icons.download,
                          _hasKeys ? () {} : _installXyzzy,
                          color: _hasKeys ? Colors.green : null),
                      const SizedBox(height: 16),
                      const Text('2. Generate Title ID (for wad2bin)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedGame,
                                    dropdownColor: const Color(0xFF1E293B),
                                    isExpanded: true,
                                    items: DLCManagerService.supportedGames.keys
                                        .map((g) {
                                      return DropdownMenuItem(
                                          value: g,
                                          child: Text(g,
                                              style: const TextStyle(
                                                  color: Colors.white)));
                                    }).toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedGame = v!),
                                    underline: Container(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                DropdownButton<String>(
                                  value: _selectedRegion,
                                  dropdownColor: const Color(0xFF1E293B),
                                  items: ['US', 'EU'].map((r) {
                                    return DropdownMenuItem(
                                        value: r,
                                        child: Text(r,
                                            style: const TextStyle(
                                                color: Colors.white)));
                                  }).toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedRegion = v!),
                                  underline: Container(),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Title ID to copy:',
                                    style: TextStyle(color: Colors.white70)),
                                SelectableText(
                                  _calculatedId,
                                  style: const TextStyle(
                                      color: FusionColors.nebulaCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      size: 20, color: Colors.white54),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _calculatedId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('ID Copied!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStepRow(
                        '3. Get wad2bin Tool',
                        'Download the tool to convert WADs.',
                        Icons.open_in_new,
                        () => launchUrl(
                            Uri.parse(
                                'https://github.com/DarkMatterCore/wad2bin/releases'),
                            mode: LaunchMode.externalApplication),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Automation Tip: Copy the Title ID above, open wad2bin, paste it, select your WAD, and run. Move the output "private" folder to your SD root.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(
      String title, String desc, IconData icon, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(desc,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}

class _BatchUpdateProgressDialog extends StatefulWidget {
  final List<GameResult> games;
  final Directory sdCard;

  const _BatchUpdateProgressDialog({
    required this.games,
    required this.sdCard,
  });

  @override
  State<_BatchUpdateProgressDialog> createState() =>
      _BatchUpdateProgressDialogState();
}

class _BatchUpdateProgressDialogState
    extends State<_BatchUpdateProgressDialog> {
  String _status = 'Initializing...';
  double _progress = 0;
  final HomebrewAutomationService _service = HomebrewAutomationService();

  @override
  void initState() {
    super.initState();
    _startBatch();
  }

  Future<void> _startBatch() async {
    try {
      await _service.installBatch(
        games: widget.games,
        sdCardRoot: widget.sdCard,
        onStatus: (msg, p) {
          if (mounted) {
            setState(() {
              _status = msg;
              _progress = p;
            });
          }
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All essential apps updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        color: FusionColors.bgSurface, // Opaque for readability
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Updating Essentials',
              style: FusionText.headlineLarge
                  .copyWith(color: FusionColors.nebulaCyan),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: FusionText.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(FusionColors.nebulaCyan),
            ),
            const SizedBox(height: 20),
            if (_status.startsWith('Error'))
              GlowButton(
                label: 'CLOSE',
                color: Colors.redAccent,
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
              )
          ],
        ),
      ),
    );
  }
}
