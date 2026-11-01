import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/blur_rule.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/similar/domain/signals.dart';

import 'similar_test_utils.dart';

void main() {
  late AppDatabase db;
  late SimilarRepository repo;
  late int sessionId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    repo = SimilarRepository(db, DbWriteQueue());
    sessionId = await session(db);
  });
  tearDown(() => db.close());

  SignalWrite ok(String id, {double blur = 200, int hash = 0, int mod = 0}) =>
      SignalWrite(
        fileId: id,
        status: SignalStatus.ok,
        dHash: hash,
        blurScore: blur,
        fileModifiedAtMs: mod,
      );

  Future<List<List<String>>> shownGroups() async => [
    for (final g in await repo.watchGroups().first)
      [for (final m in g.members) m.id],
  ];

  group('watchGroups', () {
    setUp(() async {
      await index(db, [
        for (final id in ['a1', 'a2', 'a3', 'b1', 'b2']) photo(id, minute: 1),
        photo('h', hidden: true),
      ]);
      await repo.replaceGroups([
        (members: ['b2', 'b1'], sortDateMs: 10),
        (members: ['a1', 'a2', 'a3'], sortDateMs: 20),
      ]);
    });

    test('newest first, members best first, suggested = first', () async {
      final groups = await repo.watchGroups().first;
      expect(groups.map((g) => g.members.map((m) => m.id).toList()), [
        ['a1', 'a2', 'a3'],
        ['b2', 'b1'],
      ]);
      expect(groups.first.suggestedFileId, 'a1');
    });

    test('queued/committing deletes hide members; <2 shown hides the '
        'group', () async {
      await pendingDelete(db, sessionId, 'a1');
      await pendingDelete(
        db,
        sessionId,
        'b1',
        status: PendingDeleteStatus.committing,
      );
      // Failed / committed rows don't hide (committed files leave the index).
      await pendingDelete(
        db,
        sessionId,
        'a2',
        status: PendingDeleteStatus.failed,
      );
      expect(await shownGroups(), [
        ['a2', 'a3'],
      ]);
    });

    test('members missing from the index or hidden are not shown', () async {
      await repo.replaceGroups([
        (members: ['b1', 'gone'], sortDateMs: 1),
        (members: ['b2', 'h'], sortDateMs: 2),
      ]);
      expect(await shownGroups(), isEmpty);
    });

    test(
      'all shown members dismissed hides; a new member shows it again',
      () async {
        await repo.dismiss(['a1', 'a2', 'a3', 'b1']);
        expect(await shownGroups(), [
          ['b2', 'b1'],
        ]);
        await index(db, [photo('a4', minute: 2)]);
        await repo.replaceGroups([
          (members: ['a4', 'a1', 'a2', 'a3'], sortDateMs: 20),
        ]);
        expect(await shownGroups(), [
          ['a4', 'a1', 'a2', 'a3'],
        ]);
        await repo.undismiss(['a1']);
        expect(await db.select(db.similarDismissed).get(), hasLength(3));
      },
    );

    test('a dismissed member hidden by a delete still leaves the rest '
        'deciding', () async {
      await repo.dismiss(['b2']);
      await pendingDelete(db, sessionId, 'b1');
      // b's only shown member left → <2 → hidden either way.
      expect(await shownGroups(), [
        ['a1', 'a2', 'a3'],
      ]);
    });

    test('is live: a queued delete updates the stream', () async {
      final stream = repo.watchGroups().map(
        (gs) => gs.map((g) => g.members.length).toList(),
      );
      final expectation = expectLater(
        stream,
        emitsInOrder([
          [3, 2],
          [3],
        ]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await pendingDelete(db, sessionId, 'b1');
      await expectation;
    });

    test('dismissFullySwiped dismisses only fully acted groups', () async {
      await repo.dismissFullySwiped({'a1', 'a2', 'b1'});
      expect(await shownGroups(), hasLength(2));
      // b2 trashed (pending) + b1 kept → every shown member acted.
      await pendingDelete(db, sessionId, 'b2');
      await pendingDelete(db, sessionId, 'a3');
      await repo.dismissFullySwiped({'a1', 'a2', 'a3', 'b1', 'b2'});
      final dismissed = await db.select(db.similarDismissed).get();
      expect(dismissed.map((d) => d.fileId).toSet(), {'a1', 'a2', 'a3'});
    });
  });

  group('watchBlurry', () {
    test(
      'agrees with isBlurry; only ok, visible, not deleted; newest first',
      () async {
        final rows = computeSignals([
          ('sharp', fixture('base')),
          ('blurred', fixture('blurred')),
        ]);
        await index(db, [
          photo('sharp'),
          photo('blurred', minute: 1),
          photo('blurred2', minute: 5),
          photo('hiddenBlur', hidden: true),
          photo('deleted'),
          photo('failed'),
        ]);
        await repo.writeSignals([
          for (final r in rows)
            SignalWrite(
              fileId: r.fileId,
              status: SignalStatus.ok,
              dHash: r.dHash,
              blurScore: r.blurScore,
              fileModifiedAtMs: 0,
            ),
          ok('blurred2', blur: 1),
          ok('hiddenBlur', blur: 1),
          ok('deleted', blur: 1),
          const SignalWrite(
            fileId: 'failed',
            status: SignalStatus.failed,
            fileModifiedAtMs: 0,
          ),
        ]);
        await pendingDelete(db, sessionId, 'deleted');

        final blurry = await repo.watchBlurry(threshold: 100).first;
        expect(blurry.map((f) => f.id), ['blurred2', 'blurred']);
        for (final r in rows) {
          expect(
            isBlurry(r.blurScore!, 100),
            blurry.any((f) => f.id == r.fileId),
            reason: r.fileId,
          );
        }
        expect(
          await repo.watchBlurry(threshold: 100, limit: 1).first,
          hasLength(1),
        );
      },
    );
  });

  group('job queries', () {
    test('nextBatch: visible images without a current signal, newest '
        'first, keyset', () async {
      await index(db, [
        photo('new1', minute: 1),
        photo('new2', minute: 2),
        photo('video', kind: FileKind.video),
        photo('shot', screenshot: true),
        photo('hid', hidden: true),
        photo('done', modifiedMs: 5),
        photo('changed', modifiedMs: 7),
        photo('old-algo'),
        photo('failed'),
      ]);
      await repo.writeSignals([
        ok('done', mod: 5),
        ok('changed', mod: 6),
        const SignalWrite(
          fileId: 'failed',
          status: SignalStatus.failed,
          fileModifiedAtMs: 0,
        ),
      ]);
      await db.customStatement(
        'INSERT INTO image_signals (file_id, status, file_modified_at_ms, '
        "algo_version) VALUES ('old-algo', 'unsupported', 0, ?)",
        [kSignalsAlgoVersion - 1],
      );

      final all = await repo.nextBatch(includeScreenshots: false);
      expect(all.map((f) => f.id), ['new2', 'new1', 'old-algo', 'changed']);
      expect(await repo.countPending(includeScreenshots: false), 4);
      expect(
        (await repo.nextBatch(includeScreenshots: true)).map((f) => f.id),
        contains('shot'),
      );

      final first = await repo.nextBatch(includeScreenshots: false, limit: 1);
      final after = (
        sortDateMs: first.single.sortDate.millisecondsSinceEpoch,
        id: first.single.id,
      );
      final rest = await repo.nextBatch(
        includeScreenshots: false,
        after: after,
      );
      expect(rest.map((f) => f.id), ['new1', 'old-algo', 'changed']);
    });

    test('deleteOrphans drops rows of files no longer indexed', () async {
      await index(db, [photo('kept1'), photo('kept2')]);
      await repo.writeSignals([ok('kept1'), ok('gone')]);
      await repo.replaceGroups([
        (members: ['kept1', 'kept2', 'gone'], sortDateMs: 1),
      ]);
      await repo.dismiss(['gone', 'kept2']);

      await repo.deleteOrphans();

      expect((await db.select(db.imageSignals).get()).map((r) => r.fileId), [
        'kept1',
      ]);
      expect(
        (await db.select(db.similarGroupItems).get()).map((r) => r.fileId),
        unorderedEquals(['kept1', 'kept2']),
      );
      expect(
        (await db.select(db.similarDismissed).get()).map((r) => r.fileId),
        ['kept2'],
      );
    });

    test('groupingInput: ok rows of visible images, oldest first', () async {
      await index(db, [
        photo('b', minute: 2, width: 4, height: 3, size: 9),
        photo('a', minute: 1),
        photo('shot', screenshot: true),
        photo('f'),
      ]);
      await repo.writeSignals([
        ok('a', hash: -3),
        ok('b', blur: 50),
        ok('shot'),
        const SignalWrite(
          fileId: 'f',
          status: SignalStatus.failed,
          fileModifiedAtMs: 0,
        ),
      ]);
      final points = await repo.groupingInput(includeScreenshots: false);
      expect(points.map((p) => p.fileId), ['a', 'b']);
      expect(points.first.dHash, -3);
      expect(points.last.width, 4);
      expect(points.last.sizeBytes, 9);
      expect(points.last.blurScore, 50);
    });

    test('replaceGroups replaces every group and its items', () async {
      await repo.replaceGroups([
        (members: ['x', 'y'], sortDateMs: 1),
      ]);
      await repo.replaceGroups([
        (members: ['p', 'q', 'r'], sortDateMs: 2),
        (members: ['single'], sortDateMs: 3),
      ]);
      final groups = await db.select(db.similarGroups).get();
      expect(groups.single.suggestedFileId, 'p');
      expect(groups.single.memberCount, 3);
      final items = await (db.select(
        db.similarGroupItems,
      )..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
      expect(items.map((i) => i.fileId), ['p', 'q', 'r']);
    });
  });
}
