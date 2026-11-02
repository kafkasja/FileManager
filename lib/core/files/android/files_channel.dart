import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Error from the Kotlin side; [code] is one of the FilesChannel.kt codes.
@immutable
class FilesChannelException implements Exception {
  const new(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'FilesChannelException($code): $message';
}

/// A MediaStore row as returned by FilesChannel.kt.
typedef MediaRow = Map<String, Object?>;

/// Typed wrapper around `com.kaf.kfm/files` (FilesChannel.kt). Only
/// AndroidFileSource uses it.
class FilesChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'com.kaf.kfm/files';

  /// N7: the Files-table observer (FilesChannel.kt), active while listened.
  static const changesName = 'kfm/files_changes';

  /// N7: raw `{type, path?, mediaType?}` events of `MediaStore.Files`
  /// (descendants). The native observer is registered on listen and
  /// unregistered on cancel.
  static Stream<MediaRow> filesTableEvents([EventChannel? channel]) =>
      (channel ?? const EventChannel(changesName))
          .receiveBroadcastStream()
          .where((e) => e is Map)
          .map((e) => _row(e as Map<Object?, Object?>));

  final MethodChannel _channel;

  Future<int> sdkInt() async => (await _invoke<int>('sdkInt'))!;

  /// N1: the phone's maker + model (default "Share this device" name).
  Future<String> deviceModel() async =>
      (await _invoke<String>('deviceModel')) ?? '';

  Future<bool> hasAllFilesAccess() async =>
      (await _invoke<bool>('hasAllFilesAccess'))!;

  /// API 31+ "Media management" special access (skips consent dialogs).
  Future<bool> canManageMedia() async =>
      (await _invoke<bool>('canManageMedia')) ?? false;

  /// Opens the system page for [canManageMedia]. False below API 31.
  Future<bool> openMediaManagementSettings() async =>
      (await _invoke<bool>('openMediaManagementSettings')) ?? false;

  /// API 30+: into (value) or out of (!value) the system trash. One system
  /// dialog for the whole list. False = the user declined.
  Future<bool> trashMedia(List<String> uris, {required bool value}) async =>
      (await _invoke<bool>('trashMedia', {'uris': uris, 'value': value})) ??
      false;

  /// Permanent delete (API 30+: one dialog). False = declined.
  Future<bool> deleteMedia(List<String> uris) async =>
      (await _invoke<bool>('deleteMedia', {'uris': uris})) ?? false;

  /// API 30+: media in the system trash (rows include `expires`, epoch s).
  Future<List<MediaRow>> listTrashed() async {
    final rows = await _invokeList('listTrashed');
    return rows.map(_row).toList(growable: false);
  }

  /// One page of media, newest first, keyset-paged by [afterModified] +
  /// [afterId] (the last row of the previous page).
  Future<List<MediaRow>> queryMedia({
    required Set<String> kinds,
    required int limit,
    String? root,
    int? modifiedAfterSeconds,
    int? minSize,
    int? afterModified,
    int? afterId,
  }) async {
    final rows = await _invokeList('queryMedia', {
      'kinds': kinds.toList(),
      'limit': limit,
      'root': root,
      'modifiedAfter': modifiedAfterSeconds,
      'minSize': minSize,
      'afterModified': afterModified,
      'afterId': afterId,
    });
    return rows.map(_row).toList(growable: false);
  }

  Future<MediaRow?> statMedia(int id) async {
    final row = await _invoke<Map<Object?, Object?>>('statMedia', {'id': id});
    return row == null ? null : _row(row);
  }

  /// B4: the image/video/audio row at [path], or null.
  Future<MediaRow?> statMediaByPath(String path) async {
    final row = await _invoke<Map<Object?, Object?>>('statMediaByPath', {
      'path': path,
    });
    return row == null ? null : _row(row);
  }

  /// B4: free bytes on the volume holding [path] (StatFs); null if unknown.
  Future<int?> freeBytes(String path) =>
      _invoke<int>('freeBytes', {'path': path});

  /// C1: total and free bytes of the primary volume.
  Future<({int totalBytes, int freeBytes})> storageSpace() async {
    final row = await _invoke<Map<Object?, Object?>>('storageSpace');
    final total = row?['totalBytes'];
    final free = row?['freeBytes'];
    if (total is! int || free is! int) {
      throw const FilesChannelException('bad_result', 'storageSpace');
    }
    return (totalBytes: total, freeBytes: free);
  }

  Future<MediaRow> moveMedia(int id, String targetDir, String displayName) =>
      _invokeRow('moveMedia', {
        'id': id,
        'targetDir': targetDir,
        'displayName': displayName,
      });

  Future<MediaRow> renameMedia(int id, String displayName) =>
      _invokeRow('renameMedia', {'id': id, 'displayName': displayName});

  Future<MediaRow> copyMedia(int id, String targetDir, String displayName) =>
      _invokeRow('copyMedia', {
        'id': id,
        'targetDir': targetDir,
        'displayName': displayName,
      });

  /// N9: publishes the app-private file [stagedPath] as [displayName] in
  /// [targetDir] (MediaStore insert, API 29+). Returns the new row.
  Future<MediaRow> importMedia(
    String stagedPath,
    String targetDir,
    String displayName, {
    String? mime,
  }) => _invokeRow('importMedia', {
    'stagedPath': stagedPath,
    'targetDir': targetDir,
    'displayName': displayName,
    'mime': mime,
  });

