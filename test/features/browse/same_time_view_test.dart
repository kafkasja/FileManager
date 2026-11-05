import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/browse/ui/browse_settings_section.dart';
import 'package:kfm/features/browse/ui/same_time_controller.dart';
import 'package:kfm/features/browse/ui/same_time_view.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _camera = '/storage/emulated/0/DCIM/Camera';

String _id(String name) => 'path:$_camera/$name';

/// Local times, so the day headers don't depend on the test machine's zone.
final _day1 = DateTime(2025, 6, 10, 12);
final _day2 = DateTime(2025, 6, 11, 9);

/// Day 1: d1a/b/c 2 s apart. Day 2: pair p1/p2 (3 s), pair q1/q2 (4 s,
/// 17 s after p2) and a lone photo hours later.
FakeFileSource _library() {
  final files = FakeFileSource();
  // modifiedAt is far away: the capture time (takenAt) must be used.
  final modified = DateTime.utc(2020);
  void add(String name, DateTime taken) =>
      files.addFile('$_camera/$name', takenAt: taken, modifiedAt: modified);
  add('d1a.jpg', _day1);
  add('d1b.jpg', _day1.add(const Duration(seconds: 2)));
  add('d1c.jpg', _day1.add(const Duration(seconds: 4)));
  add('p1.jpg', _day2);
  add('p2.jpg', _day2.add(const Duration(seconds: 3)));
  add('q1.jpg', _day2.add(const Duration(seconds: 20)));
  add('q2.jpg', _day2.add(const Duration(seconds: 24)));
  add('lone.jpg', _day2.add(const Duration(hours: 6)));
  return files;
}

String _header(DateTime day, String groups) =>
    '${DateFormat.yMMMEd('en').format(day)} · $groups';

Finder _card(String titleStart) => find.ancestor(
  of: find.textContaining(titleStart),
  matching: find.byType(Card),
);

Finder _tile(String name) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}, '));

/// Room for every day header and card without scrolling.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 7200);
  addTearDown(tester.view.reset);
}

Future<void> _openSameTime(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Same time'));
  await tester.pumpAndSettle();
}

