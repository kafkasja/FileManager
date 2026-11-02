import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/cross_place_ops.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/mtp/mtp_file_source.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';
import 'package:kfm/core/files/trash_types.dart';

final _volumeRoot = RegExp(r'^/storage/(emulated/\d+|[^/]+)');

/// The U1 place id of the volume root holding [path]: `primary` for
/// `/storage/emulated/N`, the volume uuid for `/storage/<uuid>`; the root
/// itself for anything else (tests, other platforms).
String placeIdOfPath(String path) {
  final m = _volumeRoot.firstMatch(path);
  if (m == null) return path.split('/').take(2).join('/');
  final v = m.group(1)!;
  return v.startsWith('emulated/') ? 'primary' : v;
}

/// The U1 place id of a folder: a path, a `saf:` id (its tree's volume) or
/// an `mtp:` folder id (the camera).
String placeIdOfFolder(String folder, {SafLocator? saf}) {
  if (folder.startsWith('mtp:')) {
    final m = parseMtpId(folder);
    return 'mtp:${m?.deviceName ?? folder.substring(4)}';
  }
  if (parseSafId(folder) case final id?) {
    final tree = saf?.treeOfUri(id.treeUri);
    if (tree != null) return placeIdOfPath(tree.root);
    final uuid = Uri.decodeComponent(id.documentId).split(':').first;
    return uuid.isEmpty ? id.treeUri : uuid;
  }
  return placeIdOfPath(folder);
}

/// The place a file is on (U3 uses it too).
String placeIdOf(FileRef f, {SafLocator? saf}) => switch (f.id) {
  final id when id.startsWith('mtp:') => placeIdOfFolder(id),
  final id when id.startsWith('saf:') => placeIdOfPath(f.folderPath),
  _ => placeIdOfPath(f.folderPath),
};

/// The one `fileSourceProvider` (TASK-U2): routes every call to the
/// source that owns the id (`ms:`/`path:` → Android, `saf:` → SAF, `mtp:`
/// → camera) or the target folder (a path under a SAF-granted root →
/// SAF), splits batches by source, and sends moves/copies between places
/// to [CrossPlaceOps]. Consumers don't change.
class RoutingFileSource implements FileSource {
  new({
    required this.android,
    required this.saf,
    required this.mtp,
    CrossPlaceOps Function(RoutingFileSource self)? crossPlace,
  }) {
    this.crossPlace =
        crossPlace?.call(this) ??
        CrossPlaceOps(
          sourceOfId: sourceForId,
          sourceOfFolder: sourceForFolder,
          staging: () => Directory.systemTemp.createTemp('kfm_xp'),
        );
    for (final s in [
      android.idChanges,
      saf.idChanges,
      this.crossPlace.idChanges,
    ]) {
      _subs.add(s.listen(_idChanges.add, onError: _idChanges.addError));
    }
  }

