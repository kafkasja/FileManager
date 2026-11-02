import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/folder_listing.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:meta/meta.dart';

/// The object handle of a storage's root folder.
const kMtpRootHandle = -1;

/// One object on a camera (`MtpChannel.kt`).
@immutable
class MtpObject {
  const new({
    required this.handle,
    required this.storage,
    required this.name,
    required this.isFolder,
    required this.sizeBytes,
    required this.modifiedSec,
    this.path = '',
  });

  factory fromRow(Map<Object?, Object?> r) => MtpObject(
    handle: (r['handle']! as num).toInt(),
    storage: (r['storage'] as num?)?.toInt() ?? 0,
    name: r['name'] as String? ?? '',
    isFolder: r['folder'] == true,
    sizeBytes: (r['size'] as num?)?.toInt() ?? 0,
    modifiedSec: (r['modified'] as num?)?.toInt() ?? 0,
    path: r['path'] as String? ?? '',
  );

  final int handle;
  final int storage;
  final String name;
  final bool isFolder;
  final int sizeBytes;

  /// Seconds since epoch (MTP dates).
  final int modifiedSec;

  /// Folder names from the storage root ('' = at the root; [MtpPlatform
  /// .info] only).
  final String path;
}

/// Read-only access to cameras (Android: `com.kaf.kfm/mtp`). Failures
/// throw [FileOpException].
abstract interface class MtpObjectsPlatform {
  Future<List<({int id, String description})>> storages(String device);
  Future<List<MtpObject>> children(String device, int storage, int parent);
  Future<MtpObject?> info(String device, int handle);

  /// Copies the object into the local file [path].
  Future<bool> importTo(String device, int handle, String path);
  Future<bool> delete(String device, int handle);
  Future<Uint8List?> thumbnail(String device, int handle);
  Future<bool> canDelete(String device);
}

class MtpObjectsChannel implements MtpObjectsPlatform {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.kaf.kfm/mtp');

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw FileOpException(switch (e.code) {
        'NOT_FOUND' => FileOpFailure.unavailable,
        'PERMISSION' => FileOpFailure.permissionDenied,
        _ => FileOpFailure.ioError,
      }, 'mtp $method: ${e.message}');
    }
  }

  @override
  Future<List<({int id, String description})>> storages(String device) async {
    final rows = await _call<List<Object?>>('storages', {'deviceName': device});
    return [
      for (final r in rows ?? const <Object?>[])
        if (r is Map<Object?, Object?>)
          (
            id: (r['id']! as num).toInt(),
            description: r['description'] as String? ?? '',
          ),
    ];
  }

  @override
  Future<List<MtpObject>> children(
    String device,
    int storage,
    int parent,
  ) async {
    final rows = await _call<List<Object?>>('children', {
      'deviceName': device,
      'storage': storage,
      'parent': parent,
    });
    return [
      for (final r in rows ?? const <Object?>[])
        if (r is Map<Object?, Object?>) MtpObject.fromRow(r),
    ];
  }

  @override
  Future<MtpObject?> info(String device, int handle) async {
    final r = await _call<Map<Object?, Object?>>('info', {
      'deviceName': device,
      'handle': handle,
    });
    return r == null ? null : MtpObject.fromRow(r);
  }

  @override
  Future<bool> importTo(String device, int handle, String path) async =>
      await _call<bool>('importTo', {
        'deviceName': device,
        'handle': handle,
        'path': path,
      }) ??
      false;

  @override
  Future<bool> delete(String device, int handle) async =>
      await _call<bool>('delete', {'deviceName': device, 'handle': handle}) ??
      false;

  @override
  Future<Uint8List?> thumbnail(String device, int handle) =>
      _call<Uint8List>('thumbnail', {'deviceName': device, 'handle': handle});

  @override
  Future<bool> canDelete(String device) async =>
      await _call<bool>('canDelete', {'deviceName': device}) ?? false;
}

/// The folder id of a camera itself (lists its storages).
String mtpDeviceFolder(String device) => 'mtp:$device';

/// Cameras over USB (TASK-U2), read-only: list, stat, read (through a
/// local cache copy), thumbnails, and permanent delete when the camera
/// supports it. Ids `mtp:<device>|<storage>|<handle>`; folders are `mtp:`
/// ids (a storage root: handle [kMtpRootHandle]); `folderPath` is
/// `/mtp/<storage>/<names>` (display only).
class MtpFileSource implements FileSource, BrowsableSource, CopiesOut {
  new({required this._channel, Future<Directory> Function()? cacheDir})
    : _cacheDir =
          cacheDir ?? (() => Directory.systemTemp.createTemp('kfm_mtp'));

  final MtpObjectsPlatform _channel;
  final Future<Directory> Function() _cacheDir;

  /// Devices known to support delete (filled by [listChildren]).
  final Map<String, bool> _canDelete = {};

