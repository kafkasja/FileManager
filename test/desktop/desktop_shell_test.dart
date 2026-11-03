import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/desktop/connect/desktop_devices_screen.dart';
import 'package:kfm/desktop/settings/desktop_settings_screen.dart';
import 'package:kfm/desktop/shell/desktop_app_shell.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/trash/desktop_trash_screen.dart';

import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

void main() {
  testWidgets('desktop form factor opens the desktop shell', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(3));
    expect(find.byType(DesktopAppShell), findsOneWidget);
    expect(find.byType(AppScaffold), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    for (final s in DesktopSection.values) {
      expect(find.byKey(ValueKey('desktop-nav-${s.name}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('desktop-search')), findsOneWidget);
    // Places: the index's top folders (not Windows here).
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
  });

  testWidgets('the mobile form factor keeps the phone shell', (tester) async {
    await pumpApp(tester, files: desktopLibrary(1));
    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.byType(DesktopAppShell), findsNothing);
  });

  testWidgets('sidebar switches sections, Devices included', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(1));
    await tester.tap(find.byKey(const ValueKey('desktop-nav-trash')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopTrashScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('desktop-nav-devices')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DesktopDevicesScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('desktop-nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopSettingsScreen), findsOneWidget);
  });

  testWidgets('details pane toggles by button and Ctrl+I', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(1));
    expect(find.text('Select a file to see its details'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('desktop-details-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Select a file to see its details'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Select a file to see its details'), findsNothing);
  });

  testWidgets('sidebar collapses to icons', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(1));
    final sidebar = find.byType(DesktopSidebar);
    expect(tester.getSize(sidebar).width, DesktopSidebar.width);
    await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, DesktopSidebar.collapsedWidth);
  });
}
