import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/swipe/ui/swipe_buttons_row.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester, {bool buttons = true}) async {
  final files = FakeFileSource();
  for (var i = 0; i < 4; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  if (buttons) {
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.swipeButtonsMode, true);
    await tester.pumpAndSettle();
  }
  return app;
}

String? _current(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value?.current?.name;

Future<List<String>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  return [
    for (final r in await app.db.select(app.db.sessionActions).get())
      r.actionType,
  ];
}

Finder _button(String label) => find.descendant(
  of: find.byType(SwipeButtonsRow),
  matching: find.text(label),
);

void main() {
  testWidgets('hidden by default', (tester) async {
    await _pump(tester, buttons: false);
    expect(find.byType(SwipeButtonsRow), findsNothing);
  });

  testWidgets('"Move to trash" flies the card left like a swipe', (
    tester,
  ) async {
    final app = await _pump(tester);
    expect(_button('Move to trash'), findsOneWidget);
    expect(_button('Keep'), findsOneWidget);
    await tester.tap(_button('Move to trash'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('→ Trash'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actions(app), ['trash']);
    expect(await app.db.select(app.db.pendingDeletes).get(), hasLength(1));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a fast double tap applies once', (tester) async {
    final app = await _pump(tester);
    await tester.tap(_button('Keep'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_button('Keep'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(await _actions(app), ['keep']);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('text scale 2.0: no overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    expect(tester.takeException(), isNull);
    expect(_button('Move to trash'), findsOneWidget);
  });

  testWidgets('screen-reader actions on the card: trash, keep, undo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = await _pump(tester, buttons: false);
    final node = tester.getSemantics(find.byType(SwipeCard));
    final labels = node
        .getSemanticsData()
        .customSemanticsActionIds!
        .map((id) => CustomSemanticsAction.getAction(id)!.label)
        .toList();
    expect(labels, containsAll(['Move to trash', 'Keep']));
    expect(labels, isNot(contains('Undo')));
    expect(node.label, contains('Photo, p3.jpg'));

    // Perform "Keep" through the semantics owner.
    final keepId = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
      (id) => CustomSemanticsAction.getAction(id)!.label == 'Keep',
    );
    node.owner!.performAction(node.id, SemanticsAction.customAction, keepId);
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actions(app), ['keep']);
    await tester.pump(const Duration(seconds: 2));
    final after = tester.getSemantics(find.byType(SwipeCard));
    expect(
      after.getSemanticsData().customSemanticsActionIds!.map(
        (id) => CustomSemanticsAction.getAction(id)!.label,
      ),
      contains('Undo'),
    );
    handle.dispose();
  });
}
