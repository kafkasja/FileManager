import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:kfm/features/archive/domain/archive_job.dart';

/// Writes a zip with async dart:io (TASK-B5), so the worker's event loop
/// runs between chunks: a cancel lands inside a large entry too (archive's
/// `ZipEncoder.add` deflates a whole entry in one synchronous call).
///
/// Format (APPNOTE 6.3): UTF-8 names (bit 11). Deflated entries are
/// streamed through dart:io's raw `ZLibEncoder`, with their CRC and sizes in
/// a data descriptor after the data (bit 3). Stored entries are read twice
/// (CRC first), so their local header carries the sizes: Java's
/// `ZipInputStream` refuses a stored entry with a descriptor. Zip64 fields
/// are written only where a size, offset or count needs them.
final class ZipWriter {
  new _(this._out);

  /// Creates (truncates) the zip at [path].
  static Future<ZipWriter> create(String path) async =>
      ZipWriter._(await File(path).open(mode: FileMode.write));

  final RandomAccessFile _out;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final List<_Central> _central = [];
  int _offset = 0;
  bool _closed = false;

  static const int _chunk = 256 * 1024;
  static const int _flushAt = 1024 * 1024;
  static const int _max32 = 0xFFFFFFFF;
  static const int _utf8Flag = 0x800;
  static const int _descriptorFlag = 0x08;

  /// A folder entry (`name` ends with `/`).
  Future<void> addDirectory(String name, DateTime modified) async {
    final entryName = name.endsWith('/') ? name : '$name/';
    final offset = _offset;
    await _localHeader(
      name: entryName,
      flags: _utf8Flag,
      method: 0,
      modified: modified,
      crc: 0,
      compressed: 0,
      uncompressed: 0,
      zip64: false,
    );
    _central.add(
      _Central(
        name: entryName,
        flags: _utf8Flag,
        method: 0,
        modified: modified,
        crc: 0,
        compressed: 0,
        uncompressed: 0,
        offset: offset,
        directory: true,
      ),
    );
  }

  /// The file at [path] as entry [name]. [store]: no compression.
  /// [onRead] gets every chunk read from [path] (a stored file is read
  /// twice); [checkpoint] runs every [_flushAt] bytes and may throw (cancel).
  /// Throws [ArchiveIoError] when the file changes size while it is read.
  Future<void> addFile(
    String name,
    String path, {
    required DateTime modified,
    required bool store,
    required void Function(int bytes) onRead,
    required Future<void> Function() checkpoint,
    int level = 6,
  }) async {
    final input = await File(path).open();
    try {
      final size = await input.length();
      if (store || size == 0) {
        await _addStored(name, path, input, size, modified, onRead, checkpoint);
      } else {
        await _addDeflated(
          name,
          input,
          size,
          modified,
          level,
          onRead,
          checkpoint,
        );
      }
    } finally {
      await input.close();
    }
  }

  Future<void> _addStored(
    String name,
    String path,
    RandomAccessFile input,
    int size,
    DateTime modified,
    void Function(int) onRead,
    Future<void> Function() checkpoint,
  ) async {
    // Pass 1: the CRC (and the real length).
    var crc = 0;
    var length = 0;
    var sinceCheck = 0;
    while (true) {
      final chunk = await input.read(_chunk);
      if (chunk.isEmpty) break;
      crc = getCrc32(chunk, crc);
      length += chunk.length;
      onRead(chunk.length);
      sinceCheck += chunk.length;
      if (sinceCheck >= _flushAt) {
        sinceCheck = 0;
        await checkpoint();
      }
    }
    final offset = _offset;
    final zip64 = length > _max32;
    await _localHeader(
      name: name,
      flags: _utf8Flag,
      method: 0,
      modified: modified,
      crc: crc,
      compressed: length,
      uncompressed: length,
      zip64: zip64,
    );
    // Pass 2: the data.
    await input.setPosition(0);
    var copied = 0;
    while (copied < length) {
      final chunk = await input.read(min(_chunk, length - copied));
      if (chunk.isEmpty) break;
      await _write(chunk);
      copied += chunk.length;
      onRead(chunk.length);
      sinceCheck += chunk.length;
      if (sinceCheck >= _flushAt) {
        sinceCheck = 0;
        await checkpoint();
      }
    }
    if (copied != length || (await input.read(1)).isNotEmpty) {
      throw ArchiveIoError(path, 'changed while it was zipped');
    }
    _central.add(
      _Central(
        name: name,
        flags: _utf8Flag,
        method: 0,
        modified: modified,
        crc: crc,
        compressed: length,
        uncompressed: length,
        offset: offset,
      ),
    );
  }

