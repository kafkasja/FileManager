import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:meta/meta.dart';

/// Max `lastAddresses` kept per device (newest first).
const int kMaxKnownAddresses = 3;

/// Temporary rows (kept only to resume a transfer) live this long after
/// `lastSeenAt` (TASK-N6).
const Duration kTemporaryDeviceMaxAge = Duration(days: 7);

/// A shared folder as stored in `allowedRootsJson`: no root id (it is
/// recomputed from the current salt on load; stored ids are never trusted).
@immutable
class StoredRoot {
  const new({required this.path, required this.label, required this.readOnly});

  factory fromSharedRoot(SharedRoot r) =>
      StoredRoot(path: r.path, label: r.label, readOnly: r.readOnly);

  /// Null when malformed.
  static StoredRoot? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final path = json['path'];
    final label = json['label'];
    final readOnly = json['readOnly'];
    if (path is! String || label is! String || readOnly is! bool) return null;
    return StoredRoot(path: path, label: label, readOnly: readOnly);
  }

  final String path;
  final String label;
  final bool readOnly;

  Map<String, Object?> toJson() => {
    'path': path,
    'label': label,
    'readOnly': readOnly,
  };

  @override
  bool operator ==(Object other) =>
      other is StoredRoot &&
      other.path == path &&
      other.label == label &&
      other.readOnly == readOnly;

  @override
  int get hashCode => Object.hash(path, label, readOnly);
}

/// The stored folders of a device after re-checking them on disk.
@immutable
class StoredScope {
  const new({required this.roots, required this.dropped});

  static const StoredScope empty = StoredScope(roots: [], dropped: false);

  /// Re-canonicalised, existing folders with ids for the current salt.
  final List<SharedRoot> roots;

  /// True when stored folders no longer exist (share screen hint).
  final bool dropped;
}

/// A remembered device (TASK-N6). Immutable; the DB row is `KnownDeviceRow`.
@immutable
class KnownDevice {
  const new({
    required this.id,
    required this.peerDeviceId,
    required this.name,
    required this.platform,
    required this.fingerprint,
    required this.lastSeenAt,
    required this.lastAddresses,
    required this.allowedRoots,
    required this.canShareToUs,
    required this.isTemporary,
    required this.autoAccept,
    this.autoAcceptFiles = false,
  });

  /// Local id.
  final String id;
  final String peerDeviceId;
  final String name;
  final String platform;

  /// The peer's `publicKeyFingerprint` (identity).
  final String fingerprint;
  final DateTime lastSeenAt;

  /// `host:port`, newest first.
  final List<String> lastAddresses;
  final List<StoredRoot> allowedRoots;
  final bool canShareToUs;
  final bool isTemporary;
  final bool autoAccept;

  /// N12 "Accept files without asking".
  final bool autoAcceptFiles;

  @override
  bool operator ==(Object other) =>
      other is KnownDevice &&
      other.id == id &&
      other.peerDeviceId == peerDeviceId &&
      other.name == name &&
      other.platform == platform &&
      other.fingerprint == fingerprint &&
      other.lastSeenAt == lastSeenAt &&
      listEquals(other.lastAddresses, lastAddresses) &&
      listEquals(other.allowedRoots, allowedRoots) &&
      other.canShareToUs == canShareToUs &&
      other.isTemporary == isTemporary &&
      other.autoAccept == autoAccept &&
      other.autoAcceptFiles == autoAcceptFiles;

  @override
  int get hashCode => Object.hash(
    id,
    peerDeviceId,
    name,
    platform,
    fingerprint,
    lastSeenAt,
    Object.hashAll(lastAddresses),
    Object.hashAll(allowedRoots),
    canShareToUs,
    isTemporary,
    autoAccept,
    autoAcceptFiles,
  );
}

/// What a finished pairing tells us about the peer (both sides).
@immutable
class PairedPeer {
  const new({
    required this.fingerprint,
    required this.peerDeviceId,
    required this.name,
    required this.platform,
    this.addresses = const [],
    this.canShareToUs = false,
    this.autoAccept,
  });

  final String fingerprint;
  final String peerDeviceId;
  final String name;
  final String platform;

  /// Where the peer was our server (client side); merged, newest first.
  final List<String> addresses;

  /// OR-ed into the row: once true it stays true.
  final bool canShareToUs;

  /// Null keeps the stored value.
  final bool? autoAccept;
}

/// JSON helpers for the text columns.
List<String> decodeAddresses(String json) {
  try {
    final v = jsonDecode(json);
    if (v is! List<Object?>) return const [];
    return List.unmodifiable(v.whereType<String>());
  } on FormatException {
    return const [];
  }
}

List<StoredRoot> decodeStoredRoots(String json) {
  try {
    final v = jsonDecode(json);
    if (v is! List<Object?>) return const [];
    return List.unmodifiable([for (final r in v) ?StoredRoot.tryFromJson(r)]);
  } on FormatException {
    return const [];
  }
}

String encodeStoredRoots(List<StoredRoot> roots) =>
    jsonEncode([for (final r in roots) r.toJson()]);

/// [fresh] first, then [old], without duplicates, at most
/// [kMaxKnownAddresses].
List<String> mergeAddresses(List<String> fresh, List<String> old) {
  final out = <String>[];
  for (final a in [...fresh, ...old]) {
    if (a.isEmpty || out.contains(a)) continue;
    out.add(a);
    if (out.length == kMaxKnownAddresses) break;
  }
  return out;
}
