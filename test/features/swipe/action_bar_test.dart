import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(
  WidgetTester tester, {
  bool enabled = true,
  List<SwipeAction> bar = const [],
}) async {
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
  await app.container
      .read(settingsRepositoryProvider)
      .write(AppSettings.actionBarEnabled, enabled);
  final deck = app.container.read(swipeDeckControllerProvider).value!;
  await app.container
      .read(sessionRepositoryProvider)
      .saveLayout(deck.session.id, SwipeLayout.basic.withActionBar(bar));
  await app.container
      .read(swipeDeckControllerProvider.notifier)
      .reloadSession();
  await tester.pumpAndSettle();
  return app;
}

String? _current(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value?.current?.name;

Future<List<String>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final rows = await app.db.select(app.db.sessionActions).get();
  return [for (final r in rows) '${r.actionType}:${r.status.name}'];
}

Finder _barButton(String label) => find.descendant(
  of: find.byType(SwipeActionBar),
  matching: find.text(label),
);

const List<SwipeAction> _keepAndFavorite = [
  SwipeAction.keep,
  SwipeAction(SwipeActionType.favorite),
];

void main() {
  testWidgets('fresh install: no bar', (tester) async {
    await _pump(tester, enabled: false, bar: _keepAndFavorite);
    expect(_barButton('Keep'), findsNothing);
  });

  testWidgets('on but empty: still hidden', (tester) async {
    await _pump(tester);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('two buttons; a tap applies like a swipe and undo works', (
    tester,
  ) async {
    final app = await _pump(tester, bar: _keepAndFavorite);
    expect(_barButton('Keep'), findsOneWidget);
    expect(_barButton('Favorite'), findsOneWidget);

    await tester.tap(_barButton('Keep'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('→ Kept'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actions(app), ['keep:applied']);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
    await tester.pumpAndSettle();
    expect(_current(app), 'p3.jpg');
    expect(await _actions(app), ['keep:undone']);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('two taps within 300 ms apply once', (tester) async {
    final app = await _pump(tester, bar: _keepAndFavorite);
    await tester.tap(_barButton('Keep'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_barButton('Keep'));
    await tester.pumpAndSettle();
    expect(await _actions(app), ['keep:applied']);
    expect(_current(app), 'p2.jpg');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a deleted tag: greyed out, explains, records nothing', (
    tester,
  ) async {
    final app = await _pump(
      tester,
      bar: const [SwipeAction(SwipeActionType.addTag, tagId: 42)],
    );
    expect(
      find.descendant(
        of: find.byType(SwipeActionBar),
        matching: find.byIcon(Icons.warning_amber),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tag no longer exists'), findsOneWidget);
    expect(await _actions(app), isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  group('controller (no app)', () {
    late AppDatabase db;
    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    ProviderContainer launch() {
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      c.listen(swipeLayoutControllerProvider, (_, _) {});
      return c;
    }

    test('add, reorder, remove survive a restart; no duplicates', () async {
      final first = launch();
      final ctrl = first.read(swipeLayoutControllerProvider.notifier);
      await ctrl.addBarAction(SwipeAction.keep);
      await ctrl.addBarAction(const SwipeAction(SwipeActionType.favorite));
      await ctrl.addBarAction(SwipeAction.trash);
      await ctrl.addBarAction(SwipeAction.keep); // duplicate: ignored
      await ctrl.moveBarAction(2, 0); // trash first
      await ctrl.removeBarAction(1); // drop keep

      final second = launch();
      final layout = await second.read(swipeLayoutControllerProvider.future);
      expect(layout.actionBar, [
        SwipeAction.trash,
        const SwipeAction(SwipeActionType.favorite),
      ]);
      // A new session copies it.
      final session = await second
          .read(sessionRepositoryProvider)
          .getOrCreateActive();
      expect(session.layout.actionBar, layout.actionBar);
    });
  });
}
