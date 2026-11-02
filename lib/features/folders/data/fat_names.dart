import 'dart:io';

/// FAT32 can't hold files of 4 GiB or more.
const int kFat32MaxFileBytes = 0xFFFFFFFF;

final _fatInvalid = RegExp('[:*?"<>|]');
final _trailing = RegExp(r'[. ]+$');

/// [name] made valid on FAT/exFAT (TASK-U2): `: * ? " < > |` and trailing
/// dots/spaces become `_`. Unchanged when it already is.
String fatSafeName(String name) {
  var out = name.replaceAll(_fatInvalid, '_');
  final trail = _trailing.firstMatch(out);
  if (trail != null) {
    out = '${out.substring(0, trail.start)}${'_' * (trail.end - trail.start)}';
  }
  return out;
}

/// Whether the volume holding [folder] (`/storage/<uuid>/…`) is FAT32,
/// from `/proc/mounts` (its `/mnt/media_rw/<uuid>` backing mount or the
/// root itself). False when unknown. [mounts] overrides the file (tests).
Future<bool> isFat32Volume(
  String folder, {
  Future<String> Function()? mounts,
}) async {
  final m = RegExp('^/storage/([^/]+)').firstMatch(folder);
  final uuid = m?.group(1);
  if (uuid == null || uuid == 'emulated' || uuid == 'self') return false;
  final String text;
  try {
    text = await (mounts ?? () => File('/proc/mounts').readAsString())();
  } on FileSystemException {
    return false;
  }
  for (final line in text.split('\n')) {
    final parts = line.split(' ');
    if (parts.length < 3) continue;
    final point = parts[1];
    if (point != '/mnt/media_rw/$uuid' && point != '/storage/$uuid') continue;
    if (parts[2] == 'vfat') return true;
  }
  return false;
}
