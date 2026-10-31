import 'dart:convert';

import 'package:kfm/features/archive/domain/archive_job.dart';

/// Zip-slip / symlink protection and entry-name decoding (TASK-B5). Pure.

final _drive = RegExp('^[A-Za-z]:');

/// The '/'-separated segments of [entryName] inside the archive root:
/// backslashes count as separators (zips made on Windows), `.` and empty
/// segments are dropped, `a/../b` resolves to `b`. Throws [UnsafeEntryPath]
/// for absolute names (`/x`, `C:/x`), NUL characters, and any `..` that
/// leaves the root (`../evil.txt`, `a/../../b`). May return an empty list
/// (`./`).
List<String> entrySegments(String entryName) {
  final name = entryName.replaceAll(r'\', '/');
  if (name.startsWith('/') ||
      _drive.hasMatch(name) ||
      name.contains('\u0000')) {
    throw UnsafeEntryPath(entryName);
  }
  final parts = <String>[];
  for (final seg in name.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (parts.isEmpty) throw UnsafeEntryPath(entryName);
      parts.removeLast();
      continue;
    }
    parts.add(seg);
  }
  return parts;
}

/// Where [entryName] goes inside [targetFolder] ('/'-separated, no
/// trailing '/'). Throws [UnsafeEntryPath] when it would land outside it,
/// or on the folder itself.
String safeJoin(String targetFolder, String entryName) {
  final parts = entrySegments(entryName);
  if (parts.isEmpty) throw UnsafeEntryPath(entryName);
  final root = targetFolder.endsWith('/') && targetFolder.length > 1
      ? targetFolder.substring(0, targetFolder.length - 1)
      : targetFolder;
  return '$root/${parts.join('/')}';
}

/// Unix-made entries (`versionMadeBy` high byte 3) whose mode is a symbolic
/// link (`S_IFLNK`). Such entries are never extracted: the whole archive is
/// refused.
bool isSymlinkEntry({
  required int versionMadeBy,
  required int externalAttributes,
}) => versionMadeBy >> 8 == 3 && (externalAttributes >> 16) & 0xF000 == 0xA000;

/// General-purpose flag bit 11: the name is UTF-8.
const zipUtf8Flag = 0x800;

/// Decodes a raw entry name: UTF-8 when [utf8Flag] is set or the bytes are
/// valid UTF-8 (macOS writes UTF-8 without the flag), else code page 437
/// (the zip default; Windows' built-in zip).
String decodeEntryName(List<int> raw, {required bool utf8Flag}) {
  if (raw.every((b) => b < 0x80)) return String.fromCharCodes(raw);
  try {
    return utf8.decode(raw);
  } on FormatException {
    if (utf8Flag) return utf8.decode(raw, allowMalformed: true);
    return decodeCp437(raw);
  }
}

/// IBM code page 437 → Unicode.
String decodeCp437(List<int> bytes) => String.fromCharCodes([
  for (final b in bytes)
    if (b < 0x80) b else _cp437High.codeUnitAt(b - 0x80),
]);

// 0x80–0xFF.
const _cp437High =
    'ÇüéâäàåçêëèïîìÄÅ'
    'ÉæÆôöòûùÿÖÜ¢£¥₧ƒ'
    'áíóúñÑªº¿⌐¬½¼¡«»'
    '░▒▓│┤╡╢╖╕╣║╗╝╜╛┐'
    '└┴┬├─┼╞╟╚╔╩╦╠═╬╧'
    '╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀'
    'αßΓπΣσµτΦΘΩδ∞φε∩'
    '≡±≥≤⌠⌡÷≈°∙·√ⁿ²■\u00A0';
