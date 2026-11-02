import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/features/privacy/domain/xmp_location.dart';

/// Location removal for ISO-BMFF files (MP4/MOV/3GP videos; also the video
/// a motion photo carries after its JPEG) (TASK-X2 step 7). Location boxes
/// become `free` boxes of the same size: offsets (`stco`/`co64`) stay valid,
/// nothing is remuxed or re-encoded and the media bytes are unchanged.
///
/// Where location lives: `udta/©xyz` (Android, most cameras), `udta/loci`
/// (3GPP), the `meta` `keys` entries `com.apple.quicktime.location.*` with
/// their values in `ilst` (iPhone), and XMP (`uuid` box BE7ACFCB…,
/// QuickTime `udta/XMP_`).

/// Thrown when the file isn't ISO-BMFF or its `moov` can't be read.
class Mp4FormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'Mp4FormatException: $message';
}

/// [Mp4FormatException.message] when location was found after removal.
const String kLocationStillPresent = 'location still present';

/// Largest top-level metadata box read into memory (`moov` is usually
/// well under 1 MB; a long 4K video's sample tables a few MB).
const int kMaxMetadataBoxBytes = 64 * 1024 * 1024;

const _containers = {'moov', 'trak', 'mdia', 'minf', 'udta', 'edts', 'moof'};
const _xmpUuid = [
  0xBE, 0x7A, 0xCF, 0xCB, 0x97, 0xA9, 0x42, 0xE8, //
  0x9C, 0x71, 0x99, 0x94, 0x91, 0xE3, 0xAF, 0xAC,
];
const _topLevel = {
  'ftyp', 'moov', 'mdat', 'free', 'skip', 'wide', 'pnot', 'uuid', 'meta', //
  'udta', 'moof', 'mfra', 'sidx', 'styp', 'emsg', 'prft', 'pdin', 'junk',
};

/// What a walk found (or changed).
class _Walk {
  int boxes = 0;
}

/// Neutralises every location box in the box sequence `b[start, end)`
/// (recursively). [dryRun] only counts them. Returns the count.
int stripIsoLocationBoxes(
  Uint8List b,
  int start,
  int end, {
  bool dryRun = false,
}) {
  final walk = _Walk();
  _walkBoxes(b, start, end, walk, dryRun: dryRun);
  return walk.boxes;
}

/// Box header at [at]: `(type, headerSize, boxEnd)` or null when it doesn't
/// fit in `[at, end)`.
(String, int, int)? _header(Uint8List b, int at, int end) {
  if (at + 8 > end) return null;
  final bd = ByteData.sublistView(b);
  var size = bd.getUint32(at);
  final type = latin1.decode(b.sublist(at + 4, at + 8));
  var header = 8;
  if (size == 1) {
    if (at + 16 > end) return null;
    final large = bd.getUint64(at + 8);
    if (large > end - at) return null;
    size = large;
    header = 16;
  } else if (size == 0) {
    size = end - at;
  }
  if (size < header || at + size > end) return null;
  if (type == 'uuid') header += 16;
  if (at + header > at + size) return null;
  return (type, header, at + size);
}

void _walkBoxes(
  Uint8List b,
  int start,
  int end,
  _Walk walk, {
  required bool dryRun,
}) {
  var at = start;
  while (at + 8 <= end) {
    final h = _header(b, at, end);
    if (h == null) return;
    final (type, header, boxEnd) = h;
    final payload = at + header;
    if (type == '©xyz' || type == 'loci') {
      walk.boxes++;
      if (!dryRun) _neutralise(b, at, header, boxEnd);
    } else if (type == 'XMP_' ||
        (type == 'uuid' && _isXmpUuid(b, at + header - 16))) {
      if (dryRun) {
        if (hasLocationText(b, payload, boxEnd)) walk.boxes++;
      } else {
        walk.boxes += blankXmpLocation(b, payload, boxEnd);
      }
    } else if (type == 'meta') {
      _walkMeta(b, payload, boxEnd, walk, dryRun: dryRun);
    } else if (_containers.contains(type)) {
      _walkBoxes(b, payload, boxEnd, walk, dryRun: dryRun);
    }
    at = boxEnd;
  }
}

bool _isXmpUuid(Uint8List b, int at) {
  for (var i = 0; i < 16; i++) {
    if (b[at + i] != _xmpUuid[i]) return false;
  }
  return true;
}

/// `free` box of the same size, its content zeroed.
void _neutralise(Uint8List b, int at, int header, int boxEnd) {
  b.setRange(at + 4, at + 8, 'free'.codeUnits);
  final contentStart = header == 16 ? at + 16 : at + 8;
  b.fillRange(contentStart, boxEnd, 0);
}

