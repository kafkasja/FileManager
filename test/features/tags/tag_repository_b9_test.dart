import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/tags/domain/tag.dart';

void main() {
  late AppDatabase db;
  late TagRepository repo;
  late Tag holiday;
  final ids = [for (var i = 0; i < 1200; i++) 'f:$i'];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TagRepository(db);
    holiday = await repo.create('Holiday', kTagColors.first);
  });
  tearDown(() => db.close());

  Future<Set<String>> filesOf(int tagId) async => {
    for (final r in await (db.select(
      db.fileTags,
    )..where((t) => t.tagId.equals(tagId))).get())
      r.fileId,
  };

  group('addToFiles / removeRows', () {
    test('1,200 files across chunks; returns only newly tagged ids', () async {
      // Pre-existing rows spread over all three chunks.
      final pre = ['f:3', 'f:600', 'f:1100'];
      expect(await repo.addToFiles(holiday.id, pre), pre);
      final inserted = await repo.addToFiles(holiday.id, [...ids, 'f:5']);
      expect(inserted, hasLength(1197));
      expect(inserted.toSet().intersection(pre.toSet()), isEmpty);
      expect(await filesOf(holiday.id), hasLength(1200));

      // Undo of add leaves the pre-existing rows.
      await repo.removeRows(holiday.id, inserted);
      expect(await filesOf(holiday.id), pre.toSet());
    });

    test('empty input is a no-op', () async {
      expect(await repo.addToFiles(holiday.id, const []), isEmpty);
      await repo.removeRows(holiday.id, const []);
    });
  });

  group('removeFromFiles / reinsert', () {
    test('returns exact rows with added_at; reinsert restores them', () async {
      await repo.addToFiles(holiday.id, ids.sublist(0, 800));
      final before = await (db.select(
        db.fileTags,
      )..where((t) => t.tagId.equals(holiday.id))).get();
      final removed = await repo.removeFromFiles(holiday.id, ids);
      expect(removed, hasLength(800));
      expect(await filesOf(holiday.id), isEmpty);
      await repo.reinsert(removed);
      final after = await (db.select(
        db.fileTags,
      )..where((t) => t.tagId.equals(holiday.id))).get();
      expect(after.toSet(), before.toSet());
    });

    test('reinsert ignores rows that already exist', () async {
      await repo.addToFiles(holiday.id, ['a', 'b']);
      final removed = await repo.removeFromFiles(holiday.id, ['a', 'b']);
      await repo.addToFiles(holiday.id, ['a']);
      await repo.reinsert(removed);
      expect(await filesOf(holiday.id), {'a', 'b'});
    });
  });

  test('tagCountsAmong counts per tag across chunks', () async {
    final work = await repo.create('Work', kTagColors.last);
    await repo.addToFiles(holiday.id, ids.sublist(0, 700));
    await repo.addToFiles(work.id, ids.sublist(1000));
    await repo.addToFiles(work.id, ['outside']);
    expect(await repo.tagCountsAmong(ids), {holiday.id: 700, work.id: 200});
    expect(await repo.tagCountsAmong(['f:1', 'f:1']), {holiday.id: 1});
    expect(await repo.tagCountsAmong(const []), isEmpty);
  });

  group('rename / recolor', () {
    test('rename to another tag name in any case is rejected', () async {
      final work = await repo.create('Work', kTagColors.first);
      expect(
        () => repo.rename(work.id, 'holiday'),
        throwsA(isA<TagNameTaken>()),
      );
      expect(
        () => repo.rename(work.id, ' HOLIDAY '),
        throwsA(isA<TagNameTaken>()),
      );
    });

    test(
      'rename to its own name in another case is allowed, trimmed',
      () async {
        await repo.rename(holiday.id, '  holiday ');
        final all = await repo.watchAll().first;
        expect(all[holiday.id]!.name, 'holiday');
      },
    );

    test('empty or 41-char names are rejected', () async {
      expect(() => repo.rename(holiday.id, '   '), throwsArgumentError);
      expect(() => repo.rename(holiday.id, 'x' * 41), throwsArgumentError);
      await repo.rename(holiday.id, 'x' * 40);
    });

    test('recolor', () async {
      await repo.recolor(holiday.id, kTagColors.last);
      expect((await repo.watchAll().first)[holiday.id]!.color, kTagColors.last);
    });
  });

  test('deleteWithSnapshot + restoreSnapshot keep id and rows', () async {
    final keep = await repo.create('Keep', kTagColors.first);
    await repo.addToFiles(holiday.id, ids.sublist(0, 600));
    await repo.addToFiles(keep.id, ['f:1']);
    final snap = await repo.deleteWithSnapshot(holiday.id);
    expect(snap.tag.id, holiday.id);
    expect(snap.rows, hasLength(600));
    expect((await repo.watchAll().first).containsKey(holiday.id), isFalse);
    expect(await filesOf(holiday.id), isEmpty); // cascade
    expect(await filesOf(keep.id), {'f:1'});

    await repo.restoreSnapshot(snap);
    final all = await repo.watchAll().first;
    expect(all[holiday.id]!.name, 'Holiday');
    expect(await filesOf(holiday.id), ids.sublist(0, 600).toSet());
  });

  test('restoreSnapshot fails when the name was taken meanwhile', () async {
    final snap = await repo.deleteWithSnapshot(holiday.id);
    await repo.create('HOLIDAY', kTagColors.first);
    expect(() => repo.restoreSnapshot(snap), throwsA(isA<TagNameTaken>()));
  });

  test('watchTagIdsOf updates live', () async {
    final work = await repo.create('Work', kTagColors.first);
    final expectation = expectLater(
      repo.watchTagIdsOf('a'),
      emitsInOrder([
        <int>{},
        {holiday.id},
        {holiday.id, work.id},
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addToFiles(holiday.id, ['a']);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addToFiles(work.id, ['a', 'b']);
    await expectation;
  });
}
