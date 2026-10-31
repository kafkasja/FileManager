import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:kfm/core/files/file_names.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'temp_file_ledger.g.dart';

final _random = Random.secure();

/// `<folder>/.kfm-tmp-<16 hex><extension>`: where a copy is written before
/// its rename. [extension] (`.jpg`, from the final name) keeps the file's
/// type the same through the rename: MediaProvider (FUSE, API 30+) checks
/// types per folder (DCIM/Pictures take media only) unless the app has All
/// files access. The dot prefix keeps the temp file hidden, so the media
/// scanner and the walker skip it. Long extensions are dropped.
String tempPathIn(String folder, {String extension = ''}) {
  final hex = [
    for (var i = 0; i < 8; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  final ext = extension.length <= _maxTempExtension ? extension : '';
  return '$folder/$tempFilePrefix$hex$ext';
}

const _maxTempExtension = 16;

/// Paths of unfinished temp files, kept in `kfm_temp_ledger.json` in the app
/// support dir (no DB: F3 doesn't depend on drift). Add before writing,
/// remove after the rename or the cleanup. Calls run one at a time.
class TempFileLedger {
  new(this.file);

  /// The JSON list on disk.
  final File file;

  /// Null until the first call loads the file.
  Set<String>? _paths;

  /// Paths found on disk at load: left by an earlier run. Only these are
  /// cleaned up, so a copy that started in this run is never touched.
  Set<String> _stale = const {};

  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Set<String>> _load() async {
    if (_paths case final paths?) return paths;
    final paths = <String>{};
    if (await file.exists()) {
      final text = await file.readAsString();
      try {
        final list = jsonDecode(text) as List<Object?>;
        paths.addAll(list.whereType<String>());
      } on FormatException catch (e) {
        // A torn write: the entries are lost, the temp files stay hidden.
        developer.log('temp ledger unreadable: $e', name: 'kfm.files');
      }
    }
    _stale = {...paths};
    return _paths = paths;
  }

  Future<void> _save(Set<String> paths) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.new');
    await tmp.writeAsString(jsonEncode(paths.toList()), flush: true);
    await tmp.rename(file.path);
  }

  /// Records [path] before anything is written there.
  Future<void> add(String path) => _serial(() async {
    final paths = await _load();
    if (paths.add(path)) await _save(paths);
  });

  /// Forgets [path] once it was renamed or deleted.
  Future<void> remove(String path) => _serial(() async {
    final paths = await _load();
    _stale.remove(path);
    if (paths.remove(path)) await _save(paths);
  });

  /// Paths currently listed (tests, diagnostics).
  Future<Set<String>> entries() => _serial(() async => {...await _load()});

  /// Deletes every path an earlier run left listed that still exists (file
  /// or folder), then forgets it. Errors per path are logged and the path
  /// kept for the next run. Returns how many paths were deleted.
  Future<int> cleanUp() => _serial(() async {
    final paths = await _load();
    var deleted = 0;
    for (final path in [..._stale]) {
      try {
        final type = await FileSystemEntity.type(path, followLinks: false);
        if (type == FileSystemEntityType.directory) {
          await Directory(path).delete(recursive: true);
          deleted++;
        } else if (type != FileSystemEntityType.notFound) {
          await File(path).delete();
          deleted++;
        }
        paths.remove(path);
        _stale.remove(path);
      } on FileSystemException catch (e) {
        developer.log('temp cleanup failed for $path: $e', name: 'kfm.files');
      }
    }
    await _save(paths);
    if (deleted > 0) {
      developer.log('removed $deleted unfinished copies', name: 'kfm.files');
    }
    return deleted;
  });
}

/// The app's ledger (Android). Null elsewhere for now (no `path:` copies).
@Riverpod(keepAlive: true)
Future<TempFileLedger?> tempFileLedger(Ref ref) async {
  if (!Platform.isAndroid) return null;
  final dir = await getApplicationSupportDirectory();
  return TempFileLedger(File('${dir.path}/kfm_temp_ledger.json'));
}
