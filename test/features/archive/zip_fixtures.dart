import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart'
    show InputFileStream, ZipDecoder, getCrc32;

/// One entry of a hand-built zip (stored, no compression), so tests can
/// write names and attributes a normal encoder refuses or rewrites.
class RawEntry {
  const new(
    this.name, {
    this.data = const [],
    this.rawName,
    this.utf8Flag = true,
    this.unixMode,
  });

  final String name;
  final List<int> data;

  /// Name bytes as stored (default: UTF-8 of [name]).
  final List<int>? rawName;
  final bool utf8Flag;

  /// Unix mode (e.g. `0xA1FF` for a symlink): written as made by Unix.
  final int? unixMode;
}

/// Writes a minimal valid zip with [entries] to [path].
Future<void> writeRawZip(String path, List<RawEntry> entries) async {
  final out = BytesBuilder();
  final central = BytesBuilder();
  void u16(BytesBuilder b, int v) => b.add([v & 0xff, (v >> 8) & 0xff]);
  void u32(BytesBuilder b, int v) =>
      b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  for (final e in entries) {
    final name = e.rawName ?? utf8.encode(e.name);
    final crc = getCrc32(e.data);
    final flags = e.utf8Flag ? 0x800 : 0;
    final offset = out.length;
    u32(out, 0x04034b50);
    u16(out, 20);
    u16(out, flags);
    u16(out, 0); // stored
    u16(out, 0);
    u16(out, 0x5821); // 2024-01-01
    u32(out, crc);
    u32(out, e.data.length);
    u32(out, e.data.length);
    u16(out, name.length);
    u16(out, 0);
    out
      ..add(name)
      ..add(e.data);

    u32(central, 0x02014b50);
    u16(central, e.unixMode != null ? (3 << 8) | 20 : 20);
    u16(central, 20);
    u16(central, flags);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0x5821);
    u32(central, crc);
    u32(central, e.data.length);
    u32(central, e.data.length);
    u16(central, name.length);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u32(central, (e.unixMode ?? 0) << 16);
    u32(central, offset);
    central.add(name);
  }
  final cdOffset = out.length;
  final cd = central.takeBytes();
  out.add(cd);
  u32(out, 0x06054b50);
  u16(out, 0);
  u16(out, 0);
  u16(out, entries.length);
  u16(out, entries.length);
  u32(out, cd.length);
  u32(out, cdOffset);
  u16(out, 0);
  await File(path).writeAsBytes(out.takeBytes());
}

/// A fresh temp folder ('/'-separated path), deleted after the test.
Future<String> tempFolder(String prefix) async {
  final dir = await Directory.systemTemp.createTemp(prefix);
  return dir.path.replaceAll(r'\', '/');
}

Future<void> deleteFolder(String path) async {
  try {
    await Directory(path).delete(recursive: true);
  } on FileSystemException {
    // Windows: a handle still closing. The OS temp cleanup gets it.
  }
}

/// Relative path → bytes of every file under [root], plus `dir/` keys for
/// folders.
Future<Map<String, List<int>>> treeOf(String root) async {
  final out = <String, List<int>>{};
  await for (final e in Directory(root).list(recursive: true)) {
    final rel = e.path.replaceAll(r'\', '/').substring(root.length + 1);
    if (e is File) {
      out[rel] = await e.readAsBytes();
    } else if (e is Directory) {
      out['$rel/'] = const [];
    }
  }
  return out;
}

/// Names in [folder] (non-recursive), sorted.
Future<List<String>> namesIn(String folder) async => [
  await for (final e in Directory(folder).list())
    e.path.replaceAll(r'\', '/').split('/').last,
]..sort();

/// Deterministic bytes that don't compress to nothing.
Uint8List noise(int length, [int seed = 1]) {
  final out = Uint8List(length);
  var x = seed;
  for (var i = 0; i < length; i++) {
    x = (x * 1103515245 + 12345) & 0x7fffffff;
    out[i] = x >> 16;
  }
  return out;
}

/// Start and length of entry [name]'s data (as stored) in the zip at
/// [path], for tests that damage it.
(int, int) entryData(String path, String name) {
  final input = InputFileStream(path);
  try {
    final decoder = ZipDecoder()..decodeStream(input);
    final h = decoder.directory.fileHeaders.firstWhere(
      (h) => h.filename == name,
    );
    final bytes = File(path).readAsBytesSync();
    final at = h.localHeaderOffset;
    final n = bytes[at + 26] | bytes[at + 27] << 8;
    final m = bytes[at + 28] | bytes[at + 29] << 8;
    return (at + 30 + n + m, h.compressedSize);
  } finally {
    input.closeSync();
  }
}
