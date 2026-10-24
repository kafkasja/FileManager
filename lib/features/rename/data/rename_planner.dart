import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:kfm/features/rename/domain/rename_batch.dart';
import 'package:meta/meta.dart';

/// One line of the rename preview.
@immutable
class RenamePreviewRow {
  const new({required this.item, this.newName, this.collision = false});

  final RenameBatchItem item;

  /// Null = the file is missing or changed: it will be skipped.
  final String? newName;

  /// [newName] got " (1)"… because the pattern's name was taken.
  final bool collision;

  bool get missing => newName == null;
}

/// The preview (TASK-P3).
@immutable
class RenamePreview {
  const new({required this.rows, this.error});

  final List<RenamePreviewRow> rows;

  /// Why Apply is disabled (null = valid).
  final PatternError? error;

  int get renamable => rows.where((r) => !r.missing).length;

  /// fileId → final name, for the runner.
  Map<String, String> get newNames => {
    for (final r in rows) r.item.fileId: ?r.newName,
  };
}

/// Builds the preview: pattern names, " (1)" for names already taken in a
/// folder by files outside the batch (never overwrite), missing files.
class RenamePlanner {
  new(this._source, this._repo, this._index);

  final FileSource _source;
  final RenameBatchRepository _repo;
  final MediaIndexDao _index;

  Future<RenamePreview> preview(int batchId, NamePattern pattern) async {
    final items = await _repo.items(batchId);
    final present = <(RenameBatchItem, FileRef)>[];
    for (final item in items) {
      final file = await _source.stat(item.currentFileId);
      if (file != null && file.name == item.currentName) {
        present.add((item, file));
      }
    }
    final sources = [
      for (final (_, f) in present) (originalName: f.name, date: f.sortDate),
    ];
    final error = validatePattern(pattern, sources);
    final names = error == null ? buildNames(pattern, sources) : null;
    // Batch files free their current names when renamed.
    final leaving = {
      for (final (_, f) in present) '${f.folderPath}/${f.name.toLowerCase()}',
    };
    final chosen = <String>{};
    final byFile = <String, RenamePreviewRow>{};
    for (final (k, (item, file)) in present.indexed) {
      if (names == null) {
        byFile[item.fileId] = RenamePreviewRow(item: item, newName: file.name);
        continue;
      }
      final folder = file.folderPath;
      Future<bool> taken(String candidate) async {
        final key = '$folder/${candidate.toLowerCase()}';
        if (chosen.contains(key)) return true;
        if (leaving.contains(key)) return false;
        return await _source.stat('path:$folder/$candidate') != null ||
            await _index.nameExists(folder, candidate);
      }

      final name = await uniqueName(names[k], taken);
      chosen.add('$folder/${name.toLowerCase()}');
      byFile[item.fileId] = RenamePreviewRow(
        item: item,
        newName: name,
        collision: name != names[k],
      );
    }
    return RenamePreview(
      error: error,
      rows: [
        for (final item in items)
          byFile[item.fileId] ?? RenamePreviewRow(item: item),
      ],
    );
  }
}
