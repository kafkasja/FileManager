import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

enum FileSortField { date, size, name }

@immutable
class FileSort {
  const new(this.field, {this.descending = true});

  final FileSortField field;
  final bool descending;

  static const newestFirst = FileSort(FileSortField.date);
}

/// Low-level query a platform can answer efficiently. Feature-level filters
/// (screenshots, reviewed, tags) are built on the F5 index, not here.
@immutable
class FileQuery {
  const new({
    this.kinds = const {},
    this.rootPath,
    this.recursive = true,
    this.modifiedAfter,
    this.minSizeBytes,
    this.includeHidden = false,
    this.sort = FileSort.newestFirst,
    this.pageSize = 500,
  });

  /// Empty = all kinds.
  final Set<FileKind> kinds;

  /// Null = all storage this source can see. Otherwise an absolute folder or
  /// volume root.
  final String? rootPath;
  final bool recursive;

  /// Incremental scan: only files changed after this instant (F5 uses it).
  final DateTime? modifiedAfter;
  final int? minSizeBytes;

  /// Dot-files/folders and folders with `.nomedia` are skipped unless true.
  final bool includeHidden;

  /// Best effort: on Android media arrive newest first and other files in
  /// walk order. Sorted views come from the F5 index.
  final FileSort sort;

  /// Results arrive in chunks of at most this size.
  final int pageSize;

  static const all = FileQuery();

  bool wants(FileKind kind) => kinds.isEmpty || kinds.contains(kind);
}
