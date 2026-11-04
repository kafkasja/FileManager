@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/io/fs_walker.dart';
import 'package:kfm/core/files/windows/win_attributes.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';

import '../platform/windows/fake_windows_channel.dart';

/// Desktop fixes: items with the Windows hidden attribute (a USB stick's
/// System Volume Information, desktop.ini, Thumbs.db) count as hidden in
/// the walker (index, Sort, Browse) and in single-file stats.
void main() {
  late Directory dir;
  late String root;

  void attrib(String path, List<String> flags) {
    final r = Process.runSync('attrib', [...flags, path.replaceAll('/', r'\')]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kfm_hidden');
    root = normalizeWindowsPath(dir.path);
    Directory('$root/Videos').createSync();
    File('$root/Videos/clip.mp4').writeAsBytesSync([1, 2]);
    Directory('$root/System Volume Information').createSync();
    File('$root/System Volume Information/IndexerVolumeGuid')
        .writeAsBytesSync([1]);
    File('$root/Videos/Thumbs.db').writeAsBytesSync([1]);
    File('$root/desktop.ini').writeAsBytesSync([1]);
    attrib('$root/System Volume Information', ['+h', '+s']);
    attrib('$root/Videos/Thumbs.db', ['+h', '+s']);
    attrib('$root/desktop.ini', ['+h', '+s']);
  });

  tearDown(() {
    for (final p in [
      '$root/System Volume Information',
      '$root/Videos/Thumbs.db',
      '$root/desktop.ini',
    ]) {
      Process.runSync('attrib', ['-h', '-s', p.replaceAll('/', r'\')]);
    }
    dir.deleteSync(recursive: true);
  });

  Future<List<FileRef>> walk({required bool includeHidden}) async => [
    await for (final page in walkFiles(
      WalkOptions(root: root, includeHidden: includeHidden),
    ))
      ...page,
  ];

  test('the attribute is read; drive roots never count', () {
    expect(hasHiddenAttribute('$root/desktop.ini'), isTrue);
    expect(hasHiddenAttribute('$root/Videos'), isFalse);
    expect(hasHiddenAttribute('C:'), isFalse);
  });

  test('the walker skips hidden items, or marks them hidden', () async {
    expect(
      [for (final f in await walk(includeHidden: false)) f.name],
      ['clip.mp4'],
    );
    final all = {
      for (final f in await walk(includeHidden: true)) f.name: f.hidden,
    };
    expect(all, {
      'clip.mp4': false,
      'Thumbs.db': true,
      'desktop.ini': true,
      'IndexerVolumeGuid': true,
    });
  });

  test('a single stat marks a file inside a hidden folder hidden', () async {
    final source = WindowsFileSource(
      channel: FakeWindowsChannel(),
      indexRoots: () async => [root],
    );
    addTearDown(source.dispose);
    final f = await source.stat(
      'path:$root/System Volume Information/IndexerVolumeGuid',
    );
    expect(f?.hidden, isTrue);
    expect((await source.stat('path:$root/Videos/clip.mp4'))?.hidden, isFalse);
  });
}
