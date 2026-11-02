import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/data/rename_runner.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

@immutable
sealed class UndoOutcome {
  const new();
}

/// The stack was empty.
class NothingToUndo extends UndoOutcome {
  const new();
}

/// Undone; the file can be shown again.
class Undone extends UndoOutcome {
  const new(
    this.action, {
    this.restoredFromTrash = false,
    this.file,
    this.reshow = true,
    this.alreadySent = false,
  });

  final SessionAction action;
  final bool restoredFromTrash;

  /// N9: the swipe send had already started or finished; it stays.
  final bool alreadySent;

  /// The file to show again when it isn't `action.fileId` (a move undone:
  /// the file is back under its old folder, maybe with a new id).
  final FileRef? file;

  /// False when no file comes back to the deck (a rename batch reverted).
  final bool reshow;
}

/// A committed permanent delete: can't come back. The stack moved past it.
class PermanentlyDeleted extends UndoOutcome {
  const new(this.action);

  final SessionAction action;
}

/// The inverse failed. [movedPast] = the row was marked undone anyway so the
/// stack can't get stuck (file missing etc.); false = retry possible (e.g.
/// the user declined the restore dialog).
class UndoFailed extends UndoOutcome {
  const new(this.action, this.error, {required this.movedPast});

  final SessionAction action;
  final Object error;
  final bool movedPast;
}

/// Undo semantics (TASK-S2). Runs under the lock shared with D2 commits.
class UndoService {
  new({
    required this._repo,
    required this._deletes,
    required this._source,
    required this._lock,
    required this._queue,
    required this._indexer,
    required this._index,
    required this._tags,
    required this._favorites,
    required this._renames,
    required this._renameRunner,
    this._remoteSource,
    this._cancelQueuedSend,
  });

  /// N9: removes a still-queued swipe send; false = already started.
  final Future<bool> Function(int transferFileId)? _cancelQueuedSend;

  final UndoRepository _repo;
  final DeleteQueue _deletes;
  final FileSource _source;

  /// N8: the source of a non-local source id (remote session actions).
  final FileSource Function(String sourceId)? _remoteSource;

  FileSource _sourceOf(String fileId) {
    final id = sourceIdOfFile(fileId);
    if (id == kLocalSourceId) return _source;
    final remote = _remoteSource;
    if (remote == null) throw ArgumentError.value(id, 'sourceId');
    return remote(id);
  }

  final SerialLock _lock;
  final DbWriteQueue _queue;
  final MediaIndexer _indexer;
  final MediaIndexDao _index;
  final TagRepository _tags;
  final FavoritesRepository _favorites;
  final RenameBatchRepository _renames;
  final RenameRunner _renameRunner;

  Future<UndoOutcome> undoLast(int sessionId) => _lock.run(() async {
    // Recorded swipes may still be in the write queue.
    await _queue.flush();
    final top = await _repo.top(sessionId);
    if (top == null) return const NothingToUndo();
    return await _undo(top);
  });

  /// Undoes everything newer than and including [seq] (history sheet).
  Future<List<UndoOutcome>> undoUntil(int sessionId, int seq) async {
    final outcomes = <UndoOutcome>[];
    while (true) {
      final outcome = await _lock.run(() async {
        await _queue.flush();
        final top = await _repo.top(sessionId);
        if (top == null || top.seq < seq) return const NothingToUndo();
        return await _undo(top);
      });
      if (outcome is NothingToUndo) break;
      outcomes.add(outcome);
      if (outcome is UndoFailed && !outcome.movedPast) break;
    }
    return outcomes;
  }

  /// U2: queued delete → dropped, the copy goes; committed to the trash →
  /// the original is restored, then the copy goes; deleted permanently →
  /// the copy is safely moved back (copy → verify → delete the copy).
  Future<UndoOutcome> _undoCrossPlaceMove(
    SessionAction a,
    CrossPlaceMovePreviousState previous,
    FileSource source,
  ) async {
    FileRef back;
    if (a.status == ActionStatus.applied) {
      await _deletes.unqueue(a.id);
      back = previous.source;
    } else if (previous.mode == 'trash' && previous.trashedItem != null) {
      back = await source.restore(TrashedItem.fromJson(previous.trashedItem!));
      await _indexer.addFiles([back]);
    } else {
      final copy = await source.stat(previous.copy.id);
      if (copy == null) {
        await _repo.markUndone(a.id);
        return PermanentlyDeleted(a);
      }
      back = await source.copy(copy, previous.source.folderPath);
      await _indexer.addFiles([back]);
    }
    final copy = await source.stat(previous.copy.id);
    // KFM's own copy: deleted without asking.
    if (copy != null) await source.deletePermanentlyBatch([copy]);
    await _index.deleteIds([previous.copy.id]);
    await _repo.markUndone(a.id);
    return Undone(a, file: back);
  }

