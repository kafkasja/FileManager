import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/windows/windows_clipboard.dart';
import 'package:kfm/desktop/browse/desktop_breadcrumb.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/browse/desktop_clipboard.dart';
import 'package:kfm/desktop/browse/disk_folders.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart' show placeIcon;
import 'package:kfm/desktop/widgets/column_widths.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/desktop/widgets/layout_switch.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/folder_menu.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// Desktop Browse (TASK-PL3 step 3, PL3-3 a): an Explorer-like folder view
/// over the index. Places (the scanned folders) at the top, then folders
/// and files with Large icons / Grid / Details (sortable columns),
/// Explorer selection and keys, right-click menus with the phone's file
/// actions (B4/B5/B9/X2/N9/B10), Del / Shift+Del / F2 / Ctrl+Z /
/// Ctrl+C·X·V, and a visible Undo after an operation.
class DesktopBrowseScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopBrowseScreen> createState() =>
      _DesktopBrowseScreenState();
}

class _DesktopBrowseScreenState extends ConsumerState<DesktopBrowseScreen> {
  final _explorer = GlobalKey<ExplorerViewState<BrowseEntry>>();
  ExplorerSelection _sel = ExplorerSelection.empty;
  List<BrowseEntry> _entries = const [];
  String? _shownFolder;

  DesktopBrowseController get _nav =>
      ref.read(desktopBrowseControllerProvider.notifier);

  List<FileRef> get _selectedFiles => [
    for (final e in _entries)
      if (e is FileBrowseEntry && _sel.contains(e.id)) e.file,
  ];

  List<FolderBrowseEntry> get _selectedFolders => [
    for (final e in _entries)
      if (e is FolderBrowseEntry && _sel.contains(e.id)) e,
  ];

  Set<String> get _roots => {
    for (final p
        in ref.read(desktopPlacesProvider).value ?? const <DesktopPlace>[])
      p.path,
  };

