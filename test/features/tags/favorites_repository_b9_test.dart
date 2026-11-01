import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';

void main() {
  late AppDatabase db;
  late FavoritesRepository repo;
  final ids = [for (var i = 0; i < 1200; i++) 'f:$i'];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FavoritesRepository(db);
  });
  tearDown(() => db.close());

  Future<Set<String>> all() async => {
    for (final r in await db.select(db.favorites).get()) r.fileId,
  };

  test('addFiles across chunks returns only new ids; undo keeps old', () async {
    final pre = ['f:2', 'f:700', 'f:1199'];
    await repo.addFiles(pre);
    final added = await repo.addFiles([...ids, 'f:2']);
    expect(added, hasLength(1197));
    expect(added.toSet().intersection(pre.toSet()), isEmpty);
    expect(await repo.countAmong(ids), 1200);
    await repo.removeIds(added);
    expect(await all(), pre.toSet());
  });

  test('removeFiles returns exact rows; reinsert restores them', () async {
    await repo.addFiles(ids.sublist(100, 900));
    final before = await db.select(db.favorites).get();
    final removed = await repo.removeFiles(ids);
    expect(removed, hasLength(800));
    expect(await all(), isEmpty);
    await repo.reinsert(removed);
    expect((await db.select(db.favorites).get()).toSet(), before.toSet());
  });

  test('countAmong ignores ids outside the list and duplicates', () async {
    await repo.addFiles(['a', 'b', 'c']);
    expect(await repo.countAmong(['a', 'a', 'x']), 1);
    expect(await repo.countAmong(const []), 0);
  });

  test('watchIsFavorite updates live', () async {
    final expectation = expectLater(
      repo.watchIsFavorite('a'),
      emitsInOrder([false, true, false]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addFiles(['a']);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.removeFiles(['a']);
    await expectation;
  });
}