Future<void> _selectGroup(WidgetTester tester, String titleStart) async {
  await tester.tap(
    find.descendant(of: _card(titleStart), matching: find.byTooltip('More')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select group'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default 5 s window: groups per day, newest day first, lone '
      'photos never shown', (tester) async {
    _tallScreen(tester);
    await pumpApp(tester, files: _library());
    await _openSameTime(tester);
    expect(find.byType(SameTimeView), findsOneWidget);

    final h1 = find.text(_header(DateTime(2025, 6, 10), '1 group'));
    final h2 = find.text(_header(DateTime(2025, 6, 11), '2 groups'));
    expect(h1, findsOneWidget);
    expect(h2, findsOneWidget);
    expect(
      tester.getTopLeft(h2).dy,
      lessThan(tester.getTopLeft(h1).dy),
      reason: 'newest day first',
    );
    expect(find.textContaining('3 files ·'), findsOneWidget);
    expect(find.textContaining('2 files ·'), findsNWidgets(2));
    expect(
      find.textContaining('3 files · ${DateFormat.Hms('en').format(_day1)}'),
      findsOneWidget,
    );
    for (final name in ['d1a.jpg', 'd1b.jpg', 'd1c.jpg', 'p1.jpg', 'q2.jpg']) {
      expect(_tile(name), findsOneWidget, reason: name);
    }
    expect(_tile('lone.jpg'), findsNothing);

    // Day 2's groups newest first too: q (later) above p.
    expect(
      tester.getTopLeft(_tile('q1.jpg')).dy,
      lessThan(tester.getTopLeft(_tile('p1.jpg')).dy),
    );
  });

  testWidgets(
    'a wider window regroups; stored values are clamped to 1 s … 24 h',
    (tester) async {
      _tallScreen(tester);
      final app = await pumpApp(tester, files: _library());
      await _openSameTime(tester);
      final settings = app.container.read(settingsRepositoryProvider);

      await settings.write(AppSettings.sameTimeWindowSeconds, 60);
      await tester.pumpAndSettle();
      expect(app.container.read(sameTimeWindowProvider).value, 60);
      expect(
        find.text(_header(DateTime(2025, 6, 11), '1 group')),
        findsOneWidget,
      );
      expect(find.textContaining('4 files ·'), findsOneWidget);
      expect(find.textContaining('3 files ·'), findsOneWidget);
      expect(find.textContaining('2 files ·'), findsNothing);
      expect(_tile('lone.jpg'), findsNothing);

      await settings.write(AppSettings.sameTimeWindowSeconds, 0);
      await tester.pumpAndSettle();
      expect(app.container.read(sameTimeWindowProvider).value, 1);
      // Nothing is within 1 s of anything else.
      expect(find.text('No photos taken at the same time'), findsOneWidget);

      await settings.write(AppSettings.sameTimeWindowSeconds, 99999);
      await tester.pumpAndSettle();
      expect(app.container.read(sameTimeWindowProvider).value, 86400);

      await settings.write(AppSettings.sameTimeWindowSeconds, 600);
      await tester.pumpAndSettle();
      // 600 s: d1 group and p+q group; lone is 6 h away.
      expect(find.textContaining('4 files ·'), findsOneWidget);
      expect(find.textContaining('3 files ·'), findsOneWidget);
    },
  );

  testWidgets('a group spanning local midnight is listed under its first '
      "item's day", (tester) async {
    final files = FakeFileSource();
    final late = DateTime(2025, 6, 12, 23, 59, 58);
    files
      ..addFile('$_camera/n1.jpg', takenAt: late)
      ..addFile(
        '$_camera/n2.jpg',
        takenAt: late.add(const Duration(seconds: 4)),
      );
    await pumpApp(tester, files: files);
    await _openSameTime(tester);
    expect(
      find.text(_header(DateTime(2025, 6, 12), '1 group')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        DateFormat.yMMMEd('en').format(late.add(const Duration(days: 1))),
      ),
      findsNothing,
    );
    expect(find.textContaining('2 files ·'), findsOneWidget);
  });

  testWidgets('Select group (⋮ and long-press) adds exactly the group; the '
      'selection is kept', (tester) async {
    _tallScreen(tester);
    final app = await pumpApp(tester, files: _library());
    Set<String> ids() =>
        app.container.read(selectionControllerProvider).value!.ids;
    await _openSameTime(tester);

    final lone = app.files.files.firstWhere((f) => f.name == 'lone.jpg');
    app.container.read(selectionControllerProvider.notifier).add(lone);
    await tester.pumpAndSettle();

    await _selectGroup(tester, '3 files ·');
    expect(find.text('Added 3 files'), findsOneWidget);
    expect(ids(), {
      _id('lone.jpg'),
      _id('d1a.jpg'),
      _id('d1b.jpg'),
      _id('d1c.jpg'),
    });

    // Again: nothing new, still add-only.
    await _selectGroup(tester, '3 files ·');
    expect(find.text('Nothing new to add'), findsOneWidget);
    expect(ids(), hasLength(4));

    // Long-press the q card's title.
    final q = find.textContaining(
      '2 files · ${DateFormat.Hms('en').format(_day2.add(const Duration(seconds: 20)))}',
    );
    expect(q, findsOneWidget);
    await tester.longPress(q);
    await tester.pumpAndSettle();
    expect(find.text('Added 2 files'), findsOneWidget);
    expect(ids(), containsAll([_id('q1.jpg'), _id('q2.jpg')]));
    expect(ids(), hasLength(6));
    expect(ids(), isNot(contains(_id('p1.jpg'))));
  });

  testWidgets('Videos chip shows only video groups; Documents is empty', (
    tester,
  ) async {
    _tallScreen(tester);
    final t = DateTime(2025, 7, 1, 10);
    final files = _library()
      ..addFile('$_camera/v1.mp4', takenAt: t)
      ..addFile('$_camera/v2.mp4', takenAt: t.add(const Duration(seconds: 1)))
      ..addFile('/storage/emulated/0/Download/a.pdf', modifiedAt: t)
      ..addFile(
        '/storage/emulated/0/Download/b.pdf',
        modifiedAt: t.add(const Duration(seconds: 1)),
      );
    await pumpApp(tester, files: files);
    await _openSameTime(tester);
    expect(_tile('v1.mp4'), findsOneWidget);
    expect(_tile('d1a.jpg'), findsOneWidget);
    expect(_tile('a.pdf'), findsNothing);

    await tester.tap(find.text('Videos'));
    await tester.pumpAndSettle();
    expect(_tile('v1.mp4'), findsOneWidget);
    expect(_tile('v2.mp4'), findsOneWidget);
    expect(_tile('d1a.jpg'), findsNothing);
    expect(find.textContaining('files ·'), findsOneWidget);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('No photos taken at the same time'), findsOneWidget);
    expect(_tile('a.pdf'), findsNothing);
  });

  testWidgets('tapping a thumbnail opens the paged preview; Close returns', (
    tester,
  ) async {
    _tallScreen(tester);
    await pumpApp(tester, files: _library());
    await _openSameTime(tester);

    await tester.tap(_tile('d1b.jpg'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsOneWidget);
    expect(find.textContaining('d1b.jpg'), findsWidgets);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsNothing);
    expect(find.byType(SameTimeView), findsOneWidget);
    expect(_tile('d1b.jpg'), findsOneWidget);
  });

  testWidgets('All files → Same time → All files keeps the grid working', (
    tester,
  ) async {
    await pumpApp(tester, files: _library());
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(_tile('lone.jpg'), findsOneWidget);

    await tester.tap(find.text('Same time'));
    await tester.pumpAndSettle();
    expect(find.byType(SameTimeView), findsOneWidget);
    expect(_tile('lone.jpg'), findsNothing);

    await tester.tap(find.text('All files'));
    await tester.pumpAndSettle();
    expect(find.byType(SameTimeView), findsNothing);
    expect(_tile('lone.jpg'), findsOneWidget);
    await tester.tap(_tile('lone.jpg'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsOneWidget);
  });

  testWidgets('Settings → Files & display: Same time window in human units', (
    tester,
  ) async {
    _tallScreen(tester);
    final app = await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final row = find.byType(SameTimeWindowRow);
    await tester.scrollUntilVisible(row, 200);
    expect(
      find.descendant(of: row, matching: find.text('5 s')),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unit-preset-60')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unit-input-save')));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();
    expect(app.container.read(sameTimeWindowProvider).value, 60);
    expect(
      find.descendant(of: row, matching: find.text('1 min')),
      findsOneWidget,
    );
  });
}
