import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';

/// What the runner reads for one file: [source] is a content URI or an
/// absolute path; [sizeBytes] is set when it isn't the file itself (X2's
/// stripped copy), and [cleanup] releases such a copy.
@immutable
class CloudSource {
  const new({required this.source, this.sizeBytes, this.cleanup});

  final String source;
  final int? sizeBytes;
  final Future<void> Function()? cleanup;

  bool get isReplacement => sizeBytes != null;
}

/// Thrown by a [CloudSourcePreparer] when location can't be removed (X2):
/// the file fails, it is never uploaded with its location.
class CloudLocationNotRemoved implements Exception {
  const new();
}

/// [stripLocation] is the job's X2 decision taken when it started (null:
/// no job in memory, e.g. after a restart; the preparer reads the setting).
typedef CloudSourcePreparer = Future<CloudSource> Function(
  FileRef file,
  int itemId, {
  bool? stripLocation,
});

/// Ids whose bytes the runner can read (MediaStore, paths, U2's SAF
/// places). MTP cameras and remote devices aren't offered.
bool cloudCanRead(FileRef f) =>
    f.id.startsWith('ms:') ||
    f.id.startsWith('path:') ||
    f.id.startsWith('saf:');

/// The file as it is.
Future<CloudSource> plainCloudSource(
  FileRef f,
  int itemId, {
  bool? stripLocation,
}) async => CloudSource(source: f.uri);

/// One user request: files to one destination.
@immutable
class CloudJobRequest {
  const new({
    required this.files,
    required this.destinationId,
    required this.mode,
    this.deleteMode = DeleteMode.trash,
    this.stripLocation,
  });

  final List<FileRef> files;
  final int destinationId;
  final CloudItemMode mode;

  /// Moves: the delete mode of this job (D1 at start, or "Use trash
  /// instead"). Kept in memory only; after a restart it is trash.
  final DeleteMode deleteMode;

  /// X2 "Remove location" as it was when the user started the job (and
  /// answered its warning); a later change of the setting doesn't apply
  /// to this job. Null = read the setting per file.
  final bool? stripLocation;
}

/// A started job: its `cloud_items` ids and its end.
@immutable
class CloudJobHandle {
  const new(this.ids, this.done);

  final List<int> ids;
  final Future<CloudMoveSummary?> done;
}

/// How a move job's originals ended (for a summary message).
@immutable
class CloudMoveSummary {
  const new({required this.deleted, required this.kept});

  final int deleted;
  final int kept;
}

typedef _VerifiedEntry = ({
  VerifiedOriginal original,
  String remoteUri,
  int bytes,
});

class _Job {
  new(this.mode, this.deleteMode, this.pending, {required this.stripLocation});

  final CloudItemMode mode;
  final DeleteMode deleteMode;
  final bool? stripLocation;
  final Set<int> pending;
  final Completer<CloudMoveSummary?> done = Completer<CloudMoveSummary?>();

  /// itemId → original + the document whose bytes were verified.
  final Map<int, _VerifiedEntry> verified = {};
}

/// X3's own upload runner (not N9's transfer kinds): one file at a time,
/// oldest first. Copy → `handedToProvider`; move → read-back SHA-256 →
/// N11's [compareCopy] → `verified`, and at the job's end one
/// [VerifiedMove.deleteOriginals] call for all its verified originals.
///
/// Documents: a row's `remote_uri` is only cleared after its document was
/// deleted; a delete that fails leaves the URI and a leftover mark on the
/// error (retried at start-up), never a silent orphan.
///
/// Created lazily (Hard rule 1): nothing here runs until [start] or
/// [resume] is called (it only listens to F3's `idChanges`).
class CloudUploadRunner {
  new({
    required this._items,
    required this._destinations,
    required this._writer,
    required this._files,
    required this._verifiedMove,
    CloudSourcePreparer? prepare,
    DateTime Function()? now,
  }) : _prepare = prepare ?? plainCloudSource,
       _now = now ?? DateTime.now {
    _idSub = _files.idChanges.listen(_onIdChange);
  }

