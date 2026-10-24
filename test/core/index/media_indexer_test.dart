import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';

import '../files/fake_file_source.dart';

/// Yields the first page, then fails (permission revoked mid-scan…).
class _FailingSource extends FakeFileSource {
  bool fail = false;

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    if (!fail) {
      yield* super.scan(query: query);
      return;
    }
    yield (await super.scan(query: query).first).take(1).toList();
    throw const FileOpException(FileOpFailure.permissionDenied, 'revoked');
  }
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SettingsRepository settings;
  late MediaIndexDao dao;
  late _FailingSource source;
  late StreamController<MediaChange> changes;
  late DateTime now;
  late bool canSeeAll;
  late MediaIndexer indexer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    dao = MediaIndexDao(db);
    now = DateTime.utc(2026, 10, 23, 12);
    source = _FailingSource();
    changes = StreamController<MediaChange>();
    canSeeAll = true;
    indexer = MediaIndexer(
      dao: dao,
      source: source,
      settings: settings,
      canSeeAllFiles: () => canSeeAll,
      changes: changes.stream,
      clock: () => now,
    );
  });

  tearDown(() async {
    await indexer.dispose();
    await changes.close();
    await queue.close();
    await db.close();
  });

  Future<Set<String>> indexed() async => {
    for (final f in (await dao.page(IndexQuery.all, limit: 1000)).items) f.id,
  };

  void addPhotos(int n, {String folder = '/s/DCIM'}) {
    for (var i = 0; i < n; i++) {
      source.addFile(
        '$folder/p$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
  }

  test('first start runs a full scan and reports progress', () async {
    addPhotos(30);
    source.addFile('/s/Download/a.pdf', modifiedAt: DateTime.utc(2025));
    final statuses = <IndexStatus>[];
    final sub = indexer.status.listen(statuses.add);
    addTearDown(sub.cancel);

    await indexer.start();
    expect(await indexed(), hasLength(31));
    expect(statuses.whereType<IndexScanning>().first.isFirstScan, isTrue);
    expect(statuses.last, isA<IndexIdle>());
    expect(await settings.read(AppSettings.indexLastFullScanAt), isNotEmpty);
  });

  test('a second full scan deletes exactly the vanished files', () async {
    addPhotos(30);
    await indexer.start();
    for (var i = 0; i < 10; i++) {
      source.removeExternally('path:/s/DCIM/p$i.jpg');
    }
    await indexer.fullScan();
    final ids = await indexed();
    expect(ids, hasLength(20));
    expect(ids, isNot(contains('path:/s/DCIM/p0.jpg')));
  });

  test(
    'a scan that fails mid-way deletes nothing and reports failure',
    () async {
      addPhotos(30);
      await indexer.start();
      source
        ..removeExternally('path:/s/DCIM/p0.jpg')
        ..fail = true;
      await indexer.fullScan();
      expect(indexer.current, isA<IndexFailed>());
      expect(await indexed(), hasLength(30));

      // The next complete scan cleans up, including rows the failed one saw.
      source.fail = false;
      await indexer.fullScan();
      expect(await indexed(), hasLength(29));
    },
  );

  test(
    'incremental scan picks up a file modified since the last scan',
    () async {
      addPhotos(5);
      await indexer.start();
      now = now.add(const Duration(hours: 1));
      source.addFile('/s/DCIM/new.jpg', modifiedAt: now);
      await indexer.start(); // not >24 h: incremental only
      expect(await indexed(), contains('path:/s/DCIM/new.jpg'));
    },
  );

  test('start after >24 h also runs a full scan', () async {
    addPhotos(5);
    await indexer.start();
    source.removeExternally('path:/s/DCIM/p1.jpg');
    now = now.add(const Duration(hours: 25));
    await indexer.start();
    expect(await indexed(), hasLength(4));
  });

  test('without All files access, document rows are kept', () async {
    addPhotos(3);
    source.addFile('/s/Download/a.pdf', modifiedAt: DateTime.utc(2025));
    await indexer.start();
    canSeeAll = false;
    await indexer.fullScan();
    expect(await indexed(), contains('path:/s/Download/a.pdf'));
    // …and hidden from views.
    expect(
      const IndexQuery(kinds: {FileKind.document})
          .visible(canSeeAllFiles: false),
      isNull,
    );
  });

  test('FileSource id changes re-key the index', () async {
    addPhotos(2);
    await indexer.start();
    final f = (await dao.byId('path:/s/DCIM/p0.jpg'))!;
    source.addFolder('/s/Pictures');
    await source.move(f, '/s/Pictures');
    await Future<void>.delayed(Duration.zero);
    await indexer.incremental(); // serial: waits for the re-key job
    expect(await dao.byId('path:/s/DCIM/p0.jpg'), isNull);
    expect(await dao.byId('path:/s/Pictures/p0.jpg'), isNotNull);
  });

  test('live changes: delete by id, insert → incremental', () async {
    await dao.upsertBatch([source.addFile('/s/DCIM/x.jpg')], 0);
    await dao.upsertBatch([
      source.addFile('/s/DCIM/y.jpg').copyWith(id: 'ms:42'),
    ], 0);
    await settings.write(
      AppSettings.indexLastFullScanAt,
      now.toIso8601String(),
    );
    changes.add(const MediaChange(type: 'delete', id: 42));
    source.addFile(
      '/s/DCIM/z.jpg',
      modifiedAt: now.add(const Duration(minutes: 5)),
    );
    changes.add(const MediaChange(type: 'insert', id: 43));
    await Future<void>.delayed(
      MediaIndexer.changeDebounce + const Duration(milliseconds: 300),
    );
    await indexer.incremental();
    final ids = await indexed();
    expect(ids, isNot(contains('ms:42')));
    expect(ids, contains('path:/s/DCIM/z.jpg'));
  });
}
