@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';

import '../platform/windows/fake_windows_channel.dart';
import 'file_source_contract.dart';

/// WindowsFileSource on a real temp folder (the dev machine / CI
/// `windows-latest` disk), the Recycle Bin through [FakeWindowsChannel].
class _WinHarness implements ContractHarness {
  new(this._dir, this.channel, this.source, this.root);

  static Future<_WinHarness> create() async {
    final dir = await Directory.systemTemp.createTemp('kfm_win');
    final root = normalizeWindowsPath(dir.path);
    final bin = Directory('$root/.bin')..createSync();
    final channel = FakeWindowsChannel(binDir: bin);
    final source = WindowsFileSource(
      channel: channel,
      indexRoots: () async => ['$root/files'],
    );
    final h = _WinHarness(dir, channel, source, '$root/files');
    await Directory(h.root).create();
    return h;
  }

  final Directory _dir;
  final FakeWindowsChannel channel;

  @override
  final WindowsFileSource source;

  @override
  final String root;

  @override
  Future<FileRef> addFile(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return (await source.stat('path:$path'))!;
  }

  @override
  Future<void> removeExternally(FileRef f) => File(f.path).delete();

  @override
  Future<void> dispose() async {
    await source.dispose();
    await _dir.delete(recursive: true);
  }
}

