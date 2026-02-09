// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TitlesTable extends Titles with TableInfo<$TitlesTable, Title> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TitlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
      'game_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sha1PartialMeta =
      const VerificationMeta('sha1Partial');
  @override
  late final GeneratedColumn<String> sha1Partial = GeneratedColumn<String>(
      'sha1_partial', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sha1FullMeta =
      const VerificationMeta('sha1Full');
  @override
  late final GeneratedColumn<String> sha1Full = GeneratedColumn<String>(
      'sha1_full', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedTimestampMeta =
      const VerificationMeta('addedTimestamp');
  @override
  late final GeneratedColumn<int> addedTimestamp = GeneratedColumn<int>(
      'added_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modifiedTimestampMeta =
      const VerificationMeta('modifiedTimestamp');
  @override
  late final GeneratedColumn<int> modifiedTimestamp = GeneratedColumn<int>(
      'modified_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastVerifiedMeta =
      const VerificationMeta('lastVerified');
  @override
  late final GeneratedColumn<int> lastVerified = GeneratedColumn<int>(
      'last_verified', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _healthStatusMeta =
      const VerificationMeta('healthStatus');
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
      'health_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unknown'));
  static const VerificationMeta _hasCoverMeta =
      const VerificationMeta('hasCover');
  @override
  late final GeneratedColumn<int> hasCover = GeneratedColumn<int>(
      'has_cover', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hasMetadataMeta =
      const VerificationMeta('hasMetadata');
  @override
  late final GeneratedColumn<int> hasMetadata = GeneratedColumn<int>(
      'has_metadata', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isQuarantinedMeta =
      const VerificationMeta('isQuarantined');
  @override
  late final GeneratedColumn<int> isQuarantined = GeneratedColumn<int>(
      'is_quarantined', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _quarantineReasonMeta =
      const VerificationMeta('quarantineReason');
  @override
  late final GeneratedColumn<String> quarantineReason = GeneratedColumn<String>(
      'quarantine_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _variantGroupMeta =
      const VerificationMeta('variantGroup');
  @override
  late final GeneratedColumn<int> variantGroup = GeneratedColumn<int>(
      'variant_group', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        gameId,
        title,
        platform,
        region,
        format,
        filePath,
        fileSizeBytes,
        sha1Partial,
        sha1Full,
        addedTimestamp,
        modifiedTimestamp,
        lastVerified,
        healthStatus,
        hasCover,
        hasMetadata,
        isQuarantined,
        quarantineReason,
        variantGroup
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'titles';
  @override
  VerificationContext validateIntegrity(Insertable<Title> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(_gameIdMeta,
          gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta));
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('sha1_partial')) {
      context.handle(
          _sha1PartialMeta,
          sha1Partial.isAcceptableOrUnknown(
              data['sha1_partial']!, _sha1PartialMeta));
    }
    if (data.containsKey('sha1_full')) {
      context.handle(_sha1FullMeta,
          sha1Full.isAcceptableOrUnknown(data['sha1_full']!, _sha1FullMeta));
    }
    if (data.containsKey('added_timestamp')) {
      context.handle(
          _addedTimestampMeta,
          addedTimestamp.isAcceptableOrUnknown(
              data['added_timestamp']!, _addedTimestampMeta));
    } else if (isInserting) {
      context.missing(_addedTimestampMeta);
    }
    if (data.containsKey('modified_timestamp')) {
      context.handle(
          _modifiedTimestampMeta,
          modifiedTimestamp.isAcceptableOrUnknown(
              data['modified_timestamp']!, _modifiedTimestampMeta));
    } else if (isInserting) {
      context.missing(_modifiedTimestampMeta);
    }
    if (data.containsKey('last_verified')) {
      context.handle(
          _lastVerifiedMeta,
          lastVerified.isAcceptableOrUnknown(
              data['last_verified']!, _lastVerifiedMeta));
    }
    if (data.containsKey('health_status')) {
      context.handle(
          _healthStatusMeta,
          healthStatus.isAcceptableOrUnknown(
              data['health_status']!, _healthStatusMeta));
    }
    if (data.containsKey('has_cover')) {
      context.handle(_hasCoverMeta,
          hasCover.isAcceptableOrUnknown(data['has_cover']!, _hasCoverMeta));
    }
    if (data.containsKey('has_metadata')) {
      context.handle(
          _hasMetadataMeta,
          hasMetadata.isAcceptableOrUnknown(
              data['has_metadata']!, _hasMetadataMeta));
    }
    if (data.containsKey('is_quarantined')) {
      context.handle(
          _isQuarantinedMeta,
          isQuarantined.isAcceptableOrUnknown(
              data['is_quarantined']!, _isQuarantinedMeta));
    }
    if (data.containsKey('quarantine_reason')) {
      context.handle(
          _quarantineReasonMeta,
          quarantineReason.isAcceptableOrUnknown(
              data['quarantine_reason']!, _quarantineReasonMeta));
    }
    if (data.containsKey('variant_group')) {
      context.handle(
          _variantGroupMeta,
          variantGroup.isAcceptableOrUnknown(
              data['variant_group']!, _variantGroupMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Title map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Title(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      gameId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region']),
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      sha1Partial: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha1_partial']),
      sha1Full: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha1_full']),
      addedTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_timestamp'])!,
      modifiedTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}modified_timestamp'])!,
      lastVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_verified']),
      healthStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}health_status'])!,
      hasCover: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}has_cover'])!,
      hasMetadata: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}has_metadata'])!,
      isQuarantined: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_quarantined'])!,
      quarantineReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quarantine_reason']),
      variantGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}variant_group']),
    );
  }

  @override
  $TitlesTable createAlias(String alias) {
    return $TitlesTable(attachedDatabase, alias);
  }
}

class Title extends DataClass implements Insertable<Title> {
  final int id;
  final String gameId;
  final String title;
  final String platform;
  final String? region;
  final String format;
  final String filePath;
  final int fileSizeBytes;
  final String? sha1Partial;
  final String? sha1Full;
  final int addedTimestamp;
  final int modifiedTimestamp;
  final int? lastVerified;
  final String healthStatus;
  final int hasCover;
  final int hasMetadata;
  final int isQuarantined;
  final String? quarantineReason;
  final int? variantGroup;
  const Title(
      {required this.id,
      required this.gameId,
      required this.title,
      required this.platform,
      this.region,
      required this.format,
      required this.filePath,
      required this.fileSizeBytes,
      this.sha1Partial,
      this.sha1Full,
      required this.addedTimestamp,
      required this.modifiedTimestamp,
      this.lastVerified,
      required this.healthStatus,
      required this.hasCover,
      required this.hasMetadata,
      required this.isQuarantined,
      this.quarantineReason,
      this.variantGroup});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<String>(gameId);
    map['title'] = Variable<String>(title);
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    map['format'] = Variable<String>(format);
    map['file_path'] = Variable<String>(filePath);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || sha1Partial != null) {
      map['sha1_partial'] = Variable<String>(sha1Partial);
    }
    if (!nullToAbsent || sha1Full != null) {
      map['sha1_full'] = Variable<String>(sha1Full);
    }
    map['added_timestamp'] = Variable<int>(addedTimestamp);
    map['modified_timestamp'] = Variable<int>(modifiedTimestamp);
    if (!nullToAbsent || lastVerified != null) {
      map['last_verified'] = Variable<int>(lastVerified);
    }
    map['health_status'] = Variable<String>(healthStatus);
    map['has_cover'] = Variable<int>(hasCover);
    map['has_metadata'] = Variable<int>(hasMetadata);
    map['is_quarantined'] = Variable<int>(isQuarantined);
    if (!nullToAbsent || quarantineReason != null) {
      map['quarantine_reason'] = Variable<String>(quarantineReason);
    }
    if (!nullToAbsent || variantGroup != null) {
      map['variant_group'] = Variable<int>(variantGroup);
    }
    return map;
  }

  TitlesCompanion toCompanion(bool nullToAbsent) {
    return TitlesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      title: Value(title),
      platform: Value(platform),
      region:
          region == null && nullToAbsent ? const Value.absent() : Value(region),
      format: Value(format),
      filePath: Value(filePath),
      fileSizeBytes: Value(fileSizeBytes),
      sha1Partial: sha1Partial == null && nullToAbsent
          ? const Value.absent()
          : Value(sha1Partial),
      sha1Full: sha1Full == null && nullToAbsent
          ? const Value.absent()
          : Value(sha1Full),
      addedTimestamp: Value(addedTimestamp),
      modifiedTimestamp: Value(modifiedTimestamp),
      lastVerified: lastVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerified),
      healthStatus: Value(healthStatus),
      hasCover: Value(hasCover),
      hasMetadata: Value(hasMetadata),
      isQuarantined: Value(isQuarantined),
      quarantineReason: quarantineReason == null && nullToAbsent
          ? const Value.absent()
          : Value(quarantineReason),
      variantGroup: variantGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(variantGroup),
    );
  }

  factory Title.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Title(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      title: serializer.fromJson<String>(json['title']),
      platform: serializer.fromJson<String>(json['platform']),
      region: serializer.fromJson<String?>(json['region']),
      format: serializer.fromJson<String>(json['format']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      sha1Partial: serializer.fromJson<String?>(json['sha1Partial']),
      sha1Full: serializer.fromJson<String?>(json['sha1Full']),
      addedTimestamp: serializer.fromJson<int>(json['addedTimestamp']),
      modifiedTimestamp: serializer.fromJson<int>(json['modifiedTimestamp']),
      lastVerified: serializer.fromJson<int?>(json['lastVerified']),
      healthStatus: serializer.fromJson<String>(json['healthStatus']),
      hasCover: serializer.fromJson<int>(json['hasCover']),
      hasMetadata: serializer.fromJson<int>(json['hasMetadata']),
      isQuarantined: serializer.fromJson<int>(json['isQuarantined']),
      quarantineReason: serializer.fromJson<String?>(json['quarantineReason']),
      variantGroup: serializer.fromJson<int?>(json['variantGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<String>(gameId),
      'title': serializer.toJson<String>(title),
      'platform': serializer.toJson<String>(platform),
      'region': serializer.toJson<String?>(region),
      'format': serializer.toJson<String>(format),
      'filePath': serializer.toJson<String>(filePath),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'sha1Partial': serializer.toJson<String?>(sha1Partial),
      'sha1Full': serializer.toJson<String?>(sha1Full),
      'addedTimestamp': serializer.toJson<int>(addedTimestamp),
      'modifiedTimestamp': serializer.toJson<int>(modifiedTimestamp),
      'lastVerified': serializer.toJson<int?>(lastVerified),
      'healthStatus': serializer.toJson<String>(healthStatus),
      'hasCover': serializer.toJson<int>(hasCover),
      'hasMetadata': serializer.toJson<int>(hasMetadata),
      'isQuarantined': serializer.toJson<int>(isQuarantined),
      'quarantineReason': serializer.toJson<String?>(quarantineReason),
      'variantGroup': serializer.toJson<int?>(variantGroup),
    };
  }

  Title copyWith(
          {int? id,
          String? gameId,
          String? title,
          String? platform,
          Value<String?> region = const Value.absent(),
          String? format,
          String? filePath,
          int? fileSizeBytes,
          Value<String?> sha1Partial = const Value.absent(),
          Value<String?> sha1Full = const Value.absent(),
          int? addedTimestamp,
          int? modifiedTimestamp,
          Value<int?> lastVerified = const Value.absent(),
          String? healthStatus,
          int? hasCover,
          int? hasMetadata,
          int? isQuarantined,
          Value<String?> quarantineReason = const Value.absent(),
          Value<int?> variantGroup = const Value.absent()}) =>
      Title(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        title: title ?? this.title,
        platform: platform ?? this.platform,
        region: region.present ? region.value : this.region,
        format: format ?? this.format,
        filePath: filePath ?? this.filePath,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        sha1Partial: sha1Partial.present ? sha1Partial.value : this.sha1Partial,
        sha1Full: sha1Full.present ? sha1Full.value : this.sha1Full,
        addedTimestamp: addedTimestamp ?? this.addedTimestamp,
        modifiedTimestamp: modifiedTimestamp ?? this.modifiedTimestamp,
        lastVerified:
            lastVerified.present ? lastVerified.value : this.lastVerified,
        healthStatus: healthStatus ?? this.healthStatus,
        hasCover: hasCover ?? this.hasCover,
        hasMetadata: hasMetadata ?? this.hasMetadata,
        isQuarantined: isQuarantined ?? this.isQuarantined,
        quarantineReason: quarantineReason.present
            ? quarantineReason.value
            : this.quarantineReason,
        variantGroup:
            variantGroup.present ? variantGroup.value : this.variantGroup,
      );
  Title copyWithCompanion(TitlesCompanion data) {
    return Title(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      title: data.title.present ? data.title.value : this.title,
      platform: data.platform.present ? data.platform.value : this.platform,
      region: data.region.present ? data.region.value : this.region,
      format: data.format.present ? data.format.value : this.format,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      sha1Partial:
          data.sha1Partial.present ? data.sha1Partial.value : this.sha1Partial,
      sha1Full: data.sha1Full.present ? data.sha1Full.value : this.sha1Full,
      addedTimestamp: data.addedTimestamp.present
          ? data.addedTimestamp.value
          : this.addedTimestamp,
      modifiedTimestamp: data.modifiedTimestamp.present
          ? data.modifiedTimestamp.value
          : this.modifiedTimestamp,
      lastVerified: data.lastVerified.present
          ? data.lastVerified.value
          : this.lastVerified,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      hasCover: data.hasCover.present ? data.hasCover.value : this.hasCover,
      hasMetadata:
          data.hasMetadata.present ? data.hasMetadata.value : this.hasMetadata,
      isQuarantined: data.isQuarantined.present
          ? data.isQuarantined.value
          : this.isQuarantined,
      quarantineReason: data.quarantineReason.present
          ? data.quarantineReason.value
          : this.quarantineReason,
      variantGroup: data.variantGroup.present
          ? data.variantGroup.value
          : this.variantGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Title(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('platform: $platform, ')
          ..write('region: $region, ')
          ..write('format: $format, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('sha1Partial: $sha1Partial, ')
          ..write('sha1Full: $sha1Full, ')
          ..write('addedTimestamp: $addedTimestamp, ')
          ..write('modifiedTimestamp: $modifiedTimestamp, ')
          ..write('lastVerified: $lastVerified, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('hasCover: $hasCover, ')
          ..write('hasMetadata: $hasMetadata, ')
          ..write('isQuarantined: $isQuarantined, ')
          ..write('quarantineReason: $quarantineReason, ')
          ..write('variantGroup: $variantGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      gameId,
      title,
      platform,
      region,
      format,
      filePath,
      fileSizeBytes,
      sha1Partial,
      sha1Full,
      addedTimestamp,
      modifiedTimestamp,
      lastVerified,
      healthStatus,
      hasCover,
      hasMetadata,
      isQuarantined,
      quarantineReason,
      variantGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Title &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.title == this.title &&
          other.platform == this.platform &&
          other.region == this.region &&
          other.format == this.format &&
          other.filePath == this.filePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.sha1Partial == this.sha1Partial &&
          other.sha1Full == this.sha1Full &&
          other.addedTimestamp == this.addedTimestamp &&
          other.modifiedTimestamp == this.modifiedTimestamp &&
          other.lastVerified == this.lastVerified &&
          other.healthStatus == this.healthStatus &&
          other.hasCover == this.hasCover &&
          other.hasMetadata == this.hasMetadata &&
          other.isQuarantined == this.isQuarantined &&
          other.quarantineReason == this.quarantineReason &&
          other.variantGroup == this.variantGroup);
}

class TitlesCompanion extends UpdateCompanion<Title> {
  final Value<int> id;
  final Value<String> gameId;
  final Value<String> title;
  final Value<String> platform;
  final Value<String?> region;
  final Value<String> format;
  final Value<String> filePath;
  final Value<int> fileSizeBytes;
  final Value<String?> sha1Partial;
  final Value<String?> sha1Full;
  final Value<int> addedTimestamp;
  final Value<int> modifiedTimestamp;
  final Value<int?> lastVerified;
  final Value<String> healthStatus;
  final Value<int> hasCover;
  final Value<int> hasMetadata;
  final Value<int> isQuarantined;
  final Value<String?> quarantineReason;
  final Value<int?> variantGroup;
  const TitlesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.title = const Value.absent(),
    this.platform = const Value.absent(),
    this.region = const Value.absent(),
    this.format = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.sha1Partial = const Value.absent(),
    this.sha1Full = const Value.absent(),
    this.addedTimestamp = const Value.absent(),
    this.modifiedTimestamp = const Value.absent(),
    this.lastVerified = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.hasCover = const Value.absent(),
    this.hasMetadata = const Value.absent(),
    this.isQuarantined = const Value.absent(),
    this.quarantineReason = const Value.absent(),
    this.variantGroup = const Value.absent(),
  });
  TitlesCompanion.insert({
    this.id = const Value.absent(),
    required String gameId,
    required String title,
    required String platform,
    this.region = const Value.absent(),
    required String format,
    required String filePath,
    required int fileSizeBytes,
    this.sha1Partial = const Value.absent(),
    this.sha1Full = const Value.absent(),
    required int addedTimestamp,
    required int modifiedTimestamp,
    this.lastVerified = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.hasCover = const Value.absent(),
    this.hasMetadata = const Value.absent(),
    this.isQuarantined = const Value.absent(),
    this.quarantineReason = const Value.absent(),
    this.variantGroup = const Value.absent(),
  })  : gameId = Value(gameId),
        title = Value(title),
        platform = Value(platform),
        format = Value(format),
        filePath = Value(filePath),
        fileSizeBytes = Value(fileSizeBytes),
        addedTimestamp = Value(addedTimestamp),
        modifiedTimestamp = Value(modifiedTimestamp);
  static Insertable<Title> custom({
    Expression<int>? id,
    Expression<String>? gameId,
    Expression<String>? title,
    Expression<String>? platform,
    Expression<String>? region,
    Expression<String>? format,
    Expression<String>? filePath,
    Expression<int>? fileSizeBytes,
    Expression<String>? sha1Partial,
    Expression<String>? sha1Full,
    Expression<int>? addedTimestamp,
    Expression<int>? modifiedTimestamp,
    Expression<int>? lastVerified,
    Expression<String>? healthStatus,
    Expression<int>? hasCover,
    Expression<int>? hasMetadata,
    Expression<int>? isQuarantined,
    Expression<String>? quarantineReason,
    Expression<int>? variantGroup,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (title != null) 'title': title,
      if (platform != null) 'platform': platform,
      if (region != null) 'region': region,
      if (format != null) 'format': format,
      if (filePath != null) 'file_path': filePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (sha1Partial != null) 'sha1_partial': sha1Partial,
      if (sha1Full != null) 'sha1_full': sha1Full,
      if (addedTimestamp != null) 'added_timestamp': addedTimestamp,
      if (modifiedTimestamp != null) 'modified_timestamp': modifiedTimestamp,
      if (lastVerified != null) 'last_verified': lastVerified,
      if (healthStatus != null) 'health_status': healthStatus,
      if (hasCover != null) 'has_cover': hasCover,
      if (hasMetadata != null) 'has_metadata': hasMetadata,
      if (isQuarantined != null) 'is_quarantined': isQuarantined,
      if (quarantineReason != null) 'quarantine_reason': quarantineReason,
      if (variantGroup != null) 'variant_group': variantGroup,
    });
  }

  TitlesCompanion copyWith(
      {Value<int>? id,
      Value<String>? gameId,
      Value<String>? title,
      Value<String>? platform,
      Value<String?>? region,
      Value<String>? format,
      Value<String>? filePath,
      Value<int>? fileSizeBytes,
      Value<String?>? sha1Partial,
      Value<String?>? sha1Full,
      Value<int>? addedTimestamp,
      Value<int>? modifiedTimestamp,
      Value<int?>? lastVerified,
      Value<String>? healthStatus,
      Value<int>? hasCover,
      Value<int>? hasMetadata,
      Value<int>? isQuarantined,
      Value<String?>? quarantineReason,
      Value<int?>? variantGroup}) {
    return TitlesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      region: region ?? this.region,
      format: format ?? this.format,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      sha1Partial: sha1Partial ?? this.sha1Partial,
      sha1Full: sha1Full ?? this.sha1Full,
      addedTimestamp: addedTimestamp ?? this.addedTimestamp,
      modifiedTimestamp: modifiedTimestamp ?? this.modifiedTimestamp,
      lastVerified: lastVerified ?? this.lastVerified,
      healthStatus: healthStatus ?? this.healthStatus,
      hasCover: hasCover ?? this.hasCover,
      hasMetadata: hasMetadata ?? this.hasMetadata,
      isQuarantined: isQuarantined ?? this.isQuarantined,
      quarantineReason: quarantineReason ?? this.quarantineReason,
      variantGroup: variantGroup ?? this.variantGroup,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (sha1Partial.present) {
      map['sha1_partial'] = Variable<String>(sha1Partial.value);
    }
    if (sha1Full.present) {
      map['sha1_full'] = Variable<String>(sha1Full.value);
    }
    if (addedTimestamp.present) {
      map['added_timestamp'] = Variable<int>(addedTimestamp.value);
    }
    if (modifiedTimestamp.present) {
      map['modified_timestamp'] = Variable<int>(modifiedTimestamp.value);
    }
    if (lastVerified.present) {
      map['last_verified'] = Variable<int>(lastVerified.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (hasCover.present) {
      map['has_cover'] = Variable<int>(hasCover.value);
    }
    if (hasMetadata.present) {
      map['has_metadata'] = Variable<int>(hasMetadata.value);
    }
    if (isQuarantined.present) {
      map['is_quarantined'] = Variable<int>(isQuarantined.value);
    }
    if (quarantineReason.present) {
      map['quarantine_reason'] = Variable<String>(quarantineReason.value);
    }
    if (variantGroup.present) {
      map['variant_group'] = Variable<int>(variantGroup.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TitlesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('platform: $platform, ')
          ..write('region: $region, ')
          ..write('format: $format, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('sha1Partial: $sha1Partial, ')
          ..write('sha1Full: $sha1Full, ')
          ..write('addedTimestamp: $addedTimestamp, ')
          ..write('modifiedTimestamp: $modifiedTimestamp, ')
          ..write('lastVerified: $lastVerified, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('hasCover: $hasCover, ')
          ..write('hasMetadata: $hasMetadata, ')
          ..write('isQuarantined: $isQuarantined, ')
          ..write('quarantineReason: $quarantineReason, ')
          ..write('variantGroup: $variantGroup')
          ..write(')'))
        .toString();
  }
}

class $IssuesTable extends Issues with TableInfo<$IssuesTable, Issue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IssuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleIdMeta =
      const VerificationMeta('titleId');
  @override
  late final GeneratedColumn<int> titleId = GeneratedColumn<int>(
      'title_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES titles (id)'));
  static const VerificationMeta _issueTypeMeta =
      const VerificationMeta('issueType');
  @override
  late final GeneratedColumn<String> issueType = GeneratedColumn<String>(
      'issue_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _estimatedImpactScoreMeta =
      const VerificationMeta('estimatedImpactScore');
  @override
  late final GeneratedColumn<int> estimatedImpactScore = GeneratedColumn<int>(
      'estimated_impact_score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _estimatedSpaceSavingsMeta =
      const VerificationMeta('estimatedSpaceSavings');
  @override
  late final GeneratedColumn<int> estimatedSpaceSavings = GeneratedColumn<int>(
      'estimated_space_savings', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fixActionMeta =
      const VerificationMeta('fixAction');
  @override
  late final GeneratedColumn<String> fixAction = GeneratedColumn<String>(
      'fix_action', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdTimestampMeta =
      const VerificationMeta('createdTimestamp');
  @override
  late final GeneratedColumn<int> createdTimestamp = GeneratedColumn<int>(
      'created_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resolvedTimestampMeta =
      const VerificationMeta('resolvedTimestamp');
  @override
  late final GeneratedColumn<int> resolvedTimestamp = GeneratedColumn<int>(
      'resolved_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        titleId,
        issueType,
        severity,
        description,
        estimatedImpactScore,
        estimatedSpaceSavings,
        fixAction,
        createdTimestamp,
        resolvedTimestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'issues';
  @override
  VerificationContext validateIntegrity(Insertable<Issue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title_id')) {
      context.handle(_titleIdMeta,
          titleId.isAcceptableOrUnknown(data['title_id']!, _titleIdMeta));
    }
    if (data.containsKey('issue_type')) {
      context.handle(_issueTypeMeta,
          issueType.isAcceptableOrUnknown(data['issue_type']!, _issueTypeMeta));
    } else if (isInserting) {
      context.missing(_issueTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('estimated_impact_score')) {
      context.handle(
          _estimatedImpactScoreMeta,
          estimatedImpactScore.isAcceptableOrUnknown(
              data['estimated_impact_score']!, _estimatedImpactScoreMeta));
    }
    if (data.containsKey('estimated_space_savings')) {
      context.handle(
          _estimatedSpaceSavingsMeta,
          estimatedSpaceSavings.isAcceptableOrUnknown(
              data['estimated_space_savings']!, _estimatedSpaceSavingsMeta));
    }
    if (data.containsKey('fix_action')) {
      context.handle(_fixActionMeta,
          fixAction.isAcceptableOrUnknown(data['fix_action']!, _fixActionMeta));
    }
    if (data.containsKey('created_timestamp')) {
      context.handle(
          _createdTimestampMeta,
          createdTimestamp.isAcceptableOrUnknown(
              data['created_timestamp']!, _createdTimestampMeta));
    } else if (isInserting) {
      context.missing(_createdTimestampMeta);
    }
    if (data.containsKey('resolved_timestamp')) {
      context.handle(
          _resolvedTimestampMeta,
          resolvedTimestamp.isAcceptableOrUnknown(
              data['resolved_timestamp']!, _resolvedTimestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Issue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Issue(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      titleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}title_id']),
      issueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issue_type'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      estimatedImpactScore: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}estimated_impact_score'])!,
      estimatedSpaceSavings: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}estimated_space_savings'])!,
      fixAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fix_action']),
      createdTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_timestamp'])!,
      resolvedTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}resolved_timestamp']),
    );
  }

  @override
  $IssuesTable createAlias(String alias) {
    return $IssuesTable(attachedDatabase, alias);
  }
}

class Issue extends DataClass implements Insertable<Issue> {
  final int id;
  final int? titleId;
  final String issueType;
  final String severity;
  final String description;
  final int estimatedImpactScore;
  final int estimatedSpaceSavings;
  final String? fixAction;
  final int createdTimestamp;
  final int? resolvedTimestamp;
  const Issue(
      {required this.id,
      this.titleId,
      required this.issueType,
      required this.severity,
      required this.description,
      required this.estimatedImpactScore,
      required this.estimatedSpaceSavings,
      this.fixAction,
      required this.createdTimestamp,
      this.resolvedTimestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || titleId != null) {
      map['title_id'] = Variable<int>(titleId);
    }
    map['issue_type'] = Variable<String>(issueType);
    map['severity'] = Variable<String>(severity);
    map['description'] = Variable<String>(description);
    map['estimated_impact_score'] = Variable<int>(estimatedImpactScore);
    map['estimated_space_savings'] = Variable<int>(estimatedSpaceSavings);
    if (!nullToAbsent || fixAction != null) {
      map['fix_action'] = Variable<String>(fixAction);
    }
    map['created_timestamp'] = Variable<int>(createdTimestamp);
    if (!nullToAbsent || resolvedTimestamp != null) {
      map['resolved_timestamp'] = Variable<int>(resolvedTimestamp);
    }
    return map;
  }

  IssuesCompanion toCompanion(bool nullToAbsent) {
    return IssuesCompanion(
      id: Value(id),
      titleId: titleId == null && nullToAbsent
          ? const Value.absent()
          : Value(titleId),
      issueType: Value(issueType),
      severity: Value(severity),
      description: Value(description),
      estimatedImpactScore: Value(estimatedImpactScore),
      estimatedSpaceSavings: Value(estimatedSpaceSavings),
      fixAction: fixAction == null && nullToAbsent
          ? const Value.absent()
          : Value(fixAction),
      createdTimestamp: Value(createdTimestamp),
      resolvedTimestamp: resolvedTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedTimestamp),
    );
  }

  factory Issue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Issue(
      id: serializer.fromJson<int>(json['id']),
      titleId: serializer.fromJson<int?>(json['titleId']),
      issueType: serializer.fromJson<String>(json['issueType']),
      severity: serializer.fromJson<String>(json['severity']),
      description: serializer.fromJson<String>(json['description']),
      estimatedImpactScore:
          serializer.fromJson<int>(json['estimatedImpactScore']),
      estimatedSpaceSavings:
          serializer.fromJson<int>(json['estimatedSpaceSavings']),
      fixAction: serializer.fromJson<String?>(json['fixAction']),
      createdTimestamp: serializer.fromJson<int>(json['createdTimestamp']),
      resolvedTimestamp: serializer.fromJson<int?>(json['resolvedTimestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titleId': serializer.toJson<int?>(titleId),
      'issueType': serializer.toJson<String>(issueType),
      'severity': serializer.toJson<String>(severity),
      'description': serializer.toJson<String>(description),
      'estimatedImpactScore': serializer.toJson<int>(estimatedImpactScore),
      'estimatedSpaceSavings': serializer.toJson<int>(estimatedSpaceSavings),
      'fixAction': serializer.toJson<String?>(fixAction),
      'createdTimestamp': serializer.toJson<int>(createdTimestamp),
      'resolvedTimestamp': serializer.toJson<int?>(resolvedTimestamp),
    };
  }

  Issue copyWith(
          {int? id,
          Value<int?> titleId = const Value.absent(),
          String? issueType,
          String? severity,
          String? description,
          int? estimatedImpactScore,
          int? estimatedSpaceSavings,
          Value<String?> fixAction = const Value.absent(),
          int? createdTimestamp,
          Value<int?> resolvedTimestamp = const Value.absent()}) =>
      Issue(
        id: id ?? this.id,
        titleId: titleId.present ? titleId.value : this.titleId,
        issueType: issueType ?? this.issueType,
        severity: severity ?? this.severity,
        description: description ?? this.description,
        estimatedImpactScore: estimatedImpactScore ?? this.estimatedImpactScore,
        estimatedSpaceSavings:
            estimatedSpaceSavings ?? this.estimatedSpaceSavings,
        fixAction: fixAction.present ? fixAction.value : this.fixAction,
        createdTimestamp: createdTimestamp ?? this.createdTimestamp,
        resolvedTimestamp: resolvedTimestamp.present
            ? resolvedTimestamp.value
            : this.resolvedTimestamp,
      );
  Issue copyWithCompanion(IssuesCompanion data) {
    return Issue(
      id: data.id.present ? data.id.value : this.id,
      titleId: data.titleId.present ? data.titleId.value : this.titleId,
      issueType: data.issueType.present ? data.issueType.value : this.issueType,
      severity: data.severity.present ? data.severity.value : this.severity,
      description:
          data.description.present ? data.description.value : this.description,
      estimatedImpactScore: data.estimatedImpactScore.present
          ? data.estimatedImpactScore.value
          : this.estimatedImpactScore,
      estimatedSpaceSavings: data.estimatedSpaceSavings.present
          ? data.estimatedSpaceSavings.value
          : this.estimatedSpaceSavings,
      fixAction: data.fixAction.present ? data.fixAction.value : this.fixAction,
      createdTimestamp: data.createdTimestamp.present
          ? data.createdTimestamp.value
          : this.createdTimestamp,
      resolvedTimestamp: data.resolvedTimestamp.present
          ? data.resolvedTimestamp.value
          : this.resolvedTimestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Issue(')
          ..write('id: $id, ')
          ..write('titleId: $titleId, ')
          ..write('issueType: $issueType, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('estimatedImpactScore: $estimatedImpactScore, ')
          ..write('estimatedSpaceSavings: $estimatedSpaceSavings, ')
          ..write('fixAction: $fixAction, ')
          ..write('createdTimestamp: $createdTimestamp, ')
          ..write('resolvedTimestamp: $resolvedTimestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      titleId,
      issueType,
      severity,
      description,
      estimatedImpactScore,
      estimatedSpaceSavings,
      fixAction,
      createdTimestamp,
      resolvedTimestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Issue &&
          other.id == this.id &&
          other.titleId == this.titleId &&
          other.issueType == this.issueType &&
          other.severity == this.severity &&
          other.description == this.description &&
          other.estimatedImpactScore == this.estimatedImpactScore &&
          other.estimatedSpaceSavings == this.estimatedSpaceSavings &&
          other.fixAction == this.fixAction &&
          other.createdTimestamp == this.createdTimestamp &&
          other.resolvedTimestamp == this.resolvedTimestamp);
}

class IssuesCompanion extends UpdateCompanion<Issue> {
  final Value<int> id;
  final Value<int?> titleId;
  final Value<String> issueType;
  final Value<String> severity;
  final Value<String> description;
  final Value<int> estimatedImpactScore;
  final Value<int> estimatedSpaceSavings;
  final Value<String?> fixAction;
  final Value<int> createdTimestamp;
  final Value<int?> resolvedTimestamp;
  const IssuesCompanion({
    this.id = const Value.absent(),
    this.titleId = const Value.absent(),
    this.issueType = const Value.absent(),
    this.severity = const Value.absent(),
    this.description = const Value.absent(),
    this.estimatedImpactScore = const Value.absent(),
    this.estimatedSpaceSavings = const Value.absent(),
    this.fixAction = const Value.absent(),
    this.createdTimestamp = const Value.absent(),
    this.resolvedTimestamp = const Value.absent(),
  });
  IssuesCompanion.insert({
    this.id = const Value.absent(),
    this.titleId = const Value.absent(),
    required String issueType,
    required String severity,
    required String description,
    this.estimatedImpactScore = const Value.absent(),
    this.estimatedSpaceSavings = const Value.absent(),
    this.fixAction = const Value.absent(),
    required int createdTimestamp,
    this.resolvedTimestamp = const Value.absent(),
  })  : issueType = Value(issueType),
        severity = Value(severity),
        description = Value(description),
        createdTimestamp = Value(createdTimestamp);
  static Insertable<Issue> custom({
    Expression<int>? id,
    Expression<int>? titleId,
    Expression<String>? issueType,
    Expression<String>? severity,
    Expression<String>? description,
    Expression<int>? estimatedImpactScore,
    Expression<int>? estimatedSpaceSavings,
    Expression<String>? fixAction,
    Expression<int>? createdTimestamp,
    Expression<int>? resolvedTimestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titleId != null) 'title_id': titleId,
      if (issueType != null) 'issue_type': issueType,
      if (severity != null) 'severity': severity,
      if (description != null) 'description': description,
      if (estimatedImpactScore != null)
        'estimated_impact_score': estimatedImpactScore,
      if (estimatedSpaceSavings != null)
        'estimated_space_savings': estimatedSpaceSavings,
      if (fixAction != null) 'fix_action': fixAction,
      if (createdTimestamp != null) 'created_timestamp': createdTimestamp,
      if (resolvedTimestamp != null) 'resolved_timestamp': resolvedTimestamp,
    });
  }

  IssuesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? titleId,
      Value<String>? issueType,
      Value<String>? severity,
      Value<String>? description,
      Value<int>? estimatedImpactScore,
      Value<int>? estimatedSpaceSavings,
      Value<String?>? fixAction,
      Value<int>? createdTimestamp,
      Value<int?>? resolvedTimestamp}) {
    return IssuesCompanion(
      id: id ?? this.id,
      titleId: titleId ?? this.titleId,
      issueType: issueType ?? this.issueType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      estimatedImpactScore: estimatedImpactScore ?? this.estimatedImpactScore,
      estimatedSpaceSavings:
          estimatedSpaceSavings ?? this.estimatedSpaceSavings,
      fixAction: fixAction ?? this.fixAction,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      resolvedTimestamp: resolvedTimestamp ?? this.resolvedTimestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titleId.present) {
      map['title_id'] = Variable<int>(titleId.value);
    }
    if (issueType.present) {
      map['issue_type'] = Variable<String>(issueType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (estimatedImpactScore.present) {
      map['estimated_impact_score'] = Variable<int>(estimatedImpactScore.value);
    }
    if (estimatedSpaceSavings.present) {
      map['estimated_space_savings'] =
          Variable<int>(estimatedSpaceSavings.value);
    }
    if (fixAction.present) {
      map['fix_action'] = Variable<String>(fixAction.value);
    }
    if (createdTimestamp.present) {
      map['created_timestamp'] = Variable<int>(createdTimestamp.value);
    }
    if (resolvedTimestamp.present) {
      map['resolved_timestamp'] = Variable<int>(resolvedTimestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IssuesCompanion(')
          ..write('id: $id, ')
          ..write('titleId: $titleId, ')
          ..write('issueType: $issueType, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('estimatedImpactScore: $estimatedImpactScore, ')
          ..write('estimatedSpaceSavings: $estimatedSpaceSavings, ')
          ..write('fixAction: $fixAction, ')
          ..write('createdTimestamp: $createdTimestamp, ')
          ..write('resolvedTimestamp: $resolvedTimestamp')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
      'task_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _progressPercentMeta =
      const VerificationMeta('progressPercent');
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
      'progress_percent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _progressMessageMeta =
      const VerificationMeta('progressMessage');
  @override
  late final GeneratedColumn<String> progressMessage = GeneratedColumn<String>(
      'progress_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedTimestampMeta =
      const VerificationMeta('startedTimestamp');
  @override
  late final GeneratedColumn<int> startedTimestamp = GeneratedColumn<int>(
      'started_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _completedTimestampMeta =
      const VerificationMeta('completedTimestamp');
  @override
  late final GeneratedColumn<int> completedTimestamp = GeneratedColumn<int>(
      'completed_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dependsOnMeta =
      const VerificationMeta('dependsOn');
  @override
  late final GeneratedColumn<int> dependsOn = GeneratedColumn<int>(
      'depends_on', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _logPathMeta =
      const VerificationMeta('logPath');
  @override
  late final GeneratedColumn<String> logPath = GeneratedColumn<String>(
      'log_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        taskType,
        state,
        priority,
        payload,
        progressPercent,
        progressMessage,
        startedTimestamp,
        completedTimestamp,
        errorMessage,
        dependsOn,
        retryCount,
        logPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
          _progressPercentMeta,
          progressPercent.isAcceptableOrUnknown(
              data['progress_percent']!, _progressPercentMeta));
    }
    if (data.containsKey('progress_message')) {
      context.handle(
          _progressMessageMeta,
          progressMessage.isAcceptableOrUnknown(
              data['progress_message']!, _progressMessageMeta));
    }
    if (data.containsKey('started_timestamp')) {
      context.handle(
          _startedTimestampMeta,
          startedTimestamp.isAcceptableOrUnknown(
              data['started_timestamp']!, _startedTimestampMeta));
    }
    if (data.containsKey('completed_timestamp')) {
      context.handle(
          _completedTimestampMeta,
          completedTimestamp.isAcceptableOrUnknown(
              data['completed_timestamp']!, _completedTimestampMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('depends_on')) {
      context.handle(_dependsOnMeta,
          dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('log_path')) {
      context.handle(_logPathMeta,
          logPath.isAcceptableOrUnknown(data['log_path']!, _logPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_type'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      progressPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}progress_percent'])!,
      progressMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}progress_message']),
      startedTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_timestamp']),
      completedTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_timestamp']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      dependsOn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}depends_on']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      logPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}log_path']),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String taskType;
  final String state;
  final int priority;
  final String payload;
  final double progressPercent;
  final String? progressMessage;
  final int? startedTimestamp;
  final int? completedTimestamp;
  final String? errorMessage;
  final int? dependsOn;
  final int retryCount;
  final String? logPath;
  const Task(
      {required this.id,
      required this.taskType,
      required this.state,
      required this.priority,
      required this.payload,
      required this.progressPercent,
      this.progressMessage,
      this.startedTimestamp,
      this.completedTimestamp,
      this.errorMessage,
      this.dependsOn,
      required this.retryCount,
      this.logPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_type'] = Variable<String>(taskType);
    map['state'] = Variable<String>(state);
    map['priority'] = Variable<int>(priority);
    map['payload'] = Variable<String>(payload);
    map['progress_percent'] = Variable<double>(progressPercent);
    if (!nullToAbsent || progressMessage != null) {
      map['progress_message'] = Variable<String>(progressMessage);
    }
    if (!nullToAbsent || startedTimestamp != null) {
      map['started_timestamp'] = Variable<int>(startedTimestamp);
    }
    if (!nullToAbsent || completedTimestamp != null) {
      map['completed_timestamp'] = Variable<int>(completedTimestamp);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || dependsOn != null) {
      map['depends_on'] = Variable<int>(dependsOn);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || logPath != null) {
      map['log_path'] = Variable<String>(logPath);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      taskType: Value(taskType),
      state: Value(state),
      priority: Value(priority),
      payload: Value(payload),
      progressPercent: Value(progressPercent),
      progressMessage: progressMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(progressMessage),
      startedTimestamp: startedTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(startedTimestamp),
      completedTimestamp: completedTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(completedTimestamp),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      dependsOn: dependsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOn),
      retryCount: Value(retryCount),
      logPath: logPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logPath),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      taskType: serializer.fromJson<String>(json['taskType']),
      state: serializer.fromJson<String>(json['state']),
      priority: serializer.fromJson<int>(json['priority']),
      payload: serializer.fromJson<String>(json['payload']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      progressMessage: serializer.fromJson<String?>(json['progressMessage']),
      startedTimestamp: serializer.fromJson<int?>(json['startedTimestamp']),
      completedTimestamp: serializer.fromJson<int?>(json['completedTimestamp']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      dependsOn: serializer.fromJson<int?>(json['dependsOn']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      logPath: serializer.fromJson<String?>(json['logPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskType': serializer.toJson<String>(taskType),
      'state': serializer.toJson<String>(state),
      'priority': serializer.toJson<int>(priority),
      'payload': serializer.toJson<String>(payload),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'progressMessage': serializer.toJson<String?>(progressMessage),
      'startedTimestamp': serializer.toJson<int?>(startedTimestamp),
      'completedTimestamp': serializer.toJson<int?>(completedTimestamp),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'dependsOn': serializer.toJson<int?>(dependsOn),
      'retryCount': serializer.toJson<int>(retryCount),
      'logPath': serializer.toJson<String?>(logPath),
    };
  }

  Task copyWith(
          {int? id,
          String? taskType,
          String? state,
          int? priority,
          String? payload,
          double? progressPercent,
          Value<String?> progressMessage = const Value.absent(),
          Value<int?> startedTimestamp = const Value.absent(),
          Value<int?> completedTimestamp = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          Value<int?> dependsOn = const Value.absent(),
          int? retryCount,
          Value<String?> logPath = const Value.absent()}) =>
      Task(
        id: id ?? this.id,
        taskType: taskType ?? this.taskType,
        state: state ?? this.state,
        priority: priority ?? this.priority,
        payload: payload ?? this.payload,
        progressPercent: progressPercent ?? this.progressPercent,
        progressMessage: progressMessage.present
            ? progressMessage.value
            : this.progressMessage,
        startedTimestamp: startedTimestamp.present
            ? startedTimestamp.value
            : this.startedTimestamp,
        completedTimestamp: completedTimestamp.present
            ? completedTimestamp.value
            : this.completedTimestamp,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        dependsOn: dependsOn.present ? dependsOn.value : this.dependsOn,
        retryCount: retryCount ?? this.retryCount,
        logPath: logPath.present ? logPath.value : this.logPath,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      state: data.state.present ? data.state.value : this.state,
      priority: data.priority.present ? data.priority.value : this.priority,
      payload: data.payload.present ? data.payload.value : this.payload,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      progressMessage: data.progressMessage.present
          ? data.progressMessage.value
          : this.progressMessage,
      startedTimestamp: data.startedTimestamp.present
          ? data.startedTimestamp.value
          : this.startedTimestamp,
      completedTimestamp: data.completedTimestamp.present
          ? data.completedTimestamp.value
          : this.completedTimestamp,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      logPath: data.logPath.present ? data.logPath.value : this.logPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('state: $state, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('progressMessage: $progressMessage, ')
          ..write('startedTimestamp: $startedTimestamp, ')
          ..write('completedTimestamp: $completedTimestamp, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('retryCount: $retryCount, ')
          ..write('logPath: $logPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      taskType,
      state,
      priority,
      payload,
      progressPercent,
      progressMessage,
      startedTimestamp,
      completedTimestamp,
      errorMessage,
      dependsOn,
      retryCount,
      logPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.taskType == this.taskType &&
          other.state == this.state &&
          other.priority == this.priority &&
          other.payload == this.payload &&
          other.progressPercent == this.progressPercent &&
          other.progressMessage == this.progressMessage &&
          other.startedTimestamp == this.startedTimestamp &&
          other.completedTimestamp == this.completedTimestamp &&
          other.errorMessage == this.errorMessage &&
          other.dependsOn == this.dependsOn &&
          other.retryCount == this.retryCount &&
          other.logPath == this.logPath);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> taskType;
  final Value<String> state;
  final Value<int> priority;
  final Value<String> payload;
  final Value<double> progressPercent;
  final Value<String?> progressMessage;
  final Value<int?> startedTimestamp;
  final Value<int?> completedTimestamp;
  final Value<String?> errorMessage;
  final Value<int?> dependsOn;
  final Value<int> retryCount;
  final Value<String?> logPath;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.taskType = const Value.absent(),
    this.state = const Value.absent(),
    this.priority = const Value.absent(),
    this.payload = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.progressMessage = const Value.absent(),
    this.startedTimestamp = const Value.absent(),
    this.completedTimestamp = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.logPath = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String taskType,
    required String state,
    this.priority = const Value.absent(),
    required String payload,
    this.progressPercent = const Value.absent(),
    this.progressMessage = const Value.absent(),
    this.startedTimestamp = const Value.absent(),
    this.completedTimestamp = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.logPath = const Value.absent(),
  })  : taskType = Value(taskType),
        state = Value(state),
        payload = Value(payload);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? taskType,
    Expression<String>? state,
    Expression<int>? priority,
    Expression<String>? payload,
    Expression<double>? progressPercent,
    Expression<String>? progressMessage,
    Expression<int>? startedTimestamp,
    Expression<int>? completedTimestamp,
    Expression<String>? errorMessage,
    Expression<int>? dependsOn,
    Expression<int>? retryCount,
    Expression<String>? logPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskType != null) 'task_type': taskType,
      if (state != null) 'state': state,
      if (priority != null) 'priority': priority,
      if (payload != null) 'payload': payload,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (progressMessage != null) 'progress_message': progressMessage,
      if (startedTimestamp != null) 'started_timestamp': startedTimestamp,
      if (completedTimestamp != null) 'completed_timestamp': completedTimestamp,
      if (errorMessage != null) 'error_message': errorMessage,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (retryCount != null) 'retry_count': retryCount,
      if (logPath != null) 'log_path': logPath,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? taskType,
      Value<String>? state,
      Value<int>? priority,
      Value<String>? payload,
      Value<double>? progressPercent,
      Value<String?>? progressMessage,
      Value<int?>? startedTimestamp,
      Value<int?>? completedTimestamp,
      Value<String?>? errorMessage,
      Value<int?>? dependsOn,
      Value<int>? retryCount,
      Value<String?>? logPath}) {
    return TasksCompanion(
      id: id ?? this.id,
      taskType: taskType ?? this.taskType,
      state: state ?? this.state,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      progressPercent: progressPercent ?? this.progressPercent,
      progressMessage: progressMessage ?? this.progressMessage,
      startedTimestamp: startedTimestamp ?? this.startedTimestamp,
      completedTimestamp: completedTimestamp ?? this.completedTimestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      dependsOn: dependsOn ?? this.dependsOn,
      retryCount: retryCount ?? this.retryCount,
      logPath: logPath ?? this.logPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (progressMessage.present) {
      map['progress_message'] = Variable<String>(progressMessage.value);
    }
    if (startedTimestamp.present) {
      map['started_timestamp'] = Variable<int>(startedTimestamp.value);
    }
    if (completedTimestamp.present) {
      map['completed_timestamp'] = Variable<int>(completedTimestamp.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<int>(dependsOn.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (logPath.present) {
      map['log_path'] = Variable<String>(logPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('state: $state, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('progressMessage: $progressMessage, ')
          ..write('startedTimestamp: $startedTimestamp, ')
          ..write('completedTimestamp: $completedTimestamp, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('retryCount: $retryCount, ')
          ..write('logPath: $logPath')
          ..write(')'))
        .toString();
  }
}

class $HealthSnapshotsTable extends HealthSnapshots
    with TableInfo<$HealthSnapshotsTable, HealthSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalTitlesMeta =
      const VerificationMeta('totalTitles');
  @override
  late final GeneratedColumn<int> totalTitles = GeneratedColumn<int>(
      'total_titles', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _healthyCountMeta =
      const VerificationMeta('healthyCount');
  @override
  late final GeneratedColumn<int> healthyCount = GeneratedColumn<int>(
      'healthy_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _duplicateCountMeta =
      const VerificationMeta('duplicateCount');
  @override
  late final GeneratedColumn<int> duplicateCount = GeneratedColumn<int>(
      'duplicate_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _corruptedCountMeta =
      const VerificationMeta('corruptedCount');
  @override
  late final GeneratedColumn<int> corruptedCount = GeneratedColumn<int>(
      'corrupted_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _missingMetadataCountMeta =
      const VerificationMeta('missingMetadataCount');
  @override
  late final GeneratedColumn<int> missingMetadataCount = GeneratedColumn<int>(
      'missing_metadata_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSizeBytesMeta =
      const VerificationMeta('totalSizeBytes');
  @override
  late final GeneratedColumn<int> totalSizeBytes = GeneratedColumn<int>(
      'total_size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _potentialSavingsBytesMeta =
      const VerificationMeta('potentialSavingsBytes');
  @override
  late final GeneratedColumn<int> potentialSavingsBytes = GeneratedColumn<int>(
      'potential_savings_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        timestamp,
        score,
        totalTitles,
        healthyCount,
        duplicateCount,
        corruptedCount,
        missingMetadataCount,
        totalSizeBytes,
        potentialSavingsBytes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<HealthSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('total_titles')) {
      context.handle(
          _totalTitlesMeta,
          totalTitles.isAcceptableOrUnknown(
              data['total_titles']!, _totalTitlesMeta));
    }
    if (data.containsKey('healthy_count')) {
      context.handle(
          _healthyCountMeta,
          healthyCount.isAcceptableOrUnknown(
              data['healthy_count']!, _healthyCountMeta));
    }
    if (data.containsKey('duplicate_count')) {
      context.handle(
          _duplicateCountMeta,
          duplicateCount.isAcceptableOrUnknown(
              data['duplicate_count']!, _duplicateCountMeta));
    }
    if (data.containsKey('corrupted_count')) {
      context.handle(
          _corruptedCountMeta,
          corruptedCount.isAcceptableOrUnknown(
              data['corrupted_count']!, _corruptedCountMeta));
    }
    if (data.containsKey('missing_metadata_count')) {
      context.handle(
          _missingMetadataCountMeta,
          missingMetadataCount.isAcceptableOrUnknown(
              data['missing_metadata_count']!, _missingMetadataCountMeta));
    }
    if (data.containsKey('total_size_bytes')) {
      context.handle(
          _totalSizeBytesMeta,
          totalSizeBytes.isAcceptableOrUnknown(
              data['total_size_bytes']!, _totalSizeBytesMeta));
    }
    if (data.containsKey('potential_savings_bytes')) {
      context.handle(
          _potentialSavingsBytesMeta,
          potentialSavingsBytes.isAcceptableOrUnknown(
              data['potential_savings_bytes']!, _potentialSavingsBytesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      totalTitles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_titles'])!,
      healthyCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}healthy_count'])!,
      duplicateCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duplicate_count'])!,
      corruptedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}corrupted_count'])!,
      missingMetadataCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}missing_metadata_count'])!,
      totalSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_size_bytes'])!,
      potentialSavingsBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}potential_savings_bytes'])!,
    );
  }

  @override
  $HealthSnapshotsTable createAlias(String alias) {
    return $HealthSnapshotsTable(attachedDatabase, alias);
  }
}

class HealthSnapshot extends DataClass implements Insertable<HealthSnapshot> {
  final int id;
  final int timestamp;
  final int score;
  final int totalTitles;
  final int healthyCount;
  final int duplicateCount;
  final int corruptedCount;
  final int missingMetadataCount;
  final int totalSizeBytes;
  final int potentialSavingsBytes;
  const HealthSnapshot(
      {required this.id,
      required this.timestamp,
      required this.score,
      required this.totalTitles,
      required this.healthyCount,
      required this.duplicateCount,
      required this.corruptedCount,
      required this.missingMetadataCount,
      required this.totalSizeBytes,
      required this.potentialSavingsBytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<int>(timestamp);
    map['score'] = Variable<int>(score);
    map['total_titles'] = Variable<int>(totalTitles);
    map['healthy_count'] = Variable<int>(healthyCount);
    map['duplicate_count'] = Variable<int>(duplicateCount);
    map['corrupted_count'] = Variable<int>(corruptedCount);
    map['missing_metadata_count'] = Variable<int>(missingMetadataCount);
    map['total_size_bytes'] = Variable<int>(totalSizeBytes);
    map['potential_savings_bytes'] = Variable<int>(potentialSavingsBytes);
    return map;
  }

  HealthSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return HealthSnapshotsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      score: Value(score),
      totalTitles: Value(totalTitles),
      healthyCount: Value(healthyCount),
      duplicateCount: Value(duplicateCount),
      corruptedCount: Value(corruptedCount),
      missingMetadataCount: Value(missingMetadataCount),
      totalSizeBytes: Value(totalSizeBytes),
      potentialSavingsBytes: Value(potentialSavingsBytes),
    );
  }

  factory HealthSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthSnapshot(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      score: serializer.fromJson<int>(json['score']),
      totalTitles: serializer.fromJson<int>(json['totalTitles']),
      healthyCount: serializer.fromJson<int>(json['healthyCount']),
      duplicateCount: serializer.fromJson<int>(json['duplicateCount']),
      corruptedCount: serializer.fromJson<int>(json['corruptedCount']),
      missingMetadataCount:
          serializer.fromJson<int>(json['missingMetadataCount']),
      totalSizeBytes: serializer.fromJson<int>(json['totalSizeBytes']),
      potentialSavingsBytes:
          serializer.fromJson<int>(json['potentialSavingsBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<int>(timestamp),
      'score': serializer.toJson<int>(score),
      'totalTitles': serializer.toJson<int>(totalTitles),
      'healthyCount': serializer.toJson<int>(healthyCount),
      'duplicateCount': serializer.toJson<int>(duplicateCount),
      'corruptedCount': serializer.toJson<int>(corruptedCount),
      'missingMetadataCount': serializer.toJson<int>(missingMetadataCount),
      'totalSizeBytes': serializer.toJson<int>(totalSizeBytes),
      'potentialSavingsBytes': serializer.toJson<int>(potentialSavingsBytes),
    };
  }

  HealthSnapshot copyWith(
          {int? id,
          int? timestamp,
          int? score,
          int? totalTitles,
          int? healthyCount,
          int? duplicateCount,
          int? corruptedCount,
          int? missingMetadataCount,
          int? totalSizeBytes,
          int? potentialSavingsBytes}) =>
      HealthSnapshot(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        score: score ?? this.score,
        totalTitles: totalTitles ?? this.totalTitles,
        healthyCount: healthyCount ?? this.healthyCount,
        duplicateCount: duplicateCount ?? this.duplicateCount,
        corruptedCount: corruptedCount ?? this.corruptedCount,
        missingMetadataCount: missingMetadataCount ?? this.missingMetadataCount,
        totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
        potentialSavingsBytes:
            potentialSavingsBytes ?? this.potentialSavingsBytes,
      );
  HealthSnapshot copyWithCompanion(HealthSnapshotsCompanion data) {
    return HealthSnapshot(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      score: data.score.present ? data.score.value : this.score,
      totalTitles:
          data.totalTitles.present ? data.totalTitles.value : this.totalTitles,
      healthyCount: data.healthyCount.present
          ? data.healthyCount.value
          : this.healthyCount,
      duplicateCount: data.duplicateCount.present
          ? data.duplicateCount.value
          : this.duplicateCount,
      corruptedCount: data.corruptedCount.present
          ? data.corruptedCount.value
          : this.corruptedCount,
      missingMetadataCount: data.missingMetadataCount.present
          ? data.missingMetadataCount.value
          : this.missingMetadataCount,
      totalSizeBytes: data.totalSizeBytes.present
          ? data.totalSizeBytes.value
          : this.totalSizeBytes,
      potentialSavingsBytes: data.potentialSavingsBytes.present
          ? data.potentialSavingsBytes.value
          : this.potentialSavingsBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshot(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('score: $score, ')
          ..write('totalTitles: $totalTitles, ')
          ..write('healthyCount: $healthyCount, ')
          ..write('duplicateCount: $duplicateCount, ')
          ..write('corruptedCount: $corruptedCount, ')
          ..write('missingMetadataCount: $missingMetadataCount, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('potentialSavingsBytes: $potentialSavingsBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      timestamp,
      score,
      totalTitles,
      healthyCount,
      duplicateCount,
      corruptedCount,
      missingMetadataCount,
      totalSizeBytes,
      potentialSavingsBytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSnapshot &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.score == this.score &&
          other.totalTitles == this.totalTitles &&
          other.healthyCount == this.healthyCount &&
          other.duplicateCount == this.duplicateCount &&
          other.corruptedCount == this.corruptedCount &&
          other.missingMetadataCount == this.missingMetadataCount &&
          other.totalSizeBytes == this.totalSizeBytes &&
          other.potentialSavingsBytes == this.potentialSavingsBytes);
}

class HealthSnapshotsCompanion extends UpdateCompanion<HealthSnapshot> {
  final Value<int> id;
  final Value<int> timestamp;
  final Value<int> score;
  final Value<int> totalTitles;
  final Value<int> healthyCount;
  final Value<int> duplicateCount;
  final Value<int> corruptedCount;
  final Value<int> missingMetadataCount;
  final Value<int> totalSizeBytes;
  final Value<int> potentialSavingsBytes;
  const HealthSnapshotsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.score = const Value.absent(),
    this.totalTitles = const Value.absent(),
    this.healthyCount = const Value.absent(),
    this.duplicateCount = const Value.absent(),
    this.corruptedCount = const Value.absent(),
    this.missingMetadataCount = const Value.absent(),
    this.totalSizeBytes = const Value.absent(),
    this.potentialSavingsBytes = const Value.absent(),
  });
  HealthSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required int timestamp,
    required int score,
    this.totalTitles = const Value.absent(),
    this.healthyCount = const Value.absent(),
    this.duplicateCount = const Value.absent(),
    this.corruptedCount = const Value.absent(),
    this.missingMetadataCount = const Value.absent(),
    this.totalSizeBytes = const Value.absent(),
    this.potentialSavingsBytes = const Value.absent(),
  })  : timestamp = Value(timestamp),
        score = Value(score);
  static Insertable<HealthSnapshot> custom({
    Expression<int>? id,
    Expression<int>? timestamp,
    Expression<int>? score,
    Expression<int>? totalTitles,
    Expression<int>? healthyCount,
    Expression<int>? duplicateCount,
    Expression<int>? corruptedCount,
    Expression<int>? missingMetadataCount,
    Expression<int>? totalSizeBytes,
    Expression<int>? potentialSavingsBytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (score != null) 'score': score,
      if (totalTitles != null) 'total_titles': totalTitles,
      if (healthyCount != null) 'healthy_count': healthyCount,
      if (duplicateCount != null) 'duplicate_count': duplicateCount,
      if (corruptedCount != null) 'corrupted_count': corruptedCount,
      if (missingMetadataCount != null)
        'missing_metadata_count': missingMetadataCount,
      if (totalSizeBytes != null) 'total_size_bytes': totalSizeBytes,
      if (potentialSavingsBytes != null)
        'potential_savings_bytes': potentialSavingsBytes,
    });
  }

  HealthSnapshotsCompanion copyWith(
      {Value<int>? id,
      Value<int>? timestamp,
      Value<int>? score,
      Value<int>? totalTitles,
      Value<int>? healthyCount,
      Value<int>? duplicateCount,
      Value<int>? corruptedCount,
      Value<int>? missingMetadataCount,
      Value<int>? totalSizeBytes,
      Value<int>? potentialSavingsBytes}) {
    return HealthSnapshotsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      totalTitles: totalTitles ?? this.totalTitles,
      healthyCount: healthyCount ?? this.healthyCount,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      corruptedCount: corruptedCount ?? this.corruptedCount,
      missingMetadataCount: missingMetadataCount ?? this.missingMetadataCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      potentialSavingsBytes:
          potentialSavingsBytes ?? this.potentialSavingsBytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (totalTitles.present) {
      map['total_titles'] = Variable<int>(totalTitles.value);
    }
    if (healthyCount.present) {
      map['healthy_count'] = Variable<int>(healthyCount.value);
    }
    if (duplicateCount.present) {
      map['duplicate_count'] = Variable<int>(duplicateCount.value);
    }
    if (corruptedCount.present) {
      map['corrupted_count'] = Variable<int>(corruptedCount.value);
    }
    if (missingMetadataCount.present) {
      map['missing_metadata_count'] = Variable<int>(missingMetadataCount.value);
    }
    if (totalSizeBytes.present) {
      map['total_size_bytes'] = Variable<int>(totalSizeBytes.value);
    }
    if (potentialSavingsBytes.present) {
      map['potential_savings_bytes'] =
          Variable<int>(potentialSavingsBytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('score: $score, ')
          ..write('totalTitles: $totalTitles, ')
          ..write('healthyCount: $healthyCount, ')
          ..write('duplicateCount: $duplicateCount, ')
          ..write('corruptedCount: $corruptedCount, ')
          ..write('missingMetadataCount: $missingMetadataCount, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('potentialSavingsBytes: $potentialSavingsBytes')
          ..write(')'))
        .toString();
  }
}

class $QuarantineLogsTable extends QuarantineLogs
    with TableInfo<$QuarantineLogsTable, QuarantineLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuarantineLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleIdMeta =
      const VerificationMeta('titleId');
  @override
  late final GeneratedColumn<int> titleId = GeneratedColumn<int>(
      'title_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES titles (id)'));
  static const VerificationMeta _originalPathMeta =
      const VerificationMeta('originalPath');
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
      'original_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quarantinePathMeta =
      const VerificationMeta('quarantinePath');
  @override
  late final GeneratedColumn<String> quarantinePath = GeneratedColumn<String>(
      'quarantine_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _restoredTimestampMeta =
      const VerificationMeta('restoredTimestamp');
  @override
  late final GeneratedColumn<int> restoredTimestamp = GeneratedColumn<int>(
      'restored_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        titleId,
        originalPath,
        quarantinePath,
        reason,
        timestamp,
        restoredTimestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quarantine_logs';
  @override
  VerificationContext validateIntegrity(Insertable<QuarantineLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title_id')) {
      context.handle(_titleIdMeta,
          titleId.isAcceptableOrUnknown(data['title_id']!, _titleIdMeta));
    } else if (isInserting) {
      context.missing(_titleIdMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
          _originalPathMeta,
          originalPath.isAcceptableOrUnknown(
              data['original_path']!, _originalPathMeta));
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('quarantine_path')) {
      context.handle(
          _quarantinePathMeta,
          quarantinePath.isAcceptableOrUnknown(
              data['quarantine_path']!, _quarantinePathMeta));
    } else if (isInserting) {
      context.missing(_quarantinePathMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('restored_timestamp')) {
      context.handle(
          _restoredTimestampMeta,
          restoredTimestamp.isAcceptableOrUnknown(
              data['restored_timestamp']!, _restoredTimestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuarantineLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuarantineLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      titleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}title_id'])!,
      originalPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_path'])!,
      quarantinePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quarantine_path'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      restoredTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}restored_timestamp']),
    );
  }

  @override
  $QuarantineLogsTable createAlias(String alias) {
    return $QuarantineLogsTable(attachedDatabase, alias);
  }
}

class QuarantineLog extends DataClass implements Insertable<QuarantineLog> {
  final int id;
  final int titleId;
  final String originalPath;
  final String quarantinePath;
  final String? reason;
  final int timestamp;
  final int? restoredTimestamp;
  const QuarantineLog(
      {required this.id,
      required this.titleId,
      required this.originalPath,
      required this.quarantinePath,
      this.reason,
      required this.timestamp,
      this.restoredTimestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title_id'] = Variable<int>(titleId);
    map['original_path'] = Variable<String>(originalPath);
    map['quarantine_path'] = Variable<String>(quarantinePath);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || restoredTimestamp != null) {
      map['restored_timestamp'] = Variable<int>(restoredTimestamp);
    }
    return map;
  }

  QuarantineLogsCompanion toCompanion(bool nullToAbsent) {
    return QuarantineLogsCompanion(
      id: Value(id),
      titleId: Value(titleId),
      originalPath: Value(originalPath),
      quarantinePath: Value(quarantinePath),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      timestamp: Value(timestamp),
      restoredTimestamp: restoredTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(restoredTimestamp),
    );
  }

  factory QuarantineLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuarantineLog(
      id: serializer.fromJson<int>(json['id']),
      titleId: serializer.fromJson<int>(json['titleId']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      quarantinePath: serializer.fromJson<String>(json['quarantinePath']),
      reason: serializer.fromJson<String?>(json['reason']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      restoredTimestamp: serializer.fromJson<int?>(json['restoredTimestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titleId': serializer.toJson<int>(titleId),
      'originalPath': serializer.toJson<String>(originalPath),
      'quarantinePath': serializer.toJson<String>(quarantinePath),
      'reason': serializer.toJson<String?>(reason),
      'timestamp': serializer.toJson<int>(timestamp),
      'restoredTimestamp': serializer.toJson<int?>(restoredTimestamp),
    };
  }

  QuarantineLog copyWith(
          {int? id,
          int? titleId,
          String? originalPath,
          String? quarantinePath,
          Value<String?> reason = const Value.absent(),
          int? timestamp,
          Value<int?> restoredTimestamp = const Value.absent()}) =>
      QuarantineLog(
        id: id ?? this.id,
        titleId: titleId ?? this.titleId,
        originalPath: originalPath ?? this.originalPath,
        quarantinePath: quarantinePath ?? this.quarantinePath,
        reason: reason.present ? reason.value : this.reason,
        timestamp: timestamp ?? this.timestamp,
        restoredTimestamp: restoredTimestamp.present
            ? restoredTimestamp.value
            : this.restoredTimestamp,
      );
  QuarantineLog copyWithCompanion(QuarantineLogsCompanion data) {
    return QuarantineLog(
      id: data.id.present ? data.id.value : this.id,
      titleId: data.titleId.present ? data.titleId.value : this.titleId,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      quarantinePath: data.quarantinePath.present
          ? data.quarantinePath.value
          : this.quarantinePath,
      reason: data.reason.present ? data.reason.value : this.reason,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      restoredTimestamp: data.restoredTimestamp.present
          ? data.restoredTimestamp.value
          : this.restoredTimestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuarantineLog(')
          ..write('id: $id, ')
          ..write('titleId: $titleId, ')
          ..write('originalPath: $originalPath, ')
          ..write('quarantinePath: $quarantinePath, ')
          ..write('reason: $reason, ')
          ..write('timestamp: $timestamp, ')
          ..write('restoredTimestamp: $restoredTimestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, titleId, originalPath, quarantinePath,
      reason, timestamp, restoredTimestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuarantineLog &&
          other.id == this.id &&
          other.titleId == this.titleId &&
          other.originalPath == this.originalPath &&
          other.quarantinePath == this.quarantinePath &&
          other.reason == this.reason &&
          other.timestamp == this.timestamp &&
          other.restoredTimestamp == this.restoredTimestamp);
}

class QuarantineLogsCompanion extends UpdateCompanion<QuarantineLog> {
  final Value<int> id;
  final Value<int> titleId;
  final Value<String> originalPath;
  final Value<String> quarantinePath;
  final Value<String?> reason;
  final Value<int> timestamp;
  final Value<int?> restoredTimestamp;
  const QuarantineLogsCompanion({
    this.id = const Value.absent(),
    this.titleId = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.quarantinePath = const Value.absent(),
    this.reason = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.restoredTimestamp = const Value.absent(),
  });
  QuarantineLogsCompanion.insert({
    this.id = const Value.absent(),
    required int titleId,
    required String originalPath,
    required String quarantinePath,
    this.reason = const Value.absent(),
    required int timestamp,
    this.restoredTimestamp = const Value.absent(),
  })  : titleId = Value(titleId),
        originalPath = Value(originalPath),
        quarantinePath = Value(quarantinePath),
        timestamp = Value(timestamp);
  static Insertable<QuarantineLog> custom({
    Expression<int>? id,
    Expression<int>? titleId,
    Expression<String>? originalPath,
    Expression<String>? quarantinePath,
    Expression<String>? reason,
    Expression<int>? timestamp,
    Expression<int>? restoredTimestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titleId != null) 'title_id': titleId,
      if (originalPath != null) 'original_path': originalPath,
      if (quarantinePath != null) 'quarantine_path': quarantinePath,
      if (reason != null) 'reason': reason,
      if (timestamp != null) 'timestamp': timestamp,
      if (restoredTimestamp != null) 'restored_timestamp': restoredTimestamp,
    });
  }

  QuarantineLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? titleId,
      Value<String>? originalPath,
      Value<String>? quarantinePath,
      Value<String?>? reason,
      Value<int>? timestamp,
      Value<int?>? restoredTimestamp}) {
    return QuarantineLogsCompanion(
      id: id ?? this.id,
      titleId: titleId ?? this.titleId,
      originalPath: originalPath ?? this.originalPath,
      quarantinePath: quarantinePath ?? this.quarantinePath,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      restoredTimestamp: restoredTimestamp ?? this.restoredTimestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titleId.present) {
      map['title_id'] = Variable<int>(titleId.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (quarantinePath.present) {
      map['quarantine_path'] = Variable<String>(quarantinePath.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (restoredTimestamp.present) {
      map['restored_timestamp'] = Variable<int>(restoredTimestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuarantineLogsCompanion(')
          ..write('id: $id, ')
          ..write('titleId: $titleId, ')
          ..write('originalPath: $originalPath, ')
          ..write('quarantinePath: $quarantinePath, ')
          ..write('reason: $reason, ')
          ..write('timestamp: $timestamp, ')
          ..write('restoredTimestamp: $restoredTimestamp')
          ..write(')'))
        .toString();
  }
}

class $SchemaVersionsTable extends SchemaVersions
    with TableInfo<$SchemaVersionsTable, SchemaVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _appliedTimestampMeta =
      const VerificationMeta('appliedTimestamp');
  @override
  late final GeneratedColumn<int> appliedTimestamp = GeneratedColumn<int>(
      'applied_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [version, appliedTimestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_versions';
  @override
  VerificationContext validateIntegrity(Insertable<SchemaVersion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('applied_timestamp')) {
      context.handle(
          _appliedTimestampMeta,
          appliedTimestamp.isAcceptableOrUnknown(
              data['applied_timestamp']!, _appliedTimestampMeta));
    } else if (isInserting) {
      context.missing(_appliedTimestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  SchemaVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaVersion(
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      appliedTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}applied_timestamp'])!,
    );
  }

  @override
  $SchemaVersionsTable createAlias(String alias) {
    return $SchemaVersionsTable(attachedDatabase, alias);
  }
}

class SchemaVersion extends DataClass implements Insertable<SchemaVersion> {
  final int version;
  final int appliedTimestamp;
  const SchemaVersion({required this.version, required this.appliedTimestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    map['applied_timestamp'] = Variable<int>(appliedTimestamp);
    return map;
  }

  SchemaVersionsCompanion toCompanion(bool nullToAbsent) {
    return SchemaVersionsCompanion(
      version: Value(version),
      appliedTimestamp: Value(appliedTimestamp),
    );
  }

  factory SchemaVersion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaVersion(
      version: serializer.fromJson<int>(json['version']),
      appliedTimestamp: serializer.fromJson<int>(json['appliedTimestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'appliedTimestamp': serializer.toJson<int>(appliedTimestamp),
    };
  }

  SchemaVersion copyWith({int? version, int? appliedTimestamp}) =>
      SchemaVersion(
        version: version ?? this.version,
        appliedTimestamp: appliedTimestamp ?? this.appliedTimestamp,
      );
  SchemaVersion copyWithCompanion(SchemaVersionsCompanion data) {
    return SchemaVersion(
      version: data.version.present ? data.version.value : this.version,
      appliedTimestamp: data.appliedTimestamp.present
          ? data.appliedTimestamp.value
          : this.appliedTimestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaVersion(')
          ..write('version: $version, ')
          ..write('appliedTimestamp: $appliedTimestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, appliedTimestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaVersion &&
          other.version == this.version &&
          other.appliedTimestamp == this.appliedTimestamp);
}

class SchemaVersionsCompanion extends UpdateCompanion<SchemaVersion> {
  final Value<int> version;
  final Value<int> appliedTimestamp;
  const SchemaVersionsCompanion({
    this.version = const Value.absent(),
    this.appliedTimestamp = const Value.absent(),
  });
  SchemaVersionsCompanion.insert({
    this.version = const Value.absent(),
    required int appliedTimestamp,
  }) : appliedTimestamp = Value(appliedTimestamp);
  static Insertable<SchemaVersion> custom({
    Expression<int>? version,
    Expression<int>? appliedTimestamp,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (appliedTimestamp != null) 'applied_timestamp': appliedTimestamp,
    });
  }

  SchemaVersionsCompanion copyWith(
      {Value<int>? version, Value<int>? appliedTimestamp}) {
    return SchemaVersionsCompanion(
      version: version ?? this.version,
      appliedTimestamp: appliedTimestamp ?? this.appliedTimestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (appliedTimestamp.present) {
      map['applied_timestamp'] = Variable<int>(appliedTimestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaVersionsCompanion(')
          ..write('version: $version, ')
          ..write('appliedTimestamp: $appliedTimestamp')
          ..write(')'))
        .toString();
  }
}

class $PatchedRomsTable extends PatchedRoms
    with TableInfo<$PatchedRomsTable, PatchedRom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatchedRomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseGameIdMeta =
      const VerificationMeta('baseGameId');
  @override
  late final GeneratedColumn<String> baseGameId = GeneratedColumn<String>(
      'base_game_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patchNameMeta =
      const VerificationMeta('patchName');
  @override
  late final GeneratedColumn<String> patchName = GeneratedColumn<String>(
      'patch_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patchVersionMeta =
      const VerificationMeta('patchVersion');
  @override
  late final GeneratedColumn<String> patchVersion = GeneratedColumn<String>(
      'patch_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadUrlMeta =
      const VerificationMeta('downloadUrl');
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
      'download_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _archiveUrlMeta =
      const VerificationMeta('archiveUrl');
  @override
  late final GeneratedColumn<String> archiveUrl = GeneratedColumn<String>(
      'archive_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _torrentUrlMeta =
      const VerificationMeta('torrentUrl');
  @override
  late final GeneratedColumn<String> torrentUrl = GeneratedColumn<String>(
      'torrent_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sha256HashMeta =
      const VerificationMeta('sha256Hash');
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
      'sha256_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sha1HashMeta =
      const VerificationMeta('sha1Hash');
  @override
  late final GeneratedColumn<String> sha1Hash = GeneratedColumn<String>(
      'sha1_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _patchNotesMeta =
      const VerificationMeta('patchNotes');
  @override
  late final GeneratedColumn<String> patchNotes = GeneratedColumn<String>(
      'patch_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadCountMeta =
      const VerificationMeta('downloadCount');
  @override
  late final GeneratedColumn<int> downloadCount = GeneratedColumn<int>(
      'download_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  @override
  late final GeneratedColumn<int> isVerified = GeneratedColumn<int>(
      'is_verified', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        baseGameId,
        patchName,
        patchVersion,
        downloadUrl,
        archiveUrl,
        torrentUrl,
        sha256Hash,
        sha1Hash,
        fileSizeBytes,
        patchNotes,
        platform,
        region,
        createdAt,
        updatedAt,
        downloadCount,
        isVerified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patched_roms';
  @override
  VerificationContext validateIntegrity(Insertable<PatchedRom> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('base_game_id')) {
      context.handle(
          _baseGameIdMeta,
          baseGameId.isAcceptableOrUnknown(
              data['base_game_id']!, _baseGameIdMeta));
    } else if (isInserting) {
      context.missing(_baseGameIdMeta);
    }
    if (data.containsKey('patch_name')) {
      context.handle(_patchNameMeta,
          patchName.isAcceptableOrUnknown(data['patch_name']!, _patchNameMeta));
    } else if (isInserting) {
      context.missing(_patchNameMeta);
    }
    if (data.containsKey('patch_version')) {
      context.handle(
          _patchVersionMeta,
          patchVersion.isAcceptableOrUnknown(
              data['patch_version']!, _patchVersionMeta));
    } else if (isInserting) {
      context.missing(_patchVersionMeta);
    }
    if (data.containsKey('download_url')) {
      context.handle(
          _downloadUrlMeta,
          downloadUrl.isAcceptableOrUnknown(
              data['download_url']!, _downloadUrlMeta));
    } else if (isInserting) {
      context.missing(_downloadUrlMeta);
    }
    if (data.containsKey('archive_url')) {
      context.handle(
          _archiveUrlMeta,
          archiveUrl.isAcceptableOrUnknown(
              data['archive_url']!, _archiveUrlMeta));
    }
    if (data.containsKey('torrent_url')) {
      context.handle(
          _torrentUrlMeta,
          torrentUrl.isAcceptableOrUnknown(
              data['torrent_url']!, _torrentUrlMeta));
    }
    if (data.containsKey('sha256_hash')) {
      context.handle(
          _sha256HashMeta,
          sha256Hash.isAcceptableOrUnknown(
              data['sha256_hash']!, _sha256HashMeta));
    }
    if (data.containsKey('sha1_hash')) {
      context.handle(_sha1HashMeta,
          sha1Hash.isAcceptableOrUnknown(data['sha1_hash']!, _sha1HashMeta));
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('patch_notes')) {
      context.handle(
          _patchNotesMeta,
          patchNotes.isAcceptableOrUnknown(
              data['patch_notes']!, _patchNotesMeta));
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('download_count')) {
      context.handle(
          _downloadCountMeta,
          downloadCount.isAcceptableOrUnknown(
              data['download_count']!, _downloadCountMeta));
    }
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatchedRom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatchedRom(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      baseGameId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_game_id'])!,
      patchName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patch_name'])!,
      patchVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patch_version'])!,
      downloadUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_url'])!,
      archiveUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}archive_url']),
      torrentUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}torrent_url']),
      sha256Hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256_hash']),
      sha1Hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha1_hash']),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      patchNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patch_notes']),
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      downloadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}download_count'])!,
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_verified'])!,
    );
  }

  @override
  $PatchedRomsTable createAlias(String alias) {
    return $PatchedRomsTable(attachedDatabase, alias);
  }
}

class PatchedRom extends DataClass implements Insertable<PatchedRom> {
  final String id;
  final String baseGameId;
  final String patchName;
  final String patchVersion;
  final String downloadUrl;
  final String? archiveUrl;
  final String? torrentUrl;
  final String? sha256Hash;
  final String? sha1Hash;
  final int fileSizeBytes;
  final String? patchNotes;
  final String platform;
  final String? region;
  final int createdAt;
  final int updatedAt;
  final int downloadCount;
  final int isVerified;
  const PatchedRom(
      {required this.id,
      required this.baseGameId,
      required this.patchName,
      required this.patchVersion,
      required this.downloadUrl,
      this.archiveUrl,
      this.torrentUrl,
      this.sha256Hash,
      this.sha1Hash,
      required this.fileSizeBytes,
      this.patchNotes,
      required this.platform,
      this.region,
      required this.createdAt,
      required this.updatedAt,
      required this.downloadCount,
      required this.isVerified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base_game_id'] = Variable<String>(baseGameId);
    map['patch_name'] = Variable<String>(patchName);
    map['patch_version'] = Variable<String>(patchVersion);
    map['download_url'] = Variable<String>(downloadUrl);
    if (!nullToAbsent || archiveUrl != null) {
      map['archive_url'] = Variable<String>(archiveUrl);
    }
    if (!nullToAbsent || torrentUrl != null) {
      map['torrent_url'] = Variable<String>(torrentUrl);
    }
    if (!nullToAbsent || sha256Hash != null) {
      map['sha256_hash'] = Variable<String>(sha256Hash);
    }
    if (!nullToAbsent || sha1Hash != null) {
      map['sha1_hash'] = Variable<String>(sha1Hash);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || patchNotes != null) {
      map['patch_notes'] = Variable<String>(patchNotes);
    }
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['download_count'] = Variable<int>(downloadCount);
    map['is_verified'] = Variable<int>(isVerified);
    return map;
  }

  PatchedRomsCompanion toCompanion(bool nullToAbsent) {
    return PatchedRomsCompanion(
      id: Value(id),
      baseGameId: Value(baseGameId),
      patchName: Value(patchName),
      patchVersion: Value(patchVersion),
      downloadUrl: Value(downloadUrl),
      archiveUrl: archiveUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveUrl),
      torrentUrl: torrentUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(torrentUrl),
      sha256Hash: sha256Hash == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256Hash),
      sha1Hash: sha1Hash == null && nullToAbsent
          ? const Value.absent()
          : Value(sha1Hash),
      fileSizeBytes: Value(fileSizeBytes),
      patchNotes: patchNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(patchNotes),
      platform: Value(platform),
      region:
          region == null && nullToAbsent ? const Value.absent() : Value(region),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      downloadCount: Value(downloadCount),
      isVerified: Value(isVerified),
    );
  }

  factory PatchedRom.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatchedRom(
      id: serializer.fromJson<String>(json['id']),
      baseGameId: serializer.fromJson<String>(json['baseGameId']),
      patchName: serializer.fromJson<String>(json['patchName']),
      patchVersion: serializer.fromJson<String>(json['patchVersion']),
      downloadUrl: serializer.fromJson<String>(json['downloadUrl']),
      archiveUrl: serializer.fromJson<String?>(json['archiveUrl']),
      torrentUrl: serializer.fromJson<String?>(json['torrentUrl']),
      sha256Hash: serializer.fromJson<String?>(json['sha256Hash']),
      sha1Hash: serializer.fromJson<String?>(json['sha1Hash']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      patchNotes: serializer.fromJson<String?>(json['patchNotes']),
      platform: serializer.fromJson<String>(json['platform']),
      region: serializer.fromJson<String?>(json['region']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      downloadCount: serializer.fromJson<int>(json['downloadCount']),
      isVerified: serializer.fromJson<int>(json['isVerified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseGameId': serializer.toJson<String>(baseGameId),
      'patchName': serializer.toJson<String>(patchName),
      'patchVersion': serializer.toJson<String>(patchVersion),
      'downloadUrl': serializer.toJson<String>(downloadUrl),
      'archiveUrl': serializer.toJson<String?>(archiveUrl),
      'torrentUrl': serializer.toJson<String?>(torrentUrl),
      'sha256Hash': serializer.toJson<String?>(sha256Hash),
      'sha1Hash': serializer.toJson<String?>(sha1Hash),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'patchNotes': serializer.toJson<String?>(patchNotes),
      'platform': serializer.toJson<String>(platform),
      'region': serializer.toJson<String?>(region),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'downloadCount': serializer.toJson<int>(downloadCount),
      'isVerified': serializer.toJson<int>(isVerified),
    };
  }

  PatchedRom copyWith(
          {String? id,
          String? baseGameId,
          String? patchName,
          String? patchVersion,
          String? downloadUrl,
          Value<String?> archiveUrl = const Value.absent(),
          Value<String?> torrentUrl = const Value.absent(),
          Value<String?> sha256Hash = const Value.absent(),
          Value<String?> sha1Hash = const Value.absent(),
          int? fileSizeBytes,
          Value<String?> patchNotes = const Value.absent(),
          String? platform,
          Value<String?> region = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          int? downloadCount,
          int? isVerified}) =>
      PatchedRom(
        id: id ?? this.id,
        baseGameId: baseGameId ?? this.baseGameId,
        patchName: patchName ?? this.patchName,
        patchVersion: patchVersion ?? this.patchVersion,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        archiveUrl: archiveUrl.present ? archiveUrl.value : this.archiveUrl,
        torrentUrl: torrentUrl.present ? torrentUrl.value : this.torrentUrl,
        sha256Hash: sha256Hash.present ? sha256Hash.value : this.sha256Hash,
        sha1Hash: sha1Hash.present ? sha1Hash.value : this.sha1Hash,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        patchNotes: patchNotes.present ? patchNotes.value : this.patchNotes,
        platform: platform ?? this.platform,
        region: region.present ? region.value : this.region,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        downloadCount: downloadCount ?? this.downloadCount,
        isVerified: isVerified ?? this.isVerified,
      );
  PatchedRom copyWithCompanion(PatchedRomsCompanion data) {
    return PatchedRom(
      id: data.id.present ? data.id.value : this.id,
      baseGameId:
          data.baseGameId.present ? data.baseGameId.value : this.baseGameId,
      patchName: data.patchName.present ? data.patchName.value : this.patchName,
      patchVersion: data.patchVersion.present
          ? data.patchVersion.value
          : this.patchVersion,
      downloadUrl:
          data.downloadUrl.present ? data.downloadUrl.value : this.downloadUrl,
      archiveUrl:
          data.archiveUrl.present ? data.archiveUrl.value : this.archiveUrl,
      torrentUrl:
          data.torrentUrl.present ? data.torrentUrl.value : this.torrentUrl,
      sha256Hash:
          data.sha256Hash.present ? data.sha256Hash.value : this.sha256Hash,
      sha1Hash: data.sha1Hash.present ? data.sha1Hash.value : this.sha1Hash,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      patchNotes:
          data.patchNotes.present ? data.patchNotes.value : this.patchNotes,
      platform: data.platform.present ? data.platform.value : this.platform,
      region: data.region.present ? data.region.value : this.region,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      downloadCount: data.downloadCount.present
          ? data.downloadCount.value
          : this.downloadCount,
      isVerified:
          data.isVerified.present ? data.isVerified.value : this.isVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatchedRom(')
          ..write('id: $id, ')
          ..write('baseGameId: $baseGameId, ')
          ..write('patchName: $patchName, ')
          ..write('patchVersion: $patchVersion, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('archiveUrl: $archiveUrl, ')
          ..write('torrentUrl: $torrentUrl, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('sha1Hash: $sha1Hash, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('patchNotes: $patchNotes, ')
          ..write('platform: $platform, ')
          ..write('region: $region, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('isVerified: $isVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      baseGameId,
      patchName,
      patchVersion,
      downloadUrl,
      archiveUrl,
      torrentUrl,
      sha256Hash,
      sha1Hash,
      fileSizeBytes,
      patchNotes,
      platform,
      region,
      createdAt,
      updatedAt,
      downloadCount,
      isVerified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatchedRom &&
          other.id == this.id &&
          other.baseGameId == this.baseGameId &&
          other.patchName == this.patchName &&
          other.patchVersion == this.patchVersion &&
          other.downloadUrl == this.downloadUrl &&
          other.archiveUrl == this.archiveUrl &&
          other.torrentUrl == this.torrentUrl &&
          other.sha256Hash == this.sha256Hash &&
          other.sha1Hash == this.sha1Hash &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.patchNotes == this.patchNotes &&
          other.platform == this.platform &&
          other.region == this.region &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.downloadCount == this.downloadCount &&
          other.isVerified == this.isVerified);
}

class PatchedRomsCompanion extends UpdateCompanion<PatchedRom> {
  final Value<String> id;
  final Value<String> baseGameId;
  final Value<String> patchName;
  final Value<String> patchVersion;
  final Value<String> downloadUrl;
  final Value<String?> archiveUrl;
  final Value<String?> torrentUrl;
  final Value<String?> sha256Hash;
  final Value<String?> sha1Hash;
  final Value<int> fileSizeBytes;
  final Value<String?> patchNotes;
  final Value<String> platform;
  final Value<String?> region;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> downloadCount;
  final Value<int> isVerified;
  final Value<int> rowid;
  const PatchedRomsCompanion({
    this.id = const Value.absent(),
    this.baseGameId = const Value.absent(),
    this.patchName = const Value.absent(),
    this.patchVersion = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.archiveUrl = const Value.absent(),
    this.torrentUrl = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.sha1Hash = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.patchNotes = const Value.absent(),
    this.platform = const Value.absent(),
    this.region = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.downloadCount = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatchedRomsCompanion.insert({
    required String id,
    required String baseGameId,
    required String patchName,
    required String patchVersion,
    required String downloadUrl,
    this.archiveUrl = const Value.absent(),
    this.torrentUrl = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.sha1Hash = const Value.absent(),
    required int fileSizeBytes,
    this.patchNotes = const Value.absent(),
    required String platform,
    this.region = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.downloadCount = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        baseGameId = Value(baseGameId),
        patchName = Value(patchName),
        patchVersion = Value(patchVersion),
        downloadUrl = Value(downloadUrl),
        fileSizeBytes = Value(fileSizeBytes),
        platform = Value(platform),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PatchedRom> custom({
    Expression<String>? id,
    Expression<String>? baseGameId,
    Expression<String>? patchName,
    Expression<String>? patchVersion,
    Expression<String>? downloadUrl,
    Expression<String>? archiveUrl,
    Expression<String>? torrentUrl,
    Expression<String>? sha256Hash,
    Expression<String>? sha1Hash,
    Expression<int>? fileSizeBytes,
    Expression<String>? patchNotes,
    Expression<String>? platform,
    Expression<String>? region,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? downloadCount,
    Expression<int>? isVerified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseGameId != null) 'base_game_id': baseGameId,
      if (patchName != null) 'patch_name': patchName,
      if (patchVersion != null) 'patch_version': patchVersion,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (archiveUrl != null) 'archive_url': archiveUrl,
      if (torrentUrl != null) 'torrent_url': torrentUrl,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (sha1Hash != null) 'sha1_hash': sha1Hash,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (patchNotes != null) 'patch_notes': patchNotes,
      if (platform != null) 'platform': platform,
      if (region != null) 'region': region,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (downloadCount != null) 'download_count': downloadCount,
      if (isVerified != null) 'is_verified': isVerified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatchedRomsCompanion copyWith(
      {Value<String>? id,
      Value<String>? baseGameId,
      Value<String>? patchName,
      Value<String>? patchVersion,
      Value<String>? downloadUrl,
      Value<String?>? archiveUrl,
      Value<String?>? torrentUrl,
      Value<String?>? sha256Hash,
      Value<String?>? sha1Hash,
      Value<int>? fileSizeBytes,
      Value<String?>? patchNotes,
      Value<String>? platform,
      Value<String?>? region,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? downloadCount,
      Value<int>? isVerified,
      Value<int>? rowid}) {
    return PatchedRomsCompanion(
      id: id ?? this.id,
      baseGameId: baseGameId ?? this.baseGameId,
      patchName: patchName ?? this.patchName,
      patchVersion: patchVersion ?? this.patchVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      archiveUrl: archiveUrl ?? this.archiveUrl,
      torrentUrl: torrentUrl ?? this.torrentUrl,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      sha1Hash: sha1Hash ?? this.sha1Hash,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      patchNotes: patchNotes ?? this.patchNotes,
      platform: platform ?? this.platform,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      downloadCount: downloadCount ?? this.downloadCount,
      isVerified: isVerified ?? this.isVerified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseGameId.present) {
      map['base_game_id'] = Variable<String>(baseGameId.value);
    }
    if (patchName.present) {
      map['patch_name'] = Variable<String>(patchName.value);
    }
    if (patchVersion.present) {
      map['patch_version'] = Variable<String>(patchVersion.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (archiveUrl.present) {
      map['archive_url'] = Variable<String>(archiveUrl.value);
    }
    if (torrentUrl.present) {
      map['torrent_url'] = Variable<String>(torrentUrl.value);
    }
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (sha1Hash.present) {
      map['sha1_hash'] = Variable<String>(sha1Hash.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (patchNotes.present) {
      map['patch_notes'] = Variable<String>(patchNotes.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (downloadCount.present) {
      map['download_count'] = Variable<int>(downloadCount.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<int>(isVerified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatchedRomsCompanion(')
          ..write('id: $id, ')
          ..write('baseGameId: $baseGameId, ')
          ..write('patchName: $patchName, ')
          ..write('patchVersion: $patchVersion, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('archiveUrl: $archiveUrl, ')
          ..write('torrentUrl: $torrentUrl, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('sha1Hash: $sha1Hash, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('patchNotes: $patchNotes, ')
          ..write('platform: $platform, ')
          ..write('region: $region, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('downloadCount: $downloadCount, ')
          ..write('isVerified: $isVerified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
      'game_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadUrlMeta =
      const VerificationMeta('downloadUrl');
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
      'download_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savePathMeta =
      const VerificationMeta('savePath');
  @override
  late final GeneratedColumn<String> savePath = GeneratedColumn<String>(
      'save_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedBytesMeta =
      const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
      'downloaded_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('queued'));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        gameId,
        title,
        platform,
        downloadUrl,
        savePath,
        totalBytes,
        downloadedBytes,
        status,
        provider,
        errorMessage,
        createdAt,
        updatedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(_gameIdMeta,
          gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta));
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('download_url')) {
      context.handle(
          _downloadUrlMeta,
          downloadUrl.isAcceptableOrUnknown(
              data['download_url']!, _downloadUrlMeta));
    } else if (isInserting) {
      context.missing(_downloadUrlMeta);
    }
    if (data.containsKey('save_path')) {
      context.handle(_savePathMeta,
          savePath.isAcceptableOrUnknown(data['save_path']!, _savePathMeta));
    } else if (isInserting) {
      context.missing(_savePathMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
          _downloadedBytesMeta,
          downloadedBytes.isAcceptableOrUnknown(
              data['downloaded_bytes']!, _downloadedBytesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      gameId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      downloadUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_url'])!,
      savePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}save_path'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      downloadedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final int id;
  final String gameId;
  final String title;
  final String platform;
  final String downloadUrl;
  final String savePath;
  final int totalBytes;
  final int downloadedBytes;
  final String status;
  final String? provider;
  final String? errorMessage;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  const Download(
      {required this.id,
      required this.gameId,
      required this.title,
      required this.platform,
      required this.downloadUrl,
      required this.savePath,
      required this.totalBytes,
      required this.downloadedBytes,
      required this.status,
      this.provider,
      this.errorMessage,
      required this.createdAt,
      required this.updatedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<String>(gameId);
    map['title'] = Variable<String>(title);
    map['platform'] = Variable<String>(platform);
    map['download_url'] = Variable<String>(downloadUrl);
    map['save_path'] = Variable<String>(savePath);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      title: Value(title),
      platform: Value(platform),
      downloadUrl: Value(downloadUrl),
      savePath: Value(savePath),
      totalBytes: Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      status: Value(status),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      title: serializer.fromJson<String>(json['title']),
      platform: serializer.fromJson<String>(json['platform']),
      downloadUrl: serializer.fromJson<String>(json['downloadUrl']),
      savePath: serializer.fromJson<String>(json['savePath']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      status: serializer.fromJson<String>(json['status']),
      provider: serializer.fromJson<String?>(json['provider']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<String>(gameId),
      'title': serializer.toJson<String>(title),
      'platform': serializer.toJson<String>(platform),
      'downloadUrl': serializer.toJson<String>(downloadUrl),
      'savePath': serializer.toJson<String>(savePath),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'status': serializer.toJson<String>(status),
      'provider': serializer.toJson<String?>(provider),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  Download copyWith(
          {int? id,
          String? gameId,
          String? title,
          String? platform,
          String? downloadUrl,
          String? savePath,
          int? totalBytes,
          int? downloadedBytes,
          String? status,
          Value<String?> provider = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          Value<int?> completedAt = const Value.absent()}) =>
      Download(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        title: title ?? this.title,
        platform: platform ?? this.platform,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        savePath: savePath ?? this.savePath,
        totalBytes: totalBytes ?? this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        status: status ?? this.status,
        provider: provider.present ? provider.value : this.provider,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      title: data.title.present ? data.title.value : this.title,
      platform: data.platform.present ? data.platform.value : this.platform,
      downloadUrl:
          data.downloadUrl.present ? data.downloadUrl.value : this.downloadUrl,
      savePath: data.savePath.present ? data.savePath.value : this.savePath,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      status: data.status.present ? data.status.value : this.status,
      provider: data.provider.present ? data.provider.value : this.provider,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('platform: $platform, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('savePath: $savePath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('provider: $provider, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      gameId,
      title,
      platform,
      downloadUrl,
      savePath,
      totalBytes,
      downloadedBytes,
      status,
      provider,
      errorMessage,
      createdAt,
      updatedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.title == this.title &&
          other.platform == this.platform &&
          other.downloadUrl == this.downloadUrl &&
          other.savePath == this.savePath &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.status == this.status &&
          other.provider == this.provider &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<int> id;
  final Value<String> gameId;
  final Value<String> title;
  final Value<String> platform;
  final Value<String> downloadUrl;
  final Value<String> savePath;
  final Value<int> totalBytes;
  final Value<int> downloadedBytes;
  final Value<String> status;
  final Value<String?> provider;
  final Value<String?> errorMessage;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.title = const Value.absent(),
    this.platform = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.savePath = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.provider = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required String gameId,
    required String title,
    required String platform,
    required String downloadUrl,
    required String savePath,
    required int totalBytes,
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.provider = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
  })  : gameId = Value(gameId),
        title = Value(title),
        platform = Value(platform),
        downloadUrl = Value(downloadUrl),
        savePath = Value(savePath),
        totalBytes = Value(totalBytes),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Download> custom({
    Expression<int>? id,
    Expression<String>? gameId,
    Expression<String>? title,
    Expression<String>? platform,
    Expression<String>? downloadUrl,
    Expression<String>? savePath,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? status,
    Expression<String>? provider,
    Expression<String>? errorMessage,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (title != null) 'title': title,
      if (platform != null) 'platform': platform,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (savePath != null) 'save_path': savePath,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (status != null) 'status': status,
      if (provider != null) 'provider': provider,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? gameId,
      Value<String>? title,
      Value<String>? platform,
      Value<String>? downloadUrl,
      Value<String>? savePath,
      Value<int>? totalBytes,
      Value<int>? downloadedBytes,
      Value<String>? status,
      Value<String?>? provider,
      Value<String?>? errorMessage,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? completedAt}) {
    return DownloadsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      savePath: savePath ?? this.savePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      provider: provider ?? this.provider,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (savePath.present) {
      map['save_path'] = Variable<String>(savePath.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('platform: $platform, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('savePath: $savePath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('provider: $provider, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TitlesTable titles = $TitlesTable(this);
  late final $IssuesTable issues = $IssuesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $HealthSnapshotsTable healthSnapshots =
      $HealthSnapshotsTable(this);
  late final $QuarantineLogsTable quarantineLogs = $QuarantineLogsTable(this);
  late final $SchemaVersionsTable schemaVersions = $SchemaVersionsTable(this);
  late final $PatchedRomsTable patchedRoms = $PatchedRomsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        titles,
        issues,
        tasks,
        healthSnapshots,
        quarantineLogs,
        schemaVersions,
        patchedRoms,
        downloads
      ];
}

typedef $$TitlesTableCreateCompanionBuilder = TitlesCompanion Function({
  Value<int> id,
  required String gameId,
  required String title,
  required String platform,
  Value<String?> region,
  required String format,
  required String filePath,
  required int fileSizeBytes,
  Value<String?> sha1Partial,
  Value<String?> sha1Full,
  required int addedTimestamp,
  required int modifiedTimestamp,
  Value<int?> lastVerified,
  Value<String> healthStatus,
  Value<int> hasCover,
  Value<int> hasMetadata,
  Value<int> isQuarantined,
  Value<String?> quarantineReason,
  Value<int?> variantGroup,
});
typedef $$TitlesTableUpdateCompanionBuilder = TitlesCompanion Function({
  Value<int> id,
  Value<String> gameId,
  Value<String> title,
  Value<String> platform,
  Value<String?> region,
  Value<String> format,
  Value<String> filePath,
  Value<int> fileSizeBytes,
  Value<String?> sha1Partial,
  Value<String?> sha1Full,
  Value<int> addedTimestamp,
  Value<int> modifiedTimestamp,
  Value<int?> lastVerified,
  Value<String> healthStatus,
  Value<int> hasCover,
  Value<int> hasMetadata,
  Value<int> isQuarantined,
  Value<String?> quarantineReason,
  Value<int?> variantGroup,
});

final class $$TitlesTableReferences
    extends BaseReferences<_$AppDatabase, $TitlesTable, Title> {
  $$TitlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IssuesTable, List<Issue>> _issuesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.issues,
          aliasName: $_aliasNameGenerator(db.titles.id, db.issues.titleId));

  $$IssuesTableProcessedTableManager get issuesRefs {
    final manager = $$IssuesTableTableManager($_db, $_db.issues)
        .filter((f) => f.titleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_issuesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$QuarantineLogsTable, List<QuarantineLog>>
      _quarantineLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quarantineLogs,
              aliasName: $_aliasNameGenerator(
                  db.titles.id, db.quarantineLogs.titleId));

  $$QuarantineLogsTableProcessedTableManager get quarantineLogsRefs {
    final manager = $$QuarantineLogsTableTableManager($_db, $_db.quarantineLogs)
        .filter((f) => f.titleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quarantineLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TitlesTableFilterComposer
    extends Composer<_$AppDatabase, $TitlesTable> {
  $$TitlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha1Partial => $composableBuilder(
      column: $table.sha1Partial, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha1Full => $composableBuilder(
      column: $table.sha1Full, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedTimestamp => $composableBuilder(
      column: $table.addedTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get modifiedTimestamp => $composableBuilder(
      column: $table.modifiedTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hasCover => $composableBuilder(
      column: $table.hasCover, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hasMetadata => $composableBuilder(
      column: $table.hasMetadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isQuarantined => $composableBuilder(
      column: $table.isQuarantined, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quarantineReason => $composableBuilder(
      column: $table.quarantineReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get variantGroup => $composableBuilder(
      column: $table.variantGroup, builder: (column) => ColumnFilters(column));

  Expression<bool> issuesRefs(
      Expression<bool> Function($$IssuesTableFilterComposer f) f) {
    final $$IssuesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.issues,
        getReferencedColumn: (t) => t.titleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IssuesTableFilterComposer(
              $db: $db,
              $table: $db.issues,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> quarantineLogsRefs(
      Expression<bool> Function($$QuarantineLogsTableFilterComposer f) f) {
    final $$QuarantineLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quarantineLogs,
        getReferencedColumn: (t) => t.titleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuarantineLogsTableFilterComposer(
              $db: $db,
              $table: $db.quarantineLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TitlesTableOrderingComposer
    extends Composer<_$AppDatabase, $TitlesTable> {
  $$TitlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha1Partial => $composableBuilder(
      column: $table.sha1Partial, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha1Full => $composableBuilder(
      column: $table.sha1Full, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedTimestamp => $composableBuilder(
      column: $table.addedTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get modifiedTimestamp => $composableBuilder(
      column: $table.modifiedTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastVerified => $composableBuilder(
      column: $table.lastVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hasCover => $composableBuilder(
      column: $table.hasCover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hasMetadata => $composableBuilder(
      column: $table.hasMetadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isQuarantined => $composableBuilder(
      column: $table.isQuarantined,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quarantineReason => $composableBuilder(
      column: $table.quarantineReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get variantGroup => $composableBuilder(
      column: $table.variantGroup,
      builder: (column) => ColumnOrderings(column));
}

class $$TitlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TitlesTable> {
  $$TitlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha1Partial => $composableBuilder(
      column: $table.sha1Partial, builder: (column) => column);

  GeneratedColumn<String> get sha1Full =>
      $composableBuilder(column: $table.sha1Full, builder: (column) => column);

  GeneratedColumn<int> get addedTimestamp => $composableBuilder(
      column: $table.addedTimestamp, builder: (column) => column);

  GeneratedColumn<int> get modifiedTimestamp => $composableBuilder(
      column: $table.modifiedTimestamp, builder: (column) => column);

  GeneratedColumn<int> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => column);

  GeneratedColumn<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus, builder: (column) => column);

  GeneratedColumn<int> get hasCover =>
      $composableBuilder(column: $table.hasCover, builder: (column) => column);

  GeneratedColumn<int> get hasMetadata => $composableBuilder(
      column: $table.hasMetadata, builder: (column) => column);

  GeneratedColumn<int> get isQuarantined => $composableBuilder(
      column: $table.isQuarantined, builder: (column) => column);

  GeneratedColumn<String> get quarantineReason => $composableBuilder(
      column: $table.quarantineReason, builder: (column) => column);

  GeneratedColumn<int> get variantGroup => $composableBuilder(
      column: $table.variantGroup, builder: (column) => column);

  Expression<T> issuesRefs<T extends Object>(
      Expression<T> Function($$IssuesTableAnnotationComposer a) f) {
    final $$IssuesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.issues,
        getReferencedColumn: (t) => t.titleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IssuesTableAnnotationComposer(
              $db: $db,
              $table: $db.issues,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> quarantineLogsRefs<T extends Object>(
      Expression<T> Function($$QuarantineLogsTableAnnotationComposer a) f) {
    final $$QuarantineLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quarantineLogs,
        getReferencedColumn: (t) => t.titleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuarantineLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.quarantineLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TitlesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TitlesTable,
    Title,
    $$TitlesTableFilterComposer,
    $$TitlesTableOrderingComposer,
    $$TitlesTableAnnotationComposer,
    $$TitlesTableCreateCompanionBuilder,
    $$TitlesTableUpdateCompanionBuilder,
    (Title, $$TitlesTableReferences),
    Title,
    PrefetchHooks Function({bool issuesRefs, bool quarantineLogsRefs})> {
  $$TitlesTableTableManager(_$AppDatabase db, $TitlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TitlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TitlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TitlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> gameId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String?> region = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> sha1Partial = const Value.absent(),
            Value<String?> sha1Full = const Value.absent(),
            Value<int> addedTimestamp = const Value.absent(),
            Value<int> modifiedTimestamp = const Value.absent(),
            Value<int?> lastVerified = const Value.absent(),
            Value<String> healthStatus = const Value.absent(),
            Value<int> hasCover = const Value.absent(),
            Value<int> hasMetadata = const Value.absent(),
            Value<int> isQuarantined = const Value.absent(),
            Value<String?> quarantineReason = const Value.absent(),
            Value<int?> variantGroup = const Value.absent(),
          }) =>
              TitlesCompanion(
            id: id,
            gameId: gameId,
            title: title,
            platform: platform,
            region: region,
            format: format,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            sha1Partial: sha1Partial,
            sha1Full: sha1Full,
            addedTimestamp: addedTimestamp,
            modifiedTimestamp: modifiedTimestamp,
            lastVerified: lastVerified,
            healthStatus: healthStatus,
            hasCover: hasCover,
            hasMetadata: hasMetadata,
            isQuarantined: isQuarantined,
            quarantineReason: quarantineReason,
            variantGroup: variantGroup,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String gameId,
            required String title,
            required String platform,
            Value<String?> region = const Value.absent(),
            required String format,
            required String filePath,
            required int fileSizeBytes,
            Value<String?> sha1Partial = const Value.absent(),
            Value<String?> sha1Full = const Value.absent(),
            required int addedTimestamp,
            required int modifiedTimestamp,
            Value<int?> lastVerified = const Value.absent(),
            Value<String> healthStatus = const Value.absent(),
            Value<int> hasCover = const Value.absent(),
            Value<int> hasMetadata = const Value.absent(),
            Value<int> isQuarantined = const Value.absent(),
            Value<String?> quarantineReason = const Value.absent(),
            Value<int?> variantGroup = const Value.absent(),
          }) =>
              TitlesCompanion.insert(
            id: id,
            gameId: gameId,
            title: title,
            platform: platform,
            region: region,
            format: format,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            sha1Partial: sha1Partial,
            sha1Full: sha1Full,
            addedTimestamp: addedTimestamp,
            modifiedTimestamp: modifiedTimestamp,
            lastVerified: lastVerified,
            healthStatus: healthStatus,
            hasCover: hasCover,
            hasMetadata: hasMetadata,
            isQuarantined: isQuarantined,
            quarantineReason: quarantineReason,
            variantGroup: variantGroup,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TitlesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {issuesRefs = false, quarantineLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (issuesRefs) db.issues,
                if (quarantineLogsRefs) db.quarantineLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (issuesRefs)
                    await $_getPrefetchedData<Title, $TitlesTable, Issue>(
                        currentTable: table,
                        referencedTable:
                            $$TitlesTableReferences._issuesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TitlesTableReferences(db, table, p0).issuesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.titleId == item.id),
                        typedResults: items),
                  if (quarantineLogsRefs)
                    await $_getPrefetchedData<Title, $TitlesTable,
                            QuarantineLog>(
                        currentTable: table,
                        referencedTable: $$TitlesTableReferences
                            ._quarantineLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TitlesTableReferences(db, table, p0)
                                .quarantineLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.titleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TitlesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TitlesTable,
    Title,
    $$TitlesTableFilterComposer,
    $$TitlesTableOrderingComposer,
    $$TitlesTableAnnotationComposer,
    $$TitlesTableCreateCompanionBuilder,
    $$TitlesTableUpdateCompanionBuilder,
    (Title, $$TitlesTableReferences),
    Title,
    PrefetchHooks Function({bool issuesRefs, bool quarantineLogsRefs})>;
typedef $$IssuesTableCreateCompanionBuilder = IssuesCompanion Function({
  Value<int> id,
  Value<int?> titleId,
  required String issueType,
  required String severity,
  required String description,
  Value<int> estimatedImpactScore,
  Value<int> estimatedSpaceSavings,
  Value<String?> fixAction,
  required int createdTimestamp,
  Value<int?> resolvedTimestamp,
});
typedef $$IssuesTableUpdateCompanionBuilder = IssuesCompanion Function({
  Value<int> id,
  Value<int?> titleId,
  Value<String> issueType,
  Value<String> severity,
  Value<String> description,
  Value<int> estimatedImpactScore,
  Value<int> estimatedSpaceSavings,
  Value<String?> fixAction,
  Value<int> createdTimestamp,
  Value<int?> resolvedTimestamp,
});

final class $$IssuesTableReferences
    extends BaseReferences<_$AppDatabase, $IssuesTable, Issue> {
  $$IssuesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TitlesTable _titleIdTable(_$AppDatabase db) => db.titles
      .createAlias($_aliasNameGenerator(db.issues.titleId, db.titles.id));

  $$TitlesTableProcessedTableManager? get titleId {
    final $_column = $_itemColumn<int>('title_id');
    if ($_column == null) return null;
    final manager = $$TitlesTableTableManager($_db, $_db.titles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_titleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IssuesTableFilterComposer
    extends Composer<_$AppDatabase, $IssuesTable> {
  $$IssuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issueType => $composableBuilder(
      column: $table.issueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedImpactScore => $composableBuilder(
      column: $table.estimatedImpactScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedSpaceSavings => $composableBuilder(
      column: $table.estimatedSpaceSavings,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fixAction => $composableBuilder(
      column: $table.fixAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdTimestamp => $composableBuilder(
      column: $table.createdTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resolvedTimestamp => $composableBuilder(
      column: $table.resolvedTimestamp,
      builder: (column) => ColumnFilters(column));

  $$TitlesTableFilterComposer get titleId {
    final $$TitlesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableFilterComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IssuesTableOrderingComposer
    extends Composer<_$AppDatabase, $IssuesTable> {
  $$IssuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issueType => $composableBuilder(
      column: $table.issueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedImpactScore => $composableBuilder(
      column: $table.estimatedImpactScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedSpaceSavings => $composableBuilder(
      column: $table.estimatedSpaceSavings,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fixAction => $composableBuilder(
      column: $table.fixAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdTimestamp => $composableBuilder(
      column: $table.createdTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resolvedTimestamp => $composableBuilder(
      column: $table.resolvedTimestamp,
      builder: (column) => ColumnOrderings(column));

  $$TitlesTableOrderingComposer get titleId {
    final $$TitlesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableOrderingComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IssuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IssuesTable> {
  $$IssuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issueType =>
      $composableBuilder(column: $table.issueType, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get estimatedImpactScore => $composableBuilder(
      column: $table.estimatedImpactScore, builder: (column) => column);

  GeneratedColumn<int> get estimatedSpaceSavings => $composableBuilder(
      column: $table.estimatedSpaceSavings, builder: (column) => column);

  GeneratedColumn<String> get fixAction =>
      $composableBuilder(column: $table.fixAction, builder: (column) => column);

  GeneratedColumn<int> get createdTimestamp => $composableBuilder(
      column: $table.createdTimestamp, builder: (column) => column);

  GeneratedColumn<int> get resolvedTimestamp => $composableBuilder(
      column: $table.resolvedTimestamp, builder: (column) => column);

  $$TitlesTableAnnotationComposer get titleId {
    final $$TitlesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableAnnotationComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IssuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IssuesTable,
    Issue,
    $$IssuesTableFilterComposer,
    $$IssuesTableOrderingComposer,
    $$IssuesTableAnnotationComposer,
    $$IssuesTableCreateCompanionBuilder,
    $$IssuesTableUpdateCompanionBuilder,
    (Issue, $$IssuesTableReferences),
    Issue,
    PrefetchHooks Function({bool titleId})> {
  $$IssuesTableTableManager(_$AppDatabase db, $IssuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> titleId = const Value.absent(),
            Value<String> issueType = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> estimatedImpactScore = const Value.absent(),
            Value<int> estimatedSpaceSavings = const Value.absent(),
            Value<String?> fixAction = const Value.absent(),
            Value<int> createdTimestamp = const Value.absent(),
            Value<int?> resolvedTimestamp = const Value.absent(),
          }) =>
              IssuesCompanion(
            id: id,
            titleId: titleId,
            issueType: issueType,
            severity: severity,
            description: description,
            estimatedImpactScore: estimatedImpactScore,
            estimatedSpaceSavings: estimatedSpaceSavings,
            fixAction: fixAction,
            createdTimestamp: createdTimestamp,
            resolvedTimestamp: resolvedTimestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> titleId = const Value.absent(),
            required String issueType,
            required String severity,
            required String description,
            Value<int> estimatedImpactScore = const Value.absent(),
            Value<int> estimatedSpaceSavings = const Value.absent(),
            Value<String?> fixAction = const Value.absent(),
            required int createdTimestamp,
            Value<int?> resolvedTimestamp = const Value.absent(),
          }) =>
              IssuesCompanion.insert(
            id: id,
            titleId: titleId,
            issueType: issueType,
            severity: severity,
            description: description,
            estimatedImpactScore: estimatedImpactScore,
            estimatedSpaceSavings: estimatedSpaceSavings,
            fixAction: fixAction,
            createdTimestamp: createdTimestamp,
            resolvedTimestamp: resolvedTimestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$IssuesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({titleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (titleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.titleId,
                    referencedTable: $$IssuesTableReferences._titleIdTable(db),
                    referencedColumn:
                        $$IssuesTableReferences._titleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IssuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IssuesTable,
    Issue,
    $$IssuesTableFilterComposer,
    $$IssuesTableOrderingComposer,
    $$IssuesTableAnnotationComposer,
    $$IssuesTableCreateCompanionBuilder,
    $$IssuesTableUpdateCompanionBuilder,
    (Issue, $$IssuesTableReferences),
    Issue,
    PrefetchHooks Function({bool titleId})>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String taskType,
  required String state,
  Value<int> priority,
  required String payload,
  Value<double> progressPercent,
  Value<String?> progressMessage,
  Value<int?> startedTimestamp,
  Value<int?> completedTimestamp,
  Value<String?> errorMessage,
  Value<int?> dependsOn,
  Value<int> retryCount,
  Value<String?> logPath,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> taskType,
  Value<String> state,
  Value<int> priority,
  Value<String> payload,
  Value<double> progressPercent,
  Value<String?> progressMessage,
  Value<int?> startedTimestamp,
  Value<int?> completedTimestamp,
  Value<String?> errorMessage,
  Value<int?> dependsOn,
  Value<int> retryCount,
  Value<String?> logPath,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _dependsOnTable(_$AppDatabase db) => db.tasks
      .createAlias($_aliasNameGenerator(db.tasks.dependsOn, db.tasks.id));

  $$TasksTableProcessedTableManager? get dependsOn {
    final $_column = $_itemColumn<int>('depends_on');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dependsOnTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progressPercent => $composableBuilder(
      column: $table.progressPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get progressMessage => $composableBuilder(
      column: $table.progressMessage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedTimestamp => $composableBuilder(
      column: $table.startedTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedTimestamp => $composableBuilder(
      column: $table.completedTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logPath => $composableBuilder(
      column: $table.logPath, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get dependsOn {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOn,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progressPercent => $composableBuilder(
      column: $table.progressPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get progressMessage => $composableBuilder(
      column: $table.progressMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedTimestamp => $composableBuilder(
      column: $table.startedTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedTimestamp => $composableBuilder(
      column: $table.completedTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logPath => $composableBuilder(
      column: $table.logPath, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get dependsOn {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOn,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableOrderingComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<double> get progressPercent => $composableBuilder(
      column: $table.progressPercent, builder: (column) => column);

  GeneratedColumn<String> get progressMessage => $composableBuilder(
      column: $table.progressMessage, builder: (column) => column);

  GeneratedColumn<int> get startedTimestamp => $composableBuilder(
      column: $table.startedTimestamp, builder: (column) => column);

  GeneratedColumn<int> get completedTimestamp => $composableBuilder(
      column: $table.completedTimestamp, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get logPath =>
      $composableBuilder(column: $table.logPath, builder: (column) => column);

  $$TasksTableAnnotationComposer get dependsOn {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOn,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool dependsOn})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<double> progressPercent = const Value.absent(),
            Value<String?> progressMessage = const Value.absent(),
            Value<int?> startedTimestamp = const Value.absent(),
            Value<int?> completedTimestamp = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> dependsOn = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> logPath = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            taskType: taskType,
            state: state,
            priority: priority,
            payload: payload,
            progressPercent: progressPercent,
            progressMessage: progressMessage,
            startedTimestamp: startedTimestamp,
            completedTimestamp: completedTimestamp,
            errorMessage: errorMessage,
            dependsOn: dependsOn,
            retryCount: retryCount,
            logPath: logPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String taskType,
            required String state,
            Value<int> priority = const Value.absent(),
            required String payload,
            Value<double> progressPercent = const Value.absent(),
            Value<String?> progressMessage = const Value.absent(),
            Value<int?> startedTimestamp = const Value.absent(),
            Value<int?> completedTimestamp = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> dependsOn = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> logPath = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            taskType: taskType,
            state: state,
            priority: priority,
            payload: payload,
            progressPercent: progressPercent,
            progressMessage: progressMessage,
            startedTimestamp: startedTimestamp,
            completedTimestamp: completedTimestamp,
            errorMessage: errorMessage,
            dependsOn: dependsOn,
            retryCount: retryCount,
            logPath: logPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({dependsOn = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dependsOn) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dependsOn,
                    referencedTable: $$TasksTableReferences._dependsOnTable(db),
                    referencedColumn:
                        $$TasksTableReferences._dependsOnTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool dependsOn})>;
typedef $$HealthSnapshotsTableCreateCompanionBuilder = HealthSnapshotsCompanion
    Function({
  Value<int> id,
  required int timestamp,
  required int score,
  Value<int> totalTitles,
  Value<int> healthyCount,
  Value<int> duplicateCount,
  Value<int> corruptedCount,
  Value<int> missingMetadataCount,
  Value<int> totalSizeBytes,
  Value<int> potentialSavingsBytes,
});
typedef $$HealthSnapshotsTableUpdateCompanionBuilder = HealthSnapshotsCompanion
    Function({
  Value<int> id,
  Value<int> timestamp,
  Value<int> score,
  Value<int> totalTitles,
  Value<int> healthyCount,
  Value<int> duplicateCount,
  Value<int> corruptedCount,
  Value<int> missingMetadataCount,
  Value<int> totalSizeBytes,
  Value<int> potentialSavingsBytes,
});

class $$HealthSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTitles => $composableBuilder(
      column: $table.totalTitles, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get healthyCount => $composableBuilder(
      column: $table.healthyCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duplicateCount => $composableBuilder(
      column: $table.duplicateCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get corruptedCount => $composableBuilder(
      column: $table.corruptedCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get missingMetadataCount => $composableBuilder(
      column: $table.missingMetadataCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get potentialSavingsBytes => $composableBuilder(
      column: $table.potentialSavingsBytes,
      builder: (column) => ColumnFilters(column));
}

class $$HealthSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTitles => $composableBuilder(
      column: $table.totalTitles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get healthyCount => $composableBuilder(
      column: $table.healthyCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duplicateCount => $composableBuilder(
      column: $table.duplicateCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get corruptedCount => $composableBuilder(
      column: $table.corruptedCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get missingMetadataCount => $composableBuilder(
      column: $table.missingMetadataCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get potentialSavingsBytes => $composableBuilder(
      column: $table.potentialSavingsBytes,
      builder: (column) => ColumnOrderings(column));
}

class $$HealthSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get totalTitles => $composableBuilder(
      column: $table.totalTitles, builder: (column) => column);

  GeneratedColumn<int> get healthyCount => $composableBuilder(
      column: $table.healthyCount, builder: (column) => column);

  GeneratedColumn<int> get duplicateCount => $composableBuilder(
      column: $table.duplicateCount, builder: (column) => column);

  GeneratedColumn<int> get corruptedCount => $composableBuilder(
      column: $table.corruptedCount, builder: (column) => column);

  GeneratedColumn<int> get missingMetadataCount => $composableBuilder(
      column: $table.missingMetadataCount, builder: (column) => column);

  GeneratedColumn<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes, builder: (column) => column);

  GeneratedColumn<int> get potentialSavingsBytes => $composableBuilder(
      column: $table.potentialSavingsBytes, builder: (column) => column);
}

class $$HealthSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HealthSnapshotsTable,
    HealthSnapshot,
    $$HealthSnapshotsTableFilterComposer,
    $$HealthSnapshotsTableOrderingComposer,
    $$HealthSnapshotsTableAnnotationComposer,
    $$HealthSnapshotsTableCreateCompanionBuilder,
    $$HealthSnapshotsTableUpdateCompanionBuilder,
    (
      HealthSnapshot,
      BaseReferences<_$AppDatabase, $HealthSnapshotsTable, HealthSnapshot>
    ),
    HealthSnapshot,
    PrefetchHooks Function()> {
  $$HealthSnapshotsTableTableManager(
      _$AppDatabase db, $HealthSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int> totalTitles = const Value.absent(),
            Value<int> healthyCount = const Value.absent(),
            Value<int> duplicateCount = const Value.absent(),
            Value<int> corruptedCount = const Value.absent(),
            Value<int> missingMetadataCount = const Value.absent(),
            Value<int> totalSizeBytes = const Value.absent(),
            Value<int> potentialSavingsBytes = const Value.absent(),
          }) =>
              HealthSnapshotsCompanion(
            id: id,
            timestamp: timestamp,
            score: score,
            totalTitles: totalTitles,
            healthyCount: healthyCount,
            duplicateCount: duplicateCount,
            corruptedCount: corruptedCount,
            missingMetadataCount: missingMetadataCount,
            totalSizeBytes: totalSizeBytes,
            potentialSavingsBytes: potentialSavingsBytes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int timestamp,
            required int score,
            Value<int> totalTitles = const Value.absent(),
            Value<int> healthyCount = const Value.absent(),
            Value<int> duplicateCount = const Value.absent(),
            Value<int> corruptedCount = const Value.absent(),
            Value<int> missingMetadataCount = const Value.absent(),
            Value<int> totalSizeBytes = const Value.absent(),
            Value<int> potentialSavingsBytes = const Value.absent(),
          }) =>
              HealthSnapshotsCompanion.insert(
            id: id,
            timestamp: timestamp,
            score: score,
            totalTitles: totalTitles,
            healthyCount: healthyCount,
            duplicateCount: duplicateCount,
            corruptedCount: corruptedCount,
            missingMetadataCount: missingMetadataCount,
            totalSizeBytes: totalSizeBytes,
            potentialSavingsBytes: potentialSavingsBytes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HealthSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HealthSnapshotsTable,
    HealthSnapshot,
    $$HealthSnapshotsTableFilterComposer,
    $$HealthSnapshotsTableOrderingComposer,
    $$HealthSnapshotsTableAnnotationComposer,
    $$HealthSnapshotsTableCreateCompanionBuilder,
    $$HealthSnapshotsTableUpdateCompanionBuilder,
    (
      HealthSnapshot,
      BaseReferences<_$AppDatabase, $HealthSnapshotsTable, HealthSnapshot>
    ),
    HealthSnapshot,
    PrefetchHooks Function()>;
typedef $$QuarantineLogsTableCreateCompanionBuilder = QuarantineLogsCompanion
    Function({
  Value<int> id,
  required int titleId,
  required String originalPath,
  required String quarantinePath,
  Value<String?> reason,
  required int timestamp,
  Value<int?> restoredTimestamp,
});
typedef $$QuarantineLogsTableUpdateCompanionBuilder = QuarantineLogsCompanion
    Function({
  Value<int> id,
  Value<int> titleId,
  Value<String> originalPath,
  Value<String> quarantinePath,
  Value<String?> reason,
  Value<int> timestamp,
  Value<int?> restoredTimestamp,
});

final class $$QuarantineLogsTableReferences
    extends BaseReferences<_$AppDatabase, $QuarantineLogsTable, QuarantineLog> {
  $$QuarantineLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TitlesTable _titleIdTable(_$AppDatabase db) => db.titles.createAlias(
      $_aliasNameGenerator(db.quarantineLogs.titleId, db.titles.id));

  $$TitlesTableProcessedTableManager get titleId {
    final $_column = $_itemColumn<int>('title_id')!;

    final manager = $$TitlesTableTableManager($_db, $_db.titles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_titleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$QuarantineLogsTableFilterComposer
    extends Composer<_$AppDatabase, $QuarantineLogsTable> {
  $$QuarantineLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalPath => $composableBuilder(
      column: $table.originalPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quarantinePath => $composableBuilder(
      column: $table.quarantinePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restoredTimestamp => $composableBuilder(
      column: $table.restoredTimestamp,
      builder: (column) => ColumnFilters(column));

  $$TitlesTableFilterComposer get titleId {
    final $$TitlesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableFilterComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuarantineLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuarantineLogsTable> {
  $$QuarantineLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalPath => $composableBuilder(
      column: $table.originalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quarantinePath => $composableBuilder(
      column: $table.quarantinePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restoredTimestamp => $composableBuilder(
      column: $table.restoredTimestamp,
      builder: (column) => ColumnOrderings(column));

  $$TitlesTableOrderingComposer get titleId {
    final $$TitlesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableOrderingComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuarantineLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuarantineLogsTable> {
  $$QuarantineLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
      column: $table.originalPath, builder: (column) => column);

  GeneratedColumn<String> get quarantinePath => $composableBuilder(
      column: $table.quarantinePath, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get restoredTimestamp => $composableBuilder(
      column: $table.restoredTimestamp, builder: (column) => column);

  $$TitlesTableAnnotationComposer get titleId {
    final $$TitlesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.titleId,
        referencedTable: $db.titles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TitlesTableAnnotationComposer(
              $db: $db,
              $table: $db.titles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuarantineLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuarantineLogsTable,
    QuarantineLog,
    $$QuarantineLogsTableFilterComposer,
    $$QuarantineLogsTableOrderingComposer,
    $$QuarantineLogsTableAnnotationComposer,
    $$QuarantineLogsTableCreateCompanionBuilder,
    $$QuarantineLogsTableUpdateCompanionBuilder,
    (QuarantineLog, $$QuarantineLogsTableReferences),
    QuarantineLog,
    PrefetchHooks Function({bool titleId})> {
  $$QuarantineLogsTableTableManager(
      _$AppDatabase db, $QuarantineLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuarantineLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuarantineLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuarantineLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> titleId = const Value.absent(),
            Value<String> originalPath = const Value.absent(),
            Value<String> quarantinePath = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int?> restoredTimestamp = const Value.absent(),
          }) =>
              QuarantineLogsCompanion(
            id: id,
            titleId: titleId,
            originalPath: originalPath,
            quarantinePath: quarantinePath,
            reason: reason,
            timestamp: timestamp,
            restoredTimestamp: restoredTimestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int titleId,
            required String originalPath,
            required String quarantinePath,
            Value<String?> reason = const Value.absent(),
            required int timestamp,
            Value<int?> restoredTimestamp = const Value.absent(),
          }) =>
              QuarantineLogsCompanion.insert(
            id: id,
            titleId: titleId,
            originalPath: originalPath,
            quarantinePath: quarantinePath,
            reason: reason,
            timestamp: timestamp,
            restoredTimestamp: restoredTimestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuarantineLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({titleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (titleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.titleId,
                    referencedTable:
                        $$QuarantineLogsTableReferences._titleIdTable(db),
                    referencedColumn:
                        $$QuarantineLogsTableReferences._titleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$QuarantineLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuarantineLogsTable,
    QuarantineLog,
    $$QuarantineLogsTableFilterComposer,
    $$QuarantineLogsTableOrderingComposer,
    $$QuarantineLogsTableAnnotationComposer,
    $$QuarantineLogsTableCreateCompanionBuilder,
    $$QuarantineLogsTableUpdateCompanionBuilder,
    (QuarantineLog, $$QuarantineLogsTableReferences),
    QuarantineLog,
    PrefetchHooks Function({bool titleId})>;
typedef $$SchemaVersionsTableCreateCompanionBuilder = SchemaVersionsCompanion
    Function({
  Value<int> version,
  required int appliedTimestamp,
});
typedef $$SchemaVersionsTableUpdateCompanionBuilder = SchemaVersionsCompanion
    Function({
  Value<int> version,
  Value<int> appliedTimestamp,
});

class $$SchemaVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaVersionsTable> {
  $$SchemaVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get appliedTimestamp => $composableBuilder(
      column: $table.appliedTimestamp,
      builder: (column) => ColumnFilters(column));
}

class $$SchemaVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaVersionsTable> {
  $$SchemaVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get appliedTimestamp => $composableBuilder(
      column: $table.appliedTimestamp,
      builder: (column) => ColumnOrderings(column));
}

class $$SchemaVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaVersionsTable> {
  $$SchemaVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get appliedTimestamp => $composableBuilder(
      column: $table.appliedTimestamp, builder: (column) => column);
}

class $$SchemaVersionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SchemaVersionsTable,
    SchemaVersion,
    $$SchemaVersionsTableFilterComposer,
    $$SchemaVersionsTableOrderingComposer,
    $$SchemaVersionsTableAnnotationComposer,
    $$SchemaVersionsTableCreateCompanionBuilder,
    $$SchemaVersionsTableUpdateCompanionBuilder,
    (
      SchemaVersion,
      BaseReferences<_$AppDatabase, $SchemaVersionsTable, SchemaVersion>
    ),
    SchemaVersion,
    PrefetchHooks Function()> {
  $$SchemaVersionsTableTableManager(
      _$AppDatabase db, $SchemaVersionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> version = const Value.absent(),
            Value<int> appliedTimestamp = const Value.absent(),
          }) =>
              SchemaVersionsCompanion(
            version: version,
            appliedTimestamp: appliedTimestamp,
          ),
          createCompanionCallback: ({
            Value<int> version = const Value.absent(),
            required int appliedTimestamp,
          }) =>
              SchemaVersionsCompanion.insert(
            version: version,
            appliedTimestamp: appliedTimestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SchemaVersionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SchemaVersionsTable,
    SchemaVersion,
    $$SchemaVersionsTableFilterComposer,
    $$SchemaVersionsTableOrderingComposer,
    $$SchemaVersionsTableAnnotationComposer,
    $$SchemaVersionsTableCreateCompanionBuilder,
    $$SchemaVersionsTableUpdateCompanionBuilder,
    (
      SchemaVersion,
      BaseReferences<_$AppDatabase, $SchemaVersionsTable, SchemaVersion>
    ),
    SchemaVersion,
    PrefetchHooks Function()>;
typedef $$PatchedRomsTableCreateCompanionBuilder = PatchedRomsCompanion
    Function({
  required String id,
  required String baseGameId,
  required String patchName,
  required String patchVersion,
  required String downloadUrl,
  Value<String?> archiveUrl,
  Value<String?> torrentUrl,
  Value<String?> sha256Hash,
  Value<String?> sha1Hash,
  required int fileSizeBytes,
  Value<String?> patchNotes,
  required String platform,
  Value<String?> region,
  required int createdAt,
  required int updatedAt,
  Value<int> downloadCount,
  Value<int> isVerified,
  Value<int> rowid,
});
typedef $$PatchedRomsTableUpdateCompanionBuilder = PatchedRomsCompanion
    Function({
  Value<String> id,
  Value<String> baseGameId,
  Value<String> patchName,
  Value<String> patchVersion,
  Value<String> downloadUrl,
  Value<String?> archiveUrl,
  Value<String?> torrentUrl,
  Value<String?> sha256Hash,
  Value<String?> sha1Hash,
  Value<int> fileSizeBytes,
  Value<String?> patchNotes,
  Value<String> platform,
  Value<String?> region,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> downloadCount,
  Value<int> isVerified,
  Value<int> rowid,
});

class $$PatchedRomsTableFilterComposer
    extends Composer<_$AppDatabase, $PatchedRomsTable> {
  $$PatchedRomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseGameId => $composableBuilder(
      column: $table.baseGameId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patchName => $composableBuilder(
      column: $table.patchName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patchVersion => $composableBuilder(
      column: $table.patchVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get archiveUrl => $composableBuilder(
      column: $table.archiveUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get torrentUrl => $composableBuilder(
      column: $table.torrentUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256Hash => $composableBuilder(
      column: $table.sha256Hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha1Hash => $composableBuilder(
      column: $table.sha1Hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patchNotes => $composableBuilder(
      column: $table.patchNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadCount => $composableBuilder(
      column: $table.downloadCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnFilters(column));
}

class $$PatchedRomsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatchedRomsTable> {
  $$PatchedRomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseGameId => $composableBuilder(
      column: $table.baseGameId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patchName => $composableBuilder(
      column: $table.patchName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patchVersion => $composableBuilder(
      column: $table.patchVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get archiveUrl => $composableBuilder(
      column: $table.archiveUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get torrentUrl => $composableBuilder(
      column: $table.torrentUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256Hash => $composableBuilder(
      column: $table.sha256Hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha1Hash => $composableBuilder(
      column: $table.sha1Hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patchNotes => $composableBuilder(
      column: $table.patchNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadCount => $composableBuilder(
      column: $table.downloadCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnOrderings(column));
}

class $$PatchedRomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatchedRomsTable> {
  $$PatchedRomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseGameId => $composableBuilder(
      column: $table.baseGameId, builder: (column) => column);

  GeneratedColumn<String> get patchName =>
      $composableBuilder(column: $table.patchName, builder: (column) => column);

  GeneratedColumn<String> get patchVersion => $composableBuilder(
      column: $table.patchVersion, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => column);

  GeneratedColumn<String> get archiveUrl => $composableBuilder(
      column: $table.archiveUrl, builder: (column) => column);

  GeneratedColumn<String> get torrentUrl => $composableBuilder(
      column: $table.torrentUrl, builder: (column) => column);

  GeneratedColumn<String> get sha256Hash => $composableBuilder(
      column: $table.sha256Hash, builder: (column) => column);

  GeneratedColumn<String> get sha1Hash =>
      $composableBuilder(column: $table.sha1Hash, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get patchNotes => $composableBuilder(
      column: $table.patchNotes, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get downloadCount => $composableBuilder(
      column: $table.downloadCount, builder: (column) => column);

  GeneratedColumn<int> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => column);
}

class $$PatchedRomsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatchedRomsTable,
    PatchedRom,
    $$PatchedRomsTableFilterComposer,
    $$PatchedRomsTableOrderingComposer,
    $$PatchedRomsTableAnnotationComposer,
    $$PatchedRomsTableCreateCompanionBuilder,
    $$PatchedRomsTableUpdateCompanionBuilder,
    (PatchedRom, BaseReferences<_$AppDatabase, $PatchedRomsTable, PatchedRom>),
    PatchedRom,
    PrefetchHooks Function()> {
  $$PatchedRomsTableTableManager(_$AppDatabase db, $PatchedRomsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatchedRomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatchedRomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatchedRomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> baseGameId = const Value.absent(),
            Value<String> patchName = const Value.absent(),
            Value<String> patchVersion = const Value.absent(),
            Value<String> downloadUrl = const Value.absent(),
            Value<String?> archiveUrl = const Value.absent(),
            Value<String?> torrentUrl = const Value.absent(),
            Value<String?> sha256Hash = const Value.absent(),
            Value<String?> sha1Hash = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> patchNotes = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String?> region = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> downloadCount = const Value.absent(),
            Value<int> isVerified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatchedRomsCompanion(
            id: id,
            baseGameId: baseGameId,
            patchName: patchName,
            patchVersion: patchVersion,
            downloadUrl: downloadUrl,
            archiveUrl: archiveUrl,
            torrentUrl: torrentUrl,
            sha256Hash: sha256Hash,
            sha1Hash: sha1Hash,
            fileSizeBytes: fileSizeBytes,
            patchNotes: patchNotes,
            platform: platform,
            region: region,
            createdAt: createdAt,
            updatedAt: updatedAt,
            downloadCount: downloadCount,
            isVerified: isVerified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String baseGameId,
            required String patchName,
            required String patchVersion,
            required String downloadUrl,
            Value<String?> archiveUrl = const Value.absent(),
            Value<String?> torrentUrl = const Value.absent(),
            Value<String?> sha256Hash = const Value.absent(),
            Value<String?> sha1Hash = const Value.absent(),
            required int fileSizeBytes,
            Value<String?> patchNotes = const Value.absent(),
            required String platform,
            Value<String?> region = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> downloadCount = const Value.absent(),
            Value<int> isVerified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatchedRomsCompanion.insert(
            id: id,
            baseGameId: baseGameId,
            patchName: patchName,
            patchVersion: patchVersion,
            downloadUrl: downloadUrl,
            archiveUrl: archiveUrl,
            torrentUrl: torrentUrl,
            sha256Hash: sha256Hash,
            sha1Hash: sha1Hash,
            fileSizeBytes: fileSizeBytes,
            patchNotes: patchNotes,
            platform: platform,
            region: region,
            createdAt: createdAt,
            updatedAt: updatedAt,
            downloadCount: downloadCount,
            isVerified: isVerified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatchedRomsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatchedRomsTable,
    PatchedRom,
    $$PatchedRomsTableFilterComposer,
    $$PatchedRomsTableOrderingComposer,
    $$PatchedRomsTableAnnotationComposer,
    $$PatchedRomsTableCreateCompanionBuilder,
    $$PatchedRomsTableUpdateCompanionBuilder,
    (PatchedRom, BaseReferences<_$AppDatabase, $PatchedRomsTable, PatchedRom>),
    PatchedRom,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  required String gameId,
  required String title,
  required String platform,
  required String downloadUrl,
  required String savePath,
  required int totalBytes,
  Value<int> downloadedBytes,
  Value<String> status,
  Value<String?> provider,
  Value<String?> errorMessage,
  required int createdAt,
  required int updatedAt,
  Value<int?> completedAt,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  Value<String> gameId,
  Value<String> title,
  Value<String> platform,
  Value<String> downloadUrl,
  Value<String> savePath,
  Value<int> totalBytes,
  Value<int> downloadedBytes,
  Value<String> status,
  Value<String?> provider,
  Value<String?> errorMessage,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> completedAt,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get savePath => $composableBuilder(
      column: $table.savePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get savePath => $composableBuilder(
      column: $table.savePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => column);

  GeneratedColumn<String> get savePath =>
      $composableBuilder(column: $table.savePath, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> gameId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> downloadUrl = const Value.absent(),
            Value<String> savePath = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> provider = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
          }) =>
              DownloadsCompanion(
            id: id,
            gameId: gameId,
            title: title,
            platform: platform,
            downloadUrl: downloadUrl,
            savePath: savePath,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            status: status,
            provider: provider,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String gameId,
            required String title,
            required String platform,
            required String downloadUrl,
            required String savePath,
            required int totalBytes,
            Value<int> downloadedBytes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> provider = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> completedAt = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            id: id,
            gameId: gameId,
            title: title,
            platform: platform,
            downloadUrl: downloadUrl,
            savePath: savePath,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            status: status,
            provider: provider,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TitlesTableTableManager get titles =>
      $$TitlesTableTableManager(_db, _db.titles);
  $$IssuesTableTableManager get issues =>
      $$IssuesTableTableManager(_db, _db.issues);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$HealthSnapshotsTableTableManager get healthSnapshots =>
      $$HealthSnapshotsTableTableManager(_db, _db.healthSnapshots);
  $$QuarantineLogsTableTableManager get quarantineLogs =>
      $$QuarantineLogsTableTableManager(_db, _db.quarantineLogs);
  $$SchemaVersionsTableTableManager get schemaVersions =>
      $$SchemaVersionsTableTableManager(_db, _db.schemaVersions);
  $$PatchedRomsTableTableManager get patchedRoms =>
      $$PatchedRomsTableTableManager(_db, _db.patchedRoms);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
