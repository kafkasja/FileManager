import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:shelf/shelf.dart';

/// What the upload routes need (read per request).
class UploadRoutesEnv {
  new({
    required this.guard,
    required this.sessions,
    required this.uploads,
    required this.source,
    required this.addToIndex,
    required this.stagingFreeBytes,
  });

  final AllowListGuard guard;
  final ClientSessionStore sessions;
  final UploadStore uploads;
  final FileSource Function() source;

  /// `MediaIndexer.addFiles` (not awaited by the routes).
  final Future<void> Function(List<FileRef> files) addToIndex;

  /// Free bytes where partials are written; null = unknown.
  final Future<int?> Function() stagingFreeBytes;
}

/// Whether [request] is a chunk upload (its own body limit instead of the
/// 64 KB JSON limit; `buildSharePipeline(sizeLimitExempt:)`).
bool isUploadChunkRequest(Request request) =>
    request.method == 'PUT' && _chunkPath.hasMatch(request.requestedUri.path);

final RegExp _chunkPath = RegExp(r'^/v1/uploads/[^/]+/chunk$');

/// TASK-N9 server routes: create → chunks → complete, or delete (cancel).
/// N10: create is idempotent, `GET /v1/uploads/<id>` tells where to
/// resume, and partials survive restarts and stop sharing (`UploadStore`).
/// Every route is `guarded`: the target folder must be in a writable shared
/// root of the caller's scope. An upload belongs to the client that made
/// it; another client's id is 404. Partials stay in the private staging
/// folder until `importFile` publishes the finished file.
List<ServerRoute> uploadRoutes(UploadRoutesEnv env) {
  final g = env.guard;

  /// The caller's own upload [id], or a 404 rejection.
  Future<UploadState> own(GuardInput i) async {
    final session = sessionOf(i.request);
    final id = routeParam(i.request, 'id');
    final u = session == null
        ? null
        : await env.uploads.lookup(id, session.clientFingerprint);
    if (u == null) {
      throw const GuardRejection(ApiErrorCode.notFound, 'upload');
    }
    return u;
  }

  return [
    ServerRoute(
      'POST',
      ApiRoutes.uploads,
      g.guarded(
        (r) => _create(env, r),
        write: true,
        extract: (i) async {
          final body = CreateUploadDto.fromJson(await i.json());
          return [RootPathTarget(body.rootId, body.path, write: true)];
        },
      ),
    ),
    ServerRoute(
      'PUT',
      '${ApiRoutes.uploadIdPattern}/chunk',
      g.guarded(
        (r) => _chunk(env, r),
        write: true,
        extract: (i) async {
          final u = await own(i);
          final offset = int.tryParse(
            i.request.url.queryParameters['offset'] ?? '',
          );
          if (offset == null) throw const FormatException('offset');
          return [RootPathTarget(u.rootId, u.path, write: true)];
        },
      ),
    ),
    ServerRoute(
      'POST',
      '${ApiRoutes.uploadIdPattern}/complete',
      g.guarded(
        (r) => _complete(env, r),
        write: true,
        extract: (i) async {
          final u = await own(i);
          return [RootPathTarget(u.rootId, u.path, write: true)];
        },
      ),
    ),
    ServerRoute(
      'GET',
      ApiRoutes.uploadIdPattern,
      g.guarded(
        (r) => _status(env, r),
        // Where to resume: readable while the root is read-only too.
        write: false,
        extract: (i) async {
          final u = await own(i);
          return [RootPathTarget(u.rootId, u.path)];
        },
      ),
    ),
    ServerRoute(
      'DELETE',
      ApiRoutes.uploadIdPattern,
      g.guarded(
        (r) => _delete(env, r),
        // Cleaning up our own partial is allowed after the root turned
        // read-only.
        write: false,
        extract: (i) async {
          final u = await own(i);
          return [RootPathTarget(u.rootId, u.path)];
        },
      ),
    ),
  ];
}

