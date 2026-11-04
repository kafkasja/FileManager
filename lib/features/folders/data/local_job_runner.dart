import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/cross_place_ops.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/place_guard.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/folders/data/fat_names.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';

/// Engine codes stored in `failure_reason` (the UI maps them to text).
abstract final class LocalJobErrors {
  static const placeUnmounted = 'place_unmounted';
  static const interrupted = 'interrupted';
  static const user = 'user';
  static const noSpace = 'no_space';
  static const someFailed = 'some_failed';
  static const sourceGone = 'source_gone';
  static const alreadyMoved = 'already_moved';
  static const exists = 'exists';
  static const fat32TooLarge = 'fat32_too_large';
  static const verificationFailed = 'verification_failed';
  static const copyMissing = 'copy_missing';
  static const placeUnavailable = 'place_unavailable';
}

/// The in-target name a copy is written under until it is verified (SAF
/// targets): a crash mid-import never leaves a partial file under the real
/// name. Swept before the file is copied again.
String localJobTempName(String jobId, int position) =>
    '.kfm-$jobId-$position.part';

/// What to start (the UI ran the pre-checks and asked the questions).
@immutable
class LocalJobRequest {
  const new({
    required this.mode,
    required this.files,
    required this.targetFolder,
    this.collision = CollisionPolicy.keepBoth,
    this.deleteMode,
  });

  final LocalJobMode mode;
  final List<FileRef> files;
  final String targetFolder;
  final CollisionPolicy collision;

  /// Move jobs: the D1 mode for this job.
  final DeleteMode? deleteMode;
}

/// Runs local copy/move jobs between places (TASK-U2): one job at a time,
/// files in position order, each copied and verified by [CrossPlaceOps].
/// Move originals are deleted once per job through N11's [VerifiedMove]
/// (one system dialog per 500). A place that goes away pauses the job;
/// mounting it again resumes it. Verified files are never copied again.
class LocalJobRunner {
  new({
    required this._dao,
    required this._files,
    required this._crossPlace,
    required this._verifiedMove,
    required this._addToIndex,
    required this._isMounted,
    required this._placeOfFile,
    required this._placeOfFolder,
    required this._staging,
    Future<bool> Function(String folder)? isFat32,
    bool Function(String placeId)? isRemovable,
    this._clock = DateTime.now,
    Random? random,
    @visibleForTesting this.fat32MaxBytes = kFat32MaxFileBytes,
    bool Function(String folder)? stagesInTarget,
    PlacesGuard? track,
    this._onJobEnded,
  }) : _track = track ?? unguardedAll,
       _stagesInTarget = stagesInTarget ?? ((_) => false),
       _isFat32 = isFat32 ?? isFat32Volume,
       _isRemovable = isRemovable ?? ((id) => id != 'primary'),
       _random = random ?? Random.secure();

  final LocalJobsDao _dao;
  final FileSource _files;
  final CrossPlaceOps _crossPlace;
  final VerifiedMove _verifiedMove;
  final Future<void> Function(List<FileRef> files) _addToIndex;
  final bool Function(String placeId) _isMounted;
  final String Function(FileRef f) _placeOfFile;
  final String Function(String folder) _placeOfFolder;
  final Future<Directory> Function() _staging;
  final Future<bool> Function(String folder) _isFat32;
  final bool Function(String placeId) _isRemovable;
  final DateTime Function() _clock;
  final Random _random;

  /// U3: each file's copy and the originals' delete count as work on their
  /// places (Eject waits; refused while a place is ejecting).
  final PlacesGuard _track;

  /// Targets whose imports are written under [localJobTempName] first
  /// (SAF: the document exists while its bytes are still streaming).
  final bool Function(String folder) _stagesInTarget;

  /// Called after each job's run (done, paused, failed): Places' free space
  /// refreshes.
  final void Function()? _onJobEnded;

  /// Files this size or larger don't fit on FAT32.
  final int fat32MaxBytes;

  bool _running = false;
  Future<void>? _loop;

  /// X8: bytes of the file being copied, by job id (polled from its staging
  /// part while it grows).
  final Map<String, ({int position, int bytes})> _liveBytes = {};
  final StreamController<Map<String, ({int position, int bytes})>> _live =
      StreamController.broadcast();

