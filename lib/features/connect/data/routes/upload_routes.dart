import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/transfer_stats_log.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/transfer_stats.dart';
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
    this.hashPath = _hashPath,
    this.hashFile = hashFileRef,
    this.grants = const NoOfferGrants(),
    this.publishMode = _mayCopy,
    this.streamingHash = true,
    this.spaceCheckBytes = kUploadSpaceCheckBytes,
  });

  /// E1: free space is checked again after this many bytes (tests: 0 =
  /// every chunk).
  final int spaceCheckBytes;

  /// E1: a copy's partial is verified with the hash made while it arrived
  /// instead of reading it back (moves always read back). Tests that hold
  /// the read-back turn it off.
  final bool streamingHash;

  static Future<String> _hashPath(String path) => hashFileInIsolate(path);

  static Future<UploadPublish> _mayCopy(String targetFolder) async =>
      UploadPublish.copy;

  final AllowListGuard guard;
  final ClientSessionStore sessions;
  final UploadStore uploads;
  final FileSource Function() source;

  /// `MediaIndexer.addFiles` (not awaited by the routes).
  final Future<void> Function(List<FileRef> files) addToIndex;

  /// Free bytes where partials are written; null = unknown.
  final Future<int?> Function() stagingFreeBytes;

  /// N11: SHA-256 of a partial (worker isolate).
  final Future<String> Function(String path) hashPath;

  /// N11: SHA-256 of the imported file, read back through the source.
  final Future<String> Function(FileRef f, FileSource source) hashFile;

  /// N12: uploads into `offer:<id>` claim an offered file first.
  final OfferGrants grants;

  /// Q8: how `importFile` will publish a finished partial into a folder
  /// (see [uploadPublishFor]).
  final Future<UploadPublish> Function(String targetFolder) publishMode;
}

/// How a finished partial reaches its target folder (Q8).
enum UploadPublish {
  /// An atomic rename on the same volume: no extra space, and the bytes
  /// are the ones just hashed (the read-back hash is skipped).
  rename,

  /// Possibly a copy (another mount, MediaStore): while it runs the
  /// partial still exists, so when the staging folder shares the target's
  /// free space the target needs the file's size twice. The copy is
  /// hashed.
  copy,

  /// A copy onto another volume than the staging folder (another drive):
  /// each side needs the size once. The copy is hashed.
  copyOtherVolume,
}

/// [UploadPublish] for a partial in [stagingPath] going to [targetFolder].
/// Android: always [UploadPublish.copy] (the staging folder under
/// `Android/data` is its own mount, so a rename across it fails; MediaStore
/// imports copy). Windows: a rename on the same drive letter, else a copy
/// to another drive. Elsewhere: [UploadPublish.copy] (unknown).
UploadPublish uploadPublishFor(
  String stagingPath,
  String targetFolder, {
  required bool isAndroid,
  required bool isWindows,
}) {
  if (isAndroid || !isWindows) return UploadPublish.copy;
  final from = _driveOf(stagingPath);
  final to = _driveOf(targetFolder);
  if (from == null || to == null) return UploadPublish.copy;
  return from == to ? UploadPublish.rename : UploadPublish.copyOtherVolume;
}

final RegExp _drive = RegExp(r'^([A-Za-z]):[/\\]');

String? _driveOf(String path) =>
    _drive.firstMatch(path)?.group(1)!.toUpperCase();

/// Two free-space answers this close come from the same volume (Q8: the
/// staging folder and a shared folder on the phone's own storage).
bool _sameSpace(int a, int b) => (a - b).abs() <= kTransferSpaceMarginBytes;

