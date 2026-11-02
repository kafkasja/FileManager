import 'dart:convert';

import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

/// TASK-N7 wire contract for remote browsing (the shared contract between
/// the server routes on the sharing device and `RemoteFileSource` on the
/// client). Ids are the sharing device's own `FileRef.id`s. Decoders throw
/// [FormatException] on bad input (the server answers 400/403).

String _str(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v is! String) throw FormatException('missing or non-string "$k"');
  return v;
}

String? _strOrNull(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v == null) return null;
  if (v is! String) throw FormatException('non-string "$k"');
  return v;
}

int _int(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v is! int) throw FormatException('missing or non-int "$k"');
  return v;
}

int? _intOrNull(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v == null) return null;
  if (v is! int) throw FormatException('non-int "$k"');
  return v;
}

bool _boolOr(Map<String, Object?> j, String k, {required bool or}) {
  final v = j[k];
  if (v == null) return or;
  if (v is! bool) throw FormatException('non-bool "$k"');
  return v;
}

List<Map<String, Object?>> _objects(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v is! List<Object?>) throw FormatException('missing or non-list "$k"');
  return [
    for (final e in v)
      if (e is Map<String, Object?>)
        e
      else
        throw FormatException('non-object in "$k"'),
  ];
}

T _enum<T extends Enum>(List<T> values, String name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('unknown value "$name"');
}

/// One file on the sharing device.
@immutable
class RemoteFileDto {
  const new({
    required this.id,
    required this.name,
    required this.kind,
    required this.sizeBytes,
    required this.modifiedAtMs,
    required this.rootId,
    required this.relativeFolder,
    this.mimeType,
    this.takenAtMs,
    this.width,
    this.height,
    this.durationMs,
  });

  factory fromJson(Map<String, Object?> j) => RemoteFileDto(
    id: _str(j, 'id'),
    name: _str(j, 'name'),
    mimeType: _strOrNull(j, 'mimeType'),
    kind: _enum(FileKind.values, _str(j, 'kind')),
    sizeBytes: _int(j, 'sizeBytes'),
    modifiedAtMs: _int(j, 'modifiedAtMs'),
    takenAtMs: _intOrNull(j, 'takenAtMs'),
    width: _intOrNull(j, 'width'),
    height: _intOrNull(j, 'height'),
    durationMs: _intOrNull(j, 'durationMs'),
    rootId: _str(j, 'rootId'),
    relativeFolder: _str(j, 'relativeFolder'),
  );

  /// The sharing device's `FileRef.id` (`path:…` / `ms:…`).
  final String id;
  final String name;
  final String? mimeType;
  final FileKind kind;
  final int sizeBytes;

  /// Epoch ms UTC.
  final int modifiedAtMs;

  /// Null = unknown (never 0).
  final int? takenAtMs;
  final int? width;
  final int? height;
  final int? durationMs;

  /// The shared root it is in, and its folder relative to that root
  /// (`''` = the root itself; never starts with '/'). Absolute paths of the
  /// sharing device are not sent (except inside `path:` ids, see N4).
  final String rootId;
  final String relativeFolder;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'mimeType': ?mimeType,
    'kind': kind.name,
    'sizeBytes': sizeBytes,
    'modifiedAtMs': modifiedAtMs,
    'takenAtMs': ?takenAtMs,
    'width': ?width,
    'height': ?height,
    'durationMs': ?durationMs,
    'rootId': rootId,
    'relativeFolder': relativeFolder,
  };
}

/// What `GET /v1/files?q=<json>` lists: one shared root (+ path below it)
/// with the filters that can run on the sharing device's index. Local-only
/// clauses (tags, favorites, reviewed) never go on the wire.
@immutable
class RemoteQueryDto {
  const new({
    required this.rootId,
    this.path = '',
    this.includeSubfolders = false,
    this.kinds = const {},
    this.sort = FileSort.newestFirst,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.fromMs,
    this.toMs,
    this.nameContains,
    this.mimePrefix,
    this.screenshotsOnly = false,
  });

  factory fromJson(Map<String, Object?> j) {
    final kinds = j['kinds'] ?? const <Object?>[];
    if (kinds is! List<Object?>) throw const FormatException('kinds');
    return RemoteQueryDto(
      rootId: _str(j, 'rootId'),
      path: _strOrNull(j, 'path') ?? '',
      includeSubfolders: _boolOr(j, 'includeSubfolders', or: false),
      kinds: {
        for (final k in kinds)
          if (k is String)
            _enum(FileKind.values, k)
          else
            throw const FormatException('kind'),
      },
      sort: FileSort(
        _enum(FileSortField.values, _strOrNull(j, 'sort') ?? 'date'),
        descending: _boolOr(j, 'descending', or: true),
      ),
      minSizeBytes: _intOrNull(j, 'minSizeBytes'),
      maxSizeBytes: _intOrNull(j, 'maxSizeBytes'),
      fromMs: _intOrNull(j, 'fromMs'),
      toMs: _intOrNull(j, 'toMs'),
      nameContains: _strOrNull(j, 'nameContains'),
      mimePrefix: _strOrNull(j, 'mimePrefix'),
      screenshotsOnly: _boolOr(j, 'screenshotsOnly', or: false),
    );
  }

