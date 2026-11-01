import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/browse/ui/browse_preview.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/files/fake_open_with.dart';
import '../../helpers/pump_app.dart';
import '../swipe/fake_video.dart';

const _camera = '/storage/emulated/0/DCIM/Camera';

/// Counts keyset page reads (B7: closing the preview must not reload).
class _SpyDao extends MediaIndexDao {
  new(super.attachedDatabase);

  int pages = 0;

  @override
  Future<IndexPage> page(
    IndexQuery query, {
    IndexCursor? after,
    int limit = 200,
  }) {
    pages++;
    return super.page(query, after: after, limit: limit);
  }
}

/// p00 … p{n-1}; newest first in Browse, so p{n-1} is the first tile.
FakeFileSource _photos(int n) {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  for (var i = 0; i < n; i++) {
    files.addFile(
      '$_camera/p${i.toString().padLeft(2, '0')}.jpg',
      modifiedAt: t.add(Duration(minutes: i)),
    );
  }
  return files;
}

String _name(int i) => 'p${i.toString().padLeft(2, '0')}.jpg';
String _id(String name) => 'path:$_camera/$name';

Finder _tile(String name) => find.bySemanticsLabel(name);

/// The ⤢ button of the tile for [path] (tiles are keyed by file id).
Finder _expand(String path) => find.descendant(
  of: find.byKey(ValueKey('path:$path')),
  matching: find.byTooltip('Preview'),
);

Future<void> _openBrowse(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
}

