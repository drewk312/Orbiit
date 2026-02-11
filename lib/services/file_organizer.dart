import 'dart:io';
import 'package:path/path.dart' as p;
import 'platform_detector.dart';

/// File organizer service
///
/// Handles:
/// - Creating proper directory structures
/// - Moving/copying files to target locations
/// - Handling naming conventions
/// - Conflict resolution
/// - Batch operations
class FileOrganizer {
  /// Organize a single file
  Future<OrganizeResult> organizeFile({
    required String sourceFile,
    required String targetRoot,
    required GamePlatform platform,
    String? gameId,
    String? title,
    bool moveInsteadOfCopy = false,
    ConflictAction conflictAction = ConflictAction.askUser,
  }) async {
    try {
      final source = File(sourceFile);
      if (!await source.exists()) {
        return OrganizeResult(
          success: false,
          error: 'Source file does not exist',
        );
      }

      // Generate target path
      final targetPath = await _generateTargetPath(
        targetRoot: targetRoot,
        platform: platform,
        gameId: gameId,
        title: title,
        sourceFileName: p.basename(sourceFile),
        sourceExtension: p.extension(sourceFile),
      );

      // Check for conflicts
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        final resolvedPath = await _resolveConflict(
          targetPath: targetPath,
          conflictAction: conflictAction,
        );

        if (resolvedPath == null) {
          return OrganizeResult(
            success: false,
            error: 'File already exists',
            conflictResolution: ConflictAction.skip,
          );
        }

        return await _performFileOperation(
          source: source,
          targetPath: resolvedPath,
          moveInsteadOfCopy: moveInsteadOfCopy,
        );
      }

      // No conflict, proceed
      return await _performFileOperation(
        source: source,
        targetPath: targetPath,
        moveInsteadOfCopy: moveInsteadOfCopy,
      );
    } catch (e) {
      return OrganizeResult(
        success: false,
        error: 'Error: $e',
      );
    }
  }

  /// Organize multiple files in batch
  Future<BatchOrganizeResult> organizeBatch(
    List<FileToOrganize> files,
    String targetRoot, {
    bool moveInsteadOfCopy = false,
    ConflictAction conflictAction = ConflictAction.skip,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <OrganizeResult>[];
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < files.length; i++) {
      final fileInfo = files[i];

      final result = await organizeFile(
        sourceFile: fileInfo.sourcePath,
        targetRoot: targetRoot,
        platform: fileInfo.platform,
        gameId: fileInfo.gameId,
        title: fileInfo.title,
        moveInsteadOfCopy: moveInsteadOfCopy,
        conflictAction: conflictAction,
      );

      results.add(result);

      if (result.success) {
        successCount++;
      } else {
        failCount++;
      }

      onProgress?.call(i + 1, files.length);

      // Small delay to avoid overwhelming filesystem
      if (i < files.length - 1) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return BatchOrganizeResult(
      results: results,
      successCount: successCount,
      failCount: failCount,
      totalCount: files.length,
    );
  }

  // === PATH GENERATION ===

  Future<String> _generateTargetPath({
    required String targetRoot,
    required GamePlatform platform,
    required String sourceFileName,
    required String sourceExtension,
    String? gameId,
    String? title,
  }) async {
    final platformFolder = platform.folderName;
    final platformPath = p.join(targetRoot, platformFolder);

    // Ensure platform directory exists
    await Directory(platformPath).create(recursive: true);

    // Generate filename based on platform
    if (platform == GamePlatform.wii || platform == GamePlatform.gamecube) {
      // Wii/GC: Use folder structure GAMEID_Title/file.ext
      final folderName = _generateWiiGCFolderName(gameId, title);
      final gamePath = p.join(platformPath, folderName);
      await Directory(gamePath).create(recursive: true);

      return p.join(gamePath, sourceFileName);
    } else {
      // Retro platforms: Flat structure with proper naming
      final fileName =
          _generateRetroFileName(title, sourceFileName, sourceExtension);
      return p.join(platformPath, fileName);
    }
  }

  String _generateWiiGCFolderName(String? gameId, String? title) {
    if (gameId != null && title != null) {
      final sanitized = _sanitizeTitle(title);
      return '${gameId}_$sanitized';
    } else if (gameId != null) {
      return gameId;
    } else if (title != null) {
      return _sanitizeTitle(title);
    } else {
      return 'Unknown_Game';
    }
  }

  String _generateRetroFileName(
      String? title, String sourceFileName, String extension) {
    if (title != null) {
      final sanitized = _sanitizeTitle(title);
      return '$sanitized$extension';
    } else {
      return sourceFileName;
    }
  }

  String _sanitizeTitle(String title) {
    return title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Remove invalid chars
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(RegExp(r'_+'), '_') // Collapse multiple underscores
        .replaceAll(RegExp(r'^_|_$'), '') // Remove leading/trailing underscores
        .substring(0, title.length.clamp(0, 80)); // Limit length
  }

  // === CONFLICT RESOLUTION ===

  Future<String?> _resolveConflict({
    required String targetPath,
    required ConflictAction conflictAction,
  }) async {
    switch (conflictAction) {
      case ConflictAction.skip:
        return null;

      case ConflictAction.replace:
        // Delete existing file
        final existing = File(targetPath);
        if (await existing.exists()) {
          await existing.delete();
        }
        return targetPath;

      case ConflictAction.keepBoth:
        // Generate numbered filename
        return _generateNumberedPath(targetPath);

      case ConflictAction.askUser:
        // For now, default to skip (UI will handle prompting)
        return null;
    }
  }

  Future<String> _generateNumberedPath(String basePath) async {
    final dir = p.dirname(basePath);
    final basename = p.basenameWithoutExtension(basePath);
    final ext = p.extension(basePath);

    int counter = 2;
    String testPath;

    do {
      testPath = p.join(dir, '$basename ($counter)$ext');
      counter++;
    } while (await File(testPath).exists() && counter < 100);

    return testPath;
  }

  // === FILE OPERATIONS ===

  Future<OrganizeResult> _performFileOperation({
    required File source,
    required String targetPath,
    required bool moveInsteadOfCopy,
  }) async {
    try {
      if (moveInsteadOfCopy) {
        // Try rename first (faster if same filesystem)
        try {
          await source.rename(targetPath);
        } catch (e) {
          // Cross-filesystem move requires copy + delete
          await source.copy(targetPath);
          await source.delete();
        }
      } else {
        // Copy
        await source.copy(targetPath);
      }

      return OrganizeResult(
        success: true,
        newPath: targetPath,
      );
    } catch (e) {
      return OrganizeResult(
        success: false,
        error: 'Could not ${moveInsteadOfCopy ? "move" : "copy"} file: $e',
      );
    }
  }

  /// Get estimated folder structure preview
  Map<String, List<String>> getStructurePreview(List<FileToOrganize> files) {
    final structure = <String, List<String>>{};

    for (final file in files) {
      final platformFolder = file.platform.folderName;

      if (!structure.containsKey(platformFolder)) {
        structure[platformFolder] = [];
      }

      if (file.platform == GamePlatform.wii ||
          file.platform == GamePlatform.gamecube) {
        final folderName = _generateWiiGCFolderName(file.gameId, file.title);
        structure[platformFolder]!.add('$folderName/');
      } else {
        final fileName = _generateRetroFileName(
          file.title,
          p.basename(file.sourcePath),
          p.extension(file.sourcePath),
        );
        structure[platformFolder]!.add(fileName);
      }
    }

    return structure;
  }
}

