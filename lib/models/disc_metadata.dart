// ═══════════════════════════════════════════════════════════════════════════
// DISC METADATA MODEL
// Complete disc information matching TinyWii's DiscInfo structure
// ═══════════════════════════════════════════════════════════════════════════

/// Disc format types
enum DiscFormat {
  iso,
  wbfs,
  rvz,
  gcz,
  ciso,
  nkit,
  unknown;

  String get displayName {
    switch (this) {
      case DiscFormat.iso:
        return 'ISO';
      case DiscFormat.wbfs:
        return 'WBFS';
      case DiscFormat.rvz:
        return 'RVZ';
      case DiscFormat.gcz:
        return 'GCZ';
      case DiscFormat.ciso:
        return 'CISO';
      case DiscFormat.nkit:
        return 'NKit';
      case DiscFormat.unknown:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case DiscFormat.iso:
        return 'Standard ISO image';
      case DiscFormat.wbfs:
        return 'Wii Backup File System';
      case DiscFormat.rvz:
        return 'Dolphin compressed format';
      case DiscFormat.gcz:
        return 'GameCube Zip format';
      case DiscFormat.ciso:
        return 'Compact ISO';
      case DiscFormat.nkit:
        return 'NKit optimized format';
      case DiscFormat.unknown:
        return 'Unknown format';
    }
  }
}

/// Compression types
enum CompressionType {
  none,
  zlib,
  lzma,
  zstd,
  bzip2,
  unknown;

  String get displayName {
    switch (this) {
      case CompressionType.none:
        return 'None';
      case CompressionType.zlib:
        return 'zlib';
      case CompressionType.lzma:
        return 'LZMA';
      case CompressionType.zstd:
        return 'Zstandard';
      case CompressionType.bzip2:
        return 'bzip2';
      case CompressionType.unknown:
        return 'Unknown';
    }
  }
}

/// Console types
enum ConsoleType {
  wii,
  gamecube,
  wiiu;

  String get displayName {
    switch (this) {
      case ConsoleType.wii:
        return 'Nintendo Wii';
      case ConsoleType.gamecube:
        return 'Nintendo GameCube';
      case ConsoleType.wiiu:
        return 'Nintendo Wii U';
    }
  }

  String get shortName {
    switch (this) {
      case ConsoleType.wii:
        return 'Wii';
      case ConsoleType.gamecube:
        return 'GameCube';
      case ConsoleType.wiiu:
        return 'Wii U';
    }
  }
}

/// Region codes
enum RegionCode {
  usa,
  europe,
  japan,
  korea,
  australia,
  taiwan,
  unknown;

  String get displayName {
    switch (this) {
      case RegionCode.usa:
        return 'USA (NTSC-U)';
      case RegionCode.europe:
        return 'Europe (PAL)';
      case RegionCode.japan:
        return 'Japan (NTSC-J)';
      case RegionCode.korea:
        return 'Korea';
      case RegionCode.australia:
        return 'Australia (PAL)';
      case RegionCode.taiwan:
        return 'Taiwan';
      case RegionCode.unknown:
        return 'Unknown';
    }
  }

  String get flagEmoji {
    switch (this) {
      case RegionCode.usa:
        return '🇺🇸';
      case RegionCode.europe:
        return '🇪🇺';
      case RegionCode.japan:
        return '🇯🇵';
      case RegionCode.korea:
        return '🇰🇷';
      case RegionCode.australia:
        return '🇦🇺';
      case RegionCode.taiwan:
        return '🇹🇼';
      case RegionCode.unknown:
        return '🌍';
    }
  }
}

/// Complete disc metadata - matches TinyWii's DiscInfo structure
class DiscMetadata {
  // File info
  final String filePath;
  final String fileName;
  final int fileSize;

  // Disc Header
  final String gameId;
  final String embeddedTitle;
  final ConsoleType console;
  final RegionCode region;
  final int discNumber;
  final int discVersion;

  // Disc Meta
  final DiscFormat format;
  final CompressionType compression;
  final int? blockSize;
  final bool isDecrypted;
  final bool needsHashRecovery;
  final bool isLossless;
  final int? discSize; // Original disc size (may differ from file size)

  // Hashes (computed or cached)
  final String? crc32;
  final String? md5;
  final String? sha1;
  final String? xxh64;

  // Misc
  final bool isWorthStripping;
  final DateTime? scannedAt;

  const DiscMetadata({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.gameId,
    required this.embeddedTitle,
    required this.console,
    required this.region,
    this.discNumber = 0,
    this.discVersion = 0,
    required this.format,
    this.compression = CompressionType.none,
    this.blockSize,
    this.isDecrypted = false,
    this.needsHashRecovery = false,
    this.isLossless = true,
    this.discSize,
    this.crc32,
    this.md5,
    this.sha1,
    this.xxh64,
    this.isWorthStripping = false,
    this.scannedAt,
  });

  /// Display title (alias for embeddedTitle)
  String get title => embeddedTitle;

  /// Platform short name (e.g. "Wii", "GameCube")
  String get platform => console.shortName;

  /// File path (alias for filePath)
  String get path => filePath;

  /// Formatted file size (alias for formattedFileSize)
  String get sizeFormatted => formattedFileSize;

  /// Region as display string
  String get displayRegion => region.displayName;

  /// Optional publisher (not parsed from disc)
  String? get publisher => null;

  /// Optional release year (not parsed from disc)
  int? get releaseYear => null;

