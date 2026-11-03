import 'package:flutter/material.dart';

/// One entry of a desktop right-click menu (null [onSelected] = disabled;
/// [divider] draws a line above it).
@immutable
class DesktopMenuEntry {
  const new({
    required this.label,
    required this.onSelected,
    this.icon,
    this.shortcut,
    this.divider = false,
    this.key,
  });

  final String label;
  final IconData? icon;

  /// "Del", "F2"… shown at the end.
  final String? shortcut;
  final VoidCallback? onSelected;
  final bool divider;
  final Key? key;
}

/// Shows a compact menu at [position] (global) and runs the chosen entry.
Future<void> showDesktopContextMenu(
  BuildContext context,
  Offset position,
  List<DesktopMenuEntry> entries,
) async {
  if (entries.isEmpty) return;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(position);
  final theme = Theme.of(context);
  final chosen = await showMenu<DesktopMenuEntry>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(local.dx, local.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
    items: [
      for (final e in entries) ...[
        if (e.divider) const PopupMenuDivider(height: 8),
        PopupMenuItem<DesktopMenuEntry>(
          key: e.key,
          value: e,
          enabled: e.onSelected != null,
          height: 34,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: e.icon == null ? null : Icon(e.icon, size: 18),
              ),
              Expanded(child: Text(e.label, overflow: TextOverflow.ellipsis)),
              if (e.shortcut case final s?)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Text(
                    s,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ],
  );
  chosen?.onSelected?.call();
}
