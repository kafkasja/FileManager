import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_keyboard_shortcuts.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, SwipeLayout layout) async {
    final calls = <String>[];
    await tester.pumpWidget(
      SwipeKeyboardShortcuts(
        layout: layout,
        onSwipe: (d) => calls.add(d.name),
        onUndo: () => calls.add('undo'),
        onOpen: () => calls.add('open'),
        child: const SizedBox.expand(),
      ),
    );
    return calls;
  }

  testWidgets('arrows swipe, Delete trashes, Ctrl+Z undoes, Space opens', (
    tester,
  ) async {
    final calls = await pump(tester, SwipeLayout.basic);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ); // no Ctrl: nothing
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(calls, ['left', 'right', 'up', 'down', 'left', 'undo', 'open']);
  });

  testWidgets('Delete follows the direction mapped to trash', (tester) async {
    final calls = await pump(
      tester,
      const SwipeLayout(
        directions: {
          SwipeDirection.down: SwipeAction.trash,
          SwipeDirection.right: SwipeAction.keep,
        },
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(calls, ['down']);
  });

  testWidgets('no trash direction: Delete does nothing', (tester) async {
    final calls = await pump(
      tester,
      const SwipeLayout(directions: {SwipeDirection.right: SwipeAction.keep}),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(calls, isEmpty);
  });
}
