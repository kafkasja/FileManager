import 'package:kfm/core/files/file_names.dart';

/// Skip rules for files and folders that aren't the user's: shared by the
/// file walker (B1) and the zip worker (B5), so a folder zips exactly what
/// Browse shows (hidden user files included).

/// Folders never walked into: `Android/data` / `Android/obb` (not readable
/// on Android 11+), KFM's pending-delete folder (`.KFMTrash`) and thumbnail
/// caches (`.thumbnails`). [path] is '/'-separated.
bool isExcludedFolderPath(String path) =>
    path.endsWith('/Android/data') ||
    path.endsWith('/Android/obb') ||
    path.endsWith('/.KFMTrash') ||
    path.endsWith('/.thumbnails');

/// MediaStore's trashed/pending files (Android 11+) and KFM's unfinished
/// copies ([tempFilePrefix]): never shown, never zipped.
bool isSystemTempName(String name) =>
    name.startsWith('.trashed-') ||
    name.startsWith('.pending-') ||
    name.startsWith(tempFilePrefix);
