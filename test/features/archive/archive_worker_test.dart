import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';
import 'package:kfm/features/archive/data/archive_worker.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';

import 'zip_fixtures.dart';

Future<void> write(String path, List<int> bytes) async {
  await File(path).parent.create(recursive: true);
  await File(path).writeAsBytes(bytes);
}

bool never() => false;

void main() {
  late String dir;

  setUp(() async => dir = await tempFolder('kfm_zip'));
  tearDown(() => deleteFolder(dir));

  Future<ArchiveOutput> compress(
    List<String> sources,
    String output, {
    bool Function() isCancelled = never,
    void Function(ArchiveProgress)? onProgress,
    String? root,
  }) => compressArchive(
    CompressJob(
      sourcePaths: sources,
      rootFolder: root ?? dir,
      outputPath: output,
    ),
    tempPath: tempPathIn(dir, extension: '.zip'),
    isCancelled: isCancelled,
    onProgress: onProgress,
  );

  Future<ArchiveOutput> extract(
    String zip,
    String target, {
    Set<String>? names,
    String? password,
    bool Function() isCancelled = never,
    String? temp,
  }) => extractArchive(
    ExtractJob(
      zipPath: zip,
      targetFolder: target,
      entryNames: names,
      password: password,
    ),
    tempPath: temp ?? tempPathIn(dir),
    isCancelled: isCancelled,
  );

  /// Nothing but [expected] at the top of [dir] (no temp leftovers).
  Future<void> expectOnly(List<String> expected) async =>
      expect(await namesIn(dir), expected..sort());

  test('round trip keeps every byte, folder and name', () async {
    final src = '$dir/tree';
    final files = {
      'top.txt': utf8.encode('hello'),
      'empty.bin': <int>[],
      'big.dat': noise(3 * 1024 * 1024 + 17),
      'photo.jpg': noise(4096, 2),
      'nested/deeper/deepest/x.md': utf8.encode('# x'),
      'ünïcødé/Fotoğraf 文件.txt': utf8.encode('ç'),
    };
    for (final MapEntry(:key, :value) in files.entries) {
      await write('$src/$key', value);
    }
    await Directory('$src/empty folder').create(recursive: true);

    final progress = <ArchiveProgress>[];
    final zipped = await compress(
      [src],
      '$dir/tree.zip',
      onProgress: progress.add,
    );
    expect(zipped.files, ['$dir/tree.zip']);
    expect(zipped.dirs, isEmpty);
    expect(progress.first.bytesDone, 0);
    final total = files.values.fold(0, (s, b) => s + b.length);
    expect(progress.first.bytesTotal, total);

    final out = await extract('$dir/tree.zip', '$dir/out');
    final before = await treeOf(src);
    final after = await treeOf('$dir/out/tree');
    expect(after.keys.toSet(), before.keys.toSet());
    for (final key in before.keys) {
      expect(after[key], before[key], reason: key);
    }
    expect(out.files.length, files.length);
    expect(out.files, everyElement(startsWith('$dir/out/tree/')));
    expect(out.dirs.first, '$dir/out');
    expect(out.dirs, contains('$dir/out/tree/empty folder'));
    await expectOnly(['out', 'tree', 'tree.zip']);
  });

  test('already-compressed types are stored, others deflated', () async {
    await write('$dir/a.jpg', noise(1000));
    await write('$dir/b.MP4', noise(1000));
    await write('$dir/c.txt', utf8.encode('text ' * 200));
    await compress(['$dir/a.jpg', '$dir/b.MP4', '$dir/c.txt'], '$dir/out.zip');
    final input = InputFileStream('$dir/out.zip');
    addTearDown(input.close);
    final decoder = ZipDecoder()..decodeStream(input);
    final methods = {
      for (final h in decoder.directory.fileHeaders)
        h.filename: h.compressionMethod,
    };
    expect(methods, {'a.jpg': 0, 'b.MP4': 0, 'c.txt': 8});
    // Stored entries carry their sizes up front (no data descriptor).
    final a = decoder.directory.fileHeaders.first;
    expect(a.generalPurposeBitFlag & 0x08, 0);
  });

  test('a name taken by then gets " (1)"', () async {
    await write('$dir/a.txt', [1]);
    await write('$dir/out.zip', [9]);
    final zipped = await compress(['$dir/a.txt'], '$dir/out.zip');
    expect(zipped.files, ['$dir/out (1).zip']);
    expect(await File('$dir/out.zip').readAsBytes(), [9]);
  });

  test('cancel mid-compress removes the temp file', () async {
    for (var i = 0; i < 4; i++) {
      await write('$dir/src/f$i.bin', noise(2 * 1024 * 1024, i + 1));
    }
    var checks = 0;
    await expectLater(
      compress(['$dir/src'], '$dir/out.zip', isCancelled: () => ++checks > 6),
      throwsA(isA<ArchiveCancelled>()),
    );
    await expectOnly(['src']);
  });

  test('folder compress skips system temp files and caches', () async {
    await write('$dir/src/keep.txt', [1]);
    await write('$dir/src/.hidden.txt', [2]);
    await write('$dir/src/.trashed-1700000000-old.jpg', [3]);
    await write('$dir/src/.pending-1700000000-new.jpg', [4]);
    await write('$dir/src/.kfm-tmp-0123456789abcdef.zip', [5]);
    await write('$dir/src/.thumbnails/t.jpg', [6]);
    await write('$dir/src/.KFMTrash/x.jpg', [7]);
    await compress(['$dir/src'], '$dir/out.zip');
    expect(listArchive('$dir/out.zip').entries.map((e) => e.name), [
      'src/',
      'src/.hidden.txt',
      'src/keep.txt',
    ]);
  });

  test('a large entry stops within a megabyte or two of the cancel', () async {
    final raf = await File('$dir/big.bin').open(mode: FileMode.write);
    for (var i = 0; i < 16; i++) {
      await raf.writeFrom(noise(1024 * 1024, i + 1));
    }
    await raf.close();
    var cancelled = false;
    var doneAtCancel = 0;
    var doneLast = 0;
    await expectLater(
      compress(
        ['$dir/big.bin'],
        '$dir/out.zip',
        isCancelled: () => cancelled,
        onProgress: (p) {
          doneLast = p.bytesDone;
          if (!cancelled && p.bytesDone >= 2 * 1024 * 1024) {
            cancelled = true;
            doneAtCancel = p.bytesDone;
          }
        },
      ),
      throwsA(isA<ArchiveCancelled>()),
    );
    expect(doneAtCancel, greaterThan(0));
    expect(doneLast - doneAtCancel, lessThanOrEqualTo(2 * 1024 * 1024));
    await expectOnly(['big.bin']);
  });

  test('no cancel once the move into place started', () async {
    await write('$dir/a.txt', [1, 2]);
    var moving = false;
    final zipped = await compressArchive(
      CompressJob(
        sourcePaths: ['$dir/a.txt'],
        rootFolder: dir,
        outputPath: '$dir/a.zip',
      ),
      tempPath: tempPathIn(dir, extension: '.zip'),
      isCancelled: () => moving,
      onMoving: () => moving = true,
    );
    expect(moving, isTrue);
    expect(zipped.files, ['$dir/a.zip']);

    moving = false;
    final out = await extractArchive(
      ExtractJob(zipPath: '$dir/a.zip', targetFolder: '$dir/t'),
      tempPath: tempPathIn(dir),
      isCancelled: () => moving,
      onMoving: () => moving = true,
    );
    expect(moving, isTrue);
    expect(await File(out.files.single).readAsBytes(), [1, 2]);
  });

  test('bad deflate data is a damaged zip, not an I/O error', () async {
    await write('$dir/a.txt', utf8.encode('hello world ' * 2000));
    await compress(['$dir/a.txt'], '$dir/z.zip');
    final (start, length) = entryData('$dir/z.zip', 'a.txt');
    final bytes = await File('$dir/z.zip').readAsBytes();
    // 0xFF: a final block of the reserved type 3, which no inflater takes.
    for (var i = start; i < start + min(length, 64); i++) {
      bytes[i] = 0xff;
    }
    await File('$dir/z.zip').writeAsBytes(bytes);
    await expectLater(
      extract('$dir/z.zip', '$dir/out'),
      throwsA(isA<CorruptArchive>()),
    );
    await expectOnly(['a.txt', 'z.zip']);
  });

  group('extract', () {
    late String zip;

    setUp(() async {
      zip = '$dir/in.zip';
      await writeRawZip(zip, [
        RawEntry('a.txt', data: utf8.encode('A')),
        const RawEntry('docs/'),
        RawEntry('docs/x.txt', data: utf8.encode('X')),
        RawEntry('sub/deep/c.txt', data: utf8.encode('C')),
        RawEntry('new.txt', data: utf8.encode('N')),
      ]);
    });

    test('into an existing folder renames clashes', () async {
      final target = '$dir/target';
      await write('$target/a.txt', utf8.encode('mine'));
      await Directory('$target/docs').create();
      final out = await extract(zip, target);
      expect(await namesIn(target), [
        'a (1).txt',
        'a.txt',
        'docs',
        'docs (1)',
        'new.txt',
        'sub',
      ]);
      expect(await File('$target/a.txt').readAsString(), 'mine');
      expect(await File('$target/docs (1)/x.txt').readAsString(), 'X');
      expect(out.files.toSet(), {
        '$target/a (1).txt',
        '$target/docs (1)/x.txt',
        '$target/sub/deep/c.txt',
        '$target/new.txt',
      });
      expect(out.dirs.toSet(), {
        '$target/docs (1)',
        '$target/sub',
        '$target/sub/deep',
      });
      // The hidden temp folder is gone.
      expect(
        (await namesIn(target)).where((n) => n.startsWith('.kfm-tmp-')),
        isEmpty,
      );
    });

    test('folders that differ only in case end up in one folder', () async {
      await writeRawZip(zip, [
        const RawEntry('Photos/a.jpg', data: [1]),
        const RawEntry('photos/b.jpg', data: [2]),
        const RawEntry('photos/A.JPG', data: [3]),
        const RawEntry('PHOTOS/sub/c.jpg', data: [4]),
      ]);
      final target = '$dir/t';
      await Directory(target).create();
      final out = await extract(zip, target);
      expect(out.files.toSet(), hasLength(4));
      final contents = <int>{};
      for (final f in out.files) {
        expect(f, startsWith('$target/Photos/'));
        expect(File(f).existsSync(), isTrue, reason: f);
        contents.addAll(await File(f).readAsBytes());
      }
      expect(contents, {1, 2, 3, 4});
      expect(out.dirs.toSet(), {'$target/Photos', '$target/Photos/sub'});
    });

    test('"Extract this" on a folder: its name picks what is below', () async {
      final target = '$dir/t';
      await Directory(target).create();
      final out = await extract(zip, target, names: {'sub'});
      expect(out.files, ['$target/sub/deep/c.txt']);
    });

    test('"Extract this" drops the parent folders', () async {
      final target = '$dir/t';
      await Directory(target).create();
      final one = await extract(zip, target, names: {'sub/deep/c.txt'});
      expect(one.files, ['$target/c.txt']);
      final folder = await extract(zip, target, names: {'docs/'});
      expect(folder.files, ['$target/docs/x.txt']);
      expect(await namesIn(target), ['c.txt', 'docs']);
    });

    test('Windows-made CP437 names decode', () async {
      await writeRawZip(zip, [
        const RawEntry(
          'x',
          rawName: [0x9A, 0x62, 0x65, 0x72, 0x2E, 0x74, 0x78, 0x74],
          utf8Flag: false,
          data: [1],
        ),
      ]);
      expect(listArchive(zip).entries.single.name, 'Über.txt');
      final out = await extract(zip, '$dir/o');
      expect(out.files, ['$dir/o/Über.txt']);
    });

    test('lists entries without reading data', () {
      final listing = listArchive(zip);
      expect(listing.entries.map((e) => e.name), [
        'a.txt',
        'docs/',
        'docs/x.txt',
        'sub/deep/c.txt',
        'new.txt',
      ]);
      expect(listing.entries[1].isDirectory, isTrue);
      expect(listing.uncompressedTotal, 4);
      expect(listing.zipSize, File(zip).lengthSync());
      expect(listing.looksLikeBomb, isFalse);
    });

    test('cancel mid-extract removes the temp folder', () async {
      await writeRawZip(zip, [
        for (var i = 0; i < 3; i++)
          RawEntry('f$i.bin', data: noise(3 * 1024 * 1024, i + 3)),
      ]);
      var checks = 0;
      await expectLater(
        extract(zip, '$dir/out', isCancelled: () => ++checks > 3),
        throwsA(isA<ArchiveCancelled>()),
      );
      await expectOnly(['in.zip']);
    });
  });

  group('refuses unsafe archives and writes nothing', () {
    for (final name in ['../evil.txt', '/abs/path', 'a/../../b']) {
      test(name, () async {
        await writeRawZip('$dir/bad.zip', [
          const RawEntry('ok.txt', data: [1]),
          RawEntry(name, data: [2]),
        ]);
        await expectLater(
          extract('$dir/bad.zip', '$dir/out'),
          throwsA(isA<UnsafeEntryPath>().having((e) => e.entry, 'entry', name)),
        );
        await expectOnly(['bad.zip']);
      });
    }

    test('symlink entry', () async {
      await writeRawZip('$dir/bad.zip', [
        const RawEntry('ok.txt', data: [1]),
        RawEntry('link', data: utf8.encode('/etc/passwd'), unixMode: 0xA1FF),
      ]);
      await expectLater(
        extract('$dir/bad.zip', '$dir/out'),
        throwsA(isA<UnsafeEntryPath>()),
      );
      await expectOnly(['bad.zip']);
    });
  });

  group('corrupt archives', () {
    test('not a zip', () async {
      await write('$dir/bad.zip', noise(5000));
      expect(() => listArchive('$dir/bad.zip'), throwsA(isA<CorruptArchive>()));
      await expectLater(
        extract('$dir/bad.zip', '$dir/out'),
        throwsA(isA<CorruptArchive>()),
      );
      await expectOnly(['bad.zip']);
    });

    test('bad data: checksum mismatch leaves no partial folder', () async {
      await writeRawZip('$dir/bad.zip', [
        RawEntry('good.txt', data: utf8.encode('good')),
        RawEntry('broken.txt', data: utf8.encode('broken data')),
      ]);
      final bytes = await File('$dir/bad.zip').readAsBytes();
      // Flip a byte inside "broken data".
      final at = latin1.decode(bytes).indexOf('broken data');
      bytes[at + 2] ^= 0xff;
      await File('$dir/bad.zip').writeAsBytes(bytes);
      await expectLater(
        extract('$dir/bad.zip', '$dir/out'),
        throwsA(isA<CorruptArchive>()),
      );
      await expectOnly(['bad.zip']);
    });

    test('truncated', () async {
      await write('$dir/a.txt', noise(10000));
      await compress(['$dir/a.txt'], '$dir/full.zip');
      final bytes = await File('$dir/full.zip').readAsBytes();
      await File('$dir/cut.zip').writeAsBytes(bytes.sublist(0, 5000));
      await expectLater(
        extract('$dir/cut.zip', '$dir/out'),
        throwsA(isA<CorruptArchive>()),
      );
      await expectOnly(['a.txt', 'cut.zip', 'full.zip']);
    });
  });

  group('password', () {
    late String zip;

    setUp(() async {
      await write('$dir/secret.txt', utf8.encode('top secret ' * 50));
      zip = '$dir/p.zip';
      final encoder = ZipFileEncoder(password: 'right')..create(zip);
      await encoder.addFile(File('$dir/secret.txt'));
      await encoder.close();
      await File('$dir/secret.txt').delete();
    });

    test('listing shows encrypted entries without a password', () {
      expect(listArchive(zip).entries.single.encrypted, isTrue);
    });

    test('needed', () async {
      await expectLater(
        extract(zip, '$dir/out'),
        throwsA(isA<PasswordNeeded>()),
      );
      await expectOnly(['p.zip']);
    });

    test('wrong', () async {
      await expectLater(
        extract(zip, '$dir/out', password: 'wrong'),
        throwsA(isA<WrongPassword>()),
      );
      await expectOnly(['p.zip']);
    });

    test('right', () async {
      final out = await extract(zip, '$dir/out', password: 'right');
      expect(out.files, ['$dir/out/secret.txt']);
      expect(
        await File('$dir/out/secret.txt').readAsString(),
        'top secret ' * 50,
      );
    });
  });

  group('AES', () {
    /// An AES zip of [files] (archive's encoder takes [password]'s char
    /// codes as its bytes).
    Future<String> aesZip(Map<String, List<int>> files, String password) async {
      final zip = '$dir/aes.zip';
      final encoder = ZipFileEncoder(password: password)..create(zip);
      for (final MapEntry(:key, :value) in files.entries) {
        await write('$dir/in/$key', value);
        await encoder.addFile(File('$dir/in/$key'));
      }
      await encoder.close();
      await Directory('$dir/in').delete(recursive: true);
      return zip;
    }

    /// Flips a byte of [name]'s authentication code (its last 10 bytes):
    /// the data and CRC stay intact, only the MAC check can notice.
    Future<void> breakMac(String zip, String name) async {
      final (start, length) = entryData(zip, name);
      final bytes = await File(zip).readAsBytes();
      bytes[start + length - 3] ^= 0x5a;
      await File(zip).writeAsBytes(bytes);
    }

    test('a bad MAC on the first entry: wrong password', () async {
      final zip = await aesZip({'a.txt': utf8.encode('A' * 300)}, 'pw');
      await breakMac(zip, 'a.txt');
      await expectLater(
        extract(zip, '$dir/out', password: 'pw'),
        throwsA(isA<WrongPassword>()),
      );
      await expectOnly(['aes.zip']);
    });

    test('a bad MAC after a good entry: damaged', () async {
      final zip = await aesZip({
        'a.txt': utf8.encode('A' * 300),
        'b.txt': utf8.encode('B' * 300),
      }, 'pw');
      expect(listArchive(zip).entries.map((e) => e.name), ['a.txt', 'b.txt']);
      await breakMac(zip, 'b.txt');
      await expectLater(
        extract(zip, '$dir/out', password: 'pw'),
        throwsA(isA<CorruptArchive>()),
      );
      await expectOnly(['aes.zip']);
    });

    test('non-ASCII passwords are used as UTF-8', () async {
      // Made the way 7-Zip does it: the key comes from the UTF-8 bytes.
      final zip = await aesZip({
        'a.txt': utf8.encode('geheim'),
      }, zipPassword('pässwörd'));
      await expectLater(
        extract(zip, '$dir/out', password: 'passwörd'),
        throwsA(isA<WrongPassword>()),
      );
      final out = await extract(zip, '$dir/out', password: 'pässwörd');
      expect(await File(out.files.single).readAsString(), 'geheim');
    });
  });
}
