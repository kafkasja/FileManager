import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/session/data/session_providers.dart';

import '../../core/files/fake_file_source.dart';
import 'folders_test_harness.dart';

const _mediaOnly = StorageAccess(
  media: MediaAccess.granted,
  allFiles: AllFilesAccess.notGranted,
  mediaManagement: false,
  mediaManagementSupported: true,
);

/// Copy fails with `noSpace` for [fullAt].
class _FullDisk extends FakeFileSource {
  new(this.fullAt);

  final String fullAt;

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    if (f.name == fullAt) {
      throw FileOpException(FileOpFailure.noSpace, 'full', fileId: f.id);
    }
    return await super.copy(f, targetFolder);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFileSource files;
  late List<FileRef> photos;

  setUp(() {
    files = FakeFileSource();
    photos = [
      for (final n in ['a', 'b', 'c', 'd'])
        files.addFile('/s/DCIM/Cam/$n.jpg', bytes: List.filled(10, 1)),
    ];
    files.addFolder('/s/DCIM/Holiday');
  });

  group('move', () {
    test(
      'moves every file, asks write access once, updates the index',
      () async {
        final h = await launchFolders(files);
        final done = await h.run(MoveOp(photos, '/s/DCIM/Holiday'));

        expect(done.succeeded, 4);
        expect(done.failed, 0);
        expect(done.cancelled, isFalse);
        expect(files.calls.where((c) => c.startsWith('requestWriteAccess')), [
          'requestWriteAccess 4',
        ]);
        final ids = await h.indexedIds();
        for (final p in photos) {
          expect(ids, isNot(contains(p.id)));
          expect(ids, contains('path:/s/DCIM/Holiday/${p.name}'));
        }
        final row = await h.indexed('path:/s/DCIM/Holiday/a.jpg');
        expect(row!.folderPath, '/s/DCIM/Holiday');
      },
    );

    test('declined consent moves nothing', () async {
      files.declineWriteAccess = true;
      final h = await launchFolders(files);
      final done = await h.run(MoveOp(photos, '/s/DCIM/Holiday'));

      expect(done.declined, isTrue);
      expect(done.succeeded, 0);
      expect(files.calls.where((c) => c.startsWith('move')), isEmpty);
      expect(files.files.every((f) => f.folderPath == '/s/DCIM/Cam'), isTrue);
    });

    test('cancel halfway leaves exactly the processed files moved', () async {
      final h = await launchFolders(files);
      final cancel = CancelToken();
      final events = <OperationProgress>[];
      final done = await h.run(
        MoveOp(photos, '/s/DCIM/Holiday'),
        cancel: cancel,
        onProgress: (p) {
          events.add(p);
          if (p.done == 2) cancel.cancel();
        },
      );

      expect(done.cancelled, isTrue);
      expect(done.results, hasLength(2));
      final inHoliday = files.files.where(
        (f) => f.folderPath == '/s/DCIM/Holiday',
      );
      expect(inHoliday.map((f) => f.name), unorderedEquals(['a.jpg', 'b.jpg']));
      expect(events.first.total, 4);
      expect(events.first.bytesTotal, 40);
      expect(events.last.bytesDone, 20);
    });

    test('a missing file fails, the rest go on', () async {
      files.removeExternally(photos[1].id);
      final h = await launchFolders(files);
      final done = await h.run(MoveOp(photos, '/s/DCIM/Holiday'));

      expect(done.succeeded, 3);
      expect(done.failed, 1);
      expect(done.results[1].error!.failure, FileOpFailure.notFound);
    });

    test('same folder is a no-op without a collision prompt', () async {
      final h = await launchFolders(files);
      final done = await h.run(MoveOp([photos[0]], '/s/DCIM/Cam'));
      expect(done.results.single.after, photos[0]);
    });
  });

