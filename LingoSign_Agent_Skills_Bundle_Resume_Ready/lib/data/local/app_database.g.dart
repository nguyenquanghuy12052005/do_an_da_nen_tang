// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SignEntriesTable extends SignEntries
    with TableInfo<$SignEntriesTable, SignEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelViMeta = const VerificationMeta(
    'labelVi',
  );
  @override
  late final GeneratedColumn<String> labelVi = GeneratedColumn<String>(
    'label_vi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<String> catalogVersion = GeneratedColumn<String>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseNameMeta = const VerificationMeta(
    'licenseName',
  );
  @override
  late final GeneratedColumn<String> licenseName = GeneratedColumn<String>(
    'license_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    labelVi,
    description,
    mediaLocalPath,
    catalogVersion,
    sourceUrl,
    licenseName,
    updatedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sign_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label_vi')) {
      context.handle(
        _labelViMeta,
        labelVi.isAcceptableOrUnknown(data['label_vi']!, _labelViMeta),
      );
    } else if (isInserting) {
      context.missing(_labelViMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('license_name')) {
      context.handle(
        _licenseNameMeta,
        licenseName.isAcceptableOrUnknown(
          data['license_name']!,
          _licenseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_licenseNameMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  SignEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignEntryRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      labelVi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_vi'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_version'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      licenseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_name'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
    );
  }

  @override
  $SignEntriesTable createAlias(String alias) {
    return $SignEntriesTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class SignEntryRow extends DataClass implements Insertable<SignEntryRow> {
  final String code;
  final String labelVi;
  final String? description;
  final String? mediaLocalPath;
  final String catalogVersion;
  final String sourceUrl;
  final String licenseName;
  final int updatedAtUtcMs;
  const SignEntryRow({
    required this.code,
    required this.labelVi,
    this.description,
    this.mediaLocalPath,
    required this.catalogVersion,
    required this.sourceUrl,
    required this.licenseName,
    required this.updatedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['label_vi'] = Variable<String>(labelVi);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    map['catalog_version'] = Variable<String>(catalogVersion);
    map['source_url'] = Variable<String>(sourceUrl);
    map['license_name'] = Variable<String>(licenseName);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    return map;
  }

  SignEntriesCompanion toCompanion(bool nullToAbsent) {
    return SignEntriesCompanion(
      code: Value(code),
      labelVi: Value(labelVi),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      catalogVersion: Value(catalogVersion),
      sourceUrl: Value(sourceUrl),
      licenseName: Value(licenseName),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    );
  }

  factory SignEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignEntryRow(
      code: serializer.fromJson<String>(json['code']),
      labelVi: serializer.fromJson<String>(json['labelVi']),
      description: serializer.fromJson<String?>(json['description']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      catalogVersion: serializer.fromJson<String>(json['catalogVersion']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      licenseName: serializer.fromJson<String>(json['licenseName']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'labelVi': serializer.toJson<String>(labelVi),
      'description': serializer.toJson<String?>(description),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'catalogVersion': serializer.toJson<String>(catalogVersion),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'licenseName': serializer.toJson<String>(licenseName),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
    };
  }

  SignEntryRow copyWith({
    String? code,
    String? labelVi,
    Value<String?> description = const Value.absent(),
    Value<String?> mediaLocalPath = const Value.absent(),
    String? catalogVersion,
    String? sourceUrl,
    String? licenseName,
    int? updatedAtUtcMs,
  }) => SignEntryRow(
    code: code ?? this.code,
    labelVi: labelVi ?? this.labelVi,
    description: description.present ? description.value : this.description,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    licenseName: licenseName ?? this.licenseName,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
  );
  SignEntryRow copyWithCompanion(SignEntriesCompanion data) {
    return SignEntryRow(
      code: data.code.present ? data.code.value : this.code,
      labelVi: data.labelVi.present ? data.labelVi.value : this.labelVi,
      description: data.description.present
          ? data.description.value
          : this.description,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      licenseName: data.licenseName.present
          ? data.licenseName.value
          : this.licenseName,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignEntryRow(')
          ..write('code: $code, ')
          ..write('labelVi: $labelVi, ')
          ..write('description: $description, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('licenseName: $licenseName, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    labelVi,
    description,
    mediaLocalPath,
    catalogVersion,
    sourceUrl,
    licenseName,
    updatedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignEntryRow &&
          other.code == this.code &&
          other.labelVi == this.labelVi &&
          other.description == this.description &&
          other.mediaLocalPath == this.mediaLocalPath &&
          other.catalogVersion == this.catalogVersion &&
          other.sourceUrl == this.sourceUrl &&
          other.licenseName == this.licenseName &&
          other.updatedAtUtcMs == this.updatedAtUtcMs);
}

class SignEntriesCompanion extends UpdateCompanion<SignEntryRow> {
  final Value<String> code;
  final Value<String> labelVi;
  final Value<String?> description;
  final Value<String?> mediaLocalPath;
  final Value<String> catalogVersion;
  final Value<String> sourceUrl;
  final Value<String> licenseName;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowid;
  const SignEntriesCompanion({
    this.code = const Value.absent(),
    this.labelVi = const Value.absent(),
    this.description = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.licenseName = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignEntriesCompanion.insert({
    required String code,
    required String labelVi,
    this.description = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    required String catalogVersion,
    required String sourceUrl,
    required String licenseName,
    required int updatedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       labelVi = Value(labelVi),
       catalogVersion = Value(catalogVersion),
       sourceUrl = Value(sourceUrl),
       licenseName = Value(licenseName),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<SignEntryRow> custom({
    Expression<String>? code,
    Expression<String>? labelVi,
    Expression<String>? description,
    Expression<String>? mediaLocalPath,
    Expression<String>? catalogVersion,
    Expression<String>? sourceUrl,
    Expression<String>? licenseName,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (labelVi != null) 'label_vi': labelVi,
      if (description != null) 'description': description,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (licenseName != null) 'license_name': licenseName,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignEntriesCompanion copyWith({
    Value<String>? code,
    Value<String>? labelVi,
    Value<String?>? description,
    Value<String?>? mediaLocalPath,
    Value<String>? catalogVersion,
    Value<String>? sourceUrl,
    Value<String>? licenseName,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowid,
  }) {
    return SignEntriesCompanion(
      code: code ?? this.code,
      labelVi: labelVi ?? this.labelVi,
      description: description ?? this.description,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      licenseName: licenseName ?? this.licenseName,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (labelVi.present) {
      map['label_vi'] = Variable<String>(labelVi.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<String>(catalogVersion.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (licenseName.present) {
      map['license_name'] = Variable<String>(licenseName.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignEntriesCompanion(')
          ..write('code: $code, ')
          ..write('labelVi: $labelVi, ')
          ..write('description: $description, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('licenseName: $licenseName, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecognitionHistoryRowsTable extends RecognitionHistoryRows
    with TableInfo<$RecognitionHistoryRowsTable, RecognitionHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecognitionHistoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signCodeMeta = const VerificationMeta(
    'signCode',
  );
  @override
  late final GeneratedColumn<String> signCode = GeneratedColumn<String>(
    'sign_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelSnapshotMeta = const VerificationMeta(
    'labelSnapshot',
  );
  @override
  late final GeneratedColumn<String> labelSnapshot = GeneratedColumn<String>(
    'label_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtUtcMsMeta = const VerificationMeta(
    'confirmedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> confirmedAtUtcMs = GeneratedColumn<int>(
    'confirmed_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageRelativePathMeta = const VerificationMeta(
    'imageRelativePath',
  );
  @override
  late final GeneratedColumn<String> imageRelativePath =
      GeneratedColumn<String>(
        'image_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signCode,
    labelSnapshot,
    confirmedAtUtcMs,
    deletedAtUtcMs,
    imageRelativePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recognition_history_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecognitionHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sign_code')) {
      context.handle(
        _signCodeMeta,
        signCode.isAcceptableOrUnknown(data['sign_code']!, _signCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_signCodeMeta);
    }
    if (data.containsKey('label_snapshot')) {
      context.handle(
        _labelSnapshotMeta,
        labelSnapshot.isAcceptableOrUnknown(
          data['label_snapshot']!,
          _labelSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_labelSnapshotMeta);
    }
    if (data.containsKey('confirmed_at_utc_ms')) {
      context.handle(
        _confirmedAtUtcMsMeta,
        confirmedAtUtcMs.isAcceptableOrUnknown(
          data['confirmed_at_utc_ms']!,
          _confirmedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confirmedAtUtcMsMeta);
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('image_relative_path')) {
      context.handle(
        _imageRelativePathMeta,
        imageRelativePath.isAcceptableOrUnknown(
          data['image_relative_path']!,
          _imageRelativePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecognitionHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecognitionHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      signCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sign_code'],
      )!,
      labelSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_snapshot'],
      )!,
      confirmedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at_utc_ms'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      imageRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_relative_path'],
      ),
    );
  }

  @override
  $RecognitionHistoryRowsTable createAlias(String alias) {
    return $RecognitionHistoryRowsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class RecognitionHistoryRow extends DataClass
    implements Insertable<RecognitionHistoryRow> {
  final String id;
  final String signCode;
  final String labelSnapshot;
  final int confirmedAtUtcMs;
  final int? deletedAtUtcMs;
  final String? imageRelativePath;
  const RecognitionHistoryRow({
    required this.id,
    required this.signCode,
    required this.labelSnapshot,
    required this.confirmedAtUtcMs,
    this.deletedAtUtcMs,
    this.imageRelativePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sign_code'] = Variable<String>(signCode);
    map['label_snapshot'] = Variable<String>(labelSnapshot);
    map['confirmed_at_utc_ms'] = Variable<int>(confirmedAtUtcMs);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    if (!nullToAbsent || imageRelativePath != null) {
      map['image_relative_path'] = Variable<String>(imageRelativePath);
    }
    return map;
  }

  RecognitionHistoryRowsCompanion toCompanion(bool nullToAbsent) {
    return RecognitionHistoryRowsCompanion(
      id: Value(id),
      signCode: Value(signCode),
      labelSnapshot: Value(labelSnapshot),
      confirmedAtUtcMs: Value(confirmedAtUtcMs),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      imageRelativePath: imageRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageRelativePath),
    );
  }

  factory RecognitionHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecognitionHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      signCode: serializer.fromJson<String>(json['signCode']),
      labelSnapshot: serializer.fromJson<String>(json['labelSnapshot']),
      confirmedAtUtcMs: serializer.fromJson<int>(json['confirmedAtUtcMs']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      imageRelativePath: serializer.fromJson<String?>(
        json['imageRelativePath'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'signCode': serializer.toJson<String>(signCode),
      'labelSnapshot': serializer.toJson<String>(labelSnapshot),
      'confirmedAtUtcMs': serializer.toJson<int>(confirmedAtUtcMs),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'imageRelativePath': serializer.toJson<String?>(imageRelativePath),
    };
  }

  RecognitionHistoryRow copyWith({
    String? id,
    String? signCode,
    String? labelSnapshot,
    int? confirmedAtUtcMs,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    Value<String?> imageRelativePath = const Value.absent(),
  }) => RecognitionHistoryRow(
    id: id ?? this.id,
    signCode: signCode ?? this.signCode,
    labelSnapshot: labelSnapshot ?? this.labelSnapshot,
    confirmedAtUtcMs: confirmedAtUtcMs ?? this.confirmedAtUtcMs,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    imageRelativePath: imageRelativePath.present
        ? imageRelativePath.value
        : this.imageRelativePath,
  );
  RecognitionHistoryRow copyWithCompanion(
    RecognitionHistoryRowsCompanion data,
  ) {
    return RecognitionHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      signCode: data.signCode.present ? data.signCode.value : this.signCode,
      labelSnapshot: data.labelSnapshot.present
          ? data.labelSnapshot.value
          : this.labelSnapshot,
      confirmedAtUtcMs: data.confirmedAtUtcMs.present
          ? data.confirmedAtUtcMs.value
          : this.confirmedAtUtcMs,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      imageRelativePath: data.imageRelativePath.present
          ? data.imageRelativePath.value
          : this.imageRelativePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecognitionHistoryRow(')
          ..write('id: $id, ')
          ..write('signCode: $signCode, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('confirmedAtUtcMs: $confirmedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('imageRelativePath: $imageRelativePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    signCode,
    labelSnapshot,
    confirmedAtUtcMs,
    deletedAtUtcMs,
    imageRelativePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecognitionHistoryRow &&
          other.id == this.id &&
          other.signCode == this.signCode &&
          other.labelSnapshot == this.labelSnapshot &&
          other.confirmedAtUtcMs == this.confirmedAtUtcMs &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.imageRelativePath == this.imageRelativePath);
}

class RecognitionHistoryRowsCompanion
    extends UpdateCompanion<RecognitionHistoryRow> {
  final Value<String> id;
  final Value<String> signCode;
  final Value<String> labelSnapshot;
  final Value<int> confirmedAtUtcMs;
  final Value<int?> deletedAtUtcMs;
  final Value<String?> imageRelativePath;
  final Value<int> rowid;
  const RecognitionHistoryRowsCompanion({
    this.id = const Value.absent(),
    this.signCode = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.confirmedAtUtcMs = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.imageRelativePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecognitionHistoryRowsCompanion.insert({
    required String id,
    required String signCode,
    required String labelSnapshot,
    required int confirmedAtUtcMs,
    this.deletedAtUtcMs = const Value.absent(),
    this.imageRelativePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       signCode = Value(signCode),
       labelSnapshot = Value(labelSnapshot),
       confirmedAtUtcMs = Value(confirmedAtUtcMs);
  static Insertable<RecognitionHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? signCode,
    Expression<String>? labelSnapshot,
    Expression<int>? confirmedAtUtcMs,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? imageRelativePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signCode != null) 'sign_code': signCode,
      if (labelSnapshot != null) 'label_snapshot': labelSnapshot,
      if (confirmedAtUtcMs != null) 'confirmed_at_utc_ms': confirmedAtUtcMs,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (imageRelativePath != null) 'image_relative_path': imageRelativePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecognitionHistoryRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? signCode,
    Value<String>? labelSnapshot,
    Value<int>? confirmedAtUtcMs,
    Value<int?>? deletedAtUtcMs,
    Value<String?>? imageRelativePath,
    Value<int>? rowid,
  }) {
    return RecognitionHistoryRowsCompanion(
      id: id ?? this.id,
      signCode: signCode ?? this.signCode,
      labelSnapshot: labelSnapshot ?? this.labelSnapshot,
      confirmedAtUtcMs: confirmedAtUtcMs ?? this.confirmedAtUtcMs,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      imageRelativePath: imageRelativePath ?? this.imageRelativePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (signCode.present) {
      map['sign_code'] = Variable<String>(signCode.value);
    }
    if (labelSnapshot.present) {
      map['label_snapshot'] = Variable<String>(labelSnapshot.value);
    }
    if (confirmedAtUtcMs.present) {
      map['confirmed_at_utc_ms'] = Variable<int>(confirmedAtUtcMs.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (imageRelativePath.present) {
      map['image_relative_path'] = Variable<String>(imageRelativePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecognitionHistoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('signCode: $signCode, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('confirmedAtUtcMs: $confirmedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('imageRelativePath: $imageRelativePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOpsTable extends PendingSyncOps
    with TableInfo<$PendingSyncOpsTable, PendingSyncOpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    entity,
    entityId,
    operation,
    payloadJson,
    createdAtUtcMs,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncOpRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  PendingSyncOpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOpRow(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingSyncOpsTable createAlias(String alias) {
    return $PendingSyncOpsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class PendingSyncOpRow extends DataClass
    implements Insertable<PendingSyncOpRow> {
  final String opId;
  final String entity;
  final String entityId;
  final String operation;
  final String payloadJson;
  final int createdAtUtcMs;
  final int retryCount;
  final String? lastError;
  const PendingSyncOpRow({
    required this.opId,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAtUtcMs,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingSyncOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOpsCompanion(
      opId: Value(opId),
      entity: Value(entity),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAtUtcMs: Value(createdAtUtcMs),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingSyncOpRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOpRow(
      opId: serializer.fromJson<String>(json['opId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingSyncOpRow copyWith({
    String? opId,
    String? entity,
    String? entityId,
    String? operation,
    String? payloadJson,
    int? createdAtUtcMs,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => PendingSyncOpRow(
    opId: opId ?? this.opId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingSyncOpRow copyWithCompanion(PendingSyncOpsCompanion data) {
    return PendingSyncOpRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOpRow(')
          ..write('opId: $opId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    entity,
    entityId,
    operation,
    payloadJson,
    createdAtUtcMs,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOpRow &&
          other.opId == this.opId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class PendingSyncOpsCompanion extends UpdateCompanion<PendingSyncOpRow> {
  final Value<String> opId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<int> createdAtUtcMs;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const PendingSyncOpsCompanion({
    this.opId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSyncOpsCompanion.insert({
    required String opId,
    required String entity,
    required String entityId,
    required String operation,
    required String payloadJson,
    required int createdAtUtcMs,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       entity = Value(entity),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAtUtcMs = Value(createdAtUtcMs);
  static Insertable<PendingSyncOpRow> custom({
    Expression<String>? opId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<int>? createdAtUtcMs,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSyncOpsCompanion copyWith({
    Value<String>? opId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<int>? createdAtUtcMs,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return PendingSyncOpsCompanion(
      opId: opId ?? this.opId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOpsCompanion(')
          ..write('opId: $opId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCursorMeta = const VerificationMeta(
    'lastCursor',
  );
  @override
  late final GeneratedColumn<String> lastCursor = GeneratedColumn<String>(
    'last_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessAtUtcMsMeta =
      const VerificationMeta('lastSuccessAtUtcMs');
  @override
  late final GeneratedColumn<int> lastSuccessAtUtcMs = GeneratedColumn<int>(
    'last_success_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    collection,
    lastCursor,
    lastSuccessAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('last_cursor')) {
      context.handle(
        _lastCursorMeta,
        lastCursor.isAcceptableOrUnknown(data['last_cursor']!, _lastCursorMeta),
      );
    }
    if (data.containsKey('last_success_at_utc_ms')) {
      context.handle(
        _lastSuccessAtUtcMsMeta,
        lastSuccessAtUtcMs.isAcceptableOrUnknown(
          data['last_success_at_utc_ms']!,
          _lastSuccessAtUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collection};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      lastCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_cursor'],
      ),
      lastSuccessAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_success_at_utc_ms'],
      ),
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String collection;
  final String? lastCursor;
  final int? lastSuccessAtUtcMs;
  const SyncStateRow({
    required this.collection,
    this.lastCursor,
    this.lastSuccessAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection'] = Variable<String>(collection);
    if (!nullToAbsent || lastCursor != null) {
      map['last_cursor'] = Variable<String>(lastCursor);
    }
    if (!nullToAbsent || lastSuccessAtUtcMs != null) {
      map['last_success_at_utc_ms'] = Variable<int>(lastSuccessAtUtcMs);
    }
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      collection: Value(collection),
      lastCursor: lastCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCursor),
      lastSuccessAtUtcMs: lastSuccessAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAtUtcMs),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      collection: serializer.fromJson<String>(json['collection']),
      lastCursor: serializer.fromJson<String?>(json['lastCursor']),
      lastSuccessAtUtcMs: serializer.fromJson<int?>(json['lastSuccessAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collection': serializer.toJson<String>(collection),
      'lastCursor': serializer.toJson<String?>(lastCursor),
      'lastSuccessAtUtcMs': serializer.toJson<int?>(lastSuccessAtUtcMs),
    };
  }

  SyncStateRow copyWith({
    String? collection,
    Value<String?> lastCursor = const Value.absent(),
    Value<int?> lastSuccessAtUtcMs = const Value.absent(),
  }) => SyncStateRow(
    collection: collection ?? this.collection,
    lastCursor: lastCursor.present ? lastCursor.value : this.lastCursor,
    lastSuccessAtUtcMs: lastSuccessAtUtcMs.present
        ? lastSuccessAtUtcMs.value
        : this.lastSuccessAtUtcMs,
  );
  SyncStateRow copyWithCompanion(SyncStatesCompanion data) {
    return SyncStateRow(
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      lastCursor: data.lastCursor.present
          ? data.lastCursor.value
          : this.lastCursor,
      lastSuccessAtUtcMs: data.lastSuccessAtUtcMs.present
          ? data.lastSuccessAtUtcMs.value
          : this.lastSuccessAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('collection: $collection, ')
          ..write('lastCursor: $lastCursor, ')
          ..write('lastSuccessAtUtcMs: $lastSuccessAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collection, lastCursor, lastSuccessAtUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.collection == this.collection &&
          other.lastCursor == this.lastCursor &&
          other.lastSuccessAtUtcMs == this.lastSuccessAtUtcMs);
}

class SyncStatesCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> collection;
  final Value<String?> lastCursor;
  final Value<int?> lastSuccessAtUtcMs;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.collection = const Value.absent(),
    this.lastCursor = const Value.absent(),
    this.lastSuccessAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String collection,
    this.lastCursor = const Value.absent(),
    this.lastSuccessAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collection = Value(collection);
  static Insertable<SyncStateRow> custom({
    Expression<String>? collection,
    Expression<String>? lastCursor,
    Expression<int>? lastSuccessAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collection != null) 'collection': collection,
      if (lastCursor != null) 'last_cursor': lastCursor,
      if (lastSuccessAtUtcMs != null)
        'last_success_at_utc_ms': lastSuccessAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? collection,
    Value<String?>? lastCursor,
    Value<int?>? lastSuccessAtUtcMs,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      collection: collection ?? this.collection,
      lastCursor: lastCursor ?? this.lastCursor,
      lastSuccessAtUtcMs: lastSuccessAtUtcMs ?? this.lastSuccessAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (lastCursor.present) {
      map['last_cursor'] = Variable<String>(lastCursor.value);
    }
    if (lastSuccessAtUtcMs.present) {
      map['last_success_at_utc_ms'] = Variable<int>(lastSuccessAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('collection: $collection, ')
          ..write('lastCursor: $lastCursor, ')
          ..write('lastSuccessAtUtcMs: $lastSuccessAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson, updatedAtUtcMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String valueJson;
  final int updatedAtUtcMs;
  const AppSettingRow({
    required this.key,
    required this.valueJson,
    required this.updatedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
    };
  }

  AppSettingRow copyWith({
    String? key,
    String? valueJson,
    int? updatedAtUtcMs,
  }) => AppSettingRow(
    key: key ?? this.key,
    valueJson: valueJson ?? this.valueJson,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
  );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAtUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAtUtcMs == this.updatedAtUtcMs);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueJson,
    required int updatedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SignEntriesTable signEntries = $SignEntriesTable(this);
  late final $RecognitionHistoryRowsTable recognitionHistoryRows =
      $RecognitionHistoryRowsTable(this);
  late final $PendingSyncOpsTable pendingSyncOps = $PendingSyncOpsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signEntries,
    recognitionHistoryRows,
    pendingSyncOps,
    syncStates,
    appSettings,
  ];
}

typedef $$SignEntriesTableCreateCompanionBuilder =
    SignEntriesCompanion Function({
      required String code,
      required String labelVi,
      Value<String?> description,
      Value<String?> mediaLocalPath,
      required String catalogVersion,
      required String sourceUrl,
      required String licenseName,
      required int updatedAtUtcMs,
      Value<int> rowid,
    });
typedef $$SignEntriesTableUpdateCompanionBuilder =
    SignEntriesCompanion Function({
      Value<String> code,
      Value<String> labelVi,
      Value<String?> description,
      Value<String?> mediaLocalPath,
      Value<String> catalogVersion,
      Value<String> sourceUrl,
      Value<String> licenseName,
      Value<int> updatedAtUtcMs,
      Value<int> rowid,
    });

class $$SignEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SignEntriesTable> {
  $$SignEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelVi => $composableBuilder(
    column: $table.labelVi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licenseName => $composableBuilder(
    column: $table.licenseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SignEntriesTable> {
  $$SignEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelVi => $composableBuilder(
    column: $table.labelVi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licenseName => $composableBuilder(
    column: $table.licenseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignEntriesTable> {
  $$SignEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get labelVi =>
      $composableBuilder(column: $table.labelVi, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get licenseName => $composableBuilder(
    column: $table.licenseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );
}

class $$SignEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignEntriesTable,
          SignEntryRow,
          $$SignEntriesTableFilterComposer,
          $$SignEntriesTableOrderingComposer,
          $$SignEntriesTableAnnotationComposer,
          $$SignEntriesTableCreateCompanionBuilder,
          $$SignEntriesTableUpdateCompanionBuilder,
          (
            SignEntryRow,
            BaseReferences<_$AppDatabase, $SignEntriesTable, SignEntryRow>,
          ),
          SignEntryRow,
          PrefetchHooks Function()
        > {
  $$SignEntriesTableTableManager(_$AppDatabase db, $SignEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> labelVi = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String> catalogVersion = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> licenseName = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignEntriesCompanion(
                code: code,
                labelVi: labelVi,
                description: description,
                mediaLocalPath: mediaLocalPath,
                catalogVersion: catalogVersion,
                sourceUrl: sourceUrl,
                licenseName: licenseName,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String labelVi,
                Value<String?> description = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                required String catalogVersion,
                required String sourceUrl,
                required String licenseName,
                required int updatedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => SignEntriesCompanion.insert(
                code: code,
                labelVi: labelVi,
                description: description,
                mediaLocalPath: mediaLocalPath,
                catalogVersion: catalogVersion,
                sourceUrl: sourceUrl,
                licenseName: licenseName,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SignEntriesTable, SignEntryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SignEntriesTable,
                    SignEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignEntriesTable,
      SignEntryRow,
      $$SignEntriesTableFilterComposer,
      $$SignEntriesTableOrderingComposer,
      $$SignEntriesTableAnnotationComposer,
      $$SignEntriesTableCreateCompanionBuilder,
      $$SignEntriesTableUpdateCompanionBuilder,
      (
        SignEntryRow,
        BaseReferences<_$AppDatabase, $SignEntriesTable, SignEntryRow>,
      ),
      SignEntryRow,
      PrefetchHooks Function()
    >;
typedef $$RecognitionHistoryRowsTableCreateCompanionBuilder =
    RecognitionHistoryRowsCompanion Function({
      required String id,
      required String signCode,
      required String labelSnapshot,
      required int confirmedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      Value<String?> imageRelativePath,
      Value<int> rowid,
    });
typedef $$RecognitionHistoryRowsTableUpdateCompanionBuilder =
    RecognitionHistoryRowsCompanion Function({
      Value<String> id,
      Value<String> signCode,
      Value<String> labelSnapshot,
      Value<int> confirmedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      Value<String?> imageRelativePath,
      Value<int> rowid,
    });

class $$RecognitionHistoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RecognitionHistoryRowsTable> {
  $$RecognitionHistoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signCode => $composableBuilder(
    column: $table.signCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAtUtcMs => $composableBuilder(
    column: $table.confirmedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecognitionHistoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecognitionHistoryRowsTable> {
  $$RecognitionHistoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signCode => $composableBuilder(
    column: $table.signCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAtUtcMs => $composableBuilder(
    column: $table.confirmedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecognitionHistoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecognitionHistoryRowsTable> {
  $$RecognitionHistoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get signCode =>
      $composableBuilder(column: $table.signCode, builder: (column) => column);

  GeneratedColumn<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get confirmedAtUtcMs => $composableBuilder(
    column: $table.confirmedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => column,
  );
}

class $$RecognitionHistoryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecognitionHistoryRowsTable,
          RecognitionHistoryRow,
          $$RecognitionHistoryRowsTableFilterComposer,
          $$RecognitionHistoryRowsTableOrderingComposer,
          $$RecognitionHistoryRowsTableAnnotationComposer,
          $$RecognitionHistoryRowsTableCreateCompanionBuilder,
          $$RecognitionHistoryRowsTableUpdateCompanionBuilder,
          (
            RecognitionHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $RecognitionHistoryRowsTable,
              RecognitionHistoryRow
            >,
          ),
          RecognitionHistoryRow,
          PrefetchHooks Function()
        > {
  $$RecognitionHistoryRowsTableTableManager(
    _$AppDatabase db,
    $RecognitionHistoryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecognitionHistoryRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecognitionHistoryRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecognitionHistoryRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> signCode = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<int> confirmedAtUtcMs = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String?> imageRelativePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecognitionHistoryRowsCompanion(
                id: id,
                signCode: signCode,
                labelSnapshot: labelSnapshot,
                confirmedAtUtcMs: confirmedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                imageRelativePath: imageRelativePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String signCode,
                required String labelSnapshot,
                required int confirmedAtUtcMs,
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String?> imageRelativePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecognitionHistoryRowsCompanion.insert(
                id: id,
                signCode: signCode,
                labelSnapshot: labelSnapshot,
                confirmedAtUtcMs: confirmedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                imageRelativePath: imageRelativePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RecognitionHistoryRowsTable,
                    RecognitionHistoryRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecognitionHistoryRowsTable,
                    RecognitionHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecognitionHistoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecognitionHistoryRowsTable,
      RecognitionHistoryRow,
      $$RecognitionHistoryRowsTableFilterComposer,
      $$RecognitionHistoryRowsTableOrderingComposer,
      $$RecognitionHistoryRowsTableAnnotationComposer,
      $$RecognitionHistoryRowsTableCreateCompanionBuilder,
      $$RecognitionHistoryRowsTableUpdateCompanionBuilder,
      (
        RecognitionHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $RecognitionHistoryRowsTable,
          RecognitionHistoryRow
        >,
      ),
      RecognitionHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncOpsTableCreateCompanionBuilder =
    PendingSyncOpsCompanion Function({
      required String opId,
      required String entity,
      required String entityId,
      required String operation,
      required String payloadJson,
      required int createdAtUtcMs,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$PendingSyncOpsTableUpdateCompanionBuilder =
    PendingSyncOpsCompanion Function({
      Value<String> opId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<int> createdAtUtcMs,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$PendingSyncOpsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingSyncOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSyncOpsTable,
          PendingSyncOpRow,
          $$PendingSyncOpsTableFilterComposer,
          $$PendingSyncOpsTableOrderingComposer,
          $$PendingSyncOpsTableAnnotationComposer,
          $$PendingSyncOpsTableCreateCompanionBuilder,
          $$PendingSyncOpsTableUpdateCompanionBuilder,
          (
            PendingSyncOpRow,
            BaseReferences<
              _$AppDatabase,
              $PendingSyncOpsTable,
              PendingSyncOpRow
            >,
          ),
          PendingSyncOpRow,
          PrefetchHooks Function()
        > {
  $$PendingSyncOpsTableTableManager(
    _$AppDatabase db,
    $PendingSyncOpsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSyncOpsCompanion(
                opId: opId,
                entity: entity,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String entity,
                required String entityId,
                required String operation,
                required String payloadJson,
                required int createdAtUtcMs,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSyncOpsCompanion.insert(
                opId: opId,
                entity: entity,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingSyncOpsTable, PendingSyncOpRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingSyncOpsTable,
                    PendingSyncOpRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSyncOpsTable,
      PendingSyncOpRow,
      $$PendingSyncOpsTableFilterComposer,
      $$PendingSyncOpsTableOrderingComposer,
      $$PendingSyncOpsTableAnnotationComposer,
      $$PendingSyncOpsTableCreateCompanionBuilder,
      $$PendingSyncOpsTableUpdateCompanionBuilder,
      (
        PendingSyncOpRow,
        BaseReferences<_$AppDatabase, $PendingSyncOpsTable, PendingSyncOpRow>,
      ),
      PendingSyncOpRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  required String collection,
  Value<String?> lastCursor,
  Value<int?> lastSuccessAtUtcMs,
  Value<int> rowid,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<String> collection,
  Value<String?> lastCursor,
  Value<int?> lastSuccessAtUtcMs,
  Value<int> rowid,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCursor => $composableBuilder(
    column: $table.lastCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSuccessAtUtcMs => $composableBuilder(
    column: $table.lastSuccessAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCursor => $composableBuilder(
    column: $table.lastCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSuccessAtUtcMs => $composableBuilder(
    column: $table.lastSuccessAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCursor => $composableBuilder(
    column: $table.lastCursor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSuccessAtUtcMs => $composableBuilder(
    column: $table.lastSuccessAtUtcMs,
    builder: (column) => column,
  );
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncStateRow,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collection = const Value.absent(),
                Value<String?> lastCursor = const Value.absent(),
                Value<int?> lastSuccessAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                collection: collection,
                lastCursor: lastCursor,
                lastSuccessAtUtcMs: lastSuccessAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collection,
                Value<String?> lastCursor = const Value.absent(),
                Value<int?> lastSuccessAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                collection: collection,
                lastCursor: lastCursor,
                lastSuccessAtUtcMs: lastSuccessAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStatesTable, SyncStateRow>(table),
                  BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncStateRow,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueJson,
      required int updatedAtUtcMs,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> updatedAtUtcMs,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueJson: valueJson,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                required int updatedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SignEntriesTableTableManager get signEntries =>
      $$SignEntriesTableTableManager(_db, _db.signEntries);
  $$RecognitionHistoryRowsTableTableManager get recognitionHistoryRows =>
      $$RecognitionHistoryRowsTableTableManager(
        _db,
        _db.recognitionHistoryRows,
      );
  $$PendingSyncOpsTableTableManager get pendingSyncOps =>
      $$PendingSyncOpsTableTableManager(_db, _db.pendingSyncOps);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
