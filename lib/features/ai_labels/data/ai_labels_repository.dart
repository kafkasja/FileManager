import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/ai_labels_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_labels_repository.g.dart';

/// Keyset position of [AiLabelsRepository.nextBatch] (newest first).
typedef LabelCursor = ({int sortDateMs, String id});

/// One image to label, with the index values the status row records.
@immutable
class LabelWork {
  const new({
    required this.file,
    required this.sortDateMs,
    required this.modifiedAtMs,
  });

  final FileRef file;
  final int sortDateMs;
  final int modifiedAtMs;

  LabelCursor get cursor => (sortDateMs: sortDateMs, id: file.id);
}

/// The outcome for one image ([AiLabelsRepository.saveBatch]).
@immutable
class LabelResult {
  const new labeled(this.work, this.labels) : error = null;

  const new failed(this.work, String this.error) : labels = const [];

  final LabelWork work;
  final List<LabelScore> labels;

  /// Null when labeled.
  final String? error;

  bool get failed => error != null;
}

/// "{processed} of {total} photos labeled" (C4's banner uses [fraction]).
@immutable
class LabelingProgress {
  const new({required this.processed, required this.total});

  static const LabelingProgress empty = LabelingProgress(
    processed: 0,
    total: 0,
  );

  final int processed;
  final int total;

  double get fraction => total == 0 ? 1 : processed / total;

  @override
  bool operator ==(Object other) =>
      other is LabelingProgress &&
      other.processed == processed &&
      other.total == total;

  @override
  int get hashCode => Object.hash(processed, total);

  @override
  String toString() => 'LabelingProgress($processed/$total)';
}

