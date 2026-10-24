import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/screenshot_rule.dart';

void main() {
  const cases = <(FileKind, String, String, bool)>[
    (FileKind.image, '/s/Pictures/Screenshots', 'a.png', true),
    (FileKind.image, '/s/DCIM/Screenshots', 'b.jpg', true),
    (FileKind.image, '/s/DCIM/Screenshots/old', 'c.jpg', true),
    (FileKind.image, '/s/Pictures/Screen captures', 'd.png', true),
    (FileKind.image, '/s/Download', 'Screenshot_2026.png', true),
    (FileKind.image, '/s/Download', 'screenshot.jpg', true),
    (FileKind.image, '/s/DCIM/Camera', 'IMG_1.jpg', false),
    (FileKind.image, '/s/Pictures/MyScreenshotsBackup', 'e.jpg', false),
    (FileKind.video, '/s/DCIM/Screenshots', 'rec.mp4', false),
    (FileKind.image, '/s/DCIM/Screen recordings', 'f.png', false),
  ];

  test('Dart rule', () {
    for (final (kind, folder, name, expected) in cases) {
      expect(
        isScreenshot(kind, folder, name),
        expected,
        reason: '$folder/$name',
      );
    }
  });

  test('the v9 backfill SQL agrees with the Dart rule', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final (i, (kind, folder, name, _)) in cases.indexed) {
      await db.customStatement(
        'INSERT INTO media_index (id, uri, name, name_lower, kind, size_bytes, '
        'modified_at_ms, sort_date_ms, folder_path, origin, indexed_at_ms, '
        'scan_generation) VALUES (?, ?, ?, ?, ?, 1, 1, 1, ?, 0, 1, 1)',
        ['id$i', 'u$i', name, name.toLowerCase(), kind.index, folder],
      );
    }
    await db.customStatement(AppDatabase.screenshotBackfillSql);
    final rows = await db.select(db.mediaIndex).get();
    for (final (i, (_, folder, name, expected)) in cases.indexed) {
      final row = rows.singleWhere((r) => r.id == 'id$i');
      expect(row.screenshot, expected, reason: '$folder/$name');
    }
  });
}
