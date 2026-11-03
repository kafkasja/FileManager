import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

FakeFileSource _library() {
  final files = FakeFileSource();
  for (final (i, name) in ['a.jpg', 'b.jpg'].indexed) {
    files.addFile('/s/DCIM/$name', modifiedAt: DateTime.utc(2025, 1, 1, 0, i));
  }
  files
    ..addFile('/s/DCIM/Trip/t.jpg', modifiedAt: DateTime.utc(2025))
    ..addFile('/s/Other/o.jpg', modifiedAt: DateTime.utc(2025));
  return files;
}

Future<TestApp> _openBrowse(WidgetTester tester, String folder) async {
  final app = await pumpDesktopApp(tester, files: _library());
  await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
  await tester.pumpAndSettle();
  app.container.read(desktopBrowseControllerProvider.notifier).open(folder);
  await tester.pumpAndSettle();
  return app;
}

/// A mouse drag from [from] to [to] in small steps, like a real one.
Future<void> _mouseDrag(WidgetTester tester, Finder from, Finder to) async {
  final start = tester.getCenter(from);
  final end = tester.getCenter(to);
  final g = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(start, end, i / 8)!);
    await tester.pump();
  }
  await g.up();
  await _settle(tester);
}

/// B4 operations and index changes run behind short timers.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Set<String> _paths(TestApp app) => {for (final f in app.files.files) f.path};

void main() {
  testWidgets('Browse: drag a file onto a folder moves it (with Undo); Ctrl '
      'copies', (tester) async {
    final app = await _openBrowse(tester, '/s/DCIM');
    final g = await tester.startGesture(
      tester.getCenter(find.text('a.jpg')),
      kind: PointerDeviceKind.mouse,
    );
    final to = tester.getCenter(find.text('Trip'));
    for (var i = 1; i <= 6; i++) {
      await g.moveTo(
        Offset.lerp(tester.getCenter(find.text('a.jpg')), to, i / 6)!,
      );
      await tester.pump();
    }
    // The label next to the pointer says what a drop does.
    expect(find.text('1 file · Move to Trip'), findsOneWidget);
    expect(find.text('Hold Ctrl to copy'), findsOneWidget);
    await g.up();
    await _settle(tester);
    expect(_paths(app), contains('/s/DCIM/Trip/a.jpg'));
    expect(_paths(app), isNot(contains('/s/DCIM/a.jpg')));
    expect(find.byKey(const ValueKey('browse-undo')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await _mouseDrag(tester, find.text('b.jpg'), find.text('Trip'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_paths(app), containsAll(['/s/DCIM/b.jpg', '/s/DCIM/Trip/b.jpg']));
  });

  testWidgets('Browse: a drag of a multi-selection keeps the selection', (
    tester,
  ) async {
    final app = await _openBrowse(tester, '/s/DCIM');
    await tester.tap(find.text('a.jpg'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('b.jpg'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    await _mouseDrag(tester, find.text('a.jpg'), find.text('Trip'));
    expect(
      _paths(app),
      containsAll(['/s/DCIM/Trip/a.jpg', '/s/DCIM/Trip/b.jpg']),
    );
  });

  testWidgets('files dropped in from Explorer are copied into the open '
      'folder', (tester) async {
    final app = await _openBrowse(tester, '/s/DCIM');
    final drag = app.container.read(desktopDragControllerProvider);
    final at = tester.getCenter(find.byKey(const ValueKey('browse-drop')));
    drag.begin(
      const DesktopDragData(
        origin: DragOrigin.explorer,
        paths: ['/s/Other/o.jpg'],
      ),
      at + const Offset(0, 200),
    );
    await tester.pump();
    expect(drag.offer?.label, 'Copy to DCIM');
    await drag.drop();
    await _settle(tester);
    expect(_paths(app), containsAll(['/s/Other/o.jpg', '/s/DCIM/o.jpg']));
    // Sort action buttons and tags don't take Explorer files.
    await tester.tap(find.byKey(const ValueKey('desktop-nav-sort')));
    await tester.pumpAndSettle();
    drag.begin(
      const DesktopDragData(
        origin: DragOrigin.explorer,
        paths: ['/s/Other/o.jpg'],
      ),
      tester.getCenter(find.byKey(const ValueKey('sort-action-keep'))),
    );
    expect(drag.offer, isNull);
    drag.cancel();
  });

  testWidgets('Sort: drag files onto an action button or the sidebar Trash', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    await _mouseDrag(
      tester,
      find.text('p2.jpg'),
      find.byKey(const ValueKey('sort-action-keep')),
    );
    await _mouseDrag(
      tester,
      find.text('p1.jpg'),
      find.byKey(const ValueKey('desktop-nav-trash')),
    );
    await app.container.read(dbWriteQueueProvider).flush();
    final rows = await app.db.select(app.db.sessionActions).get();
    expect(
      [
        for (final r in rows)
          if (r.status == ActionStatus.applied) '${r.actionType}:${r.fileId}',
      ],
      ['keep:path:/s/DCIM/p2.jpg', 'trash:path:/s/DCIM/p1.jpg'],
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
