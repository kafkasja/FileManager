import 'dart:convert';

import 'package:meta/meta.dart';

/// Backup file format (TASK-X6): one JSON object, see
/// `tasks/TASK-X6-backup-restore.md` → File format.
const kBackupFormat = 'kfm-backup';

/// The newest file schema this build reads and the one it writes.
const kBackupSchema = 1;

/// Q6: bigger files aren't read (a backup of 100k files is a few tens of MB;
/// a wrongly picked video must not fill the cache or the memory).
const int kMaxBackupFileBytes = 128 * 1024 * 1024;

enum BackupProblem {
  /// Not JSON, or not a KFM backup.
  notBackup,

  /// Written by a newer KFM.
  tooNew,
}

/// Why a file can't be imported. Nothing is written when this is thrown.
@immutable
class BackupFormatException implements Exception {
  const new(this.problem, this.detail);

  final BackupProblem problem;
  final String detail;

  @override
  String toString() => 'BackupFormatException(${problem.name}): $detail';
}

@immutable
class BackupTag {
  const new({required this.key, required this.name, required this.color});

  /// Export-side id; links `files[].tags` and layouts inside the file only.
  final int key;
  final String name;
  final int color;
}

@immutable
class BackupPreset {
  const new({
    required this.key,
    required this.name,
    required this.layout,
    required this.filter,
    required this.includeReviewed,
    required this.sortOrder,
  });

  final int key;
  final String name;

  /// SwipeLayout JSON (tag ids are export-side keys).
  final Map<String, Object?> layout;

  /// FileFilter JSON or null (tag ids are export-side keys).
  final Map<String, Object?>? filter;
  final bool includeReviewed;
  final int sortOrder;
}

@immutable
class BackupReview {
  const new({
    required this.preset,
    required this.action,
    required this.detail,
    required this.at,
  });

  /// Export-side preset key, 0 = Basic.
  final int preset;

  /// SwipeActionType.name.
  final String action;
  final String? detail;
  final DateTime at;
}

@immutable
class BackupFile {
  const new({
    required this.vol,
    required this.rel,
    required this.name,
    required this.size,
    required this.takenAtMs,
    this.tags = const [],
    this.favorite = false,
    this.reviewed = const [],
  });

  /// `int` (internal storage), `sd` (any removable volume) or `root`.
  final String vol;

  /// Folder path below the volume root ('' = the root itself).
  final String rel;
  final String name;
  final int size;
  final int? takenAtMs;
  final List<int> tags;
  final bool favorite;
  final List<BackupReview> reviewed;
}

@immutable
class BackupData {
  const new({
    required this.createdAt,
    required this.appVersion,
    required this.dbSchema,
    required this.settings,
    required this.tags,
    required this.presets,
    required this.files,
  });

  final DateTime createdAt;
  final String appVersion;
  final int dbSchema;

  /// Setting name → its JSON value (allow-listed names only on export).
  final Map<String, Object?> settings;
  final List<BackupTag> tags;
  final List<BackupPreset> presets;
  final List<BackupFile> files;
}

/// Pure encode/decode; callers run it in `Isolate.run` for big files.
abstract final class BackupCodec {
  static String encode(BackupData d) => const JsonEncoder.withIndent(' ')
      .convert(<String, Object?>{
        'format': kBackupFormat,
        'schema': kBackupSchema,
        'createdAt': d.createdAt.toUtc().toIso8601String(),
        'app': {'version': d.appVersion, 'dbSchema': d.dbSchema},
        'settings': d.settings,
        'tags': [
          for (final t in d.tags)
            {'key': t.key, 'name': t.name, 'color': t.color},
        ],
        'presets': [
          for (final p in d.presets)
            {
              'key': p.key,
              'name': p.name,
              'layout': p.layout,
              'filter': p.filter,
              'includeReviewed': p.includeReviewed,
              'sortOrder': p.sortOrder,
            },
        ],
        'files': [
          for (final f in d.files)
            {
              'vol': f.vol,
              'rel': f.rel,
              'name': f.name,
              'size': f.size,
              'takenAtMs': f.takenAtMs,
              if (f.tags.isNotEmpty) 'tags': f.tags,
              if (f.favorite) 'favorite': true,
              if (f.reviewed.isNotEmpty)
                'reviewed': [
                  for (final r in f.reviewed)
                    {
                      'preset': r.preset,
                      'action': r.action,
                      'detail': r.detail,
                      'at': r.at.toUtc().toIso8601String(),
                    },
                ],
            },
        ],
      });

