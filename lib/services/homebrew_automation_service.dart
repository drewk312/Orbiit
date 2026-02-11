import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/game_result.dart';

/// Comprehensive service for managing Homebrew installation and updates
class HomebrewAutomationService {
  static final HomebrewAutomationService _instance =
      HomebrewAutomationService._internal();
  factory HomebrewAutomationService() => _instance;
  HomebrewAutomationService._internal();

  /// Batch installs a list of recommended apps
  Future<void> installBatch({
    required List<GameResult> games,
    required Directory sdCardRoot,
    required Function(String currentTask, double progress) onStatus,
  }) async {
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final stepPrefix = '[${i + 1}/${games.length}]';

      try {
        await installToSD(
          game: game,
          sdCardRoot: sdCardRoot,
          onProgress: (p) {
            // Sub-progress within the batch item
            final globalProgress = (i + p) / games.length;
            onStatus('$stepPrefix Installing ${game.title}...', globalProgress);
          },
          onStatus: (msg) {
            onStatus('$stepPrefix $msg', i / games.length);
          },
        );
      } catch (e) {
        developer.log('Failed to install ${game.title}', error: e);
        // Continue to verify other apps even if one fails
        onStatus('Skipping ${game.title} (Error: $e)', (i + 1) / games.length);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Installs a single homebrew app to the SD card
  Future<void> installToSD({
    required GameResult game,
    required Directory sdCardRoot,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    if (game.downloadUrl == null) {
      throw Exception('No download URL available for ${game.title}');
    }

    final tempDir = await getTemporaryDirectory();
    final downloadDir =
        await Directory(path.join(tempDir.path, 'hb_dl_${game.title.hashCode}'))
            .create(recursive: true);
    final zipFile = File(path.join(downloadDir.path, 'package.zip'));

    // Sometimes archives don't have a top level folder, creating mess.
    // We extract to a specific folder first.
    final extractDir = Directory(path.join(downloadDir.path, 'extracted'));

    try {
      // 1. Download
      onStatus('Downloading ${game.title}...');
      await _downloadFile(
          game.downloadUrl!, zipFile, (p) => onProgress(p * 0.4));

      // 2. Extract
      onStatus('Extracting content...');
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      extractDir.createSync();

      // Use compute/isolate for heavy extraction if possible, or just standard
      // For now, synchronous archive_io is reliable but blocking.
      // Wrapping in Future to allow UI updates if loop allows (it won't really yield event loop in sync code though).
      await extractFileToDisk(zipFile.path, extractDir.path);
      onProgress(0.7);

      // 3. Smart Install
      onStatus('Installing to SD Card...');
      await _smartMergeToSD(extractDir, sdCardRoot, game.slug ?? 'unknown_app');

      onStatus('Refining setup...');
      onProgress(1);
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

  /// Consolidates extraction logic to ensure files end up in SD:/apps/{slug}/
  /// or SD:/{root}/ if strictly defined structure.
  Future<void> _smartMergeToSD(
      Directory source, Directory sdRoot, String appSlug) async {
    // Structure Detection:
    // 1. Does it have an 'apps' folder? -> Merge logic.
    // 2. Is it a loose 'boot.dol' + 'icon.png'? -> Wrap in 'apps/{slug}'.
    // 3. Is it a folder named '{slug}'? -> Move to 'apps/'.

    final appsDir = Directory(path.join(sdRoot.path, 'apps'));
    if (!appsDir.existsSync()) appsDir.createSync();

    final contents = source.listSync();

    // Case 1: Root contains 'apps' folder (Standard HBC format) or 'wiiu' folder (Wii U format)
    final bool hasAppsFolder =
        contents.any((e) => path.basename(e.path).toLowerCase() == 'apps');
    final bool hasWiiUFolder =
        contents.any((e) => path.basename(e.path).toLowerCase() == 'wiiu');

    if (hasAppsFolder || hasWiiUFolder) {
      // Merge blindly as the structure is likely correct (SD root style)
      await _copyDirectory(source, sdRoot);
      return;
    }

    // Case 2: Root looks like an app folder itself (contains boot.dol/elf or meta.xml)
    final bool isAppRoot = contents.any((e) {
      final name = path.basename(e.path).toLowerCase();
      return name == 'boot.dol' || name == 'boot.elf' || name == 'meta.xml';
    });

    if (isAppRoot) {
      // It's the app content itself. Move to apps/{slug}/
      final targetDir = Directory(path.join(appsDir.path, appSlug));
      if (!targetDir.existsSync()) targetDir.createSync();
      await _copyDirectory(source, targetDir);
      return;
    }

    // Case 3: It's a folder (likely the app name) containing the app
    // e.g. /extracted/USBLoaderGX/boot.dol
    if (contents.length == 1 && contents.first is Directory) {
      // Recurse down one level and try again
      final subDir = contents.first as Directory;
      // If the subdir is named 'apps', we recurse to merge logic
      if (path.basename(subDir.path).toLowerCase() == 'apps') {
        await _copyDirectory(subDir, appsDir);
        return;
      }

      // If the subdir seems to be the app itself, check inside
      final subContents = subDir.listSync();
      final bool subIsApp = subContents.any((e) {
        final name = path.basename(e.path).toLowerCase();
        return name == 'boot.dol' || name == 'boot.elf';
      });

      if (subIsApp) {
        // We'll trust this folder is the app folder.
        // We move it to apps/. WE keep the folder name provided by the zip usually,
        // to avoid breaking internal paths, unless we really want {slug}.
        // Let's use the zip's folder name for compatibility.
        final folderName = path.basename(subDir.path);
        final targetDir = Directory(path.join(appsDir.path, folderName));
        if (!targetDir.existsSync()) targetDir.createSync();
        await _copyDirectory(subDir, targetDir);
        return;
      }
    }

    // Fallback: Just dump it into apps/{slug} and hope for the best if we can't figure it out.
    // This handles unstructured zips.
    final targetDir = Directory(path.join(appsDir.path, appSlug));
    if (!targetDir.existsSync()) targetDir.createSync();
    await _copyDirectory(source, targetDir);
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    // standard recursive copy
    await for (final entity in source.list()) {
      if (entity is Directory) {
        final newDirectory =
            Directory(path.join(dest.path, path.basename(entity.path)));
        if (!newDirectory.existsSync()) newDirectory.createSync();
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final name = path.basename(entity.path);
        if (name.startsWith('.') || name == 'Thumbs.db') continue;

        await entity.copy(path.join(dest.path, name));
      }
    }
  }
}
