import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:meta/meta.dart';

/// One page of a remote listing (`GET /v1/files`).
@immutable
class RemotePage {
  const new({
    required this.items,
    this.nextCursor,
    this.total,
    this.truncated = false,
  });

  final List<FileRef> items;

  /// Null = the last page.
  final String? nextCursor;

  /// Only on the first page.
  final int? total;

  /// The other device's query budget ran out; [items] are a valid prefix.
  final bool truncated;
}

/// The remote `folderPath` of a file or folder: `'<rootId>'` for the root
/// itself, `'<rootId>/<relative>'` below it (TASK-N7 "Ids").
String remoteFolderPath(String rootId, String relative) =>
    relative.isEmpty ? rootId : '$rootId/$relative';

/// Splits a remote `folderPath` at the first `/` into root + relative path.
/// Throws `notFound` for an absolute (local) path.
({String rootId, String path}) splitRemoteFolder(String folderPath) {
  if (folderPath.isEmpty || folderPath.startsWith('/')) {
    throw const FileOpException(
      FileOpFailure.notFound,
      'not a folder on this device',
    );
  }
  final slash = folderPath.indexOf('/');
  return slash < 0
      ? (rootId: folderPath, path: '')
      : (
          rootId: folderPath.substring(0, slash),
          path: folderPath.substring(slash + 1),
        );
}

/// [RemoteFileDto] → a `FileOrigin.remote` [FileRef] of [peerFingerprint].
FileRef remoteFileRef(String peerFingerprint, RemoteFileDto d) => FileRef(
  id: remoteFileId(peerFingerprint, d.id),
  uri: 'remote://$peerFingerprint/${Uri.encodeComponent(d.id)}',
  name: d.name,
  mimeType: d.mimeType,
  kind: d.kind,
  sizeBytes: d.sizeBytes,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(d.modifiedAtMs, isUtc: true),
  takenAt: d.takenAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(d.takenAtMs!, isUtc: true),
  width: d.width,
  height: d.height,
  durationMs: d.durationMs,
  folderPath: remoteFolderPath(d.rootId, d.relativeFolder),
  origin: FileOrigin.remote,
);

/// A [RemoteApiException] as the [FileOpException] the UI maps (N7 error
/// table).
FileOpException remoteFileOpError(RemoteApiException e, {String? fileId}) {
  final failure = switch (e.code) {
    ApiErrorCode.notFound => FileOpFailure.notFound,
    ApiErrorCode.forbiddenPath ||
    ApiErrorCode.forbidden => FileOpFailure.permissionDenied,
    ApiErrorCode.invalidName => FileOpFailure.invalidName,
    ApiErrorCode.declined => FileOpFailure.userCancelled,
    ApiErrorCode.insufficientStorage => FileOpFailure.noSpace,
    ApiErrorCode.conflict => FileOpFailure.targetExists,
    ApiErrorCode.pendingFolderUnavailable =>
      FileOpFailure.pendingFolderUnavailable,
    ApiErrorCode.unauthorized ||
    ApiErrorCode.expired => FileOpFailure.unavailable,
    _ => FileOpFailure.ioError,
  };
  return FileOpException(failure, 'remote ${e.error.code}', fileId: fileId);
}

FileOpFailure _failureOfCode(String wire) =>
    remoteFileOpError(RemoteApiException(0, ApiErrorDto(wire, ''))).failure;

/// The files of a connected device (TASK-N7, client side): one more
/// [FileSource] with `FileOrigin.remote`. It never creates an HTTP client:
/// `http` returns the live connection's pinned client, or null while the
/// device isn't connected (every call then throws `unavailable`).
class RemoteFileSource implements FileSource {
  new({
    required this.peerFingerprint,
    required this._http,
    this._onUnauthorized,
  });

  /// The other device's pinned certificate fingerprint (N1).
  final String peerFingerprint;
  final RemoteHttp? Function() _http;
  final void Function()? _onUnauthorized;
  final StreamController<FileIdChange> _ids = StreamController.broadcast();

  /// A trash request stays open while the other device's dialog shows.
  static const Duration trashTimeout = Duration(minutes: 3);

  /// Default page size of [page].
  static const int pageLimit = 200;

  RemoteHttp _client() =>
      _http() ??
      (throw const FileOpException(
        FileOpFailure.unavailable,
        'device not connected',
      ));

  Future<T> _run<T>(
    Future<T> Function(RemoteHttp http) body, {
    String? fileId,
  }) async {
    final http = _client();
    try {
      return await body(http);
    } on RemoteUnavailableException catch (e) {
      throw FileOpException(
        FileOpFailure.unavailable,
        e.reason.name,
        fileId: fileId,
      );
    } on RemoteApiException catch (e) {
      if (e.code == ApiErrorCode.unauthorized) _onUnauthorized?.call();
      throw remoteFileOpError(e, fileId: fileId);
      // PinnedClient throws StateError once closed.
      // ignore: avoid_catching_errors
    } on StateError {
      // The connection's client was closed underneath us (disconnect).
      throw FileOpException(
        FileOpFailure.unavailable,
        'client closed',
        fileId: fileId,
      );
    }
  }

