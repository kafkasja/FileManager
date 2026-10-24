import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/data/rename_runner.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:kfm/features/rename/domain/rename_batch.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

import '../../core/files/fake_file_source.dart';

/// Simulates the app dying after [crashAfter] successful renames.
class _CrashingSource extends FakeFileSource {
  int? crashAfter;
  int _renames = 0;

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    if (crashAfter != null && _renames >= crashAfter!) {
      throw StateError('process killed');
    }
    _renames++;
    return await super.rename(f, newName);
  }
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late _CrashingSource files;
  late RenameBatchRepository repo;
  late UndoRepository undo;
  late MediaIndexer indexer;
  late RenameRunner runner;
  late int sessionId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    files = _CrashingSource();
    repo = RenameBatchRepository(db);
    undo = UndoRepository(db, queue);
    indexer = MediaIndexer(
      dao: MediaIndexDao(db),
      source: files,
      settings: SettingsRepository(db, queue),
      canSeeAllFiles: () => true,
    );
    runner = RenameRunner(
      source: files,
      repo: repo,
      undo: undo,
      lock: SerialLock(),
      indexer: indexer,
    );
    sessionId = (await SessionRepository(db, queue).getOrCreateActive()).id;
    await undo.prepare(sessionId);
  });

  tearDown(() async {
    await indexer.dispose();
    await queue.close();
    await db.close();
  });

  Future<int> batchOf(List<FileRef> refs) async {
    late int batchId;
    for (final f in refs) {
      final p = await db.transaction(() => repo.addInTransaction(sessionId, f));
      batchId = p.batchId;
    }
    return batchId;
  }

  Future<Map<String, String>> plan(int batchId, NamePattern p) async {
    final items = await repo.items(batchId);
    final names = buildNames(p, [
      for (final i in items)
        (originalName: i.originalName, date: DateTime(2026)),
    ]);
    return {for (final (k, i) in items.indexed) i.fileId: names[k]};
  }

  Future<List<String>> namesIn(String folder) async => [
    for (final page in await files.scan().toList())
      for (final f in page)
        if (f.folderPath == folder) f.name,
  ]..sort();

  const pattern = NamePattern(template: 'holiday_{n}');

  test(
    'apply renames on disk, records one undo row; revert restores',
    () async {
      final refs = [
        files.addFile('/s/DCIM/a.jpg'),
        files.addFile('/s/DCIM/b.mp4'),
        files.addFile('/s/DCIM/c.jpg'),
      ];
      final batchId = await batchOf(refs);
      final result = await runner.apply(
        sessionId,
        batchId,
        pattern,
        await plan(batchId, pattern),
      );
      expect(result.renamed, 3);
      expect(await namesIn('/s/DCIM'), [
        'holiday_001.jpg',
        'holiday_002.mp4',
        'holiday_003.jpg',
      ]);
      expect((await repo.byId(batchId))!.status, RenameBatchStatus.applied);
      await queue.flush();
      final top = (await undo.top(sessionId))!;
      expect((top.previous as RenamePreviousState).op, RenameOp.apply);

      final back = await runner.revert(batchId);
      expect(back.renamed, 3);
      expect(await namesIn('/s/DCIM'), ['a.jpg', 'b.mp4', 'c.jpg']);
      expect((await repo.byId(batchId))!.status, RenameBatchStatus.collecting);
    },
  );

  test('swapping two names goes through temporary names', () async {
    final a = files.addFile('/s/DCIM/x_001.jpg');
    final b = files.addFile('/s/DCIM/x_002.jpg');
    final batchId = await batchOf([b, a]); // b becomes 001, a becomes 002
    await runner.apply(
      sessionId,
      batchId,
      const NamePattern(template: 'x_{n}'),
      await plan(batchId, const NamePattern(template: 'x_{n}')),
    );
    expect(await namesIn('/s/DCIM'), ['x_001.jpg', 'x_002.jpg']);
    final items = await repo.items(batchId);
    expect(items.every((i) => !i.skipped), isTrue);
    expect(items.first.currentName, 'x_001.jpg');
    expect(items.first.originalName, 'x_002.jpg');
  });

  test('declining the one consent dialog renames nothing', () async {
    final batchId = await batchOf([files.addFile('/s/DCIM/a.jpg')]);
    files.declineWriteAccess = true;
    final result = await runner.apply(
      sessionId,
      batchId,
      pattern,
      await plan(batchId, pattern),
    );
    expect(result.declined, isTrue);
    expect(await namesIn('/s/DCIM'), ['a.jpg']);
    expect((await repo.byId(batchId))!.status, RenameBatchStatus.collecting);
  });

  test(
    'a crash mid-apply is finished at the next start, no temp names',
    () async {
      final a = files.addFile('/s/DCIM/x_001.jpg');
      final b = files.addFile('/s/DCIM/x_002.jpg');
      final c = files.addFile('/s/DCIM/c.jpg');
      final batchId = await batchOf([b, a, c]);
      files.crashAfter = 4; // inside phase 2 of the two-phase rename
      await expectLater(
        runner.apply(
          sessionId,
          batchId,
          const NamePattern(template: 'x_{n}'),
          await plan(batchId, const NamePattern(template: 'x_{n}')),
        ),
        throwsStateError,
      );
      expect((await repo.byId(batchId))!.status, RenameBatchStatus.applying);

      files.crashAfter = null;
      await runner.recoverInterrupted();
      final names = await namesIn('/s/DCIM');
      expect(names, ['x_001.jpg', 'x_002.jpg', 'x_003.jpg']);
      expect(names.any((n) => n.startsWith(RenameRunner.tempPrefix)), isFalse);
      expect((await repo.byId(batchId))!.status, RenameBatchStatus.applied);
    },
  );

  test('a file gone before apply is skipped, the rest is renamed', () async {
    final a = files.addFile('/s/DCIM/a.jpg');
    final b = files.addFile('/s/DCIM/b.jpg');
    final batchId = await batchOf([a, b]);
    await files.deletePermanentlyBatch([a]);
    final result = await runner.apply(
      sessionId,
      batchId,
      pattern,
      await plan(batchId, pattern),
    );
    expect(result.renamed, 1);
    expect(result.skipped, 1);
    expect(await namesIn('/s/DCIM'), ['holiday_002.jpg']);
  });

  test('the same file swiped in twice is added once', () async {
    final a = files.addFile('/s/DCIM/a.jpg');
    final first = await db.transaction(
      () => repo.addInTransaction(sessionId, a),
    );
    final second = await db.transaction(
      () => repo.addInTransaction(sessionId, a),
    );
    expect(first.added, isTrue);
    expect(second.added, isFalse);
    expect(await repo.items(first.batchId), hasLength(1));
  });
}
