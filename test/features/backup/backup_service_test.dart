import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/features/backup/data/backup_service.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

import 'backup_test_utils.dart';

class _Device {
  new(this.dir)
    : db = AppDatabase(NativeDatabase.memory()),
      queue = DbWriteQueue() {
    service = BackupService(
      db,
      queue,
      snapshotDir: () async => Directory('${dir.path}/backups'),
      clock: () => DateTime.utc(2026, 11, 2, 10),
    );
    settings = SettingsRepository(db, queue);
  }

  final Directory dir;
  final AppDatabase db;
  final DbWriteQueue queue;
  late final BackupService service;
  late final SettingsRepository settings;

  Future<void> close() async {
    await queue.close();
    await db.close();
  }
}

Map<String, Object?> _tagLayout(int tagId) => {
  'directions': {
    'left': {'type': 'trash'},
    'right': {'type': 'keep'},
    'up': {'type': 'addTag', 'tagId': tagId},
  },
  'actionBar': <Object?>[],
};

void main() {
  late Directory tmp;
  late _Device a;
  late _Device b;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kfm_backup');
    a = _Device(Directory('${tmp.path}/a')..createSync());
    b = _Device(Directory('${tmp.path}/b')..createSync());
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  /// Device A: 3 photos with a tag, a favorite, a preset label and a Basic
  /// label; a preset whose up-swipe adds the tag; two settings.
  Future<void> seedA() async {
    await addIndexed(
      a.db,
      id: 'a1',
      folder: '/storage/emulated/0/DCIM/Camera',
      name: 'one.jpg',
    );
    await addIndexed(
      a.db,
      id: 'a2',
      folder: '/storage/emulated/0/DCIM/Camera',
      name: 'two.jpg',
      size: 2000,
    );
    await addIndexed(
      a.db,
      id: 'a3',
      folder: '/storage/1234-ABCD/Pics',
      name: 'sd.jpg',
      takenAtMs: null,
    );
    final holiday = await addTag(a.db, 'Holiday', color: 0xFF2196F3);
    final preset = await addPreset(a.db, 'Sort', layout: _tagLayout(holiday));
    await a.db
        .into(a.db.fileTags)
        .insert(
          FileTagsCompanion.insert(
            fileId: 'a1',
            tagId: holiday,
            addedAt: DateTime.utc(2026),
          ),
        );
    await a.db
        .into(a.db.favorites)
        .insert(
          FavoritesCompanion.insert(fileId: 'a2', addedAt: DateTime.utc(2026)),
        );
    await a.db
        .into(a.db.reviewedLabels)
        .insert(
          ReviewedLabelsCompanion.insert(
            actionId: const Value(7),
            fileId: 'a3',
            presetKey: preset,
            actionType: 'keep',
            reviewedAt: DateTime.utc(2026, 10, 20),
            fileModifiedAtMs: 1,
          ),
        );
    await a.db
        .into(a.db.reviewedLabels)
        .insert(
          ReviewedLabelsCompanion.insert(
            actionId: const Value(8),
            fileId: 'a1',
            presetKey: 0,
            actionType: 'trash',
            reviewedAt: DateTime.utc(2026, 10, 21),
            fileModifiedAtMs: 1,
          ),
        );
    await a.settings.write(AppSettings.swipeButtonsMode, true);
    await a.settings.write(AppSettings.activePresetId, preset);
    // Device state: never exported.
    await a.settings.write(AppSettings.sharePort, 4242);
  }

  /// Device B: the same photos under other ids, the SD card under another
  /// UUID, `two.jpg` moved to another folder.
  Future<void> seedB() async {
    await addIndexed(
      b.db,
      id: 'b1',
      folder: '/storage/emulated/0/DCIM/Camera',
      name: 'one.jpg',
      modifiedAtMs: 5,
    );
    await addIndexed(
      b.db,
      id: 'b2',
      folder: '/storage/emulated/0/Pictures/Old',
      name: 'two.jpg',
      size: 2000,
    );
    await addIndexed(
      b.db,
      id: 'b3',
      folder: '/storage/9999-0000/Pics',
      name: 'sd.jpg',
      takenAtMs: null,
      modifiedAtMs: 9,
    );
  }

  test('round trip: export on A, import on B restores everything', () async {
    await seedA();
    await seedB();
    final json = await a.service.exportJson();
    expect(json, isNot(contains('/storage/')), reason: 'no absolute paths');
    expect(json, isNot(contains('sharePort')));

    final data = await b.service.decode(json);
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    expect(plan.matched, 3);
    expect(plan.unmatched, isEmpty);
    expect(plan.newTags.single.name, 'Holiday');
    expect(plan.newPresets.single.name, 'Sort');
    await b.service.apply(plan, applySettings: true);

    final tag = await b.db.select(b.db.tags).getSingle();
    expect(tag.name, 'Holiday');
    expect(tag.color, 0xFF2196F3);
    final ft = await b.db.select(b.db.fileTags).getSingle();
    expect((ft.fileId, ft.tagId), ('b1', tag.id));
    expect((await b.db.select(b.db.favorites).getSingle()).fileId, 'b2');

    final preset = await b.db.select(b.db.presets).getSingle();
    final layout = SwipeLayout.decode(preset.layoutJson);
    expect(
      layout.directions[SwipeDirection.up]!.tagId,
      tag.id,
      reason: 'tag id remapped',
    );

    final labels = await b.db.select(b.db.reviewedLabels).get();
    final sd = labels.singleWhere((l) => l.fileId == 'b3');
    expect(sd.presetKey, preset.id);
    expect(sd.fileModifiedAtMs, 9, reason: "the copy's current modified time");
    expect(sd.actionId, lessThan(0));
    final basic = labels.singleWhere((l) => l.fileId == 'b1');
    expect(basic.presetKey, 0);
    expect(basic.actionId, isNot(sd.actionId));

    expect(await b.settings.read(AppSettings.swipeButtonsMode), isTrue);
    expect(await b.settings.read(AppSettings.activePresetId), preset.id);
    expect(await b.settings.read(AppSettings.sharePort), 0);
  });

  test('applySettings off leaves settings alone', () async {
    await seedA();
    await seedB();
    final data = await b.service.decode(await a.service.exportJson());
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    expect(
      plan.settingChanges.map((s) => s.name),
      containsAll(['swipe.buttonsMode', 'presets.active']),
    );
    await b.service.apply(plan, applySettings: false);
    expect(await b.settings.read(AppSettings.swipeButtonsMode), isFalse);
    expect(await b.settings.read(AppSettings.activePresetId), 0);
  });

  test('merge: same-named tag reused, identical preset skipped, different one renamed, nothing deleted', () async {
    await seedA();
    await seedB();
    final existingTag = await addTag(b.db, 'holiday', color: 0xFFFF0000);
    await addTag(b.db, 'Mine');
    // Identical to A's after remapping: same name, same layout with B's tag.
    await addPreset(b.db, 'sort', layout: _tagLayout(existingTag));
    await addPreset(a.db, 'Other');
    await addPreset(b.db, 'Other', layout: _tagLayout(existingTag));
    await b.db
        .into(b.db.fileTags)
        .insert(
          FileTagsCompanion.insert(
            fileId: 'b1',
            tagId: existingTag,
            addedAt: DateTime.utc(2025),
          ),
        );

    final data = await b.service.decode(await a.service.exportJson());
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    expect(plan.newTags, isEmpty);
    expect(plan.reusedTags, 1);
    expect(plan.skippedPresets, 1);
    expect(plan.newPresets.single.name, 'Other (imported)');
    expect(plan.fileTagsToAdd, isEmpty, reason: 'b1 already has the tag');
    await b.service.apply(plan, applySettings: true);

    final tags = await b.db.select(b.db.tags).get();
    expect(tags.map((t) => t.name), unorderedEquals(['holiday', 'Mine']));
    expect(tags.firstWhere((t) => t.name == 'holiday').color, 0xFFFF0000);
    final presets = await b.db.select(b.db.presets).get();
    expect(
      presets.map((p) => p.name),
      unorderedEquals(['sort', 'Other', 'Other (imported)']),
    );
    expect(await b.db.select(b.db.fileTags).get(), hasLength(1));
  });

  test('a newer label on this device wins', () async {
    await seedA();
    await seedB();
    await b.db
        .into(b.db.reviewedLabels)
        .insert(
          ReviewedLabelsCompanion.insert(
            actionId: const Value(3),
            fileId: 'b1',
            presetKey: 0,
            actionType: 'keep',
            reviewedAt: DateTime.utc(2026, 11),
            fileModifiedAtMs: 5,
          ),
        );
    final data = await b.service.decode(await a.service.exportJson());
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    expect(plan.reviewedToAdd.where((r) => r.fileId == 'b1'), isEmpty);
  });

  test('unmatched files are listed and get nothing', () async {
    await seedA();
    await addIndexed(
      b.db,
      id: 'b1',
      folder: '/storage/emulated/0/DCIM/Camera',
      name: 'one.jpg',
    );
    final data = await b.service.decode(await a.service.exportJson());
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    expect(plan.matched, 1);
    expect(
      plan.unmatched.map((f) => f.name),
      unorderedEquals(['two.jpg', 'sd.jpg']),
    );
    expect(plan.favoritesToAdd, isEmpty);
  });

  test('undo last import restores the exact pre-import state', () async {
    await seedA();
    await seedB();
    await addTag(b.db, 'Mine');
    await b.settings.write(AppSettings.themeMode, 'dark');
    final before = await dumpUserTables(b.db);
    expect(await b.service.canUndo(), isFalse);

    final data = await b.service.decode(await a.service.exportJson());
    await b.service.apply(
      await b.service.plan(data, importedSuffix: 'imported'),
      applySettings: true,
    );
    expect(await dumpUserTables(b.db), isNot(before));
    expect(await b.service.canUndo(), isTrue);

    await b.service.undoLastImport();
    expect(await dumpUserTables(b.db), before);
    expect(await b.service.canUndo(), isFalse);
  });

  test('keeps only the newest 3 snapshots', () async {
    await seedA();
    await seedB();
    final data = await b.service.decode(await a.service.exportJson());
    var t = 0;
    final service = BackupService(
      b.db,
      b.queue,
      snapshotDir: () async => Directory('${b.dir.path}/backups'),
      clock: () => DateTime.utc(2026).add(Duration(seconds: t++)),
    );
    for (var i = 0; i < 5; i++) {
      await service.apply(
        await service.plan(data, importedSuffix: 'imported'),
        applySettings: false,
      );
    }
    final snaps = Directory('${b.dir.path}/backups')
        .listSync()
        .where((f) => f.path.endsWith('.json'));
    expect(snaps, hasLength(3));
  });

  test('a failed import writes nothing and offers no undo', () async {
    await seedA();
    await seedB();
    final data = await b.service.decode(await a.service.exportJson());
    final plan = await b.service.plan(data, importedSuffix: 'imported');
    // A same-named preset appears after planning: the unique index fails.
    await addPreset(b.db, 'SORT', layout: {'directions': <String, Object?>{}});
    final before = await dumpUserTables(b.db);
    await expectLater(
      b.service.apply(plan, applySettings: true),
      throwsA(isA<Object>()),
    );
    expect(await dumpUserTables(b.db), before);
    expect(await b.service.canUndo(), isFalse);
  });

  test('suggested file name', () {
    expect(a.service.suggestedFileName(), 'kfm-backup-2026-11-02.json');
  });

  test('export file is valid JSON with format and schema', () async {
    await seedA();
    final j = jsonDecode(await a.service.exportJson()) as Map<String, Object?>;
    expect(j['format'], kBackupFormat);
    expect(j['schema'], kBackupSchema);
  });
}