  final CloudItemsRepository _items;
  final CloudDestinationsRepository _destinations;
  final CloudDestinationWriter _writer;
  final FileSource _files;
  final VerifiedMove _verifiedMove;
  final CloudSourcePreparer _prepare;
  final DateTime Function() _now;

  final List<_Job> _jobs = [];
  final Set<int> _cancelRequested = {};
  final StreamController<Map<int, int>> _progress =
      StreamController<Map<int, int>>.broadcast();
  final Map<int, int> _bytes = {};
  StreamSubscription<({String jobKey, int bytes})>? _progressSub;
  late final StreamSubscription<FileIdChange> _idSub;

  /// Old file id → the file under its new id (this session's renames and
  /// moves), so originals held in memory are found again.
  final Map<String, FileRef> _movedIds = {};

  Future<void>? _recovered;
  Future<void>? _loop;
  int? _current;
  Completer<void>? _currentDone;

  /// "Delete originals" calls run one after another.
  Future<void> _deleting = Future<void>.value();

  /// The running copy's key: unique per attempt, so a late cancel never
  /// hits a later retry of the same item.
  String? _currentKey;
  int _attempt = 0;

  /// Bytes written per uploading item id.
  Stream<Map<int, int>> get progress => _progress.stream;
  Map<int, int> get currentProgress => Map.unmodifiable(_bytes);

  /// Whether [itemId] belongs to a move job still running in memory (its
  /// original will be handled at the job's end).
  bool inRunningJob(int itemId) => _jobs.any(
    (j) => j.pending.contains(itemId) || j.verified.containsKey(itemId),
  );

  bool _busy(int itemId) => _current == itemId || inRunningJob(itemId);

  void _onIdChange(FileIdChange c) {
    _movedIds[c.oldId] = c.newRef;
    _items.rekey(c.oldId, c.newRef.id).fireAndForget();
  }

  /// [f] under its latest id this session.
  FileRef _follow(FileRef f) {
    var cur = f;
    for (var i = 0; i < 32; i++) {
      final next = _movedIds[cur.id];
      if (next == null) break;
      cur = next;
    }
    return cur;
  }

  String _followId(String id) {
    var cur = id;
    for (var i = 0; i < 32; i++) {
      final next = _movedIds[cur];
      if (next == null) break;
      cur = next.id;
    }
    return cur;
  }

  /// Start-up recovery, once: `uploading` rows back to `queued` (their
  /// partial documents are deleted before they are written again), and
  /// documents that couldn't be deleted earlier are tried again.
  Future<void> _recover() => _recovered ??= () async {
    await _items.resetInterrupted();
    for (final r in await _items.leftovers()) {
      final uri = r.remoteUri;
      if (uri == null) continue;
      // A removed destination's grant is gone: nothing can be deleted
      // there any more (the row keeps saying so).
      if (!((await _destinations.byId(r.destinationId))?.isActive ?? false)) {
        continue;
      }
      if (await _tryDelete(uri)) await _items.clearDocument(r.id, uri);
    }
  }();

  /// App start with queued work (only called by `cloudResumeProvider`).
  Future<void> resume() async {
    await _recover();
    _kick();
  }

  /// Queues [req]'s files and starts the loop. [CloudJobHandle.done]
  /// completes when the job's files are finished: with a summary for a
  /// move whose originals were handled, else null. Files another running
  /// job (or the running copy) holds stay with it.
  Future<CloudJobHandle> start(CloudJobRequest req) async {
    await _recover();
    final files = req.files.where(cloudCanRead).toList();
    if (files.isEmpty) {
      return CloudJobHandle(const [], Future.value());
    }
    final r = await _items.enqueue(
      files,
      req.destinationId,
      req.mode,
      busy: _busy,
    );
    final mine = {...r.queued};
    // An old cancel of a re-queued row must not fail this attempt.
    _cancelRequested.removeAll(mine);
    if (mine.isEmpty) {
      _kick();
      return CloudJobHandle(r.ids, Future.value());
    }
    final job = _Job(
      req.mode,
      req.deleteMode,
      mine,
      stripLocation: req.stripLocation,
    );
    _jobs.add(job);
    _kick();
    return CloudJobHandle(r.ids, job.done.future);
  }

