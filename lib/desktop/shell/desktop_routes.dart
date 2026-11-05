import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/browse/desktop_browse_screen.dart';
import 'package:kfm/desktop/connect/desktop_devices_screen.dart';
import 'package:kfm/desktop/settings/desktop_settings_screen.dart';
import 'package:kfm/desktop/shell/desktop_app_shell.dart';
import 'package:kfm/desktop/sort/desktop_sort_screen.dart';
import 'package:kfm/desktop/trash/desktop_trash_screen.dart';

/// What `router.dart` shows on the desktop form factor (TASK-PL3). The
/// routes themselves are the phone's; only these builders differ.
Widget desktopShell(StatefulNavigationShell shell) =>
    DesktopAppShell(shell: shell);

/// The Sort section's root: the deck as an Explorer-like grid.
Widget desktopSortScreen() => const DesktopSortScreen();

/// The Browse section's root: the Explorer-like folder view.
Widget desktopBrowseScreen() => const DesktopBrowseScreen();

/// Trash: Details list of the system trash and the pending folder.
Widget desktopTrashScreen() => const DesktopTrashScreen();

/// Settings: categories left, content right; [entry] = deep link (E2).
Widget desktopSettingsScreen({String? entry}) =>
    DesktopSettingsScreen(entry: entry);

/// Devices: share / receive / type a code, devices, transfers (branch 4).
StatefulShellBranch desktopDevicesBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppRoutes.devices,
      builder: (context, state) => const DesktopDevicesScreen(),
    ),
  ],
);
