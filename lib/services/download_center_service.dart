// ═══════════════════════════════════════════════════════════════════════════
// DOWNLOAD CENTER MANAGER (Phase 5)
// ═══════════════════════════════════════════════════════════════════════════
//
// Handles the end-to-end flow of:
// 1. Importing externally downloaded archives (Zip/7z/Rar)
// 2. Auto-extracting them
// 3. Renaming using GameTDB / GameMetadata
// 4. Moving to standardized WBFS/ISO structure
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import '../core/app_logger.dart';

class DownloadCenterService {
  static final DownloadCenterService _instance =
      DownloadCenterService._internal();
  factory DownloadCenterService() => _instance;
  DownloadCenterService._internal();

  // Stream controller for progress updates if needed
  // ...

  /// Scans a "Downloads" folder for known game archives
  Future<List<File>> scanForGameArchives(Directory downloadDir) async {
    if (!downloadDir.existsSync()) return [];

    // Extensions we care about for "Get Games" flow
    // Temporarily removed .7z and .rar as pure Dart extraction is limited.
    const extensions = ['.zip', '.rvz', '.wbfs', '.iso'];

    return downloadDir.listSync().whereType<File>().where((file) {
      final ext = path.extension(file.path).toLowerCase();
      // Skip incomplete downloads
      if (file.path.endsWith('.part') || file.path.endsWith('.crdownload'))
        return false;
      return extensions.contains(ext);
    }).toList();
  }

  /// Processes a single archive file:
  /// 1. Extracts to temp
  /// 2. Identifies Game ID (by reading header or guessing)
  /// 3. Moves to SD/HDD
  Future<void> processArchive({
    required File archiveFile,
    required Directory destinationRoot, // e.g. D:/Games/Wii
    required Function(String status) onStatus,
    required Function(double progress) onProgress,
  }) async {
    final fileName = path.basename(archiveFile.path);
    onStatus('Analyzing $fileName...');

    // 1. Extraction (Prepare Temp)
    final tempDir = await Directory.systemTemp.createTemp('wii_extract_');
    try {
      if (_isArchive(archiveFile)) {
        onStatus('Extracting $fileName (this may take a while)...');
        await _extractArchive(archiveFile, tempDir, onProgress);
      } else {
        // It's already a raw file (iso/wbfs/rvz)? Copy to temp or just use it?
        // If it's on same drive, we can maybe just move.
        // For safety, let's treat it as the "source" file.
        // But if we want to "Process" it, we likely want to move/rename it.
        // Copying huge files to system temp is bad if drives differ.
        // Let's assume we work with it directly if not archive.
        // TODO: Handle raw Move logic.
      }

      // 2. Search extracted files for Game Image
      final gameFiles =
          tempDir.listSync(recursive: true).whereType<File>().where((f) {
        final ext = path.extension(f.path).toLowerCase();
        return ['.iso', '.wbfs', '.rvz', '.gcm', '.ciso'].contains(ext);
      }).toList();

      if (gameFiles.isEmpty) {
        throw Exception('No game files (iso/wbfs/rvz) found in archive.');
      }

      // For now, take the largest file as the "Game"
      // (Some archives have garbage or readme files)
      gameFiles.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
      final gameFile = gameFiles.first;

      // 3. Identify Game ID
      onStatus('Identifying Game...');
      String? gameId = await _readGameIdDisplay(gameFile);
      String gameTitle =
          path.basenameWithoutExtension(fileName); // Fallback title

      if (gameId == null) {
        onStatus(
            'Warning: Could not read Game ID from header. Using filename.');
        // Try to regex filename? e.g. "Super Mario Galaxy [RMGE01]"
        final match = RegExp(r'\[([A-Za-z0-9]{6})\]').firstMatch(fileName);
        if (match != null) {
          gameId = match.group(1);
        } else {
          // Generate a fake ID or ask user?
          // For automation, we might skip generic logic.
          gameId = 'UNKNOWN';
        }
      } else {
        // We have a real ID, lets try to fetch real title?
        // TODO: Integrate GameTDB/Metadata lookup for pretty naming
      }

      // 4. Move to Destination
      onStatus('Moving to Library...');
      final libFolder = Directory(path.join(destinationRoot.path, 'wbfs'));
      if (!libFolder.existsSync()) libFolder.createSync(recursive: true);

      // Standard Format: "Title [ID]/ID.ext"
      final safeTitle = gameTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
      final finalFolderName = '$safeTitle [$gameId]';
      final finalFileName = '$gameId${path.extension(gameFile.path)}';

      final gameFolder = Directory(path.join(libFolder.path, finalFolderName));
      if (!gameFolder.existsSync()) gameFolder.createSync();

      final finalPath = path.join(gameFolder.path, finalFileName);

      // Move/Copy
      // Cross-device move fallback
      try {
        await gameFile.rename(finalPath);
      } catch (e) {
        // Rename failed (diff volume?), copy then delete
        await gameFile.copy(finalPath);
        await gameFile.delete();
      }

      onStatus('Success! Installed to $finalFolderName');
    } finally {
      // Cleanup Temp
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    }
  }

  bool _isArchive(File f) {
    // Only support zip currently unless system tools are integrated
    return ['.zip'].contains(path.extension(f.path).toLowerCase());
  }

  Future<void> _extractArchive(
      File zip, Directory target, Function(double) onProgress) async {
    // Basic zip support via 'archive' package.
    // WARNING: 'archive' package is pure dart and SLOW for large files.
    // Recommended: Use system 7z/tar if available, or isolate.
    // Phase 5 optimization: Check for external tools or use synchronous chunks?

    // For large ISOs (4GB+), Dart heap might crash with standard 'decodeZip'.
    // Must use inputStream.

    final inputStream = InputFileStream(zip.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    int totalFiles = archive.length;
    int processed = 0;

    for (final file in archive) {
      if (file.isFile) {
        final outputStream =
            OutputFileStream(path.join(target.path, file.name));
        file.writeContent(outputStream);
        outputStream.close();
      }
      processed++;
      onProgress(processed / totalFiles);
    }
    inputStream.close();
  }

  // Reads the first 6 bytes of ISO/WBFS header to get ID
  Future<String?> _readGameIdDisplay(File file) async {
    try {
      final handle = await file.open(mode: FileMode.read);
      // ISO/GCM/WBFS usually has ID at offset 0
      // WBFS sometimes has a header, then the disc header.
      // Standard ISO: bytes 0-5 are ID.
      final bytes = await handle.read(6);
      await handle.close();

      final id = String.fromCharCodes(bytes);
      // Valid ID? (Alphanumeric 6 chars)
      if (RegExp(r'^[A-Za-z0-9]{6}$').hasMatch(id)) {
        return id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