/// Whether [left] more bytes of an upload of [size] fit: the partial in
/// staging and the target each need them plus the margin; when publishing
/// copies within the same free space, the target needs [size] once more
/// for the copy (Q8: a 4.5 GB upload briefly needed 9 GB on the phone and
/// failed only at the end).
Future<bool> _fits(
  UploadRoutesEnv env,
  String targetFolder, {
  required int size,
  required int left,
}) async {
  final freeTarget = await env.source().freeBytes(targetFolder);
  final freeStaging = await env.stagingFreeBytes();
  final need = left + kTransferSpaceMarginBytes;
  var needTarget = need;
  if (freeTarget != null &&
      freeStaging != null &&
      _sameSpace(freeTarget, freeStaging) &&
      await env.publishMode(targetFolder) == UploadPublish.copy) {
    needTarget += size;
  }
  return (freeTarget == null || freeTarget >= needTarget) &&
      (freeStaging == null || freeStaging >= need);
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

  /// The caller's own upload [id], or a 404 rejection. [orCompleted]:
  /// a remembered completion counts too (N11: status and a repeated
  /// complete after a lost answer).
  Future<UploadState> own(GuardInput i, {bool orCompleted = false}) async {
    final session = sessionOf(i.request);
    final id = routeParam(i.request, 'id');
    var u = session == null
        ? null
        : await env.uploads.lookup(id, session.clientFingerprint);
    if (u == null && orCompleted && session != null) {
      u = env.uploads.lookupCompleted(id, session.clientFingerprint)?.state;
    }
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
          final u = await own(i, orCompleted: true);
          // Optional `{sha256}`: a malformed one is refused here (403),
          // never published unverified or answered with a 500 (Q7).
          if (await i.optionalJson() case final body?) {
            CompleteUploadDto.fromJson(body);
          }
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
          final u = await own(i, orCompleted: true);
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
  if (u != null) return _statusOk(u);
  // N11: already published; the client goes straight to complete.
  final done = _completedOf(env, r);
  if (done == null) return apiError(ApiErrorCode.notFound);
  return _statusOk(done.state..received = done.state.size);
}

CompletedUpload? _completedOf(UploadRoutesEnv env, Request r) => env.uploads
    .lookupCompleted(routeParam(r, 'id'), _session(r).clientFingerprint);

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
  if (!await _fits(
    env,
    target.canonicalPath,
    size: body.size,
    left: body.size,
  )) {
    return apiError(ApiErrorCode.insufficientStorage);
  }
  // N12: only offered files (name, size + slack, count) may land in an
  // offer folder.
  if (offerIdOfRoot(body.rootId) case final offerId?) {
    final ok = await env.grants.claim(
      offerId: offerId,
      clientFingerprint: _session(r).clientFingerprint,
      name: name,
      size: body.size,
      uploadId: body.uploadId,
    );
    if (!ok) return apiError(ApiErrorCode.conflict, 'not offered');
  }
  final u = await env.uploads.create(
    uploadId: body.uploadId,
    ownerFingerprint: _session(r).clientFingerprint,
    rootId: body.rootId,
    path: body.path,
    name: name,
    size: body.size,
  );
  // N12: the receiver may have stopped the offer meanwhile.
  if (isOfferRootId(body.rootId) &&
      await env.grants.inboxRoot(_session(r).clientFingerprint, body.rootId) ==
          null) {
    await env.uploads.remove(u.uploadId);
    return apiError(ApiErrorCode.forbiddenPath);
  }
  return _statusOk(u, status: 201);
}

