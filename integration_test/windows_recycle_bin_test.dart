// Windows-only (TASK-PL1): the real `com.kaf.kfm/windows` channel in the
// runner. Run with
//   flutter test integration_test/windows_recycle_bin_test.dart -d windows
// Only touches files it creates in a fresh temp folder; the Recycle Bin is
// never emptied (deleteFromBin only gets this test's own items).
@TestOn('windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

/// A 64x64 24-bit BMP (blue/green gradient), something the Shell can
/// thumbnail without extra codecs.
Uint8List _bmp() {
  const w = 64;
  const h = 64;
  const row = w * 3;
  const size = 54 + row * h;
  final b = ByteData(size)
    ..setUint8(0, 0x42)
    ..setUint8(1, 0x4D)
    ..setUint32(2, size, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, w, Endian.little)
    ..setInt32(22, h, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, row * h, Endian.little);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final o = 54 + y * row + x * 3;
      b
        ..setUint8(o, x * 4)
        ..setUint8(o + 1, y * 4)
        ..setUint8(o + 2, 128);
    }
  }
  return b.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String root;
  final channel = WindowsChannel();
  // Bin items this test created and hasn't restored: removed at the end.
  final leftovers = <String>{};

  // Safety net: any bin item of this test's temp folders (an earlier failed
  // run) goes; nothing else in the user's Recycle Bin is touched.
  Future<void> removeOwnBinItems() async {
    final prefix = normalizeWindowsPath(
      '${Directory.systemTemp.path}/kfm_bin_test_',
    ).toLowerCase();
    final ours = [
      for (final b in await channel.listBin())
        if (b.originalPath.toLowerCase().startsWith(prefix)) b.trashId,
    ];
    if (ours.isNotEmpty) await channel.deleteFromBin(ours);
  }

  setUpAll(removeOwnBinItems);
  tearDownAll(removeOwnBinItems);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_bin_test_');
    root = normalizeWindowsPath(dir.path);
  });

  tearDown(() async {
    if (leftovers.isNotEmpty) {
      await channel.deleteFromBin(leftovers.toList());
      leftovers.clear();
    }
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('knownFolders resolves the four folders', () async {
    final folders = await channel.knownFolders();
    expect(folders.keys, containsAll(KnownFolder.values));
    for (final p in folders.values) {
      expect(Directory(p).existsSync(), isTrue, reason: p);
    }
  });

  test('networkIsPublic answers', () async {
    expect(await channel.networkIsPublic(), isA<bool>());
  });

  test('thumbnail returns PNG bytes no longer than size', () async {
    final f = File('${dir.path}\\thumb.bmp')..writeAsBytesSync(_bmp());
    final png = await channel.thumbnail(normalizeWindowsPath(f.path), 32);
    expect(png, isNotNull);
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final w = ByteData.sublistView(png).getUint32(16);
    final h = ByteData.sublistView(png).getUint32(20);
    expect(w <= 32 && h <= 32, isTrue, reason: '${w}x$h');
    expect(await channel.thumbnail('$root/missing.bmp', 32), isNull);
  });

  test('50 files: recycle in one batch, listed, restored in place', () async {
    final source = WindowsFileSource(
      channel: channel,
      indexRoots: () async => [root],
    );
    final files = <FileRef>[];
    for (var i = 0; i < 50; i++) {
      final p = '$root/sub/f$i.txt';
      File(p)
        ..createSync(recursive: true)
        ..writeAsStringSync('content $i');
      files.add((await source.stat('path:$p'))!);
    }

    expect((await channel.binAvailable([files.first.path])).values, [true]);

    final trashed = await source.trashBatch(files);
    leftovers.addAll(trashed.trashed.map((t) => t.trashId));
    expect(trashed.failed, isEmpty);
    expect(trashed.trashed, hasLength(50));
    for (final f in files) {
      expect(File(f.path).existsSync(), isFalse, reason: f.path);
    }

    final listed = await source.listTrashed();
    final ours = {for (final t in listed) t.trashId: t};
    for (final t in trashed.trashed) {
      final item = ours[t.trashId];
      expect(item, isNotNull, reason: 'bin lists ${t.trashId}');
      expect(sameWindowsPath(item!.original.path, t.original.path), isTrue);
      expect(item.original.sizeBytes, t.original.sizeBytes);
    }

    // A name taken meanwhile: that file comes back under a new name.
    File(files.first.path).writeAsStringSync('newer');
    final restored = await source.restoreBatch(trashed.trashed);
    leftovers.removeAll(restored.restored.keys);
    expect(restored.failed, isEmpty);
    expect(restored.restored, hasLength(50));
    for (final (i, t) in trashed.trashed.indexed) {
      final ref = restored.restored[t.trashId]!;
      expect(File(ref.path).readAsStringSync(), 'content $i');
      if (i == 0) {
        expect(sameWindowsPath(ref.path, t.original.path), isFalse);
      } else {
        expect(sameWindowsPath(ref.path, t.original.path), isTrue);
      }
    }
    final after = {for (final t in await channel.listBin()) t.trashId};
    expect(after.intersection(ours.keys.toSet()), isEmpty);
  });

  test('deleteFromBin removes only the given items', () async {
    final a = File('${dir.path}\\a.txt')..writeAsStringSync('a');
    final b = File('${dir.path}\\b.txt')..writeAsStringSync('b');
    final results = await channel.recycle([
      normalizeWindowsPath(a.path),
      normalizeWindowsPath(b.path),
      '$root/missing.txt',
    ]);
    expect(results.map((r) => r.error), [
      null,
      null,
      BinError.notFound,
    ], reason: results.map((r) => r.message).join(' | '));
    final ids = [for (final r in results.take(2)) r.trashId!];
    leftovers.addAll(ids);

    await channel.deleteFromBin([ids.first]);
    leftovers.remove(ids.first);
    final bin = {for (final t in await channel.listBin()) t.trashId};
    expect(bin.contains(ids.first), isFalse);
    expect(bin.contains(ids.last), isTrue);
    expect(File(ids.first).existsSync(), isFalse);
  });

  test('a file another program holds open fails alone with inUse', () async {
    final locked = File('${dir.path}\\locked.txt')..writeAsStringSync('x');
    final free = File('${dir.path}\\free.txt')..writeAsStringSync('y');
    // A Windows process holding the file without FILE_SHARE_DELETE.
    final holder = await Process.start('powershell', [
      '-NoProfile',
      '-Command',
      [
        "\$f = [IO.File]::Open('${locked.path}', 'Open', 'Read', 'Read')",
        'Write-Output ready',
        'Start-Sleep 60',
      ].join('; '),
    ]);
    try {
      await holder.stdout.firstWhere(
        (b) => String.fromCharCodes(b).contains('ready'),
      );
      final results = await channel.recycle([
        normalizeWindowsPath(locked.path),
        normalizeWindowsPath(free.path),
      ]);
      leftovers.addAll(results.map((r) => r.trashId).whereType<String>());
      expect(
        results.first.error,
        BinError.inUse,
        reason: results.first.message,
      );
      expect(results.last.error, isNull);
      expect(locked.existsSync(), isTrue);
      expect(free.existsSync(), isFalse);
    } finally {
      holder.kill();
      await holder.exitCode;
    }
  });

  test('TrashLocation of a recycled file is systemTrash', () async {
    final source = WindowsFileSource(
      channel: channel,
      indexRoots: () async => [root],
    );
    final p = '$root/one.txt';
    File(p).writeAsStringSync('1');
    final result = await source.trashBatch([(await source.stat('path:$p'))!]);
    leftovers.addAll(result.trashed.map((t) => t.trashId));
    expect(result.trashed.single.location, TrashLocation.systemTrash);
    final back = await source.restore(result.trashed.single);
    leftovers.clear();
    expect(back.path, p);
  });
}
