import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_tabs_controller.g.dart';

/// One desktop tab (TASK-E3).
@immutable
class DesktopTab {
  const new({
    required this.id,
    required this.location,
    this.back = const [],
    this.forward = const [],
  });

  /// Unique per run; the key for per-tab selection and scroll.
  final String id;
  final DesktopLocation location;

  /// Back / Forward history (not stored between runs).
  final List<DesktopLocation> back;
  final List<DesktopLocation> forward;

  DesktopTab copyWith({
    DesktopLocation? location,
    List<DesktopLocation>? back,
    List<DesktopLocation>? forward,
  }) => DesktopTab(
    id: id,
    location: location ?? this.location,
    back: back ?? this.back,
    forward: forward ?? this.forward,
  );
}

@immutable
class DesktopTabsState {
  const new({required this.tabs, required this.active});

  final List<DesktopTab> tabs;
  final int active;

  DesktopTab get current => tabs[active];
}

/// Checks a restored folder still exists (replaced in tests).
typedef FolderExists = Future<bool> Function(String path);

@Riverpod(keepAlive: true)
FolderExists desktopFolderExists(Ref ref) => (path) async {
  try {
    return await Directory(path).exists();
  } on Object {
    return false;
  }
};

/// The desktop window's tabs (TASK-E3): navigation, back/forward per tab,
/// single-instance Sort/Trash/Devices/Settings, reopen closed tabs, and
/// restore after a restart (`desktop.tabs`, debounced 500 ms).
@Riverpod(keepAlive: true)
class DesktopTabsController extends _$DesktopTabsController {
  /// Tabs kept in the window at most.
  static const maxTabs = 50;

  /// Closed tabs remembered for Ctrl+Shift+T (this run only).
  static const maxClosed = 10;

  static const _storeVersion = 1;

  var _nextId = 0;
  final List<(int, DesktopTab)> _closed = [];
  final _saver = Debouncer(const Duration(milliseconds: 500));

  /// The Home tab that replaced a closed last tab (reopening replaces it).
  String? _autoHomeId;

  /// Changed by the user before the stored tabs came back: those win.
  var _touched = false;

  /// The stored tabs have been read (or there were none).
  final Completer<void> restored = Completer();

  String _newId() => 't${_nextId++}';

  /// A fresh install opens on Sort (KFM's main feature); Ctrl+T and a
  /// closed last tab give Home, like Explorer.
  @override
  DesktopTabsState build() {
    ref.onDispose(_saver.flushNow);
    unawaited(_restore());
    return DesktopTabsState(
      tabs: [DesktopTab(id: _newId(), location: const SortLocation())],
      active: 0,
    );
  }

