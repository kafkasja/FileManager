import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/backup/data/backup_providers.dart';
import 'package:kfm/features/backup/data/backup_service.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/backup_settings_policy.dart';
import 'package:kfm/features/backup/ui/backup_section.dart';
import 'package:kfm/features/backup/ui/backup_setting_labels.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import 'backup_test_utils.dart';

class _FakeDocs implements BackupDocuments {
  new(this.content, {this.bytes, this.honorLimit = true});

  /// What the picked file contains; null = the picker is cancelled.
  final String? content;

  /// Q6: the picked file is this big instead (zeros past the content).
  final int? bytes;

  /// Like the Android channel: stop at `maxBytes` with `TOO_BIG`.
  final bool honorLimit;
  String? written;

  @override
  Future<String?> createDocument(String name, String mime) async =>
      content == null ? null : 'content://doc/$name';

  @override
  Future<String?> openDocument(List<String> mimes) async =>
      content == null ? null : 'content://doc/in';

  @override
  Future<void> readDocument(
    String uri,
    String destPath, {
    int? maxBytes,
  }) async {
    final size = bytes;
    if (size == null) {
      await File(destPath).writeAsString(content!);
      return;
    }
    if (honorLimit && maxBytes != null && size > maxBytes) {
      throw const FilesChannelException('TOO_BIG', 'over the limit');
    }
    final raf = await File(destPath).open(mode: FileMode.write);
    await raf.writeString(content!);
    await raf.setPosition(size - 1);
    await raf.writeByte(0);
    await raf.close();
  }

  @override
  Future<void> writeDocument(String uri, String srcPath) async {
    written = await File(srcPath).readAsString();
  }
}

void main() {
  late Directory tmp;
  late AppDatabase db;
  late DbWriteQueue queue;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('kfm_backup_ui');
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
  });

  tearDown(() async {
    await queue.close();
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pumpSection(WidgetTester tester, _FakeDocs docs) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          dbWriteQueueProvider.overrideWithValue(queue),
          backupDocumentsProvider.overrideWithValue(docs),
          backupCacheDirProvider.overrideWith((ref) async => tmp),
          backupIndexRefreshProvider.overrideWithValue(() async {}),
          backupServiceProvider.overrideWithValue(
            BackupService(
              db,
              queue,
              snapshotDir: () async => Directory('${tmp.path}/snaps'),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackupSection()),
        ),
      ),
    );
    await tester.pump();
  }

  /// Taps [finder] and lets real async work (isolates, files, DB) finish.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a foreign file is refused with a message, nothing written', (
    tester,
  ) async {
    await pumpSection(tester, _FakeDocs('{"some": "other app"}'));
    final before = await tester.runAsync(() => dumpUserTables(db));
    await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
    expect(find.text("This isn't a KFM backup."), findsOneWidget);
    expect(await tester.runAsync(() => dumpUserTables(db)), before);
  });

  testWidgets('Q6: a huge picked file is refused, nothing written', (
    tester,
  ) async {
    for (final honorLimit in [true, false]) {
      await pumpSection(
        tester,
        _FakeDocs(
          '{"format": "$kBackupFormat", "schema": 1, ',
          bytes: kMaxBackupFileBytes + 1,
          honorLimit: honorLimit,
        ),
      );
      final before = await tester.runAsync(() => dumpUserTables(db));
      await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
      expect(
        find.text("This isn't a KFM backup."),
        findsOneWidget,
        reason: 'honorLimit $honorLimit',
      );
      expect(await tester.runAsync(() => dumpUserTables(db)), before);
      // The staged copy is gone.
      expect(
        tmp.listSync(recursive: true).whereType<File>().where(
          (f) => f.path.endsWith('import.json'),
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a newer backup is refused', (tester) async {
    await pumpSection(
      tester,
      _FakeDocs('{"format": "$kBackupFormat", "schema": 99}'),
    );
    await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
    expect(find.textContaining('newer version'), findsOneWidget);
  });

  testWidgets('export writes the backup to the picked document', (
    tester,
  ) async {
    await tester.runAsync(() => addTag(db, 'Holiday'));
    final docs = _FakeDocs('');
    await pumpSection(tester, docs);
    await tapAndSettle(tester, find.byKey(const ValueKey('backup-export')));
    expect(find.text('Backup saved'), findsOneWidget);
    final data = BackupCodec.decode(docs.written!);
    expect(data.tags.single.name, 'Holiday');
  });

  testWidgets('import preview: Cancel writes nothing, Import applies', (
    tester,
  ) async {
    final backup = BackupCodec.encode(
      BackupData(
        createdAt: DateTime.utc(2026),
        appVersion: '0.1.0',
        dbSchema: 23,
        settings: const {},
        tags: const [BackupTag(key: 1, name: 'Holiday', color: 1)],
        presets: const [],
        files: const [
          BackupFile(
            vol: 'int',
            rel: 'DCIM',
            name: 'a.jpg',
            size: 1000,
            takenAtMs: 1700000000000,
            tags: [1],
          ),
          BackupFile(
            vol: 'int',
            rel: 'DCIM',
            name: 'gone.jpg',
            size: 5,
            takenAtMs: null,
            favorite: true,
          ),
        ],
      ),
    );
    await tester.runAsync(
      () => addIndexed(
        db,
        id: 'x1',
        folder: '/storage/emulated/0/DCIM',
        name: 'a.jpg',
      ),
    );
    await pumpSection(tester, _FakeDocs(backup));

    await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
    expect(find.text('1 new tag'), findsOneWidget);
    expect(find.text('1 file found on this phone'), findsOneWidget);
    expect(find.text('1 file not found on this phone'), findsOneWidget);
    await tapAndSettle(tester, find.text('Cancel'));
    expect(await tester.runAsync(() => db.select(db.tags).get()), isEmpty);

    await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey('backup-import-apply')),
    );
    expect(find.text('Backup imported'), findsOneWidget);
    final tags = await tester.runAsync(() => db.select(db.tags).get());
    expect(tags!.single.name, 'Holiday');
    final fileTags = await tester.runAsync(() => db.select(db.fileTags).get());
    expect(fileTags!.single.fileId, 'x1');
    expect(find.byKey(const ValueKey('backup-undo')), findsOneWidget);
  });

  testWidgets('import preview names settings, never raw keys', (tester) async {
    final backup = BackupCodec.encode(
      BackupData(
        createdAt: DateTime.utc(2026),
        appVersion: '0.1.0',
        dbSchema: 23,
        settings: {
          AppSettings.hapticsEnabled.name: false,
          AppSettings.swipeButtonsMode.name: true,
        },
        tags: const [],
        presets: const [],
        files: const [],
      ),
    );
    await pumpSection(tester, _FakeDocs(backup));
    await tapAndSettle(tester, find.byKey(const ValueKey('backup-import')));
    await tapAndSettle(tester, find.text('2 settings change').last);
    expect(find.text('Vibration feedback'), findsOneWidget);
    expect(find.text('Swipe buttons'), findsOneWidget);
    expect(find.text(AppSettings.hapticsEnabled.name), findsNothing);
    expect(find.text(AppSettings.swipeButtonsMode.name), findsNothing);
  });

  test('every backed-up setting has a label', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect([
      for (final s in backupSettings)
        if (backupSettingLabelOrNull(l10n, s.name) == null) s.name,
    ], isEmpty);
  });
}
