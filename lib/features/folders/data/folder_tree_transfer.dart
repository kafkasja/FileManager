import 'dart:io';

import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_tree_transfer.g.dart';

/// A finished [FolderTreeTransfer.transfer]: one B4 operation per target
/// folder, plus the folders it created and (moves) the emptied source
/// folders it removed.
@immutable
class TreeTransferDone {
  const new({
    required this.move,
    required this.ops,
    required this.createdDirs,
    required this.removedDirs,
    required this.folderCount,
    this.sourceDirs = const [],
  });

  final bool move;

  /// In run order.
  final List<CompletedOperation> ops;

  /// Folders created in the target, parents first.
  final List<String> createdDirs;

  /// Source folders removed after a move (empty by then), deepest first.
  final List<String> removedDirs;

  /// How many folders were dragged / pasted (for the summary).
  final int folderCount;

  /// Moves: every subfolder of the moved source trees, parents first (so
  /// Undo brings back the empty ones too).
  final List<String> sourceDirs;

  int get fileCount => ops.fold<int>(0, (n, o) => n + o.results.length);

  bool get isUndoable => createdDirs.isNotEmpty || ops.any((o) => o.isUndoable);

  bool get cancelled => ops.any((o) => o.cancelled);

  bool get stoppedEarly => ops.any((o) => o.stoppedEarly);

  /// All per-file results, in run order.
  Iterable<OpResult> get results => ops.expand((o) => o.results);
}

/// Thrown before anything changes: a folder can't go into itself or one of
/// its own subfolders.
class FolderIntoItselfException extends FileOpException {
  const new(String path)
    : super(FileOpFailure.invalidName, 'folder into itself: $path');
}

/// Removes [dir] when it holds no files (empty subfolders go with it).
/// True when it was removed.
typedef EmptyDirRemover = Future<bool> Function(String dir);

/// Every folder below [dir] ('/'-separated, any depth, empty ones
/// included); empty when it can't be listed.
typedef SubfolderLister = Future<List<String>> Function(String dir);

/// Copy / move of whole folders (TASK-PL3: folder drag & drop, Ctrl+C/X/V
/// of folders), built on B4's [FileOperationRunner] so every file keeps
/// B4's collision handling, progress, index updates and undo. The folder
/// structure is recreated in the target (`target/<name>/…`); a folder
/// already there with that name is merged into (file clashes ask, like
/// B4), except a copy into its own parent, which gets a new name
/// (`Holiday (1)`). Moves remove the source folders once they are empty.
/// Empty subfolders are recreated too (listed by [SubfolderLister]); Undo
/// removes the ones it created and brings back a moved tree's.
class FolderTreeTransfer {
  new({
    required this._source,
    required this._runner,
    EmptyDirRemover? removeEmptyDir,
    SubfolderLister? listSubfolders,
  }) : _removeEmptyDir = removeEmptyDir ?? removeEmptyIoDir,
       _listSubfolders = listSubfolders ?? listIoSubfolders;

  final FileSource _source;
  final FileOperationRunner _runner;
  final EmptyDirRemover _removeEmptyDir;
  final SubfolderLister _listSubfolders;

