import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shelf/shelf.dart';

/// A JPEG of [f] whose longest side is at most [max] px, or null.
typedef PreviewGenerator = Future<Uint8List?> Function(FileRef f, int max);

/// Android: photo_manager's sized thumbnail of a MediaStore image (JPEG,
/// quality 85). Null for anything else.
Future<Uint8List?> photoManagerPreview(FileRef f, int max) async {
  if (!f.id.startsWith('ms:') || f.kind != FileKind.image) return null;
  final asset = await AssetEntity.fromId(f.id.substring(3));
  if (asset == null) return null;
  return await asset.thumbnailDataWithSize(
    ThumbnailSize(max, max),
    quality: 85,
  );
}

/// `File(f.path).length()`; null when it can't be read.
Future<int?> fileLengthOnDisk(FileRef f) async {
  try {
    return await File(f.path).length();
  } on FileSystemException {
    return null;
  }
}

/// What the file routes need. Getters are read per request, so building
/// the route list touches no database or platform channel.
class FileRoutesEnv {
  new({
    required this.guard,
    required this.scopeOf,
    required this.sessions,
    required this.source,
    required this.dao,
    required this.addToIndex,
    required this.canSeeAllFiles,
    required this.thumbnails,
    required this.trash,
    this.preview = photoManagerPreview,
    this.diskLength = fileLengthOnDisk,
    this.listBudget = const Duration(seconds: 5),
    this.hashFile = hashFileRef,
  });

  final AllowListGuard guard;
  final ShareScope Function(String clientFingerprint) scopeOf;
  final ClientSessionStore sessions;
  final FileSource Function() source;
  final MediaIndexDao Function() dao;

  /// `MediaIndexer.addFiles` (upsert by id; not awaited by the routes).
  final Future<void> Function(List<FileRef> files) addToIndex;
  final bool Function() canSeeAllFiles;
  final Future<ThumbnailCache> Function() thumbnails;
  final RemoteTrashService Function() trash;
  final PreviewGenerator preview;

  /// The file's real byte length (MediaStore's SIZE can be 0 or stale);
  /// null = unknown, `FileRef.sizeBytes` is used.
  final Future<int?> Function(FileRef f) diskLength;

  /// `GET /v1/files` stops after this and answers `truncated: true`.
  final Duration listBudget;

  /// SHA-256 of a file, off the UI isolate (N10 `/sha256`).
  final Future<String> Function(FileRef f, FileSource source) hashFile;
}

