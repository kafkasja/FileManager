import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_source_repository.g.dart';

/// The validated, resolved request (TASK-SS1), ready for
/// [SwipeSourceRepository.open].
@immutable
class PreparedSource {
  const new({
    required this.kind,
    required this.origin,
    required this.title,
    this.filterJson,
    this.items = const [],
    this.groupCount,
    this.returnRoute,
  });

  final SwipeSourceKind kind;
  final SwipeSourceOrigin origin;
  final String title;
  final String? filterJson;

  /// (fileId, groupIndex) in order; de-duplicated, media only, ≤ kMax.
  final List<(String, int?)> items;
  final int? groupCount;
  final String? returnRoute;
}

/// `swipe_sources` + `swipe_source_items` (TASK-SS1). Every write goes
/// through [DbWriteQueue.enqueue] with a null key (structural, never
/// coalesced) and returns the queue's future.
class SwipeSourceRepository {
  new(this._db, this._queue, {this._clock = DateTime.now});

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;

  static const _chunk = 500;

  /// The open source of [sessionId], or null. A filter row is decoded
  /// strictly (`FileFilter.fromJson`, not `FileFilter.decode`, which would
  /// turn the source into "all photos"). A corrupt or invalid filter closes
  /// the row (closedAtSeq = openedAfterSeq; logged as 'kfm.swipe_source')
  /// and null is returned, so the main deck shows.
  Future<OpenSwipeSource?> openFor(int sessionId) async {
    final row =
        await (_db.select(_db.swipeSources)..where(
              (s) => s.sessionId.equals(sessionId) & s.closedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    FileFilter? filter;
    if (row.kind == SwipeSourceKind.filter) {
      try {
        final decoded = switch (jsonDecode(row.filterJson ?? '')) {
          final Map<String, Object?> j => FileFilter.fromJson(j),
          final other => throw FormatException('Not a filter: $other'),
        };
        if (!decoded.isValid) {
          throw FormatException('Invalid filter: ${decoded.problem}');
        }
        filter = decoded;
      } on FormatException catch (e, st) {
        developer.log(
          'corrupt filter on source ${row.id}, closing it',
          name: 'kfm.swipe_source',
          error: e,
          stackTrace: st,
        );
        await close(row.id, lastSeq: row.openedAfterSeq);
        return null;
      }
    }
    return OpenSwipeSource(
      id: row.id,
      sessionId: row.sessionId,
      kind: row.kind,
      origin: row.origin,
      title: row.title,
      filter: filter,
      itemCount: row.itemCount,
      groupCount: row.groupCount,
      returnRoute: row.returnRoute,
      openedAfterSeq: row.openedAfterSeq,
    );
  }

  /// Ordered ids of a list/group source: (fileId, groupIndex) by position.
  Future<List<(String, int?)>> items(int sourceId) async {
    final rows =
        await (_db.select(_db.swipeSourceItems)
              ..where((i) => i.sourceId.equals(sourceId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    return [for (final r in rows) (r.fileId, r.groupIndex)];
  }

  /// Highest closedAtSeq of [sessionId]'s closed sources (null = none).
  Future<int?> mainFloor(int sessionId) async {
    final max = _db.swipeSources.closedAtSeq.max();
    final row =
        await (_db.selectOnly(_db.swipeSources)
              ..addColumns([max])
              ..where(
                _db.swipeSources.sessionId.equals(sessionId) &
                    _db.swipeSources.closedAtSeq.isNotNull(),
              ))
            .getSingle();
    return row.read(max);
  }

  /// One transaction: close the session's open source (if any, with
  /// [lastSeq]), insert the new row, insert items in chunks of 500. Returns
  /// the new source id.
  Future<int> open({
    required int sessionId,
    required PreparedSource source,
    required int lastSeq,
  }) async {
    late int id;
    await _queue.enqueue(
      null,
      () => _db.transaction(() async {
        final now = _clock();
        final open =
            await (_db.select(_db.swipeSources)..where(
                  (s) => s.sessionId.equals(sessionId) & s.closedAt.isNull(),
                ))
                .getSingleOrNull();
        if (open != null) await _closeNow(open.id, lastSeq, now);
        id = await _db
            .into(_db.swipeSources)
            .insert(
              SwipeSourcesCompanion.insert(
                sessionId: sessionId,
                kind: source.kind,
                origin: source.origin,
                title: source.title,
                filterJson: Value(source.filterJson),
                itemCount: Value(source.items.length),
                groupCount: Value(source.groupCount),
                returnRoute: Value(source.returnRoute),
                openedAfterSeq: lastSeq,
                openedAt: now,
              ),
            );
        final items = source.items;
        for (var i = 0; i < items.length; i += _chunk) {
          final end = i + _chunk > items.length ? items.length : i + _chunk;
          await _db.batch(
            (b) => b.insertAll(_db.swipeSourceItems, [
              for (var p = i; p < end; p++)
                SwipeSourceItemsCompanion.insert(
                  sourceId: id,
                  position: p,
                  fileId: items[p].$1,
                  groupIndex: Value(items[p].$2),
                ),
            ]),
          );
        }
      }),
    );
    return id;
  }

  /// One transaction: set closedAt/closedAtSeq and delete the items.
  Future<void> close(int sourceId, {required int lastSeq}) => _queue.enqueue(
    null,
    () => _db.transaction(() => _closeNow(sourceId, lastSeq, _clock())),
  );

  /// runOutsideDeck: inserts a closed `outside` row (title, origin,
  /// openedAfterSeq = [fromSeq], closedAtSeq = [toSeq]). Skipped when
  /// toSeq == fromSeq (nothing was recorded).
  Future<void> recordOutside({
    required int sessionId,
    required SwipeSourceOrigin origin,
    required String title,
    required int fromSeq,
    required int toSeq,
  }) {
    if (toSeq == fromSeq) return Future.value();
    return _queue.enqueue(null, () async {
      final now = _clock();
      await _db
          .into(_db.swipeSources)
          .insert(
            SwipeSourcesCompanion.insert(
              sessionId: sessionId,
              kind: SwipeSourceKind.outside,
              origin: origin,
              title: swipeSourceTitle(title),
              openedAfterSeq: fromSeq,
              closedAtSeq: Value(toSeq),
              openedAt: now,
              closedAt: Value(now),
            ),
          );
    });
  }

  /// Removes item rows that turned out to be gone (deck found no file).
  Future<void> dropItems(int sourceId, List<String> fileIds) {
    if (fileIds.isEmpty) return Future.value();
    return _queue.enqueue(
      null,
      () => _db.transaction(() async {
        for (var i = 0; i < fileIds.length; i += _chunk) {
          final end = i + _chunk > fileIds.length ? fileIds.length : i + _chunk;
          final chunk = fileIds.sublist(i, end);
          await (_db.delete(_db.swipeSourceItems)..where(
                (s) => s.sourceId.equals(sourceId) & s.fileId.isIn(chunk),
              ))
              .go();
        }
      }),
    );
  }

  /// Every deck build: delete sources (items cascade) of ended sessions
  /// (`sessions.ended_at IS NOT NULL`, P6), and items of closed sources
  /// (left over from a crash between the two writes).
  Future<void> prune() => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      await _db.customStatement(
        'DELETE FROM swipe_sources WHERE session_id IN '
        '(SELECT id FROM sessions WHERE ended_at IS NOT NULL)',
      );
      await _db.customStatement(
        'DELETE FROM swipe_source_items WHERE source_id IN '
        '(SELECT id FROM swipe_sources WHERE closed_at IS NOT NULL)',
      );
    }),
  );

  Future<void> _closeNow(int sourceId, int lastSeq, DateTime now) async {
    await (_db.update(
      _db.swipeSources,
    )..where((s) => s.id.equals(sourceId) & s.closedAt.isNull())).write(
      SwipeSourcesCompanion(closedAt: Value(now), closedAtSeq: Value(lastSeq)),
    );
    await (_db.delete(
      _db.swipeSourceItems,
    )..where((i) => i.sourceId.equals(sourceId))).go();
  }
}

@Riverpod(keepAlive: true)
SwipeSourceRepository swipeSourceRepository(Ref ref) => SwipeSourceRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);
