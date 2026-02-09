import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Platform detector using magic bytes and file analysis
///
/// Detects game platform by:
/// 1. Reading file magic bytes/headers
/// 2. Analyzing file extension
/// 3. Checking file size heuristics
/// 4. Extracting game IDs from headers
class PlatformDetector {
  /// Detect platform from file
  Future<DetectionResult> detectPlatform(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return DetectionResult.unknown('File does not exist');
    }

    final fileSize = await file.length();
    final extension = p.extension(filePath).toLowerCase();

    // Read first 512 bytes for magic byte analysis
    final bytes = await _readFileHeader(file, 512);

    // Try magic byte detection first (most reliable)
    final magicResult = await _detectByMagicBytes(bytes, filePath);
    if (magicResult != null && magicResult.confidence > 0.8) {
      return magicResult;
    }

    // Try extension-based detection
    final extResult = _detectByExtension(extension, fileSize);
    if (extResult != null && extResult.confidence > 0.6) {
      // Enhance with magic byte data if available
      return extResult;
    }

    // Fallback to size heuristics
    final sizeResult = _detectBySize(fileSize, extension);
    if (sizeResult != null) {
      return sizeResult;
    }

    return DetectionResult.unknown('Could not determine platform');
  }

  /// Extract game ID from file based on platform
  Future<String?> extractGameId(String filePath, GamePlatform platform) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final bytes = await _readFileHeader(file, 512);

      switch (platform) {
        case GamePlatform.wii:
        case GamePlatform.gamecube:
          return _extractWiiGCGameId(bytes);

        case GamePlatform.gba:
          return _extractGBAGameCode(bytes);

        case GamePlatform.n64:
          return _extractN64GameCode(bytes);

        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  // === MAGIC BYTE DETECTION ===

  Future<DetectionResult?> _detectByMagicBytes(
    Uint8List bytes,
    String filePath,
  ) async {
    if (bytes.length < 32) return null;

    // Check WBFS header
    if (bytes.length >= 4 &&
        bytes[0] == 0x57 && // 'W'
        bytes[1] == 0x42 && // 'B'
        bytes[2] == 0x46 && // 'F'
        bytes[3] == 0x53) {
      // 'S'
      final gameId = await _extractWiiGCGameId(bytes);
      return DetectionResult(
        platform: GamePlatform.wii,
        confidence: 1.0,
        gameId: gameId,
        method: 'magic_bytes_wbfs',
      );
    }

    // Check RVZ header
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 && // 'R'
        bytes[1] == 0x56 && // 'V'
        bytes[2] == 0x5A && // 'Z'
        bytes[3] == 0x01) {
      // Need to check game ID to determine Wii vs GC
      final gameId = await _extractWiiGCGameId(bytes);
      final platform = gameId != null && gameId[0] == 'R'
          ? GamePlatform.wii
          : GamePlatform.gamecube;

      return DetectionResult(
        platform: platform,
        confidence: 0.95,
        gameId: gameId,
        method: 'magic_bytes_rvz',
      );
    }

    // Check Wii/GC ISO by game ID at offset 0x00
    if (bytes.length >= 6) {
      final gameId = _extractWiiGCGameId(bytes);
      if (gameId != null && gameId.length == 6) {
        final firstChar = gameId[0];

        // Wii games typically start with R, S, or D
        if (['R', 'S', 'D', 'W'].contains(firstChar)) {
          return DetectionResult(
            platform: GamePlatform.wii,
            confidence: 0.9,
            gameId: gameId,
            method: 'magic_bytes_iso_gameid',
          );
        }

        // GameCube games typically start with G
        if (firstChar == 'G') {
          return DetectionResult(
            platform: GamePlatform.gamecube,
            confidence: 0.9,
            gameId: gameId,
            method: 'magic_bytes_iso_gameid',
          );
        }
      }
    }

    // Check GBA ROM signature
    if (bytes.length >= 0xB0) {
      // GBA has Nintendo logo at 0x04, and specific boot code at 0x00
      if (bytes[0x00] == 0x00 &&
          bytes[0x01] == 0x00 &&
          bytes[0x02] == 0x00 &&
          bytes[0x03] == 0xEA) {
        final gameCode = _extractGBAGameCode(bytes);
        return DetectionResult(
          platform: GamePlatform.gba,
          confidence: 1.0,
          gameId: gameCode,
          method: 'magic_bytes_gba',
        );
      }
    }

    // Check N64 ROM (big-endian header)
    if (bytes.length >= 4) {
      if ((bytes[0] == 0x80 &&
              bytes[1] == 0x37 &&
              bytes[2] == 0x12 &&
              bytes[3] == 0x40) ||
          (bytes[0] == 0x40 &&
              bytes[1] == 0x12 &&
              bytes[2] == 0x37 &&
              bytes[3] == 0x80)) {
        return DetectionResult(
          platform: GamePlatform.n64,
          confidence: 1.0,
          method: 'magic_bytes_n64',
        );
      }
    }

    return null;
  }

  // === EXTENSION-BASED DETECTION ===

  DetectionResult? _detectByExtension(String extension, int fileSize) {
    switch (extension) {
      case '.wbfs':
        return DetectionResult(
          platform: GamePlatform.wii,
          confidence: 1.0,
          method: 'file_extension',
        );

      case '.rvz':
        // RVZ can be Wii or GC, use size as hint
        final platform = fileSize > 1.5 * 1024 * 1024 * 1024
            ? GamePlatform.wii
            : GamePlatform.gamecube;
        return DetectionResult(
          platform: platform,
          confidence: 0.7,
          method: 'file_extension',
        );

      case '.iso':
        // ISO is ambiguous, use size heuristics
        if (fileSize > 8.5 * 1024 * 1024 * 1024) {
          return DetectionResult(
            platform: GamePlatform.wiiu,
            confidence: 0.6,
            method: 'file_extension_size',
          );
        } else if (fileSize > 1.5 * 1024 * 1024 * 1024) {
          return DetectionResult(
            platform: GamePlatform.wii,
            confidence: 0.6,
            method: 'file_extension_size',
          );
        } else if (fileSize > 100 * 1024 * 1024) {
          return DetectionResult(
            platform: GamePlatform.gamecube,
            confidence: 0.6,
            method: 'file_extension_size',
          );
        }
        return null;

      case '.gba':
        return DetectionResult(
          platform: GamePlatform.gba,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.gbc':
        return DetectionResult(
          platform: GamePlatform.gbc,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.gb':
        return DetectionResult(
          platform: GamePlatform.gameboy,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.z64':
      case '.n64':
      case '.v64':
        return DetectionResult(
          platform: GamePlatform.n64,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.sfc':
      case '.smc':
        return DetectionResult(
          platform: GamePlatform.snes,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.nes':
        return DetectionResult(
          platform: GamePlatform.nes,
          confidence: 0.95,
          method: 'file_extension',
        );

      case '.gen':
      case '.md':
      case '.smd':
        return DetectionResult(
          platform: GamePlatform.genesis,
          confidence: 0.95,
          method: 'file_extension',
        );

      default:
        return null;
    }
  }

  // === SIZE-BASED DETECTION ===

  DetectionResult? _detectBySize(int fileSize, String extension) {
    // Use broad categories
    if (fileSize < 100 * 1024 * 1024) {
      // < 100 MB - likely handheld
      return DetectionResult(
        platform: GamePlatform.gba, // Default guess
        confidence: 0.3,
        method: 'file_size_heuristic',
      );
    } else if (fileSize < 1.5 * 1024 * 1024 * 1024) {
      // 100 MB - 1.5 GB - likely GameCube
      return DetectionResult(
        platform: GamePlatform.gamecube,
        confidence: 0.4,
        method: 'file_size_heuristic',
      );
    } else if (fileSize < 8.5 * 1024 * 1024 * 1024) {
      // 1.5 GB - 8.5 GB - likely Wii
      return DetectionResult(
        platform: GamePlatform.wii,
        confidence: 0.4,
        method: 'file_size_heuristic',
      );
    }

    return null;
  }

  // === GAME ID EXTRACTION ===

  String? _extractWiiGCGameId(Uint8List bytes) {
    if (bytes.length < 6) return null;

    try {
      // Game ID is at offset 0x00 for ISO
      // Format: XXXXYZ (6 characters)
      final gameId = String.fromCharCodes(bytes.sublist(0, 6));

      // Validate: should be alphanumeric
      if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(gameId)) {
        return gameId;
      }
    } catch (e) {
      // Invalid characters
    }

    return null;
  }

  String? _extractGBAGameCode(Uint8List bytes) {
    if (bytes.length < 0xB0) return null;

    try {
      // Game code is at offset 0xAC (4 bytes)
      final gameCode = String.fromCharCodes(bytes.sublist(0xAC, 0xB0));

      if (RegExp(r'^[A-Z0-9]{4}$').hasMatch(gameCode)) {
        return gameCode;
      }
    } catch (e) {
      // Invalid
    }

    return null;
  }

  String? _extractN64GameCode(Uint8List bytes) {
    if (bytes.length < 0x40) return null;

    try {
      // N64 game code varies by ROM format
      // Internal name at 0x20 (20 bytes)
      final name = String.fromCharCodes(bytes.sublist(0x20, 0x34))
          .trim()
          .replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // ASCII only

      if (name.isNotEmpty) {
        return name.substring(0, name.length.clamp(0, 20));
      }
    } catch (e) {
      // Invalid
    }

    return null;
  }

  // === UTILITIES ===

  Future<Uint8List> _readFileHeader(File file, int bytes) async {
    final handle = await file.open(mode: FileMode.read);
    try {
      final buffer = Uint8List(bytes);
      final read = await handle.readInto(buffer);
      return Uint8List.sublistView(buffer, 0, read);
    } finally {
      await handle.close();
    }
  }
}

// === RESULT CLASSES ===

/// Platform detection result
class DetectionResult {
  final GamePlatform platform;
  final double confidence; // 0.0 - 1.0
  final String? gameId;
  final String? detectedTitle;
  final String method;
  final String? error;

  DetectionResult({
    required this.platform,
    required this.confidence,
    this.gameId,
    this.detectedTitle,
    required this.method,
    this.error,
  });

  factory DetectionResult.unknown(String error) {
    return DetectionResult(
      platform: GamePlatform.other,
      confidence: 0.0,
      method: 'unknown',
      error: error,
    );
  }

  bool get isConfident => confidence > 0.7;
  bool get isUnknown => platform == GamePlatform.other;

  @override
  String toString() {
    return 'DetectionResult(platform: $platform, confidence: ${(confidence * 100).toStringAsFixed(0)}%, '
        'gameId: $gameId, method: $method)';
  }
}

/// Platform enumeration (reusing from cover art service)
enum GamePlatform {
  wii,
  wiiu,
  gamecube,
  gba,
  gbc,
  gameboy,
  n64,
  snes,
  nes,
  genesis,
  ds,
  nds,
  n3ds,
  ps1,
  ps2,
  other,
}

extension GamePlatformExtension on GamePlatform {
  String get displayName {
    switch (this) {
      case GamePlatform.wii:
        return 'Wii';
      case GamePlatform.wiiu:
        return 'Wii U';
      case GamePlatform.gamecube:
        return 'GameCube';
      case GamePlatform.gba:
        return 'Game Boy Advance';
      case GamePlatform.gbc:
        return 'Game Boy Color';
      case GamePlatform.gameboy:
        return 'Game Boy';
      case GamePlatform.n64:
        return 'Nintendo 64';
      case GamePlatform.snes:
        return 'Super Nintendo';
      case GamePlatform.nes:
        return 'NES';
      case GamePlatform.genesis:
        return 'Sega Genesis';
      case GamePlatform.ds:
      case GamePlatform.nds:
        return 'Nintendo DS';
      case GamePlatform.n3ds:
        return 'Nintendo 3DS';
      case GamePlatform.ps1:
        return 'PlayStation';
      case GamePlatform.ps2:
        return 'PlayStation 2';
      case GamePlatform.other:
        return 'Unknown';
    }
  }

  String get folderName {
    switch (this) {
      case GamePlatform.wii:
        return 'wii';
      case GamePlatform.wiiu:
        return 'wiiu';
      case GamePlatform.gamecube:
        return 'gamecube';
      case GamePlatform.gba:
        return 'gba';
      case GamePlatform.gbc:
        return 'gbc';
      case GamePlatform.gameboy:
        return 'gb';
      case GamePlatform.n64:
        return 'n64';
      case GamePlatform.snes:
        return 'snes';
      case GamePlatform.nes:
        return 'nes';
      case GamePlatform.genesis:
        return 'genesis';
      case GamePlatform.ds:
      case GamePlatform.nds:
        return 'nds';
      case GamePlatform.n3ds:
        return '3ds';
      case GamePlatform.ps1:
        return 'ps1';
      case GamePlatform.ps2:
        return 'ps2';
      case GamePlatform.other:
        return '_unsorted';
    }
  }
}
