import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/browse/desktop_browse_screen.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/data/folder_tree_transfer.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

FakeFileSource _library() => FakeFileSource()
  ..addFile('/s/DCIM/a.jpg', modifiedAt: DateTime.utc(2025))
  ..addFile('/s/DCIM/Trip/t1.jpg', modifiedAt: DateTime.utc(2025))
  ..addFile('/s/DCIM/Trip/day2/t2.jpg', modifiedAt: DateTime.utc(2025))
  ..addFile('/s/Other/o.jpg', modifiedAt: DateTime.utc(2025));

Future<TestApp> _openBrowse(WidgetTester tester, String folder) async {
  final app = await pumpDesktopApp(tester, files: _library());
  await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
  await tester.pumpAndSettle();
  app.container.read(desktopBrowseControllerProvider.notifier).open(folder);
  await tester.pumpAndSettle();
  return app;
}

List<String> _rows(WidgetTester tester) => [
  for (final e
      in tester
          .widget<ExplorerView<BrowseEntry>>(
            find.byType(ExplorerView<BrowseEntry>),
          )
          .items)
    e.name,
];

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Set<String> _paths(TestApp app) => {for (final f in app.files.files) f.path};

Future<(CollisionChoice, bool)> _keepBoth(FileRef a, FileRef b) async =>
    (CollisionChoice.keepBoth, false);

/// Pumps fake time until [future] is done (the runner's DB writes and
/// index queue run on the test clock).
Future<T> _drive<T>(WidgetTester tester, Future<T> future) async {
  T? value;
  var done = false;
  unawaited(
    future.then((v) {
      value = v;
      done = true;
    }),
  );
  for (var i = 0; i < 200 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done, isTrue);
  return value as T;
}

