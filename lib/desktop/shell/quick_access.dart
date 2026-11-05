import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_access.g.dart';

/// The default pins: Desktop, Downloads, Documents, Pictures, Videos,
/// Music (Windows' known folders); elsewhere the index's top folders.
@Riverpod(keepAlive: true)
Future<List<String>> quickAccessDefaults(Ref ref) async {
  if (!isWindowsHost) {
    final folders = await ref.watch(
      browseFoldersProvider(IndexQuery.all).future,
    );
    return [for (final f in folders) f.path];
  }
  Map<KnownFolder, String> known;
  try {
    known = await ref.watch(windowsChannelProvider).knownFolders();
  } on Object {
    known = const {};
  }
  final profile = Platform.environment['USERPROFILE']?.replaceAll(r'\', '/');
  String? under(String name) => profile == null ? null : '$profile/$name';
  final candidates = <String?>[
    under('Desktop'),
    known[KnownFolder.downloads],
    known[KnownFolder.documents],
    known[KnownFolder.pictures],
    known[KnownFolder.videos],
    under('Music'),
  ];
  return [
    for (final c in candidates)
      if (c != null && Directory(c).existsSync()) c,
  ];
}

/// Quick access pins (TASK-E3, `desktop.quickAccess`): pinned folder paths
/// in order; until the user changes them, the defaults.
@Riverpod(keepAlive: true)
class DesktopQuickAccess extends _$DesktopQuickAccess {
  @override
  Future<List<String>> build() async {
    final raw = await ref
        .read(settingsRepositoryProvider)
        .read(AppSettings.desktopQuickAccess);
    if (raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) return List.unmodifiable(list.whereType<String>());
      } on FormatException {
        // Fall back to the defaults.
      }
    }
    return await ref.watch(quickAccessDefaultsProvider.future);
  }

  Future<List<String>> _current() async => state.value ?? await future;

  Future<void> _save(List<String> pins) async {
    state = AsyncData(List.unmodifiable(pins));
    await ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.desktopQuickAccess, jsonEncode(pins));
  }

  static bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

  Future<bool> isPinned(String path) async =>
      (await _current()).any((p) => _same(p, path));

  Future<void> pin(String path, {int? at}) async {
    final pins = [...await _current()];
    if (pins.any((p) => _same(p, path))) return;
    pins.insert((at ?? pins.length).clamp(0, pins.length), path);
    await _save(pins);
  }

  Future<void> unpin(String path) async {
    final pins = [...await _current()]..removeWhere((p) => _same(p, path));
    await _save(pins);
  }

  Future<void> move(int from, int to) async {
    final pins = [...await _current()];
    if (from < 0 || from >= pins.length) return;
    final p = pins.removeAt(from);
    pins.insert(to.clamp(0, pins.length), p);
    unawaited(_save(pins).catchError((Object _) {}));
  }
}

/// Quick access pins as a write-queue-safe fire-and-forget (menus).
extension QuickAccessActions on DesktopQuickAccess {
  void togglePin(String path, {required bool pinned}) {
    (pinned ? unpin(path) : pin(path)).fireAndForget();
  }
}
