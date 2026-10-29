import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';

/// B1 migration: fills `source` and `extension` for rows indexed before
/// they existed, with the same Dart rules the DAO uses (no SQL copy).
/// Keyset chunks of [chunk] rows.
Future<void> backfillSourceAndExtension(
  AppDatabase db, {
  int chunk = 2000,
}) async {
  var after = '';
  while (true) {
    final rows = await db
        .customSelect(
          'SELECT id, kind, folder_path, name FROM media_index '
          'WHERE id > ? ORDER BY id LIMIT ?',
          variables: [Variable.withString(after), Variable.withInt(chunk)],
        )
        .get();
    if (rows.isEmpty) return;
    await db.batch((b) {
      for (final r in rows) {
        final kind = FileKind.values[r.read<int>('kind')];
        final name = r.read<String>('name');
        b.customStatement(
          'UPDATE media_index SET source = ?, extension = ? WHERE id = ?',
          [
            sourceFor(kind, r.read<String>('folder_path'), name).index,
            extensionOf(name),
            r.read<String>('id'),
          ],
        );
      }
    });
    if (rows.length < chunk) return;
    after = rows.last.read<String>('id');
  }
}
