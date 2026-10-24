import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

part 'tag_repository.g.dart';

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

  static Tag _toTag(TagRow r) => Tag(id: r.id, name: r.name, color: r.color);
}
