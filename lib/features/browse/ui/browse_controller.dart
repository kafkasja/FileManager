import 'dart:async';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browse_controller.g.dart';

/// B2: the stored Browse sort field.
@riverpod
Stream<FileSortField> browseSortField(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.browseSortField);

/// B2: the stored Browse sort direction.
@riverpod
Stream<bool> browseSortDescending(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.browseSortDescending);

/// What the Browse tab shows (TASK-B1). Kept while the tab is alive.
@riverpod
class BrowseViewController extends _$BrowseViewController {
  @override
  BrowseView build() {
    // B2: listen, don't watch: a settings event must never rebuild this
    // (that would reset the folder and filters). The stored sort applies on
    // the first stream event, a few ms after start.
    FileSort stored() => FileSort(
      ref.read(browseSortFieldProvider).value ?? FileSortField.date,
      descending: ref.read(browseSortDescendingProvider).value ?? true,
    );
    void apply(Object? _, Object? _) {
      if (ref.mounted) state = state.copyWith(sort: stored());
    }

    ref
      ..listen(browseSortFieldProvider, apply)
      ..listen(browseSortDescendingProvider, apply);
    return BrowseView(sort: stored());
  }

  /// B2: applies at once, then stored (write queue; failures surface on
  /// `dbWriteErrorsProvider`).
  void setSort(FileSort sort) {
    state = state.copyWith(sort: sort);
    final settings = ref.read(settingsRepositoryProvider);
    settings.write(AppSettings.browseSortField, sort.field).fireAndForget();
    settings
        .write(AppSettings.browseSortDescending, sort.descending)
        .fireAndForget();
  }

  /// Single-select; [add] (long-press) adds a second kind instead.
  void setKind(FileKind? kind, {bool add = false}) =>
      state = state.copyWith(kinds: toggleKind(state.kinds, kind, add: add));

  void setLayout(BrowseLayout layout) =>
      state = state.copyWith(layout: layout, folder: () => null);

  /// Folder mode: the folder to list (null = storage volumes).
  void openFolder(String? path) => state = state.copyWith(folder: () => path);

  void setShowHidden({required bool show}) =>
      state = state.copyWith(showHidden: show);
}

/// What a results list has loaded so far.
@immutable
class FilePagesState {
  const new({
    this.items = const [],
    this.next,
    this.loadingMore = false,
    this.unavailable = false,
    this.loadMoreError,
  });

  final List<FileRef> items;
  final IndexCursor? next;
  final bool loadingMore;

  /// Nothing of the query is visible without All files access.
  final bool unavailable;

  /// The last [FilePages.loadMore] failed (rule 8: shown with a retry).
  final Object? loadMoreError;

  bool get hasMore => next != null;

  FilePagesState copyWith({
    List<FileRef>? items,
    IndexCursor? Function()? next,
    bool? loadingMore,
    Object? Function()? loadMoreError,
  }) => FilePagesState(
    items: items ?? this.items,
    next: next == null ? this.next : next(),
    loadingMore: loadingMore ?? this.loadingMore,
    unavailable: unavailable,
    loadMoreError: loadMoreError == null ? this.loadMoreError : loadMoreError(),
  );
}

/// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
/// collections). Contract for B7's paged viewer: `items`, `hasMore`,
/// [loadMore]. Reloads (debounced) when the index changes, keeping as many
/// rows as were loaded so the scroll position holds.
@riverpod
class FilePages extends _$FilePages {
  static const pageSize = 200;

  int _generation = 0;
  IndexQuery? _visible;
  final _reload = Debouncer(const Duration(milliseconds: 300));

  bool _stale(int generation) =>
      generation != _generation || !ref.mounted || state.isLoading;

  @override
  Future<FilePagesState> build(IndexQuery query) async {
    _generation++;
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    ref
      ..listen(
        changesFor(query),
        (_, _) => _reload.run(() => unawaited(_reloadNow())),
      )
      ..onDispose(_reload.cancel);
    final visible = _visible = query.visible(canSeeAllFiles: canSeeAll);
    if (visible == null) return const FilePagesState(unavailable: true);
    final page = await ref.read(mediaIndexDaoProvider).page(visible);
    return FilePagesState(items: page.items, next: page.next);
  }

