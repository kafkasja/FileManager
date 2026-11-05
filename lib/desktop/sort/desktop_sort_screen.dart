import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/a11y/file_semantics.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/desktop/shell/desktop_command_bar.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/sort/sort_actions.dart';
import 'package:kfm/desktop/sort/sort_history.dart';
import 'package:kfm/desktop/sort/sort_setup_bar.dart';
import 'package:kfm/desktop/widgets/column_widths.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/desktop/widgets/file_location_actions.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/connect/ui/known_device_names.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_feedback.dart';
import 'package:kfm/features/swipe/ui/swipe_finish_flow.dart';
import 'package:kfm/features/swipe/ui/swipe_source_bar.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/ui/tag_picker_sheet.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';
import 'package:kfm/features/undo/ui/undo_button.dart' show showUndoOutcome;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_sort_screen.g.dart';

/// The Sort view's layout (Large icons by default: photos are judged by
/// their thumbnails). Kept while the app runs.
@Riverpod(keepAlive: true)
class DesktopSortLayout extends _$DesktopSortLayout {
  @override
  ExplorerLayout build() => ExplorerLayout.largeIcons;

  // A notifier method (not a setter) like the other controllers.
  // ignore: use_setters_to_change_properties
  void set(ExplorerLayout layout) => state = layout;
}

/// Undoing more than this many actions from the History panel asks first.
const sortUndoConfirmAbove = 10;

/// Desktop Sort (TASK-PL3, round 7 PL3-1 b): the swipe deck as an
/// Explorer-like grid. Select many files, press one action (toolbar button
/// or key) for all of them; each file gets its own undo row through the
/// shared deck controller. Undo is a visible button, the History panel
/// undoes back to any entry, Space opens Quick look with the same keys.
class DesktopSortScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopSortScreen> createState() => _DesktopSortScreenState();
}

class _DesktopSortScreenState extends ConsumerState<DesktopSortScreen> {
  final _explorer = GlobalKey<ExplorerViewState<FileRef>>();
  ExplorerSelection _sel = ExplorerSelection.empty;
  bool _history = false;
  bool _undoing = false;

  SwipeDeckController get _deck =>
      ref.read(swipeDeckControllerProvider.notifier);

  void _setSelection(ExplorerSelection s, SwipeDeckState deck) {
    setState(() => _sel = s);
    _report(deck);
  }