Future<Response> _chunk(UploadRoutesEnv env, Request r) async {
  final target = guardedTargetsOf(r).single;
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  final offset = int.parse(r.url.queryParameters['offset']!);
  final length = r.contentLength;
  if (length == null || length > kMaxTransferChunkBytes) {
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
  // Free space: at create and then every [kUploadSpaceCheckBytes] (other
  // files on this device grow too; E1: not per chunk).
  if (u.received - u.spaceCheckedAt >= env.spaceCheckBytes) {
    if (!await _fits(
      env,
      target.canonicalPath,
      size: u.size,
      left: u.size - u.received,
    )) {
      return apiError(ApiErrorCode.insufficientStorage);
    }
    u.spaceCheckedAt = u.received;
  }
  if (u.writing != null) return apiError(ApiErrorCode.busy);
  // Q1: another chunk at this offset may have finished during the awaits
  // above (a retry racing the original): checked again before writing, or
  // the same bytes would be appended twice.
  if (offset != u.received) return apiError(ApiErrorCode.conflict);
  final finished = Completer<void>();
  u.writing = finished.future;
  RandomAccessFile? raf;
  try {
    raf = await u.part.open(mode: FileMode.append);
    if (env.streamingHash && u.hasher == null) {
      // First chunk here (or after a cut): the bytes already on disk are
      // hashed once, then everything else as it arrives.
      final h = await HashSession.start();
      try {
        await h.addFile(u.part.path, 0, u.received);
        u.hasher = h;
      } on Object {
        h.dispose();
      }
    }
    final written = await _receive(
      env.sessions,
      _session(r).sessionId,
      target.canonicalPath,
      r.read(),
      raf,
      length,
      stats: u.stats,
      hasher: u.hasher,
      onStart: (abort) => u.abortWrite = abort,
    );
    if (written != length) {
      await _cutBack(env, u, raf);
      return apiError(ApiErrorCode.cancelled);
    }
    u.received += written;
    u.stats.bytes = u.received;
    // Write order: the bytes are flushed (fsync) before the `.json`
    // claims them; E1: every 64 MiB / 5 s and at the end, not per chunk.
    if (env.uploads.checkpointDue(u)) {
      final first = u.syncedAt == null;
      env.uploads.checkpointLater(u);
      // The first one is awaited: a resume point exists right away.
      if (first) await u.syncing;
    }
    env.uploads.touch(u);
    return _statusOk(u);
  } on Object {
    // The client went away, or Disconnect / a scope edit cancelled it.
    if (raf != null) await _cutBack(env, u, raf);
    rethrow;
  } finally {
    await raf?.close();
    u
      ..writing = null
      ..abortWrite = null;
    finished.complete();
  }
}

/// A chunk ended early: the partial goes back to [UploadState.received]
/// and the running hash (which saw the cut bytes) is dropped.
Future<void> _cutBack(
  UploadRoutesEnv env,
  UploadState u,
  RandomAccessFile raf,
) async {
  env.uploads.dropHasher(u);
  await raf.truncate(u.received);
}

/// Bytes the chunk route collects before one write (E1: network chunks
/// are ~16-64 KiB; one await per chunk capped a 312 MB upload).
const int _kWriteBlockBytes = 1024 * 1024;

/// Bytes waiting for the disk before the request stream is paused.
const int _kMaxBufferedBytes = 8 * 1024 * 1024;

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
  TransferStats? stats,
  HashSession? hasher,
}) {
  final done = Completer<int>();
  var n = 0;
  var received = 0;
  final wait = Stopwatch()..start();
  // Network chunks are collected into blocks; at most one write runs (the
  // stream is paused while too much waits). Every end waits for the
  // write, so the caller can truncate or close the file safely.
  final buffer = BytesBuilder(copy: false);
  var writing = false;
  var ended = false;
  var stopped = false;
  var pending = Future<void>.value();
  late final StreamSubscription<List<int>> sub;
  void Function()? unregister;
  void finish([Object? error]) {
    stopped = stopped || error != null;
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

  Future<void> drain() async {
    try {
      while (!stopped &&
          buffer.isNotEmpty &&
          (ended || buffer.length >= _kWriteBlockBytes)) {
        final block = buffer.takeBytes();
        if (sub.isPaused && !ended) sub.resume();
        final write = Stopwatch()..start();
        await raf.writeFrom(block);
        stats?.writeMs += write.elapsedMilliseconds;
        // Flow control: waits only when the hash worker is behind.
        await hasher?.add(block);
        n += block.length;
      }
    } finally {
      writing = false;
    }
  }

  void kick() {
    if (writing) return;
    writing = true;
    pending = drain().catchError((Object e) {
      stopped = true;
      unawaited(sub.cancel());
      finish(e);
    });
  }

  sub = body.listen(
    (chunk) {
      if (received + chunk.length > length) {
        stopped = true;
        unawaited(sub.cancel());
        finish(const FormatException('body longer than Content-Length'));
        return;
      }
      stats?.readMs += wait.elapsedMilliseconds;
      received += chunk.length;
      buffer.add(chunk);
      if (buffer.length >= _kWriteBlockBytes) kick();
      if (buffer.length >= _kMaxBufferedBytes) sub.pause();
      wait.reset();
    },
    onError: (Object e) {
      stopped = true;
      finish(e);
    },
    onDone: () {
      ended = true;
      kick();
      // The last block is written before the count is final.
      unawaited(pending.whenComplete(finish));
    },
    cancelOnError: true,
  );
  final hook = _CancelHook(sub, () {
    stopped = true;
    finish();
  });
  unregister = sessions.registerStream(
    sessionId,
    hook,
    canonicalPath: canonicalPath,
    write: true,
  );
  onStart(() => unawaited(hook.cancel()));
  return done.future;
}

// N9 complete; N11 verifies it when the client sends its `sha256`: the
/// partial is hashed before anything is published (mismatch → partial
/// deleted, 409 `verification_failed`), and the published file is read
/// back and hashed again (mismatch → that copy is deleted, 409; skipped
/// after an atomic rename: the bytes are the ones just hashed). The answer
/// carries the final hash.
///
/// Q8: one complete per upload at a time. A repeat (the link dropped while
/// a large file was hashed and the client asked again) waits for the
/// running one and gets its answer: it never publishes a second copy and
/// never removes the upload the first one is publishing.
Future<Response> _complete(UploadRoutesEnv env, Request r) async {
  final target = guardedTargetsOf(r).single;
  // The guard's extract checked it: empty, or an object with a string
  // sha256.
  final raw = await r.readAsString();
  final body = raw.isEmpty
      ? const CompleteUploadDto()
      : CompleteUploadDto.fromJson(jsonDecode(raw) as Map<String, Object?>);
  final u = await _upload(env, r);
  if (u == null) {
    final done = _completedOf(env, r);
    if (done == null) return apiError(ApiErrorCode.notFound);
    return _completeAnswer(
      CompleteOutcome(finalId: done.finalId, sha256: done.sha256),
    );
  }
  // Nothing is awaited between this check and `completing` being set.
  final running = u.completing;
  if (running != null) return _completeAnswer(await running);
  if (u.writing != null) return apiError(ApiErrorCode.busy);
  if (u.received != u.size) return apiError(ApiErrorCode.conflict);
  final outcome = _publishUpload(
    env,
    u,
    target.canonicalPath,
    body.sha256,
    readBack: body.readBack,
  );
  u.completing = outcome;
  try {
    return _completeAnswer(await outcome);
  } finally {
    u.completing = null;
  }
}

Response _completeAnswer(CompleteOutcome o) {
  final error = o.error;
  if (error != null) return apiError(error);
  return jsonOk(
    UploadCompletedDto(finalId: o.finalId!, sha256: o.sha256).toJson(),
  );
}

/// Verifies [u] (when [expected] is given), publishes it and records the
/// completion. Runs once per upload at a time (see [_complete]).
Future<CompleteOutcome> _publishUpload(
  UploadRoutesEnv env,
  UploadState u,
  String targetFolder,
  String? expected, {
  bool readBack = false,
}) async {
  final complete = Stopwatch()..start();
  // E1: everything on disk before it is hashed or published.
  try {
    await env.uploads.ensureSynced(u);
  } on Object {
    return const CompleteOutcome(error: ApiErrorCode.internal);
  }
  final streamed = u.hasher;
  u.hasher = null;
  if (expected == null) streamed?.dispose();
  if (expected != null) {
    final String partHash;
    final hash = Stopwatch()..start();
    try {
      if (streamed != null &&
          streamed.length == u.size &&
          !readBack &&
          env.streamingHash) {
        // A copy: the hash made while the bytes arrived (E1).
        partHash = await streamed.close();
      } else {
        partHash = await env.hashPath(u.part.path);
        u.stats.hashMs += hash.elapsedMilliseconds;
      }
    } on Object {
      // A read error keeps the partial (the client asks again); only a
      // partial that is gone ends the upload.
      if (!await u.part.exists()) await env.uploads.remove(u.uploadId);
      return const CompleteOutcome(error: ApiErrorCode.internal);
    } finally {
      streamed?.dispose();
    }
    if (partHash != expected) {
      await env.uploads.remove(u.uploadId);
      return const CompleteOutcome(error: ApiErrorCode.verificationFailed);
    }
  }
  final renames =
      expected != null &&
      await env.publishMode(targetFolder) == UploadPublish.rename;
  final FileRef out;
  try {
    out = await env.source().importFile(
      u.part,
      targetFolder: targetFolder,
      name: u.name,
    );
  } on FileOpException catch (e) {
    // N10: out of space keeps the partial (Resume completes it later).
    if (e.failure != FileOpFailure.noSpace) {
      await env.uploads.remove(u.uploadId);
    }
    return CompleteOutcome(
      error: switch (e.failure) {
        FileOpFailure.noSpace => ApiErrorCode.insufficientStorage,
        FileOpFailure.permissionDenied => ApiErrorCode.forbiddenPath,
        FileOpFailure.invalidName => ApiErrorCode.invalidName,
        _ => ApiErrorCode.internal,
      },
    );
  }
  String? finalHash;
  if (expected != null) {
    if (renames) {
      // Q8: the hashed file under its new name; its length must still fit.
      finalHash = out.sizeBytes == u.size ? expected : null;
    } else {
      // Never trust a copy: read the published file back.
      try {
        finalHash = await env.hashFile(out, env.source());
      } on Object {
        finalHash = null;
      }
    }
    if (finalHash != expected) {
      await env.uploads.remove(u.uploadId);
      await _deleteBadCopy(env, out);
      return const CompleteOutcome(error: ApiErrorCode.verificationFailed);
    }
  }
  // N12: the offered file is done BEFORE its partial goes, so a parallel
  // claim never sees it as a dropped upload it could take again.
  if (isOfferRootId(u.rootId)) await env.grants.completed(u.uploadId, out.id);
  await env.uploads.completed(u, finalId: out.id, sha256: finalHash);
  unawaited(env.addToIndex([out]));
  u.stats.completeMs += complete.elapsedMilliseconds;
  logTransferStats(u.stats.summary('receive'));
  return CompleteOutcome(finalId: out.id, sha256: finalHash);
}

/// A published copy that didn't verify (KFM created it): best effort.
Future<void> _deleteBadCopy(UploadRoutesEnv env, FileRef out) async {
  try {
    await env.source().deletePermanentlyBatch([out]);
  } on Object catch (e) {
    developer.log('unverified copy not deleted: $e', name: 'kfm.uploads');
  }
}

Future<Response> _delete(UploadRoutesEnv env, Request r) async {
  final u = await _upload(env, r);
  if (u == null) return apiError(ApiErrorCode.notFound);
  // Q8: being published right now; its outcome decides.
  if (u.completing != null) return apiError(ApiErrorCode.busy);
  await env.uploads.remove(u.uploadId);
  if (isOfferRootId(u.rootId)) await env.grants.released(u.uploadId);
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
