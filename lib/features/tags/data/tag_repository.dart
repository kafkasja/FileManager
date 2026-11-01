import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

part 'tag_repository.g.dart';

/// A deleted tag and its file rows, for undo (B9).
typedef TagSnapshot = ({TagRow tag, List<FileTagRow> rows});

const _chunk = 500;

Iterable<List<T>> _chunks<T>(List<T> items) sync* {
  for (var i = 0; i < items.length; i += _chunk) {
    yield items.sublist(
      i,
      i + _chunk > items.length ? items.length : i + _chunk,
    );
  }
}

/// Tags and which files have them (TASK-P2).
@DriftAccessor(tables: [Tags, FileTags])
class TagRepository extends DatabaseAccessor<AppDatabase>
    with _$TagRepositoryMixin {
  new(super.attachedDatabase, {this._clock = DateTime.now});

  final DateTime Function() _clock;

  Stream<Map<int, Tag>> watchAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch().map(
        (rows) => {for (final r in rows) r.id: _toTag(r)},
      );

  /// One tag, or null (B9: a tag created a moment ago may not be in the
  /// watched map yet).
  Future<Tag?> byId(int id) async {
    final row = await (select(
      tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTag(row);
  }

  /// Throws [TagNameTaken] for a duplicate (case-insensitive) and
  /// [ArgumentError] for an empty or too long name.
  Future<Tag> create(String name, int color) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > kTagNameMax) {
      throw ArgumentError.value(name, 'name');
    }
    return await transaction(() async {
      final clash = await (select(
        tags,
      )..where((t) => t.name.lower().equals(trimmed.toLowerCase()))).get();
      if (clash.isNotEmpty) throw TagNameTaken(trimmed);
      final id = await into(tags).insert(
        TagsCompanion.insert(name: trimmed, color: color, createdAt: _clock()),
      );
      return Tag(id: id, name: trimmed, color: color);
    });
  }

  /// Run inside the undo row's transaction: adds the tag if missing and
  /// reports whether the file already had it.
  Future<TagPreviousState> addInTransaction(String fileId, int tagId) async {
    final existing = await (select(
      fileTags,
    )..where((t) => t.fileId.equals(fileId) & t.tagId.equals(tagId))).get();
    if (existing.isEmpty) {
      await into(fileTags).insert(
        FileTagsCompanion.insert(
          fileId: fileId,
          tagId: tagId,
          addedAt: _clock(),
        ),
      );
    }
    return TagPreviousState(tagId: tagId, hadTag: existing.isNotEmpty);
  }

  /// Undo: removes the tag only if the swipe added it.
  Future<void> removeIfAdded(String fileId, TagPreviousState previous) async {
    if (previous.hadTag) return;
    await (delete(fileTags)..where(
          (t) => t.fileId.equals(fileId) & t.tagId.equals(previous.tagId),
        ))
        .go();
  }

  Future<Set<int>> tagIdsOf(String fileId) async {
    final rows = await (select(
      fileTags,
    )..where((t) => t.fileId.equals(fileId))).get();
    return {for (final r in rows) r.tagId};
  }

  Stream<Set<int>> watchTagIdsOf(String fileId) =>
      (select(fileTags)..where((t) => t.fileId.equals(fileId))).watch().map(
        (rows) => {for (final r in rows) r.tagId},
      );

  // ---- B9 bulk writes (chunks of 500, one transaction each) ----

  /// Adds [tagId] to [fileIds]. Returns the ids that didn't have it (exactly
  /// the rows inserted, for undo).
  Future<List<String>> addToFiles(int tagId, List<String> fileIds) {
    final ids = fileIds.toSet().toList();
    return transaction(() async {
      final inserted = <String>[];
      final now = _clock();
      for (final chunk in _chunks(ids)) {
        final existing = await (select(
          fileTags,
        )..where((t) => t.tagId.equals(tagId) & t.fileId.isIn(chunk))).get();
        final had = {for (final r in existing) r.fileId};
        final missing = [
          for (final id in chunk)
            if (!had.contains(id)) id,
        ];
        if (missing.isEmpty) continue;
        await batch(
          (b) => b.insertAll(fileTags, [
            for (final id in missing)
              FileTagsCompanion.insert(fileId: id, tagId: tagId, addedAt: now),
          ]),
        );
        inserted.addAll(missing);
      }
      return inserted;
    });
  }

  /// Removes [tagId] from [fileIds]; returns the removed rows (file id +
  /// added_at) for undo.
  Future<List<FileTagRow>> removeFromFiles(int tagId, List<String> fileIds) {
    final ids = fileIds.toSet().toList();
    return transaction(() async {
      final removed = <FileTagRow>[];
      for (final chunk in _chunks(ids)) {
        final rows = await (select(
          fileTags,
        )..where((t) => t.tagId.equals(tagId) & t.fileId.isIn(chunk))).get();
        if (rows.isEmpty) continue;
        await (delete(
          fileTags,
        )..where((t) => t.tagId.equals(tagId) & t.fileId.isIn(chunk))).go();
        removed.addAll(rows);
      }
      return removed;
    });
  }

  /// Undo of [removeFromFiles]: puts [rows] back (keeps their added_at).
  Future<void> reinsert(List<FileTagRow> rows) async {
    if (rows.isEmpty) return;
    await transaction(() async {
      for (final part in _chunks(rows)) {
        await batch(
          (b) => b.insertAll(fileTags, part, mode: InsertMode.insertOrIgnore),
        );
      }
    });
  }

  /// Undo of [addToFiles]: removes [tagId] from exactly [fileIds].
  Future<void> removeRows(int tagId, List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await transaction(() async {
      for (final chunk in _chunks(fileIds)) {
        await (delete(
          fileTags,
        )..where((t) => t.tagId.equals(tagId) & t.fileId.isIn(chunk))).go();
      }
    });
  }

  /// Tags on [fileIds] with how many of them have each.
  Future<Map<int, int>> tagCountsAmong(List<String> fileIds) async {
    final ids = fileIds.toSet().toList();
    final out = <int, int>{};
    final count = fileTags.fileId.count();
    for (final chunk in _chunks(ids)) {
      final rows =
          await (selectOnly(fileTags)
                ..addColumns([fileTags.tagId, count])
                ..where(fileTags.fileId.isIn(chunk))
                ..groupBy([fileTags.tagId]))
              .get();
      for (final r in rows) {
        final id = r.read(fileTags.tagId)!;
        out[id] = (out[id] ?? 0) + (r.read(count) ?? 0);
      }
    }
    return out;
  }

  /// Same checks as [create], ignoring the tag's own row (so "holiday" →
  /// "Holiday" works).
  Future<void> rename(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > kTagNameMax) {
      throw ArgumentError.value(name, 'name');
    }
    await transaction(() async {
      final clash =
          await (select(tags)..where(
                (t) =>
                    t.name.lower().equals(trimmed.toLowerCase()) &
                    t.id.equals(id).not(),
              ))
              .get();
      if (clash.isNotEmpty) throw TagNameTaken(trimmed);
      await (update(tags)..where((t) => t.id.equals(id))).write(
        TagsCompanion(name: Value(trimmed)),
      );
    });
  }

  Future<void> recolor(int id, int color) async {
    await (update(
      tags,
    )..where((t) => t.id.equals(id))).write(TagsCompanion(color: Value(color)));
  }

  /// Deletes the tag (its file_tags cascade) and returns what undo needs.
  /// Throws [StateError] when the tag doesn't exist.
  Future<TagSnapshot> deleteWithSnapshot(int id) => transaction(() async {
    final tag = await (select(
      tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tag == null) throw StateError('Tag $id not found');
    final rows = await (select(
      fileTags,
    )..where((t) => t.tagId.equals(id))).get();
    await (delete(tags)..where((t) => t.id.equals(id))).go();
    return (tag: tag, rows: rows);
  });

  /// Undo of [deleteWithSnapshot]: the tag comes back with the same id (so
  /// swipe layouts pointing at it work again) and its rows. Throws
  /// [TagNameTaken] if another tag took the name meanwhile.
  Future<void> restoreSnapshot(TagSnapshot s) => transaction(() async {
    final clash =
        await (select(tags)..where(
              (t) =>
                  t.name.lower().equals(s.tag.name.toLowerCase()) &
                  t.id.equals(s.tag.id).not(),
            ))
            .get();
    if (clash.isNotEmpty) throw TagNameTaken(s.tag.name);
    await into(tags).insert(s.tag, mode: InsertMode.insertOrReplace);
    await reinsert(s.rows);
  });

  static Tag _toTag(TagRow r) => Tag(id: r.id, name: r.name, color: r.color);
}