  final FileSource android;
  final SafFileSource saf;
  final MtpFileSource mtp;
  late final CrossPlaceOps crossPlace;
  final _subs = <StreamSubscription<FileIdChange>>[];
  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await crossPlace.dispose();
    await _idChanges.close();
  }

  FileSource sourceForId(String id) {
    if (id.startsWith('saf:')) return saf;
    if (id.startsWith('mtp:')) return mtp;
    return android;
  }

  /// The source writing into [folder].
  FileSource sourceForFolder(String folder) {
    if (folder.startsWith('mtp:')) return mtp;
    if (saf.locator.owns(folder)) return saf;
    return android;
  }

  String placeOfFile(FileRef f) => placeIdOf(f, saf: saf.locator);

  String placeOfFolder(String folder) =>
      placeIdOfFolder(folder, saf: saf.locator);

  /// True when [f] → [targetFolder] needs a copy (another place, or the
  /// same volume through another source).
  bool isCrossPlace(FileRef f, String targetFolder) =>
      !identical(sourceForId(f.id), sourceForFolder(targetFolder)) ||
      placeOfFile(f) != placeOfFolder(targetFolder);

  Map<FileSource, List<T>> _split<T>(List<T> items, String Function(T) id) {
    final out = <FileSource, List<T>>{};
    for (final i in items) {
      (out[sourceForId(id(i))] ??= []).add(i);
    }
    return out;
  }

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) {
    final root = query.rootPath;
    if (root != null && root.startsWith('saf:')) return saf.scan(query: query);
    if (root != null && root.startsWith('mtp:')) return mtp.scan(query: query);
    return android.scan(query: query);
  }

  @override
  Future<FileRef?> stat(String id) => sourceForId(id).stat(id);

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) =>
      sourceForId(f.id).openRead(f, start: start, end: end);

  @override
  Future<String> createFolder(String parentPath, String name) =>
      sourceForFolder(parentPath).createFolder(parentPath, name);

  @override
  Future<FileRef> move(FileRef f, String targetFolder) =>
      isCrossPlace(f, targetFolder)
      ? crossPlace.move(f, targetFolder)
      : sourceForId(f.id).move(f, targetFolder);

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) =>
      isCrossPlace(f, targetFolder)
      ? crossPlace.copy(f, targetFolder)
      : sourceForId(f.id).copy(f, targetFolder);

  @override
  Future<FileRef> rename(FileRef f, String newName) =>
      sourceForId(f.id).rename(f, newName);

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    final trashed = <TrashedItem>[];
    final failed = <String, FileOpException>{};
    var cancelled = false;
    for (final MapEntry(key: s, value: part) in _split(
      files,
      (f) => f.id,
    ).entries) {
      final r = await s.trashBatch(part);
      trashed.addAll(r.trashed);
      failed.addAll(r.failed);
      cancelled = cancelled || r.userCancelled;
    }
    return TrashResult(
      trashed: trashed,
      failed: failed,
      userCancelled: cancelled,
    );
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    for (final MapEntry(key: s, value: part) in _split(
      files,
      (f) => f.id,
    ).entries) {
      await s.deletePermanentlyBatch(part);
    }
  }

  @override
  Future<FileRef> restore(TrashedItem item) =>
      sourceForId(item.original.id).restore(item);

  @override
  Future<List<TrashedItem>> listTrashed() async => [
    ...await android.listTrashed(),
    ...await saf.listTrashed(),
  ];

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async {
    final restored = <String, FileRef>{};
    final failed = <String, FileOpException>{};
    var cancelled = false;
    for (final MapEntry(key: s, value: part) in _split(
      items,
      (i) => i.original.id,
    ).entries) {
      final r = await s.restoreBatch(part);
      restored.addAll(r.restored);
      failed.addAll(r.failed);
      cancelled = cancelled || r.userCancelled;
    }
    return RestoreResult(
      restored: restored,
      failed: failed,
      userCancelled: cancelled,
    );
  }

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) async {
    for (final MapEntry(key: s, value: part) in _split(
      items,
      (i) => i.original.id,
    ).entries) {
      await s.deleteFromTrash(part);
    }
  }

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async {
    for (final MapEntry(key: s, value: part) in _split(
      files,
      (f) => f.id,
    ).entries) {
      if (!await s.requestWriteAccess(part)) return false;
    }
    return true;
  }

  @override
  Future<FileRef?> statPath(String path) =>
      sourceForFolder(path).statPath(path);

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) => sourceForFolder(folderPath).renameFolder(folderPath, newName);

  @override
  Future<int?> freeBytes(String folderPath) =>
      sourceForFolder(folderPath).freeBytes(folderPath);

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) =>
      android.registerCreated(paths);

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) => sourceForFolder(targetFolder).importFile(
    staged,
    targetFolder: targetFolder,
    name: name,
    mimeType: mimeType,
  );

  @override
  bool supports(FileOp op, FileRef f) => sourceForId(f.id).supports(op, f);

  @override
  Stream<FileIdChange> get idChanges => _idChanges.stream;
}