  /// Cancels one file: a waiting one fails at once, a running copy stops
  /// at its next chunk (its partial document is deleted). The original is
  /// never touched.
  Future<void> cancel(int itemId) async {
    _cancelRequested.add(itemId);
    if (_current == itemId) {
      if (_currentKey case final key?) await _writer.cancel(key);
      return;
    }
    final failed = await _items.markFailed(itemId, CloudItemErrors.cancelled);
    // Only the running copy reads the flag (and clears it when it ends).
    if (_current != itemId) _cancelRequested.remove(itemId);
    if (failed) await _settle(itemId);
  }

  /// Removes a destination (Settings): its waiting rows fail, a copy
  /// running into it is stopped **before** its grant is released (so the
  /// partial document can still be deleted), partial documents are
  /// deleted, then the grant goes and the jobs of the failed rows end.
  Future<void> removeDestination(
    int destinationId, {
    required bool forgetUploads,
  }) async {
    final removal = await _destinations.markRemoved(
      destinationId,
      forgetUploads: forgetUploads,
    );
    final id = _current;
    final done = _currentDone;
    if (id != null && done != null && removal.failedIds.contains(id)) {
      _cancelRequested.add(id);
      if (_currentKey case final key?) await _writer.cancel(key);
      await done.future;
    }
    for (final p in removal.partials) {
      final deleted = await _tryDelete(p.uri);
      if (forgetUploads) continue; // the rows are gone; only logged
      if (deleted) {
        await _items.clearDocument(p.id, p.uri);
      } else {
        await _items.recordLeftover(p.id, p.uri);
      }
    }
    if (removal.location case final location?) {
      await _destinations.releaseGrant(location);
    }
    for (final failed in removal.failedIds) {
      await _settle(failed);
    }
  }

  /// Resolves when the queue is empty (tests).
  @visibleForTesting
  Future<void> idle() async {
    while (_loop != null) {
      await _loop;
    }
  }

  /// A kick while the loop runs: it runs once more (rows re-queued during
  /// a pass, e.g. a Retry, aren't skipped).
  bool _again = false;

  void _kick() {
    if (_loop != null) {
      _again = true;
      return;
    }
    _progressSub ??= _writer.progress.listen((p) {
      final id = _current;
      if (id == null || p.jobKey != _currentKey) return;
      _bytes[id] = p.bytes;
      _progress.add(Map.unmodifiable(_bytes));
    });
    _loop = _runAll().whenComplete(() => _loop = null);
  }

  Future<void> _runAll() async {
    do {
      _again = false;
      await _run();
    } while (_again);
  }

  Future<void> _run() async {
    final skip = <int>{};
    while (true) {
      final row = await _items.nextQueued(skip: skip);
      if (row == null) break;
      skip.add(row.id);
      _current = row.id;
      _currentKey = 'ci-${row.id}-${++_attempt}';
      final done = _currentDone = Completer<void>();
      try {
        await _process(row);
      } on Object catch (e, st) {
        // Never leave a row uploading because of a bug: it fails, the
        // original stays (and so does any document it holds).
        developer.log(
          'cloud item ${row.id} failed: $e',
          name: 'kfm.cloud',
          stackTrace: st,
        );
        await _items.markFailed(row.id, e.toString());
      } finally {
        _current = null;
        _currentKey = null;
        _currentDone = null;
        _bytes.remove(row.id);
        _progress.add(Map.unmodifiable(_bytes));
        _cancelRequested.remove(row.id);
        done.complete();
      }
      await _settle(row.id);
    }
    await _sweep();
  }

  /// Jobs never wait for rows that finished elsewhere (removed
  /// destination, forgotten rows, a cancel race): their pending ids that
  /// aren't queued/uploading any more are settled.
  Future<void> _sweep() async {
    final pending = {for (final j in _jobs) ...j.pending};
    if (pending.isEmpty) return;
    final rows = {for (final r in await _items.byIds(pending)) r.id: r};
    for (final id in pending) {
      if (id == _current) continue;
      final status = rows[id]?.status;
      if (status == CloudItemStatus.queued ||
          status == CloudItemStatus.uploading) {
        continue;
      }
      await _settle(id);
    }
  }

  Future<void> _fail(int id, String error) => _items.markFailed(id, error);

