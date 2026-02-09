import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Titles,
  Issues,
  Tasks,
  HealthSnapshots,
  QuarantineLogs,
  SchemaVersions,
  PatchedRoms,
  Downloads, // Download persistence
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Bumped for Downloads table

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Initialize schema version
        await into(schemaVersions).insert(
          SchemaVersionsCompanion.insert(
            version: const Value(2),
            appliedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add PatchedRoms table
          await m.createTable(patchedRoms);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_patched_base_game ON patched_roms(base_game_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_patched_platform ON patched_roms(platform)');

          // Update schema version
          await into(schemaVersions).insert(
            SchemaVersionsCompanion.insert(
              version: const Value(2),
              appliedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
        }

        if (from < 3) {
          // Add Downloads table
          await m.createTable(downloads);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_download_status ON downloads(status)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_download_created ON downloads(created_at)');

          // Update schema version
          await into(schemaVersions).insert(
            SchemaVersionsCompanion.insert(
              version: const Value(3),
              appliedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        // Create indexes for performance
        if (details.wasCreated) {
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_game_id ON titles(game_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_health ON titles(health_status)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_variant ON titles(variant_group)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_issue_severity ON issues(severity, resolved_timestamp)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_task_state ON tasks(state, priority)');
        }
      },
    );
  }

  // Query methods for Library
  Future<List<Title>> getAllTitles() => select(titles).get();

  Future<List<Title>> getTitlesByHealth(String healthStatus) =>
      (select(titles)..where((t) => t.healthStatus.equals(healthStatus))).get();

  Stream<List<Title>> watchAllTitles() => select(titles).watch();

  // Query methods for Issues
  Future<List<Issue>> getUnresolvedIssues() =>
      (select(issues)..where((i) => i.resolvedTimestamp.isNull())).get();

  Stream<List<Issue>> watchUnresolvedIssues() =>
      (select(issues)..where((i) => i.resolvedTimestamp.isNull())).watch();

  // Query methods for Tasks
  Future<List<Task>> getActiveTasks() => (select(tasks)
        ..where((t) => t.state.isIn(['queued', 'running', 'paused'])))
      .get();

  Stream<List<Task>> watchActiveTasks() => (select(tasks)
        ..where((t) => t.state.isIn(['queued', 'running', 'paused'])))
      .watch();

  // Get latest health snapshot
  Future<HealthSnapshot?> getLatestHealthSnapshot() async {
    final query = select(healthSnapshots)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // Insert methods
  Future<int> addTitle(TitlesCompanion title) => into(titles).insert(title);
  Future<int> addIssue(IssuesCompanion issue) => into(issues).insert(issue);
  Future<int> addTask(TasksCompanion task) => into(tasks).insert(task);
  Future<int> addHealthSnapshot(HealthSnapshotsCompanion snapshot) =>
      into(healthSnapshots).insert(snapshot);

  // Convenience insert methods
  Future<int> insertTitle({
    required String gameId,
    required String title,
    required String platform,
    required String region,
    required String format,
    required String filePath,
    required int fileSizeBytes,
    String? sha1Partial,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return into(titles).insert(
      TitlesCompanion.insert(
        gameId: gameId,
        title: title,
        platform: platform,
        format: format,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
        addedTimestamp: now,
        modifiedTimestamp: now,
        region: Value(region),
        sha1Partial: Value(sha1Partial),
        healthStatus: const Value('pending'),
      ),
      mode: InsertMode.insertOrReplace, // Skip if file_path already exists
    );
  }

  Future<int> insertIssue({
    required int titleId,
    required String issueType,
    required String severity,
    required String description,
    required int estimatedImpactScore,
    required int estimatedSpaceSavings,
    required String fixAction,
  }) {
    return into(issues).insert(IssuesCompanion.insert(
      issueType: issueType,
      severity: severity,
      description: description,
      createdTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titleId: Value(titleId),
      estimatedImpactScore: Value(estimatedImpactScore),
      estimatedSpaceSavings: Value(estimatedSpaceSavings),
      fixAction: Value(fixAction),
    ));
  }

  Future<int> insertHealthSnapshot({
    required int score,
    required int totalTitles,
    required int healthyCount,
    required int duplicateCount,
    required int corruptedCount,
    required int missingMetadataCount,
    required int totalSizeBytes,
    required int potentialSavingsBytes,
  }) {
    return into(healthSnapshots).insert(HealthSnapshotsCompanion.insert(
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      score: score,
      totalTitles: Value(totalTitles),
      healthyCount: Value(healthyCount),
      duplicateCount: Value(duplicateCount),
      corruptedCount: Value(corruptedCount),
      missingMetadataCount: Value(missingMetadataCount),
      totalSizeBytes: Value(totalSizeBytes),
      potentialSavingsBytes: Value(potentialSavingsBytes),
    ));
  }

  // Delete methods
  Future<int> deleteAllIssues() => delete(issues).go();
  Future<int> deleteTitle(int id) =>
      (delete(titles)..where((t) => t.id.equals(id))).go();
  Future<int> deleteTitleByPath(String filePath) async {
    // First delete associated issues
    final title = await (select(titles)
          ..where((t) => t.filePath.equals(filePath)))
        .getSingleOrNull();
    if (title != null) {
      await (delete(issues)..where((i) => i.titleId.equals(title.id))).go();
    }
    return (delete(titles)..where((t) => t.filePath.equals(filePath))).go();
  }

  // Get duplicate issues
  Future<List<Issue>> getDuplicateIssues() => (select(issues)
        ..where((i) =>
            i.issueType.equals('duplicate') & i.resolvedTimestamp.isNull())
        ..orderBy([(i) => OrderingTerm.desc(i.createdTimestamp)]))
      .get();

  Future<List<Title>> getTitlesByGameId(String gameId) =>
      (select(titles)..where((t) => t.gameId.equals(gameId))).get();

  // Update methods
  Future<bool> updateTitle(Title title) => update(titles).replace(title);
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  // Patched ROMs queries
  Future<List<PatchedRom>> getAllPatchedRoms() => select(patchedRoms).get();

  Future<List<PatchedRom>> getPatchedRomsByPlatform(String platform) =>
      (select(patchedRoms)..where((p) => p.platform.equals(platform))).get();

  Future<List<PatchedRom>> getPatchedRomsByBaseGame(String gameId) =>
      (select(patchedRoms)..where((p) => p.baseGameId.equals(gameId))).get();

  Future<PatchedRom?> getPatchedRomById(String id) async {
    final results =
        await (select(patchedRoms)..where((p) => p.id.equals(id))).get();
    return results.isEmpty ? null : results.first;
  }

  Future<int> addPatchedRom(PatchedRomsCompanion rom) =>
      into(patchedRoms).insert(rom, mode: InsertMode.insertOrReplace);

  Future<int> updatePatchedRomDownloadCount(String id) async {
    final rom = await getPatchedRomById(id);
    if (rom == null) return 0;
    return (update(patchedRoms)..where((p) => p.id.equals(id)))
        .write(PatchedRomsCompanion(
      downloadCount: Value(rom.downloadCount + 1),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    ));
  }

  // ========== Download Persistence Methods ==========

  Future<List<Download>> getAllDownloads() => select(downloads).get();

  Future<List<Download>> getActiveDownloads() => (select(downloads)
        ..where((d) => d.status.isIn(['queued', 'downloading', 'paused'])))
      .get();

  Stream<List<Download>> watchActiveDownloads() => (select(downloads)
        ..where((d) => d.status.isIn(['queued', 'downloading', 'paused'])))
      .watch();

  Future<int> addDownload(DownloadsCompanion download) =>
      into(downloads).insert(download);

  Future<int> updateDownloadProgress(int id, int downloadedBytes) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (update(downloads)..where((d) => d.id.equals(id)))
        .write(DownloadsCompanion(
      downloadedBytes: Value(downloadedBytes),
      updatedAt: Value(now),
    ));
  }

  Future<int> updateDownloadStatus(int id, String status,
      {String? errorMessage}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (update(downloads)..where((d) => d.id.equals(id)))
        .write(DownloadsCompanion(
      status: Value(status),
      updatedAt: Value(now),
      completedAt: status == 'completed' ? Value(now) : const Value.absent(),
      errorMessage: Value(errorMessage),
    ));
  }

  Future<int> deleteDownload(int id) =>
      (delete(downloads)..where((d) => d.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wiigc_fusion', 'library.db'));

    // Create directory if it doesn't exist
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return NativeDatabase(file);
  });
}
