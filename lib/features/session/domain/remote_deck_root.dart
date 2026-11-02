import 'dart:convert';

import 'package:meta/meta.dart';

/// The folder a remote swipe session swipes (TASK-N8), stored as the
/// session's `filter` JSON (`{"remote": {...}}`; remote sessions have no P5
/// filter). [device] is the name shown while the device isn't connected.
@immutable
class RemoteDeckRoot {
  const new({required this.rootId, this.path = '', this.device = ''});

  /// Null for anything that isn't a remote root (a P5 filter, bad JSON).
  static RemoteDeckRoot? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final j = jsonDecode(json);
      if (j is! Map<String, Object?>) return null;
      final r = j['remote'];
      if (r is! Map<String, Object?>) return null;
      final rootId = r['rootId'];
      final path = r['path'] ?? '';
      final device = r['device'] ?? '';
      if (rootId is! String || rootId.isEmpty) return null;
      if (path is! String || device is! String) return null;
      return RemoteDeckRoot(rootId: rootId, path: path, device: device);
    } on FormatException {
      return null;
    }
  }

  /// The other device's shared root id (N4).
  final String rootId;

  /// Relative to the root; `''` = the root itself. Subfolders are included.
  final String path;
  final String device;

  Map<String, Object?> toJson() => {
    'remote': {'rootId': rootId, 'path': path, 'device': device},
  };

  @override
  bool operator ==(Object other) =>
      other is RemoteDeckRoot &&
      other.rootId == rootId &&
      other.path == path &&
      other.device == device;

  @override
  int get hashCode => Object.hash(rootId, path, device);
}
