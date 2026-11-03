import 'dart:io';
import 'dart:math' as math;

import 'package:exif/exif.dart';
import 'package:meta/meta.dart';

/// Capture date and pixel size from a photo's EXIF (TASK-PL1: the Windows
/// scan has no MediaStore to ask).
@immutable
class ExifMeta {
  const new({this.takenAt, this.width, this.height});

  final DateTime? takenAt;
  final int? width;
  final int? height;
}

/// Photo formats that carry EXIF the `exif` package reads.
const Set<String> _exifExtensions = {
  'jpg',
  'jpeg',
  'jpe',
  'jfif',
  'tif',
  'tiff',
  'heic',
  'heif',
  'webp',
  'dng',
};

/// How much of the file is read: EXIF sits in the first segment.
const int exifHeadBytes = 64 * 1024;

bool hasExifExtension(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 &&
      _exifExtensions.contains(name.substring(dot + 1).toLowerCase());
}

/// Reads [path]'s first [exifHeadBytes] and parses them. Null when the file
/// has no (readable) EXIF: a photo without metadata is normal, so parse
/// failures aren't errors; the file is listed without date/size, as before.
Future<ExifMeta?> readExifMeta(String path) async {
  final List<int> head;
  try {
    final raf = File(path).openSync();
    try {
      head = raf.readSync(math.min(exifHeadBytes, raf.lengthSync()));
    } finally {
      raf.closeSync();
    }
  } on FileSystemException {
    return null;
  }
  final Map<String, IfdTag> tags;
  try {
    tags = await readExifFromBytes(head, details: false);
  } on Object {
    return null; // malformed or truncated EXIF
  }
  if (tags.isEmpty) return null;
  return exifMetaFromTags(tags);
}

@visibleForTesting
ExifMeta? exifMetaFromTags(Map<String, IfdTag> tags) {
  final takenAt =
      parseExifDate(tags['EXIF DateTimeOriginal']?.printable) ??
      parseExifDate(tags['EXIF DateTimeDigitized']?.printable) ??
      parseExifDate(tags['Image DateTime']?.printable);
  var width = _int(tags['EXIF ExifImageWidth']);
  var height = _int(tags['EXIF ExifImageLength']);
  // Orientation 5–8 = rotated by 90°: report the size as it is shown.
  final orientation = _int(tags['Image Orientation']) ?? 1;
  if (orientation >= 5 && orientation <= 8) {
    (width, height) = (height, width);
  }
  if (takenAt == null && width == null && height == null) return null;
  return ExifMeta(takenAt: takenAt, width: width, height: height);
}

int? _int(IfdTag? tag) {
  if (tag == null) return null;
  try {
    final v = tag.values.firstAsInt();
    return v > 0 ? v : null;
  } on Object {
    return null;
  }
}

final _exifDate = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})');

/// "2024:05:01 13:22:10" (camera local time, no zone) → local [DateTime].
/// Blank/zero dates ("0000:00:00 00:00:00") → null.
DateTime? parseExifDate(String? raw) {
  final m = raw == null ? null : _exifDate.firstMatch(raw.trim());
  if (m == null) return null;
  final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
  if (p[0] < 1900 || p[1] < 1 || p[1] > 12 || p[2] < 1 || p[2] > 31) {
    return null;
  }
  return DateTime(p[0], p[1], p[2], p[3], p[4], p[5]);
}
