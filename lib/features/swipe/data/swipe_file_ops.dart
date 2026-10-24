import 'dart:async';

import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

/// What happened to a move/copy swipe.
@immutable
sealed class SwipeFileOpEvent {
  const new(this.file, this.action);

  /// The file as it was when swiped.
  final FileRef file;
  final SwipeAction action;
}

final class SwipeFileOpDone extends SwipeFileOpEvent {
  const new(super.file, this.result, super.action);

  /// The moved file, or the new copy.
  final FileRef result;
}

final class SwipeFileOpFailed extends SwipeFileOpEvent {
  const new(super.file, super.action, this.error);

  final Object error;
}

/// Move/copy swipes (TASK-P2). They run immediately (rule 2) but off the
/// gesture path, under the lock shared with undo and D2 commits: an undo
/// pressed while a move runs waits for it, and a move never overlaps a
/// system trash dialog. The undo row is written only when the operation
/// succeeded; failures are published on [events] (rule 8).
class SwipeFileOps {
  new({
    required this._source,
    required this._undo,
    required this._lock,
    required this._indexer,
  });

  final FileSource _source;
  final UndoRepository _undo;
  final SerialLock _lock;
  final MediaIndexer _indexer;
  final StreamController<SwipeFileOpEvent> _events =
      StreamController.broadcast();

  Stream<SwipeFileOpEvent> get events => _events.stream;

  /// Returns the reserved seq; the work continues in the background.
  int run(int sessionId, FileRef file, SwipeAction action) {
    final seq = _undo.reserveSeq(sessionId);
    _lock.run(() => _apply(seq, sessionId, file, action)).ignore();
    return seq;
  }

  Future<void> _apply(
    int seq,
    int sessionId,
    FileRef file,
    SwipeAction action,
  ) async {
    try {
      final target = action.targetFolder;
      if (target == null) throw ArgumentError('no target folder');
      final isMove = action.type == SwipeActionType.moveTo;
      final result = isMove
          ? await _source.move(file, target)
          : await _source.copy(file, target);
      // The new folder / the copy shows up in the index right away.
      await _indexer.addFiles([result]);
      _undo.recordAt(
        seq,
        sessionId,
        isMove ? result.id : file.id,
        action,
        isMove
            ? MovePreviousState(
                folderPath: file.folderPath,
                fileIdBefore: file.id,
              )
            : CopyPreviousState(createdFileId: result.id),
      );
      _events.add(SwipeFileOpDone(file, result, action));
    } on Object catch (e) {
      _events.add(SwipeFileOpFailed(file, action, e));
    }
  }

  Future<void> dispose() => _events.close();
}
