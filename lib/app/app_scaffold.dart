import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/app/widgets/indexing_chip.dart';
import 'package:kfm/features/onboarding/ui/limited_access_banner.dart';

/// Bottom navigation (rail on wide screens) around the four tabs, with the
/// app-wide banners above the tab content.
class AppScaffold extends StatelessWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Above this width (dp) a NavigationRail replaces the bottom bar (PL1).
  static const wideBreakpoint = 840.0;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      (AppTab.swipe, Icons.swipe_outlined, Icons.swipe, l10n.tabSwipe),
      (AppTab.browse, Icons.folder_outlined, Icons.folder, l10n.tabBrowse),
      (AppTab.trash, Icons.delete_outline, Icons.delete, l10n.tabTrash),
      (
        AppTab.settings,
        Icons.settings_outlined,
        Icons.settings,
        l10n.tabSettings,
      ),
    ];
    final onMediaTab =
        shell.currentIndex == AppTab.swipe.index ||
        shell.currentIndex == AppTab.browse.index;

    final body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          const DbErrorBanner(),
          if (onMediaTab) const LimitedAccessBanner(),
          if (onMediaTab) const IndexingChip(),
          Expanded(child: shell),
        ],
      ),
    );

    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (_, icon, selected, label) in tabs)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (_, icon, selected, label) in tabs)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
