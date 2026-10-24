import 'package:flutter/foundation.dart' show setEquals;
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

const Set<FileKind> mediaKinds = {
  FileKind.image,
  FileKind.video,
  FileKind.audio,
};

/// A sorted, filtered view of the media index. P5 extends it with tag /
/// reviewed / screenshot predicates (single edit point: `_applyQuery` in
/// MediaIndexDao).
@immutable
class IndexQuery {
  const new({
    this.kinds = const {},
    this.folderPath,
    this.includeSubfolders = false,
    this.sort = FileSort.newestFirst,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.from,
    this.to,
    this.nameContains,
    this.mimePrefix,
    this.folderPaths = const {},
    this.screenshotsOnly = false,
    this.tagged,
    this.anyTagIds = const {},
    this.favoritesOnly = false,
  });

  /// Empty = all kinds.
  final Set<FileKind> kinds;
  final String? folderPath;
  final bool includeSubfolders;
  final FileSort sort;
  final int? minSizeBytes;
  final int? maxSizeBytes;

  /// sortDate >= from.
  final DateTime? from;

  /// sortDate < to.
  final DateTime? to;

  /// Case-insensitive substring of the name.
  final String? nameContains;

  /// e.g. 'video/'.
  final String? mimePrefix;

  /// P5: empty = any; exact folders, OR'ed.
  final Set<String> folderPaths;
  final bool screenshotsOnly;

  /// P5: null any · true ≥1 tag · false no tag.
  final bool? tagged;

  /// P5: non-empty = has at least one of these tags.
  final Set<int> anyTagIds;
  final bool favoritesOnly;

  static const all = IndexQuery();

  /// Without All files access only media is shown (non-media rows stay in
  /// the index). Returns null when nothing of [kinds] would be visible.
  IndexQuery? visible({required bool canSeeAllFiles}) {
    if (canSeeAllFiles) return this;
    final allowed = kinds.isEmpty ? mediaKinds : kinds.intersection(mediaKinds);
    if (allowed.isEmpty) return null;
    return copyWith(kinds: allowed);
  }

  IndexQuery copyWith({
    Set<FileKind>? kinds,
    String? folderPath,
    bool? includeSubfolders,
    FileSort? sort,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? from,
    DateTime? to,
    String? nameContains,
    String? mimePrefix,
    Set<String>? folderPaths,
    bool? screenshotsOnly,
    bool? tagged,
    Set<int>? anyTagIds,
    bool? favoritesOnly,
  }) => IndexQuery(
    kinds: kinds ?? this.kinds,
    folderPath: folderPath ?? this.folderPath,
    includeSubfolders: includeSubfolders ?? this.includeSubfolders,
    sort: sort ?? this.sort,
    minSizeBytes: minSizeBytes ?? this.minSizeBytes,
    maxSizeBytes: maxSizeBytes ?? this.maxSizeBytes,
    from: from ?? this.from,
    to: to ?? this.to,
    nameContains: nameContains ?? this.nameContains,
    mimePrefix: mimePrefix ?? this.mimePrefix,
    folderPaths: folderPaths ?? this.folderPaths,
    screenshotsOnly: screenshotsOnly ?? this.screenshotsOnly,
    tagged: tagged ?? this.tagged,
    anyTagIds: anyTagIds ?? this.anyTagIds,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is IndexQuery &&
      setEquals(other.kinds, kinds) &&
      other.folderPath == folderPath &&
      other.includeSubfolders == includeSubfolders &&
      other.sort.field == sort.field &&
      other.sort.descending == sort.descending &&
      other.minSizeBytes == minSizeBytes &&
      other.maxSizeBytes == maxSizeBytes &&
      other.from == from &&
      other.to == to &&
      other.nameContains == nameContains &&
      other.mimePrefix == mimePrefix &&
      setEquals(other.folderPaths, folderPaths) &&
      other.screenshotsOnly == screenshotsOnly &&
      other.tagged == tagged &&
      setEquals(other.anyTagIds, anyTagIds) &&
      other.favoritesOnly == favoritesOnly;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(kinds),
    folderPath,
    includeSubfolders,
    sort.field,
    sort.descending,
    minSizeBytes,
    maxSizeBytes,
    from,
    to,
    nameContains,
    mimePrefix,
    Object.hashAllUnordered(folderPaths),
    screenshotsOnly,
    tagged,
    Object.hashAllUnordered(anyTagIds),
    favoritesOnly,
  );
}

/// Position after the last item of a page: its sort value (epoch-ms, bytes or
/// lower-case name) and id, so the order is unique.
@immutable
class IndexCursor {
  const new(this.sortValue, this.id);

  final Object sortValue;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is IndexCursor && other.sortValue == sortValue && other.id == id;

  @override
  int get hashCode => Object.hash(sortValue, id);
}

@immutable
class IndexPage {
  const new(this.items, this.next);

  static const empty = IndexPage([], null);

  final List<FileRef> items;

  /// Null = end.
  final IndexCursor? next;
}