/// TASK-N7 server routes on the sharing device. Every route is wrapped in
/// N4's `guarded(...)`; handlers read ids and paths only from
/// `guardedTargetsOf`. Malformed query parameters or bodies are refused by
/// the guard (403 `forbidden_path`), like every N4 route.
List<ServerRoute> fileRoutes(FileRoutesEnv env) {
  final g = env.guard;
  Handler read(Handler h, Future<List<GuardTarget>> Function(GuardInput) x) =>
      g.guarded(h, extract: x, write: false);

  Future<List<GuardTarget>> fileId(GuardInput i) async => [
    FileIdTarget(routeParam(i.request, 'id')),
  ];

  return [
    ServerRoute(
      'GET',
      ApiRoutes.files,
      read((r) => _list(env, r), (i) async {
        final q = RemoteQueryDto.decode(_param(i.request, 'q'));
        _parseCursor(i.request.url.queryParameters['cursor'], q.sort);
        return [RootPathTarget(q.rootId, q.path)];
      }),
    ),
    ServerRoute(
      'GET',
      ApiRoutes.folders,
      read(
        (r) => _folders(env, r),
        (i) async => [
          RootPathTarget(
            _param(i.request, 'rootId'),
            i.request.url.queryParameters['path'] ?? '',
          ),
        ],
      ),
    ),
    ServerRoute('POST', ApiRoutes.filesTrash, _trashRoute(env)),
    ServerRoute('POST', ApiRoutes.filesWriteAccess, _writeAccessRoute(env)),
    ServerRoute(
      'GET',
      ApiRoutes.fileIdPattern,
      read((r) => _stat(env, r), fileId),
    ),
    ServerRoute(
      'GET',
      '${ApiRoutes.fileIdPattern}/thumb',
      read((r) => _thumb(env, r), fileId),
    ),
    ServerRoute(
      'GET',
      '${ApiRoutes.fileIdPattern}/preview',
      read((r) => _preview(env, r), fileId),
    ),
    ServerRoute(
      'GET',
      '${ApiRoutes.fileIdPattern}/content',
      read((r) => _content(env, r), fileId),
    ),
    ServerRoute(
      'GET',
      '${ApiRoutes.fileIdPattern}/sha256',
      read((r) => _sha256(env, r), fileId),
    ),
    ServerRoute(
      'POST',
      '${ApiRoutes.fileIdPattern}/move',
      _moveRoute(env, copy: false),
    ),
    ServerRoute(
      'POST',
      '${ApiRoutes.fileIdPattern}/copy',
      _moveRoute(env, copy: true),
    ),
    ServerRoute(
      'POST',
      '${ApiRoutes.fileIdPattern}/rename',
      g.guarded(
        (r) => _rename(env, r),
        write: true,
        extract: (i) async {
          RenameRequestDto.fromJson(await i.json());
          return [FileIdTarget(routeParam(i.request, 'id'), write: true)];
        },
      ),
    ),
  ];
}

// ---- helpers ----

String _param(Request r, String name) =>
    r.url.queryParameters[name] ??
    (throw FormatException('missing parameter $name'));

/// Null for no cursor; throws [FormatException] for one that doesn't
/// decode or doesn't fit [sort] (int for date/size, String for name).
IndexCursor? _parseCursor(String? raw, FileSort sort) {
  if (raw == null || raw.isEmpty) return null;
  final c = decodeCursor(raw);
  final ok = switch (sort.field) {
    FileSortField.date || FileSortField.size => c.sortValue is int,
    FileSortField.name => c.sortValue is String,
  };
  if (!ok) throw const FormatException('cursor');
  return IndexCursor(c.sortValue, c.id);
}

ClientSession _session(Request r) =>
    sessionOf(r) ?? (throw StateError('guarded route without a session'));

/// [folder] relative to [root] ('' = the root itself), or null when it
/// isn't inside.
String? _relative(String folder, SharedRoot root) {
  if (!PathGuard.isInside(folder, root.path)) return null;
  if (folder.length == root.path.length) return '';
  final start = root.path == '/' ? 1 : root.path.length + 1;
  return folder.substring(start);
}

/// The wire form of [f]. [preferred] (the root the client asked about) wins
/// when [f] is inside it; otherwise the deepest root of [scope]. Null when
/// [f] is outside the scope.
RemoteFileDto? _dto(
  FileRef f,
  ShareScope scope, {
  SharedRoot? preferred,
  String? folder,
}) {
  final dir = folder ?? f.folderPath;
  SharedRoot? root;
  String? rel;
  if (preferred != null) {
    rel = _relative(dir, preferred);
    if (rel != null) root = preferred;
  }
  if (root == null) {
    root = scope.rootFor(dir);
    if (root == null) return null;
    rel = _relative(dir, root);
  }
  return RemoteFileDto(
    id: f.id,
    name: f.name,
    mimeType: f.mimeType,
    kind: f.kind,
    sizeBytes: f.sizeBytes,
    modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
    takenAtMs: f.takenAt?.millisecondsSinceEpoch,
    width: f.width,
    height: f.height,
    durationMs: f.durationMs,
    rootId: root.id,
    relativeFolder: rel ?? '',
  );
}