  Future<UndoOutcome> _undo(SessionAction a) async {
    final remote = sourceIdOfFile(a.fileId) != kLocalSourceId;
    try {
      final source = _sourceOf(a.fileId);
      switch (a.action.type) {
        case SwipeActionType.keep:
          break;
        case SwipeActionType.sendToDevice:
          if (a.previous case SendPreviousState(:final transferFileId)) {
            final removed =
                await _cancelQueuedSend?.call(transferFileId) ?? true;
            if (!removed) {
              await _repo.markUndone(a.id);
              return Undone(a, alreadySent: true);
            }
          }
        case SwipeActionType.trash:
          if (a.status == ActionStatus.applied) {
            await _deletes.unqueue(a.id);
          } else {
            final previous = a.previous as TrashPreviousState;
            final item = previous.trashedItem;
            if (previous.mode == 'permanent' || item == null) {
              await _repo.markUndone(a.id);
              return PermanentlyDeleted(a);
            }
            // A remote file can't come back from here: `unsupported` →
            // "Restore it from the Trash on <A>" (N8).
            await source.restore(TrashedItem.fromJson(item));
            await _repo.markUndone(a.id);
            return Undone(a, restoredFromTrash: true);
          }
        case SwipeActionType.moveTo
            when a.previous is CrossPlaceMovePreviousState:
          return await _undoCrossPlaceMove(
            a,
            a.previous as CrossPlaceMovePreviousState,
            source,
          );
        case SwipeActionType.moveTo:
          final previous = a.previous as MovePreviousState;
          final current = await source.stat(a.fileId);
          if (current == null) {
            throw FileOpException(
              FileOpFailure.notFound,
              'moved file gone: ${a.fileId}',
            );
          }
          final back = await source.move(current, previous.folderPath);
          // Remote files never go into this device's index (N8).
          if (!remote) await _indexer.addFiles([back]);
          await _repo.markUndone(a.id);
          return Undone(a, file: back);
        case SwipeActionType.copyTo:
          final previous = a.previous as CopyPreviousState;
          final copy = await source.stat(previous.createdFileId);
          if (copy != null && remote) {
            // N8: never deleted permanently on another device: the copy
            // goes to its trash (recoverable, harmless).
            final result = await source.trashBatch([copy]);
            if (result.userCancelled) {
              throw const FileOpException(
                FileOpFailure.userCancelled,
                'copy not trashed',
              );
            }
          } else if (copy != null) {
            // KFM's own copy: deleted without a system dialog (P2 Kotlin).
            await source.deletePermanentlyBatch([copy]);
          }
          await _index.deleteIds([previous.createdFileId]);
        case SwipeActionType.addTag:
          await _tags.removeIfAdded(a.fileId, a.previous as TagPreviousState);
        case SwipeActionType.favorite:
          await _favorites.removeIfAdded(
            a.fileId,
            a.previous as FavoritePreviousState,
          );
        case SwipeActionType.renameBatch:
          final previous = a.previous as RenamePreviousState;
          if (previous.op == RenameOp.apply) {
            await _renameRunner.revert(previous.batchId);
            await _repo.markUndone(a.id);
            return Undone(a, reshow: false);
          }
          if (previous.added) {
            await _renames.removeItem(previous.batchId, a.fileId);
          }
      }
      await _repo.markUndone(a.id);
      return Undone(a);
    } on FileOpException catch (e) {
      final retryable = e.failure == FileOpFailure.userCancelled;
      if (!retryable) await _repo.markUndone(a.id);
      return UndoFailed(a, e, movedPast: !retryable);
    } on Object catch (e) {
      // Not built yet (restore before D3/D5, P2 actions): keep the row so
      // the user can undo it once it works. Anything else: move past.
      final retryable = e is UnimplementedError;
      if (!retryable) await _repo.markUndone(a.id);
      return UndoFailed(a, e, movedPast: !retryable);
    }
  }
}
