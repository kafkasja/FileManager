import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// A tab's title: the folder name, "Home", "Sort"…
String desktopLocationTitle(AppLocalizations l10n, DesktopLocation loc) =>
    switch (loc) {
      HomeLocation() => l10n.desktopHome,
      FolderLocation(:final path) => folderTitle(path),
      SearchLocation(:final query) => l10n.desktopTabSearch(query),
      SortLocation() => l10n.desktopNavSort,
      TrashLocation() => l10n.tabTrash,
      DevicesLocation() => l10n.desktopNavDevices,
      SettingsLocation() => l10n.tabSettings,
      RouteLocation(:final section) => desktopSectionLabel(l10n, section),
    };

/// `C:` for a drive root, else the last path segment.
String folderTitle(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 || i == path.length - 1 ? path : path.substring(i + 1);
}

/// The icon of a location (shell icon for folders).
Widget desktopLocationIcon(DesktopLocation loc, {double size = 16}) =>
    switch (loc) {
      FolderLocation(:final path) when path.length == 2 && path.endsWith(':') =>
        FileTypeIcon.drive(path, size: size),
      FolderLocation(:final path) => FileTypeIcon.folder(path, size: size),
      HomeLocation() => Icon(Icons.home_outlined, size: size),
      SearchLocation() => Icon(Icons.search, size: size),
      SortLocation() => Icon(Icons.swipe_outlined, size: size),
      TrashLocation() => Icon(Icons.delete_outline, size: size),
      DevicesLocation() => Icon(Icons.devices_outlined, size: size),
      SettingsLocation() => Icon(Icons.settings_outlined, size: size),
      RouteLocation() => Icon(Icons.label_outline, size: size),
    };

/// The tab row on top of the desktop window (TASK-E3): icon + name + ×
/// (hover/active), "+", drag to reorder, middle-click closes, double-click
/// on the empty strip opens a tab, right-click menu, files dropped on a
/// folder tab go there, and holding a drag over a tab switches to it.
class DesktopTabStrip extends ConsumerWidget {
  const new({super.key});

