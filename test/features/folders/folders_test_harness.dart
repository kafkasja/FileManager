import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

/// Runner + undo over an in-memory DB and a [FakeFileSource].
class FoldersHarness {
  new _(this.c, this.db, this.files);

  final ProviderContainer c;
  final AppDatabase db;
  final FakeFileSource files;

  FileOperationRunner get runner => c.read(fileOperationRunnerProvider);

  /// Indexed ids right now.
  Future<Set<String>> indexedIds() async => {
    for (final r in await db.select(db.mediaIndex).get()) r.id,
  };

  Future<FileRef?> indexed(String id) async =>
      (await c.read(mediaIndexDaoProvider).byIds([id])).firstOrNull;

  /// Lets id-change listeners and the indexer queue finish.
  Future<void> settle() async {
    await pumpEventQueue();
    await runner.indexSettled;
    await c.read(mediaIndexerProvider).addFiles(const []);
  }

  Future<CompletedOperation> run(
    FileOperation op, {
    CancelToken? cancel,
    CollisionResolver? resolve,
    void Function(OperationProgress)? onProgress,
  }) async {
    final done = await runner.run(
      op,
      cancel: cancel ?? CancelToken(),
      resolveCollision: resolve ?? (_, _) => fail('no collision expected'),
      onProgress: onProgress,
    );
    await settle();
    return done;
  }
}

/// A [FakeFileSource] with the B4 failure modes the runner must survive.
/// [statPath] ignores case like Android shared storage.
class FlakyFileSource extends FakeFileSource {
  /// `move` / `copy` of a file with one of these names throws `ioError`.
  final Set<String> failOpsOn = {};

  /// `deletePermanentlyBatch` deletes this many files, then throws.
  int? deleteThenThrowAfter;

  Completer<void>? _scanGate;

  /// Scans wait until the returned completer completes (a long full scan).
  Completer<void> holdScans() => _scanGate = Completer<void>();

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    if (_scanGate case final gate?) await gate.future;
    yield* super.scan(query: query);
  }

  @override
  Future<FileRef?> statPath(String path) async {
    final want = path.toLowerCase();
    return files.where((f) => f.path.toLowerCase() == want).firstOrNull;
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    if (failOpsOn.contains(f.name)) {
      throw FileOpException(FileOpFailure.ioError, 'move', fileId: f.id);
    }
    return await super.move(f, targetFolder);
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    if (failOpsOn.contains(f.name)) {
      throw FileOpException(FileOpFailure.ioError, 'copy', fileId: f.id);
    }
    return await super.copy(f, targetFolder);
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    final n = deleteThenThrowAfter;
    if (n == null) return await super.deletePermanentlyBatch(files);
    await super.deletePermanentlyBatch(files.take(n).toList());
    throw const FileOpException(FileOpFailure.ioError, 'batch broke');
  }
}

Future<FoldersHarness> launchFolders(
  FakeFileSource files, {
  StorageAccess access = grantedAccess,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      fileSourceProvider.overrideWithValue(files),
      permissionServiceProvider.overrideWithValue(
        FakePermissionService(access),
      ),
      mediaChangesProvider.overrideWithValue(const Stream.empty()),
    ],
  );
  await c.read(storageAccessControllerProvider.future);
  await c.read(mediaIndexerProvider).start();
  addTearDown(() async {
    await c.read(dbWriteQueueProvider).flush();
    c.dispose();
    await db.close();
    await files.dispose();
  });
  return FoldersHarness._(c, db, files);
}
