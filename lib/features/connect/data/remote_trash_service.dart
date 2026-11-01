import 'dart:async';

import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_trash_service.g.dart';

/// The banner the share screen shows while a client's request runs.
@Riverpod(keepAlive: true)
class RemoteRequestNoticeState extends _$RemoteRequestNoticeState {
  @override
  RemoteRequestNotice? build() => null;

  // A notifier method, not a setter: the service passes it as a callback.
  // ignore: use_setters_to_change_properties
  void show(RemoteRequestNotice? notice) => state = notice;
}

/// The last finished client request (share screen snackbar).
@Riverpod(keepAlive: true)
class RemoteRequestOutcomeState extends _$RemoteRequestOutcomeState {
  @override
  RemoteRequestOutcome? build() => null;

  // A notifier method, not a setter: the service passes it as a callback.
  // ignore: use_setters_to_change_properties
  void report(RemoteRequestOutcome outcome) => state = outcome;
}

@Riverpod(keepAlive: true)
RemoteTrashService remoteTrashService(Ref ref) => RemoteTrashService(
  source: () => ref.read(fileSourceProvider),
  lock: ref.watch(historyLockProvider),
  onNotice: (n) => ref.read(remoteRequestNoticeStateProvider.notifier).show(n),
  onOutcome: (o) =>
      ref.read(remoteRequestOutcomeStateProvider.notifier).report(o),
  sessionAlive: (id) => ref
      .read(clientSessionStoreProvider)
      .sessions
      .any((s) => s.sessionId == id),
  removeFromIndex: (ids) async {
    // Waits for indexer jobs queued before it (an empty addFiles is a
    // barrier), so an earlier upsert can't bring the rows back (B4).
    await ref.read(mediaIndexerProvider).addFiles(const []);
    await ref
        .read(dbWriteQueueProvider)
        .enqueue(null, () => ref.read(mediaIndexDaoProvider).deleteIds(ids));
  },
);

/// Who asked for a trash batch (TASK-N7). File sources never see it; only
/// the share screen's notice uses it.
@immutable
sealed class TrashBatchOrigin {
  const new();
}

/// This device's own user.
final class LocalTrashOrigin extends TrashBatchOrigin {
  const new();
}

/// A connected client ([deviceName] is the name it paired with).
final class RemoteTrashOrigin extends TrashBatchOrigin {
  const new(this.deviceName);

  final String deviceName;

  @override
  bool operator ==(Object other) =>
      other is RemoteTrashOrigin && other.deviceName == deviceName;

  @override
  int get hashCode => deviceName.hashCode;
}

/// What a remote request asks of this device.
enum RemoteRequestKind {
  /// Move files to trash (system dialog where the platform needs one).
  trash,

  /// Write access before a client's batch rename/move (system dialog).
  writeAccess,
}

/// Shown as a banner on the share screen while a remote request may open a
/// system dialog: "<B> wants to move N files to trash".
@immutable
class RemoteRequestNotice {
  const new({required this.origin, required this.count, required this.kind});

  final TrashBatchOrigin origin;
  final int count;
  final RemoteRequestKind kind;

  String get deviceName => switch (origin) {
    RemoteTrashOrigin(:final deviceName) => deviceName,
    LocalTrashOrigin() => '',
  };

  @override
  bool operator ==(Object other) =>
      other is RemoteRequestNotice &&
      other.origin == origin &&
      other.count == count &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(origin, count, kind);
}

/// How a remote trash request ended (share screen snackbar): "<B> moved N
/// files to trash" or "You declined <B>'s request". [seq] makes every
/// outcome a new value (Riverpod skips equal ones).
@immutable
class RemoteRequestOutcome {
  const new({
    required this.seq,
    required this.deviceName,
    required this.kind,
    required this.count,
    required this.declined,
  });

  final int seq;
  final String deviceName;
  final RemoteRequestKind kind;

  /// Files trashed (or asked for, when [declined]).
  final int count;
  final bool declined;

  @override
  bool operator ==(Object other) =>
      other is RemoteRequestOutcome && other.seq == seq;

  @override
  int get hashCode => seq.hashCode;
}

/// Who sent a remote request.
typedef RemoteCaller = ({
  String sessionId,
  String clientFingerprint,
  String clientName,
});

/// The client already has a trash or write-access request waiting (→ 409
/// `busy`).
class RemoteBusyException implements Exception {
  const new();

  @override
  String toString() => 'RemoteBusyException';
}

/// The client's session ended (Disconnect, stop sharing) while the request
/// waited for the history lock: nothing was done (→ 410 `cancelled`).
class RemoteRequestDropped implements Exception {
  const new();

  @override
  String toString() => 'RemoteRequestDropped';
}

