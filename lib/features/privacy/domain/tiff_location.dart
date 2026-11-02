import 'dart:typed_data';

/// EXIF GPS removal inside TIFF structures (TASK-X2): JPEG `APP1`, PNG
/// `eXIf`, WebP `EXIF`, the HEIF `Exif` item and TIFF/DNG files all hold a
/// TIFF header (`II*\0` / `MM\0*`) whose IFD0 may point to a GPS IFD
/// (tag 0x8825). Everything is edited in place, so file offsets never move.

const int _gpsPointer = 0x8825;
const int _exifPointer = 0x8769;
const int _maxEntries = 1000;

/// Removes the GPS IFD of every TIFF structure found in `bytes[start, end)`:
/// the GPS pointer leaves IFD0 (and the Exif IFD, where some writers put it)
/// and the GPS IFD with all its values is zeroed. Candidates that don't
/// parse as TIFF are left alone (they're image data, not metadata).
/// Returns how many GPS IFDs were removed.
int stripTiffGps(Uint8List bytes, [int start = 0, int? end]) {
  var count = 0;
  for (final at in _tiffCandidates(bytes, start, end ?? bytes.length)) {
    final tiff = _Tiff.at(bytes, at, end ?? bytes.length);
    if (tiff != null) count += tiff.stripGps();
  }
  return count;
}

/// Whether any TIFF structure in `bytes[start, end)` still points to a GPS
/// IFD.
bool hasTiffGps(Uint8List bytes, [int start = 0, int? end]) {
  for (final at in _tiffCandidates(bytes, start, end ?? bytes.length)) {
    final tiff = _Tiff.at(bytes, at, end ?? bytes.length);
    if (tiff != null && tiff.gpsEntries().isNotEmpty) return true;
  }
  return false;
}

Iterable<int> _tiffCandidates(Uint8List b, int start, int end) sync* {
  for (var i = start; i + 8 <= end; i++) {
    final c = b[i];
    if (c == 0x49 && b[i + 1] == 0x49 && b[i + 2] == 0x2A && b[i + 3] == 0) {
      yield i;
    } else if (c == 0x4D &&
        b[i + 1] == 0x4D &&
        b[i + 2] == 0 &&
        b[i + 3] == 0x2A) {
      yield i;
    }
  }
}

/// A parsed TIFF header at [base] (offsets inside are relative to it).
class _Tiff {
  new _(this.b, this.base, this.length, this.little);

  final Uint8List b;
  final int base;
  final int length;
  final bool little;

  static _Tiff? at(Uint8List b, int base, int end) {
    final t = _Tiff._(b, base, end - base, b[base] == 0x49);
    final ifd0 = t._u32(4);
    if (ifd0 == null || !t._validIfd(ifd0)) return null;
    return t;
  }

  int? _u16(int off) {
    if (off < 0 || off + 2 > length) return null;
    final p = base + off;
    return little ? b[p] | (b[p + 1] << 8) : (b[p] << 8) | b[p + 1];
  }

  int? _u32(int off) {
    if (off < 0 || off + 4 > length) return null;
    final p = base + off;
    return little
        ? b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24)
        : (b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3];
  }

  void _put16(int off, int v) {
    final p = base + off;
    if (little) {
      b[p] = v & 0xFF;
      b[p + 1] = (v >> 8) & 0xFF;
    } else {
      b[p] = (v >> 8) & 0xFF;
      b[p + 1] = v & 0xFF;
    }
  }

  bool _validIfd(int off) {
    if (off < 8) return false;
    final n = _u16(off);
    if (n == null || n == 0 || n > _maxEntries) return false;
    return off + 2 + n * 12 + 4 <= length;
  }

  /// `(ifdOffset, entryIndex, gpsOffset)` of every GPS pointer in IFD0 and
  /// the Exif IFD.
  List<(int, int, int)> gpsEntries() {
    final ifd0 = _u32(4)!;
    final found = <(int, int, int)>[];
    final ifds = [ifd0];
    final exif = _pointer(ifd0, _exifPointer);
    if (exif != null && exif != ifd0 && _validIfd(exif)) ifds.add(exif);
    for (final ifd in ifds) {
      final n = _u16(ifd)!;
      for (var i = 0; i < n; i++) {
        final e = ifd + 2 + i * 12;
        if (_u16(e) == _gpsPointer) found.add((ifd, i, _u32(e + 8) ?? 0));
      }
    }
    return found;
  }

  int? _pointer(int ifd, int tag) {
    final n = _u16(ifd)!;
    for (var i = 0; i < n; i++) {
      final e = ifd + 2 + i * 12;
      if (_u16(e) == tag) return _u32(e + 8);
    }
    return null;
  }

  int stripGps() {
    var count = 0;
    // Last entry first, so removing one doesn't shift a later index.
    final entries = gpsEntries().reversed.toList();
    for (final (ifd, index, gps) in entries) {
      _zeroGpsIfd(gps);
      _removeEntry(ifd, index);
      count++;
    }
    return count;
  }

  /// Zeroes the GPS IFD and every value it points to (out-of-range values
  /// are skipped: they aren't in this file's metadata).
  void _zeroGpsIfd(int off) {
    final n = _u16(off);
    if (n == null || n > _maxEntries || off < 8) return;
    final tableEnd = off + 2 + n * 12 + 4;
    if (tableEnd > length) return;
    for (var i = 0; i < n; i++) {
      final e = off + 2 + i * 12;
      final size = _typeSize(_u16(e + 2)!) * _u32(e + 4)!;
      if (size > 4) {
        final at = _u32(e + 8)!;
        if (at >= 8 && at + size <= length) {
          b.fillRange(base + at, base + at + size, 0);
        }
      }
    }
    b.fillRange(base + off, base + tableEnd, 0);
  }

  /// Drops entry [index] of the IFD at [ifd]: later entries and the
  /// next-IFD pointer move up 12 bytes; the freed 12 bytes become zero.
  void _removeEntry(int ifd, int index) {
    final n = _u16(ifd)!;
    final from = base + ifd + 2 + (index + 1) * 12;
    final tail = base + ifd + 2 + n * 12 + 4;
    b
      ..setRange(from - 12, tail - 12, b, from)
      ..fillRange(tail - 12, tail, 0);
    _put16(ifd, n - 1);
  }

  static int _typeSize(int type) => switch (type) {
    3 || 8 => 2,
    4 || 9 || 11 || 13 => 4,
    5 || 10 || 12 => 8,
    _ => 1,
  };
}
