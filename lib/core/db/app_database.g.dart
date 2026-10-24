// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaIndexTable extends MediaIndex
    with TableInfo<$MediaIndexTable, MediaIndexRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameLowerMeta = const VerificationMeta(
    'nameLower',
  );
  @override
  late final GeneratedColumn<String> nameLower = GeneratedColumn<String>(
    'name_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FileKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<FileKind>($MediaIndexTable.$converterkind);
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMsMeta = const VerificationMeta(
    'modifiedAtMs',
  );
  @override
  late final GeneratedColumn<int> modifiedAtMs = GeneratedColumn<int>(
    'modified_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMsMeta = const VerificationMeta(
    'takenAtMs',
  );
  @override
  late final GeneratedColumn<int> takenAtMs = GeneratedColumn<int>(
    'taken_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortDateMsMeta = const VerificationMeta(
    'sortDateMs',
  );
  @override
  late final GeneratedColumn<int> sortDateMs = GeneratedColumn<int>(
    'sort_date_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FileOrigin, int> origin =
      GeneratedColumn<int>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<FileOrigin>($MediaIndexTable.$converterorigin);
  static const VerificationMeta _indexedAtMsMeta = const VerificationMeta(
    'indexedAtMs',
  );
  @override
  late final GeneratedColumn<int> indexedAtMs = GeneratedColumn<int>(
    'indexed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanGenerationMeta = const VerificationMeta(
    'scanGeneration',
  );
  @override
  late final GeneratedColumn<int> scanGeneration = GeneratedColumn<int>(
    'scan_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotMeta = const VerificationMeta(
    'screenshot',
  );
  @override
  late final GeneratedColumn<bool> screenshot = GeneratedColumn<bool>(
    'screenshot',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("screenshot" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uri,
    name,
    nameLower,
    mimeType,
    kind,
    sizeBytes,
    modifiedAtMs,
    takenAtMs,
    sortDateMs,
    width,
    height,
    durationMs,
    folderPath,
    origin,
    indexedAtMs,
    scanGeneration,
    screenshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaIndexRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_lower')) {
      context.handle(
        _nameLowerMeta,
        nameLower.isAcceptableOrUnknown(data['name_lower']!, _nameLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_nameLowerMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('modified_at_ms')) {
      context.handle(
        _modifiedAtMsMeta,
        modifiedAtMs.isAcceptableOrUnknown(
          data['modified_at_ms']!,
          _modifiedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMsMeta);
    }
    if (data.containsKey('taken_at_ms')) {
      context.handle(
        _takenAtMsMeta,
        takenAtMs.isAcceptableOrUnknown(data['taken_at_ms']!, _takenAtMsMeta),
      );
    }
    if (data.containsKey('sort_date_ms')) {
      context.handle(
        _sortDateMsMeta,
        sortDateMs.isAcceptableOrUnknown(
          data['sort_date_ms']!,
          _sortDateMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sortDateMsMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('indexed_at_ms')) {
      context.handle(
        _indexedAtMsMeta,
        indexedAtMs.isAcceptableOrUnknown(
          data['indexed_at_ms']!,
          _indexedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMsMeta);
    }
    if (data.containsKey('scan_generation')) {
      context.handle(
        _scanGenerationMeta,
        scanGeneration.isAcceptableOrUnknown(
          data['scan_generation']!,
          _scanGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanGenerationMeta);
    }
    if (data.containsKey('screenshot')) {
      context.handle(
        _screenshotMeta,
        screenshot.isAcceptableOrUnknown(data['screenshot']!, _screenshotMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaIndexRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaIndexRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_lower'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      kind: $MediaIndexTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      modifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at_ms'],
      )!,
      takenAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taken_at_ms'],
      ),
      sortDateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_date_ms'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      origin: $MediaIndexTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}origin'],
        )!,
      ),
      indexedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at_ms'],
      )!,
      scanGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_generation'],
      )!,
      screenshot: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}screenshot'],
      )!,
    );
  }

  @override
  $MediaIndexTable createAlias(String alias) {
    return $MediaIndexTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FileKind, int, int> $converterkind =
      const EnumIndexConverter<FileKind>(FileKind.values);
  static JsonTypeConverter2<FileOrigin, int, int> $converterorigin =
      const EnumIndexConverter<FileOrigin>(FileOrigin.values);
}

class MediaIndexRow extends DataClass implements Insertable<MediaIndexRow> {
  /// FileRef.id.
  final String id;
  final String uri;
  final String name;

  /// For case-insensitive search and name sort (B8).
  final String nameLower;
  final String? mimeType;
  final FileKind kind;
  final int sizeBytes;
  final int modifiedAtMs;

  /// Null when unknown, never 0.
  final int? takenAtMs;

  /// takenAt ?? modifiedAt, denormalized for indexed sorting.
  final int sortDateMs;
  final int? width;
  final int? height;
  final int? durationMs;
  final String folderPath;
  final FileOrigin origin;
  final int indexedAtMs;

  /// Scan generation that last saw this row. After a full scan, rows of the
  /// scanned kinds with an older generation are gone from the device.
  final int scanGeneration;

  /// P5: see `isScreenshot` (set by the DAO on every write).
  final bool screenshot;
  const MediaIndexRow({
    required this.id,
    required this.uri,
    required this.name,
    required this.nameLower,
    this.mimeType,
    required this.kind,
    required this.sizeBytes,
    required this.modifiedAtMs,
    this.takenAtMs,
    required this.sortDateMs,
    this.width,
    this.height,
    this.durationMs,
    required this.folderPath,
    required this.origin,
    required this.indexedAtMs,
    required this.scanGeneration,
    required this.screenshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['uri'] = Variable<String>(uri);
    map['name'] = Variable<String>(name);
    map['name_lower'] = Variable<String>(nameLower);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    {
      map['kind'] = Variable<int>($MediaIndexTable.$converterkind.toSql(kind));
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['modified_at_ms'] = Variable<int>(modifiedAtMs);
    if (!nullToAbsent || takenAtMs != null) {
      map['taken_at_ms'] = Variable<int>(takenAtMs);
    }
    map['sort_date_ms'] = Variable<int>(sortDateMs);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['folder_path'] = Variable<String>(folderPath);
    {
      map['origin'] = Variable<int>(
        $MediaIndexTable.$converterorigin.toSql(origin),
      );
    }
    map['indexed_at_ms'] = Variable<int>(indexedAtMs);
    map['scan_generation'] = Variable<int>(scanGeneration);
    map['screenshot'] = Variable<bool>(screenshot);
    return map;
  }

  MediaIndexCompanion toCompanion(bool nullToAbsent) {
    return MediaIndexCompanion(
      id: Value(id),
      uri: Value(uri),
      name: Value(name),
      nameLower: Value(nameLower),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      kind: Value(kind),
      sizeBytes: Value(sizeBytes),
      modifiedAtMs: Value(modifiedAtMs),
      takenAtMs: takenAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAtMs),
      sortDateMs: Value(sortDateMs),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      folderPath: Value(folderPath),
      origin: Value(origin),
      indexedAtMs: Value(indexedAtMs),
      scanGeneration: Value(scanGeneration),
      screenshot: Value(screenshot),
    );
  }

  factory MediaIndexRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaIndexRow(
      id: serializer.fromJson<String>(json['id']),
      uri: serializer.fromJson<String>(json['uri']),
      name: serializer.fromJson<String>(json['name']),
      nameLower: serializer.fromJson<String>(json['nameLower']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      kind: $MediaIndexTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      modifiedAtMs: serializer.fromJson<int>(json['modifiedAtMs']),
      takenAtMs: serializer.fromJson<int?>(json['takenAtMs']),
      sortDateMs: serializer.fromJson<int>(json['sortDateMs']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      origin: $MediaIndexTable.$converterorigin.fromJson(
        serializer.fromJson<int>(json['origin']),
      ),
      indexedAtMs: serializer.fromJson<int>(json['indexedAtMs']),
      scanGeneration: serializer.fromJson<int>(json['scanGeneration']),
      screenshot: serializer.fromJson<bool>(json['screenshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'uri': serializer.toJson<String>(uri),
      'name': serializer.toJson<String>(name),
      'nameLower': serializer.toJson<String>(nameLower),
      'mimeType': serializer.toJson<String?>(mimeType),
      'kind': serializer.toJson<int>(
        $MediaIndexTable.$converterkind.toJson(kind),
      ),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'modifiedAtMs': serializer.toJson<int>(modifiedAtMs),
      'takenAtMs': serializer.toJson<int?>(takenAtMs),
      'sortDateMs': serializer.toJson<int>(sortDateMs),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMs': serializer.toJson<int?>(durationMs),
      'folderPath': serializer.toJson<String>(folderPath),
      'origin': serializer.toJson<int>(
        $MediaIndexTable.$converterorigin.toJson(origin),
      ),
      'indexedAtMs': serializer.toJson<int>(indexedAtMs),
      'scanGeneration': serializer.toJson<int>(scanGeneration),
      'screenshot': serializer.toJson<bool>(screenshot),
    };
  }

  MediaIndexRow copyWith({
    String? id,
    String? uri,
    String? name,
    String? nameLower,
    Value<String?> mimeType = const Value.absent(),
    FileKind? kind,
    int? sizeBytes,
    int? modifiedAtMs,
    Value<int?> takenAtMs = const Value.absent(),
    int? sortDateMs,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    String? folderPath,
    FileOrigin? origin,
    int? indexedAtMs,
    int? scanGeneration,
    bool? screenshot,
  }) => MediaIndexRow(
    id: id ?? this.id,
    uri: uri ?? this.uri,
    name: name ?? this.name,
    nameLower: nameLower ?? this.nameLower,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    kind: kind ?? this.kind,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    modifiedAtMs: modifiedAtMs ?? this.modifiedAtMs,
    takenAtMs: takenAtMs.present ? takenAtMs.value : this.takenAtMs,
    sortDateMs: sortDateMs ?? this.sortDateMs,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    folderPath: folderPath ?? this.folderPath,
    origin: origin ?? this.origin,
    indexedAtMs: indexedAtMs ?? this.indexedAtMs,
    scanGeneration: scanGeneration ?? this.scanGeneration,
    screenshot: screenshot ?? this.screenshot,
  );
  MediaIndexRow copyWithCompanion(MediaIndexCompanion data) {
    return MediaIndexRow(
      id: data.id.present ? data.id.value : this.id,
      uri: data.uri.present ? data.uri.value : this.uri,
      name: data.name.present ? data.name.value : this.name,
      nameLower: data.nameLower.present ? data.nameLower.value : this.nameLower,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      kind: data.kind.present ? data.kind.value : this.kind,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      modifiedAtMs: data.modifiedAtMs.present
          ? data.modifiedAtMs.value
          : this.modifiedAtMs,
      takenAtMs: data.takenAtMs.present ? data.takenAtMs.value : this.takenAtMs,
      sortDateMs: data.sortDateMs.present
          ? data.sortDateMs.value
          : this.sortDateMs,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      origin: data.origin.present ? data.origin.value : this.origin,
      indexedAtMs: data.indexedAtMs.present
          ? data.indexedAtMs.value
          : this.indexedAtMs,
      scanGeneration: data.scanGeneration.present
          ? data.scanGeneration.value
          : this.scanGeneration,
      screenshot: data.screenshot.present
          ? data.screenshot.value
          : this.screenshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaIndexRow(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write('mimeType: $mimeType, ')
          ..write('kind: $kind, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('takenAtMs: $takenAtMs, ')
          ..write('sortDateMs: $sortDateMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('folderPath: $folderPath, ')
          ..write('origin: $origin, ')
          ..write('indexedAtMs: $indexedAtMs, ')
          ..write('scanGeneration: $scanGeneration, ')
          ..write('screenshot: $screenshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uri,
    name,
    nameLower,
    mimeType,
    kind,
    sizeBytes,
    modifiedAtMs,
    takenAtMs,
    sortDateMs,
    width,
    height,
    durationMs,
    folderPath,
    origin,
    indexedAtMs,
    scanGeneration,
    screenshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaIndexRow &&
          other.id == this.id &&
          other.uri == this.uri &&
          other.name == this.name &&
          other.nameLower == this.nameLower &&
          other.mimeType == this.mimeType &&
          other.kind == this.kind &&
          other.sizeBytes == this.sizeBytes &&
          other.modifiedAtMs == this.modifiedAtMs &&
          other.takenAtMs == this.takenAtMs &&
          other.sortDateMs == this.sortDateMs &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMs == this.durationMs &&
          other.folderPath == this.folderPath &&
          other.origin == this.origin &&
          other.indexedAtMs == this.indexedAtMs &&
          other.scanGeneration == this.scanGeneration &&
          other.screenshot == this.screenshot);
}

class MediaIndexCompanion extends UpdateCompanion<MediaIndexRow> {
  final Value<String> id;
  final Value<String> uri;
  final Value<String> name;
  final Value<String> nameLower;
  final Value<String?> mimeType;
  final Value<FileKind> kind;
  final Value<int> sizeBytes;
  final Value<int> modifiedAtMs;
  final Value<int?> takenAtMs;
  final Value<int> sortDateMs;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMs;
  final Value<String> folderPath;
  final Value<FileOrigin> origin;
  final Value<int> indexedAtMs;
  final Value<int> scanGeneration;
  final Value<bool> screenshot;
  final Value<int> rowid;
  const MediaIndexCompanion({
    this.id = const Value.absent(),
    this.uri = const Value.absent(),
    this.name = const Value.absent(),
    this.nameLower = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.kind = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.modifiedAtMs = const Value.absent(),
    this.takenAtMs = const Value.absent(),
    this.sortDateMs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.origin = const Value.absent(),
    this.indexedAtMs = const Value.absent(),
    this.scanGeneration = const Value.absent(),
    this.screenshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaIndexCompanion.insert({
    required String id,
    required String uri,
    required String name,
    required String nameLower,
    this.mimeType = const Value.absent(),
    required FileKind kind,
    required int sizeBytes,
    required int modifiedAtMs,
    this.takenAtMs = const Value.absent(),
    required int sortDateMs,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    required String folderPath,
    required FileOrigin origin,
    required int indexedAtMs,
    required int scanGeneration,
    this.screenshot = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       uri = Value(uri),
       name = Value(name),
       nameLower = Value(nameLower),
       kind = Value(kind),
       sizeBytes = Value(sizeBytes),
       modifiedAtMs = Value(modifiedAtMs),
       sortDateMs = Value(sortDateMs),
       folderPath = Value(folderPath),
       origin = Value(origin),
       indexedAtMs = Value(indexedAtMs),
       scanGeneration = Value(scanGeneration);
  static Insertable<MediaIndexRow> custom({
    Expression<String>? id,
    Expression<String>? uri,
    Expression<String>? name,
    Expression<String>? nameLower,
    Expression<String>? mimeType,
    Expression<int>? kind,
    Expression<int>? sizeBytes,
    Expression<int>? modifiedAtMs,
    Expression<int>? takenAtMs,
    Expression<int>? sortDateMs,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMs,
    Expression<String>? folderPath,
    Expression<int>? origin,
    Expression<int>? indexedAtMs,
    Expression<int>? scanGeneration,
    Expression<bool>? screenshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uri != null) 'uri': uri,
      if (name != null) 'name': name,
      if (nameLower != null) 'name_lower': nameLower,
      if (mimeType != null) 'mime_type': mimeType,
      if (kind != null) 'kind': kind,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (modifiedAtMs != null) 'modified_at_ms': modifiedAtMs,
      if (takenAtMs != null) 'taken_at_ms': takenAtMs,
      if (sortDateMs != null) 'sort_date_ms': sortDateMs,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'duration_ms': durationMs,
      if (folderPath != null) 'folder_path': folderPath,
      if (origin != null) 'origin': origin,
      if (indexedAtMs != null) 'indexed_at_ms': indexedAtMs,
      if (scanGeneration != null) 'scan_generation': scanGeneration,
      if (screenshot != null) 'screenshot': screenshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaIndexCompanion copyWith({
    Value<String>? id,
    Value<String>? uri,
    Value<String>? name,
    Value<String>? nameLower,
    Value<String?>? mimeType,
    Value<FileKind>? kind,
    Value<int>? sizeBytes,
    Value<int>? modifiedAtMs,
    Value<int?>? takenAtMs,
    Value<int>? sortDateMs,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? durationMs,
    Value<String>? folderPath,
    Value<FileOrigin>? origin,
    Value<int>? indexedAtMs,
    Value<int>? scanGeneration,
    Value<bool>? screenshot,
    Value<int>? rowid,
  }) {
    return MediaIndexCompanion(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      name: name ?? this.name,
      nameLower: nameLower ?? this.nameLower,
      mimeType: mimeType ?? this.mimeType,
      kind: kind ?? this.kind,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAtMs: modifiedAtMs ?? this.modifiedAtMs,
      takenAtMs: takenAtMs ?? this.takenAtMs,
      sortDateMs: sortDateMs ?? this.sortDateMs,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      folderPath: folderPath ?? this.folderPath,
      origin: origin ?? this.origin,
      indexedAtMs: indexedAtMs ?? this.indexedAtMs,
      scanGeneration: scanGeneration ?? this.scanGeneration,
      screenshot: screenshot ?? this.screenshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameLower.present) {
      map['name_lower'] = Variable<String>(nameLower.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $MediaIndexTable.$converterkind.toSql(kind.value),
      );
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (modifiedAtMs.present) {
      map['modified_at_ms'] = Variable<int>(modifiedAtMs.value);
    }
    if (takenAtMs.present) {
      map['taken_at_ms'] = Variable<int>(takenAtMs.value);
    }
    if (sortDateMs.present) {
      map['sort_date_ms'] = Variable<int>(sortDateMs.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (origin.present) {
      map['origin'] = Variable<int>(
        $MediaIndexTable.$converterorigin.toSql(origin.value),
      );
    }
    if (indexedAtMs.present) {
      map['indexed_at_ms'] = Variable<int>(indexedAtMs.value);
    }
    if (scanGeneration.present) {
      map['scan_generation'] = Variable<int>(scanGeneration.value);
    }
    if (screenshot.present) {
      map['screenshot'] = Variable<bool>(screenshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaIndexCompanion(')
          ..write('id: $id, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write('mimeType: $mimeType, ')
          ..write('kind: $kind, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('takenAtMs: $takenAtMs, ')
          ..write('sortDateMs: $sortDateMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('folderPath: $folderPath, ')
          ..write('origin: $origin, ')
          ..write('indexedAtMs: $indexedAtMs, ')
          ..write('scanGeneration: $scanGeneration, ')
          ..write('screenshot: $screenshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<int> presetId = GeneratedColumn<int>(
    'preset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deleteModeMeta = const VerificationMeta(
    'deleteMode',
  );
  @override
  late final GeneratedColumn<String> deleteMode = GeneratedColumn<String>(
    'delete_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('trash'),
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cursorFileIdMeta = const VerificationMeta(
    'cursorFileId',
  );
  @override
  late final GeneratedColumn<String> cursorFileId = GeneratedColumn<String>(
    'cursor_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    presetId,
    layout,
    filter,
    deleteMode,
    cursor,
    cursorFileId,
    startedAt,
    updatedAt,
    isActive,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutMeta);
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    }
    if (data.containsKey('delete_mode')) {
      context.handle(
        _deleteModeMeta,
        deleteMode.isAcceptableOrUnknown(data['delete_mode']!, _deleteModeMeta),
      );
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('cursor_file_id')) {
      context.handle(
        _cursorFileIdMeta,
        cursorFileId.isAcceptableOrUnknown(
          data['cursor_file_id']!,
          _cursorFileIdMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset_id'],
      ),
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      )!,
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      ),
      deleteMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delete_mode'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      cursorFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_file_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;

  /// Preset id (P6); null = Basic. No FK: a deleted preset's ended sessions
  /// keep their id for P8 stats.
  final int? presetId;

  /// SwipeLayout JSON.
  final String layout;

  /// Filter JSON (P5); null = all media.
  final String? filter;

  /// 'trash' | 'permanent', copied from the setting when the session starts
  /// (D1), so changing the setting never affects queued deletes.
  final String deleteMode;

  /// Number of files swiped so far (progress).
  final int cursor;

  /// Last swiped file; the deck resumes after it even if new photos shifted
  /// positions (SE2).
  final String? cursorFileId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final bool isActive;

  /// Set when the session ends (Done / SE3 / preset deleted). Null with
  /// isActive false = paused by a preset switch (P6).
  final DateTime? endedAt;
  const SessionRow({
    required this.id,
    this.presetId,
    required this.layout,
    this.filter,
    required this.deleteMode,
    required this.cursor,
    this.cursorFileId,
    required this.startedAt,
    required this.updatedAt,
    required this.isActive,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || presetId != null) {
      map['preset_id'] = Variable<int>(presetId);
    }
    map['layout'] = Variable<String>(layout);
    if (!nullToAbsent || filter != null) {
      map['filter'] = Variable<String>(filter);
    }
    map['delete_mode'] = Variable<String>(deleteMode);
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || cursorFileId != null) {
      map['cursor_file_id'] = Variable<String>(cursorFileId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      presetId: presetId == null && nullToAbsent
          ? const Value.absent()
          : Value(presetId),
      layout: Value(layout),
      filter: filter == null && nullToAbsent
          ? const Value.absent()
          : Value(filter),
      deleteMode: Value(deleteMode),
      cursor: Value(cursor),
      cursorFileId: cursorFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(cursorFileId),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      presetId: serializer.fromJson<int?>(json['presetId']),
      layout: serializer.fromJson<String>(json['layout']),
      filter: serializer.fromJson<String?>(json['filter']),
      deleteMode: serializer.fromJson<String>(json['deleteMode']),
      cursor: serializer.fromJson<int>(json['cursor']),
      cursorFileId: serializer.fromJson<String?>(json['cursorFileId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'presetId': serializer.toJson<int?>(presetId),
      'layout': serializer.toJson<String>(layout),
      'filter': serializer.toJson<String?>(filter),
      'deleteMode': serializer.toJson<String>(deleteMode),
      'cursor': serializer.toJson<int>(cursor),
      'cursorFileId': serializer.toJson<String?>(cursorFileId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  SessionRow copyWith({
    int? id,
    Value<int?> presetId = const Value.absent(),
    String? layout,
    Value<String?> filter = const Value.absent(),
    String? deleteMode,
    int? cursor,
    Value<String?> cursorFileId = const Value.absent(),
    DateTime? startedAt,
    DateTime? updatedAt,
    bool? isActive,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    presetId: presetId.present ? presetId.value : this.presetId,
    layout: layout ?? this.layout,
    filter: filter.present ? filter.value : this.filter,
    deleteMode: deleteMode ?? this.deleteMode,
    cursor: cursor ?? this.cursor,
    cursorFileId: cursorFileId.present ? cursorFileId.value : this.cursorFileId,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isActive: isActive ?? this.isActive,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      layout: data.layout.present ? data.layout.value : this.layout,
      filter: data.filter.present ? data.filter.value : this.filter,
      deleteMode: data.deleteMode.present
          ? data.deleteMode.value
          : this.deleteMode,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      cursorFileId: data.cursorFileId.present
          ? data.cursorFileId.value
          : this.cursorFileId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('layout: $layout, ')
          ..write('filter: $filter, ')
          ..write('deleteMode: $deleteMode, ')
          ..write('cursor: $cursor, ')
          ..write('cursorFileId: $cursorFileId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    presetId,
    layout,
    filter,
    deleteMode,
    cursor,
    cursorFileId,
    startedAt,
    updatedAt,
    isActive,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.presetId == this.presetId &&
          other.layout == this.layout &&
          other.filter == this.filter &&
          other.deleteMode == this.deleteMode &&
          other.cursor == this.cursor &&
          other.cursorFileId == this.cursorFileId &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive &&
          other.endedAt == this.endedAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<int?> presetId;
  final Value<String> layout;
  final Value<String?> filter;
  final Value<String> deleteMode;
  final Value<int> cursor;
  final Value<String?> cursorFileId;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isActive;
  final Value<DateTime?> endedAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.presetId = const Value.absent(),
    this.layout = const Value.absent(),
    this.filter = const Value.absent(),
    this.deleteMode = const Value.absent(),
    this.cursor = const Value.absent(),
    this.cursorFileId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    this.presetId = const Value.absent(),
    required String layout,
    this.filter = const Value.absent(),
    this.deleteMode = const Value.absent(),
    this.cursor = const Value.absent(),
    this.cursorFileId = const Value.absent(),
    required DateTime startedAt,
    required DateTime updatedAt,
    required bool isActive,
    this.endedAt = const Value.absent(),
  }) : layout = Value(layout),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt),
       isActive = Value(isActive);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<int>? presetId,
    Expression<String>? layout,
    Expression<String>? filter,
    Expression<String>? deleteMode,
    Expression<int>? cursor,
    Expression<String>? cursorFileId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isActive,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presetId != null) 'preset_id': presetId,
      if (layout != null) 'layout': layout,
      if (filter != null) 'filter': filter,
      if (deleteMode != null) 'delete_mode': deleteMode,
      if (cursor != null) 'cursor': cursor,
      if (cursorFileId != null) 'cursor_file_id': cursorFileId,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? presetId,
    Value<String>? layout,
    Value<String?>? filter,
    Value<String>? deleteMode,
    Value<int>? cursor,
    Value<String?>? cursorFileId,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isActive,
    Value<DateTime?>? endedAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      layout: layout ?? this.layout,
      filter: filter ?? this.filter,
      deleteMode: deleteMode ?? this.deleteMode,
      cursor: cursor ?? this.cursor,
      cursorFileId: cursorFileId ?? this.cursorFileId,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<int>(presetId.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (deleteMode.present) {
      map['delete_mode'] = Variable<String>(deleteMode.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (cursorFileId.present) {
      map['cursor_file_id'] = Variable<String>(cursorFileId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('layout: $layout, ')
          ..write('filter: $filter, ')
          ..write('deleteMode: $deleteMode, ')
          ..write('cursor: $cursor, ')
          ..write('cursorFileId: $cursorFileId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionActionsTable extends SessionActions
    with TableInfo<$SessionActionsTable, SessionActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousStateMeta = const VerificationMeta(
    'previousState',
  );
  @override
  late final GeneratedColumn<String> previousState = GeneratedColumn<String>(
    'previous_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActionStatus>($SessionActionsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    fileId,
    actionType,
    payload,
    previousState,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('previous_state')) {
      context.handle(
        _previousStateMeta,
        previousState.isAcceptableOrUnknown(
          data['previous_state']!,
          _previousStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousStateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, seq},
  ];
  @override
  SessionActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      previousState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_state'],
      )!,
      status: $SessionActionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionActionsTable createAlias(String alias) {
    return $SessionActionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ActionStatus, String, String> $converterstatus =
      const EnumNameConverter<ActionStatus>(ActionStatus.values);
}

class SessionActionRow extends DataClass
    implements Insertable<SessionActionRow> {
  final int id;
  final int sessionId;

  /// 1..n per session, assigned in memory, never reused.
  final int seq;

  /// FileRef.id at the time of the action.
  final String fileId;

  /// SwipeActionType.name.
  final String actionType;

  /// SwipeAction JSON.
  final String payload;

  /// PreviousState JSON (what undo needs).
  final String previousState;
  final ActionStatus status;
  final DateTime createdAt;
  const SessionActionRow({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.fileId,
    required this.actionType,
    required this.payload,
    required this.previousState,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['file_id'] = Variable<String>(fileId);
    map['action_type'] = Variable<String>(actionType);
    map['payload'] = Variable<String>(payload);
    map['previous_state'] = Variable<String>(previousState);
    {
      map['status'] = Variable<String>(
        $SessionActionsTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionActionsCompanion toCompanion(bool nullToAbsent) {
    return SessionActionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      fileId: Value(fileId),
      actionType: Value(actionType),
      payload: Value(payload),
      previousState: Value(previousState),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory SessionActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionActionRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      fileId: serializer.fromJson<String>(json['fileId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      payload: serializer.fromJson<String>(json['payload']),
      previousState: serializer.fromJson<String>(json['previousState']),
      status: $SessionActionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'fileId': serializer.toJson<String>(fileId),
      'actionType': serializer.toJson<String>(actionType),
      'payload': serializer.toJson<String>(payload),
      'previousState': serializer.toJson<String>(previousState),
      'status': serializer.toJson<String>(
        $SessionActionsTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SessionActionRow copyWith({
    int? id,
    int? sessionId,
    int? seq,
    String? fileId,
    String? actionType,
    String? payload,
    String? previousState,
    ActionStatus? status,
    DateTime? createdAt,
  }) => SessionActionRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    fileId: fileId ?? this.fileId,
    actionType: actionType ?? this.actionType,
    payload: payload ?? this.payload,
    previousState: previousState ?? this.previousState,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  SessionActionRow copyWithCompanion(SessionActionsCompanion data) {
    return SessionActionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payload: data.payload.present ? data.payload.value : this.payload,
      previousState: data.previousState.present
          ? data.previousState.value
          : this.previousState,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionActionRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('fileId: $fileId, ')
          ..write('actionType: $actionType, ')
          ..write('payload: $payload, ')
          ..write('previousState: $previousState, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    fileId,
    actionType,
    payload,
    previousState,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionActionRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.fileId == this.fileId &&
          other.actionType == this.actionType &&
          other.payload == this.payload &&
          other.previousState == this.previousState &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SessionActionsCompanion extends UpdateCompanion<SessionActionRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> seq;
  final Value<String> fileId;
  final Value<String> actionType;
  final Value<String> payload;
  final Value<String> previousState;
  final Value<ActionStatus> status;
  final Value<DateTime> createdAt;
  const SessionActionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.fileId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payload = const Value.absent(),
    this.previousState = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SessionActionsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int seq,
    required String fileId,
    required String actionType,
    required String payload,
    required String previousState,
    required ActionStatus status,
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       seq = Value(seq),
       fileId = Value(fileId),
       actionType = Value(actionType),
       payload = Value(payload),
       previousState = Value(previousState),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SessionActionRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? seq,
    Expression<String>? fileId,
    Expression<String>? actionType,
    Expression<String>? payload,
    Expression<String>? previousState,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (fileId != null) 'file_id': fileId,
      if (actionType != null) 'action_type': actionType,
      if (payload != null) 'payload': payload,
      if (previousState != null) 'previous_state': previousState,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SessionActionsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? seq,
    Value<String>? fileId,
    Value<String>? actionType,
    Value<String>? payload,
    Value<String>? previousState,
    Value<ActionStatus>? status,
    Value<DateTime>? createdAt,
  }) {
    return SessionActionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      fileId: fileId ?? this.fileId,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      previousState: previousState ?? this.previousState,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (previousState.present) {
      map['previous_state'] = Variable<String>(previousState.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SessionActionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionActionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('fileId: $fileId, ')
          ..write('actionType: $actionType, ')
          ..write('payload: $payload, ')
          ..write('previousState: $previousState, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PendingDeletesTable extends PendingDeletes
    with TableInfo<$PendingDeletesTable, PendingDeleteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDeletesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<int> actionId = GeneratedColumn<int>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES session_actions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PendingDeleteStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PendingDeleteStatus>($PendingDeletesTable.$converterstatus);
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileModifiedAtMsMeta = const VerificationMeta(
    'fileModifiedAtMs',
  );
  @override
  late final GeneratedColumn<int> fileModifiedAtMs = GeneratedColumn<int>(
    'file_modified_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedModeMeta = const VerificationMeta(
    'committedMode',
  );
  @override
  late final GeneratedColumn<String> committedMode = GeneratedColumn<String>(
    'committed_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionId,
    sessionId,
    fileId,
    mode,
    status,
    failureReason,
    sizeBytes,
    fileModifiedAtMs,
    committedMode,
    queuedAt,
    committedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_deletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingDeleteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('file_modified_at_ms')) {
      context.handle(
        _fileModifiedAtMsMeta,
        fileModifiedAtMs.isAcceptableOrUnknown(
          data['file_modified_at_ms']!,
          _fileModifiedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileModifiedAtMsMeta);
    }
    if (data.containsKey('committed_mode')) {
      context.handle(
        _committedModeMeta,
        committedMode.isAcceptableOrUnknown(
          data['committed_mode']!,
          _committedModeMeta,
        ),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingDeleteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingDeleteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: $PendingDeletesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      fileModifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_modified_at_ms'],
      )!,
      committedMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}committed_mode'],
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      ),
    );
  }

  @override
  $PendingDeletesTable createAlias(String alias) {
    return $PendingDeletesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PendingDeleteStatus, String, String>
  $converterstatus = const EnumNameConverter<PendingDeleteStatus>(
    PendingDeleteStatus.values,
  );
}

class PendingDeleteRow extends DataClass
    implements Insertable<PendingDeleteRow> {
  final int id;
  final int actionId;
  final int sessionId;
  final String fileId;

  /// 'trash' | 'permanent' (the session's DeleteMode).
  final String mode;
  final PendingDeleteStatus status;
  final String? failureReason;

  /// FileRef.sizeBytes at queue time (P8 stats).
  final int sizeBytes;

  /// FileRef.modifiedAt (epoch ms) at queue time: a changed file is never
  /// deleted by mistake.
  final int fileModifiedAtMs;

  /// The mode actually used when committed (P8).
  final String? committedMode;
  final DateTime queuedAt;
  final DateTime? committedAt;
  const PendingDeleteRow({
    required this.id,
    required this.actionId,
    required this.sessionId,
    required this.fileId,
    required this.mode,
    required this.status,
    this.failureReason,
    required this.sizeBytes,
    required this.fileModifiedAtMs,
    this.committedMode,
    required this.queuedAt,
    this.committedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action_id'] = Variable<int>(actionId);
    map['session_id'] = Variable<int>(sessionId);
    map['file_id'] = Variable<String>(fileId);
    map['mode'] = Variable<String>(mode);
    {
      map['status'] = Variable<String>(
        $PendingDeletesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs);
    if (!nullToAbsent || committedMode != null) {
      map['committed_mode'] = Variable<String>(committedMode);
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    if (!nullToAbsent || committedAt != null) {
      map['committed_at'] = Variable<DateTime>(committedAt);
    }
    return map;
  }

  PendingDeletesCompanion toCompanion(bool nullToAbsent) {
    return PendingDeletesCompanion(
      id: Value(id),
      actionId: Value(actionId),
      sessionId: Value(sessionId),
      fileId: Value(fileId),
      mode: Value(mode),
      status: Value(status),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      sizeBytes: Value(sizeBytes),
      fileModifiedAtMs: Value(fileModifiedAtMs),
      committedMode: committedMode == null && nullToAbsent
          ? const Value.absent()
          : Value(committedMode),
      queuedAt: Value(queuedAt),
      committedAt: committedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(committedAt),
    );
  }

  factory PendingDeleteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingDeleteRow(
      id: serializer.fromJson<int>(json['id']),
      actionId: serializer.fromJson<int>(json['actionId']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      mode: serializer.fromJson<String>(json['mode']),
      status: $PendingDeletesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      fileModifiedAtMs: serializer.fromJson<int>(json['fileModifiedAtMs']),
      committedMode: serializer.fromJson<String?>(json['committedMode']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      committedAt: serializer.fromJson<DateTime?>(json['committedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actionId': serializer.toJson<int>(actionId),
      'sessionId': serializer.toJson<int>(sessionId),
      'fileId': serializer.toJson<String>(fileId),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(
        $PendingDeletesTable.$converterstatus.toJson(status),
      ),
      'failureReason': serializer.toJson<String?>(failureReason),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'fileModifiedAtMs': serializer.toJson<int>(fileModifiedAtMs),
      'committedMode': serializer.toJson<String?>(committedMode),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'committedAt': serializer.toJson<DateTime?>(committedAt),
    };
  }

  PendingDeleteRow copyWith({
    int? id,
    int? actionId,
    int? sessionId,
    String? fileId,
    String? mode,
    PendingDeleteStatus? status,
    Value<String?> failureReason = const Value.absent(),
    int? sizeBytes,
    int? fileModifiedAtMs,
    Value<String?> committedMode = const Value.absent(),
    DateTime? queuedAt,
    Value<DateTime?> committedAt = const Value.absent(),
  }) => PendingDeleteRow(
    id: id ?? this.id,
    actionId: actionId ?? this.actionId,
    sessionId: sessionId ?? this.sessionId,
    fileId: fileId ?? this.fileId,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
    committedMode: committedMode.present
        ? committedMode.value
        : this.committedMode,
    queuedAt: queuedAt ?? this.queuedAt,
    committedAt: committedAt.present ? committedAt.value : this.committedAt,
  );
  PendingDeleteRow copyWithCompanion(PendingDeletesCompanion data) {
    return PendingDeleteRow(
      id: data.id.present ? data.id.value : this.id,
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      fileModifiedAtMs: data.fileModifiedAtMs.present
          ? data.fileModifiedAtMs.value
          : this.fileModifiedAtMs,
      committedMode: data.committedMode.present
          ? data.committedMode.value
          : this.committedMode,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeleteRow(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('fileId: $fileId, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('committedMode: $committedMode, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionId,
    sessionId,
    fileId,
    mode,
    status,
    failureReason,
    sizeBytes,
    fileModifiedAtMs,
    committedMode,
    queuedAt,
    committedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingDeleteRow &&
          other.id == this.id &&
          other.actionId == this.actionId &&
          other.sessionId == this.sessionId &&
          other.fileId == this.fileId &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.failureReason == this.failureReason &&
          other.sizeBytes == this.sizeBytes &&
          other.fileModifiedAtMs == this.fileModifiedAtMs &&
          other.committedMode == this.committedMode &&
          other.queuedAt == this.queuedAt &&
          other.committedAt == this.committedAt);
}

class PendingDeletesCompanion extends UpdateCompanion<PendingDeleteRow> {
  final Value<int> id;
  final Value<int> actionId;
  final Value<int> sessionId;
  final Value<String> fileId;
  final Value<String> mode;
  final Value<PendingDeleteStatus> status;
  final Value<String?> failureReason;
  final Value<int> sizeBytes;
  final Value<int> fileModifiedAtMs;
  final Value<String?> committedMode;
  final Value<DateTime> queuedAt;
  final Value<DateTime?> committedAt;
  const PendingDeletesCompanion({
    this.id = const Value.absent(),
    this.actionId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.fileModifiedAtMs = const Value.absent(),
    this.committedMode = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.committedAt = const Value.absent(),
  });
  PendingDeletesCompanion.insert({
    this.id = const Value.absent(),
    required int actionId,
    required int sessionId,
    required String fileId,
    required String mode,
    required PendingDeleteStatus status,
    this.failureReason = const Value.absent(),
    required int sizeBytes,
    required int fileModifiedAtMs,
    this.committedMode = const Value.absent(),
    required DateTime queuedAt,
    this.committedAt = const Value.absent(),
  }) : actionId = Value(actionId),
       sessionId = Value(sessionId),
       fileId = Value(fileId),
       mode = Value(mode),
       status = Value(status),
       sizeBytes = Value(sizeBytes),
       fileModifiedAtMs = Value(fileModifiedAtMs),
       queuedAt = Value(queuedAt);
  static Insertable<PendingDeleteRow> custom({
    Expression<int>? id,
    Expression<int>? actionId,
    Expression<int>? sessionId,
    Expression<String>? fileId,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? failureReason,
    Expression<int>? sizeBytes,
    Expression<int>? fileModifiedAtMs,
    Expression<String>? committedMode,
    Expression<DateTime>? queuedAt,
    Expression<DateTime>? committedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionId != null) 'action_id': actionId,
      if (sessionId != null) 'session_id': sessionId,
      if (fileId != null) 'file_id': fileId,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (failureReason != null) 'failure_reason': failureReason,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (fileModifiedAtMs != null) 'file_modified_at_ms': fileModifiedAtMs,
      if (committedMode != null) 'committed_mode': committedMode,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (committedAt != null) 'committed_at': committedAt,
    });
  }

  PendingDeletesCompanion copyWith({
    Value<int>? id,
    Value<int>? actionId,
    Value<int>? sessionId,
    Value<String>? fileId,
    Value<String>? mode,
    Value<PendingDeleteStatus>? status,
    Value<String?>? failureReason,
    Value<int>? sizeBytes,
    Value<int>? fileModifiedAtMs,
    Value<String?>? committedMode,
    Value<DateTime>? queuedAt,
    Value<DateTime?>? committedAt,
  }) {
    return PendingDeletesCompanion(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      sessionId: sessionId ?? this.sessionId,
      fileId: fileId ?? this.fileId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
      committedMode: committedMode ?? this.committedMode,
      queuedAt: queuedAt ?? this.queuedAt,
      committedAt: committedAt ?? this.committedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actionId.present) {
      map['action_id'] = Variable<int>(actionId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PendingDeletesTable.$converterstatus.toSql(status.value),
      );
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (fileModifiedAtMs.present) {
      map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs.value);
    }
    if (committedMode.present) {
      map['committed_mode'] = Variable<String>(committedMode.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletesCompanion(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('fileId: $fileId, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('committedMode: $committedMode, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingFolderItemsTable extends PendingFolderItems
    with TableInfo<$PendingFolderItemsTable, PendingFolderItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingFolderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedPathMeta = const VerificationMeta(
    'storedPath',
  );
  @override
  late final GeneratedColumn<String> storedPath = GeneratedColumn<String>(
    'stored_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFileIdMeta = const VerificationMeta(
    'originalFileId',
  );
  @override
  late final GeneratedColumn<String> originalFileId = GeneratedColumn<String>(
    'original_file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalModifiedAtMeta =
      const VerificationMeta('originalModifiedAt');
  @override
  late final GeneratedColumn<DateTime> originalModifiedAt =
      GeneratedColumn<DateTime>(
        'original_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalPath,
    storedPath,
    volumeId,
    name,
    mimeType,
    sizeBytes,
    originalFileId,
    originalModifiedAt,
    deletedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_folder_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingFolderItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('stored_path')) {
      context.handle(
        _storedPathMeta,
        storedPath.isAcceptableOrUnknown(data['stored_path']!, _storedPathMeta),
      );
    } else if (isInserting) {
      context.missing(_storedPathMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('original_file_id')) {
      context.handle(
        _originalFileIdMeta,
        originalFileId.isAcceptableOrUnknown(
          data['original_file_id']!,
          _originalFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileIdMeta);
    }
    if (data.containsKey('original_modified_at')) {
      context.handle(
        _originalModifiedAtMeta,
        originalModifiedAt.isAcceptableOrUnknown(
          data['original_modified_at']!,
          _originalModifiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalModifiedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingFolderItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingFolderItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      storedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_path'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      originalFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_id'],
      )!,
      originalModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}original_modified_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $PendingFolderItemsTable createAlias(String alias) {
    return $PendingFolderItemsTable(attachedDatabase, alias);
  }
}

class PendingFolderItemRow extends DataClass
    implements Insertable<PendingFolderItemRow> {
  /// Random id (also part of the stored file name).
  final String id;

  /// Absolute path the file came from (restore target).
  final String originalPath;
  final String storedPath;

  /// Root path of the storage volume holding the folder.
  final String volumeId;
  final String name;
  final String? mimeType;
  final int sizeBytes;

  /// FileRef.id before the move (`ms:` for media on API ≤29).
  final String originalFileId;
  final DateTime originalModifiedAt;
  final DateTime deletedAt;
  final DateTime expiresAt;
  const PendingFolderItemRow({
    required this.id,
    required this.originalPath,
    required this.storedPath,
    required this.volumeId,
    required this.name,
    this.mimeType,
    required this.sizeBytes,
    required this.originalFileId,
    required this.originalModifiedAt,
    required this.deletedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original_path'] = Variable<String>(originalPath);
    map['stored_path'] = Variable<String>(storedPath);
    map['volume_id'] = Variable<String>(volumeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['original_file_id'] = Variable<String>(originalFileId);
    map['original_modified_at'] = Variable<DateTime>(originalModifiedAt);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  PendingFolderItemsCompanion toCompanion(bool nullToAbsent) {
    return PendingFolderItemsCompanion(
      id: Value(id),
      originalPath: Value(originalPath),
      storedPath: Value(storedPath),
      volumeId: Value(volumeId),
      name: Value(name),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      sizeBytes: Value(sizeBytes),
      originalFileId: Value(originalFileId),
      originalModifiedAt: Value(originalModifiedAt),
      deletedAt: Value(deletedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory PendingFolderItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingFolderItemRow(
      id: serializer.fromJson<String>(json['id']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      storedPath: serializer.fromJson<String>(json['storedPath']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      name: serializer.fromJson<String>(json['name']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      originalFileId: serializer.fromJson<String>(json['originalFileId']),
      originalModifiedAt: serializer.fromJson<DateTime>(
        json['originalModifiedAt'],
      ),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'originalPath': serializer.toJson<String>(originalPath),
      'storedPath': serializer.toJson<String>(storedPath),
      'volumeId': serializer.toJson<String>(volumeId),
      'name': serializer.toJson<String>(name),
      'mimeType': serializer.toJson<String?>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'originalFileId': serializer.toJson<String>(originalFileId),
      'originalModifiedAt': serializer.toJson<DateTime>(originalModifiedAt),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  PendingFolderItemRow copyWith({
    String? id,
    String? originalPath,
    String? storedPath,
    String? volumeId,
    String? name,
    Value<String?> mimeType = const Value.absent(),
    int? sizeBytes,
    String? originalFileId,
    DateTime? originalModifiedAt,
    DateTime? deletedAt,
    DateTime? expiresAt,
  }) => PendingFolderItemRow(
    id: id ?? this.id,
    originalPath: originalPath ?? this.originalPath,
    storedPath: storedPath ?? this.storedPath,
    volumeId: volumeId ?? this.volumeId,
    name: name ?? this.name,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    originalFileId: originalFileId ?? this.originalFileId,
    originalModifiedAt: originalModifiedAt ?? this.originalModifiedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  PendingFolderItemRow copyWithCompanion(PendingFolderItemsCompanion data) {
    return PendingFolderItemRow(
      id: data.id.present ? data.id.value : this.id,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      storedPath: data.storedPath.present
          ? data.storedPath.value
          : this.storedPath,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      name: data.name.present ? data.name.value : this.name,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      originalFileId: data.originalFileId.present
          ? data.originalFileId.value
          : this.originalFileId,
      originalModifiedAt: data.originalModifiedAt.present
          ? data.originalModifiedAt.value
          : this.originalModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingFolderItemRow(')
          ..write('id: $id, ')
          ..write('originalPath: $originalPath, ')
          ..write('storedPath: $storedPath, ')
          ..write('volumeId: $volumeId, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('originalFileId: $originalFileId, ')
          ..write('originalModifiedAt: $originalModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalPath,
    storedPath,
    volumeId,
    name,
    mimeType,
    sizeBytes,
    originalFileId,
    originalModifiedAt,
    deletedAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFolderItemRow &&
          other.id == this.id &&
          other.originalPath == this.originalPath &&
          other.storedPath == this.storedPath &&
          other.volumeId == this.volumeId &&
          other.name == this.name &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.originalFileId == this.originalFileId &&
          other.originalModifiedAt == this.originalModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.expiresAt == this.expiresAt);
}

class PendingFolderItemsCompanion
    extends UpdateCompanion<PendingFolderItemRow> {
  final Value<String> id;
  final Value<String> originalPath;
  final Value<String> storedPath;
  final Value<String> volumeId;
  final Value<String> name;
  final Value<String?> mimeType;
  final Value<int> sizeBytes;
  final Value<String> originalFileId;
  final Value<DateTime> originalModifiedAt;
  final Value<DateTime> deletedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const PendingFolderItemsCompanion({
    this.id = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.storedPath = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.name = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.originalFileId = const Value.absent(),
    this.originalModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingFolderItemsCompanion.insert({
    required String id,
    required String originalPath,
    required String storedPath,
    required String volumeId,
    required String name,
    this.mimeType = const Value.absent(),
    required int sizeBytes,
    required String originalFileId,
    required DateTime originalModifiedAt,
    required DateTime deletedAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       originalPath = Value(originalPath),
       storedPath = Value(storedPath),
       volumeId = Value(volumeId),
       name = Value(name),
       sizeBytes = Value(sizeBytes),
       originalFileId = Value(originalFileId),
       originalModifiedAt = Value(originalModifiedAt),
       deletedAt = Value(deletedAt),
       expiresAt = Value(expiresAt);
  static Insertable<PendingFolderItemRow> custom({
    Expression<String>? id,
    Expression<String>? originalPath,
    Expression<String>? storedPath,
    Expression<String>? volumeId,
    Expression<String>? name,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? originalFileId,
    Expression<DateTime>? originalModifiedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalPath != null) 'original_path': originalPath,
      if (storedPath != null) 'stored_path': storedPath,
      if (volumeId != null) 'volume_id': volumeId,
      if (name != null) 'name': name,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (originalFileId != null) 'original_file_id': originalFileId,
      if (originalModifiedAt != null)
        'original_modified_at': originalModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingFolderItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? originalPath,
    Value<String>? storedPath,
    Value<String>? volumeId,
    Value<String>? name,
    Value<String?>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? originalFileId,
    Value<DateTime>? originalModifiedAt,
    Value<DateTime>? deletedAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return PendingFolderItemsCompanion(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      storedPath: storedPath ?? this.storedPath,
      volumeId: volumeId ?? this.volumeId,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalFileId: originalFileId ?? this.originalFileId,
      originalModifiedAt: originalModifiedAt ?? this.originalModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (storedPath.present) {
      map['stored_path'] = Variable<String>(storedPath.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (originalFileId.present) {
      map['original_file_id'] = Variable<String>(originalFileId.value);
    }
    if (originalModifiedAt.present) {
      map['original_modified_at'] = Variable<DateTime>(
        originalModifiedAt.value,
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingFolderItemsCompanion(')
          ..write('id: $id, ')
          ..write('originalPath: $originalPath, ')
          ..write('storedPath: $storedPath, ')
          ..write('volumeId: $volumeId, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('originalFileId: $originalFileId, ')
          ..write('originalModifiedAt: $originalModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final int id;
  final String name;

  /// ARGB, one of `kTagColors`.
  final int color;
  final DateTime createdAt;
  const TagRow({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TagRow copyWith({int? id, String? name, int? color, DateTime? createdAt}) =>
      TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
      );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<DateTime> createdAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int color,
    required DateTime createdAt,
  }) : name = Value(name),
       color = Value(color),
       createdAt = Value(createdAt);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<DateTime>? createdAt,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FileTagsTable extends FileTags
    with TableInfo<$FileTagsTable, FileTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, tagId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId, tagId};
  @override
  FileTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileTagRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FileTagsTable createAlias(String alias) {
    return $FileTagsTable(attachedDatabase, alias);
  }
}

class FileTagRow extends DataClass implements Insertable<FileTagRow> {
  final String fileId;
  final int tagId;
  final DateTime addedAt;
  const FileTagRow({
    required this.fileId,
    required this.tagId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['tag_id'] = Variable<int>(tagId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FileTagsCompanion toCompanion(bool nullToAbsent) {
    return FileTagsCompanion(
      fileId: Value(fileId),
      tagId: Value(tagId),
      addedAt: Value(addedAt),
    );
  }

  factory FileTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileTagRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      tagId: serializer.fromJson<int>(json['tagId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'tagId': serializer.toJson<int>(tagId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FileTagRow copyWith({String? fileId, int? tagId, DateTime? addedAt}) =>
      FileTagRow(
        fileId: fileId ?? this.fileId,
        tagId: tagId ?? this.tagId,
        addedAt: addedAt ?? this.addedAt,
      );
  FileTagRow copyWithCompanion(FileTagsCompanion data) {
    return FileTagRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileTagRow(')
          ..write('fileId: $fileId, ')
          ..write('tagId: $tagId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, tagId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileTagRow &&
          other.fileId == this.fileId &&
          other.tagId == this.tagId &&
          other.addedAt == this.addedAt);
}

class FileTagsCompanion extends UpdateCompanion<FileTagRow> {
  final Value<String> fileId;
  final Value<int> tagId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FileTagsCompanion({
    this.fileId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileTagsCompanion.insert({
    required String fileId,
    required int tagId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       tagId = Value(tagId),
       addedAt = Value(addedAt);
  static Insertable<FileTagRow> custom({
    Expression<String>? fileId,
    Expression<int>? tagId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (tagId != null) 'tag_id': tagId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileTagsCompanion copyWith({
    Value<String>? fileId,
    Value<int>? tagId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FileTagsCompanion(
      fileId: fileId ?? this.fileId,
      tagId: tagId ?? this.tagId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileTagsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('tagId: $tagId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String fileId;
  final DateTime addedAt;
  const FavoriteRow({required this.fileId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(fileId: Value(fileId), addedAt: Value(addedAt));
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavoriteRow copyWith({String? fileId, DateTime? addedAt}) => FavoriteRow(
    fileId: fileId ?? this.fileId,
    addedAt: addedAt ?? this.addedAt,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('fileId: $fileId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.fileId == this.fileId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> fileId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.fileId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String fileId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       addedAt = Value(addedAt);
  static Insertable<FavoriteRow> custom({
    Expression<String>? fileId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? fileId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      fileId: fileId ?? this.fileId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('fileId: $fileId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RenameBatchesTable extends RenameBatches
    with TableInfo<$RenameBatchesTable, RenameBatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RenameBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RenameBatchStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RenameBatchStatus>($RenameBatchesTable.$converterstatus);
  static const VerificationMeta _patternJsonMeta = const VerificationMeta(
    'patternJson',
  );
  @override
  late final GeneratedColumn<String> patternJson = GeneratedColumn<String>(
    'pattern_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    status,
    patternJson,
    createdAt,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rename_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<RenameBatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('pattern_json')) {
      context.handle(
        _patternJsonMeta,
        patternJson.isAcceptableOrUnknown(
          data['pattern_json']!,
          _patternJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RenameBatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RenameBatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      status: $RenameBatchesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      patternJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      ),
    );
  }

  @override
  $RenameBatchesTable createAlias(String alias) {
    return $RenameBatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RenameBatchStatus, String, String>
  $converterstatus = const EnumNameConverter<RenameBatchStatus>(
    RenameBatchStatus.values,
  );
}

class RenameBatchRow extends DataClass implements Insertable<RenameBatchRow> {
  final int id;
  final int sessionId;
  final RenameBatchStatus status;

  /// The NamePattern JSON used by apply (null while collecting).
  final String? patternJson;
  final DateTime createdAt;
  final DateTime? appliedAt;
  const RenameBatchRow({
    required this.id,
    required this.sessionId,
    required this.status,
    this.patternJson,
    required this.createdAt,
    this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    {
      map['status'] = Variable<String>(
        $RenameBatchesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || patternJson != null) {
      map['pattern_json'] = Variable<String>(patternJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    return map;
  }

  RenameBatchesCompanion toCompanion(bool nullToAbsent) {
    return RenameBatchesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      status: Value(status),
      patternJson: patternJson == null && nullToAbsent
          ? const Value.absent()
          : Value(patternJson),
      createdAt: Value(createdAt),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
    );
  }

  factory RenameBatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RenameBatchRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      status: $RenameBatchesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      patternJson: serializer.fromJson<String?>(json['patternJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'status': serializer.toJson<String>(
        $RenameBatchesTable.$converterstatus.toJson(status),
      ),
      'patternJson': serializer.toJson<String?>(patternJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
    };
  }

  RenameBatchRow copyWith({
    int? id,
    int? sessionId,
    RenameBatchStatus? status,
    Value<String?> patternJson = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> appliedAt = const Value.absent(),
  }) => RenameBatchRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    status: status ?? this.status,
    patternJson: patternJson.present ? patternJson.value : this.patternJson,
    createdAt: createdAt ?? this.createdAt,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
  );
  RenameBatchRow copyWithCompanion(RenameBatchesCompanion data) {
    return RenameBatchRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      status: data.status.present ? data.status.value : this.status,
      patternJson: data.patternJson.present
          ? data.patternJson.value
          : this.patternJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RenameBatchRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('patternJson: $patternJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, status, patternJson, createdAt, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RenameBatchRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.status == this.status &&
          other.patternJson == this.patternJson &&
          other.createdAt == this.createdAt &&
          other.appliedAt == this.appliedAt);
}

class RenameBatchesCompanion extends UpdateCompanion<RenameBatchRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<RenameBatchStatus> status;
  final Value<String?> patternJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> appliedAt;
  const RenameBatchesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.patternJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  RenameBatchesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required RenameBatchStatus status,
    this.patternJson = const Value.absent(),
    required DateTime createdAt,
    this.appliedAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<RenameBatchRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? status,
    Expression<String>? patternJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? appliedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (patternJson != null) 'pattern_json': patternJson,
      if (createdAt != null) 'created_at': createdAt,
      if (appliedAt != null) 'applied_at': appliedAt,
    });
  }

  RenameBatchesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<RenameBatchStatus>? status,
    Value<String?>? patternJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? appliedAt,
  }) {
    return RenameBatchesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      patternJson: patternJson ?? this.patternJson,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $RenameBatchesTable.$converterstatus.toSql(status.value),
      );
    }
    if (patternJson.present) {
      map['pattern_json'] = Variable<String>(patternJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RenameBatchesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('patternJson: $patternJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }
}

class $RenameBatchItemsTable extends RenameBatchItems
    with TableInfo<$RenameBatchItemsTable, RenameBatchItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RenameBatchItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<int> batchId = GeneratedColumn<int>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rename_batches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentFileIdMeta = const VerificationMeta(
    'currentFileId',
  );
  @override
  late final GeneratedColumn<String> currentFileId = GeneratedColumn<String>(
    'current_file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentNameMeta = const VerificationMeta(
    'currentName',
  );
  @override
  late final GeneratedColumn<String> currentName = GeneratedColumn<String>(
    'current_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newNameMeta = const VerificationMeta(
    'newName',
  );
  @override
  late final GeneratedColumn<String> newName = GeneratedColumn<String>(
    'new_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tempNameMeta = const VerificationMeta(
    'tempName',
  );
  @override
  late final GeneratedColumn<String> tempName = GeneratedColumn<String>(
    'temp_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _skipReasonMeta = const VerificationMeta(
    'skipReason',
  );
  @override
  late final GeneratedColumn<String> skipReason = GeneratedColumn<String>(
    'skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    fileId,
    position,
    folderPath,
    originalName,
    currentFileId,
    currentName,
    newName,
    tempName,
    skipped,
    skipReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rename_batch_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RenameBatchItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('current_file_id')) {
      context.handle(
        _currentFileIdMeta,
        currentFileId.isAcceptableOrUnknown(
          data['current_file_id']!,
          _currentFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentFileIdMeta);
    }
    if (data.containsKey('current_name')) {
      context.handle(
        _currentNameMeta,
        currentName.isAcceptableOrUnknown(
          data['current_name']!,
          _currentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentNameMeta);
    }
    if (data.containsKey('new_name')) {
      context.handle(
        _newNameMeta,
        newName.isAcceptableOrUnknown(data['new_name']!, _newNameMeta),
      );
    }
    if (data.containsKey('temp_name')) {
      context.handle(
        _tempNameMeta,
        tempName.isAcceptableOrUnknown(data['temp_name']!, _tempNameMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('skip_reason')) {
      context.handle(
        _skipReasonMeta,
        skipReason.isAcceptableOrUnknown(data['skip_reason']!, _skipReasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId, fileId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {batchId, position},
  ];
  @override
  RenameBatchItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RenameBatchItemRow(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      currentFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_file_id'],
      )!,
      currentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_name'],
      )!,
      newName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_name'],
      ),
      tempName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_name'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      skipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skip_reason'],
      ),
    );
  }

  @override
  $RenameBatchItemsTable createAlias(String alias) {
    return $RenameBatchItemsTable(attachedDatabase, alias);
  }
}

class RenameBatchItemRow extends DataClass
    implements Insertable<RenameBatchItemRow> {
  final int batchId;

  /// FileRef.id when the file was added (stable key).
  final String fileId;

  /// Swipe order, 1..n.
  final int position;
  final String folderPath;
  final String originalName;
  final String currentFileId;
  final String currentName;

  /// Final name, set when apply starts.
  final String? newName;

  /// Intermediate name for the two-phase rename (name swaps).
  final String? tempName;
  final bool skipped;

  /// 'missing' | 'changed' | FileOpFailure.name.
  final String? skipReason;
  const RenameBatchItemRow({
    required this.batchId,
    required this.fileId,
    required this.position,
    required this.folderPath,
    required this.originalName,
    required this.currentFileId,
    required this.currentName,
    this.newName,
    this.tempName,
    required this.skipped,
    this.skipReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<int>(batchId);
    map['file_id'] = Variable<String>(fileId);
    map['position'] = Variable<int>(position);
    map['folder_path'] = Variable<String>(folderPath);
    map['original_name'] = Variable<String>(originalName);
    map['current_file_id'] = Variable<String>(currentFileId);
    map['current_name'] = Variable<String>(currentName);
    if (!nullToAbsent || newName != null) {
      map['new_name'] = Variable<String>(newName);
    }
    if (!nullToAbsent || tempName != null) {
      map['temp_name'] = Variable<String>(tempName);
    }
    map['skipped'] = Variable<bool>(skipped);
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(skipReason);
    }
    return map;
  }

  RenameBatchItemsCompanion toCompanion(bool nullToAbsent) {
    return RenameBatchItemsCompanion(
      batchId: Value(batchId),
      fileId: Value(fileId),
      position: Value(position),
      folderPath: Value(folderPath),
      originalName: Value(originalName),
      currentFileId: Value(currentFileId),
      currentName: Value(currentName),
      newName: newName == null && nullToAbsent
          ? const Value.absent()
          : Value(newName),
      tempName: tempName == null && nullToAbsent
          ? const Value.absent()
          : Value(tempName),
      skipped: Value(skipped),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
    );
  }

  factory RenameBatchItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RenameBatchItemRow(
      batchId: serializer.fromJson<int>(json['batchId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      position: serializer.fromJson<int>(json['position']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      originalName: serializer.fromJson<String>(json['originalName']),
      currentFileId: serializer.fromJson<String>(json['currentFileId']),
      currentName: serializer.fromJson<String>(json['currentName']),
      newName: serializer.fromJson<String?>(json['newName']),
      tempName: serializer.fromJson<String?>(json['tempName']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      skipReason: serializer.fromJson<String?>(json['skipReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<int>(batchId),
      'fileId': serializer.toJson<String>(fileId),
      'position': serializer.toJson<int>(position),
      'folderPath': serializer.toJson<String>(folderPath),
      'originalName': serializer.toJson<String>(originalName),
      'currentFileId': serializer.toJson<String>(currentFileId),
      'currentName': serializer.toJson<String>(currentName),
      'newName': serializer.toJson<String?>(newName),
      'tempName': serializer.toJson<String?>(tempName),
      'skipped': serializer.toJson<bool>(skipped),
      'skipReason': serializer.toJson<String?>(skipReason),
    };
  }

  RenameBatchItemRow copyWith({
    int? batchId,
    String? fileId,
    int? position,
    String? folderPath,
    String? originalName,
    String? currentFileId,
    String? currentName,
    Value<String?> newName = const Value.absent(),
    Value<String?> tempName = const Value.absent(),
    bool? skipped,
    Value<String?> skipReason = const Value.absent(),
  }) => RenameBatchItemRow(
    batchId: batchId ?? this.batchId,
    fileId: fileId ?? this.fileId,
    position: position ?? this.position,
    folderPath: folderPath ?? this.folderPath,
    originalName: originalName ?? this.originalName,
    currentFileId: currentFileId ?? this.currentFileId,
    currentName: currentName ?? this.currentName,
    newName: newName.present ? newName.value : this.newName,
    tempName: tempName.present ? tempName.value : this.tempName,
    skipped: skipped ?? this.skipped,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
  );
  RenameBatchItemRow copyWithCompanion(RenameBatchItemsCompanion data) {
    return RenameBatchItemRow(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      position: data.position.present ? data.position.value : this.position,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      currentFileId: data.currentFileId.present
          ? data.currentFileId.value
          : this.currentFileId,
      currentName: data.currentName.present
          ? data.currentName.value
          : this.currentName,
      newName: data.newName.present ? data.newName.value : this.newName,
      tempName: data.tempName.present ? data.tempName.value : this.tempName,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RenameBatchItemRow(')
          ..write('batchId: $batchId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('folderPath: $folderPath, ')
          ..write('originalName: $originalName, ')
          ..write('currentFileId: $currentFileId, ')
          ..write('currentName: $currentName, ')
          ..write('newName: $newName, ')
          ..write('tempName: $tempName, ')
          ..write('skipped: $skipped, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    fileId,
    position,
    folderPath,
    originalName,
    currentFileId,
    currentName,
    newName,
    tempName,
    skipped,
    skipReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RenameBatchItemRow &&
          other.batchId == this.batchId &&
          other.fileId == this.fileId &&
          other.position == this.position &&
          other.folderPath == this.folderPath &&
          other.originalName == this.originalName &&
          other.currentFileId == this.currentFileId &&
          other.currentName == this.currentName &&
          other.newName == this.newName &&
          other.tempName == this.tempName &&
          other.skipped == this.skipped &&
          other.skipReason == this.skipReason);
}

class RenameBatchItemsCompanion extends UpdateCompanion<RenameBatchItemRow> {
  final Value<int> batchId;
  final Value<String> fileId;
  final Value<int> position;
  final Value<String> folderPath;
  final Value<String> originalName;
  final Value<String> currentFileId;
  final Value<String> currentName;
  final Value<String?> newName;
  final Value<String?> tempName;
  final Value<bool> skipped;
  final Value<String?> skipReason;
  final Value<int> rowid;
  const RenameBatchItemsCompanion({
    this.batchId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.position = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.originalName = const Value.absent(),
    this.currentFileId = const Value.absent(),
    this.currentName = const Value.absent(),
    this.newName = const Value.absent(),
    this.tempName = const Value.absent(),
    this.skipped = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RenameBatchItemsCompanion.insert({
    required int batchId,
    required String fileId,
    required int position,
    required String folderPath,
    required String originalName,
    required String currentFileId,
    required String currentName,
    this.newName = const Value.absent(),
    this.tempName = const Value.absent(),
    this.skipped = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       fileId = Value(fileId),
       position = Value(position),
       folderPath = Value(folderPath),
       originalName = Value(originalName),
       currentFileId = Value(currentFileId),
       currentName = Value(currentName);
  static Insertable<RenameBatchItemRow> custom({
    Expression<int>? batchId,
    Expression<String>? fileId,
    Expression<int>? position,
    Expression<String>? folderPath,
    Expression<String>? originalName,
    Expression<String>? currentFileId,
    Expression<String>? currentName,
    Expression<String>? newName,
    Expression<String>? tempName,
    Expression<bool>? skipped,
    Expression<String>? skipReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (fileId != null) 'file_id': fileId,
      if (position != null) 'position': position,
      if (folderPath != null) 'folder_path': folderPath,
      if (originalName != null) 'original_name': originalName,
      if (currentFileId != null) 'current_file_id': currentFileId,
      if (currentName != null) 'current_name': currentName,
      if (newName != null) 'new_name': newName,
      if (tempName != null) 'temp_name': tempName,
      if (skipped != null) 'skipped': skipped,
      if (skipReason != null) 'skip_reason': skipReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RenameBatchItemsCompanion copyWith({
    Value<int>? batchId,
    Value<String>? fileId,
    Value<int>? position,
    Value<String>? folderPath,
    Value<String>? originalName,
    Value<String>? currentFileId,
    Value<String>? currentName,
    Value<String?>? newName,
    Value<String?>? tempName,
    Value<bool>? skipped,
    Value<String?>? skipReason,
    Value<int>? rowid,
  }) {
    return RenameBatchItemsCompanion(
      batchId: batchId ?? this.batchId,
      fileId: fileId ?? this.fileId,
      position: position ?? this.position,
      folderPath: folderPath ?? this.folderPath,
      originalName: originalName ?? this.originalName,
      currentFileId: currentFileId ?? this.currentFileId,
      currentName: currentName ?? this.currentName,
      newName: newName ?? this.newName,
      tempName: tempName ?? this.tempName,
      skipped: skipped ?? this.skipped,
      skipReason: skipReason ?? this.skipReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<int>(batchId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (currentFileId.present) {
      map['current_file_id'] = Variable<String>(currentFileId.value);
    }
    if (currentName.present) {
      map['current_name'] = Variable<String>(currentName.value);
    }
    if (newName.present) {
      map['new_name'] = Variable<String>(newName.value);
    }
    if (tempName.present) {
      map['temp_name'] = Variable<String>(tempName.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(skipReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RenameBatchItemsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('folderPath: $folderPath, ')
          ..write('originalName: $originalName, ')
          ..write('currentFileId: $currentFileId, ')
          ..write('currentName: $currentName, ')
          ..write('newName: $newName, ')
          ..write('tempName: $tempName, ')
          ..write('skipped: $skipped, ')
          ..write('skipReason: $skipReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresetsTable extends Presets with TableInfo<$PresetsTable, PresetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layoutJsonMeta = const VerificationMeta(
    'layoutJson',
  );
  @override
  late final GeneratedColumn<String> layoutJson = GeneratedColumn<String>(
    'layout_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterJsonMeta = const VerificationMeta(
    'filterJson',
  );
  @override
  late final GeneratedColumn<String> filterJson = GeneratedColumn<String>(
    'filter_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _includeReviewedMeta = const VerificationMeta(
    'includeReviewed',
  );
  @override
  late final GeneratedColumn<bool> includeReviewed = GeneratedColumn<bool>(
    'include_reviewed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_reviewed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    layoutJson,
    filterJson,
    includeReviewed,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('layout_json')) {
      context.handle(
        _layoutJsonMeta,
        layoutJson.isAcceptableOrUnknown(data['layout_json']!, _layoutJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutJsonMeta);
    }
    if (data.containsKey('filter_json')) {
      context.handle(
        _filterJsonMeta,
        filterJson.isAcceptableOrUnknown(data['filter_json']!, _filterJsonMeta),
      );
    }
    if (data.containsKey('include_reviewed')) {
      context.handle(
        _includeReviewedMeta,
        includeReviewed.isAcceptableOrUnknown(
          data['include_reviewed']!,
          _includeReviewedMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      layoutJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout_json'],
      )!,
      filterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_json'],
      ),
      includeReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_reviewed'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PresetsTable createAlias(String alias) {
    return $PresetsTable(attachedDatabase, alias);
  }
}

class PresetRow extends DataClass implements Insertable<PresetRow> {
  final int id;

  /// Trimmed, 1–40 chars, unique ignoring case.
  final String name;

  /// SwipeLayout JSON.
  final String layoutJson;

  /// FileFilter JSON; null = no filter.
  final String? filterJson;

  /// P7: false = skip files already reviewed in this preset (default).
  final bool includeReviewed;
  final int sortOrder;
  final DateTime createdAt;
  const PresetRow({
    required this.id,
    required this.name,
    required this.layoutJson,
    this.filterJson,
    required this.includeReviewed,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['layout_json'] = Variable<String>(layoutJson);
    if (!nullToAbsent || filterJson != null) {
      map['filter_json'] = Variable<String>(filterJson);
    }
    map['include_reviewed'] = Variable<bool>(includeReviewed);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PresetsCompanion toCompanion(bool nullToAbsent) {
    return PresetsCompanion(
      id: Value(id),
      name: Value(name),
      layoutJson: Value(layoutJson),
      filterJson: filterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(filterJson),
      includeReviewed: Value(includeReviewed),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory PresetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      layoutJson: serializer.fromJson<String>(json['layoutJson']),
      filterJson: serializer.fromJson<String?>(json['filterJson']),
      includeReviewed: serializer.fromJson<bool>(json['includeReviewed']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'layoutJson': serializer.toJson<String>(layoutJson),
      'filterJson': serializer.toJson<String?>(filterJson),
      'includeReviewed': serializer.toJson<bool>(includeReviewed),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PresetRow copyWith({
    int? id,
    String? name,
    String? layoutJson,
    Value<String?> filterJson = const Value.absent(),
    bool? includeReviewed,
    int? sortOrder,
    DateTime? createdAt,
  }) => PresetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    layoutJson: layoutJson ?? this.layoutJson,
    filterJson: filterJson.present ? filterJson.value : this.filterJson,
    includeReviewed: includeReviewed ?? this.includeReviewed,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  PresetRow copyWithCompanion(PresetsCompanion data) {
    return PresetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      layoutJson: data.layoutJson.present
          ? data.layoutJson.value
          : this.layoutJson,
      filterJson: data.filterJson.present
          ? data.filterJson.value
          : this.filterJson,
      includeReviewed: data.includeReviewed.present
          ? data.includeReviewed.value
          : this.includeReviewed,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('layoutJson: $layoutJson, ')
          ..write('filterJson: $filterJson, ')
          ..write('includeReviewed: $includeReviewed, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    layoutJson,
    filterJson,
    includeReviewed,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.layoutJson == this.layoutJson &&
          other.filterJson == this.filterJson &&
          other.includeReviewed == this.includeReviewed &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class PresetsCompanion extends UpdateCompanion<PresetRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> layoutJson;
  final Value<String?> filterJson;
  final Value<bool> includeReviewed;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const PresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.layoutJson = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.includeReviewed = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String layoutJson,
    this.filterJson = const Value.absent(),
    this.includeReviewed = const Value.absent(),
    required int sortOrder,
    required DateTime createdAt,
  }) : name = Value(name),
       layoutJson = Value(layoutJson),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<PresetRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? layoutJson,
    Expression<String>? filterJson,
    Expression<bool>? includeReviewed,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (layoutJson != null) 'layout_json': layoutJson,
      if (filterJson != null) 'filter_json': filterJson,
      if (includeReviewed != null) 'include_reviewed': includeReviewed,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? layoutJson,
    Value<String?>? filterJson,
    Value<bool>? includeReviewed,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return PresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      layoutJson: layoutJson ?? this.layoutJson,
      filterJson: filterJson ?? this.filterJson,
      includeReviewed: includeReviewed ?? this.includeReviewed,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (layoutJson.present) {
      map['layout_json'] = Variable<String>(layoutJson.value);
    }
    if (filterJson.present) {
      map['filter_json'] = Variable<String>(filterJson.value);
    }
    if (includeReviewed.present) {
      map['include_reviewed'] = Variable<bool>(includeReviewed.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('layoutJson: $layoutJson, ')
          ..write('filterJson: $filterJson, ')
          ..write('includeReviewed: $includeReviewed, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $MediaIndexTable mediaIndex = $MediaIndexTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionActionsTable sessionActions = $SessionActionsTable(this);
  late final $PendingDeletesTable pendingDeletes = $PendingDeletesTable(this);
  late final $PendingFolderItemsTable pendingFolderItems =
      $PendingFolderItemsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $FileTagsTable fileTags = $FileTagsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $RenameBatchesTable renameBatches = $RenameBatchesTable(this);
  late final $RenameBatchItemsTable renameBatchItems = $RenameBatchItemsTable(
    this,
  );
  late final $PresetsTable presets = $PresetsTable(this);
  late final Index miKindDate = Index(
    'mi_kind_date',
    'CREATE INDEX mi_kind_date ON media_index (kind, sort_date_ms)',
  );
  late final Index miKindSize = Index(
    'mi_kind_size',
    'CREATE INDEX mi_kind_size ON media_index (kind, size_bytes)',
  );
  late final Index miFolderDate = Index(
    'mi_folder_date',
    'CREATE INDEX mi_folder_date ON media_index (folder_path, sort_date_ms)',
  );
  late final Index miDate = Index(
    'mi_date',
    'CREATE INDEX mi_date ON media_index (sort_date_ms)',
  );
  late final Index miName = Index(
    'mi_name',
    'CREATE INDEX mi_name ON media_index (name_lower)',
  );
  late final Index miScreenshotDate = Index(
    'mi_screenshot_date',
    'CREATE INDEX mi_screenshot_date ON media_index (screenshot, sort_date_ms)',
  );
  late final Index oneActiveSession = Index(
    'one_active_session',
    'CREATE UNIQUE INDEX one_active_session ON sessions (is_active) WHERE is_active = 1',
  );
  late final Index oneOpenSessionPerPreset = Index(
    'one_open_session_per_preset',
    'CREATE UNIQUE INDEX one_open_session_per_preset ON sessions (COALESCE(preset_id, 0)) WHERE ended_at IS NULL',
  );
  late final Index saSessionStatusSeq = Index(
    'sa_session_status_seq',
    'CREATE INDEX sa_session_status_seq ON session_actions (session_id, status, seq)',
  );
  late final Index pdSessionStatus = Index(
    'pd_session_status',
    'CREATE INDEX pd_session_status ON pending_deletes (session_id, status)',
  );
  late final Index pfiExpires = Index(
    'pfi_expires',
    'CREATE INDEX pfi_expires ON pending_folder_items (expires_at)',
  );
  late final Index ftTag = Index(
    'ft_tag',
    'CREATE INDEX ft_tag ON file_tags (tag_id)',
  );
  late final Index oneCollectingBatch = Index(
    'one_collecting_batch',
    'CREATE UNIQUE INDEX one_collecting_batch ON rename_batches (session_id) WHERE status = \'collecting\'',
  );
  late final Index presetsNameNocase = Index(
    'presets_name_nocase',
    'CREATE UNIQUE INDEX presets_name_nocase ON presets (name COLLATE NOCASE)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    mediaIndex,
    sessions,
    sessionActions,
    pendingDeletes,
    pendingFolderItems,
    tags,
    fileTags,
    favorites,
    renameBatches,
    renameBatchItems,
    presets,
    miKindDate,
    miKindSize,
    miFolderDate,
    miDate,
    miName,
    miScreenshotDate,
    oneActiveSession,
    oneOpenSessionPerPreset,
    saSessionStatusSeq,
    pdSessionStatus,
    pfiExpires,
    ftTag,
    oneCollectingBatch,
    presetsNameNocase,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_actions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_actions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_deletes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_deletes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('file_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rename_batches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rename_batches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rename_batch_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$MediaIndexTableCreateCompanionBuilder = MediaIndexCompanion Function({
  required String id,
  required String uri,
  required String name,
  required String nameLower,
  Value<String?> mimeType,
  required FileKind kind,
  required int sizeBytes,
  required int modifiedAtMs,
  Value<int?> takenAtMs,
  required int sortDateMs,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationMs,
  required String folderPath,
  required FileOrigin origin,
  required int indexedAtMs,
  required int scanGeneration,
  Value<bool> screenshot,
  Value<int> rowid,
});
typedef $$MediaIndexTableUpdateCompanionBuilder = MediaIndexCompanion Function({
  Value<String> id,
  Value<String> uri,
  Value<String> name,
  Value<String> nameLower,
  Value<String?> mimeType,
  Value<FileKind> kind,
  Value<int> sizeBytes,
  Value<int> modifiedAtMs,
  Value<int?> takenAtMs,
  Value<int> sortDateMs,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationMs,
  Value<String> folderPath,
  Value<FileOrigin> origin,
  Value<int> indexedAtMs,
  Value<int> scanGeneration,
  Value<bool> screenshot,
  Value<int> rowid,
});

class $$MediaIndexTableFilterComposer
    extends Composer<_$AppDatabase, $MediaIndexTable> {
  $$MediaIndexTableFilterComposer({
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

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FileKind, FileKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takenAtMs => $composableBuilder(
    column: $table.takenAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FileOrigin, FileOrigin, int> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaIndexTable> {
  $$MediaIndexTableOrderingComposer({
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

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takenAtMs => $composableBuilder(
    column: $table.takenAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaIndexTable> {
  $$MediaIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameLower =>
      $composableBuilder(column: $table.nameLower, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FileKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get takenAtMs =>
      $composableBuilder(column: $table.takenAtMs, builder: (column) => column);

  GeneratedColumn<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FileOrigin, int> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => column,
  );
}

class $$MediaIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaIndexTable,
          MediaIndexRow,
          $$MediaIndexTableFilterComposer,
          $$MediaIndexTableOrderingComposer,
          $$MediaIndexTableAnnotationComposer,
          $$MediaIndexTableCreateCompanionBuilder,
          $$MediaIndexTableUpdateCompanionBuilder,
          (
            MediaIndexRow,
            BaseReferences<_$AppDatabase, $MediaIndexTable, MediaIndexRow>,
          ),
          MediaIndexRow,
          PrefetchHooks Function()
        > {
  $$MediaIndexTableTableManager(_$AppDatabase db, $MediaIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameLower = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<FileKind> kind = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> modifiedAtMs = const Value.absent(),
                Value<int?> takenAtMs = const Value.absent(),
                Value<int> sortDateMs = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<FileOrigin> origin = const Value.absent(),
                Value<int> indexedAtMs = const Value.absent(),
                Value<int> scanGeneration = const Value.absent(),
                Value<bool> screenshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaIndexCompanion(
                id: id,
                uri: uri,
                name: name,
                nameLower: nameLower,
                mimeType: mimeType,
                kind: kind,
                sizeBytes: sizeBytes,
                modifiedAtMs: modifiedAtMs,
                takenAtMs: takenAtMs,
                sortDateMs: sortDateMs,
                width: width,
                height: height,
                durationMs: durationMs,
                folderPath: folderPath,
                origin: origin,
                indexedAtMs: indexedAtMs,
                scanGeneration: scanGeneration,
                screenshot: screenshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String uri,
                required String name,
                required String nameLower,
                Value<String?> mimeType = const Value.absent(),
                required FileKind kind,
                required int sizeBytes,
                required int modifiedAtMs,
                Value<int?> takenAtMs = const Value.absent(),
                required int sortDateMs,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                required String folderPath,
                required FileOrigin origin,
                required int indexedAtMs,
                required int scanGeneration,
                Value<bool> screenshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaIndexCompanion.insert(
                id: id,
                uri: uri,
                name: name,
                nameLower: nameLower,
                mimeType: mimeType,
                kind: kind,
                sizeBytes: sizeBytes,
                modifiedAtMs: modifiedAtMs,
                takenAtMs: takenAtMs,
                sortDateMs: sortDateMs,
                width: width,
                height: height,
                durationMs: durationMs,
                folderPath: folderPath,
                origin: origin,
                indexedAtMs: indexedAtMs,
                scanGeneration: scanGeneration,
                screenshot: screenshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaIndexTable, MediaIndexRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MediaIndexTable,
                    MediaIndexRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaIndexTable,
      MediaIndexRow,
      $$MediaIndexTableFilterComposer,
      $$MediaIndexTableOrderingComposer,
      $$MediaIndexTableAnnotationComposer,
      $$MediaIndexTableCreateCompanionBuilder,
      $$MediaIndexTableUpdateCompanionBuilder,
      (
        MediaIndexRow,
        BaseReferences<_$AppDatabase, $MediaIndexTable, MediaIndexRow>,
      ),
      MediaIndexRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int?> presetId,
  required String layout,
  Value<String?> filter,
  Value<String> deleteMode,
  Value<int> cursor,
  Value<String?> cursorFileId,
  required DateTime startedAt,
  required DateTime updatedAt,
  required bool isActive,
  Value<DateTime?> endedAt,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int?> presetId,
  Value<String> layout,
  Value<String?> filter,
  Value<String> deleteMode,
  Value<int> cursor,
  Value<String?> cursorFileId,
  Value<DateTime> startedAt,
  Value<DateTime> updatedAt,
  Value<bool> isActive,
  Value<DateTime?> endedAt,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionActionsTable, List<SessionActionRow>>
  _sessionActionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionActions,
    aliasName: 'sessions__id__session_actions__session_id',
  );

  $$SessionActionsTableProcessedTableManager get sessionActionsRefs {
    final manager = $$SessionActionsTableTableManager(
      $_db,
      $_db.sessionActions,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionActionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingDeletesTable, List<PendingDeleteRow>>
  _pendingDeletesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingDeletes,
    aliasName: 'sessions__id__pending_deletes__session_id',
  );

  $$PendingDeletesTableProcessedTableManager get pendingDeletesRefs {
    final manager = $$PendingDeletesTableTableManager(
      $_db,
      $_db.pendingDeletes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pendingDeletesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RenameBatchesTable, List<RenameBatchRow>>
  _renameBatchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.renameBatches,
    aliasName: 'sessions__id__rename_batches__session_id',
  );

  $$RenameBatchesTableProcessedTableManager get renameBatchesRefs {
    final manager = $$RenameBatchesTableTableManager(
      $_db,
      $_db.renameBatches,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_renameBatchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deleteMode => $composableBuilder(
    column: $table.deleteMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorFileId => $composableBuilder(
    column: $table.cursorFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionActionsRefs(
    Expression<bool> Function($$SessionActionsTableFilterComposer f) f,
  ) {
    final $$SessionActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionActions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionActionsTableFilterComposer(
            $db: $db,
            $table: $db.sessionActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingDeletesRefs(
    Expression<bool> Function($$PendingDeletesTableFilterComposer f) f,
  ) {
    final $$PendingDeletesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingDeletes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingDeletesTableFilterComposer(
            $db: $db,
            $table: $db.pendingDeletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> renameBatchesRefs(
    Expression<bool> Function($$RenameBatchesTableFilterComposer f) f,
  ) {
    final $$RenameBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renameBatches,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchesTableFilterComposer(
            $db: $db,
            $table: $db.renameBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deleteMode => $composableBuilder(
    column: $table.deleteMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorFileId => $composableBuilder(
    column: $table.cursorFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumn<String> get deleteMode => $composableBuilder(
    column: $table.deleteMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<String> get cursorFileId => $composableBuilder(
    column: $table.cursorFileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  Expression<T> sessionActionsRefs<T extends Object>(
    Expression<T> Function($$SessionActionsTableAnnotationComposer a) f,
  ) {
    final $$SessionActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionActions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pendingDeletesRefs<T extends Object>(
    Expression<T> Function($$PendingDeletesTableAnnotationComposer a) f,
  ) {
    final $$PendingDeletesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingDeletes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingDeletesTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingDeletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> renameBatchesRefs<T extends Object>(
    Expression<T> Function($$RenameBatchesTableAnnotationComposer a) f,
  ) {
    final $$RenameBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renameBatches,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.renameBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({
            bool sessionActionsRefs,
            bool pendingDeletesRefs,
            bool renameBatchesRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> presetId = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<String?> filter = const Value.absent(),
                Value<String> deleteMode = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<String?> cursorFileId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                presetId: presetId,
                layout: layout,
                filter: filter,
                deleteMode: deleteMode,
                cursor: cursor,
                cursorFileId: cursorFileId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                isActive: isActive,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> presetId = const Value.absent(),
                required String layout,
                Value<String?> filter = const Value.absent(),
                Value<String> deleteMode = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<String?> cursorFileId = const Value.absent(),
                required DateTime startedAt,
                required DateTime updatedAt,
                required bool isActive,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                presetId: presetId,
                layout: layout,
                filter: filter,
                deleteMode: deleteMode,
                cursor: cursor,
                cursorFileId: cursorFileId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                isActive: isActive,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionActionsRefs = false,
                pendingDeletesRefs = false,
                renameBatchesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionActionsRefs) db.sessionActions,
                    if (pendingDeletesRefs) db.pendingDeletes,
                    if (renameBatchesRefs) db.renameBatches,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionActionsRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          SessionActionRow,
                          $SessionActionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionActionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionActionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (pendingDeletesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          PendingDeleteRow,
                          $PendingDeletesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._pendingDeletesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingDeletesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (renameBatchesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          RenameBatchRow,
                          $RenameBatchesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._renameBatchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).renameBatchesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({
        bool sessionActionsRefs,
        bool pendingDeletesRefs,
        bool renameBatchesRefs,
      })
    >;
typedef $$SessionActionsTableCreateCompanionBuilder =
    SessionActionsCompanion Function({
      Value<int> id,
      required int sessionId,
      required int seq,
      required String fileId,
      required String actionType,
      required String payload,
      required String previousState,
      required ActionStatus status,
      required DateTime createdAt,
    });
typedef $$SessionActionsTableUpdateCompanionBuilder =
    SessionActionsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> seq,
      Value<String> fileId,
      Value<String> actionType,
      Value<String> payload,
      Value<String> previousState,
      Value<ActionStatus> status,
      Value<DateTime> createdAt,
    });

final class $$SessionActionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionActionsTable, SessionActionRow> {
  $$SessionActionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('session_actions__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PendingDeletesTable, List<PendingDeleteRow>>
  _pendingDeletesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingDeletes,
    aliasName: 'session_actions__id__pending_deletes__action_id',
  );

  $$PendingDeletesTableProcessedTableManager get pendingDeletesRefs {
    final manager = $$PendingDeletesTableTableManager(
      $_db,
      $_db.pendingDeletes,
    ).filter((f) => f.actionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pendingDeletesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionActionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionActionsTable> {
  $$SessionActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActionStatus, ActionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pendingDeletesRefs(
    Expression<bool> Function($$PendingDeletesTableFilterComposer f) f,
  ) {
    final $$PendingDeletesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingDeletes,
      getReferencedColumn: (t) => t.actionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingDeletesTableFilterComposer(
            $db: $db,
            $table: $db.pendingDeletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionActionsTable> {
  $$SessionActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionActionsTable> {
  $$SessionActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ActionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pendingDeletesRefs<T extends Object>(
    Expression<T> Function($$PendingDeletesTableAnnotationComposer a) f,
  ) {
    final $$PendingDeletesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingDeletes,
      getReferencedColumn: (t) => t.actionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingDeletesTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingDeletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionActionsTable,
          SessionActionRow,
          $$SessionActionsTableFilterComposer,
          $$SessionActionsTableOrderingComposer,
          $$SessionActionsTableAnnotationComposer,
          $$SessionActionsTableCreateCompanionBuilder,
          $$SessionActionsTableUpdateCompanionBuilder,
          (SessionActionRow, $$SessionActionsTableReferences),
          SessionActionRow,
          PrefetchHooks Function({bool sessionId, bool pendingDeletesRefs})
        > {
  $$SessionActionsTableTableManager(
    _$AppDatabase db,
    $SessionActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> previousState = const Value.absent(),
                Value<ActionStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SessionActionsCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                fileId: fileId,
                actionType: actionType,
                payload: payload,
                previousState: previousState,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int seq,
                required String fileId,
                required String actionType,
                required String payload,
                required String previousState,
                required ActionStatus status,
                required DateTime createdAt,
              }) => SessionActionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                fileId: fileId,
                actionType: actionType,
                payload: payload,
                previousState: previousState,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionActionsTable, SessionActionRow>(table),
                  $$SessionActionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, pendingDeletesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pendingDeletesRefs) db.pendingDeletes,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$SessionActionsTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$SessionActionsTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pendingDeletesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionActionRow,
                          $SessionActionsTable,
                          PendingDeleteRow,
                          $PendingDeletesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionActionsTableReferences
                              ._pendingDeletesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionActionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingDeletesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'action_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionActionsTable,
      SessionActionRow,
      $$SessionActionsTableFilterComposer,
      $$SessionActionsTableOrderingComposer,
      $$SessionActionsTableAnnotationComposer,
      $$SessionActionsTableCreateCompanionBuilder,
      $$SessionActionsTableUpdateCompanionBuilder,
      (SessionActionRow, $$SessionActionsTableReferences),
      SessionActionRow,
      PrefetchHooks Function({bool sessionId, bool pendingDeletesRefs})
    >;
typedef $$PendingDeletesTableCreateCompanionBuilder =
    PendingDeletesCompanion Function({
      Value<int> id,
      required int actionId,
      required int sessionId,
      required String fileId,
      required String mode,
      required PendingDeleteStatus status,
      Value<String?> failureReason,
      required int sizeBytes,
      required int fileModifiedAtMs,
      Value<String?> committedMode,
      required DateTime queuedAt,
      Value<DateTime?> committedAt,
    });
typedef $$PendingDeletesTableUpdateCompanionBuilder =
    PendingDeletesCompanion Function({
      Value<int> id,
      Value<int> actionId,
      Value<int> sessionId,
      Value<String> fileId,
      Value<String> mode,
      Value<PendingDeleteStatus> status,
      Value<String?> failureReason,
      Value<int> sizeBytes,
      Value<int> fileModifiedAtMs,
      Value<String?> committedMode,
      Value<DateTime> queuedAt,
      Value<DateTime?> committedAt,
    });

final class $$PendingDeletesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PendingDeletesTable, PendingDeleteRow> {
  $$PendingDeletesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionActionsTable _actionIdTable(_$AppDatabase db) => db
      .sessionActions
      .createAlias('pending_deletes__action_id__session_actions__id');

  $$SessionActionsTableProcessedTableManager get actionId {
    final $_column = $_itemColumn<int>('action_id')!;

    final manager = $$SessionActionsTableTableManager(
      $_db,
      $_db.sessionActions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_actionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('pending_deletes__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingDeletesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingDeleteStatus,
    PendingDeleteStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get committedMode => $composableBuilder(
    column: $table.committedMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionActionsTableFilterComposer get actionId {
    final $$SessionActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actionId,
      referencedTable: $db.sessionActions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionActionsTableFilterComposer(
            $db: $db,
            $table: $db.sessionActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingDeletesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get committedMode => $composableBuilder(
    column: $table.committedMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionActionsTableOrderingComposer get actionId {
    final $$SessionActionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actionId,
      referencedTable: $db.sessionActions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionActionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessionActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingDeletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PendingDeleteStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get committedMode => $composableBuilder(
    column: $table.committedMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );

  $$SessionActionsTableAnnotationComposer get actionId {
    final $$SessionActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actionId,
      referencedTable: $db.sessionActions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingDeletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingDeletesTable,
          PendingDeleteRow,
          $$PendingDeletesTableFilterComposer,
          $$PendingDeletesTableOrderingComposer,
          $$PendingDeletesTableAnnotationComposer,
          $$PendingDeletesTableCreateCompanionBuilder,
          $$PendingDeletesTableUpdateCompanionBuilder,
          (PendingDeleteRow, $$PendingDeletesTableReferences),
          PendingDeleteRow,
          PrefetchHooks Function({bool actionId, bool sessionId})
        > {
  $$PendingDeletesTableTableManager(
    _$AppDatabase db,
    $PendingDeletesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDeletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDeletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDeletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> actionId = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<PendingDeleteStatus> status = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> fileModifiedAtMs = const Value.absent(),
                Value<String?> committedMode = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
              }) => PendingDeletesCompanion(
                id: id,
                actionId: actionId,
                sessionId: sessionId,
                fileId: fileId,
                mode: mode,
                status: status,
                failureReason: failureReason,
                sizeBytes: sizeBytes,
                fileModifiedAtMs: fileModifiedAtMs,
                committedMode: committedMode,
                queuedAt: queuedAt,
                committedAt: committedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int actionId,
                required int sessionId,
                required String fileId,
                required String mode,
                required PendingDeleteStatus status,
                Value<String?> failureReason = const Value.absent(),
                required int sizeBytes,
                required int fileModifiedAtMs,
                Value<String?> committedMode = const Value.absent(),
                required DateTime queuedAt,
                Value<DateTime?> committedAt = const Value.absent(),
              }) => PendingDeletesCompanion.insert(
                id: id,
                actionId: actionId,
                sessionId: sessionId,
                fileId: fileId,
                mode: mode,
                status: status,
                failureReason: failureReason,
                sizeBytes: sizeBytes,
                fileModifiedAtMs: fileModifiedAtMs,
                committedMode: committedMode,
                queuedAt: queuedAt,
                committedAt: committedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingDeletesTable, PendingDeleteRow>(table),
                  $$PendingDeletesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({actionId = false, sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (actionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.actionId,
                        referencedTable: $$PendingDeletesTableReferences
                            ._actionIdTable(db),
                        referencedColumn: $$PendingDeletesTableReferences
                            ._actionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$PendingDeletesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PendingDeletesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingDeletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingDeletesTable,
      PendingDeleteRow,
      $$PendingDeletesTableFilterComposer,
      $$PendingDeletesTableOrderingComposer,
      $$PendingDeletesTableAnnotationComposer,
      $$PendingDeletesTableCreateCompanionBuilder,
      $$PendingDeletesTableUpdateCompanionBuilder,
      (PendingDeleteRow, $$PendingDeletesTableReferences),
      PendingDeleteRow,
      PrefetchHooks Function({bool actionId, bool sessionId})
    >;
typedef $$PendingFolderItemsTableCreateCompanionBuilder =
    PendingFolderItemsCompanion Function({
      required String id,
      required String originalPath,
      required String storedPath,
      required String volumeId,
      required String name,
      Value<String?> mimeType,
      required int sizeBytes,
      required String originalFileId,
      required DateTime originalModifiedAt,
      required DateTime deletedAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$PendingFolderItemsTableUpdateCompanionBuilder =
    PendingFolderItemsCompanion Function({
      Value<String> id,
      Value<String> originalPath,
      Value<String> storedPath,
      Value<String> volumeId,
      Value<String> name,
      Value<String?> mimeType,
      Value<int> sizeBytes,
      Value<String> originalFileId,
      Value<DateTime> originalModifiedAt,
      Value<DateTime> deletedAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$PendingFolderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingFolderItemsTable> {
  $$PendingFolderItemsTableFilterComposer({
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

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volumeId => $composableBuilder(
    column: $table.volumeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileId => $composableBuilder(
    column: $table.originalFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get originalModifiedAt => $composableBuilder(
    column: $table.originalModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingFolderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingFolderItemsTable> {
  $$PendingFolderItemsTableOrderingComposer({
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

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeId => $composableBuilder(
    column: $table.volumeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileId => $composableBuilder(
    column: $table.originalFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get originalModifiedAt => $composableBuilder(
    column: $table.originalModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingFolderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingFolderItemsTable> {
  $$PendingFolderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volumeId =>
      $composableBuilder(column: $table.volumeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get originalFileId => $composableBuilder(
    column: $table.originalFileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get originalModifiedAt => $composableBuilder(
    column: $table.originalModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$PendingFolderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingFolderItemsTable,
          PendingFolderItemRow,
          $$PendingFolderItemsTableFilterComposer,
          $$PendingFolderItemsTableOrderingComposer,
          $$PendingFolderItemsTableAnnotationComposer,
          $$PendingFolderItemsTableCreateCompanionBuilder,
          $$PendingFolderItemsTableUpdateCompanionBuilder,
          (
            PendingFolderItemRow,
            BaseReferences<
              _$AppDatabase,
              $PendingFolderItemsTable,
              PendingFolderItemRow
            >,
          ),
          PendingFolderItemRow,
          PrefetchHooks Function()
        > {
  $$PendingFolderItemsTableTableManager(
    _$AppDatabase db,
    $PendingFolderItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingFolderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingFolderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingFolderItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String> storedPath = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> originalFileId = const Value.absent(),
                Value<DateTime> originalModifiedAt = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingFolderItemsCompanion(
                id: id,
                originalPath: originalPath,
                storedPath: storedPath,
                volumeId: volumeId,
                name: name,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalFileId: originalFileId,
                originalModifiedAt: originalModifiedAt,
                deletedAt: deletedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String originalPath,
                required String storedPath,
                required String volumeId,
                required String name,
                Value<String?> mimeType = const Value.absent(),
                required int sizeBytes,
                required String originalFileId,
                required DateTime originalModifiedAt,
                required DateTime deletedAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingFolderItemsCompanion.insert(
                id: id,
                originalPath: originalPath,
                storedPath: storedPath,
                volumeId: volumeId,
                name: name,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalFileId: originalFileId,
                originalModifiedAt: originalModifiedAt,
                deletedAt: deletedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingFolderItemsTable, PendingFolderItemRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingFolderItemsTable,
                    PendingFolderItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingFolderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingFolderItemsTable,
      PendingFolderItemRow,
      $$PendingFolderItemsTableFilterComposer,
      $$PendingFolderItemsTableOrderingComposer,
      $$PendingFolderItemsTableAnnotationComposer,
      $$PendingFolderItemsTableCreateCompanionBuilder,
      $$PendingFolderItemsTableUpdateCompanionBuilder,
      (
        PendingFolderItemRow,
        BaseReferences<
          _$AppDatabase,
          $PendingFolderItemsTable,
          PendingFolderItemRow
        >,
      ),
      PendingFolderItemRow,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String name,
  required int color,
  required DateTime createdAt,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<DateTime> createdAt,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FileTagsTable, List<FileTagRow>>
  _fileTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fileTags,
    aliasName: 'tags__id__file_tags__tag_id',
  );

  $$FileTagsTableProcessedTableManager get fileTagsRefs {
    final manager = $$FileTagsTableTableManager(
      $_db,
      $_db.fileTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fileTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fileTagsRefs(
    Expression<bool> Function($$FileTagsTableFilterComposer f) f,
  ) {
    final $$FileTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileTagsTableFilterComposer(
            $db: $db,
            $table: $db.fileTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> fileTagsRefs<T extends Object>(
    Expression<T> Function($$FileTagsTableAnnotationComposer a) f,
  ) {
    final $$FileTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.fileTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool fileTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int color,
                required DateTime createdAt,
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagRow>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fileTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fileTagsRefs) db.fileTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fileTagsRefs)
                    await $_getPrefetchedDataByColumns<
                      TagRow,
                      $TagsTable,
                      FileTagRow,
                      $FileTagsTable
                    >(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._fileTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).fileTagsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tag_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool fileTagsRefs})
    >;
typedef $$FileTagsTableCreateCompanionBuilder = FileTagsCompanion Function({
  required String fileId,
  required int tagId,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$FileTagsTableUpdateCompanionBuilder = FileTagsCompanion Function({
  Value<String> fileId,
  Value<int> tagId,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

final class $$FileTagsTableReferences
    extends BaseReferences<_$AppDatabase, $FileTagsTable, FileTagRow> {
  $$FileTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('file_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FileTagsTableFilterComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileTagsTable,
          FileTagRow,
          $$FileTagsTableFilterComposer,
          $$FileTagsTableOrderingComposer,
          $$FileTagsTableAnnotationComposer,
          $$FileTagsTableCreateCompanionBuilder,
          $$FileTagsTableUpdateCompanionBuilder,
          (FileTagRow, $$FileTagsTableReferences),
          FileTagRow,
          PrefetchHooks Function({bool tagId})
        > {
  $$FileTagsTableTableManager(_$AppDatabase db, $FileTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileTagsCompanion(
                fileId: fileId,
                tagId: tagId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required int tagId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FileTagsCompanion.insert(
                fileId: fileId,
                tagId: tagId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FileTagsTable, FileTagRow>(table),
                  $$FileTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$FileTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$FileTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FileTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileTagsTable,
      FileTagRow,
      $$FileTagsTableFilterComposer,
      $$FileTagsTableOrderingComposer,
      $$FileTagsTableAnnotationComposer,
      $$FileTagsTableCreateCompanionBuilder,
      $$FileTagsTableUpdateCompanionBuilder,
      (FileTagRow, $$FileTagsTableReferences),
      FileTagRow,
      PrefetchHooks Function({bool tagId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String fileId,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> fileId,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (
            FavoriteRow,
            BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>,
          ),
          FavoriteRow,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                fileId: fileId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                fileId: fileId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>(
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

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (
        FavoriteRow,
        BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>,
      ),
      FavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$RenameBatchesTableCreateCompanionBuilder =
    RenameBatchesCompanion Function({
      Value<int> id,
      required int sessionId,
      required RenameBatchStatus status,
      Value<String?> patternJson,
      required DateTime createdAt,
      Value<DateTime?> appliedAt,
    });
typedef $$RenameBatchesTableUpdateCompanionBuilder =
    RenameBatchesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<RenameBatchStatus> status,
      Value<String?> patternJson,
      Value<DateTime> createdAt,
      Value<DateTime?> appliedAt,
    });

final class $$RenameBatchesTableReferences
    extends BaseReferences<_$AppDatabase, $RenameBatchesTable, RenameBatchRow> {
  $$RenameBatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('rename_batches__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RenameBatchItemsTable, List<RenameBatchItemRow>>
  _renameBatchItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.renameBatchItems,
    aliasName: 'rename_batches__id__rename_batch_items__batch_id',
  );

  $$RenameBatchItemsTableProcessedTableManager get renameBatchItemsRefs {
    final manager = $$RenameBatchItemsTableTableManager(
      $_db,
      $_db.renameBatchItems,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _renameBatchItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RenameBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $RenameBatchesTable> {
  $$RenameBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RenameBatchStatus, RenameBatchStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get patternJson => $composableBuilder(
    column: $table.patternJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> renameBatchItemsRefs(
    Expression<bool> Function($$RenameBatchItemsTableFilterComposer f) f,
  ) {
    final $$RenameBatchItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renameBatchItems,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchItemsTableFilterComposer(
            $db: $db,
            $table: $db.renameBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RenameBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $RenameBatchesTable> {
  $$RenameBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternJson => $composableBuilder(
    column: $table.patternJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenameBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RenameBatchesTable> {
  $$RenameBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RenameBatchStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get patternJson => $composableBuilder(
    column: $table.patternJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> renameBatchItemsRefs<T extends Object>(
    Expression<T> Function($$RenameBatchItemsTableAnnotationComposer a) f,
  ) {
    final $$RenameBatchItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.renameBatchItems,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.renameBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RenameBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RenameBatchesTable,
          RenameBatchRow,
          $$RenameBatchesTableFilterComposer,
          $$RenameBatchesTableOrderingComposer,
          $$RenameBatchesTableAnnotationComposer,
          $$RenameBatchesTableCreateCompanionBuilder,
          $$RenameBatchesTableUpdateCompanionBuilder,
          (RenameBatchRow, $$RenameBatchesTableReferences),
          RenameBatchRow,
          PrefetchHooks Function({bool sessionId, bool renameBatchItemsRefs})
        > {
  $$RenameBatchesTableTableManager(_$AppDatabase db, $RenameBatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RenameBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RenameBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RenameBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<RenameBatchStatus> status = const Value.absent(),
                Value<String?> patternJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
              }) => RenameBatchesCompanion(
                id: id,
                sessionId: sessionId,
                status: status,
                patternJson: patternJson,
                createdAt: createdAt,
                appliedAt: appliedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required RenameBatchStatus status,
                Value<String?> patternJson = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> appliedAt = const Value.absent(),
              }) => RenameBatchesCompanion.insert(
                id: id,
                sessionId: sessionId,
                status: status,
                patternJson: patternJson,
                createdAt: createdAt,
                appliedAt: appliedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RenameBatchesTable, RenameBatchRow>(table),
                  $$RenameBatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, renameBatchItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (renameBatchItemsRefs) db.renameBatchItems,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$RenameBatchesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$RenameBatchesTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (renameBatchItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          RenameBatchRow,
                          $RenameBatchesTable,
                          RenameBatchItemRow,
                          $RenameBatchItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RenameBatchesTableReferences
                              ._renameBatchItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RenameBatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).renameBatchItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'batch_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RenameBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RenameBatchesTable,
      RenameBatchRow,
      $$RenameBatchesTableFilterComposer,
      $$RenameBatchesTableOrderingComposer,
      $$RenameBatchesTableAnnotationComposer,
      $$RenameBatchesTableCreateCompanionBuilder,
      $$RenameBatchesTableUpdateCompanionBuilder,
      (RenameBatchRow, $$RenameBatchesTableReferences),
      RenameBatchRow,
      PrefetchHooks Function({bool sessionId, bool renameBatchItemsRefs})
    >;
typedef $$RenameBatchItemsTableCreateCompanionBuilder =
    RenameBatchItemsCompanion Function({
      required int batchId,
      required String fileId,
      required int position,
      required String folderPath,
      required String originalName,
      required String currentFileId,
      required String currentName,
      Value<String?> newName,
      Value<String?> tempName,
      Value<bool> skipped,
      Value<String?> skipReason,
      Value<int> rowid,
    });
typedef $$RenameBatchItemsTableUpdateCompanionBuilder =
    RenameBatchItemsCompanion Function({
      Value<int> batchId,
      Value<String> fileId,
      Value<int> position,
      Value<String> folderPath,
      Value<String> originalName,
      Value<String> currentFileId,
      Value<String> currentName,
      Value<String?> newName,
      Value<String?> tempName,
      Value<bool> skipped,
      Value<String?> skipReason,
      Value<int> rowid,
    });

final class $$RenameBatchItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RenameBatchItemsTable,
          RenameBatchItemRow
        > {
  $$RenameBatchItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RenameBatchesTable _batchIdTable(_$AppDatabase db) => db.renameBatches
      .createAlias('rename_batch_items__batch_id__rename_batches__id');

  $$RenameBatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<int>('batch_id')!;

    final manager = $$RenameBatchesTableTableManager(
      $_db,
      $_db.renameBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RenameBatchItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RenameBatchItemsTable> {
  $$RenameBatchItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentFileId => $composableBuilder(
    column: $table.currentFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentName => $composableBuilder(
    column: $table.currentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newName => $composableBuilder(
    column: $table.newName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempName => $composableBuilder(
    column: $table.tempName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnFilters(column),
  );

  $$RenameBatchesTableFilterComposer get batchId {
    final $$RenameBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.renameBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchesTableFilterComposer(
            $db: $db,
            $table: $db.renameBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenameBatchItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RenameBatchItemsTable> {
  $$RenameBatchItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentFileId => $composableBuilder(
    column: $table.currentFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentName => $composableBuilder(
    column: $table.currentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newName => $composableBuilder(
    column: $table.newName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempName => $composableBuilder(
    column: $table.tempName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$RenameBatchesTableOrderingComposer get batchId {
    final $$RenameBatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.renameBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchesTableOrderingComposer(
            $db: $db,
            $table: $db.renameBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenameBatchItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RenameBatchItemsTable> {
  $$RenameBatchItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentFileId => $composableBuilder(
    column: $table.currentFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentName => $composableBuilder(
    column: $table.currentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get newName =>
      $composableBuilder(column: $table.newName, builder: (column) => column);

  GeneratedColumn<String> get tempName =>
      $composableBuilder(column: $table.tempName, builder: (column) => column);

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => column,
  );

  $$RenameBatchesTableAnnotationComposer get batchId {
    final $$RenameBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.renameBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RenameBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.renameBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RenameBatchItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RenameBatchItemsTable,
          RenameBatchItemRow,
          $$RenameBatchItemsTableFilterComposer,
          $$RenameBatchItemsTableOrderingComposer,
          $$RenameBatchItemsTableAnnotationComposer,
          $$RenameBatchItemsTableCreateCompanionBuilder,
          $$RenameBatchItemsTableUpdateCompanionBuilder,
          (RenameBatchItemRow, $$RenameBatchItemsTableReferences),
          RenameBatchItemRow,
          PrefetchHooks Function({bool batchId})
        > {
  $$RenameBatchItemsTableTableManager(
    _$AppDatabase db,
    $RenameBatchItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RenameBatchItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RenameBatchItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RenameBatchItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> batchId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> currentFileId = const Value.absent(),
                Value<String> currentName = const Value.absent(),
                Value<String?> newName = const Value.absent(),
                Value<String?> tempName = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RenameBatchItemsCompanion(
                batchId: batchId,
                fileId: fileId,
                position: position,
                folderPath: folderPath,
                originalName: originalName,
                currentFileId: currentFileId,
                currentName: currentName,
                newName: newName,
                tempName: tempName,
                skipped: skipped,
                skipReason: skipReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int batchId,
                required String fileId,
                required int position,
                required String folderPath,
                required String originalName,
                required String currentFileId,
                required String currentName,
                Value<String?> newName = const Value.absent(),
                Value<String?> tempName = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RenameBatchItemsCompanion.insert(
                batchId: batchId,
                fileId: fileId,
                position: position,
                folderPath: folderPath,
                originalName: originalName,
                currentFileId: currentFileId,
                currentName: currentName,
                newName: newName,
                tempName: tempName,
                skipped: skipped,
                skipReason: skipReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RenameBatchItemsTable, RenameBatchItemRow>(
                    table,
                  ),
                  $$RenameBatchItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.batchId,
                        referencedTable: $$RenameBatchItemsTableReferences
                            ._batchIdTable(db),
                        referencedColumn: $$RenameBatchItemsTableReferences
                            ._batchIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RenameBatchItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RenameBatchItemsTable,
      RenameBatchItemRow,
      $$RenameBatchItemsTableFilterComposer,
      $$RenameBatchItemsTableOrderingComposer,
      $$RenameBatchItemsTableAnnotationComposer,
      $$RenameBatchItemsTableCreateCompanionBuilder,
      $$RenameBatchItemsTableUpdateCompanionBuilder,
      (RenameBatchItemRow, $$RenameBatchItemsTableReferences),
      RenameBatchItemRow,
      PrefetchHooks Function({bool batchId})
    >;
typedef $$PresetsTableCreateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  required String name,
  required String layoutJson,
  Value<String?> filterJson,
  Value<bool> includeReviewed,
  required int sortOrder,
  required DateTime createdAt,
});
typedef $$PresetsTableUpdateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> layoutJson,
  Value<String?> filterJson,
  Value<bool> includeReviewed,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

class $$PresetsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeReviewed => $composableBuilder(
    column: $table.includeReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeReviewed => $composableBuilder(
    column: $table.includeReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeReviewed => $composableBuilder(
    column: $table.includeReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresetsTable,
          PresetRow,
          $$PresetsTableFilterComposer,
          $$PresetsTableOrderingComposer,
          $$PresetsTableAnnotationComposer,
          $$PresetsTableCreateCompanionBuilder,
          $$PresetsTableUpdateCompanionBuilder,
          (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
          PresetRow,
          PrefetchHooks Function()
        > {
  $$PresetsTableTableManager(_$AppDatabase db, $PresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> layoutJson = const Value.absent(),
                Value<String?> filterJson = const Value.absent(),
                Value<bool> includeReviewed = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PresetsCompanion(
                id: id,
                name: name,
                layoutJson: layoutJson,
                filterJson: filterJson,
                includeReviewed: includeReviewed,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String layoutJson,
                Value<String?> filterJson = const Value.absent(),
                Value<bool> includeReviewed = const Value.absent(),
                required int sortOrder,
                required DateTime createdAt,
              }) => PresetsCompanion.insert(
                id: id,
                name: name,
                layoutJson: layoutJson,
                filterJson: filterJson,
                includeReviewed: includeReviewed,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PresetsTable, PresetRow>(table),
                  BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>(
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

typedef $$PresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresetsTable,
      PresetRow,
      $$PresetsTableFilterComposer,
      $$PresetsTableOrderingComposer,
      $$PresetsTableAnnotationComposer,
      $$PresetsTableCreateCompanionBuilder,
      $$PresetsTableUpdateCompanionBuilder,
      (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
      PresetRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$MediaIndexTableTableManager get mediaIndex =>
      $$MediaIndexTableTableManager(_db, _db.mediaIndex);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionActionsTableTableManager get sessionActions =>
      $$SessionActionsTableTableManager(_db, _db.sessionActions);
  $$PendingDeletesTableTableManager get pendingDeletes =>
      $$PendingDeletesTableTableManager(_db, _db.pendingDeletes);
  $$PendingFolderItemsTableTableManager get pendingFolderItems =>
      $$PendingFolderItemsTableTableManager(_db, _db.pendingFolderItems);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$FileTagsTableTableManager get fileTags =>
      $$FileTagsTableTableManager(_db, _db.fileTags);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$RenameBatchesTableTableManager get renameBatches =>
      $$RenameBatchesTableTableManager(_db, _db.renameBatches);
  $$RenameBatchItemsTableTableManager get renameBatchItems =>
      $$RenameBatchItemsTableTableManager(_db, _db.renameBatchItems);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db, _db.presets);
}
