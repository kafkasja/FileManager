import 'dart:convert';

import 'package:kfm/core/files/file_op_exception.dart';

/// Splits "photo.jpg" into ("photo", ".jpg"); dot-files keep their name.
(String, String) splitExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return (name, '');
  return (name.substring(0, dot), name.substring(dot));
}

/// [name], or the first free `name (1).ext`, `name (2).ext`… for which
/// [exists] returns false. Never overwrites.
Future<String> uniqueName(
  String name,
  Future<bool> Function(String candidate) exists,
) async {
  if (!await exists(name)) return name;
  final (base, ext) = splitExtension(name);
  for (var i = 1; ; i++) {
    final candidate = '$base ($i)$ext';
    if (!await exists(candidate)) return candidate;
  }
}

/// Name prefix of KFM's unfinished copies (B4, `TempFileLedger`). Hidden
/// (dot) and skipped by the walker.
const tempFilePrefix = '.kfm-tmp-';

/// Longest name the file systems take (ext4, FAT/exFAT via FUSE), in UTF-8
/// bytes.
const maxFileNameBytes = 255;

/// Characters shared storage (FAT/exFAT, Windows) refuses in a name.
final _forbidden = RegExp(r'[/\\:*?"<>|\x00-\x1F]');

/// For names the user types (rename/new-folder dialogs, `createFolder`).
/// Throws `invalidName` for names that can't be a single path segment on
/// every volume: empty, `.`/`..`, any of `/ \ : * ? " < > |`, control
/// characters, or more than [maxFileNameBytes] UTF-8 bytes.
///
/// FileSource `rename`/`renameFolder` only use [checkPathSegment]: undo must
/// be able to restore a name that already exists on disk (`What?.pdf`).
void validateFileName(String name) {
  if (name.trim().isEmpty ||
      name == '.' ||
      name == '..' ||
      _forbidden.hasMatch(name) ||
      utf8.encode(name).length > maxFileNameBytes) {
    throw FileOpException(FileOpFailure.invalidName, 'invalid name: "$name"');
  }
}

/// N9: a folder name made from a name another device chose (its display
/// name for `Download/<device>`). Forbidden characters (see
/// [validateFileName]) become `_`, spaces and dots are trimmed from both
/// ends (so `..` can't climb), capped at 64 characters; empty → `Device`.
String safeFolderName(String raw) {
  var s = raw.replaceAll(_forbidden, '_');
  s = s.replaceAll(RegExp(r'^[\s.]+|[\s.]+$'), '');
  if (s.length > 64) {
    s = s.substring(0, 64).replaceAll(RegExp(r'[\s.]+$'), '');
  }
  return s.isEmpty ? 'Device' : s;
}

/// Lenient check for FileSource renames: throws `invalidName` only for names
/// that can't be one path segment at all: empty (or only spaces), `.`/`..`,
/// containing `/` or NUL, or more than [maxFileNameBytes] UTF-8 bytes.
/// Anything else the file system refuses fails as an I/O error.
void checkPathSegment(String name) {
  if (name.trim().isEmpty ||
      name == '.' ||
      name == '..' ||
      name.contains('/') ||
      name.contains('\u0000') ||
      utf8.encode(name).length > maxFileNameBytes) {
    throw FileOpException(FileOpFailure.invalidName, 'invalid name: "$name"');
  }
}

/// Absolute '/'-separated folder of [path], without trailing '/'.
String parentOf(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}

/// Last segment of [path].
String nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);

/// True if any folder segment of [path] below [root] starts with '.'.
bool isInHiddenFolder(String path, {String root = ''}) {
  final rel = path.startsWith(root) ? path.substring(root.length) : path;
  final segments = rel.split('/');
  // The last segment is the file itself.
  for (var i = 0; i < segments.length - 1; i++) {
    if (segments[i].startsWith('.')) return true;
  }
  return false;
}
