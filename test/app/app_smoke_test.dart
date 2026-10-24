import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('App boots on the Swipe tab with localized labels', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.byType(SwipeScreen), findsOneWidget);
    expect(find.text('No photos or videos found.'), findsOneWidget);
    for (final label in ['Swipe', 'Browse', 'Trash', 'Settings']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('all four tabs are reachable', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.text('Browsing is coming soon.'), findsOneWidget);
    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsNWidgets(2));
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
