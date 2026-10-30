import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/db/tables/selection_items_table.dart';
import 'package:kfm/core/files/file_query.dart';

part 'selection_dao.g.dart';

/// One selected file: id, insertion order, size (0 when not indexed).
typedef SelectedRow = ({String id, int seq, int sizeBytes});

/// The saved selection as loaded on start.
typedef StoredSelection = ({
  List<SelectedRow> rows,
  int totalBytes,
  bool hasSnapshot,
});

/// `selection_items` / `selection_snapshots` (TASK-B6). Callers run every
/// write through the DbWriteQueue (SelectionRepository).
@DriftAccessor(tables: [SelectionItems, SelectionSnapshots, MediaIndex])
class SelectionDao extends DatabaseAccessor<AppDatabase>
    with _$SelectionDaoMixin {
  new(super.attachedDatabase);

  static const _sizeJoin =
      'SELECT s.file_id AS id, s.seq AS seq, '
      'COALESCE(m.size_bytes, 0) AS size FROM ';

  /// Rows in `seq` order with their sizes.
  Future<StoredSelection> load() async {
    final rows = await _rows('selection_items');
    final snapshot = await customSelect(
      'SELECT EXISTS (SELECT 1 FROM selection_snapshots) AS has',
    ).getSingle();
    return (
      rows: rows,
      totalBytes: rows.fold(0, (sum, r) => sum + r.sizeBytes),
      hasSnapshot: snapshot.read<bool>('has'),
    );
  }

  /// Selected ids in `seq` order (actions, View selected).
  Future<List<String>> orderedIds() async {
    final rows = await (select(
      selectionItems,
    )..orderBy([(s) => OrderingTerm.asc(s.seq)])).get();
    return [for (final r in rows) r.fileId];
  }

  Future<void> add(List<({String id, int seq})> items, DateTime now) => batch((
    b,
  ) {
    b.insertAll(selectionItems, [
      for (final i in items)
        SelectionItemsCompanion.insert(fileId: i.id, seq: i.seq, addedAt: now),
    ], mode: InsertMode.insertOrIgnore);
  });

  Future<void> remove(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      await (delete(selectionItems)..where((s) => s.fileId.isIn(chunk))).go();
    }
  }

  /// Adds every row of [where] in [sort] order after the current last `seq`. Returns the
  /// rows actually added (already selected ones keep their place).
  Future<List<SelectedRow>> selectAll(
    Expression<bool> where,
    FileSort sort,
    DateTime now,
  ) => transaction(() async {
    final max = selectionItems.seq.max();
    final base =
        (await (selectOnly(
          selectionItems,
        )..addColumns([max])).getSingle()).read(max) ??
        0;
    final dir = sort.descending ? 'DESC' : 'ASC';
    final col = switch (sort.field) {
      FileSortField.date => 'sort_date_ms',
      FileSortField.size => 'size_bytes',
      FileSortField.name => 'name_lower',
    };
    final rank = CustomExpression<int>(
      '$base + ROW_NUMBER() OVER '
      '(ORDER BY media_index.$col $dir, media_index.id $dir)',
    );
    final at = Variable<DateTime>(now);
    final source = selectOnly(mediaIndex)
      ..addColumns([mediaIndex.id, rank, at])
      ..where(where);
    await into(selectionItems).insertFromSelect(
      source,
      columns: {
        selectionItems.fileId: mediaIndex.id,
        selectionItems.seq: rank,
        selectionItems.addedAt: at,
      },
      mode: InsertMode.insertOrIgnore,
    );
    return await _rows('selection_items', afterSeq: base);
  });

  /// Moves the selection into the snapshot (replacing the old one). An
  /// empty selection does nothing and keeps the old snapshot. Returns how
  /// many were cleared.
  Future<int> clearAll() => transaction(() async {
    final count = selectionItems.fileId.count();
    final n =
        (await (selectOnly(
          selectionItems,
        )..addColumns([count])).getSingle()).read(count) ??
        0;
    if (n == 0) return 0;
    await customStatement('DELETE FROM selection_snapshots');
    await customStatement(
      'INSERT INTO selection_snapshots (file_id, seq, added_at) '
      'SELECT file_id, seq, added_at FROM selection_items',
    );
    await customStatement('DELETE FROM selection_items');
    return n;
  });

  /// Merges the snapshot back (old `seq`s) and drops it. Returns the rows
  /// that were not selected already.
  Future<List<SelectedRow>> restoreSnapshot() => transaction(() async {
    final restored = await customSelect(
      '$_sizeJoin selection_snapshots s '
      'LEFT JOIN media_index m ON m.id = s.file_id '
      'WHERE s.file_id NOT IN (SELECT file_id FROM selection_items) '
      'ORDER BY s.seq',
      readsFrom: {selectionSnapshots, selectionItems, mediaIndex},
    ).get();
    // A file selected again since the clear goes back to its old place.
    await customStatement(
      'INSERT INTO selection_items (file_id, seq, added_at) '
      'SELECT file_id, seq, added_at FROM selection_snapshots WHERE true '
      'ON CONFLICT (file_id) DO UPDATE SET seq = MIN(seq, excluded.seq)',
    );
    await customStatement('DELETE FROM selection_snapshots');
    return [for (final r in restored) _toRow(r)];
  });

  /// Drops selected files that left the index; returns their ids.
  Future<List<String>> prune() => transaction(() async {
    final gone = await customSelect(
      'SELECT file_id FROM selection_items '
      'WHERE file_id NOT IN (SELECT id FROM media_index)',
      readsFrom: {selectionItems, mediaIndex},
    ).get();
    if (gone.isEmpty) return const <String>[];
    final ids = [for (final r in gone) r.read<String>('file_id')];
    await remove(ids);
    return ids;
  });

  Future<List<SelectedRow>> _rows(String table, {int? afterSeq}) async {
    final rows = await customSelect(
      '$_sizeJoin $table s LEFT JOIN media_index m ON m.id = s.file_id '
      '${afterSeq == null ? '' : 'WHERE s.seq > ?'} ORDER BY s.seq',
      variables: [if (afterSeq != null) Variable<int>(afterSeq)],
      readsFrom: {selectionItems, selectionSnapshots, mediaIndex},
    ).get();
    return [for (final r in rows) _toRow(r)];
  }

  static SelectedRow _toRow(QueryRow r) => (
    id: r.read<String>('id'),
    seq: r.read<int>('seq'),
    sizeBytes: r.read<int>('size'),
  );
}
