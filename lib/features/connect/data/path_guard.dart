import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A request target the allow-list refuses. [code] is `forbidden_path`
/// (403) or `not_found` (404).
@immutable
class GuardRejection implements Exception {
  const new(this.code, [this.reason = '']);

  final ApiErrorCode code;

  /// For logs and tests only; never sent to the peer.
  final String reason;

  @override
  String toString() => 'GuardRejection(${code.wire}: $reason)';
}

/// Resolves symbolic links of an existing [path]; null when nothing exists
/// there.
typedef SymlinkResolver = Future<String?> Function(String path);

Future<String?> _resolveOnDisk(String path) async {
  if (await FileSystemEntity.type(path, followLinks: false) ==
      FileSystemEntityType.notFound) {
    return null;
  }
  return await Directory(path).resolveSymbolicLinks();
}

/// A file the guard resolved through the server's own [FileSource].
@immutable
class GuardedFile {
  const new(this.ref, this.canonicalPath);

  /// Fresh metadata from the server (never from the request).
  final FileRef ref;

  /// Canonical absolute path of the file itself.
  final String canonicalPath;

  String get canonicalFolder => p.posix.dirname(canonicalPath);
}

/// Path canonicalisation, file-id resolution, exclusion rules and root ids
/// of the folder allow-list (TASK-N4). Paths are always '/'-separated.
/// Android only for now; Windows drive letters/case come with PL1.
class PathGuard {
  new({SymlinkResolver? resolver, Map<String, String>? aliases})
    : _resolve = resolver ?? _resolveOnDisk,
      _aliases = aliases ?? kAndroidPathAliases;

  final SymlinkResolver _resolve;
  final Map<String, String> _aliases;

  /// Other spellings of the primary volume that `resolveSymbolicLinks` may
  /// return; mapped back to the `/storage/emulated/0` form F3 uses.
  static const Map<String, String> kAndroidPathAliases = {
    '/storage/self/primary': '/storage/emulated/0',
    '/sdcard': '/storage/emulated/0',
    '/mnt/sdcard': '/storage/emulated/0',
    '/data/media/0': '/storage/emulated/0',
    '/mnt/user/0/emulated/0': '/storage/emulated/0',
  };

  /// The canonical form of absolute [path]: no NUL or `\`, normalised
  /// (`..`, `.`, `//`, trailing '/' removed), symbolic links resolved (for a
  /// missing leaf: the existing parent is resolved and the rest
  /// re-appended), volume aliases mapped back.
  Future<String> canonicalise(String path) async {
    if (path.contains('\u0000')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'NUL');
    }
    if (path.contains(r'\')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'backslash');
    }
    if (!path.startsWith('/')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'relative');
    }
    final normalised = p.posix.normalize(path);
    final resolved = _unalias(
      p.posix.normalize(await _resolveExisting(normalised)),
    );
    if (!resolved.startsWith('/') || resolved.contains(r'\')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'resolved');
    }
    return resolved;
  }

  Future<String> _resolveExisting(String path) async {
    final r = await _resolve(path);
    if (r != null) return r.replaceAll(r'\', '/');
    final parent = p.posix.dirname(path);
    if (parent == path) return path;
    return p.posix.join(await _resolveExisting(parent), p.posix.basename(path));
  }

  String _unalias(String path) {
    for (final e in _aliases.entries) {
      if (path == e.key) return e.value;
      if (path.startsWith('${e.key}/')) {
        return '${e.value}${path.substring(e.key.length)}';
      }
    }
    return path;
  }

  /// `[root path]/[relativePath]` canonicalised; must stay inside [root].
  Future<String> joinRelative(SharedRoot root, String relativePath) async {
    if (relativePath.startsWith('/')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'absolute');
    }
    if (relativePath.contains('\u0000') || relativePath.contains(r'\')) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'chars');
    }
    final joined = relativePath.isEmpty
        ? root.path
        : '${root.path}/$relativePath';
    final canonical = await canonicalise(joined);
    if (!isInside(canonical, root.path)) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'escapes root');
    }
    return canonical;
  }

  /// Resolves a client-sent file id through the server's [source]. Only
  /// `path:` and `ms:` ids exist on the server. The path of an `ms:` id
  /// comes from MediaStore, never from the request.
  ///
  /// A `path:` id must already be canonical. [inScope] (throws a
  /// [GuardRejection]) runs on the raw path before the disk is touched, so
  /// out-of-scope paths are 403 whether or not they exist (no existence
  /// or symlink oracle); only in-scope unknown files are 404.
  Future<GuardedFile> resolveFileId(
    String id,
    FileSource source, {
    void Function(String path)? inScope,
  }) async {
    if (id.startsWith('path:')) {
      final raw = id.substring('path:'.length);
      if (raw.contains('\u0000') ||
          raw.contains(r'\') ||
          !raw.startsWith('/') ||
          p.posix.normalize(raw) != raw) {
        throw const GuardRejection(ApiErrorCode.forbiddenPath, 'not canonical');
      }
      inScope?.call(raw);
      final canonical = await canonicalise(raw);
      if (canonical != raw) {
        throw const GuardRejection(ApiErrorCode.forbiddenPath, 'not canonical');
      }
      final ref = await source.stat(id);
      if (ref == null) throw const GuardRejection(ApiErrorCode.notFound);
      return GuardedFile(ref, canonical);
    }
    if (id.startsWith('ms:')) {
      // MediaStore ids are small integers; whether one exists reveals no
      // path, so an unknown one stays 404.
      final ref = await source.stat(id);
      if (ref == null) throw const GuardRejection(ApiErrorCode.notFound);
      final folder = await canonicalise(ref.folderPath);
      final path = p.posix.join(folder, ref.name);
      inScope?.call(path);
      return GuardedFile(ref, path);
    }
    throw const GuardRejection(ApiErrorCode.forbiddenPath, 'id scheme');
  }

  /// Locations no client ever sees, even inside an allowed root or with the
  /// whole storage shared: any segment starting with '.' (`.KFMTrash`,
  /// `.thumbnails`, partial-upload folders, dot-files) and `Android/data`,
  /// `Android/obb` (case-insensitive: Android's shared storage is).
  static bool isExcluded(String canonicalPath) {
    final segments = canonicalPath.split('/');
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.startsWith('.')) return true;
      if (s.toLowerCase() == 'android' && i + 1 < segments.length) {
        final next = segments[i + 1].toLowerCase();
        if (next == 'data' || next == 'obb') return true;
      }
    }
    return false;
  }

  /// Whether [path] is [folder] or below it (prefix-collision safe).
  /// Case-insensitive: Android's shared storage (and Windows) is, so
  /// `dcim/x` must not slip past a read-only `DCIM` root.
  static bool isInside(String path, String folder) {
    final a = path.toLowerCase();
    final b = folder.toLowerCase();
    return a == b || a.startsWith(b == '/' ? '/' : '$b/');
  }

  /// Defence in depth for listings: whether [f] (from the server's own
  /// index, so already canonical) is visible under [scope].
  static bool isVisible(ShareScope scope, FileRef f) =>
      !isExcluded(f.path) && scope.rootFor(f.folderPath) != null;

  /// Stable opaque root id: `base64url(sha256(salt ‖ utf8(path)))`, 16
  /// characters. Same folder + same identity → same id across runs.
  static String rootId(List<int> salt, String canonicalPath) {
    final digest = crypto.sha256.convert([
      ...salt,
      ...utf8.encode(canonicalPath.toLowerCase()),
    ]);
    return b64url(digest.bytes).substring(0, 16);
  }
}
