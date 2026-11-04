import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';

import 'desktop_helpers.dart';

/// Bugs the monkey test (test/monkey) found on the desktop shell.
void main() {
  testWidgets('expanding the sidebar never squeezes its rows', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    final notifier = app.container.read(
      desktopSidebarCollapsedProvider.notifier,
    )..toggle();
    await tester.pumpAndSettle();
    notifier.toggle();
    // Every frame of the 120 ms animation.
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
      app.container.read(desktopDetailsPaneProvider.notifier).toggle();
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