/// [FileOpException] → protocol error (TASK-N7 error table).
Response _fileOpError(FileOpException e) => apiError(switch (e.failure) {
  // FilesChannel: another system dialog is open (H1).
  FileOpFailure.ioError when e.message.contains('already in progress') =>
    ApiErrorCode.busy,
  FileOpFailure.notFound => ApiErrorCode.notFound,
  FileOpFailure.permissionDenied => ApiErrorCode.forbiddenPath,
  FileOpFailure.noSpace => ApiErrorCode.insufficientStorage,
  FileOpFailure.invalidName => ApiErrorCode.invalidName,
  FileOpFailure.userCancelled => ApiErrorCode.declined,
  FileOpFailure.pendingFolderUnavailable =>
    ApiErrorCode.pendingFolderUnavailable,
  FileOpFailure.targetExists => ApiErrorCode.conflict,
  FileOpFailure.unsupported ||
  FileOpFailure.ioError ||
  FileOpFailure.unavailable ||
  FileOpFailure.volumeEjecting ||
  FileOpFailure.inUse ||
  FileOpFailure.noTrash => ApiErrorCode.internal,
});

String _failureWire(FileOpFailure f) => switch (f) {
  FileOpFailure.notFound => ApiErrorCode.notFound.wire,
  FileOpFailure.permissionDenied => ApiErrorCode.forbiddenPath.wire,
  FileOpFailure.pendingFolderUnavailable =>
    ApiErrorCode.pendingFolderUnavailable.wire,
  FileOpFailure.noSpace => ApiErrorCode.insufficientStorage.wire,
  FileOpFailure.userCancelled => ApiErrorCode.declined.wire,
  _ => ApiErrorCode.internal.wire,
};

/// RemoteTrashService refusals, or null for anything else.
Response? _serviceError(Object e) => switch (e) {
  RemoteBusyException() => apiError(ApiErrorCode.busy),
  RemoteRequestDropped() => apiError(ApiErrorCode.cancelled),
  FileOpException() => _fileOpError(e),
  _ => null,
};

RemoteCaller _caller(Request r) {
  final s = _session(r);
  return (
    sessionId: s.sessionId,
    clientFingerprint: s.clientFingerprint,
    clientName: s.clientName,
  );
}

/// [path] in the spelling the index stores (shared storage is
/// case-insensitive; SQL folder equality isn't).
Future<String> _indexSpelling(MediaIndexDao dao, String path) async =>
    await dao.storedFolderSpelling(path) ?? path;

/// The scope root for a guarded [RootPathTarget] (the one the client
/// named), or null when the scope changed since the guard ran.
SharedRoot? _namedRoot(FileRoutesEnv env, Request r, ResolvedTarget t) {
  final target = t.target;
  if (target is! RootPathTarget) return null;
  return env.scopeOf(_session(r).clientFingerprint).byId(target.rootId);
}

// ---- listing ----

