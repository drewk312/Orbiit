import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

class DLCManagerService {
  static final DLCManagerService _instance = DLCManagerService._internal();
  factory DLCManagerService() => _instance;
  DLCManagerService._internal();

  final _logger = Logger('DLCManagerService');

  // Slug from oscwii.org
  static const String _xyzzySlug = 'xyzzy-mod';
  static const String _oscApiUrl =
      'https://api.oscwii.org/v2/primary/packages/$_xyzzySlug';
  static const String _xyzzyDownloadUrl =
      'https://oscwii.org/library/app/$_xyzzySlug/zip';

  /// checks if keys.txt and device.cert exist at SD root
  Future<bool> hasKeys(Directory sdRoot) async {
    final keys = File(path.join(sdRoot.path, 'keys.txt'));
    final cert = File(path.join(sdRoot.path, 'device.cert'));
    return await keys.exists() && await cert.exists();
  }

  /// Installs xyzzy-mod to SD card
  Future<void> installXyzzyMod({
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    try {
      onStatus('Downloading xyzzy-mod...');
      onProgress(0.1);

      // Verify connection via API (optional check)
      try {
        await http.get(Uri.parse(_oscApiUrl));
      } catch (_) {
        // ignore, proceed to download attempt
      }

      final tempDir = await Directory.systemTemp.createTemp('xyzzy_dl');
      final zipFile = File(path.join(tempDir.path, 'xyzzy.zip'));

      await _downloadFile(
          _xyzzyDownloadUrl, zipFile, (p) => onProgress(0.1 + (p * 0.4)));

      onStatus('Extracting xyzzy-mod...');
      await compute(_extractZipCb, [zipFile.path, tempDir.path]);
      onProgress(0.7);

      onStatus('Installing to apps folder...');

      // Copy to SD/apps/xyzzy-mod/
      // OSC zip usually has 'apps/xyzzy-mod/...' structure
      await _installRecursive(
          tempDir, sdCardRoot, (p) => onProgress(0.7 + (p * 0.3)));

      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);

      onStatus('xyzzy-mod Installed!');
      onProgress(1.0);
    } catch (e) {
      _logger.severe('xyzzy install failed', e);
      rethrow;
    }
  }

  Future<void> _downloadFile(
      String url, File target, Function(double) onProgress) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);
    final contentLength = response.contentLength ?? 0;
    var received = 0;

    final sink = target.openWrite();
    await response.stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      },
      onDone: () async {
        await sink.close();
      },
      onError: (e) {
        sink.close();
        throw e;
      },
      cancelOnError: true,
    ).asFuture();
  }

  Future<void> _installRecursive(Directory source, Directory destination,
      Function(double) onProgress) async {
    if (!destination.existsSync()) destination.createSync(recursive: true);
    final files = source.listSync(recursive: true).whereType<File>().toList();
    final sourcePathLength = source.path.length + 1;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = file.path.substring(sourcePathLength);
      final destPath = path.join(destination.path, relativePath);
      final destFile = File(destPath);

      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }

      if (destFile.existsSync()) destFile.deleteSync();
      await file.copy(destPath);
      onProgress((i + 1) / files.length);
    }
  }
}

Future<void> _extractZipCb(List<String> args) async {
  final zipPath = args[0];
  final extractPath = args[1];
  final bytes = File(zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File(path.join(extractPath, filename))
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory(path.join(extractPath, filename)).createSync(recursive: true);
    }
  }
}
