import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';

/// One folder the sharing device lets a client see (TASK-N4).
@immutable
class SharedRoot {
  const new({
    required this.id,
    required this.path,
    required this.label,
    required this.readOnly,
  });

  /// Stable opaque id (`PathGuard.rootId`).
  final String id;

  /// Canonical absolute path, '/'-separated, no trailing '/'.
  final String path;

  /// "Camera", "Downloads", or the folder name.
  final String label;

  /// True: no move/rename/trash/upload under it.
  final bool readOnly;

  SharedRoot withReadOnly({required bool readOnly}) =>
      SharedRoot(id: id, path: path, label: label, readOnly: readOnly);

  RootDto toDto() => RootDto(id: id, label: label, readOnly: readOnly);

  @override
  bool operator ==(Object other) =>
      other is SharedRoot &&
      other.id == id &&
      other.path == path &&
      other.label == label &&
      other.readOnly == readOnly;

  @override
  int get hashCode => Object.hash(id, path, label, readOnly);
}

/// The allow-list of one client. Empty = nothing visible.
@immutable
class ShareScope {
  const new(this.roots);

  static const ShareScope empty = ShareScope([]);

  final List<SharedRoot> roots;

  bool get isEmpty => roots.isEmpty;

  /// The root containing [canonicalPath], or null. Paths are always
  /// '/'-separated (FileRef.folderPath convention) and compared
  /// case-insensitively (Android shared storage is). With nested roots the
  /// deepest one wins, so a writable subfolder of a read-only root stays
  /// writable.
  SharedRoot? rootFor(String canonicalPath) {
    final path = canonicalPath.toLowerCase();
    SharedRoot? best;
    for (final r in roots) {
      final root = r.path.toLowerCase();
      if (path == root || path.startsWith(root == '/' ? '/' : '$root/')) {
        if (best == null || r.path.length > best.path.length) best = r;
      }
    }
    return best;
  }

  /// The root with [id], or null.
  SharedRoot? byId(String id) {
    for (final r in roots) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<RootDto> toDtos() => [for (final r in roots) r.toDto()];
}
