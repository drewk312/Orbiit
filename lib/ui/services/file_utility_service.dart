import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for file utilities - sanitization, disk space, etc.
/// Based on TinyWii's util.rs
class FileUtilityService {
  /// Sanitize filename for cross-platform compatibility
  static String sanitizeFilename(String filename) {
    // Remove or replace invalid characters
    String sanitized = filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Windows invalid chars
        .replaceAll(RegExp(r'[\x00-\x1f]'), '_') // Control characters
        .replaceAll(RegExp(r'\.+$'), '') // Trailing dots
        .trim();

    // Replace multiple spaces with single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Ensure it's not too long (255 chars max for most filesystems)
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }

    // Avoid reserved Windows names
    final reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    ];

    final baseName = path.basenameWithoutExtension(sanitized).toUpperCase();
    if (reservedNames.contains(baseName)) {
      sanitized = '_$sanitized';
    }

    return sanitized;
  }

  /// Get disk usage information
  static Future<DiskUsage> getDiskUsage(String directoryPath) async {
    final dir = Directory(directoryPath);

    if (!await dir.exists()) {
      return DiskUsage(totalBytes: 0, usedBytes: 0, freeBytes: 0);
    }

    try {
      // Use PowerShell on Windows to get disk info
      if (Platform.isWindows) {
        // Extract drive letter properly (e.g., "D:" -> "D")
        String driveLetter = directoryPath.substring(0, 1).toUpperCase();

        final result = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            'Get-Volume -DriveLetter $driveLetter | Select-Object Size,SizeRemaining | ConvertTo-Json'
          ],
          environment: {'driveLetter': driveLetter},
        );

        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          // Simple regex parsing (avoiding json package dependency)
          final sizeMatch = RegExp(r'"Size"\s*:\s*(\d+)').firstMatch(output);
          final freeMatch =
              RegExp(r'"SizeRemaining"\s*:\s*(\d+)').firstMatch(output);

          if (sizeMatch != null && freeMatch != null) {
            final totalBytes = int.parse(sizeMatch.group(1)!);
            final freeBytes = int.parse(freeMatch.group(1)!);
            return DiskUsage(
              totalBytes: totalBytes,
              usedBytes: totalBytes - freeBytes,
              freeBytes: freeBytes,
            );
          }
        }

        // Try alternative method using WMI
        final wmiResult = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            '''
            \$drive = Get-WmiObject Win32_LogicalDisk | Where-Object { \$_.DeviceID -eq "$driveLetter:" }
            if (\$drive) {
              @{ Size = [long]\$drive.Size; SizeRemaining = [long]\$drive.FreeSpace } | ConvertTo-Json
            }
            '''
          ],
        );

        if (wmiResult.exitCode == 0) {
          final output = wmiResult.stdout.toString().trim();
          final sizeMatch = RegExp(r'"Size"\s*:\s*(\d+)').firstMatch(output);
          final freeMatch =
              RegExp(r'"SizeRemaining"\s*:\s*(\d+)').firstMatch(output);

          if (sizeMatch != null && freeMatch != null) {
            final totalBytes = int.parse(sizeMatch.group(1)!);
            final freeBytes = int.parse(freeMatch.group(1)!);
            return DiskUsage(
              totalBytes: totalBytes,
              usedBytes: totalBytes - freeBytes,
              freeBytes: freeBytes,
            );
          }
        }
      }

      // Fallback: Return zeros if we can't get disk info
      return DiskUsage(totalBytes: 0, usedBytes: 0, freeBytes: 0);
    } catch (e) {
      print('Error getting disk usage: $e');
      return DiskUsage(totalBytes: 0, usedBytes: 0, freeBytes: 0);
    }
  }

  /// Check if filesystem supports files >4GB (not FAT32)
  static Future<bool> canWrite4GBFiles(String directoryPath) async {
    try {
      if (Platform.isWindows) {
        final driveLetter = path.split(directoryPath)[0];
        final result = await Process.run(
          'fsutil',
          ['fsinfo', 'volumeinfo', driveLetter],
        );

        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          // Check if it's FAT32
          if (output.contains('FAT32')) {
            return false;
          }
        }
      }

      return true; // Assume yes if we can't determine
    } catch (e) {
      return true;
    }
  }

  /// Get file extension without dot
  static String getExtension(String filename) {
    final ext = path.extension(filename);
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  /// Check if file is a valid game disc file
  static bool isGameFile(String filename) {
    final ext = getExtension(filename).toLowerCase();
    return ['iso', 'wbfs', 'gcm', 'wia', 'rvz', 'ciso', 'gcz', 'tgc', 'nfs']
        .contains(ext);
  }

  /// Format byte size to human-readable string
  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// Normalize game directory structure
  /// Ensures games are in correct format for USB loaders
  static Future<void> normalizeGameDirectory(String gamePath) async {
    // Implementation would:
    // 1. Check current directory structure
    // 2. Move files to correct locations
    // 3. Rename files to match game ID
    // This is complex and would need game-specific logic
    print('Normalizing: $gamePath');
  }
}

/// Disk usage information
class DiskUsage {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  DiskUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  double get usedPercentage {
    if (totalBytes == 0) return 0;
    return (usedBytes / totalBytes) * 100;
  }

  String get totalFormatted => FileUtilityService.formatBytes(totalBytes);
  String get usedFormatted => FileUtilityService.formatBytes(usedBytes);
  String get freeFormatted => FileUtilityService.formatBytes(freeBytes);
}
