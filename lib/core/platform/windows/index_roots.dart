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

/// What the Windows index covers (TASK-E2 §6, replaces "Folders KFM
/// scans").
enum IndexScope {
  /// The user profile and every other fixed drive (system folders skipped).
  everywhere,

  /// Only the folders open in desktop Browse; no background full scan.
  whereIAm,

  /// [AppSettings.windowsIndexRoots] (or the known folders while empty).
  chosenFolders,
}

/// The scope from the stored [AppSettings.windowsIndexScope] value: '' (never
/// chosen) → [IndexScope.chosenFolders] when the user had custom [roots],
/// else [IndexScope.everywhere]; an unknown name → everywhere. No startup
/// write, so no migration order can go wrong.
IndexScope effectiveIndexScope(String stored, List<String> roots) {
  if (stored.isEmpty) {
    return roots.isEmpty ? IndexScope.everywhere : IndexScope.chosenFolders;
  }
  return IndexScope.values.asNameMap()[stored] ?? IndexScope.everywhere;
}

/// What the Windows index scans (TASK-PL1 → Indexed locations, E2 §6): by
/// [IndexScope], everywhere ([everywhere]), the folders open in Browse
/// ([setOpenFolders]) or the chosen folders ([chosen]).
class WindowsIndexRoots {
  new({
    required this._settings,
    required this._channel,
    Map<String, String>? environment,
  }) : _environment = environment ?? Platform.environment;

  final SettingsRepository _settings;
  final WindowsChannel _channel;
  final Map<String, String> _environment;

  List<String> _open = const [];
  final StreamController<void> _openChanges =
      StreamController<void>.broadcast();

  /// [IndexScope.whereIAm]: the folders open in desktop Browse now.
  List<String> get openFolders => _open;

  /// Desktop Browse tells which folders are open (E3: one per tab).
  void setOpenFolders(List<String> folders) {
    final next = outermostRoots([
      for (final f in folders) normalizeWindowsPath(f),
    ]);
    if (_sameList(next, _open)) return;
    _open = List.unmodifiable(next);
    _openChanges.add(null);
  }

  Future<IndexScope> scope() async => effectiveIndexScope(
    await _settings.read(AppSettings.windowsIndexScope),
    await _settings.read(AppSettings.windowsIndexRoots),
  );

  Stream<IndexScope> watchScope() => _changes().asyncMap((_) => scope());

  Future<void> setScope(IndexScope scope) =>
      _settings.write(AppSettings.windowsIndexScope, scope.name);

  /// The user profile and every other fixed, mounted drive root (not the
  /// system drive's root: only the profile on it).
  Future<List<String>> everywhere() async {
    final home = _environment['USERPROFILE'];
    var drives = const <WindowsDrive>[];
    try {
      drives = await _channel.listDrives();
    } on WindowsChannelException {
      // Only the profile.
    }
    return outermostRoots([
      if (home != null && home.isNotEmpty) normalizeWindowsPath(home),
      for (final d in drives)
        if (!d.isSystem && !d.isRemovable && d.isMounted && d.type == 'fixed')
          normalizeWindowsPath(d.path),
    ]);
  }

  /// [AppSettings.windowsIndexRoots] cleaned up, or the known folders.
  Future<List<String>> chosen() async =>
      await effective(await _settings.read(AppSettings.windowsIndexRoots));

  Stream<List<String>> watchChosen() =>
      _settings.watch(AppSettings.windowsIndexRoots).asyncMap(effective);

  /// Any change of the scope, the chosen roots or the open folders.
  Stream<void> _changes() {
    late final StreamController<void> c;
    final subs = <StreamSubscription<Object?>>[];
    c = StreamController<void>(
      onListen: () {
        void ping(Object? _) => c.add(null);
        subs
          ..add(_settings.watch(AppSettings.windowsIndexScope).listen(ping))
          ..add(_settings.watch(AppSettings.windowsIndexRoots).listen(ping))
          ..add(_openChanges.stream.listen(ping));
      },
      onCancel: () => Future.wait([for (final s in subs) s.cancel()]),
    );
    return c.stream;
  }

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

  /// What a full scan walks now.
  Future<List<String>> current() async => switch (await scope()) {
    IndexScope.everywhere => await everywhere(),
    IndexScope.chosenFolders => await chosen(),
    IndexScope.whereIAm => _open,
  };

  /// [current] on every change (repeats dropped).
  Stream<List<String>> watch() {
    List<String>? last;
    return _changes().asyncMap((_) => current()).where((roots) {
      if (last != null && _sameList(last!, roots)) return false;
      last = roots;
      return true;
    });
  }

  /// [stored] cleaned up (normalized, nested roots dropped), or the
  /// defaults when empty.
  Future<List<String>> effective(List<String> stored) async =>
      outermostRoots(stored.isEmpty ? await defaults() : stored);

  /// Adds [folder] to the chosen folders; the first change turns the
  /// defaults into an explicit list. No-op if it's already chosen (also as
  /// part of another root).
  Future<void> add(String folder) async {
    final roots = await chosen();
    final path = normalizeWindowsPath(folder);
    if (isUnderAnyRoot(path, roots)) return;
    await _settings.write(AppSettings.windowsIndexRoots, [...roots, path]);
  }