ClientSession _session(Request r) =>
    sessionOf(r) ?? (throw StateError('guarded route without a session'));

Future<UploadState?> _upload(UploadRoutesEnv env, Request r) =>
    env.uploads.lookup(routeParam(r, 'id'), _session(r).clientFingerprint);

Response _statusOk(UploadState u, {int status = 200}) => Response(
  status,
  body: jsonEncode(UploadStatusDto(u.received, size: u.size).toJson()),
  headers: const {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-store',
  },
);

/// N10: where to resume (a chunk still being written isn't counted).
Future<Response> _status(UploadRoutesEnv env, Request r) async {
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  return _statusOk(u);
}

Future<Response> _create(UploadRoutesEnv env, Request r) async {
  final target = guardedTargetsOf(r).single;
  final body = CreateUploadDto.fromJson(
    jsonDecode(await r.readAsString()) as Map<String, Object?>,
  );
  final name = body.name;
  try {
    validateFileName(name);
  } on FileOpException {
    return apiError(ApiErrorCode.invalidName);
  }
  // No dot names (hidden, `.nomedia`) and nothing that lands in an
  // excluded location.
  if (name.startsWith('.') ||
      PathGuard.isExcluded('${target.canonicalPath}/$name')) {
    return apiError(ApiErrorCode.invalidName);
  }
  final existing = await env.uploads.any(body.uploadId);
  if (existing != null) {
    // Another client's id: not revealed.
    if (existing.ownerFingerprint != _session(r).clientFingerprint) {
      return apiError(ApiErrorCode.notFound);
    }
    // N10: a repeated create (lost answer, resume) is idempotent.
    if (existing.sameAs(
      rootId: body.rootId,
      path: body.path,
      name: name,
      size: body.size,
    )) {
      return _statusOk(existing);
    }
    return apiError(ApiErrorCode.conflict);
  }
  final need = body.size + kTransferSpaceMarginBytes;
  final freeTarget = await env.source().freeBytes(target.canonicalPath);
  final freeStaging = await env.stagingFreeBytes();
  if ((freeTarget != null && freeTarget < need) ||
      (freeStaging != null && freeStaging < need)) {
    return apiError(ApiErrorCode.insufficientStorage);
  }
  final u = await env.uploads.create(
    uploadId: body.uploadId,
    ownerFingerprint: _session(r).clientFingerprint,
    rootId: body.rootId,
    path: body.path,
    name: name,
    size: body.size,
  );
  return _statusOk(u, status: 201);
}

Future<Response> _chunk(UploadRoutesEnv env, Request r) async {
  final target = guardedTargetsOf(r).single;
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  final offset = int.parse(r.url.queryParameters['offset']!);
  final length = r.contentLength;
  if (length == null || length > kTransferChunkBytes) {
    return apiError(ApiErrorCode.tooLarge);
  }
  // N10: a chunk of a dropped connection may still hang; the owner's new
  // chunk ends it (cut back to `received`) and takes over.
  final previous = u.writing;
  if (previous != null) {
    u.abortWrite?.call();
    await previous;
    if (u.writing != null) return apiError(ApiErrorCode.busy);
  }
  if (offset != u.received) return apiError(ApiErrorCode.conflict);
  if (u.received + length > u.size) return apiError(ApiErrorCode.tooLarge);
  // Free space is checked per chunk (other files on this device grow too).
  final left = u.size - u.received + kTransferSpaceMarginBytes;
  final freeTarget = await env.source().freeBytes(target.canonicalPath);
  final freeStaging = await env.stagingFreeBytes();
  if ((freeTarget != null && freeTarget < left) ||
      (freeStaging != null && freeStaging < left)) {
    return apiError(ApiErrorCode.insufficientStorage);
  }
  if (u.writing != null) return apiError(ApiErrorCode.busy);
  final finished = Completer<void>();
  u.writing = finished.future;
  RandomAccessFile? raf;
  try {
    raf = await u.part.open(mode: FileMode.append);
    final written = await _receive(
      env.sessions,
      _session(r).sessionId,
      target.canonicalPath,
      r.read(),
      raf,
      length,
      onStart: (abort) => u.abortWrite = abort,
    );
    if (written != length) {
      await raf.truncate(u.received);
      return apiError(ApiErrorCode.cancelled);
    }
    // Write order: the bytes are flushed (fsync) before the `.json`
    // claims them.
    await raf.flush();
    u.received += written;
    await env.uploads.saveMeta(u);
    return _statusOk(u);
  } on Object {
    // The client went away, or Disconnect / a scope edit cancelled it.
    await raf?.truncate(u.received);
    rethrow;
  } finally {
    await raf?.close();
    u
      ..writing = null
      ..abortWrite = null;
    finished.complete();
  }
}

