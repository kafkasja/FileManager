import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';

/// Desktop Browse's address bar: Places › C: › Users › … ; each part opens
/// that folder. Starts at the start edge like Explorer. When the path is
/// longer than the bar, the end (the current folder) stays in view and the
/// start scrolls away; every part is capped at [maxPartFraction] of the
/// bar (long names are ellipsized, full name in a tooltip), so the parent
/// is always visible and clickable.
class DesktopBreadcrumb extends StatelessWidget {
  const new({
    required this.folder,
    required this.onOpen,
    this.subfoldersOf,
    super.key,
  });

  final String? folder;
  final ValueChanged<String?> onOpen;

  /// E3: the ▾ after a part lists that folder's subfolders (Explorer);
  /// null = plain chevrons.
  final Future<List<String>> Function(String folder)? subfoldersOf;

  /// The widest one part may get, as a share of the bar.
  static const maxPartFraction = 0.4;

  /// …and never wider than this.
  static const maxPartWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <(String?, String)>[(null, l10n.desktopHome)];
    final f = folder;
    if (f != null) {
      final abs = f.startsWith('/');
      var acc = '';
      for (final seg in f.split('/')) {
        if (seg.isEmpty) continue;
        acc = acc.isEmpty && !abs ? seg : '$acc/$seg';
        parts.add((acc, seg));
      }
    }
    final theme = Theme.of(context);
    return Container(
      height: scaledExtent(context, 34),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxPart = math.min(
            maxPartWidth,
            constraints.maxWidth * maxPartFraction,
          );
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // The end (current folder) is what stays in view.
            reverse: true,
            child: ConstrainedBox(
              // Short paths start at the start edge, not the end.
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                children: [
                  for (final (i, (path, label)) in parts.indexed) ...[
                    if (i > 0)
                      switch ((subfoldersOf, parts[i - 1].$1)) {
                        (final list?, final parent?) => _Chevron(
                          key: ValueKey('crumb-list-$parent'),
                          list: () => list(parent),
                          onOpen: onOpen,
                        ),
                        _ => Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      },
                    _Part(
                      key: ValueKey('crumb-${path ?? ''}'),
                      label: label,
                      maxWidth: maxPart,
                      onPressed: () => onOpen(path),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A chevron that lists the folder before it (Explorer's ▸ between parts).
class _Chevron extends StatelessWidget {
  const new({required this.list, required this.onOpen, super.key});

  final Future<List<String>> Function() list;
  final ValueChanged<String?> onOpen;

  Future<void> _show(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(
      box.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final folders = await list();
    if (!context.mounted || folders.isEmpty) return;
    final sorted = [...folders]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(at.dx, at.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      constraints: const BoxConstraints(maxHeight: 420, minWidth: 200),
      items: [
        for (final f in sorted)
          PopupMenuItem<String>(
            value: f,
            height: scaledExtent(context, 32),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    f.substring(f.lastIndexOf('/') + 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (picked != null) onOpen(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(4),
    onTap: () => _show(context),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Part extends StatelessWidget {
  const new({
    required this.label,
    required this.maxWidth,
    required this.onPressed,
    super.key,
  });

  final String label;
  final double maxWidth;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: theme.colorScheme.onSurface,
          minimumSize: Size.zero,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    // Long names are cut: the tooltip has the whole name.
    return label.length > 24 ? Tooltip(message: label, child: button) : button;
  }
}
