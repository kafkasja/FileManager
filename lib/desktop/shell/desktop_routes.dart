import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/shell/desktop_app_shell.dart';
import 'package:kfm/desktop/sort/desktop_sort_screen.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';

/// What `router.dart` shows on the desktop form factor (TASK-PL3). The
/// routes themselves are the phone's; only these builders differ.
Widget desktopShell(StatefulNavigationShell shell) =>
    DesktopAppShell(shell: shell);

/// The Sort section's root: the deck as an Explorer-like grid.
Widget desktopSortScreen() => const DesktopSortScreen();

/// The Browse section's root (PL3 step 3 replaces the phone screen).
Widget desktopBrowseScreen() => const BrowseScreen();

/// Devices: the Connect screen inside the shell (branch 4).
StatefulShellBranch desktopDevicesBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppRoutes.devices,
      builder: (context, state) => const ConnectScreen(),
    ),
  ],
);
