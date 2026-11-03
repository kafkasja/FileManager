import 'dart:async';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_badge_cache.g.dart';

/// X4: at least one KFM upload exists. Until then no badge, no filter row,
/// no cloud settings beyond X3's row, and [cloudBadgeCacheProvider] is never
/// built (simple by default).
@Riverpod(keepAlive: true)
Stream<bool> cloudHasUploads(Ref ref) =>
    ref.watch(cloudItemsRepositoryProvider).watchHasAny();

/// X4 "Show cloud icon" (Settings → Cloud).
@Riverpod(keepAlive: true)
Stream<bool> cloudShowBadge(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.cloudShowBadge);

/// X4: uploaded `cloud_items` facts per file id, looked up in batches (all
/// ids asked for in one frame = one query per 500 ids). The badge itself
/// is computed by the widget from its own `FileRef` (size + modified ms),
/// so a file edited on disk shows "changed" as soon as its ref changes.
/// Loaded ids without uploads map to an empty list.
@Riverpod(keepAlive: true)
class CloudBadgeCache extends _$CloudBadgeCache {
  /// Above this many cached ids a `cloud_items` change clears the cache
  /// (visible widgets ask again) instead of re-reading every id.
  static const int refreshLimit = 2000;

  final Set<String> _pending = {};
  Timer? _flush;
  final Debouncer _changes = Debouncer(const Duration(milliseconds: 500));

  @override
  Map<String, List<CloudUploadFact>> build() {
    final sub = ref
        .watch(cloudItemsRepositoryProvider)
        .watchChangeTick()
        .listen((_) => _changes.run(_refresh));
    ref.onDispose(() {
      unawaited(sub.cancel());
      _changes.cancel();
      _flush?.cancel();
    });
    return const {};
  }

  /// Asks for [fileId]'s facts (safe to call from `build`: the lookup runs
  /// after the frame).
  void request(String fileId) {
    if (state.containsKey(fileId) || !_pending.add(fileId)) return;
    _flush ??= Timer(Duration.zero, () => unawaited(_load()));
  }

  /// Loads every id not cached yet (one batch).
  Future<void> ensure(Iterable<String> fileIds) {
    _pending.addAll(fileIds.where((id) => !state.containsKey(id)));
    return _load();
  }

  Future<void> _load() async {
    _flush?.cancel();
    _flush = null;
    if (_pending.isEmpty) return;
    final ids = _pending.toList();
    _pending.clear();
    final facts = await ref
        .read(cloudItemsRepositoryProvider)
        .uploadFactsFor(ids);
    if (!ref.mounted) return;
    state = {
      ...state,
      for (final id in ids) id: facts[id] ?? const <CloudUploadFact>[],
    };
  }

  Future<void> _refresh() async {
    final ids = state.keys.toList();
    if (ids.length > refreshLimit) {
      state = const {};
      return;
    }
    final facts = await ref
        .read(cloudItemsRepositoryProvider)
        .uploadFactsFor(ids);
    if (!ref.mounted) return;
    state = {
      ...state,
      for (final id in ids) id: facts[id] ?? const <CloudUploadFact>[],
    };
  }
}

/// X4: one file's uploads, newest first (the viewer's info line).
@riverpod
Stream<List<CloudUploadFact>> cloudUploadsOfFile(Ref ref, String fileId) =>
    ref.watch(cloudItemsRepositoryProvider).destinationsFor(fileId);
