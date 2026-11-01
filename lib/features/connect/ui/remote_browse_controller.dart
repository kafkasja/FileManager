import 'dart:async';
import 'dart:math' as math;

import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_browse_controller.g.dart';

/// Where the remote browse screen is and how it lists (TASK-N7).
@immutable
class RemoteBrowseView {
  const new({
    this.rootId,
    this.path = '',
    this.sort = FileSort.newestFirst,
    this.kinds = const {},
  });

  /// Null = the shared roots (the root picker).
  final String? rootId;

  /// Relative to the root; `''` = the root itself.
  final String path;
  final FileSort sort;

  /// Empty = every kind.
  final Set<FileKind> kinds;

  bool get atRoots => rootId == null;

  /// The listing's remote `folderPath` (`'<rootId>[/<path>]'`).
  String? get folderPath => switch (rootId) {
    null => null,
    final root => remoteFolderPath(root, path),
  };

  RemoteQueryDto? get query => switch (rootId) {
    null => null,
    final root => RemoteQueryDto(
      rootId: root,
      path: path,
      kinds: kinds,
      sort: sort,
    ),
  };

  RemoteBrowseView copyWith({
    String? Function()? rootId,
    String? path,
    FileSort? sort,
    Set<FileKind>? kinds,
  }) => RemoteBrowseView(
    rootId: rootId == null ? this.rootId : rootId(),
    path: path ?? this.path,
    sort: sort ?? this.sort,
    kinds: kinds ?? this.kinds,
  );
}

/// What the remote browse screen has loaded.
@immutable
class RemoteBrowseState {
  const new({
    required this.view,
    this.folders = const [],
    this.items = const [],
    this.nextCursor,
    this.total,
    this.truncated = false,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final RemoteBrowseView view;
  final List<RemoteFolderDto> folders;
  final List<FileRef> items;
  final String? nextCursor;

  /// From the first page.
  final int? total;

  /// The other device stopped a page early (its query budget ran out).
  final bool truncated;
  final bool loadingMore;

  /// The last [RemoteBrowseController.loadMore] failed (shown with retry).
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;

  RemoteBrowseState copyWith({
    List<RemoteFolderDto>? folders,
    List<FileRef>? items,
    String? Function()? nextCursor,
    int? Function()? total,
    bool? truncated,
    bool? loadingMore,
    Object? Function()? loadMoreError,
  }) => RemoteBrowseState(
    view: view,
    folders: folders ?? this.folders,
    items: items ?? this.items,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    total: total == null ? this.total : total(),
    truncated: truncated ?? this.truncated,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError == null ? this.loadMoreError : loadMoreError(),
  );
}

/// Same files in the same order with the same visible facts.
bool sameRemoteItems(List<FileRef> a, List<FileRef> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final (x, y) = (a[i], b[i]);
    if (x.id != y.id ||
        x.modifiedAt != y.modifiedAt ||
        x.sizeBytes != y.sizeBytes ||
        x.name != y.name) {
      return false;
    }
  }
  return true;
}

bool _sameFolders(List<RemoteFolderDto> a, List<RemoteFolderDto> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].relativePath != b[i].relativePath ||
        a[i].name != b[i].name ||
        a[i].fileCount != b[i].fileCount) {
      return false;
    }
  }
  return true;
}

/// No automatic retry: the screen shows the error (or "not connected")
/// with its own retry, and reloads when the device connects again.
Duration? _noRetry(int retryCount, Object error) => null;

/// Pages one folder of a connected device (TASK-N7): roots → folders →
/// files, keyset paging through [RemoteFileSource.page], sort and type
/// filter. Live sync: when the heartbeat's change token changes, it
/// re-pages from the start up to the loaded count (at most
/// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
/// something differs, so the grid keeps its scroll position; a failed
/// refresh keeps the old items. Errors (also "not connected") are
/// `AsyncError` (rule 8).
@Riverpod(retry: _noRetry)
class RemoteBrowseController extends _$RemoteBrowseController {
  static const Duration refreshDelay = Duration(milliseconds: 500);
  static const int maxRefreshItems = 1000;

  RemoteBrowseView _view = const RemoteBrowseView();
  int _generation = 0;
  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _refreshAgain = false;

