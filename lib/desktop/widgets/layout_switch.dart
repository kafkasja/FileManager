import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';

/// Large icons / Grid / Details, as three toggle icons (Explorer's view
/// buttons).
class LayoutSwitch extends StatelessWidget {
  const new({required this.layout, required this.onChanged, super.key});

  final ExplorerLayout layout;
  final ValueChanged<ExplorerLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (
        ExplorerLayout.largeIcons,
        Icons.grid_view,
        l10n.desktopLayoutLargeIcons,
      ),
      (ExplorerLayout.grid, Icons.apps, l10n.desktopLayoutGrid),
      (ExplorerLayout.details, Icons.view_list, l10n.desktopLayoutDetails),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (value, icon, label) in options)
          IconButton(
            key: ValueKey('layout-${value.name}'),
            isSelected: value == layout,
            tooltip: label,
            icon: Icon(icon, size: 20),
            onPressed: () => onChanged(value),
          ),
      ],
    );
  }
}