  /// Copies (or moves) [folders] and loose [files] into [target]. Throws
  /// [FolderIntoItselfException] (nothing done) for a folder dropped into
  /// itself; `NotEnoughSpaceException` from the runner stops the rest.
  Future<TreeTransferDone> transfer({
    required List<String> folders,
    required List<FileRef> files,
    required String target,
    required bool move,
    required CancelToken cancel,
    required CollisionResolver resolveCollision,
    void Function(OperationProgress)? onProgress,
  }) async {
    final to = _trim(target);
    for (final f in folders) {
      final from = _trim(f);
      final lower = from.toLowerCase();
      final t = to.toLowerCase();
      if (t == lower || t.startsWith('$lower/')) {
        throw FolderIntoItselfException(from);
      }
    }
    // (source folder, files inside, subfolders) per dragged folder; moves
    // into the folder's own parent are no-ops.
    final trees = <(String, List<FileRef>, List<String>)>[];
    for (final f in folders) {
      final from = _trim(f);
      if (move && _same(_parentOf(from), to)) continue;
      final inside = [
        for (final page
            in await _source
                .scan(query: FileQuery(rootPath: from, includeHidden: true))
                .toList())
          ...page,
      ];
      final subfolders = [
        for (final d in await _listSubfolders(from))
          if (d.length > from.length &&
              d.toLowerCase().startsWith('${from.toLowerCase()}/'))
            d,
      ];
      trees.add((from, inside, subfolders));
    }
    final loose = [
      for (final f in files)
        if (!move || !_same(f.folderPath, to)) f,
    ];
    int bytesOf(List<FileRef> fs) => fs.fold<int>(0, (n, f) => n + f.sizeBytes);
    final total = loose.length + trees.fold<int>(0, (n, t) => n + t.$2.length);
    final totalBytes =
        bytesOf(loose) + trees.fold<int>(0, (n, t) => n + bytesOf(t.$2));

    final created = <String>[];
    final ops = <CompletedOperation>[];
    var doneBefore = 0;
    var bytesBefore = 0;
    CollisionChoice? forAll;
    Future<(CollisionChoice, bool)> resolve(FileRef a, FileRef b) async {
      if (forAll case final c?) return (c, true);
      final answer = await resolveCollision(a, b);
      if (answer.$2) forAll = answer.$1;
      return answer;
    }

    /// Runs one B4 op; false = stop (cancelled, no space, declined).
    Future<bool> runOp(List<FileRef> group, String folder) async {
      if (group.isEmpty) return true;
      if (cancel.isCancelled) return false;
      final op = move ? MoveOp(group, folder) : CopyOp(group, folder);
      final base = doneBefore;
      final baseBytes = bytesBefore;
      final done = await _runner.run(
        op,
        cancel: cancel,
        resolveCollision: resolve,
        onProgress: onProgress == null
            ? null
            : (p) => onProgress(
                OperationProgress(
                  done: base + p.done,
                  total: total,
                  bytesDone: baseBytes + p.bytesDone,
                  bytesTotal: totalBytes,
                  current: p.current,
                ),
              ),
      );
      ops.add(done);
      doneBefore += group.length;
      bytesBefore += bytesOf(group);
      return !done.cancelled && !done.stoppedEarly && !done.declined;
    }

    var going = await runOp(loose, to);
    final removed = <String>[];
    final sourceDirs = <String>[];
    for (final (from, inside, subfolders) in trees) {
      if (!going) break;
      final root = await _makeRoot(
        to,
        nameOf(from),
        unique: _same(_parentOf(from), to),
        created: created,
      );
      final groups = <String, List<FileRef>>{};
      for (final f in inside) {
        final rel = f.folderPath.length > from.length
            ? f.folderPath.substring(from.length)
            : '';
        (groups['$root$rel'] ??= []).add(f);
      }
      // Empty subfolders come along as folders without files.
      for (final d in subfolders) {
        groups.putIfAbsent('$root${d.substring(from.length)}', () => []);
      }
      if (move) sourceDirs.addAll(subfolders);
      // Parents first, so every group's folder exists before its files.
      final dirs = groups.keys.toList()..sort((a, b) => a.length - b.length);
      for (final dir in dirs) {
        if (!going) break;
        await _ensureDir(dir, created: created);
        going = await runOp(groups[dir]!, dir);
      }
      if (move && going) {
        // The source tree is empty now (its files moved): remove it.
        if (await _removeEmptyDir(from)) removed.add(from);
      }
    }
    return TreeTransferDone(
      move: move,
      ops: List.unmodifiable(ops),
      createdDirs: List.unmodifiable(created),
      removedDirs: List.unmodifiable(removed),
      folderCount: folders.length,
      sourceDirs: List.unmodifiable(
        sourceDirs..sort((a, b) => a.length - b.length),
      ),
    );
  }

