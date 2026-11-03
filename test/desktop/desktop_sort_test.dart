import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/desktop/sort/desktop_sort_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

List<String> _upcoming(TestApp app) => [
  for (final f
      in app.container.read(swipeDeckControllerProvider).value?.upcoming ??
          const <FileRef>[])
    f.name,
];

Future<List<String>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final rows = await app.db.select(app.db.sessionActions).get();
  return [
    for (final r in rows)
      if (r.status == ActionStatus.applied) '${r.actionType}:${r.fileId}',
  ];
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _withKey(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  Future<void> Function() body,
) async {
  await tester.sendKeyDownEvent(modifier);
  await body();
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

/// The "→ Trash · 3 files" note goes after 3 s.
Future<void> _flashGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  expect(find.byKey(const ValueKey('sort-flash')), findsNothing);
}

void main() {
  testWidgets('Sort shows the deck as a grid with the action buttons', (
    tester,
  ) async {
    await pumpDesktopApp(tester, files: desktopLibrary(5));
    expect(find.byType(DesktopSortScreen), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.text('p$i.jpg'), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('sort-action-trash')), findsOneWidget);
    expect(find.byKey(const ValueKey('sort-action-keep')), findsOneWidget);
    // The Undo button is always there (disabled until something happened).
    expect(find.byKey(const ValueKey('sort-undo')), findsOneWidget);
    expect(find.text('5 left'), findsOneWidget);
  });

  testWidgets('Shift+click range + Del trashes each file with its own undo '
      'row; the focus moves on', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(6));
    expect(_upcoming(app).first, 'p5.jpg');
    await tester.tap(find.text('p5.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.shiftLeft,
      () => tester.tap(find.text('p3.jpg')),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 selected · 42 B'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.delete);
    expect(_upcoming(app), ['p2.jpg', 'p1.jpg', 'p0.jpg']);
    expect(await _actions(app), [
      'trash:path:/s/DCIM/p5.jpg',
      'trash:path:/s/DCIM/p4.jpg',
      'trash:path:/s/DCIM/p3.jpg',
    ]);
    expect(await app.db.select(app.db.pendingDeletes).get(), hasLength(3));
    expect(find.text('→ Trash · 3 files'), findsOneWidget);
    // The next file is selected: K keeps just it.
    await _key(tester, LogicalKeyboardKey.keyK);
    expect(_upcoming(app), ['p1.jpg', 'p0.jpg']);
    expect((await _actions(app)).last, 'keep:path:/s/DCIM/p2.jpg');
    await _flashGone(tester);
  });

  testWidgets('Ctrl+click picks files; the toolbar button acts on them', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(5));
    await tester.tap(find.text('p4.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.tap(find.text('p1.jpg')),
    );
    await tester.tap(find.byKey(const ValueKey('sort-action-keep')));
    await tester.pumpAndSettle();
    expect(_upcoming(app), ['p3.jpg', 'p2.jpg', 'p0.jpg']);
    expect(await _actions(app), [
      'keep:path:/s/DCIM/p4.jpg',
      'keep:path:/s/DCIM/p1.jpg',
    ]);
  });

  testWidgets('Undo button and Ctrl+Z bring files back one by one', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(4));
    await tester.tap(find.text('p3.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyA),
    );
    await _key(tester, LogicalKeyboardKey.delete);
    expect(_upcoming(app), isEmpty);
    await tester.tap(find.byKey(const ValueKey('sort-undo')));
    await tester.pumpAndSettle();
    expect(_upcoming(app), ['p0.jpg']);
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyZ),
    );
    expect(_upcoming(app), ['p1.jpg', 'p0.jpg']);
    expect(await _actions(app), [
      'trash:path:/s/DCIM/p3.jpg',
      'trash:path:/s/DCIM/p2.jpg',
    ]);
    await _flashGone(tester);
  });

  testWidgets('History: clicking an entry undoes back to it; more than 10 '
      'asks first', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(14));
    await tester.tap(find.text('p13.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyA),
    );
    await _key(tester, LogicalKeyboardKey.keyK);
    expect(_upcoming(app), isEmpty);
    await tester.tap(find.byKey(const ValueKey('sort-history-toggle')));
    await tester.pumpAndSettle();
    // Newest first: entry 2 = the third newest action.
    await tester.tap(find.byKey(const ValueKey('sort-history-2')));
    await tester.pumpAndSettle();
    expect(_upcoming(app), ['p2.jpg', 'p1.jpg', 'p0.jpg']);
    // 11 left in the log: undoing all of them asks.
    await tester.drag(
      find.byKey(const ValueKey('sort-history-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sort-history-10')));
    await tester.pumpAndSettle();
    expect(find.text('Undo 11 actions?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sort-undo-many-confirm')));
    await tester.pumpAndSettle();
    expect(_upcoming(app), hasLength(14));
    expect(await _actions(app), isEmpty);
  });

  testWidgets('arrow keys move the selection; Space opens Quick look with '
      'the same keys', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(4));
    await tester.tap(find.text('p3.jpg'));
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.space);
    expect(find.byKey(const ValueKey('quick-look-close')), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.delete);
    expect((await _actions(app)).single, 'trash:path:/s/DCIM/p2.jpg');
    // Quick look stays open on the next file.
    expect(find.byKey(const ValueKey('quick-look-close')), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyK);
    expect((await _actions(app)).last, 'keep:path:/s/DCIM/p1.jpg');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.byKey(const ValueKey('quick-look-close')), findsNothing);
    expect(_upcoming(app), ['p3.jpg', 'p0.jpg']);
  });

  testWidgets('batched deletes: 60 trashed at once commit 50, the newest 10 '
      'wait', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(60));
    await tester.tap(find.text('p59.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyA),
    );
    await _key(tester, LogicalKeyboardKey.delete);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final rows = await app.db.select(app.db.pendingDeletes).get();
    expect(rows, hasLength(60));
    expect(app.files.trash, hasLength(50));
    expect(app.files.files, hasLength(10));
  });

  testWidgets('a reopened deck starts at the top: files above a sorted one '
      'are still offered', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(5));
    await tester.tap(find.text('p1.jpg'));
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.keyK);
    expect(_upcoming(app), ['p4.jpg', 'p3.jpg', 'p2.jpg', 'p0.jpg']);
    await app.container.read(dbWriteQueueProvider).flush();
    app.container.invalidate(swipeDeckControllerProvider);
    await tester.pumpAndSettle();
    expect(_upcoming(app), ['p4.jpg', 'p3.jpg', 'p2.jpg', 'p0.jpg']);
    await _flashGone(tester);
  });
}
