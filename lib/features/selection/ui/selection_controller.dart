import 'dart:async';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/selection/data/selection_dao.dart';
import 'package:kfm/features/selection/data/selection_repository.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selection_controller.g.dart';

typedef _Entry = ({int seq, int size});

/// The one global selection (TASK-B6), used by Browse, collections and
/// search. State changes at once; writes follow through the write queue.
/// Nothing here removes a file except [remove] (Edit mode), [clearAll] and
/// pruning files that left the index.
@Riverpod(keepAlive: true)
class SelectionController extends _$SelectionController {
  /// Adds (taps, drags) are written in one batch per this window: every
  /// commit is an fsync (`synchronous = FULL`).
  static const addBatchWindow = Duration(milliseconds: 100);

  /// Edit-mode removals that Undo can bring back.
  static const maxRemovalUndo = 50;

  final Map<String, _Entry> _entries = {};
  final List<({String id, _Entry entry})> _removed = [];
  final List<({String id, int seq})> _pendingAdds = [];
  Timer? _addTimer;
  int _maxSeq = 0;

  SelectionRepository get _repo => ref.read(selectionRepositoryProvider);

  @override
  Future<SelectionState> build() async {
    final sub = ref
        .watch(fileSourceProvider)
        .idChanges
        .listen((c) => _rekey(c.oldId, c.newRef.id));
    ref
      ..onDispose(sub.cancel)
      ..onDispose(() => _addTimer?.cancel())
      ..listen(mediaIndexChangesProvider, (_, _) => unawaited(_prune()));
    final stored = await ref.read(selectionRepositoryProvider).load();
    _entries
      ..clear()
      ..addEntries([
        for (final r in stored.rows)
          MapEntry(r.id, (seq: r.seq, size: r.sizeBytes)),
      ]);
    _maxSeq = stored.rows.isEmpty ? 0 : stored.rows.last.seq;
    // Files deleted while the app was closed.
    scheduleMicrotask(() => unawaited(_prune()));
    return SelectionState(
      ids: Set.unmodifiable(_entries.keys),
      totalBytes: stored.totalBytes,
      canRestoreCleared: stored.hasSnapshot,
    );
  }

  SelectionState? get _s => state.value;

  void enterSelect() => _setMode(SelectionMode.select);

  /// Back / ✕ in Select mode. The selection is kept.
  void exitSelect() => _setMode(SelectionMode.normal);

  void enterEdit() => _setMode(SelectionMode.edit);

  /// "Done" in Edit mode → back to Select.
  void exitEdit() => _setMode(SelectionMode.select);

  void _setMode(SelectionMode mode) {
    final s = _s;
    if (s == null || s.mode == mode) return;
    state = AsyncData(s.copyWith(mode: mode));
  }

  /// Select-mode tap. Never removes; false = already selected (the tile
  /// pulses).
  bool add(FileRef f) => addAll([f]) > 0;

