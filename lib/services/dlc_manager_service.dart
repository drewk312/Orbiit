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

  // Game Title IDs (Base - without region suffix)
  static const Map<String, String> supportedGames = {
    'Just Dance 2': '00010000534432',
    'Just Dance 3': '00010000534A44',
    'Just Dance 4': '00010000534A58',
    'Just Dance 2014': '00010000534A4F',
    'Just Dance 2015': '00010000534533',
    'Rock Band 2': '00010000535A41',
    'Rock Band 3': '00010000535A42', 
    'The Beatles: Rock Band': '0001000052394A',
    'Green Day: Rock Band': '00010000535A41',
    'Guitar Hero: World Tour': '00010000535841',
    'Guitar Hero 5': '00010000535845',
    'Guitar Hero: Warriors of Rock': '00010000535849',
  };

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

  String calculateTitleId(String gameName, String region) {
    if (!supportedGames.containsKey(gameName)) return '';
    final baseId = supportedGames[gameName]!;
    // Suffix: 45 for US, 50 for EU
    final suffix = (region == 'EU') ? '50' : '45';
    // Rock Band 2 uses base ID + suffix?
    // According to guide: "Rock Band 3 would be 00010000535A4245"
    // So usually just append.
    return '$baseId$suffix';
  }

  /// Organizes the output files from wad2bin to the SD card structure
  /// wad2bin output usually goes to /private/wii/data/... locally or in output dir
  Future<void> installContentToSD(Directory sourceContent, Directory sdRoot) async {
    final privateDir = Directory(path.join(sdRoot.path, 'private'));
    if (!privateDir.existsSync()) privateDir.createSync(recursive: true);
    
    // Copy the 'private' folder from source if exists, or merge
    // Assuming sourceContent IS the folder containing 'private' or the '000...bin' files
    // The guide says: "Make sure that it created a folder with .bin files in a subfolder of /private/wii/data/"
    if (path.basename(sourceContent.path) == 'private') {
      await _copyDirectory(sourceContent, privateDir);
    } else {
      // Try to find 'private' inside source
       final subPrivate = Directory(path.join(sourceContent.path, 'private'));
       if (subPrivate.existsSync()) {
         await _copyDirectory(subPrivate, privateDir);
       }
    }
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    // Standard recursive copy
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(path.join(dest.path, path.basename(entity.path)));
        if (!newDirectory.existsSync()) newDirectory.createSync();
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(path.join(dest.path, path.basename(entity.path)));
      }
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
