import 'dart:developer' as developer;

import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// [VerifiedMove] for originals on this device (TASK-N11). Every delete
/// batch runs under the history lock (the `SerialLock` swipe undo and
/// delete commits share), so its system dialog never overlaps theirs.
class LocalVerifiedMove implements VerifiedMove {
  new({
    required this._source,
    required this._lock,
    required this._removeFromIndex,
  });

  /// Files per trash / delete call (one system dialog each).
  static const int chunk = 500;

  final FileSource _source;
  final SerialLock _lock;

  /// Drops deleted originals from the index (after the batch, off the
  /// lock; failures are logged).
  final Future<void> Function(List<String> ids) _removeFromIndex;

  @override
  Future<FinalizeResult> deleteOriginals(
    List<VerifiedOriginal> originals, {
    required DeleteMode mode,
  }) async {
    final outcomes = <String, SourceOutcome>{};
    final errors = <String, String>{};
    final alive = <FileRef>[];
    for (final o in originals) {
      final id = o.original.id;
      final FileRef? now;
      try {
        now = await _source.stat(id);
      } on FileOpException catch (e) {
        if (e.failure == FileOpFailure.notFound) {
          outcomes[id] = SourceOutcome.alreadyGone;
        } else {
          outcomes[id] = SourceOutcome.keptFailed;
          errors[id] = e.failure.name;
        }
        continue;
      }
      if (now == null) {
        outcomes[id] = SourceOutcome.alreadyGone;
      } else if (_changed(now, o)) {
        outcomes[id] = SourceOutcome.keptChanged;
      } else {
        alive.add(now);
      }
    }
    final gone = <String>[];
    var declined = false;
    for (var i = 0; i < alive.length; i += chunk) {
      final part = alive.sublist(
        i,
        i + chunk > alive.length ? alive.length : i + chunk,
      );
      if (declined) {
        for (final f in part) {
          outcomes[f.id] = SourceOutcome.keptDeclined;
        }
        continue;
      }
      declined = await _lock.run(
        () => mode == DeleteMode.permanent
            ? _deletePermanently(part, outcomes, errors, gone)
            : _trash(part, outcomes, errors, gone),
      );
    }
    if (gone.isNotEmpty) {
      try {
        await _removeFromIndex(gone);
      } on Object catch (e) {
        developer.log('moved originals not unindexed: $e', name: 'kfm.move');
      }
    }
    return FinalizeResult(outcomes: outcomes, errors: errors);
  }

  /// Size differs, or the modified time moved by a second or more (some
  /// sources only keep seconds).
  static bool _changed(FileRef now, VerifiedOriginal o) =>
      now.sizeBytes != o.original.sizeBytes ||
      (now.modifiedAt.millisecondsSinceEpoch - o.modifiedAtMsAtCopy).abs() >=
          1000;

  /// Returns true when the user declined the dialog.
  Future<bool> _trash(
    List<FileRef> part,
    Map<String, SourceOutcome> outcomes,
    Map<String, String> errors,
    List<String> gone,
  ) async {
    try {
      final r = await _source.trashBatch(part);
      final trashed = {for (final t in r.trashed) t.original.id};
      for (final f in part) {
        if (trashed.contains(f.id)) {
          outcomes[f.id] = SourceOutcome.trashed;
          gone.add(f.id);
        } else if (r.removed.contains(f.id)) {
          // Q8: deleted directly (X1 shared-in copies, nothing to restore):
          // the original is gone, not kept.
          outcomes[f.id] = SourceOutcome.deletedPermanently;
          gone.add(f.id);
        } else if (r.userCancelled) {
          outcomes[f.id] = SourceOutcome.keptDeclined;
        } else {
          final e = r.failed[f.id];
          if (e?.failure == FileOpFailure.notFound) {
            outcomes[f.id] = SourceOutcome.alreadyGone;
            gone.add(f.id);
          } else {
            outcomes[f.id] = SourceOutcome.keptFailed;
            errors[f.id] = e?.failure.name ?? FileOpFailure.ioError.name;
          }
        }
      }
      return r.userCancelled;
    } on FileOpException catch (e) {
      final cancelled = e.failure == FileOpFailure.userCancelled;
      for (final f in part) {
        outcomes[f.id] = cancelled
            ? SourceOutcome.keptDeclined
            : SourceOutcome.keptFailed;
        if (!cancelled) errors[f.id] = e.failure.name;
      }
      return cancelled;
    }
  }

