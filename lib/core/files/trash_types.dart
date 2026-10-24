import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

enum TrashLocation { systemTrash, pendingFolder, recentlyDeletedLinkOnly }

@immutable
class TrashedItem {
  const new({
    required this.trashId,
    required this.original,
    required this.location,
    required this.trashedAt,
    this.expiresAt,
  });

  factory fromJson(Map<String, Object?> j) => TrashedItem(
    trashId: j['trashId']! as String,
    original: FileRef.fromJson((j['original']! as Map).cast<String, Object?>()),
    location: TrashLocation.values.byName(j['location']! as String),
    trashedAt: DateTime.fromMillisecondsSinceEpoch(
      j['trashedAt']! as int,
      isUtc: true,
    ),
    expiresAt: j['expiresAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            j['expiresAt']! as int,
            isUtc: true,
          ),
  );

  /// Platform id inside the trash: `ms:<id>` (Android IS_TRASHED row),
  /// `pending:<rowId>` (D4 folder), Windows recycle-bin parse name (PL1).
  final String trashId;

  /// FileRef as it was before trashing (path, name), needed to restore.
  final FileRef original;
  final TrashLocation location;
  final DateTime trashedAt;
  final DateTime? expiresAt;

  /// Stored in `session_actions.previousState` so undo can restore (S2).
  Map<String, Object?> toJson() => {
    'trashId': trashId,
    'original': original.toJson(),
    'location': location.name,
    'trashedAt': trashedAt.millisecondsSinceEpoch,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
  };
}

@immutable
class TrashResult {
  const new({
    required this.trashed,
    required this.failed,
    this.userCancelled = false,
  });

  final List<TrashedItem> trashed;

  /// Keyed by FileRef.id.
  final Map<String, FileOpException> failed;

  /// The user declined the single system confirmation dialog for the batch.
  final bool userCancelled;

  bool get allSucceeded => failed.isEmpty && !userCancelled;
}

@immutable
class RestoreResult {
  const new({
    required this.restored,
    required this.failed,
    this.userCancelled = false,
  });

  /// Restored files, keyed by TrashedItem.trashId.
  final Map<String, FileRef> restored;

  /// Keyed by TrashedItem.trashId (e.g. already expired → notFound).
  final Map<String, FileOpException> failed;

  /// The user declined the system dialog: nothing in that group restored.
  final bool userCancelled;
}