  Future<void> _addDeflated(
    String name,
    RandomAccessFile input,
    int size,
    DateTime modified,
    int level,
    void Function(int) onRead,
    Future<void> Function() checkpoint,
  ) async {
    const flags = _utf8Flag | _descriptorFlag;
    final offset = _offset;
    // Whether the sizes might not fit 32 bits (deflate can grow incompressible
    // data a little; the file can also grow while it's read).
    final zip64 = size + (size >> 5) + 4096 > _max32;
    await _localHeader(
      name: name,
      flags: flags,
      method: 8,
      modified: modified,
      crc: 0,
      compressed: 0,
      uncompressed: 0,
      zip64: zip64,
      sizesInDescriptor: true,
    );
    final pending = <List<int>>[];
    final deflater = ZLibEncoder(
      raw: true,
      level: level,
    ).startChunkedConversion(_ListSink(pending));
    var crc = 0;
    var uncompressed = 0;
    var compressed = 0;
    var sinceCheck = 0;
    Future<void> drain() async {
      for (final p in pending) {
        compressed += p.length;
        await _write(p);
      }
      pending.clear();
    }

    while (true) {
      final chunk = await input.read(_chunk);
      if (chunk.isEmpty) break;
      crc = getCrc32(chunk, crc);
      uncompressed += chunk.length;
      deflater.add(chunk);
      await drain();
      onRead(chunk.length);
      sinceCheck += chunk.length;
      if (sinceCheck >= _flushAt) {
        sinceCheck = 0;
        await checkpoint();
      }
    }
    deflater.close();
    await drain();
    if (!zip64 && (compressed > _max32 || uncompressed > _max32)) {
      // Grew past 4 GB while it was read: the header can't say so any more.
      throw ArchiveIoError(name, 'changed while it was zipped');
    }
    final d = BytesBuilder();
    _u32(d, 0x08074b50);
    _u32(d, crc);
    if (zip64) {
      _u64(d, compressed);
      _u64(d, uncompressed);
    } else {
      _u32(d, compressed);
      _u32(d, uncompressed);
    }
    await _write(d.takeBytes());
    _central.add(
      _Central(
        name: name,
        flags: flags,
        method: 8,
        modified: modified,
        crc: crc,
        compressed: compressed,
        uncompressed: uncompressed,
        offset: offset,
      ),
    );
  }

  /// Writes the central directory and closes the file.
  Future<void> finish() async {
    final cdStart = _offset;
    for (final e in _central) {
      await _write(e.encode());
    }
    final cdSize = _offset - cdStart;
    final count = _central.length;
    final zip64 = count > 0xFFFF || cdStart > _max32 || cdSize > _max32;
    final b = BytesBuilder();
    if (zip64) {
      final recordAt = _offset;
      _u32(b, 0x06064b50); // zip64 end of central directory record
      _u64(b, 44);
      _u16(b, (3 << 8) | 45);
      _u16(b, 45);
      _u32(b, 0);
      _u32(b, 0);
      _u64(b, count);
      _u64(b, count);
      _u64(b, cdSize);
      _u64(b, cdStart);
      _u32(b, 0x07064b50); // locator
      _u32(b, 0);
      _u64(b, recordAt);
      _u32(b, 1);
    }
    _u32(b, 0x06054b50);
    _u16(b, 0);
    _u16(b, 0);
    _u16(b, zip64 ? 0xFFFF : count);
    _u16(b, zip64 ? 0xFFFF : count);
    _u32(b, zip64 ? _max32 : cdSize);
    _u32(b, zip64 ? _max32 : cdStart);
    _u16(b, 0);
    await _write(b.takeBytes());
    await _flush();
    _closed = true;
    await _out.close();
  }

  /// Closes the file without finishing it (the caller deletes it).
  Future<void> abort() async {
    if (_closed) return;
    _closed = true;
    try {
      await _out.close();
    } on FileSystemException {
      // Already broken; the caller's delete still runs.
    }
  }

