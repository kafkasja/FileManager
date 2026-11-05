import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/connect/desktop_devices_screen.dart';
import 'package:kfm/desktop/settings/desktop_settings_screen.dart';
import 'package:kfm/desktop/trash/desktop_trash_screen.dart';
import 'package:kfm/features/trash/ui/trash_controller.dart';

import 'desktop_helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Trash: a details list with Restore and Delete forever', (
    tester,
  ) async {
    final files = desktopLibrary(3);
    final app = await pumpDesktopApp(tester, files: files);
    files
      ..trashExternally('path:/s/DCIM/p0.jpg')
      ..trashExternally('path:/s/DCIM/p1.jpg');
    await tester.tap(find.byKey(const ValueKey('desktop-nav-trash')));
    await tester.pumpAndSettle();
    app.container.invalidate(trashControllerProvider);
    await _settle(tester);
    expect(find.byType(DesktopTrashScreen), findsOneWidget);
    expect(find.text('p0.jpg'), findsOneWidget);
    expect(find.text('p1.jpg'), findsOneWidget);
    expect(find.text('Original location'), findsOneWidget);
    expect(find.text('30 days left'), findsNWidgets(2));
    // Nothing selected: the buttons are off.
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.byKey(const ValueKey('cmd-trash-restore')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('p0.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cmd-trash-restore')));
    await _settle(tester);
    expect(files.files.map((f) => f.name), contains('p0.jpg'));
    expect(find.text('p0.jpg'), findsNothing);
    // Del = Delete forever, after the confirm.
    await tester.tap(find.text('p1.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('trash-delete-forever-confirm')),
    );
    await _settle(tester);
    expect(files.trash, isEmpty);
    expect(find.text('Nothing here'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Trash: double-click shows Properties; Restore restores, '
      'Delete forever asks; Empty trash empties', (tester) async {
    final files = desktopLibrary(3);
    final app = await pumpDesktopApp(tester, files: files);
    files
      ..trashExternally('path:/s/DCIM/p0.jpg')
      ..trashExternally('path:/s/DCIM/p1.jpg')
      ..trashExternally('path:/s/DCIM/p2.jpg');
    await tester.tap(find.byKey(const ValueKey('desktop-nav-trash')));
    await tester.pumpAndSettle();
    app.container.invalidate(trashControllerProvider);
    await _settle(tester);
    Future<void> doubleClick(String name) async {
      await tester.tap(find.text(name));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    await doubleClick('p0.jpg');
    expect(find.byKey(const ValueKey('trash-properties')), findsOneWidget);
    for (final k in [
      'trash-props-name',
      'trash-props-location',
      'trash-props-deleted',
      'trash-props-size',
      'trash-props-type',
    ]) {
      expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
    }
    expect(find.text(r'\s\DCIM'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trash-props-restore')));
    await _settle(tester);
    expect(files.files.map((f) => f.name), contains('p0.jpg'));

    await doubleClick('p1.jpg');
    await tester.tap(find.byKey(const ValueKey('trash-props-delete')));
    await tester.pumpAndSettle();
    // The existing confirm.
    expect(
      find.byKey(const ValueKey('trash-delete-forever-confirm')),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(files.trash, hasLength(2));

    await tester.tap(find.byKey(const ValueKey('cmd-trash-empty')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-empty-confirm')));
    await _settle(tester);
    expect(files.trash, isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Settings: categories left, content right, phone-only '
      'sections hidden', (tester) async {
    await pumpDesktopApp(tester);
    await tester.tap(find.byKey(const ValueKey('desktop-nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopSettingsScreen), findsOneWidget);
    // Appearance (100) is open first; Permissions (400) is phone-only.
    expect(find.byKey(const ValueKey('settings-pane-100')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-cat-400')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-cat-300')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-pane-300')), findsOneWidget);
  });

  testWidgets('Devices: start choices, remembered devices and transfers', (
    tester,
  ) async {
    await pumpDesktopApp(tester);
    await tester.tap(find.byKey(const ValueKey('desktop-nav-devices')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DesktopDevicesScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('devices-share')), findsOneWidget);
    expect(find.text('Remembered devices'), findsWidgets);
    expect(find.text('Transfers'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('devices-connect')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('devices-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('devices-back')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('devices-share')), findsOneWidget);
  });
}
