import 'dart:io';

import 'package:path/path.dart' as path;

import '../core/app_logger.dart';

class MemoryCardService {
  static final MemoryCardService _instance = MemoryCardService._internal();
  factory MemoryCardService() => _instance;
  MemoryCardService._internal();

  /// Constants for memory card sizes
  static const int size59 = 512 * 1024; // 512KB (Standard 59 blocks)
  static const int size123 = 1024 * 1024; // 1MB
  static const int size251 = 2 * 1024 * 1024; // 2MB (Standard 251 blocks)
  static const int size507 = 4 * 1024 * 1024; // 4MB
  static const int size1019 = 8 * 1024 * 1024; // 8MB
  static const int size2043 = 16 * 1024 * 1024; // 16MB

  /// Finds memory card files in the Nintendont /saves directory
  Future<List<File>> scanForMemoryCards(Directory libraryRoot) async {
    final savesDir = Directory(path.join(libraryRoot.path, 'saves'));
    if (!savesDir.existsSync()) return [];

    return savesDir.listSync().whereType<File>().where((f) {
      final ext = path.extension(f.path).toLowerCase();
      // Nintendont supports .raw and .gcp. Standard naming is [GameID].raw or ninmem.raw
      return ext == '.raw' || ext == '.gcp';
    }).toList();
  }

  /// Creates a new formatted memory card file (blank .raw)
  /// Nintendont creates them automatically, but power users might want shared cards (ninmem.raw)
  Future<File> createBlankCard(
      Directory libraryRoot, String filename, int sizeBytes) async {
    final savesDir = Directory(path.join(libraryRoot.path, 'saves'));
    if (!savesDir.existsSync()) savesDir.createSync(recursive: true);

    final file = File(path.join(savesDir.path, filename));
    if (file.existsSync()) throw Exception('File already exists');

    // Create blank file filled with zeros (effectively unformatted, Nintendont will format)
    // Or we could try to write a valid header if needed, but Nintendont handles raw zero-filled files fine usually.
    // Writing 16MB of zeros might be slow in pure Dart, but acceptable.

    // distinct implementation for speed?
    // let's just create sparse file if OS supports or write blocks

    final raf = await file.open(mode: FileMode.write);
    await raf.setPosition(sizeBytes - 1);
    await raf.writeByte(0); // Sets length
    await raf.close();

    AppLogger.instance
        .info('Created memory card: ${file.path} ($sizeBytes bytes)');
    return file;
  }

  /// Backup a memory card to a "backups" folder
  Future<File> backupCard(File card) async {
    final backupDir = Directory(path.join(card.parent.path, 'backups'));
    if (!backupDir.existsSync()) backupDir.createSync();

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupName =
        '${path.basenameWithoutExtension(card.path)}_$timestamp${path.extension(card.path)}';

    final backupFile = File(path.join(backupDir.path, backupName));
    return card.copy(backupFile.path);
  }
}
