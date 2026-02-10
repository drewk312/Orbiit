import 'dart:io';
import 'package:path/path.dart' as path;
import '../../globals.dart';
import 'checksum_service.dart';
import '../../core/database/database.dart';

/// Enhanced duplicate detection service
/// Uses CRC32, file size, and game ID to detect duplicates
/// Better than TinyWii - can detect across different formats
class DuplicateDetectionService {
  final ChecksumService _checksumService = ChecksumService();

  /// Find all duplicates in a list of games
  /// Returns map of game ID -> list of duplicate entries
  Future<Map<String, List<DuplicateEntry>>> findDuplicates(
    List<Title> games, {
    bool checkCRC = true, // Slower but more accurate
    void Function(int current, int total)? onProgress,
  }) async {
    final duplicates = <String, List<DuplicateEntry>>{};
    final gameIdMap = <String, List<DuplicateEntry>>{};

    // Group by game ID first (fast)
    for (int i = 0; i < games.length; i++) {
      final game = games[i];

      // Extract 6-character game ID (e.g., RMGE01 -> RMGE01, RMGP01 -> RMGE01 for same game)
      final baseId =
          game.gameId.length >= 4 ? game.gameId.substring(0, 4) : game.gameId;

      if (!gameIdMap.containsKey(baseId)) {
        gameIdMap[baseId] = [];
      }

      final entry = DuplicateEntry(
        game: game,
        filePath: game.filePath,
        fileSize: await File(game.filePath).length(),
        format: _detectFormat(game.filePath),
      );

      gameIdMap[baseId]!.add(entry);
      onProgress?.call(i + 1, games.length);
    }

    // Filter to only groups with multiple entries
    for (final entry in gameIdMap.entries) {
      if (entry.value.length > 1) {
        duplicates[entry.key] = entry.value;
      }
    }

    // If CRC check enabled, calculate checksums for duplicates
    if (checkCRC && duplicates.isNotEmpty) {
      AppLogger.info(
          'Calculating CRC32 for ${duplicates.length} duplicate groups...',
          'DuplicateDetection');

      int processedGroups = 0;
      for (final group in duplicates.values) {
        for (final entry in group) {
          try {
            entry.crc32 =
                await _checksumService.calculateCRC32File(entry.filePath);
          } catch (e) {
            AppLogger.error('Error calculating CRC for ${entry.filePath}',
                'DuplicateDetection', e);
          }
        }
        processedGroups++;
        onProgress?.call(processedGroups, duplicates.length);
      }
    }

    return duplicates;
  }

  /// Find exact duplicates (same CRC32)
  /// More thorough than just game ID matching
  Future<List<List<DuplicateEntry>>> findExactDuplicates(
    List<Title> games, {
    void Function(int current, int total)? onProgress,
  }) async {
    final crcMap = <String, List<DuplicateEntry>>{};

    for (int i = 0; i < games.length; i++) {
      final game = games[i];

      try {
        final crc = await _checksumService.calculateCRC32File(game.filePath);

        if (!crcMap.containsKey(crc)) {
          crcMap[crc] = [];
        }

        crcMap[crc]!.add(DuplicateEntry(
          game: game,
          filePath: game.filePath,
          fileSize: await File(game.filePath).length(),
          format: _detectFormat(game.filePath),
          crc32: crc,
        ));

        onProgress?.call(i + 1, games.length);
      } catch (e) {
        AppLogger.error(
            'Error processing ${game.filePath}', 'DuplicateDetection', e);
      }
    }

    // Filter to only CRCs with multiple files
    final exactDuplicates = <List<DuplicateEntry>>[];
    for (final group in crcMap.values) {
      if (group.length > 1) {
        exactDuplicates.add(group);
      }
    }

    return exactDuplicates;
  }

  /// Detect format of game file
  String _detectFormat(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.iso':
        return 'ISO';
      case '.wbfs':
        return 'WBFS';
      case '.gcm':
        return 'GCM';
      case '.wia':
        return 'WIA';
      case '.rvz':
        return 'RVZ';
      case '.ciso':
        return 'CISO';
      case '.gcz':
        return 'GCZ';
      case '.tgc':
        return 'TGC';
      default:
        return ext.substring(1).toUpperCase();
    }
  }

  /// Recommend which duplicate to keep
  /// Priority: RVZ > WBFS > CISO > GCZ > WIA > ISO > GCM
  /// (Compressed formats are better for storage)
  DuplicateEntry recommendKeep(List<DuplicateEntry> duplicates) {
    final formatPriority = {
      'RVZ': 7, // Best compression, modern
      'WBFS': 6, // Good compression, widely supported
      'CISO': 5, // Decent compression
      'GCZ': 4, // GameCube compression
      'WIA': 3, // Dolphin format
      'ISO': 2, // Uncompressed, largest
      'GCM': 1, // GameCube uncompressed
      'TGC': 0, // Legacy format
    };

    // Sort by priority (higher is better)
    duplicates.sort((a, b) {
      final priorityA = formatPriority[a.format] ?? 0;
      final priorityB = formatPriority[b.format] ?? 0;

      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA); // Descending
      }

      // If same format, prefer smaller file (better compression)
      return a.fileSize.compareTo(b.fileSize);
    });

    return duplicates.first;
  }
}

/// Duplicate entry information
class DuplicateEntry {
  final Title game;
  final String filePath;
  final int fileSize;
  final String format;
  String? crc32;

  DuplicateEntry({
    required this.game,
    required this.filePath,
    required this.fileSize,
    required this.format,
    this.crc32,
  });

  String get sizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = fileSize.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}
