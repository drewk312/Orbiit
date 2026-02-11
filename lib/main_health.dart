import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/database/database.dart';
import '../core/models/health_issue.dart';
import '../core/models/health_score.dart';
import '../core/models/task.dart';
import '../ffi/forge_bridge.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/library_screen.dart';
import '../ui/screens/queue_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI bridge
  final bridge = ForgeBridge();
  bridge.init();
  // debugPrint('Forge version: ${ForgeBridge.getVersion()}'); // Not available

  // Initialize database
  final db = AppDatabase();

  runApp(WiiGCFusionApp(database: db));
}

class WiiGCFusionApp extends StatelessWidget {
  final AppDatabase database;

  const WiiGCFusionApp({required this.database, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiiGC Fusion',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C2FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DashboardHome(database: database),
    );
  }
}

class DashboardHome extends StatefulWidget {
  final AppDatabase database;

  const DashboardHome({required this.database, super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  HealthScore? _healthScore;
  List<HealthIssue> _issues = [];
  final List<BackgroundTask> _tasks = [];
  int _scannedFiles = 0;
  int _foundGames = 0;
  bool _scanning = false;
  int _selectedTab = 0;
  final _forgeBridge = ForgeBridge();

  @override
  void initState() {
    super.initState();
    _loadHealthData();
    // _subscribeToEvents(); // Removed, handled in _startScan
  }

  Future<void> _loadHealthData() async {
    final snapshot = await widget.database.getLatestHealthSnapshot();
    if (snapshot != null) {
      setState(() {
        _healthScore = HealthScore(
          score: snapshot.score,
          totalTitles: snapshot.totalTitles,
          healthyCount: snapshot.healthyCount,
          duplicateCount: snapshot.duplicateCount,
          corruptedCount: snapshot.corruptedCount,
          missingMetadataCount: snapshot.missingMetadataCount,
          totalSizeBytes: snapshot.totalSizeBytes,
          potentialSavingsBytes: snapshot.potentialSavingsBytes,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(snapshot.timestamp * 1000),
        );
      });
    }

    final issues = await widget.database.getUnresolvedIssues();
    setState(() {
      _issues = issues
          .map((i) => HealthIssue(
                id: i.id,
                titleId: i.titleId,
                issueType: IssueType.fromString(i.issueType),
                severity: Severity.fromString(i.severity),
                description: i.description,
                estimatedImpactScore: i.estimatedImpactScore,
                estimatedSpaceSavings: i.estimatedSpaceSavings,
                fixAction: i.fixAction,
                createdTimestamp: DateTime.fromMillisecondsSinceEpoch(
                    i.createdTimestamp * 1000),
              ))
          .toList();
    });
  }

  // _subscribeToEvents removed

  Future<void> _handleGameFound(String path, GameIdentity identity) async {
    // Map platformId to String
    String platform = 'Unknown';
    if (identity.platformId == 1) platform = 'Wii';
    if (identity.platformId == 2) platform = 'GameCube';

    // Map formatId to String
    String format = 'Unknown';
    switch (identity.formatId) {
      case 1:
        format = 'ISO';
        break;
      case 2:
        format = 'WBFS';
        break;
      case 3:
        format = 'NKit';
        break;
      case 4:
        format = 'RVZ';
        break;
    }

    final size = identity.fileSize;
    final gameId = identity.titleId;
    String title = identity.gameTitle;

    // If title is empty or generic, try to improve fallback
    // (Existing logic used filename parsing, but identity should be better)
    if (title.isEmpty || title == gameId) {
      title = _getGameNameFromId(gameId);
    }

    // Fallback to filename if still generic
    if (title == gameId || title == 'Unknown') {
      final filename = path.split('\\').last.split('/').last;
      title = filename;
    }

    debugPrint(
        'Inserting: $title [$gameId] ($platform) - ${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB');

    // Calculate partial SHA-1 (first 1MB + last 1MB for quick duplicate detection)
    String? partialHash;
    try {
      // Use new calculateHash (Note: this is full hash, but main_health.dart expects "partialHash" var name)
      // Since verifyHash calculates full hash, calculateHash also likely does full.
      // We'll just use it.
      partialHash = await _forgeBridge.calculateHash(path);
    } catch (e) {
      debugPrint('Hash calculation failed for $path: $e');
    }

    // Insert into database
    try {
      await widget.database.insertTitle(
        gameId: gameId,
        title: title,
        platform: platform,
        region: _detectRegion(gameId),
        format: format,
        filePath: path,
        fileSizeBytes: size,
        sha1Partial: partialHash,
      );
    } catch (e) {
      // Skip duplicates silently (file already scanned)
      if (!e.toString().contains('UNIQUE constraint')) {
        debugPrint('Error inserting $title: $e');
      }
    }
  }

  // Refactored _startScan and _handleScanComplete will be handled by logic below
  // We'll replace the old content with new methods.

  String _detectRegion(String gameId) {
    if (gameId.length < 4) return 'Unknown';
    final regionCode = gameId[3];
    switch (regionCode) {
      case 'E':
      case 'P':
        return 'USA';
      case 'J':
        return 'Japan';
      case 'D':
      case 'F':
      case 'I':
      case 'S':
      case 'H':
      case 'U':
      case 'X':
      case 'Y':
      case 'Z':
        return 'Europe';
      case 'K':
        return 'Korea';
      default:
        return 'Unknown';
    }
  }

  String _getGameNameFromId(String gameId) {
    // Map of known game IDs to names (common games)
    const gameNames = {
      // Mario Party series
      '7504': 'Mario Party 4',
      '7505': 'Mario Party 5',
      '7506': 'Mario Party 6',
      '7507': 'Mario Party 7',
      'GMPP01': 'Mario Party 4',
      'GP5P01': 'Mario Party 5',
      'GP6P01': 'Mario Party 6',
      'GP7P01': 'Mario Party 7',

      // Pikmin series
      '7612': 'Pikmin',
      '7613': 'Pikmin 2',
      'GPIP01': 'Pikmin',

      // Metroid
      '7526': 'Metroid Prime',
      'GM8P01': 'Metroid Prime',

      // Luigi's Mansion
      '7492': "Luigi's Mansion",
      'GLMP01': "Luigi's Mansion",

      // Kirby
      '7471': 'Kirby Air Ride',
      'GKYP01': 'Kirby Air Ride',

      // F-Zero
      '7395': 'F-Zero GX',

      // Donkey Kong
      '7375': 'Donkey Kong Jungle Beat',
      'GYBP01': 'Donkey Kong Jungle Beat',

      // Crash
      '7340': 'Crash Nitro Kart',
      'GCNP7D': 'Crash Nitro Kart',

      // Beyond Good & Evil
      '7298': 'Beyond Good & Evil',

      // Animal Crossing
      '7271': 'Animal Crossing',
      'GAFP01': 'Animal Crossing',

      // 1080 Avalanche
      '7258': '1080 Avalanche',

      // WWE
      '7669': 'WWE Day of Reckoning 2',
      '7668': 'WWE Day of Reckoning',
      'GW2P78': 'WWE Day of Reckoning 2',
    };

    return gameNames[gameId] ?? gameId;
  }

  Future<void> _calculateHealthScore() async {
    // Get all titles grouped by game_id for duplicate detection
    final titles = await widget.database.getAllTitles();

    // Group by game_id to find duplicates
    final Map<String, List<dynamic>> gameGroups = {};
    for (final title in titles) {
      gameGroups.putIfAbsent(title.gameId, () => []).add(title);
    }

    // Clear existing issues
    await widget.database.deleteAllIssues();

    int duplicateCount = 0;
    int totalSavings = 0;

    // Detect duplicates
    for (final entry in gameGroups.entries) {
      final gameId = entry.key;
      final copies = entry.value;

      if (copies.length > 1) {
        duplicateCount += copies.length - 1; // All but one are duplicates

        // Calculate potential savings (keep largest, mark rest as duplicate)
        copies.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        for (int i = 1; i < copies.length; i++) {
          totalSavings += copies[i].fileSizeBytes as int;

          // Use actual game name instead of ID in description
          final gameName = _getGameNameFromId(gameId);

          // Create issue for duplicate
          await widget.database.insertIssue(
            titleId: copies[i].id as int,
            issueType: 'duplicate',
            severity: 'medium',
            description:
                'Duplicate of "$gameName" (copy ${i + 1} of ${copies.length})',
            estimatedImpactScore: -5,
            estimatedSpaceSavings: copies[i].fileSizeBytes as int,
            fixAction: 'delete',
          );
        }
      }
    }

    // Calculate health score
    final totalTitles = titles.length;
    final healthyCount = totalTitles - duplicateCount;
    int score = 100;
    score -=
        (duplicateCount * 5).clamp(0, 50); // -5 points per duplicate, max -50

    // Create health snapshot
    await widget.database.insertHealthSnapshot(
      score: score,
      totalTitles: totalTitles,
      healthyCount: healthyCount,
      duplicateCount: duplicateCount,
      corruptedCount: 0,
      missingMetadataCount: 0,
      totalSizeBytes: titles.fold<int>(0, (sum, t) => sum + (t.fileSizeBytes)),
      potentialSavingsBytes: totalSavings,
    );

    debugPrint(
        'Health Score: $score/100 ($healthyCount healthy, $duplicateCount duplicates)');
  }

  Future<void> _handleScanComplete(int found) async {
    setState(() {
      _scanning = false;
      _scannedFiles =
          found; // Approximate, since we don't get total files scanned
      _foundGames = found;
    });

    // Calculate health score and detect duplicates
    await _calculateHealthScore();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan complete! Found $found games'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Reload health data
    _loadHealthData();
  }

  Future<void> _startScan() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to scan',
    );

    if (result != null) {
      setState(() {
        _scanning = true;
        _scannedFiles = 0;
        _foundGames = 0;
      });

      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scan started...')),
          );
        }

