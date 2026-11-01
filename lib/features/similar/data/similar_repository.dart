import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/blur_rule.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/similar/domain/grouping.dart';
import 'package:kfm/features/similar/domain/signals.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'similar_repository.g.dart';

/// A near-duplicate group as the Similar screen shows it.
@immutable
class SimilarGroup {
  const new({required this.id, required this.members});

  final int id;

  /// Shown members, best first.
  final List<FileRef> members;

  String get suggestedFileId => members.first.id;
}

/// Keyset position of [SimilarRepository.nextBatch] (newest first).
typedef SignalCursor = ({int sortDateMs, String id});

/// One row for [SimilarRepository.writeSignals].
@immutable
class SignalWrite {
  const new({
    required this.fileId,
    required this.status,
    required this.fileModifiedAtMs,
    this.dHash,
    this.blurScore,
  });

  final String fileId;
  final SignalStatus status;
  final int? dHash;
  final double? blurScore;
  final int fileModifiedAtMs;
}

/// One generated group for [SimilarRepository.replaceGroups].
typedef GroupDraft = ({List<String> members, int sortDateMs});

/// image_signals, similar_groups(+items) and similar_dismissed (TASK-C2).
/// Writes go through [DbWriteQueue] with `coalesceKey: null` (data rows).
class SimilarRepository {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;

  static const List<PendingDeleteStatus> _shownStatuses = [
    PendingDeleteStatus.queued,
    PendingDeleteStatus.committing,
  ];

  // ---------------------------------------------------------------- screen

  /// Groups newest first with their shown members (best first). A member is
  /// hidden while it has a queued/committing delete; groups with < 2 shown
  /// members or whose shown members are all dismissed are left out.
  Stream<List<SimilarGroup>> watchGroups() => _groupsQuery().watch().map(
    (rows) => [
      for (final g in _collect(rows))
        if (g.isVisible) SimilarGroup(id: g.id, members: g.shown),
    ],
  );

  /// Visible blurry images ([blurryPredicate]), newest first.
  Stream<List<FileRef>> watchBlurry({required int threshold, int limit = 500}) {
    final s = _db.imageSignals;
    final mi = _db.mediaIndex;
    final query = _db.select(s).join([innerJoin(mi, mi.id.equalsExp(s.fileId))])
      ..where(
        blurryPredicate(s, threshold) &
            mi.kind.equalsValue(FileKind.image) &
            mi.hidden.equals(false) &
            notExistsQuery(
              _db.select(_db.pendingDeletes)..where(
                (pd) =>
                    pd.fileId.equalsExp(s.fileId) &
                    pd.status.isInValues(_shownStatuses),
              ),
            ),
      )
      ..orderBy([OrderingTerm.desc(mi.sortDateMs), OrderingTerm.desc(mi.id)])
      ..limit(limit);
    return query.watch().map(
      (rows) => [for (final r in rows) MediaIndexDao.refOf(r.readTable(mi))],
    );
  }