  static const double height = 36;
  static const double minTabWidth = 120;
  static const double maxTabWidth = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final st = ref.watch(desktopTabsControllerProvider);
    final tabs = ref.read(desktopTabsControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final window = MediaQuery.sizeOf(context).width;
    // Explorer shrinks tabs as more open, down to a minimum (then scrolls).
    final tabWidth = ((window - 96) / st.tabs.length).clamp(
      minTabWidth,
      maxTabWidth,
    );
    return Container(
      height: scaledExtent(context, height),
      color: colors.surfaceContainer,
      padding: const EdgeInsetsDirectional.only(start: 6, top: 4),
      child: Row(
        children: [
          Flexible(
            child: ReorderableListView.builder(
              key: const ValueKey('desktop-tab-strip'),
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              itemCount: st.tabs.length,
              onReorderItem: tabs.move,
              proxyDecorator: (child, _, _) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (context, i) {
                final t = st.tabs[i];
                return ReorderableDragStartListener(
                  key: ValueKey('desktop-tab-${t.id}'),
                  index: i,
                  child: SizedBox(
                    width: tabWidth,
                    child: _Tab(
                      index: i,
                      tab: t,
                      active: i == st.active,
                      onlyTab: st.tabs.length == 1,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            key: const ValueKey('desktop-tab-new'),
            tooltip: shortcutHint(
              l10n,
              l10n.desktopTabNew,
              DesktopKeys.label(DesktopKeys.newTab),
            ),
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () => tabs.openInNewTab(const HomeLocation()),
          ),
          // The empty strip: double-click = new tab (Explorer).
          Expanded(
            child: GestureDetector(
              key: const ValueKey('desktop-tab-strip-empty'),
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => tabs.openInNewTab(const HomeLocation()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends ConsumerStatefulWidget {
  const new({
    required this.index,
    required this.tab,
    required this.active,
    required this.onlyTab,
  });

  final int index;
  final DesktopTab tab;
  final bool active;
  final bool onlyTab;

  @override
  ConsumerState<_Tab> createState() => _TabState();
}

class _TabState extends ConsumerState<_Tab> {
  var _hover = false;

  DesktopTabsController get _tabs =>
      ref.read(desktopTabsControllerProvider.notifier);

  Future<void> _menu(Offset at) async {
    final l10n = context.l10n;
    final i = widget.index;
    final n = ref.read(desktopTabsControllerProvider).tabs.length;
    await showDesktopContextMenu(context, at, [
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-new'),
        label: l10n.desktopTabNew,
        icon: Icons.add,
        shortcut: DesktopKeys.label(DesktopKeys.newTab),
        onSelected: () => _tabs.openInNewTab(const HomeLocation()),
      ),
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-duplicate'),
        label: l10n.desktopTabDuplicate,
        icon: Icons.copy_all_outlined,
        onSelected: widget.tab.location.singleInstance
            ? null
            : () => _tabs.duplicate(i),
      ),
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-close'),
        label: l10n.desktopTabClose,
        icon: Icons.close,
        shortcut: DesktopKeys.label(DesktopKeys.closeTab),
        divider: true,
        onSelected: () => _tabs.close(widget.tab.id),
      ),
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-close-others'),
        label: l10n.desktopTabCloseOthers,
        onSelected: n > 1 ? () => _tabs.closeOthers(i) : null,
      ),
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-close-right'),
        label: l10n.desktopTabCloseRight,
        onSelected: i < n - 1 ? () => _tabs.closeToTheRight(i) : null,
      ),
      DesktopMenuEntry(
        key: const ValueKey('tab-menu-reopen'),
        label: l10n.desktopTabReopen,
        icon: Icons.restore,
        shortcut: DesktopKeys.label(DesktopKeys.reopenTab),
        divider: true,
        onSelected: _tabs.canReopen ? _tabs.reopenClosed : null,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final loc = widget.tab.location;
    final title = desktopLocationTitle(l10n, loc);
    final showClose = widget.active || _hover;
    final body = Listener(
      onPointerDown: (e) {
        if (e.buttons == kMiddleMouseButton) _tabs.close(widget.tab.id);
      },
      child: GestureDetector(
        onSecondaryTapUp: (d) => unawaited(_menu(d.globalPosition)),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Semantics(
            selected: widget.active,
            button: true,
            label: title,
            child: InkWell(
              onTap: () => _tabs.activate(widget.index),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
                decoration: BoxDecoration(
                  color: widget.active
                      ? colors.surface
                      : _hover
                      ? colors.onSurface.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    desktopLocationIcon(loc),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Tooltip(
                        message: switch (loc) {
                          FolderLocation(:final path) => path.replaceAll(
                            '/',
                            r'\',
                          ),
                          _ => title,
                        },
                        waitDuration: const Duration(milliseconds: 600),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: widget.active
                                    ? FontWeight.w600
                                    : null,
                              ),
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 24,
                      child: showClose
                          ? IconButton(
                              key: ValueKey(
                                'desktop-tab-close-${widget.index}',
                              ),
                              padding: EdgeInsets.zero,
                              iconSize: 14,
                              tooltip: shortcutHint(
                                l10n,
                                l10n.desktopTabClose,
                                DesktopKeys.label(DesktopKeys.closeTab),
                              ),
                              icon: const Icon(Icons.close),
                              onPressed: () => _tabs.close(widget.tab.id),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Files dropped on a folder tab go into that folder; holding a drag
    // over any tab switches to it (to drop on a subfolder there).
    return DesktopDropTarget(
      offer: switch (loc) {
        FolderLocation(:final path) => folderDropOffer(context, ref, path),
        _ => (_, {required copy}) => null,
      },
      onHoverHold: () => _tabs.activate(widget.index),
      child: body,
    );
  }
}
