import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/features/onboarding/domain/onboarding_state.dart';
import 'package:kfm/features/onboarding/ui/feature_hint.dart';
import 'package:kfm/features/onboarding/ui/onboarding_controller.dart';
import 'package:kfm/features/onboarding/ui/swipe_tutorial_overlay.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/settings_helpers.dart';

const _trash = 'Swipe left to throw away';
const _keep = 'Swipe right to keep';
const _undoStep = 'Made a mistake? Tap Undo';

FakeFileSource _files([int n = 3]) {
  final files = FakeFileSource();
  for (var i = 0; i < n; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  return files;
}

Future<TestApp> _pump(
  WidgetTester tester, {
  bool tutorialDone = false,
  int files = 3,
}) async {
  final app = await pumpApp(
    tester,
    files: _files(files),
    tutorialDone: tutorialDone,
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Future<bool> _doneSetting(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  return await app.container
      .read(settingsRepositoryProvider)
      .read(AppSettings.onboardingTutorialDone);
}

Future<List<SessionActionRow>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  return await app.db.select(app.db.sessionActions).get();
}

void main() {
  setUp(SwipeDeckController.debugResetRestoreNotice);

  group('OnboardingController', () {
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
      return c;
    }

    test('fresh install: not done; Done persists across a restart', () async {
      final first = launch();
      final state = await first.read(onboardingControllerProvider.future);
      expect(state.tutorialDone, isFalse);
      expect(state.seenHints, isEmpty);
      first.read(onboardingControllerProvider.notifier).finishTutorial();
      expect(
        first.read(onboardingControllerProvider).value!.tutorialDone,
        isTrue,
      );
      await first.read(dbWriteQueueProvider).flush();

      final second = launch();
      expect(
        (await second.read(onboardingControllerProvider.future)).tutorialDone,
        isTrue,
      );
    });

    test(
      'hints are remembered; Show again resets tutorial and hints',
      () async {
        final c = launch();
        await c.read(onboardingControllerProvider.future);
        c.read(onboardingControllerProvider.notifier)
          ..finishTutorial()
          ..markHintSeen(HintIds.presets);
        await c.read(dbWriteQueueProvider).flush();
        expect(
          await c
              .read(settingsRepositoryProvider)
              .read(AppSettings.onboardingSeenHints),
          [HintIds.presets],
        );

        c.read(onboardingControllerProvider.notifier).showAgain();
        expect(
          c.read(onboardingControllerProvider).value,
          const OnboardingState(tutorialDone: false, seenHints: {}),
        );
        await c.read(dbWriteQueueProvider).flush();
        final settings = c.read(settingsRepositoryProvider);
        expect(
          await settings.read(AppSettings.onboardingTutorialDone),
          isFalse,
        );
        expect(await settings.read(AppSettings.onboardingSeenHints), isEmpty);
      },
    );

    test('an install with session_actions rows skips the tutorial; the '
        'check runs only once', () async {
      final c = launch();
      final session = await c
          .read(sessionRepositoryProvider)
          .getOrCreateActive();
      await db
          .into(db.sessionActions)
          .insert(
            SessionActionsCompanion.insert(
              sessionId: session.id,
              seq: 1,
              actionType: 'keep',
              fileId: 'ms:1',
              payload: '{}',
              previousState: '{}',
              status: ActionStatus.applied,
              createdAt: DateTime.utc(2025),
            ),
          );
      expect(await c.read(undoRepositoryProvider).hasAnyAction(), isTrue);
      expect(
        (await c.read(onboardingControllerProvider.future)).tutorialDone,
        isTrue,
      );
      await c.read(dbWriteQueueProvider).flush();
      // Stored, so a later start doesn't need the query.
      expect(
        await c
            .read(settingsRepositoryProvider)
            .read(AppSettings.onboardingTutorialDone),
        isTrue,
      );
      await db.delete(db.sessionActions).go();
      final again = launch();
      expect(
        (await again.read(onboardingControllerProvider.future)).tutorialDone,
        isTrue,
      );
    });

    test(
      'Show tutorial again survives a restart of an install with swipes',
      () async {
        final c = launch();
        final session = await c
            .read(sessionRepositoryProvider)
            .getOrCreateActive();
        await db
            .into(db.sessionActions)
            .insert(
              SessionActionsCompanion.insert(
                sessionId: session.id,
                seq: 1,
                actionType: 'keep',
                fileId: 'ms:1',
                payload: '{}',
                previousState: '{}',
                status: ActionStatus.applied,
                createdAt: DateTime.utc(2025),
              ),
            );
        expect(
          (await c.read(onboardingControllerProvider.future)).tutorialDone,
          isTrue,
        );
        c.read(onboardingControllerProvider.notifier).showAgain();
        await c.read(dbWriteQueueProvider).flush();
        final again = launch();
        expect(
          (await again.read(onboardingControllerProvider.future)).tutorialDone,
          isFalse,
        );
      },
    );

    test('hasAnyAction is false on an empty table', () async {
      final c = launch();
      expect(await c.read(undoRepositoryProvider).hasAnyAction(), isFalse);
    });
  });

  testWidgets('fresh install: 3 steps over the swipe screen, Done ends it for '
      'good', (tester) async {
    final app = await _pump(tester);
    expect(find.byType(SwipeTutorialOverlay), findsOneWidget);
    expect(find.text(_trash), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(_keep), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(_undoStep), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeTutorialOverlay), findsNothing);
    expect(await _doneSetting(app), isTrue);
  });

  testWidgets('also shows over an empty library', (tester) async {
    await _pump(tester, files: 0);
    expect(find.text(_trash), findsOneWidget);
  });

  testWidgets('Skip on step 1 ends it', (tester) async {
    final app = await _pump(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeTutorialOverlay), findsNothing);
    expect(await _doneSetting(app), isTrue);
  });

  testWidgets('dragging the dummy card advances; the real deck never moves '
      'and nothing is recorded', (tester) async {
    final app = await _pump(tester);
    final deckBefore = app.container.read(swipeDeckControllerProvider).value!;

    // A short drag springs back.
    await tester.drag(find.byIcon(Icons.photo_outlined), const Offset(-30, 0));
    await tester.pumpAndSettle();
    expect(find.text(_trash), findsOneWidget);

    await tester.drag(find.byIcon(Icons.photo_outlined), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text(_keep), findsOneWidget);

    // A drag on the wrong side of the screen hits the barrier.
    await tester.dragFrom(const Offset(20, 300), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text(_keep), findsOneWidget);

    await tester.drag(find.byIcon(Icons.photo_outlined), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text(_undoStep), findsOneWidget);

    // Step 3: tapping the highlighted real Undo does nothing.
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.undo),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text(_undoStep), findsOneWidget);

    expect(await _actions(app), isEmpty);
    final deckAfter = app.container.read(swipeDeckControllerProvider).value!;
    expect(deckAfter.current?.id, deckBefore.current?.id);
    expect(deckAfter.swiped, 0);
  });

  testWidgets('swiping the real card area during the tutorial records '
      'nothing', (tester) async {
    final app = await _pump(tester);
    await tester.drag(
      find.byType(SwipeCard),
      const Offset(-500, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(await _actions(app), isEmpty);
  });

  testWidgets('after the tutorial, swiping works as before', (tester) async {
    final app = await _pump(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect([for (final r in await _actions(app)) r.actionType], ['trash']);
  });

  testWidgets('with animations disabled it still works', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final app = await _pump(tester);
    // The pill shows at once, no animation.
    expect(find.text('→ Trash'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('→ Kept'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await _doneSetting(app), isTrue);
  });

  testWidgets('screen reader: each step is a live region; Next is a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final text = tester.getSemantics(find.text(_trash));
    expect(text.flagsCollection.isLiveRegion, isTrue);
    final next = tester.getSemantics(find.widgetWithText(FilledButton, 'Next'));
    expect(next.flagsCollection.isButton, isTrue);
    expect(next.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Next'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text(_keep)).flagsCollection.isLiveRegion,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('big text (2.0) wraps without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    expect(find.text(_trash), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(_undoStep), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('not shown over the D1 permanent-mode card; shows right after '
      'the choice', (tester) async {
    final app = await _pump(tester, tutorialDone: true);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.deleteMode, DeleteMode.permanent.name);
    await app.container.read(sessionRepositoryProvider).endActive();
    app.container.read(onboardingControllerProvider.notifier).showAgain();
    app.container.invalidate(needsDeleteModeChoiceProvider);
    await tester.pumpAndSettle();
    expect(find.text('Delete permanently this session?'), findsOneWidget);
    expect(find.byType(SwipeTutorialOverlay), findsNothing);

    await tester.tap(find.text('Use trash instead'));
    await tester.pumpAndSettle();
    expect(find.text(_trash), findsOneWidget);
  });

  testWidgets('the restore snackbar waits until the tutorial is gone', (
    tester,
  ) async {
    final app = await _pump(tester, tutorialDone: true);
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    // A new start of the deck with history, tutorial requested again.
    SwipeDeckController.debugResetRestoreNotice();
    app.container.read(onboardingControllerProvider.notifier).showAgain();
    app.container.invalidate(swipeDeckControllerProvider);
    await tester.pumpAndSettle();
    expect(
      app.container.read(swipeDeckControllerProvider).value!.restored,
      isTrue,
    );
    expect(find.text(_trash), findsOneWidget);
    expect(find.text('Continued where you left off'), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Continued where you left off'), findsOneWidget);
  });

  testWidgets('Settings → Swiping → Show tutorial again', (tester) async {
    final app = await _pump(tester, tutorialDone: true);
    app.container
        .read(onboardingControllerProvider.notifier)
        .markHintSeen(HintIds.presets);
    expect(find.byType(SwipeTutorialOverlay), findsNothing);
    await openSettingsSection(tester, 'general');
    final row = find.text('Show tutorial again');
    await tester.scrollUntilVisible(row, 200);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(_trash), findsOneWidget);
    expect(
      app.container.read(onboardingControllerProvider).value!.seenHints,
      isEmpty,
    );
  });

  testWidgets('presets hint: first open of Manage presets only', (
    tester,
  ) async {
    final app = await _pump(tester, tutorialDone: true);
    const hint =
        'A preset saves your swipe setup and filter. Switch with one tap.';
    final router = app.container.read(routerProvider)..go(AppRoutes.presets);
    await tester.pumpAndSettle();
    expect(find.text(hint), findsOneWidget);
    await tester.tap(find.byTooltip('Close hint'));
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);

    router.go(AppRoutes.swipe);
    await tester.pumpAndSettle();
    router.go(AppRoutes.presets);
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);
    await app.container.read(dbWriteQueueProvider).flush();
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.onboardingSeenHints),
      [HintIds.presets],
    );
  });

  testWidgets('action bar hint: on its first appearance only', (tester) async {
    final app = await _pump(tester, tutorialDone: true);
    const hint =
        'Extra actions live here. Turn them off in Settings → Swiping.';
    expect(find.text(hint), findsNothing);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.actionBarEnabled, true);
    final deck = app.container.read(swipeDeckControllerProvider).value!;
    await app.container
        .read(sessionRepositoryProvider)
        .saveLayout(
          deck.session.id,
          SwipeLayout.basic.withActionBar(const [SwipeAction.keep]),
        );
    await app.container
        .read(swipeDeckControllerProvider.notifier)
        .reloadSession();
    await tester.pumpAndSettle();
    expect(find.byType(FeatureHint), findsOneWidget);
    expect(find.text(hint), findsOneWidget);

    await app.container.read(dbWriteQueueProvider).flush();
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.onboardingSeenHints),
      [HintIds.actionBar],
    );

    // Turned off and on again: the bar is back, the hint isn't.
    final settings = app.container.read(settingsRepositoryProvider);
    await settings.write(AppSettings.actionBarEnabled, false);
    await tester.pumpAndSettle();
    expect(find.byType(FeatureHint), findsNothing);
    await settings.write(AppSettings.actionBarEnabled, true);
    await tester.pumpAndSettle();
    expect(find.text('Keep'), findsWidgets);
    expect(find.text(hint), findsNothing);
  });
}
