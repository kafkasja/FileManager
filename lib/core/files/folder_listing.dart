import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

/// A sub-folder in a [FolderListing] (TASK-U2). [id] is what the source
/// takes back as a folder: a path (SAF) or an `mtp:` folder id.
@immutable
class FolderItem {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FolderItem && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// One folder's direct children.
@immutable
class FolderListing {
  const new({required this.folders, required this.files});

  static const empty = FolderListing(folders: [], files: []);

  final List<FolderItem> folders;
  final List<FileRef> files;
}

/// Sources browsed by scanning (SAF, MTP): not in the F5 index.
abstract interface class BrowsableSource {
  /// The children of [folder]; hidden ones only with [includeHidden].
  Future<FolderListing> listChildren(String folder, {bool includeHidden});
}

/// Sources that copy a file into a local path natively (SAF, MTP): faster
/// than streaming [FileRef] bytes through a platform channel.
abstract interface class CopiesOut {
  /// Writes [f] to the local file [path]. Returns its SHA-256 when the
  /// platform computed it on the way (else null).
  Future<String?> copyOut(FileRef f, String path);
}

/// Sources that hash a file natively (off the UI isolate).
abstract interface class HashesNatively {
  Future<String> sha256Of(FileRef f);
}
