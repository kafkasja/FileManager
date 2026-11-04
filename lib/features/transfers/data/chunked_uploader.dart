import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/db/app_database.dart' show TransferFilesCompanion;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';

/// Re-syncs with the server's offset in a row before a chunk counts as a
/// failed try.
const int kMaxOffsetResyncs = 3;

/// How long `complete` may take for a file of [size] bytes (Q8): the other
/// device hashes the part, may copy it and hashes the copy (~35 MB/s on a
/// phone: 4.5 GB took ~4.8 min). One minute plus 10 MB/s, at least 5 min.
Duration completeTimeoutFor(int size) {
  final scaled = Duration(seconds: 60 + size ~/ (10 * 1024 * 1024));
  const floor = Duration(minutes: 5);
  return scaled > floor ? scaled : floor;
}

/// SHA-256 of what an upload sends, off the UI isolate.
Future<String> hashPrepared(PreparedSource p) async {
  final path = p.path;
  if (path != null) {
    try {
      return await hashFileInIsolate(path);
    } on FileSystemException {
      // Not readable through dart:io here: stream it instead.
    }
  }
  return await hashStreamInIsolate(p.read(0, p.sizeBytes));
}

/// Uploads one file of a job with resume (TASK-N10): the server's
/// `received` is the truth (`GET /v1/uploads/<id>`, or a repeated
/// idempotent create); chunks start there, a 409 re-syncs. The source is
/// checked for edits before and after sending; then the sender hash is
/// stored and sent with `complete`.
class ChunkedUploader {
  new({
    required this._local,
    required this._preprocessor,
    required this._save,
    this._hash = hashPrepared,
    this.chunkBytes = kTransferChunkBytes,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// Bytes per `PUT` (tests use small chunks).
  final int chunkBytes;

  final FileSource _local;
  final TransferPreprocessor _preprocessor;
  final Future<void> Function(int fileId, TransferFilesCompanion row) _save;
  final Future<String> Function(PreparedSource p) _hash;
  final Random _random;

  /// Best-effort `DELETE /v1/uploads/<id>` (cancel, a permanent failure,
  /// a changed source).
  static Future<void> discardRemote(RemoteHttp http, String uploadId) => http
      .deleteJson<void>(ApiRoutes.upload(uploadId), decode: (_) {})
      .then<void>(
        (_) {},
        onError: (Object e) =>
            developer.log('upload not deleted: $e', name: 'kfm.transfers'),
      );

  /// Returns the new file's id on the other device and, for a move job,
  /// the SHA-256 the other device read back from it (equal to ours: N11
  /// verified; a mismatch throws `verification_failed`).
  Future<({String finalId, String? receiverSha256})> run(
    TransferRun run,
    RemoteHttp http,
  ) async {
    final f = run.file;
    final job = run.job;
    final rootId = job.targetRootId;
    if (rootId == null) throw TransferFailure(ApiErrorCode.forbiddenPath.wire);
    var expected = (size: f.sizeBytes, modifiedAtMs: f.sourceModifiedAtMs);
    var uploadId = f.uploadId;
    final source = await _stat(f);
    if (_changed(source, expected)) {
      expected = _versionOf(source);
      if (uploadId != null) {
        // Bytes of the old version were sent: never stitched.
        await _restart(run, http, uploadId, source);
        throw const TransferFailure(TransferErrors.sourceChanged);
      }
      // Nothing sent yet: just remember the current version (an old hash
      // is no longer this file's).
      await _save(
        f.id,
        _versionRow(source).copyWith(senderSha256: const Value(null)),
      );
    }
    final prepared = await _preprocessor.prepare(source, _local);
    try {
      final size = prepared.sizeBytes;
      int? received;
      if (uploadId != null) {
        try {
          final st = await http.getJson(
            ApiRoutes.upload(uploadId),
            decode: UploadStatusDto.fromJson,
          );
          if (st.size != null && st.size != size) {
            await discardRemote(http, uploadId);
            uploadId = null;
          } else {
            received = st.received;
          }
        } on RemoteApiException catch (e) {
          // Gone on the other device (cleaned up, device removed there).
          if (e.code != ApiErrorCode.notFound) rethrow;
          uploadId = null;
        }
      }
      if (uploadId == null) {
        uploadId = randomHexId(_random);
        // Stored before the create: a crash after it still resumes.
        await _save(f.id, TransferFilesCompanion(uploadId: Value(uploadId)));
      }
      final id = uploadId;
      run.uploadId = id;
      if (received == null) {
        if (run.stopped) throw const TransferStopped();
        final st = await http.postJson(
          ApiRoutes.uploads,
          CreateUploadDto(
            uploadId: id,
            rootId: rootId,
            path: job.targetPath,
            name: f.name,
            size: size,
          ).toJson(),
          decode: UploadStatusDto.fromJson,
        );
        received = st.received;
      }
      var at = received;
      // Every byte was already there: a retry after a lost complete.
      final allThere = at == size;
      run.confirm(at);
      var resyncs = 0;
      while (at < size) {
        if (run.stopped) throw const TransferStopped();
        final end = min(at + chunkBytes, size);
        int next;
        try {
          final st = await http.putStream(
            ApiRoutes.uploadChunk(id),
            countedStream(run, prepared.read(at, end), at),
            end - at,
            decode: UploadStatusDto.fromJson,
            query: {'offset': '$at'},
          );
          next = st.received;
        } on RemoteApiException catch (e) {
          if (e.code != ApiErrorCode.conflict || run.stopped) rethrow;
          // 409: the other device has a different offset; seek there.
          if (++resyncs > kMaxOffsetResyncs) rethrow;
          final st = await http.getJson(
            ApiRoutes.upload(id),
            decode: UploadStatusDto.fromJson,
          );
          run.confirm(at = st.received);
          continue;
        }
        if (next <= at && ++resyncs > kMaxOffsetResyncs) {
          throw const TransferFailure(TransferErrors.incomplete);
        }
        if (next > at) resyncs = 0;
        run.confirm(at = next);
      }
      // Edited while it was sent: start over with the new version.
      final after = await _stat(f);
      if (_changed(after, expected)) {
        await _restart(run, http, id, after);
        throw const TransferFailure(TransferErrors.sourceChanged);
      }
      if (run.stopped) throw const TransferStopped();
      final move = job.mode == TransferMode.move;
      // Q8: every byte is there; hashing on both sides can take minutes
      // (the screen shows "Checking…" / a move's "Verifying…").
      await _save(
        f.id,
        const TransferFilesCompanion(
          status: Value(TransferFileStatus.verifying),
        ),
      );
      // A retry after a lost complete answer (same source version, checked
      // above; nothing sent in this run) reuses the stored hash instead of
      // reading the whole file again. A wrong one only fails verification
      // (that clears it).
      final stored = allThere ? f.senderSha256 : null;
      final sha = stored ?? await _hash(prepared);
      if (sha != f.senderSha256) {
        await _save(f.id, TransferFilesCompanion(senderSha256: Value(sha)));
      }
      if (run.stopped) throw const TransferStopped();
      // Q8: a timeout or a dropped link is retried by the engine: it asks
      // `GET /v1/uploads/<id>` (all bytes there, or already published) and
      // completes again; the other device answers a repeat with the running
      // or remembered result, never a second copy.
      final done = await http.postJson(
        ApiRoutes.uploadComplete(id),
        CompleteUploadDto(sha256: sha).toJson(),
        decode: UploadCompletedDto.fromJson,
        timeout: completeTimeoutFor(size),
      );
      if (!move) return (finalId: done.finalId, receiverSha256: null);
      // The other device hashed the part and the published file; an older
      // peer that doesn't answer a hash proves nothing.
      final check = compareCopy(
        sourceSha256: sha,
        sourceSize: size,
        copySha256: done.sha256,
        copySize: size,
      );
      if (check is! Verified) {
        throw const TransferFailure(TransferErrors.verificationFailed);
      }
      return (finalId: done.finalId, receiverSha256: check.sha256);
    } finally {
      try {
        await prepared.cleanup();
      } on Object catch (e) {
        developer.log('prepared file not cleaned: $e', name: 'kfm.transfers');
      }
    }
  }

  Future<FileRef> _stat(TransferFile f) async =>
      await _local.stat(f.sourceFileId) ??
      (throw const TransferFailure(TransferErrors.sourceGone));

  static ({int size, int modifiedAtMs}) _versionOf(FileRef f) =>
      (size: f.sizeBytes, modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch);

  /// Size differs, or the modified time moved by a second or more (some
  /// sources only keep seconds).
  static bool _changed(FileRef f, ({int size, int modifiedAtMs}) expected) =>
      f.sizeBytes != expected.size ||
      (f.modifiedAt.millisecondsSinceEpoch - expected.modifiedAtMs).abs() >=
          1000;

  static TransferFilesCompanion _versionRow(FileRef f) =>
      TransferFilesCompanion(
        sizeBytes: Value(f.sizeBytes),
        sourceModifiedAtMs: Value(f.modifiedAt.millisecondsSinceEpoch),
      );

  /// Drops the old upload and resets the row to the new version from 0.
  Future<void> _restart(
    TransferRun run,
    RemoteHttp http,
    String uploadId,
    FileRef source,
  ) async {
    await discardRemote(http, uploadId);
    run
      ..uploadId = null
      ..confirm(0);
    await _save(
      run.file.id,
      TransferFilesCompanion(
        sizeBytes: Value(source.sizeBytes),
        sourceModifiedAtMs: Value(source.modifiedAt.millisecondsSinceEpoch),
        uploadId: const Value(null),
        bytesDone: const Value(0),
        senderSha256: const Value(null),
      ),
    );
  }
}
