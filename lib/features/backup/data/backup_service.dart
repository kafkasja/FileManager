import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/backup_settings_policy.dart';
import 'package:kfm/features/backup/domain/file_matcher.dart';
import 'package:kfm/features/backup/domain/import_plan.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:path/path.dart' as p;

/// Export, import plan/apply, pre-import snapshot and "Undo last import"
/// (TASK-X6). Writes go through the write queue; an import is one
/// transaction.
class BackupService {
  new(
    this._db,
    this._queue, {
    required this._snapshotDir,
    this._clock = DateTime.now,
  });

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final Future<Directory> Function() _snapshotDir;
  final DateTime Function() _clock;

  static const _keepSnapshots = 3;
  static const _undoMarker = 'undo-target';
  static const _chunk = 500;

  // ---- Export ------------------------------------------------------------

  /// The backup of this device's tags, presets, file tags, favorites,
  /// reviewed labels and allow-listed settings.
  Future<BackupData> collect() async {
    final tags = await _db.select(_db.tags).get();
    final presets = await _db.select(_db.presets).get();
    final settings = await (_db.select(
      _db.settings,
    )..where((s) => s.key.isIn(backupSettingsByName.keys))).get();
    final fileTags = await _db.select(_db.fileTags).get();
    final favorites = await _db.select(_db.favorites).get();
    final reviews = await _db.select(_db.reviewedLabels).get();

    final presetIds = {0, for (final p in presets) p.id};
    final tagIds = {for (final t in tags) t.id};
    final tagsByFile = <String, List<int>>{};
    for (final ft in fileTags) {
      if (tagIds.contains(ft.tagId)) {
        (tagsByFile[ft.fileId] ??= []).add(ft.tagId);
      }
    }
    final favoriteIds = {for (final f in favorites) f.fileId};
    // Newest label per file and preset is what counts (P7).
    final newest = <String, Map<int, ReviewedLabelRow>>{};
    for (final r in reviews) {
      if (!presetIds.contains(r.presetKey)) continue;
      final perFile = newest[r.fileId] ??= {};
      final prev = perFile[r.presetKey];
      if (prev == null || r.reviewedAt.isAfter(prev.reviewedAt)) {
        perFile[r.presetKey] = r;
      }
    }
    final ids = {...tagsByFile.keys, ...favoriteIds, ...newest.keys}.toList();
    final rows = <String, MediaIndexRow>{};
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, (i + _chunk).clamp(0, ids.length));
      for (final r in await (_db.select(
        _db.mediaIndex,
      )..where((m) => m.id.isIn(part))).get()) {
        rows[r.id] = r;
      }
    }
    final files = <BackupFile>[];
    for (final id in ids) {
      final row = rows[id];
      // Files KFM hasn't indexed (remote, detached volume) can't be matched
      // elsewhere.
      if (row == null) continue;
      final (:vol, :rel) = splitVolume(row.folderPath);
      files.add(
        BackupFile(
          vol: vol,
          rel: rel,
          name: row.name,
          size: row.sizeBytes,
          takenAtMs: row.takenAtMs,
          tags: List.unmodifiable(
            (tagsByFile[id] ?? const <int>[]).toList()..sort(),
          ),
          favorite: favoriteIds.contains(id),
          reviewed: List.unmodifiable([
            for (final r in (newest[id] ?? const {}).values)
              BackupReview(
                preset: r.presetKey,
                action: r.actionType,
                detail: r.actionDetail,
                at: r.reviewedAt,
              ),
          ]),
        ),
      );
    }
    return BackupData(
      createdAt: _clock().toUtc(),
      appVersion: appVersion,
      dbSchema: _db.schemaVersion,
      settings: {for (final s in settings) s.key: _jsonOrNull(s.value)},
      tags: [
        for (final t in tags)
          BackupTag(key: t.id, name: t.name, color: t.color),
      ],
      presets: [
        for (final p in presets)
          if (_jsonMap(p.layoutJson) case final layout?)
            BackupPreset(
              key: p.id,
              name: p.name,
              layout: layout,
              filter: p.filterJson == null ? null : _jsonMap(p.filterJson!),
              includeReviewed: p.includeReviewed,
              sortOrder: p.sortOrder,
            ),
      ],
      files: files,
    );
  }

  /// [collect] encoded off the UI isolate.
  Future<String> exportJson() async {
    final data = await collect();
    return await _offThread(BackupCodec.encode, data);
  }

  /// `kfm-backup-YYYY-MM-DD.json`.
  String suggestedFileName() {
    final d = _clock();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'kfm-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  // ---- Import ------------------------------------------------------------

  /// Throws [BackupFormatException].
  Future<BackupData> decode(String text) =>
      _offThread(BackupCodec.decode, text);

  /// Matches the backup's files against `media_index` and builds the plan.
  /// Reads only; nothing changes until [apply].
  Future<ImportPlan> plan(
    BackupData data, {
    required String importedSuffix,
  }) async {
    final m = _db.mediaIndex;
    final indexRows =
        await (_db.selectOnly(m)..addColumns([
              m.id,
              m.folderPath,
              m.name,
              m.sizeBytes,
              m.takenAtMs,
              m.modifiedAtMs,
            ]))
            .map(
              (r) => IndexedFile(
                id: r.read(m.id)!,
                folderPath: r.read(m.folderPath)!,
                name: r.read(m.name)!,
                size: r.read(m.sizeBytes)!,
                takenAtMs: r.read(m.takenAtMs),
                modifiedAtMs: r.read(m.modifiedAtMs)!,
              ),
            )
            .get();
    final files = data.files;
    final matches = await _match(files, indexRows);
    final local = await _localState();
    return buildImportPlan(
      data,
      matches,
      local,
      importedSuffix: importedSuffix,
    );
  }

  Future<LocalBackupState> _localState() async {
    final tags = await _db.select(_db.tags).get();
    final presets = await _db.select(_db.presets).get();
    final settings = await (_db.select(
      _db.settings,
    )..where((s) => s.key.isIn(backupSettingsByName.keys))).get();
    final fileTags = await _db.select(_db.fileTags).get();
    final favorites = await _db.select(_db.favorites).get();
    final latest = <String, DateTime>{};
    for (final r in await _db.select(_db.reviewedLabels).get()) {
      final k = LocalBackupState.reviewKey(r.fileId, r.presetKey);
      final prev = latest[k];
      if (prev == null || r.reviewedAt.isAfter(prev)) latest[k] = r.reviewedAt;
    }
    return LocalBackupState(
      tags: [for (final t in tags) (id: t.id, name: t.name)],
      presets: [
        for (final p in presets)
          (
            id: p.id,
            name: p.name,
            layoutJson: p.layoutJson,
            filterJson: p.filterJson,
          ),
      ],
      settings: {for (final s in settings) s.key: s.value},
      fileTags: {
        for (final ft in fileTags)
          LocalBackupState.fileTagKey(ft.fileId, ft.tagId),
      },
      favorites: {for (final f in favorites) f.fileId},
      latestReviews: latest,
    );
  }

  /// Snapshots the current state, then applies [plan] in one transaction.
  /// Errors propagate; on failure nothing of the import is written.
  ///
  /// Returns the preset to switch to (0 = Basic) when the backup's active
  /// preset differs from the open swipe session's: the caller switches
  /// through `ActivePresetController` (that pauses the session and commits
  /// its queued deletes), so `presets.active` is not written here then.
  Future<int?> apply(ImportPlan plan, {required bool applySettings}) async {
    int? switchTo;
    await _queue.enqueue(null, () async {
      final snapshotName = await _writeSnapshot(await _snapshot());
      switchTo = await _db.transaction(() => _applyPlan(plan, applySettings));
      final dir = await _snapshotDir();
      await File(p.join(dir.path, _undoMarker)).writeAsString(snapshotName);
      await _prune(dir);
    });
    return switchTo;
  }

  /// The open local swipe session (sessions aren't part of a backup).
  Future<SessionRow?> _activeLocalSession() =>
      (_db.select(_db.sessions)..where(
            (s) =>
                s.sourceId.equals(kLocalSourceId) &
                s.isActive.equals(true) &
                s.endedAt.isNull(),
          ))
          .getSingleOrNull();

  /// Basic's layout lives on its open sessions too: keep them in step with
  /// `swipe.layout.current` ([layoutJson] = the session column format).
  Future<void> _setBasicSessionsLayout(String layoutJson) =>
      (_db.update(_db.sessions)..where(
            (s) =>
                s.sourceId.equals(kLocalSourceId) &
                s.presetId.isNull() &
                s.endedAt.isNull(),
          ))
          .write(
            SessionsCompanion(
              layout: Value(layoutJson),
              updatedAt: Value(_clock()),
            ),
          );

  /// The session column format of a raw `swipe.layout.current` row value
  /// ('' or missing = Basic); null when unreadable.
  static String? _sessionLayoutOf(String? raw) {
    final value = raw == null ? '' : _jsonOrNull(raw);
    if (value is! String) return null;
    if (value.isEmpty) return jsonEncode(SwipeLayout.basic.toJson());
    return _jsonMap(value) == null ? null : value;
  }

  Future<int?> _applyPlan(ImportPlan plan, bool applySettings) async {
    final now = _clock();
    final tagIds = <int, int>{};
    for (final t in plan.newTags) {
      final existing =
          await (_db.select(_db.tags)
                ..where((r) => r.name.lower().equals(t.name.toLowerCase())))
              .getSingleOrNull();
      tagIds[t.id] =
          existing?.id ??
          await _db
              .into(_db.tags)
              .insert(
                TagsCompanion.insert(
                  name: t.name,
                  color: t.color,
                  createdAt: now,
                ),
              );
    }
    int? tag(int id) => id >= 0 ? id : tagIds[id];

    final maxSort = _db.presets.sortOrder.max();
    final sortBase =
        ((await (_db.selectOnly(_db.presets)..addColumns([maxSort]))
                .map((r) => r.read(maxSort))
                .getSingle()) ??
            -1) +
        1;
    final presetIds = <int, int>{};
    final ordered = [...plan.newPresets]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final (i, pr) in ordered.indexed) {
      presetIds[pr.id] = await _db
          .into(_db.presets)
          .insert(
            PresetsCompanion.insert(
              name: pr.name,
              layoutJson: jsonEncode(remapLayoutTags(pr.layout, tag).toJson()),
              filterJson: Value(
                pr.filter == null
                    ? null
                    : jsonEncode(remapFilterTags(pr.filter!, tag).toJson()),
              ),
              includeReviewed: Value(pr.includeReviewed),
              sortOrder: sortBase + i,
              createdAt: now,
            ),
          );
    }
    int? preset(int id) => id >= 0 ? id : presetIds[id];

    await _db.batch((b) {
      b
        ..insertAll(_db.fileTags, [
          for (final ft in plan.fileTagsToAdd)
            if (tag(ft.tagId) case final tagId?)
              FileTagsCompanion.insert(
                fileId: ft.fileId,
                tagId: tagId,
                addedAt: now,
              ),
        ], mode: InsertMode.insertOrIgnore)
        ..insertAll(_db.favorites, [
          for (final id in plan.favoritesToAdd)
            FavoritesCompanion.insert(fileId: id, addedAt: now),
        ], mode: InsertMode.insertOrIgnore);
    });

    final minId = _db.reviewedLabels.actionId.min();
    final lowest =
        await (_db.selectOnly(
          _db.reviewedLabels,
        )..addColumns([minId])).map((r) => r.read(minId)).getSingle() ??
        0;
    // Negative ids never collide with session_actions ids (P7 rows).
    var nextId = (lowest < 0 ? lowest : 0) - 1;
    await _db.batch((b) {
      b.insertAll(_db.reviewedLabels, [
        for (final r in plan.reviewedToAdd)
          if (preset(r.presetId) case final presetKey?)
            ReviewedLabelsCompanion.insert(
              actionId: Value(nextId--),
              fileId: r.fileId,
              presetKey: presetKey,
              actionType: r.action,
              actionDetail: Value(r.detail),
              reviewedAt: r.at,
              fileModifiedAtMs: r.fileModifiedAtMs,
            ),
      ]);
    });

    if (!applySettings) return null;
    final session = await _activeLocalSession();
    int? switchTo;
    for (final s in plan.settingChanges) {
      final String raw;
      if (s.layout case final layout?) {
        raw = jsonEncode(jsonEncode(remapLayoutTags(layout, tag).toJson()));
      } else if (s.presetId case final id?) {
        final target = preset(id) ?? 0;
        if (session != null) {
          // Switching needs the session machinery: the caller does it.
          if (target != (session.presetId ?? 0)) switchTo = target;
          continue;
        }
        raw = jsonEncode(target);
      } else {
        raw = s.raw!;
      }
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(SettingRow(key: s.name, value: raw));
      if (s.name == AppSettings.swipeLayoutCurrent.name) {
        if (_sessionLayoutOf(raw) case final layoutJson?) {
          await _setBasicSessionsLayout(layoutJson);
        }
      }
    }
    return switchTo;
  }

  // ---- Snapshot + undo ---------------------------------------------------

  /// True while the last import can be undone.
  Future<bool> canUndo() async => (await _undoTarget()) != null;

  /// Restores the state from before the last import (everything changed in
  /// these tables since is lost too) and forgets that import.
  ///
  /// Like [apply], returns the preset to switch to (0 = Basic) when the
  /// restored active preset differs from the open swipe session's (see
  /// [undoPresetTarget]: callers switch first). `presets.active` becomes
  /// the restored preset; paused sessions of removed presets are closed.
  Future<int?> undoLastImport() async {
    int? switchTo;
    await _queue.enqueue(null, () async {
      switchTo = await _undo();
    });
    return switchTo;
  }

  /// The preset an undo returns to: the pre-import active preset when the
  /// snapshot has it, else Basic (0); `exists` = it exists right now (an
  /// imported preset never does; one deleted since the import comes back
  /// with the undo). Null when there is nothing to undo.
  ///
  /// The caller switches there before [undoLastImport] (that switch can be
  /// blocked by queued deletes, and then nothing is undone).
  Future<({int presetId, bool exists})?> undoPresetTarget() async {
    await _queue.flush();
    final target = await _undoTarget();
    if (target == null) return null;
    final id = _restoredPreset(await _readSnapshot(target));
    final exists =
        id == 0 ||
        await (_db.select(
              _db.presets,
            )..where((p) => p.id.equals(id))).getSingleOrNull() !=
            null;
    return (presetId: id, exists: exists);
  }

  static Future<_Snapshot> _readSnapshot(File file) async =>
      _Snapshot.fromJson(switch (jsonDecode(await file.readAsString())) {
        final Map<String, Object?> j => j,
        _ => throw const FormatException('bad snapshot'),
      });

  /// The snapshot's `presets.active` when that preset is in the snapshot
  /// (a snapshot taken while the setting pointed at a deleted preset must
  /// not bring that id back), else 0.
  static int _restoredPreset(_Snapshot snap) {
    final row = snap.settings
        .where((r) => r.key == AppSettings.activePresetId.name)
        .firstOrNull;
    final id = switch (row == null ? 0 : _jsonOrNull(row.value)) {
      final int id => id,
      _ => 0,
    };
    return snap.presets.any((p) => p.id == id) ? id : 0;
  }

  Future<int?> _undo() async {
    final target = await _undoTarget();
    if (target == null) throw StateError('no import to undo');
    final snap = await _readSnapshot(target);
    final active = AppSettings.activePresetId.name;
    final layoutKey = AppSettings.swipeLayoutCurrent.name;
    final restored = _restoredPreset(snap);
    final keptPresets = {for (final p in snap.presets) p.id};
    int? switchTo;
    await _db.transaction(() async {
      final session = await _activeLocalSession();
      final open = session == null ? null : session.presetId ?? 0;
      if (open != null && restored != open) switchTo = restored;
      // The setting never names a preset the undo removes. An open session
      // on another preset is the caller's to switch (normally it already
      // did: then open == restored).
      final hadRow = snap.settings.any((r) => r.key == active);
      final settings = [
        for (final r in snap.settings)
          if (r.key != active) r,
        if (hadRow || open != null)
          SettingRow(key: active, value: jsonEncode(restored)),
      ];
      // Paused sessions of presets the undo removes would come back on a
      // later switch to that id: close them (paused sessions never hold
      // queued deletes, like PresetRepository.delete).
      final now = _clock();
      await (_db.update(_db.sessions)..where(
            (s) =>
                s.sourceId.equals(kLocalSourceId) &
                s.isActive.equals(false) &
                s.endedAt.isNull() &
                s.presetId.isNotNull() &
                s.presetId.isNotIn(keptPresets),
          ))
          .write(SessionsCompanion(endedAt: Value(now), updatedAt: Value(now)));
      await _db.delete(_db.fileTags).go();
      await _db.delete(_db.favorites).go();
      await _db.delete(_db.reviewedLabels).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.presets).go();
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.isIn(backupSettingsByName.keys))).go();
      await _db.batch((b) {
        b
          ..insertAll(_db.tags, snap.tags)
          ..insertAll(_db.presets, snap.presets)
          ..insertAll(_db.fileTags, snap.fileTags)
          ..insertAll(_db.favorites, snap.favorites)
          ..insertAll(_db.reviewedLabels, snap.reviewed)
          ..insertAll(_db.settings, settings);
      });
      final layoutRow = snap.settings
          .where((r) => r.key == layoutKey)
          .firstOrNull;
      if (_sessionLayoutOf(layoutRow?.value) case final layoutJson?) {
        await _setBasicSessionsLayout(layoutJson);
      }
    });
    await File(p.join((await _snapshotDir()).path, _undoMarker)).delete();
    return switchTo;
  }

  Future<File?> _undoTarget() async {
    final dir = await _snapshotDir();
    final marker = File(p.join(dir.path, _undoMarker));
    if (!marker.existsSync()) return null;
    final name = (await marker.readAsString()).trim();
    if (name.isEmpty || p.basename(name) != name) return null;
    final file = File(p.join(dir.path, name));
    return file.existsSync() ? file : null;
  }

  Future<_Snapshot> _snapshot() async => _Snapshot(
    tags: await _db.select(_db.tags).get(),
    presets: await _db.select(_db.presets).get(),
    fileTags: await _db.select(_db.fileTags).get(),
    favorites: await _db.select(_db.favorites).get(),
    reviewed: await _db.select(_db.reviewedLabels).get(),
    settings: await (_db.select(
      _db.settings,
    )..where((s) => s.key.isIn(backupSettingsByName.keys))).get(),
  );

  Future<String> _writeSnapshot(_Snapshot s) async {
    final dir = await _snapshotDir();
    await dir.create(recursive: true);
    final name = 'pre-import-${_clock().toUtc().millisecondsSinceEpoch}.json';
    final json = s.toJson();
    final text = await _offThread(jsonEncode, json);
    await File(p.join(dir.path, name)).writeAsString(text, flush: true);
    return name;
  }

  Future<void> _prune(Directory dir) async {
    final snaps =
        dir
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  RegExp(r'^pre-import-\d+\.json$')
                      .hasMatch(p.basename(f.path)),
            )
            .toList()
          ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final old in snaps.skip(_keepSnapshots)) {
      await old.delete();
    }
  }

  // Static, so the isolate closures capture only their arguments (never the
  // database these instance methods hold).
  static Future<R> _offThread<A, R>(R Function(A) fn, A arg) =>
      Isolate.run(() => fn(arg));

  static Future<List<IndexedFile?>> _match(
    List<BackupFile> files,
    List<IndexedFile> index,
  ) => Isolate.run(() => matchFiles(files, index));

  static Object? _jsonOrNull(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?>? _jsonMap(String raw) =>
      switch (_jsonOrNull(raw)) {
        final Map<String, Object?> m => m,
        _ => null,
      };
}

