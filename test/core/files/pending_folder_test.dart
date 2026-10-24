import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/android/android_file_source.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/files/trash_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String root;
  late AppDatabase db;
  late DateTime now;
  late int retention;
  late PendingFolder folder;
  late AndroidFileSource source;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_pending');
    root = dir.path.replaceAll(r'\', '/');
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 10, 23);
    retention = 7;
    folder = PendingFolder(
      db: db,
      volumeRootOf: (_) => root,
      retentionDays: () async => retention,
      clock: () => now,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(FilesChannel.name),
          (call) async => switch (call.method) {
            'sdkInt' => 34,
            'scanPaths' => <Object?, Object?>{},
            'listTrashed' => <Object?>[],
            _ => null,
          },
        );
    source = AndroidFileSource(
      channel: FilesChannel(),
      primaryRoot: root,
      pendingFolder: folder,
    );
  });

  tearDown(() async {
    await source.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<String> file(String rel, String content) async {
    final f = File('$root/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsString(content);
    return f.path.replaceAll(r'\', '/');
  }

  test(
    'non-media trash goes into the hidden folder with .nomedia + index',
    () async {
      final path = await file('Download/report.pdf', 'pdf!');
      final ref = (await source.stat('path:$path'))!;
      final result = await source.trashBatch([ref]);

      expect(result.failed, isEmpty);
      final item = result.trashed.single;
      expect(item.location, TrashLocation.pendingFolder);
      expect(item.expiresAt, now.add(const Duration(days: 7)));
      expect(File(path).existsSync(), isFalse);

      final row = (await folder.all()).single;
      expect(row.storedPath, startsWith('$root/.KFMTrash/'));
      expect(row.storedPath, endsWith('__report.pdf'));
      expect(File(row.storedPath).readAsStringSync(), 'pdf!');
      expect(File('$root/.KFMTrash/.nomedia').existsSync(), isTrue);
      final index = File('$root/.KFMTrash/.index.jsonl').readAsLinesSync();
      expect(jsonDecode(index.single), containsPair('originalPath', path));
    },
  );

  test('restore puts it back; a name clash becomes "(restored)"', () async {
    final path = await file('Download/a.pdf', 'one');
    final first = await source.trashBatch([(await source.stat('path:$path'))!]);
    final back = await source.restore(first.trashed.single);
    expect(back.path, path);
    expect(File(path).readAsStringSync(), 'one');
    expect(await folder.all(), isEmpty);

    final again = await source.trashBatch([back]);
    await file('Download/a.pdf', 'new file');
    final restored = await source.restore(again.trashed.single);
    expect(restored.name, 'a (restored).pdf');
    expect(File(path).readAsStringSync(), 'new file');
  });

  test('purgeExpired removes expired files and rows only', () async {
    retention = 1;
    final old = await file('Download/old.pdf', 'x');
    await folder.moveIn((await source.stat('path:$old'))!);
    retention = 7;
    final fresh = await file('Download/new.pdf', 'y');
    await folder.moveIn((await source.stat('path:$fresh'))!);

    final purged = await folder.purgeExpired(
      now: now.add(const Duration(days: 2)),
    );
    expect(purged, 1);
    final rows = await folder.all();
    expect(rows.single.name, 'new.pdf');
    expect(
      Directory('$root/.KFMTrash')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('__old.pdf')),
      isEmpty,
    );
  });

  test('deleteNow deletes forever', () async {
    final p = await file('a.txt', 'x');
    final row = await folder.moveIn((await source.stat('path:$p'))!);
    await folder.deleteNow([row.id]);
    expect(await folder.all(), isEmpty);
    expect(File(row.storedPath).existsSync(), isFalse);
  });

  test('app data cleared: rows rebuilt from .index.jsonl', () async {
    final p1 = await file('Download/a.pdf', '1');
    final p2 = await file('Docs/b.txt', '2');
    await folder.moveIn((await source.stat('path:$p1'))!);
    await folder.moveIn((await source.stat('path:$p2'))!);
    // A stray file the index doesn't know, and a corrupt index line.
    File('$root/.KFMTrash/stray.bin').writeAsStringSync('?');
    File('$root/.KFMTrash/.index.jsonl')
        .writeAsStringSync('not json\n', mode: FileMode.append);
    await db.delete(db.pendingFolderItems).go();

    expect(await folder.reconcile([root]), 3);
    final byName = {for (final r in await folder.all()) r.name: r};
    expect(byName['a.pdf']!.originalPath, p1);
    expect(byName['b.txt']!.originalPath, p2);
    expect(
      byName['stray.bin']!.originalPath,
      '$root/Download/Restored/stray.bin',
    );
    expect(await folder.reconcile([root]), 0, reason: 'all known now');
  });

  test('H2: reconcile adds unknown files, known rows untouched', () async {
    final p1 = await file('Download/a.pdf', '1');
    final known = await folder.moveIn((await source.stat('path:$p1'))!);
    // A kill between the rename and the DB insert.
    File('$root/.KFMTrash/zz__lost.txt').writeAsStringSync('?');
    expect(await folder.reconcile([root]), 1);
    final rows = await folder.all();
    expect(rows, hasLength(2));
    final again = rows.singleWhere((r) => r.id == known.id);
    expect(again.originalPath, p1);
    expect(again.expiresAt.isAtSameMomentAs(known.expiresAt), isTrue);
    expect(rows.singleWhere((r) => r.id != known.id).name, 'lost.txt');
  });

  test('H2: folder not creatable → pendingFolderUnavailable', () async {
    final p = await file('Download/a.pdf', '1');
    // A file where the folder should be: Directory.create fails.
    File('$root/.KFMTrash').writeAsStringSync('in the way');
    await expectLater(
      folder.moveIn((await source.stat('path:$p'))!),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.pendingFolderUnavailable,
        ),
      ),
    );
    expect(File(p).existsSync(), isTrue);
    expect(await folder.all(), isEmpty);
  });

  test('H2: rename across mounts → pendingFolderUnavailable', () async {
    final crossMount = PendingFolder(
      db: db,
      volumeRootOf: (_) => root,
      retentionDays: () async => retention,
      clock: () => now,
      renameOverride: (from, to) async =>
          throw FileSystemException('rename', from, const OSError('', 18)),
    );
    final p = await file('Download/a.pdf', '1');
    await expectLater(
      crossMount.moveIn((await source.stat('path:$p'))!),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.pendingFolderUnavailable,
        ),
      ),
    );
    expect(File(p).readAsStringSync(), '1');
    expect(
      Directory('$root/.KFMTrash').listSync().whereType<File>().where(
        (f) => !f.path.replaceAll(r'\', '/').split('/').last.startsWith('.'),
      ),
      isEmpty,
      reason: 'nothing copied',
    );
    expect(await folder.all(), isEmpty);
  });

  test(
    'H2: a permission error on the file itself stays permissionDenied',
    () async {
      final denied = PendingFolder(
        db: db,
        volumeRootOf: (_) => root,
        retentionDays: () async => retention,
        clock: () => now,
        renameOverride: (from, to) async =>
            throw PathAccessException('rename', const OSError('', 13), from),
      );
      final p = await file('Download/a.pdf', '1');
      await expectLater(
        denied.moveIn((await source.stat('path:$p'))!),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.permissionDenied,
          ),
        ),
      );
      expect(File(p).existsSync(), isTrue);
    },
  );

  test('retention values out of range fall back to 7', () {
    expect(clampRetentionDays(0), 7);
    expect(clampRetentionDays(500), 7);
    expect(clampRetentionDays(14), 14);
  });

  test('a file that vanished before the move fails without a row', () async {
    final p = await file('gone.pdf', 'x');
    final ref = (await source.stat('path:$p'))!;
    File(p).deleteSync();
    final result = await source.trashBatch([ref]);
    expect(result.failed[ref.id]?.failure, FileOpFailure.notFound);
    expect(await folder.all(), isEmpty);
  });

  test(
    'listTrashed includes pending items with their original place',
    () async {
      final p = await file('Download/x.pdf', 'x');
      await source.trashBatch([(await source.stat('path:$p'))!]);
      final items = await source.listTrashed();
      expect(items.single.original.path, p);
      expect(items.single.location, TrashLocation.pendingFolder);
    },
  );

  test('H3: listed pending items point at their stored bytes', () async {
    final p = await file('Download/pic.jpg', 'img');
    final ref = (await source.stat('path:$p'))!;
    await source.trashBatch([ref]);
    final item = (await source.listTrashed()).single;
    expect(item.location, TrashLocation.pendingFolder);
    expect(item.original.path, p, reason: 'restore target unchanged');
    expect(item.storedPath, isNotNull);
    expect(File(item.preview.path).readAsStringSync(), 'img');
    expect(item.preview.name, endsWith('__pic.jpg'));
    expect(item.toJson().containsKey('storedPath'), isFalse);
  });
}
