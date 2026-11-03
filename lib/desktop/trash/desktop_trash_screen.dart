import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/trash/ui/trash_controller.dart';
import 'package:kfm/features/trash/ui/widgets/expiry_badge.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Which part of the trash the list shows.
enum DesktopTrashGroup { all, system, pending }

/// Desktop Trash (TASK-PL3 step 5): one Details list of the system trash
/// (Recycle Bin on Windows) and the pending-delete folder (name, original
/// location, deleted, size, days left, where), grouped by a filter row;
/// Explorer selection; Restore / Delete forever buttons, keys and menu.
/// Same [TrashController] as the phone's Trash tab.
class DesktopTrashScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopTrashScreen> createState() => _DesktopTrashScreenState();
}

class _DesktopTrashScreenState extends ConsumerState<DesktopTrashScreen> {
  ExplorerSelection _sel = ExplorerSelection.empty;
  DesktopTrashGroup _group = DesktopTrashGroup.all;
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

  Future<void> _deleteForever() async {
    final items = _selected;
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
          shortcut: 'Enter',
          divider: true,
          onSelected: () => unawaited(_preview(item)),
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
    final items = _items = switch (_group) {
      DesktopTrashGroup.all => [...system, ...pending],
      DesktopTrashGroup.system => system,
      DesktopTrashGroup.pending => pending,
    };
    _report();
    final busy = value?.busy ?? false;
    final hasSelection = _sel.ids.any(
      (id) => items.any((i) => i.trashId == id),
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    String summary(List<TrashedItem> list) => l10n.trashSectionSummary(
      list.length,
      formatBytes(
        list.fold(0, (a, i) => a + i.original.sizeBytes),
        locale: locale,
      ),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final g in DesktopTrashGroup.values) ...[
                        ChoiceChip(
                          key: ValueKey('trash-group-${g.name}'),
                          selected: _group == g,
                          onSelected: (_) => setState(() {
                            _group = g;
                            _sel = ExplorerSelection.empty;
                          }),
                          label: Text(switch (g) {
                            DesktopTrashGroup.all => l10n.desktopTrashAll(
                              system.length + pending.length,
                            ),
                            DesktopTrashGroup.system => l10n.desktopTrashGroup(
                              _systemLabel(l10n),
                              summary(system),
                            ),
                            DesktopTrashGroup.pending => l10n.desktopTrashGroup(
                              l10n.trashPending,
                              summary(pending),
                            ),
                          }),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: shortcutHint(
                  l10n,
                  l10n.trashRestore,
                  DesktopKeys.label(DesktopKeys.restore),
                ),
                child: FilledButton.icon(
                  key: const ValueKey('trash-restore'),
                  onPressed: hasSelection && !busy
                      ? () => unawaited(_restore())
                      : null,
                  icon: const Icon(Icons.restore, size: 18),
                  label: Text(l10n.trashRestore),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: shortcutHint(
                  l10n,
                  l10n.trashDeleteForever,
                  DesktopKeys.label(DesktopKeys.delete),
                ),
                child: OutlinedButton.icon(
                  key: const ValueKey('trash-delete-forever'),
                  onPressed: hasSelection && !busy
                      ? () => unawaited(_deleteForever())
                      : null,
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: Text(l10n.trashDeleteForever),
                ),
              ),
              IconButton(
                tooltip: l10n.desktopRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(trashControllerProvider),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
              onOpen: (i) => unawaited(_preview(i)),
              onKey: _onKey,
              onContextMenu: (item, at) => unawaited(_contextMenu(item, at)),
              tileBuilder: (context, i, {required extent}) =>
                  FileTileBody(file: i.preview),
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
