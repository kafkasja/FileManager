import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Known folders the index uses by default on Windows (TASK-PL1).
enum KnownFolder { pictures, videos, downloads, documents }

/// Why one file of a Recycle Bin operation failed (wire values of the
/// `error` field below).
enum BinError { inUse, notFound, permissionDenied, noTrash, ioError }

/// One file of a [WindowsChannel.recycle] call.
@immutable
class RecycleResult {
  const new({required this.path, this.trashId, this.error, this.message});

  /// '/'-separated, as passed in.
  final String path;

  /// The bin item's parsing name; null when [error] is set.
  final String? trashId;
  final BinError? error;
  final String? message;
}

/// One Recycle Bin item ([WindowsChannel.listBin]).
@immutable
class BinItem {
  const new({
    required this.trashId,
    required this.originalPath,
    required this.sizeBytes,
    required this.deletedAt,
    required this.modifiedAt,
  });

  final String trashId;

  /// '/'-separated path the file had before it was deleted.
  final String originalPath;
  final int sizeBytes;

  /// UTC.
  final DateTime deletedAt;

  /// UTC; the deleted date when the bin doesn't know it.
  final DateTime modifiedAt;
}

/// One item of [WindowsChannel.restoreFromBin]: the path it was restored
/// to, or why not.
@immutable
class BinRestoreResult {
  const new({required this.trashId, this.path, this.error, this.message});

  final String trashId;

  /// '/'-separated; may differ from the original (a name clash gets
  /// ` (1)`).
  final String? path;
  final BinError? error;
  final String? message;
}

/// Thrown when the native side isn't there (the C++ channel isn't built
/// yet, or a test without a fake) or answers with a platform error.
class WindowsChannelException implements Exception {
  const new(this.code, this.message);

  final String code;
  final String? message;

  @override
  String toString() => 'WindowsChannelException($code): $message';
}

