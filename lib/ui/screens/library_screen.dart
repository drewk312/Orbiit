import 'dart:io';
import 'package:flutter/material.dart' hide Title;
import '../../core/database/database.dart';
import '../widgets/cover_art_widget.dart';
import '../../services/cover_art/cover_art_service.dart';
import '../../services/cover_art/cover_art_source.dart';
import 'game_detail_screen.dart';
import 'sd_card_export_screen.dart';

/// Library Screen - Display all games with filters
class LibraryScreen extends StatefulWidget {
  final AppDatabase database;

  const LibraryScreen({super.key, required this.database});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _filterPlatform = 'all';
  String _filterHealth = 'all';
  String _sortBy = 'title';
  List<Title> _titles = [];
  List<Issue> _duplicateIssues = [];
  bool _loading = true;
  bool _gridView = false; // Toggle between list and grid

  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<void> _loadTitles() async {
    setState(() => _loading = true);

    final titles = await widget.database.getAllTitles();
    final duplicates = await widget.database.getDuplicateIssues();

    // Filter
    var filtered = titles.where((t) {
      if (_filterPlatform != 'all' && t.platform != _filterPlatform)
        return false;
      if (_filterHealth != 'all' && t.healthStatus != _filterHealth)
        return false;
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'size':
        filtered.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
      case 'health':
        // Sort by health status (pending, healthy, duplicate, corrupted)
        filtered.sort((a, b) => a.healthStatus.compareTo(b.healthStatus));
        break;
    }

    setState(() {
      _titles = filtered;
      _duplicateIssues = duplicates;
      _loading = false;
    });
  }

  Future<void> _downloadAllCovers() async {
    if (_titles.isEmpty) return;

    // Show progress dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int current = 0;
          int total = _titles.length;
          String currentGame = '';

          return AlertDialog(
            title: const Text('Downloading Covers'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: current / total),
                const SizedBox(height: 16),
                Text('$current / $total games'),
                if (currentGame.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentGame,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    // Use modular service
    final service = CoverArtService();

    // Batch download
    await service.batchGetCovers(
      games: _titles
          .map((t) => GameInfo(
                title: t.title,
                platform: _parsePlatform(t.platform),
                gameId: t.gameId,
              ))
          .toList(),
      onProgress: (curr, tot) {
        // Update dialog state (simplified)
        if (mounted) {
          // print('Downloading $curr/$tot');
        }
      },
    );

    // Close dialog
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover download complete!')),
      );
      setState(() {}); // Refresh to show new covers
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: isDark ? const Color(0xFF12121A) : Colors.white,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C2FF), Color(0xFFB000FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videogame_asset, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Library',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_titles.length} games',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
                  onPressed: () => setState(() => _gridView = !_gridView),
                  tooltip: _gridView ? 'List View' : 'Grid View',
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download All Covers'),
                  onPressed: _downloadAllCovers,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.sd_card, size: 18),
                  label: const Text('Export to SD Card'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SDCardExportScreen(database: widget.database),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF12121A) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('Platform', _filterPlatform, [
                    'all',
                    'wii',
                    'gamecube',
                  ], (value) {
                    setState(() => _filterPlatform = value);
                    _loadTitles();
                  }),
                  const SizedBox(width: 12),
                  _buildFilterChip('Health', _filterHealth, [
                    'all',
                    'healthy',
                    'duplicate',
                    'pending',
                  ], (value) {
                    setState(() => _filterHealth = value);
                    _loadTitles();
                  }),
                  const SizedBox(width: 12),
                  _buildFilterChip('Sort', _sortBy, [
                    'title',
                    'size',
                    'health',
                  ], (value) {
                    setState(() => _sortBy = value);
                    _loadTitles();
                  }),
                ],
              ),
            ),
          ),

          // Game List
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_titles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videogame_asset_off,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No games found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan a folder to add games',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            _gridView
                ? SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final title = _titles[index];
                          return _GameGridTile(
                            title: title,
                            duplicateIssues: _duplicateIssues,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameDetailScreen(
                                    title: title,
                                    database: widget.database,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _titles.length,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final title = _titles[index];
                          return _GameListTile(
                            title: title,
                            duplicateIssues: _duplicateIssues,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameDetailScreen(
                                    title: title,
                                    database: widget.database,
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              await widget.database
                                  .deleteTitleByPath(title.filePath);
                            },
                            onRefresh: _loadTitles,
                          );
                        },
                        childCount: _titles.length,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00C2FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: const Color(0xFF00C2FF).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(color: Color(0xFF00C2FF), fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFF00C2FF), size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
    );
  }

  /// Parse platform string to GamePlatform enum
  GamePlatform _parsePlatform(String platform) {
    final lower = platform.toLowerCase();

    if (lower == 'wii') return GamePlatform.wii;
    if (lower.contains('wii u') || lower == 'wiiu') return GamePlatform.wiiu;
    if (lower.contains('gamecube') || lower == 'gc')
      return GamePlatform.gamecube;

    // Fallback
    return GamePlatform.wii;
  }
}

