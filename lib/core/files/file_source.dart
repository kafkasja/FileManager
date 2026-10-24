import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:meta/meta.dart';

/// A file got a new id (move/rename/restore). Tables keyed by fileId re-key
/// in the same transaction.
@immutable
class FileIdChange {
  const new(this.oldId, this.newRef);

  final String oldId;
  final FileRef newRef;

  @override
  String toString() => 'FileIdChange($oldId -> ${newRef.id})';
}

/// The only way features touch files. One implementation per kind of place
/// (device storage, external storage, remote device). Failures throw
/// `FileOpException`.
///
/// Name collisions on move/copy/rename never overwrite: ` (1)`, ` (2)`… is
/// appended before the extension.
abstract interface class FileSource {
  /// Emits pages of results until done. Never loads everything into one list.
  /// Cancelling the subscription stops the scan.
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all});

  /// Fresh metadata for one file, or null if it no longer exists.
  Future<FileRef?> stat(String id);

  /// Byte stream for preview / hashing / transfer (N9, N11, C2).
  Stream<List<int>> openRead(FileRef f);

  /// Creates [name] inside [parentPath] and returns its absolute path.
  /// Throws `targetExists` if it is already there.
  Future<String> createFolder(String parentPath, String name);

  /// Returns the new FileRef (the id may change!).
  Future<FileRef> move(FileRef f, String targetFolder);
  Future<FileRef> copy(FileRef f, String targetFolder);
  Future<FileRef> rename(FileRef f, String newName);

  Future<TrashResult> trashBatch(List<FileRef> files); // D3
  Future<void> deletePermanentlyBatch(List<FileRef> files); // D2
  Future<FileRef> restore(TrashedItem item); // D5

  /// Everything this source can show on the trash page (D3/D4/D5).
  Future<List<TrashedItem>> listTrashed();

  /// Restores several items; system-trash items in one dialog (D5).
  Future<RestoreResult> restoreBatch(List<TrashedItem> items);

  /// "Delete forever" from the trash page (D5). Declining the system
  /// dialog throws `userCancelled`.
  Future<void> deleteFromTrash(List<TrashedItem> items);

  /// Emitted whenever move/rename/restore gives a file a new id.
  Stream<FileIdChange> get idChanges;
}
