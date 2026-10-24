import 'dart:math';

import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:kfm/features/rename/domain/rename_batch.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

/// What an apply or revert did.
@immutable
class RenameResult {
  const new({this.renamed = 0, this.skipped = 0, this.declined = false});

  final int renamed;

  /// Missing, changed meanwhile, or failed.
  final int skipped;

  /// The one system consent dialog was declined: nothing happened.
  final bool declined;
}

/// One file to rename and where it should end up.
typedef _Step = ({RenameBatchItem item, FileRef file, String target});

/// Applies and reverts rename batches (TASK-P3), crash-safe: every single
/// rename is recorded before the next one, so [recoverInterrupted] can
/// finish a batch a crash left half-way. Name swaps (A→B, B→A) go through
/// temporary names (two phases).
class RenameRunner {
  new({
    required this._source,
    required this._repo,
    required this._undo,
    required this._lock,
    required this._indexer,
    Random? random,
  }) : _random = random ?? Random.secure();

  final FileSource _source;
  final RenameBatchRepository _repo;
  final UndoRepository _undo;
  final SerialLock _lock;
  final MediaIndexer _indexer;
  final Random _random;

  static const tempPrefix = 'kfm_tmp_';

  /// [newNames]: fileId → final name (from the preview). Runs under the lock
  /// shared with undo and D2. Records one undo row for the whole batch.
  Future<RenameResult> apply(
    int sessionId,
    int batchId,
    NamePattern pattern,
    Map<String, String> newNames,
  ) => _lock.run(() async {
    final steps = <_Step>[];
    var skipped = 0;
    for (final item in await _repo.items(batchId)) {
      final target = newNames[item.fileId];
      final file = await _current(item);
      if (target == null || file == null) {
        skipped++;
        await _repo.markSkipped(batchId, item.fileId, 'missing');
        continue;
      }
      steps.add((item: item, file: file, target: target));
    }
    if (steps.isEmpty) return RenameResult(skipped: skipped);
    if (!await _source.requestWriteAccess([for (final s in steps) s.file])) {
      return const RenameResult(declined: true);
    }
    await _repo.startApply(batchId, pattern, {
      for (final s in steps) s.item.fileId: s.target,
    });
    final result = await _run(batchId, steps);
    await _repo.finishApply(batchId);
    await _undo.prepare(sessionId);
    _undo.recordAt(
      _undo.reserveSeq(sessionId),
      sessionId,
      steps.first.item.fileId,
      const SwipeAction(SwipeActionType.renameBatch),
      RenamePreviousState(batchId: batchId, op: RenameOp.apply),
    );
    return RenameResult(
      renamed: result.renamed,
      skipped: skipped + result.skipped,
    );
  });

  /// Undo of an applied batch. Called by UndoService, which already holds
  /// the lock. Files renamed by hand since are skipped (they keep it).
  Future<RenameResult> revert(int batchId) async {
    final steps = <_Step>[];
    var skipped = 0;
    for (final item in await _repo.items(batchId)) {
      if (item.skipped) continue;
      final file = await _current(item);
      if (file == null || file.name != item.currentName) {
        skipped++;
        continue;
      }
      steps.add((item: item, file: file, target: item.originalName));
    }
    if (!await _source.requestWriteAccess([for (final s in steps) s.file])) {
      throw const FileOpException(
        FileOpFailure.userCancelled,
        'rename revert declined',
      );
    }
    await _repo.startRevert(batchId);
    final result = await _run(batchId, steps);
    await _repo.finishRevert(batchId);
    return RenameResult(
      renamed: result.renamed,
      skipped: skipped + result.skipped,
    );
  }