        // Run scan (blocking/sync in Dart implementation for now)
        // We use Future.delayed to allow UI to update before blocking
        await Future.delayed(const Duration(milliseconds: 100));

        int foundCount = 0;
        try {
          foundCount = _forgeBridge.scanFolder(result, true, (path, identity) {
            // Determine if we found a game
            if (mounted) {
              setState(() {
                _foundGames++;
              });
            }
            _handleGameFound(path, identity);
          });
        } catch (e) {
          debugPrint('Scan error: $e');
        }

        if (mounted) {
          _handleScanComplete(foundCount);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _scanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showFixPlanDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix plan'),
        content: SizedBox(
          width: 400,
          child: _issues.isEmpty
              ? const Text(
                  'No issues detected. Run a scan to check for duplicates and other problems.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_issues.length} issue(s) found. Resolve duplicates from the Library tab.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ..._issues.take(10).map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  i.severity == Severity.high
                                      ? Icons.warning_amber
                                      : Icons.info_outline,
                                  size: 18,
                                  color: i.severity == Severity.high
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    i.description,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (_issues.length > 10)
                        Text(
                          '... and ${_issues.length - 10} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (_issues.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _selectedTab = 1);
              },
              child: const Text('Open Library'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (_selectedTab) {
      case 0: // Dashboard
        currentScreen = Column(
          children: [
            if (_scanning)
              Container(
                color: const Color(0xFF00C2FF).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(
                        'Scanning: $_foundGames games found ($_scannedFiles files)'),
                  ],
                ),
              ),
            Expanded(
              child: BentoDashboard(
                healthScore: _healthScore,
                topIssues: _issues,
                activeTasks: _tasks,
                onScanPressed: _startScan,
                onViewQueuePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QueueScreen(
                        tasks: _tasks,
                        onPause: (id) => debugPrint('Pause $id'),
                        onResume: (id) => debugPrint('Resume $id'),
                        onCancel: (id) => debugPrint('Cancel $id'),
                        onRetry: (id) => debugPrint('Retry $id'),
                      ),
                    ),
                  );
                },
                onFixIssuesPressed: () => _showFixPlanDialog(context),
              ),
            ),
          ],
        );
        break;
      case 1: // Library
        currentScreen = LibraryScreen(database: widget.database);
        break;
      case 2: // Queue
        currentScreen = QueueScreen(
          tasks: _tasks,
          onPause: (id) => debugPrint('Pause $id'),
          onResume: (id) => debugPrint('Resume $id'),
          onCancel: (id) => debugPrint('Cancel $id'),
          onRetry: (id) => debugPrint('Retry $id'),
        );
        break;
      case 3: // Settings
        currentScreen = _SettingsScreen(database: widget.database);
        break;
      default:
        currentScreen = LibraryScreen(database: widget.database);
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              setState(() => _selectedTab = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: Text('Health'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.videogame_asset_outlined),
                selectedIcon: Icon(Icons.videogame_asset),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.queue_outlined),
                selectedIcon: Icon(Icons.queue),
                label: Text('Queue'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: currentScreen),
        ],
      ),
    );
  }
}

/// Simple Settings screen for the health app entry point
class _SettingsScreen extends StatelessWidget {
  final AppDatabase database;

  const _SettingsScreen({required this.database});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Library path'),
          subtitle: const Text('Set in main WiiGC Fusion app'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety_outlined),
          title: const Text('Health scan'),
          subtitle: const Text('Run scan from Health tab'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text(
            'WiiGC Fusion Health • Library and queue management',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
