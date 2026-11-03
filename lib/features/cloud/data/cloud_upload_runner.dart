import 'dart:async';
import 'dart:developer' as developer;

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

typedef CloudSourcePreparer = Future<CloudSource> Function(
  FileRef file,
  int itemId,
);

/// Ids whose bytes the runner can read (MediaStore, paths, U2's SAF
/// places). MTP cameras and remote devices aren't offered.
bool cloudCanRead(FileRef f) =>
    f.id.startsWith('ms:') ||
    f.id.startsWith('path:') ||
    f.id.startsWith('saf:');

/// The file as it is.
Future<CloudSource> plainCloudSource(FileRef f, int itemId) async =>
    CloudSource(source: f.uri);

/// One user request: files to one destination.
@immutable
class CloudJobRequest {
  const new({
    required this.files,
    required this.destinationId,
    required this.mode,
    this.deleteMode = DeleteMode.trash,
  });

  final List<FileRef> files;
  final int destinationId;
  final CloudItemMode mode;

  /// Moves: the delete mode of this job (D1 at start, or "Use trash
  /// instead"). Kept in memory only; after a restart it is trash.
  final DeleteMode deleteMode;
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

class _Job {
  new(this.mode, this.deleteMode, this.pending);

  final CloudItemMode mode;
  final DeleteMode deleteMode;
  final Set<int> pending;
  final Completer<CloudMoveSummary?> done = Completer<CloudMoveSummary?>();

  /// itemId → original + the document whose bytes were verified.
  final Map<int, ({VerifiedOriginal original, String remoteUri, int bytes})>
  verified = {};
}

/// X3's own upload runner (not N9's transfer kinds): one file at a time,
/// oldest first. Copy → `handedToProvider`; move → read-back SHA-256 →
/// N11's [compareCopy] → `verified`, and at the job's end one
/// [VerifiedMove.deleteOriginals] call for all its verified originals.
///
/// Created lazily (Hard rule 1): nothing here runs until [start] or
/// [resume] is called.
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
       _now = now ?? DateTime.now;

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

  Future<void>? _recovered;
  Future<void>? _loop;
  int? _current;

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

  /// Start-up recovery, once: `uploading` rows back to `queued`, their
  /// partial documents deleted ("not found" is fine).
  Future<void> _recover() => _recovered ??= () async {
    final partials = await _items.resetInterrupted();
    for (final uri in partials) {
      try {
        await _writer.deleteDocument(uri);
      } on Object catch (e) {
        developer.log('partial not deleted: $e', name: 'kfm.cloud');
      }
    }
  }();

  /// App start with queued work (only called by `cloudResumeProvider`).
  Future<void> resume() async {
    await _recover();
    _kick();
  }

  /// Queues [req]'s files and starts the loop. [CloudJobHandle.done]
  /// completes when the job's files are finished: with a summary for a
  /// move whose originals were handled, else null.
  Future<CloudJobHandle> start(CloudJobRequest req) async {
    await _recover();
    final files = req.files.where(cloudCanRead).toList();
    if (files.isEmpty) {
      return CloudJobHandle(const [], Future.value());
    }
    final ids = await _items.enqueue(files, req.destinationId, req.mode);
    final mine = {
      for (final id in ids)
        if (!inRunningJob(id)) id,
    };
    if (mine.isEmpty) {
      _kick();
      return CloudJobHandle(ids, Future.value());
    }
    final job = _Job(req.mode, req.deleteMode, mine);
    _jobs.add(job);
    _kick();
    return CloudJobHandle(ids, job.done.future);
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
    if (await _items.markFailed(itemId, CloudItemErrors.cancelled)) {
      await _settle(itemId);
    }
  }

  /// A removed destination's running copy stops (its rows already failed
  /// in the remove transaction).
  Future<void> onDestinationRemoved(int destinationId) async {
    final id = _current;
    if (id == null) return;
    final row = await _items.byId(id);
    if (row?.destinationId == destinationId) {
      _cancelRequested.add(id);
      if (_currentKey case final key?) await _writer.cancel(key);
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
      try {
        await _process(row);
      } on Object catch (e, st) {
        // Never leave a row uploading because of a bug: it fails, the
        // original stays.
        developer.log(
          'cloud item ${row.id} failed: $e',
          name: 'kfm.cloud',
          stackTrace: st,
        );
        await _items.markFailed(row.id, e.toString(), keepRemoteUri: true);
      } finally {
        _current = null;
        _currentKey = null;
        _bytes.remove(row.id);
        _progress.add(Map.unmodifiable(_bytes));
        _cancelRequested.remove(row.id);
      }
      await _settle(row.id);
    }
  }

  Future<void> _fail(int id, String error, {bool keepRemoteUri = false}) =>
      _items.markFailed(id, error, keepRemoteUri: keepRemoteUri);

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

