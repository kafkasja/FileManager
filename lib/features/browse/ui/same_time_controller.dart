import 'dart:isolate';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/domain/time_clusters.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'same_time_controller.g.dart';

/// B3: the stored "taken within N seconds" window, clamped to 1 s … 24 h.
@Riverpod(keepAlive: true)
Stream<int> sameTimeWindow(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.sameTimeWindowSeconds)
    .map(clampWindow);

/// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
/// each other (TASK-B3). Only images and videos count; a query without
/// either (e.g. Documents) gives no groups and reads nothing. Recomputes
/// once after a scan, never during one.
@riverpod
class SameTimeClusters extends _$SameTimeClusters {
  /// Below this many rows clustering on the UI isolate is cheaper than the
  /// isolate hop.
  static const _isolateFrom = 5000;

  @override
  Future<List<TimeCluster>> build(IndexQuery query, int windowSeconds) async {
    bool idle() => ref.read(indexStatusProvider).value is IndexIdle;
    ref
      ..listen(mediaIndexChangesProvider, (_, _) {
        if (idle()) ref.invalidateSelf();
      })
      ..listen(indexStatusProvider, (previous, next) {
        final was = previous?.value;
        if (was != null && was is! IndexIdle && next.value is IndexIdle) {
          ref.invalidateSelf();
        }
      });
    final kinds = sameTimeKinds(query.kinds);
    if (kinds.isEmpty) return const [];
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final visible = query
        .copyWith(kinds: kinds)
        .visible(canSeeAllFiles: canSeeAll);
    if (visible == null) return const [];
    final rows = await ref.read(mediaIndexDaoProvider).captureTimes(visible);
    final window = Duration(seconds: windowSeconds);
    if (rows.length < _isolateFrom) return clusterByTime(rows, window);
    return await Isolate.run(() => clusterByTime(rows, window));
  }
}

/// The query's kinds that can be grouped: images and videos (empty = both).
Set<FileKind> sameTimeKinds(Set<FileKind> kinds) => kinds.isEmpty
    ? const {FileKind.image, FileKind.video}
    : kinds.intersection(const {FileKind.image, FileKind.video});

/// One day header and its groups.
@immutable
class SameTimeDay {
  const new(this.day, this.clusters);

  /// Local midnight.
  final DateTime day;
  final List<TimeCluster> clusters;
}

/// Groups [clusters] (capture time ascending) under the local day of their
/// first item; [newestFirst] reverses days and groups.
List<SameTimeDay> groupByDay(
  List<TimeCluster> clusters, {
  required bool newestFirst,
}) {
  final days = <SameTimeDay>[];
  DateTime? current;
  var group = <TimeCluster>[];
  for (final c in clusters) {
    final t = DateTime.fromMillisecondsSinceEpoch(
      c.startMs,
      isUtc: true,
    ).toLocal();
    final day = DateTime(t.year, t.month, t.day);
    if (day != current) {
      if (current != null) {
        days.add(SameTimeDay(current, List.unmodifiable(group)));
      }
      current = day;
      group = [];
    }
    group.add(c);
  }
  if (current != null) {
    days.add(SameTimeDay(current, List.unmodifiable(group)));
  }
  if (!newestFirst) return days;
  return [
    for (final d in days.reversed)
      SameTimeDay(d.day, List.unmodifiable(d.clusters.reversed)),
  ];
}