  group('collisions', () {
    setUp(() {
      for (final n in ['a', 'b', 'c']) {
        files.addFile('/s/DCIM/Holiday/$n.jpg', bytes: [9]);
      }
    });

    test('Keep both + apply to all asks once and makes (1) copies', () async {
      final h = await launchFolders(files);
      var asked = 0;
      final done = await h.run(
        CopyOp(photos.sublist(0, 3), '/s/DCIM/Holiday'),
        resolve: (incoming, existing) async {
          asked++;
          expect(incoming, photos[0]);
          expect(existing.path, '/s/DCIM/Holiday/a.jpg');
          return (CollisionChoice.keepBoth, true);
        },
      );

      expect(asked, 1);
      expect(done.succeeded, 3);
      expect(done.results.map((r) => r.after!.name), [
        'a (1).jpg',
        'b (1).jpg',
        'c (1).jpg',
      ]);
    });

    test('Skip leaves the file alone', () async {
      final h = await launchFolders(files);
      final done = await h.run(
        CopyOp(photos, '/s/DCIM/Holiday'),
        resolve: (_, _) async => (CollisionChoice.skip, false),
      );

      // a, b, c collide (asked each time), d doesn't.
      expect(done.skipped, 3);
      expect(done.succeeded, 1);
      expect(done.results.last.after!.name, 'd.jpg');
    });

    test('Replace trashes the existing file, never overwrites', () async {
      final h = await launchFolders(files);
      final existing = files.files.firstWhere(
        (f) => f.path == '/s/DCIM/Holiday/a.jpg',
      );
      final done = await h.run(
        CopyOp([photos[0]], '/s/DCIM/Holiday'),
        resolve: (_, _) async => (CollisionChoice.replace, false),
      );

      final r = done.results.single;
      expect(r.replaced, existing);
      expect(r.trashed!.original, existing);
      expect(r.after!.name, 'a.jpg');
      expect(r.after!.sizeBytes, 10);
      expect(files.trash.values.map((t) => t.original), [existing]);
    });

    test('a Replace whose trash fails reports the file failed', () async {
      final existing = files.files.firstWhere(
        (f) => f.path == '/s/DCIM/Holiday/a.jpg',
      );
      files.folderUnavailable.add(existing.id);
      final h = await launchFolders(files);
      final done = await h.run(
        CopyOp([photos[0]], '/s/DCIM/Holiday'),
        resolve: (_, _) async => (CollisionChoice.replace, false),
      );

      expect(done.failed, 1);
      expect(files.calls.where((c) => c.startsWith('copy')), isEmpty);
      expect(files.files, contains(existing));
    });
  });

  group('copy / duplicate', () {
    test('duplicate makes a (1).jpg next to the original', () async {
      final h = await launchFolders(files);
      final done = await h.run(DuplicateOp([photos[0]]));
      expect(done.results.single.after!.path, '/s/DCIM/Cam/a (1).jpg');
      expect(await h.indexedIds(), contains('path:/s/DCIM/Cam/a (1).jpg'));
    });

    test('not enough space refuses before any copy', () async {
      files.freeBytesValue = FileOperationRunner.spaceMargin + 39;
      final h = await launchFolders(files);
      await expectLater(
        h.runner.run(
          CopyOp(photos, '/s/DCIM/Holiday'),
          cancel: CancelToken(),
          resolveCollision: (_, _) => fail('no prompt'),
        ),
        throwsA(
          isA<NotEnoughSpaceException>()
              .having(
                (e) => e.neededBytes,
                'needed',
                40 + FileOperationRunner.spaceMargin,
              )
              .having(
                (e) => e.freeBytes,
                'free',
                FileOperationRunner.spaceMargin + 39,
              ),
        ),
      );
      expect(files.calls.where((c) => c.startsWith('copy')), isEmpty);
    });

    test('enough space (or unknown) copies', () async {
      files.freeBytesValue = FileOperationRunner.spaceMargin + 40;
      final h = await launchFolders(files);
      final done = await h.run(CopyOp(photos, '/s/DCIM/Holiday'));
      expect(done.succeeded, 4);
    });

    test('noSpace mid-batch stops the batch', () async {
      final full = _FullDisk('b.jpg');
      final ps = [
        for (final n in ['a', 'b', 'c']) full.addFile('/s/DCIM/Cam/$n.jpg'),
      ];
      full.addFolder('/s/DCIM/Holiday');
      final h = await launchFolders(full);
      final done = await h.run(CopyOp(ps, '/s/DCIM/Holiday'));

      expect(done.results, hasLength(2));
      expect(done.results[1].error!.failure, FileOpFailure.noSpace);
      expect(full.files.where((f) => f.name == 'c.jpg'), hasLength(1));
      // The untouched file is reported, not hidden.
      expect(done.stoppedEarly, isTrue);
      expect(done.cancelled, isFalse);
      expect(done.notProcessed, 1);
    });
  });