  void _setSelection(ExplorerSelection s) {
    setState(() => _sel = s);
    _report();
  }

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var bytes = 0;
      var count = 0;
      FileRef? focused;
      for (final e in _entries) {
        if (!_sel.contains(e.id)) continue;
        count++;
        if (e is FileBrowseEntry) bytes += e.file.sizeBytes;
      }
      for (final e in _entries) {
        if (e is FileBrowseEntry && e.id == _sel.focus) focused = e.file;
      }
      ref
          .read(desktopStatusLineProvider(DesktopSection.browse).notifier)
          .set(
            DesktopStatus(
              items: _entries.length,
              selected: count,
              selectedBytes: bytes,
            ),
          );
      ref
          .read(desktopFocusedFileProvider(DesktopSection.browse).notifier)
          .set(focused);
    });
  }

  // --- actions -------------------------------------------------------------

  /// New folder; it shows at once, though the index has no file in it.
  Future<void> _newFolder(String folder) async {
    await createFolderIn(context, ref, folder);
    _refreshDisk();
  }

  /// Lists the open folder's subfolders again (an empty folder was made,
  /// renamed or removed: no index change tells).
  void _refreshDisk() {
    if (!mounted) return;
    if (ref.read(desktopBrowseControllerProvider).folder case final f?) {
      ref.invalidate(desktopDiskFoldersProvider(f));
    }
  }

  Future<void> _open(BrowseEntry e) async {
    switch (e) {
      case FolderBrowseEntry(:final path, :final available):
        if (available) _nav.open(path);
      case FileBrowseEntry(:final file):
        await openFile(context, ref, file);
    }
  }

  Future<void> _delete({required bool permanent}) async {
    final files = _selectedFiles;
    if (files.isEmpty) return;
    if (permanent) {
      await runFileOperation(context, ref, DeleteOp(files, permanent: true));
    } else {
      await deleteFiles(context, ref, files);
    }
  }

  Future<void> _rename() async {
    final files = _selectedFiles;
    final folders = _selectedFolders;
    if (files.length == 1 && folders.isEmpty) {
      await renameFile(context, ref, files.single);
    } else if (folders.length == 1 && files.isEmpty) {
      final f = folders.single;
      if (_roots.contains(f.path)) return;
      await renameFolderFlow(
        context,
        ref,
        FolderEntry(f.path, f.fileCount ?? 0),
      );
      _refreshDisk();
    }
  }

  void _copy({required bool cut}) {
    final files = _selectedFiles;
    final roots = _roots;
    final folders = [
      for (final f in _selectedFolders)
        if (f.available && !roots.contains(f.path)) f.path,
    ];
    if (files.isEmpty && folders.isEmpty) return;
    unawaited(copyToClipboard(ref, files, cut: cut, folders: folders));
  }

  Future<void> _paste() async {
    final folder = ref.read(desktopBrowseControllerProvider).folder;
    if (folder == null) return;
    await pasteClipboard(context, ref, folder);
  }

  Future<void> _undo() async {
    if (ref.read(lastOperationUndoProvider) == null) return;
    await undoLastFileOperation(context);
  }

  Future<void> _sortThese() async {
    final st = ref.read(desktopBrowseControllerProvider);
    final folder = st.folder;
    final files = _selectedFiles;
    final l10n = context.l10n;
    if (files.length > 1) {
      await swipeFileIds(
        context,
        ref,
        ids: [for (final f in files) f.id],
        title: l10n.desktopBrowseSortThese,
      );
    } else if (folder != null) {
      await swipeQueryFiles(
        context,
        ref,
        query: IndexQuery(folderPath: folder, sort: st.fileSort),
        title: _leaf(folder),
      );
    }
  }

  Future<void> _quickLook() async {
    final focus = _sel.focus;
    final media = [
      for (final e in _entries)
        if (e case FileBrowseEntry(:final file) when file.isMedia) file,
    ];
    if (focus == null || !media.any((f) => f.id == focus)) return;
    final last = await showQuickLook(
      context,
      startId: focus,
      watchFiles: (_) => media,
    );
    if (last != null && mounted) {
      _setSelection(ExplorerSelection(ids: {last}, anchor: last, focus: last));
      _explorer.currentState?.reveal(last);
    }
  }

  KeyEventResult _onKey(KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    final ctrl = keys.isControlPressed;
    final shift = keys.isShiftPressed;
    final alt = keys.isAltPressed;
    final key = event.logicalKey;
    void run(Future<void> Function() f) => unawaited(f());
    if (key == LogicalKeyboardKey.delete) {
      run(() => _delete(permanent: shift));
    } else if (key == LogicalKeyboardKey.f2) {
      run(_rename);
    } else if (ctrl && key == LogicalKeyboardKey.keyZ) {
      run(_undo);
    } else if (ctrl && key == LogicalKeyboardKey.keyC) {
      _copy(cut: false);
    } else if (ctrl && key == LogicalKeyboardKey.keyX) {
      _copy(cut: true);
    } else if (ctrl && key == LogicalKeyboardKey.keyV) {
      run(_paste);
    } else if (key == LogicalKeyboardKey.backspace ||
        (alt && key == LogicalKeyboardKey.arrowUp)) {
      _nav.up(roots: _roots);
    } else if (alt && key == LogicalKeyboardKey.arrowLeft) {
      _nav.goBack();
    } else if (alt && key == LogicalKeyboardKey.arrowRight) {
      _nav.goForward();
    } else if (key == LogicalKeyboardKey.space && !ctrl) {
      run(_quickLook);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _contextMenu(BrowseEntry? item, Offset at) async {
    final l10n = context.l10n;
    final folder = ref.read(desktopBrowseControllerProvider).folder;
    // Paste works with KFM's clipboard or files on the Windows clipboard.
    var canPaste = ref.read(desktopClipboardProvider) != null;
    if (!canPaste && item == null) {
      final sys = await ref.read(systemFileClipboardProvider)?.read();
      if (!mounted) return;
      canPaste = sys != null && sys.paths.isNotEmpty;
    }
    final entries = <DesktopMenuEntry>[];
    final files = _selectedFiles;
    final folders = _selectedFolders;
    String keys(SingleActivator a) => DesktopKeys.label(a);
    if (item == null) {
      if (folder != null) {
        entries
          ..add(
            DesktopMenuEntry(
              key: const ValueKey('menu-new-folder'),
              label: l10n.browseNewFolder,
              icon: Icons.create_new_folder_outlined,
              onSelected: () => unawaited(_newFolder(folder)),
            ),
          )
          ..add(
            DesktopMenuEntry(
              label: l10n.desktopBrowsePaste,
              icon: Icons.content_paste,
              shortcut: 'Ctrl+V',
              onSelected: canPaste ? () => unawaited(_paste()) : null,
            ),
          )
          ..add(
            DesktopMenuEntry(
              label: l10n.desktopBrowseSortThese,
              icon: Icons.swipe_outlined,
              onSelected: () => unawaited(_sortThese()),
            ),
          );
      }
    } else if (item is FolderBrowseEntry && files.isEmpty) {
      final entry = FolderEntry(item.path, item.fileCount ?? 0);
      entries.add(
        DesktopMenuEntry(
          label: l10n.desktopBrowseOpen,
          icon: Icons.folder_open,
          shortcut: 'Enter',
          onSelected: () => unawaited(_open(item)),
        ),
      );
      if (!_roots.contains(item.path)) {
        entries
          ..add(
            DesktopMenuEntry(
              key: const ValueKey('menu-folder-cut'),
              label: l10n.desktopBrowseCut,
              icon: Icons.content_cut,
              shortcut: 'Ctrl+X',
              divider: true,
              onSelected: () => _copy(cut: true),
            ),
          )
          ..add(
            DesktopMenuEntry(
              key: const ValueKey('menu-folder-copy'),
              label: l10n.desktopBrowseCopy,
              icon: Icons.content_copy,
              shortcut: 'Ctrl+C',
              onSelected: () => _copy(cut: false),
            ),
          );
      }
      if (folders.length == 1 && !_roots.contains(item.path)) {
        for (final m in ref.read(folderMenuItemsProvider)) {
          if (!m.isAvailable(entry)) continue;
          entries.add(
            DesktopMenuEntry(
              label: m.label(context),
              icon: m.icon,
              onSelected: () => unawaited(
                m.onSelected(context, ref, entry).whenComplete(_refreshDisk),
              ),
            ),
          );
        }
      }
    } else if (files.length == 1 && folders.isEmpty) {
      final f = files.single;
      entries
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseOpen,
            icon: Icons.open_in_new,
            shortcut: 'Enter',
            onSelected: () => unawaited(openFile(context, ref, f)),
          ),
        )
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseCut,
            icon: Icons.content_cut,
            shortcut: 'Ctrl+X',
            divider: true,
            onSelected: () => _copy(cut: true),
          ),
        )
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseCopy,
            icon: Icons.content_copy,
            shortcut: 'Ctrl+C',
            onSelected: () => _copy(cut: false),
          ),
        );
      var first = true;
      for (final m in ref.read(fileMenuItemsProvider)) {
        if (!m.isAvailable(f)) continue;
        entries.add(
          DesktopMenuEntry(
            label: m.labelFor?.call(context, f) ?? m.label(context),
            icon: m.icon,
            divider: first,
            shortcut: switch (m.order) {
              20 => keys(DesktopKeys.rename),
              60 => keys(DesktopKeys.delete),
              _ => null,
            },
            onSelected: () => unawaited(m.onSelected(context, ref, f)),
          ),
        );
        first = false;
      }
      entries.add(
        DesktopMenuEntry(
          label: l10n.permanentConfirmYes,
          icon: Icons.delete_forever_outlined,
          shortcut: keys(DesktopKeys.deletePermanently),
          onSelected: () => unawaited(_delete(permanent: true)),
        ),
      );
    } else if (files.isNotEmpty) {
      final ids = [for (final f in files) f.id];
      final state = SelectionState(
        ids: ids.toSet(),
        totalBytes: files.fold(0, (a, f) => a + f.sizeBytes),
      );
      entries
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseCut,
            icon: Icons.content_cut,
            shortcut: 'Ctrl+X',
            onSelected: () => _copy(cut: true),
          ),
        )
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseCopy,
            icon: Icons.content_copy,
            shortcut: 'Ctrl+C',
            onSelected: () => _copy(cut: false),
          ),
        );
      var first = true;
      for (final a in ref.read(selectionActionsProvider)) {
        if (!a.isAvailable(state)) continue;
        entries.add(
          DesktopMenuEntry(
            label: a.label(context),
            icon: a.icon,
            divider: first,
            shortcut: a.id == 'b4.delete' ? keys(DesktopKeys.delete) : null,
            onSelected: () => unawaited(a.run(context, ref, ids)),
          ),
        );
        first = false;
      }
      entries.add(
        DesktopMenuEntry(
          label: l10n.permanentConfirmYes,
          icon: Icons.delete_forever_outlined,
          shortcut: keys(DesktopKeys.deletePermanently),
          onSelected: () => unawaited(_delete(permanent: true)),
        ),
      );
    }
    if (!mounted) return;
    await showDesktopContextMenu(context, at, entries);
  }

  // --- build ---------------------------------------------------------------

  List<BrowseEntry> _buildEntries(DesktopBrowseState st) {
    final folder = st.folder;
    if (folder == null) {
      return [
        for (final p
            in ref.watch(desktopPlacesProvider).value ?? const <DesktopPlace>[])
          FolderBrowseEntry(p.path, available: p.available),
      ];
    }
    final folders = _mergeFolders(
      indexed:
          ref
              .watch(browseFoldersProvider(st.foldersScope, parent: folder))
              .value ??
          const <FolderEntry>[],
      onDisk: ref.watch(desktopDiskFoldersProvider(folder)).value,
      showHidden: st.showHidden,
    );
    if (st.sortColumn == FileColumns.name && st.descending) {
      folders.setAll(0, folders.reversed.toList());
    }
    final query = st.filesQuery!;
    final files = ref.watch(filePagesProvider(query)).value?.items ?? const [];
    return [...folders, for (final f in files) FileBrowseEntry(f)];
  }

  /// The index's folders (with file counts) plus the folders on disk the
  /// index doesn't know (empty ones, or only unindexed files inside),
  /// like Explorer. A folder hidden on disk stays out unless [showHidden],
  /// also when older index rows still list it.
  static List<FolderBrowseEntry> _mergeFolders({
    required List<FolderEntry> indexed,
    required List<DiskFolder>? onDisk,
    required bool showHidden,
  }) {
    String key(String path) => path.toLowerCase();
    final hiddenOnDisk = {
      for (final d in onDisk ?? const <DiskFolder>[])
        if (d.hidden) key(d.path),
    };
    final byKey = <String, FolderBrowseEntry>{
      for (final f in indexed)
        if (showHidden || !hiddenOnDisk.contains(key(f.path)))
          key(f.path): FolderBrowseEntry(f.path, fileCount: f.fileCount),
    };
    for (final d in onDisk ?? const <DiskFolder>[]) {
      if (d.hidden && !showHidden) continue;
      byKey.putIfAbsent(key(d.path), () => FolderBrowseEntry(d.path));
    }
    return byKey.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final st = ref.watch(desktopBrowseControllerProvider);
    if (st.folder != _shownFolder) {
      // A new folder: nothing selected there yet.
      _shownFolder = st.folder;
      _sel = ExplorerSelection.empty;
    }
    final entries = _entries = _buildEntries(st);
    _report();
    final lastOp = ref.watch(lastOperationUndoProvider);
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          // Narrow (800 px window with the details pane): the labelled
          // buttons become icons with tooltips.
          child: LayoutBuilder(
            builder: (context, box) {
              final compact =
                  box.maxWidth < MediaQuery.textScalerOf(context).scale(600);
              return Row(
                children: [
                  IconButton(
                    key: const ValueKey('browse-back'),
                    tooltip: shortcutHint(
                      l10n,
                      l10n.desktopBrowseBack,
                      'Alt+←',
                    ),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: st.back.isEmpty ? null : _nav.goBack,
                  ),
                  IconButton(
                    tooltip: shortcutHint(
                      l10n,
                      l10n.desktopBrowseForward,
                      'Alt+→',
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: st.forward.isEmpty ? null : _nav.goForward,
                  ),
                  IconButton(
                    key: const ValueKey('browse-up'),
                    tooltip: shortcutHint(l10n, l10n.desktopBrowseUp, 'Alt+↑'),
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: st.folder == null
                        ? null
                        : () => _nav.up(roots: _roots),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DesktopBreadcrumb(
                      folder: st.folder,
                      onOpen: _nav.open,
                    ),
                  ),
                  if (lastOp != null) ...[
                    if (compact)
                      IconButton.filledTonal(
                        key: const ValueKey('browse-undo'),
                        tooltip: l10n.undo,
                        onPressed: () => unawaited(_undo()),
                        icon: const Icon(Icons.undo, size: 18),
                      )
                    else
                      FilledButton.tonalIcon(
                        key: const ValueKey('browse-undo'),
                        onPressed: () => unawaited(_undo()),
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(l10n.undo),
                      ),
                    const SizedBox(width: 4),
                  ],
                  if (st.folder != null)
                    if (compact)
                      IconButton(
                        key: const ValueKey('browse-sort-these'),
                        tooltip: l10n.desktopBrowseSortThese,
                        onPressed: () => unawaited(_sortThese()),
                        icon: const Icon(Icons.swipe_outlined, size: 18),
                      )
                    else
                      TextButton.icon(
                        key: const ValueKey('browse-sort-these'),
                        onPressed: () => unawaited(_sortThese()),
                        icon: const Icon(Icons.swipe_outlined, size: 18),
                        label: Text(l10n.desktopBrowseSortThese),
                      ),
                  IconButton(
                    key: const ValueKey('browse-show-hidden'),
                    tooltip: l10n.browseShowHidden,
                    isSelected: st.showHidden,
                    icon: const Icon(Icons.visibility_off_outlined),
                    selectedIcon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _nav.setShowHidden(show: !st.showHidden),
                  ),
                  LayoutSwitch(layout: st.layout, onChanged: _nav.setLayout),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    st.folder == null
                        ? l10n.desktopNoPlaces
                        : l10n.desktopBrowseEmptyFolder,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _folderDrop(
                  st.folder,
                  ExplorerView<BrowseEntry>(
                    key: _explorer,
                    autofocus: true,
                    dragController: ref.read(desktopDragControllerProvider),
                    dragDataOf: (ids) {
                      final files = [
                        for (final e in _entries)
                          if (e is FileBrowseEntry && ids.contains(e.id))
                            e.file,
                      ];
                      final roots = _roots;
                      final folders = [
                        for (final e in _entries)
                          if (e is FolderBrowseEntry &&
                              e.available &&
                              ids.contains(e.id) &&
                              !roots.contains(e.path))
                            e.path,
                      ];
                      return files.isEmpty && folders.isEmpty
                          ? null
                          : DesktopDragData(
                              origin: DragOrigin.browse,
                              files: files,
                              folders: folders,
                            );
                    },
                    itemDropOffer: (e) => switch (e) {
                      FolderBrowseEntry(:final path, :final available)
                          when available =>
                        folderDropOffer(context, ref, path),
                      _ => null,
                    },
                    items: entries,
                    idOf: (e) => e.id,
                    nameOf: (e) => e.name,
                    layout: st.layout,
                    selection: _sel,
                    onSelectionChanged: _setSelection,
                    sortColumn: st.sortColumn,
                    sortDescending: st.descending,
                    onSort: _nav.sortBy,
                    onOpen: (e) => unawaited(_open(e)),
                    onKey: _onKey,
                    onContextMenu: (item, at) =>
                        unawaited(_contextMenu(item, at)),
                    onNearEnd: () {
                      final q = st.filesQuery;
                      if (q != null) {
                        unawaited(
                          ref.read(filePagesProvider(q).notifier).loadMore(),
                        );
                      }
                    },
                    tileBuilder: (context, e, {required extent}) => switch (e) {
                      FileBrowseEntry(:final file) => FileTileBody(file: file),
                      FolderBrowseEntry() => _FolderTile(entry: e),
                    },
                    columnWidths:
                        ref.watch(
                          desktopColumnWidthsProvider,
                        )[ColumnWidthLists.browse] ??
                        const {},
                    onColumnWidthsChanged: (w) => ref
                        .read(desktopColumnWidthsProvider.notifier)
                        .save(ColumnWidthLists.browse, w),
                    columns: fileColumns<BrowseEntry>(
                      context,
                      fileOf: (e) => e is FileBrowseEntry ? e.file : null,
                      typeOf: (e) => e is FolderBrowseEntry
                          ? l10n.desktopTypeFolder
                          : null,
                      nameCell: (context, e) => switch (e) {
                        FileBrowseEntry(:final file) => FileNameCell(
                          name: file.name,
                          file: file,
                        ),
                        FolderBrowseEntry() => FileNameCell(
                          name: e.name,
                          icon: st.folder == null
                              ? placeIcon(e.name)
                              : Icons.folder,
                        ),
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// The open folder takes drops on its background (Explorer files are
  /// copied in); Places doesn't.
  Widget _folderDrop(String? folder, Widget child) => folder == null
      ? child
      : DesktopDropTarget(
          key: const ValueKey('browse-drop'),
          radius: 0,
          offer: folderDropOffer(context, ref, folder),
          child: child,
        );
}

String _leaf(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? path : path.substring(i + 1);
}

class _FolderTile extends StatelessWidget {
  const new({required this.entry});

  final FolderBrowseEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: FittedBox(
            child: Icon(
              placeIcon(entry.name) == Icons.folder_outlined
                  ? Icons.folder
                  : placeIcon(entry.name),
              color: entry.available
                  ? theme.colorScheme.primary
                  : theme.disabledColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: scaledExtent(context, 32),
          child: Text(
            entry.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
