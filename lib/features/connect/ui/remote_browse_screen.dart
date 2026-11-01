import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/browse/ui/widgets/sort_sheet.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_browse_controller.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// What a remote file operation failure shows (N7 error table).
String remoteFailureText(AppLocalizations l10n, Object? error, String device) =>
    switch (error) {
      FileOpException(failure: FileOpFailure.notFound) => l10n.remoteFileGone,
      FileOpException(failure: FileOpFailure.permissionDenied) =>
        l10n.remoteNotAllowed(device),
      FileOpException(failure: FileOpFailure.invalidName) => l10n.nameInvalid,
      FileOpException(failure: FileOpFailure.userCancelled) =>
        l10n.remoteDeclined(device),
      FileOpException(failure: FileOpFailure.unavailable) =>
        l10n.remoteDeviceNotConnected(device),
      _ => l10n.browseLoadError,
    };

/// Browse a connected device's shared folders (TASK-N7): roots → folders →
/// a grid of B1's tiles, sort and type chips, the paged viewer, and
/// Rename / Move / Copy / Move to trash on a long-press selection (write
/// actions only in writable roots). Live sync through
/// [RemoteBrowseController].
class RemoteBrowseScreen extends ConsumerStatefulWidget {
  const new({required this.peerFingerprint, super.key});

  final String peerFingerprint;

  @override
  ConsumerState<RemoteBrowseScreen> createState() => _RemoteBrowseScreenState();
}

class _RemoteBrowseScreenState extends ConsumerState<RemoteBrowseScreen> {
  /// Long-press selection, local to this screen (ids).
  Set<String> _selected = const {};

  String get _fp => widget.peerFingerprint;

  RemoteBrowseController get _controller =>
      ref.read(remoteBrowseControllerProvider(_fp).notifier);

  void _toggle(FileRef f) => setState(() {
    final next = {..._selected};
    if (!next.remove(f.id)) next.add(f.id);
    _selected = next;
  });

  void _clearSelection() => setState(() => _selected = const {});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connection = ref.watch(remoteConnectionControllerProvider);
    final (name, roots, connected) = switch (connection) {
      RemoteConnected(:final peerName, :final peerFingerprint, :final roots)
          when peerFingerprint == _fp =>
        (peerName, roots, true),
      RemoteDisconnected(:final peerName) => (
        peerName,
        const <RootDto>[],
        false,
      ),
      _ => ('', const <RootDto>[], false),
    };
    final async = ref.watch(remoteBrowseControllerProvider(_fp));
    final view = _controller.currentView();
    final root = roots.where((r) => r.id == view.rootId).firstOrNull;
    final writable = root != null && !root.readOnly;
    final items = async.value?.items ?? const <FileRef>[];
    final selected = [
      for (final f in items)
        if (_selected.contains(f.id)) f,
    ];
    final selecting = selected.isNotEmpty;

    final unavailable = switch (async.error) {
      FileOpException(failure: FileOpFailure.unavailable) => true,
      _ => false,
    };
    final Widget body;
    if (!connected || unavailable) {
      body = _Disconnected(name: name);
    } else if (view.atRoots) {
      body = _RootList(
        roots: roots,
        name: name,
        onOpen: (r) => unawaited(_controller.openRoot(r.id)),
      );
    } else {
      body = _FolderBody(
        peerFingerprint: _fp,
        device: name,
        view: view,
        async: async,
        selected: _selected,
        onTapFile: (f, inList) => selecting ? _toggle(f) : _open(f, inList),
        onLongPressFile: _toggle,
      );
    }

    final title = switch ((root, view.path)) {
      (null, _) => name,
      (final r?, '') => r.label,
      (_, final p) => p.substring(p.lastIndexOf('/') + 1),
    };