  group('review fixes', () {
    late FlakyFileSource flaky;
    late List<FileRef> ps;

    setUp(() {
      flaky = FlakyFileSource();
      ps = [
        for (final n in ['a', 'b', 'c', 'd'])
          flaky.addFile('/s/DCIM/Cam/$n.jpg', bytes: List.filled(10, 1)),
      ];
      flaky.addFolder('/s/DCIM/Holiday');
    });

    test('a Replace whose copy fails puts the replaced file back', () async {
      final existing = flaky.addFile('/s/DCIM/Holiday/a.jpg', bytes: [9]);
      flaky.failOpsOn.add('a.jpg');
      final h = await launchFolders(flaky);
      final done = await h.run(
        CopyOp([ps[0]], '/s/DCIM/Holiday'),
        resolve: (_, _) async => (CollisionChoice.replace, false),
      );

      final r = done.results.single;
      expect(r.error!.failure, FileOpFailure.ioError);
      expect(r.trashed, isNull);
      expect(flaky.trash, isEmpty);
      expect(flaky.files, contains(existing));
      expect(await h.indexedIds(), contains(existing.id));
      expect(done.isUndoable, isFalse);
    });

    test(
      'a Replace whose copy and put-back both fail stays undoable',
      () async {
        final existing = flaky.addFile('/s/DCIM/Holiday/a.jpg', bytes: [9]);
        flaky
          ..failOpsOn.add('a.jpg')
          ..declineDialogs = true;
        final h = await launchFolders(flaky);
        final done = await h.run(
          CopyOp([ps[0]], '/s/DCIM/Holiday'),
          resolve: (_, _) async => (CollisionChoice.replace, false),
        );

        final r = done.results.single;
        expect(r.error!.failure, FileOpFailure.ioError);
        expect(r.trashed!.original, existing);
        expect(done.isUndoable, isTrue);

        flaky.declineDialogs = false;
        final out = await h.runner.undo(done);
        await h.settle();
        expect(out.failed, isEmpty);
        expect(flaky.trash, isEmpty);
        expect(flaky.files, contains(existing));
      },
    );

    test('a file never collides with itself (case-insensitive path)', () async {
      final h = await launchFolders(flaky);
      // The resolver fails the test if asked.
      final done = await h.run(MoveOp([ps[0]], '/s/dcim/cam'));
      expect(done.results.single.trashed, isNull);
      expect(flaky.trash, isEmpty);
    });

    test(
      'two files with one name into a folder: the second keeps both',
      () async {
        final original = flaky.addFile('/s/DCIM/Holiday/x.jpg', bytes: [7]);
        final fromA = flaky.addFile('/s/A/x.jpg');
        final fromB = flaky.addFile('/s/B/x.jpg');
        final h = await launchFolders(flaky);
        var asked = 0;
        final done = await h.run(
          MoveOp([fromA, fromB], '/s/DCIM/Holiday'),
          resolve: (_, existing) async {
            asked++;
            expect(existing, original);
            return (CollisionChoice.replace, true);
          },
        );

        expect(asked, 1);
        expect(done.results.map((r) => r.after!.name), ['x.jpg', 'x (1).jpg']);
        expect(done.results[1].trashed, isNull);
        expect(flaky.trash.values.map((t) => t.original), [original]);

        final out = await h.runner.undo(done);
        await h.settle();
        expect(out.undone, 2);
        expect(
          flaky.files.map((f) => f.path),
          containsAll(<String>[
            '/s/A/x.jpg',
            '/s/B/x.jpg',
            '/s/DCIM/Holiday/x.jpg',
          ]),
        );
        final back = flaky.files.singleWhere(
          (f) => f.path == '/s/DCIM/Holiday/x.jpg',
        );
        expect(back.sizeBytes, 1);
      },
    );

    test('permanent delete that throws midway keeps what it did', () async {
      flaky.deleteThenThrowAfter = 2;
      final h = await launchFolders(flaky);
      final done = await h.run(DeleteOp(ps, permanent: true));

      expect(done.succeeded, 2);
      expect(done.failed, 2);
      expect(done.results.take(2).every((r) => r.error == null), isTrue);
      final ids = await h.indexedIds();
      expect(ids, isNot(contains(ps[0].id)));
      expect(ids, isNot(contains(ps[1].id)));
      expect(ids, containsAll([ps[2].id, ps[3].id]));
    });

    test('undo of a case-only rename renames back', () async {
      final h = await launchFolders(flaky);
      final done = await h.run(RenameOp(ps[0], 'A.jpg'));
      expect(done.results.single.after!.name, 'A.jpg');

      final out = await h.runner.undo(done);
      expect(out.undone, 1);
      expect(flaky.files.map((f) => f.name), contains('a.jpg'));
      expect(flaky.files.map((f) => f.name), isNot(contains('A.jpg')));
    });

    test('undo of a rename whose old name is taken now fails', () async {
      final h = await launchFolders(flaky);
      final done = await h.run(RenameOp(ps[0], 'beach.jpg'));
      flaky.addFile('/s/DCIM/Cam/a.jpg');

      final out = await h.runner.undo(done);
      expect(out.undone, 0);
      expect(out.failed.single.failure, FileOpFailure.targetExists);
      expect(flaky.files.map((f) => f.name), contains('beach.jpg'));
    });

    test('index updates never hold the history lock', () async {
      final h = await launchFolders(flaky);
      final gate = flaky.holdScans();
      final scan = h.c.read(mediaIndexerProvider).fullScan();

      final done = await h.runner.run(
        MoveOp([ps[0]], '/s/DCIM/Holiday'),
        cancel: CancelToken(),
        resolveCollision: (_, _) => fail('no collision expected'),
      );
      expect(done.succeeded, 1);
      // The lock is free although the indexer is still busy.
      expect(await h.c.read(historyLockProvider).run(() async => 1), 1);

      gate.complete();
      await scan;
      await h.settle();
      final row = await h.indexed('path:/s/DCIM/Holiday/a.jpg');
      expect(row!.folderPath, '/s/DCIM/Holiday');
    });
  });