  /// Removes [folder]. The last root can't be removed (an empty list means
  /// "the defaults").
  Future<void> remove(String folder) async {
    final roots = await chosen();
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

/// Drives (or folders) whose directory watchers are stopped. PL1: an
/// open watcher handle on a removable drive makes Windows refuse its eject
/// as "in use", so the eject flow pauses the drive first and resumes it
/// when the eject fails or is cancelled.
class WatchPauses {
  final Set<String> _paused = {};
  final List<Future<void> Function()> _listeners = [];

  /// Whether [path] lies under a paused drive/folder.
  bool isPaused(String path) => isUnderAnyRoot(path, _paused.toList());

  Set<String> get paused => Set.unmodifiable(_paused);

  /// Stops the watchers under [root]; completes once they're cancelled.
  Future<void> pause(String root) async {
    if (_paused.add(normalizeWindowsPath(root))) await _notify();
  }

  /// Lets the watchers under [root] start again (where the folder exists).
  Future<void> resume(String root) async {
    final before = _paused.length;
    _paused.removeWhere((r) => sameWindowsPath(r, root));
    if (_paused.length != before) await _notify();
  }

  /// [onChange] runs (and is awaited) after every pause/resume; the
  /// returned function removes it.
  void Function() addListener(Future<void> Function() onChange) {
    _listeners.add(onChange);
    return () => _listeners.remove(onChange);
  }

  Future<void> _notify() => Future.wait([
    for (final l in [..._listeners]) l(),
  ]);
}

/// How long file-system events are collected before the index hears of
/// them (a copy of 500 photos is one rescan, not 500).
const windowsChangeDebounce = Duration(seconds: 2);

/// Live changes under the index roots (`ReadDirectoryChangesW` through
/// `Directory.watch`), debounced into [MediaChange]s for F5's indexer:
/// creates/edits/moves → one `insert` (an incremental scan), deletes → one
/// `delete` without id (a media rescan). Follows [roots]: watchers start
/// and stop as roots change; a root that disappears stops its watcher.
/// Roots under a drive in [pauses] aren't watched (see [WatchPauses]).
Stream<MediaChange> windowsDirectoryChanges(
  Stream<List<String>> roots, {
  Duration debounce = windowsChangeDebounce,
  Stream<FileSystemEvent> Function(String root)? watch,
  WatchPauses? pauses,
}) {
  final watchRoot =
      watch ?? (root) => Directory(windowsIoPath(root)).watch(recursive: true);
  late final StreamController<MediaChange> controller;
  // Cancelled in the controller's onCancel.
  // ignore: cancel_subscriptions
  StreamSubscription<List<String>>? rootsSub;
  void Function()? removePauseListener;
  var lastRoots = const <String>[];
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

  Future<void> follow(List<String> next) {
    lastRoots = next;
    final wanted = {
      for (final r in next)
        if (!(pauses?.isPaused(r) ?? false)) normalizeWindowsPath(r),
    };
    final stops = [
      for (final root in watchers.keys.toList())
        if (!wanted.contains(root)) stop(root),
    ];
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
    return Future.wait(stops);
  }

  controller = StreamController<MediaChange>(
    onListen: () {
      rootsSub = roots.listen((next) => unawaited(follow(next)));
      removePauseListener = pauses?.addListener(() => follow(lastRoots));
    },
    onCancel: () async {
      timer?.cancel();
      removePauseListener?.call();
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

/// The drives whose directory watchers are paused (PL1 eject).
@Riverpod(keepAlive: true)
WatchPauses watchPauses(Ref ref) => WatchPauses();

@Riverpod(keepAlive: true)
WindowsIndexRoots windowsIndexRoots(Ref ref) => WindowsIndexRoots(
  settings: ref.watch(settingsRepositoryProvider),
  channel: ref.watch(windowsChannelProvider),
);

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!sameWindowsPath(a[i], b[i])) return false;
  }
  return true;
}

/// The scope, live (Settings → Privacy & access → Look everywhere).
@riverpod
Stream<IndexScope> windowsIndexScope(Ref ref) =>
    ref.watch(windowsIndexRootsProvider).watchScope();

/// The chosen folders with availability ("Choose folders instead…").
@riverpod
Stream<List<IndexRootStatus>> windowsChosenRootStatus(Ref ref) =>
    ref.watch(windowsIndexRootsProvider).watchChosen().map(_withStatus);

List<IndexRootStatus> _withStatus(List<String> roots) => [
  for (final r in roots)
    IndexRootStatus(r, available: Directory(windowsIoPath(r)).existsSync()),
];

/// The scanned roots with availability (desktop Places). While only open
/// folders are indexed, the known folders stand in, so Places still has
/// somewhere to start.
@riverpod
Stream<List<IndexRootStatus>> windowsIndexRootStatus(Ref ref) {
  final roots = ref.watch(windowsIndexRootsProvider);
  return roots.watch().asyncMap(
    (current) async => _withStatus(
      await roots.scope() == IndexScope.whereIAm
          ? outermostRoots(await roots.defaults())
          : current,
    ),
  );
}