/// ai_labels + ai_label_status (TASK-C3). Writes go through [DbWriteQueue]
/// with `coalesceKey: null` (data rows).
class AiLabelsRepository {
  new(this._db, this._queue, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _now;

  static const int maxErrorLength = 200;

  /// Images with no status row, an older [modelVersion] or a changed file.
  /// `failed` rows only match again when the file or model changes (no
  /// endless retries). Newest first, keyset after [after] (uses
  /// `mi_kind_date`).
  Future<List<LabelWork>> nextBatch(
    LabelCursor? after, {
    required int modelVersion,
    int limit = 50,
  }) async {
    final mi = _db.mediaIndex;
    final s = _db.aiLabelStatus;
    var where =
        mi.kind.equalsValue(FileKind.image) &
        (s.fileId.isNull() |
            s.modelVersion.isSmallerThanValue(modelVersion) |
            s.fileModifiedAtMs.equalsExp(mi.modifiedAtMs).not());
    if (after != null) {
      where =
          where &
          (mi.sortDateMs.isSmallerThanValue(after.sortDateMs) |
              (mi.sortDateMs.equals(after.sortDateMs) &
                  mi.id.isSmallerThanValue(after.id)));
    }
    final query =
        _db.select(mi).join([
            leftOuterJoin(s, s.fileId.equalsExp(mi.id), useColumns: false),
          ])
          ..where(where)
          ..orderBy([
            OrderingTerm.desc(mi.sortDateMs),
            OrderingTerm.desc(mi.id),
          ])
          ..limit(limit);
    final rows = await query.get();
    return [
      for (final row in rows.map((r) => r.readTable(mi)))
        LabelWork(
          file: MediaIndexDao.refOf(row),
          sortDateMs: row.sortDateMs,
          modifiedAtMs: row.modifiedAtMs,
        ),
    ];
  }

  /// One queued transaction per batch. Labeled: replace the file's labels,
  /// status `labeled` with attempts 1. Failed: drop old labels (they'd
  /// describe an older version), status `failed` with attempts + 1.
  Future<void> saveBatch(
    List<LabelResult> results, {
    required int modelVersion,
  }) {
    if (results.isEmpty) return Future.value();
    final nowMs = _now().millisecondsSinceEpoch;
    return _queue.enqueue(
      null,
      () => _db.transaction(() async {
        for (final r in results) {
          final id = r.work.file.id;
          await (_db.delete(
            _db.aiLabels,
          )..where((l) => l.fileId.equals(id))).go();
          if (!r.failed) {
            await _db.batch(
              (b) => b.insertAll(_db.aiLabels, [
                for (final (label, confidence) in r.labels)
                  AiLabelsCompanion.insert(
                    fileId: id,
                    label: label,
                    confidence: confidence.clamp(0.0, 1.0),
                  ),
              ], mode: InsertMode.insertOrReplace),
            );
          }
          final error = r.error;
          await _db.customInsert(
            'INSERT INTO ai_label_status (file_id, outcome, model_version, '
            'file_modified_at_ms, attempts, error, processed_at_ms) '
            'VALUES (?, ?, ?, ?, 1, ?, ?) '
            'ON CONFLICT (file_id) DO UPDATE SET '
            'outcome = excluded.outcome, '
            'model_version = excluded.model_version, '
            'file_modified_at_ms = excluded.file_modified_at_ms, '
            'attempts = CASE WHEN excluded.outcome = ? '
            'THEN ai_label_status.attempts + 1 ELSE 1 END, '
            'error = excluded.error, '
            'processed_at_ms = excluded.processed_at_ms',
            variables: [
              Variable.withString(id),
              Variable.withString(
                (r.failed ? AiLabelOutcome.failed : AiLabelOutcome.labeled)
                    .name,
              ),
              Variable.withInt(modelVersion),
              Variable.withInt(r.work.modifiedAtMs),
              Variable<String>(
                error == null || error.length <= maxErrorLength
                    ? error
                    : error.substring(0, maxErrorLength),
              ),
              Variable.withInt(nowMs),
              Variable.withString(AiLabelOutcome.failed.name),
            ],
            updates: {_db.aiLabelStatus},
          );
        }
      }),
    );
  }

  /// Rows whose file is no longer in media_index.
  Future<void> deleteOrphans() => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      const notIndexed = 'file_id NOT IN (SELECT id FROM media_index)';
      await _db.customUpdate(
        'DELETE FROM ai_labels WHERE $notIndexed',
        updates: {_db.aiLabels},
        updateKind: UpdateKind.delete,
      );
      await _db.customUpdate(
        'DELETE FROM ai_label_status WHERE $notIndexed',
        updates: {_db.aiLabelStatus},
        updateKind: UpdateKind.delete,
      );
    }),
  );

  /// "Reset labels": both tables, one transaction. The job starts over.
  Future<void> reset() => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      await _db.delete(_db.aiLabels).go();
      await _db.delete(_db.aiLabelStatus).go();
    }),
  );

  /// processed = status rows for [modelVersion] with a matching
  /// `fileModifiedAtMs`; total = indexed images.
  Stream<LabelingProgress> watchProgress(int modelVersion) => _db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM media_index WHERE kind = 0) AS total, '
        '(SELECT COUNT(*) FROM ai_label_status s JOIN media_index mi '
        'ON mi.id = s.file_id WHERE mi.kind = 0 AND s.model_version = ?1 '
        'AND s.file_modified_at_ms = mi.modified_at_ms) AS processed',
        variables: [Variable.withInt(modelVersion)],
        readsFrom: {_db.mediaIndex, _db.aiLabelStatus},
      )
      .watchSingle()
      .map(
        (r) => LabelingProgress(
          processed: r.read<int>('processed'),
          total: r.read<int>('total'),
        ),
      );

  /// Status rows with `outcome = failed` (one Settings line, never one
  /// snackbar per file).
  Stream<int> watchFailedCount() {
    final s = _db.aiLabelStatus;
    final count = s.fileId.count();
    return (_db.selectOnly(s)
          ..addColumns([count])
          ..where(s.outcome.equalsValue(AiLabelOutcome.failed)))
        .watchSingle()
        .map((r) => r.read(count) ?? 0);
  }

  /// A file's labels, best first (debug and tests).
  Future<List<AiLabelRow>> labelsOf(String fileId) =>
      (_db.select(_db.aiLabels)
            ..where((l) => l.fileId.equals(fileId))
            ..orderBy([(l) => OrderingTerm.desc(l.confidence)]))
          .get();
}

@Riverpod(keepAlive: true)
AiLabelsRepository aiLabelsRepository(Ref ref) => AiLabelsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);
