import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:meta/meta.dart';

/// What kind of storage a place is (TASK-U1). Android doesn't say SD vs
/// USB publicly: best effort from the description and attached USB devices.
enum PlaceKind { internal, sdCard, usbDrive, camera, unknown }

/// How KFM reaches a place's files.
enum AccessMethod { directPath, saf, mtp, none }

/// The id of internal storage.
const kInternalPlaceId = 'primary';

const _mtpPlacePrefix = 'mtp:';

/// A storage place: internal storage, an SD card, a USB drive or a camera.
/// Compared by value; [id] is the stable key (U2's source id is
/// `external:<id>`).
@immutable
class StoragePlace {
  const new({
    required this.id,
    required this.label,
    required this.kind,
    required this.access,
    required this.isMounted,
    this.rootPath,
    this.treeUri,
    this.totalBytes,
    this.freeBytes,
    this.needsPermission = false,
    this.isUnsupported = false,
    this.mountedAt,
  });

  /// [kInternalPlaceId], the volume uuid (e.g. `1234-ABCD`) or
  /// `mtp:<usbDeviceName>`.
  final String id;

  /// The volume description or the camera name ('' = unknown).
  final String label;
  final PlaceKind kind;
  final AccessMethod access;
  final bool isMounted;

  /// directPath and saf on Android (e.g. `/storage/1234-ABCD`); null for
  /// mtp and unmounted volumes. The join key with
  /// `pending_folder_items.volumeId` and `media_index` paths.
  final String? rootPath;

  /// saf only: the persisted grant, null until the user granted it.
  final String? treeUri;
  final int? totalBytes;
  final int? freeBytes;

  /// mtp: the USB permission isn't granted yet.
  final bool needsPermission;

  /// mtp: the camera couldn't be opened (another app holds it, or the
  /// phone doesn't allow it).
  final bool isUnsupported;

  /// U2 (h): when the volume was mounted (see `VolumeInfo.mountedAt`).
  final DateTime? mountedAt;

  bool get isRemovable => kind != PlaceKind.internal;

  /// The volume uuid (removable volumes), else null.
  String? get volumeUuid =>
      kind == PlaceKind.internal ||
          kind == PlaceKind.camera ||
          id.startsWith(_mtpPlacePrefix)
      ? null
      : id;

  /// SAF places need the one-time tree grant before they open.
  bool get needsGrant => access == AccessMethod.saf && treeUri == null;

  StoragePlace copyWith({
    String? label,
    PlaceKind? kind,
    AccessMethod? access,
    bool? isMounted,
    String? Function()? rootPath,
    String? Function()? treeUri,
    int? Function()? totalBytes,
    int? Function()? freeBytes,
    bool? needsPermission,
    bool? isUnsupported,
  }) => StoragePlace(
    id: id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    access: access ?? this.access,
    isMounted: isMounted ?? this.isMounted,
    rootPath: rootPath == null ? this.rootPath : rootPath(),
    treeUri: treeUri == null ? this.treeUri : treeUri(),
    totalBytes: totalBytes == null ? this.totalBytes : totalBytes(),
    freeBytes: freeBytes == null ? this.freeBytes : freeBytes(),
    needsPermission: needsPermission ?? this.needsPermission,
    isUnsupported: isUnsupported ?? this.isUnsupported,
    mountedAt: mountedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is StoragePlace &&
      other.id == id &&
      other.label == label &&
      other.kind == kind &&
      other.access == access &&
      other.isMounted == isMounted &&
      other.rootPath == rootPath &&
      other.treeUri == treeUri &&
      other.totalBytes == totalBytes &&
      other.freeBytes == freeBytes &&
      other.needsPermission == needsPermission &&
      other.isUnsupported == isUnsupported &&
      other.mountedAt == mountedAt;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    kind,
    access,
    isMounted,
    rootPath,
    treeUri,
    totalBytes,
    freeBytes,
    needsPermission,
    isUnsupported,
    mountedAt,
  );

  @override
  String toString() => 'StoragePlace($id, $kind, $access, mounted: $isMounted)';
}

/// The places list: internal storage first, then removable volumes in the
/// system's order, then cameras.
///
/// Access: primary → directPath; removable on API 30+ with All files
/// access → directPath; other removable → saf (API ≤ 29 can't write by
/// path); cameras → mtp. [safGrants] maps volume uuid → tree URI.
List<StoragePlace> buildPlaces({
  required List<VolumeInfo> volumes,
  required List<UsbCamera> cameras,
  required Map<String, String> safGrants,
  required bool canSeeAllFiles,
  required int sdkInt,
}) {
  final internal = <StoragePlace>[];
  final removable = <StoragePlace>[];
  for (final v in volumes) {
    if (v.isPrimary) {
      internal.add(
        StoragePlace(
          id: kInternalPlaceId,
          label: v.description,
          kind: PlaceKind.internal,
          access: AccessMethod.directPath,
          isMounted: v.isMounted,
          rootPath: v.rootPath,
          totalBytes: v.totalBytes,
          freeBytes: v.freeBytes,
        ),
      );
      continue;
    }
    final id = v.uuid;
    if (id == null) continue; // No stable key (never seen on a device).
    final direct = sdkInt >= 30 && canSeeAllFiles;
    removable.add(
      StoragePlace(
        id: id,
        label: v.description,
        kind: v.isFixed ? PlaceKind.internal : placeKindOf(v),
        access: direct ? AccessMethod.directPath : AccessMethod.saf,
        isMounted: v.isMounted,
        rootPath: v.rootPath,
        treeUri: direct ? null : safGrants[id],
        totalBytes: v.totalBytes,
        freeBytes: v.freeBytes,
        mountedAt: v.mountedAt,
      ),
    );
  }
  return [
    ...internal,
    ...removable,
    for (final c in cameras)
      StoragePlace(
        id: '$_mtpPlacePrefix${c.deviceName}',
        label: c.name,
        kind: PlaceKind.camera,
        access: AccessMethod.mtp,
        isMounted: true,
        needsPermission: !c.hasPermission,
        isUnsupported: c.supported == false,
      ),
  ];
}

final _sdWord = RegExp(r'\b(sd|microsd)\b', caseSensitive: false);
final _usbWord = RegExp(r'\busb\b', caseSensitive: false);

/// AOSP describes volumes as "`<vendor>` SD card" / "`<vendor>` USB drive"
/// (Samsung: "SD card", "USB storage"); otherwise an attached USB
/// mass-storage device makes it a USB drive.
PlaceKind placeKindOf(VolumeInfo v) {
  if (v.isPrimary) return PlaceKind.internal;
  if (v.bus == 'sd') return PlaceKind.sdCard;
  if (v.bus == 'usb') return PlaceKind.usbDrive;
  if (_usbWord.hasMatch(v.description)) return PlaceKind.usbDrive;
  if (_sdWord.hasMatch(v.description)) return PlaceKind.sdCard;
  if (v.usbMassStorage) return PlaceKind.usbDrive;
  return PlaceKind.unknown;
}

/// Mounted roots of places reached by path (D4's `PendingFolder.reconcile`).
List<String> mountedDirectPathRoots(List<StoragePlace> places) => [
  for (final p in places)
    if (p.isMounted && p.access == AccessMethod.directPath) ?p.rootPath,
];
