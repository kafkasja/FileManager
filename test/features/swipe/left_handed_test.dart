import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart';
import 'package:kfm/features/swipe/ui/swipe_buttons_row.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// Trashed files land in the pending folder (listed by name).
class _PendingTrashSource extends FakeFileSource {
  @override
  Future<List<TrashedItem>> listTrashed() async => [
    for (final t in await super.listTrashed())
      TrashedItem(
        trashId: t.trashId,
        original: t.original,
        location: TrashLocation.pendingFolder,
        trashedAt: t.trashedAt,
        expiresAt: t.trashedAt.add(const Duration(days: 7)),
      ),
  ];
}

final Finder _undo = find.widgetWithIcon(IconButton, Icons.undo);

Future<TestApp> _pump(WidgetTester tester, {bool left = false}) async {
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
  if (left) await _setLeft(tester, app, value: true);
  return app;
}

Future<void> _setLeft(
  WidgetTester tester,
  TestApp app, {
  required bool value,
}) async {
  await app.container
      .read(settingsRepositoryProvider)
      .write(AppSettings.leftHanded, value);
  await tester.pumpAndSettle();
}

/// Turns on the P4 bar with Keep + Favorite.
Future<void> _withActionBar(WidgetTester tester, TestApp app) async {
  await app.container
      .read(settingsRepositoryProvider)
      .write(AppSettings.actionBarEnabled, true);
  final deck = app.container.read(swipeDeckControllerProvider).value!;
  await app.container
      .read(sessionRepositoryProvider)
      .saveLayout(
        deck.session.id,
        SwipeLayout.basic.withActionBar(const [
          SwipeAction.keep,
          SwipeAction(SwipeActionType.favorite),
        ]),
      );
  await app.container
      .read(swipeDeckControllerProvider.notifier)
      .reloadSession();
  await tester.pumpAndSettle();
}

double _midX(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

bool _isLeft(WidgetTester tester, Finder f) =>
    tester.getCenter(f).dx < _midX(tester);

/// The swipe screen alone under a forced RTL direction.
Future<void> _pumpRtlSwipe(WidgetTester tester, TestApp app) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: SwipeScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Undo: bottom-left by default, bottom-right left-handed', (
    tester,
  ) async {
    final app = await _pump(tester);
    expect(_isLeft(tester, _undo), isTrue);

    await _setLeft(tester, app, value: true);
    expect(_isLeft(tester, _undo), isFalse);

    await _setLeft(tester, app, value: false);
    expect(_isLeft(tester, _undo), isTrue);
  });

  testWidgets('left-handed: swiping left still trashes', (tester) async {
    final app = await _pump(tester, left: true);
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    final rows = await app.db.select(app.db.sessionActions).get();
    expect([for (final r in rows) r.actionType], ['trash']);
  });

  testWidgets('P9 buttons keep their physical order left-handed', (
    tester,
  ) async {
    final app = await _pump(tester, left: true);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.swipeButtonsMode, true);
    await tester.pumpAndSettle();
    final row = find.byType(SwipeButtonsRow);
    expect(row, findsOneWidget);
    Finder arrow(IconData icon) =>
        find.descendant(of: row, matching: find.byIcon(icon));
    expect(_isLeft(tester, arrow(Icons.arrow_back)), isTrue);
    expect(_isLeft(tester, arrow(Icons.arrow_forward)), isFalse);
  });

  testWidgets('P4 bar starts at the physical left, or right left-handed', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _withActionBar(tester, app);
    Finder bar(String label) => find.descendant(
      of: find.byType(SwipeActionBar),
      matching: find.text(label),
    );
    expect(
      tester.getCenter(bar('Keep')).dx,
      lessThan(tester.getCenter(bar('Favorite')).dx),
    );
    expect(_isLeft(tester, bar('Keep')), isTrue);

    await _setLeft(tester, app, value: true);
    expect(
      tester.getCenter(bar('Keep')).dx,
      greaterThan(tester.getCenter(bar('Favorite')).dx),
    );
    expect(_isLeft(tester, bar('Keep')), isFalse);
  });

  testWidgets('forced RTL: physical sides follow handedness, not direction', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _withActionBar(tester, app);
    await _pumpRtlSwipe(tester, app);
    Finder bar(String label) => find.descendant(
      of: find.byType(SwipeActionBar),
      matching: find.text(label),
    );
    expect(_isLeft(tester, _undo), isTrue);
    expect(_isLeft(tester, bar('Keep')), isTrue);
    expect(
      tester.getCenter(bar('Keep')).dx,
      lessThan(tester.getCenter(bar('Favorite')).dx),
    );

    await _setLeft(tester, app, value: true);
    expect(_isLeft(tester, _undo), isFalse);
    expect(_isLeft(tester, bar('Keep')), isFalse);
    expect(
      tester.getCenter(bar('Keep')).dx,
      greaterThan(tester.getCenter(bar('Favorite')).dx),
    );
  });

  testWidgets('Trash selection bar swaps Restore and Delete forever', (
    tester,
  ) async {
    final files = _PendingTrashSource();
    await files.trashBatch([files.addFile('/s/Download/a.pdf')]);
    final app = await pumpApp(tester, files: files);
    await tester.tap(find.text('Trash').last);
    await tester.pumpAndSettle();
    await tester.longPress(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Restore')).dx,
      lessThan(tester.getCenter(find.text('Delete forever')).dx),
    );

    await _setLeft(tester, app, value: true);
    expect(
      tester.getCenter(find.text('Restore')).dx,
      greaterThan(tester.getCenter(find.text('Delete forever')).dx),
    );
  });

  testWidgets('the setting persists (read back from the database)', (
    tester,
  ) async {
    final app = await _pump(tester, left: true);
    await app.container.read(dbWriteQueueProvider).flush();
    final rows = await app.db.select(app.db.settings).get();
    expect(rows.where((r) => r.key == 'a11y.leftHanded').single.value, 'true');
  });
}
