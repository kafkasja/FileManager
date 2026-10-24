import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/trash/data/pending_purge_worker.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String root;
  late AppDatabase db;
  late DbWriteQueue queue;
  late SettingsRepository settings;
  late DateTime now;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_worker');
    root = dir.path.replaceAll(r'\', '/');
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    now = DateTime.utc(2026, 10, 24);
  });

  tearDown(() async {
    await queue.close();
    await db.close();
    await dir.delete(recursive: true);
  });

  PendingFolder folder() => PendingFolder(
    db: db,
    volumeRootOf: (_) => root,
    retentionDays: () async => 1,
    clock: () => now,
  );

  FileRef fileOnDisk(String name) {
    Directory('$root/Download').createSync(recursive: true);
    File('$root/Download/$name').writeAsStringSync('x');
    return FileRef(
      id: 'path:$root/Download/$name',
      uri: 'file://$root/Download/$name',
      name: name,
      kind: FileKind.document,
      sizeBytes: 1,
      modifiedAt: now,
      folderPath: '$root/Download',
      origin: FileOrigin.local,
    );
  }

  test('an expired item is purged and lastPurgeAt is set', () async {
    final f = folder();
    final row = await f.moveIn(fileOnDisk('a.pdf'));
    now = now.add(const Duration(days: 2));
    final ok = await runPendingPurge(
      settings,
      f,
      clock: () => now,
      volumeRoot: root,
    );
    expect(ok, isTrue);
    expect(await f.all(), isEmpty);
    expect(File(row.storedPath).existsSync(), isFalse);
    expect(
      await settings.read(AppSettings.pendingLastPurgeAt),
      now.toIso8601String(),
    );
    expect(await settings.read(AppSettings.pendingLastPurgeError), '');
  });

  test('permissionDenied: error stored, no retry', () async {
    final ok = await runPendingPurge(
      settings,
      _FailingFolder(db, FileOpFailure.permissionDenied),
      volumeRoot: root,
    );
    expect(ok, isTrue);
    expect(
      await settings.read(AppSettings.pendingLastPurgeError),
      'permissionDenied',
    );
  });

  test('another error: stored, WorkManager retries', () async {
    final ok = await runPendingPurge(
      settings,
      _FailingFolder(db, FileOpFailure.ioError),
      volumeRoot: root,
    );
    expect(ok, isFalse);
    expect(await settings.read(AppSettings.pendingLastPurgeError), 'ioError');
  });

  test(
    'two connections to one file write alternately (WAL + busy timeout)',
    () async {
      final file = File('$root/kfm.sqlite');
      final a = AppDatabase(
        NativeDatabase(file, setup: AppDatabase.setupConnection),
      );
      final b = AppDatabase(
        NativeDatabase(file, setup: AppDatabase.setupConnection),
      );
      final qa = DbWriteQueue();
      final qb = DbWriteQueue();
      final sa = SettingsRepository(a, qa);
      final sb = SettingsRepository(b, qb);
      for (var i = 0; i < 10; i++) {
        await sa.write(AppSettings.pendingFolderRetentionDays, i + 1);
        await sb.write(AppSettings.pendingLastPurgeAt, 'run $i');
      }
      expect(await sb.read(AppSettings.pendingFolderRetentionDays), 10);
      expect(await sa.read(AppSettings.pendingLastPurgeAt), 'run 9');
      await qa.close();
      await qb.close();
      await a.close();
      await b.close();
    },
  );

  test('startup registers the daily job once, after the purge', () async {
    final scheduler = _FakeScheduler();
    final files = FakeFileSource();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
        fileSourceProvider.overrideWithValue(files),
        pendingFolderProvider.overrideWithValue(folder()),
        backgroundSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(files.dispose);
    await settings.write(AppSettings.pendingLastPurgeError, 'ioError');
    await container.read(startupMaintenanceProvider.future);
    expect(scheduler.calls, 1);
    expect(
      await container
          .read(settingsRepositoryProvider)
          .read(AppSettings.pendingLastPurgeError),
      '',
      reason: 'a successful startup purge clears the stale error',
    );
  });
}

class _FakeScheduler implements BackgroundScheduler {
  int calls = 0;

  @override
  Future<void> ensureDailyPurge() async => calls++;
}

class _FailingFolder extends PendingFolder {
  new(AppDatabase db, this.failure)
    : super(
        db: db,
        volumeRootOf: (_) => '/nowhere',
        retentionDays: () async => 7,
      );

  final FileOpFailure failure;

  @override
  Future<int> purgeExpired({DateTime? now}) =>
      throw FileOpException(failure, 'test');
}