  Future<bool> _deletePermanently(
    List<FileRef> part,
    Map<String, SourceOutcome> outcomes,
    Map<String, String> errors,
    List<String> gone,
  ) async {
    try {
      await _source.deletePermanentlyBatch(part);
    } on FileOpException catch (e) {
      // Part of the batch may be gone before it threw.
      final cancelled = e.failure == FileOpFailure.userCancelled;
      for (final f in part) {
        if (await _isGone(f)) {
          outcomes[f.id] = SourceOutcome.deletedPermanently;
          gone.add(f.id);
        } else if (cancelled) {
          outcomes[f.id] = SourceOutcome.keptDeclined;
        } else {
          outcomes[f.id] = SourceOutcome.keptFailed;
          errors[f.id] = e.failure.name;
        }
      }
      return cancelled;
    }
    for (final f in part) {
      outcomes[f.id] = SourceOutcome.deletedPermanently;
      gone.add(f.id);
    }
    return false;
  }

  /// A failed stat counts as still there.
  Future<bool> _isGone(FileRef f) async {
    try {
      return await _source.stat(f.id) == null;
    } on FileOpException catch (e) {
      return e.failure == FileOpFailure.notFound;
    }
  }
}

/// One original on the other device (download-move), by its server id.
typedef RemoteOriginal = ({String serverId, String sha256, int sizeBytes});

/// How long the other device may take to hash the originals and wait for
/// its user's dialog.
const Duration kVerifiedMoveTrashTimeout = Duration(minutes: 10);

/// Download-move (TASK-N11): asks the other device to trash [originals]
/// with N7's `verifiedMove` reason, 500 ids per request. It re-hashes each
/// file and trashes only unchanged ones, after its own banner and system
/// dialog (never permanently). Outcomes are keyed by server id. Throws
/// when the first request can't reach the device (the caller keeps them
/// pending); a later chunk that fails is reported as `keptFailed`.
Future<FinalizeResult> trashRemoteOriginals(
  RemoteHttp http,
  List<RemoteOriginal> originals,
) async {
  final outcomes = <String, SourceOutcome>{};
  final errors = <String, String>{};
  const chunk = TrashRequestDto.kMaxTrashIds;
  var declined = false;
  for (var i = 0; i < originals.length; i += chunk) {
    final part = originals.sublist(
      i,
      i + chunk > originals.length ? originals.length : i + chunk,
    );
    if (declined) {
      for (final o in part) {
        outcomes[o.serverId] = SourceOutcome.keptDeclined;
      }
      continue;
    }
    final TrashResponseDto res;
    try {
      res = await http.postJson(
        ApiRoutes.filesTrash,
        TrashRequestDto(
          ids: [for (final o in part) o.serverId],
          reason: TrashReason.verifiedMove,
          sha256ById: {for (final o in part) o.serverId: o.sha256},
          sizeById: {for (final o in part) o.serverId: o.sizeBytes},
        ).toJson(),
        decode: TrashResponseDto.fromJson,
        timeout: kVerifiedMoveTrashTimeout,
      );
    } on RemoteApiException catch (e) {
      if (i == 0 && e.code == ApiErrorCode.unauthorized) rethrow;
      for (final o in part) {
        outcomes[o.serverId] = SourceOutcome.keptFailed;
        errors[o.serverId] = e.error.code;
      }
      continue;
    } on Object {
      if (i == 0) rethrow;
      for (final o in part) {
        outcomes[o.serverId] = SourceOutcome.keptFailed;
        errors[o.serverId] = 'unavailable';
      }
      continue;
    }
    final trashed = {for (final t in res.trashed) t.id};
    for (final o in part) {
      final id = o.serverId;
      final failure = res.failed[id];
      if (trashed.contains(id)) {
        outcomes[id] = SourceOutcome.trashed;
      } else if (failure == ApiErrorCode.verificationFailed.wire) {
        outcomes[id] = SourceOutcome.keptChanged;
      } else if (failure == ApiErrorCode.notFound.wire) {
        outcomes[id] = SourceOutcome.alreadyGone;
      } else if (failure != null) {
        outcomes[id] = SourceOutcome.keptFailed;
        errors[id] = failure;
      } else if (res.userCancelled) {
        outcomes[id] = SourceOutcome.keptDeclined;
      } else {
        outcomes[id] = SourceOutcome.keptFailed;
        errors[id] = ApiErrorCode.internal.wire;
      }
    }
    declined = res.userCancelled;
  }
  return FinalizeResult(outcomes: outcomes, errors: errors);
}
