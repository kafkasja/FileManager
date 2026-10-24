import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/customize_swipes_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester) async {
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
  return app;
}

Future<void> _openScreen(WidgetTester tester, TestApp app) async {
  app.container.read(routerProvider).go(AppRoutes.settings);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Customize swipes'));
  await tester.pumpAndSettle();
  expect(find.byType(CustomizeSwipesScreen), findsOneWidget);
}

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

/// A direction tile (the AppBar's back button uses an arrow too).
Finder _arrow(IconData icon) =>
    find.descendant(of: find.byType(Card), matching: find.byIcon(icon));

Future<void> _assign(WidgetTester tester, IconData arrow, String action) async {
  await tester.tap(_arrow(arrow));
  await tester.pumpAndSettle();
  await tester.tap(_inSheet(action));
  await tester.pumpAndSettle();
}

SwipeLayout _deckLayout(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value!.session.layout;

Future<SwipeLayout> _savedLayout(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final db = app.db;
  final row = await (db.select(
    db.settings,
  )..where((s) => s.key.equals(AppSettings.swipeLayoutCurrent.name))).get();
  return SwipeLayout.decode(
    AppSettings.swipeLayoutCurrent.decodeFromDb(row.single.value),
  );
}

void main() {
  group('Customize swipes screen', () {
    testWidgets('fresh install shows the basic layout', (tester) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      expect(find.text('Move to trash'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);
      expect(find.text('Nothing'), findsNWidgets(2));
      expect(find.text('Reset to basic'), findsNothing);
    });

    testWidgets('assigning Keep to up saves it and swiping up keeps', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      await _assign(tester, Icons.arrow_upward, 'Keep');

      expect(_deckLayout(app).actionFor(SwipeDirection.up), SwipeAction.keep);
      final saved = await _savedLayout(app);
      expect(saved.actionFor(SwipeDirection.up), SwipeAction.keep);

      app.container.read(routerProvider).go(AppRoutes.swipe);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SwipeCard), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        app.container.read(swipeDeckControllerProvider).value!.current!.name,
        'p1.jpg',
      );
    });

    testWidgets('the last action cannot be set to Nothing', (tester) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      await _assign(tester, Icons.arrow_back, 'Nothing');
      expect(_deckLayout(app).directions.keys, [SwipeDirection.right]);

      await tester.tap(_arrow(Icons.arrow_forward));
      await tester.pumpAndSettle();
      final nothing = tester.widget<ListTile>(
        find.ancestor(of: _inSheet('Nothing'), matching: find.byType(ListTile)),
      );
      expect(nothing.enabled, isFalse);
      expect(
        _inSheet('At least one direction needs an action'),
        findsOneWidget,
      );
    });

    testWidgets('Reset to basic asks first, then resets', (tester) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      await _assign(tester, Icons.arrow_downward, 'Move to trash');
      expect(_deckLayout(app).hasVertical, isTrue);

      await tester.scrollUntilVisible(
        find.text('Reset to basic'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reset to basic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_deckLayout(app).hasVertical, isTrue);

      await tester.scrollUntilVisible(
        find.text('Reset to basic'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reset to basic'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();
      expect(_deckLayout(app), SwipeLayout.basic);
      expect(find.text('Reset to basic'), findsNothing);
    });
  });

  group('P2 sub-pickers', () {
    testWidgets('Move to folder… picks an indexed folder', (tester) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      await tester.tap(_arrow(Icons.arrow_upward));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Move to folder…'));
      await tester.pumpAndSettle();
      expect(find.text('Folders with photos'), findsOneWidget);
      await tester.tap(find.text('DCIM').last);
      await tester.pumpAndSettle();
      expect(
        _deckLayout(app).actionFor(SwipeDirection.up),
        const SwipeAction(SwipeActionType.moveTo, targetFolder: '/s/DCIM'),
      );
      expect(find.text('Move to DCIM'), findsOneWidget);
    });

    testWidgets('Add tag… creates a tag and assigns it', (tester) async {
      final app = await _pump(tester);
      await _openScreen(tester, app);
      await tester.tap(_arrow(Icons.arrow_downward));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Add tag…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New tag…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cats');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      final action = _deckLayout(app).actionFor(SwipeDirection.down);
      expect(action?.type, SwipeActionType.addTag);
      expect(find.text('Tag: Cats'), findsOneWidget);
    });
  });

  group('SwipeLayoutController without the app', () {
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

    test('no active session: only the setting changes, no session is made; '
        'it survives a restart and the next session copies it', () async {
      final first = launch();
      await first
          .read(swipeLayoutControllerProvider.notifier)
          .setDirection(SwipeDirection.up, SwipeAction.keep);
      expect(await db.select(db.sessions).get(), isEmpty);

      final second = launch();
      final layout = await second.read(swipeLayoutControllerProvider.future);
      expect(layout.actionFor(SwipeDirection.up), SwipeAction.keep);

      final session = await second
          .read(sessionRepositoryProvider)
          .getOrCreateActive();
      expect(session.layout, layout);
    });

    test('a corrupt saved layout gives basic without crashing', () async {
      await db
          .into(db.settings)
          .insert(
            SettingRow(
              key: AppSettings.swipeLayoutCurrent.name,
              value: AppSettings.swipeLayoutCurrent.encodeToDb('{"direc'),
            ),
          );
      final c = launch();
      expect(
        await c.read(swipeLayoutControllerProvider.future),
        SwipeLayout.basic,
      );
      // A new session made from it is basic too.
      final session = await c
          .read(sessionRepositoryProvider)
          .getOrCreateActive();
      expect(session.layout, SwipeLayout.basic);
    });

    test('a corrupt session layout gives basic', () async {
      final c = launch();
      final session = await c
          .read(sessionRepositoryProvider)
          .getOrCreateActive();
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(session.id))).write(
        const SessionsCompanion(layout: Value('{"directions": "oops"}')),
      );
      final active = await c.read(sessionRepositoryProvider).active();
      expect(active!.layout, SwipeLayout.basic);
    });
  });
}