Future<Response> _list(FileRoutesEnv env, Request r) async {
  final resolved = guardedTargetsOf(r).single;
  final root = _namedRoot(env, r, resolved);
  if (root == null) return apiError(ApiErrorCode.forbiddenPath);
  final scope = env.scopeOf(_session(r).clientFingerprint);
  final params = r.url.queryParameters;
  final q = RemoteQueryDto.decode(params['q']!);
  var cursor = _parseCursor(params['cursor'], q.sort);
  final limit = (int.tryParse(params['limit'] ?? '') ?? 200).clamp(1, 500);
  final dao = env.dao();
  final query = IndexQuery(
    kinds: q.kinds,
    folderPath: await _indexSpelling(dao, resolved.canonicalPath),
    includeSubfolders: q.includeSubfolders,
    sort: q.sort,
    minSizeBytes: q.minSizeBytes,
    maxSizeBytes: q.maxSizeBytes,
    from: q.fromMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(q.fromMs!, isUtc: true),
    to: q.toMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(q.toMs!, isUtc: true),
    nameContains: q.nameContains,
    mimePrefix: q.mimePrefix,
    screenshotsOnly: q.screenshotsOnly,
  ).visible(canSeeAllFiles: env.canSeeAllFiles());
  final first = cursor == null;
  if (query == null) {
    return jsonOk(
      FilePageDto(items: const [], total: first ? 0 : null).toJson(),
    );
  }
  final watch = Stopwatch()..start();
  final items = <RemoteFileDto>[];
  var truncated = false;
  while (true) {
    final page = await dao.page(
      query,
      after: cursor,
      limit: limit - items.length,
    );
    for (final f in page.items) {
      // N4 step 6: defence in depth on top of the SQL folder filter.
      if (!PathGuard.isVisible(scope, f)) continue;
      if (_dto(f, scope, preferred: root) case final dto?) items.add(dto);
    }
    cursor = page.next;
    if (cursor == null || items.length >= limit) break;
    if (watch.elapsed >= env.listBudget) {
      truncated = true;
      break;
    }
  }
  final next = cursor;
  return jsonOk(
    FilePageDto(
      items: items,
      nextCursor: next == null ? null : encodeCursor(next.sortValue, next.id),
      total: first ? await dao.count(query) : null,
      truncated: truncated,
    ).toJson(),
  );
}

Future<Response> _folders(FileRoutesEnv env, Request r) async {
  final resolved = guardedTargetsOf(r).single;
  final root = _namedRoot(env, r, resolved);
  if (root == null) return apiError(ApiErrorCode.forbiddenPath);
  final scope = env.scopeOf(_session(r).clientFingerprint);
  final visible = IndexQuery.all.visible(canSeeAllFiles: env.canSeeAllFiles());
  if (visible == null) return jsonOk(const FoldersResponseDto([]).toJson());
  final dao = env.dao();
  final entries = await dao.folders(
    scope: visible,
    parent: await _indexSpelling(dao, resolved.canonicalPath),
  );
  return jsonOk(
    FoldersResponseDto([
      for (final e in entries)
        if (!PathGuard.isExcluded(e.path) && scope.rootFor(e.path) != null)
          if (_relative(e.path, root) case final rel?)
            RemoteFolderDto(
              name: e.name,
              relativePath: rel,
              fileCount: e.fileCount,
            ),
    ]).toJson(),
  );
}

// ---- one file ----

GuardedFile _file(Request r) =>
    guardedTargetsOf(r).first.file ??
    (throw StateError('file route without a file target'));

Future<Response> _stat(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  final scope = env.scopeOf(_session(r).clientFingerprint);
  final dto = _dto(file.ref, scope, folder: file.canonicalFolder);
  if (dto == null) return apiError(ApiErrorCode.forbiddenPath);
  return jsonOk(dto.toJson());
}

Future<Response> _thumb(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  final bytes = await (await env.thumbnails()).get(file.ref);
  if (bytes == null) return apiError(ApiErrorCode.notFound);
  return Response.ok(bytes, headers: _imageHeaders(bytes.length));
}

Future<Response> _preview(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  final max = (int.tryParse(r.url.queryParameters['max'] ?? '') ?? 1600).clamp(
    256,
    2048,
  );
  if (!file.ref.id.startsWith('ms:') || file.ref.kind != FileKind.image) {
    return apiError(ApiErrorCode.notFound);
  }
  final bytes = await env.preview(file.ref, max);
  if (bytes == null) return apiError(ApiErrorCode.notFound);
  return Response.ok(bytes, headers: _imageHeaders(bytes.length));
}

Map<String, String> _imageHeaders(int length) => {
  HttpHeaders.contentTypeHeader: 'image/jpeg',
  HttpHeaders.contentLengthHeader: '$length',
  HttpHeaders.cacheControlHeader: 'private, no-store',
};

/// `"<sha1(id|size|modifiedAtMs)>"` (strong ETag; N10 resumes on it).
String fileEtag(FileRef f) {
  final digest = crypto.sha1.convert(
    utf8.encode(
      '${f.id}|${f.sizeBytes}|${f.modifiedAt.millisecondsSinceEpoch}',
    ),
  );
  return '"$digest"';
}

