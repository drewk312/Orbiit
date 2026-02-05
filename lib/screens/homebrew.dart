import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/osc_provider.dart';
import '../providers/wiiload_provider.dart';
import '../widgets/fusion_app_card.dart';
import '../widgets/immersive_glass_header.dart';
import '../models/game_result.dart';

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
              'Enter your Wii IP address to enable Wiiload',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                labelText: 'Wii IP Address',
                labelStyle: const TextStyle(color: Color(0xFFB000FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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
                        wiiloadProvider.setWiiIp(_ipController.text);
                        final connected =
                            await wiiloadProvider.testConnection();
                        if (connected && mounted) Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB000FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('CONNECT',
                          style: TextStyle(color: Colors.white)),
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
  String _selectedCategory = '';
  String _selectedConsole = 'wii'; // 'wii' or 'wiiu'

  @override
  void initState() {
    super.initState();
    // Load popular homebrew on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OSCProvider>(context, listen: false);
      provider.loadPopularHomebrew();
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
            "CONNECTION ERROR",
            style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
            "No homebrew apps found",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConsoleTab('Wii', 'wii', const Color(0xFF00D4AA)),
          const SizedBox(width: 4),
          _buildConsoleTab('Wii U', 'wiiu', const Color(0xFF3B82F6)),
        ],
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
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
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
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wii U Homebrew Section with Aroma ecosystem apps
  Widget _buildWiiUHomebrewSection() {
    final wiiUApps = _getWiiUHomebrewApps();

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
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app['description'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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

  List<Map<String, dynamic>> _getWiiUHomebrewApps() {
    return [
      ..._getEssentialWiiUApps(),
      ..._getWiiUPlugins(),
      ..._getWiiUUtilities(),
    ];
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
          // "All" tab
          _buildCategoryTab('All', '', provider),
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

        if (category.isEmpty) {
          provider.loadPopularHomebrew();
        } else {
          provider.loadHomebrewByCategory(category);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB000FF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB000FF).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB000FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(OSCProvider provider) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFB000FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB000FF).withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            provider.searchHomebrew(val);
          } else {
            provider.loadPopularHomebrew();
          }
        },
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        decoration: InputDecoration(
          hintText: "SEARCH HOMEBREW...",
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 2,
            fontWeight: FontWeight.w300,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.home_repair_service_rounded,
              color: Color(0xFFB000FF),
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            "LOADING HOMEBREW...",
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 4,
              color: Color(0xFFB000FF),
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0xFFB000FF),
                  blurRadius: 15,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "CONNECTING TO OPEN SHOP CHANNEL...",
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

  Widget _buildHomebrewGrid(OSCProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cross axis count based on width for responsive bento feel
        int crossAxisCount = (constraints.maxWidth / 240).floor().clamp(3, 8);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
    debugPrint("[Homebrew] Showing info for: ${homebrew.title}");
    showDialog(
      context: context,
      builder: (context) => _HomebrewInfoDialog(homebrew: homebrew),
    );
  }

  void _archiveHomebrew(GameResult homebrew) {
    debugPrint("[Homebrew] Archiving: ${homebrew.title}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archive: ${homebrew.title}'),
        backgroundColor: const Color(0xFFB000FF),
      ),
    );
  }

  void _downloadHomebrew(GameResult homebrew) {
    debugPrint("[Homebrew] Downloading: ${homebrew.title}");

    if (homebrew.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if Wii is connected, if not show connection dialog
    final wiiloadProvider =
        Provider.of<WiiloadProvider>(context, listen: false);
    if (!wiiloadProvider.isConnected) {
      _showWiiloadConnectionDialog(context, homebrew: homebrew);
      return;
    }

    // Simulate download and send to Wii
    _sendHomebrewToWii(homebrew);
  }

  void _sendHomebrewToWii(GameResult homebrew) {
    final wiiloadProvider =
        Provider.of<WiiloadProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Sending ${homebrew.title} to Wii...'),
        backgroundColor: const Color(0xFFB000FF),
        duration: const Duration(seconds: 3),
      ),
    );

    wiiloadProvider.sendDolFile('/tmp/${homebrew.title}.dol').then((success) {
      if (!mounted) return;
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${homebrew.title} sent to Wii successfully!'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to send to Wii'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
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
                              _sendHomebrewToWii(homebrew);
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
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
                      offset: const Offset(0, 0),
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

  const _HomebrewInfoDialog({required this.homebrew});

  @override
  Widget build(BuildContext context) {
    // Determine category color
    Color categoryColor = const Color(0xFFB000FF); // Default purple
    IconData categoryIcon = Icons.code;

    final category = homebrew.region?.toLowerCase() ?? '';
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
              spreadRadius: 0,
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
                        width: 1,
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
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Send to Wii',
                            Icons.send_rounded,
                            const Color(0xFF00D4AA),
                            () {
                              Navigator.pop(context);
                            },
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    final color = const Color(0xFF3B82F6);
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
                    Text(
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
                          Row(
                            children: [
                              Icon(Icons.folder, size: 16, color: color),
                              const SizedBox(width: 8),
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
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Open download URL in browser
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
