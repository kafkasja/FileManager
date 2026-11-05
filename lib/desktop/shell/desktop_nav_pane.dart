import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/desktop/shell/desktop_drives.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/shell/quick_access.dart';
import 'package:kfm/desktop/tabs/desktop_tab_strip.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_nav_pane.g.dart';

/// E1 hook: the device rows of the nav pane's Devices group (linked and
/// remembered devices: status dot, "Send to `name`" drop, click = remote
/// browse). Empty until E1c fills it.
@Riverpod(keepAlive: true)
List<Widget> desktopNavDeviceRows(Ref ref) => const [];

/// Nav pane width (`desktop.navWidth`, 160–360 px).
@Riverpod(keepAlive: true)
class DesktopNavWidth extends _$DesktopNavWidth {
  static const min = 160.0;
  static const max = 360.0;
  static const fallback = 232.0;

  @override
  double build() {
    unawaited(_restore());
    return fallback;
  }

  Future<void> _restore() async {
    try {
      final w = await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.desktopNavWidth);
      if (ref.mounted && w > 0) state = w.toDouble().clamp(min, max);
    } on Object {
      // The default stays.
    }
  }

  void resize(double width) => state = width.clamp(min, max);

  void save() => ref
      .read(settingsRepositoryProvider)
      .write(AppSettings.desktopNavWidth, state.round())
      .fireAndForget();
}

