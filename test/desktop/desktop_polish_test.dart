import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/shell/window_memory.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';

import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

Future<List<String>> _actions(TestApp app) async {
  await app.container.read(dbWriteQueueProvider).flush();
  final rows = await app.db.select(app.db.sessionActions).get();
  return [
    for (final r in rows)
      if (r.status == ActionStatus.applied) '${r.actionType}:${r.fileId}',
  ];
}

void main() {
  testWidgets('Sort: F favorites, T opens the tag picker; both have buttons', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    expect(find.byKey(const ValueKey('sort-favorite')), findsOneWidget);
    expect(find.byKey(const ValueKey('sort-tag')), findsOneWidget);
    await tester.tap(find.text('p2.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(await _actions(app), ['favorite:path:/s/DCIM/p2.jpg']);
    await tester.tap(find.text('p1.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('left-handed: the Sort action buttons are mirrored', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(2));
    double x(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dx;
    expect(x('sort-action-trash'), lessThan(x('sort-action-keep')));
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.leftHanded, true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(x('sort-action-keep'), lessThan(x('sort-action-trash')));
  });

  testWidgets('Browse remembers its layout and sort', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(1));
    app.container.read(desktopBrowseControllerProvider.notifier)
      ..setLayout(ExplorerLayout.grid)
      ..sortBy(FileColumns.size);
    await app.container.read(dbWriteQueueProvider).flush();
    final settings = app.container.read(settingsRepositoryProvider);
    expect(await settings.read(AppSettings.desktopBrowseLayout), 'grid');
    expect(await settings.read(AppSettings.desktopBrowseSort), 'size:desc');
    app.container.invalidate(desktopBrowseControllerProvider);
    app.container.read(desktopBrowseControllerProvider);
    await tester.pump(const Duration(milliseconds: 100));
    final st = app.container.read(desktopBrowseControllerProvider);
    expect(st.layout, ExplorerLayout.grid);
    expect(st.sortColumn, FileColumns.size);
    expect(st.descending, isTrue);
  });

  test('window bounds round-trip; bad or tiny bounds are ignored', () {
    const r = Rect.fromLTWH(100, 50, 1280, 800);
    expect(WindowMemory.parse(WindowMemory.format(r)), r);
    expect(WindowMemory.parse(''), isNull);
    expect(WindowMemory.parse('1,2,3'), isNull);
    expect(WindowMemory.parse('0,0,300,200'), isNull);
    expect(WindowMemory.parse('-5000,0,1280,800'), isNull);
    // Q6: garbage rows.
    for (final raw in [
      'NaN,0,1280,800',
      '0,0,Infinity,800',
      '0,0,1280,1e308',
      '1e9,0,1280,800',
      '0,0,1280,-Infinity',
    ]) {
      expect(WindowMemory.parse(raw), isNull, reason: raw);
    }
  });
}
