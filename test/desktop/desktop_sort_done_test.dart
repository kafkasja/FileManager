import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import 'desktop_helpers.dart';

/// Monkey test (test/monkey) find: Done on the desktop Sort screen threw
/// "renameBatchCountProvider was disposed during loading state" (nothing
/// there watches it, unlike the phone's rename pill), and then waited
/// forever on the paused pendingDeleteSummaryProvider.
void main() {
  testWidgets('Done on the Sort screen asks to finish (no rename pill keeps '
      'renameBatchCountProvider alive)', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(5));
    await tester.tap(find.text('p4.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(app.container.read(swipeDeckControllerProvider).value?.swiped, 1);
    await tester.tap(find.byKey(const ValueKey('sort-done')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
