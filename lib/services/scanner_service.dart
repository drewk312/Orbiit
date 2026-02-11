import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/app_logger.dart';
import '../ffi/forge_bridge.dart';
import '../models/disc_metadata.dart';

/// Scanner Service - Detects game files and reads internal metadata
class ScannerService {
  final ForgeBridge _forge;

  /// Whether the last scan fell back to the Dart scanner because native
  /// scanning returned no results or was unavailable.
  bool lastScanUsedFallback = false;

  ScannerService({ForgeBridge? forge}) : _forge = forge ?? ForgeBridge();

  /// Supported game file extensions
  static const List<String> gameExtensions = [
    '.wbfs',
    '.iso',
    '.rvz',
    '.nkit.iso',
    '.gcm',
    '.ciso',
    // Common compressed / alternate formats
    '.gcz',
    '.iso.gz',
    '.iso.bz2',
    '.iso.xz',
    '.iso.7z',
    '.wbfs.gz',
    '.wbfs.bz2',
    '.7z',
    '.zip',
    '.rar',
    '.7z.001',
  ];

  /// Minimum file size to be considered a valid game (10MB)
  static const int minGameSize = 10 * 1024 * 1024;

  /// Scan a directory for game files
  Future<List<ScannedGame>> scanDirectory(String directoryPath) async {
    final logger = AppLogger.instance;
    logger.info('═══════════════════════════════════════════════════════════');
    logger.info('PHASE 1: Initializing scan for: $directoryPath');
    logger.info('═══════════════════════════════════════════════════════════');

    if (!_forge.isMockMode) {
      final docsDir = await getApplicationDocumentsDirectory();
      logger.info(
          'PHASE 2: Loading native scanner (forge_core.dll) at ${docsDir.path}...');
      final initOk = _forge.init(docsDir.path);
      logger.info('✓ Native library initialized: $initOk');
      if (!initOk) {
        logger.warning(
            'Native forge_init returned false - native scanning may not work');
      }

      logger.info('PHASE 3: Scanning directory for game files...');
      final games = <ScannedGame>[];
      final count =
          _forge.scanFolder(directoryPath, true, (filePath, identity) {
        // Check if size is valid, if not (0), fallback to file system
        int size = identity.fileSize;
        if (size <= 0) {
          try {
            size = File(filePath).lengthSync();
          } catch (e) {
            logger.warning('Could not get file size for $filePath: $e');
          }
        }

        games.add(ScannedGame(
          path: filePath,
          fileName: path.basename(filePath),
          title: identity.gameTitle,
          gameId: identity.titleId,
          platform: identity.platformName,
          sizeBytes: size,
          extension: path.extension(filePath),
        ));
      });

      logger.info('PHASE 4: Scan completed - Found $count games');
      logger
          .info('═══════════════════════════════════════════════════════════');

      // Reset fallback flag; we'll set it to true if we end up performing the
      // Dart fallback scan below.
      lastScanUsedFallback = false;

      // If native scanner found nothing, fall back to the Dart scanner so we still
      // discover games based on filename heuristics like TinyWii does.
      if (games.isEmpty) {
        lastScanUsedFallback = true;
        logger.info(
            '⚠ FALLBACK: Native scanner found nothing - using Dart scanner');
        logger.info('PHASE 3-B: Scanning with fallback Dart implementation...');
        final dir = Directory(directoryPath);
        if (await dir.exists()) {
          try {
            await for (final entity
                in dir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                final ext = _getExtension(entity.path);
                if (gameExtensions.contains(ext)) {
                  final game = await _parseGameFile(entity);
                  if (game != null && game.isValid) {
                    games.add(game);
                  }
                }
              }
            }
          } catch (e) {
            AppLogger.instance
                .error('[Scanner] Error listing directory in fallback: $e');
          }
        }
      }

      // Sort and return
      games.sort((a, b) => a.title.compareTo(b.title));
      return games;
    }

