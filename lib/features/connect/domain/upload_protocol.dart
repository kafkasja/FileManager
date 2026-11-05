import 'package:meta/meta.dart';

/// Bytes one `PUT /v1/uploads/<id>/chunk` carries (N9 sends, N10
/// resumes). E1: 32 MiB instead of 4 (each chunk is a stop-and-wait round
/// trip).
const int kTransferChunkBytes = 32 * 1024 * 1024;

/// Max body of one chunk the server takes (older clients send 4 MiB). N1's
/// 64 KB request limit exempts the chunk route, which enforces this itself
/// (413 `too_large`).
const int kMaxTransferChunkBytes = 32 * 1024 * 1024;

/// E1: the receiver makes received bytes durable (fsync + `.json`) at
/// least every this many bytes or [kUploadCheckpointInterval], and at the
/// end; a crash re-sends at most that much (the `.json` never claims more
/// than was synced).
const int kUploadCheckpointBytes = 64 * 1024 * 1024;
const Duration kUploadCheckpointInterval = Duration(seconds: 5);

/// E1: free space is checked at create and then every this many bytes.
const int kUploadSpaceCheckBytes = 256 * 1024 * 1024;

/// Free space a receiver keeps on top of the file (507 below it).
const int kTransferSpaceMarginBytes = 64 * 1024 * 1024;

/// Largest file an upload may declare (1 PiB, like N12 offers). Keeps
/// `size + margin` far from 2^63: a near-2^63 size wrapped negative and
/// passed the free-space check (Q7).
const int kMaxTransferFileBytes = 1 << 50;

/// Upload ids are client-made `randomHexId()`s: 32 lowercase hex. The
/// server names its partial after it, so nothing else is accepted.
final RegExp kUploadIdPattern = RegExp(r'^[0-9a-f]{32}$');

String _str(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String) return v;
  throw FormatException('missing or non-string "$key"');
}

int _int(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is int) return v;
  throw FormatException('missing or non-int "$key"');
}

/// `POST /v1/uploads` (TASK-N9).
@immutable
class CreateUploadDto {
  const new({
    required this.uploadId,
    required this.rootId,
    required this.path,
    required this.name,
    required this.size,
    this.sha256,
  });

  /// Throws [FormatException] on a bad id, a negative or too large size
  /// ([kMaxTransferFileBytes]) or a missing field.
  factory fromJson(Map<String, Object?> json) {
    final id = _str(json, 'uploadId');
    if (!kUploadIdPattern.hasMatch(id)) {
      throw const FormatException('bad uploadId');
    }
    final size = _int(json, 'size');
    if (size < 0) throw const FormatException('negative size');
    if (size > kMaxTransferFileBytes) throw const FormatException('size');
    final sha = json['sha256'];
    return CreateUploadDto(
      uploadId: id,
      rootId: _str(json, 'rootId'),
      path: _str(json, 'path'),
      name: _str(json, 'name'),
      size: size,
      sha256: sha is String ? sha : null,
    );
  }

  final String uploadId;
  final String rootId;

  /// Folder relative to [rootId] ('' = the root).
  final String path;

  /// The file name (validated by the server: 400 `invalid_name`).
  final String name;
  final int size;

  /// N10/N11.
  final String? sha256;

  Map<String, Object?> toJson() => {
    'uploadId': uploadId,
    'rootId': rootId,
    'path': path,
    'name': name,
    'size': size,
    'sha256': ?sha256,
  };
}

/// `{received, size?}`: answer of create, chunk and (N10) the upload
/// status route. [received] is what the server has durably stored.
@immutable
class UploadStatusDto {
  const new(this.received, {this.size});

  factory fromJson(Map<String, Object?> json) {
    final size = json['size'];
    return UploadStatusDto(
      _int(json, 'received'),
      size: size is int ? size : null,
    );
  }

  final int received;

  /// The declared size (N10; null from an N9 server).
  final int? size;

  Map<String, Object?> toJson() => {'received': received, 'size': ?size};
}

/// `POST /v1/uploads/<id>/complete` body (N10: the sender's hash; N11
/// makes the server check it).
@immutable
class CompleteUploadDto {
  const new({this.sha256, this.readBack = false});

  /// Throws [FormatException] when `sha256` is there but not a string.
  factory fromJson(Map<String, Object?> json) => switch (json['sha256']) {
    null => const CompleteUploadDto(),
    final String sha => CompleteUploadDto(
      sha256: sha,
      readBack: json['readBack'] == true,
    ),
    _ => throw const FormatException('sha256'),
  };

  final String? sha256;

  /// E1: a move (N11, the original is deleted afterwards). The receiver
  /// reads the part back from disk instead of trusting the hash it made
  /// while receiving (rule 10: copy → verify). Older servers ignore it and
  /// always read back.
  final bool readBack;

  Map<String, Object?> toJson() => {
    'sha256': ?sha256,
    if (readBack) 'readBack': true,
  };
}

/// `GET /v1/files/<id>/sha256` answer (N10: the sender hash of a
/// download).
@immutable
class FileSha256Dto {
  const new(this.sha256);

  factory fromJson(Map<String, Object?> json) {
    final sha = _str(json, 'sha256');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
      throw const FormatException('bad sha256');
    }
    return FileSha256Dto(sha);
  }

  final String sha256;

  Map<String, Object?> toJson() => {'sha256': sha256};
}

/// `POST /v1/uploads/<id>/complete` answer.
@immutable
class UploadCompletedDto {
  const new({required this.finalId, this.sha256});

  factory fromJson(Map<String, Object?> json) {
    final sha = json['sha256'];
    return UploadCompletedDto(
      finalId: _str(json, 'finalId'),
      sha256: sha is String ? sha : null,
    );
  }

  /// The new file's id on the receiver.
  final String finalId;

  /// N11 fills it.
  final String? sha256;

  Map<String, Object?> toJson() => {'finalId': finalId, 'sha256': sha256};
}
