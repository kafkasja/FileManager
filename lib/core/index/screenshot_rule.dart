import 'package:kfm/core/files/file_ref.dart';

/// Folder names that hold screenshots (lower case).
const screenshotFolders = {'screenshots', 'screenshot', 'screen captures'};

/// TASK-P5: an image in a Screenshots folder (any level) or named
/// `Screenshot…`. Kept in step with the v9 backfill SQL in AppDatabase (a
/// test checks both agree).
bool isScreenshot(FileKind kind, String folderPath, String name) {
  if (kind != FileKind.image) return false;
  if (name.toLowerCase().startsWith('screenshot')) return true;
  return folderPath.toLowerCase().split('/').any(screenshotFolders.contains);
}
