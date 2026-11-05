import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/shell/desktop_address_bar.dart';
import 'package:kfm/desktop/shell/desktop_command_bar.dart';
import 'package:kfm/desktop/shell/desktop_location.dart' show FolderLocation;
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/trash/trash_properties_dialog.dart';
import 'package:kfm/desktop/widgets/column_widths.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/trash/ui/trash_controller.dart';
import 'package:kfm/features/trash/ui/widgets/expiry_badge.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Desktop Trash (TASK-PL3 step 5, E3 Recycle Bin): one Details list of
/// the system trash (Recycle Bin on Windows) and the pending-delete folder
/// (name, original location, deleted, size, days left, where); Explorer
/// selection; double-click / Enter / Alt+Enter = Properties with Restore /
/// Delete forever; Space = preview; Restore, Delete forever, Empty trash
/// and Properties in the command bar. Same [TrashController] as the
/// phone's Trash tab.
class DesktopTrashScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopTrashScreen> createState() => _DesktopTrashScreenState();
}

class _DesktopTrashScreenState extends ConsumerState<DesktopTrashScreen> {
  ExplorerSelection _sel = ExplorerSelection.empty;
  List<TrashedItem> _items = const [];

  TrashController get _trash => ref.read(trashControllerProvider.notifier);

  List<TrashedItem> get _selected => [
    for (final i in _items)
      if (_sel.contains(i.trashId)) i,
  ];