    // Fallback to internal Dart scanner (for mock mode or legacy)
    logger.info(
        'PHASE 2-ALT: Using Dart scanner (mock mode - no native library)');
    logger.info('PHASE 3: Scanning directory recursively...');
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      logger.error('Directory does not exist: $directoryPath');
      throw Exception('Directory does not exist: $directoryPath');
    }

    final games = <ScannedGame>[];

    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = _getExtension(entity.path);
          if (gameExtensions.contains(ext)) {
            final game = await _parseGameFile(entity);
            if (game != null && game.isValid) {
              games.add(game);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error('[Scanner] Error listing directory: $e');
    }

    // Sort by title
    games.sort((a, b) => a.title.compareTo(b.title));
    return games;
  }

  String _getExtension(String filePath) {
    final lower = filePath.toLowerCase();
    // Special-case multi-suffix extensions
    if (lower.endsWith('.nkit.iso')) return '.nkit.iso';
    if (lower.endsWith('.iso.gz')) return '.iso.gz';
    if (lower.endsWith('.iso.bz2')) return '.iso.bz2';
    if (lower.endsWith('.iso.xz')) return '.iso.xz';
    if (lower.endsWith('.iso.7z')) return '.iso.7z';
    if (lower.endsWith('.gcz.7z')) return '.gcz.7z';
    if (lower.endsWith('.wbfs.gz')) return '.wbfs.gz';
    if (lower.endsWith('.wbfs.bz2')) return '.wbfs.bz2';
    if (lower.endsWith('.7z.001')) return '.7z.001';
    return path.extension(lower);
  }

  Future<ScannedGame?> _parseGameFile(File file) async {
    try {
      final stat = await file.stat();
      final ext = _getExtension(file.path);

      // Skip tiny files (likely corrupt or placeholder)
      if (stat.size < minGameSize) {
        return null;
      }

      String? gameId;
      String? internalTitle;
      String platform = 'Unknown';
      int discNumber = 0;
      int discVersion = 0;

      // Try to read internal header for game ID and title
      try {
        final headerInfo = await _readDiscHeader(file, ext);
        gameId = headerInfo['gameId'];
        internalTitle = headerInfo['title'];
        if (headerInfo['platform'] != null) {
          platform = headerInfo['platform']!;
        }
        if (headerInfo['discNumber'] != null) {
          discNumber = headerInfo['discNumber'] as int;
        }
        if (headerInfo['discVersion'] != null) {
          discVersion = headerInfo['discVersion'] as int;
        }

        if (headerInfo['magicValid'] == false &&
            internalTitle != null &&
            _isJunkTitle(internalTitle)) {
          AppLogger.instance.warning(
              '[Scanner] Skipping file with invalid magic and junk title: ${file.path}');
          return null;
        }
      } catch (e) {
        AppLogger.instance
            .warning('[Scanner] Could not read header: ${file.path} - $e');
      }

      // Validate title - skip if it looks like HTML/junk
      if (internalTitle != null && _isJunkTitle(internalTitle)) {
        return null;
      }

      // Get filename info
      final fileName = path.basenameWithoutExtension(file.path);
      final parentDir = path.basename(path.dirname(file.path));

      // Try to extract game ID from filename if not from header
      gameId ??= _extractGameIdFromName(fileName);
      gameId ??= _extractGameIdFromName(parentDir);

      // Determine title (priority: internal > parent folder > filename)
      String title = internalTitle ?? '';
      if (title.isEmpty || title == gameId) {
        final parentTitle = _extractTitleFromName(parentDir, gameId);
        if (parentTitle.isNotEmpty && !_isNumericOnly(parentTitle)) {
          title = parentTitle;
        }
      }
      if (title.isEmpty || _isNumericOnly(title)) {
        final fileTitle = _extractTitleFromName(fileName, gameId);
        if (fileTitle.isNotEmpty && !_isNumericOnly(fileTitle)) {
          title = fileTitle;
        }
      }
      if (title.isEmpty || _isNumericOnly(title)) {
        title = gameId ?? fileName;
      }

      // Final junk check on title
      if (_isJunkTitle(title)) return null;

      // Detect platform from game ID if not from header
      if (platform == 'Unknown' && gameId != null) {
        platform = _detectPlatformFromId(gameId);
      }

      // Detect format from extension
      final format = _detectFormat(ext);

      return ScannedGame(
        path: file.path,
        fileName: path.basename(file.path),
        title: title,
        gameId: gameId,
        platform: platform,
        sizeBytes: stat.size,
        extension: ext,
        discNumber: discNumber,
        discVersion: discVersion,
        format: format,
        compression: _detectCompression(ext),
        isLossless: format != DiscFormat.rvz, // RVZ can be lossy
      );
    } catch (e) {
      AppLogger.instance
          .error('[Scanner] Error parsing file: ${file.path} - $e');
      return null;
    }
  }

  /// Detect disc format from extension
  DiscFormat _detectFormat(String ext) {
    final e = ext.toLowerCase();
    if (e.contains('wbfs')) return DiscFormat.wbfs;
    if (e.contains('rvz')) return DiscFormat.rvz;
    if (e.contains('gcz')) return DiscFormat.gcz;
    if (e.contains('ciso')) return DiscFormat.ciso;
    if (e.contains('nkit')) return DiscFormat.nkit;
    if (e.contains('iso')) return DiscFormat.iso;
    return DiscFormat.unknown;
  }

  /// Detect compression from extension
  CompressionType _detectCompression(String ext) {
    final e = ext.toLowerCase();
    if (e.contains('.gz')) return CompressionType.zlib;
    if (e.contains('.bz2')) return CompressionType.bzip2;
    if (e.contains('.xz') || e.contains('.lzma')) return CompressionType.lzma;
    if (e.contains('rvz') || e.contains('gcz')) return CompressionType.zstd;
    return CompressionType.none;
  }

  /// Check if title contains HTML or junk characters
  bool _isJunkTitle(String title) {
    final lower = title.toLowerCase();
    return lower.contains('<!doc') ||
        lower.contains('<html') ||
        lower.contains('<meta') ||
        lower.contains('charset') ||
        lower.contains('http-equiv') ||
        lower.contains('<head') ||
        lower.contains('href=') ||
        title.contains('\x00\x00\x00') ||
        title.length < 2;
  }

  /// Read game ID and title from disc header
  Future<Map<String, dynamic>> _readDiscHeader(File file, String ext) async {
    final raf = await file.open();
    try {
      List<int> header;
      bool magicValid = false;

      if (ext == '.wbfs') {
        // WBFS header: check for magic 'WBFS'
        await raf.setPosition(0);
        final wbfsMagic = await raf.read(4);
        if (wbfsMagic.length == 4 &&
            wbfsMagic[0] == 0x57 &&
            wbfsMagic[1] == 0x42 &&
            wbfsMagic[2] == 0x46 &&
            wbfsMagic[3] == 0x53) {
          await raf.setPosition(8);
          final wbfsHeaderData = await raf.read(4);
          final sectorSizeShift = wbfsHeaderData[0];
          final sectorSize = 1 << sectorSizeShift;
          await raf.setPosition(sectorSize);
          header = await raf.read(0x60);
          magicValid = true;
        } else {
          return {
            'gameId': null,
            'title': null,
            'platform': null,
            'magicValid': false
          };
        }
      } else {
        await raf.setPosition(0);
        header = await raf.read(0x60);

        // Wii/GC magic at 0x1C: 5D 1C 9E A3
        if (header.length >= 0x20) {
          final magic = (header[0x1C] << 24) |
              (header[0x1D] << 16) |
              (header[0x1E] << 8) |
              header[0x1F];
          if (magic == 0x5D1C9EA3) {
            magicValid = true;
          }
        }
      }

      if (header.length < 0x60) {
        return {
          'gameId': null,
          'title': null,
          'platform': null,
          'magicValid': magicValid
        };
      }

      // Game ID at offset 0x00, 6 bytes
      final gameId = String.fromCharCodes(header.sublist(0, 6))
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '');

      // Title at offset 0x20, up to 64 bytes (null-terminated)
      final titleBytes = header.sublist(0x20, 0x60);
      final nullIndex = titleBytes.indexOf(0);
      final titleEnd = nullIndex > 0 ? nullIndex : titleBytes.length;
      final title = String.fromCharCodes(titleBytes.sublist(0, titleEnd))
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
          .trim();

      String? platform;
      if (magicValid) {
        platform = _detectPlatformFromId(gameId);
      }

      // Disc number at offset 0x06
      final discNumber = header.length > 6 ? header[6] : 0;
      // Disc version at offset 0x07
      final discVersion = header.length > 7 ? header[7] : 0;

      return {
        'gameId': gameId.length == 6 ? gameId : null,
        'title': title.isNotEmpty ? title : null,
        'platform': platform,
        'magicValid': magicValid,
        'discNumber': discNumber,
        'discVersion': discVersion,
      };
    } finally {
      await raf.close();
    }
  }

  bool _isNumericOnly(String s) {
    return s.trim().isEmpty || RegExp(r'^\d+$').hasMatch(s.trim());
  }

  String? _extractGameIdFromName(String name) {
    final bracketMatch = RegExp(r'[\[\(]([A-Z0-9]{6})[\]\)]').firstMatch(name);
    if (bracketMatch != null) return bracketMatch.group(1);

    final startMatch = RegExp(r'^([A-Z][A-Z0-9]{5})\b').firstMatch(name);
    if (startMatch != null) return startMatch.group(1);

    return null;
  }

  String _extractTitleFromName(String name, String? gameId) {
    String title = name;
    title = title.replaceAll(RegExp(r'[\[\(][A-Z0-9]{6}[\]\)]'), '');
    title = title.replaceAll(RegExp(r'^[A-Z][A-Z0-9]{5}\s*[-_]?\s*'), '');
    title = title.replaceAll(RegExp(r'[-_]+'), ' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ');
    return title.trim();
  }

  String _detectPlatformFromId(String gameId) {
    if (gameId.isEmpty) return 'Unknown';

    final prefix = gameId[0];
    switch (prefix) {
      case 'R':
      case 'S':
      case 'W':
        return 'Wii';
      case 'G':
      case 'D':
      case 'P':
        return 'GameCube';
      default:
        return 'Unknown';
    }
  }

  Future<int> calculateHealth(ScannedGame game) async {
    final file = File(game.path);
    if (!await file.exists()) {
      game.status = GameHealthStatus.corrupt;
      return 0;
    }

    final stat = await file.stat();
    if (stat.size == 0) {
      game.status = GameHealthStatus.corrupt;
      return 0;
    }

    int health = 50;
    if (game.gameId != null && game.gameId!.isNotEmpty) {
      health += 25;
    }

    final minSize =
        game.platform == 'Wii' ? 100 * 1024 * 1024 : 50 * 1024 * 1024;

    // Status Logic
    if (stat.size < minSize) {
      // Too small implies potential corruption or partial file
      game.status = GameHealthStatus.corrupt;
    } else if (game.gameId == null || game.gameId!.isEmpty) {
      // Valid size but missing ID -> Needs fixes (NKit / Header issue)
      game.status = GameHealthStatus.needsFix;
      health = 75;
    } else {
      // Good size and ID -> Ready
      game.status = GameHealthStatus.ready;
      health += 25;
    }

    return health.clamp(0, 100);
  }

  /// Diagnostic scan - returns a list of human readable diagnostics for files in the directory
  Future<List<String>> scanDirectoryDiagnostic(String directoryPath,
      {int maxEntries = 1000}) async {
    final logger = AppLogger.instance;
    logger.info('Starting diagnostic scan: $directoryPath');

    final diagnostics = <String>[];

    // Attempt native scan to know which files the native scanner would claim
    final nativeFound = <String>{};
    try {
      final initOk = _forge.init();
      diagnostics.add('Native forge_init: $initOk');
      if (!initOk) {
        diagnostics.add(
            'Warning: Native forge_init returned false - native scanner may be unavailable');
      }

      final count =
          _forge.scanFolder(directoryPath, true, (filePath, identity) {
        nativeFound.add(filePath);
      });
      diagnostics.add('Native scan completed. Found $count games');
    } catch (e) {
      diagnostics.add('Native scan error: $e');
    }

    // Walk files and produce diagnostics
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      diagnostics.add('Directory does not exist: $directoryPath');
      return diagnostics;
    }

    int inspected = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (inspected >= maxEntries) {
          diagnostics.add('Max entries reached ($maxEntries), stopping');
          break;
        }
        if (entity is File) {
          inspected++;
          final filePath = entity.path;
          final ext = _getExtension(filePath);
          final stat = await entity.stat();

          final buffer = StringBuffer();
          buffer.write('FILE: $filePath | ');
          final sizeBytes = stat.size;
          buffer.write('EXT: $ext | SIZE: $sizeBytes bytes | ');

          if (!gameExtensions.contains(ext)) {
            buffer.write('SKIP: unsupported extension');
            diagnostics.add(buffer.toString());
            continue;
          }

          if (stat.size < minGameSize) {
            buffer.write('SKIP: too small (< $minGameSize bytes)');
            diagnostics.add(buffer.toString());
            continue;
          }

          // Try read header
          try {
            final header = await _readDiscHeader(entity, ext);
            final magic = header['magicValid'];
            final titleStr = header['title'] ?? '<none>';
            final gid = header['gameId'] ?? '<none>';
            buffer.write('HEADER_MAGIC: $magic | ');
            buffer.write('TITLE: $titleStr | ');
            buffer.write('GAMEID: $gid | ');

            if (nativeFound.contains(filePath)) {
              buffer.write('NATIVE: found');
            } else {
              buffer.write('NATIVE: not-found');
            }

            diagnostics.add(buffer.toString());
          } catch (e) {
            buffer.write('ERROR reading header: $e');
            diagnostics.add(buffer.toString());
          }
        }
      }
    } catch (e) {
      diagnostics.add('Error while listing files: $e');
    }

    diagnostics.add('Diagnostic completed. Inspected: $inspected files');
    return diagnostics;
  }

  /// Delete a game file
  Future<bool> deleteGame(ScannedGame game) async {
    try {
      final file = File(game.path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.error('[Scanner] Error deleting file: $e');
      return false;
    }
  }
}