  FileRef _ref(String device, MtpObject o, String folder) => FileRef(
    id: mtpId(device, o.storage, o.handle),
    uri: mtpId(device, o.storage, o.handle),
    name: o.name,
    kind: kindFor(null, o.name),
    sizeBytes: o.sizeBytes,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      o.modifiedSec * 1000,
      isUtc: true,
    ),
    folderPath: folder,
    origin: FileOrigin.external,
    hidden: o.name.startsWith('.'),
  );

  static String _folderPath(int storage, String path) =>
      path.isEmpty ? '/mtp/$storage' : '/mtp/$storage/$path';

  Never _readOnly(String what) =>
      throw FileOpException(FileOpFailure.unsupported, 'camera: $what');

  @override
  Future<FolderListing> listChildren(
    String folder, {
    bool includeHidden = false,
  }) async {
    final id = parseMtpId(folder);
    if (id == null) {
      final device = folder.substring('mtp:'.length);
      _canDelete[device] ??= await _channel.canDelete(device);
      return FolderListing(
        folders: [
          for (final s in await _channel.storages(device))
            FolderItem(
              id: mtpId(device, s.id, kMtpRootHandle),
              name: s.description,
            ),
        ],
        files: const [],
      );
    }
    var path = '';
    if (id.objectHandle != kMtpRootHandle) {
      final o = await _channel.info(id.deviceName, id.objectHandle);
      if (o != null) path = o.path.isEmpty ? o.name : '${o.path}/${o.name}';
    }
    final objects = await _channel.children(
      id.deviceName,
      id.storageId,
      id.objectHandle,
    );
    final folders = <FolderItem>[];
    final files = <FileRef>[];
    for (final o in objects) {
      if (!includeHidden && o.name.startsWith('.')) continue;
      if (o.isFolder) {
        folders.add(
          FolderItem(
            id: mtpId(id.deviceName, o.storage, o.handle),
            name: o.name,
          ),
        );
      } else {
        files.add(_ref(id.deviceName, o, _folderPath(o.storage, path)));
      }
    }
    return FolderListing(folders: folders, files: files);
  }

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    final root = query.rootPath;
    if (root == null || !root.startsWith('mtp:')) return;
    final pending = [root];
    final page = <FileRef>[];
    while (pending.isNotEmpty) {
      final listing = await listChildren(
        pending.removeLast(),
        includeHidden: query.includeHidden,
      );
      if (query.recursive) pending.addAll(listing.folders.map((f) => f.id));
      for (final f in listing.files) {
        if (!query.wants(f.kind)) continue;
        page.add(f);
        if (page.length >= query.pageSize) {
          yield List.of(page);
          page.clear();
        }
      }
    }
    if (page.isNotEmpty) yield page;
  }

  @override
  Future<FileRef?> stat(String id) async {
    final m = parseMtpId(id);
    if (m == null) return null;
    final MtpObject? o;
    try {
      o = await _channel.info(m.deviceName, m.objectHandle);
    } on FileOpException catch (e) {
      if (e.failure == FileOpFailure.unavailable) return null; // unplugged
      rethrow;
    }
    if (o == null || o.isFolder) return null;
    return _ref(m.deviceName, o, _folderPath(o.storage, o.path));
  }

  @override
  Future<String?> copyOut(FileRef f, String path) async {
    final m = parseMtpId(f.id) ?? _readOnly('bad id ${f.id}');
    if (!await _channel.importTo(m.deviceName, m.objectHandle, path)) {
      throw FileOpException(
        FileOpFailure.ioError,
        'import failed',
        fileId: f.id,
      );
    }
    return null;
  }

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) async* {
    final dir = await _cacheDir();
    final local = File('${dir.path}/object.bin');
    try {
      await copyOut(f, local.path);
      yield* local.openRead(start, end);
    } finally {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Cache: the OS clears it.
      }
    }
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    for (final f in files) {
      final m = parseMtpId(f.id) ?? _readOnly('bad id ${f.id}');
      if (!await _channel.delete(m.deviceName, m.objectHandle)) {
        throw FileOpException(
          FileOpFailure.unsupported,
          'camera refused delete',
          fileId: f.id,
        );
      }
    }
  }

  /// Cameras have no trash: everything fails `unsupported` (D2 queues
  /// camera deletes as permanent).
  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async => TrashResult(
    trashed: const [],
    failed: {
      for (final f in files)
        f.id: FileOpException(
          FileOpFailure.unsupported,
          'camera has no trash',
          fileId: f.id,
        ),
    },
  );

  @override
  bool supports(FileOp op, FileRef f) => switch (op) {
    FileOp.copy => true,
    FileOp.deletePermanently =>
      _canDelete[parseMtpId(f.id)?.deviceName ?? ''] ?? false,
    _ => false,
  };

  @override
  Future<String> createFolder(String parentPath, String name) =>
      _readOnly('createFolder');

  @override
  Future<FileRef> move(FileRef f, String targetFolder) => _readOnly('move');

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) =>
      _readOnly('copy (use CrossPlaceOps)');

  @override
  Future<FileRef> rename(FileRef f, String newName) => _readOnly('rename');

  @override
  Future<FileRef> restore(TrashedItem item) => _readOnly('restore');

  @override
  Future<List<TrashedItem>> listTrashed() async => const [];

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async =>
      const RestoreResult(restored: {}, failed: {});

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) async {}

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async => true;

  @override
  Future<FileRef?> statPath(String path) async => null;

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) => _readOnly('renameFolder');

  @override
  Future<int?> freeBytes(String folderPath) async => null;

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) async => const [];

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) => _readOnly('importFile');

  @override
  Stream<FileIdChange> get idChanges => const Stream.empty();
}