  /// The other device's id of [f]; throws `notFound` for a file of another
  /// device or a local file.
  String serverIdOf(FileRef f) => _serverId(f.id);

  String _serverId(String id) {
    try {
      final p = parseRemoteFileId(id);
      if (p.peerFingerprint == peerFingerprint) return p.serverId;
    } on FormatException {
      // Falls through.
    }
    throw FileOpException(
      FileOpFailure.notFound,
      'not a file of this device',
      fileId: id,
    );
  }

  FileRef _toRef(RemoteFileDto d) => remoteFileRef(peerFingerprint, d);

  /// One page of `GET /v1/files` (the browse screen's listing).
  Future<RemotePage> page(
    RemoteQueryDto q, {
    String? cursor,
    int limit = pageLimit,
  }) => _run((http) async {
    final dto = await http.getJson(
      ApiRoutes.files,
      decode: FilePageDto.fromJson,
      query: {'q': q.encode(), 'cursor': ?cursor, 'limit': '$limit'},
    );
    return RemotePage(
      items: List.unmodifiable(dto.items.map(_toRef)),
      nextCursor: dto.nextCursor,
      total: dto.total,
      truncated: dto.truncated,
    );
  });

  /// Subfolders of [path] in [rootId] (`GET /v1/folders`).
  Future<List<RemoteFolderDto>> folders(String rootId, {String path = ''}) =>
      _run((http) async {
        final dto = await http.getJson(
          ApiRoutes.folders,
          decode: FoldersResponseDto.fromJson,
          query: {'rootId': rootId, 'path': path},
        );
        return dto.folders;
      });

  /// The shared roots (`GET /v1/roots`).
  Future<List<RootDto>> roots() => _run((http) async {
    final dto = await http.getJson(
      ApiRoutes.roots,
      decode: RootsResponseDto.fromJson,
    );
    return dto.roots;
  });

