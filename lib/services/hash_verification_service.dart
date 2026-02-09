import 'dart:io';

import 'package:crypto/crypto.dart';

/// Hash Verification Service - Compute and verify file hashes (CRC32, MD5, SHA1).
/// Optionally check against a loaded Redump-style database when available.
class HashVerificationService {
  static final Map<String, RedumpEntry> _hashDatabase = {};
  static bool _isLoaded = false;

  /// Load hash database for a platform (e.g. from DAT file or API).
  /// Call with a platform key; database can be populated from external DAT/JSON later.
  static Future<void> loadDatabase(String platform) async {
    if (_isLoaded) return;
    _isLoaded = true;
    // Database can be populated via registerHash() or by loading a DAT file.
  }

  /// Register a known hash for verification (e.g. from Redump DAT).
  static void registerHash(RedumpEntry entry) {
    _hashDatabase[entry.crc32.toLowerCase()] = entry;
    _hashDatabase[entry.md5.toLowerCase()] = entry;
    _hashDatabase[entry.sha1.toLowerCase()] = entry;
  }

  /// Verify a file: compute CRC32, MD5, SHA1 and check against loaded database.
  static Future<VerificationResult> verifyFile(File file) async {
    try {
      final stat = await file.stat();
      final bytes = await file.readAsBytes();

      final crc = _calculateCRC32(bytes);
      final md5Hash = md5.convert(bytes).toString();
      final sha1Hash = sha1.convert(bytes).toString();

      final isKnown = _hashDatabase.containsKey(crc.toLowerCase()) ||
          _hashDatabase.containsKey(md5Hash) ||
          _hashDatabase.containsKey(sha1Hash);
      final matched = isKnown
          ? (_hashDatabase[crc.toLowerCase()] ??
              _hashDatabase[md5Hash] ??
              _hashDatabase[sha1Hash])
          : null;

      return VerificationResult(
        filePath: file.path,
        crc32: crc,
        md5: md5Hash,
        sha1: sha1Hash,
        isVerified: isKnown,
        matchedEntry: matched,
        fileSize: stat.size,
      );
    } catch (e) {
      return VerificationResult(
        filePath: file.path,
        crc32: '',
        md5: '',
        sha1: '',
        isVerified: false,
        errorMessage: e.toString(),
        fileSize: 0,
      );
    }
  }

  /// Quick check: file exists, non-zero size, optional Wii/GC magic.
  static Future<QuickCheckResult> quickCheck(File file,
      {int? expectedSize}) async {
    try {
      if (!await file.exists()) {
        return QuickCheckResult(isValid: false, reason: 'File not found');
      }

      final stat = await file.stat();

      if (stat.size == 0) {
        return QuickCheckResult(isValid: false, reason: 'File is empty');
      }

      if (expectedSize != null && stat.size != expectedSize) {
        return QuickCheckResult(
          isValid: false,
          reason: 'Size mismatch: expected $expectedSize, got ${stat.size}',
        );
      }

      final raf = await file.open();
      final header = await raf.read(32);
      await raf.close();

      if (header.length >= 32) {
        final magic = (header[0x1C] << 24) |
            (header[0x1D] << 16) |
            (header[0x1E] << 8) |
            header[0x1F];
        if (magic == 0x5D1C9EA3) {
          return QuickCheckResult(
            isValid: true,
            reason: 'Valid Wii/GC disc image',
            discType: 'Wii/GameCube',
          );
        }
      }

      return QuickCheckResult(isValid: true, reason: 'File exists');
    } catch (e) {
      return QuickCheckResult(isValid: false, reason: e.toString());
    }
  }

  static String _calculateCRC32(List<int> bytes) {
    int crc = 0xFFFFFFFF;
    const polynomial = 0xEDB88320;

    for (final byte in bytes) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ polynomial;
        } else {
          crc >>= 1;
        }
      }
    }
    return (~crc & 0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0');
  }
}

class VerificationResult {
  final String filePath;
  final String crc32;
  final String md5;
  final String sha1;
  final bool isVerified;
  final RedumpEntry? matchedEntry;
  final String? errorMessage;
  final int fileSize;

  VerificationResult({
    required this.filePath,
    required this.crc32,
    required this.md5,
    required this.sha1,
    required this.isVerified,
    this.matchedEntry,
    this.errorMessage,
    required this.fileSize,
  });
}

class QuickCheckResult {
  final bool isValid;
  final String reason;
  final String? discType;

  QuickCheckResult({
    required this.isValid,
    required this.reason,
    this.discType,
  });
}

class RedumpEntry {
  final String title;
  final String gameId;
  final String region;
  final String crc32;
  final String md5;
  final String sha1;
  final int size;

  RedumpEntry({
    required this.title,
    required this.gameId,
    required this.region,
    required this.crc32,
    required this.md5,
    required this.sha1,
    required this.size,
  });
}
