import 'package:drift/drift.dart';

class Titles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameId => text()();
  TextColumn get title => text()();
  TextColumn get platform => text()();
  TextColumn get region => text().nullable()();
  TextColumn get format => text()();
  TextColumn get filePath => text().unique()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get sha1Partial => text().nullable()();
  TextColumn get sha1Full => text().nullable()();
  IntColumn get addedTimestamp => integer()();
  IntColumn get modifiedTimestamp => integer()();
  IntColumn get lastVerified => integer().nullable()();
  TextColumn get healthStatus =>
      text().withDefault(const Constant('unknown'))();
  IntColumn get hasCover => integer().withDefault(const Constant(0))();
  IntColumn get hasMetadata => integer().withDefault(const Constant(0))();
  IntColumn get isQuarantined => integer().withDefault(const Constant(0))();
  TextColumn get quarantineReason => text().nullable()();
  IntColumn get variantGroup => integer().nullable()();
}

class Issues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get titleId => integer().nullable().references(Titles, #id)();
  TextColumn get issueType => text()();
  TextColumn get severity => text()();
  TextColumn get description => text()();
  IntColumn get estimatedImpactScore =>
      integer().withDefault(const Constant(0))();
  IntColumn get estimatedSpaceSavings =>
      integer().withDefault(const Constant(0))();
  TextColumn get fixAction => text().nullable()();
  IntColumn get createdTimestamp => integer()();
  IntColumn get resolvedTimestamp => integer().nullable()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskType => text()();
  TextColumn get state => text()();
  IntColumn get priority => integer().withDefault(const Constant(5))();
  TextColumn get payload => text()();
  RealColumn get progressPercent => real().withDefault(const Constant(0))();
  TextColumn get progressMessage => text().nullable()();
  IntColumn get startedTimestamp => integer().nullable()();
  IntColumn get completedTimestamp => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get dependsOn => integer().nullable().references(Tasks, #id)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get logPath => text().nullable()();
}

class HealthSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timestamp => integer()();
  IntColumn get score => integer()();
  IntColumn get totalTitles => integer().withDefault(const Constant(0))();
  IntColumn get healthyCount => integer().withDefault(const Constant(0))();
  IntColumn get duplicateCount => integer().withDefault(const Constant(0))();
  IntColumn get corruptedCount => integer().withDefault(const Constant(0))();
  IntColumn get missingMetadataCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalSizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get potentialSavingsBytes =>
      integer().withDefault(const Constant(0))();
}

class QuarantineLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get titleId => integer().references(Titles, #id)();
  TextColumn get originalPath => text()();
  TextColumn get quarantinePath => text()();
  TextColumn get reason => text().nullable()();
  IntColumn get timestamp => integer()();
  IntColumn get restoredTimestamp => integer().nullable()();
}

class SchemaVersions extends Table {
  IntColumn get version => integer()();
  IntColumn get appliedTimestamp => integer()();

  @override
  Set<Column> get primaryKey => {version};
}

class PatchedRoms extends Table {
  TextColumn get id => text()();
  TextColumn get baseGameId => text()();
  TextColumn get patchName => text()();
  TextColumn get patchVersion => text()();
  TextColumn get downloadUrl => text()();
  TextColumn get archiveUrl => text().nullable()();
  TextColumn get torrentUrl => text().nullable()();
  TextColumn get sha256Hash => text().nullable()();
  TextColumn get sha1Hash => text().nullable()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get patchNotes => text().nullable()();
  TextColumn get platform => text()();
  TextColumn get region => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get downloadCount => integer().withDefault(const Constant(0))();
  IntColumn get isVerified => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Downloads table for persistent download state
/// Allows downloads to resume after app restart
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameId => text()(); // Game ID (e.g., RMCE01)
  TextColumn get title => text()(); // Game title
  TextColumn get platform => text()(); // Wii or GameCube
  TextColumn get downloadUrl => text()(); // Source URL
  TextColumn get savePath => text()(); // Destination file path

  IntColumn get totalBytes => integer()(); // Total download size
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  // Status: queued, downloading, paused, completed, failed, canceled
  TextColumn get status => text().withDefault(const Constant('queued'))();

  TextColumn get provider => text().nullable()(); // Myrient, Archive.org, etc.
  TextColumn get errorMessage => text().nullable()(); // Error if failed

  IntColumn get createdAt => integer()(); // Unix timestamp
  IntColumn get updatedAt => integer()(); // Last update timestamp
  IntColumn get completedAt => integer().nullable()(); // When finished
}