  /// Startup: finish batches a crash left in `applying`/`reverting`. No
  /// `kfm_tmp_` names survive.
  Future<void> recoverInterrupted() => _lock.run(() async {
    for (final batch in await _repo.interrupted()) {
      final applying = batch.status == RenameBatchStatus.applying;
      final steps = <_Step>[];
      for (final item in await _repo.items(batch.id)) {
        if (item.skipped) continue;
        final target = applying ? item.newName : item.originalName;
        if (target == null) continue;
        final file = await _find(item, target);
        if (file == null) {
          await _repo.markSkipped(batch.id, item.fileId, 'missing');
          continue;
        }
        if (file.name != target) {
          steps.add((item: item, file: file, target: target));
        } else if (file.id != item.currentFileId ||
            file.name != item.currentName) {
          await _repo.recordRename(
            batch.id,
            item.fileId,
            currentFileId: file.id,
            currentName: file.name,
          );
        }
      }
      await _run(batch.id, steps);
      if (applying) {
        await _repo.finishApply(batch.id);
        await _undo.prepare(batch.sessionId);
        _undo.recordAt(
          _undo.reserveSeq(batch.sessionId),
          batch.sessionId,
          (await _repo.items(batch.id)).first.fileId,
          const SwipeAction(SwipeActionType.renameBatch),
          RenamePreviousState(batchId: batch.id, op: RenameOp.apply),
        );
      } else {
        await _repo.finishRevert(batch.id);
        await _repo.markApplyUndone(batch.id);
      }
    }
  });

  Future<({int renamed, int skipped})> _run(
    int batchId,
    List<_Step> steps,
  ) async {
    var renamed = 0;
    var skipped = 0;
    final done = <FileRef>[];
    final current = [for (final s in steps) s.file];
    final failed = <int>{};
    if (_needsTwoPhase(steps)) {
      for (final (i, s) in steps.indexed) {
        final (_, ext) = splitExtension(s.file.name);
        final temp = '$tempPrefix${_hex()}_${s.item.position}$ext';
        try {
          final moved = await _source.rename(current[i], temp);
          await _repo.recordRename(
            batchId,
            s.item.fileId,
            currentFileId: moved.id,
            currentName: moved.name,
            tempName: temp,
          );
          current[i] = moved;
        } on FileOpException catch (e) {
          await _repo.markSkipped(batchId, s.item.fileId, e.failure.name);
          failed.add(i);
        }
      }
    }
    for (final (i, s) in steps.indexed) {
      if (failed.contains(i)) {
        skipped++;
        continue;
      }
      try {
        final result = await _source.rename(current[i], s.target);
        await _repo.recordRename(
          batchId,
          s.item.fileId,
          currentFileId: result.id,
          currentName: result.name,
        );
        done.add(result);
        renamed++;
      } on FileOpException catch (e) {
        await _repo.markSkipped(batchId, s.item.fileId, e.failure.name);
        skipped++;
      }
    }
    for (var i = 0; i < done.length; i += 200) {
      await _indexer.addFiles(done.sublist(i, min(i + 200, done.length)));
    }
    return (renamed: renamed, skipped: skipped);
  }

  /// A target equals another batch file's current name in the same folder.
  static bool _needsTwoPhase(List<_Step> steps) {
    final names = <String, String>{
      for (final s in steps)
        '${s.file.folderPath}/${s.file.name.toLowerCase()}': s.item.fileId,
    };
    return steps.any((s) {
      final owner = names['${s.file.folderPath}/${s.target.toLowerCase()}'];
      return owner != null && owner != s.item.fileId;
    });
  }

  /// The item's file now, or null when gone or changed by someone else.
  Future<FileRef?> _current(RenameBatchItem item) async {
    final file = await _source.stat(item.currentFileId);
    if (file == null || file.name != item.currentName) return null;
    return file;
  }

  /// Recovery: by current id, else by the names it could have.
  Future<FileRef?> _find(RenameBatchItem item, String target) async {
    final byId = await _source.stat(item.currentFileId);
    if (byId != null) return byId;
    for (final name in {item.currentName, ?item.tempName, target}) {
      final f = await _source.stat('path:${item.folderPath}/$name');
      if (f != null) return f;
    }
    return null;
  }

  String _hex() => [
    for (var i = 0; i < 4; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
