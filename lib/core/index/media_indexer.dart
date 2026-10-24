import 'dart:async';

import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:meta/meta.dart';

@immutable
sealed class IndexStatus {
  const new();
}

class IndexIdle extends IndexStatus {
  const new(this.lastScan);

  final DateTime? lastScan;
}

class IndexScanning extends IndexStatus {
  const new({required this.found, required this.isFirstScan});

  final int found;
  final bool isFirstScan;
}

class IndexFailed extends IndexStatus {
  const new(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Keeps `media_index` in sync with the device (TASK-F5).
///
/// - Full scan: every row seen gets a fresh generation; when the scan
///   completes, rows of the scanned kinds with an older generation are
///   deleted. A failed or killed scan deletes nothing.
/// - Incremental scan: files modified since the last scan (no deletions).
/// - Live changes: MediaStore deletes by id; inserts/updates → incremental.
/// - FileSource.idChanges re-key rows.
///
/// Jobs run one at a time. Failures become [IndexFailed]; they are never
/// swallowed.
class MediaIndexer {
  new({
    required this._dao,
    required FileSource source,
    required this._settings,
    required this._canSeeAllFiles,
    Stream<MediaChange> changes = const Stream.empty(),
    this._clock = DateTime.now,
  }) : _source = source {
    _idSub = source.idChanges.listen(
      (c) => unawaited(_serial(() => _dao.applyIdChange(c))),
    );
    _changeSub = changes.listen(onMediaChange);
  }

  static const fullScanInterval = Duration(hours: 24);
  static const changeDebounce = Duration(seconds: 2);

  /// Incremental scans look this far before the last scan (clock skew,
  /// 1-second MediaStore resolution).
  static const incrementalOverlap = Duration(minutes: 1);

  final MediaIndexDao _dao;
  final FileSource _source;
  final SettingsRepository _settings;
  final bool Function() _canSeeAllFiles;
  final DateTime Function() _clock;

  final StreamController<IndexStatus> _status =
      StreamController<IndexStatus>.broadcast();
  IndexStatus _current = const IndexIdle(null);
  Future<void> _tail = Future<void>.value();
  late final StreamSubscription<FileIdChange> _idSub;
  late final StreamSubscription<MediaChange> _changeSub;

  Timer? _changeTimer;
  final Set<String> _pendingDeletes = {};
  bool _pendingIncremental = false;
  bool _pendingMediaFullScan = false;

  Stream<IndexStatus> get status => _status.stream;
  IndexStatus get current => _current;

  /// App start / access granted: full scan the first time, otherwise an
  /// incremental scan, plus a full scan if the last one is >24 h old.
  Future<void> start() => _serial(() async {
    final lastFull = await _lastFullScan();
    if (lastFull == null) {
      await _fullScan(_allowedKinds(), isFirstScan: true);
      return;
    }
    await _incremental();
    if (_clock().difference(lastFull) > fullScanInterval) {
      await _fullScan(_allowedKinds(), isFirstScan: false);
    }
  });

  Future<void> fullScan({Set<FileKind>? kinds}) => _serial(() async {
    final allowed = _allowedKinds();
    await _fullScan(
      kinds == null ? allowed : kinds.intersection(allowed),
      isFirstScan: await _lastFullScan() == null,
    );
  });

  Future<void> incremental() => _serial(_incremental);

  /// Files this app brought back (trash restore): back into the index now,
  /// since their modified time is old and an incremental scan skips them.
  Future<void> addFiles(List<FileRef> files) => _serial(() async {
    if (files.isEmpty) return;
    final generation = await _settings.read(AppSettings.indexGeneration);
    await _dao.upsertBatch(files, generation, now: _clock());
  });

  /// Batches live changes for [changeDebounce], then applies them.
  void onMediaChange(MediaChange change) {
    if (change.type == 'delete') {
      if (change.id != null) {
        _pendingDeletes.add('ms:${change.id}');
      } else {
        _pendingMediaFullScan = true;
      }
    } else {
      _pendingIncremental = true;
    }
    _changeTimer?.cancel();
    _changeTimer = Timer(changeDebounce, () => unawaited(_applyChanges()));
  }

  Future<void> dispose() async {
    _changeTimer?.cancel();
    await _idSub.cancel();
    await _changeSub.cancel();
    await _tail;
    await _status.close();
  }

  // ---- jobs ----

  Future<void> _applyChanges() => _serial(() async {
    final deletes = _pendingDeletes.toList();
    final mediaFull = _pendingMediaFullScan;
    final incremental = _pendingIncremental;
    _pendingDeletes.clear();
    _pendingMediaFullScan = false;
    _pendingIncremental = false;
    if (deletes.isNotEmpty) await _dao.deleteIds(deletes);
    if (mediaFull) {
      await _fullScan(mediaKinds, isFirstScan: false);
    } else if (incremental) {
      await _incremental();
    }
  });

  Future<void> _fullScan(
    Set<FileKind> kinds, {
    required bool isFirstScan,
  }) async {
    if (kinds.isEmpty) return;
    final startedAt = _clock().toUtc();
    // Each attempt gets a fresh generation, persisted up front, so rows seen
    // by a killed attempt are still cleaned up by the next complete one.
    final generation = await _settings.read(AppSettings.indexGeneration) + 1;
    await _settings.write(AppSettings.indexGeneration, generation);

    var found = 0;
    _emit(IndexScanning(found: 0, isFirstScan: isFirstScan));
    await for (final page in _source.scan(query: FileQuery(kinds: kinds))) {
      await _dao.upsertBatch(page, generation, now: _clock());
      found += page.length;
      _emit(IndexScanning(found: found, isFirstScan: isFirstScan));
    }
    await _dao.deleteOlderThanGeneration(generation, kinds: kinds);
    final stamp = startedAt.toIso8601String();
    await _settings.write(AppSettings.indexLastFullScanAt, stamp);
    await _settings.write(AppSettings.indexLastIncrementalAt, stamp);
    _emit(IndexIdle(startedAt));
  }

  Future<void> _incremental() async {
    final startedAt = _clock().toUtc();
    final since =
        _parse(await _settings.read(AppSettings.indexLastIncrementalAt)) ??
        await _lastFullScan();
    if (since == null) {
      await _fullScan(_allowedKinds(), isFirstScan: true);
      return;
    }
    final generation = await _settings.read(AppSettings.indexGeneration);
    final query = FileQuery(
      kinds: _allowedKinds(),
      modifiedAfter: since.subtract(incrementalOverlap),
    );
    var found = 0;
    await for (final page in _source.scan(query: query)) {
      await _dao.upsertBatch(page, generation, now: _clock());
      found += page.length;
      _emit(IndexScanning(found: found, isFirstScan: false));
    }
    await _settings.write(
      AppSettings.indexLastIncrementalAt,
      startedAt.toIso8601String(),
    );
    _emit(IndexIdle(startedAt));
  }

  // ---- helpers ----

  /// Runs [job] after every earlier job; failures go to [status].
  Future<void> _serial(Future<void> Function() job) {
    final next = _tail.then((_) async {
      try {
        await job();
      } on Object catch (e, st) {
        _emit(IndexFailed(e, st));
      }
    });
    return _tail = next;
  }

  /// Without All files access only media is scanned, so non-media rows are
  /// never deleted just because access is off.
  Set<FileKind> _allowedKinds() =>
      _canSeeAllFiles() ? FileKind.values.toSet() : mediaKinds;

  Future<DateTime?> _lastFullScan() async =>
      _parse(await _settings.read(AppSettings.indexLastFullScanAt));

  static DateTime? _parse(String iso) =>
      iso.isEmpty ? null : DateTime.tryParse(iso);

  void _emit(IndexStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }
}
