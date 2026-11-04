@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/io/fs_walker.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';

import '../platform/windows/fake_windows_channel.dart';

/// Q4: odd names, long paths, deep nesting and link loops on a real NTFS
/// temp folder.
void main() {
  late Directory dir;
  late String root;
  late WindowsFileSource source;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_odd');
    root = normalizeWindowsPath(dir.path);
    source = WindowsFileSource(
      channel: FakeWindowsChannel(
        binDir: Directory('$root/.bin')..createSync(),
      ),
      indexRoots: () async => ['$root/files'],
    );
    Directory('$root/files').createSync();
    Directory('$root/dest').createSync();
  });

  tearDown(() async {
    await source.dispose();
    // rmdir handles names and lengths dart:io can't delete.
    Process.runSync('cmd', ['/c', 'rmdir', '/s', '/q', r'\\?\' + dir.path]);
  });

  /// Creates [name] in [folder] through a `\\?\` path (taken literally).
  void literal(
    String folder,
    String name, {
    String? content,
    bool dir = false,
  }) {
    final win = '\\\\?\\${folder.replaceAll('/', r'\')}\\$name'.replaceAll(
      "'",
      "''",
    );
    final cmd = dir
        ? "[IO.Directory]::CreateDirectory('$win') | Out-Null"
        : "[IO.File]::WriteAllText('$win', '${content ?? ''}')";
    final r = Process.runSync('powershell', ['-NoProfile', '-Command', cmd]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }

  Future<List<FileRef>> walk(String at) async => [
    await for (final page in walkFiles(
      WalkOptions(root: at, includeHidden: true),
    ))
      ...page,
  ];

  Matcher fails(FileOpFailure f) =>
      throwsA(isA<FileOpException>().having((e) => e.failure, 'failure', f));

  group('names Win32 paths cannot reach', () {
    late String files;

    setUp(() {
      files = '$root/files';
      File('$files/a').writeAsStringSync('PLAIN');
      literal(files, 'a.', content: 'DOTTED');
      literal(files, 'b ', content: 'SPACE');
      literal(files, 'NUL', content: 'NULFILE');
      Directory('$files/dir').createSync();
      File('$files/dir/x.txt').writeAsStringSync('X');
      literal(files, 'dir.', dir: true);
      literal('$files/dir.', 'inside.txt', content: 'INSIDE');
    });

    test('are never listed (they would read another file)', () async {
      final found = {for (final f in await walk(files)) f.path: f.sizeBytes};
      expect(found, {'$files/a': 5, '$files/dir/x.txt': 1});
      expect(isWin32AddressableName('a.'), isFalse);
      expect(isWin32AddressableName('b '), isFalse);
      expect(isWin32AddressableName('nul'), isFalse);
      expect(isWin32AddressableName('NUL.txt'), isTrue);
      expect(isWin32AddressableName('.hidden'), isTrue);
    });

    test('every operation refuses them; the look-alike file is kept', () async {
      expect(await source.stat('path:$files/a.'), isNull);
      final plain = (await source.stat('path:$files/a'))!;
      final dotted = FileRef(
        id: 'path:$files/a.',
        uri: '$files/a.',
        name: 'a.',
        kind: plain.kind,
        sizeBytes: 6,
        modifiedAt: plain.modifiedAt,
        folderPath: files,
        origin: plain.origin,
      );
      await expectLater(
        source.move(dotted, '$root/dest'),
        fails(FileOpFailure.invalidName),
      );
      await expectLater(
        source.copy(dotted, '$root/dest'),
        fails(FileOpFailure.invalidName),
      );
      await expectLater(
        source.rename(dotted, 'c.txt'),
        fails(FileOpFailure.invalidName),
      );
      await expectLater(
        source.deletePermanentlyBatch([dotted]),
        fails(FileOpFailure.invalidName),
      );
      await expectLater(
        source.openRead(dotted).toList(),
        fails(FileOpFailure.invalidName),
      );
      final trash = await source.trashBatch([dotted]);
      expect(trash.trashed, isEmpty);
      expect(trash.failed[dotted.id]?.failure, FileOpFailure.invalidName);

      expect(File('$files/a').readAsStringSync(), 'PLAIN');
      expect(Directory('$root/dest').listSync(), isEmpty);
      final names = Directory(r'\\?\' + dir.path)
          .listSync()
          .map((e) => e.path)
          .join('|');
      expect(names, isNotEmpty);
      final inFiles =
          Process.runSync('cmd', [
                '/c',
                'dir',
                '/b',
                '\\\\?\\${dir.path}\\files',
              ]).stdout
              as String;
      expect(inFiles.split(RegExp(r'\r?\n')), containsAll(['a', 'a.', 'b ']));
    });
  });

  group('valid odd names', () {
    final names = <String>[
      '🙂 smile 👨‍👩‍👧.jpg',
      'صورة العائلة.jpg',
      'שלום.png',
      'e\u0301cole.txt', // e + combining acute
      'école.txt', // precomposed: another name on NTFS
      '-leading dash.txt',
      '100% done.txt',
      '#tag #2.jpg',
      'a%20b.txt',
      r'$dollar & ampersand (1).txt',
      "it's [x] {y}.txt",
      'CON.txt', // reserved stem + extension: a normal file on Windows 11
      '${'n' * 251}.txt', // 255 characters, the NTFS limit
    ];

    test('walk, stat, copy, move, rename and hash keep every byte', () async {
      final files = '$root/files';
      for (final (i, n) in names.indexed) {
        File('$files/$n').writeAsStringSync('content $i');
      }
      final found = {for (final f in await walk(files)) f.name};
      expect(found, names.toSet());
      for (final (i, n) in names.indexed) {
        final f = (await source.stat('path:$files/$n'))!;
        expect(f.name, n);
        final copied = await source.copy(f, '$root/dest');
        expect(copied.name, n);
        expect(File(copied.path).readAsStringSync(), 'content $i');
        final hash = await hashFileInIsolate(f.path);
        expect(await hashFileInIsolate(copied.path), hash);
        // A name at the limit can't take the " (1)" suffix: clear error.
        final moved = await source
            .move(f, '$root/dest')
            .then<FileRef?>(
              (m) => m,
              onError: (Object e) {
                expect(n.length, greaterThan(250), reason: '$n: $e');
                return null;
              },
            );
        if (moved == null) continue;
        expect(moved.name, isNot(n), reason: 'unique name in dest');
        expect(File(moved.path).readAsStringSync(), 'content $i');
        final back = await source.move(moved, files);
        final renamed = await source.rename(
          back,
          '~$i ${back.name}'.substring(0, back.name.length > 200 ? 200 : null),
        );
        expect(File(renamed.path).readAsStringSync(), 'content $i');
      }
    });
  });

  test('a 256-character name is refused with invalidName', () async {
    File('$root/files/a.txt').writeAsStringSync('A');
    final f = (await source.stat('path:$root/files/a.txt'))!;
    await expectLater(
      source.rename(f, '${'n' * 252}.txt'),
      throwsA(isA<FileOpException>()),
    );
    expect(File('$root/files/a.txt').readAsStringSync(), 'A');
  });

  test('paths over 260 characters and 50-level nesting', () async {
    final deep = [
      '$root/files',
      for (var i = 0; i < 50; i++) 'level_${i.toString().padLeft(2, '0')}',
    ].join('/');
    expect(deep.length, greaterThan(400));
    Directory(deep).createSync(recursive: true);
    File('$deep/deep.jpg').writeAsBytesSync(List.filled(1000, 7));
    File('$root/files/level_00/shallow.jpg').writeAsBytesSync([1]);

    // Browse / index see it (the listing used to fail past ~260).
    final walked = await walk('$root/files');
    expect(walked.map((f) => f.name), containsAll(['deep.jpg', 'shallow.jpg']));
    final scanned = [
      await for (final p in source.scan(
        query: FileQuery(rootPath: deep, recursive: false),
      ))
        ...p,
    ];
    expect(scanned.single.name, 'deep.jpg');

    final f = (await source.stat('path:$deep/deep.jpg'))!;
    final copy = await source.copy(f, '$root/dest');
    expect(File(copy.path).lengthSync(), 1000);
    final up = await source.move(f, '$root/dest');
    expect(File('$deep/deep.jpg').existsSync(), isFalse, reason: 'moved out');
    expect(
      await FileSystemEntity.type('$deep/deep.jpg'),
      FileSystemEntityType.notFound,
    );
    final down = await source.move(up, deep);
    expect(down.path, '$deep/${up.name}');
    expect(
      await hashFileInIsolate(down.path),
      await hashFileInIsolate(copy.path),
    );
    final renamed = await source.renameFolder(deep, 'renamed_last');
    expect(renamed.files.single.name, up.name);
  });

  test('junction and symlink loops: the walk ends, nothing twice', () async {
    final files = '$root/files';
    Directory('$files/loop').createSync();
    File('$files/loop/one.jpg').writeAsBytesSync([1]);
    final r = Process.runSync('cmd', [
      '/c',
      'mklink',
      '/J',
      '${dir.path}\\files\\loop\\junction_back',
      '${dir.path}\\files',
    ]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    var symlink = true;
    try {
      Link('$files/loop/symlink_back').createSync('$files/loop');
    } on FileSystemException {
      symlink = false; // no Developer Mode: junction only
    }
    final walked = await walk(files).timeout(const Duration(seconds: 20));
    expect(walked.map((f) => f.path), ['$files/loop/one.jpg']);
    final again = [await for (final p in source.scan()) ...p];
    expect(again.map((f) => f.path), ['$files/loop/one.jpg']);
    addTearDown(() {
      if (symlink) Link('$files/loop/symlink_back').deleteSync();
    });
  });
}
