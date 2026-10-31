import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/archive/data/archive_service.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/session/data/session_providers.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import 'zip_fixtures.dart';

/// [FakeFileSource] over real files: [registerCreated] reads them from
/// disk, [trashBatch] also deletes them there.
class _DiskFake extends FakeFileSource {
  /// Android 11+ system trash: the file is renamed in place
  /// (`.trashed-<ts>-name`) instead of disappearing.
  bool trashInPlace = false;

  /// The trash dialog is declined.
  bool declineTrash = false;

  /// [registerCreated] finds nothing.
  bool registerNothing = false;

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) async {
    if (registerNothing) return const [];
    for (final p in paths) {
      final f = File(p);
      if (await f.exists()) addFile(p, bytes: await f.readAsBytes());
    }
    return await super.registerCreated(paths);
  }

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    if (declineTrash) {
      return const TrashResult(trashed: [], failed: {}, userCancelled: true);
    }
    final res = await super.trashBatch(files);
    for (final t in res.trashed) {
      final f = File(t.original.path);
      if (!await f.exists()) continue;
      if (trashInPlace) {
        await f.rename(
          '${t.original.folderPath}/.trashed-1700000000-${t.original.name}',
        );
      } else {
        await f.delete();
      }
    }
    return res;
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    await super.deletePermanentlyBatch(files);
    for (final f in files) {
      final file = File(f.path);
      if (await file.exists()) await file.delete();
    }
  }
}

class _Harness {
  new(this.c, this.db, this.files, this.ledger);

  final ProviderContainer c;
  final AppDatabase db;
  final _DiskFake files;
  final TempFileLedger ledger;

  ArchiveService get service => c.read(archiveServiceProvider);

  LastOperation? get last => c.read(lastOperationUndoProvider);

  Future<Set<String>> indexedIds() async {
    await service.indexSettled;
    await c.read(mediaIndexerProvider).addFiles(const []);
    await c.read(dbWriteQueueProvider).flush();
    return {for (final r in await db.select(db.mediaIndex).get()) r.id};
  }
}

