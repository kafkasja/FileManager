import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/handed.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';

/// One labelled button on an enlarged viewer's action bar.
@immutable
class ViewerBarAction {
  const new({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Key? key;
}

/// The action bar of an enlarged file (user feedback: "when a file is
/// enlarged you cannot do anything with it"): labelled icon buttons on a
/// dark strip along the bottom. Phone: full width, ≥48 dp targets, labels
/// wrap to two lines at big text, mirrored for left-handed use (the last
/// button, More, sits at the thumb). Desktop: centred, at most 640 px.
class ViewerActionBar extends ConsumerWidget {
  const new({required this.actions, super.key});

  final List<ViewerBarAction> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = ref.watch(formFactorProvider).isDesktop;
    final buttons = [
      for (final a in actions) Expanded(child: _BarButton(action: a)),
    ];
    final Widget row = desktop
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buttons,
              ),
            ),
          )
        : Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: mirroredFor(handednessOf(ref), buttons),
          );
    return Material(
      color: Colors.black54,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          child: row,
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const new({required this.action});

  final ViewerBarAction action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelMedium;
    return TextButton(
      key: action.key,
      onPressed: action.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        minimumSize: const Size(48, 56),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 2,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(action.icon),
          const SizedBox(height: 4),
          Text(
            action.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            // The button's white (or disabled) colour, the theme's size.
            style: TextStyle(
              fontSize: text?.fontSize,
              fontWeight: text?.fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

/// [FileMenuItem.id]s on the bar itself, in order; everything else of
/// the file menu goes under More. Share is a phone thing (the desktop
/// keeps it under More).
List<String> viewerBarIds({required bool desktop}) => [
  if (!desktop) FileMenuIds.share,
  FileMenuIds.sendLinked,
  FileMenuIds.moveTo,
  FileMenuIds.delete,
];

/// The bar for a file on this device: Share (phone), Send to `device`
/// (while linked), Move to, Delete, and More with the rest of
/// [fileMenuItemsProvider] (Open with, Rename, Copy to, Duplicate,
/// favorites and tags, zip items, Details). One list for the ⋮ menu and
/// every viewer. [onLeft]: a delete or move took the file away.
class LocalViewerBar extends ConsumerWidget {
  const new({required this.file, required this.onLeft, super.key});

  final FileRef file;
  final ValueChanged<FileRef> onLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = ref.watch(formFactorProvider).isDesktop;
    final items = [
      for (final item in ref.watch(fileMenuItemsProvider))
        if (item.isAvailable(file)) item,
    ];
    final onBar = [
      for (final id in viewerBarIds(desktop: desktop))
        ...items.where((i) => i.id == id),
    ];
    final more = [
      for (final item in items)
        if (!onBar.contains(item)) item,
    ];

    Future<void> run(FileMenuItem item) async {
      final result = await item.onSelected(context, ref, file);
      if (item.leaves && result == true) onLeft(file);
    }

    String label(FileMenuItem item) =>
        item.labelFor?.call(context, file) ?? item.label(context);

    return ViewerActionBar(
      actions: [
        for (final item in onBar)
          ViewerBarAction(
            key: ValueKey('viewer-${item.id}'),
            label: label(item),
            icon: item.icon,
            onPressed: () => unawaited(run(item)),
          ),
        if (more.isNotEmpty)
          ViewerBarAction(
            key: const ValueKey('viewer-more'),
            label: context.l10n.viewerMore,
            icon: Icons.more_horiz,
            onPressed: () => unawaited(() async {
              final picked = await showViewerMoreSheet<FileMenuItem>(context, [
                for (final item in more) (item, label(item), item.icon),
              ]);
              if (picked != null && context.mounted) await run(picked);
            }()),
          ),
      ],
    );
  }
}

/// More: the rest of the actions as a list (a bottom sheet on the phone,
/// a dialog on the desktop). Completes with the picked value.
Future<T?> showViewerMoreSheet<T>(
  BuildContext context,
  List<(T value, String label, IconData icon)> entries,
) => showAdaptiveSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label, icon) in entries)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    ),
  ),
);