  Future<void> loadMore() async {
    final current = state.value;
    final visible = _visible;
    if (current == null ||
        visible == null ||
        !current.hasMore ||
        current.loadingMore ||
        state.isLoading) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreError: () => null),
    );
    try {
      final page = await ref
          .read(mediaIndexDaoProvider)
          .page(visible, after: current.next);
      if (_stale(generation)) return;
      final latest = state.value!;
      state = AsyncData(
        latest.copyWith(
          items: List.unmodifiable([...latest.items, ...page.items]),
          next: () => page.next,
          loadingMore: false,
        ),
      );
    } on Object catch (e) {
      if (_stale(generation)) return;
      state = AsyncData(
        state.value!.copyWith(loadingMore: false, loadMoreError: () => e),
      );
    }
  }

  Future<void> _reloadNow() async {
    final current = state.value;
    final visible = _visible;
    if (current == null || visible == null || state.isLoading) return;
    final generation = _generation;
    final dao = ref.read(mediaIndexDaoProvider);
    try {
      final items = <FileRef>[];
      IndexCursor? next;
      do {
        final page = await dao.page(visible, after: next);
        if (_stale(generation)) return;
        items.addAll(page.items);
        next = page.next;
      } while (next != null && items.length < current.items.length);
      state = AsyncData(
        FilePagesState(items: List.unmodifiable(items), next: next),
      );
    } on Object catch (e, st) {
      if (_stale(generation)) return;
      state = AsyncError(e, st);
    }
  }
}

/// How many files [query] shows now (chip counts). 0 when nothing of it is
/// visible without All files access. Refreshes with the index (debounced).
@riverpod
Future<int> browseCount(Ref ref, IndexQuery query) async {
  ref.watch(changesFor(query));
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = query.visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return 0;
  return await ref.watch(mediaIndexDaoProvider).count(visible);
}

/// Folder mode: child folders of [parent] (null = volumes) for [scope].
@riverpod
Future<List<FolderEntry>> browseFolders(
  Ref ref,
  IndexQuery scope, {
  String? parent,
}) async {
  ref.watch(mediaIndexChangesProvider);
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = scope.visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return const [];
  return await ref
      .watch(mediaIndexDaoProvider)
      .folders(parent: parent, scope: visible);
}

/// "Other" source: the folders holding files no rule recognised, by file
/// count (largest first). [scope] carries the type/hidden choice.
@riverpod
Future<List<FolderEntry>> otherFolders(Ref ref, IndexQuery scope) async {
  ref.watch(mediaIndexChangesProvider);
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = scope
      .copyWith(sources: {SourceBucket.none})
      .visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return const [];
  final summaries = await ref
      .watch(mediaIndexDaoProvider)
      .folderSummaries(scope: visible);
  return [for (final s in summaries) FolderEntry(s.path, s.count)]
    ..sort((a, b) => b.fileCount.compareTo(a.fileCount));
}

/// A carousel card's cover: the newest photo or video of [query], else its
/// newest file of any kind (shown as a type icon). Null = empty.
@riverpod
Future<FileRef?> collectionCover(Ref ref, IndexQuery query) async {
  ref.watch(changesFor(query));
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final dao = ref.watch(mediaIndexDaoProvider);
  final newest = query.copyWith(sort: FileSort.newestFirst);
  final visual = newest.kinds.isEmpty
      ? const {FileKind.image, FileKind.video}
      : newest.kinds.intersection(const {FileKind.image, FileKind.video});
  for (final q in [
    if (visual.isNotEmpty) newest.copyWith(kinds: visual),
    newest,
  ]) {
    final visible = q.visible(canSeeAllFiles: canSeeAll);
    if (visible == null) continue;
    final page = await dao.page(visible, limit: 1);
    if (page.items.isNotEmpty) return page.items.first;
  }
  return null;
}
