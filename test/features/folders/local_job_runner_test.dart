import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/folders/data/fat_names.dart';
import 'package:kfm/features/folders/data/local_job_runner.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/routing_setup.dart';

class _RecordingMove implements VerifiedMove {
  final List<List<VerifiedOriginal>> calls = [];
  final List<DeleteMode> modes = [];
  SourceOutcome answer = SourceOutcome.trashed;

  @override
  Future<FinalizeResult> deleteOriginals(
    List<VerifiedOriginal> originals, {
    required DeleteMode mode,
  }) async {
    calls.add(originals);
    modes.add(mode);
    return FinalizeResult(
      outcomes: {for (final o in originals) o.original.id: answer},
    );
  }
}

void main() {
  late Setup s;
  late AppDatabase db;
  late DbWriteQueue queue;
  late LocalJobsDao dao;
  late _RecordingMove moves;
  late Set<String> unmounted;
  late List<FileRef> indexed;
  late LocalJobRunner runner;
  var jobsEnded = 0;

  LocalJobRunner build({
    bool fat32 = false,
    int? fatMax,
    VolumeActivityTracker? tracker,
  }) => LocalJobRunner(
    onJobEnded: () => jobsEnded++,
    dao: dao,
    files: s.router,
    crossPlace: s.router.crossPlace,
    verifiedMove: moves,
    addToIndex: (files) async => indexed.addAll(files),
    isMounted: (id) => !unmounted.contains(id),
    placeOfFile: s.router.placeOfFile,
    placeOfFolder: s.router.placeOfFolder,
    staging: () async => s.staging,
    isFat32: (_) async => fat32,
    fat32MaxBytes: fatMax ?? kFat32MaxFileBytes,
    stagesInTarget: s.router.saf.locator.owns,
    track: tracker?.runAll,
  );

  setUp(() {
    s = Setup();
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    dao = LocalJobsDao(db, queue);
    moves = _RecordingMove();
    unmounted = {};
    indexed = [];
    runner = build();
    s.safFake.addFolder('${s.usb}/Photos');
  });
  tearDown(() async {
    await queue.flush();
    await db.close();
    await s.dispose();
  });

  List<FileRef> addLocal(int n) => [
    for (var i = 0; i < n; i++)
      s.android.addFile('${Setup.internal}/Pictures/p$i.jpg', bytes: [i, i, i]),
  ];

  Future<LocalJobView> run(LocalJobRequest r) async {
    final id = await runner.start(r);
    await runner.idle;
    await queue.flush();
    return LocalJobView((await dao.job(id))!, await dao.files(id));
  }

  test(
    'move job: every file copied and verified, one deleteOriginals call',
    () async {
      final files = addLocal(3);
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      expect(view.job.status, LocalJobStatus.done);
      expect(jobsEnded, greaterThanOrEqualTo(1)); // Places' free space
      expect(moves.calls, hasLength(1));
      expect(moves.calls.single, hasLength(3));
      expect(moves.modes.single, DeleteMode.trash);
      for (var i = 0; i < 3; i++) {
        expect(s.safFake.bytesAt('${s.usb}/Photos/p$i.jpg'), [i, i, i]);
      }
      expect(
        view.files.map((f) => f.sourceOutcome),
        everyElement(SourceOutcome.trashed),
      );
      expect(
        view.files.map((f) => f.status),
        everyElement(LocalFileStatus.done),
      );
      expect(view.files.every((f) => f.sha256 != null), isTrue);
      expect(s.staging.listSync(), isEmpty);
    },
  );

  test('copy job: originals stay, copies are indexed when local', () async {
    final usb = await s.safFile('DCIM/a.jpg', [1, 2]);
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: [usb],
        targetFolder: '${Setup.internal}/Pictures',
      ),
    );
    expect(view.job.status, LocalJobStatus.done);
    expect(moves.calls, isEmpty);
    expect(indexed.single.name, 'a.jpg');
    expect(await s.router.stat(usb.id), isNotNull);
  });

  group('Q4 disk full / failing source mid-copy', () {
    const full = FileSystemException(
      'writeFrom failed',
      'staging/part',
      OSError('There is not enough space on the disk.', 112),
    );

    test('a full disk stops the job as no_space: nothing written, '
        'originals kept, staging empty, resumable', () async {
      final files = addLocal(3);
      s.android.readFault = (afterBytes: 2, error: full);
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      expect(view.job.status, LocalJobStatus.failed);
      expect(
        view.job.failureReason,
        LocalJobErrors.noSpace,
        reason: view.files.map((f) => '${f.status} ${f.failureReason}').join(),
      );
      // The file is queued again (Retry continues), the others untouched.
      expect(
        view.files.map((f) => f.status),
        everyElement(LocalFileStatus.queued),
      );
      expect(s.safFake.calls.where((c) => c.startsWith('importFile')), isEmpty);
      for (var i = 0; i < 3; i++) {
        expect(s.safFake.existsPath('${s.usb}/Photos/p$i.jpg'), isFalse);
        expect(await s.android.stat(files[i].id), isNotNull);
      }
      expect(moves.calls, isEmpty);
      expect(s.staging.listSync(), isEmpty);

      // Space freed: Retry finishes the job.
      s.android.readFault = null;
      await runner.resume(view.job.id);
      await runner.idle;
      await queue.flush();
      final again = (await dao.job(view.job.id))!;
      expect(again.status, LocalJobStatus.done);
      for (var i = 0; i < 3; i++) {
        expect(s.safFake.bytesAt('${s.usb}/Photos/p$i.jpg'), [i, i, i]);
      }
    });

    test('the target volume full on import: no_space, original kept', () async {
      final files = addLocal(1);
      s.safFake.importFailure = const FileOpException(
        FileOpFailure.noSpace,
        'ENOSPC',
      );
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      expect(view.job.failureReason, LocalJobErrors.noSpace);
      expect(s.safFake.existsPath('${s.usb}/Photos/p0.jpg'), isFalse);
      expect(await s.android.stat(files.single.id), isNotNull);
      expect(moves.calls, isEmpty);
      expect(s.staging.listSync(), isEmpty);
    });

    test('a read error mid-copy fails only that file; source kept', () async {
      final files = addLocal(1);
      s.android.readFault = (
        afterBytes: 1,
        error: const FileSystemException(
          'read failed',
          'x',
          OSError('The device is not ready.', 21),
        ),
      );
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      expect(view.files.single.status, LocalFileStatus.failed);
      expect(view.files.single.failureReason, FileOpFailure.ioError.name);
      expect(s.safFake.existsPath('${s.usb}/Photos/p0.jpg'), isFalse);
      expect(await s.android.stat(files.single.id), isNotNull);
      expect(moves.calls, isEmpty);
      expect(s.staging.listSync(), isEmpty);
    });
  });

  test('a checksum mismatch fails the file and keeps the source', () async {
    final files = addLocal(2);
    s.safFake.corruptNextImport = true;
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.move,
        files: files,
        targetFolder: '${s.usb}/Photos',
      ),
    );
    expect(view.job.status, LocalJobStatus.failed);
    final bad = view.files.first;
    expect(bad.status, LocalFileStatus.failed);
    expect(bad.failureReason, LocalJobErrors.verificationFailed);
    expect(s.safFake.existsPath('${s.usb}/Photos/p0.jpg'), isFalse);
    // Only the verified file's original is deleted.
    expect(moves.calls.single.map((o) => o.original.id), [files[1].id]);
  });

  test(
    'an unmounted target pauses; re-mount resumes without re-copying',
    () async {
      final files = addLocal(2);
      unmounted.add('ABCD-1234');
      final paused = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      expect(paused.job.status, LocalJobStatus.paused);
      expect(paused.job.failureReason, LocalJobErrors.placeUnmounted);
      expect(s.safFake.calls.where((c) => c.startsWith('importFile')), isEmpty);

      unmounted.clear();
      await runner.onPlacesChanged();
      await runner.idle;
      await queue.flush();
      expect((await dao.job(paused.job.id))!.status, LocalJobStatus.done);
      expect(
        s.safFake.calls.where((c) => c.startsWith('importFile')),
        hasLength(2),
      );

      // A resume of a finished job copies nothing again.
      await runner.resume(paused.job.id);
      await runner.idle;
      expect(
        s.safFake.calls.where((c) => c.startsWith('importFile')),
        hasLength(2),
      );
    },
  );

  test('verified files are never copied again after a restart', () async {
    final files = addLocal(2);
    final id = await runner.start(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: files,
        targetFolder: '${s.usb}/Photos',
      ),
    );
    await runner.idle;
    await queue.flush();
    // Simulate a kill mid-job: the second file is back to queued.
    await dao.setFile(
      id,
      1,
      const LocalJobFilesCompanion(status: Value(LocalFileStatus.copying)),
    );
    await dao.setJob(id, LocalJobStatus.running);
    s.safFake.removeDoc('${s.safFake.uuid}:Photos/p1.jpg');
    runner = build();
    await runner.recover();
    await queue.flush();
    expect((await dao.job(id))!.status, LocalJobStatus.paused);
    await runner.resume(id);
    await runner.idle;
    await queue.flush();
    // p0 once, p1 twice (under its temp name), never p0 again.
    expect(s.safFake.calls.where((c) => c.startsWith('importFile')), [
      'importFile ${localJobTempName(id, 0)}',
      'importFile ${localJobTempName(id, 1)}',
      'importFile ${localJobTempName(id, 1)}',
    ]);
    expect(s.safFake.bytesAt('${s.usb}/Photos/p1.jpg'), [1, 1, 1]);
    expect((await dao.job(id))!.status, LocalJobStatus.done);
  });

  test('collision Skip leaves the existing file; Keep both adds (1)', () async {
    s.safFake.addFile('${s.usb}/Photos/p0.jpg', [9]);
    final files = addLocal(1);
    final skipped = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: files,
        targetFolder: '${s.usb}/Photos',
        collision: CollisionPolicy.skip,
      ),
    );
    expect(skipped.files.single.status, LocalFileStatus.skipped);
    expect(s.safFake.bytesAt('${s.usb}/Photos/p0.jpg'), [9]);

    final both = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: files,
        targetFolder: '${s.usb}/Photos',
      ),
    );
    expect(both.files.single.targetName, 'p0 (1).jpg');
  });

  test('collision Replace swaps the file only after verification', () async {
    s.safFake.addFile('${s.usb}/Photos/p0.jpg', [9]);
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: addLocal(1),
        targetFolder: '${s.usb}/Photos',
        collision: CollisionPolicy.replace,
      ),
    );
    expect(view.files.single.targetName, 'p0.jpg');
    expect(s.safFake.bytesAt('${s.usb}/Photos/p0.jpg'), [0, 0, 0]);
    expect(s.safFake.existsPath('${s.usb}/Photos/p0 (1).jpg'), isFalse);
  });

  test('FAT names: invalid characters become _ on removable targets', () async {
    final f = s.android.addFile('${Setup.internal}/Pictures/a:b.jpg');
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: [f],
        targetFolder: '${s.usb}/Photos',
      ),
    );
    expect(view.files.single.targetName, 'a_b.jpg');
    expect(view.renamed, hasLength(1));
    expect(s.safFake.existsPath('${s.usb}/Photos/a_b.jpg'), isTrue);
  });

  test('FAT32: a too-large file fails early, nothing written', () async {
    runner = build(fat32: true, fatMax: 3);
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.copy,
        files: addLocal(1),
        targetFolder: '${s.usb}/Photos',
      ),
    );
    expect(view.files.single.status, LocalFileStatus.failed);
    expect(view.files.single.failureReason, LocalJobErrors.fat32TooLarge);
    expect(s.safFake.calls.where((c) => c.startsWith('importFile')), isEmpty);
  });

  test('declined delete keeps originals; Delete originals retries', () async {
    moves.answer = SourceOutcome.keptDeclined;
    final files = addLocal(2);
    final view = await run(
      LocalJobRequest(
        mode: LocalJobMode.move,
        files: files,
        targetFolder: '${s.usb}/Photos',
        deleteMode: DeleteMode.permanent,
      ),
    );
    expect(view.originalsLeft, hasLength(2));
    expect(moves.modes.single, DeleteMode.permanent);
    moves.answer = SourceOutcome.deletedPermanently;
    await runner.deleteOriginals(view.job.id);
    await queue.flush();
    final again = LocalJobView(view.job, await dao.files(view.job.id));
    expect(again.originalsLeft, isEmpty);
    expect(moves.calls, hasLength(2));
  });

  test('fatSafeName', () {
    expect(fatSafeName('a:b*c?.jpg'), 'a_b_c_.jpg');
    expect(fatSafeName('name. '), 'name__');
    expect(fatSafeName('ok.jpg'), 'ok.jpg');
  });

  test('isFat32Volume reads the backing mount', () async {
    Future<String> mounts() async =>
        '/dev/block/vold/public:179,1 /mnt/media_rw/1234-ABCD vfat rw 0 0\n'
        '/dev/fuse /storage/1234-ABCD fuse rw 0 0\n'
        '/dev/block/vold/public:8,1 /mnt/media_rw/9999-0000 exfat rw 0 0\n';
    expect(
      await isFat32Volume('/storage/1234-ABCD/DCIM', mounts: mounts),
      isTrue,
    );
    expect(await isFat32Volume('/storage/9999-0000', mounts: mounts), isFalse);
    expect(
      await isFat32Volume('/storage/emulated/0/DCIM', mounts: mounts),
      isFalse,
    );
  });

  group('U2 review fixes', () {
    test('#1 files with one target name all survive Replace', () async {
      s.safFake.addFile('${s.usb}/Photos/p.jpg', [9]);
      s.android.addFolder('${Setup.internal}/A');
      final a = s.android.addFile('${Setup.internal}/A/p.jpg', bytes: [1]);
      final b = s.android.addFile(
        '${Setup.internal}/Pictures/P.jpg',
        bytes: [2],
      );
      final c = s.android.addFile(
        '${Setup.internal}/Pictures/p:.jpg',
        bytes: [3],
      );
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: [a, b, c],
          targetFolder: '${s.usb}/Photos',
          collision: CollisionPolicy.replace,
        ),
      );
      expect(view.job.status, LocalJobStatus.done);
      expect(s.safFake.bytesAt('${s.usb}/Photos/p.jpg'), [1]);
      final names = view.files.map((f) => f.targetName).toList();
      expect(names.map((n) => n.toLowerCase()).toSet(), hasLength(3));
      for (final (i, n) in names.indexed) {
        expect(s.safFake.bytesAt('${s.usb}/Photos/$n'), [i + 1]);
      }
      expect(moves.calls.single, hasLength(3));
    });

    test('#1 Skip never skips a name this job wrote', () async {
      s.android.addFolder('${Setup.internal}/A');
      final a = s.android.addFile('${Setup.internal}/A/p.jpg', bytes: [1]);
      final b = s.android.addFile(
        '${Setup.internal}/Pictures/p.jpg',
        bytes: [2],
      );
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: [a, b],
          targetFolder: '${s.usb}/Photos',
          collision: CollisionPolicy.skip,
        ),
      );
      expect(
        view.files.map((f) => f.status),
        everyElement(LocalFileStatus.done),
      );
      expect(moves.calls.single, hasLength(2));
    });

    test('#2 an original is kept when its copy is gone', () async {
      moves.answer = SourceOutcome.keptDeclined;
      final files = addLocal(2);
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: files,
          targetFolder: '${s.usb}/Photos',
        ),
      );
      s.safFake.removeDoc('${s.safFake.uuid}:Photos/p0.jpg');
      moves.answer = SourceOutcome.trashed;
      await runner.deleteOriginals(view.job.id);
      await queue.flush();
      expect(moves.calls.last.map((o) => o.original.id), [files[1].id]);
      final rows = await dao.files(view.job.id);
      expect(rows[0].sourceOutcome, SourceOutcome.keptFailed);
      expect(rows[0].failureReason, LocalJobErrors.copyMissing);
    });

    test('#2 an unmounted target keeps every original', () async {
      moves.answer = SourceOutcome.keptDeclined;
      final view = await run(
        LocalJobRequest(
          mode: LocalJobMode.move,
          files: addLocal(1),
          targetFolder: '${s.usb}/Photos',
        ),
      );
      unmounted.add('ABCD-1234');
      await runner.deleteOriginals(view.job.id);
      await queue.flush();
      expect(moves.calls, hasLength(1));
    });

    test('#4 copies go under a temp name; a stale temp is swept', () async {
      unmounted.add('ABCD-1234');
      final paused = await run(
        LocalJobRequest(
          mode: LocalJobMode.copy,
          files: addLocal(1),
          targetFolder: '${s.usb}/Photos',
        ),
      );
      final tempName = localJobTempName(paused.job.id, 0);
      final temp = '${s.usb}/Photos/$tempName';
      s.safFake.addFile(temp, [0]); // a crash mid-import
      unmounted.clear();
      await runner.onPlacesChanged();
      await runner.idle;
      await queue.flush();
      expect(s.safFake.existsPath(temp), isFalse);
      expect(s.safFake.bytesAt('${s.usb}/Photos/p0.jpg'), [0, 0, 0]);
      expect(s.safFake.calls.where((c) => c.startsWith('importFile')), [
        'importFile $tempName',
      ]);
    });

    test(
      '#8 a SAF source without its grant fails, never "already moved"',
      () async {
        final usb = await s.safFile('DCIM/a.jpg', [1]);
        s.granted = false;
        final view = await run(
          LocalJobRequest(
            mode: LocalJobMode.move,
            files: [usb],
            targetFolder: '${Setup.internal}/Pictures',
          ),
        );
        expect(view.files.single.status, LocalFileStatus.failed);
        expect(view.files.single.failureReason, 'unavailable');
        expect(moves.calls, isEmpty);
      },
    );
  });

  group('U3 safe eject', () {
    late ProviderContainer container;
    late VolumeActivityTracker tracker;
    setUp(() {
      container = ProviderContainer();
      tracker = container.read(volumeActivityTrackerProvider.notifier);
      runner = build(tracker: tracker);
    });
    tearDown(() => container.dispose());

    test('a job reaching an ejecting place pauses, resumable', () async {
      final target = '${s.usb}/Photos';
      final place = s.router.placeOfFolder(target);
      tracker.beginEject(place);
      final files = addLocal(2);
      var view = await run(
        LocalJobRequest(
          mode: LocalJobMode.copy,
          files: files,
          targetFolder: target,
        ),
      );
      expect(view.job.status, LocalJobStatus.paused);
      expect(
        view.files.map((f) => f.status),
        everyElement(LocalFileStatus.queued),
      );
      expect(container.read(volumeActivityTrackerProvider).open, isEmpty);
      tracker.cancelEject(place);
      await runner.resume(view.job.id);
      await runner.idle;
      await queue.flush();
      view = LocalJobView(
        (await dao.job(view.job.id))!,
        await dao.files(view.job.id),
      );
      expect(view.job.status, LocalJobStatus.done);
    });

    test('pauseWhere pauses the jobs on a place', () async {
      final target = '${s.usb}/Photos';
      final place = s.router.placeOfFolder(target);
      final id = await runner.start(
        LocalJobRequest(
          mode: LocalJobMode.copy,
          files: addLocal(3),
          targetFolder: target,
        ),
      );
      expect(await runner.activeJobsOn(place), [id]);
      expect(await runner.activeJobsOn('other'), isEmpty);
      expect(await runner.pauseWhere(place), 1);
      await runner.idle;
      await queue.flush();
      final job = (await dao.job(id))!;
      expect(job.status, LocalJobStatus.paused);
      // Whatever finished is complete (verified); the rest stays queued.
      for (final f in await dao.files(id)) {
        expect(f.status, anyOf(LocalFileStatus.done, LocalFileStatus.queued));
      }
    });
  });
}
