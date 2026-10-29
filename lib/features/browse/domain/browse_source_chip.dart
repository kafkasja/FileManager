import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:meta/meta.dart';

/// The source cards on the All files page (TASK-B1), in display order.
/// Cards with no files are hidden, so a user without Snapchat never sees
/// "Snapchat".
enum BrowseSourceChip {
  camera,
  screenshots,
  whatsapp,
  snapchat,
  downloads,
  videos,
  panoramas,
  screenRecordings,
  expertRaw,
  gifs,
  collages,
  clippedImages,
  liveMessages,
  videoCaptures,
  telegram,
  instagram,
  other,
  hidden;

  /// This source's files on top of [base] (its kinds, sort and hidden choice).
  IndexQuery apply(IndexQuery base) => switch (this) {
    camera => base.copyWith(sources: {SourceBucket.camera}),
    screenshots => base.copyWith(sources: {SourceBucket.screenshots}),
    whatsapp => base.copyWith(sources: {SourceBucket.whatsapp}),
    snapchat => base.copyWith(sources: {SourceBucket.snapchat}),
    downloads => base.copyWith(sources: {SourceBucket.downloads}),
    // A shortcut for the Videos type filter, not a bucket.
    videos => base.copyWith(kinds: {FileKind.video}),
    panoramas => base.copyWith(panoramaOnly: true),
    screenRecordings => base.copyWith(sources: {SourceBucket.screenRecordings}),
    expertRaw => base.copyWith(sources: {SourceBucket.expertRaw}),
    gifs => base.copyWith(sources: {SourceBucket.gifs}),
    collages => base.copyWith(sources: {SourceBucket.collages}),
    clippedImages => base.copyWith(sources: {SourceBucket.clippedImages}),
    liveMessages => base.copyWith(sources: {SourceBucket.liveMessages}),
    videoCaptures => base.copyWith(sources: {SourceBucket.videoCaptures}),
    telegram => base.copyWith(sources: {SourceBucket.telegram}),
    instagram => base.copyWith(sources: {SourceBucket.instagram}),
    other => base.copyWith(sources: {SourceBucket.none}),
    hidden => base.copyWith(hidden: HiddenFilter.only),
  };

  /// Only (or mostly) there with All files access: shown without it, so
  /// opening it explains why it's empty.
  bool get needsAllFiles => this == hidden || this == downloads;
}

/// What a carousel card opens: a source, or a recent search.
@immutable
sealed class BrowseCollection {
  const new();

  /// The files, before the page's own type chips and the global sort.
  IndexQuery get query;
}

class SourceCollection extends BrowseCollection {
  const new(this.source);

  final BrowseSourceChip source;

  @override
  IndexQuery get query => source.apply(IndexQuery.all);

  @override
  bool operator ==(Object other) =>
      other is SourceCollection && other.source == source;

  @override
  int get hashCode => source.hashCode;
}

class RecentCollection extends BrowseCollection {
  const new(this.search);

  final RecentSearch search;

  @override
  IndexQuery get query => search.query;

  @override
  bool operator ==(Object other) =>
      other is RecentCollection &&
      other.search.query == search.query &&
      other.search.title == search.title;

  @override
  int get hashCode => Object.hash(search.query, search.title);
}

/// Type chips: a tap selects only [kind] (again: all), [add] (long-press)
/// toggles it next to the others; null = all.
Set<FileKind> toggleKind(
  Set<FileKind> current,
  FileKind? kind, {
  bool add = false,
}) {
  if (kind == null) return const {};
  if (add) {
    return Set.unmodifiable(
      current.contains(kind)
          ? ({...current}..remove(kind))
          : {...current, kind},
    );
  }
  return current.length == 1 && current.contains(kind) ? const {} : {kind};
}

/// What the Browse tab's main page shows. Immutable; [query] is what gets
/// paged.
@immutable
class BrowseView {
  const new({
    this.kinds = const {},
    this.folderMode = false,
    this.folder,
    this.showHidden = false,
    this.sort = FileSort.newestFirst,
  });

  /// Empty = all kinds.
  final Set<FileKind> kinds;

  /// Folders (breadcrumb + folder list) instead of one flat list.
  final bool folderMode;

  /// Folder mode: the folder whose files are listed.
  final String? folder;

  /// "Show hidden files" (not persisted).
  final bool showHidden;

  /// B2: one sort for every Browse page (stored).
  final FileSort sort;

  IndexQuery get query {
    final q = IndexQuery(
      kinds: kinds,
      sort: sort,
      hidden: showHidden ? HiddenFilter.include : HiddenFilter.exclude,
    );
    final f = folder;
    return f == null ? q : q.copyWith(folderPath: () => f);
  }

  BrowseView copyWith({
    Set<FileKind>? kinds,
    bool? folderMode,
    String? Function()? folder,
    bool? showHidden,
    FileSort? sort,
  }) => BrowseView(
    kinds: kinds ?? this.kinds,
    folderMode: folderMode ?? this.folderMode,
    folder: folder == null ? this.folder : folder(),
    showHidden: showHidden ?? this.showHidden,
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is BrowseView &&
      other.kinds.length == kinds.length &&
      other.kinds.containsAll(kinds) &&
      other.folderMode == folderMode &&
      other.folder == folder &&
      other.showHidden == showHidden &&
      other.sort.field == sort.field &&
      other.sort.descending == sort.descending;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(kinds),
    folderMode,
    folder,
    showHidden,
    sort.field,
    sort.descending,
  );
}
