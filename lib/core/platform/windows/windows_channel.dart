import 'dart:async';

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

/// What [WindowsChannel.openFile] / [WindowsChannel.openWith] did
/// (`failed` is thrown as [WindowsChannelException]).
enum ShellOpenResult { opened, noApp, notFound, cancelled, failed }

/// One drive letter ([WindowsChannel.listDrives]). CD drives and empty card
/// reader slots aren't listed.
@immutable
class WindowsDrive {
  const new({
    required this.path,
    required this.isSystem,
    required this.type,
    required this.isRemovable,
    required this.isMounted,
    this.uuid,
    this.label = '',
    this.fileSystem = '',
    this.bus = 'other',
    this.totalBytes,
    this.freeBytes,
  });

  factory fromRow(Map<Object?, Object?> r) {
    String str(Object? v) => v is String ? v : '';
    int? integer(Object? v) => v is int ? v : null;
    return WindowsDrive(
      path: str(r['path']).toUpperCase(),
      isSystem: r['system'] == true,
      type: str(r['type']),
      isRemovable: r['removable'] == true,
      isMounted: r['mounted'] == true,
      uuid: switch (r['uuid']) {
        final String u when u.isNotEmpty => u,
        _ => null,
      },
      label: str(r['label']),
      fileSystem: str(r['fileSystem']),
      bus: switch (r['bus']) {
        final String b when b.isNotEmpty => b,
        _ => 'other',
      },
      totalBytes: integer(r['totalBytes']),
      freeBytes: integer(r['freeBytes']),
    );
  }

  /// `E:` (KFM's form of a drive root).
  final String path;

  /// The drive Windows runs from.
  final bool isSystem;

  /// `removable`, `fixed` or `remote`.
  final String type;

  /// Can be ejected: a removable drive, or a fixed one on USB/SD/FireWire.
  final bool isRemovable;
  final bool isMounted;

  /// Volume serial number `ABCD-1234`; null for network drives.
  final String? uuid;
  final String label;
  final String fileSystem;

  /// `usb`, `sd`, `firewire`, `internal`, `virtual` or `other`.
  final String bus;
  final int? totalBytes;
  final int? freeBytes;

  @override
  bool operator ==(Object other) =>
      other is WindowsDrive &&
      other.path == path &&
      other.isSystem == isSystem &&
      other.type == type &&
      other.isRemovable == isRemovable &&
      other.isMounted == isMounted &&
      other.uuid == uuid &&
      other.label == label &&
      other.fileSystem == fileSystem &&
      other.bus == bus &&
      other.totalBytes == totalBytes &&
      other.freeBytes == freeBytes;

  @override
  int get hashCode => Object.hash(
    path,
    isSystem,
    type,
    isRemovable,
    isMounted,
    uuid,
    label,
    fileSystem,
    bus,
    totalBytes,
    freeBytes,
  );
}

/// Why [WindowsChannel.ejectDrive] didn't eject.
enum DriveEjectError {
  /// A program (maybe Explorer) still has a file open on it.
  inUse,

  /// Not a device Windows can eject (an internal disk).
  notEjectable,
  failed,
}

/// Sleep / wake ([WindowsChannel.events]).
enum PowerState { suspend, resume }

/// Something the native side reports by itself (`WM_DEVICECHANGE`,
/// `WM_POWERBROADCAST`).
@immutable
sealed class WindowsEvent {
  const new();
}

/// A volume arrived or went away: read [WindowsChannel.listDrives] again.
class VolumesChanged extends WindowsEvent {
  const new();
}

class PowerChanged extends WindowsEvent {
  const new(this.state);

