import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';

/// Counts every [FileSource] call that touches a removable place in the
/// [VolumeActivityTracker] (TASK-U3), so Eject can wait for KFM's own work
/// and refuse new work. Streams count from listen until done, error or
/// cancel; an eject ends top-level streams with `volumeEjecting`.
/// Metadata-only calls (`stat`, `statPath`, `freeBytes`, `listTrashed`)
/// pass through.
class TrackedFileSource implements FileSource, FileSourceDecorator {
  new({
    required this.inner,
    required this._tracker,
    String Function(FileRef f)? placeOfFile,
    String Function(String folder)? placeOfFolder,
  }) : _placeOfFile = placeOfFile ?? routingOf(inner)?.placeOfFile ?? placeIdOf,
       _placeOfFolder =
           placeOfFolder ?? routingOf(inner)?.placeOfFolder ?? placeIdOfFolder;

  @override
  final FileSource inner;
  final VolumeActivityTracker _tracker;
  final String Function(FileRef f) _placeOfFile;
  final String Function(String folder) _placeOfFolder;

  /// The place [f] is on, as this source counts it (U3's reader cleanup).
  String placeOfFile(FileRef f) => _placeOfFile(f);

  Future<T> _files<T>(Iterable<FileRef> files, Future<T> Function() op) =>
      _tracker.runAll({for (final f in files) _placeOfFile(f)}, op);

  Stream<T> _stream<T>(String placeId, Stream<T> Function() open) {
    if (!VolumeActivityTracker.tracks(placeId)) return open();
    // Cancelled in stop() (cancel, eject) or done.
    // ignore: cancel_subscriptions
    StreamSubscription<T>? sub;
    VolumeLease? lease;
    late final StreamController<T> out;
    Future<void> stop() async {
      lease?.release();
      final s = sub;
      sub = null;
      await s?.cancel();
    }

    out = StreamController<T>(
      onListen: () {
        try {
          lease = _tracker.acquire(
            placeId,
            onEject: () {
              unawaited(() async {
                await stop();
                if (out.isClosed) return;
                out.addError(
                  FileOpException(
                    FileOpFailure.volumeEjecting,
                    'ejecting: $placeId',
                  ),
                );
                await out.close();
              }());
            },
          );
          sub = open().listen(
            out.add,
            onError: out.addError,
            onDone: () {
              lease?.release();
              sub = null;
              unawaited(out.close());
            },
          );
        } on Object catch (e, st) {
          lease?.release();
          out
            ..addError(e, st)
            ..close().ignore();
        }
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: stop,
    );
    return out.stream;
  }

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) {
    final root = query.rootPath;
    if (root == null) return inner.scan(query: query); // every volume
    return _stream(_placeOfFolder(root), () => inner.scan(query: query));
  }

  @override
  Future<FileRef?> stat(String id) => inner.stat(id);

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) =>
      _stream(_placeOfFile(f), () => inner.openRead(f, start: start, end: end));

  @override
  Future<String> createFolder(String parentPath, String name) => _tracker.run(
    _placeOfFolder(parentPath),
    () => inner.createFolder(parentPath, name),
  );

  @override
  Future<FileRef> move(FileRef f, String targetFolder) => _tracker.runAll([
    _placeOfFile(f),
    _placeOfFolder(targetFolder),
  ], () => inner.move(f, targetFolder));

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) => _tracker.runAll([
    _placeOfFile(f),
    _placeOfFolder(targetFolder),
  ], () => inner.copy(f, targetFolder));

  @override
  Future<FileRef> rename(FileRef f, String newName) =>
      _files([f], () => inner.rename(f, newName));

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) =>
      _files(files, () => inner.trashBatch(files));

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) =>
      _files(files, () => inner.deletePermanentlyBatch(files));

  @override
  Future<FileRef> restore(TrashedItem item) =>
      _files([item.original], () => inner.restore(item));

  @override
  Future<List<TrashedItem>> listTrashed() => inner.listTrashed();

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) => _files([
    for (final i in items) i.original,
  ], () => inner.restoreBatch(items));

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) => _files([
    for (final i in items) i.original,
  ], () => inner.deleteFromTrash(items));

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) =>
      inner.requestWriteAccess(files);

  @override
  Future<FileRef?> statPath(String path) => inner.statPath(path);

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) => _tracker.run(
    _placeOfFolder(folderPath),
    () => inner.renameFolder(folderPath, newName),
  );

  @override
  Future<int?> freeBytes(String folderPath) => inner.freeBytes(folderPath);

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) => _tracker.runAll({
    for (final p in paths) placeIdOfPath(p),
  }, () => inner.registerCreated(paths));

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) => _tracker.run(
    _placeOfFolder(targetFolder),
    () => inner.importFile(
      staged,
      targetFolder: targetFolder,
      name: name,
      mimeType: mimeType,
    ),
  );

  @override
  bool supports(FileOp op, FileRef f) => inner.supports(op, f);

  @override
  Stream<FileIdChange> get idChanges => inner.idChanges;
}
