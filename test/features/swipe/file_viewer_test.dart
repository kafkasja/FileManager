import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester, int n) async {
  final files = FakeFileSource();
  for (var i = 0; i < n; i++) {
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

String? _current(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value?.current?.name;

Future<void> _swipeDeck(WidgetTester tester, Offset by) async {
  await tester.drag(find.byType(SwipeCard), by);
  await tester.pumpAndSettle();
}

Future<void> _openViewer(WidgetTester tester) async {
  await tester.tap(find.byType(SwipeCard));
  // A tap waits for the double-tap window on the card.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tap opens the viewer; ✕ returns to the same file', (
    tester,
  ) async {
    final app = await _pump(tester, 3);
    await _openViewer(tester);
    expect(find.byType(FileViewer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsNothing, reason: 'covered');

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(FileViewer), findsNothing);
    expect(_current(app), 'p2.jpg');
  });

  testWidgets('swiping in the viewer acts on the deck and shows the next', (
    tester,
  ) async {
    final app = await _pump(tester, 6);
    for (var i = 0; i < 3; i++) {
      await _swipeDeck(tester, const Offset(500, 0));
    }
    expect(_current(app), 'p2.jpg');

    await _openViewer(tester);
    await tester.drag(
      find.descendant(
        of: find.byType(FileViewer),
        matching: find.byType(SwipeCard),
      ),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FileViewer), findsOneWidget, reason: 'stays open');
    expect(_current(app), 'p1.jpg');

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(_current(app), 'p1.jpg');
    await app.container.read(dbWriteQueueProvider).flush();
    expect(await app.db.select(app.db.sessionActions).get(), hasLength(4));
  });

  testWidgets('back closes only the viewer', (tester) async {
    final app = await _pump(tester, 2);
    await _openViewer(tester);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.byType(FileViewer), findsNothing);
    expect(_current(app), 'p1.jpg');
  });

  testWidgets('zoomed in: horizontal drags pan, never swipe', (tester) async {
    final app = await _pump(tester, 3);
    await _openViewer(tester);
    final center = tester.getCenter(find.byType(FileViewer));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.dragFrom(center, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(_current(app), 'p2.jpg');
    expect(await app.db.select(app.db.sessionActions).get(), isEmpty);
  });

  testWidgets('tapping hides the info bar but never the close button', (
    tester,
  ) async {
    await _pump(tester, 2);
    await _openViewer(tester);
    expect(find.textContaining('p1.jpg'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(FileViewer)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('p1.jpg'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);
  });

  group('feedback in the viewer (H3)', () {
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

    Finder inViewer(Finder f) =>
        find.descendant(of: find.byType(FileViewer), matching: f);

    testWidgets('a left swipe shows "→ Trash", vibrates, logs the trash', (
      tester,
    ) async {
      final app = await _pump(tester, 3);
      await _openViewer(tester);
      haptics.clear();
      await tester.drag(
        inViewer(find.byType(SwipeCard)),
        const Offset(-500, 0),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(inViewer(find.text('→ Trash')), findsOneWidget);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
      expect(_current(app), 'p1.jpg');
      await app.container.read(dbWriteQueueProvider).flush();
      final actions = await app.db.select(app.db.sessionActions).get();
      expect(actions.single.actionType, 'trash');
      // ✕ still works while the label is up.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(FileViewer), findsNothing);
    });

    testWidgets('past the threshold: edge hint with its label', (tester) async {
      await _pump(tester, 3);
      await _openViewer(tester);
      haptics.clear();
      final card = inViewer(find.byType(SwipeCard));
      final gesture = await tester.startGesture(tester.getCenter(card));
      await gesture.moveBy(const Offset(-300, 0));
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      expect(inViewer(find.text('→ Trash')), findsOneWidget);
      await gesture.moveBy(const Offset(300, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('vibration off: label shown, no vibration', (tester) async {
      final app = await _pump(tester, 3);
      await app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.hapticsEnabled, false);
      await tester.pumpAndSettle();
      await _openViewer(tester);
      haptics.clear();
      await tester.drag(
        inViewer(find.byType(SwipeCard)),
        const Offset(-500, 0),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(inViewer(find.text('→ Trash')), findsOneWidget);
      expect(haptics, isEmpty);
      await tester.pumpAndSettle();
    });

    testWidgets('an unmapped direction springs back silently', (tester) async {
      final app = await _pump(tester, 3);
      await _openViewer(tester);
      haptics.clear();
      await tester.drag(
        inViewer(find.byType(SwipeCard)),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(_current(app), 'p2.jpg');
      expect(haptics, isEmpty);
      expect(inViewer(find.textContaining('→')), findsNothing);
    });
  });
}