  /// Not used by the UI: every shared root, pages unsorted (best effort).
  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    for (final root in await roots()) {
      final q = RemoteQueryDto(
        rootId: root.id,
        includeSubfolders: true,
        kinds: query.kinds,
        minSizeBytes: query.minSizeBytes,
        fromMs: query.modifiedAfter?.millisecondsSinceEpoch,
      );
      String? cursor;
      do {
        final p = await page(q, cursor: cursor, limit: query.pageSize);
        if (p.items.isNotEmpty) yield p.items;
        cursor = p.nextCursor;
      } while (cursor != null);
    }
  }

  @override
  Future<FileRef?> stat(String id) async {
    final String serverId;
    try {
      serverId = _serverId(id);
    } on FileOpException {
      return null;
    }
    try {
      return await _run(
        (http) => http
            .getJson(
              ApiRoutes.fileStat(serverId),
              decode: RemoteFileDto.fromJson,
            )
            .then(_toRef),
        fileId: id,
      );
    } on FileOpException catch (e) {
      if (e.failure == FileOpFailure.notFound) return null;
      rethrow;
    }
  }

  /// `GET /content` with a `Range` for `[start, end)`. A server that ignores
  /// the range (200) is trimmed here.
  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) async* {
    if (end != null && end <= start) return;
    final serverId = serverIdOf(f);
    final ranged = start > 0 || end != null;
    final res = await _run(
      (http) => http.getStream(
        ApiRoutes.fileContent(serverId),
        headers: {
          if (ranged)
            HttpHeaders.rangeHeader:
                'bytes=$start-${end == null ? '' : end - 1}',
        },
      ),
      fileId: f.id,
    );
    // 206 starts at `start`; a plain 200 starts at 0.
    var pos = res.statusCode == HttpStatus.partialContent ? start : 0;
    try {
      await for (final chunk in res) {
        final from = pos;
        pos += chunk.length;
        var lo = 0;
        var hi = chunk.length;
        if (from < start) lo = (start - from).clamp(0, chunk.length);
        if (end != null && pos > end) {
          hi = (end - from).clamp(0, chunk.length);
        }
        if (hi > lo) {
          yield lo == 0 && hi == chunk.length ? chunk : chunk.sublist(lo, hi);
        }
        if (end != null && pos >= end) break;
      }
    } on RemoteUnavailableException catch (e) {
      throw FileOpException(FileOpFailure.unavailable, e.reason.name);
    } on IOException {
      throw FileOpException(
        FileOpFailure.unavailable,
        'stream cut',
        fileId: f.id,
      );
    }
  }

  @override
  Future<String> createFolder(String parentPath, String name) =>
      Future.error(_unsupported('createFolder'));

  Future<FileRef> _moveOrCopy(
    FileRef f,
    String targetFolder,
    String route,
  ) async {
    final target = splitRemoteFolder(targetFolder);
    return await _run(
      (http) => http
          .postJson(
            route,
            MoveRequestDto(
              targetRootId: target.rootId,
              targetPath: target.path,
            ).toJson(),
            decode: RemoteFileDto.fromJson,
          )
          .then(_toRef),
      fileId: f.id,
    );
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    final moved = await _moveOrCopy(
      f,
      targetFolder,
      ApiRoutes.fileMove(serverIdOf(f)),
    );
    _ids.add(FileIdChange(f.id, moved));
    return moved;
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async =>
      await _moveOrCopy(f, targetFolder, ApiRoutes.fileCopy(serverIdOf(f)));

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    checkPathSegment(newName);
    final serverId = serverIdOf(f);
    final renamed = await _run(
      (http) => http
          .postJson(
            ApiRoutes.fileRename(serverId),
            RenameRequestDto(newName).toJson(),
            decode: RemoteFileDto.fromJson,
          )
          .then(_toRef),
      fileId: f.id,
    );
    _ids.add(FileIdChange(f.id, renamed));
    return renamed;
  }

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) => trashBatchFor(files);

  /// [trashBatch] with the reason the other device shows (N8: swipe).
  /// Chunks of ≤500; a declined dialog stops the rest (`userCancelled`).
  Future<TrashResult> trashBatchFor(
    List<FileRef> files, {
    TrashReason reason = TrashReason.user,
  }) async {
    final byServerId = {for (final f in files) serverIdOf(f): f};
    final ids = byServerId.keys.toList();
    final trashed = <TrashedItem>[];
    final failed = <String, FileOpException>{};
    const chunk = TrashRequestDto.kMaxTrashIds;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      final TrashResponseDto res;
      try {
        res = await _run(
          (http) => http.postJson(
            ApiRoutes.filesTrash,
            TrashRequestDto(ids: part, reason: reason).toJson(),
            decode: TrashResponseDto.fromJson,
            timeout: trashTimeout,
          ),
        );
      } on FileOpException catch (e) {
        if (i == 0) rethrow;
        // Earlier chunks went through: report the rest as failed.
        for (final id in ids.skip(i)) {
          final f = byServerId[id]!;
          failed[f.id] = FileOpException(e.failure, e.message, fileId: f.id);
        }
        break;
      }
      for (final t in res.trashed) {
        final original = byServerId[t.id];
        if (original == null) continue;
        trashed.add(
          TrashedItem(
            trashId: t.trashId,
            original: original,
            location:
                TrashLocation.values.asNameMap()[t.location] ??
                TrashLocation.systemTrash,
            trashedAt: DateTime.fromMillisecondsSinceEpoch(
              t.trashedAtMs,
              isUtc: true,
            ),
            expiresAt: t.expiresAtMs == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    t.expiresAtMs!,
                    isUtc: true,
                  ),
          ),
        );
      }
      for (final MapEntry(key: id, value: code) in res.failed.entries) {
        final f = byServerId[id];
        if (f == null) continue;
        failed[f.id] = FileOpException(
          _failureOfCode(code),
          'remote $code',
          fileId: f.id,
        );
      }
      if (res.userCancelled) {
        return TrashResult(
          trashed: trashed,
          failed: failed,
          userCancelled: true,
        );
      }
    }
    return TrashResult(trashed: trashed, failed: failed);
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) =>
      Future.error(_unsupported('deletePermanentlyBatch'));

  @override
  Future<FileRef> restore(TrashedItem item) =>
      Future.error(_unsupported('restore'));

  /// Remote files are restored on the other device's Trash page.
  @override
  Future<List<TrashedItem>> listTrashed() async => const [];

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) =>
      Future.error(_unsupported('restoreBatch'));

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) =>
      Future.error(_unsupported('deleteFromTrash'));

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async {
    final ids = [for (final f in files) serverIdOf(f)];
    const chunk = TrashRequestDto.kMaxTrashIds;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      final granted = await _run(
        (http) => http.postJson(
          ApiRoutes.filesWriteAccess,
          {'ids': part},
          decode: (j) => j['granted'] == true,
          timeout: trashTimeout,
        ),
      );
      if (!granted) return false;
    }
    return true;
  }

  /// Remote files have no local path.
  @override
  Future<FileRef?> statPath(String path) async => null;

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) => Future.error(_unsupported('renameFolder'));

  @override
  Future<int?> freeBytes(String folderPath) async => null;

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) =>
      Future.error(_unsupported('registerCreated'));

  /// Uploads go through the transfer engine (N9), not this source.
  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) => Future.error(_unsupported('importFile'));

  /// Read-only roots are checked by the other device (N4 → 403).
  @override
  bool supports(FileOp op, FileRef f) => true;

  @override
  Stream<FileIdChange> get idChanges => _ids.stream;

  Future<void> dispose() => _ids.close();

  static FileOpException _unsupported(String what) =>
      FileOpException(FileOpFailure.unsupported, '$what on a remote device');
}