// === RESULT CLASSES ===

class OrganizeResult {
  final bool success;
  final String? newPath;
  final String? error;
  final ConflictAction? conflictResolution;

  OrganizeResult({
    required this.success,
    this.newPath,
    this.error,
    this.conflictResolution,
  });

  @override
  String toString() {
    if (success) {
      return 'OrganizeResult(success: true, newPath: $newPath)';
    } else {
      return 'OrganizeResult(success: false, error: $error)';
    }
  }
}

class BatchOrganizeResult {
  final List<OrganizeResult> results;
  final int successCount;
  final int failCount;
  final int totalCount;

  BatchOrganizeResult({
    required this.results,
    required this.successCount,
    required this.failCount,
    required this.totalCount,
  });

  double get successRate => totalCount > 0 ? successCount / totalCount : 0.0;

  @override
  String toString() {
    return 'BatchOrganizeResult($successCount/$totalCount successful, $failCount failed)';
  }
}

class FileToOrganize {
  final String sourcePath;
  final GamePlatform platform;
  final String? gameId;
  final String? title;

  FileToOrganize({
    required this.sourcePath,
    required this.platform,
    this.gameId,
    this.title,
  });
}

enum ConflictAction {
  skip, // Keep existing, skip new
  replace, // Replace existing with new
  keepBoth, // Rename new file with (2), (3), etc.
  askUser, // Prompt user for decision (handled by UI)
}
