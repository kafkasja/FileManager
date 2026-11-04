import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// A photo or video whose content is gone (desktop fixes): e.g. a USB
/// stick that lost data and now holds files of only zero bytes. The UI
/// says "it may be damaged" instead of showing a black screen.
class DamagedFileException implements Exception {
  const new(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'DamagedFileException($reason): $path';
}

/// How much of the start of a file [looksDamaged] reads.
const int kDamageProbeBytes = 64 * 1024;

/// Cheap check (one read of at most [probeBytes]): true for an empty file
/// or one whose first [probeBytes] are all zero bytes — no photo or video
/// format starts like that. False when the file can't be read (the player
/// or decoder reports that itself).
Future<bool> looksDamaged(
  String path, {
  int probeBytes = kDamageProbeBytes,
}) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final length = await raf.length();
    if (length == 0) return true;
    final bytes = await raf.read(math.min(length, probeBytes));
    return isAllZero(bytes);
  } on FileSystemException {
    return false;
  } finally {
    await raf?.close();
  }
}

/// True when every byte of [bytes] is 0 (and there is at least one).
bool isAllZero(Uint8List bytes) {
  if (bytes.isEmpty) return false;
  for (final b in bytes) {
    if (b != 0) return false;
  }
  return true;
}
