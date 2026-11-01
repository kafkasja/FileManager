import 'package:flutter/foundation.dart' show setEquals;
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:meta/meta.dart';

const Set<FileKind> mediaKinds = {
  FileKind.image,
  FileKind.video,
  FileKind.audio,
};

/// P7: only files (not) reviewed in a preset (0 = Basic).
@immutable
class ReviewedClause {
  const new({required this.presetKey, required this.reviewed});

  final int presetKey;

  /// true = only reviewed files, false = only not-reviewed files.
  final bool reviewed;

  @override
  bool operator ==(Object other) =>
      other is ReviewedClause &&
      other.presetKey == presetKey &&
      other.reviewed == reviewed;

  @override
  int get hashCode => Object.hash(presetKey, reviewed);
}

/// B1: hidden files (dot-files/folders, `.nomedia` folders).
enum HiddenFilter {
  /// Default: every existing view (swipe deck, counts) stays as it was.
  exclude,
  include,
  only,
}

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
    this.reviewed,
    this.sources = const {},
    this.hidden = HiddenFilter.exclude,
    this.extensions = const {},
    this.panoramaOnly = false,
    this.smartGroupId,
    this.selfiesOnly = false,
    this.documentsGroup = false,
    this.labelTerms = const [],
    this.blurryOnly = false,
    this.blurThreshold,
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

  /// P7; null = no reviewed predicate.
  final ReviewedClause? reviewed;

  /// B1: empty = any source; OR'ed (e.g. {whatsapp, telegram}).
  final Set<SourceBucket> sources;

  /// B1: hidden files are left out unless asked for.
  final HiddenFilter hidden;

  /// B1: lower-case extensions without the dot, OR'ed. Empty = any (B8).
  final Set<String> extensions;

  /// B1: best-effort panoramas (`PANO_…` names or ≥ 2:1 images).
  final bool panoramaOnly;

  /// C5: only files in this stored smart group (EXISTS on smart_group_items).
  final int? smartGroupId;

  /// C5: Selfies rule (folder `…/Selfies` or EXIF front camera).
  final bool selfiesOnly;

  /// C5: documents, plus images C3 labeled 'document'.
  final bool documentsGroup;

  /// C4: AI label terms. Each inner set is one typed term (its labels
  /// OR'ed); the terms are AND'ed: "blue beach" → [{'color:blue'},
  /// {'beach'}]. Non-empty implies kind = image.
  final List<Set<String>> labelTerms;

  /// C4: only images C2 measured as blurry (C2's shared blur predicate with
  /// [blurThreshold]). Implies kind = image.
  final bool blurryOnly;

  /// C2's `similar.blurThreshold`, set together with [blurryOnly] (the DAO
  /// never reads settings). Null with [blurryOnly] = matches nothing.
  final int? blurThreshold;

  /// C4: a content (AI label or blur) predicate is present.
  bool get hasContentTerms => labelTerms.isNotEmpty || blurryOnly;

  static const all = IndexQuery();

  /// Without All files access only media is shown (non-media rows stay in
  /// the index). Returns null when nothing of [kinds] would be visible.
  IndexQuery? visible({required bool canSeeAllFiles}) {
    if (canSeeAllFiles) return this;
    // Hidden files are only indexed with All files access.
    if (hidden == HiddenFilter.only) return null;
    final allowed = kinds.isEmpty ? mediaKinds : kinds.intersection(mediaKinds);
    if (allowed.isEmpty) return null;
    return copyWith(kinds: allowed);
  }

  /// Nullable fields take a function so they can be cleared:
  /// `copyWith(folderPath: () => null)`.
  IndexQuery copyWith({
    Set<FileKind>? kinds,
    String? Function()? folderPath,
    bool? includeSubfolders,
    FileSort? sort,
    int? Function()? minSizeBytes,
    int? Function()? maxSizeBytes,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? Function()? nameContains,
    String? Function()? mimePrefix,
    Set<String>? folderPaths,
    bool? screenshotsOnly,
    bool? Function()? tagged,
    Set<int>? anyTagIds,
    bool? favoritesOnly,
    ReviewedClause? Function()? reviewed,
    Set<SourceBucket>? sources,
    HiddenFilter? hidden,
    Set<String>? extensions,
    bool? panoramaOnly,
    int? Function()? smartGroupId,
    bool? selfiesOnly,
    bool? documentsGroup,
    List<Set<String>>? labelTerms,
    bool? blurryOnly,
    int? Function()? blurThreshold,
  }) => IndexQuery(
    kinds: kinds ?? this.kinds,
    folderPath: folderPath == null ? this.folderPath : folderPath(),
    includeSubfolders: includeSubfolders ?? this.includeSubfolders,
    sort: sort ?? this.sort,
    minSizeBytes: minSizeBytes == null ? this.minSizeBytes : minSizeBytes(),
    maxSizeBytes: maxSizeBytes == null ? this.maxSizeBytes : maxSizeBytes(),
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    nameContains: nameContains == null ? this.nameContains : nameContains(),
    mimePrefix: mimePrefix == null ? this.mimePrefix : mimePrefix(),
    folderPaths: folderPaths ?? this.folderPaths,
    screenshotsOnly: screenshotsOnly ?? this.screenshotsOnly,
    tagged: tagged == null ? this.tagged : tagged(),
    anyTagIds: anyTagIds ?? this.anyTagIds,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    reviewed: reviewed == null ? this.reviewed : reviewed(),
    sources: sources ?? this.sources,
    hidden: hidden ?? this.hidden,
    extensions: extensions ?? this.extensions,
    panoramaOnly: panoramaOnly ?? this.panoramaOnly,
    smartGroupId: smartGroupId == null ? this.smartGroupId : smartGroupId(),
    selfiesOnly: selfiesOnly ?? this.selfiesOnly,
    documentsGroup: documentsGroup ?? this.documentsGroup,
    labelTerms: labelTerms ?? this.labelTerms,
    blurryOnly: blurryOnly ?? this.blurryOnly,
    blurThreshold: blurThreshold == null ? this.blurThreshold : blurThreshold(),
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
      other.favoritesOnly == favoritesOnly &&
      other.reviewed == reviewed &&
      setEquals(other.sources, sources) &&
      other.hidden == hidden &&
      setEquals(other.extensions, extensions) &&
      other.panoramaOnly == panoramaOnly &&
      other.smartGroupId == smartGroupId &&
      other.selfiesOnly == selfiesOnly &&
      other.documentsGroup == documentsGroup &&
      _termsEqual(other.labelTerms, labelTerms) &&
      other.blurryOnly == blurryOnly &&
      other.blurThreshold == blurThreshold;

  static bool _termsEqual(List<Set<String>> a, List<Set<String>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!setEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
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
    reviewed,
    Object.hashAllUnordered(sources),
    hidden,
    Object.hashAllUnordered(extensions),
    panoramaOnly,
    smartGroupId,
    selfiesOnly,
    documentsGroup,
    Object.hashAll(labelTerms.map(Object.hashAllUnordered)),
    blurryOnly,
    blurThreshold,
  ]);
}

/// B1: a folder in Browse's folder mode, with how many files of the current
/// view are in it (subfolders included).
@immutable
class FolderEntry {
  const new(this.path, this.fileCount);

  /// Absolute, no trailing '/'.
  final String path;
  final int fileCount;

  String get name => path.substring(path.lastIndexOf('/') + 1);

  @override
  bool operator ==(Object other) =>
      other is FolderEntry &&
      other.path == path &&
      other.fileCount == fileCount;

  @override
  int get hashCode => Object.hash(path, fileCount);
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
