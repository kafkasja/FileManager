import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';

/// Stores an [IndexQuery] (Browse recents). Only non-default fields;
/// tag / favorite / reviewed predicates are not stored (search doesn't use
/// them yet; B9 adds them if a recent ever needs them).
Map<String, Object?> indexQueryToJson(IndexQuery q) => {
  'v': 1,
  if (q.kinds.isNotEmpty) 'kinds': [for (final k in q.kinds) k.name]..sort(),
  'folder': ?q.folderPath,
  if (q.includeSubfolders) 'subfolders': true,
  if (q.sort.field != FileSortField.date || !q.sort.descending)
    'sort': {'field': q.sort.field.name, 'desc': q.sort.descending},
  'minSize': ?q.minSizeBytes,
  'maxSize': ?q.maxSizeBytes,
  'from': ?q.from?.millisecondsSinceEpoch,
  'to': ?q.to?.millisecondsSinceEpoch,
  'name': ?q.nameContains,
  'mime': ?q.mimePrefix,
  if (q.folderPaths.isNotEmpty) 'folders': q.folderPaths.toList()..sort(),
  if (q.screenshotsOnly) 'screenshots': true,
  if (q.sources.isNotEmpty)
    'sources': [for (final s in q.sources) s.name]..sort(),
  if (q.hidden != HiddenFilter.exclude) 'hidden': q.hidden.name,
  if (q.extensions.isNotEmpty) 'ext': q.extensions.toList()..sort(),
  if (q.panoramaOnly) 'pano': true,
  if (q.labelTerms.isNotEmpty)
    'labels': [for (final term in q.labelTerms) term.toList()..sort()],
  if (q.blurryOnly) 'blurry': true,
  'blurMax': ?q.blurThreshold,
  'cloud': ?q.onCloud,
};

/// Throws [FormatException] on bad data or a newer version.
IndexQuery indexQueryFromJson(Map<String, Object?> j) {
  final v = j['v'];
  if (v is! int || v > 1) throw FormatException('Bad query version: $v');
  T? opt<T>(String key) => switch (j[key]) {
    null => null,
    final T value => value,
    final other => throw FormatException('Bad $key: $other'),
  };
  E byName<E extends Enum>(List<E> values, Object? name) =>
      values.asNameMap()[name] ?? (throw FormatException('Bad value: $name'));
  List<Object?> list(String key) => opt<List<Object?>>(key) ?? const [];
  DateTime? date(String key) => switch (opt<int>(key)) {
    null => null,
    final ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  };
  final sort = opt<Map<String, Object?>>('sort');
  return IndexQuery(
    kinds: {for (final k in list('kinds')) byName(FileKind.values, k)},
    folderPath: opt<String>('folder'),
    includeSubfolders: opt<bool>('subfolders') ?? false,
    sort: sort == null
        ? FileSort.newestFirst
        : FileSort(
            byName(FileSortField.values, sort['field']),
            descending: sort['desc'] != false,
          ),
    minSizeBytes: opt<int>('minSize'),
    maxSizeBytes: opt<int>('maxSize'),
    from: date('from'),
    to: date('to'),
    nameContains: opt<String>('name'),
    mimePrefix: opt<String>('mime'),
    folderPaths: {for (final f in list('folders')) f! as String},
    screenshotsOnly: opt<bool>('screenshots') ?? false,
    sources: {for (final s in list('sources')) byName(SourceBucket.values, s)},
    hidden: switch (opt<String>('hidden')) {
      null => HiddenFilter.exclude,
      final h => byName(HiddenFilter.values, h),
    },
    extensions: {for (final e in list('ext')) e! as String},
    panoramaOnly: opt<bool>('pano') ?? false,
    labelTerms: [
      for (final term in list('labels'))
        switch (term) {
          final List<Object?> labels => {
            for (final l in labels)
              if (l is String) l else throw FormatException('Bad label: $l'),
          },
          _ => throw FormatException('Bad label term: $term'),
        },
    ],
    blurryOnly: opt<bool>('blurry') ?? false,
    blurThreshold: opt<int>('blurMax'),
    onCloud: opt<bool>('cloud'),
  );
}