/// A parsed single `Range: bytes=…` header: `[start, end)` within [size];
/// null = serve everything (absent, malformed, multi-range); `(-1, -1)` =
/// unsatisfiable (416).
(int, int)? parseByteRange(String? header, int size) {
  if (header == null) return null;
  final m = RegExp(r'^\s*bytes\s*=\s*(\d*)\s*-\s*(\d*)\s*$').firstMatch(header);
  if (m == null) return null;
  final a = m.group(1)!;
  final b = m.group(2)!;
  if (a.isEmpty && b.isEmpty) return null;
  if (a.isEmpty) {
    // Suffix: the last N bytes.
    final n = int.tryParse(b);
    if (n == null) return null;
    if (n == 0 || size == 0) return (-1, -1);
    return (n >= size ? 0 : size - n, size);
  }
  // Digits beyond 64 bits: a start past any file, an end past its end.
  final start = int.tryParse(a);
  if (start == null || start >= size) return (-1, -1);
  if (b.isEmpty) return (start, size);
  final last = int.tryParse(b);
  if (last != null && last < start) return null;
  return (start, last == null || last >= size - 1 ? size : last + 1);
}

Future<Response> _content(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  final f = await _withDiskLength(env, file.ref);
  final size = f.sizeBytes;
  final etag = fileEtag(f);
  var range = parseByteRange(r.headers[HttpHeaders.rangeHeader], size);
  final ifRange = r.headers[HttpHeaders.ifRangeHeader];
  if (range != null && ifRange != null && ifRange.trim() != etag) range = null;
  final headers = <String, String>{
    HttpHeaders.contentTypeHeader: f.mimeType ?? 'application/octet-stream',
    HttpHeaders.acceptRangesHeader: 'bytes',
    HttpHeaders.etagHeader: etag,
    HttpHeaders.cacheControlHeader: 'private, no-store',
  };
  if (range case (-1, -1)) {
    return Response(
      416,
      headers: {...headers, HttpHeaders.contentRangeHeader: 'bytes */$size'},
    );
  }
  final (start, end) = range ?? (0, size);
  final body = _tracked(
    env.sessions,
    _session(r).sessionId,
    file.canonicalPath,
    env.source().openRead(f, start: start, end: end),
  );
  headers[HttpHeaders.contentLengthHeader] = '${end - start}';
  if (range == null) return Response.ok(body, headers: headers);
  headers[HttpHeaders.contentRangeHeader] = 'bytes $start-${end - 1}/$size';
  return Response(206, body: body, headers: headers);
}

/// N10: the sender hash of a download (hashed in a worker isolate).
Future<Response> _sha256(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  try {
    final hex = await env.hashFile(file.ref, env.source());
    return jsonOk(FileSha256Dto(hex).toJson());
  } on FileSystemException {
    return apiError(ApiErrorCode.notFound);
  } on FileOpException {
    return apiError(ApiErrorCode.notFound);
  }
}

Future<FileRef> _withDiskLength(FileRoutesEnv env, FileRef f) async {
  final length = await env.diskLength(f);
  return length == null || length == f.sizeBytes
      ? f
      : f.copyWith(sizeBytes: length);
}

