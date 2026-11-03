import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/layout/app_text_size.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

Future<void> _browse(WidgetTester tester, TestApp app) async {
  await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
  await tester.pumpAndSettle();
  app.container.read(desktopBrowseControllerProvider.notifier).open('/s/DCIM');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sort: presets dropdown switches the preset; setup is a dialog', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    final id = await app.container
        .read(presetRepositoryProvider)
        .create(name: 'Holiday', layout: SwipeLayout.basic);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Preset: Basic'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sort-preset-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Manage presets…'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('sort-preset-$id')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(app.container.read(activePresetIdProvider).value, id);
    expect(find.text('Preset: Holiday'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sort-setup')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopSheetDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('desktop-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopSheetDialog), findsNothing);
  });

  testWidgets('Sort: T opens the tag picker as a dialog', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(2));
    await tester.tap(find.text('p1.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pumpAndSettle();
    expect(find.byType(DesktopSheetDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Browse details: dragging a column edge resizes it', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    await _browse(tester, app);
    final handle = find.byKey(const ValueKey('explorer-resize-size'));
    expect(handle, findsOneWidget);
    final cell = find.byKey(const ValueKey('explorer-column-size'));
    final before = tester.getSize(cell).width;
    await tester.drag(handle, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(cell).width, closeTo(before + 60, 1));
    // Double-click resets.
    await tester.tap(handle);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(tester.getSize(cell).width, closeTo(before, 1));
  });

  testWidgets('big text: desktop Sort and Browse lay out without overflow', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(4));
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.textSize, AppTextSize.extraLarge);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('p3.jpg'), findsOneWidget);
    await _browse(tester, app);
    expect(tester.takeException(), isNull);
    // The header (and rows) grew with the text: 32 × 1.6.
    final header = tester.getSize(
      find.byKey(const ValueKey('explorer-resize-size')),
    );
    expect(header.height, closeTo(32 * 1.6, 1));
  });
}
