/// File ids of external places (TASK-U1; U2 uses them). The one parser of
/// the `saf:` and `mtp:` formats (see `FileRef.id`).
///
/// - `saf:<treeUri>|<documentId>`: `|` never appears in an encoded tree URI
///   (document ids may hold `/` and `:`, and even `|`: everything after the
///   first `|` is the document id).
/// - `mtp:<usbDeviceName>|<storageId>|<objectHandle>`.
library;

import 'package:meta/meta.dart';

const _safPrefix = 'saf:';
const _mtpPrefix = 'mtp:';

/// A document inside a persisted SAF tree.
@immutable
class SafId {
  const new(this.treeUri, this.documentId);

  final String treeUri;
  final String documentId;

  @override
  bool operator ==(Object other) =>
      other is SafId &&
      other.treeUri == treeUri &&
      other.documentId == documentId;

  @override
  int get hashCode => Object.hash(treeUri, documentId);

  @override
  String toString() => safId(treeUri, documentId);
}

/// An object on an MTP/PTP device.
@immutable
class MtpId {
  const new(this.deviceName, this.storageId, this.objectHandle);

  /// `UsbDevice.getDeviceName()` (e.g. `/dev/bus/usb/001/002`).
  final String deviceName;
  final int storageId;
  final int objectHandle;

  @override
  bool operator ==(Object other) =>
      other is MtpId &&
      other.deviceName == deviceName &&
      other.storageId == storageId &&
      other.objectHandle == objectHandle;

  @override
  int get hashCode => Object.hash(deviceName, storageId, objectHandle);

  @override
  String toString() => mtpId(deviceName, storageId, objectHandle);
}

String safId(String treeUri, String documentId) {
  if (treeUri.isEmpty || treeUri.contains('|')) {
    throw ArgumentError.value(treeUri, 'treeUri', 'empty or contains |');
  }
  return '$_safPrefix$treeUri|$documentId';
}

String mtpId(String deviceName, int storageId, int objectHandle) {
  if (deviceName.isEmpty || deviceName.contains('|')) {
    throw ArgumentError.value(deviceName, 'deviceName', 'empty or contains |');
  }
  return '$_mtpPrefix$deviceName|$storageId|$objectHandle';
}

/// Null when [id] isn't a well-formed `saf:` id.
SafId? parseSafId(String id) {
  if (!id.startsWith(_safPrefix)) return null;
  final rest = id.substring(_safPrefix.length);
  final bar = rest.indexOf('|');
  if (bar <= 0) return null;
  return SafId(rest.substring(0, bar), rest.substring(bar + 1));
}

/// Null when [id] isn't a well-formed `mtp:` id.
MtpId? parseMtpId(String id) {
  if (!id.startsWith(_mtpPrefix)) return null;
  final parts = id.substring(_mtpPrefix.length).split('|');
  if (parts.length != 3 || parts[0].isEmpty) return null;
  final storage = int.tryParse(parts[1]);
  final handle = int.tryParse(parts[2]);
  if (storage == null || handle == null) return null;
  return MtpId(parts[0], storage, handle);
}

final _sharedInCopy = RegExp(r'^/data/(user/\d+|data)/[^/]+/files/shared_in/');

/// X1: a file KFM copied from another app's share (app-private storage,
/// `<filesDir>/shared_in/<receivedAtMs>/…`). Such copies count as being on
/// the primary place and are deleted directly, never trashed.
bool isSharedInCopyPath(String path) => _sharedInCopy.hasMatch(path);
