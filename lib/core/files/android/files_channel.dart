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

  final MethodChannel _channel;

  Future<int> sdkInt() async => (await _invoke<int>('sdkInt'))!;

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

  /// `{path, label?, removable, primary}` per mounted volume (U1).
  Future<List<MediaRow>> storageVolumes() async {
    final rows = await _invokeList('storageVolumes');
    return rows.map(_row).toList(growable: false);
  }

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