  /// Get formatted file size
  String get formattedFileSize => _formatBytes(fileSize);

  /// Get formatted disc size
  String get formattedDiscSize =>
      discSize != null ? _formatBytes(discSize!) : 'N/A';

  /// Get formatted block size
  String get formattedBlockSize =>
      blockSize != null ? _formatBytes(blockSize!) : 'N/A';

  /// Check if this is a Wii game
  bool get isWii => console == ConsoleType.wii;

  /// Check if this is a GameCube game
  bool get isGameCube => console == ConsoleType.gamecube;

  /// Get cover art URL from GameTDB
  String get coverUrl {
    final regionCode = _regionToCode(region);
    return 'https://art.gametdb.com/wii/cover3D/$regionCode/$gameId.png';
  }

  /// Get full cover art URL from GameTDB
  String get fullCoverUrl {
    final regionCode = _regionToCode(region);
    return 'https://art.gametdb.com/wii/coverfull/$regionCode/$gameId.png';
  }

  /// Get disc art URL from GameTDB
  String get discUrl {
    final regionCode = _regionToCode(region);
    return 'https://art.gametdb.com/wii/disc/$regionCode/$gameId.png';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String _regionToCode(RegionCode region) {
    switch (region) {
      case RegionCode.usa:
        return 'US';
      case RegionCode.europe:
        return 'EN';
      case RegionCode.japan:
        return 'JA';
      case RegionCode.korea:
        return 'KO';
      case RegionCode.australia:
        return 'AU';
      case RegionCode.taiwan:
        return 'TW';
      case RegionCode.unknown:
        return 'US';
    }
  }

  /// Create from ScannedGame for backwards compatibility
  factory DiscMetadata.fromScannedGame({
    required String path,
    required String fileName,
    required String title,
    String? gameId,
    required String platform,
    required int sizeBytes,
    required String extension,
  }) {
    return DiscMetadata(
      filePath: path,
      fileName: fileName,
      fileSize: sizeBytes,
      gameId: gameId ?? 'UNKNOWN',
      embeddedTitle: title,
      console: _detectConsole(platform, gameId),
      region: _detectRegion(gameId),
      format: _detectFormat(extension),
    );
  }

  static ConsoleType _detectConsole(String platform, String? gameId) {
    final p = platform.toLowerCase();
    if (p.contains('gamecube') || p.contains('gc')) return ConsoleType.gamecube;
    if (p.contains('wiiu') || p.contains('wii u')) return ConsoleType.wiiu;
    if (p.contains('wii')) return ConsoleType.wii;

    // Detect from game ID prefix
    if (gameId != null && gameId.isNotEmpty) {
      switch (gameId[0]) {
        case 'G':
        case 'D':
        case 'P':
          return ConsoleType.gamecube;
        case 'R':
        case 'S':
        case 'W':
          return ConsoleType.wii;
      }
    }

    return ConsoleType.wii;
  }

  static RegionCode _detectRegion(String? gameId) {
    if (gameId == null || gameId.length < 4) return RegionCode.unknown;

    switch (gameId[3]) {
      case 'E':
        return RegionCode.usa;
      case 'P':
        return RegionCode.europe;
      case 'J':
        return RegionCode.japan;
      case 'K':
        return RegionCode.korea;
      case 'W':
        return RegionCode.taiwan;
      default:
        return RegionCode.usa;
    }
  }

  static DiscFormat _detectFormat(String extension) {
    final ext = extension.toLowerCase();
    if (ext.contains('wbfs')) return DiscFormat.wbfs;
    if (ext.contains('rvz')) return DiscFormat.rvz;
    if (ext.contains('gcz')) return DiscFormat.gcz;
    if (ext.contains('ciso')) return DiscFormat.ciso;
    if (ext.contains('nkit')) return DiscFormat.nkit;
    if (ext.contains('iso')) return DiscFormat.iso;
    return DiscFormat.unknown;
  }

  DiscMetadata copyWith({
    String? filePath,
    String? fileName,
    int? fileSize,
    String? gameId,
    String? embeddedTitle,
    ConsoleType? console,
    RegionCode? region,
    int? discNumber,
    int? discVersion,
    DiscFormat? format,
    CompressionType? compression,
    int? blockSize,
    bool? isDecrypted,
    bool? needsHashRecovery,
    bool? isLossless,
    int? discSize,
    String? crc32,
    String? md5,
    String? sha1,
    String? xxh64,
    bool? isWorthStripping,
    DateTime? scannedAt,
  }) {
    return DiscMetadata(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      gameId: gameId ?? this.gameId,
      embeddedTitle: embeddedTitle ?? this.embeddedTitle,
      console: console ?? this.console,
      region: region ?? this.region,
      discNumber: discNumber ?? this.discNumber,
      discVersion: discVersion ?? this.discVersion,
      format: format ?? this.format,
      compression: compression ?? this.compression,
      blockSize: blockSize ?? this.blockSize,
      isDecrypted: isDecrypted ?? this.isDecrypted,
      needsHashRecovery: needsHashRecovery ?? this.needsHashRecovery,
      isLossless: isLossless ?? this.isLossless,
      discSize: discSize ?? this.discSize,
      crc32: crc32 ?? this.crc32,
      md5: md5 ?? this.md5,
      sha1: sha1 ?? this.sha1,
      xxh64: xxh64 ?? this.xxh64,
      isWorthStripping: isWorthStripping ?? this.isWorthStripping,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}
