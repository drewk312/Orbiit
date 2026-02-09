import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

// Top-level function for isolate
Future<void> _extractZipCb(List<String> args) async {
  final archivePath = args[0];
  final destPath = args[1];
  await extractFileToDisk(archivePath, destPath);
}

class ProjectPlusService {
  static const String _downloadUrl =
      'https://github.com/Project-Plus-Development-Team/PPlusReleases/releases/download/v3.1.5/Project+.v3.1.5.Wii.Lite.zip';

  final _logger = Logger('ProjectPlusService');

  /// Installs Project+ to the SD card root
  Future<void> installProjectPlus({
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File(path.join(tempDir.path, 'pplus_installer.zip'));
    final extractDir = Directory(path.join(tempDir.path, 'pplus_extracted'));

    try {
      // 1. Download
      onStatus('Downloading Project+ v3.1.5...');
      // 0.0 - 0.5
      await _downloadFile(_downloadUrl, zipFile, (p) => onProgress(p * 0.5));

      // 2. Extract
      onStatus('Extracting files (this may take a minute)...');
      // 0.5 - 0.8
      onProgress(0.5);

      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      extractDir.createSync();

      await compute(_extractZipCb, [zipFile.path, extractDir.path]);
      onProgress(0.8);

      // 3. Install (Move files)
      onStatus('Installing to SD Card...');
      // 0.8 - 1.0
      await _installFiles(
          extractDir, sdCardRoot, (p) => onProgress(0.8 + (p * 0.2)));

      // Cleanup
      if (zipFile.existsSync()) zipFile.deleteSync();
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);

      onStatus('Installation Complete!');
      onProgress(1.0);
    } catch (e) {
      _logger.severe('Installation failed', e);
      // Cleanup on fail
      if (zipFile.existsSync()) zipFile.deleteSync();
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      throw Exception('Installation failed: $e');
    }
  }

  Future<void> _downloadFile(
      String url, File targetFile, Function(double) onProgress) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var downloaded = 0;
      final sink = targetFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        }
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<void> _installFiles(Directory source, Directory destination,
      Function(double) onProgress) async {
    // Check if files are in a subfolder
    Directory rootSrc = source;
    final entities = source.listSync();
    if (entities.length == 1 && entities.first is Directory) {
      rootSrc = entities.first as Directory;
    }

    final allFiles =
        rootSrc.listSync(recursive: true).whereType<File>().toList();
    final total = allFiles.length;
    var count = 0;

    if (!destination.existsSync()) destination.createSync(recursive: true);

    // Calculate base relative path length to strip
    final rootPathLen = rootSrc.path.length + 1;

    for (final file in allFiles) {
      final relativePath = file.path.substring(rootPathLen);
      final destPath = path.join(destination.path, relativePath);

      final destFile = File(destPath);
      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }

      if (destFile.existsSync()) destFile.deleteSync();
      await file.copy(destPath);

      count++;
      onProgress(count / total);
    }
  }
}