/// [source] as a response body whose subscription is registered with
/// [sessions] (N3/N4): Disconnect or a scope edit cancels it and ends the
/// body early, so the client sees a cut-off response.
Stream<List<int>> _tracked(
  ClientSessionStore sessions,
  String sessionId,
  String canonicalPath,
  Stream<List<int>> source,
) {
  late final StreamController<List<int>> out;
  StreamSubscription<List<int>>? sub;
  void Function()? unregister;
  void finish() {
    unregister?.call();
    unregister = null;
    if (!out.isClosed) unawaited(out.close());
  }

  out = StreamController<List<int>>(
    onListen: () {
      // Cancelled in onCancel / by the session store (_CancelHook).
      // ignore: cancel_subscriptions
      final s = source.listen(
        out.add,
        onError: out.addError,
        onDone: finish,
        cancelOnError: true,
      );
      sub = s;
      unregister = sessions.registerStream(
        sessionId,
        _CancelHook(s, finish),
        canonicalPath: canonicalPath,
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () async {
      unregister?.call();
      unregister = null;
      await sub?.cancel();
    },
  );
  return out.stream;
}

/// The subscription [ClientSessionStore] cancels: cancelling it also ends
/// the response body.
class _CancelHook implements StreamSubscription<List<int>> {
  new(this._inner, this._onCancel);

  final StreamSubscription<List<int>> _inner;
  final void Function() _onCancel;

  @override
  Future<void> cancel() async {
    await _inner.cancel();
    _onCancel();
  }

  @override
  void onData(void Function(List<int> data)? handleData) =>
      _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}

// ---- edits ----

Handler _moveRoute(FileRoutesEnv env, {required bool copy}) =>
    env.guard.guarded(
      (r) async {
        final targets = guardedTargetsOf(r);
        final src = targets[0].file!;
        final dst = targets[1];
        final root = _namedRoot(env, r, dst);
        final FileRef out;
        try {
          // A copy never asks for consent; a move of a MediaStore file can
          // (Android 11+), so it runs under the lock and the banner.
          out = copy
              ? await env.source().copy(src.ref, dst.canonicalPath)
              : await env.trash().edit(
                  () => env.source().move(src.ref, dst.canonicalPath),
                  caller: _caller(r),
                );
        } on Object catch (e) {
          if (_serviceError(e) case final response?) return response;
          rethrow;
        }
        unawaited(env.addToIndex([out]));
        final scope = env.scopeOf(_session(r).clientFingerprint);
        final dto =
            _dto(out, scope, preferred: root) ??
            _dto(out, scope, preferred: root, folder: dst.canonicalPath);
        if (dto == null) return apiError(ApiErrorCode.notFound);
        return jsonOk(dto.toJson());
      },
      write: false,
      extract: (i) async {
        final body = MoveRequestDto.fromJson(await i.json());
        return [
          // A move source is written (it disappears there); a copy source
          // is only read.
          FileIdTarget(routeParam(i.request, 'id'), write: !copy),
          RootPathTarget(body.targetRootId, body.targetPath, write: true),
        ];
      },
    );

Future<Response> _rename(FileRoutesEnv env, Request r) async {
  final file = _file(r);
  final body = RenameRequestDto.fromJson(
    jsonDecode(await r.readAsString()) as Map<String, Object?>,
  );
  final name = body.newName;
  // No dot names (`.nomedia` would hide the folder from the gallery; a
  // dot-file vanishes from every listing) and nothing that lands in an
  // excluded location (e.g. a file renamed `data` inside `Android`).
  if (name.startsWith('.') ||
      PathGuard.isExcluded('${file.canonicalFolder}/$name')) {
    return apiError(ApiErrorCode.invalidName);
  }
  final FileRef out;
  try {
    validateFileName(name);
    out = await env.trash().edit(
      () => env.source().rename(file.ref, name),
      caller: _caller(r),
    );
  } on Object catch (e) {
    if (_serviceError(e) case final response?) return response;
    rethrow;
  }
  unawaited(env.addToIndex([out]));
  final scope = env.scopeOf(_session(r).clientFingerprint);
  final dto = _dto(out, scope, folder: file.canonicalFolder);
  if (dto == null) return apiError(ApiErrorCode.notFound);
  return jsonOk(dto.toJson());
}

List<String> _ids(Map<String, Object?> body) {
  final ids = body['ids'];
  if (ids is! List<Object?> || ids.length > TrashRequestDto.kMaxTrashIds) {
    throw const FormatException('ids');
  }
  return [
    for (final i in ids)
      if (i is String) i else throw const FormatException('id'),
  ];
}

Handler _writeAccessRoute(FileRoutesEnv env) => env.guard.guarded(
  (r) async {
    final files = [for (final t in guardedTargetsOf(r)) t.file!.ref];
    try {
      final granted = await env.trash().requestWriteAccess(
        files,
        caller: _caller(r),
      );
      return jsonOk({'granted': granted});
    } on Object catch (e) {
      if (_serviceError(e) case final response?) return response;
      rethrow;
    }
  },
  write: true,
  extract: (i) async => [
    for (final id in _ids(await i.json())) FileIdTarget(id, write: true),
  ],
);

Handler _trashRoute(FileRoutesEnv env) => env.guard.guarded(
  (r) async {
    final targets = guardedTargetsOf(r);
    var files = [for (final t in targets) t.file!.ref];
    final refused = <String, String>{};
    final body = TrashRequestDto.fromJson(
      jsonDecode(await r.readAsString()) as Map<String, Object?>,
    );
    if (body.reason == TrashReason.verifiedMove) {
      // N11: only files whose bytes are still what the client verified.
      final keep = <FileRef>[];
      for (final t in targets) {
        final id = (t.target as FileIdTarget).id;
        final f = t.file!.ref;
        final check = await _verifyOriginal(
          env,
          f,
          sha256: body.sha256ById[id] ?? body.sha256ById[f.id],
          size: body.sizeById[id] ?? body.sizeById[f.id],
        );
        if (check == null) {
          keep.add(f);
        } else {
          refused[f.id] = check;
        }
      }
      files = keep;
    }
    TrashResult result;
    try {
      result = files.isEmpty
          ? const TrashResult(trashed: [], failed: {})
          : await env.trash().trash(files, caller: _caller(r));
    } on Object catch (e) {
      if (_serviceError(e) case final response?) return response;
      rethrow;
    }
    return jsonOk(
      TrashResponseDto(
        trashed: [
          for (final t in result.trashed)
            RemoteTrashedDto(
              id: t.original.id,
              trashId: t.trashId,
              location: t.location.name,
              trashedAtMs: t.trashedAt.millisecondsSinceEpoch,
              expiresAtMs: t.expiresAt?.millisecondsSinceEpoch,
            ),
        ],
        failed: {
          ...refused,
          for (final MapEntry(:key, :value) in result.failed.entries)
            key: _failureWire(value.failure),
        },
        userCancelled: result.userCancelled,
      ).toJson(),
    );
  },
  write: true,
  extract: (i) async {
    final body = TrashRequestDto.fromJson(await i.json());
    // Duplicates would trash the same file twice.
    return [
      for (final id in {...body.ids}) FileIdTarget(id, write: true),
    ];
  },
);

/// N11 `verifiedMove`: null when [f]'s on-disk length and SHA-256 (hashed
/// in a worker isolate) equal what the client received; otherwise the
/// wire code it gets back for that id (`verification_failed`, or
/// `not_found` when the file can't be read any more).
Future<String?> _verifyOriginal(
  FileRoutesEnv env,
  FileRef f, {
  required String? sha256,
  required int? size,
}) async {
  if (sha256 == null || size == null) {
    return ApiErrorCode.verificationFailed.wire;
  }
  try {
    final length = await env.diskLength(f) ?? f.sizeBytes;
    if (length != size) return ApiErrorCode.verificationFailed.wire;
    final hex = await env.hashFile(f, env.source());
    return hex == sha256 ? null : ApiErrorCode.verificationFailed.wire;
  } on FileSystemException {
    return ApiErrorCode.notFound.wire;
  } on FileOpException {
    return ApiErrorCode.notFound.wire;
  } on Object {
    // A hash worker that failed: nothing is trashed, the client may ask
    // again.
    return ApiErrorCode.internal.wire;
  }
}
