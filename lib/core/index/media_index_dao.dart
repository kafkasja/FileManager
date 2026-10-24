import 'dart:async';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/index_query.dart';

part 'media_index_dao.g.dart';

/// Indexed, keyset-paged access to `media_index` (TASK-F5). Never OFFSET:
/// pages near the end of 50k rows stay as fast as the first.
@DriftAccessor(tables: [MediaIndex])
class MediaIndexDao extends DatabaseAccessor<AppDatabase>
    with _$MediaIndexDaoMixin {
  new(super.attachedDatabase);

  static const changeDebounce = Duration(milliseconds: 300);

  Future<IndexPage> page(
    IndexQuery q, {
    IndexCursor? after,
    int limit = 200,
  }) async {
    final sortCol = _sortColumn(q.sort.field);
    final desc = q.sort.descending;
    final select = this.select(mediaIndex)
      ..where((t) {
        var where = _applyQuery(t, q);
        if (after != null) where = where & _beyond(t, q.sort, after);
        return where;
      })
      ..orderBy([
        (_) => OrderingTerm(
          expression: sortCol,
          mode: desc ? OrderingMode.desc : OrderingMode.asc,
        ),
        (t) => OrderingTerm(
          expression: t.id,
          mode: desc ? OrderingMode.desc : OrderingMode.asc,
        ),
      ])
      ..limit(limit);
    final rows = await select.get();
    final next = rows.length < limit
        ? null
        : IndexCursor(_sortValueOf(rows.last, q.sort.field), rows.last.id);
    return IndexPage(List.unmodifiable(rows.map(_toRef)), next);
  }

  Future<int> count(IndexQuery q) => _countQuery(q).getSingle();

  Stream<int> watchCount(IndexQuery q) => _countQuery(q).watchSingle();

  Future<int> totalBytes(IndexQuery q) {
    final sum = mediaIndex.sizeBytes.sum();
    final query = selectOnly(mediaIndex)
      ..addColumns([sum])
      ..where(_applyQuery(mediaIndex, q));
    return query.getSingle().then((row) => row.read(sum) ?? 0);
  }

  /// Emits (debounced) after any change to the index. Views reload their
  /// visible pages. Not filtered per query: a cheap reload beats tracking.
  Stream<void> watchChanges() {
    final updates = attachedDatabase.tableUpdates(
      TableUpdateQuery.onTable(mediaIndex),
    );
    late StreamController<void> controller;
    StreamSubscription<Set<TableUpdate>>? sub;
    Timer? timer;
    controller = StreamController<void>(
      onListen: () => sub = updates.listen((_) {
        timer?.cancel();
        timer = Timer(changeDebounce, () => controller.add(null));
      }, onError: controller.addError),
      onCancel: () async {
        timer?.cancel();
        await sub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<FileRef?> byId(String id) async {
    final row = await (select(
      mediaIndex,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toRef(row);
  }

  /// Rows for [ids] in the same order; missing ids are skipped.
  Future<List<FileRef>> byIds(List<String> ids) async {
    final found = <String, FileRef>{};
    // SQLite limits bound variables; chunk large lists.
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final rows = await (select(
        mediaIndex,
      )..where((t) => t.id.isIn(chunk))).get();
      for (final r in rows) {
        found[r.id] = _toRef(r);
      }
    }
    return [for (final id in ids) ?found[id]];
  }

  /// Inserts or updates one scan page in a single transaction.
  Future<void> upsertBatch(
    List<FileRef> files,
    int generation, {
    DateTime? now,
  }) {
    final indexedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return batch((b) {
      b.insertAllOnConflictUpdate(mediaIndex, [
        for (final f in files) _toCompanion(f, generation, indexedAt),
      ]);
    });
  }

  /// Removes rows of [kinds] (under [rootPath], if given) that the full scan
  /// [generation] didn't see. Returns the number removed.
  Future<int> deleteOlderThanGeneration(
    int generation, {
    required Set<FileKind> kinds,
    String? rootPath,
  }) =>
      (delete(mediaIndex)..where((t) {
            var where =
                t.scanGeneration.isSmallerThanValue(generation) &
                t.kind.isIn([for (final k in kinds) k.index]);
            if (rootPath != null) {
              where =
                  where &
                  (t.folderPath.equals(rootPath) |
                      t.folderPath.like(
                        '${_escapeLike(rootPath)}/%',
                        escapeChar: r'\',
                      ));
            }
            return where;
          }))
          .go();

  Future<void> deleteIds(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      await (delete(mediaIndex)..where((t) => t.id.isIn(chunk))).go();
    }
  }

  /// Re-keys a row after FileSource reported a new id (move/rename).
  Future<void> applyIdChange(FileIdChange change) => transaction(() async {
    final old = await (select(
      mediaIndex,
    )..where((t) => t.id.equals(change.oldId))).getSingleOrNull();
    await (delete(mediaIndex)..where((t) => t.id.equals(change.oldId))).go();
    await into(mediaIndex).insertOnConflictUpdate(
      _toCompanion(
        change.newRef,
        old?.scanGeneration ?? 0,
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
  });

  // ---- helpers ----

  Selectable<int> _countQuery(IndexQuery q) {
    final count = mediaIndex.id.count();
    return (selectOnly(mediaIndex)
          ..addColumns([count])
          ..where(_applyQuery(mediaIndex, q)))
        .map((r) => r.read(count) ?? 0);
  }

  /// The one place query filters become SQL (P5 adds its joins here).
  Expression<bool> _applyQuery($MediaIndexTable t, IndexQuery q) {
    Expression<bool> where = const Constant(true);
    if (q.kinds.isNotEmpty) {
      where = where & t.kind.isIn([for (final k in q.kinds) k.index]);
    }
    if (q.folderPath case final folder?) {
      where =
          where &
          (q.includeSubfolders
              ? t.folderPath.equals(folder) |
                    t.folderPath.like(
                      '${_escapeLike(folder)}/%',
                      escapeChar: r'\',
                    )
              : t.folderPath.equals(folder));
    }
    if (q.minSizeBytes case final min?) {
      where = where & t.sizeBytes.isBiggerOrEqualValue(min);
    }
    if (q.maxSizeBytes case final max?) {
      where = where & t.sizeBytes.isSmallerOrEqualValue(max);
    }
    if (q.from case final from?) {
      where =
          where &
          t.sortDateMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch);
    }
    if (q.to case final to?) {
      where =
          where & t.sortDateMs.isSmallerThanValue(to.millisecondsSinceEpoch);
    }
    if (q.nameContains case final name? when name.isNotEmpty) {
      where =
          where &
          t.nameLower.like(
            '%${_escapeLike(name.toLowerCase())}%',
            escapeChar: r'\',
          );
    }
    if (q.mimePrefix case final prefix?) {
      where =
          where & t.mimeType.like('${_escapeLike(prefix)}%', escapeChar: r'\');
    }
    return where;
  }

  Expression<Object> _sortColumn(FileSortField field) => switch (field) {
    FileSortField.date => mediaIndex.sortDateMs,
    FileSortField.size => mediaIndex.sizeBytes,
    FileSortField.name => mediaIndex.nameLower,
  };

  static Object _sortValueOf(MediaIndexRow r, FileSortField field) =>
      switch (field) {
        FileSortField.date => r.sortDateMs,
        FileSortField.size => r.sizeBytes,
        FileSortField.name => r.nameLower,
      };

  /// Rows strictly after [c] in (sortColumn, id) order.
  static Expression<bool> _beyond(
    $MediaIndexTable t,
    FileSort sort,
    IndexCursor c,
  ) {
    final desc = sort.descending;
    final idBeyond = desc
        ? t.id.isSmallerThanValue(c.id)
        : t.id.isBiggerThanValue(c.id);
    Expression<bool> intBeyond(GeneratedColumn<int> col) {
      final v = c.sortValue as int;
      return (desc ? col.isSmallerThanValue(v) : col.isBiggerThanValue(v)) |
          (col.equals(v) & idBeyond);
    }

    return switch (sort.field) {
      FileSortField.date => intBeyond(t.sortDateMs),
      FileSortField.size => intBeyond(t.sizeBytes),
      FileSortField.name => () {
        final v = c.sortValue as String;
        return (desc
                ? t.nameLower.isSmallerThanValue(v)
                : t.nameLower.isBiggerThanValue(v)) |
            (t.nameLower.equals(v) & idBeyond);
      }(),
    };
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static MediaIndexCompanion _toCompanion(
    FileRef f,
    int generation,
    int indexedAtMs,
  ) => MediaIndexCompanion.insert(
    id: f.id,
    uri: f.uri,
    name: f.name,
    nameLower: f.name.toLowerCase(),
    mimeType: Value(f.mimeType),
    kind: f.kind,
    sizeBytes: f.sizeBytes,
    modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
    takenAtMs: Value(f.takenAt?.millisecondsSinceEpoch),
    sortDateMs: f.sortDate.millisecondsSinceEpoch,
    width: Value(f.width),
    height: Value(f.height),
    durationMs: Value(f.durationMs),
    folderPath: f.folderPath,
    origin: f.origin,
    indexedAtMs: indexedAtMs,
    scanGeneration: generation,
  );

  static FileRef _toRef(MediaIndexRow r) => FileRef(
    id: r.id,
    uri: r.uri,
    name: r.name,
    mimeType: r.mimeType,
    kind: r.kind,
    sizeBytes: r.sizeBytes,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      r.modifiedAtMs,
      isUtc: true,
    ),
    takenAt: r.takenAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r.takenAtMs!, isUtc: true),
    width: r.width,
    height: r.height,
    durationMs: r.durationMs,
    folderPath: r.folderPath,
    origin: r.origin,
  );
}
