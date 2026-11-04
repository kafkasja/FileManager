// Windows-only (TASK-Q, Q3): folders the user may not write or read (an ACL
// deny, standing in for Defender Controlled Folder Access) and files another
// program holds open without sharing. Run with
//   flutter test integration_test/windows_denied_locked_test.dart -d windows
// Only touches a fresh temp folder; every deny is removed in tearDown (and
// once more in tearDownAll as a safety net).
@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

final String _user =
    '${Platform.environment['USERDOMAIN']}\\${Platform.environment['USERNAME']}';

Future<void> _icacls(List<String> args) async {
  final r = await Process.run('icacls', args);
  if (r.exitCode != 0) {
    throw StateError('icacls ${args.join(' ')}: ${r.stdout}${r.stderr}');
  }
}

/// Like Controlled Folder Access: nothing in [dir] may be written, created,
/// renamed or deleted (inherited by the files inside). Specific rights, not
/// `(W)` (that also denies SYNCHRONIZE) and DELETE only on the files (a
/// folder without DELETE can't even be listed): either hides the folder.
Future<void> _denyWrite(String dir) async {
  await _icacls([dir, '/deny', '$_user:(OI)(CI)(WD,AD,WA,DC)']);
  await _icacls([dir, '/deny', '$_user:(OI)(IO)(D)']);
}

/// Nothing in [dir] may be listed, and no file in it read.
Future<void> _denyRead(String dir) =>
    _icacls([dir, '/deny', '$_user:(OI)(CI)(RD)']);

/// Removing the explicit deny on [dir] also drops the inherited copies.
Future<void> _undeny(String dir) async {
  if (!Directory(dir).existsSync()) return;
  await Process.run('icacls', [dir, '/remove:d', _user]);
}

Matcher _fails(FileOpFailure failure) => throwsA(
  isA<FileOpException>().having((e) => e.failure, 'failure', failure),
);

