import 'package:flutter/material.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';

// E3: the PL3 sidebar became `DesktopNavPane` (desktop_nav_pane.dart);
// its row widget and place icons stay here.

IconData placeIcon(String name) => switch (name.toLowerCase()) {
  'pictures' || 'afbeeldingen' || 'resimler' => Icons.photo_library_outlined,
  'videos' || "video's" || 'videolar' => Icons.video_library_outlined,
  'downloads' || 'indirilenler' => Icons.download_outlined,
  'documents' || 'documenten' || 'belgeler' => Icons.description_outlined,
  final n when n.length == 2 && n.endsWith(':') => Icons.storage_outlined,
  _ => Icons.folder_outlined,
};

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
    this.trailing,
    this.leading,
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

  /// A small button after the label (PL1: Eject); hidden when collapsed.
  final Widget? trailing;

  /// E3: drawn instead of [icon] (a shell icon).
  final Widget? leading;

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
            height: scaledExtent(context, 36),
            margin: const EdgeInsetsDirectional.symmetric(vertical: 1),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                widget.leading ??
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
    final body = tip == null ? row : Tooltip(message: tip, child: row);
    final trailing = widget.trailing;
    if (trailing == null || widget.collapsed) return body;
    return Row(
      children: [
        Expanded(child: body),
        trailing,
      ],
    );
  }
}