/// Raw rows of the tables an import touches, with local ids.
class _Snapshot {
  new({
    required this.tags,
    required this.presets,
    required this.fileTags,
    required this.favorites,
    required this.reviewed,
    required this.settings,
  });

  factory fromJson(Map<String, Object?> j) {
    if (j['kind'] != 'kfm-pre-import' || j['v'] != 1) {
      throw const FormatException('not a pre-import snapshot');
    }
    List<T> rows<T>(String key, T Function(Map<String, Object?>) f) =>
        switch (j[key]) {
          final List<Object?> l => [
            for (final e in l)
              if (e is Map<String, Object?>)
                f(e)
              else
                throw FormatException('bad $key row'),
          ],
          _ => throw FormatException('missing $key'),
        };
    return _Snapshot(
      tags: rows('tags', TagRow.fromJson),
      presets: rows('presets', PresetRow.fromJson),
      fileTags: rows('fileTags', FileTagRow.fromJson),
      favorites: rows('favorites', FavoriteRow.fromJson),
      reviewed: rows('reviewed', ReviewedLabelRow.fromJson),
      settings: rows('settings', SettingRow.fromJson),
    );
  }

  final List<TagRow> tags;
  final List<PresetRow> presets;
  final List<FileTagRow> fileTags;
  final List<FavoriteRow> favorites;
  final List<ReviewedLabelRow> reviewed;
  final List<SettingRow> settings;

  Map<String, Object?> toJson() => {
    'kind': 'kfm-pre-import',
    'v': 1,
    'tags': [for (final r in tags) r.toJson()],
    'presets': [for (final r in presets) r.toJson()],
    'fileTags': [for (final r in fileTags) r.toJson()],
    'favorites': [for (final r in favorites) r.toJson()],
    'reviewed': [for (final r in reviewed) r.toJson()],
    'settings': [for (final r in settings) r.toJson()],
  };
}
