import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_result.dart';

// Top-level function for isolate extraction to keep UI smooth
Future<void> _extractHomebrewZipCb(List<String> args) async {
  final zipPath = args[0];
  final extractPath = args[1];
  await extractFileToDisk(zipPath, extractPath);
}

// Top-level function for checksum to keep UI smooth
Future<String> _calculateMd5Cb(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return '';
  // Read in chunks for memory efficiency
  final digest = await md5.bind(file.openRead()).first;
  return digest.toString();
}

class HomebrewAutomationService {
  static final HomebrewAutomationService _instance =
      HomebrewAutomationService._internal();
  factory HomebrewAutomationService() => _instance;
  HomebrewAutomationService._internal();

  /// Installs a homebrew app to the SD card
  /// [expectedMd5] is optional but highly recommended.
  Future<void> installToSD({
    required GameResult game,
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
    String? expectedMd5,
  }) async {
    if (game.downloadUrl == null) {
      throw Exception('No download URL available for ${game.title}');
    }

    final tempDir = await getTemporaryDirectory();
    final downloadDir =
        await Directory(path.join(tempDir.path, 'hb_dl_${game.title.hashCode}'))
            .create(recursive: true);
    final zipFile = File(path.join(downloadDir.path, 'package.zip'));
    final extractDir = Directory(path.join(downloadDir.path, 'extracted'));

    try {
      // 1. Download
      onStatus('Downloading ${game.title}...');
      await _downloadFile(
          game.downloadUrl!, zipFile, (p) => onProgress(p * 0.4));

      // 1.5 Verify Checksum
      if (expectedMd5 != null && expectedMd5.isNotEmpty) {
        onStatus('Verifying integrity...');
        final calculatedMd5 = await compute(_calculateMd5Cb, zipFile.path);
        if (calculatedMd5.toLowerCase() != expectedMd5.toLowerCase()) {
           throw Exception('Checksum mismatch! Expected $expectedMd5 but got $calculatedMd5.');
        }
      }

      // 2. Extract
      onStatus('Extracting ${game.title}...');
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      extractDir.createSync();

      await compute(_extractHomebrewZipCb, [zipFile.path, extractDir.path]);
      onProgress(0.7);

      // 3. Install
      onStatus('Installing to SD Card...');
      await _mergeToSD(
          extractDir, sdCardRoot, (p) => onProgress(0.7 + (p * 0.3)));

      onStatus('Successfully installed ${game.title}!');
      onProgress(1.0);
    } catch (e) {
      // Rethrow to let provider handle UI error state
      rethrow;
    } finally {
      // Cleanup
      if (downloadDir.existsSync()) {
        try {
          downloadDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<void> _downloadFile(
      String url, File target, Function(double) onProgress) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;
      final sink = target.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<void> _mergeToSD(Directory source, Directory destination,
      Function(double) onProgress) async {
    // OSC Zips usually have 'apps/slug/...' or just 'slug/...'
    // We want to ensure 'apps/' exists if we are moving folders.

    // Find where the 'apps' folder is, or if it's a flat zip
    Directory rootToCopy = source;
    final entities = source.listSync();

    // Heuristic: If it's a single folder that isn't 'apps' and contains boot.dol/elf deeper down, 
    // it might be the app root itself.
    if (entities.length == 1 && entities.first is Directory) {
      final dirName = path.basename(entities.first.path).toLowerCase();
      // Don't strip 'apps' or huge system folders
      if (dirName != 'apps' && dirName != 'wiiu') {
        rootToCopy = entities.first as Directory;
      }
    }

    final files =
        rootToCopy.listSync(recursive: true).whereType<File>().toList();
    if (files.isEmpty) return;

    final sourcePathLen = rootToCopy.path.length + 1;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      String relativePath = file.path.substring(sourcePathLen);
      final filename = path.basename(relativePath);

      // Junk Filter
      if (filename.startsWith('__MACOSX') || 
          filename.contains('.DS_Store') || 
          filename.contains('Thumbs.db')) {
        continue;
      }

      // Destination Logic
      final destPath = path.join(destination.path, relativePath);
      final destFile = File(destPath);

      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }

      await file.copy(destPath);
      onProgress((i + 1) / files.length);
    }
  }
}
