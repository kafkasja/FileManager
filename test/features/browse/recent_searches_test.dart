import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';

/// Reads fail while [failReads] is set.
class _FlakySettings extends SettingsRepository {
  new(super._db, super._queue);

  bool failReads = false;

  @override
  Future<T> read<T extends Object>(SettingKey<T> key) {
    if (failReads) return Future.error(StateError('disk gone'));
    return super.read(key);
  }
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late _FlakySettings settings;
  late List<Object> errors;
  late RecentSearchesRepository repo;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    settings = _FlakySettings(db, queue);
    errors = [];
    queue.errors.listen((e) => errors.add(e.error));
    repo = RecentSearchesRepository(
      settings,
      onError: (e, st) => queue.report('recentSearches', e, st),
    );
  });

  tearDown(() async {
    await queue.close();
    await db.close();
  });

  Future<List<String>> titles() async => [
    for (final r in await repo.watch().first) r.title,
  ];

  test('adds called together all land (no lost read-modify-write)', () async {
    await Future.wait([
      for (var i = 0; i < 4; i++)
        repo.add('s$i', IndexQuery(nameContains: 's$i')),
    ]);
    expect(await titles(), ['s3', 's2', 's1', 's0']);
  });

  test('a failed read is published and later calls still run', () async {
    settings.failReads = true;
    final failed = repo.add('lost', const IndexQuery(nameContains: 'lost'));
    await expectLater(failed, throwsStateError);
    await pumpEventQueue();
    expect(errors.single, isA<StateError>());

    settings.failReads = false;
    await repo.add('kept', const IndexQuery(nameContains: 'kept'));
    expect(await titles(), ['kept']);
  });

  test('text and demoted words survive the JSON round trip', () async {
    await repo.add(
      'video beach',
      const IndexQuery(nameContains: 'video beach'),
      text: 'video beach',
      demoted: const {'video'},
    );
    final r = (await repo.watch().first).single;
    expect(r.text, 'video beach');
    expect(r.demoted, {'video'});
    // Older entries have neither.
    final old = RecentSearch.fromJson(
      RecentSearch(
        title: 'x',
        query: IndexQuery.all,
        at: DateTime.utc(2026),
      ).toJson(),
    );
    expect(old.text, isNull);
    expect(old.demoted, isEmpty);
  });
}
