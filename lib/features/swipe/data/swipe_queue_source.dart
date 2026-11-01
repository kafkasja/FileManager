import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';

/// What the deck pages through (TASK-SS1). N8 adds a remote implementation.
abstract interface class SwipeQueueSource {
  /// Up to [size] files after [after], skipping [skip].
  Future<SwipeWindow> window({
    required Set<String> skip,
    IndexCursor? after,
    int size = 200,
  });

  /// Files not acted on yet (approximate for lists until every window is
  /// loaded: gone files are only found while paging).
  Future<int> remaining(Set<String> acted);

  /// SE2's "N new photos" chip (main deck only).
  bool get offersNewFiles;

  /// Group position of [fileId] (groups sources only).
  SwipeGroupPosition? groupPositionOf(String fileId);
}

/// The media index through [query] (today's deck: the main deck with P5's
/// filter, or a filter source). A null [query] is an empty deck.
class IndexQueueSource implements SwipeQueueSource {
  new(this._repo, this._dao, this.query, {this.offersNewFiles = true});

  final SwipeQueueRepository _repo;
  final MediaIndexDao _dao;
  final IndexQuery? query;

  @override
  final bool offersNewFiles;

  @override
  Future<SwipeWindow> window({
    required Set<String> skip,
    IndexCursor? after,
    int size = 200,
  }) async {
    final q = query;
    if (q == null) return const SwipeWindow([], null);
    return await _repo.window(skip: skip, query: q, after: after, size: size);
  }

  @override
  Future<int> remaining(Set<String> acted) async {
    final q = query;
    if (q == null) return 0;
    final total = await _repo.count(q);
    final done = await _dao.countAmong(q, acted.toList());
    final left = total - done;
    return left < 0 ? 0 : left;
  }

  @override
  SwipeGroupPosition? groupPositionOf(String fileId) => null;
}

/// A list or group source's ids in the caller's order (TASK-SS1). The
/// cursor is `IndexCursor(position, fileId)`. Ids that resolve to nothing
/// are dropped (in memory and through [onGone]).
class ListQueueSource implements SwipeQueueSource {
  new(
    this._dao,
    this._files,
    List<(String, int?)> items, {
    required this.onGone,
    this.groupCount,
  }) : _ids = [for (final (id, _) in items) id] {
    final perGroup = <int, int>{};
    for (final (id, group) in items) {
      if (group == null) continue;
      _group[id] ??= group;
      _indexInGroup[id] ??= perGroup[group] ?? 0;
      perGroup[group] = (perGroup[group] ?? 0) + 1;
    }
    _groupSize.addAll(perGroup);
  }

  final MediaIndexDao _dao;
  final FileSource _files;
  final List<String> _ids;
  final int? groupCount;

  /// Called (once per window) with ids that resolved to nothing.
  final void Function(List<String> gone) onGone;

  final Set<String> _gone = {};
  final Map<String, int> _group = {};
  final Map<String, int> _indexInGroup = {};
  final Map<int, int> _groupSize = {};

  /// Max ids looked up per window; stat fallbacks are slow (one by one).
  static const _statLimit = 500;

  @override
  bool get offersNewFiles => false;

  @override
  Future<SwipeWindow> window({
    required Set<String> skip,
    IndexCursor? after,
    int size = 200,
  }) async {
    var pos = after == null ? 0 : (after.sortValue as int) + 1;
    final files = <FileRef>[];
    final gone = <String>[];
    var stats = 0;
    while (files.length < size && pos < _ids.length) {
      final batch = <(int, String)>[];
      while (batch.length < size - files.length && pos < _ids.length) {
        final id = _ids[pos];
        if (!skip.contains(id) && !_gone.contains(id)) batch.add((pos, id));
        pos++;
      }
      if (batch.isEmpty) break;
      final found = {
        for (final f in await _dao.byIds([for (final (_, id) in batch) id]))
          f.id: f,
      };
      for (final (_, id) in batch) {
        var file = found[id];
        if (file == null && stats < _statLimit) {
          stats++;
          file = await _files.stat(id);
        }
        if (file == null) {
          gone.add(id);
        } else {
          files.add(file);
        }
      }
    }
    if (gone.isNotEmpty) {
      _gone.addAll(gone);
      onGone(gone);
    }
    final next = pos < _ids.length && files.isNotEmpty
        ? IndexCursor(pos - 1, _ids[pos - 1])
        : null;
    return SwipeWindow(files, next);
  }

  @override
  Future<int> remaining(Set<String> acted) async => _ids
      .where((id) => !acted.contains(id) && !_gone.contains(id))
      .toSet()
      .length;

  @override
  SwipeGroupPosition? groupPositionOf(String fileId) {
    final count = groupCount;
    final group = _group[fileId];
    if (count == null || group == null) return null;
    return SwipeGroupPosition(
      group: group + 1,
      groupCount: count,
      index: (_indexInGroup[fileId] ?? 0) + 1,
      groupSize: _groupSize[group] ?? 1,
    );
  }
}