  /// Status bar + details pane (after the frame: never during a build).
  void _report(SwipeDeckState deck) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var bytes = 0;
      FileRef? focused;
      for (final f in deck.upcoming) {
        if (_sel.contains(f.id)) bytes += f.sizeBytes;
        if (f.id == _sel.focus) focused = f;
      }
      ref
          .read(desktopStatusLineProvider(DesktopSection.sort).notifier)
          .set(
            DesktopStatus(
              selected: _sel.count,
              selectedBytes: bytes,
              left: deck.remaining,
              driveHint: (focused ?? deck.current)?.path,
            ),
          );
      ref
          .read(desktopFocusedFileProvider(DesktopSection.sort).notifier)
          .set(focused);
    });
  }

  void _onDeckChanged(
    AsyncValue<SwipeDeckState>? before,
    AsyncValue<SwipeDeckState> next,
  ) {
    final deck = next.value;
    if (deck == null) return;
    final old = before?.value;
    final order = [for (final f in deck.upcoming) f.id];
    var sel = _sel.retain(order, before: [...?old?.upcoming.map((f) => f.id)]);
    // An undo brought a file back: select it and scroll to it.
    final mark = deck.undoMark;
    if (mark != null && mark.tick != old?.undoMark?.tick) {
      sel = ExplorerSelection(
        ids: {mark.fileId},
        anchor: mark.fileId,
        focus: mark.fileId,
      );
      _explorer.currentState?.reveal(mark.fileId);
    }
    if (sel != _sel) setState(() => _sel = sel);
    _report(deck);
  }

  /// Runs [entry]'s action on the selection (or the focused file).
  void _apply(SortActionEntry entry, SwipeDeckState deck) {
    final files = [
      for (final f in deck.upcoming)
        if (_sel.contains(f.id)) f,
    ];
    if (files.isEmpty) {
      final focus = deck.upcoming.where((f) => f.id == _sel.focus);
      files.addAll(focus);
    }
    _applyFiles(entry, deck, files);
  }

  /// F: the selection to Favorites (a Sort action, one undo row each).
  void _favorite(SwipeDeckState deck) => _apply(
    const SortActionEntry(
      action: SwipeAction(SwipeActionType.favorite),
      key: DesktopKeys.favorite,
    ),
    deck,
  );

  /// T: pick a tag, then tag the selection (a Sort action).
  Future<void> _tag(SwipeDeckState deck) async {
    if (_sel.isEmpty && _sel.focus == null) return;
    final tagId = await showTagPicker(context);
    if (tagId == null || !mounted) return;
    final current = ref.read(swipeDeckControllerProvider).value ?? deck;
    _apply(
      SortActionEntry(
        action: SwipeAction(SwipeActionType.addTag, tagId: tagId),
        key: DesktopKeys.tag,
      ),
      current,
    );
  }

  /// [files] dragged onto [entry]'s button, or the selection.
  void _applyFiles(
    SortActionEntry entry,
    SwipeDeckState deck,
    List<FileRef> files,
  ) {
    if (files.isEmpty) return;
    final result = _deck.applyToFiles(files, entry.action);
    if (result.problem case final p?) SwipeFeedback.explain(context, p);
    if (result.applied > 0) _showFlash(entry, deck, result.applied);
  }

  void _showFlash(SortActionEntry entry, SwipeDeckState deck, int count) {
    final l10n = context.l10n;
    final label = actionLabel(
      l10n,
      entry.action,
      deleteMode: deck.session.deleteMode,
      tagName: ref.read(tagsByIdProvider).value?[entry.action.tagId]?.name,
      deviceName: knownDeviceName(ref, entry.action.deviceId),
    );
    // E3: the last action goes to the status bar (the toolbar stays still).
    ref
        .read(desktopStatusMessageProvider.notifier)
        .show(l10n.desktopSortActed(label, count));
  }

  List<FileRef> _selectedFiles(SwipeDeckState deck) => [
    for (final f in deck.upcoming)
      if (_sel.contains(f.id)) f,
  ];

  /// E3: right-click on Sort files: the sort actions, then where the file
  /// is (Open file location, Show in Explorer, Copy as path, Properties).
  Future<void> _contextMenu(
    FileRef? item,
    Offset at,
    SwipeDeckState deck,
    List<SortActionEntry> entries,
  ) async {
    if (item == null) return;
    final l10n = context.l10n;
    final tags = ref.read(tagsByIdProvider).value ?? const {};
    final mode = deck.session.deleteMode;
    final files = _sel.contains(item.id) ? _selectedFiles(deck) : [item];
    if (!_sel.contains(item.id)) {
      _setSelection(
        ExplorerSelection(ids: {item.id}, anchor: item.id, focus: item.id),
        deck,
      );
    }
    await showDesktopContextMenu(context, at, [
      for (final e in entries)
        DesktopMenuEntry(
          label: swipeActionName(l10n, e.action, mode, tags: tags),
          icon: swipeActionIcon(e.action.type),
          shortcut: DesktopKeys.label(e.key),
          onSelected: () => _applyFiles(e, deck, files),
        ),
      DesktopMenuEntry(
        label: l10n.desktopSortFavorite,
        icon: Icons.star_outline,
        shortcut: DesktopKeys.label(DesktopKeys.favorite),
        onSelected: () => _favorite(deck),
      ),
      DesktopMenuEntry(
        label: l10n.desktopQuickLook,
        icon: Icons.visibility_outlined,
        shortcut: DesktopKeys.label(DesktopKeys.quickLook),
        divider: true,
        onSelected: () => unawaited(_quickLook(deck, entries)),
      ),
      DesktopMenuEntry(
        label: l10n.desktopBrowseOpen,
        icon: Icons.open_in_new,
        onSelected: () => unawaited(openOrExplain(context, ref, files.first)),
      ),
      ...fileLocationMenuEntries(context, ref, files),
    ]);
  }

  void _publishCommands(
    SwipeDeckState deck,
    List<SortActionEntry> entries,
    int undoable,
  ) {
    final l10n = context.l10n;
    final files = _selectedFiles(deck);
    final focus = files.length == 1
        ? files.single
        : deck.upcoming.where((f) => f.id == _sel.focus).firstOrNull;
    final hasSelection = !_sel.isEmpty || _sel.focus != null;
    final tags = ref.read(tagsByIdProvider).value ?? const {};
    final mode = deck.session.deleteMode;
    final commands = [
      ...sortSetupCommands(context, ref, deck),
      // The actions take the selection, or Sort files dragged onto them.
      for (final (i, e) in entries.indexed)
        DesktopCommand(
          id: 'sort-action-${e.action.type.name}-$i',
          key: ValueKey('sort-action-${e.action.type.name}'),
          label: swipeActionShortLabel(
            l10n,
            e.action,
            deleteMode: mode,
            tags: tags,
          ),
          icon:
              e.action.type == SwipeActionType.trash &&
                  mode == DeleteMode.permanent
              ? Icons.delete_forever_outlined
              : swipeActionIcon(e.action.type),
          color: sortActionColor(context, e.action),
          shortcut: DesktopKeys.label(e.key),
          keepLabel: true,
          divider: i == 0,
          onPressed: hasSelection ? () => _apply(e, deck) : null,
          dropOffer: (data, {required copy}) => data.origin != DragOrigin.sort
              ? null
              : DropOffer(
                  label: swipeActionName(l10n, e.action, mode, tags: tags),
                  onDrop: () async => _applyFiles(e, deck, data.files),
                ),
        ),
      DesktopCommand(
        id: 'sort-favorite',
        key: const ValueKey('sort-favorite'),
        label: l10n.desktopSortFavorite,
        icon: Icons.star_outline,
        shortcut: DesktopKeys.label(DesktopKeys.favorite),
        onPressed: hasSelection ? () => _favorite(deck) : null,
      ),
      DesktopCommand(
        id: 'sort-tag',
        key: const ValueKey('sort-tag'),
        label: l10n.desktopSortTag,
        icon: Icons.label_outline,
        shortcut: DesktopKeys.label(DesktopKeys.tag),
        onPressed: hasSelection ? () => unawaited(_tag(deck)) : null,
      ),
      DesktopCommand(
        id: 'sort-open-location',
        label: l10n.desktopOpenFileLocation,
        icon: Icons.folder_open_outlined,
        divider: true,
        onPressed: focus == null ? null : () => openFileLocation(ref, focus),
      ),
      DesktopCommand(
        id: 'sort-copy-path',
        label: l10n.desktopCopyAsPath,
        icon: Icons.content_paste_go,
        shortcut: DesktopKeys.label(DesktopKeys.copyAsPath),
        onPressed: files.isEmpty && focus == null
            ? null
            : () => unawaited(
                copyPathsAsText(ref, [
                  for (final f in files.isEmpty ? [focus!] : files) f.path,
                ]),
              ),
      ),
      // Always there (round 7: older users don't know Ctrl+Z).
      DesktopCommand(
        id: 'sort-undo',
        key: const ValueKey('sort-undo'),
        label: l10n.undo,
        icon: _undoing ? Icons.hourglass_empty : Icons.undo,
        shortcut: DesktopKeys.label(DesktopKeys.undo),
        keepLabel: true,
        divider: true,
        onPressed: undoable > 0 && !_undoing
            ? () => unawaited(_undoSteps(1))
            : null,
      ),
      DesktopCommand(
        id: 'sort-history',
        key: const ValueKey('sort-history-toggle'),
        label: l10n.desktopSortHistory,
        icon: Icons.history,
        shortcut: DesktopKeys.label(DesktopKeys.history),
        onPressed: () => setState(() => _history = !_history),
      ),
      if (deck.swiped > 0)
        DesktopCommand(
          id: 'sort-done',
          key: const ValueKey('sort-done'),
          label: l10n.swipeDone,
          icon: Icons.check,
          keepLabel: true,
          onPressed: () => unawaited(finishSwipeSession(context, ref, deck)),
        ),
    ];
    final layout = ref.read(desktopSortLayoutProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(desktopCommandsProvider(DesktopSection.sort).notifier)
          .set(commands);
      ref
          .read(desktopViewTogglesProvider(DesktopSection.sort).notifier)
          .set(
            DesktopViewToggle(
              details: layout == ExplorerLayout.details,
              onChanged: (d) => ref
                  .read(desktopSortLayoutProvider.notifier)
                  .set(d ? ExplorerLayout.details : ExplorerLayout.largeIcons),
            ),
          );
    });
  }

  Future<void> _undoSteps(int steps) async {
    if (_undoing || steps <= 0) return;
    if (steps > sortUndoConfirmAbove) {
      final l10n = context.l10n;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.desktopSortUndoManyTitle(steps)),
          content: Text(l10n.desktopSortUndoManyBody(steps)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey('sort-undo-many-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.desktopSortUndoManyConfirm(steps)),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _undoing = true);
    try {
      for (var i = 0; i < steps; i++) {
        final outcome = await _deck.undo();
        if (mounted) showUndoOutcome(context, outcome);
        if (outcome is! Undone) break;
      }
    } finally {
      if (mounted) setState(() => _undoing = false);
    }
  }

  Future<void> _quickLook(
    SwipeDeckState deck,
    List<SortActionEntry> entries,
  ) async {
    final start = _sel.focus ?? deck.current?.id;
    if (start == null) return;
    final l10n = context.l10n;
    final tags = ref.read(tagsByIdProvider).value ?? const {};
    final last = await showQuickLook(
      context,
      startId: start,
      watchFiles: (ref) =>
          ref.watch(swipeDeckControllerProvider).value?.upcoming ?? const [],
      actions: [
        for (final e in entries)
          QuickLookAction(
            label: swipeActionShortLabel(
              l10n,
              e.action,
              deleteMode: deck.session.deleteMode,
              tags: tags,
            ),
            icon: swipeActionIcon(e.action.type),
            color: sortActionColor(context, e.action),
            keyHint: DesktopKeys.label(e.key),
            matches: (event) => sortEntryForKey([e], event) != null,
            run: (file) {
              final r = _deck.applyToFiles([file], e.action);
              if (r.problem case final p? when mounted) {
                SwipeFeedback.explain(context, p);
              }
              return r.applied > 0;
            },
          ),
      ],
    );
    if (!mounted || last == null) return;
    final current = ref.read(swipeDeckControllerProvider).value;
    if (current == null || !current.upcoming.any((f) => f.id == last)) return;
    _setSelection(
      ExplorerSelection(ids: {last}, anchor: last, focus: last),
      current,
    );
    _explorer.currentState?.reveal(last);
  }

  KeyEventResult _onGridKey(
    KeyEvent event,
    SwipeDeckState deck,
    List<SortActionEntry> entries,
  ) {
    final entry = sortEntryForKey(entries, event);
    if (entry != null) {
      _apply(entry, deck);
      return KeyEventResult.handled;
    }
    final keys = HardwareKeyboard.instance;
    final plain =
        !keys.isControlPressed && !keys.isAltPressed && !keys.isShiftPressed;
    if (plain && event.logicalKey == DesktopKeys.favorite.trigger) {
      _favorite(deck);
      return KeyEventResult.handled;
    }
    if (plain && event.logicalKey == DesktopKeys.tag.trigger) {
      unawaited(_tag(deck));
      return KeyEventResult.handled;
    }
    if (keys.isControlPressed &&
        keys.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC) {
      final files = _selectedFiles(deck);
      unawaited(copyPathsAsText(ref, [for (final f in files) f.path]));
      return KeyEventResult.handled;
    }
    if (keys.isAltPressed && event.logicalKey == LogicalKeyboardKey.enter) {
      final files = _selectedFiles(deck);
      if (files.length == 1) {
        unawaited(showFileProperties(context, ref, files.single));
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space &&
        !keys.isControlPressed) {
      unawaited(_quickLook(deck, entries));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(swipeDeckControllerProvider, _onDeckChanged);
    final needsChoice = ref.watch(needsDeleteModeChoiceProvider);
    if (needsChoice.value != false) {
      return needsChoice.value == true
          ? const _PermanentModeChoice()
          : needsChoice.hasError
          ? _Message(icon: Icons.error_outline, text: l10n.swipeErrorGeneric)
          : const Center(child: CircularProgressIndicator());
    }
    return switch (ref.watch(swipeDeckControllerProvider)) {
      AsyncData(:final value) => _body(context, value),
      AsyncError() => _Message(
        icon: Icons.error_outline,
        text: l10n.swipeErrorGeneric,
        action: TextButton(
          onPressed: () => ref.invalidate(swipeDeckControllerProvider),
          child: Text(l10n.retry),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _body(BuildContext context, SwipeDeckState deck) {
    final entries = sortActionEntries(deck.session.layout);
    final layout = ref.watch(desktopSortLayoutProvider);
    final undoable =
        ref.watch(undoableCountProvider(deck.session.id)).value ?? 0;
    listenPresetSwitchErrors(context, ref);
    _publishCommands(deck, entries, undoable);
    return CallbackShortcuts(
      bindings: {
        DesktopKeys.undo: () => unawaited(_undoSteps(1)),
        DesktopKeys.history: () => setState(() => _history = !_history),
      },
      child: Column(
        children: [
          SwipeSourceBar(deck: deck),
          // E3: the setup row and the action toolbar are the shell's
          // command bar now (`_publishCommands`).
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _content(context, deck, entries, layout)),
                if (_history) ...[
                  const VerticalDivider(width: 1),
                  SortHistoryPanel(
                    key: const ValueKey('sort-history'),
                    sessionId: deck.session.id,
                    deleteMode: deck.session.deleteMode,
                    busy: _undoing,
                    onUndoSteps: _undoSteps,
                    onClose: () => setState(() => _history = false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    SwipeDeckState deck,
    List<SortActionEntry> entries,
    ExplorerLayout layout,
  ) {
    final l10n = context.l10n;
    if (deck.current == null) {
      final scanning = ref.watch(indexStatusProvider).value is IndexScanning;
      final filtered = !FileFilter.decode(deck.session.filterJson).isEmpty;
      return scanning && deck.swiped == 0
          ? _Message(
              icon: Icons.hourglass_empty,
              text: l10n.swipeLookingForPhotos,
            )
          : filtered
          ? _Message(
              icon: Icons.filter_list_off,
              text: deck.remaining == 0 && deck.swiped == 0
                  ? l10n.filterNoMatches
                  : l10n.filterAllDone,
            )
          : _Message(
              icon: deck.swiped > 0
                  ? Icons.check_circle_outline
                  : Icons.photo_library_outlined,
              text: deck.swiped > 0
                  ? l10n.swipeAllDone
                  : l10n.swipeEmptyLibrary,
            );
    }
    return ExplorerView<FileRef>(
      semanticLabelOf: (f) => fileSemanticsLabel(context.l10n, f),
      key: _explorer,
      autofocus: true,
      items: deck.upcoming,
      idOf: (f) => f.id,
      layout: layout,
      selection: _sel,
      onSelectionChanged: (s) => _setSelection(s, deck),
      dragController: ref.read(desktopDragControllerProvider),
      dragDataOf: (ids) => DesktopDragData(
        origin: DragOrigin.sort,
        files: [
          for (final f in deck.upcoming)
            if (ids.contains(f.id)) f,
        ],
      ),
      tileBuilder: (context, f, {required extent}) => FileTileBody(file: f),
      columnWidths:
          ref.watch(desktopColumnWidthsProvider)[ColumnWidthLists.sort] ??
          const {},
      onColumnWidthsChanged: (w) => ref
          .read(desktopColumnWidthsProvider.notifier)
          .save(ColumnWidthLists.sort, w),
      columns: fileColumns<FileRef>(
        context,
        fileOf: (f) => f,
        sortable: false,
        // E3: files come from many folders.
        folderColumn: true,
        nameCell: (context, f) => FileNameCell(name: f.name, file: f),
      ),
      onContextMenu: (item, at) =>
          unawaited(_contextMenu(item, at, deck, entries)),
      onOpen: (_) => unawaited(_quickLook(deck, entries)),
      onKey: (e) => _onGridKey(e, deck, entries),
      onNearEnd: () => unawaited(_deck.loadMore()),
    );
  }
}

class _PermanentModeChoice extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_forever_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.permanentConfirmTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.permanentConfirmBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => startSessionWith(ref, DeleteMode.permanent),
                  child: Text(l10n.permanentConfirmYes),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => startSessionWith(ref, DeleteMode.trash),
                  child: Text(l10n.permanentConfirmUseTrash),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone's empty-state look: an icon and a sentence.
class _Message extends StatelessWidget {
  const new({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
