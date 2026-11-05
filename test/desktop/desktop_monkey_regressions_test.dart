import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/shell/desktop_nav_pane.dart';
import 'package:kfm/desktop/shell/desktop_side_pane.dart';

import 'desktop_helpers.dart';

/// Bugs the monkey test (test/monkey) found on the desktop shell.
void main() {
  testWidgets('hiding and showing the navigation pane never squeezes rows', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    final notifier = app.container.read(desktopNavPaneShownProvider.notifier)
      ..toggle();
    await tester.pumpAndSettle();
    notifier.toggle();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
  });

  for (final section in ['sort', 'browse', 'trash']) {
    testWidgets('$section fits an 800 × 600 window with the details pane', (
      tester,
    ) async {
      final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
      tester.view.physicalSize = const Size(800, 600);
      app.container
          .read(desktopSidePaneModeProvider.notifier)
          .toggle(DesktopSidePane.details);
      await tester.pumpAndSettle();
      if (section != 'sort') {
        await tester.tap(find.byKey(ValueKey('desktop-nav-$section')).first);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('arrow keys after switching sections back to Favorites (focus '
      'on the shell, pages under Favorites not laid out)', (tester) async {
    await pumpDesktopApp(tester, files: desktopLibrary(3));
    await tester.tap(find.byKey(const ValueKey('desktop-favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desktop-nav-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desktop-favorites')));
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