  /// Where the screen is (also while a load is running).
  RemoteBrowseView currentView() => _view;

  RemoteFileSource get _source =>
      ref.read(remoteSourceProvider(peerFingerprint));

  @override
  Future<RemoteBrowseState> build(String peerFingerprint) async {
    final connected = ref.watch(remotePeerConnectedProvider(peerFingerprint));
    ref
      ..listen(remoteChangeTokenProvider, (prev, next) {
        if (prev != null && next != null && prev != next) _scheduleRefresh();
      })
      ..onDispose(() => _refreshTimer?.cancel());
    final generation = ++_generation;
    if (!connected) {
      throw const FileOpException(
        FileOpFailure.unavailable,
        'device not connected',
      );
    }
    final loaded = await _fetch(_view);
    if (generation != _generation) {
      // A navigation started meanwhile; its own result lands later.
      return state.value ?? loaded;
    }
    return loaded;
  }

  Future<RemoteBrowseState> _fetch(RemoteBrowseView v) async {
    final q = v.query;
    if (q == null) return RemoteBrowseState(view: v);
    final source = _source;
    final foldersF = source.folders(q.rootId, path: q.path);
    // Both requests run at once; an error of either fails the load.
    unawaited(foldersF.then<void>((_) {}, onError: (Object _) {}));
    final page = await source.page(q);
    final folders = await foldersF;
    return RemoteBrowseState(
      view: v,
      folders: List.unmodifiable(folders),
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total,
      truncated: page.truncated,
    );
  }

  Future<void> _go(RemoteBrowseView v) async {
    _view = v;
    final generation = ++_generation;
    _refreshTimer?.cancel();
    state = const AsyncLoading<RemoteBrowseState>();
    final next = await AsyncValue.guard(() => _fetch(v));
    if (generation != _generation || !ref.mounted) return;
    state = next;
  }

  /// Opens a shared root (null = back to the roots).
  Future<void> openRoot(String? rootId) =>
      _go(_view.copyWith(rootId: () => rootId, path: ''));

  /// Opens [relativePath] inside the current root.
  Future<void> openFolder(String relativePath) =>
      _go(_view.copyWith(path: relativePath));

  /// One level up; false when already at the roots.
  bool up() {
    if (_view.atRoots) return false;
    final p = _view.path;
    if (p.isEmpty) {
      unawaited(openRoot(null));
    } else {
      final slash = p.lastIndexOf('/');
      unawaited(openFolder(slash < 0 ? '' : p.substring(0, slash)));
    }
    return true;
  }

  Future<void> setSort(FileSort sort) => _go(_view.copyWith(sort: sort));

  /// Single-select; [add] (long-press) adds a second kind.
  Future<void> setKind(FileKind? kind, {bool add = false}) =>
      _go(_view.copyWith(kinds: toggleKind(_view.kinds, kind, add: add)));

  /// Retry after an error.
  Future<void> reload() => _go(_view);