  factory decode(String text) {
    final j = jsonDecode(text);
    if (j is! Map<String, Object?>) throw const FormatException('q');
    return RemoteQueryDto.fromJson(j);
  }

  final String rootId;

  /// Relative to the root; `''` = the root.
  final String path;
  final bool includeSubfolders;

  /// Empty = every kind.
  final Set<FileKind> kinds;
  final FileSort sort;
  final int? minSizeBytes;
  final int? maxSizeBytes;
  final int? fromMs;
  final int? toMs;
  final String? nameContains;
  final String? mimePrefix;
  final bool screenshotsOnly;

  Map<String, Object?> toJson() => {
    'rootId': rootId,
    'path': path,
    'includeSubfolders': includeSubfolders,
    'kinds': [for (final k in kinds) k.name],
    'sort': sort.field.name,
    'descending': sort.descending,
    'minSizeBytes': ?minSizeBytes,
    'maxSizeBytes': ?maxSizeBytes,
    'fromMs': ?fromMs,
    'toMs': ?toMs,
    'nameContains': ?nameContains,
    'mimePrefix': ?mimePrefix,
    'screenshotsOnly': screenshotsOnly,
  };

  /// The `q` query parameter.
  String encode() => jsonEncode(toJson());
}

/// One page of `GET /v1/files`.
@immutable
class FilePageDto {
  const new({
    required this.items,
    this.nextCursor,
    this.total,
    this.truncated = false,
  });

  factory fromJson(Map<String, Object?> j) => FilePageDto(
    items: [for (final o in _objects(j, 'items')) RemoteFileDto.fromJson(o)],
    nextCursor: _strOrNull(j, 'nextCursor'),
    total: _intOrNull(j, 'total'),
    truncated: _boolOr(j, 'truncated', or: false),
  );

  final List<RemoteFileDto> items;

  /// Opaque (`encodeCursor`); null = end.
  final String? nextCursor;

  /// Only on the first page (no cursor).
  final int? total;

  /// The server's query budget ran out; [items] are a valid prefix.
  final bool truncated;

  Map<String, Object?> toJson() => {
    'items': [for (final i in items) i.toJson()],
    'nextCursor': ?nextCursor,
    'total': ?total,
    'truncated': truncated,
  };
}

/// Keyset cursor on the wire: base64url JSON `[sortValue, id]`, where
/// sortValue is an int (date ms / size) or a String (name).
String encodeCursor(Object sortValue, String id) =>
    base64Url.encode(utf8.encode(jsonEncode([sortValue, id])));

/// Inverse of [encodeCursor]; throws [FormatException].
({Object sortValue, String id}) decodeCursor(String cursor) {
  final Object? j;
  try {
    j = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(cursor))));
  } on Object {
    throw const FormatException('cursor');
  }
  if (j is! List<Object?> || j.length != 2) {
    throw const FormatException('cursor');
  }
  final [value, id] = j;
  if (id is! String || (value is! int && value is! String)) {
    throw const FormatException('cursor');
  }
  return (sortValue: value!, id: id);
}

/// One subfolder in `GET /v1/folders?rootId=&path=`.
@immutable
class RemoteFolderDto {
  const new({
    required this.name,
    required this.relativePath,
    required this.fileCount,
  });

  factory fromJson(Map<String, Object?> j) => RemoteFolderDto(
    name: _str(j, 'name'),
    relativePath: _str(j, 'relativePath'),
    fileCount: _int(j, 'fileCount'),
  );

  final String name;

  /// Relative to the root (never starts with '/').
  final String relativePath;

  /// Indexed files at or below it.
  final int fileCount;

  Map<String, Object?> toJson() => {
    'name': name,
    'relativePath': relativePath,
    'fileCount': fileCount,
  };
}

@immutable
class FoldersResponseDto {
  const new(this.folders);

  factory fromJson(Map<String, Object?> j) => FoldersResponseDto([
    for (final o in _objects(j, 'folders')) RemoteFolderDto.fromJson(o),
  ]);

  final List<RemoteFolderDto> folders;

  Map<String, Object?> toJson() => {
    'folders': [for (final f in folders) f.toJson()],
  };
}

/// `GET /v1/session` (N5 heartbeat) answer since N7: [changeToken] changes
/// whenever anything inside the client's shared roots changed (live sync).
/// A 204 / empty body (older server) decodes to a null token.
@immutable
class SessionDto {
  const new({this.changeToken});

  factory fromJson(Map<String, Object?> j) =>
      SessionDto(changeToken: _strOrNull(j, 'changeToken'));

  final String? changeToken;

  Map<String, Object?> toJson() => {'changeToken': ?changeToken};
}

/// Body of move and copy: the target folder as root + relative path.
@immutable
class MoveRequestDto {
  const new({required this.targetRootId, this.targetPath = ''});

