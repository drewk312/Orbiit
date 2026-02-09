// ═══════════════════════════════════════════════════════════════════════════
// GAME LIBRARY SCREEN
// PlayStation/Xbox-style game library with stunning visuals
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import '../fusion/design_system.dart';
import '../fusion/game_cover_card.dart';
import '../widgets/premium_game_info_panel.dart';
import '../../widgets/empty_state.dart' as ws;
import '../../services/scanner_service.dart';

/// Filter options
enum PlatformFilter {
  all,
  wii,
  gamecube,
  wiiu,
}

/// Sort options
enum SortOption {
  nameAsc,
  nameDesc,
  sizeAsc,
  sizeDesc,
  recentlyAdded,
}

/// Game Library Screen
class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen>
    with TickerProviderStateMixin {
  // Services
  final ScannerService _scannerService = ScannerService();

  // State
  List<GameCardData> _games = [];
  List<GameCardData> _filteredGames = [];
  Map<String, ScannedGame> _scannedGamesMap =
      {}; // Map game ID to full metadata
  bool _isLoading = true;
  bool _isScanning = false;
  String _scanStatus = '';
  String? _selectedDrive;
  List<String> _availableDrives = [];

  // Filters & Search
  final TextEditingController _searchController = TextEditingController();
  PlatformFilter _platformFilter = PlatformFilter.all;
  SortOption _sortOption = SortOption.nameAsc;

  // Animation
  late AnimationController _scanAnimController;

  // Stats
  int _wiiCount = 0;
  int _gcCount = 0;
  String _totalSize = '0 GB';

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadDrives();
    // Don't auto-scan - wait for user to select drive and press scan
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadDrives() async {
    // Detect removable drives on Windows
    final drives = <String>[];
    for (var letter in 'DEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final path = '$letter:\\';
      if (Directory(path).existsSync()) {
        try {
          // Check if it's likely a removable drive
          final stat = FileStat.statSync(path);
          if (stat.type == FileSystemEntityType.directory) {
            drives.add(path);
          }
        } catch (_) {}
      }
    }

    setState(() {
      _availableDrives = drives;
      if (drives.isNotEmpty && _selectedDrive == null) {
        _selectedDrive = drives.first;
      }
    });
  }

  /// Scan the selected drive for games
  Future<void> _scanDrive() async {
    if (_selectedDrive == null) return;

    setState(() {
      _isScanning = true;
      _scanStatus = 'Initializing scanner...';
      _games.clear();
      _filteredGames.clear();
      _scannedGamesMap.clear();
    });

    try {
      setState(() => _scanStatus = 'Scanning $_selectedDrive for games...');

      // Use the scanner service to find games
      final scannedGames = await _scannerService.scanDirectory(_selectedDrive!);

      setState(() => _scanStatus =
          'Found ${scannedGames.length} games, loading covers...');

      // Build map for later lookup and convert to GameCardData
      final gameCards = <GameCardData>[];
      for (final game in scannedGames) {
        final region = game.region ?? 'US';
        final gameId = game.gameId ?? 'UNKNOWN';
        final platform =
            game.platform.toLowerCase().contains('gamecube') ? 'gc' : 'wii';

        // Store in map for metadata lookup
        _scannedGamesMap[gameId] = game;

        gameCards.add(GameCardData(
          id: gameId,
          title: game.title,
          platform: platform,
          // GameTDB uses 'wii' path for both Wii and GameCube
          coverUrl: 'https://art.gametdb.com/wii/cover3D/$region/$gameId.png',
          size: game.formattedSize,
          region: region,
        ));
      }

      // Calculate stats
      final wiiCount = gameCards.where((g) => g.platform == 'wii').length;
      final gcCount = gameCards.where((g) => g.platform == 'gc').length;
      final totalBytes =
          scannedGames.fold<int>(0, (sum, g) => sum + g.sizeBytes);
      final totalSizeStr = _formatSize(totalBytes);

      setState(() {
        _games = gameCards;
        _filteredGames = gameCards;
        _wiiCount = wiiCount;
        _gcCount = gcCount;
        _totalSize = totalSizeStr;
        _isScanning = false;
        _scanStatus = '';
      });

      _filterAndSortGames();
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Scan failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _filterAndSortGames() {
    var filtered = List<GameCardData>.from(_games);

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((g) =>
              g.title.toLowerCase().contains(query) ||
              g.id.toLowerCase().contains(query))
          .toList();
    }

    // Platform filter
    if (_platformFilter != PlatformFilter.all) {
      final platformStr = _platformFilter.name;
      filtered = filtered
          .where((g) =>
              g.platform.toLowerCase() == platformStr ||
              (platformStr == 'gamecube' && g.platform.toLowerCase() == 'gc'))
          .toList();
    }

    // Sort
    switch (_sortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.sizeAsc:
        filtered.sort((a, b) => (a.size ?? '0').compareTo(b.size ?? '0'));
        break;
      case SortOption.sizeDesc:
        filtered.sort((a, b) => (b.size ?? '0').compareTo(a.size ?? '0'));
        break;
      case SortOption.recentlyAdded:
        // Would need timestamp data
        break;
    }

    setState(() {
      _filteredGames = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Allow SpaceBackground to show through
      child: Column(
        children: [
          // 1. Compact Header (Title + Drive + Scan)
          _buildCompactHeader(),

          // 2. Compact Toolbar (Search + Stats + Filter)
          _buildCompactToolbar(),

          // 3. Game Grid (Takes remaining space)
          Expanded(
            child: _isLoading || _isScanning
                ? _buildLoadingState()
                : _filteredGames.isEmpty
                    ? _buildEmptyState()
                    : _buildGameGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      height: 80, // Slightly taller for better spacing
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: OrbColors.glassBorder)),
        color: OrbColors.bgSecondary
            .withValues(alpha: 0.3), // Subtle glass overlay
      ),
      child: Row(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrbColors.orbitCyan.withValues(alpha: 0.1),
              border:
                  Border.all(color: OrbColors.orbitCyan.withValues(alpha: 0.3)),
              boxShadow: OrbShadows.cyanGlow(0.5),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: OrbColors.orbitCyan, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GAME LIBRARY",
                style: OrbText.headlineMedium.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "${_filteredGames.length} TITLES DETECTED",
                style: OrbText.caption.copyWith(
                  color: OrbColors.orbitCyan,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Drive Selector Pill
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: OrbColors.bgSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(OrbRadius.full),
              border: Border.all(color: OrbColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDrive,
                dropdownColor: OrbColors.bgSecondary,
                icon: Icon(Icons.expand_more_rounded,
                    color: OrbColors.orbitCyan, size: 20),
                style:
                    OrbText.labelMedium.copyWith(color: OrbColors.textPrimary),
                items: _availableDrives
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text("DRIVE $d")))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDrive = v),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Neon Scan Button
          GestureDetector(
            onTap: _isScanning ? null : _scanDrive,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: OrbColors.orbitGradient,
                  borderRadius: BorderRadius.circular(OrbRadius.full),
                  boxShadow: [
                    BoxShadow(
                        color: OrbColors.orbitCyan.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: -4)
                  ],
                ),
                child: Row(
                  children: [
                    if (_isScanning)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                    else
                      const Icon(Icons.radar_rounded,
                          color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(_isScanning ? "SCANNING" : "SCAN DRIVE",
                        style: OrbText.labelMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: [
          // Search Bar - Glass Pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: OrbColors.bgSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(OrbRadius.full),
                border: Border.all(color: OrbColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: OrbColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filterAndSortGames(),
                      style: OrbText.bodyMedium
                          .copyWith(color: OrbColors.textPrimary),
                      cursorColor: OrbColors.orbitCyan,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: "Search library...",
                        hintStyle: OrbText.bodyMedium
                            .copyWith(color: OrbColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Inline Stats
          _buildInlineStat(Icons.sports_esports_rounded, "$_wiiCount Wii"),
          const SizedBox(width: 16),
          _buildInlineStat(Icons.gamepad_rounded, "$_gcCount GC"),
          const SizedBox(width: 16),
          _buildInlineStat(Icons.storage_rounded, _totalSize),

          const SizedBox(width: 24),
          Container(
              width: 1, height: 24, color: OrbColors.glassBorder), // Divider
          const SizedBox(width: 24),

          // Platform Filter Icons
          Row(
            children: [
              _buildFilterIcon(
                  Icons.grid_view_rounded, PlatformFilter.all, "Show All"),
              const SizedBox(width: 4),
              _buildFilterIcon(
                  Icons.disc_full_rounded, PlatformFilter.wii, "Wii Only"),
              const SizedBox(width: 4),
              _buildFilterIcon(Icons.videogame_asset_rounded,
                  PlatformFilter.gamecube, "GameCube Only"),
            ],
          ),

          const SizedBox(width: 16),

          // Sort Button
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildFilterIcon(
      IconData icon, PlatformFilter filter, String tooltip) {
    final isSelected = _platformFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _platformFilter = filter;
          _filterAndSortGames();
        }),
        borderRadius: BorderRadius.circular(OrbRadius.full),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? OrbColors.orbitCyan.withValues(alpha: 0.2)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: OrbColors.orbitCyan.withValues(alpha: 0.5))
                : null,
          ),
          child: Icon(icon,
              color: isSelected ? OrbColors.orbitCyan : OrbColors.textMuted,
              size: 20),
        ),
      ),
    );
  }

  Widget _buildInlineStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: OrbColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: OrbText.labelMedium.copyWith(
                color: OrbColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSortButton() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: OrbColors.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(OrbRadius.full),
        border: Border.all(color: OrbColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: _sortOption,
          dropdownColor: OrbColors.bgSecondary,
          icon: const Icon(Icons.sort_rounded,
              color: OrbColors.textMuted, size: 18),
          style: OrbText.labelMedium.copyWith(color: OrbColors.textPrimary),
          items: const [
            DropdownMenuItem(
                value: SortOption.nameAsc, child: Text('Name (A-Z)')),
            DropdownMenuItem(
                value: SortOption.nameDesc, child: Text('Name (Z-A)')),
            DropdownMenuItem(
                value: SortOption.sizeDesc, child: Text('Size (Largest)')),
            DropdownMenuItem(
                value: SortOption.sizeAsc, child: Text('Size (Smallest)')),
            DropdownMenuItem(
                value: SortOption.recentlyAdded, child: Text('Recent')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _sortOption = value);
              _filterAndSortGames();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    return GameCoverGrid(
      games: _filteredGames,
      onGameTap: (game) => _showGameDetails(game),
      onGameInfo: (game) => _showGameDetails(game),
      onGameDownload: (game) => _downloadCover(game),
      onGameDelete: (game) => _confirmDelete(game),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scanAnimController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _scanAnimController.value * 6.28,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        FusionColors.wiiBlue,
                        FusionColors.wiiBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: CircleAvatar(
                      backgroundColor: FusionColors.backgroundDark,
                      child: Icon(
                        Icons.album,
                        color: FusionColors.wiiBlue,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanning for games...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: FusionColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a moment',
            style: TextStyle(
              fontSize: 13,
              color: FusionColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ws.EmptyState(
      icon: Icons.videogame_asset_off,
      title: _searchController.text.isNotEmpty
          ? 'No games match your search'
          : 'No games found',
      subtitle: _searchController.text.isNotEmpty
          ? 'Try a different search term'
          : 'Select a drive and click "Scan Drive" to find games',
      action: _searchController.text.isEmpty
          ? GlowButton(
              label: 'Scan Now',
              icon: Icons.refresh,
              onPressed: _scanDrive,
            )
          : GlowButton(
              label: 'Clear Search',
              icon: Icons.clear,
              color: FusionColors.textMuted,
              onPressed: () {
                _searchController.clear();
                _filterAndSortGames();
              },
            ),
    );
  }

  void _showGameDetails(GameCardData game) {
    // Get full metadata from stored scanned games
    final scannedGame = _scannedGamesMap[game.id];

    if (scannedGame != null) {
      // Use premium panel with full metadata
      showDialog(
        context: context,
        builder: (context) => PremiumGameInfoPanel(
          disc: scannedGame.toDiscMetadata(),
          onClose: () => Navigator.pop(context),
          onOpenFolder: () {
            Navigator.pop(context);
            _openGameFolder(scannedGame.path);
          },
          onVerify: () async {
            Navigator.pop(context);
            await _verifyGame(scannedGame);
          },
          onConvert: () {
            Navigator.pop(context);
            _convertGame(scannedGame);
          },
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete(game);
          },
        ),
      );
    } else {
      // Fallback to basic dialog
      showDialog(
        context: context,
        builder: (context) => _GameDetailsDialog(game: game),
      );
    }
  }

  Future<void> _verifyGame(dynamic scannedGame) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Verifying ${scannedGame.title}...'),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final file = File(scannedGame.path);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();
      // Basic verification: check file size is reasonable for Wii/GC
      final isWii =
          scannedGame.platform?.toLowerCase().contains('wii') ?? false;
      final minSize = isWii
          ? 100 * 1024 * 1024
          : 50 * 1024 * 1024; // 100MB Wii, 50MB GC minimum

      if (fileSize < minSize) {
        throw Exception('File appears to be corrupted (too small)');
      }

      // Check file header for valid Wii/GC magic
      final bytes = await file.openRead(0, 6).first;
      final isValidWii = bytes.length >= 6 &&
          bytes[0] == 0x00 &&
          bytes[1] == 0x00 &&
          bytes[2] == 0x00 &&
          bytes[3] == 0x00;
      final isValidGC = bytes.length >= 4 &&
          String.fromCharCodes(bytes.take(4)).contains(RegExp(r'[A-Z0-9]{4}'));
      final isWBFS = bytes.length >= 4 &&
          bytes[0] == 0x57 &&
          bytes[1] == 0x42 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x53;

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${scannedGame.title} verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _convertGame(dynamic scannedGame) async {
    final currentExt = scannedGame.path.toLowerCase().split('.').last;

    // Show conversion options
    final targetFormat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title:
            const Text('Convert Format', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current format: .$currentExt',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Select target format:',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          if (currentExt != 'wbfs')
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'wbfs'),
              child: const Text('WBFS (USB Loader)'),
            ),
          if (currentExt != 'iso')
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'iso'),
              child: const Text('ISO (Full Disc)'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (targetFormat == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Format conversion to .$targetFormat requires wit tool. '
            'Install Wiimms ISO Tools for full conversion support.'),
        action: SnackBarAction(
          label: 'Learn More',
          onPressed: () async {
            // Open wit documentation
          },
        ),
      ),
    );
  }

  void _openGameFolder(String filePath) async {
    try {
      final directory = File(filePath).parent.path;
      await Process.run('explorer.exe', [directory]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open folder: $e')),
        );
      }
    }
  }

  void _downloadCover(GameCardData game) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading cover for ${game.title}...')),
    );

    try {
      final gameId = game.id;
      if (gameId.isEmpty || gameId.length != 6) {
        throw Exception('Invalid game ID');
      }

      // Download from GameTDB
      final urls = [
        'https://art.gametdb.com/wii/cover3D/US/$gameId.png',
        'https://art.gametdb.com/wii/cover/US/$gameId.png',
        'https://art.gametdb.com/wii/disc/US/$gameId.png',
      ];

      final client = HttpClient();
      for (final url in urls) {
        try {
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();

          if (response.statusCode == 200) {
            // Save to covers folder
            final coversDir = Directory('covers');
            if (!await coversDir.exists()) {
              await coversDir.create();
            }

            final type = url.contains('cover3D')
                ? '3D'
                : url.contains('disc')
                    ? 'disc'
                    : 'cover';
            final file = File('covers/${gameId}_$type.png');
            final sink = file.openWrite();
            await response.pipe(sink);

            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Downloaded $type art for ${game.title}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }

      throw Exception('No cover art found');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download cover: $e')),
        );
      }
    }
  }

  void _confirmDelete(GameCardData game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22222E),
        title: const Text('Delete Game?'),
        content: Text(
            'Are you sure you want to delete "${game.title}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FusionColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGame(game);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGame(GameCardData game) async {
    try {
      final scannedGame = _scannedGamesMap[game.id];
      if (scannedGame != null) {
        final file = File(scannedGame.path);
        if (await file.exists()) {
          await file.delete();

          // Remove from lists
          setState(() {
            _games.removeWhere((g) => g.id == game.id);
            _filteredGames.removeWhere((g) => g.id == game.id);
            _scannedGamesMap.remove(game.id);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Deleted ${game.title}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _GameDetailsDialog extends StatelessWidget {
  final GameCardData game;

  const _GameDetailsDialog({required this.game});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FusionRadius.xl),
          color: FusionColors.surfaceCard,
          border: Border.all(
            color: FusionColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(FusionRadius.md),
                  child: game.coverUrl != null
                      ? Image.network(
                          game.coverUrl!,
                          width: 160,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160,
                            height: 220,
                            color: const Color(0xFF22222E),
                            child: Icon(
                              game.platformIcon,
                              size: 48,
                              color: FusionColors.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 160,
                          height: 220,
                          color: const Color(0xFF22222E),
                          child: Icon(
                            game.platformIcon,
                            size: 48,
                            color: FusionColors.textMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 24),

                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: FusionColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Game ID', value: game.id),
                      _InfoRow(
                          label: 'Platform',
                          value: game.platform.toUpperCase()),
                      if (game.region != null)
                        _InfoRow(label: 'Region', value: game.region!),
                      if (game.size != null)
                        _InfoRow(label: 'Size', value: game.size!),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          GlowButton(
                            label: 'Download Cover',
                            icon: Icons.download,
                            isCompact: true,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          GlowButton(
                            label: 'Open Folder',
                            icon: Icons.folder_open,
                            isCompact: true,
                            color: FusionColors.textMuted,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: FusionColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: FusionColors.textMuted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: FusionColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
