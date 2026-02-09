import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Top-level function for compute() isolate
/// Arguments: [archivePath, destinationPath]
Future<void> _extractZipCb(List<String> args) async {
  final archivePath = args[0];
  final destPath = args[1];
  await extractFileToDisk(archivePath, destPath);
}

/// Service to handle archive extraction (7z, zip)
class ArchiveService {
  /// Extracts the given archive file to the destination directory.
  /// Returns the path to the extracted game file (.wbfs, .iso, .rvz) or null if not found.
  Future<String?> extractGame(File archiveFile, Directory destination) async {
    debugPrint(
        '[ArchiveService] Extracting ${archiveFile.path} to ${destination.path}');

    if (!await archiveFile.exists()) {
      debugPrint('[ArchiveService] Error: Archive file does not exist');
      return null;
    }

    try {
      if (archiveFile.path.toLowerCase().endsWith('.7z')) {
        debugPrint(
            '[ArchiveService] Detected 7z archive. Attempting external 7z...');
        final exe = await _resolve7zExecutable();
        if (exe == null) {
          debugPrint(
              '[ArchiveService] 7z executable not found. Cannot extract .7z file.');
          return null;
        }

        // Use 'x' command to extract with full paths
        final result = await Process.run(
            exe, ['x', archiveFile.path, '-o${destination.path}', '-y']);

        if (result.exitCode != 0) {
          debugPrint('[ArchiveService] 7z extraction failed: ${result.stderr}');
          return null;
        }
      } else {
        // Fallback for Zip using archive_io in isolate
        await compute(_extractZipCb, [archiveFile.path, destination.path]);
      }

      // Find the game file (.wbfs, .iso, .rvz, .ciso)
      final files = destination.listSync();
      for (var file in files) {
        final ext = path.extension(file.path).toLowerCase();
        if (ext == '.wbfs' ||
            ext == '.iso' ||
            ext == '.rvz' ||
            ext == '.ciso') {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[ArchiveService] Extraction failed: $e');
      return null;
    }
  }

  Future<String?> _resolve7zExecutable() async {
    if (Platform.isWindows) {
      // 1) Common locations
      final commonPaths = [
        r'C:\Program Files\7-Zip\7z.exe',
        r'C:\Program Files (x86)\7-Zip\7z.exe',
        r'C:\Program Files\7-Zip\7za.exe',
        r'C:\Program Files (x86)\7-Zip\7za.exe',
      ];
      for (final p in commonPaths) {
        if (await File(p).exists()) return p;
      }

      // 2) Bundled tools folder (if applicable) -> assets/tools/ or standard paths

      // 3) PATH
      try {
        final result = await Process.run('where', ['7z']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.isNotEmpty && lines.first.trim().isNotEmpty) {
            return lines.first.trim();
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
