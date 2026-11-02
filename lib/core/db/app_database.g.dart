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
  late final GeneratedColumnWithTypeConverter<SourceBucket, int> source =
      GeneratedColumn<int>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SourceBucket>($MediaIndexTable.$convertersource);
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extensionMeta = const VerificationMeta(
    'extension',
  );
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
    'extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    source,
    hidden,
    extension,
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
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('extension')) {
      context.handle(
        _extensionMeta,
        extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta),
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
      source: $MediaIndexTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}source'],
        )!,
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      extension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension'],
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
  static JsonTypeConverter2<SourceBucket, int, int> $convertersource =
      const EnumIndexConverter<SourceBucket>(SourceBucket.values);
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

  /// B1: where the file comes from (`sourceFor`, set by the DAO on every
  /// write). intEnum stores the index: only ever APPEND values.
  final SourceBucket source;

  /// B1: dot-file, inside a dot-folder or inside a `.nomedia` folder.
  final bool hidden;

  /// B1: lower-case extension without the dot ('' = none), `extensionOf`.
  final String extension;
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
    required this.source,
    required this.hidden,
    required this.extension,
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
    {
      map['source'] = Variable<int>(
        $MediaIndexTable.$convertersource.toSql(source),
      );
    }
    map['hidden'] = Variable<bool>(hidden);
    map['extension'] = Variable<String>(extension);
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
      source: Value(source),
      hidden: Value(hidden),
      extension: Value(extension),
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
      source: $MediaIndexTable.$convertersource.fromJson(
        serializer.fromJson<int>(json['source']),
      ),
      hidden: serializer.fromJson<bool>(json['hidden']),
      extension: serializer.fromJson<String>(json['extension']),
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
      'source': serializer.toJson<int>(
        $MediaIndexTable.$convertersource.toJson(source),
      ),
      'hidden': serializer.toJson<bool>(hidden),
      'extension': serializer.toJson<String>(extension),
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
    SourceBucket? source,
    bool? hidden,
    String? extension,
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
    source: source ?? this.source,
    hidden: hidden ?? this.hidden,
    extension: extension ?? this.extension,
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
      source: data.source.present ? data.source.value : this.source,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      extension: data.extension.present ? data.extension.value : this.extension,
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
          ..write('screenshot: $screenshot, ')
          ..write('source: $source, ')
          ..write('hidden: $hidden, ')
          ..write('extension: $extension')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    source,
    hidden,
    extension,
  ]);
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
          other.screenshot == this.screenshot &&
          other.source == this.source &&
          other.hidden == this.hidden &&
          other.extension == this.extension);
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
  final Value<SourceBucket> source;
  final Value<bool> hidden;
  final Value<String> extension;
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
    this.source = const Value.absent(),
    this.hidden = const Value.absent(),
    this.extension = const Value.absent(),
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
    this.source = const Value.absent(),
    this.hidden = const Value.absent(),
    this.extension = const Value.absent(),
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
    Expression<int>? source,
    Expression<bool>? hidden,
    Expression<String>? extension,
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
      if (source != null) 'source': source,
      if (hidden != null) 'hidden': hidden,
      if (extension != null) 'extension': extension,
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
    Value<SourceBucket>? source,
    Value<bool>? hidden,
    Value<String>? extension,
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
      source: source ?? this.source,
      hidden: hidden ?? this.hidden,
      extension: extension ?? this.extension,
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
    if (source.present) {
      map['source'] = Variable<int>(
        $MediaIndexTable.$convertersource.toSql(source.value),
      );
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
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
          ..write('source: $source, ')
          ..write('hidden: $hidden, ')
          ..write('extension: $extension, ')
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
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
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
    sourceId,
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
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
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
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
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

  /// Whose files the session swipes (N8): `local`,
  /// `remote:<peerFingerprint>` or (U2) `external:<volumeId>`.
  final String sourceId;
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
    required this.sourceId,
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
    map['source_id'] = Variable<String>(sourceId);
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
      sourceId: Value(sourceId),
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
      sourceId: serializer.fromJson<String>(json['sourceId']),
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
      'sourceId': serializer.toJson<String>(sourceId),
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
    String? sourceId,
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
    sourceId: sourceId ?? this.sourceId,
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
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
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
          ..write('endedAt: $endedAt, ')
          ..write('sourceId: $sourceId')
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
    sourceId,
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
          other.endedAt == this.endedAt &&
          other.sourceId == this.sourceId);
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
  final Value<String> sourceId;
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
    this.sourceId = const Value.absent(),
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
    this.sourceId = const Value.absent(),
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
    Expression<String>? sourceId,
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
      if (sourceId != null) 'source_id': sourceId,
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
    Value<String>? sourceId,
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
      sourceId: sourceId ?? this.sourceId,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
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
          ..write('endedAt: $endedAt, ')
          ..write('sourceId: $sourceId')
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
  static const VerificationMeta _trashIdMeta = const VerificationMeta(
    'trashId',
  );
  @override
  late final GeneratedColumn<String> trashId = GeneratedColumn<String>(
    'trash_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leftTrashAtMeta = const VerificationMeta(
    'leftTrashAt',
  );
  @override
  late final GeneratedColumn<DateTime> leftTrashAt = GeneratedColumn<DateTime>(
    'left_trash_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrashExit?, String>
  leftTrashReason = GeneratedColumn<String>(
    'left_trash_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<TrashExit?>($PendingDeletesTable.$converterleftTrashReasonn);
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
    trashId,
    leftTrashAt,
    leftTrashReason,
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
    if (data.containsKey('trash_id')) {
      context.handle(
        _trashIdMeta,
        trashId.isAcceptableOrUnknown(data['trash_id']!, _trashIdMeta),
      );
    }
    if (data.containsKey('left_trash_at')) {
      context.handle(
        _leftTrashAtMeta,
        leftTrashAt.isAcceptableOrUnknown(
          data['left_trash_at']!,
          _leftTrashAtMeta,
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
      trashId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trash_id'],
      ),
      leftTrashAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}left_trash_at'],
      ),
      leftTrashReason: $PendingDeletesTable.$converterleftTrashReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}left_trash_reason'],
        ),
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
  static JsonTypeConverter2<TrashExit, String, String>
  $converterleftTrashReason = const EnumNameConverter<TrashExit>(
    TrashExit.values,
  );
  static JsonTypeConverter2<TrashExit?, String?, String?>
  $converterleftTrashReasonn = JsonTypeConverter2.asNullable(
    $converterleftTrashReason,
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

  /// P8. TrashedItem.trashId when committed to the trash; null otherwise.
  final String? trashId;

  /// P8. When the trashed file left the trash (restored or purged).
  final DateTime? leftTrashAt;
  final TrashExit? leftTrashReason;
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
    this.trashId,
    this.leftTrashAt,
    this.leftTrashReason,
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
    if (!nullToAbsent || trashId != null) {
      map['trash_id'] = Variable<String>(trashId);
    }
    if (!nullToAbsent || leftTrashAt != null) {
      map['left_trash_at'] = Variable<DateTime>(leftTrashAt);
    }
    if (!nullToAbsent || leftTrashReason != null) {
      map['left_trash_reason'] = Variable<String>(
        $PendingDeletesTable.$converterleftTrashReasonn.toSql(leftTrashReason),
      );
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
      trashId: trashId == null && nullToAbsent
          ? const Value.absent()
          : Value(trashId),
      leftTrashAt: leftTrashAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leftTrashAt),
      leftTrashReason: leftTrashReason == null && nullToAbsent
          ? const Value.absent()
          : Value(leftTrashReason),
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
      trashId: serializer.fromJson<String?>(json['trashId']),
      leftTrashAt: serializer.fromJson<DateTime?>(json['leftTrashAt']),
      leftTrashReason: $PendingDeletesTable.$converterleftTrashReasonn.fromJson(
        serializer.fromJson<String?>(json['leftTrashReason']),
      ),
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
      'trashId': serializer.toJson<String?>(trashId),
      'leftTrashAt': serializer.toJson<DateTime?>(leftTrashAt),
      'leftTrashReason': serializer.toJson<String?>(
        $PendingDeletesTable.$converterleftTrashReasonn.toJson(leftTrashReason),
      ),
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
    Value<String?> trashId = const Value.absent(),
    Value<DateTime?> leftTrashAt = const Value.absent(),
    Value<TrashExit?> leftTrashReason = const Value.absent(),
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
    trashId: trashId.present ? trashId.value : this.trashId,
    leftTrashAt: leftTrashAt.present ? leftTrashAt.value : this.leftTrashAt,
    leftTrashReason: leftTrashReason.present
        ? leftTrashReason.value
        : this.leftTrashReason,
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
      trashId: data.trashId.present ? data.trashId.value : this.trashId,
      leftTrashAt: data.leftTrashAt.present
          ? data.leftTrashAt.value
          : this.leftTrashAt,
      leftTrashReason: data.leftTrashReason.present
          ? data.leftTrashReason.value
          : this.leftTrashReason,
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
          ..write('committedAt: $committedAt, ')
          ..write('trashId: $trashId, ')
          ..write('leftTrashAt: $leftTrashAt, ')
          ..write('leftTrashReason: $leftTrashReason')
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
    trashId,
    leftTrashAt,
    leftTrashReason,
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
          other.committedAt == this.committedAt &&
          other.trashId == this.trashId &&
          other.leftTrashAt == this.leftTrashAt &&
          other.leftTrashReason == this.leftTrashReason);
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
  final Value<String?> trashId;
  final Value<DateTime?> leftTrashAt;
  final Value<TrashExit?> leftTrashReason;
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
    this.trashId = const Value.absent(),
    this.leftTrashAt = const Value.absent(),
    this.leftTrashReason = const Value.absent(),
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
    this.trashId = const Value.absent(),
    this.leftTrashAt = const Value.absent(),
    this.leftTrashReason = const Value.absent(),
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
    Expression<String>? trashId,
    Expression<DateTime>? leftTrashAt,
    Expression<String>? leftTrashReason,
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
      if (trashId != null) 'trash_id': trashId,
      if (leftTrashAt != null) 'left_trash_at': leftTrashAt,
      if (leftTrashReason != null) 'left_trash_reason': leftTrashReason,
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
    Value<String?>? trashId,
    Value<DateTime?>? leftTrashAt,
    Value<TrashExit?>? leftTrashReason,
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
      trashId: trashId ?? this.trashId,
      leftTrashAt: leftTrashAt ?? this.leftTrashAt,
      leftTrashReason: leftTrashReason ?? this.leftTrashReason,
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
    if (trashId.present) {
      map['trash_id'] = Variable<String>(trashId.value);
    }
    if (leftTrashAt.present) {
      map['left_trash_at'] = Variable<DateTime>(leftTrashAt.value);
    }
    if (leftTrashReason.present) {
      map['left_trash_reason'] = Variable<String>(
        $PendingDeletesTable.$converterleftTrashReasonn.toSql(
          leftTrashReason.value,
        ),
      );
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
          ..write('committedAt: $committedAt, ')
          ..write('trashId: $trashId, ')
          ..write('leftTrashAt: $leftTrashAt, ')
          ..write('leftTrashReason: $leftTrashReason')
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

class $ReviewedLabelsTable extends ReviewedLabels
    with TableInfo<$ReviewedLabelsTable, ReviewedLabelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewedLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<int> actionId = GeneratedColumn<int>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _presetKeyMeta = const VerificationMeta(
    'presetKey',
  );
  @override
  late final GeneratedColumn<int> presetKey = GeneratedColumn<int>(
    'preset_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _actionDetailMeta = const VerificationMeta(
    'actionDetail',
  );
  @override
  late final GeneratedColumn<String> actionDetail = GeneratedColumn<String>(
    'action_detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    actionId,
    fileId,
    presetKey,
    actionType,
    actionDetail,
    reviewedAt,
    fileModifiedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviewed_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewedLabelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('preset_key')) {
      context.handle(
        _presetKeyMeta,
        presetKey.isAcceptableOrUnknown(data['preset_key']!, _presetKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_presetKeyMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('action_detail')) {
      context.handle(
        _actionDetailMeta,
        actionDetail.isAcceptableOrUnknown(
          data['action_detail']!,
          _actionDetailMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionId};
  @override
  ReviewedLabelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewedLabelRow(
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      presetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset_key'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      actionDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_detail'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      fileModifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_modified_at_ms'],
      )!,
    );
  }

  @override
  $ReviewedLabelsTable createAlias(String alias) {
    return $ReviewedLabelsTable(attachedDatabase, alias);
  }
}

class ReviewedLabelRow extends DataClass
    implements Insertable<ReviewedLabelRow> {
  /// session_actions.id of the action that wrote it. No FK: labels outlive
  /// any future pruning of the undo log.
  final int actionId;

  /// FileRef.id after the action (re-keyed on idChanges).
  final String fileId;

  /// Preset id, 0 = Basic.
  final int presetKey;

  /// SwipeActionType.name.
  final String actionType;

  /// Folder name (move/copy) or tag name (addTag); else null.
  final String? actionDetail;
  final DateTime reviewedAt;

  /// FileRef.modifiedAt (epoch ms) when swiped. A different modified time
  /// (whole seconds) = edited = not reviewed any more.
  final int fileModifiedAtMs;
  const ReviewedLabelRow({
    required this.actionId,
    required this.fileId,
    required this.presetKey,
    required this.actionType,
    this.actionDetail,
    required this.reviewedAt,
    required this.fileModifiedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_id'] = Variable<int>(actionId);
    map['file_id'] = Variable<String>(fileId);
    map['preset_key'] = Variable<int>(presetKey);
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || actionDetail != null) {
      map['action_detail'] = Variable<String>(actionDetail);
    }
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs);
    return map;
  }

  ReviewedLabelsCompanion toCompanion(bool nullToAbsent) {
    return ReviewedLabelsCompanion(
      actionId: Value(actionId),
      fileId: Value(fileId),
      presetKey: Value(presetKey),
      actionType: Value(actionType),
      actionDetail: actionDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(actionDetail),
      reviewedAt: Value(reviewedAt),
      fileModifiedAtMs: Value(fileModifiedAtMs),
    );
  }

  factory ReviewedLabelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewedLabelRow(
      actionId: serializer.fromJson<int>(json['actionId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      presetKey: serializer.fromJson<int>(json['presetKey']),
      actionType: serializer.fromJson<String>(json['actionType']),
      actionDetail: serializer.fromJson<String?>(json['actionDetail']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      fileModifiedAtMs: serializer.fromJson<int>(json['fileModifiedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionId': serializer.toJson<int>(actionId),
      'fileId': serializer.toJson<String>(fileId),
      'presetKey': serializer.toJson<int>(presetKey),
      'actionType': serializer.toJson<String>(actionType),
      'actionDetail': serializer.toJson<String?>(actionDetail),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'fileModifiedAtMs': serializer.toJson<int>(fileModifiedAtMs),
    };
  }

  ReviewedLabelRow copyWith({
    int? actionId,
    String? fileId,
    int? presetKey,
    String? actionType,
    Value<String?> actionDetail = const Value.absent(),
    DateTime? reviewedAt,
    int? fileModifiedAtMs,
  }) => ReviewedLabelRow(
    actionId: actionId ?? this.actionId,
    fileId: fileId ?? this.fileId,
    presetKey: presetKey ?? this.presetKey,
    actionType: actionType ?? this.actionType,
    actionDetail: actionDetail.present ? actionDetail.value : this.actionDetail,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
  );
  ReviewedLabelRow copyWithCompanion(ReviewedLabelsCompanion data) {
    return ReviewedLabelRow(
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      presetKey: data.presetKey.present ? data.presetKey.value : this.presetKey,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      actionDetail: data.actionDetail.present
          ? data.actionDetail.value
          : this.actionDetail,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      fileModifiedAtMs: data.fileModifiedAtMs.present
          ? data.fileModifiedAtMs.value
          : this.fileModifiedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewedLabelRow(')
          ..write('actionId: $actionId, ')
          ..write('fileId: $fileId, ')
          ..write('presetKey: $presetKey, ')
          ..write('actionType: $actionType, ')
          ..write('actionDetail: $actionDetail, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actionId,
    fileId,
    presetKey,
    actionType,
    actionDetail,
    reviewedAt,
    fileModifiedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewedLabelRow &&
          other.actionId == this.actionId &&
          other.fileId == this.fileId &&
          other.presetKey == this.presetKey &&
          other.actionType == this.actionType &&
          other.actionDetail == this.actionDetail &&
          other.reviewedAt == this.reviewedAt &&
          other.fileModifiedAtMs == this.fileModifiedAtMs);
}

class ReviewedLabelsCompanion extends UpdateCompanion<ReviewedLabelRow> {
  final Value<int> actionId;
  final Value<String> fileId;
  final Value<int> presetKey;
  final Value<String> actionType;
  final Value<String?> actionDetail;
  final Value<DateTime> reviewedAt;
  final Value<int> fileModifiedAtMs;
  const ReviewedLabelsCompanion({
    this.actionId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.presetKey = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actionDetail = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.fileModifiedAtMs = const Value.absent(),
  });
  ReviewedLabelsCompanion.insert({
    this.actionId = const Value.absent(),
    required String fileId,
    required int presetKey,
    required String actionType,
    this.actionDetail = const Value.absent(),
    required DateTime reviewedAt,
    required int fileModifiedAtMs,
  }) : fileId = Value(fileId),
       presetKey = Value(presetKey),
       actionType = Value(actionType),
       reviewedAt = Value(reviewedAt),
       fileModifiedAtMs = Value(fileModifiedAtMs);
  static Insertable<ReviewedLabelRow> custom({
    Expression<int>? actionId,
    Expression<String>? fileId,
    Expression<int>? presetKey,
    Expression<String>? actionType,
    Expression<String>? actionDetail,
    Expression<DateTime>? reviewedAt,
    Expression<int>? fileModifiedAtMs,
  }) {
    return RawValuesInsertable({
      if (actionId != null) 'action_id': actionId,
      if (fileId != null) 'file_id': fileId,
      if (presetKey != null) 'preset_key': presetKey,
      if (actionType != null) 'action_type': actionType,
      if (actionDetail != null) 'action_detail': actionDetail,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (fileModifiedAtMs != null) 'file_modified_at_ms': fileModifiedAtMs,
    });
  }

  ReviewedLabelsCompanion copyWith({
    Value<int>? actionId,
    Value<String>? fileId,
    Value<int>? presetKey,
    Value<String>? actionType,
    Value<String?>? actionDetail,
    Value<DateTime>? reviewedAt,
    Value<int>? fileModifiedAtMs,
  }) {
    return ReviewedLabelsCompanion(
      actionId: actionId ?? this.actionId,
      fileId: fileId ?? this.fileId,
      presetKey: presetKey ?? this.presetKey,
      actionType: actionType ?? this.actionType,
      actionDetail: actionDetail ?? this.actionDetail,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionId.present) {
      map['action_id'] = Variable<int>(actionId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (presetKey.present) {
      map['preset_key'] = Variable<int>(presetKey.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (actionDetail.present) {
      map['action_detail'] = Variable<String>(actionDetail.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (fileModifiedAtMs.present) {
      map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewedLabelsCompanion(')
          ..write('actionId: $actionId, ')
          ..write('fileId: $fileId, ')
          ..write('presetKey: $presetKey, ')
          ..write('actionType: $actionType, ')
          ..write('actionDetail: $actionDetail, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs')
          ..write(')'))
        .toString();
  }
}

class $SelectionItemsTable extends SelectionItems
    with TableInfo<$SelectionItemsTable, SelectionItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [fileId, seq, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'selection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectionItemRow> instance, {
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
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
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
  SelectionItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectionItemRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $SelectionItemsTable createAlias(String alias) {
    return $SelectionItemsTable(attachedDatabase, alias);
  }
}

class SelectionItemRow extends DataClass
    implements Insertable<SelectionItemRow> {
  /// FileRef.id (re-keyed on idChanges).
  final String fileId;

  /// Insertion order ("View selected", Swipe these, actions).
  final int seq;
  final DateTime addedAt;
  const SelectionItemRow({
    required this.fileId,
    required this.seq,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['seq'] = Variable<int>(seq);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SelectionItemsCompanion toCompanion(bool nullToAbsent) {
    return SelectionItemsCompanion(
      fileId: Value(fileId),
      seq: Value(seq),
      addedAt: Value(addedAt),
    );
  }

  factory SelectionItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectionItemRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      seq: serializer.fromJson<int>(json['seq']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'seq': serializer.toJson<int>(seq),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SelectionItemRow copyWith({String? fileId, int? seq, DateTime? addedAt}) =>
      SelectionItemRow(
        fileId: fileId ?? this.fileId,
        seq: seq ?? this.seq,
        addedAt: addedAt ?? this.addedAt,
      );
  SelectionItemRow copyWithCompanion(SelectionItemsCompanion data) {
    return SelectionItemRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      seq: data.seq.present ? data.seq.value : this.seq,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectionItemRow(')
          ..write('fileId: $fileId, ')
          ..write('seq: $seq, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, seq, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectionItemRow &&
          other.fileId == this.fileId &&
          other.seq == this.seq &&
          other.addedAt == this.addedAt);
}

class SelectionItemsCompanion extends UpdateCompanion<SelectionItemRow> {
  final Value<String> fileId;
  final Value<int> seq;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const SelectionItemsCompanion({
    this.fileId = const Value.absent(),
    this.seq = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelectionItemsCompanion.insert({
    required String fileId,
    required int seq,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       seq = Value(seq),
       addedAt = Value(addedAt);
  static Insertable<SelectionItemRow> custom({
    Expression<String>? fileId,
    Expression<int>? seq,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (seq != null) 'seq': seq,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelectionItemsCompanion copyWith({
    Value<String>? fileId,
    Value<int>? seq,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return SelectionItemsCompanion(
      fileId: fileId ?? this.fileId,
      seq: seq ?? this.seq,
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
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
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
    return (StringBuffer('SelectionItemsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('seq: $seq, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SelectionSnapshotsTable extends SelectionSnapshots
    with TableInfo<$SelectionSnapshotsTable, SelectionSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelectionSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [fileId, seq, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'selection_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectionSnapshotRow> instance, {
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
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
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
  SelectionSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectionSnapshotRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $SelectionSnapshotsTable createAlias(String alias) {
    return $SelectionSnapshotsTable(attachedDatabase, alias);
  }
}

class SelectionSnapshotRow extends DataClass
    implements Insertable<SelectionSnapshotRow> {
  final String fileId;
  final int seq;
  final DateTime addedAt;
  const SelectionSnapshotRow({
    required this.fileId,
    required this.seq,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['seq'] = Variable<int>(seq);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SelectionSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SelectionSnapshotsCompanion(
      fileId: Value(fileId),
      seq: Value(seq),
      addedAt: Value(addedAt),
    );
  }

  factory SelectionSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectionSnapshotRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      seq: serializer.fromJson<int>(json['seq']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'seq': serializer.toJson<int>(seq),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SelectionSnapshotRow copyWith({
    String? fileId,
    int? seq,
    DateTime? addedAt,
  }) => SelectionSnapshotRow(
    fileId: fileId ?? this.fileId,
    seq: seq ?? this.seq,
    addedAt: addedAt ?? this.addedAt,
  );
  SelectionSnapshotRow copyWithCompanion(SelectionSnapshotsCompanion data) {
    return SelectionSnapshotRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      seq: data.seq.present ? data.seq.value : this.seq,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectionSnapshotRow(')
          ..write('fileId: $fileId, ')
          ..write('seq: $seq, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, seq, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectionSnapshotRow &&
          other.fileId == this.fileId &&
          other.seq == this.seq &&
          other.addedAt == this.addedAt);
}

class SelectionSnapshotsCompanion
    extends UpdateCompanion<SelectionSnapshotRow> {
  final Value<String> fileId;
  final Value<int> seq;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const SelectionSnapshotsCompanion({
    this.fileId = const Value.absent(),
    this.seq = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelectionSnapshotsCompanion.insert({
    required String fileId,
    required int seq,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       seq = Value(seq),
       addedAt = Value(addedAt);
  static Insertable<SelectionSnapshotRow> custom({
    Expression<String>? fileId,
    Expression<int>? seq,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (seq != null) 'seq': seq,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelectionSnapshotsCompanion copyWith({
    Value<String>? fileId,
    Value<int>? seq,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return SelectionSnapshotsCompanion(
      fileId: fileId ?? this.fileId,
      seq: seq ?? this.seq,
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
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
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
    return (StringBuffer('SelectionSnapshotsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('seq: $seq, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SwipeSourcesTable extends SwipeSources
    with TableInfo<$SwipeSourcesTable, SwipeSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SwipeSourcesTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<SwipeSourceKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SwipeSourceKind>($SwipeSourcesTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<SwipeSourceOrigin, String>
  origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SwipeSourceOrigin>($SwipeSourcesTable.$converterorigin);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
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
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupCountMeta = const VerificationMeta(
    'groupCount',
  );
  @override
  late final GeneratedColumn<int> groupCount = GeneratedColumn<int>(
    'group_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnRouteMeta = const VerificationMeta(
    'returnRoute',
  );
  @override
  late final GeneratedColumn<String> returnRoute = GeneratedColumn<String>(
    'return_route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAfterSeqMeta = const VerificationMeta(
    'openedAfterSeq',
  );
  @override
  late final GeneratedColumn<int> openedAfterSeq = GeneratedColumn<int>(
    'opened_after_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtSeqMeta = const VerificationMeta(
    'closedAtSeq',
  );
  @override
  late final GeneratedColumn<int> closedAtSeq = GeneratedColumn<int>(
    'closed_at_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    kind,
    origin,
    title,
    filterJson,
    itemCount,
    groupCount,
    returnRoute,
    openedAfterSeq,
    closedAtSeq,
    openedAt,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'swipe_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SwipeSourceRow> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('filter_json')) {
      context.handle(
        _filterJsonMeta,
        filterJson.isAcceptableOrUnknown(data['filter_json']!, _filterJsonMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    }
    if (data.containsKey('group_count')) {
      context.handle(
        _groupCountMeta,
        groupCount.isAcceptableOrUnknown(data['group_count']!, _groupCountMeta),
      );
    }
    if (data.containsKey('return_route')) {
      context.handle(
        _returnRouteMeta,
        returnRoute.isAcceptableOrUnknown(
          data['return_route']!,
          _returnRouteMeta,
        ),
      );
    }
    if (data.containsKey('opened_after_seq')) {
      context.handle(
        _openedAfterSeqMeta,
        openedAfterSeq.isAcceptableOrUnknown(
          data['opened_after_seq']!,
          _openedAfterSeqMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openedAfterSeqMeta);
    }
    if (data.containsKey('closed_at_seq')) {
      context.handle(
        _closedAtSeqMeta,
        closedAtSeq.isAcceptableOrUnknown(
          data['closed_at_seq']!,
          _closedAtSeqMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SwipeSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SwipeSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      kind: $SwipeSourcesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      origin: $SwipeSourcesTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      filterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_json'],
      ),
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      groupCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_count'],
      ),
      returnRoute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_route'],
      ),
      openedAfterSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_after_seq'],
      )!,
      closedAtSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at_seq'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $SwipeSourcesTable createAlias(String alias) {
    return $SwipeSourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SwipeSourceKind, String, String> $converterkind =
      const EnumNameConverter<SwipeSourceKind>(SwipeSourceKind.values);
  static JsonTypeConverter2<SwipeSourceOrigin, String, String>
  $converterorigin = const EnumNameConverter<SwipeSourceOrigin>(
    SwipeSourceOrigin.values,
  );
}

class SwipeSourceRow extends DataClass implements Insertable<SwipeSourceRow> {
  final int id;
  final int sessionId;
  final SwipeSourceKind kind;
  final SwipeSourceOrigin origin;

  /// Shown in the source bar as given (caller localizes it or passes user
  /// data such as a group title or the search text). 1–80 chars.
  final String title;

  /// P5 FileFilter JSON; set only for kind = filter.
  final String? filterJson;

  /// Files stored in swipe_source_items (0 for filter sources).
  final int itemCount;

  /// Number of groups (kind = groups only).
  final int? groupCount;

  /// go_router location for "Back to …" when the source is finished.
  final String? returnRoute;

  /// Highest session_actions.seq when opened (0 = none yet).
  final int openedAfterSeq;

  /// Highest seq when closed; null while open.
  final int? closedAtSeq;
  final DateTime openedAt;
  final DateTime? closedAt;
  const SwipeSourceRow({
    required this.id,
    required this.sessionId,
    required this.kind,
    required this.origin,
    required this.title,
    this.filterJson,
    required this.itemCount,
    this.groupCount,
    this.returnRoute,
    required this.openedAfterSeq,
    this.closedAtSeq,
    required this.openedAt,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    {
      map['kind'] = Variable<String>(
        $SwipeSourcesTable.$converterkind.toSql(kind),
      );
    }
    {
      map['origin'] = Variable<String>(
        $SwipeSourcesTable.$converterorigin.toSql(origin),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || filterJson != null) {
      map['filter_json'] = Variable<String>(filterJson);
    }
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || groupCount != null) {
      map['group_count'] = Variable<int>(groupCount);
    }
    if (!nullToAbsent || returnRoute != null) {
      map['return_route'] = Variable<String>(returnRoute);
    }
    map['opened_after_seq'] = Variable<int>(openedAfterSeq);
    if (!nullToAbsent || closedAtSeq != null) {
      map['closed_at_seq'] = Variable<int>(closedAtSeq);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  SwipeSourcesCompanion toCompanion(bool nullToAbsent) {
    return SwipeSourcesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kind: Value(kind),
      origin: Value(origin),
      title: Value(title),
      filterJson: filterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(filterJson),
      itemCount: Value(itemCount),
      groupCount: groupCount == null && nullToAbsent
          ? const Value.absent()
          : Value(groupCount),
      returnRoute: returnRoute == null && nullToAbsent
          ? const Value.absent()
          : Value(returnRoute),
      openedAfterSeq: Value(openedAfterSeq),
      closedAtSeq: closedAtSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAtSeq),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory SwipeSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SwipeSourceRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      kind: $SwipeSourcesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      origin: $SwipeSourcesTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      title: serializer.fromJson<String>(json['title']),
      filterJson: serializer.fromJson<String?>(json['filterJson']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      groupCount: serializer.fromJson<int?>(json['groupCount']),
      returnRoute: serializer.fromJson<String?>(json['returnRoute']),
      openedAfterSeq: serializer.fromJson<int>(json['openedAfterSeq']),
      closedAtSeq: serializer.fromJson<int?>(json['closedAtSeq']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'kind': serializer.toJson<String>(
        $SwipeSourcesTable.$converterkind.toJson(kind),
      ),
      'origin': serializer.toJson<String>(
        $SwipeSourcesTable.$converterorigin.toJson(origin),
      ),
      'title': serializer.toJson<String>(title),
      'filterJson': serializer.toJson<String?>(filterJson),
      'itemCount': serializer.toJson<int>(itemCount),
      'groupCount': serializer.toJson<int?>(groupCount),
      'returnRoute': serializer.toJson<String?>(returnRoute),
      'openedAfterSeq': serializer.toJson<int>(openedAfterSeq),
      'closedAtSeq': serializer.toJson<int?>(closedAtSeq),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  SwipeSourceRow copyWith({
    int? id,
    int? sessionId,
    SwipeSourceKind? kind,
    SwipeSourceOrigin? origin,
    String? title,
    Value<String?> filterJson = const Value.absent(),
    int? itemCount,
    Value<int?> groupCount = const Value.absent(),
    Value<String?> returnRoute = const Value.absent(),
    int? openedAfterSeq,
    Value<int?> closedAtSeq = const Value.absent(),
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => SwipeSourceRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    kind: kind ?? this.kind,
    origin: origin ?? this.origin,
    title: title ?? this.title,
    filterJson: filterJson.present ? filterJson.value : this.filterJson,
    itemCount: itemCount ?? this.itemCount,
    groupCount: groupCount.present ? groupCount.value : this.groupCount,
    returnRoute: returnRoute.present ? returnRoute.value : this.returnRoute,
    openedAfterSeq: openedAfterSeq ?? this.openedAfterSeq,
    closedAtSeq: closedAtSeq.present ? closedAtSeq.value : this.closedAtSeq,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  SwipeSourceRow copyWithCompanion(SwipeSourcesCompanion data) {
    return SwipeSourceRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      origin: data.origin.present ? data.origin.value : this.origin,
      title: data.title.present ? data.title.value : this.title,
      filterJson: data.filterJson.present
          ? data.filterJson.value
          : this.filterJson,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      groupCount: data.groupCount.present
          ? data.groupCount.value
          : this.groupCount,
      returnRoute: data.returnRoute.present
          ? data.returnRoute.value
          : this.returnRoute,
      openedAfterSeq: data.openedAfterSeq.present
          ? data.openedAfterSeq.value
          : this.openedAfterSeq,
      closedAtSeq: data.closedAtSeq.present
          ? data.closedAtSeq.value
          : this.closedAtSeq,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SwipeSourceRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('origin: $origin, ')
          ..write('title: $title, ')
          ..write('filterJson: $filterJson, ')
          ..write('itemCount: $itemCount, ')
          ..write('groupCount: $groupCount, ')
          ..write('returnRoute: $returnRoute, ')
          ..write('openedAfterSeq: $openedAfterSeq, ')
          ..write('closedAtSeq: $closedAtSeq, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    kind,
    origin,
    title,
    filterJson,
    itemCount,
    groupCount,
    returnRoute,
    openedAfterSeq,
    closedAtSeq,
    openedAt,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwipeSourceRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.origin == this.origin &&
          other.title == this.title &&
          other.filterJson == this.filterJson &&
          other.itemCount == this.itemCount &&
          other.groupCount == this.groupCount &&
          other.returnRoute == this.returnRoute &&
          other.openedAfterSeq == this.openedAfterSeq &&
          other.closedAtSeq == this.closedAtSeq &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt);
}

class SwipeSourcesCompanion extends UpdateCompanion<SwipeSourceRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<SwipeSourceKind> kind;
  final Value<SwipeSourceOrigin> origin;
  final Value<String> title;
  final Value<String?> filterJson;
  final Value<int> itemCount;
  final Value<int?> groupCount;
  final Value<String?> returnRoute;
  final Value<int> openedAfterSeq;
  final Value<int?> closedAtSeq;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  const SwipeSourcesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.origin = const Value.absent(),
    this.title = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.groupCount = const Value.absent(),
    this.returnRoute = const Value.absent(),
    this.openedAfterSeq = const Value.absent(),
    this.closedAtSeq = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
  });
  SwipeSourcesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required SwipeSourceKind kind,
    required SwipeSourceOrigin origin,
    required String title,
    this.filterJson = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.groupCount = const Value.absent(),
    this.returnRoute = const Value.absent(),
    required int openedAfterSeq,
    this.closedAtSeq = const Value.absent(),
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       kind = Value(kind),
       origin = Value(origin),
       title = Value(title),
       openedAfterSeq = Value(openedAfterSeq),
       openedAt = Value(openedAt);
  static Insertable<SwipeSourceRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? kind,
    Expression<String>? origin,
    Expression<String>? title,
    Expression<String>? filterJson,
    Expression<int>? itemCount,
    Expression<int>? groupCount,
    Expression<String>? returnRoute,
    Expression<int>? openedAfterSeq,
    Expression<int>? closedAtSeq,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (origin != null) 'origin': origin,
      if (title != null) 'title': title,
      if (filterJson != null) 'filter_json': filterJson,
      if (itemCount != null) 'item_count': itemCount,
      if (groupCount != null) 'group_count': groupCount,
      if (returnRoute != null) 'return_route': returnRoute,
      if (openedAfterSeq != null) 'opened_after_seq': openedAfterSeq,
      if (closedAtSeq != null) 'closed_at_seq': closedAtSeq,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
    });
  }

  SwipeSourcesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<SwipeSourceKind>? kind,
    Value<SwipeSourceOrigin>? origin,
    Value<String>? title,
    Value<String?>? filterJson,
    Value<int>? itemCount,
    Value<int?>? groupCount,
    Value<String?>? returnRoute,
    Value<int>? openedAfterSeq,
    Value<int?>? closedAtSeq,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
  }) {
    return SwipeSourcesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      origin: origin ?? this.origin,
      title: title ?? this.title,
      filterJson: filterJson ?? this.filterJson,
      itemCount: itemCount ?? this.itemCount,
      groupCount: groupCount ?? this.groupCount,
      returnRoute: returnRoute ?? this.returnRoute,
      openedAfterSeq: openedAfterSeq ?? this.openedAfterSeq,
      closedAtSeq: closedAtSeq ?? this.closedAtSeq,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SwipeSourcesTable.$converterkind.toSql(kind.value),
      );
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $SwipeSourcesTable.$converterorigin.toSql(origin.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filterJson.present) {
      map['filter_json'] = Variable<String>(filterJson.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (groupCount.present) {
      map['group_count'] = Variable<int>(groupCount.value);
    }
    if (returnRoute.present) {
      map['return_route'] = Variable<String>(returnRoute.value);
    }
    if (openedAfterSeq.present) {
      map['opened_after_seq'] = Variable<int>(openedAfterSeq.value);
    }
    if (closedAtSeq.present) {
      map['closed_at_seq'] = Variable<int>(closedAtSeq.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SwipeSourcesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('origin: $origin, ')
          ..write('title: $title, ')
          ..write('filterJson: $filterJson, ')
          ..write('itemCount: $itemCount, ')
          ..write('groupCount: $groupCount, ')
          ..write('returnRoute: $returnRoute, ')
          ..write('openedAfterSeq: $openedAfterSeq, ')
          ..write('closedAtSeq: $closedAtSeq, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }
}

class $SwipeSourceItemsTable extends SwipeSourceItems
    with TableInfo<$SwipeSourceItemsTable, SwipeSourceItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SwipeSourceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES swipe_sources (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIndexMeta = const VerificationMeta(
    'groupIndex',
  );
  @override
  late final GeneratedColumn<int> groupIndex = GeneratedColumn<int>(
    'group_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    position,
    fileId,
    groupIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'swipe_source_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SwipeSourceItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('group_index')) {
      context.handle(
        _groupIndexMeta,
        groupIndex.isAcceptableOrUnknown(data['group_index']!, _groupIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, position};
  @override
  SwipeSourceItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SwipeSourceItemRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      groupIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_index'],
      ),
    );
  }

  @override
  $SwipeSourceItemsTable createAlias(String alias) {
    return $SwipeSourceItemsTable(attachedDatabase, alias);
  }
}

class SwipeSourceItemRow extends DataClass
    implements Insertable<SwipeSourceItemRow> {
  final int sourceId;

  /// 0..n-1 in the caller's order.
  final int position;
  final String fileId;

  /// 0-based group (kind = groups); null otherwise.
  final int? groupIndex;
  const SwipeSourceItemRow({
    required this.sourceId,
    required this.position,
    required this.fileId,
    this.groupIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['position'] = Variable<int>(position);
    map['file_id'] = Variable<String>(fileId);
    if (!nullToAbsent || groupIndex != null) {
      map['group_index'] = Variable<int>(groupIndex);
    }
    return map;
  }

  SwipeSourceItemsCompanion toCompanion(bool nullToAbsent) {
    return SwipeSourceItemsCompanion(
      sourceId: Value(sourceId),
      position: Value(position),
      fileId: Value(fileId),
      groupIndex: groupIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(groupIndex),
    );
  }

  factory SwipeSourceItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SwipeSourceItemRow(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      position: serializer.fromJson<int>(json['position']),
      fileId: serializer.fromJson<String>(json['fileId']),
      groupIndex: serializer.fromJson<int?>(json['groupIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'position': serializer.toJson<int>(position),
      'fileId': serializer.toJson<String>(fileId),
      'groupIndex': serializer.toJson<int?>(groupIndex),
    };
  }

  SwipeSourceItemRow copyWith({
    int? sourceId,
    int? position,
    String? fileId,
    Value<int?> groupIndex = const Value.absent(),
  }) => SwipeSourceItemRow(
    sourceId: sourceId ?? this.sourceId,
    position: position ?? this.position,
    fileId: fileId ?? this.fileId,
    groupIndex: groupIndex.present ? groupIndex.value : this.groupIndex,
  );
  SwipeSourceItemRow copyWithCompanion(SwipeSourceItemsCompanion data) {
    return SwipeSourceItemRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      position: data.position.present ? data.position.value : this.position,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      groupIndex: data.groupIndex.present
          ? data.groupIndex.value
          : this.groupIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SwipeSourceItemRow(')
          ..write('sourceId: $sourceId, ')
          ..write('position: $position, ')
          ..write('fileId: $fileId, ')
          ..write('groupIndex: $groupIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, position, fileId, groupIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwipeSourceItemRow &&
          other.sourceId == this.sourceId &&
          other.position == this.position &&
          other.fileId == this.fileId &&
          other.groupIndex == this.groupIndex);
}

class SwipeSourceItemsCompanion extends UpdateCompanion<SwipeSourceItemRow> {
  final Value<int> sourceId;
  final Value<int> position;
  final Value<String> fileId;
  final Value<int?> groupIndex;
  final Value<int> rowid;
  const SwipeSourceItemsCompanion({
    this.sourceId = const Value.absent(),
    this.position = const Value.absent(),
    this.fileId = const Value.absent(),
    this.groupIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SwipeSourceItemsCompanion.insert({
    required int sourceId,
    required int position,
    required String fileId,
    this.groupIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       position = Value(position),
       fileId = Value(fileId);
  static Insertable<SwipeSourceItemRow> custom({
    Expression<int>? sourceId,
    Expression<int>? position,
    Expression<String>? fileId,
    Expression<int>? groupIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (position != null) 'position': position,
      if (fileId != null) 'file_id': fileId,
      if (groupIndex != null) 'group_index': groupIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SwipeSourceItemsCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? position,
    Value<String>? fileId,
    Value<int?>? groupIndex,
    Value<int>? rowid,
  }) {
    return SwipeSourceItemsCompanion(
      sourceId: sourceId ?? this.sourceId,
      position: position ?? this.position,
      fileId: fileId ?? this.fileId,
      groupIndex: groupIndex ?? this.groupIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (groupIndex.present) {
      map['group_index'] = Variable<int>(groupIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SwipeSourceItemsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('position: $position, ')
          ..write('fileId: $fileId, ')
          ..write('groupIndex: $groupIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageSignalsTable extends ImageSignals
    with TableInfo<$ImageSignalsTable, ImageSignalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageSignalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SignalStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SignalStatus>($ImageSignalsTable.$converterstatus);
  static const VerificationMeta _dHashMeta = const VerificationMeta('dHash');
  @override
  late final GeneratedColumn<int> dHash = GeneratedColumn<int>(
    'd_hash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blurScoreMeta = const VerificationMeta(
    'blurScore',
  );
  @override
  late final GeneratedColumn<double> blurScore = GeneratedColumn<double>(
    'blur_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
  static const VerificationMeta _algoVersionMeta = const VerificationMeta(
    'algoVersion',
  );
  @override
  late final GeneratedColumn<int> algoVersion = GeneratedColumn<int>(
    'algo_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    status,
    dHash,
    blurScore,
    fileModifiedAtMs,
    algoVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_signals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageSignalRow> instance, {
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
    if (data.containsKey('d_hash')) {
      context.handle(
        _dHashMeta,
        dHash.isAcceptableOrUnknown(data['d_hash']!, _dHashMeta),
      );
    }
    if (data.containsKey('blur_score')) {
      context.handle(
        _blurScoreMeta,
        blurScore.isAcceptableOrUnknown(data['blur_score']!, _blurScoreMeta),
      );
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
    if (data.containsKey('algo_version')) {
      context.handle(
        _algoVersionMeta,
        algoVersion.isAcceptableOrUnknown(
          data['algo_version']!,
          _algoVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algoVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  ImageSignalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageSignalRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      status: $ImageSignalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      dHash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}d_hash'],
      ),
      blurScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blur_score'],
      ),
      fileModifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_modified_at_ms'],
      )!,
      algoVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}algo_version'],
      )!,
    );
  }

  @override
  $ImageSignalsTable createAlias(String alias) {
    return $ImageSignalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SignalStatus, String, String> $converterstatus =
      const EnumNameConverter<SignalStatus>(SignalStatus.values);
}

class ImageSignalRow extends DataClass implements Insertable<ImageSignalRow> {
  final String fileId;
  final SignalStatus status;
  final int? dHash;
  final double? blurScore;

  /// = media_index.modified_at_ms when computed (ms, not drift DateTime,
  /// which stores seconds and would make every row look stale).
  final int fileModifiedAtMs;
  final int algoVersion;
  const ImageSignalRow({
    required this.fileId,
    required this.status,
    this.dHash,
    this.blurScore,
    required this.fileModifiedAtMs,
    required this.algoVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    {
      map['status'] = Variable<String>(
        $ImageSignalsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || dHash != null) {
      map['d_hash'] = Variable<int>(dHash);
    }
    if (!nullToAbsent || blurScore != null) {
      map['blur_score'] = Variable<double>(blurScore);
    }
    map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs);
    map['algo_version'] = Variable<int>(algoVersion);
    return map;
  }

  ImageSignalsCompanion toCompanion(bool nullToAbsent) {
    return ImageSignalsCompanion(
      fileId: Value(fileId),
      status: Value(status),
      dHash: dHash == null && nullToAbsent
          ? const Value.absent()
          : Value(dHash),
      blurScore: blurScore == null && nullToAbsent
          ? const Value.absent()
          : Value(blurScore),
      fileModifiedAtMs: Value(fileModifiedAtMs),
      algoVersion: Value(algoVersion),
    );
  }

  factory ImageSignalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageSignalRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      status: $ImageSignalsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      dHash: serializer.fromJson<int?>(json['dHash']),
      blurScore: serializer.fromJson<double?>(json['blurScore']),
      fileModifiedAtMs: serializer.fromJson<int>(json['fileModifiedAtMs']),
      algoVersion: serializer.fromJson<int>(json['algoVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'status': serializer.toJson<String>(
        $ImageSignalsTable.$converterstatus.toJson(status),
      ),
      'dHash': serializer.toJson<int?>(dHash),
      'blurScore': serializer.toJson<double?>(blurScore),
      'fileModifiedAtMs': serializer.toJson<int>(fileModifiedAtMs),
      'algoVersion': serializer.toJson<int>(algoVersion),
    };
  }

  ImageSignalRow copyWith({
    String? fileId,
    SignalStatus? status,
    Value<int?> dHash = const Value.absent(),
    Value<double?> blurScore = const Value.absent(),
    int? fileModifiedAtMs,
    int? algoVersion,
  }) => ImageSignalRow(
    fileId: fileId ?? this.fileId,
    status: status ?? this.status,
    dHash: dHash.present ? dHash.value : this.dHash,
    blurScore: blurScore.present ? blurScore.value : this.blurScore,
    fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
    algoVersion: algoVersion ?? this.algoVersion,
  );
  ImageSignalRow copyWithCompanion(ImageSignalsCompanion data) {
    return ImageSignalRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      status: data.status.present ? data.status.value : this.status,
      dHash: data.dHash.present ? data.dHash.value : this.dHash,
      blurScore: data.blurScore.present ? data.blurScore.value : this.blurScore,
      fileModifiedAtMs: data.fileModifiedAtMs.present
          ? data.fileModifiedAtMs.value
          : this.fileModifiedAtMs,
      algoVersion: data.algoVersion.present
          ? data.algoVersion.value
          : this.algoVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageSignalRow(')
          ..write('fileId: $fileId, ')
          ..write('status: $status, ')
          ..write('dHash: $dHash, ')
          ..write('blurScore: $blurScore, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('algoVersion: $algoVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    status,
    dHash,
    blurScore,
    fileModifiedAtMs,
    algoVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageSignalRow &&
          other.fileId == this.fileId &&
          other.status == this.status &&
          other.dHash == this.dHash &&
          other.blurScore == this.blurScore &&
          other.fileModifiedAtMs == this.fileModifiedAtMs &&
          other.algoVersion == this.algoVersion);
}

class ImageSignalsCompanion extends UpdateCompanion<ImageSignalRow> {
  final Value<String> fileId;
  final Value<SignalStatus> status;
  final Value<int?> dHash;
  final Value<double?> blurScore;
  final Value<int> fileModifiedAtMs;
  final Value<int> algoVersion;
  final Value<int> rowid;
  const ImageSignalsCompanion({
    this.fileId = const Value.absent(),
    this.status = const Value.absent(),
    this.dHash = const Value.absent(),
    this.blurScore = const Value.absent(),
    this.fileModifiedAtMs = const Value.absent(),
    this.algoVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageSignalsCompanion.insert({
    required String fileId,
    required SignalStatus status,
    this.dHash = const Value.absent(),
    this.blurScore = const Value.absent(),
    required int fileModifiedAtMs,
    required int algoVersion,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       status = Value(status),
       fileModifiedAtMs = Value(fileModifiedAtMs),
       algoVersion = Value(algoVersion);
  static Insertable<ImageSignalRow> custom({
    Expression<String>? fileId,
    Expression<String>? status,
    Expression<int>? dHash,
    Expression<double>? blurScore,
    Expression<int>? fileModifiedAtMs,
    Expression<int>? algoVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (status != null) 'status': status,
      if (dHash != null) 'd_hash': dHash,
      if (blurScore != null) 'blur_score': blurScore,
      if (fileModifiedAtMs != null) 'file_modified_at_ms': fileModifiedAtMs,
      if (algoVersion != null) 'algo_version': algoVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageSignalsCompanion copyWith({
    Value<String>? fileId,
    Value<SignalStatus>? status,
    Value<int?>? dHash,
    Value<double?>? blurScore,
    Value<int>? fileModifiedAtMs,
    Value<int>? algoVersion,
    Value<int>? rowid,
  }) {
    return ImageSignalsCompanion(
      fileId: fileId ?? this.fileId,
      status: status ?? this.status,
      dHash: dHash ?? this.dHash,
      blurScore: blurScore ?? this.blurScore,
      fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
      algoVersion: algoVersion ?? this.algoVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ImageSignalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (dHash.present) {
      map['d_hash'] = Variable<int>(dHash.value);
    }
    if (blurScore.present) {
      map['blur_score'] = Variable<double>(blurScore.value);
    }
    if (fileModifiedAtMs.present) {
      map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs.value);
    }
    if (algoVersion.present) {
      map['algo_version'] = Variable<int>(algoVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageSignalsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('status: $status, ')
          ..write('dHash: $dHash, ')
          ..write('blurScore: $blurScore, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('algoVersion: $algoVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SimilarGroupsTable extends SimilarGroups
    with TableInfo<$SimilarGroupsTable, SimilarGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimilarGroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _suggestedFileIdMeta = const VerificationMeta(
    'suggestedFileId',
  );
  @override
  late final GeneratedColumn<String> suggestedFileId = GeneratedColumn<String>(
    'suggested_file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    suggestedFileId,
    memberCount,
    sortDateMs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'similar_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimilarGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('suggested_file_id')) {
      context.handle(
        _suggestedFileIdMeta,
        suggestedFileId.isAcceptableOrUnknown(
          data['suggested_file_id']!,
          _suggestedFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_suggestedFileIdMeta);
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memberCountMeta);
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
  SimilarGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimilarGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      suggestedFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_file_id'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      sortDateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_date_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SimilarGroupsTable createAlias(String alias) {
    return $SimilarGroupsTable(attachedDatabase, alias);
  }
}

class SimilarGroupRow extends DataClass implements Insertable<SimilarGroupRow> {
  final int id;
  final String suggestedFileId;
  final int memberCount;

  /// Newest member's sort_date_ms (list order: newest groups first).
  final int sortDateMs;
  final DateTime createdAt;
  const SimilarGroupRow({
    required this.id,
    required this.suggestedFileId,
    required this.memberCount,
    required this.sortDateMs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['suggested_file_id'] = Variable<String>(suggestedFileId);
    map['member_count'] = Variable<int>(memberCount);
    map['sort_date_ms'] = Variable<int>(sortDateMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SimilarGroupsCompanion toCompanion(bool nullToAbsent) {
    return SimilarGroupsCompanion(
      id: Value(id),
      suggestedFileId: Value(suggestedFileId),
      memberCount: Value(memberCount),
      sortDateMs: Value(sortDateMs),
      createdAt: Value(createdAt),
    );
  }

  factory SimilarGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimilarGroupRow(
      id: serializer.fromJson<int>(json['id']),
      suggestedFileId: serializer.fromJson<String>(json['suggestedFileId']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      sortDateMs: serializer.fromJson<int>(json['sortDateMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'suggestedFileId': serializer.toJson<String>(suggestedFileId),
      'memberCount': serializer.toJson<int>(memberCount),
      'sortDateMs': serializer.toJson<int>(sortDateMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SimilarGroupRow copyWith({
    int? id,
    String? suggestedFileId,
    int? memberCount,
    int? sortDateMs,
    DateTime? createdAt,
  }) => SimilarGroupRow(
    id: id ?? this.id,
    suggestedFileId: suggestedFileId ?? this.suggestedFileId,
    memberCount: memberCount ?? this.memberCount,
    sortDateMs: sortDateMs ?? this.sortDateMs,
    createdAt: createdAt ?? this.createdAt,
  );
  SimilarGroupRow copyWithCompanion(SimilarGroupsCompanion data) {
    return SimilarGroupRow(
      id: data.id.present ? data.id.value : this.id,
      suggestedFileId: data.suggestedFileId.present
          ? data.suggestedFileId.value
          : this.suggestedFileId,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      sortDateMs: data.sortDateMs.present
          ? data.sortDateMs.value
          : this.sortDateMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimilarGroupRow(')
          ..write('id: $id, ')
          ..write('suggestedFileId: $suggestedFileId, ')
          ..write('memberCount: $memberCount, ')
          ..write('sortDateMs: $sortDateMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, suggestedFileId, memberCount, sortDateMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimilarGroupRow &&
          other.id == this.id &&
          other.suggestedFileId == this.suggestedFileId &&
          other.memberCount == this.memberCount &&
          other.sortDateMs == this.sortDateMs &&
          other.createdAt == this.createdAt);
}

class SimilarGroupsCompanion extends UpdateCompanion<SimilarGroupRow> {
  final Value<int> id;
  final Value<String> suggestedFileId;
  final Value<int> memberCount;
  final Value<int> sortDateMs;
  final Value<DateTime> createdAt;
  const SimilarGroupsCompanion({
    this.id = const Value.absent(),
    this.suggestedFileId = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.sortDateMs = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SimilarGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String suggestedFileId,
    required int memberCount,
    required int sortDateMs,
    required DateTime createdAt,
  }) : suggestedFileId = Value(suggestedFileId),
       memberCount = Value(memberCount),
       sortDateMs = Value(sortDateMs),
       createdAt = Value(createdAt);
  static Insertable<SimilarGroupRow> custom({
    Expression<int>? id,
    Expression<String>? suggestedFileId,
    Expression<int>? memberCount,
    Expression<int>? sortDateMs,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (suggestedFileId != null) 'suggested_file_id': suggestedFileId,
      if (memberCount != null) 'member_count': memberCount,
      if (sortDateMs != null) 'sort_date_ms': sortDateMs,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SimilarGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? suggestedFileId,
    Value<int>? memberCount,
    Value<int>? sortDateMs,
    Value<DateTime>? createdAt,
  }) {
    return SimilarGroupsCompanion(
      id: id ?? this.id,
      suggestedFileId: suggestedFileId ?? this.suggestedFileId,
      memberCount: memberCount ?? this.memberCount,
      sortDateMs: sortDateMs ?? this.sortDateMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (suggestedFileId.present) {
      map['suggested_file_id'] = Variable<String>(suggestedFileId.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (sortDateMs.present) {
      map['sort_date_ms'] = Variable<int>(sortDateMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimilarGroupsCompanion(')
          ..write('id: $id, ')
          ..write('suggestedFileId: $suggestedFileId, ')
          ..write('memberCount: $memberCount, ')
          ..write('sortDateMs: $sortDateMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SimilarGroupItemsTable extends SimilarGroupItems
    with TableInfo<$SimilarGroupItemsTable, SimilarGroupItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimilarGroupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES similar_groups (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [groupId, fileId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'similar_group_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimilarGroupItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, fileId};
  @override
  SimilarGroupItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimilarGroupItemRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SimilarGroupItemsTable createAlias(String alias) {
    return $SimilarGroupItemsTable(attachedDatabase, alias);
  }
}

class SimilarGroupItemRow extends DataClass
    implements Insertable<SimilarGroupItemRow> {
  final int groupId;
  final String fileId;

  /// 0 = suggested best, then by compareBest order.
  final int position;
  const SimilarGroupItemRow({
    required this.groupId,
    required this.fileId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['file_id'] = Variable<String>(fileId);
    map['position'] = Variable<int>(position);
    return map;
  }

  SimilarGroupItemsCompanion toCompanion(bool nullToAbsent) {
    return SimilarGroupItemsCompanion(
      groupId: Value(groupId),
      fileId: Value(fileId),
      position: Value(position),
    );
  }

  factory SimilarGroupItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimilarGroupItemRow(
      groupId: serializer.fromJson<int>(json['groupId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'fileId': serializer.toJson<String>(fileId),
      'position': serializer.toJson<int>(position),
    };
  }

  SimilarGroupItemRow copyWith({int? groupId, String? fileId, int? position}) =>
      SimilarGroupItemRow(
        groupId: groupId ?? this.groupId,
        fileId: fileId ?? this.fileId,
        position: position ?? this.position,
      );
  SimilarGroupItemRow copyWithCompanion(SimilarGroupItemsCompanion data) {
    return SimilarGroupItemRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimilarGroupItemRow(')
          ..write('groupId: $groupId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, fileId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimilarGroupItemRow &&
          other.groupId == this.groupId &&
          other.fileId == this.fileId &&
          other.position == this.position);
}

class SimilarGroupItemsCompanion extends UpdateCompanion<SimilarGroupItemRow> {
  final Value<int> groupId;
  final Value<String> fileId;
  final Value<int> position;
  final Value<int> rowid;
  const SimilarGroupItemsCompanion({
    this.groupId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SimilarGroupItemsCompanion.insert({
    required int groupId,
    required String fileId,
    required int position,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       fileId = Value(fileId),
       position = Value(position);
  static Insertable<SimilarGroupItemRow> custom({
    Expression<int>? groupId,
    Expression<String>? fileId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (fileId != null) 'file_id': fileId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SimilarGroupItemsCompanion copyWith({
    Value<int>? groupId,
    Value<String>? fileId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SimilarGroupItemsCompanion(
      groupId: groupId ?? this.groupId,
      fileId: fileId ?? this.fileId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimilarGroupItemsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SimilarDismissedTable extends SimilarDismissed
    with TableInfo<$SimilarDismissedTable, SimilarDismissedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimilarDismissedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dismissedAtMeta = const VerificationMeta(
    'dismissedAt',
  );
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
    'dismissed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, dismissedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'similar_dismissed';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimilarDismissedRow> instance, {
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
    if (data.containsKey('dismissed_at')) {
      context.handle(
        _dismissedAtMeta,
        dismissedAt.isAcceptableOrUnknown(
          data['dismissed_at']!,
          _dismissedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dismissedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  SimilarDismissedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimilarDismissedRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      dismissedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dismissed_at'],
      )!,
    );
  }

  @override
  $SimilarDismissedTable createAlias(String alias) {
    return $SimilarDismissedTable(attachedDatabase, alias);
  }
}

class SimilarDismissedRow extends DataClass
    implements Insertable<SimilarDismissedRow> {
  final String fileId;
  final DateTime dismissedAt;
  const SimilarDismissedRow({required this.fileId, required this.dismissedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    return map;
  }

  SimilarDismissedCompanion toCompanion(bool nullToAbsent) {
    return SimilarDismissedCompanion(
      fileId: Value(fileId),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory SimilarDismissedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimilarDismissedRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      dismissedAt: serializer.fromJson<DateTime>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'dismissedAt': serializer.toJson<DateTime>(dismissedAt),
    };
  }

  SimilarDismissedRow copyWith({String? fileId, DateTime? dismissedAt}) =>
      SimilarDismissedRow(
        fileId: fileId ?? this.fileId,
        dismissedAt: dismissedAt ?? this.dismissedAt,
      );
  SimilarDismissedRow copyWithCompanion(SimilarDismissedCompanion data) {
    return SimilarDismissedRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimilarDismissedRow(')
          ..write('fileId: $fileId, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimilarDismissedRow &&
          other.fileId == this.fileId &&
          other.dismissedAt == this.dismissedAt);
}

class SimilarDismissedCompanion extends UpdateCompanion<SimilarDismissedRow> {
  final Value<String> fileId;
  final Value<DateTime> dismissedAt;
  final Value<int> rowid;
  const SimilarDismissedCompanion({
    this.fileId = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SimilarDismissedCompanion.insert({
    required String fileId,
    required DateTime dismissedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       dismissedAt = Value(dismissedAt);
  static Insertable<SimilarDismissedRow> custom({
    Expression<String>? fileId,
    Expression<DateTime>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SimilarDismissedCompanion copyWith({
    Value<String>? fileId,
    Value<DateTime>? dismissedAt,
    Value<int>? rowid,
  }) {
    return SimilarDismissedCompanion(
      fileId: fileId ?? this.fileId,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimilarDismissedCompanion(')
          ..write('fileId: $fileId, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaLocationsTable extends MediaLocations
    with TableInfo<$MediaLocationsTable, MediaLocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frontCameraMeta = const VerificationMeta(
    'frontCamera',
  );
  @override
  late final GeneratedColumn<bool> frontCamera = GeneratedColumn<bool>(
    'front_camera',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("front_camera" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _locationReadableMeta = const VerificationMeta(
    'locationReadable',
  );
  @override
  late final GeneratedColumn<bool> locationReadable = GeneratedColumn<bool>(
    'location_readable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("location_readable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _readAtMsMeta = const VerificationMeta(
    'readAtMs',
  );
  @override
  late final GeneratedColumn<int> readAtMs = GeneratedColumn<int>(
    'read_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    fileModifiedAtMs,
    lat,
    lng,
    frontCamera,
    locationReadable,
    readAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaLocationRow> instance, {
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
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('front_camera')) {
      context.handle(
        _frontCameraMeta,
        frontCamera.isAcceptableOrUnknown(
          data['front_camera']!,
          _frontCameraMeta,
        ),
      );
    }
    if (data.containsKey('location_readable')) {
      context.handle(
        _locationReadableMeta,
        locationReadable.isAcceptableOrUnknown(
          data['location_readable']!,
          _locationReadableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationReadableMeta);
    }
    if (data.containsKey('read_at_ms')) {
      context.handle(
        _readAtMsMeta,
        readAtMs.isAcceptableOrUnknown(data['read_at_ms']!, _readAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  MediaLocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaLocationRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      fileModifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_modified_at_ms'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      frontCamera: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}front_camera'],
      )!,
      locationReadable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}location_readable'],
      )!,
      readAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at_ms'],
      )!,
    );
  }

  @override
  $MediaLocationsTable createAlias(String alias) {
    return $MediaLocationsTable(attachedDatabase, alias);
  }
}

class MediaLocationRow extends DataClass
    implements Insertable<MediaLocationRow> {
  final String fileId;

  /// media_index.modifiedAtMs when read (epoch ms).
  final int fileModifiedAtMs;
  final double? lat;
  final double? lng;
  final bool frontCamera;

  /// Location access was granted (or not needed, API < 29) when read. Rows
  /// read without it are read again once access is granted.
  final bool locationReadable;
  final int readAtMs;
  const MediaLocationRow({
    required this.fileId,
    required this.fileModifiedAtMs,
    this.lat,
    this.lng,
    required this.frontCamera,
    required this.locationReadable,
    required this.readAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['front_camera'] = Variable<bool>(frontCamera);
    map['location_readable'] = Variable<bool>(locationReadable);
    map['read_at_ms'] = Variable<int>(readAtMs);
    return map;
  }

  MediaLocationsCompanion toCompanion(bool nullToAbsent) {
    return MediaLocationsCompanion(
      fileId: Value(fileId),
      fileModifiedAtMs: Value(fileModifiedAtMs),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      frontCamera: Value(frontCamera),
      locationReadable: Value(locationReadable),
      readAtMs: Value(readAtMs),
    );
  }

  factory MediaLocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaLocationRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      fileModifiedAtMs: serializer.fromJson<int>(json['fileModifiedAtMs']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      frontCamera: serializer.fromJson<bool>(json['frontCamera']),
      locationReadable: serializer.fromJson<bool>(json['locationReadable']),
      readAtMs: serializer.fromJson<int>(json['readAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'fileModifiedAtMs': serializer.toJson<int>(fileModifiedAtMs),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'frontCamera': serializer.toJson<bool>(frontCamera),
      'locationReadable': serializer.toJson<bool>(locationReadable),
      'readAtMs': serializer.toJson<int>(readAtMs),
    };
  }

  MediaLocationRow copyWith({
    String? fileId,
    int? fileModifiedAtMs,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    bool? frontCamera,
    bool? locationReadable,
    int? readAtMs,
  }) => MediaLocationRow(
    fileId: fileId ?? this.fileId,
    fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    frontCamera: frontCamera ?? this.frontCamera,
    locationReadable: locationReadable ?? this.locationReadable,
    readAtMs: readAtMs ?? this.readAtMs,
  );
  MediaLocationRow copyWithCompanion(MediaLocationsCompanion data) {
    return MediaLocationRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      fileModifiedAtMs: data.fileModifiedAtMs.present
          ? data.fileModifiedAtMs.value
          : this.fileModifiedAtMs,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      frontCamera: data.frontCamera.present
          ? data.frontCamera.value
          : this.frontCamera,
      locationReadable: data.locationReadable.present
          ? data.locationReadable.value
          : this.locationReadable,
      readAtMs: data.readAtMs.present ? data.readAtMs.value : this.readAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaLocationRow(')
          ..write('fileId: $fileId, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('frontCamera: $frontCamera, ')
          ..write('locationReadable: $locationReadable, ')
          ..write('readAtMs: $readAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    fileModifiedAtMs,
    lat,
    lng,
    frontCamera,
    locationReadable,
    readAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaLocationRow &&
          other.fileId == this.fileId &&
          other.fileModifiedAtMs == this.fileModifiedAtMs &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.frontCamera == this.frontCamera &&
          other.locationReadable == this.locationReadable &&
          other.readAtMs == this.readAtMs);
}

class MediaLocationsCompanion extends UpdateCompanion<MediaLocationRow> {
  final Value<String> fileId;
  final Value<int> fileModifiedAtMs;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<bool> frontCamera;
  final Value<bool> locationReadable;
  final Value<int> readAtMs;
  final Value<int> rowid;
  const MediaLocationsCompanion({
    this.fileId = const Value.absent(),
    this.fileModifiedAtMs = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.frontCamera = const Value.absent(),
    this.locationReadable = const Value.absent(),
    this.readAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaLocationsCompanion.insert({
    required String fileId,
    required int fileModifiedAtMs,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.frontCamera = const Value.absent(),
    required bool locationReadable,
    required int readAtMs,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       fileModifiedAtMs = Value(fileModifiedAtMs),
       locationReadable = Value(locationReadable),
       readAtMs = Value(readAtMs);
  static Insertable<MediaLocationRow> custom({
    Expression<String>? fileId,
    Expression<int>? fileModifiedAtMs,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<bool>? frontCamera,
    Expression<bool>? locationReadable,
    Expression<int>? readAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (fileModifiedAtMs != null) 'file_modified_at_ms': fileModifiedAtMs,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (frontCamera != null) 'front_camera': frontCamera,
      if (locationReadable != null) 'location_readable': locationReadable,
      if (readAtMs != null) 'read_at_ms': readAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaLocationsCompanion copyWith({
    Value<String>? fileId,
    Value<int>? fileModifiedAtMs,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<bool>? frontCamera,
    Value<bool>? locationReadable,
    Value<int>? readAtMs,
    Value<int>? rowid,
  }) {
    return MediaLocationsCompanion(
      fileId: fileId ?? this.fileId,
      fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      frontCamera: frontCamera ?? this.frontCamera,
      locationReadable: locationReadable ?? this.locationReadable,
      readAtMs: readAtMs ?? this.readAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (fileModifiedAtMs.present) {
      map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (frontCamera.present) {
      map['front_camera'] = Variable<bool>(frontCamera.value);
    }
    if (locationReadable.present) {
      map['location_readable'] = Variable<bool>(locationReadable.value);
    }
    if (readAtMs.present) {
      map['read_at_ms'] = Variable<int>(readAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaLocationsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('frontCamera: $frontCamera, ')
          ..write('locationReadable: $locationReadable, ')
          ..write('readAtMs: $readAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartGroupsTable extends SmartGroups
    with TableInfo<$SmartGroupsTable, SmartGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartGroupsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<SmartGroupKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SmartGroupKind>($SmartGroupsTable.$converterkind);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMsMeta = const VerificationMeta(
    'startAtMs',
  );
  @override
  late final GeneratedColumn<int> startAtMs = GeneratedColumn<int>(
    'start_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMsMeta = const VerificationMeta(
    'endAtMs',
  );
  @override
  late final GeneratedColumn<int> endAtMs = GeneratedColumn<int>(
    'end_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerLatMeta = const VerificationMeta(
    'centerLat',
  );
  @override
  late final GeneratedColumn<double> centerLat = GeneratedColumn<double>(
    'center_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _centerLngMeta = const VerificationMeta(
    'centerLng',
  );
  @override
  late final GeneratedColumn<double> centerLng = GeneratedColumn<double>(
    'center_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverFileIdMeta = const VerificationMeta(
    'coverFileId',
  );
  @override
  late final GeneratedColumn<String> coverFileId = GeneratedColumn<String>(
    'cover_file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userTitleMeta = const VerificationMeta(
    'userTitle',
  );
  @override
  late final GeneratedColumn<String> userTitle = GeneratedColumn<String>(
    'user_title',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeNameMeta = const VerificationMeta(
    'placeName',
  );
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
    'place_name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geocodedAtMsMeta = const VerificationMeta(
    'geocodedAtMs',
  );
  @override
  late final GeneratedColumn<int> geocodedAtMs = GeneratedColumn<int>(
    'geocoded_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    rank,
    startAtMs,
    endAtMs,
    centerLat,
    centerLng,
    coverFileId,
    itemCount,
    userTitle,
    placeName,
    geocodedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    if (data.containsKey('start_at_ms')) {
      context.handle(
        _startAtMsMeta,
        startAtMs.isAcceptableOrUnknown(data['start_at_ms']!, _startAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMsMeta);
    }
    if (data.containsKey('end_at_ms')) {
      context.handle(
        _endAtMsMeta,
        endAtMs.isAcceptableOrUnknown(data['end_at_ms']!, _endAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMsMeta);
    }
    if (data.containsKey('center_lat')) {
      context.handle(
        _centerLatMeta,
        centerLat.isAcceptableOrUnknown(data['center_lat']!, _centerLatMeta),
      );
    }
    if (data.containsKey('center_lng')) {
      context.handle(
        _centerLngMeta,
        centerLng.isAcceptableOrUnknown(data['center_lng']!, _centerLngMeta),
      );
    }
    if (data.containsKey('cover_file_id')) {
      context.handle(
        _coverFileIdMeta,
        coverFileId.isAcceptableOrUnknown(
          data['cover_file_id']!,
          _coverFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coverFileIdMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('user_title')) {
      context.handle(
        _userTitleMeta,
        userTitle.isAcceptableOrUnknown(data['user_title']!, _userTitleMeta),
      );
    }
    if (data.containsKey('place_name')) {
      context.handle(
        _placeNameMeta,
        placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta),
      );
    }
    if (data.containsKey('geocoded_at_ms')) {
      context.handle(
        _geocodedAtMsMeta,
        geocodedAtMs.isAcceptableOrUnknown(
          data['geocoded_at_ms']!,
          _geocodedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $SmartGroupsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      startAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at_ms'],
      )!,
      endAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at_ms'],
      )!,
      centerLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_lat'],
      ),
      centerLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_lng'],
      ),
      coverFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_file_id'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      userTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_title'],
      ),
      placeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name'],
      ),
      geocodedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}geocoded_at_ms'],
      ),
    );
  }

  @override
  $SmartGroupsTable createAlias(String alias) {
    return $SmartGroupsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SmartGroupKind, String, String> $converterkind =
      const EnumNameConverter<SmartGroupKind>(SmartGroupKind.values);
}

class SmartGroupRow extends DataClass implements Insertable<SmartGroupRow> {
  final int id;
  final SmartGroupKind kind;

  /// Places: 1 = largest shown place ("Place 1"). Trips: 0.
  final int rank;

  /// Min sortDateMs of the members.
  final int startAtMs;

  /// Max sortDateMs of the members.
  final int endAtMs;
  final double? centerLat;
  final double? centerLng;

  /// Newest member.
  final String coverFileId;
  final int itemCount;

  /// Set by the user (rename); wins over everything. 1–80 chars.
  final String? userTitle;

  /// Online lookup result (setting on); null = none.
  final String? placeName;

  /// Last lookup attempt (success or failure), so failures aren't retried
  /// on every run. Cleared when the setting is turned on again.
  final int? geocodedAtMs;
  const SmartGroupRow({
    required this.id,
    required this.kind,
    required this.rank,
    required this.startAtMs,
    required this.endAtMs,
    this.centerLat,
    this.centerLng,
    required this.coverFileId,
    required this.itemCount,
    this.userTitle,
    this.placeName,
    this.geocodedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
        $SmartGroupsTable.$converterkind.toSql(kind),
      );
    }
    map['rank'] = Variable<int>(rank);
    map['start_at_ms'] = Variable<int>(startAtMs);
    map['end_at_ms'] = Variable<int>(endAtMs);
    if (!nullToAbsent || centerLat != null) {
      map['center_lat'] = Variable<double>(centerLat);
    }
    if (!nullToAbsent || centerLng != null) {
      map['center_lng'] = Variable<double>(centerLng);
    }
    map['cover_file_id'] = Variable<String>(coverFileId);
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || userTitle != null) {
      map['user_title'] = Variable<String>(userTitle);
    }
    if (!nullToAbsent || placeName != null) {
      map['place_name'] = Variable<String>(placeName);
    }
    if (!nullToAbsent || geocodedAtMs != null) {
      map['geocoded_at_ms'] = Variable<int>(geocodedAtMs);
    }
    return map;
  }

  SmartGroupsCompanion toCompanion(bool nullToAbsent) {
    return SmartGroupsCompanion(
      id: Value(id),
      kind: Value(kind),
      rank: Value(rank),
      startAtMs: Value(startAtMs),
      endAtMs: Value(endAtMs),
      centerLat: centerLat == null && nullToAbsent
          ? const Value.absent()
          : Value(centerLat),
      centerLng: centerLng == null && nullToAbsent
          ? const Value.absent()
          : Value(centerLng),
      coverFileId: Value(coverFileId),
      itemCount: Value(itemCount),
      userTitle: userTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(userTitle),
      placeName: placeName == null && nullToAbsent
          ? const Value.absent()
          : Value(placeName),
      geocodedAtMs: geocodedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(geocodedAtMs),
    );
  }

  factory SmartGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartGroupRow(
      id: serializer.fromJson<int>(json['id']),
      kind: $SmartGroupsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      rank: serializer.fromJson<int>(json['rank']),
      startAtMs: serializer.fromJson<int>(json['startAtMs']),
      endAtMs: serializer.fromJson<int>(json['endAtMs']),
      centerLat: serializer.fromJson<double?>(json['centerLat']),
      centerLng: serializer.fromJson<double?>(json['centerLng']),
      coverFileId: serializer.fromJson<String>(json['coverFileId']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      userTitle: serializer.fromJson<String?>(json['userTitle']),
      placeName: serializer.fromJson<String?>(json['placeName']),
      geocodedAtMs: serializer.fromJson<int?>(json['geocodedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $SmartGroupsTable.$converterkind.toJson(kind),
      ),
      'rank': serializer.toJson<int>(rank),
      'startAtMs': serializer.toJson<int>(startAtMs),
      'endAtMs': serializer.toJson<int>(endAtMs),
      'centerLat': serializer.toJson<double?>(centerLat),
      'centerLng': serializer.toJson<double?>(centerLng),
      'coverFileId': serializer.toJson<String>(coverFileId),
      'itemCount': serializer.toJson<int>(itemCount),
      'userTitle': serializer.toJson<String?>(userTitle),
      'placeName': serializer.toJson<String?>(placeName),
      'geocodedAtMs': serializer.toJson<int?>(geocodedAtMs),
    };
  }

  SmartGroupRow copyWith({
    int? id,
    SmartGroupKind? kind,
    int? rank,
    int? startAtMs,
    int? endAtMs,
    Value<double?> centerLat = const Value.absent(),
    Value<double?> centerLng = const Value.absent(),
    String? coverFileId,
    int? itemCount,
    Value<String?> userTitle = const Value.absent(),
    Value<String?> placeName = const Value.absent(),
    Value<int?> geocodedAtMs = const Value.absent(),
  }) => SmartGroupRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    rank: rank ?? this.rank,
    startAtMs: startAtMs ?? this.startAtMs,
    endAtMs: endAtMs ?? this.endAtMs,
    centerLat: centerLat.present ? centerLat.value : this.centerLat,
    centerLng: centerLng.present ? centerLng.value : this.centerLng,
    coverFileId: coverFileId ?? this.coverFileId,
    itemCount: itemCount ?? this.itemCount,
    userTitle: userTitle.present ? userTitle.value : this.userTitle,
    placeName: placeName.present ? placeName.value : this.placeName,
    geocodedAtMs: geocodedAtMs.present ? geocodedAtMs.value : this.geocodedAtMs,
  );
  SmartGroupRow copyWithCompanion(SmartGroupsCompanion data) {
    return SmartGroupRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      rank: data.rank.present ? data.rank.value : this.rank,
      startAtMs: data.startAtMs.present ? data.startAtMs.value : this.startAtMs,
      endAtMs: data.endAtMs.present ? data.endAtMs.value : this.endAtMs,
      centerLat: data.centerLat.present ? data.centerLat.value : this.centerLat,
      centerLng: data.centerLng.present ? data.centerLng.value : this.centerLng,
      coverFileId: data.coverFileId.present
          ? data.coverFileId.value
          : this.coverFileId,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      userTitle: data.userTitle.present ? data.userTitle.value : this.userTitle,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      geocodedAtMs: data.geocodedAtMs.present
          ? data.geocodedAtMs.value
          : this.geocodedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartGroupRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('rank: $rank, ')
          ..write('startAtMs: $startAtMs, ')
          ..write('endAtMs: $endAtMs, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLng: $centerLng, ')
          ..write('coverFileId: $coverFileId, ')
          ..write('itemCount: $itemCount, ')
          ..write('userTitle: $userTitle, ')
          ..write('placeName: $placeName, ')
          ..write('geocodedAtMs: $geocodedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    rank,
    startAtMs,
    endAtMs,
    centerLat,
    centerLng,
    coverFileId,
    itemCount,
    userTitle,
    placeName,
    geocodedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartGroupRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.rank == this.rank &&
          other.startAtMs == this.startAtMs &&
          other.endAtMs == this.endAtMs &&
          other.centerLat == this.centerLat &&
          other.centerLng == this.centerLng &&
          other.coverFileId == this.coverFileId &&
          other.itemCount == this.itemCount &&
          other.userTitle == this.userTitle &&
          other.placeName == this.placeName &&
          other.geocodedAtMs == this.geocodedAtMs);
}

class SmartGroupsCompanion extends UpdateCompanion<SmartGroupRow> {
  final Value<int> id;
  final Value<SmartGroupKind> kind;
  final Value<int> rank;
  final Value<int> startAtMs;
  final Value<int> endAtMs;
  final Value<double?> centerLat;
  final Value<double?> centerLng;
  final Value<String> coverFileId;
  final Value<int> itemCount;
  final Value<String?> userTitle;
  final Value<String?> placeName;
  final Value<int?> geocodedAtMs;
  const SmartGroupsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.rank = const Value.absent(),
    this.startAtMs = const Value.absent(),
    this.endAtMs = const Value.absent(),
    this.centerLat = const Value.absent(),
    this.centerLng = const Value.absent(),
    this.coverFileId = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.userTitle = const Value.absent(),
    this.placeName = const Value.absent(),
    this.geocodedAtMs = const Value.absent(),
  });
  SmartGroupsCompanion.insert({
    this.id = const Value.absent(),
    required SmartGroupKind kind,
    required int rank,
    required int startAtMs,
    required int endAtMs,
    this.centerLat = const Value.absent(),
    this.centerLng = const Value.absent(),
    required String coverFileId,
    required int itemCount,
    this.userTitle = const Value.absent(),
    this.placeName = const Value.absent(),
    this.geocodedAtMs = const Value.absent(),
  }) : kind = Value(kind),
       rank = Value(rank),
       startAtMs = Value(startAtMs),
       endAtMs = Value(endAtMs),
       coverFileId = Value(coverFileId),
       itemCount = Value(itemCount);
  static Insertable<SmartGroupRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? rank,
    Expression<int>? startAtMs,
    Expression<int>? endAtMs,
    Expression<double>? centerLat,
    Expression<double>? centerLng,
    Expression<String>? coverFileId,
    Expression<int>? itemCount,
    Expression<String>? userTitle,
    Expression<String>? placeName,
    Expression<int>? geocodedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (rank != null) 'rank': rank,
      if (startAtMs != null) 'start_at_ms': startAtMs,
      if (endAtMs != null) 'end_at_ms': endAtMs,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (coverFileId != null) 'cover_file_id': coverFileId,
      if (itemCount != null) 'item_count': itemCount,
      if (userTitle != null) 'user_title': userTitle,
      if (placeName != null) 'place_name': placeName,
      if (geocodedAtMs != null) 'geocoded_at_ms': geocodedAtMs,
    });
  }

  SmartGroupsCompanion copyWith({
    Value<int>? id,
    Value<SmartGroupKind>? kind,
    Value<int>? rank,
    Value<int>? startAtMs,
    Value<int>? endAtMs,
    Value<double?>? centerLat,
    Value<double?>? centerLng,
    Value<String>? coverFileId,
    Value<int>? itemCount,
    Value<String?>? userTitle,
    Value<String?>? placeName,
    Value<int?>? geocodedAtMs,
  }) {
    return SmartGroupsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      rank: rank ?? this.rank,
      startAtMs: startAtMs ?? this.startAtMs,
      endAtMs: endAtMs ?? this.endAtMs,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      coverFileId: coverFileId ?? this.coverFileId,
      itemCount: itemCount ?? this.itemCount,
      userTitle: userTitle ?? this.userTitle,
      placeName: placeName ?? this.placeName,
      geocodedAtMs: geocodedAtMs ?? this.geocodedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SmartGroupsTable.$converterkind.toSql(kind.value),
      );
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (startAtMs.present) {
      map['start_at_ms'] = Variable<int>(startAtMs.value);
    }
    if (endAtMs.present) {
      map['end_at_ms'] = Variable<int>(endAtMs.value);
    }
    if (centerLat.present) {
      map['center_lat'] = Variable<double>(centerLat.value);
    }
    if (centerLng.present) {
      map['center_lng'] = Variable<double>(centerLng.value);
    }
    if (coverFileId.present) {
      map['cover_file_id'] = Variable<String>(coverFileId.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (userTitle.present) {
      map['user_title'] = Variable<String>(userTitle.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (geocodedAtMs.present) {
      map['geocoded_at_ms'] = Variable<int>(geocodedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartGroupsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('rank: $rank, ')
          ..write('startAtMs: $startAtMs, ')
          ..write('endAtMs: $endAtMs, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLng: $centerLng, ')
          ..write('coverFileId: $coverFileId, ')
          ..write('itemCount: $itemCount, ')
          ..write('userTitle: $userTitle, ')
          ..write('placeName: $placeName, ')
          ..write('geocodedAtMs: $geocodedAtMs')
          ..write(')'))
        .toString();
  }
}

class $SmartGroupItemsTable extends SmartGroupItems
    with TableInfo<$SmartGroupItemsTable, SmartGroupItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartGroupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES smart_groups (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [groupId, fileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_group_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartGroupItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, fileId};
  @override
  SmartGroupItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartGroupItemRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
    );
  }

  @override
  $SmartGroupItemsTable createAlias(String alias) {
    return $SmartGroupItemsTable(attachedDatabase, alias);
  }
}

class SmartGroupItemRow extends DataClass
    implements Insertable<SmartGroupItemRow> {
  final int groupId;
  final String fileId;
  const SmartGroupItemRow({required this.groupId, required this.fileId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['file_id'] = Variable<String>(fileId);
    return map;
  }

  SmartGroupItemsCompanion toCompanion(bool nullToAbsent) {
    return SmartGroupItemsCompanion(
      groupId: Value(groupId),
      fileId: Value(fileId),
    );
  }

  factory SmartGroupItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartGroupItemRow(
      groupId: serializer.fromJson<int>(json['groupId']),
      fileId: serializer.fromJson<String>(json['fileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'fileId': serializer.toJson<String>(fileId),
    };
  }

  SmartGroupItemRow copyWith({int? groupId, String? fileId}) =>
      SmartGroupItemRow(
        groupId: groupId ?? this.groupId,
        fileId: fileId ?? this.fileId,
      );
  SmartGroupItemRow copyWithCompanion(SmartGroupItemsCompanion data) {
    return SmartGroupItemRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartGroupItemRow(')
          ..write('groupId: $groupId, ')
          ..write('fileId: $fileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, fileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartGroupItemRow &&
          other.groupId == this.groupId &&
          other.fileId == this.fileId);
}

class SmartGroupItemsCompanion extends UpdateCompanion<SmartGroupItemRow> {
  final Value<int> groupId;
  final Value<String> fileId;
  final Value<int> rowid;
  const SmartGroupItemsCompanion({
    this.groupId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartGroupItemsCompanion.insert({
    required int groupId,
    required String fileId,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       fileId = Value(fileId);
  static Insertable<SmartGroupItemRow> custom({
    Expression<int>? groupId,
    Expression<String>? fileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (fileId != null) 'file_id': fileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartGroupItemsCompanion copyWith({
    Value<int>? groupId,
    Value<String>? fileId,
    Value<int>? rowid,
  }) {
    return SmartGroupItemsCompanion(
      groupId: groupId ?? this.groupId,
      fileId: fileId ?? this.fileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartGroupItemsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('fileId: $fileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiLabelsTable extends AiLabels
    with TableInfo<$AiLabelsTable, AiLabelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, label, confidence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiLabelRow> instance, {
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
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId, label};
  @override
  AiLabelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiLabelRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
    );
  }

  @override
  $AiLabelsTable createAlias(String alias) {
    return $AiLabelsTable(attachedDatabase, alias);
  }
}

class AiLabelRow extends DataClass implements Insertable<AiLabelRow> {
  final String fileId;

  /// Lowercase vocabulary label, e.g. 'cat', 'color:blue'.
  final String label;
  final double confidence;
  const AiLabelRow({
    required this.fileId,
    required this.label,
    required this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['label'] = Variable<String>(label);
    map['confidence'] = Variable<double>(confidence);
    return map;
  }

  AiLabelsCompanion toCompanion(bool nullToAbsent) {
    return AiLabelsCompanion(
      fileId: Value(fileId),
      label: Value(label),
      confidence: Value(confidence),
    );
  }

  factory AiLabelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiLabelRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      label: serializer.fromJson<String>(json['label']),
      confidence: serializer.fromJson<double>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'label': serializer.toJson<String>(label),
      'confidence': serializer.toJson<double>(confidence),
    };
  }

  AiLabelRow copyWith({String? fileId, String? label, double? confidence}) =>
      AiLabelRow(
        fileId: fileId ?? this.fileId,
        label: label ?? this.label,
        confidence: confidence ?? this.confidence,
      );
  AiLabelRow copyWithCompanion(AiLabelsCompanion data) {
    return AiLabelRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      label: data.label.present ? data.label.value : this.label,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiLabelRow(')
          ..write('fileId: $fileId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, label, confidence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiLabelRow &&
          other.fileId == this.fileId &&
          other.label == this.label &&
          other.confidence == this.confidence);
}

class AiLabelsCompanion extends UpdateCompanion<AiLabelRow> {
  final Value<String> fileId;
  final Value<String> label;
  final Value<double> confidence;
  final Value<int> rowid;
  const AiLabelsCompanion({
    this.fileId = const Value.absent(),
    this.label = const Value.absent(),
    this.confidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiLabelsCompanion.insert({
    required String fileId,
    required String label,
    required double confidence,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       label = Value(label),
       confidence = Value(confidence);
  static Insertable<AiLabelRow> custom({
    Expression<String>? fileId,
    Expression<String>? label,
    Expression<double>? confidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (label != null) 'label': label,
      if (confidence != null) 'confidence': confidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiLabelsCompanion copyWith({
    Value<String>? fileId,
    Value<String>? label,
    Value<double>? confidence,
    Value<int>? rowid,
  }) {
    return AiLabelsCompanion(
      fileId: fileId ?? this.fileId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiLabelsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiLabelStatusTable extends AiLabelStatus
    with TableInfo<$AiLabelStatusTable, AiLabelStatusRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiLabelStatusTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AiLabelOutcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AiLabelOutcome>($AiLabelStatusTable.$converteroutcome);
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<int> modelVersion = GeneratedColumn<int>(
    'model_version',
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
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedAtMsMeta = const VerificationMeta(
    'processedAtMs',
  );
  @override
  late final GeneratedColumn<int> processedAtMs = GeneratedColumn<int>(
    'processed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    outcome,
    modelVersion,
    fileModifiedAtMs,
    attempts,
    error,
    processedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_label_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiLabelStatusRow> instance, {
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
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
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
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('processed_at_ms')) {
      context.handle(
        _processedAtMsMeta,
        processedAtMs.isAcceptableOrUnknown(
          data['processed_at_ms']!,
          _processedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  AiLabelStatusRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiLabelStatusRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      outcome: $AiLabelStatusTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}model_version'],
      )!,
      fileModifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_modified_at_ms'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      processedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at_ms'],
      )!,
    );
  }

  @override
  $AiLabelStatusTable createAlias(String alias) {
    return $AiLabelStatusTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AiLabelOutcome, String, String> $converteroutcome =
      const EnumNameConverter<AiLabelOutcome>(AiLabelOutcome.values);
}

class AiLabelStatusRow extends DataClass
    implements Insertable<AiLabelStatusRow> {
  final String fileId;
  final AiLabelOutcome outcome;

  /// LabelingJob.modelVersion (bumped when a model or label_map changes).
  final int modelVersion;

  /// media_index.modifiedAtMs when processed (epoch ms, same unit).
  final int fileModifiedAtMs;
  final int attempts;

  /// Short reason for `failed` (exception type + message, ≤ 200 chars).
  final String? error;

  /// Epoch ms (drift's DateTime stores seconds).
  final int processedAtMs;
  const AiLabelStatusRow({
    required this.fileId,
    required this.outcome,
    required this.modelVersion,
    required this.fileModifiedAtMs,
    required this.attempts,
    this.error,
    required this.processedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    {
      map['outcome'] = Variable<String>(
        $AiLabelStatusTable.$converteroutcome.toSql(outcome),
      );
    }
    map['model_version'] = Variable<int>(modelVersion);
    map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['processed_at_ms'] = Variable<int>(processedAtMs);
    return map;
  }

  AiLabelStatusCompanion toCompanion(bool nullToAbsent) {
    return AiLabelStatusCompanion(
      fileId: Value(fileId),
      outcome: Value(outcome),
      modelVersion: Value(modelVersion),
      fileModifiedAtMs: Value(fileModifiedAtMs),
      attempts: Value(attempts),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      processedAtMs: Value(processedAtMs),
    );
  }

  factory AiLabelStatusRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiLabelStatusRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      outcome: $AiLabelStatusTable.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
      modelVersion: serializer.fromJson<int>(json['modelVersion']),
      fileModifiedAtMs: serializer.fromJson<int>(json['fileModifiedAtMs']),
      attempts: serializer.fromJson<int>(json['attempts']),
      error: serializer.fromJson<String?>(json['error']),
      processedAtMs: serializer.fromJson<int>(json['processedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'outcome': serializer.toJson<String>(
        $AiLabelStatusTable.$converteroutcome.toJson(outcome),
      ),
      'modelVersion': serializer.toJson<int>(modelVersion),
      'fileModifiedAtMs': serializer.toJson<int>(fileModifiedAtMs),
      'attempts': serializer.toJson<int>(attempts),
      'error': serializer.toJson<String?>(error),
      'processedAtMs': serializer.toJson<int>(processedAtMs),
    };
  }

  AiLabelStatusRow copyWith({
    String? fileId,
    AiLabelOutcome? outcome,
    int? modelVersion,
    int? fileModifiedAtMs,
    int? attempts,
    Value<String?> error = const Value.absent(),
    int? processedAtMs,
  }) => AiLabelStatusRow(
    fileId: fileId ?? this.fileId,
    outcome: outcome ?? this.outcome,
    modelVersion: modelVersion ?? this.modelVersion,
    fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
    attempts: attempts ?? this.attempts,
    error: error.present ? error.value : this.error,
    processedAtMs: processedAtMs ?? this.processedAtMs,
  );
  AiLabelStatusRow copyWithCompanion(AiLabelStatusCompanion data) {
    return AiLabelStatusRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      fileModifiedAtMs: data.fileModifiedAtMs.present
          ? data.fileModifiedAtMs.value
          : this.fileModifiedAtMs,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      error: data.error.present ? data.error.value : this.error,
      processedAtMs: data.processedAtMs.present
          ? data.processedAtMs.value
          : this.processedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiLabelStatusRow(')
          ..write('fileId: $fileId, ')
          ..write('outcome: $outcome, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('attempts: $attempts, ')
          ..write('error: $error, ')
          ..write('processedAtMs: $processedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    outcome,
    modelVersion,
    fileModifiedAtMs,
    attempts,
    error,
    processedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiLabelStatusRow &&
          other.fileId == this.fileId &&
          other.outcome == this.outcome &&
          other.modelVersion == this.modelVersion &&
          other.fileModifiedAtMs == this.fileModifiedAtMs &&
          other.attempts == this.attempts &&
          other.error == this.error &&
          other.processedAtMs == this.processedAtMs);
}

class AiLabelStatusCompanion extends UpdateCompanion<AiLabelStatusRow> {
  final Value<String> fileId;
  final Value<AiLabelOutcome> outcome;
  final Value<int> modelVersion;
  final Value<int> fileModifiedAtMs;
  final Value<int> attempts;
  final Value<String?> error;
  final Value<int> processedAtMs;
  final Value<int> rowid;
  const AiLabelStatusCompanion({
    this.fileId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.fileModifiedAtMs = const Value.absent(),
    this.attempts = const Value.absent(),
    this.error = const Value.absent(),
    this.processedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiLabelStatusCompanion.insert({
    required String fileId,
    required AiLabelOutcome outcome,
    required int modelVersion,
    required int fileModifiedAtMs,
    this.attempts = const Value.absent(),
    this.error = const Value.absent(),
    required int processedAtMs,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       outcome = Value(outcome),
       modelVersion = Value(modelVersion),
       fileModifiedAtMs = Value(fileModifiedAtMs),
       processedAtMs = Value(processedAtMs);
  static Insertable<AiLabelStatusRow> custom({
    Expression<String>? fileId,
    Expression<String>? outcome,
    Expression<int>? modelVersion,
    Expression<int>? fileModifiedAtMs,
    Expression<int>? attempts,
    Expression<String>? error,
    Expression<int>? processedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (outcome != null) 'outcome': outcome,
      if (modelVersion != null) 'model_version': modelVersion,
      if (fileModifiedAtMs != null) 'file_modified_at_ms': fileModifiedAtMs,
      if (attempts != null) 'attempts': attempts,
      if (error != null) 'error': error,
      if (processedAtMs != null) 'processed_at_ms': processedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiLabelStatusCompanion copyWith({
    Value<String>? fileId,
    Value<AiLabelOutcome>? outcome,
    Value<int>? modelVersion,
    Value<int>? fileModifiedAtMs,
    Value<int>? attempts,
    Value<String?>? error,
    Value<int>? processedAtMs,
    Value<int>? rowid,
  }) {
    return AiLabelStatusCompanion(
      fileId: fileId ?? this.fileId,
      outcome: outcome ?? this.outcome,
      modelVersion: modelVersion ?? this.modelVersion,
      fileModifiedAtMs: fileModifiedAtMs ?? this.fileModifiedAtMs,
      attempts: attempts ?? this.attempts,
      error: error ?? this.error,
      processedAtMs: processedAtMs ?? this.processedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $AiLabelStatusTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<int>(modelVersion.value);
    }
    if (fileModifiedAtMs.present) {
      map['file_modified_at_ms'] = Variable<int>(fileModifiedAtMs.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (processedAtMs.present) {
      map['processed_at_ms'] = Variable<int>(processedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiLabelStatusCompanion(')
          ..write('fileId: $fileId, ')
          ..write('outcome: $outcome, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('fileModifiedAtMs: $fileModifiedAtMs, ')
          ..write('attempts: $attempts, ')
          ..write('error: $error, ')
          ..write('processedAtMs: $processedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnownDevicesTable extends KnownDevices
    with TableInfo<$KnownDevicesTable, KnownDeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDeviceIdMeta = const VerificationMeta(
    'peerDeviceId',
  );
  @override
  late final GeneratedColumn<String> peerDeviceId = GeneratedColumn<String>(
    'peer_device_id',
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
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyFingerprintMeta =
      const VerificationMeta('publicKeyFingerprint');
  @override
  late final GeneratedColumn<String> publicKeyFingerprint =
      GeneratedColumn<String>(
        'public_key_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _lastSeenAtMsMeta = const VerificationMeta(
    'lastSeenAtMs',
  );
  @override
  late final GeneratedColumn<int> lastSeenAtMs = GeneratedColumn<int>(
    'last_seen_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAddressesMeta = const VerificationMeta(
    'lastAddresses',
  );
  @override
  late final GeneratedColumn<String> lastAddresses = GeneratedColumn<String>(
    'last_addresses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _allowedRootsJsonMeta = const VerificationMeta(
    'allowedRootsJson',
  );
  @override
  late final GeneratedColumn<String> allowedRootsJson = GeneratedColumn<String>(
    'allowed_roots_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _canShareToUsMeta = const VerificationMeta(
    'canShareToUs',
  );
  @override
  late final GeneratedColumn<bool> canShareToUs = GeneratedColumn<bool>(
    'can_share_to_us',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_share_to_us" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTemporaryMeta = const VerificationMeta(
    'isTemporary',
  );
  @override
  late final GeneratedColumn<bool> isTemporary = GeneratedColumn<bool>(
    'is_temporary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_temporary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _autoAcceptMeta = const VerificationMeta(
    'autoAccept',
  );
  @override
  late final GeneratedColumn<bool> autoAccept = GeneratedColumn<bool>(
    'auto_accept',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_accept" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerDeviceId,
    name,
    platform,
    publicKeyFingerprint,
    lastSeenAtMs,
    lastAddresses,
    allowedRootsJson,
    canShareToUs,
    isTemporary,
    autoAccept,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnownDeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_device_id')) {
      context.handle(
        _peerDeviceIdMeta,
        peerDeviceId.isAcceptableOrUnknown(
          data['peer_device_id']!,
          _peerDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDeviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('public_key_fingerprint')) {
      context.handle(
        _publicKeyFingerprintMeta,
        publicKeyFingerprint.isAcceptableOrUnknown(
          data['public_key_fingerprint']!,
          _publicKeyFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyFingerprintMeta);
    }
    if (data.containsKey('last_seen_at_ms')) {
      context.handle(
        _lastSeenAtMsMeta,
        lastSeenAtMs.isAcceptableOrUnknown(
          data['last_seen_at_ms']!,
          _lastSeenAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMsMeta);
    }
    if (data.containsKey('last_addresses')) {
      context.handle(
        _lastAddressesMeta,
        lastAddresses.isAcceptableOrUnknown(
          data['last_addresses']!,
          _lastAddressesMeta,
        ),
      );
    }
    if (data.containsKey('allowed_roots_json')) {
      context.handle(
        _allowedRootsJsonMeta,
        allowedRootsJson.isAcceptableOrUnknown(
          data['allowed_roots_json']!,
          _allowedRootsJsonMeta,
        ),
      );
    }
    if (data.containsKey('can_share_to_us')) {
      context.handle(
        _canShareToUsMeta,
        canShareToUs.isAcceptableOrUnknown(
          data['can_share_to_us']!,
          _canShareToUsMeta,
        ),
      );
    }
    if (data.containsKey('is_temporary')) {
      context.handle(
        _isTemporaryMeta,
        isTemporary.isAcceptableOrUnknown(
          data['is_temporary']!,
          _isTemporaryMeta,
        ),
      );
    }
    if (data.containsKey('auto_accept')) {
      context.handle(
        _autoAcceptMeta,
        autoAccept.isAcceptableOrUnknown(data['auto_accept']!, _autoAcceptMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnownDeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownDeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      peerDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_device_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      publicKeyFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_fingerprint'],
      )!,
      lastSeenAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at_ms'],
      )!,
      lastAddresses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_addresses'],
      )!,
      allowedRootsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allowed_roots_json'],
      )!,
      canShareToUs: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_share_to_us'],
      )!,
      isTemporary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_temporary'],
      )!,
      autoAccept: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_accept'],
      )!,
    );
  }

  @override
  $KnownDevicesTable createAlias(String alias) {
    return $KnownDevicesTable(attachedDatabase, alias);
  }
}

class KnownDeviceRow extends DataClass implements Insertable<KnownDeviceRow> {
  /// Local random 128-bit hex (`randomHexId`), never the peer's id.
  final String id;

  /// The peer's self-asserted deviceId; informational only.
  final String peerDeviceId;
  final String name;

  /// android | windows | ios; '' when unknown.
  final String platform;

  /// Identity: 64 lowercase hex.
  final String publicKeyFingerprint;

  /// Epoch ms.
  final int lastSeenAtMs;

  /// JSON `["ip:port", ...]` (max 3, newest first): where the peer was our
  /// server.
  final String lastAddresses;

  /// JSON `[{path, label, readOnly}]`: what THIS device shares with that
  /// peer. Local only; root ids are recomputed on load.
  final String allowedRootsJson;

  /// The peer has been our server at least once.
  final bool canShareToUs;

  /// Kept only for resuming transfers (N9/N10); hidden from the list.
  final bool isTemporary;

  /// "Always allow": a verified `/v1/pair/known` from this peer is accepted
  /// without the accept prompt (sharing side only).
  final bool autoAccept;
  const KnownDeviceRow({
    required this.id,
    required this.peerDeviceId,
    required this.name,
    required this.platform,
    required this.publicKeyFingerprint,
    required this.lastSeenAtMs,
    required this.lastAddresses,
    required this.allowedRootsJson,
    required this.canShareToUs,
    required this.isTemporary,
    required this.autoAccept,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['peer_device_id'] = Variable<String>(peerDeviceId);
    map['name'] = Variable<String>(name);
    map['platform'] = Variable<String>(platform);
    map['public_key_fingerprint'] = Variable<String>(publicKeyFingerprint);
    map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs);
    map['last_addresses'] = Variable<String>(lastAddresses);
    map['allowed_roots_json'] = Variable<String>(allowedRootsJson);
    map['can_share_to_us'] = Variable<bool>(canShareToUs);
    map['is_temporary'] = Variable<bool>(isTemporary);
    map['auto_accept'] = Variable<bool>(autoAccept);
    return map;
  }

  KnownDevicesCompanion toCompanion(bool nullToAbsent) {
    return KnownDevicesCompanion(
      id: Value(id),
      peerDeviceId: Value(peerDeviceId),
      name: Value(name),
      platform: Value(platform),
      publicKeyFingerprint: Value(publicKeyFingerprint),
      lastSeenAtMs: Value(lastSeenAtMs),
      lastAddresses: Value(lastAddresses),
      allowedRootsJson: Value(allowedRootsJson),
      canShareToUs: Value(canShareToUs),
      isTemporary: Value(isTemporary),
      autoAccept: Value(autoAccept),
    );
  }

  factory KnownDeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownDeviceRow(
      id: serializer.fromJson<String>(json['id']),
      peerDeviceId: serializer.fromJson<String>(json['peerDeviceId']),
      name: serializer.fromJson<String>(json['name']),
      platform: serializer.fromJson<String>(json['platform']),
      publicKeyFingerprint: serializer.fromJson<String>(
        json['publicKeyFingerprint'],
      ),
      lastSeenAtMs: serializer.fromJson<int>(json['lastSeenAtMs']),
      lastAddresses: serializer.fromJson<String>(json['lastAddresses']),
      allowedRootsJson: serializer.fromJson<String>(json['allowedRootsJson']),
      canShareToUs: serializer.fromJson<bool>(json['canShareToUs']),
      isTemporary: serializer.fromJson<bool>(json['isTemporary']),
      autoAccept: serializer.fromJson<bool>(json['autoAccept']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerDeviceId': serializer.toJson<String>(peerDeviceId),
      'name': serializer.toJson<String>(name),
      'platform': serializer.toJson<String>(platform),
      'publicKeyFingerprint': serializer.toJson<String>(publicKeyFingerprint),
      'lastSeenAtMs': serializer.toJson<int>(lastSeenAtMs),
      'lastAddresses': serializer.toJson<String>(lastAddresses),
      'allowedRootsJson': serializer.toJson<String>(allowedRootsJson),
      'canShareToUs': serializer.toJson<bool>(canShareToUs),
      'isTemporary': serializer.toJson<bool>(isTemporary),
      'autoAccept': serializer.toJson<bool>(autoAccept),
    };
  }

  KnownDeviceRow copyWith({
    String? id,
    String? peerDeviceId,
    String? name,
    String? platform,
    String? publicKeyFingerprint,
    int? lastSeenAtMs,
    String? lastAddresses,
    String? allowedRootsJson,
    bool? canShareToUs,
    bool? isTemporary,
    bool? autoAccept,
  }) => KnownDeviceRow(
    id: id ?? this.id,
    peerDeviceId: peerDeviceId ?? this.peerDeviceId,
    name: name ?? this.name,
    platform: platform ?? this.platform,
    publicKeyFingerprint: publicKeyFingerprint ?? this.publicKeyFingerprint,
    lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
    lastAddresses: lastAddresses ?? this.lastAddresses,
    allowedRootsJson: allowedRootsJson ?? this.allowedRootsJson,
    canShareToUs: canShareToUs ?? this.canShareToUs,
    isTemporary: isTemporary ?? this.isTemporary,
    autoAccept: autoAccept ?? this.autoAccept,
  );
  KnownDeviceRow copyWithCompanion(KnownDevicesCompanion data) {
    return KnownDeviceRow(
      id: data.id.present ? data.id.value : this.id,
      peerDeviceId: data.peerDeviceId.present
          ? data.peerDeviceId.value
          : this.peerDeviceId,
      name: data.name.present ? data.name.value : this.name,
      platform: data.platform.present ? data.platform.value : this.platform,
      publicKeyFingerprint: data.publicKeyFingerprint.present
          ? data.publicKeyFingerprint.value
          : this.publicKeyFingerprint,
      lastSeenAtMs: data.lastSeenAtMs.present
          ? data.lastSeenAtMs.value
          : this.lastSeenAtMs,
      lastAddresses: data.lastAddresses.present
          ? data.lastAddresses.value
          : this.lastAddresses,
      allowedRootsJson: data.allowedRootsJson.present
          ? data.allowedRootsJson.value
          : this.allowedRootsJson,
      canShareToUs: data.canShareToUs.present
          ? data.canShareToUs.value
          : this.canShareToUs,
      isTemporary: data.isTemporary.present
          ? data.isTemporary.value
          : this.isTemporary,
      autoAccept: data.autoAccept.present
          ? data.autoAccept.value
          : this.autoAccept,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownDeviceRow(')
          ..write('id: $id, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('publicKeyFingerprint: $publicKeyFingerprint, ')
          ..write('lastSeenAtMs: $lastSeenAtMs, ')
          ..write('lastAddresses: $lastAddresses, ')
          ..write('allowedRootsJson: $allowedRootsJson, ')
          ..write('canShareToUs: $canShareToUs, ')
          ..write('isTemporary: $isTemporary, ')
          ..write('autoAccept: $autoAccept')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerDeviceId,
    name,
    platform,
    publicKeyFingerprint,
    lastSeenAtMs,
    lastAddresses,
    allowedRootsJson,
    canShareToUs,
    isTemporary,
    autoAccept,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownDeviceRow &&
          other.id == this.id &&
          other.peerDeviceId == this.peerDeviceId &&
          other.name == this.name &&
          other.platform == this.platform &&
          other.publicKeyFingerprint == this.publicKeyFingerprint &&
          other.lastSeenAtMs == this.lastSeenAtMs &&
          other.lastAddresses == this.lastAddresses &&
          other.allowedRootsJson == this.allowedRootsJson &&
          other.canShareToUs == this.canShareToUs &&
          other.isTemporary == this.isTemporary &&
          other.autoAccept == this.autoAccept);
}

class KnownDevicesCompanion extends UpdateCompanion<KnownDeviceRow> {
  final Value<String> id;
  final Value<String> peerDeviceId;
  final Value<String> name;
  final Value<String> platform;
  final Value<String> publicKeyFingerprint;
  final Value<int> lastSeenAtMs;
  final Value<String> lastAddresses;
  final Value<String> allowedRootsJson;
  final Value<bool> canShareToUs;
  final Value<bool> isTemporary;
  final Value<bool> autoAccept;
  final Value<int> rowid;
  const KnownDevicesCompanion({
    this.id = const Value.absent(),
    this.peerDeviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.platform = const Value.absent(),
    this.publicKeyFingerprint = const Value.absent(),
    this.lastSeenAtMs = const Value.absent(),
    this.lastAddresses = const Value.absent(),
    this.allowedRootsJson = const Value.absent(),
    this.canShareToUs = const Value.absent(),
    this.isTemporary = const Value.absent(),
    this.autoAccept = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownDevicesCompanion.insert({
    required String id,
    required String peerDeviceId,
    required String name,
    required String platform,
    required String publicKeyFingerprint,
    required int lastSeenAtMs,
    this.lastAddresses = const Value.absent(),
    this.allowedRootsJson = const Value.absent(),
    this.canShareToUs = const Value.absent(),
    this.isTemporary = const Value.absent(),
    this.autoAccept = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       peerDeviceId = Value(peerDeviceId),
       name = Value(name),
       platform = Value(platform),
       publicKeyFingerprint = Value(publicKeyFingerprint),
       lastSeenAtMs = Value(lastSeenAtMs);
  static Insertable<KnownDeviceRow> custom({
    Expression<String>? id,
    Expression<String>? peerDeviceId,
    Expression<String>? name,
    Expression<String>? platform,
    Expression<String>? publicKeyFingerprint,
    Expression<int>? lastSeenAtMs,
    Expression<String>? lastAddresses,
    Expression<String>? allowedRootsJson,
    Expression<bool>? canShareToUs,
    Expression<bool>? isTemporary,
    Expression<bool>? autoAccept,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerDeviceId != null) 'peer_device_id': peerDeviceId,
      if (name != null) 'name': name,
      if (platform != null) 'platform': platform,
      if (publicKeyFingerprint != null)
        'public_key_fingerprint': publicKeyFingerprint,
      if (lastSeenAtMs != null) 'last_seen_at_ms': lastSeenAtMs,
      if (lastAddresses != null) 'last_addresses': lastAddresses,
      if (allowedRootsJson != null) 'allowed_roots_json': allowedRootsJson,
      if (canShareToUs != null) 'can_share_to_us': canShareToUs,
      if (isTemporary != null) 'is_temporary': isTemporary,
      if (autoAccept != null) 'auto_accept': autoAccept,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownDevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? peerDeviceId,
    Value<String>? name,
    Value<String>? platform,
    Value<String>? publicKeyFingerprint,
    Value<int>? lastSeenAtMs,
    Value<String>? lastAddresses,
    Value<String>? allowedRootsJson,
    Value<bool>? canShareToUs,
    Value<bool>? isTemporary,
    Value<bool>? autoAccept,
    Value<int>? rowid,
  }) {
    return KnownDevicesCompanion(
      id: id ?? this.id,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      publicKeyFingerprint: publicKeyFingerprint ?? this.publicKeyFingerprint,
      lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
      lastAddresses: lastAddresses ?? this.lastAddresses,
      allowedRootsJson: allowedRootsJson ?? this.allowedRootsJson,
      canShareToUs: canShareToUs ?? this.canShareToUs,
      isTemporary: isTemporary ?? this.isTemporary,
      autoAccept: autoAccept ?? this.autoAccept,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (peerDeviceId.present) {
      map['peer_device_id'] = Variable<String>(peerDeviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (publicKeyFingerprint.present) {
      map['public_key_fingerprint'] = Variable<String>(
        publicKeyFingerprint.value,
      );
    }
    if (lastSeenAtMs.present) {
      map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs.value);
    }
    if (lastAddresses.present) {
      map['last_addresses'] = Variable<String>(lastAddresses.value);
    }
    if (allowedRootsJson.present) {
      map['allowed_roots_json'] = Variable<String>(allowedRootsJson.value);
    }
    if (canShareToUs.present) {
      map['can_share_to_us'] = Variable<bool>(canShareToUs.value);
    }
    if (isTemporary.present) {
      map['is_temporary'] = Variable<bool>(isTemporary.value);
    }
    if (autoAccept.present) {
      map['auto_accept'] = Variable<bool>(autoAccept.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownDevicesCompanion(')
          ..write('id: $id, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('publicKeyFingerprint: $publicKeyFingerprint, ')
          ..write('lastSeenAtMs: $lastSeenAtMs, ')
          ..write('lastAddresses: $lastAddresses, ')
          ..write('allowedRootsJson: $allowedRootsJson, ')
          ..write('canShareToUs: $canShareToUs, ')
          ..write('isTemporary: $isTemporary, ')
          ..write('autoAccept: $autoAccept, ')
          ..write('rowid: $rowid')
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
  late final $ReviewedLabelsTable reviewedLabels = $ReviewedLabelsTable(this);
  late final $SelectionItemsTable selectionItems = $SelectionItemsTable(this);
  late final $SelectionSnapshotsTable selectionSnapshots =
      $SelectionSnapshotsTable(this);
  late final $SwipeSourcesTable swipeSources = $SwipeSourcesTable(this);
  late final $SwipeSourceItemsTable swipeSourceItems = $SwipeSourceItemsTable(
    this,
  );
  late final $ImageSignalsTable imageSignals = $ImageSignalsTable(this);
  late final $SimilarGroupsTable similarGroups = $SimilarGroupsTable(this);
  late final $SimilarGroupItemsTable similarGroupItems =
      $SimilarGroupItemsTable(this);
  late final $SimilarDismissedTable similarDismissed = $SimilarDismissedTable(
    this,
  );
  late final $MediaLocationsTable mediaLocations = $MediaLocationsTable(this);
  late final $SmartGroupsTable smartGroups = $SmartGroupsTable(this);
  late final $SmartGroupItemsTable smartGroupItems = $SmartGroupItemsTable(
    this,
  );
  late final $AiLabelsTable aiLabels = $AiLabelsTable(this);
  late final $AiLabelStatusTable aiLabelStatus = $AiLabelStatusTable(this);
  late final $KnownDevicesTable knownDevices = $KnownDevicesTable(this);
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
  late final Index miSourceDate = Index(
    'mi_source_date',
    'CREATE INDEX mi_source_date ON media_index (source, sort_date_ms)',
  );
  late final Index miExt = Index(
    'mi_ext',
    'CREATE INDEX mi_ext ON media_index (extension)',
  );
  late final Index oneActiveSessionPerSource = Index(
    'one_active_session_per_source',
    'CREATE UNIQUE INDEX one_active_session_per_source ON sessions (source_id) WHERE is_active = 1',
  );
  late final Index oneOpenSessionPerSourcePreset = Index(
    'one_open_session_per_source_preset',
    'CREATE UNIQUE INDEX one_open_session_per_source_preset ON sessions (source_id, COALESCE(preset_id, 0)) WHERE ended_at IS NULL',
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
  late final Index rlFilePreset = Index(
    'rl_file_preset',
    'CREATE INDEX rl_file_preset ON reviewed_labels (file_id, preset_key)',
  );
  late final Index rlPreset = Index(
    'rl_preset',
    'CREATE INDEX rl_preset ON reviewed_labels (preset_key)',
  );
  late final Index oneOpenSourcePerSession = Index(
    'one_open_source_per_session',
    'CREATE UNIQUE INDEX one_open_source_per_session ON swipe_sources (session_id) WHERE closed_at IS NULL',
  );
  late final Index ssSessionClosedSeq = Index(
    'ss_session_closed_seq',
    'CREATE INDEX ss_session_closed_seq ON swipe_sources (session_id, closed_at_seq)',
  );
  late final Index ssiFile = Index(
    'ssi_file',
    'CREATE INDEX ssi_file ON swipe_source_items (file_id)',
  );
  late final Index isBlur = Index(
    'is_blur',
    'CREATE INDEX is_blur ON image_signals (blur_score)',
  );
  late final Index sgiFile = Index(
    'sgi_file',
    'CREATE INDEX sgi_file ON similar_group_items (file_id)',
  );
  late final Index sgKindRank = Index(
    'sg_kind_rank',
    'CREATE INDEX sg_kind_rank ON smart_groups (kind, rank)',
  );
  late final Index smgiFile = Index(
    'smgi_file',
    'CREATE INDEX smgi_file ON smart_group_items (file_id)',
  );
  late final Index aiLabelsLabel = Index(
    'ai_labels_label',
    'CREATE INDEX ai_labels_label ON ai_labels (label, file_id)',
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
    reviewedLabels,
    selectionItems,
    selectionSnapshots,
    swipeSources,
    swipeSourceItems,
    imageSignals,
    similarGroups,
    similarGroupItems,
    similarDismissed,
    mediaLocations,
    smartGroups,
    smartGroupItems,
    aiLabels,
    aiLabelStatus,
    knownDevices,
    miKindDate,
    miKindSize,
    miFolderDate,
    miDate,
    miName,
    miScreenshotDate,
    miSourceDate,
    miExt,
    oneActiveSessionPerSource,
    oneOpenSessionPerSourcePreset,
    saSessionStatusSeq,
    pdSessionStatus,
    pfiExpires,
    ftTag,
    oneCollectingBatch,
    presetsNameNocase,
    rlFilePreset,
    rlPreset,
    oneOpenSourcePerSession,
    ssSessionClosedSeq,
    ssiFile,
    isBlur,
    sgiFile,
    sgKindRank,
    smgiFile,
    aiLabelsLabel,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('swipe_sources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'swipe_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('swipe_source_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'similar_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('similar_group_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'smart_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('smart_group_items', kind: UpdateKind.delete)],
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
  Value<SourceBucket> source,
  Value<bool> hidden,
  Value<String> extension,
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
  Value<SourceBucket> source,
  Value<bool> hidden,
  Value<String> extension,
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

  ColumnWithTypeConverterFilters<SourceBucket, SourceBucket, int> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extension => $composableBuilder(
    column: $table.extension,
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

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extension => $composableBuilder(
    column: $table.extension,
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

  GeneratedColumnWithTypeConverter<SourceBucket, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);
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
                Value<SourceBucket> source = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> extension = const Value.absent(),
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
                source: source,
                hidden: hidden,
                extension: extension,
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
                Value<SourceBucket> source = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> extension = const Value.absent(),
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
                source: source,
                hidden: hidden,
                extension: extension,
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
  Value<String> sourceId,
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
  Value<String> sourceId,
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

  static MultiTypedResultKey<$SwipeSourcesTable, List<SwipeSourceRow>>
  _swipeSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.swipeSources,
    aliasName: 'sessions__id__swipe_sources__session_id',
  );

  $$SwipeSourcesTableProcessedTableManager get swipeSourcesRefs {
    final manager = $$SwipeSourcesTableTableManager(
      $_db,
      $_db.swipeSources,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_swipeSourcesRefsTable($_db));
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

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

  Expression<bool> swipeSourcesRefs(
    Expression<bool> Function($$SwipeSourcesTableFilterComposer f) f,
  ) {
    final $$SwipeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.swipeSources,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.swipeSources,
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

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

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

  Expression<T> swipeSourcesRefs<T extends Object>(
    Expression<T> Function($$SwipeSourcesTableAnnotationComposer a) f,
  ) {
    final $$SwipeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.swipeSources,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.swipeSources,
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
            bool swipeSourcesRefs,
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
                Value<String> sourceId = const Value.absent(),
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
                sourceId: sourceId,
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
                Value<String> sourceId = const Value.absent(),
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
                sourceId: sourceId,
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
                swipeSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionActionsRefs) db.sessionActions,
                    if (pendingDeletesRefs) db.pendingDeletes,
                    if (renameBatchesRefs) db.renameBatches,
                    if (swipeSourcesRefs) db.swipeSources,
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
                      if (swipeSourcesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          SwipeSourceRow,
                          $SwipeSourcesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._swipeSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).swipeSourcesRefs,
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
        bool swipeSourcesRefs,
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
      Value<String?> trashId,
      Value<DateTime?> leftTrashAt,
      Value<TrashExit?> leftTrashReason,
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
      Value<String?> trashId,
      Value<DateTime?> leftTrashAt,
      Value<TrashExit?> leftTrashReason,
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

  ColumnFilters<String> get trashId => $composableBuilder(
    column: $table.trashId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leftTrashAt => $composableBuilder(
    column: $table.leftTrashAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TrashExit?, TrashExit, String>
  get leftTrashReason => $composableBuilder(
    column: $table.leftTrashReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get trashId => $composableBuilder(
    column: $table.trashId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leftTrashAt => $composableBuilder(
    column: $table.leftTrashAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leftTrashReason => $composableBuilder(
    column: $table.leftTrashReason,
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

  GeneratedColumn<String> get trashId =>
      $composableBuilder(column: $table.trashId, builder: (column) => column);

  GeneratedColumn<DateTime> get leftTrashAt => $composableBuilder(
    column: $table.leftTrashAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TrashExit?, String> get leftTrashReason =>
      $composableBuilder(
        column: $table.leftTrashReason,
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
                Value<String?> trashId = const Value.absent(),
                Value<DateTime?> leftTrashAt = const Value.absent(),
                Value<TrashExit?> leftTrashReason = const Value.absent(),
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
                trashId: trashId,
                leftTrashAt: leftTrashAt,
                leftTrashReason: leftTrashReason,
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
                Value<String?> trashId = const Value.absent(),
                Value<DateTime?> leftTrashAt = const Value.absent(),
                Value<TrashExit?> leftTrashReason = const Value.absent(),
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
                trashId: trashId,
                leftTrashAt: leftTrashAt,
                leftTrashReason: leftTrashReason,
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
typedef $$ReviewedLabelsTableCreateCompanionBuilder =
    ReviewedLabelsCompanion Function({
      Value<int> actionId,
      required String fileId,
      required int presetKey,
      required String actionType,
      Value<String?> actionDetail,
      required DateTime reviewedAt,
      required int fileModifiedAtMs,
    });
typedef $$ReviewedLabelsTableUpdateCompanionBuilder =
    ReviewedLabelsCompanion Function({
      Value<int> actionId,
      Value<String> fileId,
      Value<int> presetKey,
      Value<String> actionType,
      Value<String?> actionDetail,
      Value<DateTime> reviewedAt,
      Value<int> fileModifiedAtMs,
    });

class $$ReviewedLabelsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewedLabelsTable> {
  $$ReviewedLabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get presetKey => $composableBuilder(
    column: $table.presetKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionDetail => $composableBuilder(
    column: $table.actionDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewedLabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewedLabelsTable> {
  $$ReviewedLabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get presetKey => $composableBuilder(
    column: $table.presetKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionDetail => $composableBuilder(
    column: $table.actionDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewedLabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewedLabelsTable> {
  $$ReviewedLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get presetKey =>
      $composableBuilder(column: $table.presetKey, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionDetail => $composableBuilder(
    column: $table.actionDetail,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => column,
  );
}

class $$ReviewedLabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewedLabelsTable,
          ReviewedLabelRow,
          $$ReviewedLabelsTableFilterComposer,
          $$ReviewedLabelsTableOrderingComposer,
          $$ReviewedLabelsTableAnnotationComposer,
          $$ReviewedLabelsTableCreateCompanionBuilder,
          $$ReviewedLabelsTableUpdateCompanionBuilder,
          (
            ReviewedLabelRow,
            BaseReferences<
              _$AppDatabase,
              $ReviewedLabelsTable,
              ReviewedLabelRow
            >,
          ),
          ReviewedLabelRow,
          PrefetchHooks Function()
        > {
  $$ReviewedLabelsTableTableManager(
    _$AppDatabase db,
    $ReviewedLabelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewedLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewedLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewedLabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> actionId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> presetKey = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String?> actionDetail = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> fileModifiedAtMs = const Value.absent(),
              }) => ReviewedLabelsCompanion(
                actionId: actionId,
                fileId: fileId,
                presetKey: presetKey,
                actionType: actionType,
                actionDetail: actionDetail,
                reviewedAt: reviewedAt,
                fileModifiedAtMs: fileModifiedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> actionId = const Value.absent(),
                required String fileId,
                required int presetKey,
                required String actionType,
                Value<String?> actionDetail = const Value.absent(),
                required DateTime reviewedAt,
                required int fileModifiedAtMs,
              }) => ReviewedLabelsCompanion.insert(
                actionId: actionId,
                fileId: fileId,
                presetKey: presetKey,
                actionType: actionType,
                actionDetail: actionDetail,
                reviewedAt: reviewedAt,
                fileModifiedAtMs: fileModifiedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewedLabelsTable, ReviewedLabelRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReviewedLabelsTable,
                    ReviewedLabelRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewedLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewedLabelsTable,
      ReviewedLabelRow,
      $$ReviewedLabelsTableFilterComposer,
      $$ReviewedLabelsTableOrderingComposer,
      $$ReviewedLabelsTableAnnotationComposer,
      $$ReviewedLabelsTableCreateCompanionBuilder,
      $$ReviewedLabelsTableUpdateCompanionBuilder,
      (
        ReviewedLabelRow,
        BaseReferences<_$AppDatabase, $ReviewedLabelsTable, ReviewedLabelRow>,
      ),
      ReviewedLabelRow,
      PrefetchHooks Function()
    >;
typedef $$SelectionItemsTableCreateCompanionBuilder =
    SelectionItemsCompanion Function({
      required String fileId,
      required int seq,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$SelectionItemsTableUpdateCompanionBuilder =
    SelectionItemsCompanion Function({
      Value<String> fileId,
      Value<int> seq,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$SelectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SelectionItemsTable> {
  $$SelectionItemsTableFilterComposer({
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

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SelectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SelectionItemsTable> {
  $$SelectionItemsTableOrderingComposer({
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

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SelectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SelectionItemsTable> {
  $$SelectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SelectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SelectionItemsTable,
          SelectionItemRow,
          $$SelectionItemsTableFilterComposer,
          $$SelectionItemsTableOrderingComposer,
          $$SelectionItemsTableAnnotationComposer,
          $$SelectionItemsTableCreateCompanionBuilder,
          $$SelectionItemsTableUpdateCompanionBuilder,
          (
            SelectionItemRow,
            BaseReferences<
              _$AppDatabase,
              $SelectionItemsTable,
              SelectionItemRow
            >,
          ),
          SelectionItemRow,
          PrefetchHooks Function()
        > {
  $$SelectionItemsTableTableManager(
    _$AppDatabase db,
    $SelectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectionItemsCompanion(
                fileId: fileId,
                seq: seq,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required int seq,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => SelectionItemsCompanion.insert(
                fileId: fileId,
                seq: seq,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SelectionItemsTable, SelectionItemRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SelectionItemsTable,
                    SelectionItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SelectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SelectionItemsTable,
      SelectionItemRow,
      $$SelectionItemsTableFilterComposer,
      $$SelectionItemsTableOrderingComposer,
      $$SelectionItemsTableAnnotationComposer,
      $$SelectionItemsTableCreateCompanionBuilder,
      $$SelectionItemsTableUpdateCompanionBuilder,
      (
        SelectionItemRow,
        BaseReferences<_$AppDatabase, $SelectionItemsTable, SelectionItemRow>,
      ),
      SelectionItemRow,
      PrefetchHooks Function()
    >;
typedef $$SelectionSnapshotsTableCreateCompanionBuilder =
    SelectionSnapshotsCompanion Function({
      required String fileId,
      required int seq,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$SelectionSnapshotsTableUpdateCompanionBuilder =
    SelectionSnapshotsCompanion Function({
      Value<String> fileId,
      Value<int> seq,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$SelectionSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SelectionSnapshotsTable> {
  $$SelectionSnapshotsTableFilterComposer({
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

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SelectionSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SelectionSnapshotsTable> {
  $$SelectionSnapshotsTableOrderingComposer({
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

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SelectionSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SelectionSnapshotsTable> {
  $$SelectionSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SelectionSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SelectionSnapshotsTable,
          SelectionSnapshotRow,
          $$SelectionSnapshotsTableFilterComposer,
          $$SelectionSnapshotsTableOrderingComposer,
          $$SelectionSnapshotsTableAnnotationComposer,
          $$SelectionSnapshotsTableCreateCompanionBuilder,
          $$SelectionSnapshotsTableUpdateCompanionBuilder,
          (
            SelectionSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $SelectionSnapshotsTable,
              SelectionSnapshotRow
            >,
          ),
          SelectionSnapshotRow,
          PrefetchHooks Function()
        > {
  $$SelectionSnapshotsTableTableManager(
    _$AppDatabase db,
    $SelectionSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelectionSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelectionSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelectionSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectionSnapshotsCompanion(
                fileId: fileId,
                seq: seq,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required int seq,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => SelectionSnapshotsCompanion.insert(
                fileId: fileId,
                seq: seq,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SelectionSnapshotsTable, SelectionSnapshotRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SelectionSnapshotsTable,
                    SelectionSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SelectionSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SelectionSnapshotsTable,
      SelectionSnapshotRow,
      $$SelectionSnapshotsTableFilterComposer,
      $$SelectionSnapshotsTableOrderingComposer,
      $$SelectionSnapshotsTableAnnotationComposer,
      $$SelectionSnapshotsTableCreateCompanionBuilder,
      $$SelectionSnapshotsTableUpdateCompanionBuilder,
      (
        SelectionSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $SelectionSnapshotsTable,
          SelectionSnapshotRow
        >,
      ),
      SelectionSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$SwipeSourcesTableCreateCompanionBuilder =
    SwipeSourcesCompanion Function({
      Value<int> id,
      required int sessionId,
      required SwipeSourceKind kind,
      required SwipeSourceOrigin origin,
      required String title,
      Value<String?> filterJson,
      Value<int> itemCount,
      Value<int?> groupCount,
      Value<String?> returnRoute,
      required int openedAfterSeq,
      Value<int?> closedAtSeq,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
    });
typedef $$SwipeSourcesTableUpdateCompanionBuilder =
    SwipeSourcesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<SwipeSourceKind> kind,
      Value<SwipeSourceOrigin> origin,
      Value<String> title,
      Value<String?> filterJson,
      Value<int> itemCount,
      Value<int?> groupCount,
      Value<String?> returnRoute,
      Value<int> openedAfterSeq,
      Value<int?> closedAtSeq,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
    });

final class $$SwipeSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SwipeSourcesTable, SwipeSourceRow> {
  $$SwipeSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('swipe_sources__session_id__sessions__id');

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

  static MultiTypedResultKey<$SwipeSourceItemsTable, List<SwipeSourceItemRow>>
  _swipeSourceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.swipeSourceItems,
    aliasName: 'swipe_sources__id__swipe_source_items__source_id',
  );

  $$SwipeSourceItemsTableProcessedTableManager get swipeSourceItemsRefs {
    final manager = $$SwipeSourceItemsTableTableManager(
      $_db,
      $_db.swipeSourceItems,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _swipeSourceItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SwipeSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SwipeSourcesTable> {
  $$SwipeSourcesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SwipeSourceKind, SwipeSourceKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SwipeSourceOrigin, SwipeSourceOrigin, String>
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupCount => $composableBuilder(
    column: $table.groupCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnRoute => $composableBuilder(
    column: $table.returnRoute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedAfterSeq => $composableBuilder(
    column: $table.openedAfterSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedAtSeq => $composableBuilder(
    column: $table.closedAtSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
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

  Expression<bool> swipeSourceItemsRefs(
    Expression<bool> Function($$SwipeSourceItemsTableFilterComposer f) f,
  ) {
    final $$SwipeSourceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.swipeSourceItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourceItemsTableFilterComposer(
            $db: $db,
            $table: $db.swipeSourceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SwipeSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SwipeSourcesTable> {
  $$SwipeSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupCount => $composableBuilder(
    column: $table.groupCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnRoute => $composableBuilder(
    column: $table.returnRoute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedAfterSeq => $composableBuilder(
    column: $table.openedAfterSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedAtSeq => $composableBuilder(
    column: $table.closedAtSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
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

class $$SwipeSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SwipeSourcesTable> {
  $$SwipeSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SwipeSourceKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SwipeSourceOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get groupCount => $composableBuilder(
    column: $table.groupCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnRoute => $composableBuilder(
    column: $table.returnRoute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openedAfterSeq => $composableBuilder(
    column: $table.openedAfterSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closedAtSeq => $composableBuilder(
    column: $table.closedAtSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

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

  Expression<T> swipeSourceItemsRefs<T extends Object>(
    Expression<T> Function($$SwipeSourceItemsTableAnnotationComposer a) f,
  ) {
    final $$SwipeSourceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.swipeSourceItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.swipeSourceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SwipeSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SwipeSourcesTable,
          SwipeSourceRow,
          $$SwipeSourcesTableFilterComposer,
          $$SwipeSourcesTableOrderingComposer,
          $$SwipeSourcesTableAnnotationComposer,
          $$SwipeSourcesTableCreateCompanionBuilder,
          $$SwipeSourcesTableUpdateCompanionBuilder,
          (SwipeSourceRow, $$SwipeSourcesTableReferences),
          SwipeSourceRow,
          PrefetchHooks Function({bool sessionId, bool swipeSourceItemsRefs})
        > {
  $$SwipeSourcesTableTableManager(_$AppDatabase db, $SwipeSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SwipeSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SwipeSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SwipeSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<SwipeSourceKind> kind = const Value.absent(),
                Value<SwipeSourceOrigin> origin = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> filterJson = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int?> groupCount = const Value.absent(),
                Value<String?> returnRoute = const Value.absent(),
                Value<int> openedAfterSeq = const Value.absent(),
                Value<int?> closedAtSeq = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => SwipeSourcesCompanion(
                id: id,
                sessionId: sessionId,
                kind: kind,
                origin: origin,
                title: title,
                filterJson: filterJson,
                itemCount: itemCount,
                groupCount: groupCount,
                returnRoute: returnRoute,
                openedAfterSeq: openedAfterSeq,
                closedAtSeq: closedAtSeq,
                openedAt: openedAt,
                closedAt: closedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required SwipeSourceKind kind,
                required SwipeSourceOrigin origin,
                required String title,
                Value<String?> filterJson = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int?> groupCount = const Value.absent(),
                Value<String?> returnRoute = const Value.absent(),
                required int openedAfterSeq,
                Value<int?> closedAtSeq = const Value.absent(),
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
              }) => SwipeSourcesCompanion.insert(
                id: id,
                sessionId: sessionId,
                kind: kind,
                origin: origin,
                title: title,
                filterJson: filterJson,
                itemCount: itemCount,
                groupCount: groupCount,
                returnRoute: returnRoute,
                openedAfterSeq: openedAfterSeq,
                closedAtSeq: closedAtSeq,
                openedAt: openedAt,
                closedAt: closedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SwipeSourcesTable, SwipeSourceRow>(table),
                  $$SwipeSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, swipeSourceItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (swipeSourceItemsRefs) db.swipeSourceItems,
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
                            referencedTable: $$SwipeSourcesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$SwipeSourcesTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (swipeSourceItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          SwipeSourceRow,
                          $SwipeSourcesTable,
                          SwipeSourceItemRow,
                          $SwipeSourceItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SwipeSourcesTableReferences
                              ._swipeSourceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SwipeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).swipeSourceItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SwipeSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SwipeSourcesTable,
      SwipeSourceRow,
      $$SwipeSourcesTableFilterComposer,
      $$SwipeSourcesTableOrderingComposer,
      $$SwipeSourcesTableAnnotationComposer,
      $$SwipeSourcesTableCreateCompanionBuilder,
      $$SwipeSourcesTableUpdateCompanionBuilder,
      (SwipeSourceRow, $$SwipeSourcesTableReferences),
      SwipeSourceRow,
      PrefetchHooks Function({bool sessionId, bool swipeSourceItemsRefs})
    >;
typedef $$SwipeSourceItemsTableCreateCompanionBuilder =
    SwipeSourceItemsCompanion Function({
      required int sourceId,
      required int position,
      required String fileId,
      Value<int?> groupIndex,
      Value<int> rowid,
    });
typedef $$SwipeSourceItemsTableUpdateCompanionBuilder =
    SwipeSourceItemsCompanion Function({
      Value<int> sourceId,
      Value<int> position,
      Value<String> fileId,
      Value<int?> groupIndex,
      Value<int> rowid,
    });

final class $$SwipeSourceItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SwipeSourceItemsTable,
          SwipeSourceItemRow
        > {
  $$SwipeSourceItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SwipeSourcesTable _sourceIdTable(_$AppDatabase db) => db.swipeSources
      .createAlias('swipe_source_items__source_id__swipe_sources__id');

  $$SwipeSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SwipeSourcesTableTableManager(
      $_db,
      $_db.swipeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SwipeSourceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SwipeSourceItemsTable> {
  $$SwipeSourceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$SwipeSourcesTableFilterComposer get sourceId {
    final $$SwipeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.swipeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.swipeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SwipeSourceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SwipeSourceItemsTable> {
  $$SwipeSourceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$SwipeSourcesTableOrderingComposer get sourceId {
    final $$SwipeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.swipeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.swipeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SwipeSourceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SwipeSourceItemsTable> {
  $$SwipeSourceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => column,
  );

  $$SwipeSourcesTableAnnotationComposer get sourceId {
    final $$SwipeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.swipeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SwipeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.swipeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SwipeSourceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SwipeSourceItemsTable,
          SwipeSourceItemRow,
          $$SwipeSourceItemsTableFilterComposer,
          $$SwipeSourceItemsTableOrderingComposer,
          $$SwipeSourceItemsTableAnnotationComposer,
          $$SwipeSourceItemsTableCreateCompanionBuilder,
          $$SwipeSourceItemsTableUpdateCompanionBuilder,
          (SwipeSourceItemRow, $$SwipeSourceItemsTableReferences),
          SwipeSourceItemRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$SwipeSourceItemsTableTableManager(
    _$AppDatabase db,
    $SwipeSourceItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SwipeSourceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SwipeSourceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SwipeSourceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int?> groupIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SwipeSourceItemsCompanion(
                sourceId: sourceId,
                position: position,
                fileId: fileId,
                groupIndex: groupIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int position,
                required String fileId,
                Value<int?> groupIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SwipeSourceItemsCompanion.insert(
                sourceId: sourceId,
                position: position,
                fileId: fileId,
                groupIndex: groupIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SwipeSourceItemsTable, SwipeSourceItemRow>(
                    table,
                  ),
                  $$SwipeSourceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$SwipeSourceItemsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$SwipeSourceItemsTableReferences
                            ._sourceIdTable(db)
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

typedef $$SwipeSourceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SwipeSourceItemsTable,
      SwipeSourceItemRow,
      $$SwipeSourceItemsTableFilterComposer,
      $$SwipeSourceItemsTableOrderingComposer,
      $$SwipeSourceItemsTableAnnotationComposer,
      $$SwipeSourceItemsTableCreateCompanionBuilder,
      $$SwipeSourceItemsTableUpdateCompanionBuilder,
      (SwipeSourceItemRow, $$SwipeSourceItemsTableReferences),
      SwipeSourceItemRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$ImageSignalsTableCreateCompanionBuilder =
    ImageSignalsCompanion Function({
      required String fileId,
      required SignalStatus status,
      Value<int?> dHash,
      Value<double?> blurScore,
      required int fileModifiedAtMs,
      required int algoVersion,
      Value<int> rowid,
    });
typedef $$ImageSignalsTableUpdateCompanionBuilder =
    ImageSignalsCompanion Function({
      Value<String> fileId,
      Value<SignalStatus> status,
      Value<int?> dHash,
      Value<double?> blurScore,
      Value<int> fileModifiedAtMs,
      Value<int> algoVersion,
      Value<int> rowid,
    });

class $$ImageSignalsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageSignalsTable> {
  $$ImageSignalsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SignalStatus, SignalStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get dHash => $composableBuilder(
    column: $table.dHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get blurScore => $composableBuilder(
    column: $table.blurScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get algoVersion => $composableBuilder(
    column: $table.algoVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImageSignalsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageSignalsTable> {
  $$ImageSignalsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dHash => $composableBuilder(
    column: $table.dHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get blurScore => $composableBuilder(
    column: $table.blurScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get algoVersion => $composableBuilder(
    column: $table.algoVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImageSignalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageSignalsTable> {
  $$ImageSignalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SignalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get dHash =>
      $composableBuilder(column: $table.dHash, builder: (column) => column);

  GeneratedColumn<double> get blurScore =>
      $composableBuilder(column: $table.blurScore, builder: (column) => column);

  GeneratedColumn<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get algoVersion => $composableBuilder(
    column: $table.algoVersion,
    builder: (column) => column,
  );
}

class $$ImageSignalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageSignalsTable,
          ImageSignalRow,
          $$ImageSignalsTableFilterComposer,
          $$ImageSignalsTableOrderingComposer,
          $$ImageSignalsTableAnnotationComposer,
          $$ImageSignalsTableCreateCompanionBuilder,
          $$ImageSignalsTableUpdateCompanionBuilder,
          (
            ImageSignalRow,
            BaseReferences<_$AppDatabase, $ImageSignalsTable, ImageSignalRow>,
          ),
          ImageSignalRow,
          PrefetchHooks Function()
        > {
  $$ImageSignalsTableTableManager(_$AppDatabase db, $ImageSignalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageSignalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageSignalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageSignalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<SignalStatus> status = const Value.absent(),
                Value<int?> dHash = const Value.absent(),
                Value<double?> blurScore = const Value.absent(),
                Value<int> fileModifiedAtMs = const Value.absent(),
                Value<int> algoVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageSignalsCompanion(
                fileId: fileId,
                status: status,
                dHash: dHash,
                blurScore: blurScore,
                fileModifiedAtMs: fileModifiedAtMs,
                algoVersion: algoVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required SignalStatus status,
                Value<int?> dHash = const Value.absent(),
                Value<double?> blurScore = const Value.absent(),
                required int fileModifiedAtMs,
                required int algoVersion,
                Value<int> rowid = const Value.absent(),
              }) => ImageSignalsCompanion.insert(
                fileId: fileId,
                status: status,
                dHash: dHash,
                blurScore: blurScore,
                fileModifiedAtMs: fileModifiedAtMs,
                algoVersion: algoVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImageSignalsTable, ImageSignalRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImageSignalsTable,
                    ImageSignalRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImageSignalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageSignalsTable,
      ImageSignalRow,
      $$ImageSignalsTableFilterComposer,
      $$ImageSignalsTableOrderingComposer,
      $$ImageSignalsTableAnnotationComposer,
      $$ImageSignalsTableCreateCompanionBuilder,
      $$ImageSignalsTableUpdateCompanionBuilder,
      (
        ImageSignalRow,
        BaseReferences<_$AppDatabase, $ImageSignalsTable, ImageSignalRow>,
      ),
      ImageSignalRow,
      PrefetchHooks Function()
    >;
typedef $$SimilarGroupsTableCreateCompanionBuilder =
    SimilarGroupsCompanion Function({
      Value<int> id,
      required String suggestedFileId,
      required int memberCount,
      required int sortDateMs,
      required DateTime createdAt,
    });
typedef $$SimilarGroupsTableUpdateCompanionBuilder =
    SimilarGroupsCompanion Function({
      Value<int> id,
      Value<String> suggestedFileId,
      Value<int> memberCount,
      Value<int> sortDateMs,
      Value<DateTime> createdAt,
    });

final class $$SimilarGroupsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SimilarGroupsTable, SimilarGroupRow> {
  $$SimilarGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SimilarGroupItemsTable, List<SimilarGroupItemRow>>
  _similarGroupItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.similarGroupItems,
        aliasName: 'similar_groups__id__similar_group_items__group_id',
      );

  $$SimilarGroupItemsTableProcessedTableManager get similarGroupItemsRefs {
    final manager = $$SimilarGroupItemsTableTableManager(
      $_db,
      $_db.similarGroupItems,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _similarGroupItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SimilarGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $SimilarGroupsTable> {
  $$SimilarGroupsTableFilterComposer({
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

  ColumnFilters<String> get suggestedFileId => $composableBuilder(
    column: $table.suggestedFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> similarGroupItemsRefs(
    Expression<bool> Function($$SimilarGroupItemsTableFilterComposer f) f,
  ) {
    final $$SimilarGroupItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.similarGroupItems,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimilarGroupItemsTableFilterComposer(
            $db: $db,
            $table: $db.similarGroupItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SimilarGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SimilarGroupsTable> {
  $$SimilarGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get suggestedFileId => $composableBuilder(
    column: $table.suggestedFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SimilarGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SimilarGroupsTable> {
  $$SimilarGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get suggestedFileId => $composableBuilder(
    column: $table.suggestedFileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortDateMs => $composableBuilder(
    column: $table.sortDateMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> similarGroupItemsRefs<T extends Object>(
    Expression<T> Function($$SimilarGroupItemsTableAnnotationComposer a) f,
  ) {
    final $$SimilarGroupItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.similarGroupItems,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SimilarGroupItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.similarGroupItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SimilarGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SimilarGroupsTable,
          SimilarGroupRow,
          $$SimilarGroupsTableFilterComposer,
          $$SimilarGroupsTableOrderingComposer,
          $$SimilarGroupsTableAnnotationComposer,
          $$SimilarGroupsTableCreateCompanionBuilder,
          $$SimilarGroupsTableUpdateCompanionBuilder,
          (SimilarGroupRow, $$SimilarGroupsTableReferences),
          SimilarGroupRow,
          PrefetchHooks Function({bool similarGroupItemsRefs})
        > {
  $$SimilarGroupsTableTableManager(_$AppDatabase db, $SimilarGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimilarGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimilarGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimilarGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> suggestedFileId = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<int> sortDateMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SimilarGroupsCompanion(
                id: id,
                suggestedFileId: suggestedFileId,
                memberCount: memberCount,
                sortDateMs: sortDateMs,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String suggestedFileId,
                required int memberCount,
                required int sortDateMs,
                required DateTime createdAt,
              }) => SimilarGroupsCompanion.insert(
                id: id,
                suggestedFileId: suggestedFileId,
                memberCount: memberCount,
                sortDateMs: sortDateMs,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SimilarGroupsTable, SimilarGroupRow>(table),
                  $$SimilarGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({similarGroupItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (similarGroupItemsRefs) db.similarGroupItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (similarGroupItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      SimilarGroupRow,
                      $SimilarGroupsTable,
                      SimilarGroupItemRow,
                      $SimilarGroupItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$SimilarGroupsTableReferences
                          ._similarGroupItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SimilarGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).similarGroupItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'group_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SimilarGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SimilarGroupsTable,
      SimilarGroupRow,
      $$SimilarGroupsTableFilterComposer,
      $$SimilarGroupsTableOrderingComposer,
      $$SimilarGroupsTableAnnotationComposer,
      $$SimilarGroupsTableCreateCompanionBuilder,
      $$SimilarGroupsTableUpdateCompanionBuilder,
      (SimilarGroupRow, $$SimilarGroupsTableReferences),
      SimilarGroupRow,
      PrefetchHooks Function({bool similarGroupItemsRefs})
    >;
typedef $$SimilarGroupItemsTableCreateCompanionBuilder =
    SimilarGroupItemsCompanion Function({
      required int groupId,
      required String fileId,
      required int position,
      Value<int> rowid,
    });
typedef $$SimilarGroupItemsTableUpdateCompanionBuilder =
    SimilarGroupItemsCompanion Function({
      Value<int> groupId,
      Value<String> fileId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$SimilarGroupItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SimilarGroupItemsTable,
          SimilarGroupItemRow
        > {
  $$SimilarGroupItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SimilarGroupsTable _groupIdTable(_$AppDatabase db) => db.similarGroups
      .createAlias('similar_group_items__group_id__similar_groups__id');

  $$SimilarGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$SimilarGroupsTableTableManager(
      $_db,
      $_db.similarGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SimilarGroupItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SimilarGroupItemsTable> {
  $$SimilarGroupItemsTableFilterComposer({
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

  $$SimilarGroupsTableFilterComposer get groupId {
    final $$SimilarGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.similarGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimilarGroupsTableFilterComposer(
            $db: $db,
            $table: $db.similarGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SimilarGroupItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SimilarGroupItemsTable> {
  $$SimilarGroupItemsTableOrderingComposer({
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

  $$SimilarGroupsTableOrderingComposer get groupId {
    final $$SimilarGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.similarGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimilarGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.similarGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SimilarGroupItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SimilarGroupItemsTable> {
  $$SimilarGroupItemsTableAnnotationComposer({
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

  $$SimilarGroupsTableAnnotationComposer get groupId {
    final $$SimilarGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.similarGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimilarGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.similarGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SimilarGroupItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SimilarGroupItemsTable,
          SimilarGroupItemRow,
          $$SimilarGroupItemsTableFilterComposer,
          $$SimilarGroupItemsTableOrderingComposer,
          $$SimilarGroupItemsTableAnnotationComposer,
          $$SimilarGroupItemsTableCreateCompanionBuilder,
          $$SimilarGroupItemsTableUpdateCompanionBuilder,
          (SimilarGroupItemRow, $$SimilarGroupItemsTableReferences),
          SimilarGroupItemRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$SimilarGroupItemsTableTableManager(
    _$AppDatabase db,
    $SimilarGroupItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimilarGroupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimilarGroupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimilarGroupItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SimilarGroupItemsCompanion(
                groupId: groupId,
                fileId: fileId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int groupId,
                required String fileId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => SimilarGroupItemsCompanion.insert(
                groupId: groupId,
                fileId: fileId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SimilarGroupItemsTable, SimilarGroupItemRow>(
                    table,
                  ),
                  $$SimilarGroupItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
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
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$SimilarGroupItemsTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$SimilarGroupItemsTableReferences
                            ._groupIdTable(db)
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

typedef $$SimilarGroupItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SimilarGroupItemsTable,
      SimilarGroupItemRow,
      $$SimilarGroupItemsTableFilterComposer,
      $$SimilarGroupItemsTableOrderingComposer,
      $$SimilarGroupItemsTableAnnotationComposer,
      $$SimilarGroupItemsTableCreateCompanionBuilder,
      $$SimilarGroupItemsTableUpdateCompanionBuilder,
      (SimilarGroupItemRow, $$SimilarGroupItemsTableReferences),
      SimilarGroupItemRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$SimilarDismissedTableCreateCompanionBuilder =
    SimilarDismissedCompanion Function({
      required String fileId,
      required DateTime dismissedAt,
      Value<int> rowid,
    });
typedef $$SimilarDismissedTableUpdateCompanionBuilder =
    SimilarDismissedCompanion Function({
      Value<String> fileId,
      Value<DateTime> dismissedAt,
      Value<int> rowid,
    });

class $$SimilarDismissedTableFilterComposer
    extends Composer<_$AppDatabase, $SimilarDismissedTable> {
  $$SimilarDismissedTableFilterComposer({
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

  ColumnFilters<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SimilarDismissedTableOrderingComposer
    extends Composer<_$AppDatabase, $SimilarDismissedTable> {
  $$SimilarDismissedTableOrderingComposer({
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

  ColumnOrderings<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SimilarDismissedTableAnnotationComposer
    extends Composer<_$AppDatabase, $SimilarDismissedTable> {
  $$SimilarDismissedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => column,
  );
}

class $$SimilarDismissedTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SimilarDismissedTable,
          SimilarDismissedRow,
          $$SimilarDismissedTableFilterComposer,
          $$SimilarDismissedTableOrderingComposer,
          $$SimilarDismissedTableAnnotationComposer,
          $$SimilarDismissedTableCreateCompanionBuilder,
          $$SimilarDismissedTableUpdateCompanionBuilder,
          (
            SimilarDismissedRow,
            BaseReferences<
              _$AppDatabase,
              $SimilarDismissedTable,
              SimilarDismissedRow
            >,
          ),
          SimilarDismissedRow,
          PrefetchHooks Function()
        > {
  $$SimilarDismissedTableTableManager(
    _$AppDatabase db,
    $SimilarDismissedTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimilarDismissedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimilarDismissedTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimilarDismissedTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<DateTime> dismissedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SimilarDismissedCompanion(
                fileId: fileId,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required DateTime dismissedAt,
                Value<int> rowid = const Value.absent(),
              }) => SimilarDismissedCompanion.insert(
                fileId: fileId,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SimilarDismissedTable, SimilarDismissedRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SimilarDismissedTable,
                    SimilarDismissedRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SimilarDismissedTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SimilarDismissedTable,
      SimilarDismissedRow,
      $$SimilarDismissedTableFilterComposer,
      $$SimilarDismissedTableOrderingComposer,
      $$SimilarDismissedTableAnnotationComposer,
      $$SimilarDismissedTableCreateCompanionBuilder,
      $$SimilarDismissedTableUpdateCompanionBuilder,
      (
        SimilarDismissedRow,
        BaseReferences<
          _$AppDatabase,
          $SimilarDismissedTable,
          SimilarDismissedRow
        >,
      ),
      SimilarDismissedRow,
      PrefetchHooks Function()
    >;
typedef $$MediaLocationsTableCreateCompanionBuilder =
    MediaLocationsCompanion Function({
      required String fileId,
      required int fileModifiedAtMs,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> frontCamera,
      required bool locationReadable,
      required int readAtMs,
      Value<int> rowid,
    });
typedef $$MediaLocationsTableUpdateCompanionBuilder =
    MediaLocationsCompanion Function({
      Value<String> fileId,
      Value<int> fileModifiedAtMs,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> frontCamera,
      Value<bool> locationReadable,
      Value<int> readAtMs,
      Value<int> rowid,
    });

class $$MediaLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaLocationsTable> {
  $$MediaLocationsTableFilterComposer({
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

  ColumnFilters<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get frontCamera => $composableBuilder(
    column: $table.frontCamera,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get locationReadable => $composableBuilder(
    column: $table.locationReadable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAtMs => $composableBuilder(
    column: $table.readAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaLocationsTable> {
  $$MediaLocationsTableOrderingComposer({
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

  ColumnOrderings<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get frontCamera => $composableBuilder(
    column: $table.frontCamera,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locationReadable => $composableBuilder(
    column: $table.locationReadable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAtMs => $composableBuilder(
    column: $table.readAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaLocationsTable> {
  $$MediaLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<bool> get frontCamera => $composableBuilder(
    column: $table.frontCamera,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get locationReadable => $composableBuilder(
    column: $table.locationReadable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readAtMs =>
      $composableBuilder(column: $table.readAtMs, builder: (column) => column);
}

class $$MediaLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaLocationsTable,
          MediaLocationRow,
          $$MediaLocationsTableFilterComposer,
          $$MediaLocationsTableOrderingComposer,
          $$MediaLocationsTableAnnotationComposer,
          $$MediaLocationsTableCreateCompanionBuilder,
          $$MediaLocationsTableUpdateCompanionBuilder,
          (
            MediaLocationRow,
            BaseReferences<
              _$AppDatabase,
              $MediaLocationsTable,
              MediaLocationRow
            >,
          ),
          MediaLocationRow,
          PrefetchHooks Function()
        > {
  $$MediaLocationsTableTableManager(
    _$AppDatabase db,
    $MediaLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<int> fileModifiedAtMs = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> frontCamera = const Value.absent(),
                Value<bool> locationReadable = const Value.absent(),
                Value<int> readAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaLocationsCompanion(
                fileId: fileId,
                fileModifiedAtMs: fileModifiedAtMs,
                lat: lat,
                lng: lng,
                frontCamera: frontCamera,
                locationReadable: locationReadable,
                readAtMs: readAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required int fileModifiedAtMs,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> frontCamera = const Value.absent(),
                required bool locationReadable,
                required int readAtMs,
                Value<int> rowid = const Value.absent(),
              }) => MediaLocationsCompanion.insert(
                fileId: fileId,
                fileModifiedAtMs: fileModifiedAtMs,
                lat: lat,
                lng: lng,
                frontCamera: frontCamera,
                locationReadable: locationReadable,
                readAtMs: readAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaLocationsTable, MediaLocationRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MediaLocationsTable,
                    MediaLocationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaLocationsTable,
      MediaLocationRow,
      $$MediaLocationsTableFilterComposer,
      $$MediaLocationsTableOrderingComposer,
      $$MediaLocationsTableAnnotationComposer,
      $$MediaLocationsTableCreateCompanionBuilder,
      $$MediaLocationsTableUpdateCompanionBuilder,
      (
        MediaLocationRow,
        BaseReferences<_$AppDatabase, $MediaLocationsTable, MediaLocationRow>,
      ),
      MediaLocationRow,
      PrefetchHooks Function()
    >;
typedef $$SmartGroupsTableCreateCompanionBuilder =
    SmartGroupsCompanion Function({
      Value<int> id,
      required SmartGroupKind kind,
      required int rank,
      required int startAtMs,
      required int endAtMs,
      Value<double?> centerLat,
      Value<double?> centerLng,
      required String coverFileId,
      required int itemCount,
      Value<String?> userTitle,
      Value<String?> placeName,
      Value<int?> geocodedAtMs,
    });
typedef $$SmartGroupsTableUpdateCompanionBuilder =
    SmartGroupsCompanion Function({
      Value<int> id,
      Value<SmartGroupKind> kind,
      Value<int> rank,
      Value<int> startAtMs,
      Value<int> endAtMs,
      Value<double?> centerLat,
      Value<double?> centerLng,
      Value<String> coverFileId,
      Value<int> itemCount,
      Value<String?> userTitle,
      Value<String?> placeName,
      Value<int?> geocodedAtMs,
    });

final class $$SmartGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $SmartGroupsTable, SmartGroupRow> {
  $$SmartGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SmartGroupItemsTable, List<SmartGroupItemRow>>
  _smartGroupItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.smartGroupItems,
    aliasName: 'smart_groups__id__smart_group_items__group_id',
  );

  $$SmartGroupItemsTableProcessedTableManager get smartGroupItemsRefs {
    final manager = $$SmartGroupItemsTableTableManager(
      $_db,
      $_db.smartGroupItems,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _smartGroupItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SmartGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartGroupsTable> {
  $$SmartGroupsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SmartGroupKind, SmartGroupKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAtMs => $composableBuilder(
    column: $table.startAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAtMs => $composableBuilder(
    column: $table.endAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLat => $composableBuilder(
    column: $table.centerLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLng => $composableBuilder(
    column: $table.centerLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverFileId => $composableBuilder(
    column: $table.coverFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userTitle => $composableBuilder(
    column: $table.userTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get geocodedAtMs => $composableBuilder(
    column: $table.geocodedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> smartGroupItemsRefs(
    Expression<bool> Function($$SmartGroupItemsTableFilterComposer f) f,
  ) {
    final $$SmartGroupItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smartGroupItems,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartGroupItemsTableFilterComposer(
            $db: $db,
            $table: $db.smartGroupItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SmartGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartGroupsTable> {
  $$SmartGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAtMs => $composableBuilder(
    column: $table.startAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAtMs => $composableBuilder(
    column: $table.endAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLat => $composableBuilder(
    column: $table.centerLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLng => $composableBuilder(
    column: $table.centerLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverFileId => $composableBuilder(
    column: $table.coverFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userTitle => $composableBuilder(
    column: $table.userTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get geocodedAtMs => $composableBuilder(
    column: $table.geocodedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartGroupsTable> {
  $$SmartGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SmartGroupKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<int> get startAtMs =>
      $composableBuilder(column: $table.startAtMs, builder: (column) => column);

  GeneratedColumn<int> get endAtMs =>
      $composableBuilder(column: $table.endAtMs, builder: (column) => column);

  GeneratedColumn<double> get centerLat =>
      $composableBuilder(column: $table.centerLat, builder: (column) => column);

  GeneratedColumn<double> get centerLng =>
      $composableBuilder(column: $table.centerLng, builder: (column) => column);

  GeneratedColumn<String> get coverFileId => $composableBuilder(
    column: $table.coverFileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get userTitle =>
      $composableBuilder(column: $table.userTitle, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumn<int> get geocodedAtMs => $composableBuilder(
    column: $table.geocodedAtMs,
    builder: (column) => column,
  );

  Expression<T> smartGroupItemsRefs<T extends Object>(
    Expression<T> Function($$SmartGroupItemsTableAnnotationComposer a) f,
  ) {
    final $$SmartGroupItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smartGroupItems,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartGroupItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.smartGroupItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SmartGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartGroupsTable,
          SmartGroupRow,
          $$SmartGroupsTableFilterComposer,
          $$SmartGroupsTableOrderingComposer,
          $$SmartGroupsTableAnnotationComposer,
          $$SmartGroupsTableCreateCompanionBuilder,
          $$SmartGroupsTableUpdateCompanionBuilder,
          (SmartGroupRow, $$SmartGroupsTableReferences),
          SmartGroupRow,
          PrefetchHooks Function({bool smartGroupItemsRefs})
        > {
  $$SmartGroupsTableTableManager(_$AppDatabase db, $SmartGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SmartGroupKind> kind = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<int> startAtMs = const Value.absent(),
                Value<int> endAtMs = const Value.absent(),
                Value<double?> centerLat = const Value.absent(),
                Value<double?> centerLng = const Value.absent(),
                Value<String> coverFileId = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> userTitle = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<int?> geocodedAtMs = const Value.absent(),
              }) => SmartGroupsCompanion(
                id: id,
                kind: kind,
                rank: rank,
                startAtMs: startAtMs,
                endAtMs: endAtMs,
                centerLat: centerLat,
                centerLng: centerLng,
                coverFileId: coverFileId,
                itemCount: itemCount,
                userTitle: userTitle,
                placeName: placeName,
                geocodedAtMs: geocodedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SmartGroupKind kind,
                required int rank,
                required int startAtMs,
                required int endAtMs,
                Value<double?> centerLat = const Value.absent(),
                Value<double?> centerLng = const Value.absent(),
                required String coverFileId,
                required int itemCount,
                Value<String?> userTitle = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<int?> geocodedAtMs = const Value.absent(),
              }) => SmartGroupsCompanion.insert(
                id: id,
                kind: kind,
                rank: rank,
                startAtMs: startAtMs,
                endAtMs: endAtMs,
                centerLat: centerLat,
                centerLng: centerLng,
                coverFileId: coverFileId,
                itemCount: itemCount,
                userTitle: userTitle,
                placeName: placeName,
                geocodedAtMs: geocodedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmartGroupsTable, SmartGroupRow>(table),
                  $$SmartGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({smartGroupItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (smartGroupItemsRefs) db.smartGroupItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (smartGroupItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      SmartGroupRow,
                      $SmartGroupsTable,
                      SmartGroupItemRow,
                      $SmartGroupItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$SmartGroupsTableReferences
                          ._smartGroupItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SmartGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).smartGroupItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'group_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SmartGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartGroupsTable,
      SmartGroupRow,
      $$SmartGroupsTableFilterComposer,
      $$SmartGroupsTableOrderingComposer,
      $$SmartGroupsTableAnnotationComposer,
      $$SmartGroupsTableCreateCompanionBuilder,
      $$SmartGroupsTableUpdateCompanionBuilder,
      (SmartGroupRow, $$SmartGroupsTableReferences),
      SmartGroupRow,
      PrefetchHooks Function({bool smartGroupItemsRefs})
    >;
typedef $$SmartGroupItemsTableCreateCompanionBuilder =
    SmartGroupItemsCompanion Function({
      required int groupId,
      required String fileId,
      Value<int> rowid,
    });
typedef $$SmartGroupItemsTableUpdateCompanionBuilder =
    SmartGroupItemsCompanion Function({
      Value<int> groupId,
      Value<String> fileId,
      Value<int> rowid,
    });

final class $$SmartGroupItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SmartGroupItemsTable,
          SmartGroupItemRow
        > {
  $$SmartGroupItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SmartGroupsTable _groupIdTable(_$AppDatabase db) => db.smartGroups
      .createAlias('smart_group_items__group_id__smart_groups__id');

  $$SmartGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$SmartGroupsTableTableManager(
      $_db,
      $_db.smartGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SmartGroupItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartGroupItemsTable> {
  $$SmartGroupItemsTableFilterComposer({
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

  $$SmartGroupsTableFilterComposer get groupId {
    final $$SmartGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.smartGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartGroupsTableFilterComposer(
            $db: $db,
            $table: $db.smartGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartGroupItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartGroupItemsTable> {
  $$SmartGroupItemsTableOrderingComposer({
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

  $$SmartGroupsTableOrderingComposer get groupId {
    final $$SmartGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.smartGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.smartGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartGroupItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartGroupItemsTable> {
  $$SmartGroupItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  $$SmartGroupsTableAnnotationComposer get groupId {
    final $$SmartGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.smartGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.smartGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartGroupItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartGroupItemsTable,
          SmartGroupItemRow,
          $$SmartGroupItemsTableFilterComposer,
          $$SmartGroupItemsTableOrderingComposer,
          $$SmartGroupItemsTableAnnotationComposer,
          $$SmartGroupItemsTableCreateCompanionBuilder,
          $$SmartGroupItemsTableUpdateCompanionBuilder,
          (SmartGroupItemRow, $$SmartGroupItemsTableReferences),
          SmartGroupItemRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$SmartGroupItemsTableTableManager(
    _$AppDatabase db,
    $SmartGroupItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartGroupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartGroupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartGroupItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartGroupItemsCompanion(
                groupId: groupId,
                fileId: fileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int groupId,
                required String fileId,
                Value<int> rowid = const Value.absent(),
              }) => SmartGroupItemsCompanion.insert(
                groupId: groupId,
                fileId: fileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmartGroupItemsTable, SmartGroupItemRow>(table),
                  $$SmartGroupItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
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
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$SmartGroupItemsTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$SmartGroupItemsTableReferences
                            ._groupIdTable(db)
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

typedef $$SmartGroupItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartGroupItemsTable,
      SmartGroupItemRow,
      $$SmartGroupItemsTableFilterComposer,
      $$SmartGroupItemsTableOrderingComposer,
      $$SmartGroupItemsTableAnnotationComposer,
      $$SmartGroupItemsTableCreateCompanionBuilder,
      $$SmartGroupItemsTableUpdateCompanionBuilder,
      (SmartGroupItemRow, $$SmartGroupItemsTableReferences),
      SmartGroupItemRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$AiLabelsTableCreateCompanionBuilder = AiLabelsCompanion Function({
  required String fileId,
  required String label,
  required double confidence,
  Value<int> rowid,
});
typedef $$AiLabelsTableUpdateCompanionBuilder = AiLabelsCompanion Function({
  Value<String> fileId,
  Value<String> label,
  Value<double> confidence,
  Value<int> rowid,
});

class $$AiLabelsTableFilterComposer
    extends Composer<_$AppDatabase, $AiLabelsTable> {
  $$AiLabelsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiLabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiLabelsTable> {
  $$AiLabelsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiLabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiLabelsTable> {
  $$AiLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );
}

class $$AiLabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiLabelsTable,
          AiLabelRow,
          $$AiLabelsTableFilterComposer,
          $$AiLabelsTableOrderingComposer,
          $$AiLabelsTableAnnotationComposer,
          $$AiLabelsTableCreateCompanionBuilder,
          $$AiLabelsTableUpdateCompanionBuilder,
          (
            AiLabelRow,
            BaseReferences<_$AppDatabase, $AiLabelsTable, AiLabelRow>,
          ),
          AiLabelRow,
          PrefetchHooks Function()
        > {
  $$AiLabelsTableTableManager(_$AppDatabase db, $AiLabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiLabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiLabelsCompanion(
                fileId: fileId,
                label: label,
                confidence: confidence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required String label,
                required double confidence,
                Value<int> rowid = const Value.absent(),
              }) => AiLabelsCompanion.insert(
                fileId: fileId,
                label: label,
                confidence: confidence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiLabelsTable, AiLabelRow>(table),
                  BaseReferences<_$AppDatabase, $AiLabelsTable, AiLabelRow>(
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

typedef $$AiLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiLabelsTable,
      AiLabelRow,
      $$AiLabelsTableFilterComposer,
      $$AiLabelsTableOrderingComposer,
      $$AiLabelsTableAnnotationComposer,
      $$AiLabelsTableCreateCompanionBuilder,
      $$AiLabelsTableUpdateCompanionBuilder,
      (AiLabelRow, BaseReferences<_$AppDatabase, $AiLabelsTable, AiLabelRow>),
      AiLabelRow,
      PrefetchHooks Function()
    >;
typedef $$AiLabelStatusTableCreateCompanionBuilder =
    AiLabelStatusCompanion Function({
      required String fileId,
      required AiLabelOutcome outcome,
      required int modelVersion,
      required int fileModifiedAtMs,
      Value<int> attempts,
      Value<String?> error,
      required int processedAtMs,
      Value<int> rowid,
    });
typedef $$AiLabelStatusTableUpdateCompanionBuilder =
    AiLabelStatusCompanion Function({
      Value<String> fileId,
      Value<AiLabelOutcome> outcome,
      Value<int> modelVersion,
      Value<int> fileModifiedAtMs,
      Value<int> attempts,
      Value<String?> error,
      Value<int> processedAtMs,
      Value<int> rowid,
    });

class $$AiLabelStatusTableFilterComposer
    extends Composer<_$AppDatabase, $AiLabelStatusTable> {
  $$AiLabelStatusTableFilterComposer({
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

  ColumnWithTypeConverterFilters<AiLabelOutcome, AiLabelOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedAtMs => $composableBuilder(
    column: $table.processedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiLabelStatusTableOrderingComposer
    extends Composer<_$AppDatabase, $AiLabelStatusTable> {
  $$AiLabelStatusTableOrderingComposer({
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

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedAtMs => $composableBuilder(
    column: $table.processedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiLabelStatusTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiLabelStatusTable> {
  $$AiLabelStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AiLabelOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<int> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileModifiedAtMs => $composableBuilder(
    column: $table.fileModifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get processedAtMs => $composableBuilder(
    column: $table.processedAtMs,
    builder: (column) => column,
  );
}

class $$AiLabelStatusTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiLabelStatusTable,
          AiLabelStatusRow,
          $$AiLabelStatusTableFilterComposer,
          $$AiLabelStatusTableOrderingComposer,
          $$AiLabelStatusTableAnnotationComposer,
          $$AiLabelStatusTableCreateCompanionBuilder,
          $$AiLabelStatusTableUpdateCompanionBuilder,
          (
            AiLabelStatusRow,
            BaseReferences<
              _$AppDatabase,
              $AiLabelStatusTable,
              AiLabelStatusRow
            >,
          ),
          AiLabelStatusRow,
          PrefetchHooks Function()
        > {
  $$AiLabelStatusTableTableManager(_$AppDatabase db, $AiLabelStatusTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiLabelStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiLabelStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiLabelStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<AiLabelOutcome> outcome = const Value.absent(),
                Value<int> modelVersion = const Value.absent(),
                Value<int> fileModifiedAtMs = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> processedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiLabelStatusCompanion(
                fileId: fileId,
                outcome: outcome,
                modelVersion: modelVersion,
                fileModifiedAtMs: fileModifiedAtMs,
                attempts: attempts,
                error: error,
                processedAtMs: processedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required AiLabelOutcome outcome,
                required int modelVersion,
                required int fileModifiedAtMs,
                Value<int> attempts = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required int processedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AiLabelStatusCompanion.insert(
                fileId: fileId,
                outcome: outcome,
                modelVersion: modelVersion,
                fileModifiedAtMs: fileModifiedAtMs,
                attempts: attempts,
                error: error,
                processedAtMs: processedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiLabelStatusTable, AiLabelStatusRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AiLabelStatusTable,
                    AiLabelStatusRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiLabelStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiLabelStatusTable,
      AiLabelStatusRow,
      $$AiLabelStatusTableFilterComposer,
      $$AiLabelStatusTableOrderingComposer,
      $$AiLabelStatusTableAnnotationComposer,
      $$AiLabelStatusTableCreateCompanionBuilder,
      $$AiLabelStatusTableUpdateCompanionBuilder,
      (
        AiLabelStatusRow,
        BaseReferences<_$AppDatabase, $AiLabelStatusTable, AiLabelStatusRow>,
      ),
      AiLabelStatusRow,
      PrefetchHooks Function()
    >;
typedef $$KnownDevicesTableCreateCompanionBuilder =
    KnownDevicesCompanion Function({
      required String id,
      required String peerDeviceId,
      required String name,
      required String platform,
      required String publicKeyFingerprint,
      required int lastSeenAtMs,
      Value<String> lastAddresses,
      Value<String> allowedRootsJson,
      Value<bool> canShareToUs,
      Value<bool> isTemporary,
      Value<bool> autoAccept,
      Value<int> rowid,
    });
typedef $$KnownDevicesTableUpdateCompanionBuilder =
    KnownDevicesCompanion Function({
      Value<String> id,
      Value<String> peerDeviceId,
      Value<String> name,
      Value<String> platform,
      Value<String> publicKeyFingerprint,
      Value<int> lastSeenAtMs,
      Value<String> lastAddresses,
      Value<String> allowedRootsJson,
      Value<bool> canShareToUs,
      Value<bool> isTemporary,
      Value<bool> autoAccept,
      Value<int> rowid,
    });

class $$KnownDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableFilterComposer({
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

  ColumnFilters<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyFingerprint => $composableBuilder(
    column: $table.publicKeyFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAddresses => $composableBuilder(
    column: $table.lastAddresses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowedRootsJson => $composableBuilder(
    column: $table.allowedRootsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canShareToUs => $composableBuilder(
    column: $table.canShareToUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoAccept => $composableBuilder(
    column: $table.autoAccept,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnownDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableOrderingComposer({
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

  ColumnOrderings<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyFingerprint => $composableBuilder(
    column: $table.publicKeyFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAddresses => $composableBuilder(
    column: $table.lastAddresses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowedRootsJson => $composableBuilder(
    column: $table.allowedRootsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canShareToUs => $composableBuilder(
    column: $table.canShareToUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoAccept => $composableBuilder(
    column: $table.autoAccept,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnownDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get publicKeyFingerprint => $composableBuilder(
    column: $table.publicKeyFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenAtMs => $composableBuilder(
    column: $table.lastSeenAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAddresses => $composableBuilder(
    column: $table.lastAddresses,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allowedRootsJson => $composableBuilder(
    column: $table.allowedRootsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canShareToUs => $composableBuilder(
    column: $table.canShareToUs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoAccept => $composableBuilder(
    column: $table.autoAccept,
    builder: (column) => column,
  );
}

class $$KnownDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnownDevicesTable,
          KnownDeviceRow,
          $$KnownDevicesTableFilterComposer,
          $$KnownDevicesTableOrderingComposer,
          $$KnownDevicesTableAnnotationComposer,
          $$KnownDevicesTableCreateCompanionBuilder,
          $$KnownDevicesTableUpdateCompanionBuilder,
          (
            KnownDeviceRow,
            BaseReferences<_$AppDatabase, $KnownDevicesTable, KnownDeviceRow>,
          ),
          KnownDeviceRow,
          PrefetchHooks Function()
        > {
  $$KnownDevicesTableTableManager(_$AppDatabase db, $KnownDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> peerDeviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> publicKeyFingerprint = const Value.absent(),
                Value<int> lastSeenAtMs = const Value.absent(),
                Value<String> lastAddresses = const Value.absent(),
                Value<String> allowedRootsJson = const Value.absent(),
                Value<bool> canShareToUs = const Value.absent(),
                Value<bool> isTemporary = const Value.absent(),
                Value<bool> autoAccept = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownDevicesCompanion(
                id: id,
                peerDeviceId: peerDeviceId,
                name: name,
                platform: platform,
                publicKeyFingerprint: publicKeyFingerprint,
                lastSeenAtMs: lastSeenAtMs,
                lastAddresses: lastAddresses,
                allowedRootsJson: allowedRootsJson,
                canShareToUs: canShareToUs,
                isTemporary: isTemporary,
                autoAccept: autoAccept,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String peerDeviceId,
                required String name,
                required String platform,
                required String publicKeyFingerprint,
                required int lastSeenAtMs,
                Value<String> lastAddresses = const Value.absent(),
                Value<String> allowedRootsJson = const Value.absent(),
                Value<bool> canShareToUs = const Value.absent(),
                Value<bool> isTemporary = const Value.absent(),
                Value<bool> autoAccept = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownDevicesCompanion.insert(
                id: id,
                peerDeviceId: peerDeviceId,
                name: name,
                platform: platform,
                publicKeyFingerprint: publicKeyFingerprint,
                lastSeenAtMs: lastSeenAtMs,
                lastAddresses: lastAddresses,
                allowedRootsJson: allowedRootsJson,
                canShareToUs: canShareToUs,
                isTemporary: isTemporary,
                autoAccept: autoAccept,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnownDevicesTable, KnownDeviceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $KnownDevicesTable,
                    KnownDeviceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnownDevicesTable,
      KnownDeviceRow,
      $$KnownDevicesTableFilterComposer,
      $$KnownDevicesTableOrderingComposer,
      $$KnownDevicesTableAnnotationComposer,
      $$KnownDevicesTableCreateCompanionBuilder,
      $$KnownDevicesTableUpdateCompanionBuilder,
      (
        KnownDeviceRow,
        BaseReferences<_$AppDatabase, $KnownDevicesTable, KnownDeviceRow>,
      ),
      KnownDeviceRow,
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
  $$ReviewedLabelsTableTableManager get reviewedLabels =>
      $$ReviewedLabelsTableTableManager(_db, _db.reviewedLabels);
  $$SelectionItemsTableTableManager get selectionItems =>
      $$SelectionItemsTableTableManager(_db, _db.selectionItems);
  $$SelectionSnapshotsTableTableManager get selectionSnapshots =>
      $$SelectionSnapshotsTableTableManager(_db, _db.selectionSnapshots);
  $$SwipeSourcesTableTableManager get swipeSources =>
      $$SwipeSourcesTableTableManager(_db, _db.swipeSources);
  $$SwipeSourceItemsTableTableManager get swipeSourceItems =>
      $$SwipeSourceItemsTableTableManager(_db, _db.swipeSourceItems);
  $$ImageSignalsTableTableManager get imageSignals =>
      $$ImageSignalsTableTableManager(_db, _db.imageSignals);
  $$SimilarGroupsTableTableManager get similarGroups =>
      $$SimilarGroupsTableTableManager(_db, _db.similarGroups);
  $$SimilarGroupItemsTableTableManager get similarGroupItems =>
      $$SimilarGroupItemsTableTableManager(_db, _db.similarGroupItems);
  $$SimilarDismissedTableTableManager get similarDismissed =>
      $$SimilarDismissedTableTableManager(_db, _db.similarDismissed);
  $$MediaLocationsTableTableManager get mediaLocations =>
      $$MediaLocationsTableTableManager(_db, _db.mediaLocations);
  $$SmartGroupsTableTableManager get smartGroups =>
      $$SmartGroupsTableTableManager(_db, _db.smartGroups);
  $$SmartGroupItemsTableTableManager get smartGroupItems =>
      $$SmartGroupItemsTableTableManager(_db, _db.smartGroupItems);
  $$AiLabelsTableTableManager get aiLabels =>
      $$AiLabelsTableTableManager(_db, _db.aiLabels);
  $$AiLabelStatusTableTableManager get aiLabelStatus =>
      $$AiLabelStatusTableTableManager(_db, _db.aiLabelStatus);
  $$KnownDevicesTableTableManager get knownDevices =>
      $$KnownDevicesTableTableManager(_db, _db.knownDevices);
}