/// View → Navigation pane.
@Riverpod(keepAlive: true)
class DesktopNavPaneShown extends _$DesktopNavPaneShown {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

/// The navigation pane (TASK-E3, replaces PL3's sidebar): Sort, Home,
/// Quick access, This PC (drives), Devices, Tags, Trash and Settings at the
/// bottom.
class DesktopNavPane extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final width = ref.watch(desktopNavWidthProvider);
    final loc = ref.watch(desktopTabsControllerProvider).current.location;
    final tabs = ref.read(desktopTabsControllerProvider.notifier);
    final pins = ref.watch(desktopQuickAccessProvider).value ?? const [];
    final tags = (ref.watch(tagsByIdProvider).value?.values.toList() ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final devices = ref.watch(desktopNavDeviceRowsProvider);
    final route = loc is RouteLocation ? loc.uri : null;

    Widget item({
      required Key key,
      required IconData icon,
      required String label,
      required DesktopLocation to,
      DropOfferBuilder? offer,
      Color? iconColor,
    }) {
      final row = SidebarItem(
        key: key,
        icon: icon,
        label: label,
        iconColor: iconColor,
        selected: loc == to,
        onTap: () => tabs.navigate(to),
      );
      return offer == null ? row : DesktopDropTarget(offer: offer, child: row);
    }

    return SizedBox(
      width: width,
      child: ColoredBox(
        color: colors.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                children: [
                  item(
                    key: const ValueKey('desktop-nav-sort'),
                    icon: loc is SortLocation
                        ? Icons.swipe
                        : Icons.swipe_outlined,
                    label: l10n.desktopNavSort,
                    to: const SortLocation(),
                    iconColor: colors.primary,
                  ),
                  item(
                    key: const ValueKey('desktop-nav-browse'),
                    icon: loc is HomeLocation
                        ? Icons.home
                        : Icons.home_outlined,
                    label: l10n.desktopHome,
                    to: const HomeLocation(),
                  ),
                  _Header(
                    l10n.desktopQuickAccess,
                    key: const ValueKey('desktop-nav-quick-access'),
                    offer: (data, {required copy}) {
                      // A folder dropped on the header is pinned.
                      if (data.origin != DragOrigin.browse ||
                          data.folders.isEmpty ||
                          data.files.isNotEmpty) {
                        return null;
                      }
                      return DropOffer(
                        label: l10n.desktopPinToQuickAccess,
                        onDrop: () async {
                          final qa = ref.read(
                            desktopQuickAccessProvider.notifier,
                          );
                          for (final f in data.folders) {
                            await qa.pin(f);
                          }
                        },
                      );
                    },
                  ),
                  for (final p in pins)
                    _PinRow(path: p, selected: loc == FolderLocation(p)),
                  _Header(l10n.desktopThisPc),
                  const DesktopDriveItems(collapsed: false),
                  _Header(l10n.desktopNavDevices),
                  ...devices,
                  item(
                    key: const ValueKey('desktop-nav-devices'),
                    icon: Icons.add_link,
                    label: l10n.desktopConnectDevice,
                    to: const DevicesLocation(),
                    offer: devicesDropOffer(context, ref),
                  ),
                  ...[
                    _Header(l10n.desktopSidebarCollections),
                    DesktopDropTarget(
                      offer: favoriteDropOffer(context, ref),
                      child: SidebarItem(
                        key: const ValueKey('desktop-favorites'),
                        icon: Icons.star_outline,
                        label: l10n.desktopFavorites,
                        selected: route == AppRoutes.collectionFavorites,
                        onTap: () => tabs.navigate(
                          const RouteLocation(AppRoutes.collectionFavorites),
                        ),
                      ),
                    ),
                    for (final t in tags)
                      DesktopDropTarget(
                        offer: tagDropOffer(context, ref, t.id, t.name),
                        child: SidebarItem(
                          key: ValueKey('desktop-tag-${t.id}'),
                          icon: Icons.label_outline,
                          iconColor: Color(t.color),
                          label: t.name,
                          selected: route == AppRoutes.collectionTagFor(t.id),
                          onTap: () => tabs.navigate(
                            RouteLocation(AppRoutes.collectionTagFor(t.id)),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  item(
                    key: const ValueKey('desktop-nav-trash'),
                    icon: loc is TrashLocation
                        ? Icons.delete
                        : Icons.delete_outline,
                    label: l10n.tabTrash,
                    to: const TrashLocation(),
                    offer: trashDropOffer(context, ref),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsetsDirectional.all(6),
              child: item(
                key: const ValueKey('desktop-nav-settings'),
                icon: loc is SettingsLocation
                    ? Icons.settings
                    : Icons.settings_outlined,
                label: l10n.tabSettings,
                to: const SettingsLocation(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinRow extends ConsumerWidget {
  const new({required this.path, required this.selected});

  final String path;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tabs = ref.read(desktopTabsControllerProvider.notifier);
    return GestureDetector(
      onSecondaryTapUp: (d) => unawaited(
        showDesktopContextMenu(context, d.globalPosition, [
          DesktopMenuEntry(
            label: l10n.desktopBrowseOpen,
            icon: Icons.folder_open,
            onSelected: () => tabs.navigate(FolderLocation(path)),
          ),
          DesktopMenuEntry(
            label: l10n.desktopOpenInNewTab,
            icon: Icons.tab,
            onSelected: () => tabs.openInNewTab(FolderLocation(path)),
          ),
          DesktopMenuEntry(
            key: const ValueKey('menu-unpin'),
            label: l10n.desktopUnpinFromQuickAccess,
            icon: Icons.push_pin_outlined,
            divider: true,
            onSelected: () => ref
                .read(desktopQuickAccessProvider.notifier)
                .unpin(path)
                .fireAndForget(),
          ),
        ]),
      ),
      child: DesktopDropTarget(
        offer: folderDropOffer(context, ref, path),
        child: SidebarItem(
          key: ValueKey('desktop-pin-$path'),
          icon: Icons.folder,
          leading: FileTypeIcon.folder(path, size: 18),
          label: folderTitle(path),
          tooltip: path.replaceAll('/', r'\'),
          selected: selected,
          onTap: () => tabs.navigate(FolderLocation(path)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new(this.text, {this.offer, super.key});

  final String text;
  final DropOfferBuilder? offer;

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 14, 10, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
    final o = offer;
    return o == null ? label : DesktopDropTarget(offer: o, child: label);
  }
}

/// The splitter right of the nav pane: drag to resize (saved on release).
class DesktopNavSplitter extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(desktopNavWidthProvider.notifier);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        key: const ValueKey('desktop-nav-splitter'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) =>
            ctl.resize(ref.read(desktopNavWidthProvider) + d.delta.dx),
        onHorizontalDragEnd: (_) => ctl.save(),
        child: SizedBox(
          width: 5,
          child: Center(
            child: VerticalDivider(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}