/// Streams [body] into [raf]; the subscription is registered with
/// [sessions] so Disconnect, stop sharing or a scope edit that makes the
/// root read-only cancels it. Returns the bytes written (short = cancelled).
Future<int> _receive(
  ClientSessionStore sessions,
  String sessionId,
  String canonicalPath,
  Stream<List<int>> body,
  RandomAccessFile raf,
  int length, {
  required void Function(void Function() abort) onStart,
}) {
  final done = Completer<int>();
  var n = 0;
  // At most one write runs (the stream is paused meanwhile); every end
  // waits for it, so the caller can truncate or close the file safely.
  var pending = Future<void>.value();
  late final StreamSubscription<List<int>> sub;
  void Function()? unregister;
  void finish([Object? error]) {
    unregister?.call();
    unregister = null;
    unawaited(
      pending.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
        if (done.isCompleted) return;
        if (error != null) {
          done.completeError(error);
        } else {
          done.complete(n);
        }
      }),
    );
  }

  sub = body.listen(
    (chunk) {
      if (n + chunk.length > length) {
        unawaited(sub.cancel());
        finish(const FormatException('body longer than Content-Length'));
        return;
      }
      sub.pause();
      pending = raf
          .writeFrom(chunk)
          .then<void>(
            (_) {
              n += chunk.length;
              sub.resume();
            },
            onError: (Object e) {
              unawaited(sub.cancel());
              finish(e);
            },
          );
    },
    onError: finish,
    onDone: finish,
    cancelOnError: true,
  );
  final hook = _CancelHook(sub, finish);
  unregister = sessions.registerStream(
    sessionId,
    hook,
    canonicalPath: canonicalPath,
    write: true,
  );
  onStart(() => unawaited(hook.cancel()));
  return done.future;
}

Future<Response> _complete(UploadRoutesEnv env, Request r) async {
  final target = guardedTargetsOf(r).single;
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  if (u.writing != null) return apiError(ApiErrorCode.busy);
  if (u.received != u.size) return apiError(ApiErrorCode.conflict);
  final FileRef out;
  try {
    out = await env.source().importFile(
      u.part,
      targetFolder: target.canonicalPath,
      name: u.name,
    );
  } on FileOpException catch (e) {
    // N10: out of space keeps the partial (Resume completes it later).
    if (e.failure != FileOpFailure.noSpace) {
      await env.uploads.remove(u.uploadId);
    }
    return apiError(switch (e.failure) {
      FileOpFailure.noSpace => ApiErrorCode.insufficientStorage,
      FileOpFailure.permissionDenied => ApiErrorCode.forbiddenPath,
      FileOpFailure.invalidName => ApiErrorCode.invalidName,
      _ => ApiErrorCode.internal,
    });
  }
  await env.uploads.completed(u.uploadId);
  unawaited(env.addToIndex([out]));
  return jsonOk(UploadCompletedDto(finalId: out.id).toJson());
}

Future<Response> _delete(UploadRoutesEnv env, Request r) async {
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  await env.uploads.remove(u.uploadId);
  return Response(204);
}

/// The subscription [ClientSessionStore] cancels: cancelling it also ends
/// the chunk (short count → the partial is truncated back).
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