  /// X8: how often a copying file's part is measured.
  @visibleForTesting
  Duration livePollInterval = const Duration(milliseconds: 500);

  /// X8: the copying file's bytes per job (position = its row).
  Stream<Map<String, ({int position, int bytes})>> get live => _live.stream;
  Map<String, ({int position, int bytes})> get currentLive =>
      Map.unmodifiable(_liveBytes);

  void _setLive(String jobId, ({int position, int bytes})? v) {
    if (v == null) {
      if (_liveBytes.remove(jobId) == null) return;
    } else {
      _liveBytes[jobId] = v;
    }
    if (_live.hasListener) _live.add(Map.unmodifiable(_liveBytes));
  }

  final Map<String, LocalJobStatus> _stopRequests = {};

  /// Completes when the current run loop ends (tests).
  Future<void> get idle => _loop ?? Future<void>.value();

  int get _now => _clock().millisecondsSinceEpoch;

  /// App start: running jobs → paused, mid-copy files → queued, staging
  /// parts of local jobs deleted.
  Future<void> recover() async {
    await _dao.recoverAtStart();
    for (final job in await _dao.jobsWith({
      LocalJobStatus.queued,
      LocalJobStatus.paused,
      LocalJobStatus.failed,
    })) {
      if (!_stagesInTarget(job.targetFolder) ||
          !_isMounted(job.targetPlaceId)) {
        continue;
      }
      for (final f in await _dao.files(job.id)) {
        if (f.targetId == null) await _sweepTemp(job, f.position);
      }
    }
    try {
      final dir = await _staging();
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.last;
        if (e is File &&
            name.startsWith(CrossPlaceOps.partPrefix) &&
            name.endsWith('.part')) {
          await e.delete();
        }
      }
    } on FileSystemException catch (e) {
      developer.log('staging sweep failed: $e', name: 'kfm.localJobs');
    }
  }

  /// Creates the job and starts it (or queues it behind the running one).
  Future<String> start(LocalJobRequest r) async {
    final id = randomHexId(_random);
    final now = _now;
    final removable = _isRemovable(_placeOfFolder(r.targetFolder));
    await _dao.create(
      LocalJobsCompanion.insert(
        id: id,
        mode: r.mode,
        targetPlaceId: _placeOfFolder(r.targetFolder),
        targetFolder: r.targetFolder,
        status: LocalJobStatus.queued,
        collisionPolicy: Value(r.collision),
        deleteMode: Value(
          r.mode == LocalJobMode.move
              ? (r.deleteMode ?? DeleteMode.trash).name
              : null,
        ),
        createdAtMs: now,
        updatedAtMs: now,
      ),
      [
        for (final (i, f) in r.files.indexed)
          LocalJobFilesCompanion.insert(
            jobId: id,
            position: i,
            sourceId: f.id,
            sourcePlaceId: _placeOfFile(f),
            originalName: f.name,
            targetName: removable ? fatSafeName(f.name) : f.name,
            sizeBytes: f.sizeBytes,
            status: LocalFileStatus.queued,
            sourceModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
          ),
      ],
    );
    _kick();
    return id;
  }

  /// Stops after the current file (that file finishes or starts over).
  Future<void> pause(String id) async {
    final job = await _dao.job(id);
    if (job == null) return;
    if (job.status == LocalJobStatus.running) {
      _stopRequests[id] = LocalJobStatus.paused;
    } else if (job.status == LocalJobStatus.queued) {
      await _dao.setJob(
        id,
        LocalJobStatus.paused,
        failureReason: LocalJobErrors.user,
      );
    }
  }

  Future<void> resume(String id) async {
    final job = await _dao.job(id);
    if (job == null ||
        (job.status != LocalJobStatus.paused &&
            job.status != LocalJobStatus.failed)) {
      return;
    }
    if (job.status == LocalJobStatus.failed) {
      // Retry: failed files go again (verified ones never do).
      for (final f in await _dao.files(id)) {
        if (f.status == LocalFileStatus.failed) {
          await _dao.setFile(
            id,
            f.position,
            const LocalJobFilesCompanion(
              status: Value(LocalFileStatus.queued),
              failureReason: Value(null),
            ),
          );
        }
      }
    }
    await _dao.setJob(id, LocalJobStatus.queued, nowMs: _now);
    _kick();
  }

  Future<void> cancel(String id) async {
    final job = await _dao.job(id);
    if (job == null) return;
    if (job.status == LocalJobStatus.running) {
      _stopRequests[id] = LocalJobStatus.cancelled;
      return;
    }
    if (job.status == LocalJobStatus.done ||
        job.status == LocalJobStatus.cancelled) {
      return;
    }
    await _markCancelled(id);
  }

  /// U3: running or queued jobs that read from or write to [placeId].
  Future<List<String>> activeJobsOn(String placeId) async {
    final out = <String>[];
    final jobs = await _dao.jobsWith({
      LocalJobStatus.running,
      LocalJobStatus.queued,
    });
    for (final job in jobs) {
      if (job.targetPlaceId == placeId ||
          (await _dao.files(job.id)).any(
            (f) =>
                f.sourcePlaceId == placeId &&
                (f.status == LocalFileStatus.queued ||
                    f.status == LocalFileStatus.copying ||
                    f.status == LocalFileStatus.verifying),
          )) {
        out.add(job.id);
      }
    }
    return out;
  }

  /// U3 "Pause & eject": pauses every job on [placeId]. A running job
  /// stops after its current file (which completes and is verified, so no
  /// partial file stays); everything else stays queued and resumable.
  Future<int> pauseWhere(String placeId) async {
    final ids = await activeJobsOn(placeId);
    for (final id in ids) {
      await pause(id);
    }
    return ids.length;
  }

  /// Places changed (U1): paused jobs whose places are all back resume.
  Future<void> onPlacesChanged() async {
    for (final job in await _dao.jobsWith({LocalJobStatus.paused})) {
      if (job.failureReason != LocalJobErrors.placeUnmounted) continue;
      if (!await _placesMounted(job)) continue;
      await _dao.setJob(job.id, LocalJobStatus.queued, nowMs: _now);
    }
    _kick();
  }

  Future<bool> _placesMounted(LocalJobRow job) async {
    if (!_isMounted(job.targetPlaceId)) return false;
    for (final f in await _dao.files(job.id)) {
      if (f.status == LocalFileStatus.queued && !_isMounted(f.sourcePlaceId)) {
        return false;
      }
    }
    return true;
  }

  /// "Delete originals" for a move job whose originals were kept
  /// (declined dialog, failure, cancel).
  Future<void> deleteOriginals(String id) async {
    final job = await _dao.job(id);
    if (job == null || job.mode != LocalJobMode.move) return;
    final view = LocalJobView(job, await _dao.files(id));
    final rows = view.originalsLeft;
    await _track({
      job.targetPlaceId,
      for (final r in rows) r.sourcePlaceId,
    }, () => _finalize(job, rows));
  }

  void _kick() {
    if (_running) return;
    _running = true;
    _loop = _runAll().whenComplete(() => _running = false);
  }

  Future<void> _runAll() async {
    while (true) {
      final queued = await _dao.jobsWith({LocalJobStatus.queued});
      if (queued.isEmpty) return;
      try {
        await _runJob(queued.first);
      } on Object catch (e, s) {
        developer.log('job failed: $e', name: 'kfm.localJobs', stackTrace: s);
        await _dao.setJob(
          queued.first.id,
          LocalJobStatus.failed,
          failureReason: e is FileOpException ? e.failure.name : 'internal',
          nowMs: _now,
        );
      } finally {
        _onJobEnded?.call();
      }
    }
  }

  Future<void> _runJob(LocalJobRow job) async {
    await _dao.setJob(job.id, LocalJobStatus.running, nowMs: _now);
    final files = await _dao.files(job.id);
    final policy = job.collisionPolicy ?? CollisionPolicy.keepBoth;
    // Names this job wrote itself: never a "clash" to skip or replace (two
    // selected files with one target name both survive as keep-both).
    final written = {
      for (final f in files)
        if (f.targetId != null) f.targetName.toLowerCase(),
    };
    for (final row in files) {
      if (row.status != LocalFileStatus.queued) continue;
      switch (_stopRequests.remove(job.id)) {
        case LocalJobStatus.paused:
          await _dao.setJob(
            job.id,
            LocalJobStatus.paused,
            failureReason: LocalJobErrors.user,
            nowMs: _now,
          );
          return;
        case LocalJobStatus.cancelled:
          await _markCancelled(job.id);
          return;
        case _:
          break;
      }
      if (!_isMounted(job.targetPlaceId) || !_isMounted(row.sourcePlaceId)) {
        await _pauseUnmounted(job.id);
        return;
      }
      final bool stop;
      try {
        stop = await _track({
          job.targetPlaceId,
          row.sourcePlaceId,
        }, () => _copyOne(job, row, policy, written));
      } on FileOpException catch (e) {
        if (e.failure != FileOpFailure.volumeEjecting) rethrow;
        // U3: a place is being ejected: stop here, resumable.
        await _dao.setJob(
          job.id,
          LocalJobStatus.paused,
          failureReason: LocalJobErrors.user,
          nowMs: _now,
        );
        return;
      }
      if (stop) return;
    }
    if (_stopRequests.remove(job.id) == LocalJobStatus.cancelled) {
      await _markCancelled(job.id);
      return;
    }
    var latest = await _dao.files(job.id);
    if (job.mode == LocalJobMode.move) {
      final rows = [
        for (final f in latest)
          if (f.status == LocalFileStatus.verified && f.sourceOutcome == null)
            f,
      ];
      try {
        await _track({
          job.targetPlaceId,
          for (final r in rows) r.sourcePlaceId,
        }, () => _finalize(job, rows));
      } on FileOpException catch (e) {
        // U3: ejecting: the originals stay ("Delete originals" later).
        if (e.failure != FileOpFailure.volumeEjecting) rethrow;
      }
      latest = await _dao.files(job.id);
    }
    final failed = latest.any((f) => f.status == LocalFileStatus.failed);
    await _dao.setJob(
      job.id,
      failed ? LocalJobStatus.failed : LocalJobStatus.done,
      failureReason: failed ? LocalJobErrors.someFailed : null,
      nowMs: _now,
    );
  }

  /// Copies one file. True = the job stopped (paused / failed).
  Future<bool> _copyOne(
    LocalJobRow job,
    LocalJobFileRow row,
    CollisionPolicy policy,
    Set<String> written,
  ) async {
    final pos = row.position;
    Future<void> fail(String reason) => _dao.setFile(
      job.id,
      pos,
      LocalJobFilesCompanion(
        status: const Value(LocalFileStatus.failed),
        failureReason: Value(reason),
      ),
    );
    final FileRef? source;
    try {
      source = await _files.stat(row.sourceId);
    } on FileOpException catch (e) {
      if (await _unmountedNow(job, row)) {
        await _pauseUnmounted(job.id);
        return true;
      }
      await fail(e.failure.name);
      return false;
    }
    if (source == null) {
      if (!_isMounted(row.sourcePlaceId)) {
        await _pauseUnmounted(job.id);
        return true;
      }
      if (job.mode == LocalJobMode.move) {
        await _dao.setFile(
          job.id,
          pos,
          const LocalJobFilesCompanion(
            status: Value(LocalFileStatus.skipped),
            failureReason: Value(LocalJobErrors.alreadyMoved),
          ),
        );
      } else {
        await fail(LocalJobErrors.sourceGone);
      }
      return false;
    }
    if (source.sizeBytes >= fat32MaxBytes && await _isFat32(job.targetFolder)) {
      await fail(LocalJobErrors.fat32TooLarge);
      return false;
    }
    final staged = _stagesInTarget(job.targetFolder);
    final FileRef? existing;
    try {
      if (staged) await _sweepTemp(job, pos);
      final found = await _files.statPath(
        '${job.targetFolder}/${row.targetName}',
      );
      // Only a file that was there before this job is a clash.
      existing = found != null && !written.contains(found.name.toLowerCase())
          ? found
          : null;
    } on FileOpException catch (e) {
      if (await _unmountedNow(job, row)) {
        await _pauseUnmounted(job.id);
        return true;
      }
      await fail(e.failure.name);
      return false;
    }
    if (existing != null && policy == CollisionPolicy.skip) {
      await _dao.setFile(
        job.id,
        pos,
        const LocalJobFilesCompanion(
          status: Value(LocalFileStatus.skipped),
          failureReason: Value(LocalJobErrors.exists),
        ),
      );
      return false;
    }
    await _dao.setFile(
      job.id,
      pos,
      LocalJobFilesCompanion(
        status: const Value(LocalFileStatus.copying),
        sizeBytes: Value(source.sizeBytes),
        sourceModifiedAtMs: Value(source.modifiedAt.millisecondsSinceEpoch),
      ),
    );
    final partName = '${CrossPlaceOps.partPrefix}${job.id}-$pos.part';
    final poll = await _pollPart(job.id, pos, partName);
    try {
      final done = await _crossPlace.copyVerified(
        source,
        job.targetFolder,
        name: staged ? localJobTempName(job.id, pos) : row.targetName,
        // A neutral type, so the provider keeps the temp name as given.
        mimeType: staged ? 'application/octet-stream' : null,
        partName: partName,
        onVerifying: () => _dao
            .setFile(
              job.id,
              pos,
              const LocalJobFilesCompanion(
                status: Value(LocalFileStatus.verifying),
              ),
            )
            .ignore(),
      );
      var copy = done.copy;
      if (existing != null && policy == CollisionPolicy.replace) {
        // The old file goes only now that the new one is verified.
        await _files.deletePermanentlyBatch([existing]);
        copy = await _files.rename(copy, row.targetName);
      } else if (staged) {
        // Keep both: a taken name gets ` (1)`.
        copy = await _files.rename(copy, row.targetName);
      }
      written.add(copy.name.toLowerCase());
      if (copy.id.startsWith('ms:') || copy.id.startsWith('path:')) {
        try {
          await _addToIndex([copy]);
        } on Object catch (e) {
          developer.log('copy not indexed: $e', name: 'kfm.localJobs');
        }
      }
      await _dao.setFile(
        job.id,
        pos,
        LocalJobFilesCompanion(
          status: Value(
            job.mode == LocalJobMode.copy
                ? LocalFileStatus.done
                : LocalFileStatus.verified,
          ),
          targetId: Value(copy.id),
          targetName: Value(copy.name),
          sha256: Value(done.sha256),
        ),
      );
      return false;
    } on CopyVerificationException {
      await fail(LocalJobErrors.verificationFailed);
      return false;
    } on FileOpException catch (e) {
      if (e.failure == FileOpFailure.noSpace) {
        await _requeue(job.id, pos);
        await _dao.setJob(
          job.id,
          LocalJobStatus.failed,
          failureReason: LocalJobErrors.noSpace,
          nowMs: _now,
        );
        return true;
      }
      if (await _unmountedNow(job, row)) {
        await _requeue(job.id, pos);
        await _pauseUnmounted(job.id);
        return true;
      }
      await fail(e.failure.name);
      return false;
    } on FileSystemException catch (e) {
      if (await _unmountedNow(job, row)) {
        await _requeue(job.id, pos);
        await _pauseUnmounted(job.id);
        return true;
      }
      await fail(FileOpFailure.ioError.name);
      developer.log('copy failed: $e', name: 'kfm.localJobs');
      return false;
    } finally {
      poll?.cancel();
      _setLive(job.id, null);
    }
  }

  /// X8: measures [partName] in the staging folder while it is copied.
  Future<Timer?> _pollPart(String jobId, int pos, String partName) async {
    final Directory dir;
    try {
      dir = await _staging();
    } on Object {
      return null;
    }
    final part = File('${dir.path}/$partName');
    _setLive(jobId, (position: pos, bytes: 0));
    var busy = false;
    return Timer.periodic(livePollInterval, (_) async {
      if (busy) return;
      busy = true;
      try {
        if (await part.exists()) {
          final n = await part.length();
          if (_liveBytes.containsKey(jobId)) {
            _setLive(jobId, (position: pos, bytes: n));
          }
        }
      } on FileSystemException {
        // Gone between the checks (imported or deleted).
      } finally {
        busy = false;
      }
    });
  }

  Future<bool> _unmountedNow(LocalJobRow job, LocalJobFileRow row) async =>
      !_isMounted(job.targetPlaceId) || !_isMounted(row.sourcePlaceId);

  Future<void> _requeue(String jobId, int pos) => _dao.setFile(
    jobId,
    pos,
    const LocalJobFilesCompanion(status: Value(LocalFileStatus.queued)),
  );

  Future<void> _pauseUnmounted(String id) => _dao.setJob(
    id,
    LocalJobStatus.paused,
    failureReason: LocalJobErrors.placeUnmounted,
    nowMs: _now,
  );

  Future<void> _markCancelled(String id) async {
    final job = await _dao.job(id);
    if (job == null) return;
    if (job.mode == LocalJobMode.move) {
      await _dao.setOutcomes(id, {
        for (final f in await _dao.files(id))
          if (f.status == LocalFileStatus.verified && f.sourceOutcome == null)
            f.position: (outcome: SourceOutcome.keptCancelled, error: null),
      });
    }
    await _dao.setJob(id, LocalJobStatus.cancelled, nowMs: _now);
  }

  Future<bool> _copyIntact(LocalJobRow job, LocalJobFileRow r) async {
    final target = r.targetId;
    if (target == null || !_isMounted(job.targetPlaceId)) return false;
    try {
      final copy = await _files.stat(target);
      return copy != null && copy.sizeBytes == r.sizeBytes;
    } on FileOpException {
      return false;
    }
  }

  /// Deletes a leftover in-target temp file of [pos] (a crash mid-import).
  Future<void> _sweepTemp(LocalJobRow job, int pos) async {
    final stale = await _files.statPath(
      '${job.targetFolder}/${localJobTempName(job.id, pos)}',
    );
    if (stale != null) await _files.deletePermanentlyBatch([stale]);
  }

  /// One N11 `deleteOriginals` call for [rows]' originals; outcomes are
  /// stored, and moved files are announced so labels follow them.
  Future<void> _finalize(LocalJobRow job, List<LocalJobFileRow> rows) async {
    if (rows.isEmpty) return;
    final mode =
        DeleteMode.values.asNameMap()[job.deleteMode] ?? DeleteMode.trash;
    final originals = <VerifiedOriginal>[];
    final byId = <String, LocalJobFileRow>{};
    final settled = <int, ({SourceOutcome outcome, String? error})>{};
    for (final r in rows) {
      // The copy must still be there, whole, before an original goes.
      if (!await _copyIntact(job, r)) {
        settled[r.position] = (
          outcome: SourceOutcome.keptFailed,
          error: LocalJobErrors.copyMissing,
        );
        continue;
      }
      if (!_isMounted(r.sourcePlaceId)) {
        settled[r.position] = (
          outcome: SourceOutcome.keptFailed,
          error: LocalJobErrors.placeUnavailable,
        );
        continue;
      }
      final FileRef? now;
      try {
        now = await _files.stat(r.sourceId);
      } on FileOpException catch (e) {
        settled[r.position] = (
          outcome: SourceOutcome.keptFailed,
          error: e.failure.name,
        );
        continue;
      }
      if (now == null) {
        settled[r.position] = (outcome: SourceOutcome.alreadyGone, error: null);
        continue;
      }
      byId[r.sourceId] = r;
      originals.add(
        VerifiedOriginal(
          original: now.copyWith(sizeBytes: r.sizeBytes),
          proof: Verified(sha256: r.sha256!, sizeBytes: r.sizeBytes),
          modifiedAtMsAtCopy: r.sourceModifiedAtMs,
        ),
      );
    }
    if (originals.isNotEmpty) {
      final result = await _verifiedMove.deleteOriginals(originals, mode: mode);
      for (final MapEntry(key: id, value: outcome) in result.outcomes.entries) {
        final r = byId[id];
        if (r == null) continue;
        settled[r.position] = (outcome: outcome, error: result.errors[id]);
      }
    }
    await _dao.setOutcomes(job.id, settled);
    for (final r in rows) {
      final o = settled[r.position]?.outcome;
      if (o != SourceOutcome.trashed &&
          o != SourceOutcome.deletedPermanently &&
          o != SourceOutcome.alreadyGone) {
        continue;
      }
      final target = r.targetId;
      if (target == null) continue;
      try {
        final copy = await _files.stat(target);
        if (copy != null) _crossPlace.announceMoved(r.sourceId, copy);
      } on FileOpException catch (e) {
        developer.log('copy not found for re-key: $e', name: 'kfm.localJobs');
      }
    }
  }
}
