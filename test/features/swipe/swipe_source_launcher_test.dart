import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/ensure_swipe_session.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

/// p0 … p9 (p9 newest), plus a WhatsApp photo and PDF.
FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  for (var i = 0; i < 10; i++) {
    files.addFile(
      '$_root/DCIM/Camera/p$i.jpg',
      modifiedAt: t.add(Duration(minutes: i)),
    );
  }
  const wa = 'Android/media/com.whatsapp/WhatsApp/Media';
  files
    ..addFile(
      '$_root/$wa/WhatsApp Images/w1.jpg',
      modifiedAt: t.subtract(const Duration(days: 1)),
    )
    ..addFile(
      '$_root/$wa/WhatsApp Documents/w.pdf',
      modifiedAt: t.subtract(const Duration(days: 2)),
    );
  return files;
}

String _id(int i) => 'path:$_root/DCIM/Camera/p$i.jpg';

Future<TestApp> _pump(WidgetTester tester) async {
  final app = await pumpApp(tester, files: _library());
  // Indexer scan → index change (debounced) → deck reload.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

SwipeDeckState _deck(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value!;

String? _current(TestApp app) => _deck(app).current?.name;

Future<void> _open(
  WidgetTester tester,
  TestApp app,
  SwipeSourceRequest request,
) async {
  final result = await app.container
      .read(swipeSourceLauncherProvider.notifier)
      .open(request);
  expect(result, isA<SwipeSourceOpened>());
  await tester.pumpAndSettle();
}

FilesSourceRequest _list(
  List<String> ids, {
  String title = 'Picked',
  String? returnRoute,
}) => FilesSourceRequest(
  origin: SwipeSourceOrigin.browse,
  title: title,
  fileIds: ids,
  returnRoute: returnRoute,
);

Future<void> _swipeRight(WidgetTester tester) async {
  await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
  await tester.pumpAndSettle();
}

String _location(TestApp app) => app.container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .path;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the bar shows the title; the filter button hides; × goes back '
      'to the main deck', (tester) async {
    final app = await _pump(tester);
    expect(find.byTooltip('Filter'), findsOneWidget);
    await _open(tester, app, _list([_id(2), _id(5), _id(1)]));

    expect(find.byTooltip('Back to all files'), findsOneWidget);
    expect(find.text('Picked'), findsOneWidget);
    expect(find.byTooltip('Filter'), findsNothing);
    expect(_current(app), 'p2.jpg');
    await _swipeRight(tester);
    expect(_current(app), 'p5.jpg');

    await tester.tap(find.byTooltip('Back to all files'));
    await tester.pumpAndSettle();
    expect(find.text('Picked'), findsNothing);
    expect(find.byTooltip('Filter'), findsOneWidget);
    expect(_deck(app).source, isNull);
    expect(_current(app), 'p9.jpg');
  });

  testWidgets('a group source shows "Group 2 of 3 · 4/5"', (tester) async {
    final app = await _pump(tester);
    await _open(
      tester,
      app,
      GroupsSourceRequest(
        origin: SwipeSourceOrigin.similar,
        title: 'Similar',
        groups: [
          [_id(0), _id(1)],
          [for (var i = 2; i < 7; i++) _id(i)],
          [_id(7), _id(8), _id(9)],
        ],
      ),
    );
    expect(find.text('Group 1 of 3 · 1/2'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await _swipeRight(tester);
    }
    expect(_current(app), 'p5.jpg');
    expect(find.text('Group 2 of 3 · 4/5'), findsOneWidget);
  });

  testWidgets('system back closes an open source', (tester) async {
    final app = await _pump(tester);
    await _open(tester, app, _list([_id(3), _id(4)]));
    expect(find.text('Picked'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_deck(app).source, isNull);
    expect(find.text('Picked'), findsNothing);
    expect(find.byType(SwipeScreen), findsOneWidget);
  });

  testWidgets('finished source: "Back to swiping" returns to the main deck', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _open(tester, app, _list([_id(3)], returnRoute: AppRoutes.browse));
    await _swipeRight(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('All done in Picked'), findsOneWidget);
    expect(find.text('Back to Browse'), findsOneWidget);

    await tester.tap(find.text('Back to swiping'));
    await tester.pumpAndSettle();
    expect(_deck(app).source, isNull);
    expect(find.text('All done in Picked'), findsNothing);
    expect(_current(app), 'p9.jpg');
    expect(_location(app), AppRoutes.swipe);
  });

  testWidgets('finished source: "Back to Browse" closes it and opens Browse', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _open(tester, app, _list([_id(3)], returnRoute: AppRoutes.browse));
    await _swipeRight(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to Browse'));
    await tester.pumpAndSettle();
    expect(_deck(app).source, isNull);
    expect(_location(app), AppRoutes.browse);
  });

  testWidgets('without a return route only "Back to swiping" shows', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _open(tester, app, _list([_id(3)]));
    await _swipeRight(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('All done in Picked'), findsOneWidget);
    expect(find.text('Back to swiping'), findsOneWidget);
    expect(find.textContaining('Back to Browse'), findsNothing);
  });

  testWidgets('a continued source shows "Continued in {title}"', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _open(tester, app, _list([_id(3), _id(4), _id(5)]));
    await _swipeRight(tester);
    // A new process: the restore note may show again, on a new tree.
    await tester.pumpWidget(const SizedBox.shrink());
    SwipeDeckController.debugResetRestoreNotice();
    app.container.invalidate(swipeDeckControllerProvider);
    await app.container.read(swipeDeckControllerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: app.container, child: const App()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continued in Picked'), findsOneWidget);
    expect(_current(app), 'p4.jpg');
  });

  testWidgets('a refused open shows a snackbar and leaves the deck', (
    tester,
  ) async {
    final app = await _pump(tester);
    final result = await app.container
        .read(swipeSourceLauncherProvider.notifier)
        .open(_list(const []));
    expect(result, isA<SwipeSourceNotOpened>());
    final context = tester.element(find.byType(SwipeScreen));
    showSwipeSourceResult(context, result);
    await tester.pumpAndSettle();
    expect(find.text('Nothing to swipe here'), findsOneWidget);
    expect(_deck(app).source, isNull);
    expect(_current(app), 'p9.jpg');
  });

  group('permanent delete mode, no session', () {
    Future<TestApp> pumpPermanent(WidgetTester tester) async {
      final app = await _pump(tester);
      await app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.deleteMode, 'permanent');
      await app.container.read(sessionRepositoryProvider).endActive();
      app.container.invalidate(needsDeleteModeChoiceProvider);
      await tester.pumpAndSettle();
      expect(find.text('Delete permanently this session?'), findsOneWidget);
      return app;
    }

    Future<Session?> active(TestApp app) =>
        app.container.read(sessionRepositoryProvider).active();

    testWidgets('D1 shows "Opens: {title}"; no session before the choice; '
        'then the source deck opens', (tester) async {
      final app = await pumpPermanent(tester);
      await app.container
          .read(swipeSourceLauncherProvider.notifier)
          .open(_list([_id(6), _id(2)], title: 'Two'));
      await tester.pumpAndSettle();
      expect(find.text('Opens: Two'), findsOneWidget);
      expect(find.text('Delete permanently this session?'), findsOneWidget);
      expect(await active(app), isNull);
      expect(await app.db.select(app.db.swipeSources).get(), isEmpty);

      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      final session = await active(app);
      expect(session?.deleteMode, DeleteMode.permanent);
      expect(find.byTooltip('Back to all files'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(_deck(app).source?.sessionId, session!.id);
      expect(_current(app), 'p6.jpg');
      expect(app.container.read(swipeSourceLauncherProvider), isNull);
    });

    testWidgets('ensureSwipeSession: Cancel returns null and creates nothing', (
      tester,
    ) async {
      final app = await pumpPermanent(tester);
      final ref = tester.element(find.byType(SwipeScreen)) as WidgetRef;
      final context = tester.element(find.byType(SwipeScreen));
      final pending = ensureSwipeSession(context, ref);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(await pending, isNull);
      expect(await active(app), isNull);
    });

    testWidgets('ensureSwipeSession: "Use trash instead" starts a session', (
      tester,
    ) async {
      final app = await pumpPermanent(tester);
      final ref = tester.element(find.byType(SwipeScreen)) as WidgetRef;
      final context = tester.element(find.byType(SwipeScreen));
      final pending = ensureSwipeSession(context, ref);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Use trash instead'),
        ),
      );
      await tester.pumpAndSettle();
      final session = await pending;
      expect(session, isNotNull);
      expect(session!.deleteMode, DeleteMode.trash);
      expect((await active(app))?.id, session.id);
    });
  });

  testWidgets('ensureSwipeSession returns the active session at once', (
    tester,
  ) async {
    final app = await _pump(tester);
    final ref = tester.element(find.byType(SwipeScreen)) as WidgetRef;
    final context = tester.element(find.byType(SwipeScreen));
    final session = await ensureSwipeSession(context, ref);
    expect(session?.id, _deck(app).session.id);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('runOutsideDeck keeps the main position', (tester) async {
    final app = await _pump(tester);
    await _swipeRight(tester);
    await _swipeRight(tester);
    expect(_current(app), 'p7.jpg');
    final deck = _deck(app);
    final targets = [
      for (final i in [0, 1, 2]) (await app.files.stat(_id(i)))!,
    ];
    await app.container
        .read(swipeSourceLauncherProvider.notifier)
        .runOutsideDeck(
          sessionId: deck.session.id,
          origin: SwipeSourceOrigin.similar,
          title: 'Keep best',
          body: () async {
            for (final f in targets) {
              app.container
                  .read(swipeActionDispatcherProvider)
                  .dispatch(deck.session, f, SwipeAction.trash);
            }
          },
        );
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    expect(await app.db.select(app.db.pendingDeletes).get(), hasLength(3));
    expect(_current(app), 'p7.jpg');
    expect(_deck(app).source, isNull);
    expect(find.byTooltip('Back to all files'), findsNothing);
  });

  testWidgets('"Swipe these" in the selection\'s More menu swipes the '
      'selection in order', (tester) async {
    final app = await _pump(tester);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel('p3.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('p8.jpg'));
    await tester.pumpAndSettle();

    await _tap(tester, find.byTooltip('More'));
    await _tap(tester, find.text('Swipe these').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(_location(app), AppRoutes.swipe);
    expect(_deck(app).source?.title, 'Selected files');
    expect(_deck(app).source?.returnRoute, AppRoutes.browse);
    expect([for (final f in _deck(app).upcoming) f.name], ['p3.jpg', 'p8.jpg']);
    expect(find.text('Selected files'), findsOneWidget);
  });

  testWidgets('"Swipe these" on a collection page swipes its photos', (
    tester,
  ) async {
    final app = await _pump(tester);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    final card = find.widgetWithText(InkWell, 'WhatsApp');
    await _tap(tester, card);
    await _tap(tester, find.byTooltip('Swipe these'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(_location(app), AppRoutes.swipe);
    expect(_deck(app).source?.title, 'WhatsApp');
    expect(_deck(app).source?.returnRoute, AppRoutes.browse);
    // Photos and videos only: the PDF stays out.
    expect([for (final f in _deck(app).upcoming) f.name], ['w1.jpg']);
  });
}
