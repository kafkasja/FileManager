import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

FakeFileSource _library(int n) {
  final files = FakeFileSource();
  for (var i = 0; i < n; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  return files;
}

Future<TestApp> _pumpWithLibrary(WidgetTester tester, int n) async {
  final app = await pumpApp(tester, files: _library(n));
  // Indexer scan → index change (debounced) → deck reload.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

/// The fly-out (180 ms) starts on the next frame; the label one frame after.
Future<void> _finishFlyOut(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String? _current(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value?.current?.name;

Future<List<String>> _actionTypes(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final rows = await app.db.select(app.db.sessionActions).get();
  return [
    for (final r in rows)
      '${r.actionType}:${r.status == ActionStatus.applied ? 'applied' : r.status.name}',
  ];
}

void main() {
  testWidgets('shows the newest photo first', (tester) async {
    final app = await _pumpWithLibrary(tester, 3);
    expect(_current(app), 'p2.jpg');
    expect(find.byType(SwipeCard), findsOneWidget);
    expect(find.text('0 done · 3 left'), findsOneWidget);
  });

  testWidgets('swipe left past the threshold trashes and shows the next', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_current(app), 'p1.jpg');
    expect(await _actionTypes(app), ['trash:applied']);
    expect(await app.db.select(app.db.pendingDeletes).get(), hasLength(1));
    expect(find.text('1 done · 2 left'), findsOneWidget);
  });

  testWidgets('swipe right keeps: no delete queued', (tester) async {
    final app = await _pumpWithLibrary(tester, 3);
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(_current(app), 'p1.jpg');
    expect(await _actionTypes(app), ['keep:applied']);
    expect(await app.db.select(app.db.pendingDeletes).get(), isEmpty);
  });

  testWidgets('a short slow drag springs back, nothing recorded', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    await tester.timedDrag(
      find.byType(SwipeCard),
      const Offset(-60, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actionTypes(app), isEmpty);
  });

  testWidgets('swiping up (no action in the basic layout) springs back', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    await tester.drag(find.byType(SwipeCard), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actionTypes(app), isEmpty);
  });

  testWidgets('undo brings the file back; disabled when nothing to undo', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    final undo = find.widgetWithIcon(IconButton, Icons.undo);
    expect(tester.widget<IconButton>(undo).onPressed, isNull);

    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await _actionTypes(app), ['trash:undone']);
    expect(await app.db.select(app.db.pendingDeletes).get(), isEmpty);
    expect(tester.widget<IconButton>(undo).onPressed, isNull);
  });

  testWidgets('the last swipe still shows its label on "All done"', (
    tester,
  ) async {
    await _pumpWithLibrary(tester, 1);
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await _finishFlyOut(tester);
    expect(find.text('→ Kept'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('undo shows "↩ Undone"; a double tap undoes only one swipe', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
      await tester.pumpAndSettle();
    }
    expect(_current(app), 'p0.jpg');
    final undo = find.widgetWithIcon(IconButton, Icons.undo);
    await tester.tap(undo);
    // Second tap while the first undo is still running: ignored.
    await tester.tap(find.byType(IconButton).last, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('↩ Undone'), findsOneWidget);
    expect(_current(app), 'p1.jpg');
    expect(await _actionTypes(app), ['keep:applied', 'keep:undone']);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the last swipe shows the all-done state', (tester) async {
    await _pumpWithLibrary(tester, 2);
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
      await tester.pumpAndSettle();
    }
    expect(
      find.text("All done! You've gone through every photo and video."),
      findsOneWidget,
    );
    // Let the debounced progress save run before the tree is torn down.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Done commits the queued deletes and starts a new session', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 3);
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('1 file will be moved to the trash.'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(app.files.trash, hasLength(1));
    expect(_current(app), 'p1.jpg');
    expect(find.text('0 done · 2 left'), findsOneWidget);
  });

  group('feedback (S4)', () {
    late List<String> haptics;

    setUp(() {
      haptics = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('a left swipe vibrates and shows "→ Trash"', (tester) async {
      await _pumpWithLibrary(tester, 3);
      await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
      await _finishFlyOut(tester);
      expect(find.text('→ Trash'), findsOneWidget);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
      await tester.pumpAndSettle();
    });

    testWidgets('fast swipes show only the newest label', (tester) async {
      await _pumpWithLibrary(tester, 3);
      await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
      await _finishFlyOut(tester);
      await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
      await _finishFlyOut(tester);
      expect(find.text('→ Kept'), findsOneWidget);
      expect(find.text('→ Trash'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('vibration off: label still shows, no vibration', (
      tester,
    ) async {
      final app = await _pumpWithLibrary(tester, 3);
      await app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.hapticsEnabled, false);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
      await _finishFlyOut(tester);
      expect(find.text('→ Trash'), findsOneWidget);
      expect(haptics, isEmpty);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('H3: an empty library after the scan hints at permissions', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 0);
    expect(find.text('No photos or videos found.'), findsOneWidget);
    expect(
      find.textContaining('KFM may not be allowed to see them'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Open settings'));
    await tester.pump();
    expect(app.permissions.calls, contains('openAppSettings'));
  });

  testWidgets('V1 bug 3: a touch during the fly-out never strands the card', (
    tester,
  ) async {
    final app = await _pumpWithLibrary(tester, 5);
    String? current() =>
        app.container.read(swipeDeckControllerProvider).value?.current?.name;
    expect(current(), 'p4.jpg');
    final center = tester.getCenter(find.byType(SwipeCard));
    await tester.dragFrom(center, const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 20));
    // A second finger lands and drags while the first card is still flying.
    final touch = await tester.startGesture(center);
    await touch.moveBy(const Offset(-60, 0));
    await touch.moveBy(const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 20));
    await touch.up();
    await tester.pumpAndSettle();
    expect(current(), isNot('p4.jpg'), reason: 'first swipe recorded');
    final before = current();
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(current(), isNot(before), reason: 'the deck still swipes');
    await tester.pump(const Duration(seconds: 2));
  });
}
