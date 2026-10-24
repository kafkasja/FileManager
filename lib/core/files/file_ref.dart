import 'package:meta/meta.dart';

enum FileKind { image, video, audio, document, archive, other }

enum FileOrigin { local, external, remote }

/// One file anywhere KFM can see it. Owned by TASK-F3; never redefine.
@immutable
class FileRef {
  const new({
    required this.id,
    required this.uri,
    required this.name,
    required this.kind,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.folderPath,
    required this.origin,
    this.mimeType,
    this.takenAt,
    this.width,
    this.height,
    this.durationMs,
  });

  factory fromJson(Map<String, Object?> j) => FileRef(
    id: j['id']! as String,
    uri: j['uri']! as String,
    name: j['name']! as String,
    mimeType: j['mimeType'] as String?,
    kind: FileKind.values.byName(j['kind']! as String),
    sizeBytes: j['sizeBytes']! as int,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      j['modifiedAt']! as int,
      isUtc: true,
    ),
    takenAt: j['takenAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            j['takenAt']! as int,
            isUtc: true,
          ),
    width: j['width'] as int?,
    height: j['height'] as int?,
    durationMs: j['durationMs'] as int?,
    folderPath: j['folderPath']! as String,
    origin: FileOrigin.values.byName(j['origin']! as String),
  );

  /// Stable id. Formats:
  /// - `ms:<mediaStoreId>`: Android images/videos/audio (MediaStore)
  /// - `path:<absolutePath>`: everything else on Android/Windows
  /// - `ph:<PHAsset.localIdentifier>`: iOS photos (PL2)
  /// - `remote:<deviceId>:<id>`: files on a connected device (N7)
  /// Ids can change on move/rename: see `FileSource.idChanges`.
  final String id;

  /// content://… or absolute file path.
  final String uri;

  /// Display name including extension.
  final String name;
  final String? mimeType;
  final FileKind kind;
  final int sizeBytes;

  /// UTC.
  final DateTime modifiedAt;

  /// UTC; EXIF/MediaStore DATE_TAKEN; null when unknown (never epoch 0).
  final DateTime? takenAt;
  final int? width;
  final int? height;
  final int? durationMs;

  /// Absolute folder path, '/'-separated, no trailing '/'.
  final String folderPath;
  final FileOrigin origin;

  /// Absolute path of the file itself.
  String get path => '$folderPath/$name';

  /// Best date for "recent/old" sorting and grouping.
  DateTime get sortDate => takenAt ?? modifiedAt;

  bool get isMedia => kind == FileKind.image || kind == FileKind.video;

  Map<String, Object?> toJson() => {
    'id': id,
    'uri': uri,
    'name': name,
    'mimeType': mimeType,
    'kind': kind.name,
    'sizeBytes': sizeBytes,
    'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    'takenAt': takenAt?.millisecondsSinceEpoch,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'folderPath': folderPath,
    'origin': origin.name,
  };

  FileRef copyWith({
    String? id,
    String? uri,
    String? name,
    String? mimeType,
    FileKind? kind,
    int? sizeBytes,
    DateTime? modifiedAt,
    DateTime? takenAt,
    int? width,
    int? height,
    int? durationMs,
    String? folderPath,
    FileOrigin? origin,
  }) => FileRef(
    id: id ?? this.id,
    uri: uri ?? this.uri,
    name: name ?? this.name,
    mimeType: mimeType ?? this.mimeType,
    kind: kind ?? this.kind,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    takenAt: takenAt ?? this.takenAt,
    width: width ?? this.width,
    height: height ?? this.height,
    durationMs: durationMs ?? this.durationMs,
    folderPath: folderPath ?? this.folderPath,
    origin: origin ?? this.origin,
  );

  // Deliberately ignores metadata that can't change without modifiedAt
  // changing.
  @override
  bool operator ==(Object other) =>
      other is FileRef &&
      other.id == id &&
      other.uri == uri &&
      other.name == name &&
      other.sizeBytes == sizeBytes &&
      other.modifiedAt == modifiedAt &&
      other.folderPath == folderPath;

  @override
  int get hashCode =>
      Object.hash(id, uri, name, sizeBytes, modifiedAt, folderPath);

  @override
  String toString() => 'FileRef($id, $path)';
}
