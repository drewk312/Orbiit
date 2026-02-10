import 'dart:io';
import 'package:path/path.dart' as path;
import '../../globals.dart';

/// Service for splitting large files for FAT32 compatibility
/// FAT32 has a 4GB file size limit (4,294,967,295 bytes)
/// Based on TinyWii's split functionality
class FileSplitterService {
  // FAT32 max file size: 4GB - 32KB for safety
  static const int maxChunkSize = 4294934528; // 4GB - 32KB

  /// Split a large file into FAT32-compatible chunks
  /// Returns list of created chunk file paths
  static Future<List<String>> splitFile(
    String inputPath, {
    String? outputDir,
    void Function(int current, int total)? onProgress,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $inputPath');
    }

    final fileSize = await inputFile.length();

    // No need to split if under 4GB
    if (fileSize <= maxChunkSize) {
      AppLogger.info('File is under 4GB, no splitting needed', 'FileSplitter');
      return [inputPath];
    }

    final dir = outputDir ?? path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final ext = path.extension(inputPath);

    // Calculate number of chunks
    final numChunks = (fileSize / maxChunkSize).ceil();
    final chunkPaths = <String>[];

    AppLogger.info('Splitting ${fileSize} bytes into $numChunks chunks...',
        'FileSplitter');

    final inputStream = inputFile.openRead();
    int chunkIndex = 0;
    int totalBytesRead = 0;

    await for (final chunk in inputStream) {
      // Determine chunk filename (.part1, .part2, etc.)
      final chunkPath = path.join(
        dir,
        '$baseName.part${chunkIndex + 1}$ext',
      );

      final chunkFile = File(chunkPath);
      final sink = chunkFile.openWrite(mode: FileMode.append);

      sink.add(chunk);
      totalBytesRead += chunk.length;

      // Move to next chunk if we've reached max size
      if (totalBytesRead >= maxChunkSize * (chunkIndex + 1)) {
        await sink.flush();
        await sink.close();
        chunkPaths.add(chunkPath);
        chunkIndex++;

        onProgress?.call(chunkIndex, numChunks);
      }
    }

    // Close final chunk
    if (chunkPaths.length < numChunks) {
      final lastChunkPath = path.join(
        dir,
        '$baseName.part${chunkIndex + 1}$ext',
      );
      chunkPaths.add(lastChunkPath);
    }

    onProgress?.call(numChunks, numChunks);

    AppLogger.info(
        'Split complete: ${chunkPaths.length} parts created', 'FileSplitter');
    return chunkPaths;
  }

  /// Join split files back into original
  static Future<String> joinFiles(
    List<String> chunkPaths,
    String outputPath, {
    void Function(int current, int total)? onProgress,
  }) async {
    final outputFile = File(outputPath);
    final sink = outputFile.openWrite();

    for (int i = 0; i < chunkPaths.length; i++) {
      final chunkFile = File(chunkPaths[i]);

      if (!await chunkFile.exists()) {
        throw Exception('Chunk file not found: ${chunkPaths[i]}');
      }

      final bytes = await chunkFile.readAsBytes();
      sink.add(bytes);

      onProgress?.call(i + 1, chunkPaths.length);
    }

    await sink.flush();
    await sink.close();

    AppLogger.info('Join complete: $outputPath', 'FileSplitter');
    return outputPath;
  }

  /// Auto-detect split files for a given game
  /// Returns list of part files in correct order
  static Future<List<String>> detectSplitFiles(String basePath) async {
    final dir = path.dirname(basePath);
    final baseName = path.basenameWithoutExtension(basePath);
    final ext = path.extension(basePath);

    final parts = <String>[];
    int partNum = 1;

    while (true) {
      final partPath = path.join(dir, '$baseName.part$partNum$ext');
      final partFile = File(partPath);

      if (await partFile.exists()) {
        parts.add(partPath);
        partNum++;
      } else {
        break;
      }
    }

    return parts;
  }

  /// Check if a file needs splitting for FAT32
  static Future<bool> needsSplitting(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final size = await file.length();
    return size > maxChunkSize;
  }

  /// Delete split parts
  static Future<void> deleteSplitParts(List<String> partPaths) async {
    for (final partPath in partPaths) {
      final file = File(partPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