    return PopScope(
      canPop: !selecting && view.atRoots,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selecting) {
          _clearSelection();
        } else {
          _controller.up();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: selecting
              ? IconButton(
                  tooltip: l10n.selectionExit,
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          title: Text(
            selecting ? l10n.selectionViewTitle(selected.length) : title,
          ),
          actions: [
            if (selecting) ...[
              if (writable && selected.length == 1)
                IconButton(
                  tooltip: l10n.fileMenuRename,
                  icon: const Icon(Icons.drive_file_rename_outline),
                  onPressed: () => unawaited(_rename(selected.single, name)),
                ),
              if (writable)
                IconButton(
                  tooltip: l10n.swipeActionTrash,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => unawaited(_trash(selected, name)),
                ),
              PopupMenuButton<bool>(
                onSelected: (move) =>
                    unawaited(_moveOrCopy(selected, name, roots, move: move)),
                itemBuilder: (_) => [
                  if (writable)
                    PopupMenuItem(
                      value: true,
                      child: Text(l10n.selectionActionMove),
                    ),
                  PopupMenuItem(
                    value: false,
                    child: Text(l10n.selectionActionCopy),
                  ),
                ],
              ),
            ] else if (connected && !view.atRoots)
              _SortButton(
                sort: view.sort,
                onSort: (s) => unawaited(_controller.setSort(s)),
              ),
          ],
        ),
        body: SafeArea(child: body),
      ),
    );
  }

  Future<void> _open(FileRef f, List<FileRef> loaded) async {
    if (!f.isMedia) {
      await showFileDetails(context, f);
      return;
    }
    final source = _RemoteViewerSource(
      ProviderScope.containerOf(context, listen: false),
      _fp,
    );
    final index = source.items.indexWhere((i) => i.id == f.id);
    try {
      await openPagedViewer(
        context,
        source: source,
        initialIndex: index < 0 ? 0 : index,
        otherPage: (_, file) => FileDetailsList(file: file),
      );
    } finally {
      source.dispose();
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _rename(FileRef f, String device) async {
    final l10n = context.l10n;
    final newName = await showNameDialog(
      context,
      title: l10n.fileMenuRename,
      action: l10n.renameAction,
      initial: f.name,
      selectBaseName: true,
    );
    if (newName == null || newName == f.name || !mounted) return;
    try {
      await _controller.rename(f, newName);
      _clearSelection();
    } on Object catch (e) {
      _snack(remoteFailureText(l10n, e, device));
    }
  }

  Future<void> _trash(List<FileRef> files, String device) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.remoteTrashConfirm(files.length, device)),
        content: Text(l10n.remoteTrashConfirmHint(device)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.swipeActionTrash),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final result = await _controller.trash(files);
      _clearSelection();
      if (result.userCancelled) {
        _snack(l10n.remoteDeleteDeclined(device));
      } else if (result.failed.isNotEmpty) {
        _snack(l10n.remoteSomeFailed(result.failed.length));
      } else {
        _snack(l10n.remoteTrashed(result.trashed.length, device));
      }
    } on Object catch (e) {
      _snack(remoteFailureText(l10n, e, device));
    }
  }

  Future<void> _moveOrCopy(
    List<FileRef> files,
    String device,
    List<RootDto> roots, {
    required bool move,
  }) async {
    final l10n = context.l10n;
    final target = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RemoteFolderPicker(
        source: ref.read(remoteSourceProvider(_fp)),
        device: device,
        roots: [
          for (final r in roots)
            if (!r.readOnly) r,
        ],
      ),
    );
    if (target == null || !mounted) return;
    final failed = move
        ? await _controller.move(files, target)
        : await _controller.copy(files, target);
    if (!mounted) return;
    _clearSelection();
    final done = files.length - failed.length;
    if (failed.isEmpty) {
      _snack(move ? l10n.remoteMoved(done) : l10n.remoteCopied(done));
    } else if (failed.length == 1) {
      _snack(remoteFailureText(l10n, failed.values.single, device));
    } else {
      _snack(l10n.remoteSomeFailed(failed.length));
    }
  }
}

class _SortButton extends StatelessWidget {
  const new({required this.sort, required this.onSort});

  final FileSort sort;
  final ValueChanged<FileSort> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(FileSortField f) => switch (f) {
      FileSortField.date => l10n.browseSortDate,
      FileSortField.size => l10n.browseSortSize,
      FileSortField.name => l10n.browseSortName,
    };
    return PopupMenuButton<FileSortField>(
      tooltip: l10n.browseSortTitle,
      icon: const Icon(Icons.sort),
      onSelected: (field) => onSort(
        field == sort.field
            ? FileSort(field, descending: !sort.descending)
            : naturalSort(field),
      ),
      itemBuilder: (_) => [
        for (final field in FileSortField.values)
          CheckedPopupMenuItem(
            value: field,
            checked: field == sort.field,
            child: Text(
              field == sort.field ? sortLabel(l10n, sort) : label(field),
            ),
          ),
      ],
    );
  }
}

