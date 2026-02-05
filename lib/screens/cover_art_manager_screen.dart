import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cover_art_provider.dart';

/// Screen for managing cover art downloads
class CoverArtManagerScreen extends StatefulWidget {
  const CoverArtManagerScreen({super.key});

  @override
  State<CoverArtManagerScreen> createState() => _CoverArtManagerScreenState();
}

class _CoverArtManagerScreenState extends State<CoverArtManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoverArtProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cover Art Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Cache Stats',
            onPressed: () async {
              await context.read<CoverArtProvider>().initialize();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cache',
            onPressed: () => _showClearCacheDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCacheStats(),
          const Divider(),
          Expanded(
            child: _buildDownloadsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchDownloadDialog(context),
        icon: const Icon(Icons.download),
        label: const Text('Batch Download'),
      ),
    );
  }

  Widget _buildCacheStats() {
    return Consumer<CoverArtProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.image,
                label: 'Cached Covers',
                value: '${provider.cachedCount}',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.storage,
                label: 'Cache Size',
                value: provider.formattedCacheSize,
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.downloading,
                label: 'Downloading',
                value: '${provider.activeDownloads.length}',
                color: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadsList() {
    return Consumer<CoverArtProvider>(
      builder: (context, provider, child) {
        final downloads = provider.activeDownloads;

        if (downloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active downloads',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showBatchDownloadDialog(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Start Batch Download'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: downloads.length,
          itemBuilder: (context, index) {
            final download = downloads[index];
            return _buildDownloadTile(download);
          },
        );
      },
    );
  }

  Widget _buildDownloadTile(CoverArtDownloadProgress download) {
    IconData icon;
    Color color;

    switch (download.status) {
      case DownloadStatus.queued:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        break;
      case DownloadStatus.complete:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DownloadStatus.notFound:
        icon = Icons.search_off;
        color = Colors.orange;
        break;
      case DownloadStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(download.gameTitle),
      subtitle: Text(download.platform.displayName),
      trailing: download.localPath != null
          ? Image.file(
              File(download.localPath!),
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            )
          : null,
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will delete all cached cover art. You will need to re-download covers.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<CoverArtProvider>().clearCache();
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showBatchDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Download'),
        content: const Text(
          'This will scan your library and download missing cover art for all games.\n\nThis may take several minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startBatchDownload(context);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _startBatchDownload(BuildContext context) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchDownloadProgressDialog(),
    );
  }
}

class _BatchDownloadProgressDialog extends StatefulWidget {
  @override
  State<_BatchDownloadProgressDialog> createState() =>
      _BatchDownloadProgressDialogState();
}

class _BatchDownloadProgressDialogState
    extends State<_BatchDownloadProgressDialog> {
  String _status = 'Scanning library...';
  double _progress = 0.0;
  int _downloaded = 0;
  int _total = 0;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _runBatchDownload();
  }

  Future<void> _runBatchDownload() async {
    try {
      // Find game library paths
      final possiblePaths = [
        'C:/Orbiit/wbfs',
        'C:/Orbiit/games',
        Directory.current.path,
      ];

      final gameIds = <String>[];

      for (final basePath in possiblePaths) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final idMatch = RegExp(r'\[([A-Z0-9]{6})\]').firstMatch(fileName);
            if (idMatch != null && !gameIds.contains(idMatch.group(1))) {
              gameIds.add(idMatch.group(1)!);
            }
          }
        }
      }

      if (gameIds.isEmpty) {
        setState(() {
          _status = 'No games found in library';
          _isRunning = false;
        });
        return;
      }

      setState(() {
        _total = gameIds.length;
        _status = 'Downloading covers...';
      });

      final coverDir = Directory('covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      for (int i = 0; i < gameIds.length && _isRunning; i++) {
        final gameId = gameIds[i];
        setState(() {
          _progress = i / gameIds.length;
          _status = 'Downloading: $gameId (${i + 1}/$_total)';
        });

        try {
          // Check if already exists
          if (await File('${coverDir.path}/${gameId}_3D.png').exists()) {
            continue;
          }

          // Download 3D cover from GameTDB
          final url = 'https://art.gametdb.com/wii/cover3D/US/$gameId.png';
          final client = HttpClient();
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();

          if (response.statusCode == 200) {
            final file = File('${coverDir.path}/${gameId}_3D.png');
            final sink = file.openWrite();
            await response.pipe(sink);
            _downloaded++;
          }
        } catch (_) {
          // Skip failed downloads
        }

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _status = 'Complete! Downloaded $_downloaded covers';
        _progress = 1.0;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Download'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_status),
          if (_total > 0) ...[
            const SizedBox(height: 8),
            Text('$_downloaded / $_total covers downloaded',
                style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
      actions: [
        if (_isRunning)
          TextButton(
            onPressed: () {
              _isRunning = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
