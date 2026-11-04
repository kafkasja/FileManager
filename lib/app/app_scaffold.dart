import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/app/widgets/db_startup_banner.dart';
import 'package:kfm/app/widgets/indexing_chip.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/features/background_jobs/ui/jobs_indicator.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/external_storage/ui/external_notices.dart';
import 'package:kfm/features/onboarding/ui/limited_access_banner.dart';
import 'package:kfm/features/share_in/ui/share_in_prompter.dart';
import 'package:kfm/features/trash/ui/no_trash_prompter.dart';
import 'package:kfm/features/updates/ui/update_banner.dart';

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
          const DbStartupBanner(),
          // U1: "USB drive connected · Open", "Storage removed".
          const ExternalNotices(),
          // N12: send-files offer prompts and their snackbars.
          const IncomingOfferPrompter(),
          // X1: files shared into KFM from other apps.
          const ShareInPrompter(),
          // PL1: "This drive has no Recycle Bin. Delete permanently?"
          const NoTrashPrompter(),
          // PL1: the one-time "still sharing from the tray" notice.
          if (isWindowsHost) const WindowsCloseHost(),
          // X7: never over the swipe card (rule 5).
          if (shell.currentIndex != AppTab.swipe.index) const UpdateBanner(),
          if (onMediaTab) const LimitedAccessBanner(),
          if (onMediaTab) const IndexingChip(),
          Expanded(child: shell),
        ],
      ),
    );
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    if (wide) {
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
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  // X8: transfers and copies on every tab.
                  const JobsIndicator(),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // X8: transfers and copies on every tab, above the tabs.
          const JobsIndicator(),
          NavigationBar(
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
        ],
      ),
    );
  }
}