  group('delete', () {
    test('trash mode (default) trashes and drops index rows', () async {
      final h = await launchFolders(files);
      final op = await h.runner.deleteOp(photos.sublist(0, 2));
      expect(op.permanent, isFalse);
      final done = await h.run(op);

      expect(done.succeeded, 2);
      expect(done.results.every((r) => r.trashed != null), isTrue);
      expect(done.isUndoable, isTrue);
      expect(files.trash, hasLength(2));
      final ids = await h.indexedIds();
      expect(ids, isNot(contains(photos[0].id)));
      expect(ids, contains(photos[2].id));
    });

    test('permanent mode deletes for good, nothing to undo', () async {
      final h = await launchFolders(files);
      await h.c
          .read(settingsRepositoryProvider)
          .write(AppSettings.deleteMode, 'permanent');
      final op = await h.runner.deleteOp([photos[0]]);
      expect(op.permanent, isTrue);
      final done = await h.run(op);

      expect(done.succeeded, 1);
      expect(done.isUndoable, isFalse);
      expect(files.trash, isEmpty);
      expect(files.files, isNot(contains(photos[0])));
      expect(await h.indexedIds(), isNot(contains(photos[0].id)));
    });

    test('pending folder unavailable is reported for the fallback', () async {
      files.folderUnavailable.add(photos[1].id);
      final h = await launchFolders(files);
      final done = await h.run(
        DeleteOp(photos.sublist(0, 2), permanent: false),
      );

      expect(done.succeeded, 1);
      expect(done.pendingFolderUnavailable, [photos[1]]);
      expect(await h.indexedIds(), contains(photos[1].id));
    });
  });

  test('loadForAction leaves out non-media without All files access', () async {
    final pdf = files.addFile('/s/Download/a.pdf');
    final h = await launchFolders(files, access: _mediaOnly);
    // The pdf isn't indexed without All files access: index it by hand.
    await h.c.read(mediaIndexerProvider).addFiles([pdf]);
    final got = await h.runner.loadForAction([
      photos[0].id,
      pdf.id,
      'path:/gone.jpg',
    ]);

    expect(got.files.map((f) => f.id), [photos[0].id]);
    expect(got.needAllFiles, 1);
    expect(got.missing, 1);
  });
}
