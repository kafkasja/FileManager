import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/desktop/connect/desktop_devices_screen.dart';
import 'package:kfm/desktop/settings/desktop_settings_screen.dart';
import 'package:kfm/desktop/shell/desktop_app_shell.dart';
import 'package:kfm/desktop/shell/desktop_nav_pane.dart';
import 'package:kfm/desktop/tabs/desktop_tab_strip.dart';
import 'package:kfm/desktop/trash/desktop_trash_screen.dart';

import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

void main() {
  testWidgets('desktop form factor opens the File Explorer layout', (
    tester,
  ) async {
    await pumpDesktopApp(tester, files: desktopLibrary(3));
    expect(find.byType(DesktopAppShell), findsOneWidget);
    expect(find.byType(AppScaffold), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(DesktopTabStrip), findsOneWidget);
    expect(find.byType(DesktopNavPane), findsOneWidget);
    for (final k in [
      'desktop-nav-sort',
      'desktop-nav-browse',
      'desktop-nav-trash',
      'desktop-nav-devices',
      'desktop-nav-settings',
    ]) {
      expect(find.byKey(ValueKey(k)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('desktop-search')), findsOneWidget);
    // Quick access: the index's top folders (not Windows here).
    expect(find.text('Quick access'), findsOneWidget);
    expect(find.text('This PC'), findsOneWidget);
  });

  testWidgets('the mobile form factor keeps the phone shell', (tester) async {
    await pumpApp(tester, files: desktopLibrary(1));
    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.byType(DesktopAppShell), findsNothing);
  });

  testWidgets('nav pane switches sections, Devices included', (tester) async {
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

  testWidgets('details pane toggles by View ▾ and Alt+Shift+P', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(1));
    await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
    await tester.pumpAndSettle();
    expect(find.text('Select a file to see its details'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cmd-view')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cmd-view-details-pane')));
    await tester.pumpAndSettle();
    expect(find.text('Select a file to see its details'), findsOneWidget);
    // Back in the list (a click on it), then the key.
    await tester.tap(find.text('s').last);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('Select a file to see its details'), findsNothing);
  });

  testWidgets('the nav pane resizes by its splitter, 160–360 px', (
    tester,
  ) async {
    await pumpDesktopApp(tester, files: desktopLibrary(1));
    final pane = find.byType(DesktopNavPane);
    expect(tester.getSize(pane).width, DesktopNavWidth.fallback);
    await tester.drag(
      find.byKey(const ValueKey('desktop-nav-splitter')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(pane).width, DesktopNavWidth.max);
    await tester.drag(
      find.byKey(const ValueKey('desktop-nav-splitter')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(pane).width, DesktopNavWidth.min);
  });
}
