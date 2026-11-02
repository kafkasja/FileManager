import 'package:meta/meta.dart';

/// Max body of one `PUT /v1/uploads/<id>/chunk` (N9 sends, N10 resumes).
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

/// `{received}`: answer of create and chunk.
@immutable
class UploadStatusDto {
  const new(this.received);

  factory fromJson(Map<String, Object?> json) =>
      UploadStatusDto(_int(json, 'received'));

  final int received;

  Map<String, Object?> toJson() => {'received': received};
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