    final CloudSource source;
    try {
      source = await _prepare(file, row.id);
    } on CloudLocationNotRemoved {
      await _fail(row.id, CloudItemErrors.locationNotRemoved);
      return;
    }
    String? remoteUri;
    try {
      remoteUri = await _writer.create(dest.location, file.name, file.mimeType);
      if (!await _items.markUploading(row.id, remoteUri)) {
        await _dropDocument(remoteUri);
        return;
      }
      if (_cancelRequested.contains(row.id)) {
        await _dropDocument(remoteUri);
        await _fail(row.id, CloudItemErrors.cancelled);
        return;
      }
      final written = await _writer.write(
        source: source.source,
        remoteUri: remoteUri,
        jobKey: _currentKey!,
      );
      final expected = source.sizeBytes ?? file.sizeBytes;
      final at = _now().millisecondsSinceEpoch;
      if (_cancelRequested.contains(row.id)) {
        // Cancelled after the last chunk: the copy goes, nothing else.
        await _dropDocument(remoteUri);
        await _fail(row.id, CloudItemErrors.cancelled);
        return;
      }
      if (row.mode == CloudItemMode.copy) {
        if (!await _items.markHandedToProvider(row.id, written.sha256, at)) {
          await _dropDocument(remoteUri); // cancelled / removed meanwhile
        }
        return;
      }
      // Move: the bytes read must be the whole file as it was stat'ed
      // (else it changed while copying), and the read-back must match.
      if (written.bytes != expected) {
        await _dropDocument(remoteUri);
        await _fail(row.id, CloudItemErrors.sourceChanged);
        return;
      }
      CloudWriteResult? back;
      Object? backError;
      try {
        back = await _writer.readBack(remoteUri);
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
          await _dropDocument(remoteUri);
          await _fail(row.id, CloudItemErrors.cancelled);
        case final Verified proof:
          if (!await _items.markVerified(row.id, proof.sha256, at)) {
            await _dropDocument(remoteUri);
            return;
          }
          _jobOf(row.id)?.verified[row.id] = (
            original: VerifiedOriginal(
              original: file,
              proof: proof,
              modifiedAtMsAtCopy: modifiedAtMs,
            ),
            remoteUri: remoteUri,
            bytes: written.bytes,
          );
        case Mismatch():
          // The copy is bad: deleted, the original stays.
          await _dropDocument(remoteUri);
          await _fail(row.id, CloudItemErrors.verify);
        case VerifyUnavailable():
          // Nothing proven: the copy stays, so does the original.
          await _fail(
            row.id,
            CloudItemErrors.verifyUnavailable,
            keepRemoteUri: true,
          );
      }
    } on CloudWriteException catch (e) {
      // The writer deleted its partial document itself.
      await _fail(
        row.id,
        e.failure == CloudWriteFailure.cancelled
            ? CloudItemErrors.cancelled
            : e.failure == CloudWriteFailure.permission
            ? CloudItemErrors.needsReconnecting
            : e.failure.name,
      );
    } finally {
      try {
        await source.cleanup?.call();
      } on Object catch (e) {
        developer.log('temp copy not released: $e', name: 'kfm.cloud');
      }
    }
  }

  Future<void> _dropDocument(String uri) async {
    try {
      await _writer.deleteDocument(uri);
    } on Object catch (e) {
      developer.log('cloud copy not deleted: $e', name: 'kfm.cloud');
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
  /// trash mode (the job's choice isn't kept across restarts).
  Future<CloudMoveSummary> deleteOriginals(List<int> itemIds) async {
    final rows = await _items.byIds(itemIds);
    final entries =
        <int, ({VerifiedOriginal original, String remoteUri, int bytes})>{};
    final settled = <int, ({SourceOutcome outcome, String? error})>{};
    for (final r in rows) {
      final sha = r.sha256;
      final uri = r.remoteUri;
      if (r.mode != CloudItemMode.move ||
          r.status != CloudItemStatus.verified ||
          sha == null ||
          uri == null ||
          inRunningJob(r.id)) {
        continue;
      }
      final FileRef? now;
      try {
        now = await _files.stat(r.fileId);
      } on FileOpException catch (e) {
        settled[r.id] = (
          outcome: SourceOutcome.keptFailed,
          error: e.failure.name,
        );
        continue;
      }
      if (now == null) {
        settled[r.id] = (outcome: SourceOutcome.alreadyGone, error: null);
        continue;
      }
      entries[r.id] = (
        original: VerifiedOriginal(
          original: now.copyWith(sizeBytes: r.sizeBytes),
          proof: Verified(sha256: sha, sizeBytes: r.sizeBytes),
          modifiedAtMsAtCopy: r.sourceModifiedAtMs,
        ),
        remoteUri: uri,
        // Unknown for a stripped copy: only presence is checked then.
        bytes: -1,
      );
    }
    if (settled.isNotEmpty) await _items.setOutcomes(settled);
    if (entries.isEmpty) {
      return CloudMoveSummary(deleted: 0, kept: settled.length);
    }
    return await _finalize(entries, DeleteMode.trash);
  }

  /// The cloud copy must still be there (with the verified length when
  /// known) before its original goes; then one N11 call for all.
  Future<CloudMoveSummary> _finalize(
    Map<int, ({VerifiedOriginal original, String remoteUri, int bytes})>
    entries,
    DeleteMode mode,
  ) async {
    final settled = <int, ({SourceOutcome outcome, String? error})>{};
    final byFileId = <String, int>{};
    final originals = <VerifiedOriginal>[];
    for (final MapEntry(key: id, value: e) in entries.entries) {
      int? size;
      try {
        size = await _writer.sizeOf(e.remoteUri);
      } on Object {
        size = null;
      }
      if (size == null || (e.bytes >= 0 && size != e.bytes)) {
        settled[id] = (
          outcome: SourceOutcome.keptFailed,
          error: CloudItemErrors.copyMissing,
        );
        continue;
      }
      byFileId[e.original.original.id] = id;
      originals.add(e.original);
    }
    if (originals.isNotEmpty) {
      final r = await _verifiedMove.deleteOriginals(originals, mode: mode);
      for (final MapEntry(key: fileId, value: outcome) in r.outcomes.entries) {
        final id = byFileId[fileId];
        if (id == null) continue;
        settled[id] = (outcome: outcome, error: r.errors[fileId]);
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
    await _progressSub?.cancel();
    await _progress.close();
  }
}
