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
  const new({required this.folder, required this.onOpen, super.key});

  final String? folder;
  final ValueChanged<String?> onOpen;

  /// The widest one part may get, as a share of the bar.
  static const maxPartFraction = 0.4;

  /// …and never wider than this.
  static const maxPartWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <(String?, String)>[(null, l10n.desktopSidebarPlaces)];
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
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
