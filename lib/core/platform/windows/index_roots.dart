import 'dart:async';
import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'index_roots.g.dart';

/// The `%USERPROFILE%` sub-folders standing in for the known folders when
/// the native channel can't say (not built yet, or it failed). English
/// names: localized Windows still uses them on disk.
Map<KnownFolder, String> fallbackKnownFolders(Map<String, String> env) {
  final home = env['USERPROFILE'];
  if (home == null || home.isEmpty) return const {};
  final base = normalizeWindowsPath(home);
  return {
    KnownFolder.pictures: '$base/Pictures',
    KnownFolder.videos: '$base/Videos',
    KnownFolder.downloads: '$base/Downloads',
    KnownFolder.documents: '$base/Documents',
  };
}

/// What the Windows index scans (TASK-PL1 → Indexed locations):
/// [AppSettings.windowsIndexRoots], or the known folders while it's empty.
class WindowsIndexRoots {
  new({
    required this._settings,
    required this._channel,
    Map<String, String>? environment,
  }) : _environment = environment ?? Platform.environment;

  final SettingsRepository _settings;
  final WindowsChannel _channel;
  final Map<String, String> _environment;

  Future<Map<KnownFolder, String>>? _known;

  /// Pictures, Videos, Downloads, Documents (asked once).
  Future<Map<KnownFolder, String>> knownFolders() => _known ??= () async {
    try {
      final known = await _channel.knownFolders();
      if (known.isNotEmpty) return known;
    } on WindowsChannelException {
      // Fall through to the profile folders.
    }
    return fallbackKnownFolders(_environment);
  }();

  Future<List<String>> defaults() async {
    final known = await knownFolders();
    return [for (final k in KnownFolder.values) ?known[k]];
  }

  Future<List<String>> current() async =>
      await effective(await _settings.read(AppSettings.windowsIndexRoots));

  Stream<List<String>> watch() =>
      _settings.watch(AppSettings.windowsIndexRoots).asyncMap(effective);

  /// [stored] cleaned up (normalized, nested roots dropped), or the
  /// defaults when empty.
  Future<List<String>> effective(List<String> stored) async =>
      outermostRoots(stored.isEmpty ? await defaults() : stored);

  /// Adds [folder]; the first change turns the defaults into an explicit
  /// list. No-op if it's already scanned (also as part of another root).
  Future<void> add(String folder) async {
    final roots = await current();
    final path = normalizeWindowsPath(folder);
    if (isUnderAnyRoot(path, roots)) return;
    await _settings.write(AppSettings.windowsIndexRoots, [...roots, path]);
  }

  /// Removes [folder]. The last root can't be removed (an empty list means
  /// "the defaults").
  Future<void> remove(String folder) async {
    final roots = await current();
    final left = [
      for (final r in roots)
        if (!sameWindowsPath(r, folder)) r,
    ];
    if (left.isEmpty || left.length == roots.length) return;
    await _settings.write(AppSettings.windowsIndexRoots, left);
  }

  Future<void> resetToDefaults() =>
      _settings.write(AppSettings.windowsIndexRoots, const <String>[]);
}

/// One root as the settings section shows it.
@immutable
class IndexRootStatus {
  const new(this.path, {required this.available});

  final String path;

  /// False: the folder is gone or its drive is unplugged.
  final bool available;

  @override
  bool operator ==(Object other) =>
      other is IndexRootStatus &&
      other.path == path &&
      other.available == available;

  @override
  int get hashCode => Object.hash(path, available);
}

/// How long file-system events are collected before the index hears of
/// them (a copy of 500 photos is one rescan, not 500).
const windowsChangeDebounce = Duration(seconds: 2);

/// Live changes under the index roots (`ReadDirectoryChangesW` through
/// `Directory.watch`), debounced into [MediaChange]s for F5's indexer:
/// creates/edits/moves → one `insert` (an incremental scan), deletes → one
/// `delete` without id (a media rescan). Follows [roots]: watchers start
/// and stop as roots change; a root that disappears stops its watcher.
Stream<MediaChange> windowsDirectoryChanges(
  Stream<List<String>> roots, {
  Duration debounce = windowsChangeDebounce,
  Stream<FileSystemEvent> Function(String root)? watch,
}) {
  final watchRoot =
      watch ?? (root) => Directory(windowsIoPath(root)).watch(recursive: true);
  late final StreamController<MediaChange> controller;
  // Cancelled in the controller's onCancel.
  // ignore: cancel_subscriptions
  StreamSubscription<List<String>>? rootsSub;
  final watchers = <String, StreamSubscription<FileSystemEvent>>{};
  Timer? timer;
  var sawDelete = false;
  var sawChange = false;

  void flush() {
    if (sawChange) controller.add(const MediaChange(type: 'insert'));
    if (sawDelete) controller.add(const MediaChange(type: 'delete'));
    sawChange = false;
    sawDelete = false;
  }

  void onEvent(FileSystemEvent e) {
    if (e is FileSystemDeleteEvent) {
      sawDelete = true;
    } else if (e is FileSystemMoveEvent) {
      // The old path is gone, the new one is new.
      sawDelete = true;
      sawChange = true;
    } else {
      sawChange = true;
    }
    timer?.cancel();
    timer = Timer(debounce, flush);
  }

  Future<void> stop(String root) async {
    await watchers.remove(root)?.cancel();
  }

  void follow(List<String> next) {
    final wanted = {for (final r in next) normalizeWindowsPath(r)};
    for (final root in watchers.keys.toList()) {
      if (!wanted.contains(root)) unawaited(stop(root));
    }
    for (final root in wanted) {
      if (watchers.containsKey(root)) continue;
      if (!Directory(windowsIoPath(root)).existsSync()) continue;
      try {
        watchers[root] = watchRoot(root).listen(
          onEvent,
          // The folder went away (drive unplugged): stop watching it; the
          // next roots change or app start picks it up again.
          onError: (Object _) => unawaited(stop(root)),
          onDone: () => watchers.remove(root),
        );
      } on FileSystemException {
        // Not watchable right now; the next scan still sees it.
      }
    }
  }

  controller = StreamController<MediaChange>(
    onListen: () {
      rootsSub = roots.listen(follow);
    },
    onCancel: () async {
      timer?.cancel();
      // All cancels start right away; then wait for them together.
      final cancels = [
        if (rootsSub case final s?) s.cancel(),
        for (final s in watchers.values) s.cancel(),
      ];
      watchers.clear();
      await Future.wait(cancels);
    },
  );
  return controller.stream;
}

@Riverpod(keepAlive: true)
WindowsChannel windowsChannel(Ref ref) => WindowsChannel();

@Riverpod(keepAlive: true)
WindowsIndexRoots windowsIndexRoots(Ref ref) => WindowsIndexRoots(
  settings: ref.watch(settingsRepositoryProvider),
  channel: ref.watch(windowsChannelProvider),
);

/// The roots for the "Folders KFM scans" section, with availability.
@riverpod
Stream<List<IndexRootStatus>> windowsIndexRootStatus(Ref ref) => ref
    .watch(windowsIndexRootsProvider)
    .watch()
    .map(
      (roots) => [
        for (final r in roots)
          IndexRootStatus(
            r,
            available: Directory(windowsIoPath(r)).existsSync(),
          ),
      ],
    );
