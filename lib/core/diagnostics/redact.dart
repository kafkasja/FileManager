import 'dart:convert';

import 'package:crypto/crypto.dart';

/// H5: hides folder and file names in error-log text.
///
/// - `/storage/emulated/<n>/A/B/c.jpg` → `[int]/A/#3f9a1c/#9b2e07.jpg`: the
///   first folder is kept (it helps debugging), deeper segments and the file
///   name become `#` + 6 hex of SHA-256(salt + segment); the extension stays.
/// - `/storage/XXXX-XXXX/…` → `[sd]/…`, `/sdcard/…` and
///   `/storage/self/primary/…` → `[int]/…` (same rule).
/// - `/data/user/<n>/com.kaf.kfm/…` and `/data/data/com.kaf.kfm/…` →
///   `[app]/…` (KFM's own files, kept).
/// - Any other absolute path keeps its first segment and hashes the rest.
/// - URIs (`content://…`, `file://…`), `ms:<id>` ids, `package:` frames and
///   Windows paths are left alone; `path:` ids go through the path rule.
///
/// Pure: the same [salt] maps the same name to the same token.
String redactForLog(String text, String salt) =>
    text.replaceAllMapped(_absolutePath, (m) {
      final lead = m[1]!;
      final path = m[2]!;
      return '$lead${_redactPath(path, salt)}';
    });

/// An absolute path starting at a boundary (line start, whitespace, quote,
/// bracket, `=`, or `:` after a word as in `path:/…`), so
/// `package:kfm/a/b.dart`, `content://a/b` and `file:///C:/src` (slash
/// after a word char, a slash or a drive letter) don't match.
/// Segments may hold spaces but stop at quotes, brackets, `:`, `,`, `;` and
/// line ends.
final _absolutePath = RegExp(
  r'''(^|[\s'"(\[{<=]|(?<=[A-Za-z]{2}):)(/[^\s/'"()\[\]{}<>:,;][^/\n\r\t'"()\[\]{}<>:,;]*(?:/[^/\n\r\t'"()\[\]{}<>:,;]*)*)''',
  multiLine: true,
);

final _appDir = RegExp(r'^/data/(?:user/\d+|data)/com\.kaf\.kfm(?=/|$)');
final _internal = RegExp(
  r'^/(?:storage/emulated/\d+|storage/self/primary|sdcard|mnt/sdcard)(?=/|$)',
);
final _sd = RegExp(r'^/storage/[^/]+(?=/|$)');
final _extension = RegExp(r'^(.+)\.([A-Za-z0-9]{1,5})$');

String _redactPath(String path, String salt) {
  final app = _appDir.firstMatch(path);
  if (app != null) return '[app]${path.substring(app.end)}';

  final String prefix;
  final String rest;
  final internal = _internal.firstMatch(path);
  final sd = internal == null ? _sd.firstMatch(path) : null;
  if (internal != null) {
    prefix = '[int]';
    rest = path.substring(internal.end);
  } else if (sd != null) {
    prefix = '[sd]';
    rest = path.substring(sd.end);
  } else {
    prefix = '';
    rest = path;
  }
  // rest = '' | '/A' | '/A/B/c.jpg' (maybe with a trailing slash or space).
  final segments = rest.split('/');
  final out = StringBuffer(prefix);
  for (var i = 1; i < segments.length; i++) {
    out.write('/');
    final segment = segments[i];
    // The first folder below the volume (or the first segment of an
    // unknown path) is kept.
    out.write(i == 1 ? segment : _hashSegment(segment, salt));
  }
  return out.toString();
}

String _hashSegment(String segment, String salt) {
  // Keep trailing whitespace outside the token (end of a sentence).
  final trimmed = segment.trimRight();
  if (trimmed.isEmpty) return segment;
  final tail = segment.substring(trimmed.length);
  final ext = _extension.firstMatch(trimmed);
  final token = '#${_hash(trimmed, salt)}';
  return '${ext == null ? token : '$token.${ext[2]}'}$tail';
}

String _hash(String value, String salt) =>
    sha256.convert(utf8.encode('$salt$value')).toString().substring(0, 6);
