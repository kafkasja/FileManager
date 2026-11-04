import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/backup/data/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_providers.g.dart';

/// The system "Save as" / open pickers for one document (Android:
/// `SafDocuments.kt` on the files channel). Null uri = cancelled.
abstract interface class BackupDocuments {
  Future<String?> createDocument(String name, String mime);
  Future<String?> openDocument(List<String> mimes);
  Future<void> writeDocument(String uri, String srcPath);

  /// Copies the document to [destPath]. Fails with a [FilesChannelException]
  /// `TOO_BIG` (partial copy removed) when it is over [maxBytes].
  Future<void> readDocument(String uri, String destPath, {int? maxBytes});
}

class ChannelBackupDocuments implements BackupDocuments {
  const new(this._channel);

  final FilesChannel _channel;

  @override
  Future<String?> createDocument(String name, String mime) =>
      _channel.createDocument(name, mime);

  @override
  Future<String?> openDocument(List<String> mimes) =>
      _channel.openDocument(mimes);

  @override
  Future<void> writeDocument(String uri, String srcPath) =>
      _channel.writeDocument(uri, srcPath);

  @override
  Future<void> readDocument(String uri, String destPath, {int? maxBytes}) =>
      _channel.readDocument(uri, destPath, maxBytes: maxBytes);
}

@Riverpod(keepAlive: true)
BackupDocuments backupDocuments(Ref ref) =>
    ChannelBackupDocuments(FilesChannel());

/// Where backup files are staged between the pickers and the app.
@Riverpod(keepAlive: true)
Future<Directory> backupCacheDir(Ref ref) async {
  final dir = Directory(p.join((await getTemporaryDirectory()).path, 'backup'));
  await dir.create(recursive: true);
  return dir;
}

@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) => BackupService(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
  snapshotDir: () async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'backups'),
  ),
);

/// Brings `media_index` up to date before matching (an incremental scan).
@Riverpod(keepAlive: true)
Future<void> Function() backupIndexRefresh(Ref ref) {
  final indexer = ref.watch(mediaIndexerProvider);
  return indexer.incremental;
}

/// "Undo last import" is offered while this is true; invalidate after an
/// import or undo.
@riverpod
Future<bool> backupUndoAvailable(Ref ref) =>
    ref.watch(backupServiceProvider).canUndo();