  Future<void> _restore() async {
    try {
      final raw = await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.desktopTabs);
      if (raw.isEmpty || !ref.mounted || _touched) return;
      final parsed = await _parse(raw);
      if (!ref.mounted || _touched || parsed == null) return;
      state = parsed;
    } on Object catch (e, st) {
      // A bad store = one Home tab (logged, not shown).
      if (ref.mounted && !_touched) {
        state = DesktopTabsState(
          tabs: [DesktopTab(id: _newId(), location: const HomeLocation())],
          active: 0,
        );
      }
      ref
          .read(errorLogProvider)
          .record(
            ErrorLogEntry(
              at: DateTime.now().toUtc(),
              source: ErrorSource.flutter,
              error: 'desktop tabs restore: $e',
              stack: st,
            ),
          )
          .ignore();
    } finally {
      if (!restored.isCompleted) restored.complete();
    }
  }

  Future<DesktopTabsState?> _parse(String raw) async {
    final json = jsonDecode(raw);
    if (json is! Map<String, Object?> || json['v'] != _storeVersion) {
      throw FormatException('bad desktop.tabs: $raw');
    }
    final list = json['tabs'];
    if (list is! List<Object?>) throw FormatException('bad tabs: $raw');
    final exists = ref.read(desktopFolderExistsProvider);
    final tabs = <DesktopTab>[];
    for (final t in list.take(maxTabs)) {
      if (t is! Map<String, Object?>) continue;
      var loc = DesktopLocation.fromJson(t);
      if (loc is FolderLocation && !await exists(loc.path)) {
        loc = const HomeLocation();
      }
      if (loc.singleInstance && tabs.any((x) => x.location == loc)) continue;
      tabs.add(DesktopTab(id: _newId(), location: loc));
    }
    if (tabs.isEmpty) {
      return DesktopTabsState(
        tabs: [DesktopTab(id: _newId(), location: const HomeLocation())],
        active: 0,
      );
    }
    final active = switch (json['active']) {
      final int a => a.clamp(0, tabs.length - 1),
      _ => 0,
    };
    return DesktopTabsState(tabs: List.unmodifiable(tabs), active: active);
  }

  /// The stored form of [s] (back/forward stacks left out).
  @visibleForTesting
  static String encode(DesktopTabsState s) => jsonEncode({
    'v': _storeVersion,
    'active': s.active,
    'tabs': [for (final t in s.tabs) t.location.toJson()],
  });

  void _set(DesktopTabsState next) {
    _touched = true;
    state = next;
    _saver.run(() {
      if (!ref.mounted) return;
      ref
          .read(settingsRepositoryProvider)
          .write(AppSettings.desktopTabs, encode(state))
          .fireAndForget();
    });
  }

  /// Writes a pending change now (window closing).
  void flush() => _saver.flushNow();

  List<DesktopTab> get _tabs => state.tabs;

  /// Opens [loc] in the active tab (Back returns). A single-instance
  /// location open in another tab focuses that tab instead.
  void navigate(DesktopLocation loc) {
    if (_focusSingle(loc)) return;
    final cur = state.current;
    if (cur.location == loc) return;
    _replaceActive(
      cur.copyWith(
        location: loc,
        back: [...cur.back, cur.location],
        forward: const [],
      ),
    );
  }

  /// Shows [loc] in the active tab without a Back entry (a route change
  /// that doesn't count as navigation, e.g. the router's own redirect).
  void replace(DesktopLocation loc) {
    if (_focusSingle(loc)) return;
    final cur = state.current;
    if (cur.location == loc) return;
    _replaceActive(cur.copyWith(location: loc));
  }

  bool _focusSingle(DesktopLocation loc) {
    if (!loc.singleInstance) return false;
    final i = _tabs.indexWhere((t) => t.location == loc);
    if (i < 0) return false;
    if (i != state.active) activate(i);
    return true;
  }

  void _replaceActive(DesktopTab tab) {
    final tabs = [..._tabs]..[state.active] = tab;
    _set(DesktopTabsState(tabs: List.unmodifiable(tabs), active: state.active));
  }

  /// A new tab after the active one (Ctrl+T: Home).
  void openInNewTab(DesktopLocation loc, {bool activate = true}) {
    if (_focusSingle(loc)) return;
    if (_tabs.length >= maxTabs) {
      navigate(loc);
      return;
    }
    final at = state.active + 1;
    final tabs = [..._tabs]
      ..insert(at, DesktopTab(id: _newId(), location: loc));
    _set(
      DesktopTabsState(
        tabs: List.unmodifiable(tabs),
        active: activate ? at : state.active,
      ),
    );
  }

  /// A copy of the tab at [index] (its history too) right after it.
  void duplicate(int index) {
    final t = _tabs[index];
    if (t.location.singleInstance || _tabs.length >= maxTabs) return;
    final tabs = [..._tabs]
      ..insert(
        index + 1,
        DesktopTab(
          id: _newId(),
          location: t.location,
          back: t.back,
          forward: t.forward,
        ),
      );
    _set(DesktopTabsState(tabs: List.unmodifiable(tabs), active: index + 1));
  }

  /// Closes the tab [id]; the last tab becomes a Home tab (never an empty
  /// window).
  void close(String id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _remember(i, _tabs[i]);
    if (_tabs.length == 1) {
      final home = DesktopTab(id: _newId(), location: const HomeLocation());
      _set(DesktopTabsState(tabs: [home], active: 0));
      _autoHomeId = home.id;
      return;
    }
    final tabs = [..._tabs]..removeAt(i);
    var active = state.active;
    if (i < active || (i == active && active == tabs.length)) active--;
    _set(DesktopTabsState(tabs: List.unmodifiable(tabs), active: active));
  }

  void closeOthers(int index) {
    final keep = _tabs[index];
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (i != index) _remember(i, _tabs[i]);
    }
    _set(DesktopTabsState(tabs: [keep], active: 0));
  }

  void closeToTheRight(int index) {
    if (index >= _tabs.length - 1) return;
    for (var i = _tabs.length - 1; i > index; i--) {
      _remember(i, _tabs[i]);
    }
    final tabs = _tabs.sublist(0, index + 1);
    _set(
      DesktopTabsState(
        tabs: List.unmodifiable(tabs),
        active: state.active.clamp(0, index),
      ),
    );
  }

  void _remember(int index, DesktopTab tab) {
    _closed.add((index, tab));
    if (_closed.length > maxClosed) _closed.removeAt(0);
  }

  bool get canReopen => _closed.isNotEmpty;

  /// Ctrl+Shift+T: the last closed tab, where it was.
  void reopenClosed() {
    if (_closed.isEmpty) return;
    final (index, tab) = _closed.removeLast();
    if (_focusSingle(tab.location)) return;
    // A lone Home tab left by closing the last one is replaced.
    final lone =
        _tabs.length == 1 &&
        _tabs.single.id == _autoHomeId &&
        _tabs.single.location is HomeLocation;
    final restoredTab = DesktopTab(
      id: _newId(),
      location: tab.location,
      back: tab.back,
      forward: tab.forward,
    );
    if (lone) {
      _set(DesktopTabsState(tabs: [restoredTab], active: 0));
      return;
    }
    final at = index.clamp(0, _tabs.length);
    final tabs = [..._tabs]..insert(at, restoredTab);
    _set(DesktopTabsState(tabs: List.unmodifiable(tabs), active: at));
  }

  void activate(int index) {
    if (index < 0 || index >= _tabs.length || index == state.active) return;
    _set(DesktopTabsState(tabs: _tabs, active: index));
  }

  /// Ctrl+Tab / Ctrl+Shift+Tab.
  void cycle({bool backwards = false}) {
    final n = _tabs.length;
    if (n < 2) return;
    activate((state.active + (backwards ? n - 1 : 1)) % n);
  }

  /// Drag-to-reorder: the tab at [from] ends up at [to].
  void move(int from, int to) {
    if (from == to || from < 0 || from >= _tabs.length) return;
    final activeId = state.current.id;
    final tabs = [..._tabs];
    final t = tabs.removeAt(from);
    tabs.insert(to.clamp(0, tabs.length), t);
    _set(
      DesktopTabsState(
        tabs: List.unmodifiable(tabs),
        active: tabs.indexWhere((x) => x.id == activeId),
      ),
    );
  }

  void back() {
    final cur = state.current;
    if (cur.back.isEmpty) return;
    _replaceActive(
      cur.copyWith(
        location: cur.back.last,
        back: cur.back.sublist(0, cur.back.length - 1),
        forward: [cur.location, ...cur.forward],
      ),
    );
  }

  void forward() {
    final cur = state.current;
    if (cur.forward.isEmpty) return;
    _replaceActive(
      cur.copyWith(
        location: cur.forward.first,
        back: [...cur.back, cur.location],
        forward: cur.forward.sublist(1),
      ),
    );
  }

  /// Alt+↑: the parent folder; a drive root goes to Home.
  void up() {
    if (parentOf(state.current.location) case final p?) navigate(p);
  }

  /// Where Up leads from [loc]; null when there's no way up.
  static DesktopLocation? parentOf(DesktopLocation loc) {
    if (loc is! FolderLocation) {
      return loc is SearchLocation
          ? switch (loc.scope) {
              final s? => FolderLocation(s),
              null => const HomeLocation(),
            }
          : null;
    }
    final path = loc.path;
    final slash = path.lastIndexOf('/');
    if (slash <= 0) return const HomeLocation();
    final parent = path.substring(0, slash);
    // `/s` on a POSIX host: its parent is the root, shown as Home.
    return parent.isEmpty ? const HomeLocation() : FolderLocation(parent);
  }
}
