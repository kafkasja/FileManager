import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/rename/ui/rename_batch_screen.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester) async {
  final files = FakeFileSource();
  for (var i = 0; i < 4; i++) {
    files.addFile(
      '/s/DCIM/IMG_$i.${i.isEven ? 'jpg' : 'mp4'}',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  final deck = app.container.read(swipeDeckControllerProvider).value!;
  await app.container
      .read(sessionRepositoryProvider)
      .saveLayout(
        deck.session.id,
        SwipeLayout.basic.withDirection(
          SwipeDirection.right,
          const SwipeAction(SwipeActionType.renameBatch),
        ),
      );
  await app.container
      .read(swipeDeckControllerProvider.notifier)
      .reloadSession();
  await tester.pumpAndSettle();
  return app;
}

Future<void> _swipeIntoBatch(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
  }
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Future<List<String>> _names(TestApp app) async => [
  for (final page in await app.files.scan().toList())
    for (final f in page) f.name,
]..sort();

void main() {
  testWidgets('pill, preview, apply, one undo restores everything', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _swipeIntoBatch(tester, 3);
    expect(find.text('✎ 3'), findsOneWidget);

    await tester.tap(find.text('✎ 3'));
    await tester.pumpAndSettle();
    expect(find.byType(RenameBatchScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'holiday_{n}');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // Newest first: IMG_3.mp4, IMG_2.jpg, IMG_1.mp4 went in, in that order.
    expect(find.text('→ holiday_001.mp4'), findsOneWidget);
    expect(find.text('→ holiday_002.jpg'), findsOneWidget);
    expect(find.text('→ holiday_003.mp4'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed 3 files'), findsOneWidget);
    expect(await _names(app), [
      'IMG_0.jpg',
      'holiday_001.mp4',
      'holiday_002.jpg',
      'holiday_003.mp4',
    ]);
    expect(find.text('✎ 3'), findsNothing);

    await app.container.read(dbWriteQueueProvider).flush();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
    await tester.pumpAndSettle();
    expect(await _names(app), [
      'IMG_0.jpg',
      'IMG_1.mp4',
      'IMG_2.jpg',
      'IMG_3.mp4',
    ]);
    // The batch collects again: older undos remove files one by one.
    expect(find.text('✎ 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('invalid patterns disable Rename and explain why', (
    tester,
  ) async {
    await _pump(tester);
    await _swipeIntoBatch(tester, 2);
    await tester.tap(find.text('✎ 2'));
    await tester.pumpAndSettle();
    final rename = find.widgetWithText(FilledButton, 'Rename');

    await tester.enterText(find.byType(TextField).first, 'a/b_{n}');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.textContaining("can't be used"), findsOneWidget);
    expect(tester.widget<FilledButton>(rename).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'holiday');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.text('Add {n} so every file gets its own number'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(rename).onPressed, isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a taken name gets " (1)" in the preview', (tester) async {
    final app = await _pump(tester);
    app.files.addFile('/s/DCIM/x_001.jpg', modifiedAt: DateTime.utc(2020));
    await _swipeIntoBatch(tester, 1);
    await tester.tap(find.text('✎ 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'x_{n}');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // The first swiped file is IMG_3.mp4: x_001.mp4 is free.
    expect(find.text('→ x_001.mp4'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Done with a waiting batch asks first; Discard drops it', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _swipeIntoBatch(tester, 2);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Rename 2 files first?'), findsOneWidget);
    await tester.tap(find.text('Discard batch'));
    await tester.pumpAndSettle();
    // The usual finish confirmation follows.
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('✎'), findsNothing);
    expect(await _names(app), [
      'IMG_0.jpg',
      'IMG_1.mp4',
      'IMG_2.jpg',
      'IMG_3.mp4',
    ]);
    await tester.pump(const Duration(seconds: 2));
  });
}