/// Dart side of the method channel `com.kaf.kfm/windows` (TASK-PL1,
/// `windows/runner/windows_channel.cpp`, registered in
/// `flutter_window.cpp`; work runs on a background thread, COM initialised
/// STA per thread).
///
/// Paths cross the channel as native Windows paths (backslashes); this
/// wrapper converts them from and to KFM's '/'-separated form. Every time
/// is milliseconds since the epoch, UTC. A missing native side throws
/// [WindowsChannelException] with code `MISSING`.
///
/// Native method spec (arguments → result):
/// - `knownFolders` → `{pictures, videos, downloads, documents: String?}`
///   via `SHGetKnownFolderPath` (`FOLDERID_Pictures`, `_Videos`,
///   `_Downloads`, `_Documents`; OneDrive-redirected paths as resolved).
/// - `binAvailable {paths: [String]}` → `{path: bool}` per path: false when
///   the volume has no usable Recycle Bin (`SHQueryRecycleBinW` on the
///   volume root fails, or `GetDriveTypeW` says network/remote/CD).
/// - `recycle {paths: [String]}` → `[{path, trashId?, error?, message?}]`,
///   one entry per path in order. ONE `IFileOperation` with
///   `FOFX_RECYCLEONDELETE | FOF_NOCONFIRMATION | FOF_SILENT |
///   FOF_NOERRORUI` for all paths; an `IFileOperationProgressSink` collects
///   per item `PostDeleteItem(hrDelete, psiNewlyCreated)`: `trashId` = the
///   parsing name (`SIGDN_DESKTOPABSOLUTEPARSING`) of `psiNewlyCreated`;
///   failures as `error`: `inUse` (`ERROR_SHARING_VIOLATION`/
///   `ERROR_LOCK_VIOLATION`, `COPYENGINE_E_SHARING_VIOLATION_SRC`),
///   `notFound`, `permissionDenied` (`E_ACCESSDENIED`), `noTrash` (the item
///   would be deleted permanently: `COPYENGINE_S_USER_IGNORED`/no bin),
///   `ioError` otherwise. One locked file never stops the others
///   (`FOFX_EARLYFAILURE` off).
/// - `listBin` → `[{trashId, originalPath, size, deletedAt, modifiedAt?}]`:
///   `IShellFolder2` over `FOLDERID_RecycleBinFolder`; `originalPath` =
///   `PKEY_ItemPathDisplay`-style original location
///   (`SCID_ORIGINAL_LOCATION` + display name), `deletedAt` =
///   `SCID_DATE_DELETED`, `size` = `PKEY_Size`.
/// - `restoreFromBin {trashIds: [String]}` → `[{trashId, path?, error?,
///   message?}]`: one `IFileOperation` moving every bin item back to its
///   original folder (`FOF_RENAMEONCOLLISION`: a taken name gets a new
///   one; `path` = where it landed, from `PostMoveItem`).
/// - `deleteFromBin {trashIds: [String]}` → null: one `IFileOperation`
///   `DeleteItems` without `FOFX_RECYCLEONDELETE` (permanent).
/// - `thumbnail {path, size}` → PNG bytes or null:
///   `IShellItemImageFactory::GetImage(SIIGBF_THUMBNAILONLY |
///   SIIGBF_BIGGERSIZEOK)`, longest side `size` px; null when Windows has no
///   thumbnail (missing HEIF codec…).
/// - `networkIsPublic` → bool: `INetworkListManager` → any connected
///   network with category `NLM_NETWORK_CATEGORY_PUBLIC`.
class WindowsChannel {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'com.kaf.kfm/windows';

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException catch (e) {
      throw WindowsChannelException('MISSING', e.message);
    } on PlatformException catch (e) {
      throw WindowsChannelException(e.code, e.message);
    }
  }

  static String toNative(String path) => path.replaceAll('/', r'\');
  static String fromNative(String path) => path.replaceAll(r'\', '/');

  static BinError? _error(Object? wire) => switch (wire) {
    final String s => BinError.values.firstWhere(
      (e) => e.name == s,
      orElse: () => BinError.ioError,
    ),
    _ => null,
  };

  static DateTime _time(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms is int ? ms : 0, isUtc: true);

  Future<Map<KnownFolder, String>> knownFolders() async {
    final raw = await _call<Map<Object?, Object?>>('knownFolders') ?? const {};
    return {
      for (final k in KnownFolder.values)
        if (raw[k.name] case final String p when p.isNotEmpty) k: fromNative(p),
    };
  }

  Future<Map<String, bool>> binAvailable(List<String> paths) async {
    final raw =
        await _call<Map<Object?, Object?>>('binAvailable', {
          'paths': [for (final p in paths) toNative(p)],
        }) ??
        const {};
    return {for (final p in paths) p: raw[toNative(p)] == true};
  }

  Future<List<RecycleResult>> recycle(List<String> paths) async {
    final raw =
        await _call<List<Object?>>('recycle', {
          'paths': [for (final p in paths) toNative(p)],
        }) ??
        const [];
    return [
      for (final r in raw.whereType<Map<Object?, Object?>>())
        RecycleResult(
          path: fromNative(r['path']! as String),
          trashId: r['trashId'] as String?,
          error: _error(r['error']),
          message: r['message'] as String?,
        ),
    ];
  }

  Future<List<BinItem>> listBin() async {
    final raw = await _call<List<Object?>>('listBin') ?? const [];
    return [
      for (final r in raw.whereType<Map<Object?, Object?>>())
        BinItem(
          trashId: r['trashId']! as String,
          originalPath: fromNative(r['originalPath']! as String),
          sizeBytes: (r['size'] as int?) ?? 0,
          deletedAt: _time(r['deletedAt']),
          modifiedAt: _time(r['modifiedAt'] ?? r['deletedAt']),
        ),
    ];
  }

  Future<List<BinRestoreResult>> restoreFromBin(List<String> trashIds) async {
    final raw =
        await _call<List<Object?>>('restoreFromBin', {'trashIds': trashIds}) ??
        const [];
    return [
      for (final r in raw.whereType<Map<Object?, Object?>>())
        BinRestoreResult(
          trashId: r['trashId']! as String,
          path: switch (r['path']) {
            final String p => fromNative(p),
            _ => null,
          },
          error: _error(r['error']),
          message: r['message'] as String?,
        ),
    ];
  }

  Future<void> deleteFromBin(List<String> trashIds) =>
      _call<void>('deleteFromBin', {'trashIds': trashIds});

  Future<Uint8List?> thumbnail(String path, int size) =>
      _call<Uint8List>('thumbnail', {'path': toNative(path), 'size': size});

  Future<bool> networkIsPublic() async =>
      await _call<bool>('networkIsPublic') ?? false;
}