Future<void> _nextPage(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

/// The info bar shows "name · size · date".
Finder _shown(String name) => find.textContaining(name);

void main() {
  testWidgets('Select mode: preview, page 20 files, select one, close → same '
      'mode, +1 selected, last file visible, no reload', (tester) async {
    late _SpyDao spy;
    final app = await pumpApp(
      tester,
      files: _photos(60),
      overrides: [
        mediaIndexDaoProvider.overrideWith(
          (ref) => spy = _SpyDao(ref.watch(appDatabaseProvider)),
        ),
      ],
    );
    SelectionState state() =>
        app.container.read(selectionControllerProvider).value!;
    await _openBrowse(tester);

    app.container.read(selectionControllerProvider.notifier)
      ..enterSelect()
      ..addAll([
        for (final i in [59, 58, 57, 56, 55]) app.files.files[i],
      ]);
    await tester.pumpAndSettle();
    expect(state().count, 5);
    final readsBefore = spy.pages;

    // Newest first: p59 is the first tile.
    await tester.tap(_expand('$_camera/${_name(59)}'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsOneWidget);
    expect(app.container.read(viewerOpenProvider), isTrue);
    expect(_shown(_name(59)), findsOneWidget);
    // Already selected: "Selected" and tapping it does nothing.
    await tester.tap(find.widgetWithText(FilledButton, 'Selected'));
    await tester.pumpAndSettle();
    expect(state().count, 5);

    for (var i = 0; i < 20; i++) {
      await _nextPage(tester);
    }
    expect(_shown(_name(39)), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Select'));
    await tester.pumpAndSettle();
    expect(state().ids, contains(_id(_name(39))));
    expect(find.widgetWithText(FilledButton, 'Selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsNothing);
    expect(app.container.read(viewerOpenProvider), isFalse);
    expect(state().mode, SelectionMode.select);
    expect(state().count, 6);

    // The last-viewed file is on screen; nothing was read again.
    final rect = tester.getRect(_tile(_name(39)));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(screen.height));
    expect(spy.pages, readsBefore);
  });

  testWidgets('Normal mode: Select from the preview keeps Normal mode', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _photos(3));
    await _openBrowse(tester);
    await tester.tap(_tile(_name(2)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Select'));
    await tester.pumpAndSettle();
    final s = app.container.read(selectionControllerProvider).value!;
    expect(s.mode, SelectionMode.normal);
    expect(s.ids, {_id(_name(2))});
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected · 3 B'), findsOneWidget);
  });

  testWidgets('Edit mode: Remove from selection, Undo brings it back', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _photos(3));
    SelectionState state() =>
        app.container.read(selectionControllerProvider).value!;
    await _openBrowse(tester);
    app.container.read(selectionControllerProvider.notifier)
      ..addAll(app.files.files)
      ..enterEdit();
    await tester.pumpAndSettle();

    await tester.tap(_expand('$_camera/${_name(2)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from selection'));
    await tester.pumpAndSettle();
    expect(state().count, 2);
    expect(find.text('Remove from selection'), findsNothing);
    // The root messenger shows it on the Browse scaffold too.
    await tester.tap(find.text('Undo').last);
    await tester.pumpAndSettle();
    expect(state().count, 3);
    expect(state().mode, SelectionMode.edit);
  });

  testWidgets('Preview selected pages only through the selection, in order', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _photos(6));
    await _openBrowse(tester);
    FileRef f(int i) => app.files.files[i];
    app.container.read(selectionControllerProvider.notifier)
      ..add(f(1))
      ..add(f(4))
      ..add(f(2));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    // B10 added Details: the menu scrolls in the 600 px test window.
    await tester.ensureVisible(find.text('Preview selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview selected'));
    await tester.pumpAndSettle();
    expect(_shown(_name(1)), findsOneWidget);
    await _nextPage(tester);
    expect(_shown(_name(4)), findsOneWidget);
    await _nextPage(tester);
    expect(_shown(_name(2)), findsOneWidget);
    await _nextPage(tester);
    expect(_shown(_name(2)), findsOneWidget, reason: 'last selected file');
  });

  testWidgets('other kinds: info card with Open with; no app keeps the '
      'preview open', (tester) async {
    final files = FakeFileSource()
      ..addFile('/storage/emulated/0/Download/manual.pdf');
    final openWith = FakeOpenWith();
    final app = await pumpApp(tester, files: files, openWith: openWith);
    await _openBrowse(tester);
    app.container.read(selectionControllerProvider.notifier).enterSelect();
    await tester.pumpAndSettle();

    await tester.tap(_expand('/storage/emulated/0/Download/manual.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(FileInfoCard), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Open with'));
    await tester.pumpAndSettle();
    expect(openWith.opened.single.name, 'manual.pdf');

    openWith.noApp = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Open with'));
    await tester.pumpAndSettle();
    expect(find.text('No app can open this file'), findsWidgets);
    expect(find.byType(PagedFileViewer), findsOneWidget);
  });

  testWidgets('videos wait for ▶; a deleted file says so', (tester) async {
    final files = _photos(1)..addFile('$_camera/v.mp4');
    final videos = FakeVideoFactory();
    await pumpApp(tester, files: files, videos: videos);
    await _openBrowse(tester);

    // The Swipe deck shares the pooled player: only count calls from here.
    List<String> calls() => videos.created.single.calls;
    final before = calls().length;
    await tester.tap(_tile('v.mp4'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    expect(calls().sublist(before), isNot(contains('play')));
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(calls().sublist(before), contains('play'));
    expect(find.byIcon(Icons.play_circle_fill), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    files.removeExternally(_id(_name(0)));
    await tester.tap(_tile(_name(0)));
    await tester.pumpAndSettle();
    expect(find.text('This file no longer exists'), findsOneWidget);
  });

  testWidgets('the Swipe deck pauses while hidden and plays again after a '
      'Browse video preview', (tester) async {
    final files = FakeFileSource()..addFile('$_camera/v.mp4');
    final videos = FakeVideoFactory();
    await pumpApp(tester, files: files, videos: videos);
    List<String> calls() => videos.created.single.calls;
    expect(calls().last, 'play');

    await _openBrowse(tester);
    expect(calls().last, 'pause', reason: 'hidden tab');
    await tester.tap(_tile('v.mp4'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(calls().last, 'pause');

    await tester.tap(find.text('Swipe'));
    await tester.pumpAndSettle();
    expect(calls().last, 'play');
    expect(calls().reversed.skip(1).first, 'volume 0.0', reason: 'muted');
  });
}
