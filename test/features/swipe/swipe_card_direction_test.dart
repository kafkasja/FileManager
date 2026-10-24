import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester, {SwipeLayout? layout}) async {
  final files = FakeFileSource();
  for (var i = 0; i < 3; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  if (layout != null) {
    // Auto-dispose provider: keep it alive like the screen would.
    app.container.listen(swipeLayoutControllerProvider, (_, _) {});
    final controller = app.container.read(
      swipeLayoutControllerProvider.notifier,
    );
    for (final d in SwipeDirection.values) {
      await controller.setDirection(d, layout.actionFor(d));
    }
    await tester.pumpAndSettle();
  }
  return app;
}

String? _current(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value?.current?.name;

Future<List<String>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final rows = await app.db.select(app.db.sessionActions).get();
  return [for (final r in rows) r.actionType];
}

const _upKeeps = SwipeLayout(
  directions: {
    SwipeDirection.left: SwipeAction.trash,
    SwipeDirection.right: SwipeAction.keep,
    SwipeDirection.up: SwipeAction.keep,
  },
);

/// Drags the card by [by] in small steps without releasing.
Future<TestGesture> _hold(WidgetTester tester, Offset by) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(SwipeCard)),
  );
  for (var i = 1; i <= 10; i++) {
    await gesture.moveBy(by / 10);
    await tester.pump();
  }
  return gesture;
}

void main() {
  testWidgets('with up = keep, swiping up keeps the file with feedback', (
    tester,
  ) async {
    final app = await _pump(tester, layout: _upKeeps);
    await tester.drag(find.byType(SwipeCard), const Offset(0, -500));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('→ Kept'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_current(app), 'p1.jpg');
    expect(await _actions(app), ['keep']);
  });

  testWidgets('with a vertical action, a 45° drag fires nothing', (
    tester,
  ) async {
    final app = await _pump(tester, layout: _upKeeps);
    await tester.drag(find.byType(SwipeCard), const Offset(-400, -400));
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actions(app), isEmpty);
  });

  testWidgets('without vertical actions a mostly sideways diagonal trashes', (
    tester,
  ) async {
    final app = await _pump(tester);
    await tester.drag(find.byType(SwipeCard), const Offset(-400, -300));
    await tester.pumpAndSettle();
    expect(_current(app), 'p1.jpg');
    expect(await _actions(app), ['trash']);
  });

  testWidgets('the hint shows the action label while dragging', (tester) async {
    await _pump(tester, layout: _upKeeps);
    var gesture = await _hold(tester, const Offset(0, -300));
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.text('→ Kept'),
      ),
      findsOneWidget,
    );
    await gesture.moveBy(const Offset(0, 300));
    await gesture.up();
    await tester.pumpAndSettle();

    gesture = await _hold(tester, const Offset(-400, 0));
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.text('→ Trash'),
      ),
      findsOneWidget,
    );
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Down has no action: no hint.
    gesture = await _hold(tester, const Offset(0, 300));
    expect(find.text('→ Kept'), findsNothing);
    expect(find.text('→ Trash'), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