/// Holds [path] open with no sharing at all (like an editor or a virus
/// scanner mid-scan) until the returned process is killed.
Future<Process> _lock(String path) async {
  final p = await Process.start('powershell', [
    '-NoProfile',
    '-Command',
    [
      "\$f = [IO.File]::Open('$path', 'Open', 'ReadWrite', 'None')",
      'Write-Output ready',
      'Start-Sleep 120',
    ].join('; '),
  ]);
  await p.stdout.firstWhere((b) => String.fromCharCodes(b).contains('ready'));
  return p;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final channel = WindowsChannel();
  late Directory dir;
  late String root;
  late WindowsFileSource source;
  final denied = <String>[];
  final created = <Directory>[];
  final binLeftovers = <String>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_q3_test_');
    created.add(dir);
    root = normalizeWindowsPath(dir.path);
    source = WindowsFileSource(
      channel: channel,
      indexRoots: () async => [root],
    );
  });

  tearDown(() async {
    for (final d in denied) {
      await _undeny(d);
    }
    denied.clear();
    if (binLeftovers.isNotEmpty) {
      await channel.deleteFromBin(binLeftovers.toList());
      binLeftovers.clear();
    }
    await source.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  tearDownAll(() async {
    for (final d in created) {
      await _undeny(d.path);
      if (d.existsSync()) await d.delete(recursive: true);
    }
  });

  Future<FileRef> file(String rel, [String text = 'hello']) async {
    final p = '$root/$rel';
    File(p)
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
    return (await source.stat('path:$p'))!;
  }

  List<String> namesIn(String folder) => [
    for (final e in Directory(folder).listSync())
      e.path.replaceAll(r'\', '/').split('/').last,
  ];

  group('write-denied folder (Controlled Folder Access stand-in)', () {
    late String locked;
    late FileRef inside;
    late FileRef outside;

    setUp(() async {
      inside = await file('locked/a.txt', 'inside');
      outside = await file('free/b.txt', 'outside');
      locked = '$root/locked';
      await _denyWrite(locked);
      denied.add(locked);
    });

    test('browse works; reading is a clean failure', () async {
      final pages = await source
          .scan(query: FileQuery(rootPath: locked))
          .toList();
      expect(pages.expand((p) => p).map((f) => f.name), ['a.txt']);
      // Observed on Windows 11: a file with DELETE denied can't be read
      // either (dart:io and .NET alike). It fails typed, not with a crash.
      await expectLater(
        hashFileRef(inside, source),
        _fails(FileOpFailure.permissionDenied),
      );
    });

    test('copy into: permissionDenied, no file or temp left', () async {
      await expectLater(
        source.copy(outside, locked),
        _fails(FileOpFailure.permissionDenied),
      );
      await _undeny(locked);
      expect(namesIn(locked), ['a.txt']);
      expect(File(outside.path).readAsStringSync(), 'outside');
    });

    test('move in and move out: permissionDenied, both files stay', () async {
      await expectLater(
        source.move(outside, locked),
        _fails(FileOpFailure.permissionDenied),
      );
      await expectLater(
        source.move(inside, '$root/free'),
        _fails(FileOpFailure.permissionDenied),
      );
      await _undeny(locked);
      expect(namesIn(locked), ['a.txt']);
      expect(namesIn('$root/free'), ['b.txt']);
    });

    test('rename, new folder, delete: permissionDenied', () async {
      await expectLater(
        source.rename(inside, 'c.txt'),
        _fails(FileOpFailure.permissionDenied),
      );
      await expectLater(
        source.createFolder(locked, 'sub'),
        _fails(FileOpFailure.permissionDenied),
      );
      await expectLater(
        source.deletePermanentlyBatch([inside]),
        _fails(FileOpFailure.permissionDenied),
      );
      expect(File(inside.path).existsSync(), isTrue);
    });

    test('trash: that file fails alone, the free one is recycled', () async {
      final result = await source.trashBatch([inside, outside]);
      binLeftovers.addAll(result.trashed.map((t) => t.trashId));
      expect(result.trashed.map((t) => t.original.id), [outside.id]);
      expect(
        result.failed[inside.id]?.failure,
        FileOpFailure.permissionDenied,
        reason: '${result.failed[inside.id]}',
      );
      expect(File(inside.path).existsSync(), isTrue);
    });

    test('import into: permissionDenied, the staged file is kept', () async {
      final staged = File('$root/staged.part')..writeAsStringSync('x');
      await expectLater(
        source.importFile(staged, targetFolder: locked, name: 'in.txt'),
        _fails(FileOpFailure.permissionDenied),
      );
      expect(staged.existsSync(), isTrue);
    });

    test('undo of a move into a folder that became denied', () async {
      Directory('$root/target').createSync();
      final moved = await source.move(outside, '$root/target');
      await _denyWrite('$root/target');
      denied.add('$root/target');
      // The undo (move back) fails cleanly; the file stays where it is.
      await expectLater(
        source.move(moved, '$root/free'),
        _fails(FileOpFailure.permissionDenied),
      );
      expect(File(moved.path).existsSync(), isTrue);
      expect(File(outside.path).existsSync(), isFalse);
    });
  });

  group('read-denied folder', () {
    late String hidden;
    late FileRef inside;

    setUp(() async {
      inside = await file('secret/a.jpg', 'not really a jpeg');
      await file('open/b.txt');
      hidden = '$root/secret';
      await _denyRead(hidden);
      denied.add(hidden);
    });

    test('index of the parent skips it and finishes', () async {
      final names = [
        await for (final page in source.scan()) ...page.map((f) => f.name),
      ];
      expect(names, ['b.txt']);
    });

    test('browsing it fails with permissionDenied', () async {
      await expectLater(
        source.scan(query: FileQuery(rootPath: hidden)).toList(),
        _fails(FileOpFailure.permissionDenied),
      );
    });

    test('read, hash, copy out, thumbnail: clean failures', () async {
      await expectLater(
        source.openRead(inside).toList(),
        _fails(FileOpFailure.permissionDenied),
      );
      await expectLater(
        hashFileRef(inside, source),
        _fails(FileOpFailure.permissionDenied),
      );
      await expectLater(
        source.copy(inside, '$root/open'),
        throwsA(isA<FileOpException>()),
      );
      expect(namesIn('$root/open'), ['b.txt']);
      // No crash; no thumbnail.
      expect(await channel.thumbnail(inside.path, 64), isNull);
    });
  });

  group('file held open by another program without sharing', () {
    late FileRef held;
    late Process holder;

    setUp(() async {
      held = await file('busy/a.jpg', 'held bytes');
      await file('busy/other.txt');
      holder = await _lock(held.path.replaceAll('/', r'\'));
    });

    tearDown(() async {
      holder.kill();
      await holder.exitCode;
    });

    test('move, rename, copy: inUse, the file stays', () async {
      Directory('$root/dest').createSync();
      await expectLater(
        source.move(held, '$root/dest'),
        _fails(FileOpFailure.inUse),
      );
      await expectLater(
        source.rename(held, 'b.jpg'),
        _fails(FileOpFailure.inUse),
      );
      await expectLater(
        source.copy(held, '$root/dest'),
        _fails(FileOpFailure.inUse),
      );
      expect(namesIn('$root/dest'), isEmpty);
      holder.kill();
      await holder.exitCode;
      expect(File(held.path).readAsStringSync(), 'held bytes');
    });

    test('trash: inUse for it alone', () async {
      final other = (await source.stat('path:$root/busy/other.txt'))!;
      final result = await source.trashBatch([held, other]);
      binLeftovers.addAll(result.trashed.map((t) => t.trashId));
      expect(result.failed[held.id]?.failure, FileOpFailure.inUse);
      expect(result.trashed.map((t) => t.original.id), [other.id]);
    });

    test('hash and thumbnail: clean failure, index still lists it', () async {
      await expectLater(
        hashFileRef(held, source),
        _fails(FileOpFailure.inUse),
      );
      expect(await channel.thumbnail(held.path, 64), isNull);
      final names = [
        await for (final page in source.scan()) ...page.map((f) => f.name),
      ]..sort();
      expect(names, ['a.jpg', 'other.txt']);
    });
  });
}
