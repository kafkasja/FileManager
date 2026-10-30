import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/selection/data/selection_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selection_repository.g.dart';

/// The saved selection (TASK-B6). Every write goes through the ordered
/// DbWriteQueue (`coalesceKey` null), so an add queued before Clear all
/// lands before it.
class SelectionRepository {
  new(this._dao, this._index, this._queue, {this._clock = DateTime.now});

  final SelectionDao _dao;
  final MediaIndexDao _index;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;

  /// Reads after queued writes, so it sees them.
  Future<StoredSelection> load() async {
    await _queue.flush();
    return await _dao.load();
  }

  Future<List<String>> orderedIds() async {
    await _queue.flush();
    return await _dao.orderedIds();
  }

  Future<void> add(List<({String id, int seq})> items) {
    if (items.isEmpty) return Future.value();
    final now = _clock();
    return _queue.enqueue(null, () => _dao.add(items, now));
  }

  Future<void> remove(List<String> ids) {
    if (ids.isEmpty) return Future.value();
    return _queue.enqueue(null, () => _dao.remove(ids));
  }

  /// Adds every file of [visible] (already `IndexQuery.visible`). Returns
  /// the rows added, in their new order.
  Future<List<SelectedRow>> selectAll(IndexQuery visible) => _run(
    () => _dao.selectAll(
      _index.whereFor(_index.attachedDatabase.mediaIndex, visible),
      visible.sort,
      _clock(),
    ),
  );

  /// How many were cleared (0 = nothing selected, snapshot unchanged).
  Future<int> clearAll() => _run(_dao.clearAll);

  /// Rows the restore added back.
  Future<List<SelectedRow>> restoreCleared() => _run(_dao.restoreSnapshot);

  /// Ids dropped because they left the index.
  Future<List<String>> prune() => _run(_dao.prune);

  Future<T> _run<T>(Future<T> Function() job) async {
    late T result;
    await _queue.enqueue(null, () async => result = await job());
    return result;
  }
}

@Riverpod(keepAlive: true)
SelectionRepository selectionRepository(Ref ref) => SelectionRepository(
  SelectionDao(ref.watch(appDatabaseProvider)),
  ref.watch(mediaIndexDaoProvider),
  ref.watch(dbWriteQueueProvider),
);