  /// Drag / range add. Returns how many were new.
  int addAll(Iterable<FileRef> files) {
    final s = _s;
    if (s == null) return 0;
    var bytes = 0;
    final added = <String>[];
    for (final f in files) {
      if (_entries.containsKey(f.id)) continue;
      final seq = ++_maxSeq;
      _entries[f.id] = (seq: seq, size: f.sizeBytes);
      _pendingAdds.add((id: f.id, seq: seq));
      added.add(f.id);
      bytes += f.sizeBytes;
    }
    if (added.isEmpty) return 0;
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable({...s.ids, ...added}),
        totalBytes: s.totalBytes + bytes,
      ),
    );
    _addTimer ??= Timer(addBatchWindow, _flushAdds);
    return added.length;
  }

  /// Edit-mode tap: removes [f] (Undo via [undoRemove]).
  void remove(FileRef f) {
    final s = _s;
    final entry = _entries.remove(f.id);
    if (s == null || entry == null) return;
    _removed.add((id: f.id, entry: entry));
    if (_removed.length > maxRemovalUndo) _removed.removeAt(0);
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable({...s.ids}..remove(f.id)),
        totalBytes: s.totalBytes - entry.size,
      ),
    );
    _flushAdds();
    _repo.remove([f.id]).fireAndForget();
  }

  bool get canUndoRemove => _removed.isNotEmpty;

  /// Brings back the last removed file with its old place in the order.
  void undoRemove() {
    final s = _s;
    if (s == null || _removed.isEmpty) return;
    final last = _removed.removeLast();
    if (_entries.containsKey(last.id)) return;
    _entries[last.id] = last.entry;
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable({...s.ids, last.id}),
        totalBytes: s.totalBytes + last.entry.size,
      ),
    );
    _flushAdds();
    _repo.add([(id: last.id, seq: last.entry.seq)]).fireAndForget();
  }

  /// Adds every visible file of [query] (not only loaded pages). Returns
  /// how many were added (0 when nothing of it is visible).
  Future<int> selectAll(IndexQuery query) async {
    final canSeeAll =
        ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final visible = query.visible(canSeeAllFiles: canSeeAll);
    if (visible == null || _s == null) return 0;
    _flushAdds();
    final rows = await _repo.selectAll(visible);
    if (!ref.mounted) return 0;
    _merge(rows);
    return rows.length;
  }

  /// Clears instantly; Undo = [restoreCleared]. Returns how many.
  Future<int> clearAll() async {
    final s = _s;
    if (s == null || s.isEmpty) return 0;
    _flushAdds();
    final count = s.count;
    _entries.clear();
    _removed.clear();
    state = AsyncData(
      s.copyWith(ids: const {}, totalBytes: 0, canRestoreCleared: true),
    );
    await _repo.clearAll();
    return count;
  }

  /// "Restore last selection" / the snackbar's Undo. Merges with files
  /// selected since the clear.
  Future<void> restoreCleared() async {
    if (_s == null) return;
    _flushAdds();
    final rows = await _repo.restoreCleared();
    if (!ref.mounted) return;
    _merge(rows);
    final s = _s;
    if (s != null) state = AsyncData(s.copyWith(canRestoreCleared: false));
  }

  /// Selected ids in selection order (actions, View selected, Swipe these).
  Future<List<String>> orderedIds() {
    _flushAdds();
    return _repo.orderedIds();
  }

  /// True once: the first tap on an already-selected tile shows the tip.
  Future<bool> takeTip() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.read(AppSettings.selectionTipShown)) return false;
    await settings.write(AppSettings.selectionTipShown, true);
    return true;
  }

  /// Writes pending adds and waits for the queue (tests, app pause).
  Future<void> flush() async {
    _flushAdds();
    await ref.read(dbWriteQueueProvider).flush();
  }

  void _flushAdds() {
    _addTimer?.cancel();
    _addTimer = null;
    if (_pendingAdds.isEmpty) return;
    final items = List.of(_pendingAdds);
    _pendingAdds.clear();
    _repo.add(items).fireAndForget();
  }

  void _merge(List<SelectedRow> rows) {
    final s = _s;
    if (s == null || rows.isEmpty) return;
    var bytes = 0;
    final added = <String>[];
    for (final r in rows) {
      if (_entries.containsKey(r.id)) continue;
      _entries[r.id] = (seq: r.seq, size: r.sizeBytes);
      if (r.seq > _maxSeq) _maxSeq = r.seq;
      added.add(r.id);
      bytes += r.sizeBytes;
    }
    if (added.isEmpty) return;
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable({...s.ids, ...added}),
        totalBytes: s.totalBytes + bytes,
      ),
    );
  }

  /// FileIdRekeyer moves the rows; this swaps the id in memory.
  void _rekey(String oldId, String newId) {
    final s = _s;
    if (s == null || oldId == newId) return;
    for (final (i, r) in _removed.indexed) {
      if (r.id == oldId) _removed[i] = (id: newId, entry: r.entry);
    }
    final entry = _entries.remove(oldId);
    if (entry == null) return;
    _entries[newId] = entry;
    // An add of the old id still waiting may land after the re-key: write
    // the new id too (idempotent with FileIdRekeyer).
    _flushAdds();
    _repo.add([(id: newId, seq: entry.seq)]).fireAndForget();
    _repo.remove([oldId]).fireAndForget();
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable(
          {...s.ids}
            ..remove(oldId)
            ..add(newId),
        ),
      ),
    );
  }

  Future<void> _prune() async {
    if (_s == null) return;
    _flushAdds();
    final gone = await _repo.prune();
    if (!ref.mounted) return;
    final s = _s;
    if (s == null || gone.isEmpty) return;
    var bytes = 0;
    final removed = <String>{};
    for (final id in gone) {
      final entry = _entries.remove(id);
      if (entry == null) continue;
      bytes += entry.size;
      removed.add(id);
    }
    if (removed.isEmpty) return;
    state = AsyncData(
      s.copyWith(
        ids: Set.unmodifiable(s.ids.difference(removed)),
        totalBytes: s.totalBytes - bytes,
      ),
    );
  }
}
