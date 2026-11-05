import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/windows_clipboard.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/browse/desktop_clipboard.dart';
import 'package:kfm/desktop/browse/desktop_disk_files.dart';
import 'package:kfm/desktop/browse/disk_folders.dart';
import 'package:kfm/desktop/shell/desktop_address_bar.dart';
import 'package:kfm/desktop/shell/desktop_command_bar.dart';
import 'package:kfm/desktop/shell/desktop_drives.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_nav_pane.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart' show placeIcon;
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/shell/quick_access.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/column_widths.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/desktop/widgets/file_location_actions.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/folder_menu.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// Desktop Browse (TASK-PL3 step 3, PL3-3 a; E3): an Explorer-like folder
/// view over the index (folders outside it list their files from disk).
/// Home = Quick access pins + drives; search results of a tab; folders
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

  /// E3: each tab keeps its own selection.
  final Map<String, ExplorerSelection> _selByTab = {};
  String? _tabId;
  DesktopLocation _location = const HomeLocation();

  DesktopBrowseController get _nav =>
      ref.read(desktopBrowseControllerProvider.notifier);

  List<FileRef> get _selectedFiles => [
    for (final e in _entries)
      if (e is FileBrowseEntry && _sel.contains(e.id)) e.file,
  ];

  List<String> get _selectedPaths => [
    for (final e in _entries)
      if (_sel.contains(e.id))
        switch (e) {
          FileBrowseEntry(:final file) => file.path,
          FolderBrowseEntry(:final path) => path,
        },
  ];

  List<FolderBrowseEntry> get _selectedFolders => [
    for (final e in _entries)
      if (e is FolderBrowseEntry && _sel.contains(e.id)) e,
  ];

  /// Drive roots: never renamed, cut or dragged away.
  Set<String> get _roots => {
    for (final d in desktopDrivesOf(ref.read(placesProvider).value ?? const []))
      ?d.rootPath,
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
        // E3: Explorer's double-click: the Windows default app (KFM's
        // viewer is in the menu and on Space).
        if (isWindowsHost) {
          await openOrExplain(context, ref, file);
        } else {
          await openFile(context, ref, file);
        }
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
    final folder = ref.read(desktopBrowseControllerProvider).folder;
    if (ctrl && shift && key == LogicalKeyboardKey.keyC) {
      run(() => copyPathsAsText(ref, _selectedPaths));
    } else if (ctrl && shift && key == LogicalKeyboardKey.keyN) {
      if (folder != null) run(() => _newFolder(folder));
    } else if (alt && key == LogicalKeyboardKey.enter) {
      if (_selectedFiles case [final f]) {
        run(() => showFileProperties(context, ref, f));
      }
    } else if (ctrl && shift && key == LogicalKeyboardKey.digit2) {
      _nav.setLayout(ExplorerLayout.largeIcons);
    } else if (ctrl && shift && key == LogicalKeyboardKey.digit6) {
      _nav.setLayout(ExplorerLayout.details);
    } else if (key == LogicalKeyboardKey.delete) {
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
      _nav.up();
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
      final pinned = await ref
          .read(desktopQuickAccessProvider.notifier)
          .isPinned(item.path);
      if (!mounted) return;
      entries
        ..add(
          DesktopMenuEntry(
            label: l10n.desktopBrowseOpen,
            icon: Icons.folder_open,
            shortcut: 'Enter',
            onSelected: () => unawaited(_open(item)),
          ),
        )
        ..add(
          DesktopMenuEntry(
            key: const ValueKey('menu-open-new-tab'),
            label: l10n.desktopOpenInNewTab,
            icon: Icons.tab,
            onSelected: () => ref
                .read(desktopTabsControllerProvider.notifier)
                .openInNewTab(FolderLocation(item.path)),
          ),
        )
        ..add(
          DesktopMenuEntry(
            key: const ValueKey('menu-pin'),
            label: pinned
                ? l10n.desktopUnpinFromQuickAccess
                : l10n.desktopPinToQuickAccess,
            icon: Icons.push_pin_outlined,
            onSelected: () => ref
                .read(desktopQuickAccessProvider.notifier)
                .togglePin(item.path, pinned: pinned),
          ),
        )
        ..add(
          DesktopMenuEntry(
            key: const ValueKey('menu-folder-copy-path'),
            label: l10n.desktopCopyAsPath,
            icon: Icons.content_paste_go,
            shortcut: DesktopKeys.label(DesktopKeys.copyAsPath),
            onSelected: () => unawaited(copyPathsAsText(ref, [item.path])),
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
            onSelected: () => unawaited(_open(FileBrowseEntry(f))),
          ),
        )
        ..add(
          DesktopMenuEntry(
            key: const ValueKey('menu-open-kfm'),
            label: l10n.desktopOpenInKfm,
            icon: Icons.visibility_outlined,
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
      entries
        ..add(
          DesktopMenuEntry(
            label: l10n.permanentConfirmYes,
            icon: Icons.delete_forever_outlined,
            shortcut: keys(DesktopKeys.deletePermanently),
            onSelected: () => unawaited(_delete(permanent: true)),
          ),
        )
        ..addAll(
          fileLocationMenuEntries(context, ref, [
            f,
          ], openLocation: _location is SearchLocation),
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
    if (_location case SearchLocation(:final query, :final scope)) {
      final q = searchQuery(query, scope, st);
      final files = ref.watch(filePagesProvider(q)).value?.items ?? const [];
      return [for (final f in files) FileBrowseEntry(f)];
    }
    final folder = st.folder;
    if (folder == null) {
      // Home: Quick access pins, then the drives (no recent files).
      final pins = ref.watch(desktopQuickAccessProvider).value ?? const [];
      final drives = desktopDrivesOf(ref.watch(placesProvider).value ?? []);
      final seen = <String>{};
      return [
        for (final p in pins)
          if (seen.add(p.toLowerCase())) FolderBrowseEntry(p),
        for (final d in drives)
          if (d.rootPath case final root? when seen.add(root.toLowerCase()))
            FolderBrowseEntry(root, label: desktopDriveLabel(context.l10n, d)),
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
    // E3: a folder the index doesn't cover lists its files from disk (index
    // rows win on the same path).
    final disk = ref.watch(desktopDiskFilesProvider(folder)).value;
    final merged = <FileRef>[...files];
    if (disk != null && disk.files.isNotEmpty) {
      final known = {for (final f in files) f.path.toLowerCase()};
      merged
        ..addAll(disk.files.where((f) => !known.contains(f.path.toLowerCase())))
        ..sort(_fileOrder(st));
    }
    return [...folders, for (final f in merged) FileBrowseEntry(f)];
  }

  static int Function(FileRef, FileRef) _fileOrder(DesktopBrowseState st) {
    int base(FileRef a, FileRef b) => switch (st.sortColumn) {
      FileColumns.date => a.sortDate.compareTo(b.sortDate),
      FileColumns.size => a.sizeBytes.compareTo(b.sizeBytes),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return st.descending ? (a, b) => base(b, a) : base;
  }

  /// The index query of a search tab: names containing [query] under
  /// [scope] (everywhere when null).
  static IndexQuery searchQuery(
    String query,
    String? scope,
    DesktopBrowseState st,
  ) => IndexQuery(
    nameContains: query,
    folderPath: scope,
    includeSubfolders: true,
    sort: st.fileSort,
  );

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

  /// Selects and shows the file a reveal request names (address bar with
  /// a file path, "Open file location").
  void _takeReveal(String? path, List<BrowseEntry> entries) {
    if (path == null) return;
    final lower = path.toLowerCase();
    for (final e in entries) {
      if (e case FileBrowseEntry(:final file)
          when file.path.toLowerCase() == lower) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(desktopRevealRequestProvider.notifier).request(null);
          _setSelection(
            ExplorerSelection(ids: {e.id}, anchor: e.id, focus: e.id),
          );
          _explorer.currentState?.reveal(e.id);
        });
        return;
      }
    }
  }

  void _publishCommands(DesktopBrowseState st, bool hasUndo) {
    final l10n = context.l10n;
    final folder = st.folder;
    final files = _selectedFiles;
    final folders = _selectedFolders;
    final any = files.isNotEmpty || folders.isNotEmpty;
    final roots = _roots;
    final movable =
        files.isNotEmpty ||
        folders.any((f) => f.available && !roots.contains(f.path));
    String keys(SingleActivator a) => DesktopKeys.label(a);
    final commands = <DesktopCommand>[
      DesktopCommand(
        id: 'new',
        label: l10n.desktopCmdNew,
        icon: Icons.add_circle_outline,
        menu: [
          DesktopCommand(
            id: 'new-folder',
            label: l10n.browseNewFolder,
            icon: Icons.create_new_folder_outlined,
            shortcut: keys(DesktopKeys.newFolder),
            onPressed: folder == null
                ? null
                : () => unawaited(_newFolder(folder)),
          ),
        ],
      ),
      DesktopCommand(
        id: 'cut',
        label: l10n.desktopBrowseCut,
        icon: Icons.content_cut,
        shortcut: 'Ctrl+X',
        divider: true,
        onPressed: movable ? () => _copy(cut: true) : null,
      ),
      DesktopCommand(
        id: 'copy',
        label: l10n.desktopBrowseCopy,
        icon: Icons.content_copy,
        shortcut: 'Ctrl+C',
        onPressed: movable ? () => _copy(cut: false) : null,
      ),
      DesktopCommand(
        id: 'paste',
        label: l10n.desktopBrowsePaste,
        icon: Icons.content_paste,
        shortcut: 'Ctrl+V',
        onPressed: folder == null ? null : () => unawaited(_paste()),
      ),
      DesktopCommand(
        id: 'rename',
        label: l10n.fileMenuRename,
        icon: Icons.drive_file_rename_outline,
        shortcut: keys(DesktopKeys.rename),
        onPressed: (files.length + folders.length) == 1
            ? () => unawaited(_rename())
            : null,
      ),
      DesktopCommand(
        id: 'delete',
        label: l10n.fileMenuDelete,
        icon: Icons.delete_outline,
        shortcut: keys(DesktopKeys.delete),
        onPressed: files.isNotEmpty
            ? () => unawaited(_delete(permanent: false))
            : null,
      ),
      DesktopCommand(
        id: 'sort-by',
        label: l10n.desktopCmdSortBy,
        icon: Icons.sort,
        divider: true,
        menu: [
          for (final (id, label) in [
            (FileColumns.name, l10n.browseSortName),
            (FileColumns.date, l10n.browseSortDate),
            (FileColumns.size, l10n.detailsSize),
          ])
            DesktopCommand(
              id: 'sort-$id',
              label: label,
              icon: Icons.sort,
              selected: st.sortColumn == id,
              onPressed: () => _nav.sortBy(id),
            ),
          DesktopCommand(
            id: 'sort-descending',
            label: l10n.desktopSortDescending,
            icon: Icons.south,
            selected: st.descending,
            onPressed: () => _nav.sortBy(st.sortColumn),
          ),
        ],
      ),
      DesktopCommand(
        id: 'view',
        label: l10n.desktopCmdView,
        icon: Icons.view_agenda_outlined,
        menu: [
          for (final (layout, label) in [
            (ExplorerLayout.largeIcons, l10n.desktopLayoutLargeIcons),
            (ExplorerLayout.grid, l10n.desktopLayoutGrid),
            (ExplorerLayout.details, l10n.desktopLayoutDetails),
          ])
            DesktopCommand(
              id: 'view-${layout.name}',
              label: label,
              icon: Icons.view_list,
              selected: st.layout == layout,
              onPressed: () => _nav.setLayout(layout),
            ),
          DesktopCommand(
            id: 'view-nav-pane',
            label: l10n.desktopViewNavPane,
            icon: Icons.view_sidebar_outlined,
            selected: ref.read(desktopNavPaneShownProvider),
            onPressed: () =>
                ref.read(desktopNavPaneShownProvider.notifier).toggle(),
          ),
          DesktopCommand(
            id: 'view-details-pane',
            label: l10n.desktopViewDetailsPane,
            icon: Icons.vertical_split_outlined,
            selected: ref.read(desktopDetailsPaneProvider),
            onPressed: () =>
                ref.read(desktopDetailsPaneProvider.notifier).toggle(),
          ),
          DesktopCommand(
            id: 'view-hidden',
            label: l10n.desktopViewHidden,
            icon: Icons.visibility_outlined,
            selected: st.showHidden,
            onPressed: () => _nav.setShowHidden(show: !st.showHidden),
          ),
        ],
      ),
      DesktopCommand(
        id: 'sort-these',
        label: l10n.desktopBrowseSortThese,
        icon: Icons.swipe_outlined,
        divider: true,
        keepLabel: true,
        onPressed: folder != null || files.length > 1
            ? () => unawaited(_sortThese())
            : null,
      ),
      if (hasUndo)
        DesktopCommand(
          id: 'undo',
          label: l10n.undo,
          icon: Icons.undo,
          shortcut: 'Ctrl+Z',
          keepLabel: true,
          onPressed: () => unawaited(_undo()),
        ),
      if (any)
        DesktopCommand(
          id: 'copy-path',
          label: l10n.desktopCopyAsPath,
          icon: Icons.content_paste_go,
          shortcut: keys(DesktopKeys.copyAsPath),
          divider: true,
          onPressed: () => unawaited(copyPathsAsText(ref, _selectedPaths)),
        ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(desktopCommandsProvider(DesktopSection.browse).notifier)
          .set(commands);
      ref
          .read(desktopViewTogglesProvider(DesktopSection.browse).notifier)
          .set(
            DesktopViewToggle(
              details: st.layout == ExplorerLayout.details,
              onChanged: (d) => _nav.setLayout(
                d ? ExplorerLayout.details : ExplorerLayout.largeIcons,
              ),
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final st = ref.watch(desktopBrowseControllerProvider);
    final tabs = ref.watch(desktopTabsControllerProvider);
    final tab = tabs.current;
    // Only Browse locations change what this screen shows.
    if (tab.location.section == DesktopSection.browse &&
        tab.location is! RouteLocation) {
      if (tab.id != _tabId) {
        if (_tabId case final old?) _selByTab[old] = _sel;
        _selByTab.removeWhere((id, _) => !tabs.tabs.any((t) => t.id == id));
        _tabId = tab.id;
        _sel = _selByTab[tab.id] ?? ExplorerSelection.empty;
        _shownFolder = st.folder;
      }
      if (tab.location != _location) {
        _location = tab.location;
        _sel = ExplorerSelection.empty;
      }
    }
    if (st.folder != _shownFolder) {
      // A new folder: nothing selected there yet.
      _shownFolder = st.folder;
      _sel = ExplorerSelection.empty;
    }
    final entries = _entries = _buildEntries(st);
    _report();
    _takeReveal(ref.watch(desktopRevealRequestProvider), entries);
    ref.watch(desktopRefreshTickProvider);
    final lastOp = ref.watch(lastOperationUndoProvider);
    _publishCommands(st, lastOp != null);
    final theme = Theme.of(context);
    final search = _location is SearchLocation
        ? _location as SearchLocation
        : null;
    return Column(
      children: [
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    search != null
                        ? l10n.desktopSearchNone(search.query)
                        : st.folder == null
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
                    itemHoverHold: (e) {
                      if (e case FolderBrowseEntry(:final available)
                          when available) {
                        unawaited(_open(e));
                      }
                    },
                    onNearEnd: () {
                      final q = search != null
                          ? searchQuery(search.query, search.scope, st)
                          : st.filesQuery;
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
                      folderColumn: search != null,
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
                          folderPath: e.path,
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
          child: LayoutBuilder(
            builder: (context, c) => Center(
              child: entry.isDrive
                  ? FileTypeIcon.drive(
                      entry.path,
                      size: c.biggest.shortestSide.clamp(16, 128),
                    )
                  : FileTypeIcon.folder(
                      entry.path,
                      size: c.biggest.shortestSide.clamp(16, 128),
                      color: entry.available ? null : theme.disabledColor,
                      fallback: placeIcon(entry.name) == Icons.folder_outlined
                          ? Icons.folder
                          : placeIcon(entry.name),
                    ),
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