/// Runs a client's trash, write-access and consent-prone edit requests on
/// the sharing device (TASK-N7 → "Remote trash"). Every request holds the
/// history lock (the `SerialLock` swipe undo and delete commits share), so
/// it never overlaps this device's own dialogs, and shows
/// [RemoteRequestNotice] while it runs. A request whose session is gone by
/// the time it gets the lock is dropped; each client has at most one
/// trash/write-access request waiting. Uses `trashBatch` only: a remote
/// delete is **never** permanent, whatever this device's delete setting
/// is. Trashed files leave the index through `removeFromIndex` afterwards
/// (off the lock).
///
/// A system dialog nobody answers keeps the lock (the platform can't
/// cancel it); stopping sharing ends the sessions, so every request queued
/// behind it is dropped instead of opening another dialog.
class RemoteTrashService {
  new({
    required this._source,
    required this._lock,
    required this._onNotice,
    required this._onOutcome,
    required this._removeFromIndex,
    bool Function(String sessionId)? sessionAlive,
  }) : _sessionAlive = sessionAlive ?? _always;

  static bool _always(String _) => true;

  /// Files per `trashBatch` call (one system dialog each).
  static const chunk = 500;

  final FileSource Function() _source;
  final SerialLock _lock;
  final void Function(RemoteRequestNotice? notice) _onNotice;
  final void Function(RemoteRequestOutcome outcome) _onOutcome;
  final Future<void> Function(List<String> ids) _removeFromIndex;
  final bool Function(String sessionId) _sessionAlive;
  final Set<String> _waiting = {};
  int _seq = 0;

  /// Index removal of the last request (tests).
  Future<void> indexSettled = Future<void>.value();

  Future<T> _run<T>(
    RemoteCaller caller,
    RemoteRequestKind kind,
    int count,
    Future<T> Function() op, {
    required bool onePerClient,
  }) async {
    if (onePerClient && !_waiting.add(caller.clientFingerprint)) {
      throw const RemoteBusyException();
    }
    try {
      return await _lock.run(() async {
        if (!_sessionAlive(caller.sessionId)) {
          throw const RemoteRequestDropped();
        }
        _onNotice(
          RemoteRequestNotice(
            origin: RemoteTrashOrigin(caller.clientName),
            count: count,
            kind: kind,
          ),
        );
        try {
          return await op();
        } finally {
          _onNotice(null);
        }
      });
    } finally {
      if (onePerClient) _waiting.remove(caller.clientFingerprint);
    }
  }

  /// Trashes [files] for [caller], in chunks of [chunk]. A declined system
  /// dialog comes back as `userCancelled` (never thrown; later chunks are
  /// skipped); a chunk that fails reports its ids in `failed`, and what was
  /// trashed before stays reported (and leaves the index).
  Future<TrashResult> trash(
    List<FileRef> files, {
    required RemoteCaller caller,
  }) {
    if (files.isEmpty) {
      return Future.value(const TrashResult(trashed: [], failed: {}));
    }
    return _run(caller, RemoteRequestKind.trash, files.length, () async {
      final trashed = <TrashedItem>[];
      final failed = <String, FileOpException>{};
      var cancelled = false;
      try {
        for (var i = 0; i < files.length && !cancelled; i += chunk) {
          final part = files.sublist(
            i,
            i + chunk > files.length ? files.length : i + chunk,
          );
          try {
            final r = await _source().trashBatch(part);
            trashed.addAll(r.trashed);
            failed.addAll(r.failed);
            cancelled = r.userCancelled;
          } on FileOpException catch (e) {
            if (e.failure == FileOpFailure.userCancelled) {
              cancelled = true;
            } else {
              for (final f in part) {
                failed[f.id] = FileOpException(
                  e.failure,
                  e.message,
                  fileId: f.id,
                );
              }
            }
          } on Object catch (e) {
            for (final f in part) {
              failed[f.id] = FileOpException(
                FileOpFailure.ioError,
                '$e',
                fileId: f.id,
              );
            }
          }
        }
      } finally {
        final ids = [for (final t in trashed) t.original.id];
        if (ids.isNotEmpty) {
          final removal = _removeFromIndex(ids);
          indexSettled = removal;
          unawaited(removal.then<void>((_) {}, onError: (Object _) {}));
        }
        _onOutcome(
          RemoteRequestOutcome(
            seq: ++_seq,
            deviceName: caller.clientName,
            kind: RemoteRequestKind.trash,
            count: cancelled && trashed.isEmpty ? files.length : trashed.length,
            declined: cancelled && trashed.isEmpty,
          ),
        );
      }
      return TrashResult(
        trashed: trashed,
        failed: failed,
        userCancelled: cancelled,
      );
    }, onePerClient: true);
  }

  /// `FileSource.requestWriteAccess` for [caller] under the lock and the
  /// notice. False = declined.
  Future<bool> requestWriteAccess(
    List<FileRef> files, {
    required RemoteCaller caller,
  }) {
    if (files.isEmpty) return Future.value(true);
    return _run(caller, RemoteRequestKind.writeAccess, files.length, () async {
      final granted = await _source().requestWriteAccess(files);
      if (!granted) {
        _onOutcome(
          RemoteRequestOutcome(
            seq: ++_seq,
            deviceName: caller.clientName,
            kind: RemoteRequestKind.writeAccess,
            count: files.length,
            declined: true,
          ),
        );
      }
      return granted;
    }, onePerClient: true);
  }

  /// A move or rename for [caller]: on Android 11+ it can open a consent
  /// dialog, so it runs under the lock and the notice too.
  Future<T> edit<T>(Future<T> Function() op, {required RemoteCaller caller}) =>
      _run(caller, RemoteRequestKind.writeAccess, 1, op, onePerClient: false);
}
