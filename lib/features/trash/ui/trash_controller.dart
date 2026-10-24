import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_controller.g.dart';

@immutable
class TrashViewState {
  const new({
    required this.system,
    required this.pending,
    this.selectedIds = const {},
    this.busy = false,
  });

  /// Soonest expiry first.
  final List<TrashedItem> system;
  final List<TrashedItem> pending;

  /// TrashedItem.trashId.
  final Set<String> selectedIds;
  final bool busy;

  bool get selecting => selectedIds.isNotEmpty;

  List<TrashedItem> get selected => [
    for (final i in [...system, ...pending])
      if (selectedIds.contains(i.trashId)) i,
  ];

  TrashViewState copyWith({
    List<TrashedItem>? system,
    List<TrashedItem>? pending,
    Set<String>? selectedIds,
    bool? busy,
  }) => TrashViewState(
    system: system ?? this.system,
    pending: pending ?? this.pending,
    selectedIds: selectedIds ?? this.selectedIds,
    busy: busy ?? this.busy,
  );
}

/// What an action did, for the snackbar.
@immutable
class TrashActionResult {
  const new({this.done = 0, this.alreadyGone = 0, this.cancelled = false});

  final int done;
  final int alreadyGone;
  final bool cancelled;
}

/// Trash page (TASK-D5): system trash and pending folder on one page.
@riverpod
class TrashController extends _$TrashController {
  @override
  Future<TrashViewState> build() async {
    // Batch commits remove index rows: reload then.
    ref.watch(mediaIndexChangesProvider);
    final items = await ref.watch(fileSourceProvider).listTrashed();
    int byExpiry(TrashedItem a, TrashedItem b) =>
        (a.expiresAt ?? a.trashedAt).compareTo(b.expiresAt ?? b.trashedAt);
    final previous = state.value?.selectedIds ?? const {};
    final ids = {for (final i in items) i.trashId};
    return TrashViewState(
      system: [
        for (final i in items)
          if (i.location == TrashLocation.systemTrash) i,
      ]..sort(byExpiry),
      pending: [
        for (final i in items)
          if (i.location == TrashLocation.pendingFolder) i,
      ]..sort(byExpiry),
      selectedIds: previous.intersection(ids),
    );
  }

  void toggle(String trashId) {
    final s = state.value;
    if (s == null) return;
    final next = {...s.selectedIds};
    if (!next.remove(trashId)) next.add(trashId);
    state = AsyncData(s.copyWith(selectedIds: next));
  }

  void selectAll(List<TrashedItem> items) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(
        selectedIds: {...s.selectedIds, ...items.map((i) => i.trashId)},
      ),
    );
  }

  void clearSelection() {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(selectedIds: {}));
  }

  /// One system dialog for all selected system-trash items; pending items
  /// without a dialog. Declined → selection kept.
  Future<TrashActionResult> restoreSelected() async {
    final s = state.value;
    if (s == null || s.selected.isEmpty) return const TrashActionResult();
    state = AsyncData(s.copyWith(busy: true));
    try {
      final result = await ref
          .read(fileSourceProvider)
          .restoreBatch(s.selected);
      await _markRestoredInSession(s.selected, result);
      await ref
          .read(mediaIndexerProvider)
          .addFiles(result.restored.values.toList());
      if (result.userCancelled && result.restored.isEmpty) {
        state = AsyncData(s.copyWith(busy: false));
        return const TrashActionResult(cancelled: true);
      }
      ref.invalidateSelf();
      await future;
      return TrashActionResult(
        done: result.restored.length,
        alreadyGone: result.failed.values
            .where((e) => e.failure == FileOpFailure.notFound)
            .length,
        cancelled: result.userCancelled,
      );
    } on Object {
      state = AsyncData(s.copyWith(busy: false));
      rethrow;
    }
  }

  /// After the in-app confirmation: system dialog for media, then gone.
  Future<TrashActionResult> deleteForever(List<TrashedItem> items) async {
    final s = state.value;
    if (s == null || items.isEmpty) return const TrashActionResult();
    state = AsyncData(s.copyWith(busy: true));
    try {
      await ref.read(fileSourceProvider).deleteFromTrash(items);
    } on FileOpException catch (e) {
      state = AsyncData(s.copyWith(busy: false));
      if (e.failure == FileOpFailure.userCancelled) {
        return const TrashActionResult(cancelled: true);
      }
      rethrow;
    }
    ref.invalidateSelf();
    await future;
    return TrashActionResult(done: items.length);
  }

  /// Restored files are no longer "deleted" in the active session (S2).
  Future<void> _markRestoredInSession(
    List<TrashedItem> items,
    RestoreResult result,
  ) async {
    final session = await ref.read(sessionRepositoryProvider).active();
    if (session == null) return;
    final undo = ref.read(undoRepositoryProvider);
    for (final i in items) {
      if (result.restored.containsKey(i.trashId)) {
        await undo.markUndoneByFileId(session.id, i.original.id);
      }
    }
  }
}
