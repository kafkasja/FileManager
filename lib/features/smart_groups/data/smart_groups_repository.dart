import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/smart_groups/data/exif_reader.dart';
import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:kfm/features/smart_groups/domain/group_matcher.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_groups_repository.g.dart';

/// Keyset position of [SmartGroupsRepository.nextExifBatch] (newest first).
typedef ExifCursor = ({int sortDateMs, String id});

/// An image whose EXIF must be (re)read.
typedef ExifWorkItem = ({String id, int modifiedAtMs, int sortDateMs});

/// One image of the clustering input.
typedef ClusterInputRow = ({
  String id,
  int sortDateMs,
  double? lat,
  double? lng,
});

/// A computed Trip/Place for [SmartGroupsRepository.replaceGroups].
@immutable
class SmartGroupDraft {
  const new({
    required this.rank,
    required this.startAtMs,
    required this.endAtMs,
    required this.coverFileId,
    required this.memberIds,
    this.center,
  });

  final int rank;
  final int startAtMs;
  final int endAtMs;
  final GeoPoint? center;
  final String coverFileId;
  final List<String> memberIds;
}

/// A stored group with its cover file (null while the cover isn't indexed).
@immutable
class SmartGroupView {
  const new(this.row, this.cover);

  final SmartGroupRow row;
  final FileRef? cover;
}

/// A matched group keeps its online place name while its centre moved less
/// than this.
const double kKeepPlaceNameKm = 1;

/// media_locations, smart_groups and smart_group_items (TASK-C5). Writes go
/// through [DbWriteQueue] with `coalesceKey: null` (data rows).
class SmartGroupsRepository {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;

  static const _images = 'mi.kind = 0 AND mi.hidden = 0';

  // ------------------------------------------------------------------ EXIF

  String _workWhere({required bool locationGranted}) =>
      '$_images AND (l.file_id IS NULL OR '
      'l.file_modified_at_ms <> mi.modified_at_ms'
      '${locationGranted ? ' OR l.location_readable = 0' : ''})';

  /// Images with no EXIF row, a changed file, or (once location access is
  /// granted) a row read without it. Newest first, keyset after [after].
  Future<List<ExifWorkItem>> nextExifBatch({
    required bool locationGranted,
    ExifCursor? after,
    int limit = 200,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT mi.id, mi.modified_at_ms, mi.sort_date_ms '
          'FROM media_index mi '
          'LEFT JOIN media_locations l ON l.file_id = mi.id '
          'WHERE ${_workWhere(locationGranted: locationGranted)}'
          '${after == null ? '' : ' AND (mi.sort_date_ms < ? OR '
                    '(mi.sort_date_ms = ? AND mi.id < ?))'} '
          'ORDER BY mi.sort_date_ms DESC, mi.id DESC LIMIT ?',
          variables: [
            if (after != null) ...[
              Variable.withInt(after.sortDateMs),
              Variable.withInt(after.sortDateMs),
              Variable.withString(after.id),
            ],
            Variable.withInt(limit),
          ],
          readsFrom: {_db.mediaIndex, _db.mediaLocations},
        )
        .get();
    return [
      for (final r in rows)
        (
          id: r.read<String>('id'),
          modifiedAtMs: r.read<int>('modified_at_ms'),
          sortDateMs: r.read<int>('sort_date_ms'),
        ),
    ];
  }