  void _setSelection(ExplorerSelection s) {
    setState(() => _sel = s);
    _report();
  }

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var bytes = 0;
      var count = 0;
      for (final i in _items) {
        if (!_sel.contains(i.trashId)) continue;
        count++;
        bytes += i.original.sizeBytes;
      }
      ref
          .read(desktopStatusLineProvider(DesktopSection.trash).notifier)
          .set(
            DesktopStatus(
              items: _items.length,
              selected: count,
              selectedBytes: bytes,
              totalBytes: count == 0
                  ? _items.fold<int>(0, (a, i) => a + i.original.sizeBytes)
                  : null,
            ),
          );
    });
  }

  Future<void> _restore([List<TrashedItem>? items]) async {
    final list = items ?? _selected;
    if (list.isEmpty) return;
    final result = await _trash.restore(list);
    if (mounted) _showResult(result);
  }

  Future<void> _deleteForever([List<TrashedItem>? list]) async {
    final items = list ?? _selected;
    if (items.isEmpty) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trashDeleteForeverTitle(items.length)),
        content: Text(l10n.trashDeleteForeverBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('trash-delete-forever-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.trashDeleteForever),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await _trash.deleteForever(items);
    if (mounted && result.cancelled) _showResult(result);
  }

  void _showResult(TrashActionResult result) {
    final l10n = context.l10n;
    final text = result.cancelled && result.done == 0
        ? l10n.trashCancelled
        : result.alreadyGone > 0
        ? l10n.trashAlreadyRemoved
        : l10n.trashRestored(result.done);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// E3: Recycle Bin's Properties (double-click, Enter, Alt+Enter).
  Future<void> _properties([TrashedItem? item]) async {
    final items = switch (item) {
      final i? when !_sel.contains(i.trashId) => [i],
      _ => _selected,
    };
    if (items.isEmpty) return;
    final action = await showTrashProperties(
      context,
      items,
      systemLabel: _systemLabel(context.l10n),
    );
    if (!mounted) return;
    switch (action) {
      case TrashPropertiesAction.restore:
        await _restore(items);
      case TrashPropertiesAction.deleteForever:
        await _deleteForever(items);
      case TrashPropertiesAction.openLocation:
        ref
            .read(desktopTabsControllerProvider.notifier)
            .openInNewTab(FolderLocation(items.first.original.folderPath));
      case null:
    }
  }

  /// Empty trash: everything, pending items too (with a confirm).
  Future<void> _emptyTrash() async {
    final items = _items;
    if (items.isEmpty) return;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final size = formatBytes(
      items.fold(0, (a, i) => a + i.original.sizeBytes),
      locale: locale,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trashEmptyTitle(items.length)),
        content: Text(l10n.trashEmptyBody(size)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('trash-empty-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.trashEmpty),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await _trash.deleteForever(items);
    if (mounted && result.cancelled) _showResult(result);
  }

  void _publishCommands({required bool hasSelection, required bool busy}) {
    final l10n = context.l10n;
    final commands = [
      DesktopCommand(
        id: 'trash-restore',
        label: l10n.trashRestore,
        icon: Icons.restore,
        shortcut: DesktopKeys.label(DesktopKeys.restore),
        keepLabel: true,
        onPressed: hasSelection && !busy ? () => unawaited(_restore()) : null,
      ),
      DesktopCommand(
        id: 'trash-delete-forever',
        label: l10n.trashDeleteForever,
        icon: Icons.delete_forever_outlined,
        shortcut: DesktopKeys.label(DesktopKeys.delete),
        onPressed: hasSelection && !busy
            ? () => unawaited(_deleteForever())
            : null,
      ),
      DesktopCommand(
        id: 'trash-empty',
        label: l10n.trashEmpty,
        icon: Icons.delete_sweep_outlined,
        onPressed: _items.isNotEmpty && !busy
            ? () => unawaited(_emptyTrash())
            : null,
      ),
      DesktopCommand(
        id: 'trash-properties',
        label: l10n.desktopProperties,
        icon: Icons.info_outline,
        shortcut: DesktopKeys.label(DesktopKeys.properties),
        divider: true,
        onPressed: hasSelection ? () => unawaited(_properties()) : null,
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(desktopCommandsProvider(DesktopSection.trash).notifier)
          .set(commands);
    });
  }

  /// The phone's preview with a Restore button (H3).
  Future<void> _preview(TrashedItem item) => openViewer(
    context,
    item.preview,
    swipeable: false,
    title: item.original.name,
    actions: [
      Builder(
        builder: (viewerContext) => FilledButton.tonal(
          onPressed: () async {
            final result = await _trash.restore([item]);
            if (!viewerContext.mounted) return;
            if (!result.cancelled) Navigator.of(viewerContext).pop();
            _showResult(result);
          },
          child: Text(viewerContext.l10n.trashRestore),
        ),
      ),
    ],
  );

  KeyEventResult _onKey(KeyEvent event) {
    final key = event.logicalKey;
    // Recycle Bin: Del deletes forever (with the confirm).
    if (key == LogicalKeyboardKey.delete) {
      unawaited(_deleteForever());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR && DesktopKeys.ctrl) {
      unawaited(_restore());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isAltPressed) {
      unawaited(_properties());
      return KeyEventResult.handled;
    }
    // Space: the preview (Quick look), like the rest of the desktop app.
    if (key == LogicalKeyboardKey.space) {
      final focus = _sel.focus;
      for (final i in _items) {
        if (i.trashId == focus) unawaited(_preview(i));
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _contextMenu(TrashedItem? item, Offset at) async {
    if (item == null) return;
    final l10n = context.l10n;
    await showDesktopContextMenu(context, at, [
      DesktopMenuEntry(
        key: const ValueKey('trash-menu-restore'),
        label: l10n.trashRestore,
        icon: Icons.restore,
        shortcut: DesktopKeys.label(DesktopKeys.restore),
        onSelected: () => unawaited(_restore()),
      ),
      DesktopMenuEntry(
        label: l10n.trashDeleteForever,
        icon: Icons.delete_forever_outlined,
        shortcut: DesktopKeys.label(DesktopKeys.delete),
        onSelected: () => unawaited(_deleteForever()),
      ),
      if (_sel.count == 1)
        DesktopMenuEntry(
          label: l10n.desktopQuickLook,
          icon: Icons.visibility_outlined,
          shortcut: 'Space',
          divider: true,
          onSelected: () => unawaited(_preview(item)),
        ),
      DesktopMenuEntry(
        key: const ValueKey('trash-menu-properties'),
        label: l10n.desktopProperties,
        icon: Icons.info_outline,
        shortcut: DesktopKeys.label(DesktopKeys.properties),
        divider: _sel.count != 1,
        onSelected: () => unawaited(_properties(item)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trash = ref.watch(trashControllerProvider);
    final value = trash.value;
    final system = value?.system ?? const <TrashedItem>[];
    final pending = value?.pending ?? const <TrashedItem>[];
    final items = _items = [...system, ...pending];
    _report();
    final busy = value?.busy ?? false;
    final hasSelection = _sel.ids.any(
      (id) => items.any((i) => i.trashId == id),
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    ref.listen(desktopRefreshTickProvider, (_, _) {
      ref.invalidate(trashControllerProvider);
    });
    _publishCommands(hasSelection: hasSelection, busy: busy);
    return Column(
      children: [
        Expanded(
          child: switch (trash) {
            AsyncError() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.trashLoadFailed),
                  TextButton(
                    onPressed: () => ref.invalidate(trashControllerProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            _ when value == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when items.isEmpty => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.trashNothingHere,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _ => ExplorerView<TrashedItem>(
              autofocus: true,
              items: items,
              idOf: (i) => i.trashId,
              nameOf: (i) => i.original.name,
              layout: ExplorerLayout.details,
              selection: _sel,
              onSelectionChanged: _setSelection,
              onOpen: (i) => unawaited(_properties(i)),
              onKey: _onKey,
              onContextMenu: (item, at) => unawaited(_contextMenu(item, at)),
              tileBuilder: (context, i, {required extent}) =>
                  FileTileBody(file: i.preview),
              columnWidths:
                  ref.watch(
                    desktopColumnWidthsProvider,
                  )[ColumnWidthLists.trash] ??
                  const {},
              onColumnWidthsChanged: (w) => ref
                  .read(desktopColumnWidthsProvider.notifier)
                  .save(ColumnWidthLists.trash, w),
              columns: _columns(context, l10n, locale),
            ),
          },
        ),
      ],
    );
  }

  String _systemLabel(AppLocalizations l10n) =>
      isWindowsHost ? l10n.desktopTrashRecycleBin : l10n.trashSystem;

  List<ExplorerColumn<TrashedItem>> _columns(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final small = Theme.of(context).textTheme.bodySmall;
    Widget text(String s) =>
        Text(s, style: small, maxLines: 1, overflow: TextOverflow.ellipsis);
    final now = DateTime.now();
    return [
      ExplorerColumn(
        id: 'name',
        label: l10n.browseSortName,
        expand: true,
        cell: (context, i) =>
            FileNameCell(name: i.original.name, file: i.preview),
      ),
      ExplorerColumn(
        id: 'location',
        label: l10n.desktopTrashOriginalLocation,
        width: 240,
        cell: (context, i) => text(i.original.folderPath),
      ),
      ExplorerColumn(
        id: 'deleted',
        label: l10n.desktopTrashDeleted,
        width: 150,
        cell: (context, i) =>
            text(formatDateAndTime(i.trashedAt, locale: locale)),
      ),
      ExplorerColumn(
        id: 'size',
        label: l10n.detailsSize,
        width: 90,
        alignEnd: true,
        cell: (context, i) =>
            text(formatBytes(i.original.sizeBytes, locale: locale)),
      ),
      ExplorerColumn(
        id: 'left',
        label: l10n.desktopTrashDaysLeft,
        width: 110,
        cell: (context, i) => text(switch (i.expiresAt) {
          final e? => switch (daysLeft(e, now)) {
            0 => l10n.trashExpiresToday,
            final d => l10n.trashDaysLeft(d),
          },
          null => '—',
        }),
      ),
      ExplorerColumn(
        id: 'where',
        label: l10n.desktopTrashWhere,
        width: 130,
        cell: (context, i) => text(
          i.location == TrashLocation.pendingFolder
              ? l10n.trashPending
              : _systemLabel(l10n),
        ),
      ),
    ];
  }
}