class _Disconnected extends StatelessWidget {
  const new({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: spacing * 2),
            Text(
              name.isEmpty
                  ? l10n.remoteNotConnected
                  : l10n.remoteDeviceNotConnected(name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: spacing * 2),
            FilledButton(
              onPressed: () => unawaited(context.push(AppRoutes.connect)),
              child: Text(l10n.remoteReconnect),
            ),
          ],
        ),
      ),
    );
  }
}

class _RootList extends StatelessWidget {
  const new({required this.roots, required this.name, required this.onOpen});

  final List<RootDto> roots;
  final String name;
  final ValueChanged<RootDto> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (roots.isEmpty) {
      return Center(child: Text(l10n.connectNoFoldersYet(name)));
    }
    return ListView(
      children: [
        ListTile(
          title: Text(
            l10n.remoteBrowseRoots,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final r in roots)
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined),
            title: Text(r.label),
            subtitle: r.readOnly ? Text(l10n.remoteReadOnly) : null,
            onTap: () => onOpen(r),
          ),
      ],
    );
  }
}

class _FolderBody extends ConsumerWidget {
  const new({
    required this.peerFingerprint,
    required this.device,
    required this.view,
    required this.async,
    required this.selected,
    required this.onTapFile,
    required this.onLongPressFile,
  });

