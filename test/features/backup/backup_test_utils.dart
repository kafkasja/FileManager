import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';

/// Inserts one `media_index` row.
Future<void> addIndexed(
  AppDatabase db, {
  required String id,
  required String folder,
  required String name,
  int size = 1000,
  int? takenAtMs = 1700000000000,
  int modifiedAtMs = 1700000001000,
}) => db
    .into(db.mediaIndex)
    .insert(
      MediaIndexCompanion.insert(
        id: id,
        uri: 'content://media/$id',
        name: name,
        nameLower: name.toLowerCase(),
        kind: FileKind.image,
        sizeBytes: size,
        modifiedAtMs: modifiedAtMs,
        takenAtMs: Value(takenAtMs),
        sortDateMs: takenAtMs ?? modifiedAtMs,
        folderPath: folder,
        origin: FileOrigin.local,
        indexedAtMs: 0,
        scanGeneration: 1,
      ),
    );

Future<int> addTag(AppDatabase db, String name, {int color = 0xFF4CAF50}) => db
    .into(db.tags)
    .insert(
      TagsCompanion.insert(
        name: name,
        color: color,
        createdAt: DateTime.utc(2026),
      ),
    );

Future<int> addPreset(
  AppDatabase db,
  String name, {
  Map<String, Object?>? layout,
  Map<String, Object?>? filter,
}) => db
    .into(db.presets)
    .insert(
      PresetsCompanion.insert(
        name: name,
        layoutJson: jsonEncode(
          layout ??
              {
                'directions': {
                  'left': {'type': 'trash'},
                  'right': {'type': 'keep'},
                },
                'actionBar': <Object?>[],
              },
        ),
        filterJson: Value(filter == null ? null : jsonEncode(filter)),
        sortOrder: 0,
        createdAt: DateTime.utc(2026),
      ),
    );

/// Every row of the tables an import touches, as comparable JSON.
Future<String> dumpUserTables(AppDatabase db) async {
  Future<List<Object?>> rows<T extends Table, R extends DataClass>(
    TableInfo<T, R> table,
  ) async =>
      [for (final r in await db.select(table).get()) r.toJson()]
        ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
  return jsonEncode({
    'tags': await rows(db.tags),
    'fileTags': await rows(db.fileTags),
    'favorites': await rows(db.favorites),
    'presets': await rows(db.presets),
    'reviewed': await rows(db.reviewedLabels),
    'settings': await rows(db.settings),
  });
}