  /// Asks MediaStore to (re)index [paths]. Returns path → new media id.
  Future<Map<String, int?>> scanPaths(List<String> paths) async {
    final result = await _invoke<Map<Object?, Object?>>('scanPaths', {
      'paths': paths,
    });
    return {
      for (final MapEntry(:key, :value) in (result ?? const {}).entries)
        key! as String: value as int?,
    };
  }

  /// One system dialog for the whole list (API 30+). True if granted.
  Future<bool> requestWriteConsent(List<String> uris) async =>
      (await _invoke<bool>('requestWriteConsent', {'uris': uris})) ?? false;

  /// U1 (X3 reuses it): the SAF tree picker, opened at the volume [uuid]
  /// when given. Null = cancelled.
  Future<({String uri, String? treeDocumentId})?> pickTree({
    String? uuid,
  }) async {
    final row = await _invoke<Map<Object?, Object?>>('pickTree', {
      'uuid': uuid,
    });
    final uri = row?['uri'];
    if (uri is! String) return null;
    final doc = row?['treeDocumentId'];
    return (uri: uri, treeDocumentId: doc is String ? doc : null);
  }

  /// Keeps read + write access to the tree [uri] across restarts.
  Future<bool> persistTree(String uri) async =>
      (await _invoke<bool>('persistTree', {'uri': uri})) ?? false;

  Future<bool> releaseTree(String uri) async =>
      (await _invoke<bool>('releaseTree', {'uri': uri})) ?? false;

  /// The tree URIs this app holds a persisted grant for.
  Future<List<String>> persistedTrees() async {
    try {
      return await _channel.invokeListMethod<String>('persistedTrees') ??
          const [];
    } on PlatformException catch (e) {
      throw FilesChannelException(e.code, e.message ?? '');
    }
  }

  /// True when the grant is persisted and the tree's root still accepts new
  /// files (a reformatted stick with the same uuid fails).
  Future<bool> validateTree(String uri) async =>
      (await _invoke<bool>('validateTree', {'uri': uri})) ?? false;

  /// B1: Android "Open with" chooser. [contentUri] for MediaStore items,
  /// else [path] (shared through the FileProvider). False = no app.
  Future<bool> openWith({
    String? contentUri,
    String? path,
    String? mime,
  }) async =>
      (await _invoke<bool>('openWith', {
        'contentUri': contentUri,
        'path': path,
        'mime': mime,
      })) ??
      false;

  /// H5: Android share sheet for an app file under `filesDir/logs/export/`
  /// (FileProvider). False when no app can receive it.
  Future<bool> shareFile({
    required String path,
    required String mime,
    required String subject,
  }) async =>
      (await _invoke<bool>('shareFile', {
        'path': path,
        'mime': mime,
        'subject': subject,
      })) ??
      false;

  /// C5: EXIF GPS + front camera per MediaStore image id (own executor on
  /// the Kotlin side). Rows: `{id, lat?, lng?, frontCamera,
  /// locationReadable}` or `{id, error}`.
  Future<List<MediaRow>> readExif(List<int> ids) async {
    final rows = await _invokeList('readExif', {'ids': ids});
    return rows.map(_row).toList(growable: false);
  }

  /// C5: like [readExif] for `path:` images (All files access); `id` is
  /// the path.
  Future<List<MediaRow>> readExifPaths(List<String> paths) async {
    final rows = await _invokeList('readExifPaths', {'paths': paths});
    return rows.map(_row).toList(growable: false);
  }

  /// H7: a square JPEG thumbnail ([size] px) made from the file at [path]
  /// (images, videos, audio cover art); null if it has none or doesn't
  /// decode. Runs on its own Kotlin threads.
  Future<Uint8List?> fileThumbnail(String path, int size) =>
      _invoke<Uint8List>('fileThumbnail', {'path': path, 'size': size});

  /// B10: what MediaStore knows about the file at [path] (`id`: its
  /// MediaStore id for `ms:` files): `{exists, mediaId?, dateAdded? (epoch
  /// s), mime?, owner?, relativePath?, downloadUri?, refererUri?, error?}`.
  /// Every key except `exists` may be missing.
  Future<MediaRow> fileDetails(String path, {int? id}) =>
      _invokeRow('fileDetails', {'path': path, 'id': id});

  /// B10: `{label, icon? (PNG bytes)}` of an installed app this app can see
  /// (launcher `<queries>`), or null.
  Future<MediaRow?> appInfo(String packageName) async {
    final row = await _invoke<Map<Object?, Object?>>('appInfo', {
      'package': packageName,
    });
    return row == null ? null : _row(row);
  }

  /// B10: opens the system App info page of [packageName].
  Future<bool> openAppDetails(String packageName) async =>
      (await _invoke<bool>('openAppDetails', {'package': packageName})) ??
      false;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw FilesChannelException(e.code, e.message ?? '');
    }
  }

  Future<List<Map<Object?, Object?>>> _invokeList(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
        method,
        args,
      );
      return list ?? const [];
    } on PlatformException catch (e) {
      throw FilesChannelException(e.code, e.message ?? '');
    }
  }

  Future<MediaRow> _invokeRow(String method, Map<String, Object?> args) async {
    final row = await _invoke<Map<Object?, Object?>>(method, args);
    if (row == null) {
      throw FilesChannelException('IO', '$method returned nothing');
    }
    return _row(row);
  }

  static MediaRow _row(Map<Object?, Object?> raw) => {
    for (final MapEntry(:key, :value) in raw.entries) key! as String: value,
  };
}
