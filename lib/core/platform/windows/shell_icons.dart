import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

/// Extensions whose icon belongs to the file itself (TASK-E3): asked per
/// path. Everything else is asked per extension (no disk access).
const Set<String> perPathIconExtensions = {
  '.exe',
  '.lnk',
  '.ico',
  '.url',
  '.scr',
  '.cpl',
  '.msc',
};

/// The shell image list sizes, physical pixels.
const List<int> shellIconSizes = [16, 32, 48, 256];

/// The shell size for an icon drawn [logical] px wide at [devicePixelRatio].
int shellIconPx(double logical, double devicePixelRatio) {
  final physical = logical * devicePixelRatio;
  for (final s in shellIconSizes) {
    if (s >= physical) return s;
  }
  return shellIconSizes.last;
}

/// What one shell icon request is: `ext:.pdf`, `path:c:/users/x/app.exe`,
/// `folder`, at [px] physical pixels.
@immutable
class ShellIconKey {
  const new _(this.kind, this.value, this.px);

  /// A file: per extension, or per path for [perPathIconExtensions].
  factory file(String path, int px) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    final dot = name.lastIndexOf('.');
    final ext = dot <= 0 ? '' : name.substring(dot).toLowerCase();
    if (perPathIconExtensions.contains(ext)) {
      return ShellIconKey._(ShellIconKind.path, path.toLowerCase(), px);
    }
    return ShellIconKey._(ShellIconKind.ext, ext, px);
  }

  /// A folder: the generic folder icon, or its own for [special] ones
  /// (known folders like Downloads, which Windows draws differently).
  factory folder(String path, int px, {Set<String> special = const {}}) {
    final lower = path.toLowerCase();
    if (special.contains(lower)) {
      return ShellIconKey._(ShellIconKind.path, lower, px);
    }
    return ShellIconKey._(ShellIconKind.folder, '', px);
  }

  /// A drive root (`C:`).
  factory drive(String root, int px) =>
      ShellIconKey._(ShellIconKind.drive, root.toUpperCase(), px);

  final ShellIconKind kind;
  final String value;
  final int px;

  /// `ext:.pdf` / `path:…` / `folder` / `drive:C:` (tests, logs).
  String get id => switch (kind) {
    ShellIconKind.folder => 'folder',
    _ => '${kind.name}:$value',
  };

  @override
  bool operator ==(Object other) =>
      other is ShellIconKey &&
      other.kind == kind &&
      other.value == value &&
      other.px == px;

  @override
  int get hashCode => Object.hash(kind, value, px);

  @override
  String toString() => 'ShellIconKey($id@$px)';
}

enum ShellIconKind { ext, path, folder, drive }

/// Asks the shell for one icon's PNG.
typedef ShellIconFetch = Future<Uint8List?> Function(ShellIconKey key);

/// The Windows channel as a [ShellIconFetch].
ShellIconFetch channelIconFetch(WindowsChannel channel) =>
    (key) => switch (key.kind) {
      ShellIconKind.ext => channel.fileIcon(ext: key.value, px: key.px),
      ShellIconKind.path => channel.fileIcon(path: key.value, px: key.px),
      ShellIconKind.folder => channel.fileIcon(folder: true, px: key.px),
      ShellIconKind.drive => channel.fileIcon(
        path: key.value,
        drive: true,
        px: key.px,
      ),
    };

/// In-memory LRU of shell icon PNGs (TASK-E3): [capacity] entries,
/// in-flight requests shared, failures (null, error or [timeout]) cached
/// for the run so a broken icon isn't asked again. No disk cache: an
/// ext-keyed icon takes about a millisecond.
class ShellIconCache {
  new(
    this._fetch, {
    this.capacity = 512,
    this.timeout = const Duration(seconds: 1),
  });

  final ShellIconFetch _fetch;
  final int capacity;
  final Duration timeout;

  // Insertion order = the LRU order.
  final LinkedHashMap<ShellIconKey, Uint8List> _done = LinkedHashMap();
  final Set<ShellIconKey> _failed = {};
  final Map<ShellIconKey, Future<Uint8List?>> _inFlight = {};

  /// Fetches so far (tests).
  @visibleForTesting
  int fetches = 0;

  /// Already known: the PNG, or null after a failure / when not asked yet.
  Uint8List? peek(ShellIconKey key) {
    final hit = _done.remove(key);
    if (hit != null) _done[key] = hit;
    return hit;
  }

  bool hasFailed(ShellIconKey key) => _failed.contains(key);

  Future<Uint8List?> get(ShellIconKey key) {
    if (peek(key) case final hit?) return SynchronousFuture(hit);
    if (_failed.contains(key)) return SynchronousFuture(null);
    return _inFlight[key] ??= _load(key);
  }

  Future<Uint8List?> _load(ShellIconKey key) async {
    fetches++;
    Uint8List? bytes;
    try {
      bytes = await _fetch(key).timeout(timeout);
    } on Object {
      bytes = null;
    } finally {
      _inFlight.remove(key)?.ignore();
    }
    if (bytes == null || bytes.isEmpty) {
      _failed.add(key);
      return null;
    }
    _done[key] = bytes;
    while (_done.length > capacity) {
      _done.remove(_done.keys.first);
    }
    return bytes;
  }
}

/// A shell icon as an image (errors when Windows has none, so callers
/// show their fallback icon).
@immutable
class ShellIconImage extends ImageProvider<ShellIconKey> {
  const new(this.key, this.cache);

  final ShellIconKey key;
  final ShellIconCache cache;

  @override
  Future<ShellIconKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(key);

  @override
  ImageStreamCompleter loadImage(
    ShellIconKey key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(decode));

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    final bytes = await cache.get(key);
    if (bytes == null) throw StateError('no shell icon for $key');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }

  @override
  bool operator ==(Object other) =>
      other is ShellIconImage && other.key == key && other.cache == cache;

  @override
  int get hashCode => Object.hash(key, cache);
}