  /// Deletes a document; false (logged) when the provider refused. A
  /// document that is gone already counts as deleted.
  Future<bool> _tryDelete(String uri) async {
    try {
      await _writer.deleteDocument(uri);
      return true;
    } on Object catch (e) {
      developer.log('cloud copy not deleted: $e', name: 'kfm.cloud');
      return false;
    }
  }

  /// The attempt failed with [error]: its document [uri] is deleted
  /// first; if that fails the row keeps the URI and says so.
  Future<void> _failWith(int id, String error, {String? uri}) async {
    if (uri == null) {
      await _fail(id, error);
      return;
    }
    if (await _tryDelete(uri)) {
      if (!await _items.markFailed(id, error, documentRemoved: true)) {
        await _items.clearDocument(id, uri);
      }
    } else if (!await _items.markFailed(
      id,
      CloudItemErrors.withLeftover(error),
    )) {
      await _items.recordLeftover(id, uri);
    }
  }

  /// The row ended without this attempt (cancelled, destination removed):
  /// its new document goes.
  Future<void> _discard(int id, String uri) async {
    if (await _tryDelete(uri)) {
      await _items.clearDocument(id, uri);
    } else {
      await _items.recordLeftover(id, uri);
    }
  }

  Future<void> _process(CloudItemRow row) async {
    final dest = await _destinations.byId(row.destinationId);
    if (dest == null || !dest.isActive) {
      await _fail(row.id, CloudItemErrors.destinationRemoved);
      return;
    }
    final health = await _destinations.health([dest]);
    if (health[dest.id] == CloudDestinationHealth.needsReconnecting) {
      await _fail(row.id, CloudItemErrors.needsReconnecting);
      return;
    }
    final FileRef? file;
    try {
      file = await _files.stat(row.fileId);
    } on FileOpException catch (e) {
      await _fail(
        row.id,
        e.failure == FileOpFailure.notFound
            ? CloudItemErrors.sourceGone
            : e.failure.name,
      );
      return;
    }
    if (file == null) {
      await _fail(row.id, CloudItemErrors.sourceGone);
      return;
    }
    if (!cloudCanRead(file)) {
      await _fail(row.id, CloudItemErrors.unsupported);
      return;
    }
    final modifiedAtMs = file.modifiedAt.millisecondsSinceEpoch;
    if (!await _items.startUploading(
      row.id,
      sizeBytes: file.sizeBytes,
      sourceModifiedAtMs: modifiedAtMs,
    )) {
      return; // cancelled or removed meanwhile
    }
    if (_cancelRequested.contains(row.id)) {
      await _fail(row.id, CloudItemErrors.cancelled);
      return;
    }
    // A document of an earlier attempt (Retry, restart, kept unverified
    // copy) goes first, so it is never orphaned as "name (1)".
    if (row.remoteUri case final stale?) {
      if (!await _tryDelete(stale)) {
        await _fail(
          row.id,
          CloudItemErrors.withLeftover(CloudWriteFailure.io.name),
        );
        return;
      }
      await _items.clearRemoteUri(row.id);
    }

    final CloudSource source;
    try {
      source = await _prepare(
        file,
        row.id,
        stripLocation: _jobOf(row.id)?.stripLocation,
      );
    } on CloudLocationNotRemoved {
      await _fail(row.id, CloudItemErrors.locationNotRemoved);
      return;
    }
    String? remoteUri;
    try {
      // A crash between createDocument and markUploading can leave one
      // empty document unrecorded (no URI exists before create returns).
      final uri = remoteUri = await _writer.create(
        dest.location,
        file.name,
        file.mimeType,
      );
      if (!await _items.markUploading(row.id, uri)) {
        await _discard(row.id, uri);
        return;
      }
      if (_cancelRequested.contains(row.id)) {
        await _failWith(row.id, CloudItemErrors.cancelled, uri: uri);
        return;
      }
      final written = await _writer.write(
        source: source.source,
        remoteUri: uri,
        jobKey: _currentKey!,
      );
      final expected = source.sizeBytes ?? file.sizeBytes;
      final at = _now().millisecondsSinceEpoch;
      if (_cancelRequested.contains(row.id)) {
        // Cancelled after the last chunk: the copy goes, nothing else.
        await _failWith(row.id, CloudItemErrors.cancelled, uri: uri);
        return;
      }
      // The bytes read must be the whole file as it was stat'ed (else it
      // changed while copying): copies and moves alike.
      if (written.bytes != expected) {
        await _failWith(row.id, CloudItemErrors.sourceChanged, uri: uri);
        return;
      }
      if (row.mode == CloudItemMode.copy) {
        if (!await _items.markHandedToProvider(row.id, written.sha256, at)) {
          await _discard(row.id, uri); // cancelled / removed meanwhile
        }
        return;
      }
      // Move: the read-back must match.
      CloudWriteResult? back;
      Object? backError;
      try {
        back = await _writer.readBack(uri);
      } on Object catch (e) {
        backError = e;
      }
      final result = back == null
          ? VerifyUnavailable(backError ?? StateError('no read-back'))
          : compareCopy(
              sourceSha256: written.sha256,
              sourceSize: written.bytes,
              copySha256: back.sha256,
              copySize: back.bytes,
            );
      switch (result) {
        case final Verified _ when _cancelRequested.contains(row.id):
          await _failWith(row.id, CloudItemErrors.cancelled, uri: uri);
        case final Verified proof:
          if (!await _items.markVerified(row.id, proof.sha256, at)) {
            await _discard(row.id, uri);
            return;
          }
          _jobOf(row.id)?.verified[row.id] = (
            original: VerifiedOriginal(
              original: _follow(file),
              proof: proof,
              modifiedAtMsAtCopy: modifiedAtMs,
            ),
            remoteUri: uri,
            bytes: written.bytes,
          );
        case Mismatch():
          // The copy is bad: deleted, the original stays.
          await _failWith(row.id, CloudItemErrors.verify, uri: uri);
        case VerifyUnavailable():
          // Nothing proven: the copy stays (a Retry replaces it), so does
          // the original.
          await _fail(row.id, CloudItemErrors.verifyUnavailable);
      }
    } on CloudWriteException catch (e) {
      // The writer tries to delete its partial itself; it is deleted again
      // here (gone = fine) so a failed delete is recorded, not lost.
      await _failWith(
        row.id,
        e.failure == CloudWriteFailure.cancelled
            ? CloudItemErrors.cancelled
            : e.failure == CloudWriteFailure.permission
            ? CloudItemErrors.needsReconnecting
            : e.failure.name,
        uri: remoteUri,
      );
    } finally {
      try {
        await source.cleanup?.call();
      } on Object catch (e) {
        developer.log('temp copy not released: $e', name: 'kfm.cloud');
      }
    }
  }

