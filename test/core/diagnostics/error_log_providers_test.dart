import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';

import 'fake_error_log.dart';

void main() {
  test('a failed queued write is logged with its coalesce key', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final log = FakeErrorLog();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        errorLogProvider.overrideWithValue(log),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    // Watched like App.build does (unwatched providers are paused).
    final sub = container.listen(errorLogDbBridgeProvider, (_, _) {});
    addTearDown(sub.close);
    // The banner keeps working: errors still reach dbWriteErrorsProvider.
    final banner = <Object>[];
    container.listen(dbWriteErrorsProvider, (_, next) {
      if (next.value case final e?) banner.add(e);
    });
    await Future<void>.delayed(Duration.zero);

    final queue = container.read(dbWriteQueueProvider);
    await queue
        .enqueue('session:cursor', () async => throw StateError('disk full'))
        .catchError((Object _) {});
    await Future<void>.delayed(Duration.zero);

    expect(log.entries, hasLength(1));
    expect(log.entries.single.source, ErrorSource.db);
    expect(log.entries.single.error, contains('session:cursor'));
    expect(log.entries.single.error, contains('disk full'));
    expect(banner, hasLength(1));
  });

  test(
    'the About count follows new errors and clear without a rebuild',
    () async {
      final dir = Directory.systemTemp.createTempSync('kfm_error_count');
      addTearDown(() => dir.deleteSync(recursive: true));
      final log = ErrorLog.main(() async => dir);
      final container = ProviderContainer(
        overrides: [errorLogProvider.overrideWithValue(log)],
      );
      addTearDown(container.dispose);
      final counts = <int>[];
      final sub = container.listen(errorLogCountProvider, (_, next) {
        if (next.value case final c?) counts.add(c);
      }, fireImmediately: true);
      addTearDown(sub.close);
      await container.read(errorLogCountProvider.future);

      await log.record(
        ErrorLogEntry(
          at: DateTime.utc(2026, 11, 2),
          source: ErrorSource.flutter,
          error: 'boom',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await container.read(errorLogCountProvider.future), 1);

      await log.clear();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await container.read(errorLogCountProvider.future), 0);
      expect(counts, containsAllInOrder([0, 1, 0]));
    },
  );

  test('without main the log is disabled', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(errorLogProvider).entryCount(), 0);
  });
}
