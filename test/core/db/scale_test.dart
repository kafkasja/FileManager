import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

/// Q6 scale: 100k indexed files (50k in one folder), 10k tags, a 1,000-swipe
/// undo history and a 5,000-file transfer job on a real WAL database file.
/// Bounds are generous (this PC is several times faster than a phone, and
/// other suites may run at once); each value is the best of 3 runs.
const _root = '/storage/emulated/0';
const _camera = '$_root/DCIM/Camera';
const _total = 100000;
const _inCamera = 50000;

Future<Duration> _best(Future<void> Function() body, {int runs = 3}) async {
  var best = const Duration(days: 1);
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    await body();
    if (sw.elapsed < best) best = sw.elapsed;
  }
  return best;
}

final _report = <String>[];

Future<void> _within(
  String what,
  Duration bound,
  Future<void> Function() f,
) async {
  final t = await _best(f);
  _report.add('$what: ${t.inMilliseconds} ms (bound ${bound.inMilliseconds})');
  expect(t, lessThan(bound), reason: what);
}

FileRef _file(int i) {
  final folder = i < _inCamera ? _camera : '$_root/Pictures/album_${i % 500}';
  final name = 'IMG_${i.toString().padLeft(6, '0')}.jpg';
  return FileRef(
    id: 'ms:$i',
    uri: 'content://media/$i',
    name: name,
    kind: i % 10 == 0 ? FileKind.video : FileKind.image,
    sizeBytes: 1000 + i,
    modifiedAt: DateTime.utc(2020).add(Duration(minutes: i)),
    folderPath: folder,
    origin: FileOrigin.local,
    takenAt: DateTime.utc(2020).add(Duration(minutes: i)),
  );
}