Future<_Harness> _launch(String dir) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final files = _DiskFake();
  final ledger = TempFileLedger(File('$dir/ledger/ledger.json'));
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      fileSourceProvider.overrideWithValue(files),
      permissionServiceProvider.overrideWithValue(FakePermissionService()),
      mediaChangesProvider.overrideWithValue(const Stream.empty()),
      tempFileLedgerProvider.overrideWith((_) async => ledger),
    ],
  );
  await c.read(storageAccessControllerProvider.future);
  await c.read(mediaIndexerProvider).start();
  // Keep the undo notifier alive (it listens to idChanges).
  c.listen(lastOperationUndoProvider, (_, _) {});
  addTearDown(() async {
    await c.read(dbWriteQueueProvider).flush();
    c.dispose();
    await db.close();
    await files.dispose();
  });
  return _Harness(c, db, files, ledger);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String dir;
  late _Harness h;

  setUp(() async {
    dir = await tempFolder('kfm_zipsvc');
    h = await _launch(dir);
  });
  tearDown(() => deleteFolder(dir));

  Future<void> write(String path, List<int> bytes) async {
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(bytes);
  }

  Future<void> fixture() async {
    await write('$dir/src/a.txt', utf8.encode('A'));
    await write('$dir/src/sub/b.jpg', noise(5000));
  }

  CompressJob compressJob() => CompressJob(
    sourcePaths: ['$dir/src'],
    rootFolder: dir,
    outputPath: '$dir/src.zip',
  );

  test('compress in an isolate: progress, index, undo', () async {
    await fixture();
    final progress = <ArchiveProgress>[];
    final out = await h.service.run(
      compressJob(),
      cancel: CancelToken(),
      onProgress: progress.add,
    );
    expect(out.files, ['$dir/src.zip']);
    expect(progress, isNotEmpty);
    expect(progress.first.bytesTotal, 5001);
    expect(await h.indexedIds(), contains('path:$dir/src.zip'));
    expect(await h.ledger.entries(), isEmpty);
    final last = h.last;
    expect(last, isA<CompressDone>());
    expect((last! as CompressDone).zip.path, '$dir/src.zip');

    final listing = await h.service.list('$dir/src.zip');
    expect(listing.entries.map((e) => e.name), [
      'src/',
      'src/a.txt',
      'src/sub/',
      'src/sub/b.jpg',
    ]);

    final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
    expect(undo!.undone, 1);
    expect(File('$dir/src.zip').existsSync(), isFalse);
    expect(h.files.trash.keys, ['trash:path:$dir/src.zip']);
    expect(await h.indexedIds(), isNot(contains('path:$dir/src.zip')));
    expect(h.last, isNull);
  });

  test(
    'extract here: target name, files indexed, undo removes the folder',
    () async {
      await fixture();
      await h.service.run(compressJob(), cancel: CancelToken());
      // A folder named like the zip already exists.
      await Directory('$dir/src (1)').create();
      final target = await h.service.extractHereTarget('$dir/src.zip');
      expect(target, '$dir/src (2)');
      expect(Directory(target).existsSync(), isFalse);

      final out = await h.service.run(
        ExtractJob(zipPath: '$dir/src.zip', targetFolder: target),
        cancel: CancelToken(),
      );
      expect(out.files.toSet(), {'$target/src/a.txt', '$target/src/sub/b.jpg'});
      expect(await File('$target/src/a.txt').readAsString(), 'A');
      expect(
        await h.indexedIds(),
        containsAll(['path:$target/src/a.txt', 'path:$target/src/sub/b.jpg']),
      );
      final last = h.last! as ExtractDone;
      expect(last.files, hasLength(2));
      expect(last.dirs, contains(target));

      final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
      expect(undo!.undone, 2);
      expect(Directory(target).existsSync(), isFalse);
      expect(await h.indexedIds(), isNot(contains('path:$target/src/a.txt')));
      expect(File('$dir/src.zip').existsSync(), isTrue);
    },
  );

  test('undo extract keeps a folder the user added to', () async {
    await fixture();
    await h.service.run(compressJob(), cancel: CancelToken());
    final target = '$dir/out';
    await h.service.run(
      ExtractJob(zipPath: '$dir/src.zip', targetFolder: target),
      cancel: CancelToken(),
    );
    await write('$target/src/sub/mine.txt', [1]);
    final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
    expect(undo!.undone, 2);
    expect(await namesIn('$target/src'), ['sub']);
    expect(await namesIn('$target/src/sub'), ['mine.txt']);
  });

  test('undo counts files removed meanwhile as missing', () async {
    await fixture();
    await h.service.run(compressJob(), cancel: CancelToken());
    await h.service.run(
      ExtractJob(zipPath: '$dir/src.zip', targetFolder: '$dir/out'),
      cancel: CancelToken(),
    );
    h.files.removeExternally('path:$dir/out/src/a.txt');
    final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
    expect(undo!.undone, 1);
    expect(undo.missing, 1);
  });

  test('not enough space is refused before anything is written', () async {
    await fixture();
    h.files.freeBytesValue = 1000;
    await expectLater(
      h.service.run(compressJob(), cancel: CancelToken()),
      throwsA(
        isA<NotEnoughSpace>()
            .having((e) => e.free, 'free', 1000)
            .having(
              (e) => e.needed,
              'needed',
              5001 + ArchiveService.spaceMargin,
            ),
      ),
    );
    expect((await namesIn(dir))..remove('ledger'), ['src']);
    expect(h.last, isNull);

    h.files.freeBytesValue = null;
    await h.service.run(compressJob(), cancel: CancelToken());
    h.files.freeBytesValue = 10;
    await expectLater(
      h.service.run(
        ExtractJob(zipPath: '$dir/src.zip', targetFolder: '$dir/out'),
        cancel: CancelToken(),
      ),
      throwsA(isA<NotEnoughSpace>()),
    );
    expect(Directory('$dir/out').existsSync(), isFalse);
  });

  test('cancel stops the worker and removes the temp file', () async {
    for (var i = 0; i < 30; i++) {
      await write('$dir/src/f$i.bin', noise(1024 * 1024, i + 1));
    }
    final cancel = CancelToken();
    await expectLater(
      h.service.run(
        compressJob(),
        cancel: cancel,
        onProgress: (_) => cancel.cancel(),
      ),
      throwsA(isA<ArchiveCancelled>()),
    );
    expect((await namesIn(dir))..remove('ledger'), ['src']);
    expect(await h.ledger.entries(), isEmpty);
    expect(h.last, isNull);
  });

  ArchiveService serviceWith(Duration killAfter) => ArchiveService(
    source: h.files,
    indexer: h.c.read(mediaIndexerProvider),
    indexDao: h.c.read(mediaIndexDaoProvider),
    writes: h.c.read(dbWriteQueueProvider),
    lock: h.c.read(historyLockProvider),
    ledger: Future.value(h.ledger),
    recordUndo: (_) {},
    killAfter: killAfter,
  );

  Future<void> bigFile(String path, int megabytes) async {
    await File(path).parent.create(recursive: true);
    final raf = await File(path).open(mode: FileMode.write);
    for (var i = 0; i < megabytes; i++) {
      await raf.writeFrom(noise(1024 * 1024, i + 1));
    }
    await raf.close();
  }

  test('cancel inside one large entry stops the worker by itself', () async {
    // One big deflated file: the whole job is a single entry. With the
    // kill a minute away, only the worker's own cancel check can end it
    // early.
    await bigFile('$dir/src/big.bin', 64);
    final service = serviceWith(const Duration(minutes: 1));
    final cancel = CancelToken();
    final clock = Stopwatch();
    await expectLater(
      service.run(
        compressJob(),
        cancel: cancel,
        onProgress: (p) {
          if (p.bytesDone > 0 && !cancel.isCancelled) {
            cancel.cancel();
            clock.start();
          }
        },
      ),
      throwsA(isA<ArchiveCancelled>()),
    );
    expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
    expect((await namesIn(dir))..remove('ledger'), ['src']);
    expect(await h.ledger.entries(), isEmpty);
  });

  test('a worker that misses the kill deadline is killed', () async {
    await bigFile('$dir/src/big.bin', 16);
    final service = serviceWith(Duration.zero);
    final cancel = CancelToken();
    await expectLater(
      service.run(
        compressJob(),
        cancel: cancel,
        onProgress: (p) {
          if (p.bytesDone > 0) cancel.cancel();
        },
      ),
      throwsA(isA<ArchiveCancelled>()),
    );
    // No zip. A temp the killed worker still holds open (Windows can't
    // delete it then; Android can) stays in the ledger, which removes it at
    // the next start.
    final left = (await namesIn(dir))
      ..remove('ledger')
      ..remove('src');
    expect(left, everyElement(startsWith('.kfm-tmp-')));
    expect(await h.ledger.entries(), {for (final n in left) '$dir/$n'});
    expect(h.last, isNull);
  });

  group('Replace', () {
    test('the old zip is trashed only after the new one is written', () async {
      await fixture();
      final old = h.files.addFile('$dir/src.zip', bytes: [9]);
      await File('$dir/src.zip').writeAsBytes([9]);
      final out = await h.service.run(
        compressJob(),
        cancel: CancelToken(),
        replacing: old,
      );
      expect(out.files, ['$dir/src.zip']);
      expect(out.replaceFailed, isFalse);
      expect(h.files.trash.keys, ['trash:${old.id}']);
      expect(
        (await h.service.list('$dir/src.zip')).entries.map((e) => e.name),
        contains('src/a.txt'),
      );
      expect(await namesIn(dir), isNot(contains('src (1).zip')));
      expect(h.last, isA<CompressDone>());
    });

    test('a failed job leaves the old zip alone', () async {
      final old = h.files.addFile('$dir/src.zip', bytes: [9]);
      await File('$dir/src.zip').writeAsBytes([9]);
      await expectLater(
        h.service.run(
          CompressJob(
            sourcePaths: ['$dir/missing'],
            rootFolder: dir,
            outputPath: '$dir/src.zip',
          ),
          cancel: CancelToken(),
          replacing: old,
        ),
        throwsA(isA<ArchiveIoError>()),
      );
      expect(h.files.trash, isEmpty);
      expect(await File('$dir/src.zip').readAsBytes(), [9]);
    });

    test('declined: the old zip stays, the new one keeps " (1)"', () async {
      await fixture();
      final old = h.files.addFile('$dir/src.zip', bytes: [9]);
      await File('$dir/src.zip').writeAsBytes([9]);
      h.files.declineTrash = true;
      final out = await h.service.run(
        compressJob(),
        cancel: CancelToken(),
        replacing: old,
      );
      expect(out.files, ['$dir/src (1).zip']);
      expect(out.replaceFailed, isTrue);
      expect(out.undoRecorded, isTrue);
      expect(await File('$dir/src.zip').readAsBytes(), [9]);
      expect((h.last! as CompressDone).zip.path, '$dir/src (1).zip');
    });
  });

  test('undoRecorded is false when nothing could be registered', () async {
    await fixture();
    h.files.registerNothing = true;
    final out = await h.service.run(compressJob(), cancel: CancelToken());
    expect(out.undoRecorded, isFalse);
    expect(h.last, isNull);
  });

  group('undo extract', () {
    Future<String> extracted() async {
      await fixture();
      await h.service.run(compressJob(), cancel: CancelToken());
      final target = '$dir/out';
      await h.service.run(
        ExtractJob(zipPath: '$dir/src.zip', targetFolder: target),
        cancel: CancelToken(),
      );
      return target;
    }

    test(
      'unchanged files are deleted, so in-place trash leaves no folders',
      () async {
        final target = await extracted();
        // Android 11+: trashing renames in place (.trashed-…).
        h.files.trashInPlace = true;
        final last = h.last! as ExtractDone;
        expect(last.zipPath, '$dir/src.zip');
        expect(last.stamps, hasLength(2));
        final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
        expect(undo!.undone, 2);
        expect(Directory(target).existsSync(), isFalse);
        expect(h.files.trash, isEmpty);
        expect(
          h.files.calls.where((c) => c.startsWith('deletePermanentlyBatch')),
          hasLength(1),
        );
      },
    );

    test('a changed file is trashed (and its folder stays)', () async {
      final target = await extracted();
      h.files.trashInPlace = true;
      await File('$target/src/a.txt').writeAsString('changed!');
      h.files.addFile(
        '$target/src/a.txt',
        bytes: await File('$target/src/a.txt').readAsBytes(),
      );
      final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
      expect(undo!.undone, 2);
      expect(h.files.trash.keys, ['trash:path:$target/src/a.txt']);
      expect(File('$target/src/sub/b.jpg').existsSync(), isFalse);
      expect(Directory('$target/src/sub').existsSync(), isFalse);
      // The trashed file is still there under its .trashed- name.
      expect(await namesIn('$target/src'), [startsWith('.trashed-')]);
    });

    test('without the zip, everything is trashed', () async {
      final target = await extracted();
      await File('$dir/src.zip').delete();
      final undo = await h.c.read(lastOperationUndoProvider.notifier).undo();
      expect(undo!.undone, 2);
      expect(h.files.trash, hasLength(2));
      expect(Directory(target).existsSync(), isFalse);
    });
  });

  test('errors come back typed', () async {
    await write('$dir/bad.zip', noise(3000));
    await expectLater(
      h.service.list('$dir/bad.zip'),
      throwsA(isA<CorruptArchive>()),
    );
    await expectLater(
      h.service.run(
        ExtractJob(zipPath: '$dir/bad.zip', targetFolder: '$dir/out'),
        cancel: CancelToken(),
      ),
      throwsA(isA<CorruptArchive>()),
    );
    await writeRawZip('$dir/slip.zip', [
      const RawEntry('../evil.txt', data: [1]),
    ]);
    await expectLater(
      h.service.run(
        ExtractJob(zipPath: '$dir/slip.zip', targetFolder: '$dir/out'),
        cancel: CancelToken(),
      ),
      throwsA(isA<UnsafeEntryPath>()),
    );
    expect(File('$dir/evil.txt').existsSync(), isFalse);
    expect(Directory('$dir/out').existsSync(), isFalse);
    expect(await h.ledger.entries(), isEmpty);
  });

  test('compressBlockReason: only local ms:/path: files', () {
    FileRef ref(String id, FileOrigin origin) => FileRef(
      id: id,
      uri: '/s/a.jpg',
      name: 'a.jpg',
      kind: FileKind.image,
      sizeBytes: 1,
      modifiedAt: DateTime.utc(2024),
      folderPath: '/s',
      origin: origin,
    );
    final s = h.service;
    expect(
      s.compressBlockReason([
        ref('ms:1', FileOrigin.local),
        ref('path:/s/a.jpg', FileOrigin.local),
      ]),
      isNull,
    );
    expect(
      s.compressBlockReason([ref('path:/x', FileOrigin.external)]),
      ArchiveService.notLocalReason,
    );
    expect(
      s.compressBlockReason([ref('remote:d:1', FileOrigin.remote)]),
      ArchiveService.notLocalReason,
    );
    expect(
      s.compressBlockReason([ref('saf:x', FileOrigin.local)]),
      ArchiveService.notLocalReason,
    );
  });

  test(
    'trashForReplace trashes the old zip and drops it from the index',
    () async {
      final old = h.files.addFile('$dir/old.zip');
      await h.c.read(mediaIndexerProvider).addFiles([old]);
      expect(await h.indexedIds(), contains(old.id));
      await h.service.trashForReplace(old);
      expect(h.files.trash.keys, ['trash:${old.id}']);
      expect(await h.indexedIds(), isNot(contains(old.id)));

      final other = h.files.addFile('$dir/other.zip');
      h.files.folderUnavailable.add(other.id);
      await expectLater(
        h.service.trashForReplace(other),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.pendingFolderUnavailable,
          ),
        ),
      );
    },
  );
}
