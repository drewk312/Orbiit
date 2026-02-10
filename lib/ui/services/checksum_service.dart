import 'dart:io';
import 'package:crypto/crypto.dart';

/// Service for calculating and verifying game file checksums
/// Based on TinyWii's checksum.rs - supports CRC32, MD5, SHA-1
class ChecksumService {
  /// Calculate CRC32 checksum
  Future<String> calculateCRC32File(
    String filePath, {
    Function(int current, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    int crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = _crc32Table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    final result = (crc ^ 0xFFFFFFFF) >>> 0;
    return result.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  /// Calculate MD5 checksum
  Future<String> calculateMD5File(
    String filePath, {
    Function(int current, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// Calculate SHA-1 checksum
  Future<String> calculateSHA1File(
    String filePath, {
    Function(int current, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// Calculate all checksums at once (more efficient)
  Future<ChecksumResult> calculateAllFile(
    String filePath, {
    Function(int current, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();

    // CRC32
    int crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = _crc32Table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    final crcResult = (crc ^ 0xFFFFFFFF) >>> 0;
    final crcHex = crcResult.toRadixString(16).padLeft(8, '0').toUpperCase();

    // MD5 and SHA-1
    final md5Digest = md5.convert(bytes);
    final sha1Digest = sha1.convert(bytes);

    return ChecksumResult(
      crc32: crcHex,
      md5: md5Digest.toString().toUpperCase(),
      sha1: sha1Digest.toString().toUpperCase(),
    );
  }

  // CRC32 lookup table
  static final List<int> _crc32Table = _generateCRC32Table();

  static List<int> _generateCRC32Table() {
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc = crc >> 1;
        }
      }
      table[i] = crc;
    }
    return table;
  }
}

/// Checksum calculation result
class ChecksumResult {
  final String crc32;
  final String md5;
  final String sha1;

  ChecksumResult({
    required this.crc32,
    required this.md5,
    required this.sha1,
  });

  @override
  String toString() {
    return 'CRC32: $crc32\nMD5: $md5\nSHA-1: $sha1';
  }
}