  Future<void> _localHeader({
    required String name,
    required int flags,
    required int method,
    required DateTime modified,
    required int crc,
    required int compressed,
    required int uncompressed,
    required bool zip64,
    bool sizesInDescriptor = false,
  }) async {
    final nameBytes = _utf8(name);
    final b = BytesBuilder();
    _u32(b, 0x04034b50);
    _u16(b, zip64 ? 45 : 20);
    _u16(b, flags);
    _u16(b, method);
    _u16(b, _dosTime(modified));
    _u16(b, _dosDate(modified));
    _u32(b, crc);
    _u32(b, zip64 ? _max32 : compressed);
    _u32(b, zip64 ? _max32 : uncompressed);
    _u16(b, nameBytes.length);
    _u16(b, zip64 ? 20 : 0);
    b.add(nameBytes);
    if (zip64) {
      _u16(b, 1);
      _u16(b, 16);
      _u64(b, sizesInDescriptor ? 0 : uncompressed);
      _u64(b, sizesInDescriptor ? 0 : compressed);
    }
    await _write(b.takeBytes());
  }

  Future<void> _write(List<int> bytes) async {
    if (bytes.isEmpty) return;
    _buffer.add(bytes);
    _offset += bytes.length;
    if (_buffer.length >= _flushAt) await _flush();
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    await _out.writeFrom(_buffer.takeBytes());
  }
}

/// One central-directory record.
final class _Central {
  const new({
    required this.name,
    required this.flags,
    required this.method,
    required this.modified,
    required this.crc,
    required this.compressed,
    required this.uncompressed,
    required this.offset,
    this.directory = false,
  });

  final String name;
  final int flags;
  final int method;
  final DateTime modified;
  final int crc;
  final int compressed;
  final int uncompressed;
  final int offset;
  final bool directory;

  Uint8List encode() {
    const max32 = ZipWriter._max32;
    final nameBytes = _utf8(name);
    final bigU = uncompressed > max32;
    final bigC = compressed > max32;
    final bigO = offset > max32;
    final extra = BytesBuilder();
    if (bigU || bigC || bigO) {
      final fields = BytesBuilder();
      if (bigU) _u64(fields, uncompressed);
      if (bigC) _u64(fields, compressed);
      if (bigO) _u64(fields, offset);
      final f = fields.takeBytes();
      _u16(extra, 1);
      _u16(extra, f.length);
      extra.add(f);
    }
    final extraBytes = extra.takeBytes();
    final version = extraBytes.isEmpty ? 20 : 45;
    final b = BytesBuilder();
    _u32(b, 0x02014b50);
    _u16(b, (3 << 8) | version); // made by Unix
    _u16(b, version);
    _u16(b, flags);
    _u16(b, method);
    _u16(b, _dosTime(modified));
    _u16(b, _dosDate(modified));
    _u32(b, crc);
    _u32(b, bigC ? max32 : compressed);
    _u32(b, bigU ? max32 : uncompressed);
    _u16(b, nameBytes.length);
    _u16(b, extraBytes.length);
    _u16(b, 0); // comment
    _u16(b, 0); // disk
    _u16(b, 0); // internal attributes
    // rw-r--r-- file / rwxr-xr-x folder (+ the MS-DOS folder bit).
    _u32(b, directory ? (0x41ED << 16) | 0x10 : 0x81A4 << 16);
    _u32(b, bigO ? max32 : offset);
    b
      ..add(nameBytes)
      ..add(extraBytes);
    return b.takeBytes();
  }
}

/// Collects the deflater's output (it calls [add] synchronously).
final class _ListSink implements Sink<List<int>> {
  const new(this._into);

  final List<List<int>> _into;

  @override
  void add(List<int> data) => _into.add(data);

  @override
  void close() {}
}

List<int> _utf8(String s) => utf8.encode(s);

/// DOS time can't say anything before 1980 (or after 2107).
DateTime _dosRange(DateTime t) => t.year < 1980
    ? DateTime(1980)
    : t.year > 2107
    ? DateTime(2107, 12, 31, 23, 59, 58)
    : t;

int _dosTime(DateTime time) {
  final t = _dosRange(time);
  return (t.hour << 11) | (t.minute << 5) | (t.second ~/ 2);
}

int _dosDate(DateTime time) {
  final t = _dosRange(time);
  return ((t.year - 1980) << 9) | (t.month << 5) | t.day;
}

void _u16(BytesBuilder b, int v) => b
  ..addByte(v & 0xff)
  ..addByte((v >> 8) & 0xff);

void _u32(BytesBuilder b, int v) {
  for (var i = 0; i < 4; i++) {
    b.addByte((v >> (8 * i)) & 0xff);
  }
}

void _u64(BytesBuilder b, int v) {
  _u32(b, v & 0xFFFFFFFF);
  _u32(b, v >>> 32);
}