/// Health status of a game file
enum GameHealthStatus {
  ready, // Healthy, playable
  needsFix, // Minor issues (wrong name, missing ID)
  corrupt, // Major issues (too small, invalid header)
  unknown, // Not scanned yet
}

/// Represents a scanned game file
class ScannedGame {
  final String path;
  final String fileName;
  final String title;
  final String? gameId;
  final String platform;
  final int sizeBytes;
  final String extension;
  int health;
  bool verified;
  GameHealthStatus status;

  // Extended metadata for premium info panel
  final int discNumber;
  final int discVersion;
  final DiscFormat format;
  final CompressionType compression;
  final int? blockSize;
  final bool isDecrypted;
  final bool needsHashRecovery;
  final bool isLossless;
  final int? discSize;

  ScannedGame({
    required this.path,
    required this.fileName,
    required this.title,
    required this.platform,
    required this.sizeBytes,
    required this.extension,
    this.gameId,
    this.health = 0,
    this.verified = false,
    this.status = GameHealthStatus.unknown,
    this.discNumber = 0,
    this.discVersion = 0,
    this.format = DiscFormat.unknown,
    this.compression = CompressionType.none,
    this.blockSize,
    this.isDecrypted = false,
    this.needsHashRecovery = false,
    this.isLossless = true,
    this.discSize,
  });

