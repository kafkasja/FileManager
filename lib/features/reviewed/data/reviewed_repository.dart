import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/reviewed/domain/reviewed_rules.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reviewed_repository.g.dart';

/// The latest label of a file in one preset (viewer info bar).
@immutable
class ReviewedLabel {
  const new({
    required this.presetKey,
    required this.actionType,
    required this.reviewedAt,
    this.actionDetail,
  });

  final int presetKey;
  final String actionType;
  final String? actionDetail;
  final DateTime reviewedAt;
}

/// Reviewed labels (TASK-P7). They are written by UndoRepository with each
/// action; this reads, counts and resets them.
class ReviewedRepository {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;

  /// Which of [files] are reviewed in [presetKey] (edited files aren't).
  Future<Set<String>> reviewedAmong(int presetKey, List<FileRef> files) async {
    if (files.isEmpty) return const {};
    final byId = {for (final f in files) f.id: f};
    final reviewed = <String>{};
    final ids = byId.keys.toList();
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final rows =
          await (_db.select(_db.reviewedLabels)..where(
                (l) => l.presetKey.equals(presetKey) & l.fileId.isIn(chunk),
              ))
              .get();
      for (final r in rows) {
        final f = byId[r.fileId];
        if (f != null &&
            sameSecond(
              r.fileModifiedAtMs,
              f.modifiedAt.millisecondsSinceEpoch,
            )) {
          reviewed.add(r.fileId);
        }
      }
    }
    return reviewed;
  }

  /// Newest label per preset for [file] (not shown once the file changed).
  Future<List<ReviewedLabel>> labelsFor(FileRef file) async {
    final rows =
        await (_db.select(_db.reviewedLabels)
              ..where((l) => l.fileId.equals(file.id))
              ..orderBy([(l) => OrderingTerm.desc(l.reviewedAt)]))
            .get();
    final seen = <int>{};
    return [
      for (final r in rows)
        if (sameSecond(
              r.fileModifiedAtMs,
              file.modifiedAt.millisecondsSinceEpoch,
            ) &&
            seen.add(r.presetKey))
          ReviewedLabel(
            presetKey: r.presetKey,
            actionType: r.actionType,
            actionDetail: r.actionDetail,
            reviewedAt: r.reviewedAt,
          ),
    ];
  }

  /// Files with a label, per preset key (reset dialog).
  Future<Map<int, int>> fileCounts() async {
    final rows = await _db
        .customSelect(
          'SELECT preset_key, COUNT(DISTINCT file_id) AS n '
          'FROM reviewed_labels GROUP BY preset_key',
          readsFrom: {_db.reviewedLabels},
        )
        .get();
    return {for (final r in rows) r.read<int>('preset_key'): r.read<int>('n')};
  }

  /// Not undoable.
  Future<void> resetPreset(int presetKey) => _queue.enqueue(
    null,
    () => (_db.delete(
      _db.reviewedLabels,
    )..where((l) => l.presetKey.equals(presetKey))).go(),
  );

  Future<void> resetAll() =>
      _queue.enqueue(null, () => _db.delete(_db.reviewedLabels).go());
}

@Riverpod(keepAlive: true)
ReviewedRepository reviewedRepository(Ref ref) => ReviewedRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

/// Newest label per preset for [file] (viewer info bar).
@riverpod
Future<List<ReviewedLabel>> reviewedLabelsFor(Ref ref, FileRef file) =>
    ref.watch(reviewedRepositoryProvider).labelsFor(file);