  /// Undoes [done]: the source folders come back, every op is undone
  /// (newest first), then the folders it created are removed when empty.
  Future<UndoOutcome> undo(
    TreeTransferDone done, {
    required CancelToken cancel,
    void Function(OperationProgress)? onProgress,
  }) async {
    var undone = 0;
    var missing = 0;
    var declined = false;
    var cancelled = false;
    final failed = <FileOpException>[];
    if (done.move) {
      final back = {
        for (final r in done.results)
          if (r.after != null) r.before.folderPath,
      }.toList()..sort((a, b) => a.length - b.length);
      for (final dir in back) {
        await _ensureDir(dir, created: <String>[]);
      }
      // Folders that had no files left either way, and the empty
      // subfolders of the moved trees.
      for (final dir in done.removedDirs.reversed) {
        await _ensureDir(dir, created: <String>[]);
      }
      for (final dir in done.sourceDirs) {
        await _ensureDir(dir, created: <String>[]);
      }
    }
    for (final op in done.ops.reversed) {
      if (cancel.isCancelled) {
        cancelled = true;
        break;
      }
      final out = await _runner.undo(
        op,
        cancel: cancel,
        onProgress: onProgress,
      );
      undone += out.undone;
      missing += out.missing;
      failed.addAll(out.failed);
      declined = declined || out.declined;
      cancelled = cancelled || out.cancelled;
      if (out.declined || out.cancelled) break;
    }
    if (!cancelled && !declined) {
      for (final dir in done.createdDirs.reversed) {
        await _removeEmptyDir(dir);
      }
    }
    return UndoOutcome(
      undone: undone,
      missing: missing,
      failed: List.unmodifiable(failed),
      declined: declined,
      cancelled: cancelled,
    );
  }

  /// `target/name`, created when missing (or `name (1)`… when [unique]).
  Future<String> _makeRoot(
    String target,
    String name, {
    required bool unique,
    required List<String> created,
  }) async {
    if (!unique) {
      await _ensureDir('$target/$name', created: created);
      return '$target/$name';
    }
    for (var i = 1; ; i++) {
      final candidate = '$name ($i)';
      try {
        final path = await _source.createFolder(target, candidate);
        created.add(path);
        return path;
      } on FileOpException catch (e) {
        if (e.failure != FileOpFailure.targetExists || i > 999) rethrow;
      }
    }
  }

  /// Creates [dir] and its missing parents; new ones go to [created].
  Future<void> _ensureDir(String dir, {required List<String> created}) async {
    final parent = _parentOf(dir);
    final name = nameOf(dir);
    try {
      created.add(await _source.createFolder(parent, name));
    } on FileOpException catch (e) {
      if (e.failure == FileOpFailure.targetExists) return;
      if (e.failure != FileOpFailure.notFound ||
          parent == dir ||
          parent.isEmpty) {
        rethrow;
      }
      await _ensureDir(parent, created: created);
      created.add(await _source.createFolder(parent, name));
    }
  }

  static String _trim(String p) =>
      p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;

  static String _parentOf(String p) {
    final i = p.lastIndexOf('/');
    return i <= 0 ? p.substring(0, i + 1) : p.substring(0, i);
  }

  static bool _same(String a, String b) =>
      _trim(a).toLowerCase() == _trim(b).toLowerCase();
}

/// [EmptyDirRemover] on the real file system (desktop paths): removes
/// [dir] only when no file is left anywhere inside it.
Future<bool> removeEmptyIoDir(String dir) async {
  final d = Directory(dir);
  try {
    if (!await d.exists()) return false;
    await for (final e in d.list(recursive: true, followLinks: false)) {
      if (e is! Directory) return false;
    }
    await d.delete(recursive: true);
    return true;
  } on FileSystemException {
    return false;
  }
}

/// [SubfolderLister] on the real file system: every folder below [dir]
/// (links not followed), '/'-separated like [dir].
Future<List<String>> listIoSubfolders(String dir) async {
  final out = <String>[];
  try {
    await for (final e in Directory(
      dir,
    ).list(recursive: true, followLinks: false)) {
      if (e is Directory) out.add(e.path.replaceAll(r'\', '/'));
    }
  } on FileSystemException {
    // Unreadable: the files still go; only empty folders are missed.
  }
  return out..sort((a, b) => a.length - b.length);
}

/// How subfolders are listed (tests: the fake file source has no disk).
@Riverpod(keepAlive: true)
SubfolderLister subfolderLister(Ref ref) => listIoSubfolders;

/// How emptied folders are removed (tests: the fake file source has no
/// disk).
@Riverpod(keepAlive: true)
EmptyDirRemover emptyDirRemover(Ref ref) => removeEmptyIoDir;

@Riverpod(keepAlive: true)
FolderTreeTransfer folderTreeTransfer(Ref ref) => FolderTreeTransfer(
  source: ref.watch(fileSourceProvider),
  runner: ref.watch(fileOperationRunnerProvider),
  removeEmptyDir: ref.watch(emptyDirRemoverProvider),
  listSubfolders: ref.watch(subfolderListerProvider),
);