  Future<int> countExifWork({required bool locationGranted}) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM media_index mi '
          'LEFT JOIN media_locations l ON l.file_id = mi.id '
          'WHERE ${_workWhere(locationGranted: locationGranted)}',
          readsFrom: {_db.mediaIndex, _db.mediaLocations},
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Upserts one batch in one transaction. A file read with an error gets a
  /// row without GPS too (not retried until the file changes).
  Future<void> writeLocations(
    List<ExifFacts> facts,
    Map<String, int> modifiedAtMs, {
    required int nowMs,
  }) {
    final rows = [
      for (final f in facts)
        if (modifiedAtMs[f.fileId] case final modified?)
          MediaLocationsCompanion.insert(
            fileId: f.fileId,
            fileModifiedAtMs: modified,
            lat: Value(f.error == null ? f.lat : null),
            lng: Value(f.error == null ? f.lng : null),
            frontCamera: Value(f.error == null && f.frontCamera),
            locationReadable: f.error != null || f.locationReadable,
            readAtMs: nowMs,
          ),
    ];
    if (rows.isEmpty) return Future.value();
    return _queue.enqueue(
      null,
      () => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.mediaLocations, rows),
      ),
    );
  }

  // ------------------------------------------------------------- recompute

  /// "$imageCount:$maxModifiedAtMs:$locationRows:$maxReadAtMs" (the job
  /// appends the location access flag).
  Future<String> inputSignature() async {
    final r = await _db
        .customSelect(
          'SELECT COUNT(*) AS c, COALESCE(MAX(mi.modified_at_ms), 0) AS m, '
          '(SELECT COUNT(*) FROM media_locations) AS lc, '
          '(SELECT COALESCE(MAX(read_at_ms), 0) FROM media_locations) AS lr '
          'FROM media_index mi WHERE $_images',
          readsFrom: {_db.mediaIndex, _db.mediaLocations},
        )
        .getSingle();
    return '${r.read<int>('c')}:${r.read<int>('m')}:'
        '${r.read<int>('lc')}:${r.read<int>('lr')}';
  }

  /// Every visible image with its GPS ([withGps] false = coordinates left
  /// out), oldest first.
  Future<List<ClusterInputRow>> clusterInput({required bool withGps}) async {
    final rows = await _db
        .customSelect(
          'SELECT mi.id, mi.sort_date_ms, l.lat, l.lng FROM media_index mi '
          'LEFT JOIN media_locations l ON l.file_id = mi.id '
          'WHERE $_images ORDER BY mi.sort_date_ms, mi.id',
          readsFrom: {_db.mediaIndex, _db.mediaLocations},
        )
        .get();
    return [
      for (final r in rows)
        (
          id: r.read<String>('id'),
          sortDateMs: r.read<int>('sort_date_ms'),
          lat: withGps ? r.readNullable<double>('lat') : null,
          lng: withGps ? r.readNullable<double>('lng') : null,
        ),
    ];
  }

  /// Stored groups of [kind] with their member ids.
  Future<Map<int, (SmartGroupRow, Set<String>)>> existingGroups(
    SmartGroupKind kind,
  ) async {
    final groups = await (_db.select(
      _db.smartGroups,
    )..where((g) => g.kind.equalsValue(kind))).get();
    final result = <int, (SmartGroupRow, Set<String>)>{
      for (final g in groups) g.id: (g, <String>{}),
    };
    if (result.isEmpty) return result;
    final items = await _db
        .customSelect(
          'SELECT i.group_id, i.file_id FROM smart_group_items i '
          'JOIN smart_groups g ON g.id = i.group_id WHERE g.kind = ?',
          variables: [Variable.withString(kind.name)],
          readsFrom: {_db.smartGroupItems, _db.smartGroups},
        )
        .get();
    for (final r in items) {
      result[r.read<int>('group_id')]?.$2.add(r.read<String>('file_id'));
    }
    return result;
  }

  /// Replaces every group of [kind] in one transaction (§5): matched
  /// drafts update their old row in place (same id; `userTitle` kept, the
  /// place name kept while the centre moved < [kKeepPlaceNameKm]),
  /// unmatched drafts are inserted, unmatched old groups deleted.
  Future<void> replaceGroups(
    SmartGroupKind kind,
    List<SmartGroupDraft> drafts,
  ) => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      final old = await existingGroups(kind);
      final matches = matchGroups(
        {for (final MapEntry(:key, :value) in old.entries) key: value.$2},
        [for (final d in drafts) d.memberIds.toSet()],
      );
      for (final (i, d) in drafts.indexed) {
        final common = SmartGroupsCompanion(
          rank: Value(d.rank),
          startAtMs: Value(d.startAtMs),
          endAtMs: Value(d.endAtMs),
          centerLat: Value(d.center?.lat),
          centerLng: Value(d.center?.lng),
          coverFileId: Value(d.coverFileId),
          itemCount: Value(d.memberIds.length),
        );
        final int id;
        if (matches[i] case final oldId?) {
          id = oldId;
          final before = old[oldId]!.$1;
          final keepName = _near(before, d.center);
          await (_db.update(
            _db.smartGroups,
          )..where((g) => g.id.equals(oldId))).write(
            keepName
                ? common
                : common.copyWith(
                    placeName: const Value(null),
                    geocodedAtMs: const Value(null),
                  ),
          );
          await (_db.delete(
            _db.smartGroupItems,
          )..where((it) => it.groupId.equals(oldId))).go();
        } else {
          id = await _db
              .into(_db.smartGroups)
              .insert(common.copyWith(kind: Value(kind)));
        }
        await _db.batch(
          (b) => b.insertAll(_db.smartGroupItems, [
            for (final f in d.memberIds)
              SmartGroupItemsCompanion.insert(groupId: id, fileId: f),
          ], mode: InsertMode.insertOrIgnore),
        );
      }
      final kept = matches.values.toSet();
      final gone = [
        for (final id in old.keys)
          if (!kept.contains(id)) id,
      ];
      if (gone.isNotEmpty) {
        await (_db.delete(_db.smartGroups)..where((g) => g.id.isIn(gone))).go();
      }
    }),
  );

  static bool _near(SmartGroupRow before, GeoPoint? center) {
    final lat = before.centerLat;
    final lng = before.centerLng;
    if (lat == null || lng == null || center == null) {
      return lat == null && center == null;
    }
    return haversineKm(GeoPoint(lat, lng), center) < kKeepPlaceNameKm;
  }

  // ------------------------------------------------------------ cleanup

  /// Drops rows of files no longer indexed; groups get a new cover / count
  /// and empty groups are deleted. Writes only when something is stale.
  Future<void> deleteOrphans() async {
    const notIndexed = 'file_id NOT IN (SELECT id FROM media_index)';
    final stale = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM media_locations WHERE $notIndexed) '
          'OR EXISTS (SELECT 1 FROM smart_group_items WHERE $notIndexed) '
          'OR EXISTS (SELECT 1 FROM smart_groups g WHERE g.item_count <> '
          '(SELECT COUNT(*) FROM smart_group_items i WHERE i.group_id = g.id)) '
          'AS stale',
          readsFrom: {
            _db.mediaLocations,
            _db.smartGroupItems,
            _db.smartGroups,
            _db.mediaIndex,
          },
        )
        .getSingle();
    if (!stale.read<bool>('stale')) return;
    await _queue.enqueue(
      null,
      () => _db.transaction(() async {
        await _db.customUpdate(
          'DELETE FROM media_locations WHERE $notIndexed',
          updates: {_db.mediaLocations},
          updateKind: UpdateKind.delete,
        );
        await _db.customUpdate(
          'DELETE FROM smart_group_items WHERE $notIndexed',
          updates: {_db.smartGroupItems},
          updateKind: UpdateKind.delete,
        );
        await _db.customUpdate(
          'UPDATE smart_groups SET item_count = (SELECT COUNT(*) FROM '
          'smart_group_items i WHERE i.group_id = smart_groups.id)',
          updates: {_db.smartGroups},
          updateKind: UpdateKind.update,
        );
        await _db.customUpdate(
          'DELETE FROM smart_groups WHERE item_count = 0',
          updates: {_db.smartGroups, _db.smartGroupItems},
          updateKind: UpdateKind.delete,
        );
        await _db.customUpdate(
          'UPDATE smart_groups SET cover_file_id = (SELECT i.file_id FROM '
          'smart_group_items i JOIN media_index mi ON mi.id = i.file_id '
          'WHERE i.group_id = smart_groups.id '
          'ORDER BY mi.sort_date_ms DESC, mi.id DESC LIMIT 1) '
          'WHERE cover_file_id NOT IN (SELECT file_id FROM smart_group_items '
          'WHERE group_id = smart_groups.id)',
          updates: {_db.smartGroups},
          updateKind: UpdateKind.update,
        );
      }),
    );
  }

  // ---------------------------------------------------------- place names

  /// Place groups never looked up (max [limit], by rank).
  Future<List<SmartGroupRow>> placesToName({int limit = 20}) =>
      (_db.select(_db.smartGroups)
            ..where(
              (g) =>
                  g.kind.equalsValue(SmartGroupKind.place) &
                  g.placeName.isNull() &
                  g.geocodedAtMs.isNull() &
                  g.centerLat.isNotNull(),
            )
            ..orderBy([(g) => OrderingTerm.asc(g.rank)])
            ..limit(limit))
          .get();

  /// Stores a lookup result (or only the attempt when [name] is null).
  Future<void> setPlaceName(int id, String? name, {required int nowMs}) {
    final trimmed = name?.trim();
    final value = trimmed == null || trimmed.isEmpty
        ? null
        : trimmed.length > 120
        ? trimmed.substring(0, 120)
        : trimmed;
    return _queue.enqueue(
      null,
      () => (_db.update(_db.smartGroups)..where((g) => g.id.equals(id))).write(
        SmartGroupsCompanion(
          placeName: Value(value),
          geocodedAtMs: Value(nowMs),
        ),
      ),
    );
  }

  /// The setting was turned on again: failed lookups may be retried.
  Future<void> resetFailedLookups() => _queue.enqueue(
    null,
    () => _db.customUpdate(
      'UPDATE smart_groups SET geocoded_at_ms = NULL '
      'WHERE place_name IS NULL AND geocoded_at_ms IS NOT NULL',
      updates: {_db.smartGroups},
      updateKind: UpdateKind.update,
    ),
  );

  // -------------------------------------------------------------------- UI

  /// The user's title (1–80 chars); empty/null = back to automatic.
  Future<void> rename(int id, String? title) {
    final t = title?.trim();
    final value = t == null || t.isEmpty
        ? null
        : t.length > 80
        ? t.substring(0, 80)
        : t;
    return _queue.enqueue(
      null,
      () => (_db.update(_db.smartGroups)..where((g) => g.id.equals(id))).write(
        SmartGroupsCompanion(userTitle: Value(value)),
      ),
    );
  }

  /// Trips newest first, Places by rank, each with its cover.
  Stream<List<SmartGroupView>> watchGroups(SmartGroupKind kind) {
    final g = _db.smartGroups;
    final mi = _db.mediaIndex;
    final query =
        _db.select(g).join([leftOuterJoin(mi, mi.id.equalsExp(g.coverFileId))])
          ..where(g.kind.equalsValue(kind))
          ..orderBy(
            kind == SmartGroupKind.trip
                ? [OrderingTerm.desc(g.startAtMs), OrderingTerm.desc(g.id)]
                : [OrderingTerm.asc(g.rank), OrderingTerm.asc(g.id)],
          );
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          SmartGroupView(r.readTable(g), switch (r.readTableOrNull(mi)) {
            final row? => MediaIndexDao.refOf(row),
            null => null,
          }),
      ],
    );
  }

  Stream<SmartGroupRow?> watchGroup(int id) => (_db.select(
    _db.smartGroups,
  )..where((g) => g.id.equals(id))).watchSingleOrNull();
}

@Riverpod(keepAlive: true)
SmartGroupsRepository smartGroupsRepository(Ref ref) => SmartGroupsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);
