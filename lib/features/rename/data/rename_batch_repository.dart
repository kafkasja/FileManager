import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/rename_batches_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:kfm/features/rename/domain/rename_batch.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

part 'rename_batch_repository.g.dart';

/// Rename batches and their files (TASK-P3).
@DriftAccessor(tables: [RenameBatches, RenameBatchItems])
class RenameBatchRepository extends DatabaseAccessor<AppDatabase>
    with _$RenameBatchRepositoryMixin {
  new(super.attachedDatabase, {this._clock = DateTime.now});

  final DateTime Function() _clock;

  /// Run inside the undo row's transaction: adds [f] to the session's
  /// collecting batch (created on first use). A file already in it is
  /// ignored (`added: false`).
  Future<RenamePreviousState> addInTransaction(int sessionId, FileRef f) async {
    final batchId = await _collectingId(sessionId) ?? await _create(sessionId);
    final existing =
        await (select(renameBatchItems)
              ..where((i) => i.batchId.equals(batchId) & i.fileId.equals(f.id)))
            .getSingleOrNull();
    if (existing == null) {
      final max = renameBatchItems.position.max();
      final row =
          await (selectOnly(renameBatchItems)
                ..addColumns([max])
                ..where(renameBatchItems.batchId.equals(batchId)))
              .getSingle();
      await into(renameBatchItems).insert(
        RenameBatchItemsCompanion.insert(
          batchId: batchId,
          fileId: f.id,
          position: (row.read(max) ?? 0) + 1,
          folderPath: f.folderPath,
          originalName: f.name,
          currentFileId: f.id,
          currentName: f.name,
        ),
      );
    }
    return RenamePreviousState(
      batchId: batchId,
      op: RenameOp.add,
      added: existing == null,
    );
  }

  /// Undo of an `add` swipe (only while the batch is collecting).
  Future<void> removeItem(int batchId, String fileId) async {
    final batch = await byId(batchId);
    if (batch?.status != RenameBatchStatus.collecting) return;
    await (delete(
      renameBatchItems,
    )..where((i) => i.batchId.equals(batchId) & i.fileId.equals(fileId))).go();
  }

  /// Files in the session's collecting batch (the pill).
  Stream<int> watchCount(int sessionId) {
    final count = renameBatchItems.fileId.count();
    final query =
        selectOnly(renameBatchItems).join([
            innerJoin(
              renameBatches,
              renameBatches.id.equalsExp(renameBatchItems.batchId),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..where(
            renameBatches.sessionId.equals(sessionId) &
                renameBatches.status.equalsValue(RenameBatchStatus.collecting),
          );
    return query.watchSingle().map((r) => r.read(count) ?? 0);
  }

  Future<RenameBatch?> collecting(int sessionId) async {
    final row =
        await (select(renameBatches)..where(
              (b) =>
                  b.sessionId.equals(sessionId) &
                  b.status.equalsValue(RenameBatchStatus.collecting),
            ))
            .getSingleOrNull();
    return row == null ? null : _toBatch(row);
  }

  Future<RenameBatch?> byId(int batchId) async {
    final row = await (select(
      renameBatches,
    )..where((b) => b.id.equals(batchId))).getSingleOrNull();
    return row == null ? null : _toBatch(row);
  }

  /// Ordered by swipe order.
  Future<List<RenameBatchItem>> items(int batchId) async {
    final rows =
        await (select(renameBatchItems)
              ..where((i) => i.batchId.equals(batchId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    return rows.map(_toItem).toList();
  }

  Future<void> discard(int batchId) =>
      _setStatus(batchId, RenameBatchStatus.discarded);

  /// Session end (Done / SE3 new session): a collecting batch is dropped.
  Future<void> discardForSession(int sessionId) async {
    await (update(renameBatches)..where(
          (b) =>
              b.sessionId.equals(sessionId) &
              b.status.equalsValue(RenameBatchStatus.collecting),
        ))
        .write(
          const RenameBatchesCompanion(
            status: Value(RenameBatchStatus.discarded),
          ),
        );
  }

  /// Apply starts: pattern + every item's final name, in one transaction.
  Future<void> startApply(
    int batchId,
    NamePattern pattern,
    Map<String, String> newNames,
  ) => transaction(() async {
    await (update(renameBatches)..where((b) => b.id.equals(batchId))).write(
      RenameBatchesCompanion(
        status: const Value(RenameBatchStatus.applying),
        patternJson: Value(jsonEncode(pattern.toJson())),
      ),
    );
    for (final MapEntry(key: fileId, value: name) in newNames.entries) {
      await (update(renameBatchItems)
            ..where((i) => i.batchId.equals(batchId) & i.fileId.equals(fileId)))
          .write(
            RenameBatchItemsCompanion(
              newName: Value(name),
              tempName: const Value(null),
              skipped: const Value(false),
              skipReason: const Value(null),
            ),
          );
    }
  });

  Future<void> startRevert(int batchId) =>
      _setStatus(batchId, RenameBatchStatus.reverting);

  /// After every single rename (awaited: crash recovery needs it on disk).
  Future<void> recordRename(
    int batchId,
    String fileId, {
    required String currentFileId,
    required String currentName,
    String? tempName,
  }) =>
      (update(renameBatchItems)
            ..where((i) => i.batchId.equals(batchId) & i.fileId.equals(fileId)))
          .write(
            RenameBatchItemsCompanion(
              currentFileId: Value(currentFileId),
              currentName: Value(currentName),
              tempName: Value(tempName),
            ),
          );

  Future<void> markSkipped(int batchId, String fileId, String reason) =>
      (update(renameBatchItems)
            ..where((i) => i.batchId.equals(batchId) & i.fileId.equals(fileId)))
          .write(
            RenameBatchItemsCompanion(
              skipped: const Value(true),
              skipReason: Value(reason),
            ),
          );

  Future<void> finishApply(int batchId) =>
      (update(renameBatches)..where((b) => b.id.equals(batchId))).write(
        RenameBatchesCompanion(
          status: const Value(RenameBatchStatus.applied),
          appliedAt: Value(_clock()),
        ),
      );

  /// Reverted batches collect again (older undos remove files one by one).
  Future<void> finishRevert(int batchId) =>
      _setStatus(batchId, RenameBatchStatus.collecting);

  /// Recovery of an interrupted revert: its undo row is done too.
  Future<void> markApplyUndone(int batchId) => customUpdate(
    "UPDATE session_actions SET status = 'undone' "
    "WHERE action_type = 'renameBatch' AND status != 'undone' "
    r"AND json_extract(previous_state, '$.op') = 'apply' "
    r"AND json_extract(previous_state, '$.batchId') = ?",
    variables: [Variable.withInt(batchId)],
    updates: {attachedDatabase.sessionActions},
  );

  /// Batches a crash left half-way.
  Future<List<RenameBatch>> interrupted() async {
    final rows =
        await (select(renameBatches)..where(
              (b) => b.status.isInValues([
                RenameBatchStatus.applying,
                RenameBatchStatus.reverting,
              ]),
            ))
            .get();
    return rows.map(_toBatch).toList();
  }

  Future<void> _setStatus(int batchId, RenameBatchStatus status) =>
      (update(renameBatches)..where((b) => b.id.equals(batchId))).write(
        RenameBatchesCompanion(status: Value(status)),
      );

  Future<int?> _collectingId(int sessionId) async =>
      (await collecting(sessionId))?.id;

  Future<int> _create(int sessionId) => into(renameBatches).insert(
    RenameBatchesCompanion.insert(
      sessionId: sessionId,
      status: RenameBatchStatus.collecting,
      createdAt: _clock(),
    ),
  );

  static RenameBatch _toBatch(RenameBatchRow r) => RenameBatch(
    id: r.id,
    sessionId: r.sessionId,
    status: r.status,
    pattern: switch (r.patternJson) {
      final String json => _pattern(json),
      null => null,
    },
  );

  static NamePattern? _pattern(String json) {
    try {
      return switch (jsonDecode(json)) {
        final Map<String, Object?> j => NamePattern.fromJson(j),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  static RenameBatchItem _toItem(RenameBatchItemRow r) => RenameBatchItem(
    batchId: r.batchId,
    fileId: r.fileId,
    position: r.position,
    folderPath: r.folderPath,
    originalName: r.originalName,
    currentFileId: r.currentFileId,
    currentName: r.currentName,
    newName: r.newName,
    tempName: r.tempName,
    skipped: r.skipped,
    skipReason: r.skipReason,
  );
}
