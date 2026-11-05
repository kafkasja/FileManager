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

/// TASK-E2 §6: Windows folders a desktop index scan ("Look everywhere")
/// never walks into: the OS, programs, app data, the Recycle Bin. [path] is
/// '/'-separated (`C:/Windows`, `C:/Users/me/AppData`).
bool isWindowsSystemFolder(String path) {
  final lower = path.toLowerCase();
  final slash = lower.lastIndexOf('/');
  final name = lower.substring(slash + 1);
  if (_anywhere.contains(name)) return true;
  // Directly under a drive root (`c:/windows`).
  return slash == 2 && lower[1] == ':' && _atDriveRoot.contains(name);
}

const Set<String> _atDriveRoot = {
  'windows',
  'program files',
  'program files (x86)',
  'programdata',
  'recovery',
  'perflogs',
  r'$windows.~bt',
  r'$windows.~ws',
};

const Set<String> _anywhere = {
  'appdata',
  r'$recycle.bin',
  'system volume information',
  '.kfmtrash',
};

/// MediaStore's trashed/pending files (Android 11+) and KFM's unfinished
/// copies ([tempFilePrefix]): never shown, never zipped.
bool isSystemTempName(String name) =>
    name.startsWith('.trashed-') ||
    name.startsWith('.pending-') ||
    name.startsWith(tempFilePrefix);

/// Folder names that only ever hold tool output (package and build
/// caches).
const Set<String> _toolOutputNames = {
  'node_modules',
  '.dart_tool',
  '.gradle',
  '__pycache__',
  '.pub-cache',
};

/// Folder names that are build output when a project file sits next to
/// them (`*` = any name with that ending).
const Map<String, List<String>> _buildOutputMarkers = {
  'build': [
    'pubspec.yaml',
    'build.gradle',
    'build.gradle.kts',
    'settings.gradle',
    'settings.gradle.kts',
    'CMakeLists.txt',
    'package.json',
    'setup.py',
    'pyproject.toml',
  ],
  'target': ['Cargo.toml', 'pom.xml'],
  'obj': ['*.csproj'],
  'bin': ['*.csproj'],
};

/// Build output inside a developer's project (`build/` next to a
/// `pubspec.yaml`, `node_modules`, `.dart_tool`…): thousands of generated
/// files that aren't the user's (TASK-PL3, desktop index scans). [name] is
/// the folder's name, [siblings] the names in its parent folder. A plain
/// `build` folder with no project file next to it is kept.
bool isBuildOutputFolder(String name, Iterable<String> siblings) {
  if (_toolOutputNames.contains(name)) return true;
  final markers = _buildOutputMarkers[name];
  if (markers == null) return false;
  for (final entry in siblings) {
    final lower = entry.toLowerCase();
    for (final m in markers) {
      final hit = m.startsWith('*')
          ? lower.endsWith(m.substring(1).toLowerCase())
          : lower == m.toLowerCase();
      if (hit) return true;
    }
  }
  return false;
}
