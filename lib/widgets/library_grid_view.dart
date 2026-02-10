import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cover_art_provider.dart';
import '../../services/cover_art/cover_art_source.dart';

/// Enhanced library grid tile with cover art
class LibraryGameTile extends StatefulWidget {
  final String gameId;
  final String title;
  final String platform;
  final String? filePath;
  final VoidCallback? onTap;

  const LibraryGameTile({
    super.key,
    required this.gameId,
    required this.title,
    required this.platform,
    this.filePath,
    this.onTap,
  });

  @override
  State<LibraryGameTile> createState() => _LibraryGameTileState();
}

class _LibraryGameTileState extends State<LibraryGameTile> {
  String? _coverPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCoverArt();
  }

  Future<void> _loadCoverArt() async {
    if (_loading) return;

    setState(() => _loading = true);

    final coverProvider = context.read<CoverArtProvider>();

    // Convert platform string to GamePlatform enum
    final platform = _parsePlatform(widget.platform);
    if (platform == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final coverPath = await coverProvider.downloadCover(
        gameTitle: widget.title,
        platform: platform,
        gameId: widget.gameId,
      );

      if (mounted) {
        setState(() {
          _coverPath = coverPath;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  GamePlatform? _parsePlatform(String platformStr) {
    switch (platformStr.toLowerCase()) {
      case 'wii':
      case 'nintendo wii':
        return GamePlatform.wii;
      case 'gc':
      case 'gamecube':
      case 'nintendo gamecube':
        return GamePlatform.gamecube;
      case 'wiiu':
      case 'wii u':
      case 'nintendo wii u':
        return GamePlatform.wiiu;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover art section
            Expanded(
              child: _buildCoverArt(),
            ),
            // Game info section
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withValues(alpha: 0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.platform.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArt() {
    if (_loading) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_coverPath != null && File(_coverPath!).existsSync()) {
      return Image.file(
        File(_coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon() {
    switch (widget.platform.toLowerCase()) {
      case 'wii':
      case 'nintendo wii':
        return Icons.gamepad;
      case 'gc':
      case 'gamecube':
      case 'nintendo gamecube':
        return Icons.sports_esports;
      case 'wiiu':
      case 'wii u':
      case 'nintendo wii u':
        return Icons.videogame_asset;
      default:
        return Icons.videogame_asset_outlined;
    }
  }
}

/// Library grid view widget
class LibraryGridView extends StatelessWidget {
  final List<GameGridItem> games;
  final Function(GameGridItem game)? onGameTap;

  const LibraryGridView({
    super.key,
    required this.games,
    this.onGameTap,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No games in library',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your collection to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 covers per row
        childAspectRatio: 0.7, // Portrait cover ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return LibraryGameTile(
          gameId: game.gameId,
          title: game.title,
          platform: game.platform,
          filePath: game.filePath,
          onTap: onGameTap != null ? () => onGameTap!(game) : null,
        );
      },
    );
  }
}

/// Data model for grid items
class GameGridItem {
  final String gameId;
  final String title;
  final String platform;
  final String? filePath;
  final int? fileSizeBytes;

  GameGridItem({
    required this.gameId,
    required this.title,
    required this.platform,
    this.filePath,
    this.fileSizeBytes,
  });
}