void main() {
  late Directory dir;
  late AppDatabase db;
  late DbWriteQueue queue;
  late MediaIndexDao index;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('kfm_scale');
    db = AppDatabase(
      NativeDatabase(
        File('${dir.path}/kfm.sqlite'),
        setup: AppDatabase.setupConnection,
      ),
    );
    queue = DbWriteQueue();
    index = MediaIndexDao(db);
    final sw = Stopwatch()..start();
    for (var start = 0; start < _total; start += 5000) {
      await index.upsertBatch([
        for (var i = start; i < start + 5000; i++) _file(i),
      ], 1);
    }
    _report.add('insert 100k index rows: ${sw.elapsedMilliseconds} ms');
  });

  tearDownAll(() async {
    await queue.close();
    await db.close();
    dir.deleteSync(recursive: true);
    // Kept in the test output for the Q notes.
    stdout.writeln(_report.join('\n'));
  });

  group('100k index rows', () {
    test('first and deep pages (keyset) stay fast', () async {
      const all = IndexQuery(kinds: {FileKind.image, FileKind.video});
      await _within(
        'first page, newest',
        const Duration(milliseconds: 300),
        () async {
          expect((await index.page(all)).items, hasLength(200));
        },
      );
      // A cursor ~60k rows down.
      var page = await index.page(all, limit: 1000);
      for (var i = 0; i < 60; i++) {
        page = await index.page(all, after: page.next, limit: 1000);
      }
      await _within(
        'page 60k rows deep',
        const Duration(milliseconds: 300),
        () async {
          expect(
            (await index.page(all, after: page.next)).items,
            hasLength(200),
          );
        },
      );
      await _within('count all', const Duration(milliseconds: 500), () async {
        expect(await index.count(all), _total);
      });
    });

    test('50k files in one folder: name sort, size sort, count', () async {
      const camera = IndexQuery(
        folderPath: _camera,
        sort: FileSort(FileSortField.name, descending: false),
      );
      await _within(
        'folder by name',
        const Duration(milliseconds: 300),
        () async {
          final p = await index.page(camera);
          expect(p.items.first.name, 'IMG_000000.jpg');
        },
      );
      await _within(
        'folder by size',
        const Duration(milliseconds: 600),
        () async {
          await index.page(
            camera.copyWith(sort: const FileSort(FileSortField.size)),
          );
        },
      );
      await _within(
        'folder count',
        const Duration(milliseconds: 300),
        () async {
          expect(await index.count(camera), _inCamera);
        },
      );
    });

    test('folder tree, search and capture times', () async {
      await _within(
        'folders under Pictures',
        const Duration(seconds: 2),
        () async {
          final f = await index.folders(
            scope: IndexQuery.all,
            parent: '$_root/Pictures',
          );
          expect(f, hasLength(500));
        },
      );
      await _within('name search', const Duration(milliseconds: 800), () async {
        final p = await index.page(const IndexQuery(nameContains: '_004242.'));
        expect(p.items.single.name, 'IMG_004242.jpg');
      });
      await _within(
        'capture times (same-time groups)',
        const Duration(seconds: 3),
        () async {
          final t = await index.captureTimes(
            const IndexQuery(kinds: {FileKind.image}),
          );
          expect(t.length, 90000);
        },
      );
    });
  });

  test('10k tags with 20k tagged files', () async {
    final tags = TagRepository(db);
    final sw = Stopwatch()..start();
    await db.batch((b) {
      b.insertAll(db.tags, [
        for (var i = 0; i < 10000; i++)
          TagsCompanion.insert(
            name: 'tag $i',
            color: 0xff000000 + i,
            createdAt: DateTime.utc(2026),
          ),
      ]);
    });
    final ids = (await db.select(db.tags).get()).map((t) => t.id).toList();
    await db.batch((b) {
      b.insertAll(db.fileTags, [
        for (var i = 0; i < 20000; i++)
          FileTagsCompanion.insert(
            fileId: 'ms:$i',
            tagId: ids[i % ids.length],
            addedAt: DateTime.utc(2026),
          ),
      ]);
    });
    _report.add(
      'insert 10k tags + 20k file tags: ${sw.elapsedMilliseconds} ms',
    );
    await _within(
      'all tags (first emission)',
      const Duration(milliseconds: 800),
      () async {
        expect(await tags.watchAll().first, hasLength(10000));
      },
    );
    await _within(
      'tag counts of 1,000 files',
      const Duration(milliseconds: 500),
      () async {
        await tags.tagCountsAmong([for (var i = 0; i < 1000; i++) 'ms:$i']);
      },
    );
    await _within(
      'tagged-files page',
      const Duration(milliseconds: 800),
      () async {
        final p = await index.page(IndexQuery(anyTagIds: {ids[7]}));
        expect(p.items, hasLength(2));
      },
    );
  });

  test('a 1,000-swipe undo history', () async {
    final sessionId = await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            layout: jsonEncode(SwipeLayout.basic.toJson()),
            startedAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            isActive: true,
          ),
        );
    final undo = UndoRepository(db, queue);
    await undo.prepare(sessionId);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      undo.record(
        sessionId,
        _file(i),
        i.isEven ? SwipeAction.keep : SwipeAction.trash,
        i.isEven
            ? const NoPreviousState()
            : const TrashPreviousState(mode: 'trash'),
      );
    }
    await queue.flush();
    _report.add('record 1,000 swipes: ${sw.elapsedMilliseconds} ms');
    await _within('undo top', const Duration(milliseconds: 100), () async {
      expect(await undo.top(sessionId), isNotNull);
    });
    await _within(
      'undoable count',
      const Duration(milliseconds: 300),
      () async {
        expect(await undo.watchUndoableCount(sessionId).first, 1000);
      },
    );
    // Undo all 1,000, one by one, newest first: order kept, each fast.
    final popped = <int>[];
    final all = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      final top = (await undo.top(sessionId))!;
      popped.add(top.seq);
      await undo.markUndone(top.id);
    }
    _report.add('undo 1,000 one by one: ${all.elapsedMilliseconds} ms');
    expect(all.elapsed, lessThan(const Duration(seconds: 30)));
    expect(popped, [for (var s = 1000; s >= 1; s--) s]);
    expect(await undo.top(sessionId), isNull);
  });

  test('a 5,000-file transfer job', () async {
    final repo = TransfersRepository(TransfersDao(db), queue);
    final fp = 'ef' * 32;
    final device = await KnownDevicesRepository(KnownDevicesDao(db), queue)
        .saveAfterPairing(
          PairedPeer(
            fingerprint: fp,
            peerDeviceId: 'p',
            name: 'Phone',
            platform: 'android',
          ),
          temporary: false,
        );
    late String id;
    await _within('create job', const Duration(seconds: 5), () async {
      id = await repo.createJob(
        deviceId: device.id,
        direction: TransferDirection.download,
        targetPath: '/dl',
        files: [
          for (var i = 0; i < 5000; i++)
            (
              sourceFileId: 'r$i',
              name: 'f$i.jpg',
              sizeBytes: 1 << 20,
              sourceModifiedAtMs: 0,
            ),
        ],
      );
    });
    await _within(
      'load job with 5,000 files',
      const Duration(seconds: 1),
      () async {
        expect((await repo.dao.job(id))!.files, hasLength(5000));
      },
    );
    await _within(
      'next queued files',
      const Duration(milliseconds: 200),
      () async {
        final next = await repo.dao.nextQueued(
          fp,
          limit: 3,
          now: DateTime.now(),
        );
        expect(next, hasLength(3));
      },
    );
  });
}
