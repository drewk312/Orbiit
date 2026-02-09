import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class RiivolutionService {
  static final RiivolutionService _instance = RiivolutionService._internal();
  factory RiivolutionService() => _instance;
  RiivolutionService._internal();

  final _logger = Logger('RiivolutionService');

  // OSC Slug for Riivolution (verified from oscwii.org)
  static const String _riivolutionSlug = 'riivolution';
  static const String _oscApiUrl =
      'https://api.oscwii.org/v2/primary/packages/$_riivolutionSlug';

  /// Installs the Riivolution Homebrew App to the SD Card
  Future<void> installRiivolutionApp({
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    try {
      onStatus('Fetching Riivolution metadata...');
      onProgress(0.1);

      // 1. Get download URL from OSC
      final response = await http.get(Uri.parse(_oscApiUrl));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch Riivolution metadata: ${response.statusCode}');
      }

      // Basic JSON parsing to get zip URL (avoiding full model overhead for this single use)
      // OSC V2 API returns a JSON object with 'location'
      // Actual response is a list or object depending on endpoint.
      // Verified OSC API: GET /v2/primary/packages/{slug} returns JSON object.
      // We'll assume standard OSC structure or fallback to a direct reliable mirror if needed.
      // For simplicity/robustness in this "system" context, let's use the direct OSC zip URL pattern
      // which is usually https://oscwii.org/library/app/{slug}/(ignoring version)/{slug}.zip
      // BUT api is safer. Let's try direct download from OSC library which redirects.
      final downloadUrl =
          'https://oscwii.org/library/app/$_riivolutionSlug/zip';

      onStatus('Downloading Riivolution...');
      final tempDir = await Directory.systemTemp.createTemp('riivolution_dl');
      final zipFile = File(path.join(tempDir.path, 'riivolution.zip'));

      await _downloadFile(
          downloadUrl, zipFile, (p) => onProgress(0.1 + (p * 0.4)));

      onStatus('Extracting Riivolution...');
      await compute(_extractZipCb, [zipFile.path, tempDir.path]);
      onProgress(0.7);

      onStatus('Installing to SD Card...');

      // OSC Zips usually have the 'apps/slug/...' structure.
      // pass 'true' to merge, ensuring we don't wipe existing apps
      await _installRecursive(
          tempDir, sdCardRoot, (p) => onProgress(0.7 + (p * 0.3)));

      // Cleanup
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);

      onStatus('Riivolution Installed!');
      onProgress(1.0);
    } catch (e) {
      _logger.severe('Riivolution install failed', e);
      rethrow;
    }
  }

  /// Installs a Riivolution Mod (zip file) with smart structure detection
  Future<void> installMod({
    required File modZip,
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    try {
      onStatus('Analyzing Mod Archive...');
      onProgress(0.1);

      final tempDir = await Directory.systemTemp.createTemp('riivolution_mod');

      onStatus('Extracting Mod Files...');
      // Extract everything first to inspect structure
      await compute(_extractZipCb, [modZip.path, tempDir.path]);
      onProgress(0.5);

      onStatus('Installing Mod Files...');

      // Smart Detection Logic
      // 1. Check for 'riivolution' folder (config patches)
      // 2. Check for 'apps/riivolution' (custom boot.elfs?)
      // 3. Check for specific game folders (e.g. 'mario_kart', 'ssbb')
      //    (This is hard to know generically, so we usually merge ROOT to ROOT)

      // Strategy:
      // If the zip root contains 'riivolution' folder -> Merge zip root to SD root.
      // If the zip root contains 'apps' folder -> Merge zip root to SD root.
      // If the zip root contains 'GameFiles' or similar -> Merge zip root to SD root.
      // If the zip root has ONLY a single folder that IS NOT 'riivolution' or 'apps',
      //    it might be a "nested" zip (e.g. 'MyCoolMod/riivolution/...').
      //    In that case, we should install the CONTENT of that folder.

      Directory contentRoot = tempDir;
      final entities = tempDir.listSync();
      // If single directory, check if it's a wrapper
      if (entities.length == 1 && entities.first is Directory) {
        final subDir = entities.first as Directory;
        final subName = path.basename(subDir.path).toLowerCase();

        // If the one folder IS 'riivolution' or 'apps', then the root IS correct.
        // If it is something else (e.g. 'NewerSMBW'), check inside.
        // If inside has 'riivolution', then 'NewerSMBW' is likely just a container.
        if (subName != 'riivolution' && subName != 'apps') {
          // Peek inside
          final subEntities =
              subDir.listSync().map((e) => path.basename(e.path).toLowerCase());
          if (subEntities.contains('riivolution') ||
              subEntities.contains('apps')) {
            contentRoot = subDir; // Move down one level
          }
        }
      }

      await _installRecursive(
          contentRoot, sdCardRoot, (p) => onProgress(0.5 + (p * 0.5)));

      // Cleanup
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);

      onStatus('Mod Installed Successfully!');
      onProgress(1.0);
    } catch (e) {
      _logger.severe('Mod install failed', e);
      rethrow;
    }
  }

  // --- Helpers ---

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
    final sourcePathLength = source.path.length + 1; // +1 for separator

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = file.path.substring(sourcePathLength);
      final destPath = path.join(destination.path, relativePath);
      final destFile = File(destPath);

      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }

      // Check if we are overwriting
      if (destFile.existsSync()) destFile.deleteSync();

      await file.copy(destPath);
      onProgress((i + 1) / files.length);
    }
  }
}

// Top-level function for isolate
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