  /// Throws [BackupFormatException]; never returns partial data.
  static BackupData decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException catch (e) {
      throw BackupFormatException(BackupProblem.notBackup, 'not JSON: $e');
    }
    if (root is! Map<String, Object?> || root['format'] != kBackupFormat) {
      throw const BackupFormatException(
        BackupProblem.notBackup,
        'no kfm-backup format field',
      );
    }
    final schema = root['schema'];
    if (schema is! int || schema < 1) {
      throw BackupFormatException(BackupProblem.notBackup, 'schema $schema');
    }
    if (schema > kBackupSchema) {
      throw BackupFormatException(BackupProblem.tooNew, 'schema $schema');
    }
    try {
      return _decodeV1(_Obj(root, ''));
    } on _Bad catch (e) {
      throw BackupFormatException(BackupProblem.notBackup, e.message);
    }
  }

  static BackupData _decodeV1(_Obj r) {
    final app = r.obj('app');
    final tags = [
      for (final t in r.objList('tags'))
        BackupTag(
          key: t.req<int>('key'),
          name: t.str('name'),
          color: t.req<int>('color'),
        ),
    ];
    final presets = [
      for (final p in r.objList('presets'))
        BackupPreset(
          key: p.req<int>('key'),
          name: p.str('name'),
          layout: p.req<Map<String, Object?>>('layout'),
          filter: p.opt<Map<String, Object?>>('filter'),
          includeReviewed: p.opt<bool>('includeReviewed') ?? false,
          sortOrder: p.opt<int>('sortOrder') ?? 0,
        ),
    ];
    final files = [
      for (final f in r.objList('files'))
        BackupFile(
          vol: f.str('vol'),
          rel: f.req<String>('rel'),
          name: f.str('name'),
          size: f.req<int>('size'),
          takenAtMs: f.opt<int>('takenAtMs'),
          tags: List.unmodifiable(f.list<int>('tags')),
          favorite: f.opt<bool>('favorite') ?? false,
          reviewed: List.unmodifiable([
            for (final rv in f.objList('reviewed'))
              BackupReview(
                preset: rv.req<int>('preset'),
                action: rv.str('action'),
                detail: rv.opt<String>('detail'),
                at: rv.time('at'),
              ),
          ]),
        ),
    ];
    return BackupData(
      createdAt: r.time('createdAt'),
      appVersion: app.opt<String>('version') ?? '',
      dbSchema: app.opt<int>('dbSchema') ?? 0,
      settings: Map.unmodifiable(
        r.opt<Map<String, Object?>>('settings') ?? const {},
      ),
      tags: List.unmodifiable(tags),
      presets: List.unmodifiable(presets),
      files: List.unmodifiable(files),
    );
  }
}

class _Bad implements Exception {
  new(this.message);

  final String message;
}

/// Strictly typed field access with the JSON path in error messages.
extension type const _Obj._(({Map<String, Object?> m, String path}) _o) {
  new(Map<String, Object?> m, String path) : this._((m: m, path: path));

  T req<T extends Object>(String key) => switch (_o.m[key]) {
    final T v => v,
    final other => throw _Bad('${_o.path}.$key: bad value $other'),
  };

  T? opt<T extends Object>(String key) => switch (_o.m[key]) {
    null => null,
    final T v => v,
    final other => throw _Bad('${_o.path}.$key: bad value $other'),
  };

  /// A non-empty string.
  String str(String key) {
    final v = req<String>(key);
    if (v.isEmpty) throw _Bad('${_o.path}.$key: empty');
    return v;
  }

  DateTime time(String key) {
    final v = DateTime.tryParse(req<String>(key));
    if (v == null) throw _Bad('${_o.path}.$key: bad time');
    return v.toUtc();
  }

  _Obj obj(String key) =>
      _Obj(req<Map<String, Object?>>(key), '${_o.path}.$key');

  List<T> list<T extends Object>(String key) => [
    for (final (i, e) in (opt<List<Object?>>(key) ?? const []).indexed)
      if (e is T) e else throw _Bad('${_o.path}.$key[$i]: bad value $e'),
  ];

  List<_Obj> objList(String key) => [
    for (final (i, e) in list<Map<String, Object?>>(key).indexed)
      _Obj(e, '${_o.path}.$key[$i]'),
  ];
}