  _Job? _jobOf(int itemId) =>
      _jobs.where((j) => j.pending.contains(itemId)).firstOrNull;

  /// [itemId] is finished: a move job whose last file this was deletes its
  /// verified originals.
  Future<void> _settle(int itemId) async {
    final job = _jobOf(itemId);
    if (job == null) return;
    job.pending.remove(itemId);
    if (job.pending.isNotEmpty) return;
    _jobs.remove(job);
    if (job.mode != CloudItemMode.move || job.verified.isEmpty) {
      job.done.complete(null);
      return;
    }
    try {
      job.done.complete(await _finalize(job.verified, job.deleteMode));
    } on Object catch (e, st) {
      job.done.completeError(e, st);
    }
  }

  /// "Delete originals" for verified move rows whose original is still
  /// there (declined dialog, a restart before the job's end). Always in
  /// trash mode (the job's choice isn't kept across restarts). Calls run
  /// one after another (a double tap never races).
  Future<CloudMoveSummary> deleteOriginals(List<int> itemIds) {
    final run = _deleting.then((_) => _deleteOriginals(itemIds));
    _deleting = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<CloudMoveSummary> _deleteOriginals(List<int> itemIds) async {
    final rows = await _items.byIds(itemIds);
    final entries = <int, _VerifiedEntry>{};
    final settled = <int, ({SourceOutcome outcome, String? error})>{};
    for (final r in rows) {
      final sha = r.sha256;
      final uri = r.remoteUri;
      if (!cloudOriginalMayGo(r) ||
          sha == null ||
          uri == null ||
          inRunningJob(r.id)) {
        continue;
      }
      final FileRef? now;
      try {
        now = await _files.stat(_followId(r.fileId));
      } on FileOpException catch (e) {
        settled[r.id] = (
          outcome: SourceOutcome.keptFailed,
          error: e.failure == FileOpFailure.notFound
              ? CloudItemErrors.sourceGone
              : e.failure.name,
        );
        continue;
      }
      if (now == null) {
        // Not found under this id: maybe gone, maybe renamed while KFM
        // wasn't watching. Never counted as deleted.
        settled[r.id] = (
          outcome: SourceOutcome.keptFailed,
          error: CloudItemErrors.sourceGone,
        );
        continue;
      }
      // The cloud copy is read back again: it must still be the verified
      // bytes (the stored length is the local file's, not a stripped
      // copy's, so the hash is what proves it).
      CloudWriteResult? back;
      try {
        back = await _writer.readBack(uri);
      } on Object catch (e) {
        developer.log('cloud copy not readable: $e', name: 'kfm.cloud');
        back = null;
      }
      if (back == null || back.sha256 != sha) {
        settled[r.id] = (
          outcome: SourceOutcome.keptFailed,
          error: CloudItemErrors.copyMissing,
        );
        continue;
      }
      entries[r.id] = (
        original: VerifiedOriginal(
          original: now.copyWith(sizeBytes: r.sizeBytes),
          proof: Verified(sha256: sha, sizeBytes: r.sizeBytes),
          modifiedAtMsAtCopy: r.sourceModifiedAtMs,
        ),
        remoteUri: uri,
        bytes: back.bytes,
      );
    }
    if (settled.isNotEmpty) await _items.setOutcomes(settled);
    if (entries.isEmpty) {
      return CloudMoveSummary(deleted: 0, kept: settled.length);
    }
    final s = await _finalize(entries, DeleteMode.trash);
    return CloudMoveSummary(deleted: s.deleted, kept: s.kept + settled.length);
  }

  /// The cloud copy must still be there with the verified length before
  /// its original goes; then one N11 call for all (one entry per file: the
  /// same file verified at two destinations is deleted once and both rows
  /// get its outcome).
  Future<CloudMoveSummary> _finalize(
    Map<int, _VerifiedEntry> entries,
    DeleteMode mode,
  ) async {
    final settled = <int, ({SourceOutcome outcome, String? error})>{};
    final idsByFile = <String, List<int>>{};
    final originals = <String, VerifiedOriginal>{};
    for (final MapEntry(key: id, value: e) in entries.entries) {
      int? size;
      try {
        size = await _writer.sizeOf(e.remoteUri);
      } on Object {
        size = null;
      }
      if (size == null || size != e.bytes) {
        settled[id] = (
          outcome: SourceOutcome.keptFailed,
          error: CloudItemErrors.copyMissing,
        );
        continue;
      }
      final o = e.original;
      final f = _follow(o.original);
      final current = identical(f, o.original)
          ? o
          : VerifiedOriginal(
              original: f,
              proof: o.proof,
              modifiedAtMsAtCopy: o.modifiedAtMsAtCopy,
            );
      (idsByFile[f.id] ??= []).add(id);
      originals.putIfAbsent(f.id, () => current);
    }
    if (originals.isNotEmpty) {
      final r = await _verifiedMove.deleteOriginals(
        originals.values.toList(),
        mode: mode,
      );
      for (final MapEntry(key: fileId, value: outcome) in r.outcomes.entries) {
        for (final id in idsByFile[fileId] ?? const <int>[]) {
          settled[id] = (outcome: outcome, error: r.errors[fileId]);
        }
      }
    }
    await _items.setOutcomes(settled);
    var deleted = 0;
    for (final o in settled.values) {
      if (o.outcome == SourceOutcome.trashed ||
          o.outcome == SourceOutcome.deletedPermanently ||
          o.outcome == SourceOutcome.alreadyGone) {
        deleted++;
      }
    }
    return CloudMoveSummary(deleted: deleted, kept: settled.length - deleted);
  }

  Future<void> dispose() async {
    await _idSub.cancel();
    await _progressSub?.cancel();
    await _progress.close();
  }
}
