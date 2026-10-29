import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/screenshot_rule.dart';

/// Where a file comes from (TASK-B1). Stored by index (intEnum): APPEND ONLY.
/// One bucket per kind of phone creation: no combined "made on phone".
/// Adding one later = append + a rule + a backfill in that task's migration.
enum SourceBucket {
  none,
  camera,
  screenshots,
  screenRecordings,
  whatsapp,
  snapchat,
  telegram,
  instagram,
  downloads,
  expertRaw,
  gifs,
  collages,
  clippedImages,
  liveMessages,
  videoCaptures,
}

final _volumeRoot = RegExp(
  r'^(/storage/emulated/\d+|/storage/[^/]+|/sdcard|/mnt/sdcard'
  r'|[a-z]:/users/[^/]+)(/|$)',
);
final _dcfFolder = RegExp(r'^dcim/\d{3}[a-z0-9_]{5}$');
const _screenRecordingFolders = {
  'screen recordings',
  'screenrecorder',
  'screen recorder',
  'screenrecord',
};
final _screenRecordingName = RegExp(
  r'^(screen_recording|screen-recording|screenrecord|screen-\d)',
);

/// '/storage/emulated/0/DCIM/Camera' → 'dcim/camera'. Also strips
/// `/storage/<uuid>/` (SD card, USB), `/sdcard/` and (Windows, PL1)
/// `C:/Users/<name>/`. Lower case.
String volumeRelative(String folderPath) {
  final lower = folderPath.toLowerCase().replaceAll(r'\', '/');
  final m = _volumeRoot.firstMatch(lower);
  final rel = m == null ? lower : lower.substring(m.end);
  return rel.startsWith('/') ? rel.substring(1) : rel;
}

final _volumeRootExact = RegExp(r'^(/storage/emulated/\d+|/storage/[^/]+)');

/// The storage volume [folderPath] is on: '/storage/emulated/0',
/// '/storage/1A2B-3C4D'… Elsewhere the first path segment ('/', 'C:').
String volumeRootOf(String folderPath) {
  final m = _volumeRootExact.firstMatch(folderPath);
  if (m != null) return m.group(0)!;
  final rest = folderPath.startsWith('/')
      ? folderPath.substring(1)
      : folderPath;
  final slash = rest.indexOf('/');
  final first = slash < 0 ? rest : rest.substring(0, slash);
  return folderPath.startsWith('/') ? '/$first' : first;
}

/// Pure. First matching rule wins (order matters: `Download/Telegram` is
/// telegram, `DCIM/Screenshots` is screenshots, never camera).
SourceBucket sourceFor(FileKind kind, String folderPath, String name) {
  final rel = volumeRelative(folderPath);
  final segments = rel.split('/');
  final lowerName = name.toLowerCase();
  bool under(String prefix) => rel == prefix || rel.startsWith('$prefix/');
  final media = kind == FileKind.image || kind == FileKind.video;

  if (under('whatsapp') ||
      under('whatsapp business') ||
      under('android/media/com.whatsapp') ||
      under('android/media/com.whatsapp.w4b')) {
    return SourceBucket.whatsapp;
  }
  if (under('telegram') ||
      under('android/media/org.telegram.messenger') ||
      segments.contains('telegram')) {
    return SourceBucket.telegram;
  }
  if (segments.contains('snapchat') ||
      under('android/media/com.snapchat.android')) {
    return SourceBucket.snapchat;
  }
  if (segments.contains('instagram') ||
      under('android/media/com.instagram.android')) {
    return SourceBucket.instagram;
  }
  if (isScreenshot(kind, folderPath, name)) return SourceBucket.screenshots;
  if (kind == FileKind.video &&
      (segments.any(_screenRecordingFolders.contains) ||
          _screenRecordingName.hasMatch(lowerName))) {
    return SourceBucket.screenRecordings;
  }
  if (under('dcim/expert raw')) return SourceBucket.expertRaw;
  if (media && (under('dcim/camera') || _dcfFolder.hasMatch(rel))) {
    return SourceBucket.camera;
  }
  if (under('dcim/gif')) return SourceBucket.gifs;
  if (under('dcim/collage')) return SourceBucket.collages;
  if (under('dcim/clipped images')) return SourceBucket.clippedImages;
  if (under('dcim/live message')) return SourceBucket.liveMessages;
  if (under('dcim/videocaptures')) return SourceBucket.videoCaptures;
  if (under('download') || under('downloads')) return SourceBucket.downloads;
  return SourceBucket.none;
}
