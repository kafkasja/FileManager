import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';

void main() {
  late Directory dir;
  late String root;
  late File store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_ledger');
    root = dir.path.replaceAll(r'\', '/');
    store = File('$root/support/kfm_temp_ledger.json');
  });
  tearDown(() => dir.delete(recursive: true));

  test('tempPathIn: hidden name with 16 hex digits, unique', () {
    final a = tempPathIn('/x/y');
    final b = tempPathIn('/x/y');
    expect(a, matches(RegExp(r'^/x/y/\.kfm-tmp-[0-9a-f]{16}$')));
    expect(a, isNot(b));
    expect(nameOf(a), startsWith(tempFilePrefix));
  });

  test('tempPathIn keeps a short extension, drops a long one', () {
    expect(
      tempPathIn('/x', extension: '.jpg'),
      matches(RegExp(r'^/x/\.kfm-tmp-[0-9a-f]{16}\.jpg$')),
    );
    expect(
      tempPathIn('/x', extension: '.${'a' * 40}'),
      matches(RegExp(r'^/x/\.kfm-tmp-[0-9a-f]{16}$')),
    );
  });

  test('add / remove persist across instances', () async {
    final ledger = TempFileLedger(store);
    await ledger.add('$root/a');
    await ledger.add('$root/b');
    await ledger.remove('$root/a');
    expect(await TempFileLedger(store).entries(), {'$root/b'});
  });

  test('kill mid-copy: the next run deletes the temp file', () async {
    // Run 1: the copy starts, then the process dies before the rename.
    final temp = File('$root/dst/.kfm-tmp-0123456789abcdef');
    await TempFileLedger(store).add(temp.path);
    await temp.create(recursive: true);
    await temp.writeAsBytes([1, 2, 3]);

    // Run 2: startup cleanup.
    final next = TempFileLedger(store);
    expect(await next.cleanUp(), 1);
    expect(temp.existsSync(), isFalse);
    expect(await next.entries(), isEmpty);
    expect(await TempFileLedger(store).entries(), isEmpty);
  });

  test('cleanUp removes folders, forgets paths already gone', () async {
    final folder = Directory('$root/.kfm-tmp-folder');
    await File('${folder.path}/inner.bin').create(recursive: true);
    final first = TempFileLedger(store);
    await first.add(folder.path);
    await first.add('$root/never-written');

    final next = TempFileLedger(store);
    expect(await next.cleanUp(), 1);
    expect(folder.existsSync(), isFalse);
    expect(await next.entries(), isEmpty);
  });

  test('cleanUp leaves copies this run started alone', () async {
    final ledger = TempFileLedger(store);
    final temp = File('$root/.kfm-tmp-inflight');
    await ledger.add(temp.path);
    await temp.writeAsBytes([1]);
    expect(await ledger.cleanUp(), 0);
    expect(temp.existsSync(), isTrue);
    expect(await ledger.entries(), {temp.path});
  });

  test('an unreadable ledger file is treated as empty', () async {
    await store.create(recursive: true);
    await store.writeAsString('{not json');
    final ledger = TempFileLedger(store);
    expect(await ledger.cleanUp(), 0);
    await ledger.add('$root/x');
    expect(await TempFileLedger(store).entries(), {'$root/x'});
  });
}