void main() {
  testWidgets('Ctrl+X on a folder, Ctrl+V elsewhere moves the whole tree; '
      'Undo moves it back', (tester) async {
    final app = await _openBrowse(tester, '/s/DCIM');
    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyX);
    app.container
        .read(desktopBrowseControllerProvider.notifier)
        .open('/s/Other');
    await tester.pumpAndSettle();
    await tester.tap(find.text('o.jpg'));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyV);
    expect(
      _paths(app),
      containsAll(['/s/Other/Trip/t1.jpg', '/s/Other/Trip/day2/t2.jpg']),
    );
    expect(_paths(app), isNot(contains('/s/DCIM/Trip/t1.jpg')));
    expect(find.text('Moved 1 folder (2 files)'), findsOneWidget);
    expect(_rows(tester), contains('Trip'));

    await tester.tap(find.byKey(const ValueKey('cmd-undo')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      _paths(app),
      containsAll(['/s/DCIM/Trip/t1.jpg', '/s/DCIM/Trip/day2/t2.jpg']),
    );
    expect(_paths(app), isNot(contains('/s/Other/Trip/t1.jpg')));
  });

  testWidgets('dragging a folder onto another folder offers a move; never '
      'into itself', (tester) async {
    await _openBrowse(tester, '/s/DCIM');
    final screen = find.byType(DesktopBrowseScreen);
    final context = tester.element(screen);
    final ref = tester.state<ConsumerState<DesktopBrowseScreen>>(screen).ref;
    const data = DesktopDragData(
      origin: DragOrigin.browse,
      folders: ['/s/DCIM/Trip'],
    );
    expect(
      folderDropOffer(context, ref, '/s/DCIM/Trip/day2')(data, copy: false),
      isNull,
    );
    expect(folderDropOffer(context, ref, '/s/DCIM')(data, copy: false), isNull);
    final offer = folderDropOffer(context, ref, '/s/Other')(data, copy: false);
    expect(offer?.label, 'Move to Other');
    expect(trashDropOffer(context, ref)(data, copy: false), isNull);
  });

  testWidgets('FolderTreeTransfer: copy into its own parent gets a new name, '
      'into itself is refused; undo removes the copies', (tester) async {
    final app = await pumpDesktopApp(tester, files: _library());
    final transfer = app.container.read(folderTreeTransferProvider);
    await expectLater(
      transfer.transfer(
        folders: ['/s/DCIM/Trip'],
        files: const [],
        target: '/s/DCIM/Trip/day2',
        move: true,
        cancel: CancelToken(),
        resolveCollision: _keepBoth,
      ),
      throwsA(isA<FolderIntoItselfException>()),
    );
    final done = await _drive(
      tester,
      transfer.transfer(
        folders: ['/s/DCIM/Trip'],
        files: const [],
        target: '/s/DCIM',
        move: false,
        cancel: CancelToken(),
        resolveCollision: _keepBoth,
      ),
    );
    expect(
      _paths(app),
      containsAll([
        '/s/DCIM/Trip (1)/t1.jpg',
        '/s/DCIM/Trip (1)/day2/t2.jpg',
        '/s/DCIM/Trip/t1.jpg',
      ]),
    );
    expect(done.createdDirs, ['/s/DCIM/Trip (1)', '/s/DCIM/Trip (1)/day2']);
    final out = await _drive(
      tester,
      transfer.undo(done, cancel: CancelToken()),
    );
    expect(out.undone, 2);
    expect(_paths(app).where((p) => p.contains('Trip (1)')), isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('FolderTreeTransfer: empty subfolders are recreated on copy and '
      'move; Undo removes them / brings them back', (tester) async {
    final app = await pumpDesktopApp(tester, files: _library());
    final removed = <String>[];
    final transfer = FolderTreeTransfer(
      source: app.container.read(fileSourceProvider),
      runner: app.container.read(fileOperationRunnerProvider),
      removeEmptyDir: (dir) async {
        removed.add(dir);
        return true;
      },
      listSubfolders: (dir) async => [
        if (dir == '/s/DCIM/Trip') ...[
          '/s/DCIM/Trip/day2',
          '/s/DCIM/Trip/empty',
          '/s/DCIM/Trip/empty/deeper',
        ],
      ],
    );
    final copy = await _drive(
      tester,
      transfer.transfer(
        folders: ['/s/DCIM/Trip'],
        files: const [],
        target: '/s/Other',
        move: false,
        cancel: CancelToken(),
        resolveCollision: _keepBoth,
      ),
    );
    expect(copy.createdDirs, [
      '/s/Other/Trip',
      '/s/Other/Trip/day2',
      '/s/Other/Trip/empty',
      '/s/Other/Trip/empty/deeper',
    ]);
    expect(copy.sourceDirs, isEmpty);
    await _drive(tester, transfer.undo(copy, cancel: CancelToken()));
    // Created folders are removed deepest first.
    expect(removed, [
      '/s/Other/Trip/empty/deeper',
      '/s/Other/Trip/empty',
      '/s/Other/Trip/day2',
      '/s/Other/Trip',
    ]);

    // (The fake remover leaves the copies in place: move elsewhere.)
    removed.clear();
    app.files.addFolder('/s/Moved');
    final files = app.files;
    final move = await _drive(
      tester,
      transfer.transfer(
        folders: ['/s/DCIM/Trip'],
        files: const [],
        target: '/s/Moved',
        move: true,
        cancel: CancelToken(),
        resolveCollision: _keepBoth,
      ),
    );
    expect(move.createdDirs, contains('/s/Moved/Trip/empty/deeper'));
    expect(move.removedDirs, ['/s/DCIM/Trip']);
    expect(move.sourceDirs, [
      '/s/DCIM/Trip/day2',
      '/s/DCIM/Trip/empty',
      '/s/DCIM/Trip/empty/deeper',
    ]);
    files.calls.clear();
    await _drive(tester, transfer.undo(move, cancel: CancelToken()));
    expect(
      files.calls,
      containsAll([
        'createFolder /s/DCIM/Trip empty',
        'createFolder /s/DCIM/Trip/empty deeper',
      ]),
    );
    expect(_paths(app), contains('/s/DCIM/Trip/day2/t2.jpg'));
    await tester.pump(const Duration(seconds: 1));
  });

  test('listIoSubfolders lists every folder below, empty ones too', () async {
    final dir = Directory.systemTemp.createTempSync('kfm_tree');
    addTearDown(() => dir.deleteSync(recursive: true));
    Directory('${dir.path}/a/b').createSync(recursive: true);
    Directory('${dir.path}/c').createSync();
    File('${dir.path}/a/f.txt').writeAsStringSync('x');
    final root = dir.path.replaceAll(r'\', '/');
    expect(await listIoSubfolders(root), ['$root/a', '$root/c', '$root/a/b']);
    expect(await listIoSubfolders('$root/missing'), isEmpty);
  });
}