  final PowerState state;
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
/// - `openFile {path}` → `{result, message?}`: `ShellExecuteExW` with the
///   default verb (`SEE_MASK_NOASYNC | SEE_MASK_FLAG_NO_UI`); `result` ∈
///   `opened`, `noApp` (`ERROR_NO_ASSOCIATION`), `notFound`, `cancelled`,
///   `failed`.
/// - `openWith {path}` → same shape: `SHOpenWithDialog` (`OAIF_EXEC`), the
///   Windows "Open with" chooser; closing it is `cancelled`.
/// - `networkIsPublic` → bool: `INetworkListManager` → any connected
///   network with category `NLM_NETWORK_CATEGORY_PUBLIC`.
/// - `listDrives` → `[{path: "E:", system, type, removable, mounted, uuid?,
///   label?, fileSystem?, bus?, totalBytes?, freeBytes?}]`
///   (`GetLogicalDrives`, `GetDriveTypeW`, `GetVolumeInformationW`,
///   `IOCTL_STORAGE_QUERY_PROPERTY` for the bus).
/// - `ejectDrive {path}` → `{ok, error?}`: `CM_Request_Device_EjectW` on the
///   disk's parent device; `error` ∈ `inUse`, `notEjectable`, `failed`.
///
/// Calls from the native side (`events`): `volumesChanged` (a volume
/// arrived / was removed) and `power {state: suspend|resume}`.
/// X8: `ITaskbarList3::SetProgressState` states.
enum TaskbarProgress { none, normal, paused, error, indeterminate }

class WindowsChannel {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'com.kaf.kfm/windows';

  final MethodChannel _channel;

  late final StreamController<WindowsEvent> _events =
      StreamController<WindowsEvent>.broadcast(
        onListen: () => _channel.setMethodCallHandler(_onNativeCall),
      );

  /// Native drive and power events. The handler is installed on the first
  /// listen and stays (one channel instance per app).
  Stream<WindowsEvent> get events => _events.stream;

  Future<Object?> _onNativeCall(MethodCall call) async {
    final event = parseWindowsEvent(call.method, call.arguments);
    if (event != null) _events.add(event);
    return null;
  }

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

  /// The file's default app ([ShellOpenResult.noApp] when there is none).
  Future<ShellOpenResult> openFile(String path) => _open('openFile', path);

  /// The Windows "Open with" chooser for [path].
  Future<ShellOpenResult> openWith(String path) => _open('openWith', path);

  Future<ShellOpenResult> _open(String method, String path) async {
    final raw =
        await _call<Map<Object?, Object?>>(method, {'path': toNative(path)}) ??
        const {};
    final result = ShellOpenResult.values.firstWhere(
      (r) => r.name == raw['result'],
      orElse: () => ShellOpenResult.failed,
    );
    if (result == ShellOpenResult.failed) {
      throw WindowsChannelException('OPEN', '${raw['message'] ?? method}');
    }
    return result;
  }

  /// X8: the taskbar button's progress ([value] 0..100; ignored for
  /// [TaskbarProgress.none] and [TaskbarProgress.indeterminate]).
  Future<void> setTaskbarProgress(TaskbarProgress state, [int value = 0]) =>
      _call<void>('setTaskbarProgress', {
        'state': state.name,
        'value': value.clamp(0, 100),
      });

  Future<bool> networkIsPublic() async =>
      await _call<bool>('networkIsPublic') ?? false;

  Future<List<WindowsDrive>> listDrives() async {
    final raw = await _call<List<Object?>>('listDrives') ?? const [];
    return [
      for (final r in raw.whereType<Map<Object?, Object?>>())
        WindowsDrive.fromRow(r),
    ];
  }

  /// Null when Windows ejected the drive.
  Future<DriveEjectError?> ejectDrive(String path) async {
    final raw =
        await _call<Map<Object?, Object?>>('ejectDrive', {
          'path': toNative(path),
        }) ??
        const {};
    if (raw['ok'] == true) return null;
    return DriveEjectError.values.firstWhere(
      (e) => e.name == raw['error'],
      orElse: () => DriveEjectError.failed,
    );
  }
}

@visibleForTesting
WindowsEvent? parseWindowsEvent(String method, Object? args) =>
    switch (method) {
      'volumesChanged' => const VolumesChanged(),
      'power' => switch (args) {
        {'state': 'suspend'} => const PowerChanged(PowerState.suspend),
        {'state': 'resume'} => const PowerChanged(PowerState.resume),
        _ => null,
      },
      _ => null,
    };
