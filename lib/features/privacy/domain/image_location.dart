import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:kfm/features/privacy/domain/mp4_location_stripper.dart';
import 'package:kfm/features/privacy/domain/tiff_location.dart';
import 'package:kfm/features/privacy/domain/xmp_location.dart';

/// Thrown when location can't be proven gone from a photo; the caller must
/// not send it.
class ImageLocationException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'ImageLocationException: $message';
}

/// Removes location from a photo's bytes (TASK-X2) and returns the result
/// (the same list, edited in place, except for PNG when a chunk is
/// dropped): EXIF GPS (every TIFF structure in the file: JPEG `APP1`,
/// WebP `EXIF`, the HEIF `Exif` item, TIFF/DNG, secondary MPO images), XMP
/// GPS and place names (blanked to spaces), and the location of a motion
/// photo's embedded video. PNG chunks are walked (CRCs are fixed). The
/// output is a pure function of the input: the same photo always gives the
/// same bytes (N10 resumes uploads by offset).
///
/// Then the output is checked; any location left throws
/// [ImageLocationException].
Uint8List stripImageLocation(Uint8List bytes) {
  final out = _isPng(bytes) ? _stripPng(bytes) : _stripGeneric(bytes);
  if (imageHasLocation(out)) {
    throw const ImageLocationException('location still present');
  }
  return out;
}

/// Whether [bytes] still carry a GPS IFD, XMP GPS text, an Apple location
/// key, or (motion photos) a video location box.
bool imageHasLocation(Uint8List bytes) {
  if (hasTiffGps(bytes) || hasLocationText(bytes)) return true;
  if (_isPng(bytes)) return _pngHasHiddenLocation(bytes);
  final video = _embeddedVideo(bytes);
  return video != null &&
      stripIsoLocationBoxes(bytes, video, bytes.length, dryRun: true) > 0;
}

/// Reads [path], strips it and writes it back (the size may change for
/// PNG). Returns the new length. For an isolate (`Isolate.run`).
Future<int> stripImageFileInPlace(String path) async {
  final file = File(path);
  final out = stripImageLocation(await file.readAsBytes());
  await file.writeAsBytes(out, flush: true);
  return out.length;
}

Uint8List _stripGeneric(Uint8List b) {
  stripTiffGps(b);
  blankXmpLocation(b);
  final video = _embeddedVideo(b);
  if (video != null) stripIsoLocationBoxes(b, video, b.length);
  return b;
}

/// Start of an MP4 appended to a JPEG (Samsung/Google motion photos): the
/// first `ftyp` box after the JPEG's end marker.
int? _embeddedVideo(Uint8List b) {
  if (b.length < 16 || b[0] != 0xFF || b[1] != 0xD8) return null;
  for (var i = 4; i + 8 <= b.length; i++) {
    if (b[i] == 0x66 &&
        b[i + 1] == 0x74 &&
        b[i + 2] == 0x79 &&
        b[i + 3] == 0x70) {
      final start = i - 4;
      final size = ByteData.sublistView(b).getUint32(start);
      if (size >= 8 && size <= 1024 && start + size <= b.length) {
        // Preceded by a JPEG end marker somewhere before: it's a trailer.
        if (_hasEoiBefore(b, start)) return start;
      }
    }
  }
  return null;
}

bool _hasEoiBefore(Uint8List b, int end) {
  for (var i = end - 2; i >= 2; i--) {
    if (b[i] == 0xFF && b[i + 1] == 0xD9) return true;
  }
  return false;
}

const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

bool _isPng(Uint8List b) {
  if (b.length < 8) return false;
  for (var i = 0; i < 8; i++) {
    if (b[i] != _pngSignature[i]) return false;
  }
  return true;
}

/// One PNG chunk.
typedef _Chunk = ({String type, int dataStart, int dataEnd});

List<_Chunk> _pngChunks(Uint8List b) {
  final bd = ByteData.sublistView(b);
  final chunks = <_Chunk>[];
  var at = 8;
  while (at + 12 <= b.length) {
    final len = bd.getUint32(at);
    final end = at + 8 + len + 4;
    if (end > b.length) throw const ImageLocationException('truncated PNG');
    final type = latin1.decode(b.sublist(at + 4, at + 8));
    chunks.add((type: type, dataStart: at + 8, dataEnd: at + 8 + len));
    at = end;
    if (type == 'IEND') break;
  }
  return chunks;
}

