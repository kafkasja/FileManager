import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/shell/desktop_navigation.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

/// Left sidebar (TASK-PL3 PL3-2 a): the sections, then Places and
/// Collections. Collapses to icons.
class DesktopSidebar extends ConsumerWidget {
  const new({required this.current, required this.onSelect, super.key});

  final DesktopSection current;
  final ValueChanged<DesktopSection> onSelect;

  static const width = 232.0;
  static const collapsedWidth = 60.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final collapsed = ref.watch(desktopSidebarCollapsedProvider);
    final places = ref.watch(desktopPlacesProvider).value ?? const [];
    final tags = (ref.watch(tagsByIdProvider).value?.values.toList() ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final colors = Theme.of(context).colorScheme;
    final sections = [
      (DesktopSection.sort, Icons.swipe_outlined, Icons.swipe),
      (DesktopSection.browse, Icons.folder_outlined, Icons.folder),
      (DesktopSection.trash, Icons.delete_outline, Icons.delete),
      (DesktopSection.devices, Icons.devices_outlined, Icons.devices),
      (DesktopSection.settings, Icons.settings_outlined, Icons.settings),
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: collapsed ? collapsedWidth : width,
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                key: const ValueKey('desktop-sidebar-toggle'),
                tooltip: collapsed
                    ? l10n.desktopSidebarExpand
                    : l10n.desktopSidebarCollapse,
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ref.read(desktopSidebarCollapsedProvider.notifier).toggle(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              children: [
                for (final (s, icon, selectedIcon) in sections)
                  SidebarItem(
                    key: ValueKey('desktop-nav-${s.name}'),
                    icon: s == current ? selectedIcon : icon,
                    label: desktopSectionLabel(l10n, s),
                    selected: s == current,
                    collapsed: collapsed,
                    onTap: () => onSelect(s),
                  ),
                if (!collapsed) _Header(l10n.desktopSidebarPlaces),
                if (collapsed) const Divider(),
                for (final p in places)
                  SidebarItem(
                    key: ValueKey('desktop-place-${p.path}'),
                    icon: placeIcon(p.name),
                    label: p.name,
                    tooltip: p.path,
                    collapsed: collapsed,
                    enabled: p.available,
                    onTap: () => openDesktopFolder(context, ref, p.path),
                  ),
                if (places.isEmpty && !collapsed) _Hint(l10n.desktopNoPlaces),
                if (!collapsed) _Header(l10n.desktopSidebarCollections),
                if (collapsed) const Divider(),
                SidebarItem(
                  key: const ValueKey('desktop-favorites'),
                  icon: Icons.star_outline,
                  label: l10n.desktopFavorites,
                  collapsed: collapsed,
                  onTap: () => context.go(AppRoutes.collectionFavorites),
                ),
                for (final t in tags)
                  SidebarItem(
                    icon: Icons.label_outline,
                    iconColor: Color(t.color),
                    label: t.name,
                    collapsed: collapsed,
                    onTap: () => context.go(AppRoutes.collectionTagFor(t.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData placeIcon(String name) => switch (name.toLowerCase()) {
  'pictures' || 'afbeeldingen' || 'resimler' => Icons.photo_library_outlined,
  'videos' || "video's" || 'videolar' => Icons.video_library_outlined,
  'downloads' || 'indirilenler' => Icons.download_outlined,
  'documents' || 'documenten' || 'belgeler' => Icons.description_outlined,
  final n when n.length == 2 && n.endsWith(':') => Icons.storage_outlined,
  _ => Icons.folder_outlined,
};

class _Header extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 16, 12, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _Hint extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// One row of the sidebar: hover highlight, a rounded accent pill when
/// selected, a tooltip when collapsed.
class SidebarItem extends StatefulWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.collapsed = false,
    this.enabled = true,
    this.tooltip,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool collapsed;
  final bool enabled;
  final String? tooltip;
  final Color? iconColor;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final fg = !widget.enabled
        ? colors.onSurface.withValues(alpha: 0.38)
        : selected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final bg = selected
        ? colors.secondaryContainer
        : _hover
        ? colors.onSurface.withValues(alpha: 0.06)
        : Colors.transparent;
    final row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            height: 36,
            margin: const EdgeInsetsDirectional.symmetric(vertical: 1),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.enabled ? (widget.iconColor ?? fg) : fg,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final tip = widget.collapsed ? widget.label : widget.tooltip;
    return tip == null ? row : Tooltip(message: tip, child: row);
  }
}