  factory fromJson(Map<String, Object?> j) => MoveRequestDto(
    targetRootId: _str(j, 'targetRootId'),
    targetPath: _strOrNull(j, 'targetPath') ?? '',
  );

  final String targetRootId;
  final String targetPath;

  Map<String, Object?> toJson() => {
    'targetRootId': targetRootId,
    'targetPath': targetPath,
  };
}

@immutable
class RenameRequestDto {
  const new(this.newName);

  factory fromJson(Map<String, Object?> j) =>
      RenameRequestDto(_str(j, 'newName'));

  final String newName;

  Map<String, Object?> toJson() => {'newName': newName};
}

/// Why the client asks to trash (N7: user / swipe; N11: verifiedMove).
enum TrashReason { user, swipe, verifiedMove }

/// `POST /v1/files/trash`: at most [kMaxTrashIds] ids. N11
/// `verifiedMove`: [sha256ById] and [sizeById] hold what the client
/// received for every id; the sharing device trashes only files whose
/// on-disk hash and length still match.
@immutable
class TrashRequestDto {
  const new({
    required this.ids,
    this.reason = TrashReason.user,
    this.sha256ById = const {},
    this.sizeById = const {},
  });

  factory fromJson(Map<String, Object?> j) {
    final ids = j['ids'];
    if (ids is! List<Object?> || ids.length > kMaxTrashIds) {
      throw const FormatException('ids');
    }
    final list = [
      for (final i in ids)
        if (i is String) i else throw const FormatException('id'),
    ];
    final reason = _enum(TrashReason.values, _strOrNull(j, 'reason') ?? 'user');
    final sha = <String, String>{};
    final size = <String, int>{};
    if (reason == TrashReason.verifiedMove) {
      final rawSha = j['sha256ById'];
      final rawSize = j['sizeById'];
      if (rawSha is! Map<String, Object?> || rawSize is! Map<String, Object?>) {
        throw const FormatException('verifiedMove needs hashes and sizes');
      }
      for (final id in list) {
        final h = rawSha[id];
        final n = rawSize[id];
        if (h is! String || !_sha256Hex.hasMatch(h) || n is! int || n < 0) {
          throw const FormatException('verifiedMove hash or size');
        }
        sha[id] = h;
        size[id] = n;
      }
    }
    return TrashRequestDto(
      ids: list,
      reason: reason,
      sha256ById: sha,
      sizeById: size,
    );
  }

  static const int kMaxTrashIds = 500;
  static final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

  final List<String> ids;
  final TrashReason reason;

  /// N11 `verifiedMove` only.
  final Map<String, String> sha256ById;

  /// N11 `verifiedMove` only.
  final Map<String, int> sizeById;

  Map<String, Object?> toJson() => {
    'ids': ids,
    'reason': reason.name,
    if (reason == TrashReason.verifiedMove) ...{
      'sha256ById': sha256ById,
      'sizeById': sizeById,
    },
  };
}

/// One trashed file in a [TrashResponseDto].
@immutable
class RemoteTrashedDto {
  const new({
    required this.id,
    required this.trashId,
    required this.location,
    required this.trashedAtMs,
    this.expiresAtMs,
  });

  factory fromJson(Map<String, Object?> j) => RemoteTrashedDto(
    id: _str(j, 'id'),
    trashId: _str(j, 'trashId'),
    location: _str(j, 'location'),
    trashedAtMs: _int(j, 'trashedAtMs'),
    expiresAtMs: _intOrNull(j, 'expiresAtMs'),
  );

  final String id;
  final String trashId;

  /// `TrashLocation.name` on the sharing device.
  final String location;
  final int trashedAtMs;
  final int? expiresAtMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'trashId': trashId,
    'location': location,
    'trashedAtMs': trashedAtMs,
    'expiresAtMs': ?expiresAtMs,
  };
}

@immutable
class TrashResponseDto {
  const new({
    required this.trashed,
    this.failed = const {},
    this.userCancelled = false,
  });

  factory fromJson(Map<String, Object?> j) {
    final failed = j['failed'] ?? const <String, Object?>{};
    if (failed is! Map<String, Object?>) throw const FormatException('failed');
    return TrashResponseDto(
      trashed: [
        for (final o in _objects(j, 'trashed')) RemoteTrashedDto.fromJson(o),
      ],
      failed: {
        for (final e in failed.entries)
          e.key: e.value is String
              ? e.value! as String
              : throw const FormatException('failed code'),
      },
      userCancelled: _boolOr(j, 'userCancelled', or: false),
    );
  }

  final List<RemoteTrashedDto> trashed;

  /// id → `ApiErrorCode.wire` (`not_found`, `forbidden_path`, …).
  final Map<String, String> failed;

  /// The person at the sharing device declined the system dialog.
  final bool userCancelled;

  Map<String, Object?> toJson() => {
    'trashed': [for (final t in trashed) t.toJson()],
    'failed': failed,
    'userCancelled': userCancelled,
  };
}
