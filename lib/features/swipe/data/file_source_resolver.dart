import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:kfm/features/session/domain/session_source.dart';

part 'file_source_resolver.g.dart';

/// The [FileSource] of a session source id (TASK-N8): this device's, or a
/// connected device's (N7). Unknown prefixes throw [ArgumentError].
class FileSourceResolver {
  new(this._local, this._remote);

  final FileSource _local;
  final FileSource Function(String peerFingerprint) _remote;

  FileSource call(String sourceId) {
    if (sourceId == kLocalSourceId) return _local;
    final fp = peerOfSourceId(sourceId);
    if (fp == null) throw ArgumentError.value(sourceId, 'sourceId');
    return _remote(fp);
  }

  /// The source of the file [fileId] (`remote:<fp>:…` or local).
  FileSource forFile(String fileId) => call(sourceIdOfFile(fileId));

  /// D2's trash call: a remote device is told the files were swiped, so
  /// its banner says so (N7 `TrashReason.swipe`).
  static Future<TrashResult> swipeTrash(
    FileSource source,
    List<FileRef> files,
  ) => source is RemoteFileSource
      ? source.trashBatchFor(files, reason: TrashReason.swipe)
      : source.trashBatch(files);
}

@Riverpod(keepAlive: true)
FileSourceResolver fileSourceResolver(Ref ref) => FileSourceResolver(
  ref.watch(fileSourceProvider),
  (fp) => ref.read(remoteSourceProvider(fp)),
);
