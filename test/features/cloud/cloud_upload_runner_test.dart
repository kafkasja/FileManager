import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/data/cloud_upload_runner.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';
import 'package:kfm/features/transfers/data/verified_move_impl.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';
import 'fake_cloud.dart';

/// N11's real implementation, recording its calls.
class _CountingMove implements VerifiedMove {
  new(this._inner);

  final VerifiedMove _inner;
  final List<List<VerifiedOriginal>> calls = [];
  final List<DeleteMode> modes = [];

  /// Runs before N11 re-checks the originals.
  void Function()? before;

  @override
  Future<FinalizeResult> deleteOriginals(
    List<VerifiedOriginal> originals, {
    required DeleteMode mode,
  }) {
    before?.call();
    calls.add(originals);
    modes.add(mode);
    return _inner.deleteOriginals(originals, mode: mode);
  }
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late FakeFileSource fs;
  late FakeCloudWriter writer;
  late FakeCloudTrees trees;
  late CloudDestinationsRepository dests;
  late CloudItemsRepository items;
  late _CountingMove moves;
  late CloudUploadRunner runner;
  late int dest;

  CloudUploadRunner build({CloudSourcePreparer? prepare}) => CloudUploadRunner(
    items: items,
    destinations: dests,
    writer: writer,
    files: fs,
    verifiedMove: moves,
    prepare: prepare,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    fs = FakeFileSource();
    writer = FakeCloudWriter((source) => fs.bytesOf('path:$source'));
    trees = FakeCloudTrees()..persisted.add('content://drive/tree/p');
    dests = CloudDestinationsRepository(
      db,
      queue,
      platform: trees,
      protectedTrees: () async => const {},
    );
    items = CloudItemsRepository(db, queue);
    moves = _CountingMove(
      LocalVerifiedMove(
        source: fs,
        lock: SerialLock(),
        removeFromIndex: (_) async {},
      ),
    );
    runner = build();
    dest = await dests.add(
      location: 'content://drive/tree/p',
      label: 'Drive › Photos',
      provider: CloudProviderGuess.googleDrive,
    );
  });
  tearDown(() async {
    await runner.dispose();
    await queue.flush();
    await db.close();
  });

  List<FileRef> photos(int n) => [
    for (var i = 0; i < n; i++)
      fs.addFile(
        '/storage/emulated/0/DCIM/p$i.jpg',
        bytes: [i, i + 1, i + 2, 9],
        mimeType: 'image/jpeg',
      ),
  ];

  Future<List<CloudItemRow>> rows() => db.select(db.cloudItems).get();

  test('copy: every file handed to the provider, originals kept', () async {
    final files = photos(3);
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.copy,
      ),
    );
    await runner.idle();
    expect(await h.done, isNull);
    final all = await rows();
    expect(
      all.map((r) => r.status),
      everyElement(CloudItemStatus.handedToProvider),
    );
    expect(all.map((r) => r.sizeBytes), everyElement(4));
    expect(
      all.map((r) => r.sourceModifiedAtMs),
      files.map((f) => f.modifiedAt.millisecondsSinceEpoch),
    );
    expect(writer.docs, hasLength(3));
    expect(fs.files, hasLength(3));
    expect(moves.calls, isEmpty);
  });

  test('move: verified, then ONE deleteOriginals for the job', () async {
    final files = photos(5);
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    final summary = await h.done;
    expect(summary!.deleted, 5);
    expect(moves.calls, hasLength(1));
    expect(moves.calls.single, hasLength(5));
    expect(moves.modes.single, DeleteMode.trash);
    expect(fs.files, isEmpty, reason: 'originals in the trash');
    expect(fs.trash, hasLength(5));
    final all = await rows();
    expect(all.map((r) => r.status), everyElement(CloudItemStatus.verified));
    expect(
      all.map((r) => r.sourceOutcome),
      everyElement(SourceOutcome.trashed),
    );
    expect(writer.docs, hasLength(5));
  });

  test('verify mismatch: copy deleted, original kept, row failed', () async {
    final files = photos(1);
    writer.corruptReadBack = true;
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    expect(await h.done, isNull);
    final row = (await rows()).single;
    expect(row.status, CloudItemStatus.failed);
    expect(row.error, CloudItemErrors.verify);
    expect(writer.docs, isEmpty);
    expect(fs.files, hasLength(1));
    expect(moves.calls, isEmpty);
  });

  test('read-back unavailable: copy and original both kept', () async {
    final files = photos(1);
    writer.readBackFails = true;
    await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    final row = (await rows()).single;
    expect(row.status, CloudItemStatus.failed);
    expect(row.error, CloudItemErrors.verifyUnavailable);
    expect(writer.docs, hasLength(1));
    expect(fs.files, hasLength(1));
    expect(moves.calls, isEmpty);
  });

  test('an original edited before the job end is kept (keptChanged)', () async {
    final files = photos(2);
    moves.before = () => fs.putRef(
      files[1].copyWith(
        modifiedAt: files[1].modifiedAt.add(const Duration(minutes: 5)),
      ),
      bytes: const [1, 2, 3, 9],
    );
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    final s = (await h.done)!;
    expect(s.deleted, 1);
    expect(s.kept, 1);
    final all = await rows();
    expect(
      all.firstWhere((r) => r.fileId == files[1].id).sourceOutcome,
      SourceOutcome.keptChanged,
    );
    expect(fs.files.map((f) => f.id), [files[1].id]);
  });

  test(
    'declined dialog: rows stay verified; Delete originals retries',
    () async {
      final files = photos(3);
      fs.declineDeletes = true;
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      expect((await h.done)!.kept, 3);
      var all = await rows();
      expect(all.map((r) => r.status), everyElement(CloudItemStatus.verified));
      expect(
        all.map((r) => r.sourceOutcome),
        everyElement(SourceOutcome.keptDeclined),
      );
      expect(fs.files, hasLength(3));

      fs.declineDeletes = false;
      final s = await runner.deleteOriginals([for (final r in all) r.id]);
      expect(s.deleted, 3);
      expect(moves.calls, hasLength(2));
      expect(moves.calls.last, hasLength(3));
      expect(fs.files, isEmpty);
      all = await rows();
      expect(
        all.map((r) => r.sourceOutcome),
        everyElement(SourceOutcome.trashed),
      );
    },
  );

  test('cloud copy gone before the job end: original kept', () async {
    final files = photos(1);
    writer.reportGone = true;
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    expect((await h.done)!.kept, 1);
    final row = (await rows()).single;
    expect(row.sourceOutcome, SourceOutcome.keptFailed);
    expect(row.error, CloudItemErrors.copyMissing);
    expect(moves.calls, isEmpty);
    expect(fs.files, hasLength(1));
  });

  test('cancel mid-write: partial deleted, original untouched', () async {
    final files = photos(1);
    final gate = Completer<void>();
    writer.gate = gate;
    await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await pumpUntil(() async => writer.calls.any((c) => c.startsWith('write')));
    final id = (await rows()).single.id;
    await runner.cancel(id);
    gate.complete();
    await runner.idle();
    final row = (await rows()).single;
    expect(row.status, CloudItemStatus.failed);
    expect(row.error, CloudItemErrors.cancelled);
    expect(writer.docs, isEmpty);
    expect(fs.files, hasLength(1));
    expect(moves.calls, isEmpty);
  });

  test('cancel while waiting fails the row at once', () async {
    final files = photos(2);
    final gate = Completer<void>();
    writer.gate = gate;
    await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.copy,
      ),
    );
    await pumpUntil(() async => writer.calls.any((c) => c.startsWith('write')));
    final second = (await rows()).firstWhere((r) => r.fileId == files[1].id);
    await runner.cancel(second.id);
    gate.complete();
    await runner.idle();
    final after = (await items.byId(second.id))!;
    expect(after.status, CloudItemStatus.failed);
    expect(after.error, CloudItemErrors.cancelled);
    expect(writer.docs, hasLength(1));
  });

  test('restart: uploading rows restart, partials are deleted', () async {
    final files = photos(1);
    final ids = (await items.enqueue(files, dest, CloudItemMode.copy)).ids;
    await items.startUploading(ids.single, sizeBytes: 4, sourceModifiedAtMs: 1);
    writer.docs['content://drive/tree/p/doc/old'] = const [1];
    await items.markUploading(ids.single, 'content://drive/tree/p/doc/old');

    final fresh = build();
    addTearDown(fresh.dispose);
    await fresh.resume();
    await fresh.idle();
    expect(writer.calls, contains('delete content://drive/tree/p/doc/old'));
    expect(writer.docs.keys, isNot(contains('content://drive/tree/p/doc/old')));
    expect(writer.docs, hasLength(1));
    expect(
      (await items.byId(ids.single))!.status,
      CloudItemStatus.handedToProvider,
    );
  });

  test(
    'restart with a verified move row: original waits for the user',
    () async {
      final files = photos(1);
      final ids = (await items.enqueue(files, dest, CloudItemMode.move)).ids;
      final fresh = build();
      addTearDown(fresh.dispose);
      await fresh.resume();
      await fresh.idle();
      expect((await items.byId(ids.single))!.status, CloudItemStatus.verified);
      expect(moves.calls, isEmpty, reason: 'no system dialog after a restart');
      expect(fs.files, hasLength(1));
    },
  );

  test('lost grant: fails as needs reconnecting, nothing written', () async {
    trees.persisted.clear();
    final files = photos(1);
    await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    final row = (await rows()).single;
    expect(row.error, CloudItemErrors.needsReconnecting);
    expect(writer.docs, isEmpty);
    expect(fs.files, hasLength(1));
  });

  test('provider error: row failed, original untouched', () async {
    writer.failWrite = CloudWriteFailure.noSpace;
    final files = photos(1);
    await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    final row = (await rows()).single;
    expect(row.status, CloudItemStatus.failed);
    expect(row.error, CloudWriteFailure.noSpace.name);
    expect(fs.files, hasLength(1));
  });

  test('a stripped copy is uploaded and verified; the original goes', () async {
    final files = photos(1);
    var released = false;
    await runner.dispose();
    writer = FakeCloudWriter(
      (source) => source == '/cache/privacy/stripped.jpg'
          ? const [7, 7]
          : fs.bytesOf('path:$source'),
    );
    runner = CloudUploadRunner(
      items: items,
      destinations: dests,
      writer: writer,
      files: fs,
      verifiedMove: moves,
      prepare: (f, id, {stripLocation}) async => CloudSource(
        source: '/cache/privacy/stripped.jpg',
        sizeBytes: 2,
        cleanup: () async => released = true,
      ),
    );
    final h = await runner.start(
      CloudJobRequest(
        files: files,
        destinationId: dest,
        mode: CloudItemMode.move,
      ),
    );
    await runner.idle();
    expect((await h.done)!.deleted, 1);
    expect(writer.docs.values.single, [7, 7]);
    expect(released, isTrue);
  });

  test('location not removable: never uploaded', () async {
    await runner.dispose();
    runner = build(
      prepare: (f, id, {stripLocation}) async =>
          throw const CloudLocationNotRemoved(),
    );
    await runner.start(
      CloudJobRequest(
        files: photos(1),
        destinationId: dest,
        mode: CloudItemMode.copy,
      ),
    );
    await runner.idle();
    expect((await rows()).single.error, CloudItemErrors.locationNotRemoved);
    expect(writer.calls, isEmpty);
  });

  test('camera and remote files are not offered', () async {
    final cam = FileRef(
      id: 'mtp:/dev/bus|1|2',
      uri: 'mtp',
      name: 'a.jpg',
      kind: FileKind.image,
      sizeBytes: 1,
      modifiedAt: DateTime.utc(2026),
      folderPath: '/mtp/1',
      origin: FileOrigin.external,
    );
    final h = await runner.start(
      CloudJobRequest(
        files: [cam],
        destinationId: dest,
        mode: CloudItemMode.copy,
      ),
    );
    expect(h.ids, isEmpty);
    expect(await rows(), isEmpty);
  });

  group('review fixes', () {
    const loc = 'content://drive/tree/p';

    test('1+3: removing the destination mid-job ends the job; the partial is '
        'deleted before the grant goes; a later move is its own job', () async {
      writer
        ..selfCleanup = false
        ..grantHeld = () => trees.persisted.contains(loc);
      final files = photos(2);
      final gate = Completer<void>();
      writer.gate = gate;
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
          deleteMode: DeleteMode.permanent,
        ),
      );
      await pumpUntil(
        () async => writer.calls.any((c) => c.startsWith('write')),
      );
      final removing = runner.removeDestination(dest, forgetUploads: false);
      gate.complete();
      await removing;
      await runner.idle();
      expect(
        await h.done.timeout(const Duration(seconds: 2)),
        isNull,
        reason: 'the job ends (nothing verified)',
      );
      expect(writer.docs, isEmpty, reason: 'partial deleted');
      expect(trees.persisted, isEmpty, reason: 'grant released after');
      final all = await rows();
      expect(all.map((r) => r.status), everyElement(CloudItemStatus.failed));
      expect(all.map((r) => r.remoteUri), everyElement(isNull));
      expect(
        all.map((r) => r.error),
        everyElement(CloudItemErrors.destinationRemoved),
      );
      expect(runner.inRunningJob(all.first.id), isFalse);
      expect(fs.files, hasLength(2));

      // Re-added and moved again: a new job with its own delete mode.
      trees.persisted.add(loc);
      final again = await dests.add(
        location: loc,
        label: 'Drive',
        provider: CloudProviderGuess.googleDrive,
      );
      expect(again, dest);
      final h2 = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      expect((await h2.done)!.deleted, 2);
      expect(moves.modes, [DeleteMode.trash]);
    });

    test('4: a copy that cannot be deleted stays recorded and is retried '
        'at start-up', () async {
      final files = photos(1);
      writer
        ..corruptReadBack = true
        ..failDeletes = true;
      await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      var row = (await rows()).single;
      expect(row.status, CloudItemStatus.failed);
      expect(row.remoteUri, isNotNull);
      expect(CloudItemErrors.hasLeftover(row.error), isTrue);
      expect(CloudItemErrors.reasonOf(row.error), CloudItemErrors.verify);
      expect(writer.docs, hasLength(1));

      writer.failDeletes = false;
      final fresh = build();
      addTearDown(fresh.dispose);
      await fresh.resume();
      await fresh.idle();
      row = (await rows()).single;
      expect(row.remoteUri, isNull);
      expect(row.error, CloudItemErrors.verify);
      expect(writer.docs, isEmpty);
      expect(fs.files, hasLength(1));
    });

    test('4: a failed write whose own cleanup failed is deleted by the '
        'runner', () async {
      writer
        ..selfCleanup = false
        ..failWrite = CloudWriteFailure.noSpace;
      await runner.start(
        CloudJobRequest(
          files: photos(1),
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      await runner.idle();
      final row = (await rows()).single;
      expect(row.error, CloudWriteFailure.noSpace.name);
      expect(row.remoteUri, isNull);
      expect(writer.docs, isEmpty);
    });

    test('5: Retry after cancelling a waiting row runs it', () async {
      final files = photos(2);
      final gate = Completer<void>();
      writer.gate = gate;
      await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      await pumpUntil(
        () async => writer.calls.any((c) => c.startsWith('write')),
      );
      final second = (await rows()).firstWhere((r) => r.fileId == files[1].id);
      await runner.cancel(second.id);
      gate.complete();
      await runner.idle();
      expect((await items.byId(second.id))!.error, CloudItemErrors.cancelled);

      writer.gate = null;
      await runner.start(
        CloudJobRequest(
          files: [files[1]],
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      await runner.idle();
      expect(
        (await items.byId(second.id))!.status,
        CloudItemStatus.handedToProvider,
      );
    });

    test(
      '5: a cancel that came too late never fails the next attempt',
      () async {
        final files = photos(1);
        await runner.start(
          CloudJobRequest(
            files: files,
            destinationId: dest,
            mode: CloudItemMode.copy,
          ),
        );
        await runner.idle();
        final id = (await rows()).single.id;
        await runner.cancel(id); // already finished
        await runner.start(
          CloudJobRequest(
            files: files,
            destinationId: dest,
            mode: CloudItemMode.copy,
          ),
        );
        await runner.idle();
        expect(
          (await items.byId(id))!.status,
          CloudItemStatus.handedToProvider,
        );
      },
    );

    test('6: a verified row waiting for its job end is not reset', () async {
      final files = photos(2);
      // The second file waits until the first is verified.
      final gate = Completer<void>();
      writer
        ..gate = gate
        ..gateOnly = {files[1].uri};
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await pumpUntil(
        () async =>
            (await rows()).any((x) => x.status == CloudItemStatus.verified),
      );
      final first = (await rows()).firstWhere((r) => r.fileId == files[0].id);
      final h2 = await runner.start(
        CloudJobRequest(
          files: [files[0]],
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      expect(h2.ids, [first.id]);
      expect(await h2.done, isNull);
      expect((await items.byId(first.id))!.status, CloudItemStatus.verified);
      gate.complete();
      await runner.idle();
      expect((await h.done)!.deleted, 2);
      expect(moves.calls.single, hasLength(2));
    });

    test('6: a queued row of no running job takes the new request', () async {
      final files = photos(1);
      await items.enqueue(files, dest, CloudItemMode.move);
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      await runner.idle();
      expect(await h.done, isNull);
      final row = (await rows()).single;
      expect(row.mode, CloudItemMode.copy);
      expect(row.status, CloudItemStatus.handedToProvider);
      expect(fs.files, hasLength(1));
    });

    test('7: Retry replaces a kept unverified copy (no orphan)', () async {
      final files = photos(1);
      writer.readBackFails = true;
      await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      final kept = (await rows()).single.remoteUri;
      expect(kept, isNotNull);
      expect(writer.docs.keys, [kept]);

      writer.readBackFails = false;
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      expect((await h.done)!.deleted, 1);
      expect(writer.calls, contains('delete $kept'));
      expect(writer.docs, hasLength(1));
      expect(writer.docs.keys.single, isNot(kept));
    });

    test('8: the job keeps its location decision', () async {
      final seen = <bool?>[];
      await runner.dispose();
      runner = build(
        prepare: (f, id, {stripLocation}) async {
          seen.add(stripLocation);
          return CloudSource(source: f.uri);
        },
      );
      await runner.start(
        CloudJobRequest(
          files: photos(2),
          destinationId: dest,
          mode: CloudItemMode.move,
          stripLocation: false,
        ),
      );
      await runner.idle();
      expect(seen, [false, false]);
    });

    test('9: a file renamed mid-job is followed; its original is deleted '
        'under the new id', () async {
      final files = photos(2);
      final gate = Completer<void>();
      writer
        ..gate = gate
        ..gateOnly = {files[1].uri};
      final h = await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await pumpUntil(
        () async =>
            (await rows()).any((x) => x.status == CloudItemStatus.verified),
      );
      final renamed = await fs.rename(files[0], 'renamed.jpg');
      gate.complete();
      await runner.idle();
      final s = (await h.done)!;
      expect(s.deleted, 2);
      expect(
        moves.calls.single.map((o) => o.original.id),
        contains(renamed.id),
      );
      expect(fs.files, isEmpty);
      expect(fs.trash, hasLength(2));
      await queue.flush();
      expect(
        (await rows()).map((r) => r.fileId),
        containsAll([renamed.id, files[1].id]),
      );
    });

    test(
      '9: Delete originals never counts a missing original as deleted',
      () async {
        final files = photos(1);
        fs.declineDeletes = true;
        await runner.start(
          CloudJobRequest(
            files: files,
            destinationId: dest,
            mode: CloudItemMode.move,
          ),
        );
        await runner.idle();
        fs
          ..declineDeletes = false
          ..removeExternally(files[0].id);
        final id = (await rows()).single.id;
        final s = await runner.deleteOriginals([id]);
        expect(s.deleted, 0);
        expect(s.kept, 1);
        final row = (await items.byId(id))!;
        expect(row.sourceOutcome, SourceOutcome.keptFailed);
        expect(row.error, CloudItemErrors.sourceGone);
        expect(cloudOriginalMayGo(row), isFalse);
      },
    );

    test(
      '10a+10c: one file at two destinations; double tap is serialized',
      () async {
        trees.persisted.add('content://drive/tree/q');
        final dest2 = await dests.add(
          location: 'content://drive/tree/q',
          label: 'Drive › Q',
          provider: CloudProviderGuess.googleDrive,
        );
        final files = photos(1);
        fs.declineDeletes = true;
        for (final d in [dest, dest2]) {
          await runner.start(
            CloudJobRequest(
              files: files,
              destinationId: d,
              mode: CloudItemMode.move,
            ),
          );
          await runner.idle();
        }
        fs.declineDeletes = false;
        final ids = [for (final r in await rows()) r.id];
        expect(ids, hasLength(2));
        final a = runner.deleteOriginals(ids);
        final b = runner.deleteOriginals(ids);
        expect((await a).deleted, 2);
        expect((await b).deleted, 0);
        expect(moves.calls.last, hasLength(1), reason: 'one original once');
        expect(
          (await rows()).map((r) => r.sourceOutcome),
          everyElement(SourceOutcome.trashed),
        );
      },
    );

    test('10b: Delete originals re-checks the copy bytes', () async {
      final files = photos(1);
      fs.declineDeletes = true;
      await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      fs.declineDeletes = false;
      final row = (await rows()).single;
      writer.docs[row.remoteUri!] = const [0, 0, 0, 0]; // same length
      final s = await runner.deleteOriginals([row.id]);
      expect(s.deleted, 0);
      expect((await items.byId(row.id))!.error, CloudItemErrors.copyMissing);
      expect(fs.files, hasLength(1));
    });

    test('10d: old verified moves stay listed for Delete originals', () async {
      final files = photos(1);
      fs.declineDeletes = true;
      await runner.start(
        CloudJobRequest(
          files: files,
          destinationId: dest,
          mode: CloudItemMode.move,
        ),
      );
      await runner.idle();
      final listed = await items
          .watchJobs(since: DateTime.now().add(const Duration(days: 1)))
          .first;
      expect(listed, hasLength(1));
    });

    test('10e: a copy whose source changed size fails', () async {
      await runner.dispose();
      runner = build(
        prepare: (f, id, {stripLocation}) async =>
            CloudSource(source: f.uri, sizeBytes: 99),
      );
      await runner.start(
        CloudJobRequest(
          files: photos(1),
          destinationId: dest,
          mode: CloudItemMode.copy,
        ),
      );
      await runner.idle();
      final row = (await rows()).single;
      expect(row.error, CloudItemErrors.sourceChanged);
      expect(writer.docs, isEmpty);
    });
  });

  test('no destination, no start: the writer is never touched', () async {
    final idle = build();
    addTearDown(idle.dispose);
    expect(writer.calls, isEmpty);
    expect(trees.calls, isEmpty);
  });
}

/// Polls [done] on the event loop (no fake clock here).
Future<void> pumpUntil(Future<bool> Function() done) async {
  for (var i = 0; i < 500; i++) {
    if (await done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  throw StateError('condition not reached');
}