  /// Marks [fileIds] as finished (their group hides until a new member
  /// joins). Completes when committed.
  Future<void> dismiss(List<String> fileIds) {
    if (fileIds.isEmpty) return Future.value();
    final now = DateTime.now().toUtc();
    return _queue.enqueue(
      null,
      () => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.similarDismissed, [
          for (final id in fileIds.toSet())
            SimilarDismissedCompanion.insert(fileId: id, dismissedAt: now),
        ]),
      ),
    );
  }

  Future<void> undismiss(List<String> fileIds) {
    if (fileIds.isEmpty) return Future.value();
    final ids = fileIds.toSet().toList();
    return _queue.enqueue(
      null,
      () => _db.transaction(() async {
        for (final chunk in _chunks(ids)) {
          await (_db.delete(
            _db.similarDismissed,
          )..where((d) => d.fileId.isIn(chunk))).go();
        }
      }),
    );
  }

  /// Swipe mode (§7): dismisses every visible group whose shown members are
  /// all in [actedIds] (the active session's acted files).
  Future<void> dismissFullySwiped(Set<String> actedIds) async {
    if (actedIds.isEmpty) return;
    final groups = _collect(await _groupsQuery().get());
    final ids = <String>[
      for (final g in groups)
        if (g.isVisible && g.shown.every((f) => actedIds.contains(f.id)))
          ...g.allIds,
    ];
    await dismiss(ids);
  }

  // ------------------------------------------------------------------- job

  /// Images that need (re)computing: no signal row, an older algorithm, or
  /// a changed file. `failed`/`unsupported` rows only match again when the
  /// file or algorithm changes. Newest first, keyset after [after].
  Future<List<FileRef>> nextBatch({
    required bool includeScreenshots,
    SignalCursor? after,
    int limit = 200,
  }) async {
    final mi = _db.mediaIndex;
    final query = _workQuery(includeScreenshots, countOnly: false)
      ..orderBy([OrderingTerm.desc(mi.sortDateMs), OrderingTerm.desc(mi.id)])
      ..limit(limit);
    if (after != null) {
      query.where(
        mi.sortDateMs.isSmallerThanValue(after.sortDateMs) |
            (mi.sortDateMs.equals(after.sortDateMs) &
                mi.id.isSmallerThanValue(after.id)),
      );
    }
    final rows = await query.get();
    return [for (final r in rows) MediaIndexDao.refOf(r.readTable(mi))];
  }

  /// How many images [nextBatch] would walk through in one run.
  Future<int> countPending({required bool includeScreenshots}) async {
    final count = _db.mediaIndex.id.count();
    final query = _workQuery(includeScreenshots, countOnly: true)
      ..addColumns([count]);
    final row = await query.getSingle();
    return row.read<int>(count) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, Object?> _workQuery(
    bool includeScreenshots, {
    required bool countOnly,
  }) {
    final mi = _db.mediaIndex;
    final s = _db.imageSignals;
    var where =
        mi.kind.equalsValue(FileKind.image) &
        mi.hidden.equals(false) &
        (s.fileId.isNull() |
            s.algoVersion.isSmallerThanValue(kSignalsAlgoVersion) |
            s.fileModifiedAtMs.equalsExp(mi.modifiedAtMs).not());
    if (!includeScreenshots) where = where & mi.screenshot.equals(false);
    final joins = [
      leftOuterJoin(s, s.fileId.equalsExp(mi.id), useColumns: false),
    ];
    final JoinedSelectStatement<HasResultSet, Object?> query = countOnly
        ? (_db.selectOnly(mi)..join(joins))
        : _db.select(mi).join(joins);
    return query..where(where);
  }

  Future<void> writeSignals(List<SignalWrite> rows) {
    if (rows.isEmpty) return Future.value();
    return _queue.enqueue(
      null,
      () => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.imageSignals, [
          for (final r in rows)
            ImageSignalsCompanion.insert(
              fileId: r.fileId,
              status: r.status,
              dHash: Value(r.dHash),
              blurScore: Value(r.blurScore),
              fileModifiedAtMs: r.fileModifiedAtMs,
              algoVersion: kSignalsAlgoVersion,
            ),
        ]),
      ),
    );
  }

  /// Rows whose file is no longer in media_index (committed deletes, files
  /// gone from the device).
  Future<void> deleteOrphans() => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      const notIndexed = 'file_id NOT IN (SELECT id FROM media_index)';
      await _db.customUpdate(
        'DELETE FROM image_signals WHERE $notIndexed',
        updates: {_db.imageSignals},
        updateKind: UpdateKind.delete,
      );
      await _db.customUpdate(
        'DELETE FROM similar_group_items WHERE $notIndexed',
        updates: {_db.similarGroupItems},
        updateKind: UpdateKind.delete,
      );
      await _db.customUpdate(
        'DELETE FROM similar_dismissed WHERE $notIndexed',
        updates: {_db.similarDismissed},
        updateKind: UpdateKind.delete,
      );
    }),
  );

  /// `ok` signals of visible images, oldest first (the grouping input).
  Future<List<SignalPoint>> groupingInput({
    required bool includeScreenshots,
  }) async {
    final mi = _db.mediaIndex;
    final s = _db.imageSignals;
    var where =
        s.status.equalsValue(SignalStatus.ok) &
        mi.kind.equalsValue(FileKind.image) &
        mi.hidden.equals(false);
    if (!includeScreenshots) where = where & mi.screenshot.equals(false);
    final query =
        _db.selectOnly(s).join([innerJoin(mi, mi.id.equalsExp(s.fileId))])
          ..addColumns([
            s.fileId,
            s.dHash,
            s.blurScore,
            mi.sortDateMs,
            mi.width,
            mi.height,
            mi.sizeBytes,
          ])
          ..where(where)
          ..orderBy([OrderingTerm.asc(mi.sortDateMs)]);
    final rows = await query.get();
    return [
      for (final r in rows)
        SignalPoint(
          fileId: r.read(s.fileId)!,
          sortDateMs: r.read(mi.sortDateMs)!,
          dHash: r.read(s.dHash)!,
          blurScore: r.read(s.blurScore)!,
          width: r.read(mi.width),
          height: r.read(mi.height),
          sizeBytes: r.read(mi.sizeBytes)!,
        ),
    ];
  }

  /// Replaces every generated group in one transaction. Completes when
  /// committed.
  Future<void> replaceGroups(List<GroupDraft> groups) {
    final now = DateTime.now().toUtc();
    return _queue.enqueue(
      null,
      () => _db.transaction(() async {
        await _db.delete(_db.similarGroupItems).go();
        await _db.delete(_db.similarGroups).go();
        for (final g in groups) {
          if (g.members.length < 2) continue;
          final id = await _db
              .into(_db.similarGroups)
              .insert(
                SimilarGroupsCompanion.insert(
                  suggestedFileId: g.members.first,
                  memberCount: g.members.length,
                  sortDateMs: g.sortDateMs,
                  createdAt: now,
                ),
              );
          await _db.batch(
            (b) => b.insertAll(_db.similarGroupItems, [
              for (final (i, f) in g.members.indexed)
                SimilarGroupItemsCompanion.insert(
                  groupId: id,
                  fileId: f,
                  position: i,
                ),
            ]),
          );
        }
      }),
    );
  }

  // --------------------------------------------------------------- helpers

  Selectable<QueryRow> _groupsQuery() => _db.customSelect(
    'SELECT gi.group_id AS g_group_id, gi.file_id AS g_file_id, '
    '(sd.file_id IS NOT NULL) AS g_dismissed, '
    'EXISTS (SELECT 1 FROM pending_deletes pd WHERE pd.file_id = gi.file_id '
    "AND pd.status IN ('queued', 'committing')) AS g_pending, "
    'mi.* '
    'FROM similar_groups g '
    'JOIN similar_group_items gi ON gi.group_id = g.id '
    'LEFT JOIN media_index mi ON mi.id = gi.file_id AND mi.hidden = 0 '
    'LEFT JOIN similar_dismissed sd ON sd.file_id = gi.file_id '
    'ORDER BY g.sort_date_ms DESC, g.id DESC, gi.position',
    readsFrom: {
      _db.similarGroups,
      _db.similarGroupItems,
      _db.mediaIndex,
      _db.similarDismissed,
      _db.pendingDeletes,
    },
  );

  List<_GroupRows> _collect(List<QueryRow> rows) {
    final groups = <_GroupRows>[];
    for (final row in rows) {
      final id = row.read<int>('g_group_id');
      if (groups.isEmpty || groups.last.id != id) groups.add(_GroupRows(id));
      final g = groups.last..allIds.add(row.read<String>('g_file_id'));
      final indexed = row.data['id'] != null;
      if (!indexed || row.read<bool>('g_pending')) continue;
      g.shown.add(MediaIndexDao.refOf(_db.mediaIndex.map(row.data)));
      if (!row.read<bool>('g_dismissed')) g.anyUndismissed = true;
    }
    return groups;
  }

  static Iterable<List<String>> _chunks(List<String> ids) sync* {
    for (var i = 0; i < ids.length; i += 500) {
      yield ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
    }
  }
}

class _GroupRows {
  new(this.id);

  final int id;
  final List<String> allIds = [];
  final List<FileRef> shown = [];
  bool anyUndismissed = false;

  bool get isVisible => shown.length >= 2 && anyUndismissed;
}

@Riverpod(keepAlive: true)
SimilarRepository similarRepository(Ref ref) => SimilarRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);
