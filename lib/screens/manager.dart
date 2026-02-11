import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_logger.dart';
import '../core/error_handler.dart';
import '../core/native_library_loader.dart';
import '../services/library_state_service.dart';
import '../services/scanner_service.dart';
import '../ui/widgets/cover_download_indicator.dart';
import '../widgets/game_cover.dart';
import '../widgets/immersive_glass_header.dart';
import '../widgets/spinning_disc.dart';

/// Manager Screen - Library view with animations and scale support
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen>
    with TickerProviderStateMixin {
  final ScannerService _scanner = ScannerService();
  final LibraryStateService _libraryState = LibraryStateService();
  bool _isScanning = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  String _filterPlatform = 'All';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    await _libraryState.loadFromCache();
    if (mounted) {
      setState(() {});
      _fadeController.forward();

      // Background cover downloads disabled - using on-demand downloads instead
      // Covers download automatically when CoverArtWidget displays each game
    }
  }

  /// Automatically download missing covers in background (TinyWii style)
  Future<void> _startBackgroundCoverDownloads() async {
    // DISABLED - We now use on-demand downloads in CoverArtWidget
    // This is much faster than downloading all covers at once
    // Covers are downloaded as you scroll through the library
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<ScannedGame> get _filteredGames {
    if (_filterPlatform == 'All') return _libraryState.games;
    return _libraryState.games
        .where((g) => g.platform == _filterPlatform)
        .toList();
  }

  Future<void> _scanFolder() async {
    final logger = AppLogger.instance;

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select your game library folder',
    );

    if (result == null) return;

    // Ensure widget is still mounted before proceeding
    if (!mounted) return;

    // Use ErrorHandler.handleAsync for standardized loading and error handling
    await ErrorHandler.handleAsync<List<ScannedGame>>(
      context,
      () async {
        logger.info('Starting folder scan: $result');

        List<ScannedGame> games = await _scanner.scanDirectory(result);

        if (games.isEmpty) {
          final candidates = [
            '$result/wbfs',
            '$result/WBFS',
            '$result/games',
            '$result/Games',
          ];
          for (final p in candidates) {
            try {
              final dir = Directory(p);
              if (await dir.exists()) {
                final sub = await _scanner.scanDirectory(p);
                if (sub.isNotEmpty) {
                  games = sub;
                  break;
                }
              }
            } catch (_) {}
          }
        }

        // Calculate health for each game
        for (final game in games) {
          game.health = await _scanner.calculateHealth(game);
          game.verified = game.health >= 70;
        }

        _libraryState.updateLibrary(games, result);

        if (!mounted) return games;
        setState(() {}); // Trigger UI rebuild
        _fadeController.forward(from: 0);
        final count = games.length;

        // Show success message (guarded immediately before using context)
        if (count > 0) {
          if (!mounted) return games;
          await ErrorHandler.showSuccessDialog(
            context,
            'Scan Complete',
            'Found $count games',
          );

          // If we had to fall back to the Dart scanner, notify the user so they
          // know native scanning is not available and covers or metadata may be
          // less reliable. This also points them at installation instructions.
          if (_scanner.lastScanUsedFallback) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'No native scanner detected — using fallback scanner. Install the native Forge library for better detection.',
                  ),
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: 'Instructions',
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Native Scanner'),
                          content: Text(NativeLibraryLoader
                              .getInstallationInstructions()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }
        } else {
          if (!mounted) return games;

          // Run a diagnostic scan to explain why nothing was detected and present it to the user
          final diagnostics = await _scanner.scanDirectoryDiagnostic(result);
          final details = diagnostics.join('\n');

          if (!mounted) {
            return games; // Guard against using context after async gap
          }

          await ErrorHandler.showErrorDialog(
            context,
            'Scan Diagnostic',
            'No games were found in the selected folder. Diagnostic output is shown below for troubleshooting.',
            details: details,
            onRetry: () => _scanFolder(),
          );
        }

        return games;
      },
      loadingText: 'Scanning folder...',
      errorTitle: 'Scan Failed',
      errorMessage: (e) =>
          'Failed to scan the selected folder: ${e.toString()}',
      onRetry: () => _scanFolder(),
    );
  }

  Future<void> _verifyAllGames() async {
    final logger = AppLogger.instance;

    if (_libraryState.games.isEmpty) {
      logger.info('No games to verify');
      return;
    }

    logger.info(
      'Starting library verification of ${_libraryState.games.length} games',
    );

    // Use ErrorHandler.handleAsync for standardized loading and error handling
    await ErrorHandler.handleAsync<void>(
      context,
      () async {
        final List<ScannedGame> updatedGames = [];
        int verifiedCount = 0;

        for (final game in _libraryState.games) {
          logger.debug('Verifying game: ${game.title}');
          final health = await _scanner.calculateHealth(game);
          game.health = health;
          game.verified = health >= 70;
          if (game.verified) verifiedCount++;
          updatedGames.add(game);
        }

        _libraryState.updateLibrary(
          updatedGames,
          _libraryState.lastScannedPath ?? '',
        );

        if (!mounted) return;
        logger.info(
          'Library verification complete. Verified: $verifiedCount/${_libraryState.games.length}',
        );

        // Use success dialog instead of snackbar (guarded immediately)
        if (!mounted) return;
        await ErrorHandler.showSuccessDialog(
          context,
          'Verification Complete',
          'Verified $verifiedCount of ${_libraryState.games.length} games',
        );
      },
      loadingText: 'Verifying games...',
      errorTitle: 'Verification Failed',
      errorMessage: (e) =>
          'Failed to verify your game library: ${e.toString()}',
      onRetry: () => _verifyAllGames(),
    );
  }

  Future<void> _deleteGame(ScannedGame game) async {
    final logger = AppLogger.instance;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: Text(
          'Are you sure you want to delete "${game.title}"?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      logger.info('Attempting to delete game: ${game.title}');
      final success = await _scanner.deleteGame(game);
      if (success) {
        _libraryState.games.remove(game);
        _libraryState.updateLibrary(
          _libraryState.games,
          _libraryState.lastScannedPath ?? '',
        );
        if (mounted) {
          setState(() {});
          logger.info('Successfully deleted game: ${game.title}');
          await ErrorHandler.showSuccessDialog(
            context,
            'Game Deleted',
            'Successfully deleted: ${game.title}',
          );
        }
      } else {
        logger.warning('Failed to delete game: ${game.title}');
        if (mounted) {
          await ErrorHandler.showErrorDialog(
            context,
            'Delete Failed',
            'Failed to delete: ${game.title}',
            details:
                'The file may be in use or you may not have permission to delete it.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Stack(
      children: [
        ImmersiveAppShell(
          title: 'LIBRARY',
          actions: [
            // Cover download badge
            const CoverDownloadBadge(),
            _buildActionButton(
              icon: Icons.folder_open,
              label: 'SCAN',
              color: primaryColor,
              textColor: Colors.white,
              filled: true,
              onPressed: () async {
                setState(() => _isScanning = true);
                try {
                  await _scanFolder();
                } finally {
                  if (mounted) {
                    setState(() => _isScanning = false);
                  }
                }
              },
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.verified,
              label: 'VERIFY',
              color: primaryColor,
              textColor: primaryColor,
              filled: false,
              onPressed: _libraryState.hasGames && !_isScanning
                  ? () async {
                      setState(() => _isScanning = true);
                      try {
                        await _verifyAllGames();
                      } finally {
                        if (mounted) {
                          setState(() => _isScanning = false);
                        }
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 20),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform filter pills
                if (_libraryState.hasGames) _buildFilterPills(primaryColor),

                const SizedBox(height: 24),

                // Main content
                Expanded(
                  child: _isScanning
                      ? _buildScanningState(primaryColor)
                      : _libraryState.hasGames
                          ? _buildLibraryGrid(primaryColor)
                          : _buildEmptyState(primaryColor, Colors.white),
                ),
              ],
            ),
          ),
        ),
        // Floating download progress indicator
        const CoverDownloadIndicator(),
      ],
    );
  }

  Widget _buildFilterPills(Color primaryColor) {
    final platforms = ['All', 'Wii', 'GameCube'];
    final counts = {
      'All': _libraryState.games.length,
      'Wii': _libraryState.games.where((g) => g.platform == 'Wii').length,
      'GameCube':
          _libraryState.games.where((g) => g.platform == 'GameCube').length,
    };

    return Row(
      children: platforms.map((platform) {
        final isSelected = _filterPlatform == platform;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterPlatform = platform),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      platform,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${counts[platform]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required bool filled,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? Colors.transparent : color.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinningDisc(size: 80, color: primaryColor),
          const SizedBox(height: 24),
          Text(
            'Scanning library...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reading game headers',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 48,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No games in library',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Scan Folder" to add your games',
            style: TextStyle(color: textColor.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _scanFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose Folder'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryGrid(Color primaryColor) {
    final games = _filteredGames;

    return FadeTransition(
      opacity: _fadeController,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: games.length,
        cacheExtent: 500, // Pre-render offscreen items for smoother scrolling
        itemBuilder: (context, index) => _buildGameCard(games[index], index),
      ),
    );
  }

  Widget _buildGameCard(ScannedGame game, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index % 10) * 30),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedGameCard(
              gameId: game.gameId,
              title: game.title,
              platform: game.platform.toLowerCase(),
              healthPercent: game.health.toDouble(),
              isVerified: game.verified,
              onTap: () => _showGameDetails(game),
            ),
          ),
        );
      },
    );
  }

  void _showGameDetails(ScannedGame game) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover art
                  Container(
                    width: 90,
                    height: 126,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GameCover(
                        gameId: game.gameId,
                        title: game.title,
                        platform: game.platform.toLowerCase(),
                        width: 90,
                        height: 126,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(primaryColor, game.platform),
                            if (game.gameId != null)
                              _buildInfoChip(primaryColor, game.gameId!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _buildStatCard(
                    ctx,
                    'Health',
                    '${game.health}%',
                    primaryColor,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    ctx,
                    'Size',
                    game.formattedSize,
                    primaryColor,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    ctx,
                    'Format',
                    game.extension.toUpperCase(),
                    primaryColor,
                    isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteGame(game);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Close', style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext ctx,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