/// `meta` is a full box in ISO files (4 bytes version/flags first) and a
/// plain container in QuickTime files; the `hdlr` child tells which.
void _walkMeta(
  Uint8List b,
  int payload,
  int end,
  _Walk walk, {
  required bool dryRun,
}) {
  var children = payload + 4;
  if (payload + 8 <= end &&
      latin1.decode(b.sublist(payload + 4, payload + 8)) == 'hdlr') {
    children = payload;
  }
  if (children > end) return;
  // keys: 1-based index → is a location key.
  final locationKeys = <int>{};
  var at = children;
  while (at + 8 <= end) {
    final h = _header(b, at, end);
    if (h == null) break;
    final (type, header, boxEnd) = h;
    if (type == 'keys') {
      locationKeys.addAll(
        _locationKeys(b, at + header, boxEnd, walk, dryRun: dryRun),
      );
    }
    at = boxEnd;
  }
  at = children;
  while (at + 8 <= end) {
    final h = _header(b, at, end);
    if (h == null) break;
    final (type, header, boxEnd) = h;
    if (type == 'ilst') {
      _walkIlst(b, at + header, boxEnd, locationKeys, walk, dryRun: dryRun);
    } else if (type != 'keys') {
      _walkBoxes(b, at, boxEnd, walk, dryRun: dryRun);
    }
    at = boxEnd;
  }
}

/// Indexes of `com.apple.quicktime.location.*` keys; their names are zeroed
/// (the entry sizes stay).
Set<int> _locationKeys(
  Uint8List b,
  int payload,
  int end,
  _Walk walk, {
  required bool dryRun,
}) {
  final found = <int>{};
  if (payload + 8 > end) return found;
  final bd = ByteData.sublistView(b);
  final count = bd.getUint32(payload + 4);
  var at = payload + 8;
  for (var i = 1; i <= count && at + 8 <= end; i++) {
    final size = bd.getUint32(at);
    if (size < 8 || at + size > end) break;
    final name = latin1.decode(b.sublist(at + 8, at + size));
    if (name.toLowerCase().contains('location')) {
      found.add(i);
      walk.boxes++;
      if (!dryRun) b.fillRange(at + 8, at + size, 0);
    }
    at += size;
  }
  return found;
}

/// `ilst` children are typed by their key index (or a classic tag such as
/// `©xyz`): location values become `free`.
void _walkIlst(
  Uint8List b,
  int payload,
  int end,
  Set<int> locationKeys,
  _Walk walk, {
  required bool dryRun,
}) {
  final bd = ByteData.sublistView(b);
  var at = payload;
  while (at + 8 <= end) {
    final h = _header(b, at, end);
    if (h == null) return;
    final (type, header, boxEnd) = h;
    if (type == '©xyz' || locationKeys.contains(bd.getUint32(at + 4))) {
      walk.boxes++;
      if (!dryRun) _neutralise(b, at, header, boxEnd);
    }
    at = boxEnd;
  }
}

/// Whether [head] starts like an ISO-BMFF file (a known top-level box).
bool looksLikeIsoBmff(Uint8List head) {
  if (head.length < 8) return false;
  return _topLevel.contains(latin1.decode(head.sublist(4, 8)));
}

/// Removes location from the ISO-BMFF file at [path], in place: only the
/// top-level metadata boxes (`moov`, `meta`, `udta`, XMP `uuid`) are read
/// and rewritten at the same offsets. Then they're read again and checked.
/// Returns the number of boxes neutralised. Throws [Mp4FormatException]
/// when the file isn't ISO-BMFF, `moov` is missing, truncated or too large,
/// or location is still found afterwards.
Future<int> stripMp4LocationInPlace(String path) async {
  final raf = await File(path).open(mode: FileMode.append);
  try {
    final length = await raf.length();
    await raf.setPosition(0);
    if (!looksLikeIsoBmff(await raf.read(16))) {
      throw const Mp4FormatException('not ISO-BMFF');
    }
    var changed = 0;
    var sawMoov = false;
    for (final (at, size, type) in await _topBoxes(raf, length)) {
      if (type == 'moov') sawMoov = true;
      if (!{'moov', 'meta', 'udta', 'uuid'}.contains(type)) continue;
      if (size > kMaxMetadataBoxBytes) {
        if (type == 'moov') throw const Mp4FormatException('moov too large');
        continue;
      }
      await raf.setPosition(at);
      final box = await raf.read(size);
      if (box.length != size) throw const Mp4FormatException('truncated');
      final n = stripIsoLocationBoxes(box, 0, size);
      if (n > 0) {
        await raf.setPosition(at);
        await raf.writeFrom(box);
        changed += n;
      }
      await raf.setPosition(at);
      final check = await raf.read(size);
      if (stripIsoLocationBoxes(check, 0, size, dryRun: true) > 0 ||
          (type != 'mdat' && hasLocationText(check))) {
        throw const Mp4FormatException(kLocationStillPresent);
      }
    }
    if (!sawMoov) throw const Mp4FormatException('no moov');
    await raf.flush();
    return changed;
  } finally {
    await raf.close();
  }
}

/// `(offset, size, type)` of each top-level box.
Future<List<(int, int, String)>> _topBoxes(
  RandomAccessFile raf,
  int length,
) async {
  final boxes = <(int, int, String)>[];
  var at = 0;
  while (at + 8 <= length) {
    await raf.setPosition(at);
    final h = await raf.read(16);
    if (h.length < 8) break;
    final bd = ByteData.sublistView(h);
    var size = bd.getUint32(0);
    final type = latin1.decode(h.sublist(4, 8));
    if (size == 1) {
      if (h.length < 16) throw const Mp4FormatException('truncated');
      size = bd.getUint64(8);
    } else if (size == 0) {
      size = length - at;
    }
    if (size < 8 || at + size > length) {
      throw const Mp4FormatException('truncated');
    }
    boxes.add((at, size, type));
    at += size;
  }
  return boxes;
}