  /// Create ScannedGame from Map (for JSON deserialization)
  factory ScannedGame.fromMap(Map<String, dynamic> map) {
    return ScannedGame(
      path: map['path'],
      fileName: map['fileName'],
      title: map['title'],
      gameId: map['gameId'],
      platform: map['platform'],
      sizeBytes: map['sizeBytes'],
      extension: map['extension'],
      health: map['health'] ?? 100,
      verified: map['verified'] ?? true,
    );
  }

  /// Convert to Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'fileName': fileName,
      'title': title,
      'gameId': gameId,
      'platform': platform,
      'sizeBytes': sizeBytes,
      'extension': extension,
      'health': health,
      'verified': verified,
    };
  }

  /// Get region from game ID (4th character)
  String? get region {
    if (gameId == null || gameId!.length < 4) return null;
    final regionCode = gameId![3];
    switch (regionCode) {
      case 'E':
        return 'US';
      case 'P':
        return 'EN';
      case 'J':
        return 'JA';
      case 'K':
        return 'KO';
      default:
        return 'US'; // Default to US
    }
  }

  /// Check if this is a valid game (not junk)
  bool get isValid {
    return sizeBytes >= ScannerService.minGameSize &&
        !title.contains('<') &&
        !title.contains('>') &&
        title.isNotEmpty;
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get displayGameId => gameId ?? 'UNKNOWN';

  /// Convert to full DiscMetadata for premium info panel
  DiscMetadata toDiscMetadata() {
    return DiscMetadata.fromScannedGame(
      path: path,
      fileName: fileName,
      title: title,
      gameId: gameId,
      platform: platform,
      sizeBytes: sizeBytes,
      extension: extension,
    ).copyWith(
      discNumber: discNumber,
      discVersion: discVersion,
      format: format,
      compression: compression,
      blockSize: blockSize,
      isDecrypted: isDecrypted,
      needsHashRecovery: needsHashRecovery,
      isLossless: isLossless,
      discSize: discSize,
    );
  }
}
