import 'dart:async';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

/// N8: what a remote session's swipes may do. [roots] maps the other
/// device's shared root ids to "read-only" (N4); null = not known right now
/// (not connected: nothing is checked, nothing runs on the device anyway).
@immutable
class RemoteSwipeRules {
  const new({this.roots, this.peerDeviceId});

  final Map<String, bool>? roots;

  /// N9: that device's known_devices id (null = not remembered). A send to
  /// it from its own session downloads the file here.
  final String? peerDeviceId;

  /// The root id of a remote `folderPath` (`'<rootId>[/<path>]'`), or null
  /// for a local (absolute) path.
  static String? rootOf(String? folderPath) {
    if (folderPath == null || folderPath.isEmpty) return null;
    if (folderPath.startsWith('/')) return null;
    final slash = folderPath.indexOf('/');
    return slash < 0 ? folderPath : folderPath.substring(0, slash);
  }
}

/// N9: queues a swipe send inside the undo row's transaction and returns
/// the transfer file id (local session: upload into the action's folder on
/// its device; remote session: download into `Download/<device>`).
typedef SwipeSendQueue = Future<int> Function(
  Session session,
  FileRef file,
  SwipeAction action,
);

/// Routes a swipe to the undo log (S2) and, for trash, the delete queue (D2),
/// without awaiting any I/O on the gesture path. Write failures surface on
/// the write queue's error stream (shell banner); move/copy failures on
/// [SwipeFileOps.events].
class SwipeActionDispatcher {
  new(
    this._undo,
    this._deletes, {
    required this._fileOps,
    required this._tags,
    required this._favorites,
    required this._renames,
    this._sends,
  });

  final UndoRepository _undo;
  final DeleteQueue _deletes;

  /// U2: session ids, once per session, on the first delete swipe of a
  /// camera file (its delete is permanent: the screen warns).
  Stream<int> get cameraDeleteWarnings => _cameraWarnings.stream;
  final StreamController<int> _cameraWarnings =
      StreamController<int>.broadcast();
  final Set<int> _warnedSessions = {};
  final SwipeFileOps _fileOps;
  final TagRepository _tags;
  final FavoritesRepository _favorites;
  final RenameBatchRepository _renames;
  final SwipeSendQueue? _sends;

  /// Types the deck can dispatch; others act as unmapped (spring back).
  static const Set<SwipeActionType> supported = {
    SwipeActionType.trash,
    SwipeActionType.keep,
    SwipeActionType.moveTo,
    SwipeActionType.copyTo,
    SwipeActionType.addTag,
    SwipeActionType.favorite,
    SwipeActionType.renameBatch,
    SwipeActionType.sendToDevice,
  };

  /// Synchronous pre-check (no I/O). A missing folder is only found by the
  /// file operation itself. N8: in a remote session ([remote]) the target
  /// must be a writable folder on that device, and [file]'s folder must be
  /// writable for trash and move. N9: a send needs a remembered device
  /// ([knownDeviceIds]; null = not loaded, not checked) and, locally, a
  /// folder on it.
  static SwipeActionProblem? problemFor(
    SwipeAction action,
    Map<int, Tag> tags, {
    RemoteSwipeRules? remote,
    FileRef? file,
    Set<String>? knownDeviceIds,
  }) {
    if (remote != null) {
      final problem = _remoteProblem(action, remote, file);
      if (problem != null) return problem;
    }
    if (!supported.contains(action.type)) {
      return SwipeActionProblem.unsupported;
    }
    if (action.type == SwipeActionType.addTag &&
        !tags.containsKey(action.tagId)) {
      return SwipeActionProblem.tagMissing;
    }
    if ((action.type == SwipeActionType.moveTo ||
            action.type == SwipeActionType.copyTo) &&
        action.targetFolder == null) {
      return SwipeActionProblem.unsupported;
    }
    if (action.type == SwipeActionType.sendToDevice) {
      final device = action.deviceId;
      if (device == null) return SwipeActionProblem.unsupported;
      if (knownDeviceIds != null && !knownDeviceIds.contains(device)) {
        return SwipeActionProblem.deviceMissing;
      }
      if (remote == null && action.targetFolder == null) {
        return SwipeActionProblem.unsupported;
      }
    }
    return null;
  }

  static SwipeActionProblem? _remoteProblem(
    SwipeAction action,
    RemoteSwipeRules rules,
    FileRef? file,
  ) {
    switch (action.type) {
      case SwipeActionType.renameBatch:
        return SwipeActionProblem.notOnDevice;
      case SwipeActionType.sendToDevice:
        // Only "to this device" (a download); never to a third device.
        if (rules.peerDeviceId == null ||
            action.deviceId != rules.peerDeviceId) {
          return SwipeActionProblem.notOnDevice;
        }
      case SwipeActionType.moveTo || SwipeActionType.copyTo:
        final target = RemoteSwipeRules.rootOf(action.targetFolder);
        if (action.targetFolder != null && target == null) {
          return SwipeActionProblem.folderNotOnSource;
        }
        final roots = rules.roots;
        if (roots != null && target != null && roots[target] != false) {
          return SwipeActionProblem.folderNotOnSource;
        }
      case _:
        break;
    }
    final writes =
        action.type == SwipeActionType.trash ||
        action.type == SwipeActionType.moveTo;
    final roots = rules.roots;
    final root = RemoteSwipeRules.rootOf(file?.folderPath);
    if (writes && roots != null && root != null && roots[root] == true) {
      return SwipeActionProblem.readOnly;
    }
    return null;
  }

  /// U2: camera files (`mtp:`) have no trash: their deletes are permanent
  /// (the swipe screen warned once).
  static DeleteMode _trashMode(Session session, FileRef file) =>
      file.id.startsWith('mtp:') ? DeleteMode.permanent : session.deleteMode;

  /// Returns the action's seq. Call only when [problemFor] is null.
  int dispatch(Session session, FileRef file, SwipeAction action) {
    if (file.id.startsWith('mtp:') &&
        (action.type == SwipeActionType.trash ||
            action.type == SwipeActionType.moveTo) &&
        _warnedSessions.add(session.id)) {
      _cameraWarnings.add(session.id);
    }
    return _dispatch(session, file, action);
  }

  int _dispatch(Session session, FileRef file, SwipeAction action) =>
      switch (action.type) {
        SwipeActionType.keep => _undo.record(
          session.id,
          file,
          action,
          const NoPreviousState(),
        ),
        SwipeActionType.trash => _undo.record(
          session.id,
          file,
          action,
          TrashPreviousState(mode: _trashMode(session, file).name),
          alsoInTransaction: (actionId) => _deletes.queueInTransaction(
            actionId: actionId,
            sessionId: session.id,
            file: file,
            mode: _trashMode(session, file),
          ),
        ),
        SwipeActionType.addTag => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () =>
              _tags.addInTransaction(file.id, action.tagId!),
        ),
        SwipeActionType.favorite => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () => _favorites.addInTransaction(file.id),
        ),
        SwipeActionType.moveTo || SwipeActionType.copyTo => _fileOps.run(
          session.id,
          file,
          action,
          // U2: cameras have no trash.
          deleteMode: file.id.startsWith('mtp:')
              ? DeleteMode.permanent
              : session.deleteMode,
        ),
        SwipeActionType.renameBatch => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () => _renames.addInTransaction(session.id, file),
        ),
        SwipeActionType.sendToDevice => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () async {
            final sends =
                _sends ?? (throw StateError('no transfer queue (N9)'));
            return SendPreviousState(
              transferFileId: await sends(session, file, action),
            );
          },
        ),
      };
}