  Future<void> loadMore() async {
    final current = state.value;
    final q = _view.query;
    if (current == null ||
        q == null ||
        !current.hasMore ||
        current.loadingMore ||
        _refreshing ||
        state.isLoading) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreError: () => null),
    );
    try {
      final page = await _source.page(q, cursor: current.nextCursor);
      if (generation != _generation || !ref.mounted) return;
      final latest = state.value!;
      state = AsyncData(
        latest.copyWith(
          items: List.unmodifiable([...latest.items, ...page.items]),
          nextCursor: () => page.nextCursor,
          truncated: page.truncated,
          loadingMore: false,
        ),
      );
    } on Object catch (e) {
      if (generation != _generation || !ref.mounted) return;
      state = AsyncData(
        state.value!.copyWith(loadingMore: false, loadMoreError: () => e),
      );
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(refreshDelay, () => unawaited(refresh()));
  }

  /// Live sync: re-reads the folders and the loaded pages; no state change
  /// when nothing differs, old items kept on error.
  @visibleForTesting
  Future<void> refresh() async {
    final current = state.value;
    final q = _view.query;
    if (current == null || q == null || state.isLoading) return;
    if (_refreshing || current.loadingMore) {
      _refreshAgain = true;
      if (!_refreshing) _scheduleRefresh();
      return;
    }
    _refreshing = true;
    _refreshAgain = false;
    final generation = _generation;
    try {
      final source = _source;
      final foldersF = source.folders(q.rootId, path: q.path);
      unawaited(foldersF.then<void>((_) {}, onError: (Object _) {}));
      final want = math.min(math.max(current.items.length, 1), maxRefreshItems);
      final items = <FileRef>[];
      String? cursor;
      int? total;
      var truncated = false;
      var first = true;
      do {
        final page = await source.page(q, cursor: cursor);
        if (first) total = page.total;
        first = false;
        items.addAll(page.items);
        cursor = page.nextCursor;
        truncated = page.truncated;
      } while (cursor != null && items.length < want);
      final folders = await foldersF;
      if (generation != _generation || !ref.mounted) return;
      final latest = state.value;
      if (latest == null) return;
      if (sameRemoteItems(latest.items, items) &&
          _sameFolders(latest.folders, folders) &&
          latest.hasMore == (cursor != null) &&
          (total == null || latest.total == total)) {
        return;
      }
      state = AsyncData(
        latest.copyWith(
          folders: List.unmodifiable(folders),
          items: List.unmodifiable(items),
          nextCursor: () => cursor,
          total: () => total ?? latest.total,
          truncated: truncated,
          loadMoreError: () => null,
        ),
      );
    } on Object {
      // Live sync is best effort: the old items stay (the heartbeat reports
      // a lost connection, the next token change tries again).
    } finally {
      _refreshing = false;
      if (_refreshAgain && ref.mounted) _scheduleRefresh();
    }
  }

  void _edit(List<FileRef> Function(List<FileRef> items) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(items: List.unmodifiable(change(current.items))),
    );
  }

  /// Renames [f] on the other device; the list shows the new name at once.
  Future<FileRef> rename(FileRef f, String newName) async {
    final renamed = await _source.rename(f, newName);
    _edit(
      (items) => [
        for (final i in items)
          if (i.id == f.id) renamed else i,
      ],
    );
    return renamed;
  }

  /// Moves [files] into [targetFolder] (a remote `folderPath`). Files that
  /// leave this folder leave the list. Returns the failures by file id.
  Future<Map<String, Object>> move(
    List<FileRef> files,
    String targetFolder,
  ) async {
    final failed = <String, Object>{};
    final moved = <String, FileRef>{};
    for (final f in files) {
      try {
        moved[f.id] = await _source.move(f, targetFolder);
      } on FileOpException catch (e) {
        failed[f.id] = e;
        if (e.failure == FileOpFailure.unavailable) break;
      }
    }
    final here = _view.folderPath;
    _edit(
      (items) => [
        for (final i in items)
          if (moved[i.id] == null)
            i
          else if (moved[i.id]!.folderPath == here)
            moved[i.id]!,
      ],
    );
    return failed;
  }

  /// Copies [files] into [targetFolder]; a copy into this folder shows up
  /// with the next refresh.
  Future<Map<String, Object>> copy(
    List<FileRef> files,
    String targetFolder,
  ) async {
    final failed = <String, Object>{};
    for (final f in files) {
      try {
        await _source.copy(f, targetFolder);
      } on FileOpException catch (e) {
        failed[f.id] = e;
        if (e.failure == FileOpFailure.unavailable) break;
      }
    }
    if (targetFolder == _view.folderPath) unawaited(refresh());
    return failed;
  }

  /// Asks the other device to move [files] to its trash (its own dialog
  /// may show there). Trashed files leave the list at once.
  Future<TrashResult> trash(List<FileRef> files) async {
    final result = await _source.trashBatch(files);
    final gone = {for (final t in result.trashed) t.original.id};
    // "No longer available": gone already, so gone from the list too.
    for (final MapEntry(:key, :value) in result.failed.entries) {
      if (value.failure == FileOpFailure.notFound) gone.add(key);
    }
    if (gone.isNotEmpty) {
      _edit(
        (items) => [
          for (final i in items)
            if (!gone.contains(i.id)) i,
        ],
      );
    }
    return result;
  }

  /// Drops [id] from the list (opened file was gone on the other device).
  void removeGone(String id) => _edit(
    (items) => [
      for (final i in items)
        if (i.id != id) i,
    ],
  );
}
