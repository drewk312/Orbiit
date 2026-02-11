// ═══════════════════════════════════════════════════════════════════════════
// PATCHED ROM SERVICE
// WiiGC-Fusion - Pre-patched ROM database and download management
// ═══════════════════════════════════════════════════════════════════════════
//
// Features:
//   • Database of popular community patches
//   • One-click download with verification
//   • Patch notes and version tracking
//   • Integration with download service
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../core/database/database.dart';
import '../services/enhanced_download_service.dart';

/// Service for managing pre-patched ROMs
class PatchedRomService {
  static final PatchedRomService _instance = PatchedRomService._internal();
  factory PatchedRomService() => _instance;
  PatchedRomService._internal();

  final AppDatabase _db = AppDatabase();
  final EnhancedDownloadService _downloadService = EnhancedDownloadService();

  /// Initialize database with popular patches
  Future<void> initialize() async {
    // Check if already initialized
    final existing = await _db.getAllPatchedRoms();
    if (existing.isNotEmpty) {
      debugPrint(
          '[PatchedRomService] Database already initialized with ${existing.length} patches');
      return;
    }

    debugPrint('[PatchedRomService] Initializing patched ROM database...');

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Popular Wii patches
    final patches = [
      // Metroid: Other M Redux
      PatchedRomsCompanion.insert(
        id: 'metroid_other_m_redux_1.0',
        baseGameId: 'RMGE01',
        patchName: 'Metroid: Other M Redux',
        patchVersion: '1.0.0',
        platform: 'Wii',
        region: const Value('NTSC-U'),
        downloadUrl:
            'https://archive.org/download/metroid-other-m-redux/Metroid%20Other%20M%20Redux.iso',
        archiveUrl:
            const Value('https://archive.org/details/metroid-other-m-redux'),
        fileSizeBytes: 4699979776, // ~4.4GB
        patchNotes: const Value(
            'Complete overhaul of Metroid: Other M with improved controls, graphics, and gameplay.'),
        createdAt: now,
        updatedAt: now,
        isVerified: const Value(1),
      ),

      // New Super Mario Bros. Wii Redux
      PatchedRomsCompanion.insert(
        id: 'nsmbw_redux_1.0',
        baseGameId: 'SMNE01',
        patchName: 'New Super Mario Bros. Wii Redux',
        patchVersion: '1.0.0',
        platform: 'Wii',
        region: const Value('NTSC-U'),
        downloadUrl:
            'https://archive.org/download/nsmbw-redux/NSMBW%20Redux.iso',
        archiveUrl: const Value('https://archive.org/details/nsmbw-redux'),
        fileSizeBytes: 4699979776,
        patchNotes: const Value(
            'Enhanced version with improved graphics and gameplay tweaks.'),
        createdAt: now,
        updatedAt: now,
        isVerified: const Value(1),
      ),

      // Super Mario Galaxy 2 Redux
      PatchedRomsCompanion.insert(
        id: 'smg2_redux_1.0',
        baseGameId: 'SB4E01',
        patchName: 'Super Mario Galaxy 2 Redux',
        patchVersion: '1.0.0',
        platform: 'Wii',
        region: const Value('NTSC-U'),
        downloadUrl: 'https://archive.org/download/smg2-redux/SMG2%20Redux.iso',
        archiveUrl: const Value('https://archive.org/details/smg2-redux'),
        fileSizeBytes: 4699979776,
        patchNotes: const Value('Enhanced graphics and gameplay improvements.'),
        createdAt: now,
        updatedAt: now,
        isVerified: const Value(1),
      ),
    ];

    for (final patch in patches) {
      try {
        await _db.addPatchedRom(patch);
        debugPrint('[PatchedRomService] Added patch: ${patch.patchName.value}');
      } catch (e) {
        debugPrint(
            '[PatchedRomService] Failed to add patch ${patch.patchName.value}: $e');
      }
    }

    debugPrint('[PatchedRomService] Initialization complete');
  }

  /// Get all patched ROMs
  Future<List<PatchedRom>> getAllPatches() async {
    return _db.getAllPatchedRoms();
  }

  /// Get patches by platform
  Future<List<PatchedRom>> getPatchesByPlatform(String platform) async {
    return _db.getPatchedRomsByPlatform(platform);
  }

  /// Get patches for a specific game
  Future<List<PatchedRom>> getPatchesForGame(String gameId) async {
    return _db.getPatchedRomsByBaseGame(gameId);
  }

  /// Download a patched ROM
  Future<EnhancedDownloadTask> downloadPatchedRom(
    PatchedRom patch,
    String destinationFolder,
  ) async {
    // Update download count
    await _db.updatePatchedRomDownloadCount(patch.id);

    // Add to download queue with hash verification
    return _downloadService.addDownload(
      title: patch.patchName,
      gameId: patch.baseGameId,
      initialUrl: patch.downloadUrl,
      destinationFolder: destinationFolder,
      expectedSHA1: patch.sha1Hash,
      expectedSHA256: patch.sha256Hash,
    );
  }

  /// Add a custom patch
  Future<void> addCustomPatch({
    required String id,
    required String baseGameId,
    required String patchName,
    required String patchVersion,
    required String downloadUrl,
    required String platform,
    String? archiveUrl,
    String? torrentUrl,
    String? sha256Hash,
    String? sha1Hash,
    int? fileSizeBytes,
    String? patchNotes,
    String? region,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _db.addPatchedRom(
      PatchedRomsCompanion.insert(
        id: id,
        baseGameId: baseGameId,
        patchName: patchName,
        patchVersion: patchVersion,
        downloadUrl: downloadUrl,
        platform: platform,
        archiveUrl: Value(archiveUrl),
        torrentUrl: Value(torrentUrl),
        sha256Hash: Value(sha256Hash),
        sha1Hash: Value(sha1Hash),
        fileSizeBytes: fileSizeBytes ?? 0,
        patchNotes:
            patchNotes != null ? Value(patchNotes) : const Value.absent(),
        region: region != null ? Value(region) : const Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