const _textChunks = {'tEXt', 'zTXt', 'iTXt'};

/// PNG: EXIF in `eXIf`, XMP in `iTXt` (`XML:com.adobe.xmp`), ImageMagick
/// "Raw profile" text chunks. Uncompressed chunks are edited in place and
/// get a new CRC; a compressed text chunk with location is dropped.
Uint8List _stripPng(Uint8List b) {
  final keep = BytesBuilder(copy: false)..add(b.sublist(0, 8));
  for (final c in _pngChunks(b)) {
    final chunkStart = c.dataStart - 8;
    final chunkEnd = c.dataEnd + 4;
    if (c.type == 'eXIf' || _textChunks.contains(c.type)) {
      final text = _pngText(b, c);
      if (text == null) {
        // Compressed (or raw profile) text: dropped when it has location.
        if (_compressedHasLocation(b, c)) continue;
      } else {
        final n =
            stripTiffGps(b, c.dataStart, c.dataEnd) +
            blankXmpLocation(b, c.dataStart, c.dataEnd);
        if (n > 0) _fixCrc(b, c);
      }
    }
    keep.add(Uint8List.sublistView(b, chunkStart, chunkEnd));
  }
  return keep.takeBytes();
}

/// The chunk's text when it can be edited in place (eXIf, tEXt, an
/// uncompressed iTXt), else null. Raw profiles (hex EXIF) count as
/// compressed: they're checked as a whole.
String? _pngText(Uint8List b, _Chunk c) {
  if (c.type == 'eXIf') return '';
  final data = Uint8List.sublistView(b, c.dataStart, c.dataEnd);
  final nul = data.indexOf(0);
  if (nul < 0) return null;
  final keyword = latin1.decode(data.sublist(0, nul));
  if (keyword.startsWith('Raw profile type')) return null;
  if (c.type == 'zTXt') return null;
  if (c.type == 'iTXt' && (nul + 1 >= data.length || data[nul + 1] != 0)) {
    return null;
  }
  return keyword;
}

bool _compressedHasLocation(Uint8List b, _Chunk c) {
  final data = Uint8List.sublistView(b, c.dataStart, c.dataEnd);
  final nul = data.indexOf(0);
  if (nul < 0) return false;
  final keyword = latin1.decode(data.sublist(0, nul));
  final raw = keyword.startsWith('Raw profile type');
  Uint8List body;
  try {
    if (c.type == 'zTXt') {
      body = _inflate(data.sublist(nul + 2));
    } else if (c.type == 'iTXt') {
      // keyword\0 flag method lang\0 translated\0 text
      var p = nul + 3;
      p = data.indexOf(0, p) + 1;
      p = data.indexOf(0, p) + 1;
      if (p <= 0) return true;
      final text = data.sublist(p);
      body = data[nul + 1] == 1 ? _inflate(text) : text;
    } else {
      body = data.sublist(nul + 1);
    }
  } on FormatException {
    // Unreadable: can't prove it's clean.
    return raw || keyword.contains('xmp');
  }
  if (hasLocationText(body) || hasTiffGps(body)) return true;
  // A raw profile is "\n<name>\n<length>\n<hex lines>": decode the hex to
  // look for a GPS IFD.
  if (raw) {
    final lines = latin1.decode(body).split('\n');
    final hex = lines.skip(3).join().replaceAll(RegExp('[^0-9a-fA-F]'), '');
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return hasTiffGps(bytes) || hasLocationText(bytes);
  }
  return false;
}

bool _pngHasHiddenLocation(Uint8List b) {
  for (final c in _pngChunks(b)) {
    if (_textChunks.contains(c.type) &&
        _pngText(b, c) == null &&
        _compressedHasLocation(b, c)) {
      return true;
    }
  }
  return false;
}

Uint8List _inflate(List<int> data) {
  try {
    return Uint8List.fromList(ZLibDecoder().convert(data));
  } on Object {
    throw const FormatException('bad zlib data');
  }
}

void _fixCrc(Uint8List b, _Chunk c) {
  final crc = getCrc32(Uint8List.sublistView(b, c.dataStart - 4, c.dataEnd));
  ByteData.sublistView(b).setUint32(c.dataEnd, crc);
}
