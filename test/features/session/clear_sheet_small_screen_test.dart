import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Monkey seed 1: on a 320 dp phone turned sideways the sheet's rows and
  // buttons overflowed (154 px at the bottom, 3.5 px on the right in Dutch).
  testWidgets('Clear sheet scrolls on a small phone in landscape', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final tile = find.text('Clear / fresh start…');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    // A small phone turned sideways while the sheet is open (640 × 360 dp).
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The buttons are reachable by scrolling.
    await tester.dragUntilVisible(
      find.text('Cancel'),
      find.byType(BottomSheet),
      const Offset(0, -100),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
