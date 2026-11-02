import 'dart:async';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/ai_labels_table.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/db/tables/media_locations_table.dart';
import 'package:kfm/core/db/tables/reviewed_labels_table.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/blur_rule.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/screenshot_rule.dart';
import 'package:kfm/core/index/source_rule.dart';

part 'media_index_dao.g.dart';

/// One root of [MediaIndexDao.scopeDigest].
typedef ScopeDigestRow = ({
  String root,
  int count,
  int bytes,
  int newestIndexedAtMs,
});

/// Indexed, keyset-paged access to `media_index` (TASK-F5). Never OFFSET:
/// pages near the end of 50k rows stay as fast as the first.
@DriftAccessor(
  tables: [
    MediaIndex,
    FileTags,
    Favorites,
    ReviewedLabels,
    MediaLocations,
    SmartGroupItems,
    AiLabels,
    ImageSignals,
  ],
)
class MediaIndexDao extends DatabaseAccessor<AppDatabase>
    with _$MediaIndexDaoMixin {
  new(super.attachedDatabase);

  static const changeDebounce = Duration(milliseconds: 300);

  Set<String> _excludedRoots = const {};

  /// U1: volume roots (e.g. `/storage/1234-ABCD`) of detached storage. Their
  /// rows stay in the index (tags, favorites, reviewed labels survive a
  /// replug) but every query leaves them out (`_applyQuery`, the folder
  /// lists). Unfiltered helpers ([byId], [countByKind]) still see them.
  Set<String> get excludedRoots => _excludedRoots;

  /// Replaces [excludedRoots]; a change reloads every open view.
  void setExcludedRoots(Set<String> roots) {
    if (roots.length == _excludedRoots.length &&
        roots.containsAll(_excludedRoots)) {
      return;
    }
    _excludedRoots = Set.unmodifiable(roots);
    attachedDatabase.notifyUpdates({
      TableUpdate.onTable(mediaIndex, kind: UpdateKind.update),
    });
  }

  /// U1: the roots of removable volumes that have indexed rows
  /// (`/storage/<id>`, never `/storage/emulated/…`).
  Future<Set<String>> indexedVolumeRoots() async {
    final col = mediaIndex.folderPath;
    final rows =
        await (selectOnly(mediaIndex, distinct: true)
              ..addColumns([col])
              ..where(
                col.like('/storage/%') & col.like('/storage/emulated/%').not(),
              ))
            .get();
    return {
      for (final r in rows)
        if (_removableRoot.firstMatch(r.read(col)!) case final m?) m.group(0)!,
    };
  }

  static final _removableRoot = RegExp('^/storage/[^/]+');

  Future<IndexPage> page(
    IndexQuery q, {
    IndexCursor? after,
    int limit = 200,
  }) async {
    final sortCol = _sortColumn(q.sort.field);
    final desc = q.sort.descending;
    final select = this.select(mediaIndex)
      ..where((t) {
        var where = _applyQuery(t, q);
        if (after != null) where = where & _beyond(t, q.sort, after);
        return where;
      })
      ..orderBy([
        (_) => OrderingTerm(
          expression: sortCol,
          mode: desc ? OrderingMode.desc : OrderingMode.asc,
        ),
        (t) => OrderingTerm(
          expression: t.id,
          mode: desc ? OrderingMode.desc : OrderingMode.asc,
        ),
      ])
      ..limit(limit);
    final rows = await select.get();
    final next = rows.length < limit
        ? null
        : IndexCursor(_sortValueOf(rows.last, q.sort.field), rows.last.id);
    return IndexPage(List.unmodifiable(rows.map(_toRef)), next);
  }

  Future<int> count(IndexQuery q) => _countQuery(q).getSingle();

  Stream<int> watchCount(IndexQuery q) => _countQuery(q).watchSingle();

  /// B9: visible files per tag (tag id → count). Joins `media_index`, so rows
  /// for files missing from the index aren't counted, and filters with
  /// [scope] like every page. A null [scope] (`visible()` found nothing
  /// visible) emits `{}`. Tags without visible files are absent. Reads
  /// `file_tags` + `media_index`, so it updates live.
  Stream<Map<int, int>> watchTagCounts(IndexQuery? scope) {
    if (scope == null) return Stream.value(const {});
    final count = fileTags.fileId.count();
    final query =
        selectOnly(fileTags).join([
            innerJoin(
              mediaIndex,
              mediaIndex.id.equalsExp(fileTags.fileId),
              useColumns: false,
            ),
          ])
          ..addColumns([fileTags.tagId, count])
          ..where(_applyQuery(mediaIndex, scope))
          ..groupBy([fileTags.tagId]);
    return query.watch().map(
      (rows) => {
        for (final r in rows) r.read(fileTags.tagId)!: r.read(count) ?? 0,
      },
    );
  }

  /// Rows per kind, unfiltered (every row, hidden ones too). Kinds without
  /// rows map to 0. Used to reconcile the index with MediaStore on start.
  Future<Map<FileKind, int>> countByKind(Set<FileKind> kinds) async {
    final count = mediaIndex.id.count();
    final rows =
        await (selectOnly(mediaIndex)
              ..addColumns([mediaIndex.kind, count])
              ..where(mediaIndex.kind.isIn([for (final k in kinds) k.index]))
              ..groupBy([mediaIndex.kind]))
            .get();
    final out = {for (final k in kinds) k: 0};
    for (final r in rows) {
      final kind = r.readWithConverter(mediaIndex.kind);
      if (kind != null) out[kind] = r.read(count) ?? 0;
    }
    return out;
  }

  Future<int> totalBytes(IndexQuery q) {
    final sum = mediaIndex.sizeBytes.sum();
    final query = selectOnly(mediaIndex)
      ..addColumns([sum])
      ..where(_applyQuery(mediaIndex, q));
    return query.getSingle().then((row) => row.read(sum) ?? 0);
  }

  /// B3: `(id, sortDateMs)` of every row matching [q], ordered by capture
  /// time ascending, then id (the input `clusterByTime` expects). [q] must
  /// already be `visible()`; [q]'s own sort is ignored.
  Future<List<(String, int)>> captureTimes(IndexQuery q) async {
    final id = mediaIndex.id;
    final ms = mediaIndex.sortDateMs;
    final rows =
        await (selectOnly(mediaIndex)
              ..addColumns([id, ms])
              ..where(_applyQuery(mediaIndex, q))
              ..orderBy([OrderingTerm.asc(ms), OrderingTerm.asc(id)]))
            .get();
    return [for (final r in rows) (r.read(id)!, r.read(ms)!)];
  }

  /// Emits (debounced) after any change to the index. Views reload their
  /// visible pages. Not filtered per query: a cheap reload beats tracking.
  /// Each event is a new number: Riverpod skips equal values, so a plain
  /// `void` event would only ever be delivered once.
  ///
  /// [withTags] (B9): tag and favorite changes count too, for views that
  /// filter on them (Favorites, a tag's files).
  ///
  /// [withGroups] (C5): smart group members and EXIF rows count too, for
  /// the Groups views (a stored group, Selfies), and (C3) AI labels for
  /// Documents and C4 content search, and (C2) image signals for `blurry`.
  Stream<int> watchChanges({bool withTags = false, bool withGroups = false}) {
    final updates = attachedDatabase.tableUpdates(
      withTags || withGroups
          ? TableUpdateQuery.allOf([
              TableUpdateQuery.onTable(mediaIndex),
              if (withTags) ...[
                TableUpdateQuery.onTable(fileTags),
                TableUpdateQuery.onTable(favorites),
              ],
              if (withGroups) ...[
                TableUpdateQuery.onTable(smartGroupItems),
                TableUpdateQuery.onTable(mediaLocations),
                TableUpdateQuery.onTable(aiLabels),
                TableUpdateQuery.onTable(imageSignals),
              ],
            ])
          : TableUpdateQuery.onTable(mediaIndex),
    );
    late StreamController<int> controller;
    var tick = 0;
    StreamSubscription<Set<TableUpdate>>? sub;
    Timer? timer;
    controller = StreamController<int>(
      onListen: () => sub = updates.listen((_) {
        timer?.cancel();
        timer = Timer(changeDebounce, () => controller.add(++tick));
      }, onError: controller.addError),
      onCancel: () async {
        timer?.cancel();
        await sub?.cancel();
      },
    );
    return controller.stream;
  }

  /// Every indexed folder with its file count, sorted by path (P2 folder
  /// picker: "Folders with photos"). B1: [scope] narrows the counted files
  /// (null = every row, as before).
  Future<List<({String path, int count})>> folderSummaries({
    IndexQuery? scope,
  }) async {
    final count = mediaIndex.id.count();
    final query = selectOnly(mediaIndex)
      ..addColumns([mediaIndex.folderPath, count])
      ..groupBy([mediaIndex.folderPath])
      ..orderBy([OrderingTerm.asc(mediaIndex.folderPath)])
      ..where(
        scope != null
            ? _applyQuery(mediaIndex, scope)
            : _notExcluded(mediaIndex),
      );
    final rows = await query.get();
    return [
      for (final r in rows)
        (path: r.read(mediaIndex.folderPath)!, count: r.read(count) ?? 0),
    ];
  }

  /// B1 folder mode: the direct child folders of [parent] (null = storage
  /// volumes) holding files of [scope], with counts including subfolders.
  /// [scope]'s own folder is ignored. Sorted by name, case-insensitive.
  Future<List<FolderEntry>> folders({
    required IndexQuery scope,
    String? parent,
  }) async {
    final summaries = await folderSummaries(
      scope: scope.copyWith(folderPath: () => null, folderPaths: const {}),
    );
    final counts = <String, int>{};
    for (final (:path, :count) in summaries) {
      final String child;
      if (parent == null) {
        child = volumeRootOf(path);
      } else if (path.startsWith('$parent/')) {
        final rest = path.substring(parent.length + 1);
        final slash = rest.indexOf('/');
        child = '$parent/${slash < 0 ? rest : rest.substring(0, slash)}';
      } else {
        continue;
      }
      counts[child] = (counts[child] ?? 0) + count;
    }
    return [
      for (final MapEntry(:key, :value) in counts.entries)
        FolderEntry(key, value),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// N7 live sync: per root of [rootPaths] (in order), the visible rows of
  /// [kinds] (empty = all) at or below it: how many, their total size and
  /// the newest `indexed_at_ms`. Any add, delete, move or re-index under a
  /// root changes its triple; changes elsewhere don't. Hidden rows are left
  /// out, as in every listing.
  Future<List<ScopeDigestRow>> scopeDigest(
    List<String> rootPaths, {
    Set<FileKind> kinds = const {},
  }) async {
    final count = mediaIndex.id.count();
    final bytes = mediaIndex.sizeBytes.sum();
    final newest = mediaIndex.indexedAtMs.max();
    final out = <ScopeDigestRow>[];
    for (final root in rootPaths) {
      final q = IndexQuery(
        kinds: kinds,
        folderPath: root,
        includeSubfolders: true,
      );
      final row =
          await (selectOnly(mediaIndex)
                ..addColumns([count, bytes, newest])
                ..where(_applyQuery(mediaIndex, q)))
              .getSingle();
      out.add((
        root: root,
        count: row.read(count) ?? 0,
        bytes: row.read(bytes) ?? 0,
        newestIndexedAtMs: row.read(newest) ?? 0,
      ));
    }
    return out;
  }

  /// N7: how the index spells [folderPath] (case-insensitive match; the
  /// folder itself or, failing that, a folder below it), or null when
  /// nothing is indexed there. Remote listings map a canonical path to the
  /// stored spelling, so `folderPath` equality still uses the index.
  Future<String?> storedFolderSpelling(String folderPath) async {
    final col = mediaIndex.folderPath;
    final exact =
        await (selectOnly(mediaIndex)
              ..addColumns([col])
              ..where(col.collate(Collate.noCase).equals(folderPath))
              ..limit(1))
            .getSingleOrNull();
    if (exact != null) return exact.read(col);
    final below =
        await (selectOnly(mediaIndex)
              ..addColumns([col])
              ..where(
                col.like('${_escapeLike(folderPath)}/%', escapeChar: r'\'),
              )
              ..limit(1))
            .getSingleOrNull();
    final path = below?.read(col);
    return path?.substring(0, folderPath.length);
  }

  /// Some indexed file in [folderPath] is called [name] (case-insensitive;
  /// shared storage is). P3 preview collisions for MediaStore files.
  Future<bool> nameExists(String folderPath, String name) async =>
      (await (select(mediaIndex)
                ..where(
                  (t) =>
                      t.folderPath.equals(folderPath) &
                      t.nameLower.equals(name.toLowerCase()),
                )
                ..limit(1))
              .get())
          .isNotEmpty;

  Future<FileRef?> byId(String id) async {
    final row = await (select(
      mediaIndex,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toRef(row);
  }

  /// Rows for [ids] in the same order; missing ids are skipped.
  Future<List<FileRef>> byIds(List<String> ids) async {
    final found = <String, FileRef>{};
    // SQLite limits bound variables; chunk large lists.
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final rows = await (select(
        mediaIndex,
      )..where((t) => t.id.isIn(chunk))).get();
      for (final r in rows) {
        found[r.id] = _toRef(r);
      }
    }
    return [for (final id in ids) ?found[id]];
  }

  /// Inserts or updates one scan page in a single transaction.
  Future<void> upsertBatch(
    List<FileRef> files,
    int generation, {
    DateTime? now,
  }) {
    final indexedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return batch((b) {
      b.insertAllOnConflictUpdate(mediaIndex, [
        for (final f in files) _toCompanion(f, generation, indexedAt),
      ]);
    });
  }

  /// Removes rows of [kinds] (under [rootPath], if given) that the full scan
  /// [generation] didn't see. Returns the number removed.
  /// U1: rows under [keepUnder] (roots of detached volumes) are never
  /// removed: their files are only away.
  Future<int> deleteOlderThanGeneration(
    int generation, {
    required Set<FileKind> kinds,
    String? rootPath,
    bool recursive = true,
    Set<String> keepUnder = const {},
  }) =>
      (delete(mediaIndex)..where((t) {
            var where =
                t.scanGeneration.isSmallerThanValue(generation) &
                t.kind.isIn([for (final k in kinds) k.index]) &
                _outside(t, keepUnder);
            if (rootPath != null) {
              final here = t.folderPath.equals(rootPath);
              where =
                  where &
                  (recursive
                      ? here |
                            t.folderPath.like(
                              '${_escapeLike(rootPath)}/%',
                              escapeChar: r'\',
                            )
                      : here);
            }
            return where;
          }))
          .go();

  Future<void> deleteIds(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      await (delete(mediaIndex)..where((t) => t.id.isIn(chunk))).go();
    }
  }

  /// Re-keys a row after FileSource reported a new id (move/rename).
  Future<void> applyIdChange(FileIdChange change) => transaction(() async {
    final old = await (select(
      mediaIndex,
    )..where((t) => t.id.equals(change.oldId))).getSingleOrNull();
    await (delete(mediaIndex)..where((t) => t.id.equals(change.oldId))).go();
    await into(mediaIndex).insertOnConflictUpdate(
      _toCompanion(
        change.newRef,
        old?.scanGeneration ?? 0,
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
  });

  // ---- helpers ----

  Selectable<int> _countQuery(IndexQuery q) {
    final count = mediaIndex.id.count();
    return (selectOnly(mediaIndex)
          ..addColumns([count])
          ..where(_applyQuery(mediaIndex, q)))
        .map((r) => r.read(count) ?? 0);
  }

  /// [q]'s filters as a WHERE expression over [t], for queries built
  /// outside this DAO (B6 select all). Same SQL as every page.
  Expression<bool> whereFor($MediaIndexTable t, IndexQuery q) =>
      _applyQuery(t, q);

  /// U1: not under any of [excludedRoots].
  Expression<bool> _notExcluded($MediaIndexTable t) =>
      _outside(t, _excludedRoots);

  static Expression<bool> _outside($MediaIndexTable t, Set<String> roots) {
    Expression<bool> where = const Constant(true);
    for (final root in roots) {
      where =
          where &
          t.folderPath.equals(root).not() &
          t.folderPath.like('${_escapeLike(root)}/%', escapeChar: r'\').not();
    }
    return where;
  }

  /// The one place query filters become SQL (P5 adds its joins here).
  Expression<bool> _applyQuery($MediaIndexTable t, IndexQuery q) {
    var where = _notExcluded(t);
    if (q.kinds.isNotEmpty) {
      where = where & t.kind.isIn([for (final k in q.kinds) k.index]);
    }
    if (q.folderPath case final folder?) {
      where =
          where &
          (q.includeSubfolders
              ? t.folderPath.equals(folder) |
                    t.folderPath.like(
                      '${_escapeLike(folder)}/%',
                      escapeChar: r'\',
                    )
              : t.folderPath.equals(folder));
    }
    if (q.minSizeBytes case final min?) {
      where = where & t.sizeBytes.isBiggerOrEqualValue(min);
    }
    if (q.maxSizeBytes case final max?) {
      where = where & t.sizeBytes.isSmallerOrEqualValue(max);
    }
    if (q.from case final from?) {
      where =
          where &
          t.sortDateMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch);
    }
    if (q.to case final to?) {
      where =
          where & t.sortDateMs.isSmallerThanValue(to.millisecondsSinceEpoch);
    }
    // B8: every whitespace-separated word must occur (AND), in any order.
    if (q.nameContains case final name? when name.isNotEmpty) {
      for (final word in name.toLowerCase().split(_whitespace)) {
        if (word.isEmpty) continue;
        where =
            where &
            t.nameLower.like('%${_escapeLike(word)}%', escapeChar: r'\');
      }
    }
    if (q.mimePrefix case final prefix?) {
      where =
          where & t.mimeType.like('${_escapeLike(prefix)}%', escapeChar: r'\');
    }
    if (q.folderPaths.isNotEmpty) {
      where = where & t.folderPath.isIn(q.folderPaths);
    }
    if (q.screenshotsOnly) where = where & t.screenshot.equals(true);
    if (q.tagged case final tagged?) {
      final any = existsQuery(
        select(fileTags)..where((ft) => ft.fileId.equalsExp(t.id)),
      );
      where = where & (tagged ? any : any.not());
    }
    if (q.anyTagIds.isNotEmpty) {
      where =
          where &
          existsQuery(
            select(fileTags)..where(
              (ft) => ft.fileId.equalsExp(t.id) & ft.tagId.isIn(q.anyTagIds),
            ),
          );
    }
    if (q.reviewed case final r?) {
      // Same file, same preset, same modified second (edited = not reviewed).
      final l = reviewedLabels;
      final sub = selectOnly(l)
        ..addColumns([l.actionId])
        ..where(
          l.fileId.equalsExp(t.id) &
              l.presetKey.equals(r.presetKey) &
              CustomExpression<bool>(
                '${l.fileModifiedAtMs.escapedNameFor(SqlDialect.sqlite)} / 1000 '
                '= media_index.modified_at_ms / 1000',
              ),
        );
      where = where & (r.reviewed ? existsQuery(sub) : notExistsQuery(sub));
    }
    if (q.favoritesOnly) {
      where =
          where &
          existsQuery(
            select(favorites)..where((f) => f.fileId.equalsExp(t.id)),
          );
    }
    if (q.sources.isNotEmpty) {
      where = where & t.source.isIn([for (final s in q.sources) s.index]);
    }
    switch (q.hidden) {
      case HiddenFilter.exclude:
        where = where & t.hidden.equals(false);
      case HiddenFilter.include:
        break;
      case HiddenFilter.only:
        where = where & t.hidden.equals(true);
    }
    if (q.extensions.isNotEmpty) {
      where = where & t.extension.isIn(q.extensions);
    }
    if (q.panoramaOnly) {
      final w = t.width;
      final h = t.height;
      where =
          where &
          t.kind.equals(FileKind.image.index) &
          (t.nameLower.like(r'pano\_%', escapeChar: r'\') |
              (w.isNotNull() &
                  h.isNotNull() &
                  (w.isBiggerOrEqual(h * const Constant(2)) |
                      h.isBiggerOrEqual(w * const Constant(2)))));
    }
    if (q.smartGroupId case final groupId?) {
      where =
          where &
          existsQuery(
            select(smartGroupItems)..where(
              (i) => i.fileId.equalsExp(t.id) & i.groupId.equals(groupId),
            ),
          );
    }
    if (q.selfiesOnly) {
      final folder = t.folderPath.lower();
      where =
          where &
          t.kind.equals(FileKind.image.index) &
          (folder.equals('selfies') |
              folder.like('%/selfies') |
              existsQuery(
                select(mediaLocations)..where(
                  (l) => l.fileId.equalsExp(t.id) & l.frontCamera.equals(true),
                ),
              ));
    }
    if (q.documentsGroup) {
      // C5 + C3: documents, or images the AI labeled 'document'
      // (photographed paper, menus, screens).
      where =
          where &
          (t.kind.equals(FileKind.document.index) |
              (t.kind.equals(FileKind.image.index) &
                  existsQuery(
                    select(aiLabels)..where(
                      (l) =>
                          l.fileId.equalsExp(t.id) &
                          l.label.equals(kDocumentLabel),
                    ),
                  )));
    }
    // C4: content search. One correlated EXISTS per typed term (AND), its
    // labels OR'ed; served by ai_labels' (file_id, label) primary key.
    if (q.hasContentTerms) {
      where = where & t.kind.equals(FileKind.image.index);
    }
    for (final term in q.labelTerms) {
      if (term.isEmpty) continue;
      where =
          where &
          existsQuery(
            select(aiLabels)
              ..where((l) => l.fileId.equalsExp(t.id) & l.label.isIn(term)),
          );
    }
    if (q.blurryOnly) {
      final threshold = q.blurThreshold;
      where =
          where &
          (threshold == null
              ? const Constant(false)
              : existsQuery(
                  select(imageSignals)..where(
                    (s) =>
                        s.fileId.equalsExp(t.id) &
                        blurryPredicate(s, threshold),
                  ),
                ));
    }
    return where;
  }

  /// How many of [ids] match [q] (P5: acted files under a filter).
  Future<int> countAmong(IndexQuery q, List<String> ids) async {
    var total = 0;
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final count = mediaIndex.id.count();
      final row =
          await (selectOnly(mediaIndex)
                ..addColumns([count])
                ..where(_applyQuery(mediaIndex, q) & mediaIndex.id.isIn(chunk)))
              .getSingle();
      total += row.read(count) ?? 0;
    }
    return total;
  }

  Expression<Object> _sortColumn(FileSortField field) => switch (field) {
    FileSortField.date => mediaIndex.sortDateMs,
    FileSortField.size => mediaIndex.sizeBytes,
    FileSortField.name => mediaIndex.nameLower,
  };

  static Object _sortValueOf(MediaIndexRow r, FileSortField field) =>
      switch (field) {
        FileSortField.date => r.sortDateMs,
        FileSortField.size => r.sizeBytes,
        FileSortField.name => r.nameLower,
      };

  /// Rows strictly after [c] in (sortColumn, id) order.
  static Expression<bool> _beyond(
    $MediaIndexTable t,
    FileSort sort,
    IndexCursor c,
  ) {
    final desc = sort.descending;
    final idBeyond = desc
        ? t.id.isSmallerThanValue(c.id)
        : t.id.isBiggerThanValue(c.id);
    Expression<bool> intBeyond(GeneratedColumn<int> col) {
      final v = c.sortValue as int;
      return (desc ? col.isSmallerThanValue(v) : col.isBiggerThanValue(v)) |
          (col.equals(v) & idBeyond);
    }

    return switch (sort.field) {
      FileSortField.date => intBeyond(t.sortDateMs),
      FileSortField.size => intBeyond(t.sizeBytes),
      FileSortField.name => () {
        final v = c.sortValue as String;
        return (desc
                ? t.nameLower.isSmallerThanValue(v)
                : t.nameLower.isBiggerThanValue(v)) |
            (t.nameLower.equals(v) & idBeyond);
      }(),
    };
  }

  static final _whitespace = RegExp(r'\s+');

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static MediaIndexCompanion _toCompanion(
    FileRef f,
    int generation,
    int indexedAtMs,
  ) => MediaIndexCompanion.insert(
    id: f.id,
    uri: f.uri,
    name: f.name,
    nameLower: f.name.toLowerCase(),
    mimeType: Value(f.mimeType),
    kind: f.kind,
    sizeBytes: f.sizeBytes,
    modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
    takenAtMs: Value(f.takenAt?.millisecondsSinceEpoch),
    sortDateMs: f.sortDate.millisecondsSinceEpoch,
    width: Value(f.width),
    height: Value(f.height),
    durationMs: Value(f.durationMs),
    folderPath: f.folderPath,
    origin: f.origin,
    indexedAtMs: indexedAtMs,
    scanGeneration: generation,
    screenshot: Value(isScreenshot(f.kind, f.folderPath, f.name)),
    source: Value(sourceFor(f.kind, f.folderPath, f.name)),
    hidden: Value(f.hidden),
    extension: Value(extensionOf(f.name)),
  );

  /// A row as a [FileRef] (for other features' joins over media_index).
  static FileRef refOf(MediaIndexRow r) => _toRef(r);

  static FileRef _toRef(MediaIndexRow r) => FileRef(
    id: r.id,
    uri: r.uri,
    name: r.name,
    mimeType: r.mimeType,
    kind: r.kind,
    sizeBytes: r.sizeBytes,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      r.modifiedAtMs,
      isUtc: true,
    ),
    takenAt: r.takenAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r.takenAtMs!, isUtc: true),
    width: r.width,
    height: r.height,
    durationMs: r.durationMs,
    folderPath: r.folderPath,
    origin: r.origin,
    hidden: r.hidden,
  );
}
