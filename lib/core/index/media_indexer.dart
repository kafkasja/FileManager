import 'dart:async';
import 'dart:io';

import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_store_counts.dart';
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
/// - Start reconciliation: after the incremental scan, per media kind,
///   MediaStore's count minus the index count must equal the difference
///   recorded after the last full scan of that kind; otherwise files were
///   deleted while the app wasn't running, and those kinds get a full scan.
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
    this._mediaStoreCounts,
    this._clock = DateTime.now,
    this.fileChangeDebounce = const Duration(seconds: 2),
    this.reconcileMinInterval = const Duration(seconds: 10),
    this._hasNoMediaMarker = _noMediaOnDisk,
  }) : _source = source {
    _idSub = source.idChanges.listen(
      (c) => unawaited(_serial(() => _dao.applyIdChange(c))),
    );
    _changeSub = changes.listen(onMediaChange);
  }

  static const fullScanInterval = Duration(hours: 24);

  /// N7: Files-table events are batched this long.
  final Duration fileChangeDebounce;

  /// N7: folder reconciles (deletes, unknown paths) run at most this often.
  final Duration reconcileMinInterval;

  /// Whether a folder holds a `.nomedia` file (its files are hidden).
  final Future<bool> Function(String folderPath) _hasNoMediaMarker;

  static Future<bool> _noMediaOnDisk(String folder) =>
      File('$folder/.nomedia').exists();
  static const changeDebounce = Duration(seconds: 2);

  /// Incremental scans look this far before the last scan (clock skew,
  /// 1-second MediaStore resolution).
  static const incrementalOverlap = Duration(minutes: 1);

  final MediaIndexDao _dao;
  final FileSource _source;
  final SettingsRepository _settings;
  final bool Function() _canSeeAllFiles;
  final DateTime Function() _clock;

  /// Null = no MediaStore (tests, desktop): no start reconciliation.
  final MediaStoreCounts? _mediaStoreCounts;

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

  // N7 Files-table events.
  Timer? _fileTimer;
  final List<FilesTableChange> _pendingFileEvents = [];
  final Set<String> _pendingReconcile = {};
  List<String> _reconcileRoots = const [];
  DateTime? _lastReconcile;

  Stream<IndexStatus> get status => _status.stream;
  IndexStatus get current => _current;

  /// App start / access granted: full scan the first time, otherwise an
  /// incremental scan, plus a full scan if the last one is >24 h old, or of
  /// the media kinds whose MediaStore count no longer matches the index.
  Future<void> start() => _serial(() async {
    final lastFull = await _lastFullScan();
    if (lastFull == null) {
      await _fullScan(_allowedKinds(), isFirstScan: true);
      await _markHiddenScanned();
      return;
    }
    await _incremental();
    final hiddenScanned = await _settings.read(AppSettings.indexHiddenScanned);
    if (_clock().difference(lastFull) > fullScanInterval ||
        (_canSeeAllFiles() && !hiddenScanned)) {
      // B1: hidden files aren't modified "since the last scan": a full scan
      // catches them up once.
      await _fullScan(_allowedKinds(), isFirstScan: false);
      await _markHiddenScanned();
      return;
    }
    await _markHiddenScanned();
    final stale = await _kindsOutOfSync();
    if (stale.isNotEmpty) await _fullScan(stale, isFirstScan: false);
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

  /// N7 live sync: a change from the Files-table observer (non-media files
  /// MediaStore knows about, e.g. a downloaded PDF). Media are ignored
  /// (photo_manager's observer covers them), and so is a change whose id is
  /// an indexed `ms:` file (this device's own trash/delete commits).
  /// - Insert/update with a path: stat'ed and upserted (no walk), `hidden`
  ///   computed like the walker (dot segments, `.nomedia` above it). A path
  ///   that is gone again refreshes only its own folder (not recursive).
  /// - A delete, or a change without a path (pending rows are hidden on
  ///   Android 11+, so "not found" is no delete): reconciles
  ///   [reconcileRoots] (shared folders, never a whole volume; empty = the
  ///   next full scan catches it) with [refreshFolder].
  ///
  /// Batched for [fileChangeDebounce]; reconciles at most every
  /// [reconcileMinInterval].
  void onFileChange(
    FilesTableChange change, {
    List<String> reconcileRoots = const [],
  }) {
    if (change.isMedia) return;
    _reconcileRoots = reconcileRoots;
    _pendingFileEvents.add(change);
    _scheduleFileChanges(fileChangeDebounce);
  }

  void _scheduleFileChanges(Duration after) {
    _fileTimer?.cancel();
    _fileTimer = Timer(after, () => unawaited(_applyFileChanges()));
  }

  /// N7: re-scans [rootPath] (media and, with All files access, the walk
  /// below it) under a new generation, then removes the rows below it that
  /// the scan didn't see. Never the whole volume: callers pass shared
  /// folders. Doesn't count as a full scan.
  Future<void> refreshFolder(String rootPath, {bool recursive = true}) =>
      _serial(() => _refreshFolder(rootPath, recursive: recursive));

  Future<void> dispose() async {
    _fileTimer?.cancel();
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

  Future<void> _applyFileChanges() => _serial(() async {
    final events = List.of(_pendingFileEvents);
    _pendingFileEvents.clear();
    final canSeeAll = _canSeeAllFiles();
    final paths = <String>{};
    final folders = <String>{};
    for (final e in events) {
      if (e.id case final id? when await _dao.byId('ms:$id') != null) {
        continue; // An indexed media row: photo_manager's events cover it.
      }
      final path = e.path;
      if (e.type != 'delete' && path != null) {
        if (canSeeAll) paths.add(path);
      } else {
        _pendingReconcile.addAll(_reconcileRoots);
      }
    }
    final found = <FileRef>[];
    for (final path in paths) {
      final ref = await _source.statPath(path);
      if (ref == null) {
        // Gone again, or not readable: refresh just its folder.
        final slash = path.lastIndexOf('/');
        if (slash > 0) folders.add(path.substring(0, slash));
        continue;
      }
      if (mediaKinds.contains(ref.kind)) continue;
      found.add(ref.copyWith(hidden: ref.hidden || await _isHidden(ref)));
    }
    if (found.isNotEmpty) {
      final generation = await _settings.read(AppSettings.indexGeneration);
      await _dao.upsertBatch(found, generation, now: _clock());
    }
    for (final folder in folders) {
      await _refreshFolder(folder, recursive: false);
    }
    if (_pendingReconcile.isEmpty) return;
    final last = _lastReconcile;
    final now = _clock();
    if (last != null && now.difference(last) < reconcileMinInterval) {
      _scheduleFileChanges(reconcileMinInterval - now.difference(last));
      return;
    }
    final roots = _outermost(_pendingReconcile);
    _pendingReconcile.clear();
    _lastReconcile = now;
    for (final root in roots) {
      await _refreshFolder(root);
    }
  });

  Future<void> _refreshFolder(String rootPath, {bool recursive = true}) async {
    final kinds = _allowedKinds();
    final generation = await _settings.read(AppSettings.indexGeneration) + 1;
    await _settings.write(AppSettings.indexGeneration, generation);
    final query = FileQuery(
      kinds: kinds,
      rootPath: rootPath,
      recursive: recursive,
      includeHidden: _canSeeAllFiles(),
    );
    await for (final page in _source.scan(query: query)) {
      await _dao.upsertBatch(page, generation, now: _clock());
    }
    await _dao.deleteOlderThanGeneration(
      generation,
      kinds: kinds,
      rootPath: rootPath,
      recursive: recursive,
    );
  }

  /// Like the walker: a dot-file, a dot folder on the way, or a `.nomedia`
  /// in its folder or any folder above it (up to the volume root).
  Future<bool> _isHidden(FileRef f) async {
    if (f.name.startsWith('.') || isInHiddenFolder(f.path)) return true;
    final stop = _volumeRoot.firstMatch(f.folderPath)?.group(0) ?? '/';
    var folder = f.folderPath;
    while (folder.length >= stop.length && folder.isNotEmpty) {
      if (await _hasNoMediaMarker(folder)) return true;
      final slash = folder.lastIndexOf('/');
      if (slash <= 0) break;
      folder = folder.substring(0, slash);
    }
    return false;
  }

  static final _volumeRoot = RegExp(r'^/storage/(emulated/\d+|[^/]+)');

  /// [roots] without the ones inside another of them.
  static List<String> _outermost(Set<String> roots) => [
    for (final r in roots)
      if (!roots.any(
        (o) => o != r && r.toLowerCase().startsWith('${o.toLowerCase()}/'),
      ))
        r,
  ];

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
    final query = FileQuery(kinds: kinds, includeHidden: _canSeeAllFiles());
    await for (final page in _source.scan(query: query)) {
      await _dao.upsertBatch(page, generation, now: _clock());
      found += page.length;
      _emit(IndexScanning(found: found, isFirstScan: isFirstScan));
    }
    await _dao.deleteOlderThanGeneration(generation, kinds: kinds);
    // Only a scan of every allowed kind counts as "the" full scan: a
    // reconciliation or live-change scan of some media kinds must not push
    // back the 24 h scan of the rest (non-media walker files), nor move the
    // incremental cursor past changes in kinds it didn't look at.
    if (kinds.containsAll(_allowedKinds())) {
      final stamp = startedAt.toIso8601String();
      await _settings.write(AppSettings.indexLastFullScanAt, stamp);
      await _settings.write(AppSettings.indexLastIncrementalAt, stamp);
    }
    await _recordCountOffsets(kinds.intersection(mediaKinds));
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
      includeHidden: _canSeeAllFiles(),
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

  // ---- start reconciliation ----

  /// Media kinds whose MediaStore − index difference changed since their
  /// last full scan (or was never recorded).
  Future<Set<FileKind>> _kindsOutOfSync() async {
    final counter = _mediaStoreCounts;
    if (counter == null) return const {};
    final store = await counter();
    if (store == null) return const {};
    final indexed = await _dao.countByKind(mediaKinds);
    final offsets = await _settings.read(indexMediaCountOffsets);
    return {
      for (final k in mediaKinds)
        if (offsets[k.name] case final offset
            when offset == null ||
                (store[k] ?? 0) - (indexed[k] ?? 0) != offset)
          k,
    };
  }

  /// After a full scan of [kinds]: remember MediaStore − index per kind. A
  /// file added between the scan and this count skews it by one, which only
  /// costs one extra full scan on a later start.
  Future<void> _recordCountOffsets(Set<FileKind> kinds) async {
    final counter = _mediaStoreCounts;
    if (counter == null || kinds.isEmpty) return;
    final store = await counter();
    if (store == null) return;
    final indexed = await _dao.countByKind(kinds);
    final offsets = {
      ...await _settings.read(indexMediaCountOffsets),
      for (final k in kinds) k.name: (store[k] ?? 0) - (indexed[k] ?? 0),
    };
    await _settings.write(indexMediaCountOffsets, offsets);
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

  /// Losing All files access resets it, so regaining it catches up again.
  Future<void> _markHiddenScanned() =>
      _settings.write(AppSettings.indexHiddenScanned, _canSeeAllFiles());

  Future<DateTime?> _lastFullScan() async =>
      _parse(await _settings.read(AppSettings.indexLastFullScanAt));

  static DateTime? _parse(String iso) =>
      iso.isEmpty ? null : DateTime.tryParse(iso);

  void _emit(IndexStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }
}
