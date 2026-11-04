import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/browse/disk_folders.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';

import '../core/files/fake_file_source.dart';
import 'desktop_helpers.dart';

List<String> _rows(WidgetTester tester) => [
  for (final e
      in tester
          .widget<ExplorerView<BrowseEntry>>(
            find.byType(ExplorerView<BrowseEntry>),
          )
          .items)
    e.name,
];

void main() {
  testWidgets('a USB stick root: the empty folder shows, the hidden system '
      'folder only with Show hidden', (tester) async {
    final files = FakeFileSource()
      ..addFile('/E/Videos/clip.mp4')
      // Indexed before KFM read the hidden attribute: still a plain row.
      ..addFile('/E/System Volume Information/IndexerVolumeGuid');
    final app = await pumpDesktopApp(
      tester,
      files: files,
      diskFolders: (folder) async => folder == '/E'
          ? const [
              DiskFolder('/E/Fotos'),
              DiskFolder('/E/Videos'),
              DiskFolder('/E/System Volume Information', hidden: true),
            ]
          : const [],
    );
    await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
    await tester.pumpAndSettle();
    app.container.read(desktopBrowseControllerProvider.notifier).open('/E');
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Fotos', 'Videos']);

    await tester.tap(find.byKey(const ValueKey('browse-show-hidden')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Fotos', 'System Volume Information', 'Videos']);

    // The empty folder opens (empty).
    await tester.tap(find.byKey(const ValueKey('browse-show-hidden')));
    await tester.pumpAndSettle();
    app.container
        .read(desktopBrowseControllerProvider.notifier)
        .open('/E/Fotos');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('crumb-/E/Fotos')), findsOneWidget);
    expect(find.byType(ExplorerView<BrowseEntry>), findsNothing);
  });

  group('listDiskFolders on a real folder', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('kfm-disk-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('lists empty folders; dot and hidden-attribute folders marked '
        'hidden', () async {
      Directory('${dir.path}/Fotos').createSync();
      Directory('${dir.path}/Videos').createSync();
      File('${dir.path}/Videos/a.mp4').writeAsBytesSync([1]);
      Directory('${dir.path}/.cache').createSync();
      final sys = Directory('${dir.path}/System Volume Information')
        ..createSync();
      if (Platform.isWindows) {
        final r = await Process.run('attrib', ['+h', '+s', sys.path]);
        expect(r.exitCode, 0);
      }
      File('${dir.path}/loose.txt').writeAsBytesSync([1]);
      final root = dir.path.replaceAll(r'\', '/');
      final found = await listDiskFolders(root);
      final byName = {
        for (final f in found) f.path.substring(root.length + 1): f.hidden,
      };
      expect(byName, {
        'Fotos': false,
        'Videos': false,
        '.cache': true,
        'System Volume Information': Platform.isWindows,
      });
      if (Platform.isWindows) {
        await Process.run('attrib', ['-h', '-s', sys.path]);
      }
    });

    test('a missing folder lists nothing', () async {
      expect(await listDiskFolders('${dir.path}/nope'), isEmpty);
    });
  });
}
