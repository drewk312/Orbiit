import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

/// Service for extracting game archives
/// Based on GCBM's extraction features - supports ZIP, 7Z, RAR, BZIP2
class ArchiveExtractionService {
  /// Extract a game archive
  static Future<String?> extractArchive(
    String archivePath,
    String outputDir, {
    Function(int current, int total, String filename)? onProgress,
  }) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      throw Exception('Archive not found: $archivePath');
    }

    final extension = path.extension(archivePath).toLowerCase();

    switch (extension) {
      case '.zip':
        return _extractZip(archivePath, outputDir, onProgress);
      case '.7z':
        return _extract7z(archivePath, outputDir, onProgress);
      case '.rar':
        return _extractRar(archivePath, outputDir, onProgress);
      case '.gz':
      case '.bz2':
        return _extractCompressed(archivePath, outputDir, onProgress);
      default:
        throw Exception('Unsupported archive format: $extension');
    }
  }

  /// Extract ZIP archive
  static Future<String?> _extractZip(
    String archivePath,
    String outputDir,
    Function(int, int, String)? onProgress,
  ) async {
    try {
      final inputStream = InputFileStream(archivePath);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      final dir = Directory(outputDir);
      await dir.create(recursive: true);

      String? gameFilePath;

      for (int i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        onProgress?.call(i + 1, archive.files.length, file.name);

        final outputPath = path.join(outputDir, file.name);

        if (file.isFile) {
          final outputFile = File(outputPath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);

          // Track game file (ISO, WBFS, etc.)
          if (_isGameFile(file.name)) {
            gameFilePath = outputPath;
          }
        } else {
          await Directory(outputPath).create(recursive: true);
        }
      }

      inputStream.close();
      return gameFilePath;
    } catch (e) {
      throw Exception('Failed to extract ZIP: $e');
    }
  }

  /// Extract 7z archive (requires 7z CLI on system)
  static Future<String?> _extract7z(
    String archivePath,
    String outputDir,
    Function(int, int, String)? onProgress,
  ) async {
    // Check if 7z is available
    final result = await Process.run('7z', ['--help']);
    if (result.exitCode != 0) {
      throw Exception('7z not found. Please install 7-Zip.');
    }

    await Directory(outputDir).create(recursive: true);

    final process = await Process.start(
      '7z',
      ['x', archivePath, '-o$outputDir', '-y'],
    );

    await for (final line
        in process.stdout.transform(const SystemEncoding().decoder)) {
      print(line);
      // Parse progress if possible
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('7z extraction failed with code $exitCode');
    }

    return _findGameFile(outputDir);
  }

  /// Extract RAR archive (requires WinRAR or unrar CLI)
  static Future<String?> _extractRar(
    String archivePath,
    String outputDir,
    Function(int, int, String)? onProgress,
  ) async {
    // Try unrar first, then WinRAR
    String command = 'unrar';
    var result = await Process.run(command, ['--help']);

    if (result.exitCode != 0) {
      command = 'WinRAR';
      result = await Process.run(command, ['--help']);
      if (result.exitCode != 0) {
        throw Exception(
            'RAR extraction requires WinRAR or unrar to be installed');
      }
    }

    await Directory(outputDir).create(recursive: true);

    final process = await Process.start(
      command,
      ['x', '-y', archivePath, outputDir],
    );

    await for (final line
        in process.stdout.transform(const SystemEncoding().decoder)) {
      print(line);
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('RAR extraction failed with code $exitCode');
    }

    return _findGameFile(outputDir);
  }

  /// Extract GZ/BZ2 compressed files
  static Future<String?> _extractCompressed(
    String archivePath,
    String outputDir,
    Function(int, int, String)? onProgress,
  ) async {
    try {
      final inputFile = File(archivePath);
      final bytes = await inputFile.readAsBytes();

      List<int> decompressed;
      if (archivePath.endsWith('.gz')) {
        decompressed = GZipDecoder().decodeBytes(bytes);
      } else if (archivePath.endsWith('.bz2')) {
        decompressed = BZip2Decoder().decodeBytes(bytes);
      } else {
        throw Exception('Unsupported compression format');
      }

      await Directory(outputDir).create(recursive: true);

      // Remove compression extension to get output filename
      final String outputFileName = path.basenameWithoutExtension(archivePath);
      if (outputFileName.endsWith('.tar')) {
        // Handle tar.gz / tar.bz2
        final tarArchive = TarDecoder().decodeBytes(decompressed);
        for (final file in tarArchive.files) {
          if (file.isFile) {
            final outputPath = path.join(outputDir, file.name);
            final outputFile = File(outputPath);
            await outputFile.create(recursive: true);
            await outputFile.writeAsBytes(file.content as List<int>);
          }
        }
        return _findGameFile(outputDir);
      } else {
        // Just decompress the single file
        final outputPath = path.join(outputDir, outputFileName);
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(decompressed);
        return _isGameFile(outputFileName) ? outputPath : null;
      }
    } catch (e) {
      throw Exception('Failed to extract compressed file: $e');
    }
  }

  /// Check if a file is a game file
  static bool _isGameFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return [
      '.iso',
      '.wbfs',
      '.gcm',
      '.wia',
      '.rvz',
      '.ciso',
      '.gcz',
      '.tgc',
      '.nfs'
    ].contains(ext);
  }

  /// Find game file in directory
  static String? _findGameFile(String directory) {
    final dir = Directory(directory);
    final files = dir.listSync(recursive: true);

    for (final file in files) {
      if (file is File && _isGameFile(file.path)) {
        return file.path;
      }
    }

    return null;
  }

  /// Get supported archive extensions
  static List<String> getSupportedExtensions() {
    return ['.zip', '.7z', '.rar', '.gz', '.bz2', '.tar.gz', '.tar.bz2'];
  }

  /// Check if file is a supported archive
  static bool isSupportedArchive(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return getSupportedExtensions()
        .any((e) => filename.toLowerCase().endsWith(e));
  }
}