Matcher _fails(FileOpFailure failure) => throwsA(
  isA<FileOpException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  fileSourceContract(
    'WindowsFileSource',
    _WinHarness.create,
    diskRefusesWindowsChars: true,
  );

  group('WindowsFileSource', () {
    late _WinHarness h;
    late WindowsFileSource s;

    setUp(() async {
      h = await _WinHarness.create();
      s = h.source;
    });
    tearDown(() => h.dispose());

    test('ids and folders are /-separated; backslash input works', () async {
      final f = await h.addFile('${h.root}/a/b.txt', [1]);
      expect(f.id, 'path:${h.root}/a/b.txt');
      expect(f.folderPath, '${h.root}/a');
      final native = '${h.root}/a/b.txt'.replaceAll('/', r'\');
      expect((await s.statPath(native))?.id, f.id);
      expect((await s.stat('path:$native'))?.folderPath, '${h.root}/a');
    });

    test('case-only rename goes through a temp name and sticks', () async {
      final f = await h.addFile('${h.root}/photo.jpg', [1, 2]);
      final changes = <FileIdChange>[];
      final sub = s.idChanges.listen(changes.add);
      addTearDown(sub.cancel);

      final renamed = await s.rename(f, 'Photo.JPG');
      expect(renamed.name, 'Photo.JPG');
      final onDisk = Directory(h.root)
          .listSync()
          .map((e) => e.uri.pathSegments.last);
      expect(onDisk, contains('Photo.JPG'));
      expect(onDisk, isNot(contains('photo.jpg')));
      await Future<void>.delayed(Duration.zero);
      expect(changes.single.oldId, f.id);
      expect(changes.single.newRef.id, renamed.id);
    });

    test('move to the same folder in other casing is a no-op', () async {
      final f = await h.addFile('${h.root}/A/doc.pdf', [1]);
      final same = await s.move(f, '${h.root}/a'.replaceAll('/', r'\'));
      expect(same.id, f.id);
    });

    test('Windows-invalid names are refused', () async {
      final f = await h.addFile('${h.root}/x.pdf', [1]);
      for (final bad in [
        r'a\b.pdf',
        'what?.pdf',
        'a:b',
        'CON',
        'nul.txt',
        'com1.tar.gz',
        'dot.',
        'space ',
      ]) {
        await expectLater(
          s.rename(f, bad),
          _fails(FileOpFailure.invalidName),
          reason: bad,
        );
        await expectLater(
          s.createFolder(h.root, bad),
          _fails(FileOpFailure.invalidName),
          reason: bad,
        );
      }
      // Names that only look reserved are fine.
      expect((await s.rename(f, 'console.pdf')).name, 'console.pdf');
    });

    test('scan without root walks every index root once', () async {
      final base = h.root;
      await h.addFile('$base/pics/a.jpg', [1]);
      await h.addFile('$base/pics/sub/b.jpg', [1]);
      await h.addFile('$base/docs/c.pdf', [1]);
      await h.addFile('$base/elsewhere/d.pdf', [1]);
      final source = WindowsFileSource(
        channel: FakeWindowsChannel(),
        indexRoots: () async => [
          '$base/pics',
          '$base/pics/sub'.replaceAll('/', r'\'), // nested: no duplicates
          '$base/docs',
          '$base/missing', // skipped, no error
        ],
      );
      addTearDown(source.dispose);
      final names = [
        for (final page in await source.scan().toList())
          for (final f in page) f.name,
      ];
      expect(names, unorderedEquals(['a.jpg', 'b.jpg', 'c.pdf']));

      final images = [
        for (final page
            in await source
                .scan(query: const FileQuery(kinds: {FileKind.image}))
                .toList())
          ...page,
      ];
      expect(images.map((f) => f.name), unorderedEquals(['a.jpg', 'b.jpg']));
    });

    test(
      'trashBatch: one recycle call; locked and no-bin files fail alone',
      () async {
        final a = await h.addFile('${h.root}/a.jpg', [1]);
        final b = await h.addFile('${h.root}/b.jpg', [2]);
        final c = await h.addFile('${h.root}/c.jpg', [3]);
        h.channel.lockedPaths.add(b.path);

        final result = await s.trashBatch([a, b, c]);
        expect(h.channel.calls.where((m) => m == 'recycle'), hasLength(1));
        expect(result.trashed.map((t) => t.original.id), [a.id, c.id]);
        expect(
          result.trashed.every((t) => t.location == TrashLocation.systemTrash),
          isTrue,
        );
        expect(result.failed[b.id]?.failure, FileOpFailure.inUse);
        expect(await s.stat(a.id), isNull);
        expect(await s.stat(b.id), isNotNull);
      },
    );

    test('trashBatch: a drive without a bin fails with noTrash', () async {
      final f = await h.addFile('${h.root}/a.jpg', [1]);
      final noBin = WindowsFileSource(
        channel: FakeWindowsChannel(
          binDir: Directory('${h.root}/../.bin'),
          noBinUnder: [h.root],
        ),
        indexRoots: () async => [h.root],
      );
      addTearDown(noBin.dispose);
      final result = await noBin.trashBatch([f]);
      expect(result.trashed, isEmpty);
      expect(result.failed[f.id]?.failure, FileOpFailure.noTrash);
      expect(await s.stat(f.id), isNotNull);
    });

    test('without the native side trashing fails as unsupported', () async {
      final f = await h.addFile('${h.root}/a.jpg', [1]);
      final none = WindowsFileSource(
        channel: FakeWindowsChannel(missing: true),
        indexRoots: () async => [h.root],
      );
      addTearDown(none.dispose);
      final result = await none.trashBatch([f]);
      expect(result.failed[f.id]?.failure, FileOpFailure.unsupported);
    });

    test('listTrashed shows bin items under the index roots only', () async {
      final mine = await h.addFile('${h.root}/a.jpg', [1, 2, 3]);
      final outside = '${parentOf(h.root)}/outside.jpg';
      File(outside).writeAsBytesSync([1]);
      await s.trashBatch([mine]);
      await h.channel.recycle([outside]);

      final items = await s.listTrashed();
      expect(items.single.original.id, mine.id);
      expect(items.single.original.sizeBytes, 3);
      expect(items.single.original.folderPath, h.root);
    });

    test('restore puts files back; a taken name changes the id', () async {
      final a = await h.addFile('${h.root}/a.jpg', [1]);
      final b = await h.addFile('${h.root}/b.jpg', [2]);
      final trashed = (await s.trashBatch([a, b])).trashed;
      await h.addFile('${h.root}/b.jpg', [9]); // b's name taken meanwhile
      final changes = <FileIdChange>[];
      final sub = s.idChanges.listen(changes.add);
      addTearDown(sub.cancel);

      final result = await s.restoreBatch(trashed);
      expect(h.channel.calls.where((m) => m == 'restoreFromBin'), hasLength(1));
      expect(result.failed, isEmpty);
      expect(result.restored[trashed[0].trashId]?.id, a.id);
      final bBack = result.restored[trashed[1].trashId]!;
      expect(bBack.name, 'b (1).jpg');
      await Future<void>.delayed(Duration.zero);
      expect(changes.single.oldId, b.id);
      expect(await s.listTrashed(), isEmpty);

      await expectLater(s.restore(trashed[0]), _fails(FileOpFailure.notFound));
    });

    test('deleteFromTrash empties those bin items', () async {
      final a = await h.addFile('${h.root}/a.jpg', [1]);
      final trashed = (await s.trashBatch([a])).trashed;
      await s.deleteFromTrash(trashed);
      expect(await s.listTrashed(), isEmpty);
    });

    test(
      'deletePermanentlyBatch deletes all, a missing file is fine',
      () async {
        final a = await h.addFile('${h.root}/a.txt', [1]);
        final b = await h.addFile('${h.root}/b.txt', [1]);
        await h.removeExternally(a);
        await s.deletePermanentlyBatch([a, b]);
        expect(await s.stat(b.id), isNull);
      },
    );

    test(
      'a file open elsewhere fails with inUse, the rest is deleted',
      () async {
        final a = await h.addFile('${h.root}/a.txt', [1]);
        final b = await h.addFile('${h.root}/b.txt', [1]);
        // dart:io opens files without FILE_SHARE_DELETE: deleting it fails
        // with a sharing violation while it's open.
        final handle = await File(a.path).open(mode: FileMode.append);
        addTearDown(handle.close);
        await expectLater(
          s.deletePermanentlyBatch([a, b]),
          _fails(FileOpFailure.inUse),
        );
        expect(await s.stat(b.id), isNull);
      },
    );
  });

  group('Windows paths', () {
    test('normalizeWindowsPath', () {
      expect(normalizeWindowsPath(r'C:\Users\me\'), 'C:/Users/me');
      expect(normalizeWindowsPath('C:/'), 'C:');
      expect(normalizeWindowsPath('C:'), 'C:');
    });

    test('roots: case-insensitive, nested and duplicate roots dropped', () {
      expect(
        outermostRoots([
          'C:/Users/me/Pictures',
          r'c:\users\me\pictures\Holiday',
          'C:/Users/me/Videos',
          'c:/users/me/videos/',
        ]),
        ['C:/Users/me/Pictures', 'C:/Users/me/Videos'],
      );
      expect(isUnderWindowsRoot('C:/A/b.jpg', 'c:/a'), isTrue);
      expect(isUnderWindowsRoot('C:/AB/b.jpg', 'C:/A'), isFalse);
      expect(sameWindowsPath(r'C:\A\', 'c:/a'), isTrue);
    });
  });
}
