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

  /// Asks once for write access to [files] where the platform needs it
  /// (Android 11+ media files without All files access / Media management:
  /// one system dialog per ≤500). False = declined. P3 calls this before a
  /// batch, so the renames don't each ask.
  Future<bool> requestWriteAccess(List<FileRef> files);

  /// B4: the file at [path], or null if nothing is there. Media known to
  /// MediaStore come back as `ms:` refs (so a Replace trashes them through
  /// the system trash), everything else as `path:`.
  Future<FileRef?> statPath(String path);

  /// B4: renames the folder at [folderPath] (not a volume root). Returns the
  /// new path and every file now inside it (ids may have changed: those are
  /// also announced on [idChanges]). Throws `targetExists`, `invalidName`,
  /// `permissionDenied` (no All files access).
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  );

  /// B4: free bytes on the volume holding [folderPath]; null when unknown.
  Future<int?> freeBytes(String folderPath);

  /// B5: makes files KFM just wrote with dart:io (zip / unzip) known to the
  /// platform (Android: MediaStore scan) and returns their refs (`ms:` when
  /// MediaStore indexed them, else `path:`). Missing paths are skipped. The
  /// caller adds the refs to the index (`MediaIndexer.addFiles`).
  Future<List<FileRef>> registerCreated(List<String> paths);

  /// Emitted whenever move/rename/restore gives a file a new id.
  Stream<FileIdChange> get idChanges;
}