  final String peerFingerprint;
  final String device;
  final RemoteBrowseView view;
  final AsyncValue<RemoteBrowseState> async;
  final Set<String> selected;
  final void Function(FileRef f, List<FileRef> loaded) onTapFile;
  final ValueChanged<FileRef> onLongPressFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(
      remoteBrowseControllerProvider(peerFingerprint).notifier,
    );
    final chips = SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: spacing),
            child: ChoiceChip(
              label: Text(l10n.browseKindAll),
              selected: view.kinds.isEmpty,
              onSelected: (_) => unawaited(controller.setKind(null)),
            ),
          ),
          for (final kind in browseKinds)
            Padding(
              padding: EdgeInsetsDirectional.only(end: spacing),
              child: GestureDetector(
                onLongPress: () =>
                    unawaited(controller.setKind(kind, add: true)),
                child: ChoiceChip(
                  label: Text(kindLabel(l10n, kind)),
                  selected: view.kinds.contains(kind),
                  onSelected: (_) => unawaited(controller.setKind(kind)),
                ),
              ),
            ),
        ],
      ),
    );
    final Widget content;
    switch (async) {
      case AsyncValue(:final value?) when !async.isLoading:
        content = _Grid(
          state: value,
          device: device,
          selected: selected,
          onRefresh: controller.reload,
          onLoadMore: () => unawaited(controller.loadMore()),
          onOpenFolder: (p) => unawaited(controller.openFolder(p)),
          onTapFile: onTapFile,
          onLongPressFile: onLongPressFile,
        );
      case AsyncValue(:final error?) when !async.isLoading:
        content = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remoteFailureText(l10n, error, device),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing),
              OutlinedButton(
                onPressed: () => unawaited(controller.reload()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case _:
        content = const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chips,
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: Text(
            sortLabel(l10n, view.sort),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const new({
    required this.state,
    required this.device,
    required this.selected,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenFolder,
    required this.onTapFile,
    required this.onLongPressFile,
  });

  final RemoteBrowseState state;
  final String device;
  final Set<String> selected;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onOpenFolder;
  final void Function(FileRef f, List<FileRef> loaded) onTapFile;
  final ValueChanged<FileRef> onLongPressFile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final items = state.items;
    final sizeSort = state.view.sort.field == FileSortField.size;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (state.hasMore &&
              state.loadMoreError == null &&
              n.metrics.extentAfter < 800) {
            onLoadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList.builder(
              itemCount: state.folders.length,
              itemBuilder: (_, i) {
                final folder = state.folders[i];
                return ListTile(
                  key: ValueKey('folder:${folder.relativePath}'),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  subtitle: Text(l10n.browseFileCount(folder.fileCount)),
                  onTap: () => onOpenFolder(folder.relativePath),
                );
              },
            ),
            if (items.isEmpty && state.folders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.remoteEmptyFolder)),
              ),
            SliverPadding(
              padding: EdgeInsetsDirectional.all(spacing / 4),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 128,
                  mainAxisSpacing: spacing / 4,
                  crossAxisSpacing: spacing / 4,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final f = items[i];
                  final isSelected = selected.contains(f.id);
                  return GestureDetector(
                    key: ValueKey(f.id),
                    onLongPress: () => onLongPressFile(f),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FileGridTile(
                          file: f,
                          showSize: sizeSort,
                          highlightBig: true,
                          onTap: () => onTapFile(f, items),
                        ),
                        if (isSelected)
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.25),
                                border: Border.all(
                                  color: scheme.primary,
                                  width: 3,
                                ),
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.all(
                                    spacing / 2,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _Footer(state: state, onRetry: onLoadMore),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({required this.state, required this.onRetry});

  final RemoteBrowseState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final Widget? child;
    if (state.loadMoreError != null) {
      child = TextButton(onPressed: onRetry, child: Text(l10n.retry));
    } else if (state.loadingMore) {
      child = const CircularProgressIndicator();
    } else if (state.truncated && !state.hasMore) {
      child = Text(l10n.remoteShowingFirst(state.items.length));
    } else {
      child = null;
    }
    if (child == null) return SizedBox(height: spacing * 2);
    return Padding(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      child: Center(child: child),
    );
  }
}

/// Picks a folder in one of the other device's writable roots; pops with
/// its remote `folderPath`.
class _RemoteFolderPicker extends StatefulWidget {
  const new({required this.source, required this.device, required this.roots});

  final RemoteFileSource source;
  final String device;
  final List<RootDto> roots;

  @override
  State<_RemoteFolderPicker> createState() => _RemoteFolderPickerState();
}

class _RemoteFolderPickerState extends State<_RemoteFolderPicker> {
  RootDto? _root;
  String _path = '';
  Future<List<RemoteFolderDto>>? _folders;

  void _open(RootDto root, String path) => setState(() {
    _root = root;
    _path = path;
    _folders = widget.source.folders(root.id, path: path);
  });

  void _up() {
    final root = _root;
    if (root == null) return;
    if (_path.isEmpty) {
      setState(() {
        _root = null;
        _folders = null;
      });
    } else {
      final slash = _path.lastIndexOf('/');
      _open(root, slash < 0 ? '' : _path.substring(0, slash));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final root = _root;
    final folders = _folders;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: root == null
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: const BackButtonIcon(),
                      onPressed: _up,
                    ),
              title: Text(
                root == null
                    ? l10n.remotePickFolderTitle(widget.device)
                    : _path.isEmpty
                    ? root.label
                    : _path.substring(_path.lastIndexOf('/') + 1),
              ),
              trailing: root == null
                  ? null
                  : FilledButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(remoteFolderPath(root.id, _path)),
                      child: Text(l10n.remotePickHere),
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              child: root == null || folders == null
                  ? ListView(
                      children: [
                        for (final r in widget.roots)
                          ListTile(
                            leading: const Icon(Icons.folder_shared_outlined),
                            title: Text(r.label),
                            onTap: () => _open(r, ''),
                          ),
                      ],
                    )
                  : FutureBuilder<List<RemoteFolderDto>>(
                      future: folders,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              remoteFailureText(
                                l10n,
                                snap.error,
                                widget.device,
                              ),
                            ),
                          );
                        }
                        final list = snap.data;
                        if (list == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return ListView(
                          children: [
                            for (final f in list)
                              ListTile(
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(f.name),
                                onTap: () => _open(root, f.relativePath),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The paged viewer over the screen's loaded photos and videos; pages it
/// loads land in the grid too.
class _RemoteViewerSource extends ChangeNotifier implements PagedViewerSource {
  new(this._container, this._fp) {
    _sub = _container.listen(remoteBrowseControllerProvider(_fp), (_, next) {
      final value = next.value;
      final items = _media(value);
      final more = _more(value);
      if (_same(items, _items) && more == _hasMore) return;
      _items = items;
      _hasMore = more;
      notifyListeners();
    });
    final value = _sub.read().value;
    _items = _media(value);
    _hasMore = _more(value);
  }

  final ProviderContainer _container;
  final String _fp;
  late final ProviderSubscription<AsyncValue<RemoteBrowseState>> _sub;
  List<FileRef> _items = const [];
  bool _hasMore = false;

  static List<FileRef> _media(RemoteBrowseState? s) => [
    for (final f in s?.items ?? const <FileRef>[])
      if (f.isMedia) f,
  ];

  static bool _more(RemoteBrowseState? s) =>
      s != null && s.hasMore && s.loadMoreError == null;

  static bool _same(List<FileRef> a, List<FileRef> b) => sameRemoteItems(a, b);

  @override
  List<FileRef> get items => _items;

  @override
  bool get hasMore => _hasMore;

  @override
  Listenable get changes => this;

  @override
  Future<void> loadMore() =>
      _container.read(remoteBrowseControllerProvider(_fp).notifier).loadMore();

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
