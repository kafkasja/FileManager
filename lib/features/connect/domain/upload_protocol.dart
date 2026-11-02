import 'package:meta/meta.dart';

/// Max body of one `PUT /v1/uploads/<id>/chunk` (N9 sends, N10 resumes).
/// N1's 64 KB request limit exempts the chunk route, which enforces this
/// itself (413 `too_large`).
const int kTransferChunkBytes = 4 * 1024 * 1024;

/// Free space a receiver keeps on top of the file (507 below it).
const int kTransferSpaceMarginBytes = 64 * 1024 * 1024;

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

  /// Throws [FormatException] on a bad id, a negative size or a missing
  /// field.
  factory fromJson(Map<String, Object?> json) {
    final id = _str(json, 'uploadId');
    if (!kUploadIdPattern.hasMatch(id)) {
      throw const FormatException('bad uploadId');
    }
    final size = _int(json, 'size');
    if (size < 0) throw const FormatException('negative size');
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
  const new({this.sha256});

  factory fromJson(Map<String, Object?> json) {
    final sha = json['sha256'];
    return CompleteUploadDto(sha256: sha is String ? sha : null);
  }

  final String? sha256;

  Map<String, Object?> toJson() => {'sha256': ?sha256};
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