class _GameListTile extends StatelessWidget {
  final Title title;
  final List<Issue> duplicateIssues;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final Future<void> Function() onRefresh;

  const _GameListTile({
    required this.title,
    required this.duplicateIssues,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sizeGB =
        (title.fileSizeBytes / 1024 / 1024 / 1024).toStringAsFixed(2);

    // Check if this title has duplicate issue
    final hasDuplicateIssue =
        duplicateIssues.any((issue) => issue.titleId == title.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: hasDuplicateIssue
            ? Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Hero(
          tag: 'cover_${title.id}',
          child: CoverArtWidget(
            gameId: title.gameId,
            platform: title.platform,
            region: title.region ?? 'Unknown',
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Text(
          title.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: title.platform == 'wii'
                        ? const Color(0xFF00C2FF).withValues(alpha: 0.2)
                        : const Color(0xFFB000FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title.platform == 'wii' ? 'Wii' : 'GameCube',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: title.platform == 'wii'
                          ? const Color(0xFF00C2FF)
                          : const Color(0xFFB000FF),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.region == 'Unknown'
                      ? '$sizeGB GB'
                      : '${title.region} • $sizeGB GB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (hasDuplicateIssue) ...[
              const SizedBox(height: 4),
              Text(
                '⚠️ ${duplicateIssues.firstWhere((i) => i.titleId == title.id).description}',
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHealthBadge(),
            if (hasDuplicateIssue) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete duplicate file',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Duplicate?'),
        content: Text(
          'This will permanently delete:\n${title.filePath}\n\nSize: ${(title.fileSizeBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete the physical file
        final file = File(title.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete from database
        await onDelete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${title.title}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the list
        await onRefresh();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHealthBadge() {
    Color color;
    String text;

    switch (title.healthStatus) {
      case 'healthy':
        color = Colors.green;
        text = 'Healthy';
        break;
      case 'duplicate':
        color = Colors.orange;
        text = 'Duplicate';
        break;
      case 'corrupted':
        color = Colors.red;
        text = 'Corrupted';
        break;
      default:
        color = Colors.grey;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Grid view tile for Wii-style cover browsing
class _GameGridTile extends StatefulWidget {
  final Title title;
  final List<Issue> duplicateIssues;
  final VoidCallback onTap;

  const _GameGridTile({
    required this.title,
    required this.duplicateIssues,
    required this.onTap,
  });

  @override
  State<_GameGridTile> createState() => _GameGridTileState();
}

class _GameGridTileState extends State<_GameGridTile>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier instead of setState for hover state
  final ValueNotifier<bool> _isHoveredNotifier = ValueNotifier<bool>(false);
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWii = widget.title.platform == 'wii';
    final primaryColor =
        isWii ? const Color(0xFF00C2FF) : const Color(0xFFB000FF);
    final hasDuplicate =
        widget.duplicateIssues.any((i) => i.titleId == widget.title.id);

    return MouseRegion(
      onEnter: (_) {
        _isHoveredNotifier.value = true;
        _bounceController.forward();
      },
      onExit: (_) {
        _isHoveredNotifier.value = false;
        _bounceController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isHoveredNotifier,
            builder: (context, isHovered, _) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: hasDuplicate
                      ? Border.all(
                          color: Colors.orange.withValues(alpha: 0.6),
                          width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? primaryColor.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: isHovered ? 24 : 12,
                      spreadRadius: isHovered ? 3 : 0,
                      offset: Offset(0, isHovered ? 12 : 6),
                    ),
                    // Add secondary glow for depth
                    if (isHovered)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover art with gradient overlay
                    Expanded(
                      flex: 3,
                      child: Hero(
                        tag: 'cover_${widget.title.id}',
                        child: Stack(
                          children: [
                            CoverArtWidget(
                              gameId: widget.title.gameId,
                              platform: widget.title.platform,
                              region: widget.title.region ?? 'Unknown',
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            // Subtle gradient overlay for depth
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (hasDuplicate)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Game info with better spacing
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.title.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isWii ? 'Wii' : 'GC',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.title.region ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
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
              );
            },
          ),
        ),
      ),
    );
  }
}
